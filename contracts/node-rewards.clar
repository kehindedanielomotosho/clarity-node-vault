;; Node Rewards Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant reward-cycle u2100)
(define-constant reward-amount u1000)
(define-constant err-invalid-node (err u401))
(define-constant err-too-early (err u402))
(define-constant err-inactive-node (err u403))

;; Maps
(define-map reward-claims
  principal
  {last-claim: uint,
   total-claimed: uint}
)

;; Claim rewards
(define-public (claim-rewards)
  (let ((node-data (unwrap! (contract-call? .node-vault get-node tx-sender) err-invalid-node)))
    (if (is-some node-data)
      (let ((node-info (unwrap-panic node-data))
            (last-claim (default-to u0 (get last-claim 
                       (default-to {last-claim: u0, total-claimed: u0} 
                       (map-get? reward-claims tx-sender))))))
        (asserts! (is-eq (get status node-info) "active") err-inactive-node)
        (if (>= block-height (+ last-claim reward-cycle))
          (ok (map-set reward-claims
              tx-sender
              {last-claim: block-height,
               total-claimed: (+ reward-amount (get total-claimed 
                              (default-to {last-claim: u0, total-claimed: u0}
                              (map-get? reward-claims tx-sender))))}))
          err-too-early))
      err-invalid-node)))
