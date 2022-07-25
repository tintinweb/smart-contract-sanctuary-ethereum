// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IPanaAuthority.sol";

abstract contract PanaAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPanaAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IPanaAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IPanaAuthority _authority) {
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

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IPanaAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "../interfaces/IPanaAuthority.sol";

import "../access/PanaAccessControlled.sol";

contract PanaAuthority is IPanaAuthority, PanaAccessControlled {


    /* ========== STATE VARIABLES ========== */

    address public override governor;

    address public override guardian;

    address public override policy;

    address public override vault;

    address public override distributionVault;

    address public newGovernor;

    address public newGuardian;

    address public newPolicy;

    address public newVault;

    address public newDistributionVault;


    /* ========== Constructor ========== */

    constructor(
        address _governor,
        address _guardian,
        address _policy,
        address _vault,
        address _distributionVault
    ) PanaAccessControlled( IPanaAuthority(address(this)) ) {
        governor = _governor;
        emit GovernorPushed(address(0), governor, true);
        guardian = _guardian;
        emit GuardianPushed(address(0), guardian, true);
        policy = _policy;
        emit PolicyPushed(address(0), policy, true);
        vault = _vault;
        emit VaultPushed(address(0), vault, true);
        distributionVault = _distributionVault;
        emit DistributionVaultPushed(address(0), distributionVault, true);
    }


    /* ========== GOV ONLY ========== */

    function pushPanaGovernor(address _newGovernor, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) governor = _newGovernor;
        newGovernor = _newGovernor;
        emit GovernorPushed(governor, newGovernor, _effectiveImmediately);
    }

    function pushGuardian(address _newGuardian, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) guardian = _newGuardian;
        newGuardian = _newGuardian;
        emit GuardianPushed(guardian, newGuardian, _effectiveImmediately);
    }

    function pushPolicy(address _newPolicy, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) policy = _newPolicy;
        newPolicy = _newPolicy;
        emit PolicyPushed(policy, newPolicy, _effectiveImmediately);
    }

    function pushVault(address _newVault, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) vault = _newVault;
        newVault = _newVault;
        emit VaultPushed(vault, newVault, _effectiveImmediately);
    }

    function pushDistributionVault(address _newDistributionVault, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) distributionVault = _newDistributionVault;
        newDistributionVault = _newDistributionVault;
        emit DistributionVaultPushed(distributionVault, newDistributionVault, _effectiveImmediately);
    }


    /* ========== PENDING ROLE ONLY ========== */

    function pullPanaGovernor() external {
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

    function pullVault() external {
        require(msg.sender == newVault, "!newVault");
        emit VaultPulled(vault, newVault);
        vault = newVault;
    }

    function pullDistributionVault() external {
        require(msg.sender == newDistributionVault, "!newDistributionVault");
        emit DistributionVaultPulled(distributionVault, newDistributionVault);
        distributionVault = newDistributionVault;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPanaAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event DistributionVaultPushed(address indexed from, address indexed to, bool _effectiveImmediately); 

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event DistributionVaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
    function distributionVault() external view returns (address);
}