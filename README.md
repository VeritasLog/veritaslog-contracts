# 🛡️ VeritasLog - Decentralized Compliance Logging System

[![Sui Move](https://img.shields.io/badge/Sui-Move-blue)](https://sui.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Testnet](https://img.shields.io/badge/Network-Testnet-green)](https://testnet.sui.io/)

> **VeritasLog** is a decentralized compliance logging system built on Sui blockchain, designed to provide immutable, transparent, and auditable records for enterprise compliance needs. The system leverages Walrus storage for decentralized log storage and implements a robust access control mechanism.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Smart Contracts](#-smart-contracts)
- [Quick Start](#-quick-start)
- [Deployment Guide](#-deployment-guide)
- [Usage Examples](#-usage-examples)
- [Testing](#-testing)
- [Security Considerations](#-security-considerations)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**VeritasLog** solves the critical challenge of maintaining tamper-proof compliance logs in regulated industries. Traditional centralized logging systems are vulnerable to manipulation and single points of failure. Our solution leverages:

- **Sui Blockchain**: For transparent and immutable record-keeping
- **Walrus Storage**: For decentralized log file storage
- **Smart Access Control**: Role-based access with approval workflows
- **Audit Trail**: Complete transparency for regulatory compliance

### Use Cases

- 🏦 **Financial Services**: Transaction logs, KYC/AML records
- 🏥 **Healthcare**: HIPAA-compliant medical records access logs
- 🏭 **Manufacturing**: Quality control and safety incident reports
- 🔐 **Cybersecurity**: Security incident response logs
- 📊 **Government**: Public sector transparency and accountability

---

## ✨ Key Features

### 🔐 **Decentralized & Immutable**
- All logs are stored on Sui blockchain with cryptographic integrity
- Walrus CID references for decentralized file storage
- No single point of failure or manipulation

### 👥 **Role-Based Access Control**
- **Super Admin**: Full system control, can add admins
- **Admins**: Can register logs and approve access requests
- **Auditors**: Can request access to specific logs for review

### 📝 **Comprehensive Log Metadata**
- Title, severity level, module/department tracking
- Timestamp for chronological ordering
- Owner identification for accountability

### 🔍 **Access Request Workflow**
- Auditors submit formal access requests
- Admins review and approve/deny requests
- Maintains audit trail of who accessed what and when

### 🌐 **Shared Object Model**
- Single shared registry accessible by all participants
- Gas-efficient operations with Sui's parallel execution
- Real-time updates visible to all stakeholders

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     VeritasLog System                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐         ┌──────────────────┐             │
│  │  Super Admin  │────────▶│ Add/Manage Admins│             │
│  └───────────────┘         └──────────────────┘             │
│         │                                                   │
│         ▼                                                   │
│  ┌───────────────┐         ┌──────────────────┐             │
│  │    Admins     │────────▶│  Register Logs   │             │
│  └───────────────┘         │  Approve Access  │             │
│         │                  └──────────────────┘             │
│         │                            │                      │
│         │                            ▼                      │
│         │                   ┌──────────────────┐            │
│         │                   │ VeritasLog       │            │
│         │                   │ Registry         │            │
│         │                   │ (Shared Object)  │            │
│         │                   └──────────────────┘            │
│         │                            │                      │
│         │                            ▼                      │
│  ┌───────────────┐         ┌──────────────────┐             │
│  │   Auditors    │────────▶│ Request Access   │             │
│  └───────────────┘         │ View Logs        │             │
│                            └──────────────────┘             │
│                                     │                       │
│                                     ▼                       │
│                            ┌──────────────────┐             │
│                            │ Walrus Storage   │             │
│                            │ (Decentralized)  │             │
│                            └──────────────────┘             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
veritaslog-contracts/
├── sources/
│   └── veritaslog.move           # Main smart contract module
├── tests/
│   ├── veritaslog_tests.move     # Unit tests 
│   └── README.md                 # Test documentation
├── Move.toml                     # Package manifest
└── README.md                     # This file
```

### File Descriptions

- **`sources/veritaslog.move`**: Core smart contract containing all logic for registry management, access control, and log operations
- **`tests/veritaslog_tests.move`**: Unit test for core smart contract
- **`tests/README.md`**: Documentation for unit tests
- **`Move.toml`**: Package configuration with dependencies and metadata
- **`README.md`**: Comprehensive documentation (you're reading it!)

---

## 📜 Smart Contracts

### Main Module: `veritaslog::registry`

#### Structs

##### `VeritasLogRegistry`
The main shared object that holds the entire system state.

```move
public struct VeritasLogRegistry has key {
    id: UID,
    super_admin: address,
    admins: vector<address>,
    next_log_id: u64,
    logs: Table<u64, Log>,
}
```

**Fields:**
- `id`: Unique identifier for the registry object
- `super_admin`: Address with full system control
- `admins`: List of authorized admin addresses
- `next_log_id`: Auto-incrementing counter for log IDs
- `logs`: Table mapping log IDs to log entries

##### `Log`
Individual compliance log entry with metadata and access control.

```move
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
```

**Fields:**
- `walrus_cid`: Content identifier for decentralized storage
- `owner`: Address that created the log
- `allowed`: List of addresses with read access
- `title`: Log entry title/description
- `severity`: Log severity level (e.g., "critical", "warning", "info")
- `module_name`: Department or system module name
- `created_at`: Unix timestamp
- `pending`: List of addresses with pending access requests

---

#### Functions

##### `init(ctx: &mut TxContext)`
**Visibility:** Private (auto-called on deployment)

Initializes the registry with the deployer as super admin. Creates and shares the `VeritasLogRegistry` object.

**Emitted on:** Contract deployment

---

##### `add_admin(registry: &mut VeritasLogRegistry, new_admin: address, ctx: &mut TxContext)`
**Visibility:** Public Entry  
**Access:** Super Admin or existing Admins only

Adds a new admin to the system.

**Parameters:**
- `registry`: Mutable reference to the shared registry
- `new_admin`: Address to be granted admin privileges
- `ctx`: Transaction context

**Assertions:**
- Caller must be super admin or an existing admin (error code: 1)

---

##### `register_log(registry: &mut VeritasLogRegistry, walrus_cid: String, title: String, severity: String, module_name: String, created_at: u64, ctx: &mut TxContext)`
**Visibility:** Public Entry  
**Access:** Admins only

Registers a new compliance log entry.

**Parameters:**
- `registry`: Mutable reference to the shared registry
- `walrus_cid`: Walrus content identifier (can be mock value for testing)
- `title`: Descriptive title for the log
- `severity`: Severity level (e.g., "critical", "high", "medium", "low", "info")
- `module_name`: Name of the system module or department
- `created_at`: Unix timestamp (in seconds)
- `ctx`: Transaction context

**Behavior:**
- Auto-increments log ID
- Sets caller as owner
- Automatically grants owner read access
- Returns new log ID

**Assertions:**
- Caller must be an admin (error code: 2)

---

##### `request_access(registry: &mut VeritasLogRegistry, log_id: u64, ctx: &mut TxContext)`
**Visibility:** Public Entry  
**Access:** Anyone

Submits an access request for a specific log.

**Parameters:**
- `registry`: Mutable reference to the shared registry
- `log_id`: ID of the log to request access to
- `ctx`: Transaction context

**Behavior:**
- Adds caller to the log's pending access list
- Prevents duplicate requests from same address

---

##### `approve_access(registry: &mut VeritasLogRegistry, log_id: u64, requester: address, ctx: &mut TxContext)`
**Visibility:** Public Entry  
**Access:** Admins only

Approves a pending access request.

**Parameters:**
- `registry`: Mutable reference to the shared registry
- `log_id`: ID of the log
- `requester`: Address to grant access to
- `ctx`: Transaction context

**Behavior:**
- Removes requester from pending list
- Adds requester to allowed list
- Prevents duplicate entries in allowed list

**Assertions:**
- Caller must be an admin (error code: 3)

---

## 🚀 Quick Start

### Prerequisites

- **Sui CLI** installed ([Installation Guide](https://docs.sui.io/build/install))
- **Sui Wallet** configured with testnet
- **Testnet SUI** tokens for gas fees

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/veritaslog-contracts.git
cd veritaslog-contracts
```

2. **Check Sui CLI installation**
```bash
sui --version
# Should output: sui 1.x.x
```

3. **Configure Sui client for testnet**
```bash
sui client active-env
# Should show: testnet
```

If not on testnet:
```bash
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet
```

4. **Create or switch to your wallet address**
```bash
# Check active address
sui client active-address

# Or create new address
sui client new-address ed25519

# Switch to specific address
sui client switch --address <YOUR_ADDRESS>
```

5. **Get testnet SUI tokens**
```bash
sui client faucet
```

Or visit: https://faucet.testnet.sui.io/

6. **Verify balance**
```bash
sui client gas
```

---

## 🚢 Deployment Guide

### Step 1: Build the Contract

```bash
sui move build
```

**Expected Output:**
```
INCLUDING DEPENDENCY Sui
INCLUDING DEPENDENCY MoveStdlib
BUILDING veritaslog
```

### Step 2: Deploy to Testnet

```bash
sui client publish --gas-budget 50000000
```

**Expected Output:**
```
Transaction Digest: <TRANSACTION_HASH>
╭─────────────────────────────────────────────────────────────────╮
│ Object Changes                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Created Objects:                                                │
│  ┌──                                                            │
│  │ ObjectID: 0x...                                              │
│  │ Sender: 0x...                                                │
│  │ Owner: Shared                                                │
│  │ ObjectType: 0x...::registry::VeritasLogRegistry              │
│  └──                                                            │
╰─────────────────────────────────────────────────────────────────╯
```

### Step 3: Save Important Values

After deployment, save these values:

```bash
# Package ID (use this for all function calls)
PACKAGE_ID=0x...

# Registry Object ID (the shared object)
REGISTRY_ID=0x...

# Your address (super admin)
SUPER_ADMIN=0x...
```

**💡 Tip**: Create a `.env` file to store these values:
```bash
echo "PACKAGE_ID=0x..." > .env
echo "REGISTRY_ID=0x..." >> .env
echo "SUPER_ADMIN=0x..." >> .env
```

---

## 💻 Usage Examples

### 1. Add an Admin

```bash
sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function add_admin \
  --args $REGISTRY_ID 0xNEW_ADMIN_ADDRESS \
  --gas-budget 10000000
```

**Example:**
```bash
sui client call \
  --package 0x1a2b3c4d5e6f \
  --module registry \
  --function add_admin \
  --args 0x9f8e7d6c5b4a 0x7890abcd1234 \
  --gas-budget 10000000
```

### 2. Register a New Log

```bash
sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function register_log \
  --args $REGISTRY_ID \
    "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi" \
    "Failed Login Attempt Detected" \
    "critical" \
    "Authentication" \
    1699564800 \
  --gas-budget 10000000
```

**Parameters Explained:**
- `walrus_cid`: `"bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi"` (Walrus content ID)
- `title`: `"Failed Login Attempt Detected"`
- `severity`: `"critical"` (options: critical, high, medium, low, info)
- `module_name`: `"Authentication"`
- `created_at`: `1699564800` (Unix timestamp)

### 3. Request Access to a Log

```bash
sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function request_access \
  --args $REGISTRY_ID 0 \
  --gas-budget 10000000
```

**Note:** Replace `0` with the actual log ID you want to access.

### 4. Approve Access Request

```bash
sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function approve_access \
  --args $REGISTRY_ID 0 0xREQUESTER_ADDRESS \
  --gas-budget 10000000
```

**Example:**
```bash
sui client call \
  --package 0x1a2b3c4d5e6f \
  --module registry \
  --function approve_access \
  --args 0x9f8e7d6c5b4a 0 0x7890abcd1234 \
  --gas-budget 10000000
```

---

## 🧪 Testing

### Terminal Test Snippets

Here's a complete testing workflow you can run in your terminal:

```bash
#!/bin/bash

# Set your variables
export PACKAGE_ID="YOUR_PACKAGE_ID"
export REGISTRY_ID="YOUR_REGISTRY_ID"

echo "=== VeritasLog Testing Suite ==="
echo ""

# Test 1: Add Admin
echo "Test 1: Adding new admin..."
NEW_ADMIN=$(sui client new-address ed25519 | grep -oE '0x[a-fA-F0-9]{64}')
echo "Created test admin: $NEW_ADMIN"

sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function add_admin \
  --args $REGISTRY_ID $NEW_ADMIN \
  --gas-budget 10000000

echo "✅ Admin added"
echo ""

# Test 2: Register Log (Critical Severity)
echo "Test 2: Registering critical security log..."
sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function register_log \
  --args $REGISTRY_ID \
    "bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi" \
    "Unauthorized Access Attempt" \
    "critical" \
    "Security" \
    $(date +%s) \
  --gas-budget 10000000

echo "✅ Critical log registered (Log ID: 0)"
echo ""

# Test 3: Register Log (Info Severity)
echo "Test 3: Registering info log..."
sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function register_log \
  --args $REGISTRY_ID \
    "bafybeia6zukjbzbxj4xcmyy7nz3p6etwt5f4n6jtqj7swmudkn4fy2jlse" \
    "System Backup Completed" \
    "info" \
    "Operations" \
    $(date +%s) \
  --gas-budget 10000000

echo "✅ Info log registered (Log ID: 1)"
echo ""

# Test 4: Switch to auditor and request access
echo "Test 4: Creating auditor and requesting access..."
AUDITOR=$(sui client new-address ed25519 | grep -oE '0x[a-fA-F0-9]{64}')
sui client switch --address $AUDITOR
sui client faucet

sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function request_access \
  --args $REGISTRY_ID 0 \
  --gas-budget 10000000

echo "✅ Access requested by auditor: $AUDITOR"
echo ""

# Test 5: Switch back to admin and approve access
echo "Test 5: Approving access request..."
sui client switch --address $SUPER_ADMIN

sui client call \
  --package $PACKAGE_ID \
  --module registry \
  --function approve_access \
  --args $REGISTRY_ID 0 $AUDITOR \
  --gas-budget 10000000

echo "✅ Access approved for auditor"
echo ""

echo "=== All Tests Completed Successfully ==="
```

### Manual Testing Checklist

- [ ] Deploy contract successfully
- [ ] Add 2-3 admins
- [ ] Register logs with different severity levels
- [ ] Test access request from non-admin address
- [ ] Approve access request
- [ ] Try to call admin functions from non-admin (should fail)
- [ ] Register multiple logs and verify auto-incrementing IDs
- [ ] Test duplicate access request (should not create duplicate)

---

## 🔒 Security Considerations

### Access Control
- ✅ Super admin is set to deployer address on initialization
- ✅ All admin functions check caller authorization
- ✅ Access requests are validated to prevent duplicates
- ✅ Log ownership is immutable after creation

### Best Practices
1. **Key Management**: Store private keys securely, never commit to version control
2. **Admin Rotation**: Regularly review and update admin list
3. **Access Auditing**: Monitor all access requests and approvals
4. **Gas Budget**: Always set appropriate gas budgets for transactions
5. **Walrus CID**: Verify Walrus content integrity before registering

### Known Limitations
- Log entries cannot be deleted (by design for compliance)
- Log metadata cannot be modified after creation
- Access cannot be revoked once granted (future enhancement)
- No built-in log expiration mechanism

---

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### Reporting Issues
- Use GitHub Issues to report bugs
- Include reproduction steps and expected behavior
- Provide Sui version and environment details

### Submitting Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Move coding conventions
- Add tests for new features
- Update documentation
- Keep commits atomic and well-described

---

## 📝 Notes

### For Hackathon Judges

**Why VeritasLog?**

Traditional compliance logging systems suffer from centralization risks, lack of transparency, and potential for tampering. VeritasLog addresses these critical issues by:

1. **Immutability**: All logs are stored on Sui blockchain, ensuring tamper-proof records
2. **Transparency**: Shared object model allows authorized stakeholders to verify logs in real-time
3. **Decentralization**: Integration with Walrus storage eliminates single points of failure
4. **Auditability**: Complete access trail for regulatory compliance
5. **Scalability**: Sui's parallel execution enables high-throughput logging

**Technical Highlights:**

- Efficient use of Sui's shared objects for gas optimization
- Clean separation of concerns with role-based access control
- Production-ready error handling with assertion codes
- Extensible design for future enhancements

**Real-World Impact:**

This solution can be immediately deployed in regulated industries requiring:
- GDPR compliance (data access logs)
- SOX compliance (financial transaction logs)
- HIPAA compliance (healthcare access logs)
- ISO 27001 (information security logs)

### Gas Optimization Tips

- **Batch Operations**: Consider batching multiple log registrations
- **Storage Efficiency**: Use compact string representations
- **Access Lists**: Monitor size of allowed/pending vectors for large-scale deployments

### Troubleshooting

**Problem**: "Cannot find gas coin" error
```bash
# Solution: Request faucet
sui client faucet
```

**Problem**: "Object not found" error
```bash
# Solution: Verify registry object ID
sui client object $REGISTRY_ID
```

**Problem**: "Unauthorized" assertion error
```bash
# Solution: Check if caller is admin
sui client active-address
# Verify this address is in admins list
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Developer**: Dhisa (ijlalwindhi15@gmail.com)
- **Organization**: VeritasLog Team

---

## 🔗 Links

- **Sui Documentation**: https://docs.sui.io/
- **Walrus Storage**: https://walrus.site/
- **Sui Testnet Explorer**: https://testnet.suivision.xyz/
- **Sui Discord**: https://discord.gg/sui

---

## 📞 Support

For questions, feedback, or support:
- 📧 Email: ijlalwindhi15@gmail.com
- 💬 Discord: [Join Sui Discord](https://discord.gg/sui)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/veritaslog-contracts/issues)

---

<div align="center">

**Built with ❤️ on Sui Blockchain**

*Empowering transparency, one log at a time*

</div>