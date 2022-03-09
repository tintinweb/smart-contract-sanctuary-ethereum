// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/IAuthority.sol";
import "./type/AccessControl.sol";

contract Authority is IAuthority, AccessControl
    {
    
    /* ========== STATE VARIABLES ========== */

    address public override governor;
    address public override vault;
    address public override guardian;
    address public override policy;
    address public override newGovernor;
    address public override newVault;
    address public override newGuardian;
    address public override newPolicy;

    /* ========== CONSTRUCTOR/INITIALIZER ========== */

    constructor() AccessControl(IAuthority(address(this))) {
        governor = msg.sender;
        vault = msg.sender;
        guardian = msg.sender;
    }
    
    /*
    function __AuthorityControl_init() internal initializer {
        __AuthorityControl_init_unchained();
        __AccessControl_init(IAuthority(address(this)));
    }

    function __AuthorityControl_init_unchained() internal onlyInitializing { 
        governor = msg.sender;
    }
    */

    /* ========== GOV ONLY ========== */

    function pushGovernor(address _newGovernor, bool _effectiveImmediately) public virtual onlyGovernor {
        if (_effectiveImmediately) {
            governor = _newGovernor;
        }
        newGovernor = _newGovernor;
        emit GovernorPushed(governor, _newGovernor, _effectiveImmediately);
    }

    function pushVault(address _newVault, bool _effectiveImmediately) public virtual onlyGovernor {
        if (_effectiveImmediately) {
            vault = _newVault;
        }
        newVault = _newVault;
        emit VaultPushed(vault, _newVault, _effectiveImmediately);
    }

    /* ========== PENDING ROLE ONLY ========== */

    function pullGovernor() public virtual onlyNewGovernor {
        emit GovernorPulled(governor, newGovernor);
        governor = newGovernor;
    }

    function pullVault() public virtual onlyNewVault {
        emit VaultPulled(vault, newVault);
        vault = newVault;
    }

    /* ========== VIEW ONLY ========== */

    function version() public virtual pure returns (string memory) {
        return "1.0.0";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed _from, address indexed _to, bool _effectiveImmediately);
    
    event Guardian(address indexed _from, address indexed _to, bool _effectiveImmediately);
    
    event VaultPushed(address indexed _from, address indexed _to, bool _effectiveImmediately);
    
    event GovernorPulled(address indexed _from, address indexed _to);
    
    event GuardianPushed(address indexed _from, address indexed _to);
    
    event VaultPulled(address indexed _from, address indexed _to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function vault() external view returns (address);

    function policy() external view returns (address);

    function newGovernor() external view returns (address);

    function newGuardian() external view returns (address);

    function newVault() external view returns (address);

    function newPolicy() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
*/

import "@openzeppelin/contracts/utils/Context.sol";
import "../interface/IAuthority.sol";

abstract contract AccessControl is Context {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IAuthority _newAuthority);

    string UNAUTHORIZED;
    
    /* ========== STATE VARIABLES ========== */
    
    IAuthority public authority;

    /* ========== CONSTRUCTOR/INITIALIZER ========== */

    constructor (IAuthority _authority)  {
        authority = _authority;
        UNAUTHORIZED = "UNAUTHORIZED";
        emit AuthorityUpdated(authority);
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

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyNewGovernor() {
        require(msg.sender == authority.newGovernor(), UNAUTHORIZED);
        _;
    }

    modifier onlyNewVault() {
        require(msg.sender == authority.newVault(), UNAUTHORIZED);
        _;
    }

    modifier onlyGovernorGuardian() {
        require(msg.sender == authority.newGovernor(), UNAUTHORIZED);
        _;
    }

    modifier onlyAuthority() {
        require(
            msg.sender == authority.governor() ||
            msg.sender == authority.guardian() ||
            msg.sender == authority.policy(), UNAUTHORIZED
        );
        _;
    }

    /* ========== GOV ONLY ========== */

     function setAuthority(IAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}