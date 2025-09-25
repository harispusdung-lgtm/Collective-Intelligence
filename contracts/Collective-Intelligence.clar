;; Crowd-Intelligence-Enhanced AI Solver for Complex Innovation Challenges
;; A hybrid platform combining human crowd intelligence with AI assistance
;; to solve complex problems through collaborative innovation

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-CHALLENGE-NOT-FOUND (err u404))
(define-constant ERR-CONTRIBUTOR-NOT-FOUND (err u405))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-CHALLENGE-CLOSED (err u403))
(define-constant ERR-ALREADY-VOTED (err u406))
(define-constant ERR-INVALID-PHASE (err u407))
(define-constant ERR-AI-ANALYSIS-PENDING (err u408))
(define-constant ERR-INSUFFICIENT-VALIDATION (err u409))
(define-constant ERR-SOLUTION-NOT-FOUND (err u410))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Challenge phases
(define-constant PHASE-CROWD-INTELLIGENCE u1)
(define-constant PHASE-AI-ANALYSIS u2)
(define-constant PHASE-HYBRID-SYNTHESIS u3)
(define-constant PHASE-VALIDATION u4)
(define-constant PHASE-RESOLVED u5)

;; Validation thresholds
(define-constant MIN-VALIDATION-VOTES u5)
(define-constant CONSENSUS-THRESHOLD u70) ;; 70% consensus required

;; Data Maps

;; Challenge registry - stores all innovation challenges
(define-map challenges
  { challenge-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    reward: uint,
    created-at: uint,
    deadline: uint,
    phase: uint,
    status: (string-ascii 20),
    contribution-count: uint,
    ai-analysis-requested: bool,
    hybrid-solution-id: (optional uint),
    validation-votes-for: uint,
    validation-votes-against: uint,
    total-validation-votes: uint
  }
)

;; Crowd contributions - stores human intelligence inputs
(define-map contributions
  { challenge-id: uint, contributor: principal, contribution-id: uint }
  {
    content: (string-ascii 1000),
    expertise-area: (string-ascii 50),
    confidence-score: uint,
    submitted-at: uint,
    upvotes: uint,
    downvotes: uint,
    ai-relevance-score: (optional uint),
    tags: (list 10 (string-ascii 30))
  }
)

;; AI analysis results - stores AI processing of crowd contributions
(define-map ai-analysis
  { challenge-id: uint }
  {
    analyzed-at: uint,
    pattern-insights: (string-ascii 500),
    synthesized-approach: (string-ascii 500),
    confidence-rating: uint,
    key-themes: (list 10 (string-ascii 50)),
    recommended-next-steps: (string-ascii 300),
    contribution-rankings: (list 20 { contributor: principal, relevance: uint })
  }
)

;; Hybrid solutions - combines crowd intelligence with AI analysis
(define-map hybrid-solutions
  { solution-id: uint }
  {
    challenge-id: uint,
    crowd-elements: (list 10 (string-ascii 200)),
    ai-enhancements: (string-ascii 500),
    implementation-roadmap: (string-ascii 500),
    resource-requirements: (string-ascii 300),
    risk-assessment: (string-ascii 300),
    success-metrics: (string-ascii 300),
    created-at: uint,
    creator: principal,
    validation-score: uint
  }
)

;; Contributor profiles - tracks user engagement and expertise
(define-map contributor-profiles
  { contributor: principal }
  {
    reputation-score: uint,
    total-contributions: uint,
    successful-solutions: uint,
    expertise-domains: (list 10 (string-ascii 50)),
    joined-at: uint,
    last-active: uint,
    total-rewards-earned: uint,
    validation-accuracy: uint
  }
)

;; Validation votes - tracks community validation of solutions
(define-map validation-votes
  { solution-id: uint, validator: principal }
  {
    vote: bool, ;; true = approve, false = reject
    reasoning: (string-ascii 200),
    expertise-relevance: uint,
    voted-at: uint
  }
)

;; Challenge funding - tracks funding for challenges and rewards
(define-map challenge-funding
  { challenge-id: uint, funder: principal }
  {
    amount: uint,
    funded-at: uint,
    funding-type: (string-ascii 20) ;; "reward", "development", "research"
  }
)

