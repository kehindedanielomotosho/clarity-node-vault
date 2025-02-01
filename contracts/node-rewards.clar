;; Node Rewards Contract

;; Constants
(define-constant reward-cycle u2100)
(define-constant reward-amount u1000)

;; Maps
(define-map reward-claims
  principal
  {last-claim: uint,
   total-claimed: uint}
)

;; Claim rewards
(define-public (claim-rewards)
  (let ((node-data (contract-call? .node-vault get-node tx-sender)))
    (if (is-ok node-data)
      (let ((last-claim (default-to u0 (get last-claim 
                       (default-to {last-claim: u0, total-claimed: u0} 
                       (map-get? reward-claims tx-sender))))))
        (if (>= block-height (+ last-claim reward-cycle))
          (ok (map-set reward-claims
              tx-sender
              {last-claim: block-height,
               total-claimed: (+ reward-amount (get total-claimed 
                              (default-to {last-claim: u0, total-claimed: u0}
                              (map-get? reward-claims tx-sender))))}))
          (err u403)))
      (err u404))))
