// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISanctionsList {
    function isSanctioned(address _address) external view returns (bool);
}

interface IWhitelist {
    function isCustomer(address _address) external view returns (bool);

    function isLP(address _address) external view returns (bool);

    function isOTC(address _address) external view returns (bool);

    function isVault(address vault) external view returns (bool);

    function engineAccess(address _address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// Vault
error HV_ActiveRound();
error HV_AuctionInProgress();
error HV_BadAddress();
error HV_BadAmount();
error HV_BadCap();
error HV_BadCollaterals();
error HV_BadCollateralPosition();
error HV_BadDepositAmount();
error HV_BadDuration();
error HV_BadExpiry();
error HV_BadFee();
error HV_BadLevRatio();
error HV_BadNumRounds();
error HV_BadNumShares();
error HV_BadNumStrikes();
error HV_BadOption();
error HV_BadPPS();
error HV_BadRound();
error HV_BadSB();
error HV_BadStructures();
error HV_CustomerNotPermissioned();
error HV_ExistingWithdraw();
error HV_ExceedsCap();
error HV_ExceedsAvailable();
error HV_Initialized();
error HV_InsufficientFunds();
error HV_OptionNotExpired();
error HV_RoundClosed();
error HV_RoundNotClosed();
error HV_Unauthorized();
error HV_Uninitialized();

// VaultPauser
error VP_BadAddress();
error VP_CustomerNotPermissioned();
error VP_Overflow();
error VP_PositionPaused();
error VP_RoundOpen();
error VP_Unauthorized();
error VP_VaultNotPermissioned();

// VaultUtil
error VL_BadCap();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();
error VL_BadExpiryDate();
error VL_BadFee();
error VL_BadFeeAddress();
error VL_BadGrappaAddress();
error VL_BadId();
error VL_BadInstruments();
error VL_BadManagerAddress();
error VL_BadOracleAddress();
error VL_BadOwnerAddress();
error VL_BadPauserAddress();
error VL_BadPrecision();
error VL_BadProduct();
error VL_BadStrike();
error VL_BadStrikeAddress();
error VL_BadSupply();
error VL_BadToken();
error VL_BadUnderlyingAddress();
error VL_BadWeight();
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_Overflow();
error VL_Unauthorized();

// ShareMath
error SM_NPSLow();
error SM_Overflow();

// BatchAuction
error BA_AuctionClosed();
error BA_AuctionNotClosed();
error BA_AuctionSettled();
error BA_AuctionUnsettled();
error BA_BadAddress();
error BA_BadAmount();
error BA_BadBiddingAddress();
error BA_BadCollateral();
error BA_BadOptionAddress();
error BA_BadOptions();
error BA_BadPrice();
error BA_BadSize();
error BA_BadTime();
error BA_EmptyAuction();
error BA_Unauthorized();
error BA_Uninitialized();

// Whitelist
error WL_BadAddress();
error WL_BadRole();
error WL_Paused();
error WL_Unauthorized();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import { ISanctionsList } from "../interfaces/IWhitelist.sol";

import "../libraries/Errors.sol";

contract HashnoteWhitelistManager is Ownable, Pausable {
    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant CUSTOMER_ROLE = keccak256("CUSTOMER_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    bytes32 public constant OTC_ROLE = keccak256("OTC_ROLE");

    /*///////////////////////////////////////////////////////////////
                            Storage
    //////////////////////////////////////////////////////////////*/

    address public sanctionsOracle;

    mapping(bytes32 => mapping(address => bool)) public permissions;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() { }

    /**
     * @notice Sets the new oracle address
     * @param _sanctionsOracle is the address of the new oracle
     */
    function setSanctionsOracle(address _sanctionsOracle) external {
        _checkOwner();

        if (_sanctionsOracle == address(0)) revert WL_BadAddress();

        sanctionsOracle = _sanctionsOracle;
    }

    /**
     * @notice Checks if customer has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isCustomer(address _address) external view returns (bool) {
        return hasRoleAndNotSanctioned(CUSTOMER_ROLE, _address);
    }

    /**
     * @notice Checks if LP has been whitelisted
     * @param _address the address of the LP Wallet
     * @return value returning if allowed to transact
     */
    function isLP(address _address) external view returns (bool) {
        return hasRoleAndNotSanctioned(LP_ROLE, _address);
    }

    /**
     * @notice Checks if Vault has been whitelisted
     * @param _address the address of the Vault
     * @return value returning if allowed to transact
     */
    function isVault(address _address) external view returns (bool) {
        return hasRole(VAULT_ROLE, _address);
    }

    /*
     * @notice Checks if OTC has been whitelisted
     * @param _address the address of the OTC
     * @return value returning if allowed to transact
     */
    function isOTC(address _address) external view returns (bool) {
        return hasRoleAndNotSanctioned(OTC_ROLE, _address);
    }

    /**
     * @notice Checks if address has been whitelisted
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function engineAccess(address _address) external view returns (bool) {
        return (hasRole(VAULT_ROLE, _address) || hasRole(LP_ROLE, _address) || hasRole(CUSTOMER_ROLE, _address))
            && !_sanctioned(_address);
    }

    function grantRole(bytes32 role, address _address) external {
        _checkOwner();

        permissions[role][_address] = true;

        emit RoleGranted(role, _address, _msgSender());
    }

    function revokeRole(bytes32 role, address _address) external {
        _checkOwner();

        permissions[role][_address] = false;

        emit RoleRevoked(role, _address, _msgSender());
    }

    /**
     * @notice Checks if an address has a specific role and is not sanctioned
     * @param role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRoleAndNotSanctioned(bytes32 role, address _address) public view returns (bool) {
        return hasRole(role, _address) && !_sanctioned(_address);
    }

    /**
     * @notice Checks if an address has a specific role
     * @param role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRole(bytes32 role, address _address) public view returns (bool) {
        if (paused()) revert WL_Paused();

        if (role == bytes32(0)) revert WL_BadRole();
        if (_address == address(0)) revert WL_BadAddress();
        return permissions[role][_address];
    }

    /**
     * @notice Pauses whitelist
     * @dev reverts on any check of permissions preventing any movement of funds
     *      between vault, auction, and option protocol
     */
    function pause() public {
        _checkOwner();

        _pause();
    }

    /**
     * @notice Unpauses whitelist
     */
    function unpause() public {
        _checkOwner();

        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _checkOwner() internal view {
        if (owner() != _msgSender()) revert WL_Unauthorized();
    }

    /**
     * @notice Checks if an address is sanctioned
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function _sanctioned(address _address) internal view returns (bool) {
        if (_address == address(0)) revert WL_BadAddress();

        return sanctionsOracle != address(0) ? ISanctionsList(sanctionsOracle).isSanctioned(_address) : false;
    }
}