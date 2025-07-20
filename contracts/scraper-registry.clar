;; Mint Scraper Registry Contract
;; Manages core registration and tracking of scraping references

(define-constant CONTRACT-OWNER tx-sender)

;; Errors
(define-constant ERR-NOT-AUTHORIZED (err u2000))
(define-constant ERR-REFERENCE-EXISTS (err u2001))
(define-constant ERR-REFERENCE-NOT-FOUND (err u2002))

;; Data Maps
(define-map scraping-references 
  { ref-id: (string-utf8 128) }
  { 
    hash: (buff 32), 
    version: (string-utf8 32), 
    metadata: (optional (string-utf8 256)),
    created-at: uint,
    last-updated: uint
  }
)

(define-map reference-owners 
  { ref-id: (string-utf8 128) }
  { owner: principal }
)

;; Register a new scraping reference
(define-public (register-reference 
  (ref-id (string-utf8 128)) 
  (hash (buff 32)) 
  (version (string-utf8 32)) 
  (metadata (optional (string-utf8 256)))
)
  (let ((current-timestamp (block-height)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! 
      (is-none (map-get? scraping-references { ref-id: ref-id })) 
      ERR-REFERENCE-EXISTS
    )
    (map-set scraping-references 
      { ref-id: ref-id }
      { 
        hash: hash, 
        version: version, 
        metadata: metadata,
        created-at: current-timestamp,
        last-updated: current-timestamp
      }
    )
    (map-set reference-owners 
      { ref-id: ref-id }
      { owner: tx-sender }
    )
    (ok true)
  )
)

;; Update an existing reference
(define-public (update-reference 
  (ref-id (string-utf8 128)) 
  (hash (buff 32)) 
  (version (string-utf8 32)) 
  (metadata (optional (string-utf8 256)))
)
  (let ((current-timestamp (block-height))
        (existing-ref (unwrap! 
          (map-get? scraping-references { ref-id: ref-id }) 
          ERR-REFERENCE-NOT-FOUND))
        (owner (unwrap! 
          (get owner (map-get? reference-owners { ref-id: ref-id })) 
          ERR-REFERENCE-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (map-set scraping-references 
      { ref-id: ref-id }
      { 
        hash: hash, 
        version: version, 
        metadata: metadata,
        created-at: (get created-at existing-ref),
        last-updated: current-timestamp
      }
    )
    (ok true)
  )
)

;; Share a reference with another user
(define-public (share-reference (ref-id (string-utf8 128)) (user principal))
  (let ((current-owner (unwrap! 
    (get owner (map-get? reference-owners { ref-id: ref-id })) 
    ERR-REFERENCE-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    (map-set reference-owners 
      { ref-id: ref-id }
      { owner: user }
    )
    (ok true)
  )
)

;; Verify reference ownership
(define-read-only (is-reference-owner (ref-id (string-utf8 128)) (user principal))
  (match (map-get? reference-owners { ref-id: ref-id })
    owner (is-eq (get owner owner) user)
    false
  )
)