(define-constant err-unauthorized u100)
(define-constant err-exists u101)
(define-constant err-not-found u102)
(define-constant err-bad-arg u103)
(define-constant err-finalized u104)
(define-constant err-voted u105)
(define-constant err-zero u106)
(define-constant err-insufficient u107)

(define-map balances {owner: principal} {amount: uint})
(define-map staked {owner: principal} {amount: uint})
(define-map proposals {id: uint} {proposer: principal, chapter: uint, hash: (string-ascii 128), reward: uint, start: uint, end: uint, yes: uint, no: uint, finalized: bool, accepted: bool})
(define-map votes {id: uint, voter: principal} {support: bool})
(define-map chapters {id: uint} {hash: (string-ascii 128), rev: uint})

(define-data-var owner (optional principal) none)
(define-data-var next-proposal-id uint u0)
(define-data-var min-quorum uint u0)
(define-data-var total-supply uint u0)

(define-read-only (get-owner) (ok (var-get owner)))
(define-read-only (get-min-quorum) (ok (var-get min-quorum)))
(define-read-only (get-total-supply) (ok (var-get total-supply)))

(define-private (ensure-owner)
  (let ((o (var-get owner)))
    (if (is-some o)
      (begin (asserts! (is-eq tx-sender (unwrap-panic o)) (err err-unauthorized)) (ok true))
      (begin (var-set owner (some tx-sender)) (ok true))
    )
  )
)

(define-read-only (balance-of (who principal))
  (ok (default-to u0 (get amount (map-get? balances {owner: who}))))
)

(define-read-only (stake-of (who principal))
  (ok (default-to u0 (get amount (map-get? staked {owner: who}))))
)

(define-read-only (get-proposal (id uint))
  (match (map-get? proposals {id: id}) p (ok p) (err err-not-found))
)

(define-read-only (get-chapter (id uint))
  (match (map-get? chapters {id: id}) c (ok c) (err err-not-found))
)

(define-private (inc-balance (who principal) (amt uint))
  (let ((cur (default-to u0 (get amount (map-get? balances {owner: who})))))
    (map-set balances {owner: who} {amount: (+ cur amt)})
  )
)

(define-private (dec-balance (who principal) (amt uint))
  (let ((cur (default-to u0 (get amount (map-get? balances {owner: who})))))
    (if (>= cur amt)
      (begin (map-set balances {owner: who} {amount: (- cur amt)}) (ok true))
      (err err-insufficient)
    )
  )
)

(define-private (inc-stake (who principal) (amt uint))
  (let ((cur (default-to u0 (get amount (map-get? staked {owner: who})))))
    (map-set staked {owner: who} {amount: (+ cur amt)})
  )
)

(define-private (dec-stake (who principal) (amt uint))
  (let ((cur (default-to u0 (get amount (map-get? staked {owner: who})))))
    (if (>= cur amt)
      (begin (map-set staked {owner: who} {amount: (- cur amt)}) (ok true))
      (err err-insufficient)
    )
  )
)

(define-public (set-min-quorum (q uint))
  (begin
    (try! (ensure-owner))
    (var-set min-quorum q)
    (ok true)
  )
)

(define-private (mint (to principal) (amt uint))
  (begin
    (asserts! (> amt u0) (err err-zero))
    (inc-balance to amt)
    (var-set total-supply (+ (var-get total-supply) amt))
    (ok true)
  )
)

(define-public (owner-mint (to principal) (amt uint))
  (begin
    (try! (ensure-owner))
    (mint to amt)
  )
)

(define-public (transfer (to principal) (amt uint))
  (begin
    (asserts! (> amt u0) (err err-zero))
(try! (dec-balance tx-sender amt))
    (inc-balance to amt)
    (ok true)
  )
)

(define-public (stake (amt uint))
  (begin
    (asserts! (> amt u0) (err err-zero))
(try! (dec-balance tx-sender amt))
    (inc-stake tx-sender amt)
    (ok true)
  )
)

