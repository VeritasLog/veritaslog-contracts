#[test_only]
module veritaslog::registry_tests {
    use std::string::{Self, String};
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::test_utils;
    use veritaslog::registry::{Self, VeritasLogRegistry};

    const SUPER_ADMIN: address = @0xA;
    const ADMIN_1: address = @0xB;
    const ADMIN_2: address = @0xC;
    const AUDITOR_1: address = @0xD;
    const AUDITOR_2: address = @0xE;

    fun create_test_string(value: vector<u8>): String {
        string::utf8(value)
    }

    fun create_test_commitment(): vector<u8> {
        // Create a 32-byte commitment for testing
        vector[
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10,
            0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
            0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20
        ]
    }

    fun init_registry(): Scenario {
        let mut scenario = ts::begin(SUPER_ADMIN);
        {
            let ctx = ts::ctx(&mut scenario);
            registry::init_for_testing(ctx);
        };
        scenario
    }

    #[test]
    fun test_init_registry() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            
            assert!(registry::get_super_admin(&registry) == SUPER_ADMIN, 0);
            assert!(registry::get_next_log_id(&registry) == 0, 1);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_add_admin_by_super_admin() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            assert!(registry::is_admin(&registry, ADMIN_1), 0);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_add_admin_by_existing_admin() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_2, ctx);
            
            assert!(registry::is_admin(&registry, ADMIN_2), 0);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_add_admin_by_non_admin_fails() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, AUDITOR_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_register_log() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let walrus_cid = create_test_string(b"bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi");
            let meta_commitment = create_test_commitment();
            
            registry::register_log(
                &mut registry,
                walrus_cid,
                meta_commitment,
                1699564800,
                2, // HIGH severity
                ctx
            );
            
            assert!(registry::get_next_log_id(&registry) == 1, 0);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_register_log_by_non_admin_fails() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, AUDITOR_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let walrus_cid = create_test_string(b"test_cid");
            let meta_commitment = create_test_commitment();
            
            registry::register_log(
                &mut registry,
                walrus_cid,
                meta_commitment,
                1699564800,
                0, // LOW severity
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_request_access() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let walrus_cid = create_test_string(b"test_cid");
            let meta_commitment = create_test_commitment();
            
            registry::register_log(
                &mut registry,
                walrus_cid,
                meta_commitment,
                1699564800,
                0,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, AUDITOR_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::request_access(&mut registry, 0, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_approve_access() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let walrus_cid = create_test_string(b"test_cid");
            let meta_commitment = create_test_commitment();
            
            registry::register_log(
                &mut registry,
                walrus_cid,
                meta_commitment,
                1699564800,
                0,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, AUDITOR_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::request_access(&mut registry, 0, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::approve_access(&mut registry, 0, AUDITOR_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_approve_access_by_non_admin_fails() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            let walrus_cid = create_test_string(b"test_cid");
            let meta_commitment = create_test_commitment();
            
            registry::register_log(
                &mut registry,
                walrus_cid,
                meta_commitment,
                1699564800,
                0,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, AUDITOR_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::request_access(&mut registry, 0, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, AUDITOR_2);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::approve_access(&mut registry, 0, AUDITOR_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_multiple_logs() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::register_log(
                &mut registry,
                create_test_string(b"cid_1"),
                create_test_commitment(),
                1699564800,
                2, // critical -> HIGH
                ctx
            );
            
            registry::register_log(
                &mut registry,
                create_test_string(b"cid_2"),
                create_test_commitment(),
                1699564900,
                0, // info -> LOW
                ctx
            );
            
            registry::register_log(
                &mut registry,
                create_test_string(b"cid_3"),
                create_test_commitment(),
                1699565000,
                1, // warning -> MEDIUM
                ctx
            );
            
            assert!(registry::get_next_log_id(&registry) == 3, 0);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_prevent_duplicate_access_request() {
        let mut scenario = init_registry();
        
        ts::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            registry::add_admin(&mut registry, ADMIN_1, ctx);
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, ADMIN_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::register_log(
                &mut registry,
                create_test_string(b"test_cid"),
                create_test_commitment(),
                1699564800,
                0,
                ctx
            );
            
            ts::return_shared(registry);
        };
        
        ts::next_tx(&mut scenario, AUDITOR_1);
        {
            let mut registry = ts::take_shared<VeritasLogRegistry>(&scenario);
            let ctx = ts::ctx(&mut scenario);
            
            registry::request_access(&mut registry, 0, ctx);
            registry::request_access(&mut registry, 0, ctx);
            
            ts::return_shared(registry);
        };
        
        ts::end(scenario);
    }
}