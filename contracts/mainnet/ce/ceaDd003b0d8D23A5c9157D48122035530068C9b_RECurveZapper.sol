// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IBridgeable
{
    struct BridgeInstruction
    {
        uint256 instructionId;
        uint256 value;
        address to;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event BridgeIn(uint256 indexed instructionId, address indexed to, uint256 value);
    event BridgeOut(address indexed from, address indexed controller, uint256 value);

    error ZeroAmount();
    error ZeroAddress();
    error ZeroArray();
    error DuplicateInstruction();
    error InvalidBridgeSignature();

    function isBridgeable() external view returns (bool);
    function bridgeInstructionFulfilled(uint256 instructionId) external view returns (bool);

    function bridgeIn(BridgeInstruction calldata instruction) external;
    function multiBridgeIn(BridgeInstruction[] calldata instructions) external;
    function bridgeOut(address controller, uint256 value) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./IRERC20.sol";
import "./IBridgeable.sol";

interface IBridgeRERC20 is IBridgeable, IMinter, IRERC20
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICanMint is IERC20
{
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20Full is IERC20Metadata, IERC20Permit {
    /** This function might not exist */
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IMinter
{
    event SetMinter(address user, bool canMint);
    
    error NotMinter();
    error NotMinterOwner();
    
    function isMinter(address user) external view returns (bool);
    
    function setMinter(address user, bool canMint) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IOwned
{
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    error NotOwner();
    error AlreadyInitialized();

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
    function claimOwnership() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Library/CheapSafeERC20.sol";

interface IRECoverable
{
    error NotRECoverableOwner();
    
    function recoverERC20(IERC20 token) external;
    function recoverNative() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IERC20Full.sol";

interface IRERC20 is IERC20Full
{
    error InsufficientAllowance();
    error InsufficientBalance();
    error TransferFromZeroAddress();
    error MintToZeroAddress();
    error DeadlineExpired();
    error InvalidPermitSignature();
    error NameMismatch();
    
    function isRERC20() external view returns (bool);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../IREStablecoins.sol";
import "../IREUSD.sol";
import "../IRECustodian.sol";

interface IREUSDMinterBase
{
    event MintREUSD(address indexed minter, IERC20 paymentToken, uint256 reusdAmount);

    function REUSD() external view returns (IREUSD);
    function stablecoins() external view returns (IREStablecoins);
    function totalMinted() external view returns (uint256);
    function totalReceived(IERC20 paymentToken) external view returns (uint256);
    function getREUSDAmount(IERC20 paymentToken, uint256 paymentTokenAmount) external view returns (uint256 reusdAmount);
    function custodian() external view returns (IRECustodian);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IUUPSUpgradeableVersion.sol";
import "./IRECoverable.sol";
import "./IOwned.sol";

interface IUpgradeableBase is IUUPSUpgradeableVersion, IRECoverable, IOwned
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface IUUPSUpgradeable
{
    event Upgraded(address newImplementation);

    error ProxyDelegateCallRequired();
    error DelegateCallForbidden();
    error ProxyNotActive();
    error NotUUPS();
    error UnsupportedProxiableUUID();
    error UpgradeCallFailed();
    
    function proxiableUUID() external view returns (bytes32);
    
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IUUPSUpgradeable.sol";

interface IUUPSUpgradeableVersion is IUUPSUpgradeable
{
    error UpgradeToSameVersion();

    function contractVersion() external view returns (uint256);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IMinter.sol";
import "../Library/Roles.sol";

/**
    Exposes minter role functionality
 */
abstract contract Minter is IMinter
{
    bytes32 private constant MinterRole = keccak256("ROLE:Minter");

    // Probably implemented using "Owned" contract functions
    function getMinterOwner() internal virtual view returns (address);

    function isMinter(address user)
        public
        view
        returns (bool)
    {
        return Roles.hasRole(MinterRole, user);
    }

    modifier onlyMinter()
    {
        if (!isMinter(msg.sender)) { revert NotMinter(); }
        _;
    }

    function setMinter(address user, bool canMint)
        public
    {
        if (msg.sender != getMinterOwner()) { revert NotMinterOwner(); }
        emit SetMinter(user, canMint);
        Roles.setRole(MinterRole, user, canMint);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IOwned.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
    Allows contract ownership, but not renunciation
 */
abstract contract Owned is IOwned
{
    bytes32 private constant OwnerSlot = keccak256("SLOT:Owned:owner");
    bytes32 private constant PendingOwnerSlot = keccak256("SLOT:Owned:pendingOwner");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable firstOwner = msg.sender;

    function owner() public view returns (address)
    {
        address o = StorageSlot.getAddressSlot(OwnerSlot).value;
        return o == address(0) ? firstOwner : o;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        StorageSlot.getAddressSlot(PendingOwnerSlot).value = newOwner;
    }

    function claimOwnership()
        public
    {
        StorageSlot.AddressSlot storage pending = StorageSlot.getAddressSlot(PendingOwnerSlot);
        if (pending.value != msg.sender) { revert NotOwner(); }
        emit OwnershipTransferred(owner(), msg.sender);
        pending.value = address(0);
        StorageSlot.getAddressSlot(OwnerSlot).value = msg.sender;
    }

    modifier onlyOwner() 
    {
        if (msg.sender != owner()) { revert NotOwner(); }
        _;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IRECoverable.sol";

using CheapSafeERC20 for IERC20;

/**
    Allows for recovery of funds
 */
abstract contract RECoverable is IRECoverable 
{
    // Probably implemented using "Owned" contract functions
    function getRECoverableOwner() internal virtual view returns (address);

    function recoverERC20(IERC20 token)
        public
    {
        if (msg.sender != getRECoverableOwner()) { revert NotRECoverableOwner(); }
        beforeRecoverERC20(token);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function beforeRecoverERC20(IERC20 token) internal virtual {}

    function recoverNative()
        public
    {
        if (msg.sender != getRECoverableOwner()) { revert NotRECoverableOwner(); }
        beforeRecoverNative();
        (bool success,) = msg.sender.call{ value: address(this).balance }(""); 
        assert(success);
    }

    function beforeRecoverNative() internal virtual {}
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../IREUSD.sol";
import "./IREUSDMinterBase.sol";
import "../Library/CheapSafeERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

using CheapSafeERC20 for IERC20;

/**
    Functionality for a contract that wants to mint REUSD

    It knows how to mint the correct amount and take payment from an accepted stablecoin
 */
abstract contract REUSDMinterBase is IREUSDMinterBase
{
    bytes32 private constant TotalMintedSlot = keccak256("SLOT:REUSDMinterBase:totalMinted");
    bytes32 private constant TotalReceivedSlotPrefix = keccak256("SLOT:REUSDMinterBase:totalReceived");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREUSD public immutable REUSD;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREStablecoins public immutable stablecoins;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRECustodian public immutable custodian;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _REUSD, IREStablecoins _stablecoins)
    {
        assert(_REUSD.isREUSD() && _stablecoins.isREStablecoins() && _custodian.isRECustodian());
        REUSD = _REUSD;
        stablecoins = _stablecoins;
        custodian = _custodian;
    }    

    function totalMinted() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalMintedSlot).value; }
    function totalReceivedSlot(IERC20 paymentToken) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(TotalReceivedSlotPrefix, paymentToken))); }
    function totalReceived(IERC20 paymentToken) public view returns (uint256) { return totalReceivedSlot(paymentToken).value; }

    /** 
        Gets the amount of REUSD that will be minted for an amount of an acceptable payment token
        Reverts if the payment token is not accepted
        
        All accepted stablecoins have 6 or 18 decimals
    */
    function getREUSDAmount(IERC20 paymentToken, uint256 paymentTokenAmount)
        public
        view
        returns (uint256 reusdAmount)
    {        
        return stablecoins.getStablecoinConfig(address(paymentToken)).decimals == 6 ? paymentTokenAmount * 10**12 : paymentTokenAmount;
    }

    /**
        This will:
            Take payment (or revert if the payment token is not acceptable)
            Send the payment to the custodian address
            Mint REUSD
     */
    function mintREUSDCore(address from, IERC20 paymentToken, address recipient, uint256 reusdAmount)
        internal
    {
        uint256 factor = stablecoins.getStablecoinConfig(address(paymentToken)).decimals == 6 ? 10**12 : 1;
        uint256 paymentAmount = reusdAmount / factor;
        unchecked { if (paymentAmount * factor != reusdAmount) { ++paymentAmount; } }
        paymentToken.safeTransferFrom(from, address(custodian), paymentAmount);
        REUSD.mint(recipient, reusdAmount);
        emit MintREUSD(from, paymentToken, reusdAmount);
        StorageSlot.getUint256Slot(TotalMintedSlot).value += reusdAmount;
        totalReceivedSlot(paymentToken).value += paymentAmount;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./UUPSUpgradeableVersion.sol";
import "./RECoverable.sol";
import "./Owned.sol";
import "./IUpgradeableBase.sol";

/**
    All deployable upgradeable contracts should derive from this
 */
abstract contract UpgradeableBase is UUPSUpgradeableVersion, RECoverable, Owned, IUpgradeableBase
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 __contractVersion)
        UUPSUpgradeableVersion(__contractVersion)
    {
    }

    function getRECoverableOwner() internal override view returns (address) { return owner(); }
    
    function beforeUpgradeVersion(address newImplementation)
        internal
        override
        view
        onlyOwner
    {
        checkUpgradeBase(newImplementation);
    }

    function checkUpgradeBase(address newImplementation) internal virtual view;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./IUUPSUpgradeable.sol";

/**
    Adapted from openzeppelin's UUPSUpgradeable

    However, with some notable differences
        
        We don't use the whole "initializers" scheme.  It's error-prone and awkward.  A couple contracts
        may have an initialize function, but it's not some special built-in scheme that can be screwed up.

        We don't use beacons, and we don't need to upgrade from old UUPS or other types of proxies.  We
        only support UUPS.  We don't support rollbacks.

        We don't use default-slot storage.  It's also error-prone and awkward.  It's weird that it was ever
        done that way in the first place.  But regardless, we don't.

        We have no concept of "Admin" at this stage.  Whoever implements "beforeUpgrade" can decide to
        check access if they want to.  For us, we do this in "UpgradeableBase".

 */

abstract contract UUPSUpgradeable is IUUPSUpgradeable
{
    bytes32 private constant ImplementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable self = address(this);

    function beforeUpgrade(address newImplementation) internal virtual view;
    
    modifier notDelegated()
    {
        if (address(this) != self) { revert DelegateCallForbidden(); }
        _;
    }

    modifier onlyProxy()
    {
        if (address(this) == self) { revert ProxyDelegateCallRequired(); }
        if (StorageSlot.getAddressSlot(ImplementationSlot).value != self) { revert ProxyNotActive(); }
        _;
    }

    function proxiableUUID()
        public
        virtual
        view
        notDelegated
        returns (bytes32)
    {
        return ImplementationSlot;
    }

    function upgradeTo(address newImplementation)
        public
        onlyProxy
    {
        try IUUPSUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot)
        {
            if (slot != ImplementationSlot) { revert UnsupportedProxiableUUID(); }
            beforeUpgrade(newImplementation);
            StorageSlot.getAddressSlot(ImplementationSlot).value = newImplementation;
            emit Upgraded(newImplementation);
        }
        catch
        {
            revert NotUUPS();
        }
    }
    
    function upgradeToAndCall(address newImplementation, bytes memory data)
        public
    {
        upgradeTo(newImplementation);
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool success, bytes memory returndata) = newImplementation.delegatecall(data);
        if (!success)
        {
            if (returndata.length > 0)
            {
                assembly
                {                                
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            revert UpgradeCallFailed();
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./IUUPSUpgradeableVersion.sol";

/**
    Adds contract versioning

    Contract upgrades to a new contract with the same version will be rejected
 */
abstract contract UUPSUpgradeableVersion is UUPSUpgradeable, IUUPSUpgradeableVersion
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable _contractVersion;

    function contractVersion() public virtual view returns (uint256) { return _contractVersion; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint256 __contractVersion)
    {
        _contractVersion = __contractVersion;
    }

    function beforeUpgrade(address newImplementation)
        internal
        override
        view
    {
        if (IUUPSUpgradeableVersion(newImplementation).contractVersion() == contractVersion()) { revert UpgradeToSameVersion(); }        
        beforeUpgradeVersion(newImplementation);
    }

    function beforeUpgradeVersion(address newImplementation) internal virtual view;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./ICurveStableSwap.sol";

interface ICurveGauge is IERC20Full
{
    struct Reward
    {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    function lp_token() external view returns (ICurveStableSwap);
    function deposit(uint256 amount, address receiver, bool _claim_rewards) external;
    function withdraw(uint256 amount, bool _claim_rewards) external;
    function claim_rewards(address addr) external;
    function working_supply() external view returns (uint256);
    function working_balances(address _user) external view returns (uint256);
    function claimable_tokens(address _user) external view returns (uint256);
    function claimable_reward(address _user, address _token) external view returns (uint256);
    function claimed_reward(address _user, address _token) external view returns (uint256);
    function reward_tokens(uint256 index) external view returns (address);
    function deposit_reward_token(address _token, uint256 amount) external;
    function reward_count() external view returns (uint256);
    function reward_data(address token) external view returns (Reward memory);
    
    /** Permission works only on sidechains */
    function add_reward(address _reward_token, address _distributor) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/IERC20Full.sol";

interface ICurvePool
{
    function coins(uint256 index) external view returns (IERC20Full);
    function balances(uint256 index) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

    function remove_liquidity(uint256 amount, uint256[2] memory minAmounts) external returns (uint256[2] memory receivedAmounts);
    function remove_liquidity(uint256 amount, uint256[3] memory minAmounts) external returns (uint256[3] memory receivedAmounts);
    function remove_liquidity(uint256 amount, uint256[4] memory minAmounts) external returns (uint256[4] memory receivedAmounts);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./ICurvePool.sol";

interface ICurveStableSwap is IERC20Full, ICurvePool
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IREUSD.sol";
import "./Base/IUpgradeableBase.sol";
import "./Curve/ICurveStableSwap.sol";
import "./IRECustodian.sol";

interface IRECurveBlargitrage is IUpgradeableBase
{
    error MissingDesiredToken();
    
    function isRECurveBlargitrage() external view returns (bool);
    function pool() external view returns (ICurveStableSwap);
    function basePool() external view returns (ICurvePool);
    function desiredToken() external view returns (IERC20);
    function REUSD() external view returns (IREUSD);
    function custodian() external view returns (IRECustodian);

    function balance() external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";
import "./Base/IERC20Full.sol";
import "./Base/IREUSDMinterBase.sol";
import "./Curve/ICurveStableSwap.sol";
import "./Curve/ICurvePool.sol";
import "./Curve/ICurveGauge.sol";

interface IRECurveZapper is IREUSDMinterBase, IUpgradeableBase
{
    error UnsupportedToken();
    error ZeroAmount();
    error PoolMismatch();
    error TooManyPoolCoins();
    error TooManyBasePoolCoins();
    error MissingREUSD();
    error BasePoolWithREUSD();

    function isRECurveZapper() external view returns (bool);
    function basePoolCoinCount() external view returns (uint256);
    function pool() external view returns (ICurveStableSwap);
    function basePool() external view returns (ICurvePool);
    function basePoolToken() external view returns (IERC20);
    function gauge() external view returns (ICurveGauge);

    function zap(IERC20 token, uint256 tokenAmount, bool mintREUSD) external;
    function zapPermit(IERC20Full token, uint256 tokenAmount, bool mintREUSD, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function unzap(IERC20 token, uint256 tokenAmount) external;    

    struct TokenAmount
    {        
        IERC20 token;
        uint256 amount;
    }
    struct PermitData
    {
        IERC20Full token;
        uint32 deadline;
        uint8 v;
        uint256 permitAmount;
        bytes32 r;
        bytes32 s;
    }

    function multiZap(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts) external;
    function multiZapPermit(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts, PermitData[] calldata permits) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IUpgradeableBase.sol";

interface IRECustodian is IUpgradeableBase
{
    function isRECustodian() external view returns (bool);
    function amountRecovered(address token) external view returns (uint256);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IERC20Full.sol";
import "./Base/IUpgradeableBase.sol";

interface IREStablecoins is IUpgradeableBase
{
    struct StablecoinConfig
    {
        IERC20Full token;
        uint8 decimals;
        bool hasPermit;
    }
    struct StablecoinConfigWithName
    {
        StablecoinConfig config;
        string name;
        string symbol;
    }

    error TokenNotSupported();
    error TokenMisconfigured();
    error StablecoinAlreadyExists();
    error StablecoinDoesNotExist();
    error StablecoinBakedIn();

    function isREStablecoins() external view returns (bool);
    function supportedStablecoins() external view returns (StablecoinConfigWithName[] memory);
    function getStablecoinConfig(address token) external view returns (StablecoinConfig memory config);

    function addStablecoin(address stablecoin, bool hasPermit) external;
    function removeStablecoin(address stablecoin) external;
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/IBridgeRERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREUSD is IBridgeRERC20, ICanMint, IUpgradeableBase
{
    function isREUSD() external view returns (bool);
    function url() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/*
    Adapted from openzeppelin's `Address.sol`    
*/

library CheapSafeCall
{
    /**
        Makes a call
        Returns true if the call succeeded, and it was to a contract address, and either nothing was returned or 'true' was returned
        It does not revert on failures
     */
    function callOptionalBooleanNoThrow(address addr, bytes memory data) 
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        return success && (result.length == 0 ? addr.code.length > 0 : abi.decode(result, (bool)));        
    }
    /**
        Makes a call
        Returns true if the call succeeded, and it was to a contract address, and either nothing was returned or 'true' was returned
        Returns false if 'false' was returned
        Returns false if the call failed and nothing was returned
        Bubbles up the revert reason if the call reverted
     */
    function callOptionalBoolean(address addr, bytes memory data) 
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        if (success) 
        {
            return result.length == 0 ? addr.code.length > 0 : abi.decode(result, (bool));
        }
        else 
        {
            if (result.length == 0) { return false; }
            assembly 
            {
                let resultSize := mload(result)
                revert(add(32, result), resultSize)
            }
        }        
    }
    /**
        Makes a call
        Returns true if the call succeded, and it was to a contract address (ignores any return value)        
        Returns false if the call succeeded and nothing was returned
        Bubbles up the revert reason if the call reverted
     */
    function call(address addr, bytes memory data)
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        if (success)
        {
            return result.length > 0 || addr.code.length > 0;
        }
        if (result.length == 0) { return false; }
        assembly 
        {
            let resultSize := mload(result)
            revert(add(32, result), resultSize)
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CheapSafeERC20.sol";
import "./CheapSafeCall.sol";

using CheapSafeERC20 for IERC20;

/**
    An attempt to more safely work with all the weird quirks of Curve

    Sometimes, Curve contracts have X interface.  Sometimes, they don't.  Sometimes, they return a value.  Sometimes, they don't.
 */

library CheapSafeCurve
{
    error AddCurveLiquidityFailed();
    error NoPoolTokensMinted();
    error RemoveCurveLiquidityOneCoinCallFailed();
    error InsufficientTokensReceived();

    /**
        We call "add_liquidity", ignoring any return value or lack thereof
        Instead, we check to see if any pool tokens were minted.  If not, we'll revert because we know the call failed.
        On success, we'll return however many new pool tokens were minted for us.
     */
    function safeAddLiquidityCore(address pool, IERC20 poolToken, bytes memory data)
        private
        returns (uint256 poolTokenAmount)
    {
        uint256 balance = poolToken.balanceOf(address(this));
        if (!CheapSafeCall.call(pool, data)) { revert AddCurveLiquidityFailed(); }
        uint256 newBalance = poolToken.balanceOf(address(this));
        if (newBalance <= balance) { revert NoPoolTokensMinted(); }
        unchecked { return newBalance - balance; }
    }

    function safeAddLiquidity(address pool, IERC20 poolToken, uint256[2] memory amounts, uint256 minMintAmount)
        internal
        returns (uint256 poolTokenAmount)
    {
        return safeAddLiquidityCore(pool, poolToken, abi.encodeWithSignature("add_liquidity(uint256[2],uint256)", amounts, minMintAmount));
    }

    function safeAddLiquidity(address pool, IERC20 poolToken, uint256[3] memory amounts, uint256 minMintAmount)
        internal
        returns (uint256 poolTokenAmount)
    {
        return safeAddLiquidityCore(pool, poolToken, abi.encodeWithSignature("add_liquidity(uint256[3],uint256)", amounts, minMintAmount));
    }

    function safeAddLiquidity(address pool, IERC20 poolToken, uint256[4] memory amounts, uint256 minMintAmount)
        internal
        returns (uint256 poolTokenAmount)
    {
        return safeAddLiquidityCore(pool, poolToken, abi.encodeWithSignature("add_liquidity(uint256[4],uint256)", amounts, minMintAmount));
    }

    /**
        We'll call "remove_liquidity_one_coin", ignoring any return value or lack thereof
        Instead, we'll check to see how many tokens we received.  If not enough, then we revert.
        On success, we'll return however many tokens we received
     */
    function safeRemoveLiquidityOneCoin(address pool, IERC20 token, uint256 tokenIndex, uint256 amount, uint256 minReceived, address receiver)
        internal
        returns (uint256 amountReceived)
    {
        uint256 balance = token.balanceOf(address(this));
        if (!CheapSafeCall.call(pool, abi.encodeWithSignature("remove_liquidity_one_coin(uint256,int128,uint256)", amount, int128(int256(tokenIndex)), 0))) { revert RemoveCurveLiquidityOneCoinCallFailed(); }
        uint256 newBalance = token.balanceOf(address(this));
        if (newBalance < balance + minReceived) { revert InsufficientTokensReceived(); }
        unchecked { amountReceived = newBalance - balance; }
        if (receiver != address(this))
        {
            token.safeTransfer(receiver, amountReceived);
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CheapSafeCall.sol";

/*
    Adapted from openzeppelin's `SafeERC20.sol`

    But implemented using custom errors, and with different 'safeApprove' functionality
*/

library CheapSafeERC20 
{
    error TransferFailed();
    error ApprovalFailed();

    /**
        Calls 'transfer' on an ERC20
        On failure, reverts with either the ERC20's error message or 'TransferFailed'
     */
    function safeTransfer(IERC20 token, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transfer.selector, to, value))) { revert TransferFailed(); }
    }

    /**
        Calls 'transferFrom' on an ERC20
        On failure, reverts with either the ERC20's error message or 'TransferFailed'
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value))) { revert TransferFailed(); }
    }

    /**
        Calls 'approve' on an ERC20
        If it fails, it attempts to approve for 0 amount then to the requested amount
        If that also fails, it will revert with either the ERC20's error message or 'ApprovalFailed'
     */
    function safeApprove(IERC20 token, address spender, uint256 value)
        internal
    {
        if (!CheapSafeCall.callOptionalBooleanNoThrow(address(token), abi.encodeWithSelector(token.approve.selector, spender, value)))
        {
            if (value == 0 ||
                !CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.approve.selector, spender, 0)) ||
                !CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.approve.selector, spender, value)))
            {
                revert ApprovalFailed(); 
            }
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
    Arbitrary 'role' functionality to assign roles to users
 */
library Roles
{
    error MissingRole();

    bytes32 private constant RoleSlotPrefix = keccak256("SLOT:Roles:role");

    function hasRole(bytes32 role, address user)
        internal
        view
        returns (bool)
    {
        return StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(RoleSlotPrefix, role, user))).value;
    }

    function setRole(bytes32 role, address user, bool enable)
        internal
    {
        StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(RoleSlotPrefix, role, user))).value = enable;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/UpgradeableBase.sol";
import "./IRECurveZapper.sol";
import "./Library/CheapSafeERC20.sol";
import "./Base/REUSDMinterBase.sol";
import "./Library/CheapSafeCurve.sol";
import "./IRECurveBlargitrage.sol";

using CheapSafeERC20 for IERC20;
using CheapSafeERC20 for ICurveStableSwap;

contract RECurveZapper is REUSDMinterBase, UpgradeableBase(2), IRECurveZapper
{
    /*
        addWrapper(unwrappedToken, supportedButWrappedToken, wrapSig, unwrapSig);
        ^-- potential approach to future strategy for pools dealing with wrapped assets
    */
    bool public constant isRECurveZapper = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveStableSwap public immutable pool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurvePool public immutable basePool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable basePoolToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable poolCoin0;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable poolCoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin0;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin1;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin2;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 immutable basePoolCoin3;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ICurveGauge public immutable gauge;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable basePoolCoinCount;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRECurveBlargitrage immutable blargitrage;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICurveGauge _gauge, IREStablecoins _stablecoins, IRECurveBlargitrage _blargitrage)
        REUSDMinterBase(_blargitrage.custodian(), _blargitrage.REUSD(), _stablecoins)
    {
        /*
            Stableswap pools:
                Always have 2 coins
                One of them must be REUSD
                The pool token is always the pool itself
            Other pools:
                Have at least 2 coins
                We support 2-4 coins
                Must not include REUSD
        */
        assert(_blargitrage.isRECurveBlargitrage());
        
        gauge = _gauge;
        blargitrage = _blargitrage;
        basePool = _blargitrage.basePool();
        pool = gauge.lp_token();
        poolCoin0 = pool.coins(0); 
        poolCoin1 = pool.coins(1);
        basePoolToken = address(poolCoin0) == address(REUSD) ? poolCoin1 : poolCoin0;

        if (pool != _blargitrage.pool()) { revert PoolMismatch(); }

        basePoolCoin0 = basePool.coins(0);
        basePoolCoin1 = basePool.coins(1);
        uint256 count = 2;
        try basePool.coins(2) returns (IERC20Full coin2)
        {
            basePoolCoin2 = coin2;
            count = 3;
            try basePool.coins(3) returns (IERC20Full coin3)
            {
                basePoolCoin3 = coin3;
                count = 4;
            }
            catch {}
        }
        catch {}
        basePoolCoinCount = count;

        try pool.coins(2) returns (IERC20Full) { revert TooManyPoolCoins(); } catch {}
        try basePool.coins(4) returns (IERC20Full) { revert TooManyBasePoolCoins(); } catch {}        

        if (address(poolCoin0) != address(REUSD) && address(poolCoin1) != address(REUSD)) { revert MissingREUSD(); }
        if (basePoolCoin0 == REUSD || basePoolCoin1 == REUSD || basePoolCoin2 == REUSD || basePoolCoin3 == REUSD) { revert BasePoolWithREUSD(); }
    }

    function initialize()
        public
    {
        poolCoin0.safeApprove(address(pool), type(uint256).max);
        poolCoin1.safeApprove(address(pool), type(uint256).max);
        basePoolCoin0.safeApprove(address(basePool), type(uint256).max);
        basePoolCoin1.safeApprove(address(basePool), type(uint256).max);
        if (address(basePoolCoin2) != address(0)) { basePoolCoin2.safeApprove(address(basePool), type(uint256).max); }
        if (address(basePoolCoin3) != address(0)) { basePoolCoin3.safeApprove(address(basePool), type(uint256).max); }
        basePoolToken.safeApprove(address(basePool), type(uint256).max);
        pool.safeApprove(address(gauge), type(uint256).max);
    }
    
    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IRECurveZapper(newImplementation).isRECurveZapper());
    }

    function isBasePoolToken(IERC20 token) 
        private
        view
        returns (bool)
    {
        return address(token) != address(0) &&
            (
                token == basePoolCoin0 ||
                token == basePoolCoin1 ||
                token == basePoolCoin2 ||
                token == basePoolCoin3
            );
    }

    function addBasePoolLiquidity(IERC20 token, uint256 amount)
        private
        returns (uint256)
    {
        uint256 amount0 = token == basePoolCoin0 ? amount : 0;
        uint256 amount1 = token == basePoolCoin1 ? amount : 0;
        if (basePoolCoinCount == 2)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1], 0);
        }
        uint256 amount2 = token == basePoolCoin2 ? amount : 0;
        if (basePoolCoinCount == 3)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1, amount2], 0);
        }
        uint256 amount3 = token == basePoolCoin3 ? amount : 0;
        return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amount0, amount1, amount2, amount3], 0);
    }

    function addBasePoolLiquidity(uint256[] memory amounts)
        private
        returns (uint256)
    {
        if (basePoolCoinCount == 2)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1]], 0);
        }
        if (basePoolCoinCount == 3)
        {
            return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1], amounts[2]], 0);
        }
        return CheapSafeCurve.safeAddLiquidity(address(basePool), basePoolToken, [amounts[0], amounts[1], amounts[2], amounts[3]], 0);
    }

    function zap(IERC20 token, uint256 tokenAmount, bool mintREUSD)
        public
    {
        if (tokenAmount == 0) { revert ZeroAmount(); }

        if (mintREUSD && token != REUSD) 
        {
            /*
                Convert whatever the user is staking into REUSD, and
                then continue onwards as if the user is staking REUSD
            */
            tokenAmount = getREUSDAmount(token, tokenAmount);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            mintREUSDCore(msg.sender, token, address(this), tokenAmount);
            token = REUSD;
        }
        else 
        {
            token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }
        
        if (isBasePoolToken(token)) 
        {
            /*
                Add liquidity to the base pool, and then continue onwards
                as if the user is staking the base pool token
            */
            tokenAmount = addBasePoolLiquidity(token, tokenAmount);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            token = address(poolCoin0) == address(REUSD) ? poolCoin1 : poolCoin0;
        }
        if (token == poolCoin0 || token == poolCoin1) 
        {
            /*
                Add liquidity to the pool, and then continue onwards as if
                the user is staking the pool token
            */
            tokenAmount = CheapSafeCurve.safeAddLiquidity(address(pool), pool, [
                token == poolCoin0 ? tokenAmount : 0,
                token == poolCoin1 ? tokenAmount : 0
                ], 0);
            if (tokenAmount == 0) { revert ZeroAmount(); }
            token = pool;
        }
        else if (token != pool) { revert UnsupportedToken(); }

        gauge.deposit(tokenAmount, msg.sender, true);

        blargitrage.balance();
    }

    function zapPermit(IERC20Full token, uint256 tokenAmount, bool mintREUSD, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        token.permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        zap(token, tokenAmount, mintREUSD);
    }

    function unzap(IERC20 token, uint256 tokenAmount)
        public
    {
        unzapCore(token, tokenAmount);
        blargitrage.balance();
    }

    function unzapCore(IERC20 token, uint256 tokenAmount)
        private
    {
        if (tokenAmount == 0) { revert ZeroAmount(); }       

        gauge.transferFrom(msg.sender, address(this), tokenAmount);
        gauge.claim_rewards(msg.sender);
        gauge.withdraw(tokenAmount, false);

        /*
            Now, we have pool tokens (1 gauge token yields 1 pool token)
        */

        if (token == pool)
        {
            // If they want the pool token, just send it and we're done
            token.safeTransfer(msg.sender, tokenAmount);
            return;
        }
        if (token == poolCoin0 || token == poolCoin1)
        {
            // If they want either REUSD or the base pool token, then
            // remove liquidity to them directly and we're done
            CheapSafeCurve.safeRemoveLiquidityOneCoin(address(pool), token, token == poolCoin0 ? 0 : 1, tokenAmount, 1, msg.sender);
            return;
        }
        
        if (!isBasePoolToken(token)) { revert UnsupportedToken(); }

        // They want one of the base pool coins, so remove pool
        // liquidity to get base pool tokens, then remove base pool
        // liquidity directly to the them
        tokenAmount = CheapSafeCurve.safeRemoveLiquidityOneCoin(address(pool), basePoolToken, poolCoin0 == basePoolToken ? 0 : 1, tokenAmount, 1, address(this));
        
        CheapSafeCurve.safeRemoveLiquidityOneCoin(
            address(basePool), 
            token, 
            token == basePoolCoin0 ? 0 : token == basePoolCoin1 ? 1 : token == basePoolCoin2 ? 2 : 3,
            tokenAmount, 
            1, 
            msg.sender);
    }

    function multiZap(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts)
        public
    {
        /*
            0-3 = basePoolCoin[0-3]
            4 = reusd
            5 = base pool token
            6 = pool token

            We'll loop through the parameters, adding whatever we find
            into the amounts[] array.

            Then we add base pool liquidity as required

            Then we add pool liquidity as required
        */
        uint256[] memory amounts = new uint256[](7);
        for (uint256 x = mints.length; x > 0;)
        {
            IERC20 token = mints[--x].token;
            uint256 amount = getREUSDAmount(token, mints[x].amount);
            mintREUSDCore(msg.sender, token, address(this), amount);
            amounts[4] += amount;
        }
        for (uint256 x = tokenAmounts.length; x > 0;)
        {
            IERC20 token = tokenAmounts[--x].token;
            uint256 amount = tokenAmounts[x].amount;
            if (token == basePoolCoin0)
            {
                amounts[0] += amount;
            }
            else if (token == basePoolCoin1)
            {
                amounts[1] += amount;
            }
            else if (token == basePoolCoin2)
            {
                amounts[2] += amount;
            }
            else if (token == basePoolCoin3)
            {
                amounts[3] += amount;
            }
            else if (token == REUSD)
            {
                amounts[4] += amount;
            }
            else if (token == basePoolToken)
            {
                amounts[5] += amount;
            }
            else if (token == pool)
            {
                amounts[6] += amount;
            }
            else 
            {
                revert UnsupportedToken();
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
        if (amounts[0] > 0 || amounts[1] > 0 || amounts[2] > 0 || amounts[3] > 0)
        {
            amounts[5] += addBasePoolLiquidity(amounts);
        }
        if (amounts[4] > 0 || amounts[5] > 0)
        {
            amounts[6] += CheapSafeCurve.safeAddLiquidity(address(pool), pool, poolCoin0 == REUSD ? [amounts[4], amounts[5]] : [amounts[5], amounts[4]], 0);            
        }
        if (amounts[6] == 0)
        {
            revert ZeroAmount();
        }

        gauge.deposit(amounts[6], msg.sender, true);

        blargitrage.balance();
    }

    function multiZapPermit(TokenAmount[] calldata mints, TokenAmount[] calldata tokenAmounts, PermitData[] calldata permits)
        public
    {
        for (uint256 x = permits.length; x > 0;)
        {
            --x;
            permits[x].token.permit(msg.sender, address(this), permits[x].permitAmount, permits[x].deadline, permits[x].v, permits[x].r, permits[x].s);
        }
        multiZap(mints, tokenAmounts);
    }
}