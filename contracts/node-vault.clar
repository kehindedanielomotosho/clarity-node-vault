;; Node Vault - Main contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-stake u100000) ;; Minimum stake required
(define-constant err-unauthorized (err u100))
(define-constant err-insufficient-stake (err u101))
(define-constant err-node-exists (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-node-not-found (err u104))

;; Valid status values
(define-data-var valid-statuses (list 10 (string-ascii 10)) 
  (list "active" "inactive" "slashed" "pending"))

;; Data structures
(define-map nodes 
  principal 
  {stake: uint, 
   status: (string-ascii 10),
   uptime: uint,
   rewards: uint}
)

;; Read-only functions
(define-read-only (get-node (node principal))
  (ok (map-get? nodes node)))

(define-read-only (is-valid-status (status (string-ascii 10)))
  (ok (asserts! (is-some (index-of (var-get valid-statuses) status)) err-invalid-status)))

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
             status: "pending",
             uptime: u100,
             rewards: u0}
          )))
        err-insufficient-stake))))

;; Update node status
(define-public (update-status (node principal) (new-status (string-ascii 10)))
  (let ((node-data (map-get? nodes node)))
    (if (and (is-eq tx-sender contract-owner)
             (is-some node-data))
      (begin
        (try! (is-valid-status new-status))
        (ok (map-set nodes 
          node
          (merge (unwrap-panic node-data)
                {status: new-status}))))
      err-unauthorized)))

;; Unregister node
(define-public (unregister-node)
  (let ((node-data (map-get? nodes tx-sender)))
    (if (is-some node-data)
      (begin
        (try! (as-contract (stx-transfer? 
          (get stake (unwrap-panic node-data))
          (as-contract tx-sender)
          tx-sender)))
        (ok (map-delete nodes tx-sender)))
      err-node-not-found)))
