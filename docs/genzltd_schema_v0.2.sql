SET client_encoding TO 'UTF8';

-- GenzLTD 业务库 v0.2（对齐真源 manager.py，49 表）
DROP TABLE IF EXISTS attestation_evidence, trust_audit_log, attestations,
    share_codes, trust_memories, game_profiles, user_identities, users CASCADE;
DROP TYPE IF EXISTS claim_type, evidence_type, verify_status, acct_provider,
    identity_state, px_identity, tier CASCADE;

CREATE TABLE users (
    id                TEXT PRIMARY KEY,
    email             TEXT UNIQUE,
    email_hash        TEXT,
    password_hash     TEXT,
    wechat_openid     TEXT UNIQUE,
    supabase_uid      TEXT UNIQUE,
    name              TEXT DEFAULT '',
    tier              TEXT DEFAULT 'free',
    role              TEXT DEFAULT 'user',
    is_early_adopter  INTEGER DEFAULT 0,
    created_at        TIMESTAMPTZ DEFAULT now(),
    updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_wechat_openid ON users(wechat_openid);
CREATE INDEX idx_users_email_hash ON users(email_hash);
CREATE UNIQUE INDEX idx_users_supabase_uid ON users(supabase_uid);

CREATE TABLE user_identities (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id),
    provider        TEXT NOT NULL,
    provider_uid    TEXT NOT NULL,
    provider_email  TEXT,
    provider_name   TEXT,
    metadata_json   TEXT DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(provider, provider_uid)
);
CREATE INDEX idx_user_identities_user ON user_identities(user_id);
CREATE INDEX idx_user_identities_provider ON user_identities(provider, provider_uid);

CREATE TABLE game_profiles (
    id                  TEXT PRIMARY KEY,
    user_id             TEXT NOT NULL REFERENCES users(id),
    identity            TEXT,
    personality_type    TEXT,
    personality_detail  TEXT,
    xp                  INTEGER DEFAULT 0,
    level               INTEGER DEFAULT 1,
    updated_at          TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);
CREATE INDEX idx_game_profiles_user ON game_profiles(user_id);

CREATE TABLE fleets (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    captain_id  TEXT NOT NULL REFERENCES users(id),
    description TEXT DEFAULT '',
    invite_code TEXT UNIQUE,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE fleet_members (
    id        TEXT PRIMARY KEY,
    fleet_id  TEXT NOT NULL REFERENCES fleets(id),
    user_id   TEXT NOT NULL REFERENCES users(id),
    joined_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(fleet_id, user_id)
);
CREATE INDEX idx_fleet_members_user ON fleet_members(user_id);

CREATE TABLE mission_completions (
    id           TEXT PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES users(id),
    mission_id   TEXT NOT NULL,
    xp_reward    INTEGER DEFAULT 0,
    completed_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, mission_id)
);
CREATE INDEX idx_missions_user ON mission_completions(user_id);

