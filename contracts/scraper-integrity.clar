;; Mint Scraper Integrity Management Contract
;; Ensures data integrity, verification, and conflict resolution

(define-constant CONTRACT-OWNER tx-sender)

;; Errors
(define-constant ERR-NOT-AUTHORIZED (err u3000))
(define-constant ERR-INVALID-HASH (err u3001))
(define-constant ERR-CONFLICT-EXISTS (err u3002))

;; Data Maps
(define-map data-hashes 
  { data-id: (string-utf8 36) }
  { 
    current-hash: (buff 32),
    device-id: (string-utf8 36),
    submitted-at: uint
  }
)

(define-map conflict-records 
  { data-id: (string-utf8 36) }
  { 
    conflicting-hashes: (list 5 (buff 32)),
    conflict-opened-at: uint
  }
)

;; Submit a new data hash
(define-public (submit-data-hash 
  (data-id (string-utf8 36)) 
  (hash (buff 32)) 
  (device-id (string-utf8 36))
)
  (let ((current-timestamp (block-height)))
    (match (map-get? data-hashes { data-id: data-id })
      existing-record 
        (if (not (is-eq (get current-hash existing-record) hash))
          (begin
            (map-set data-hashes 
              { data-id: data-id }
              { 
                current-hash: hash, 
                device-id: device-id, 
                submitted-at: current-timestamp 
              }
            )
            (ok true)
          )
          (err ERR-INVALID-HASH)
        )
      (begin
        (map-set data-hashes 
          { data-id: data-id }
          { 
            current-hash: hash, 
            device-id: device-id, 
            submitted-at: current-timestamp 
          }
        )
        (ok true)
      )
    )
  )
)

;; Verify data integrity
(define-public (verify-data 
  (data-id (string-utf8 36)) 
  (hash (buff 32)) 
  (proof (buff 128))
)
  (match (map-get? data-hashes { data-id: data-id })
    record 
      (if (is-eq (get current-hash record) hash)
        (ok true)
        (err ERR-INVALID-HASH)
      )
    (err ERR-INVALID-HASH)
  )
)

;; Resolve data conflicts
(define-public (resolve-conflict 
  (data-id (string-utf8 36)) 
  (selected-hash (buff 32))
)
  (match (map-get? conflict-records { data-id: data-id })
    conflict 
      (if (is-some (index-of (get conflicting-hashes conflict) selected-hash))
        (begin
          (map-delete conflict-records { data-id: data-id })
          (map-set data-hashes 
            { data-id: data-id }
            { 
              current-hash: selected-hash,
              device-id: (unwrap-panic (get device-id (map-get? data-hashes { data-id: data-id }))),
              submitted-at: (block-height)
            }
          )
          (ok true)
        )
        (err ERR-INVALID-HASH)
      )
    (err ERR-INVALID-HASH)
  )
)

;; Detect and track data conflicts
(define-public (detect-conflict 
  (data-id (string-utf8 36)) 
  (hash (buff 32))
)
  (match (map-get? data-hashes { data-id: data-id })
    existing-record
      (if (not (is-eq (get current-hash existing-record) hash))
        (begin
          (match (map-get? conflict-records { data-id: data-id })
            existing-conflict
              (map-set conflict-records 
                { data-id: data-id }
                { 
                  conflicting-hashes: (unwrap-panic (as-max-len? 
                    (append (get conflicting-hashes existing-conflict) hash) 
                    u5
                  )),
                  conflict-opened-at: (block-height)
                }
              )
            (map-set conflict-records 
              { data-id: data-id }
              { 
                conflicting-hashes: (list hash),
                conflict-opened-at: (block-height)
              }
            )
          )
          (ok true)
        )
        (err ERR-INVALID-HASH)
      )
    (err ERR-INVALID-HASH)
  )
)