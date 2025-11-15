module veritaslog::registry {
    use std::vector;
    use std::string::String;

    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// Error codes
    const E_NOT_ADMIN: u64 = 1;
    const E_REGISTER_FORBIDDEN: u64 = 2;
    const E_APPROVE_FORBIDDEN: u64 = 3;
    const E_BAD_COMMITMENT_LEN: u64 = 10;
    const E_NO_ACCESS: u64 = 11;

    /// Struct for storing access request details
    public struct AccessRequest has store, drop, copy {
        requester: address,
        reason: String,
        requested_at: u64,
    }

    /// Main shared registry object for managing compliance logs
    public struct VeritasLogRegistry has key {
        id: UID,
        super_admin: address,
        admins: vector<address>,
        next_log_id: u64,
        logs: Table<u64, Log>,
    }

    /// Compact on-chain record (NO plaintext fields)
    /// - walrus_cid: pointer to encrypted/normalized bundle in Walrus
    /// - meta_commitment: 32-byte seal-compatible commitment (sha256 or proof root)
    /// - severity_code: 0=LOW, 1=MEDIUM, 2=HIGH (expand later bila perlu)
    public struct Log has store, drop {
        walrus_cid: String,
        owner: address,
        allowed: vector<address>,
        created_at: u64,
        severity_code: u8,
        meta_commitment: vector<u8>, // expect 32 bytes
        pending: vector<address>,
        access_requests: vector<AccessRequest>,
    }

    /// Event for indexers
    public struct RegisterLogEvent has copy, drop {
        log_id: u64,
        walrus_cid: String,
        created_at: u64,
        severity_code: u8,
        commitment: vector<u8>,
        owner: address,
    }

    /// Event when access is requested
    public struct AccessRequestEvent has copy, drop {
        log_id: u64,
        requester: address,
        reason: String,
        requested_at: u64,
    }

    /// Event when access is approved
    public struct AccessApprovedEvent has copy, drop {
        log_id: u64,
        requester: address,
        approved_by: address,
        approved_at: u64,
    }

    /// Event when access is rejected
    public struct AccessRejectedEvent has copy, drop {
        log_id: u64,
        requester: address,
        rejected_by: address,
        rejected_at: u64,
        reason: String,
    }

    /// Initialize the registry once and share it
    fun init(ctx: &mut TxContext) {
        let registry = VeritasLogRegistry {
            id: object::new(ctx),
            super_admin: tx_context::sender(ctx),
            admins: vector::empty<address>(),
            next_log_id: 0,
            logs: table::new<u64, Log>(ctx),
        };
        transfer::share_object(registry);
    }

    /// Add a new admin (only super admin or existing admins can call this)
    public entry fun add_admin(
        registry: &mut VeritasLogRegistry,
        new_admin: address,
        ctx: &mut TxContext
    ) {
        assert!(is_admin_internal(registry, ctx), E_NOT_ADMIN);
        vector::push_back(&mut registry.admins, new_admin);
    }

    /// Register a new compliance log (admin only, PRIVACY-PRESERVING)
    /// - `walrus_cid` : pointer ke blob Walrus (bundle JSON terenkripsi/ternormalisasi)
    /// - `meta_commitment` : 32-byte commitment dari bundle/meta (sha256/Seal root)
    /// - `created_at` : epoch seconds
    /// - `severity_code` : 0/1/2 (LOW/MEDIUM/HIGH)
    public entry fun register_log(
        registry: &mut VeritasLogRegistry,
        walrus_cid: String,
        meta_commitment: vector<u8>,
        created_at: u64,
        severity_code: u8,
        ctx: &mut TxContext
    ) {
        assert!(is_admin_internal(registry, ctx), E_REGISTER_FORBIDDEN);
        // Commitment should 32 bytes (sha256)
        let len = vector::length(&meta_commitment);
        assert!(len == 32, E_BAD_COMMITMENT_LEN);

        let id = registry.next_log_id;
        registry.next_log_id = id + 1;

        let owner = tx_context::sender(ctx);

        let log = Log {
            walrus_cid,
            owner,
            allowed: vector::singleton<address>(owner),
            created_at,
            severity_code,
            meta_commitment,
            pending: vector::empty<address>(),
            access_requests: vector::empty<AccessRequest>(),
        };

        table::add(&mut registry.logs, id, log);

        // Emit event for indexer
        event::emit(RegisterLogEvent {
            log_id: id,
            walrus_cid: table::borrow(&registry.logs, id).walrus_cid,
            created_at,
            severity_code,
            commitment: table::borrow(&registry.logs, id).meta_commitment,
            owner,
        });
    }

    /// Request access to a specific log (auditors/public)
    public entry fun request_access(
        registry: &mut VeritasLogRegistry,
        log_id: u64,
        reason: String,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let log_ref = table::borrow_mut(&mut registry.logs, log_id);
        let current_time = tx_context::epoch(ctx);
        
        // Check if already requested
        if (!vector::contains(&log_ref.pending, &sender)) {
            vector::push_back(&mut log_ref.pending, sender);
            
            // Save request details
            let request = AccessRequest {
                requester: sender,
                reason,
                requested_at: current_time,
            };
            vector::push_back(&mut log_ref.access_requests, request);

            // Emit event
            event::emit(AccessRequestEvent {
                log_id,
                requester: sender,
                reason,
                requested_at: current_time,
            });
        }
    }

    /// Approve access request for a requester (admin only)
    public entry fun approve_access(
        registry: &mut VeritasLogRegistry,
        log_id: u64,
        requester: address,
        ctx: &mut TxContext
    ) {
        assert!(is_admin_internal(registry, ctx), E_APPROVE_FORBIDDEN);
        let log_ref = table::borrow_mut(&mut registry.logs, log_id);

        remove_pending(&mut log_ref.pending, requester);
        remove_access_request(&mut log_ref.access_requests, requester);

        if (!vector::contains(&log_ref.allowed, &requester)) {
            vector::push_back(&mut log_ref.allowed, requester);
        };

        // Emit event
        event::emit(AccessApprovedEvent {
            log_id,
            requester,
            approved_by: tx_context::sender(ctx),
            approved_at: tx_context::epoch(ctx),
        });
    }

    /// Reject access request (admin only)
    public entry fun reject_access(
        registry: &mut VeritasLogRegistry,
        log_id: u64,
        requester: address,
        reason: String,
        ctx: &mut TxContext
    ) {
        assert!(is_admin_internal(registry, ctx), E_APPROVE_FORBIDDEN);
        let log_ref = table::borrow_mut(&mut registry.logs, log_id);

        remove_pending(&mut log_ref.pending, requester);
        remove_access_request(&mut log_ref.access_requests, requester);

        // Emit event
        event::emit(AccessRejectedEvent {
            log_id,
            requester,
            rejected_by: tx_context::sender(ctx),
            rejected_at: tx_context::epoch(ctx),
            reason,
        });
    }

    /// Get all access requests for a specific log (admin only)
    public fun get_access_requests(
        registry: &VeritasLogRegistry,
        log_id: u64,
        ctx: &TxContext
    ): vector<AccessRequest> {
        assert!(is_admin_internal(registry, ctx), E_APPROVE_FORBIDDEN);
        let log_ref = table::borrow(&registry.logs, log_id);
        *&log_ref.access_requests
    }

    /// Check if user can view log (admin, super_admin, or in allowed list)
    public fun can_view_log(
        registry: &VeritasLogRegistry,
        log_id: u64,
        ctx: &TxContext
    ): bool {
        let sender = tx_context::sender(ctx);
        
        // Admin & super admin can view all logs
        if (is_admin_internal(registry, ctx)) {
            return true
        };

        // Check if in allowed list
        let log_ref = table::borrow(&registry.logs, log_id);
        vector::contains(&log_ref.allowed, &sender)
    }

    public entry fun seal_approve(
    id: vector<u8>,
    registry: &VeritasLogRegistry,
    log_id: u64,
    ctx: &TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let log_ref = table::borrow(&registry.logs, log_id);

        assert!(vector::contains(&log_ref.allowed, &sender), E_NO_ACCESS);

        assert!(id == log_ref.meta_commitment, E_NO_ACCESS);
    }

    /// Remove address from pending requests vector
    fun remove_pending(pending: &mut vector<address>, requester: address) {
        let len = vector::length(pending);
        let mut i = 0;
        while (i < len) {
            if (*vector::borrow(pending, i) == requester) {
                vector::swap_remove(pending, i);
                return
            };
            i = i + 1;
        };
    }

    /// Remove access request from vector
    fun remove_access_request(requests: &mut vector<AccessRequest>, requester: address) {
        let len = vector::length(requests);
        let mut i = 0;
        while (i < len) {
            if (vector::borrow(requests, i).requester == requester) {
                vector::swap_remove(requests, i);
                return
            };
            i = i + 1;
        };
    }

    /// Check if address is admin or super_admin
    fun is_admin_internal(registry: &VeritasLogRegistry, ctx: &TxContext): bool {
        let sender = tx_context::sender(ctx);
        if (sender == registry.super_admin) { return true };
        vector::contains(&registry.admins, &sender)
    }

    // ==================== View functions for UI ====================
    /// Get log details (anyone can call, but content access controlled elsewhere)
    public fun get_log(
        registry: &VeritasLogRegistry,
        log_id: u64,
    ): (String, address, vector<address>, u64, u8, vector<u8>, vector<address>) {
        let log_ref = table::borrow(&registry.logs, log_id);
        (
            log_ref.walrus_cid,
            log_ref.owner,
            *&log_ref.allowed,
            log_ref.created_at,
            log_ref.severity_code,
            *&log_ref.meta_commitment,
            *&log_ref.pending,
        )
    }

    /// Get total number of logs
    public fun get_total_logs(registry: &VeritasLogRegistry): u64 {
        registry.next_log_id
    }

    // ==================== Test-only functions ====================
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) { init(ctx); }

    #[test_only]
    public fun get_super_admin(registry: &VeritasLogRegistry): address { registry.super_admin }

    #[test_only]
    public fun get_next_log_id(registry: &VeritasLogRegistry): u64 { registry.next_log_id }

    #[test_only]
    public fun is_admin(registry: &VeritasLogRegistry, addr: address): bool {
        if (addr == registry.super_admin) { return true };
        vector::contains(&registry.admins, &addr)
    }
}