;; Data variables for tracking global state
(define-data-var challenge-nonce uint u0)
(define-data-var contribution-nonce uint u0)
(define-data-var solution-nonce uint u0)
(define-data-var total-platform-funds uint u0)

;; Platform configuration
(define-data-var ai-oracle-address (optional principal) none)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee
(define-data-var min-challenge-reward uint u1000) ;; Minimum reward in microSTX

;; Public Functions

;; Create contributor profile
(define-public (create-contributor-profile (expertise-domains (list 10 (string-ascii 50))))
  (let
    (
      (contributor tx-sender)
    )
    (asserts! (is-none (map-get? contributor-profiles {contributor: contributor})) ERR-INVALID-INPUT)
    (ok (map-set contributor-profiles
      {contributor: contributor}
      {
        reputation-score: u100, ;; Starting reputation
        total-contributions: u0,
        successful-solutions: u0,
        expertise-domains: expertise-domains,
        joined-at: burn-block-height,
        last-active: burn-block-height,
        total-rewards-earned: u0,
        validation-accuracy: u100
      }
    ))
  )
)

;; Post a new innovation challenge
(define-public (post-challenge 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (reward uint)
  (deadline-blocks uint)
)
  (let
    (
      (challenge-id (+ (var-get challenge-nonce) u1))
      (creator tx-sender)
    )
    (asserts! (>= reward (var-get min-challenge-reward)) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> deadline-blocks burn-block-height) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u10) ERR-INVALID-INPUT)
    
    ;; Transfer reward to contract
    (try! (stx-transfer? reward creator (as-contract tx-sender)))
    
    ;; Create challenge
    (map-set challenges
      {challenge-id: challenge-id}
      {
        creator: creator,
        title: title,
        description: description,
        category: category,
        reward: reward,
        created-at: burn-block-height,
        deadline: deadline-blocks,
        phase: PHASE-CROWD-INTELLIGENCE,
        status: "open",
        contribution-count: u0,
        ai-analysis-requested: false,
        hybrid-solution-id: none,
        validation-votes-for: u0,
        validation-votes-against: u0,
        total-validation-votes: u0
      }
    )
    
    ;; Update platform funds
    (var-set total-platform-funds (+ (var-get total-platform-funds) reward))
    (var-set challenge-nonce challenge-id)
    
    (ok challenge-id)
  )
)

;; Submit crowd intelligence contribution
(define-public (submit-contribution
  (challenge-id uint)
  (content (string-ascii 1000))
  (expertise-area (string-ascii 50))
  (confidence-score uint)
  (tags (list 10 (string-ascii 30)))
)
  (let
    (
      (contributor tx-sender)
      (contribution-id (+ (var-get contribution-nonce) u1))
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
    )
    ;; Validate inputs
    (asserts! (is-eq (get status challenge) "open") ERR-CHALLENGE-CLOSED)
    (asserts! (is-eq (get phase challenge) PHASE-CROWD-INTELLIGENCE) ERR-INVALID-PHASE)
    (asserts! (> (len content) u10) ERR-INVALID-INPUT)
    (asserts! (<= confidence-score u100) ERR-INVALID-INPUT)
    (asserts! (< burn-block-height (get deadline challenge)) ERR-CHALLENGE-CLOSED)
    
    ;; Ensure contributor profile exists
    (asserts! (is-some (map-get? contributor-profiles {contributor: contributor})) ERR-CONTRIBUTOR-NOT-FOUND)
    
    ;; Add contribution
    (map-set contributions
      {challenge-id: challenge-id, contributor: contributor, contribution-id: contribution-id}
      {
        content: content,
        expertise-area: expertise-area,
        confidence-score: confidence-score,
        submitted-at: burn-block-height,
        upvotes: u0,
        downvotes: u0,
        ai-relevance-score: none,
        tags: tags
      }
    )
    
    ;; Update challenge contribution count
    (map-set challenges
      {challenge-id: challenge-id}
      (merge challenge {contribution-count: (+ (get contribution-count challenge) u1)})
    )
    
    ;; Update contributor profile
    (let
      (
        (profile (unwrap! (map-get? contributor-profiles {contributor: contributor}) ERR-CONTRIBUTOR-NOT-FOUND))
      )
      (map-set contributor-profiles
        {contributor: contributor}
        (merge profile {
          total-contributions: (+ (get total-contributions profile) u1),
          last-active: burn-block-height
        })
      )
    )
    
    (var-set contribution-nonce contribution-id)
    (ok contribution-id)
  )
)

