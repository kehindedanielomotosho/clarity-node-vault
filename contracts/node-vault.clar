;; Node Vault - Main contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-stake u100000) ;; Minimum stake required
(define-constant err-unauthorized (err u100))
(define-constant err-insufficient-stake (err u101))
(define-constant err-node-exists (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-node-not-found (err u104))
(define-constant err-invalid-uptime (err u105))

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

;; Events
(define-data-var last-event-id uint u0)

(define-public (emit-node-event (event-type (string-ascii 20)) (node principal))
  (begin
    (var-set last-event-id (+ (var-get last-event-id) u1))
    (print {event-id: (var-get last-event-id), 
           type: event-type,
           node: node,
           block: block-height})))

;; Read-only functions
(define-read-only (get-node (node principal))
  (ok (map-get? nodes node)))

(define-read-only (is-valid-status (status (string-ascii 10)))
  (ok (asserts! (is-some (index-of (var-get valid-statuses) status)) err-invalid-status)))

;; Register new node
(define-public (register-node (stake uint))
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (>= stake min-stake) err-insufficient-stake)
    (asserts! (is-none node-data) err-node-exists)
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    (emit-node-event "register" tx-sender)
    (ok (map-set nodes 
      tx-sender
      {stake: stake,
       status: "pending",
       uptime: u100,
       rewards: u0}))))

;; Update node status
(define-public (update-status (node principal) (new-status (string-ascii 10)))
  (let ((node-data (map-get? nodes node)))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-some node-data) err-node-not-found)
    (try! (is-valid-status new-status))
    (emit-node-event "status-update" node)
    (ok (map-set nodes 
      node
      (merge (unwrap-panic node-data)
            {status: new-status})))))

;; Unregister node
(define-public (unregister-node)
  (let ((node-data (map-get? nodes tx-sender)))
    (asserts! (is-some node-data) err-node-not-found)
    (try! (as-contract (stx-transfer? 
      (get stake (unwrap-panic node-data))
      tx-sender
      tx-sender)))
    (emit-node-event "unregister" tx-sender)
    (ok (map-delete nodes tx-sender))))
