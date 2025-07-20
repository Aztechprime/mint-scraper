;; Mint Scraper Metadata Management Contract
;; Tracks and manages metadata for scraped content

(define-constant CONTRACT-OWNER tx-sender)

;; Errors
(define-constant ERR-NOT-AUTHORIZED (err u4000))
(define-constant ERR-CONTENT-NOT-FOUND (err u4001))
(define-constant ERR-INVALID-VERSION (err u4002))

;; Data Maps
(define-map content-metadata 
  { content-id: (string-utf8 36) }
  { 
    title: (string-utf8 128), 
    content-type: (string-utf8 32), 
    total-size-bytes: uint,
    created-at: uint
  }
)

(define-map content-versions 
  { content-id: (string-utf8 36), version-number: uint }
  { 
    hash: (buff 32),
    device-id: (string-utf8 36),
    change-description: (string-utf8 256),
    version-size-bytes: uint,
    submitted-at: uint
  }
)

(define-map device-sync-status 
  { content-id: (string-utf8 36), device-id: (string-utf8 36) }
  { 
    latest-synced-version: uint,
    last-sync-timestamp: uint
  }
)

;; Create content metadata
(define-public (create-content-metadata 
  (content-id (string-utf8 36)) 
  (title (string-utf8 128)) 
  (content-type (string-utf8 32)) 
  (size-bytes uint)
)
  (let ((current-timestamp (block-height)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! 
      (is-none (map-get? content-metadata { content-id: content-id })) 
      ERR-CONTENT-NOT-FOUND
    )
    (map-set content-metadata 
      { content-id: content-id }
      { 
        title: title, 
        content-type: content-type, 
        total-size-bytes: size-bytes,
        created-at: current-timestamp
      }
    )
    (ok true)
  )
)

;; Add a new content version
(define-public (add-content-version 
  (content-id (string-utf8 36)) 
  (hash (buff 32)) 
  (device-id (string-utf8 36)) 
  (change-description (string-utf8 256)) 
  (size-bytes uint)
)
  (let ((current-timestamp (block-height))
        (next-version 
          (+ 
            (default-to u0 
              (get latest-synced-version 
                (map-get? device-sync-status { 
                  content-id: content-id, 
                  device-id: device-id 
                })
              )
            ) 
            u1
          )
        )
  )
    (asserts! (is-some (map-get? content-metadata { content-id: content-id })) ERR-CONTENT-NOT-FOUND)
    (map-set content-versions 
      { content-id: content-id, version-number: next-version }
      { 
        hash: hash,
        device-id: device-id,
        change-description: change-description,
        version-size-bytes: size-bytes,
        submitted-at: current-timestamp
      }
    )
    (map-set device-sync-status 
      { content-id: content-id, device-id: device-id }
      { 
        latest-synced-version: next-version,
        last-sync-timestamp: current-timestamp
      }
    )
    (ok true)
  )
)

;; Update sync status for a device
(define-public (update-sync-status 
  (content-id (string-utf8 36)) 
  (device-id (string-utf8 36)) 
  (synced-version uint)
)
  (let ((current-timestamp (block-height)))
    (asserts! 
      (is-some (map-get? content-metadata { content-id: content-id })) 
      ERR-CONTENT-NOT-FOUND
    )
    (map-set device-sync-status 
      { content-id: content-id, device-id: device-id }
      { 
        latest-synced-version: synced-version,
        last-sync-timestamp: current-timestamp
      }
    )
    (ok true)
  )
)

;; Retrieve content version details
(define-read-only (get-content-version 
  (content-id (string-utf8 36)) 
  (version-number uint)
)
  (map-get? content-versions { content-id: content-id, version-number: version-number })
)