;; Request AI analysis of crowd contributions
(define-public (trigger-ai-analysis (challenge-id uint))
  (let
    (
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
    )
    ;; Validate prerequisites
    (asserts! (is-eq (get phase challenge) PHASE-CROWD-INTELLIGENCE) ERR-INVALID-PHASE)
    (asserts! (>= (get contribution-count challenge) u3) ERR-INSUFFICIENT-VALIDATION) ;; Need at least 3 contributions
    (asserts! (not (get ai-analysis-requested challenge)) ERR-AI-ANALYSIS-PENDING)
    
    ;; Only challenge creator or contract owner can trigger AI analysis
    (asserts! (or (is-eq tx-sender (get creator challenge)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    
    ;; Update challenge to indicate AI analysis requested
    (map-set challenges
      {challenge-id: challenge-id}
      (merge challenge {
        phase: PHASE-AI-ANALYSIS,
        ai-analysis-requested: true
      })
    )
    
    ;; Note: In a real implementation, this would trigger an external AI oracle
    ;; For now, we'll simulate the AI analysis being completed immediately
    (try! (complete-ai-analysis challenge-id))
    
    (ok true)
  )
)

;; Internal function to complete AI analysis (simulated)
(define-private (complete-ai-analysis (challenge-id uint))
  (let
    (
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
    )
    ;; Simulate AI analysis results
    (map-set ai-analysis
      {challenge-id: challenge-id}
      {
        analyzed-at: burn-block-height,
        pattern-insights: "AI-identified patterns and trends from crowd contributions",
        synthesized-approach: "Recommended approach based on contribution analysis",
        confidence-rating: u85,
        key-themes: (list "innovation" "efficiency" "scalability" "sustainability" "user-experience"),
        recommended-next-steps: "Proceed with hybrid solution synthesis",
        contribution-rankings: (list)
      }
    )
    
    ;; Move to hybrid synthesis phase
    (map-set challenges
      {challenge-id: challenge-id}
      (merge challenge {phase: PHASE-HYBRID-SYNTHESIS})
    )
    
    (ok true)
  )
)

;; Submit hybrid solution combining crowd intelligence and AI insights
(define-public (submit-hybrid-solution
  (challenge-id uint)
  (crowd-elements (list 10 (string-ascii 200)))
  (ai-enhancements (string-ascii 500))
  (implementation-roadmap (string-ascii 500))
  (resource-requirements (string-ascii 300))
  (risk-assessment (string-ascii 300))
  (success-metrics (string-ascii 300))
)
  (let
    (
      (solution-id (+ (var-get solution-nonce) u1))
      (creator tx-sender)
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
    )
    ;; Validate prerequisites
    (asserts! (is-eq (get phase challenge) PHASE-HYBRID-SYNTHESIS) ERR-INVALID-PHASE)
    (asserts! (> (len crowd-elements) u0) ERR-INVALID-INPUT)
    (asserts! (> (len ai-enhancements) u10) ERR-INVALID-INPUT)
    (asserts! (> (len implementation-roadmap) u10) ERR-INVALID-INPUT)
    
    ;; Ensure AI analysis exists
    (asserts! (is-some (map-get? ai-analysis {challenge-id: challenge-id})) ERR-AI-ANALYSIS-PENDING)
    
    ;; Create hybrid solution
    (map-set hybrid-solutions
      {solution-id: solution-id}
      {
        challenge-id: challenge-id,
        crowd-elements: crowd-elements,
        ai-enhancements: ai-enhancements,
        implementation-roadmap: implementation-roadmap,
        resource-requirements: resource-requirements,
        risk-assessment: risk-assessment,
        success-metrics: success-metrics,
        created-at: burn-block-height,
        creator: creator,
        validation-score: u0
      }
    )
    
    ;; Update challenge with solution and move to validation phase
    (map-set challenges
      {challenge-id: challenge-id}
      (merge challenge {
        phase: PHASE-VALIDATION,
        hybrid-solution-id: (some solution-id)
      })
    )
    
    (var-set solution-nonce solution-id)
    (ok solution-id)
  )
)

;; Vote on hybrid solution validation
(define-public (vote-on-solution
  (solution-id uint)
  (approve bool)
  (reasoning (string-ascii 200))
  (expertise-relevance uint)
)
  (let
    (
      (validator tx-sender)
      (solution (unwrap! (map-get? hybrid-solutions {solution-id: solution-id}) ERR-SOLUTION-NOT-FOUND))
      (challenge-id (get challenge-id solution))
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
    )
    ;; Validate prerequisites
    (asserts! (is-eq (get phase challenge) PHASE-VALIDATION) ERR-INVALID-PHASE)
    (asserts! (<= expertise-relevance u100) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? validation-votes {solution-id: solution-id, validator: validator})) ERR-ALREADY-VOTED)
    
    ;; Ensure validator profile exists
    (asserts! (is-some (map-get? contributor-profiles {contributor: validator})) ERR-CONTRIBUTOR-NOT-FOUND)
    
    ;; Record vote
    (map-set validation-votes
      {solution-id: solution-id, validator: validator}
      {
        vote: approve,
        reasoning: reasoning,
        expertise-relevance: expertise-relevance,
        voted-at: burn-block-height
      }
    )
    
    ;; Update challenge vote counts
    (let
      (
        (new-total-votes (+ (get total-validation-votes challenge) u1))
        (new-votes-for (if approve (+ (get validation-votes-for challenge) u1) (get validation-votes-for challenge)))
        (new-votes-against (if (not approve) (+ (get validation-votes-against challenge) u1) (get validation-votes-against challenge)))
      )
      (begin
        (map-set challenges
          {challenge-id: challenge-id}
          (merge challenge {
            total-validation-votes: new-total-votes,
            validation-votes-for: new-votes-for,
            validation-votes-against: new-votes-against
          })
        )
        
        ;; Check if we have enough votes to resolve and trigger resolution if needed
        (if (>= new-total-votes MIN-VALIDATION-VOTES)
          (check-and-resolve-challenge challenge-id)
          (ok true)
        )
      )
    )
  )
)

;; Internal function to check validation consensus and resolve challenge
(define-private (check-and-resolve-challenge (challenge-id uint))
  (let
    (
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
      (total-votes (get total-validation-votes challenge))
      (votes-for (get validation-votes-for challenge))
      (consensus-percentage (/ (* votes-for u100) total-votes))
    )
    (if (>= consensus-percentage CONSENSUS-THRESHOLD)
      (begin
        ;; Solution approved - resolve challenge
        (map-set challenges
          {challenge-id: challenge-id}
          (merge challenge {
            phase: PHASE-RESOLVED,
            status: "resolved"
          })
        )
        
        ;; Distribute rewards
        (try! (distribute-challenge-rewards challenge-id))
        (ok true)
      )
      (begin
        ;; Solution rejected - back to synthesis phase
        (map-set challenges
          {challenge-id: challenge-id}
          (merge challenge {
            phase: PHASE-HYBRID-SYNTHESIS,
            hybrid-solution-id: none,
            validation-votes-for: u0,
            validation-votes-against: u0,
            total-validation-votes: u0
          })
        )
        (ok false)
      )
    )
  )
)

;; Internal function to distribute rewards
(define-private (distribute-challenge-rewards (challenge-id uint))
  (let
    (
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
      (total-reward (get reward challenge))
      (platform-fee (/ (* total-reward (var-get platform-fee-percentage)) u100))
      (remaining-reward (- total-reward platform-fee))
      (solution-id (unwrap! (get hybrid-solution-id challenge) ERR-SOLUTION-NOT-FOUND))
      (solution (unwrap! (map-get? hybrid-solutions {solution-id: solution-id}) ERR-SOLUTION-NOT-FOUND))
      (solution-creator (get creator solution))
    )
    ;; Transfer 60% to solution creator
    (let ((creator-reward (/ (* remaining-reward u60) u100)))
      (try! (as-contract (stx-transfer? creator-reward tx-sender solution-creator)))
      
      ;; Update creator profile
      (let
        (
          (profile (unwrap! (map-get? contributor-profiles {contributor: solution-creator}) ERR-CONTRIBUTOR-NOT-FOUND))
        )
        (map-set contributor-profiles
          {contributor: solution-creator}
          (merge profile {
            successful-solutions: (+ (get successful-solutions profile) u1),
            total-rewards-earned: (+ (get total-rewards-earned profile) creator-reward),
            reputation-score: (+ (get reputation-score profile) u50)
          })
        )
      )
    )
    
    ;; Remaining 40% could be distributed to top contributors
    ;; For simplicity, we'll keep it in the contract for now
    (var-set total-platform-funds (- (var-get total-platform-funds) total-reward))
    
    (ok true)
  )
)

;; Add funding to a challenge
(define-public (add-challenge-funding
  (challenge-id uint)
  (amount uint)
  (funding-type (string-ascii 20))
)
  (let
    (
      (funder tx-sender)
      (challenge (unwrap! (map-get? challenges {challenge-id: challenge-id}) ERR-CHALLENGE-NOT-FOUND))
    )
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (not (is-eq (get status challenge) "resolved")) ERR-CHALLENGE-CLOSED)
    
    ;; Transfer funds to contract
    (try! (stx-transfer? amount funder (as-contract tx-sender)))
    
    ;; Record funding
    (map-set challenge-funding
      {challenge-id: challenge-id, funder: funder}
      {
        amount: amount,
        funded-at: burn-block-height,
        funding-type: funding-type
      }
    )
    
    ;; Update challenge reward if it's reward funding
    (if (is-eq funding-type "reward")
      (map-set challenges
        {challenge-id: challenge-id}
        (merge challenge {reward: (+ (get reward challenge) amount)})
      )
      true
    )
    
    (var-set total-platform-funds (+ (var-get total-platform-funds) amount))
    (ok true)
  )
)

