;; Node Vault - Main contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-stake u100000) ;; Minimum stake required
(define-constant err-unauthorized (err u100))
(define-constant err-insufficient-stake (err u101))
(define-constant err-node-exists (err u102))

;; Data structures
(define-map nodes 
  principal 
  {stake: uint, 
   status: (string-ascii 10),
   uptime: uint,
   rewards: uint}
)

;; Register new node
(define-public (register-node (stake uint))
  (let ((node-data (map-get? nodes tx-sender)))
    (if (is-some node-data)
      err-node-exists
      (if (>= stake min-stake)
        (begin
          (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
          (ok (map-set nodes 
            tx-sender
            {stake: stake,
             status: "active",
             uptime: u100,
             rewards: u0}
          )))
        err-insufficient-stake))))

;; Update node status
(define-public (update-status (node principal) (new-status (string-ascii 10)))
  (if (is-eq tx-sender contract-owner)
    (ok (map-set nodes 
      node
      (merge (unwrap-panic (map-get? nodes node))
            {status: new-status})))
    err-unauthorized))
