// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITheopetraAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ManagerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event SignerPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event ManagerPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event SignerPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function manager() external view returns (address);

    function vault() external view returns (address);

    function whitelistSigner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";
import "../Types/TheopetraAccessControlled.sol";

contract TheopetraAuthority is ITheopetraAuthority, TheopetraAccessControlled {
    /* ========== STATE VARIABLES ========== */

    address public override governor;

    address public override guardian;

    address public override policy;

    address public override manager;

    address public override vault;

    address public override whitelistSigner;

    address public newGovernor;

    address public newGuardian;

    address public newPolicy;

    address public newManager;

    address public newVault;

    address public newWhitelistSigner;

    string private constant REQUIRE_ERROR = "Address cannot be zero address";

    /* ========== Constructor ========== */

    constructor(
        address _governor,
        address _guardian,
        address _policy,
        address _manager,
        address _vault,
        address _whitelistSigner
    ) TheopetraAccessControlled(ITheopetraAuthority(address(this))) {
        require(_governor != address(0), REQUIRE_ERROR);
        governor = _governor;
        emit GovernorPushed(address(0), governor, true);
        require(_guardian != address(0), REQUIRE_ERROR);
        guardian = _guardian;
        emit GuardianPushed(address(0), guardian, true);
        require(_policy != address(0), REQUIRE_ERROR);
        policy = _policy;
        emit PolicyPushed(address(0), policy, true);
        require(_manager != address(0), REQUIRE_ERROR);
        manager = _manager;
        emit ManagerPushed(address(0), manager, true);
        require(_vault != address(0), REQUIRE_ERROR);
        vault = _vault;
        emit VaultPushed(address(0), vault, true);
        require(_whitelistSigner != address(0), REQUIRE_ERROR);
        whitelistSigner = _whitelistSigner;
        emit SignerPushed(address(0), whitelistSigner, true);
    }

    /* ========== GOV ONLY ========== */

    function pushGovernor(address _newGovernor, bool _effectiveImmediately) external onlyGovernor {
        require(_newGovernor != address(0), REQUIRE_ERROR);
        if (_effectiveImmediately) governor = _newGovernor;
        newGovernor = _newGovernor;
        emit GovernorPushed(governor, newGovernor, _effectiveImmediately);
    }

    function pushGuardian(address _newGuardian, bool _effectiveImmediately) external onlyGovernor {
        require(_newGuardian != address(0), REQUIRE_ERROR);
        if (_effectiveImmediately) guardian = _newGuardian;
        newGuardian = _newGuardian;
        emit GuardianPushed(guardian, newGuardian, _effectiveImmediately);
    }

    function pushPolicy(address _newPolicy, bool _effectiveImmediately) external onlyGovernor {
        require(_newPolicy != address(0), REQUIRE_ERROR);
        if (_effectiveImmediately) policy = _newPolicy;
        newPolicy = _newPolicy;
        emit PolicyPushed(policy, newPolicy, _effectiveImmediately);
    }

    function pushManager(address _newManager, bool _effectiveImmediately) external onlyGovernor {
        require(_newManager != address(0), REQUIRE_ERROR);
        if (_effectiveImmediately) manager = _newManager;
        newManager = _newManager;
        emit ManagerPushed(manager, newManager, _effectiveImmediately);
    }

    function pushVault(address _newVault, bool _effectiveImmediately) external onlyGovernor {
        require(_newVault != address(0), REQUIRE_ERROR);
        if (_effectiveImmediately) vault = _newVault;
        newVault = _newVault;
        emit VaultPushed(vault, newVault, _effectiveImmediately);
    }

    function pushWhitelistSigner(address _newWhitelistSigner, bool _effectiveImmediately) external onlyGovernor {
        require(_newWhitelistSigner != address(0), REQUIRE_ERROR);
        if (_effectiveImmediately) whitelistSigner = _newWhitelistSigner;
        newWhitelistSigner = _newWhitelistSigner;
        emit SignerPushed(whitelistSigner, newWhitelistSigner, _effectiveImmediately);
    }

    /* ========== PENDING ROLE ONLY ========== */

    function pullGovernor() external {
        require(msg.sender == newGovernor, "!newGovernor");
        emit GovernorPulled(governor, newGovernor);
        governor = newGovernor;
    }

    function pullGuardian() external {
        require(msg.sender == newGuardian, "!newGuard");
        emit GuardianPulled(guardian, newGuardian);
        guardian = newGuardian;
    }

    function pullPolicy() external {
        require(msg.sender == newPolicy, "!newPolicy");
        emit PolicyPulled(policy, newPolicy);
        policy = newPolicy;
    }

    function pullManager() external {
        require(msg.sender == newManager, "!newManager");
        emit ManagerPulled(manager, newManager);
        manager = newManager;
    }

    function pullVault() external {
        require(msg.sender == newVault, "!newVault");
        emit VaultPulled(vault, newVault);
        vault = newVault;
    }

    function pullWhitelistSigner() external {
        require(msg.sender == newWhitelistSigner, "!newWhitelistSigner");
        emit SignerPulled(whitelistSigner, newWhitelistSigner);
        whitelistSigner = newWhitelistSigner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";

abstract contract TheopetraAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(ITheopetraAuthority indexed authority);

    string constant UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    ITheopetraAuthority public authority;

    /* ========== Constructor ========== */

    constructor(ITheopetraAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == authority.manager(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(ITheopetraAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}