CREATE TABLE trust_memories (
    id             TEXT PRIMARY KEY,
    user_id        TEXT NOT NULL REFERENCES users(id),
    session_type   TEXT NOT NULL,
    session_id     TEXT NOT NULL,
    memory_content TEXT NOT NULL,
    memory_level   INTEGER DEFAULT 1,
    created_at     TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_trust_memories_user ON trust_memories(user_id);
CREATE INDEX idx_trust_memories_session ON trust_memories(session_type, session_id);

CREATE TABLE trust_attestations (
    id                  TEXT PRIMARY KEY,
    candidate_id        TEXT NOT NULL REFERENCES users(id),
    claim_type          TEXT NOT NULL,
    claim_statement     TEXT NOT NULL,
    evidence_type       TEXT NOT NULL,
    evidence_refs       TEXT DEFAULT '[]',
    verification_status TEXT DEFAULT 'unverified',
    confidence_score    DOUBLE PRECISION DEFAULT 0.0,
    generated_by        TEXT DEFAULT 'trust_agent_v0',
    signature           TEXT DEFAULT '',
    expires_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT now(),
    updated_at          TIMESTAMPTZ DEFAULT now(),
    UNIQUE(candidate_id, claim_type)
);
CREATE INDEX idx_trust_attestations_candidate ON trust_attestations(candidate_id);
CREATE INDEX idx_trust_attestations_type ON trust_attestations(claim_type, verification_status);

CREATE TABLE signal_ingest (
    signal_type      TEXT NOT NULL,
    user_email_hash  TEXT NOT NULL,
    nonce            TEXT NOT NULL,
    payload_json     TEXT,
    created_at       TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (signal_type, user_email_hash, nonce)
);

CREATE TABLE match_consensus (
    id           TEXT PRIMARY KEY,
    fleet_id     TEXT NOT NULL,
    initiator_id TEXT NOT NULL REFERENCES users(id),
    candidate_id TEXT NOT NULL REFERENCES users(id),
    match_score  INTEGER NOT NULL,
    status       TEXT DEFAULT 'pending',
    reason       TEXT DEFAULT '',
    created_at   TIMESTAMPTZ DEFAULT now(),
    verified_at  TIMESTAMPTZ,
    expires_at   TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_match_consensus_initiator ON match_consensus(initiator_id, status);
CREATE INDEX idx_match_consensus_candidate ON match_consensus(candidate_id, status);

-- ============ 企业 / 招聘 ============
CREATE TABLE enterprises (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    domain     TEXT,
    plan       TEXT DEFAULT 'free',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE enterprise_users (
    id            TEXT PRIMARY KEY,
    enterprise_id TEXT NOT NULL REFERENCES enterprises(id),
    user_id       TEXT NOT NULL REFERENCES users(id),
    role          TEXT DEFAULT 'member',
    created_at    TIMESTAMPTZ DEFAULT now(),
    UNIQUE(enterprise_id, user_id)
);
CREATE INDEX idx_enterprise_users_enterprise ON enterprise_users(enterprise_id);
CREATE INDEX idx_enterprise_users_user ON enterprise_users(user_id);

CREATE TABLE candidates (
    id            TEXT PRIMARY KEY,
    enterprise_id TEXT NOT NULL REFERENCES enterprises(id),
    user_id       TEXT REFERENCES users(id),
    name          TEXT NOT NULL,
    email         TEXT,
    phone         TEXT,
    status        TEXT DEFAULT 'new',
    profile_data  TEXT,
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_candidates_enterprise ON candidates(enterprise_id);

CREATE TABLE job_posts (
    id           TEXT PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES users(id),
    title        TEXT NOT NULL,
    company      TEXT DEFAULT '',
    description  TEXT DEFAULT '',
    requirements TEXT DEFAULT '',
    status       TEXT DEFAULT 'active',
    created_at   TIMESTAMPTZ DEFAULT now(),
    updated_at   TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_job_posts_user ON job_posts(user_id);
CREATE INDEX idx_job_posts_status ON job_posts(user_id, status);

CREATE TABLE applications (
    id             TEXT PRIMARY KEY,
    seeker_user_id TEXT NOT NULL REFERENCES users(id),
    resume_id      TEXT NOT NULL,
    job_id         TEXT NOT NULL,
    enterprise_id  TEXT DEFAULT '',
    status         TEXT DEFAULT 'submitted',
    metadata       TEXT DEFAULT '{}',
    created_at     TIMESTAMPTZ NOT NULL,
    updated_at     TIMESTAMPTZ NOT NULL,
    withdrawn_at   TIMESTAMPTZ
);
CREATE INDEX idx_applications_seeker ON applications(seeker_user_id);
CREATE INDEX idx_applications_job ON applications(job_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE UNIQUE INDEX idx_applications_active_unique
    ON applications(seeker_user_id, resume_id, job_id) WHERE status = 'submitted';

CREATE TABLE sales_inquiries (
    id            TEXT PRIMARY KEY,
    user_id       TEXT REFERENCES users(id),
    company_name  TEXT NOT NULL,
    contact_name  TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    contact_phone TEXT DEFAULT '',
    scale         TEXT DEFAULT '',
    message       TEXT DEFAULT '',
    status        TEXT DEFAULT 'new',
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_sales_inquiries_status ON sales_inquiries(status);

-- ============ 支付 ============
CREATE TABLE orders (
    id             TEXT PRIMARY KEY,
    user_id        TEXT NOT NULL REFERENCES users(id),
    plan_id        TEXT NOT NULL,
    tier           TEXT NOT NULL,
    amount         DOUBLE PRECISION NOT NULL,
    currency       TEXT NOT NULL DEFAULT 'CNY',
    out_trade_no   TEXT UNIQUE NOT NULL,
    transaction_id TEXT,
    status         TEXT DEFAULT 'pending',
    prepay_id      TEXT,
    qr_code_url    TEXT,
    metadata_json  TEXT DEFAULT '{}',
    created_at     TIMESTAMPTZ DEFAULT now(),
    paid_at        TIMESTAMPTZ
);
CREATE INDEX idx_orders_user ON orders(user_id, created_at);
CREATE INDEX idx_orders_trade_no ON orders(out_trade_no);
CREATE INDEX idx_orders_status ON orders(status);

CREATE TABLE subscriptions (
    id                   TEXT PRIMARY KEY,
    user_id              TEXT NOT NULL UNIQUE REFERENCES users(id),
    tier                 TEXT NOT NULL,
    plan_id              TEXT NOT NULL,
    status               TEXT DEFAULT 'active',
    started_at           TIMESTAMPTZ DEFAULT now(),
    expires_at           TIMESTAMPTZ NOT NULL,
    auto_renew           INTEGER DEFAULT 0,
    cancel_at_period_end INTEGER DEFAULT 0,
    created_at           TIMESTAMPTZ DEFAULT now(),
    updated_at           TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_expires ON subscriptions(expires_at);

-- ============ 推送 / 增长 / 用量 ============
CREATE TABLE huawei_push_tokens (
    id         BIGSERIAL PRIMARY KEY,
    user_id    TEXT NOT NULL REFERENCES users(id),
    push_token TEXT NOT NULL,
    created_at BIGINT DEFAULT (EXTRACT(EPOCH FROM now()))::bigint
);
CREATE UNIQUE INDEX idx_push_token ON huawei_push_tokens(push_token);
CREATE INDEX idx_push_user ON huawei_push_tokens(user_id);

CREATE TABLE invite_codes (
    id         TEXT PRIMARY KEY,
    code       TEXT UNIQUE NOT NULL,
    created_by TEXT REFERENCES users(id),
    used_by    TEXT REFERENCES users(id),
    tier_grant TEXT DEFAULT 'free',
    expires_at TIMESTAMPTZ,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_invite_codes_code ON invite_codes(code);

CREATE TABLE usage_logs (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id),
    endpoint    TEXT NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_usage_logs_user_date ON usage_logs(user_id, created_at);

CREATE TABLE llm_usage (
    id         TEXT PRIMARY KEY,
    user_id    TEXT,
    provider   TEXT NOT NULL,
    model      TEXT NOT NULL,
    tokens_in  INTEGER DEFAULT 0,
    tokens_out INTEGER DEFAULT 0,
    cost_yuan  DOUBLE PRECISION DEFAULT 0,
    latency_ms INTEGER DEFAULT 0,
    status     TEXT DEFAULT 'ok',
    error      TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_llm_usage_provider_date ON llm_usage(provider, created_at);
CREATE INDEX idx_llm_usage_user_date ON llm_usage(user_id, created_at);

CREATE TABLE quota_records (
    id          BIGSERIAL PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id),
    resource    TEXT NOT NULL,
    date        TEXT NOT NULL,
    used        INTEGER DEFAULT 0,
    daily_limit INTEGER NOT NULL,
    UNIQUE(user_id, resource, date)
);
CREATE INDEX idx_quota_records_user ON quota_records(user_id, resource, date);

CREATE TABLE boost_packs (
    id           BIGSERIAL PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES users(id),
    pack_name    TEXT NOT NULL DEFAULT '标准加量包',
    credits      INTEGER NOT NULL,
    credits_used INTEGER DEFAULT 0,
    price_yuan   INTEGER DEFAULT 29,
    purchased_at TIMESTAMPTZ DEFAULT now(),
    expires_at   TIMESTAMPTZ NOT NULL,
    status       TEXT DEFAULT 'active'
);
CREATE INDEX idx_boost_packs_user ON boost_packs(user_id, status);
CREATE INDEX idx_boost_packs_expires ON boost_packs(expires_at);

CREATE TABLE boost_consumptions (
    id               BIGSERIAL PRIMARY KEY,
    user_id          TEXT NOT NULL REFERENCES users(id),
    boost_pack_id    INTEGER NOT NULL REFERENCES boost_packs(id),
    resource         TEXT NOT NULL,
    credits_consumed INTEGER DEFAULT 1,
    consumed_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_boost_consumptions_user ON boost_consumptions(user_id);

-- ============ 诗词 / 知识库 ============
CREATE TABLE poems (
    id         BIGSERIAL PRIMARY KEY,
    title      TEXT NOT NULL,
    author     TEXT NOT NULL DEFAULT '',
    dynasty    TEXT NOT NULL DEFAULT '',
    theme      TEXT NOT NULL DEFAULT '',
    content    TEXT NOT NULL,
    tags       TEXT DEFAULT '',
    source     TEXT DEFAULT 'imported',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(title, author)
);
CREATE INDEX idx_poems_dynasty ON poems(dynasty);
CREATE INDEX idx_poems_author ON poems(author);
CREATE INDEX idx_poems_theme ON poems(theme);
CREATE INDEX idx_poems_title ON poems(title);

CREATE TABLE challenge_rounds (
    id         BIGSERIAL PRIMARY KEY,
    week_key   TEXT NOT NULL UNIQUE,
    poem_id    INTEGER NOT NULL REFERENCES poems(id),
    title      TEXT NOT NULL DEFAULT '',
    status     TEXT NOT NULL DEFAULT 'open',
    starts_at  TIMESTAMPTZ NOT NULL,
    ends_at    TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_challenge_rounds_status ON challenge_rounds(status);
CREATE INDEX idx_challenge_rounds_ends ON challenge_rounds(ends_at);

CREATE TABLE challenge_entries (
    id               BIGSERIAL PRIMARY KEY,
    round_id         INTEGER NOT NULL REFERENCES challenge_rounds(id),
    user_id          TEXT NOT NULL REFERENCES users(id),
    translation      TEXT NOT NULL,
    note             TEXT NOT NULL DEFAULT '',
    license_accepted INTEGER NOT NULL DEFAULT 0,
    vote_count       INTEGER NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ DEFAULT now(),
    updated_at       TIMESTAMPTZ DEFAULT now(),
    UNIQUE(round_id, user_id)
);
CREATE INDEX idx_challenge_entries_round ON challenge_entries(round_id);

CREATE TABLE documents (
    id           BIGSERIAL PRIMARY KEY,
    title        TEXT NOT NULL,
    file_path    TEXT NOT NULL UNIQUE,
    doc_type     TEXT NOT NULL,
    file_size    INTEGER DEFAULT 0,
    metadata     TEXT DEFAULT '{}',
    status       TEXT DEFAULT 'pending',
    chunk_count  INTEGER DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL,
    processed_at TIMESTAMPTZ
);
CREATE INDEX idx_documents_status ON documents(status);

CREATE TABLE chunks (
    id          BIGSERIAL PRIMARY KEY,
    document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content     TEXT NOT NULL,
    char_count  INTEGER DEFAULT 0,
    metadata    TEXT DEFAULT '{}',
    created_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_chunks_document ON chunks(document_id);

CREATE TABLE query_logs (
    id               BIGSERIAL PRIMARY KEY,
    query_text       TEXT NOT NULL,
    provider         TEXT NOT NULL,
    response_time_ms DOUBLE PRECISION DEFAULT 0,
    chunk_count      INTEGER DEFAULT 0,
    rating           INTEGER,
    intent_label     TEXT,
    user_id          TEXT,
    created_at       TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_query_logs_time ON query_logs(created_at);
CREATE INDEX idx_query_logs_user ON query_logs(user_id);

-- ============ 叙事 / 领域引擎 / 埋点 ============
CREATE TABLE narrative_sessions (
    id               TEXT PRIMARY KEY,
    user_id          TEXT REFERENCES users(id),
    domain           TEXT NOT NULL,
    status           TEXT DEFAULT 'active',
    duration_seconds DOUBLE PRECISION DEFAULT 0,
    started_at       TIMESTAMPTZ DEFAULT now(),
    ended_at         TIMESTAMPTZ
);
CREATE INDEX idx_narrative_sessions_user ON narrative_sessions(user_id);
CREATE INDEX idx_narrative_sessions_domain ON narrative_sessions(domain);

CREATE TABLE narrative_events (
    id             BIGSERIAL PRIMARY KEY,
    session_id     TEXT NOT NULL REFERENCES narrative_sessions(id),
    event_type     TEXT NOT NULL,
    domain         TEXT,
    choice         TEXT,
    navigator_line TEXT,
    metadata_json  TEXT DEFAULT '{}',
    created_at     TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_narrative_events_session ON narrative_events(session_id);
CREATE INDEX idx_narrative_events_type ON narrative_events(event_type);

CREATE TABLE narrative_feedback (
    id              BIGSERIAL PRIMARY KEY,
    session_id      TEXT NOT NULL REFERENCES narrative_sessions(id),
    resonated       INTEGER NOT NULL DEFAULT 0,
    navigator_quote TEXT,
    would_replay    INTEGER,
    shared          INTEGER NOT NULL DEFAULT 0,
    share_channel   TEXT,
    open_feedback   TEXT,
    created_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(session_id)
);
CREATE INDEX idx_narrative_feedback_session ON narrative_feedback(session_id);

CREATE TABLE value_imprints (
    user_id    TEXT PRIMARY KEY REFERENCES users(id),
    survival   INTEGER NOT NULL DEFAULT 0,
    freedom    INTEGER NOT NULL DEFAULT 0,
    belonging  INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE navigator_memories (
    id               BIGSERIAL PRIMARY KEY,
    user_id          TEXT NOT NULL REFERENCES users(id),
    memory_level     TEXT NOT NULL,
    content          TEXT NOT NULL,
    context          TEXT,
    domain           TEXT,
    choice           TEXT,
    importance       DOUBLE PRECISION DEFAULT 1.0,
    referenced_count INTEGER DEFAULT 0,
    session_id       TEXT,
    created_at       TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_navigator_memories_user ON navigator_memories(user_id);
CREATE INDEX idx_navigator_memories_level ON navigator_memories(memory_level);

CREATE TABLE emergent_strategy_log (
    id            BIGSERIAL PRIMARY KEY,
    user_id       TEXT NOT NULL REFERENCES users(id),
    strategy_type TEXT NOT NULL,
    triggered_at  TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_emergent_strategy_user ON emergent_strategy_log(user_id);

CREATE TABLE domain_visits (
    id                BIGSERIAL PRIMARY KEY,
    user_id           TEXT NOT NULL REFERENCES users(id),
    session_id        TEXT NOT NULL REFERENCES narrative_sessions(id),
    domain            TEXT NOT NULL,
    previous_domain   TEXT,
    interaction_level TEXT,
    echo_triggered    INTEGER NOT NULL DEFAULT 0,
    entered_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_domain_visits_user ON domain_visits(user_id);
CREATE INDEX idx_domain_visits_session ON domain_visits(session_id);

CREATE TABLE product_events (
    id              BIGSERIAL PRIMARY KEY,
    event_name      TEXT NOT NULL,
    user_id         TEXT,
    session_id      TEXT,
    platform        TEXT DEFAULT 'unknown',
    share_code      TEXT,
    source          TEXT DEFAULT 'client',
    success         INTEGER NOT NULL DEFAULT 1,
    properties_json TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_product_events_name ON product_events(event_name);
CREATE INDEX idx_product_events_created ON product_events(created_at);
CREATE INDEX idx_product_events_share ON product_events(share_code);

CREATE TABLE micro_feedback (
    id            BIGSERIAL PRIMARY KEY,
    context       TEXT NOT NULL,
    score         INTEGER NOT NULL,
    optional_text TEXT,
    user_id       TEXT,
    session_id    TEXT,
    platform      TEXT DEFAULT 'unknown',
    share_code    TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_micro_feedback_context ON micro_feedback(context);

CREATE TABLE act1_sessions (
    session_id TEXT PRIMARY KEY REFERENCES narrative_sessions(id),
    state_json TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============ 合规 / 答题 / 匹配 ============
CREATE TABLE consents (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id),
    scope       TEXT NOT NULL,
    purpose     TEXT DEFAULT '',
    status      TEXT DEFAULT 'granted',
    ip          TEXT DEFAULT '',
    user_agent  TEXT DEFAULT '',
    granted_at  TIMESTAMPTZ DEFAULT now(),
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);
CREATE UNIQUE INDEX idx_consents_active ON consents(user_id, scope) WHERE status='granted';
CREATE INDEX idx_consents_user ON consents(user_id);
CREATE INDEX idx_consents_scope ON consents(scope);

CREATE TABLE audit_logs (
    id            TEXT PRIMARY KEY,
    actor         TEXT NOT NULL,
    action        TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id   TEXT DEFAULT '',
    consent_id    TEXT DEFAULT '',
    metadata      TEXT DEFAULT '{}',
    ip            TEXT DEFAULT '',
    user_agent    TEXT DEFAULT '',
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_time ON audit_logs(created_at);

CREATE TABLE quiz_sessions (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id),
    questions_json  TEXT NOT NULL DEFAULT '[]',
    current_index   INTEGER NOT NULL DEFAULT 0,
    answers_json    TEXT NOT NULL DEFAULT '[]',
    total_score     INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL DEFAULT 0,
    correct_count   INTEGER NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'active',
    result_type     TEXT DEFAULT '',
    insights_json   TEXT DEFAULT '[]',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ
);
CREATE INDEX idx_quiz_sessions_user ON quiz_sessions(user_id, created_at);

CREATE TABLE match_reports (
    id              TEXT PRIMARY KEY,
    user_id         TEXT NOT NULL REFERENCES users(id),
    resume_id       TEXT DEFAULT '',
    resume_snapshot TEXT DEFAULT '',
    title           TEXT DEFAULT '',
    status          TEXT DEFAULT 'completed',
    summary         TEXT DEFAULT '',
    metadata        TEXT DEFAULT '{}',
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_match_reports_user ON match_reports(user_id);
CREATE INDEX idx_match_reports_created ON match_reports(created_at);
CREATE INDEX idx_match_reports_status ON match_reports(status);

CREATE TABLE match_report_items (
    id                     TEXT PRIMARY KEY,
    report_id              TEXT NOT NULL REFERENCES match_reports(id) ON DELETE CASCADE,
    job_title              TEXT NOT NULL,
    company_name           TEXT NOT NULL,
    location               TEXT DEFAULT '',
    salary_range           TEXT DEFAULT '',
    jd_snapshot            TEXT DEFAULT '',
    overall_score          DOUBLE PRECISION DEFAULT 0,
    background_match       DOUBLE PRECISION DEFAULT 0,
    skills_overlap         DOUBLE PRECISION DEFAULT 0,
    experience_relevance   DOUBLE PRECISION DEFAULT 0,
    seniority              DOUBLE PRECISION DEFAULT 0,
    language_requirement   DOUBLE PRECISION DEFAULT 0,
    company_score          DOUBLE PRECISION DEFAULT 0,
    salary_match           DOUBLE PRECISION DEFAULT 0,
    location_match         DOUBLE PRECISION DEFAULT 0,
    culture_workload_match DOUBLE PRECISION DEFAULT 0,
    match_reason           TEXT DEFAULT '',
    matched_skills         TEXT DEFAULT '[]',
    missing_skills         TEXT DEFAULT '[]',
    fit_bullets            TEXT DEFAULT '[]',
    gap_analysis           TEXT DEFAULT '[]',
    improvement_plan       TEXT DEFAULT '',
    credit_snapshot        TEXT DEFAULT '{}',
    rank_order             INTEGER DEFAULT 0,
    created_at             TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_report_items_report ON match_report_items(report_id);
CREATE INDEX idx_report_items_company ON match_report_items(company_name);

CREATE TABLE report_sharing (
    id                TEXT PRIMARY KEY,
    report_id         TEXT NOT NULL REFERENCES match_reports(id) ON DELETE CASCADE,
    user_id           TEXT NOT NULL REFERENCES users(id),
    shared_with_type  TEXT NOT NULL DEFAULT 'career_partner',
    shared_with_id    TEXT DEFAULT '',
    shared_dimensions TEXT NOT NULL DEFAULT '[]',
    purpose           TEXT DEFAULT '',
    status            TEXT DEFAULT 'active',
    granted_at        TIMESTAMPTZ DEFAULT now(),
    revoked_at        TIMESTAMPTZ,
    expires_at        TIMESTAMPTZ,
    created_at        TIMESTAMPTZ DEFAULT now(),
    updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_sharing_report ON report_sharing(report_id);
CREATE INDEX idx_sharing_user ON report_sharing(user_id);
CREATE INDEX idx_sharing_status ON report_sharing(status);
CREATE INDEX idx_sharing_type ON report_sharing(shared_with_type);

CREATE TABLE share_codes (
    id                TEXT PRIMARY KEY,
    code              TEXT UNIQUE NOT NULL,
    owner_id          TEXT NOT NULL REFERENCES users(id),
    scope             TEXT NOT NULL DEFAULT '[]',
    max_access_count  INTEGER NOT NULL DEFAULT 10,
    access_count      INTEGER NOT NULL DEFAULT 0,
    expires_at        TIMESTAMPTZ NOT NULL,
    status            TEXT NOT NULL DEFAULT 'active',
    created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_share_codes_code ON share_codes(code);
CREATE INDEX idx_share_codes_owner ON share_codes(owner_id);

CREATE TABLE verification_audit_log (
    id              TEXT PRIMARY KEY,
    share_code      TEXT NOT NULL,
    owner_id        TEXT NOT NULL REFERENCES users(id),
    verifier_info   TEXT DEFAULT '',
    attestation_ids TEXT NOT NULL DEFAULT '[]',
    result          TEXT NOT NULL DEFAULT 'success',
    created_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_verification_audit_owner ON verification_audit_log(owner_id, created_at);
CREATE INDEX idx_verification_audit_code ON verification_audit_log(share_code);

CREATE TABLE timeline_events (
    id             TEXT PRIMARY KEY,
    user_id        TEXT NOT NULL REFERENCES users(id),
    event_kind     TEXT NOT NULL,
    occurred_at    TIMESTAMPTZ NOT NULL,
    recorded_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_system  TEXT NOT NULL,
    source_ref     TEXT DEFAULT '',
    title          TEXT DEFAULT '',
    summary        TEXT DEFAULT '',
    payload_json   TEXT DEFAULT '{}',
    signal_quality TEXT NOT NULL DEFAULT 'observed',
    confidence     DOUBLE PRECISION DEFAULT 0.5,
    weight_role    TEXT NOT NULL DEFAULT 'evidence',
    visibility     TEXT NOT NULL DEFAULT 'private',
    consent_scope  TEXT DEFAULT '[]',
    status         TEXT NOT NULL DEFAULT 'active',
    superseded_by  TEXT,
    created_at     TIMESTAMPTZ DEFAULT now(),
    updated_at     TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_timeline_user_time ON timeline_events(user_id, occurred_at DESC);
CREATE INDEX idx_timeline_user_kind ON timeline_events(user_id, event_kind, occurred_at);
CREATE INDEX idx_timeline_source ON timeline_events(source_system, source_ref);