(define-public (unstake (amt uint))
  (begin
    (asserts! (> amt u0) (err err-zero))
(try! (dec-stake tx-sender amt))
    (inc-balance tx-sender amt)
    (ok true)
  )
)

(define-public (propose (chapter uint) (hash (string-ascii 128)) (reward uint) (duration uint))
  (begin
    (asserts! (> reward u0) (err err-zero))
    (let ((id (var-get next-proposal-id)))
      (map-set proposals {id: id} {proposer: tx-sender, chapter: chapter, hash: hash, reward: reward, start: u0, end: duration, yes: u0, no: u0, finalized: false, accepted: false})
      (var-set next-proposal-id (+ id u1))
      (ok id)
    )
  )
)

(define-private (stake-of-now (who principal))
  (default-to u0 (get amount (map-get? staked {owner: who})))
)

(define-public (vote (id uint) (support bool))
  (begin
    (let ((p (unwrap! (map-get? proposals {id: id}) (err err-not-found))))
      (asserts! (not (get finalized p)) (err err-finalized))
      (asserts! (is-none (map-get? votes {id: id, voter: tx-sender})) (err err-voted))
      (let ((w (stake-of-now tx-sender)))
        (asserts! (> w u0) (err err-zero))
        (map-set votes {id: id, voter: tx-sender} {support: support})
        (if support
          (map-set proposals {id: id} {proposer: (get proposer p), chapter: (get chapter p), hash: (get hash p), reward: (get reward p), start: (get start p), end: (get end p), yes: (+ (get yes p) w), no: (get no p), finalized: false, accepted: false})
          (map-set proposals {id: id} {proposer: (get proposer p), chapter: (get chapter p), hash: (get hash p), reward: (get reward p), start: (get start p), end: (get end p), yes: (get yes p), no: (+ (get no p) w), finalized: false, accepted: false})
        )
        (ok true)
      )
    )
  )
)

(define-private (apply-chapter (chapter uint) (hash (string-ascii 128)))
  (let ((cur (map-get? chapters {id: chapter})))
    (if (is-some cur)
      (let ((c (unwrap-panic cur)))
        (map-set chapters {id: chapter} {hash: hash, rev: (+ (get rev c) u1)})
      )
      (map-set chapters {id: chapter} {hash: hash, rev: u1})
    )
  )
)

(define-public (finalize (id uint))
  (begin
    (let ((p (unwrap! (map-get? proposals {id: id}) (err err-not-found))))
      (asserts! (not (get finalized p)) (err err-finalized))
      (let ((yes (get yes p)) (no (get no p)) (q (var-get min-quorum)))
        (let ((okpass (and (>= yes q) (> yes no))))
          (if okpass
            (begin
              (apply-chapter (get chapter p) (get hash p))
              (try! (mint (get proposer p) (get reward p)))
              (map-set proposals {id: id} {proposer: (get proposer p), chapter: (get chapter p), hash: (get hash p), reward: (get reward p), start: (get start p), end: (get end p), yes: yes, no: no, finalized: true, accepted: true})
              (ok true)
            )
            (begin
              (map-set proposals {id: id} {proposer: (get proposer p), chapter: (get chapter p), hash: (get hash p), reward: (get reward p), start: (get start p), end: (get end p), yes: yes, no: no, finalized: true, accepted: false})
              (ok false)
            )
          )
        )
      )
    )
  )
)

(define-read-only (proposal-tally (id uint))
  (let ((p (unwrap! (map-get? proposals {id: id}) (err err-not-found))))
    (ok {yes: (get yes p), no: (get no p), finalized: (get finalized p), accepted: (get accepted p)})
  )
)

(define-read-only (voted? (id uint) (who principal))
  (ok (is-some (map-get? votes {id: id, voter: who})))
)

;; title: Collaborative-Open-Source-Textbook-DAO
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