;; Read-only functions for data retrieval

;; Get challenge details
(define-read-only (get-challenge (challenge-id uint))
  (map-get? challenges {challenge-id: challenge-id})
)

;; Get contributor profile
(define-read-only (get-contributor-profile (contributor principal))
  (map-get? contributor-profiles {contributor: contributor})
)

;; Get contribution details
(define-read-only (get-contribution (challenge-id uint) (contributor principal) (contribution-id uint))
  (map-get? contributions {challenge-id: challenge-id, contributor: contributor, contribution-id: contribution-id})
)

;; Get AI analysis for a challenge
(define-read-only (get-ai-analysis (challenge-id uint))
  (map-get? ai-analysis {challenge-id: challenge-id})
)

;; Get hybrid solution details
(define-read-only (get-hybrid-solution (solution-id uint))
  (map-get? hybrid-solutions {solution-id: solution-id})
)

;; Get validation vote
(define-read-only (get-validation-vote (solution-id uint) (validator principal))
  (map-get? validation-votes {solution-id: solution-id, validator: validator})
)

;; Get challenge funding details
(define-read-only (get-challenge-funding (challenge-id uint) (funder principal))
  (map-get? challenge-funding {challenge-id: challenge-id, funder: funder})
)

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-challenges: (var-get challenge-nonce),
    total-contributions: (var-get contribution-nonce),
    total-solutions: (var-get solution-nonce),
    platform-funds: (var-get total-platform-funds),
    min-challenge-reward: (var-get min-challenge-reward),
    platform-fee-percentage: (var-get platform-fee-percentage)
  }
)

;; Administrative functions (contract owner only)

;; Update AI oracle address
(define-public (set-ai-oracle (oracle-address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set ai-oracle-address (some oracle-address))
    (ok true)
  )
)

;; Update platform fee
(define-public (set-platform-fee (fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= fee-percentage u20) ERR-INVALID-INPUT) ;; Max 20% fee
    (var-set platform-fee-percentage fee-percentage)
    (ok true)
  )
)

;; Update minimum challenge reward
(define-public (set-min-challenge-reward (min-reward uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> min-reward u0) ERR-INVALID-INPUT)
    (var-set min-challenge-reward min-reward)
    (ok true)
  )
)

;; Emergency pause/unpause functionality
(define-data-var contract-paused bool false)

(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

;; Helper function to check if contract is operational
(define-private (assert-contract-operational)
  (begin
    (asserts! (not (var-get contract-paused)) (err u500))
    (ok true)
  )
)

;; Initialize contract with default settings
(define-private (initialize-contract)
  (begin
    (var-set ai-oracle-address none)
    (var-set platform-fee-percentage u5)
    (var-set min-challenge-reward u1000)
    (var-set contract-paused false)
    (ok true)
  )
)

;; Contract initialization
(begin
  (initialize-contract)
)
