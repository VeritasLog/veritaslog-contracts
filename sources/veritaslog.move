module veritaslog::registry {
    use std::string::{String};
    use std::vector;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};

    /// Main shared registry object for managing compliance logs
    public struct VeritasLogRegistry has key {
        id: UID,
        super_admin: address,
        admins: vector<address>,
        next_log_id: u64,
        logs: Table<u64, Log>,
    }

    /// Compliance log entry with access control
    public struct Log has store, drop {
        walrus_cid: String,
        owner: address,
        allowed: vector<address>,
        title: String,
        severity: String,
        module_name: String,
        created_at: u64,
        pending: vector<address>,
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
        assert!(is_admin_internal(registry, ctx), 1);
        vector::push_back(&mut registry.admins, new_admin);
    }

    /// Register a new compliance log (admin only)
    public entry fun register_log(
        registry: &mut VeritasLogRegistry,
        walrus_cid: String,
        title: String,
        severity: String,
        module_name: String,
        created_at: u64,
        ctx: &mut TxContext
    ) {
        assert!(is_admin_internal(registry, ctx), 2);

        let id = registry.next_log_id;
        registry.next_log_id = id + 1;

        let owner = tx_context::sender(ctx);

        let log = Log {
            walrus_cid,
            owner,
            allowed: vector::singleton<address>(owner),
            title,
            severity,
            module_name: module_name,
            created_at,
            pending: vector::empty<address>(),
        };

        table::add(&mut registry.logs, id, log);
    }

    /// Request access to a specific log (auditors/public)
    public entry fun request_access(
        registry: &mut VeritasLogRegistry,
        log_id: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let log_ref = table::borrow_mut(&mut registry.logs, log_id);
        
        if (!vector::contains(&log_ref.pending, &sender)) {
            vector::push_back(&mut log_ref.pending, sender);
        }
    }

    /// Approve access request for a requester (admin only)
    public entry fun approve_access(
        registry: &mut VeritasLogRegistry,
        log_id: u64,
        requester: address,
        ctx: &mut TxContext
    ) {
        assert!(is_admin_internal(registry, ctx), 3);
        let log_ref = table::borrow_mut(&mut registry.logs, log_id);

        remove_pending(&mut log_ref.pending, requester);

        if (!vector::contains(&log_ref.allowed, &requester)) {
            vector::push_back(&mut log_ref.allowed, requester);
        }
    }

    /// Remove address from pending requests vector
    fun remove_pending(pending: &mut vector<address>, requester: address) {
        let len = vector::length(pending);
        let mut i = 0;
        while (i < len) {
            if (*vector::borrow(pending, i) == requester) {
                vector::swap_remove(pending, i);
                return;
            };
            i = i + 1;
        };
    }

    /// Check if address is admin or super_admin
    fun is_admin_internal(registry: &VeritasLogRegistry, ctx: &TxContext): bool {
        let sender = tx_context::sender(ctx);
        if (sender == registry.super_admin) {
            return true
        };
        vector::contains(&registry.admins, &sender)
    }

    // ==================== Test-only functions ====================
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only]
    public fun get_super_admin(registry: &VeritasLogRegistry): address {
        registry.super_admin
    }

    #[test_only]
    public fun get_next_log_id(registry: &VeritasLogRegistry): u64 {
        registry.next_log_id
    }

    #[test_only]
    public fun is_admin(registry: &VeritasLogRegistry, addr: address): bool {
        if (addr == registry.super_admin) {
            return true
        };
        vector::contains(&registry.admins, &addr)
    }
}