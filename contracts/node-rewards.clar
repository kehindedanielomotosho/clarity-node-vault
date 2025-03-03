;; Node Rewards Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant reward-cycle u2100)
(define-constant reward-amount u1000)
(define-constant err-invalid-node (err u401))
(define-constant err-too-early (err u402))
(define-constant err-inactive-node (err u403))
(define-constant err-unauthorized (err u404))

;; Maps
(define-map reward-claims
  principal
  {last-claim: uint,
   total-claimed: uint}
)

;; Claim rewards
(define-public (claim-rewards)
  (let ((node-data (unwrap! (contract-call? .node-vault get-node tx-sender) err-invalid-node))
        (claim-data (default-to {last-claim: u0, total-claimed: u0} 
                    (map-get? reward-claims tx-sender))))
    (asserts! (is-eq (get status node-data) "active") err-inactive-node)
    (asserts! (>= block-height (+ (get last-claim claim-data) reward-cycle)) err-too-early)
    (try! (as-contract (stx-transfer? reward-amount (as-contract tx-sender) tx-sender)))
    (ok (map-set reward-claims
        tx-sender
        {last-claim: block-height,
         total-claimed: (+ reward-amount (get total-claimed claim-data))}))))
