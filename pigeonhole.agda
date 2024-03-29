module pigeonhole where
  open import HoTT-UF-Agda public
  open import basic_logic public
  
  finset : ℕ → 𝓤₀ ̇
  finset zero     = 𝟘
  finset (succ n) = 𝟙 + (finset n)

  [_] = finset

  deq-sum : (A : 𝓤 ̇) → (B : 𝓥 ̇) → has-decidable-equality A
                                → has-decidable-equality B
                                → has-decidable-equality (A + B)
  deq-sum A B deqA _    (inl x) (inl y) = +-recursion (inl ∘ (ap inl))
                                                      (λ neq → inr (λ eq → neq (ap (λ {(inl z) → z; (inr _) → x}) eq)))
                                                      (deqA x y)
  deq-sum A B _    _    (inr x) (inl y) = inr (λ eq → transport (λ {(inl _) → 𝟘; (inr _) → 𝟙}) eq ⋆)
  deq-sum A B _    _    (inl x) (inr y) = inr (λ eq → transport (λ {(inl _) → 𝟙; (inr _) → 𝟘}) eq ⋆)
  deq-sum A B deqA deqB (inr x) (inr y) = +-recursion (inl ∘ (ap inr))
                                                      (λ neq → inr (λ eq → neq (ap (λ {(inl _) → x; (inr z) → z}) eq)))
                                                      (deqB x y)

  deq-plus-𝟙 : (A : 𝓤 ̇) → has-decidable-equality A
                        → has-decidable-equality (𝟙 + A)
  deq-plus-𝟙 A deqA = deq-sum 𝟙 A (λ x → λ y → inl (𝟙-is-subsingleton x y)) deqA

  deq-finset : (n : ℕ) → has-decidable-equality [ n ]
  deq-finset zero     = λ x → λ y → inl (𝟘-is-subsingleton x y)
  deq-finset (succ n) = deq-plus-𝟙 [ n ] (deq-finset n)

  open basic-arithmetic-and-order

  noninjective : {A : 𝓤 ̇} {B : 𝓥 ̇} (f : A → B) → (𝓤 ⊔ 𝓥) ̇
  noninjective f = Σ (λ t → (pr₁ t ≢ pr₂ t) × (f (pr₁ t) ≡ f (pr₂ t)))

  succ-not-≤ : (m : ℕ) → ¬ (succ m ≤ m)
  succ-not-≤ 0 leq        = leq
  succ-not-≤ (succ m) leq = succ-not-≤ m leq

  ≤-not-> : (m n : ℕ) → (m ≤ n) → ¬ (n < m)
  ≤-not-> m n leq sl = succ-not-≤ n (≤-trans (succ n) m n sl leq)

  pigeon-base : (m : ℕ) → (1 < m) → (f : [ m ] → 𝟘) → noninjective f
  pigeon-base 0 sl _ = ex-nihilo (≤-not-> 0 2 ⋆ sl) 
  pigeon-base 1 sl _ = ex-nihilo (≤-not-> 1 2 ⋆ sl)
  pigeon-base (succ (succ n)) _ f = ((x1 , x2) , (
                                                    (λ eq → transport (λ {(inl _) → 𝟙; (inr _) → 𝟘}) eq ⋆) ,
                                                    (𝟘-is-subsingleton (f x1) (f x2))
                                                 ))
                                  where x1 = inl ⋆
                                        x2 = inr (inl ⋆)

  data List {𝓤} (A : 𝓤 ̇) : 𝓤 ̇ where
    empty : List A
    append : A → List A → List A

  finset-fxn-to-list : {A : 𝓤 ̇} {n : ℕ} → (f : [ n ] → A) → List A
  finset-fxn-to-list {n = 0}        f = empty
  finset-fxn-to-list {n = (succ m)} f = append (f (inl ⋆)) (finset-fxn-to-list (f ∘ inr))

  list-has-value : {A : 𝓤 ̇} → (has-decidable-equality A) → List A → A → 𝓤₀ ̇
  list-has-value _    empty         _ = 𝟘
  list-has-value deqA (append a as) v = +-recursion (λ _ → 𝟙) (λ _ → list-has-value deqA as v) (deqA a v) 

  decide-list-has-value : {A : 𝓤 ̇} → (deqA : has-decidable-equality A) → (as : List A) → (v : A) → decidable (list-has-value deqA as v) 
  decide-list-has-value _ empty _ = inr id
  decide-list-has-value deqA (append a as) v = +-recursion (λ eq → inl (transport id ((χ-case1 eq (deqA a v)) ⁻¹) ⋆))
                                                           (λ neq → transport decidable ((χ-case2 neq (deqA a v)) ⁻¹) (decide-list-has-value deqA as v))
                                                           (deqA a v)

  decide-f-has-value : {A : 𝓤 ̇}
                          → (n : ℕ)
                          → (has-decidable-equality A)
                          → (f : [ n ] → A)
                          → (a : A)
                          → decidable (Σ (λ x → f x ≡ a))
  decide-f-has-value 0        _    _ _ = inr (ex-nihilo ∘ pr₁)
  decide-f-has-value (succ n) deqA f a = +-recursion
                                           (λ eq → inl (z , eq))
                                           (λ neq → +-recursion
                                             (λ hv → inl (inr (pr₁ hv) , pr₂ hv))
                                             (λ nv → inr (λ sol → +-induction
                                               (λ x → (f x ≡ a) → 𝟘)
                                               (λ lx → λ eq → neq (transport
                                                 (λ y → (f (inl y) ≡ a))
                                                 (𝟙-is-subsingleton lx ⋆)
                                                 eq))
                                               (λ rx → λ eq → nv (rx , eq))
                                               (pr₁ sol)
                                               (pr₂ sol)))
                                             (decide-f-has-value n deqA (f ∘ inr) a)
                                            )
                                            (deqA (f z) a)
                                       where z = inl ⋆

  decide-f0-repeated : {A : 𝓤 ̇}
                          → (n : ℕ)
                          → (has-decidable-equality A)
                          → (f : [ (succ n) ] → A)
                          → decidable (Σ (λ x → (f (inr x)) ≡ (f (inl ⋆))))
  decide-f0-repeated n deqA f = decide-f-has-value n deqA (f ∘ inr) (f (inl ⋆))

  fintree-splice : (n : ℕ) → [ (succ n) ] → [ n ] → [ (succ n) ]
  fintree-splice 0 _ ()
  fintree-splice (succ n) spl = +-recursion
                                  (λ _ → inr)
                                  (λ spl' → λ {(inl x) → inl ⋆; (inr x) → inr (fintree-splice n spl' x)})
                                  spl

  -- pigeonhole : (m n : ℕ) → (n < m) → (2 < m) → (f : [ m ] → [ n ]) → noninjective f
