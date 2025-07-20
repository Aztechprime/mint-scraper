;; Mint Scraper Permission Management Contract
;; Controls access, authorization, and device management for the mint scraper system

(define-constant CONTRACT-OWNER tx-sender)

;; Errors
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-DEVICE-ALREADY-REGISTERED (err u1001))
(define-constant ERR-DEVICE-NOT-FOUND (err u1002))

;; Data Maps
(define-map authorized-devices 
  { user: principal, device-id: (string-utf8 36) }
  { device-name: (string-utf8 64), registered-at: uint }
)

(define-map device-ownership 
  { device-id: (string-utf8 36) }
  { owner: principal }
)

;; Check if a device is authorized
(define-read-only (is-device-authorized (user principal) (device-id (string-utf8 36)))
  (is-some (map-get? authorized-devices { user: user, device-id: device-id }))
)

;; Register a new device
(define-public (register-device (device-id (string-utf8 36)) (device-name (string-utf8 64)))
  (let ((current-timestamp (block-height)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! 
      (is-none (map-get? authorized-devices { user: tx-sender, device-id: device-id })) 
      ERR-DEVICE-ALREADY-REGISTERED
    )
    (map-set authorized-devices 
      { user: tx-sender, device-id: device-id }
      { device-name: device-name, registered-at: current-timestamp }
    )
    (map-set device-ownership 
      { device-id: device-id }
      { owner: tx-sender }
    )
    (ok true)
  )
)

;; Transfer device ownership
(define-public (transfer-device-ownership 
  (device-id (string-utf8 36)) 
  (new-owner principal)
)
  (let ((current-owner (unwrap! 
    (get owner (map-get? device-ownership { device-id: device-id })) 
    ERR-DEVICE-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    (map-set device-ownership 
      { device-id: device-id }
      { owner: new-owner }
    )
    (ok true)
  )
)

;; Revoke device authorization
(define-public (revoke-device (device-id (string-utf8 36)))
  (let ((device-owner (unwrap! 
    (get owner (map-get? device-ownership { device-id: device-id })) 
    ERR-DEVICE-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender device-owner) ERR-NOT-AUTHORIZED)
    (map-delete authorized-devices { user: device-owner, device-id: device-id })
    (map-delete device-ownership { device-id: device-id })
    (ok true)
  )
)