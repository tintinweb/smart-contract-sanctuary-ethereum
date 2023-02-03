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

import "./IBridgeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../Library/CheapSafeEC.sol";

/**
    Implements cross-chain bridging functionality (for our purposes, in an ERC20)

    The bridge (an off-chain process) can sign instructions for minting, which users can submit to the blockchain.

    Users can also send funds to the bridge, which can be detected by the bridge processor looking for "BridgeOut" events
 */
abstract contract Bridgeable is IBridgeable
{
    bytes32 private constant BridgeInstructionFulfilledSlotPrefix = keccak256("SLOT:Bridgeable:bridgeInstructionFulfilled");

    bool public constant isBridgeable = true;
    bytes32 private constant bridgeInTypeHash = keccak256("BridgeIn(uint256 instructionId,address to,uint256 value)");

    // A fully constructed contract would likely use "Minter" contract functions to implement this
    function bridgeCanMint(address user) internal virtual view returns (bool);
    // A fully constructed contract would likely use "RERC20" contract functions to implement these
    function bridgeSigningHash(bytes32 dataHash) internal virtual view returns (bytes32);
    function bridgeMint(address to, uint256 amount) internal virtual;
    function bridgeBurn(address from, uint256 amount) internal virtual;

    function checkUpgrade(address newImplementation)
        internal
        virtual
        view
    {
        assert(IBridgeable(newImplementation).isBridgeable());
    }

    function bridgeInstructionFulfilled(uint256 instructionId)
        public
        view
        returns (bool)
    {
        return StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(BridgeInstructionFulfilledSlotPrefix, instructionId))).value;
    }

    function throwStatus(uint256 status)
        private
        pure
    {
        if (status == 1) { revert ZeroAmount(); }
        if (status == 2) { revert InvalidBridgeSignature(); }
        if (status == 3) { revert DuplicateInstruction(); }
    }

    /** Returns 0 on success */
    function bridgeInCore(BridgeInstruction calldata instruction)
        private
        returns (uint256)
    {
        if (instruction.value == 0) { return 1; }
        if (!bridgeCanMint(
                CheapSafeEC.recover(
                    bridgeSigningHash(
                        keccak256(
                            abi.encode(
                                bridgeInTypeHash, 
                                instruction.instructionId,
                                instruction.to, 
                                instruction.value))),
                instruction.v,
                instruction.r,
                instruction.s))) 
        {
            return 2;
        }
        StorageSlot.BooleanSlot storage fulfilled = StorageSlot.getBooleanSlot(keccak256(abi.encodePacked(BridgeInstructionFulfilledSlotPrefix, instruction.instructionId)));
        if (fulfilled.value) { return 3; }
        fulfilled.value = true;
        bridgeMint(instruction.to, instruction.value);
        emit BridgeIn(instruction.instructionId, instruction.to, instruction.value);
        return 0;
    }

    /** Mints according to the bridge instruction, or reverts on failure */
    function bridgeIn(BridgeInstruction calldata instruction)
        public
    {
        uint256 status = bridgeInCore(instruction);
        if (status != 0) { throwStatus(status); }
    }

    /** Mints according to multiple bridge instructions.  Only reverts if no instructions succeeded */
    function multiBridgeIn(BridgeInstruction[] calldata instructions)
        public
    {
        bool anySuccess = false;
        uint256 status = 0;
        for (uint256 x = instructions.length; x > 0;) 
        {
            unchecked { --x; }
            status = bridgeInCore(instructions[x]);
            if (status == 0) { anySuccess = true; }
        }
        if (!anySuccess) 
        {
            throwStatus(status); 
            revert ZeroArray();
        }
    }

    /** Sends funds to the bridge */
    function bridgeOut(address controller, uint256 value)
        public
    {
        if (value == 0) { revert ZeroAmount(); }
        if (controller == address(0)) { revert ZeroAddress(); }
        bridgeBurn(msg.sender, value);
        emit BridgeOut(msg.sender, controller, value);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./RERC20.sol";
import "./IBridgeRERC20.sol";
import "./Bridgeable.sol";

/**
    A bridgeable ERC20 contract
*/
abstract contract BridgeRERC20 is RERC20, Minter, Bridgeable, IBridgeRERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(RERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        RERC20.checkUpgrade(newImplementation);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Minter.sol";
import "./SelfStakingERC20.sol";
import "./IBridgeSelfStakingERC20.sol";
import "./Bridgeable.sol";

/**
    A bridgeable self-staking ERC20 contract
*/
abstract contract BridgeSelfStakingERC20 is SelfStakingERC20, Minter, Bridgeable, IBridgeSelfStakingERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(SelfStakingERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        SelfStakingERC20.checkUpgrade(newImplementation);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

/**
    Functionality to help implement "permit" on ERC20's
 */
abstract contract EIP712 
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory name) 
    {
        nameHash = keccak256(bytes(name));
    }

    bytes32 private constant eip712DomainHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant versionHash = keccak256(bytes("1"));
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 public immutable nameHash;
    
    function domainSeparator()
        internal
        view
        returns (bytes32) 
    {
        // Can't cache this in an upgradeable contract unfortunately
        return keccak256(abi.encode(
            eip712DomainHash,
            nameHash,
            versionHash,
            block.chainid,
            address(this)));
    }
    
    function getSigningHash(bytes32 dataHash)
        internal
        view
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator(), dataHash));
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

import "./Minter.sol";
import "./ISelfStakingERC20.sol";
import "./IBridgeable.sol";

interface IBridgeSelfStakingERC20 is IBridgeable, IMinter, ISelfStakingERC20
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

import "./IRERC20.sol";
import "./IOwned.sol";

interface ISelfStakingERC20 is IRERC20
{
    event RewardAdded(uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event Excluded(address indexed user, bool excluded);

    error InvalidParameters();
    error TooMuch();
    error WrongRewardToken();
    error NotDelegatedClaimer();
    error NotRewardManager();
    error NotSelfStakingERC20Owner();

    function isSelfStakingERC20() external view returns (bool);
    function rewardToken() external view returns (IERC20);
    function isExcluded(address addr) external view returns (bool);
    function totalStakingSupply() external view returns (uint256);
    function rewardData() external view returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute);
    function pendingReward(address user) external view returns (uint256);
    function isDelegatedClaimer(address user) external view returns (bool);
    function isRewardManager(address user) external view returns (bool);

    function claim() external;
    
    function claimFor(address user) external;

    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp) external;
    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function setExcluded(address user, bool excluded) external;
    function setDelegatedClaimer(address user, bool enable) external;
    function setRewardManager(address user, bool enable) external;
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

import "./EIP712.sol";
import "./IRERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../Library/StringHelper.sol";
import "../Library/CheapSafeEC.sol";

/**
    Our ERC20 (also supporting "permit")

    RERC20... because RE... real estate... uh....... yeah.  It was just hard to name it.

    It does not use any default-slot storage
 */
abstract contract RERC20 is EIP712, IRERC20
{
    bytes32 private constant TotalSupplySlot = keccak256("SLOT:RERC20:totalSupply");
    bytes32 private constant BalanceSlotPrefix = keccak256("SLOT:RERC20:balanceOf");
    bytes32 private constant AllowanceSlotPrefix = keccak256("SLOT:RERC20:allowance");
    bytes32 private constant NoncesSlotPrefix = keccak256("SLOT:RERC20:nonces");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable nameBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable symbolBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint8 public immutable decimals;

    bool public constant isRERC20 = true;
    bool public constant isUUPSERC20 = true; // This can be removed after all deployed contracts are upgraded
    bytes32 private constant permitTypeHash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol, uint8 _decimals) 
        EIP712(_name)
    {
        nameBytes = StringHelper.toBytes32(_name);
        symbolBytes = StringHelper.toBytes32(_symbol);
        decimals = _decimals;
    }

    function name() public view returns (string memory) { return StringHelper.toString(nameBytes); }
    function symbol() public view returns (string memory) { return StringHelper.toString(symbolBytes); }
    function version() public pure returns (string memory) { return "1"; }

    function balanceSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(BalanceSlotPrefix, user))); }
    function allowanceSlot(address owner, address spender) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(AllowanceSlotPrefix, owner, spender))); }
    function noncesSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(NoncesSlotPrefix, user))); }

    function totalSupply() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalSupplySlot).value; }
    function balanceOf(address user) public view returns (uint256) { return balanceSlot(user).value; }
    function allowance(address owner, address spender) public view returns (uint256) { return allowanceSlot(owner, spender).value; }
    function nonces(address user) public view returns (uint256) { return noncesSlot(user).value; }

    function checkUpgrade(address newImplementation)
        internal
        virtual
        view
    {
        assert(IRERC20(newImplementation).isRERC20());
        assert(EIP712(newImplementation).nameHash() == nameHash);
    }

    function approveCore(address _owner, address _spender, uint256 _amount) internal returns (bool)
    {
        allowanceSlot(_owner, _spender).value = _amount;
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function transferCore(address _from, address _to, uint256 _amount) internal returns (bool)
    {
        if (_from == address(0)) { revert TransferFromZeroAddress(); }
        if (_to == address(0)) 
        {
            burnCore(_from, _amount);
            return true;
        }
        StorageSlot.Uint256Slot storage fromBalanceSlot = balanceSlot(_from);
        uint256 oldBalance = fromBalanceSlot.value;
        if (oldBalance < _amount) { revert InsufficientBalance(); }
        beforeTransfer(_from, _to, _amount);
        unchecked 
        {
            fromBalanceSlot.value = oldBalance - _amount; 
            balanceSlot(_to).value += _amount;
        }
        emit Transfer(_from, _to, _amount);
        afterTransfer(_from, _to, _amount);
        return true;
    }

    function mintCore(address _to, uint256 _amount) internal
    {
        if (_to == address(0)) { revert MintToZeroAddress(); }
        beforeMint(_to, _amount);
        StorageSlot.getUint256Slot(TotalSupplySlot).value += _amount;
        unchecked { balanceSlot(_to).value += _amount; }
        afterMint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burnCore(address _from, uint256 _amount) internal
    {
        StorageSlot.Uint256Slot storage fromBalance = balanceSlot(_from);
        uint256 oldBalance = fromBalance.value;
        if (oldBalance < _amount) { revert InsufficientBalance(); }
        beforeBurn(_from, _amount);
        unchecked
        {
            fromBalance.value = oldBalance - _amount;
            StorageSlot.getUint256Slot(TotalSupplySlot).value -= _amount;
        }
        emit Transfer(_from, address(0), _amount);
        afterBurn(_from, _amount);
    }

    function approve(address _spender, uint256 _amount) public returns (bool)
    {
        return approveCore(msg.sender, _spender, _amount);
    }

    function transfer(address _to, uint256 _amount) public returns (bool)
    {
        return transferCore(msg.sender, _to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
    {
        StorageSlot.Uint256Slot storage fromAllowance = allowanceSlot(_from, msg.sender);
        uint256 oldAllowance = fromAllowance.value;
        if (oldAllowance != type(uint256).max) 
        {
            if (oldAllowance < _amount) { revert InsufficientAllowance(); }
            unchecked { fromAllowance.value = oldAllowance - _amount; }
        }
        return transferCore(_from, _to, _amount);
    }

    function beforeTransfer(address _from, address _to, uint256 _amount) internal virtual {}
    function afterTransfer(address _from, address _to, uint256 _amount) internal virtual {}
    function beforeBurn(address _from, uint256 _amount) internal virtual {}
    function afterBurn(address _from, uint256 _amount) internal virtual {}
    function beforeMint(address _to, uint256 _amount) internal virtual {}
    function afterMint(address _to, uint256 _amount) internal virtual {}

    function DOMAIN_SEPARATOR() public view returns (bytes32) { return domainSeparator(); }

    function permit(address _owner, address _spender, uint256 _amount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public
    {
        if (block.timestamp > _deadline) { revert DeadlineExpired(); }
        uint256 nonce;
        unchecked { nonce = noncesSlot(_owner).value++; }
        address signer = CheapSafeEC.recover(getSigningHash(keccak256(abi.encode(permitTypeHash, _owner, _spender, _amount, nonce, _deadline))), _v, _r, _s);
        if (signer != _owner || signer == address(0)) { revert InvalidPermitSignature(); }
        approveCore(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./RERC20.sol";
import "./ISelfStakingERC20.sol";
import "../Library/CheapSafeERC20.sol";
import "../Library/Roles.sol";

using CheapSafeERC20 for IERC20;

/**
    An ERC20 which gives out staking rewards just for owning the token, without the need to interact with staking contracts

    This seems... odd.  But it was necessary to avoid weird problems with other approaches with a separate staking contract

    The functionality is similar to masterchef or other popular staking contracts, with some notable differences:

        Interacting with it doesn't trigger rewards to be sent to you automatically
            Instead, it's tracked via "Owed" storage slots
            Necessary to stop contracts from accidentally earning USDC (ie: Uniswap, Sushiswap, etc)
        We add a reward, and it's split evenly over a period of time
        We can exclude addresses from receiving rewards (curve pools, uniswap, sushiswap, etc)
 */
abstract contract SelfStakingERC20 is RERC20, ISelfStakingERC20
{
    bytes32 private constant TotalStakingSupplySlot = keccak256("SLOT:SelfStakingERC20:totalStakingSupply");
    bytes32 private constant TotalRewardDebtSlot = keccak256("SLOT:SelfStakingERC20:totalRewardDebt");
    bytes32 private constant TotalOwedSlot = keccak256("SLOT:SelfStakingERC20:totalOwed");
    bytes32 private constant RewardInfoSlot = keccak256("SLOT:SelfStakingERC20:rewardInfo");
    bytes32 private constant RewardPerShareSlot = keccak256("SLOT:SelfStakingERC20:rewardPerShare");
    bytes32 private constant UserRewardDebtSlotPrefix = keccak256("SLOT:SelfStakingERC20:userRewardDebt");
    bytes32 private constant UserOwedSlotPrefix = keccak256("SLOT:SelfStakingERC20:userOwed");

    bytes32 private constant DelegatedClaimerRole = keccak256("ROLE:SelfStakingERC20:delegatedClaimer");
    bytes32 private constant RewardManagerRole = keccak256("ROLE:SelfStakingERC20:rewardManager");
    bytes32 private constant ExcludedRole = keccak256("ROLE:SelfStakingERC20:excluded");

    struct RewardInfo 
    {
        uint32 lastRewardTimestamp;
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint160 amountToDistribute;
    }

    bool public constant isSelfStakingERC20 = true;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable rewardToken;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol, uint8 _decimals) 
        RERC20(_name, _symbol, _decimals)
    {
        rewardToken = _rewardToken;
    }

    // Probably hooked up using functions from "Owned"
    function getSelfStakingERC20Owner() internal virtual view returns (address);

    /** The total supply MINUS balances held by excluded addresses */
    function totalStakingSupply() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalStakingSupplySlot).value; }

    function userRewardDebtSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(UserRewardDebtSlotPrefix, user))); }
    function userOwedSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(UserOwedSlotPrefix, user))); }

    function isExcluded(address user) public view returns (bool) { return Roles.hasRole(ExcludedRole, user); }
    function isDelegatedClaimer(address user) public view returns (bool) { return Roles.hasRole(DelegatedClaimerRole, user); }
    function isRewardManager(address user) public view returns (bool) { return Roles.hasRole(RewardManagerRole, user); }

    modifier onlySelfStakingERC20Owner()
    {
        if (msg.sender != getSelfStakingERC20Owner()) { revert NotSelfStakingERC20Owner(); }
        _;
    }

    function getRewardInfo()
        internal
        view
        returns (RewardInfo memory rewardInfo)
    {
        unchecked
        {
            uint256 packed = StorageSlot.getUint256Slot(RewardInfoSlot).value;
            rewardInfo.lastRewardTimestamp = uint32(packed >> 224);
            rewardInfo.startTimestamp = uint32(packed >> 192);
            rewardInfo.endTimestamp = uint32(packed >> 160);
            rewardInfo.amountToDistribute = uint160(packed);
        }
    }
    function setRewardInfo(RewardInfo memory rewardInfo)
        internal
    {
        unchecked
        {
            StorageSlot.getUint256Slot(RewardInfoSlot).value = 
                (uint256(rewardInfo.lastRewardTimestamp) << 224) |
                (uint256(rewardInfo.startTimestamp) << 192) |
                (uint256(rewardInfo.endTimestamp) << 160) |
                uint256(rewardInfo.amountToDistribute);
        }
    }

    /** 
        Excludes/includes an address from being able to receive rewards

        Any rewards already owing will be lost to the user, and will end up being added into the rewards pool next time rewards are added
     */
    function setExcluded(address user, bool excluded)
        public
        onlySelfStakingERC20Owner
    {
        if (isExcluded(user) == excluded) { return; }

        /*
            Our strategy is
                Nuke their balance (forces calculations to be done, too) 
                Set them as excluded/included
                If they're being excluded, we nuke their owed rewards
                Restore their balance
        */
        
        uint256 balance = balanceOf(user);
        if (balance > 0)
        {
            burnCore(user, balance);
        }

        Roles.setRole(ExcludedRole, user, excluded);

        if (excluded)
        {
            StorageSlot.Uint256Slot storage owedSlot = userOwedSlot(user);
            uint256 oldOwed = owedSlot.value;
            if (oldOwed != 0)
            {
                owedSlot.value = 0;
                StorageSlot.getUint256Slot(TotalOwedSlot).value -= oldOwed;
            }
        }

        if (balance > 0)
        {
            mintCore(user, balance);
        }

        emit Excluded(user, excluded);
    }

    function checkUpgrade(address newImplementation)
        internal
        virtual
        override
        view
        onlySelfStakingERC20Owner
    {
        ISelfStakingERC20 newContract = ISelfStakingERC20(newImplementation);
        assert(newContract.isSelfStakingERC20());
        if (newContract.rewardToken() != rewardToken) { revert WrongRewardToken(); }
        super.checkUpgrade(newImplementation);
    }

    function rewardData()
        public
        view
        returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute)
    {
        RewardInfo memory rewardInfo = getRewardInfo();
        lastRewardTimestamp = rewardInfo.lastRewardTimestamp;
        startTimestamp = rewardInfo.startTimestamp;
        endTimestamp = rewardInfo.endTimestamp;
        amountToDistribute = rewardInfo.amountToDistribute;
    }

    /** Calculates how much NEW reward should be released based on the distribution rate and time passed */
    function calculateReward(RewardInfo memory reward)
        private
        view
        returns (uint256)
    {
        if (block.timestamp <= reward.lastRewardTimestamp ||
            reward.lastRewardTimestamp >= reward.endTimestamp ||
            block.timestamp <= reward.startTimestamp ||
            reward.startTimestamp == reward.endTimestamp)
        {
            return 0;
        }
        uint256 from = reward.lastRewardTimestamp < reward.startTimestamp ? reward.startTimestamp : reward.lastRewardTimestamp;
        uint256 until = block.timestamp < reward.endTimestamp ? block.timestamp : reward.endTimestamp;
        return reward.amountToDistribute * (until - from) / (reward.endTimestamp - reward.startTimestamp);
    }

    function pendingReward(address user)
        public
        view
        returns (uint256)
    {
        if (isExcluded(user)) { return 0; }
        uint256 perShare = StorageSlot.getUint256Slot(RewardPerShareSlot).value;
        RewardInfo memory reward = getRewardInfo();
        uint256 totalStaked = totalStakingSupply();
        if (totalStaked != 0) 
        {
            perShare += calculateReward(reward) * 1e30 / totalStaked;
        }
        return balanceOf(user) * perShare / 1e30 - userRewardDebtSlot(user).value + userOwedSlot(user).value;
    }

    /** Updates the state with any new rewards, and returns the new rewardPerShare multiplier */
    function update() 
        private
        returns (uint256 rewardPerShare)
    {
        StorageSlot.Uint256Slot storage rewardPerShareSlot = StorageSlot.getUint256Slot(RewardPerShareSlot);
        rewardPerShare = rewardPerShareSlot.value;        
        RewardInfo memory reward = getRewardInfo();
        uint256 rewardToAdd = calculateReward(reward);
        if (rewardToAdd == 0) { return rewardPerShare; }

        uint256 totalStaked = totalStakingSupply();
        if (totalStaked > 0) 
        {
            rewardPerShare += rewardToAdd * 1e30 / totalStaked;
            rewardPerShareSlot.value = rewardPerShare;
        }

        reward.lastRewardTimestamp = uint32(block.timestamp);
        setRewardInfo(reward);
    }

    /** Adds rewards and updates the timeframes.  Any leftover rewards not yet distributed are added */
    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp)
        public
    {
        if (!isRewardManager(msg.sender) && msg.sender != getSelfStakingERC20Owner()) { revert NotRewardManager(); }
        if (startTimestamp < block.timestamp) { startTimestamp = block.timestamp; }
        if (startTimestamp >= endTimestamp || endTimestamp > type(uint32).max) { revert InvalidParameters(); }
        uint256 rewardPerShare = update();
        rewardToken.transferFrom(msg.sender, address(this), amount);
        uint256 amountToDistribute = rewardToken.balanceOf(address(this)) + StorageSlot.getUint256Slot(TotalRewardDebtSlot).value - StorageSlot.getUint256Slot(TotalOwedSlot).value - totalStakingSupply() * rewardPerShare / 1e30;
        if (amountToDistribute > type(uint160).max) { revert TooMuch(); }
        setRewardInfo(RewardInfo({
            amountToDistribute: uint160(amountToDistribute),
            startTimestamp: uint32(startTimestamp),
            endTimestamp: uint32(endTimestamp),
            lastRewardTimestamp: uint32(block.timestamp)
        }));
        emit RewardAdded(amount);
    }

    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        IERC20Permit(address(rewardToken)).permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        addReward(amount, startTimestamp, endTimestamp);
    }

    /** Pays out all rewards */
    function claim()
        public
    {
        claimCore(msg.sender);
    }

    function claimFor(address user)
        public
    {
        if (!isDelegatedClaimer(msg.sender)) { revert NotDelegatedClaimer(); }
        claimCore(user);
    }

    function claimCore(address user)
        private
    {
        if (isExcluded(user)) { return; }
        uint256 rewardPerShare = update();
        StorageSlot.Uint256Slot storage owedSlot = userOwedSlot(user);
        uint256 oldOwed = owedSlot.value;
        StorageSlot.getUint256Slot(TotalOwedSlot).value -= oldOwed;
        StorageSlot.Uint256Slot storage rewardDebtSlot = userRewardDebtSlot(user);
        uint256 oldDebt = rewardDebtSlot.value;
        uint256 newDebt = balanceOf(user) * rewardPerShare / 1e30;
        uint256 claimAmount = oldOwed + newDebt - oldDebt;
        if (claimAmount == 0) { return; }
        owedSlot.value = 0;
        rewardDebtSlot.value = newDebt;
        StorageSlot.Uint256Slot storage totalRewardDebtSlot = StorageSlot.getUint256Slot(TotalRewardDebtSlot);
        totalRewardDebtSlot.value = totalRewardDebtSlot.value + newDebt - oldDebt;
        sendReward(user, claimAmount);
    }

    function sendReward(address user, uint256 amount)
        private
    {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (amount > balance)
        {
            userOwedSlot(user).value += amount - balance;
            StorageSlot.getUint256Slot(TotalOwedSlot).value += amount - balance;
            amount = balance;
        }
        rewardToken.safeTransfer(user, amount);
        emit RewardPaid(user, amount);
    }

    /** update() must be called before this */
    function updateOwed(address user, uint256 rewardPerShare, uint256 currentBalance, uint256 newBalance)
        private
    {
        StorageSlot.Uint256Slot storage rewardDebtSlot = userRewardDebtSlot(user);
        uint256 oldDebt = rewardDebtSlot.value;
        uint256 pending = currentBalance * rewardPerShare / 1e30 - oldDebt;
        StorageSlot.getUint256Slot(TotalOwedSlot).value += pending;
        userOwedSlot(user).value += pending;
        uint256 newDebt = newBalance * rewardPerShare / 1e30;
        rewardDebtSlot.value = newDebt;
        StorageSlot.Uint256Slot storage totalRewardDebtSlot = StorageSlot.getUint256Slot(TotalRewardDebtSlot);
        totalRewardDebtSlot.value = totalRewardDebtSlot.value + newDebt - oldDebt;
    }

    function setDelegatedClaimer(address user, bool enable)
        public
        onlySelfStakingERC20Owner
    {
        Roles.setRole(DelegatedClaimerRole, user, enable);
    }

    function setRewardManager(address user, bool enable)
        public
        onlySelfStakingERC20Owner
    {
        Roles.setRole(RewardManagerRole, user, enable);
    }

    function beforeTransfer(address _from, address _to, uint256 _amount) 
        internal
        override
    {
        bool fromExcluded = isExcluded(_from);
        bool toExcluded = isExcluded(_to);
        if (!fromExcluded || !toExcluded)
        {
            uint256 rewardPerShare = update();
            uint256 balance;
            if (!fromExcluded)
            {
                balance = balanceOf(_from);
                updateOwed(_from, rewardPerShare, balance, balance - _amount);
            }
            if (!toExcluded)
            {
                balance = balanceOf(_to);
                updateOwed(_to, rewardPerShare, balance, balance + _amount);
            }
        }
        if (fromExcluded || toExcluded)
        {
            StorageSlot.Uint256Slot storage totalStaked = StorageSlot.getUint256Slot(TotalStakingSupplySlot);
            totalStaked.value = 
                totalStaked.value
                + (fromExcluded ? _amount : 0)
                - (toExcluded ? _amount : 0);
        }
    }    

    function beforeBurn(address _from, uint256 _amount) 
        internal
        override
    {
        if (!isExcluded(_from))
        {
            uint256 rewardPerShare = update();
            uint256 balance = balanceOf(_from);
            updateOwed(_from, rewardPerShare, balance, balance - _amount);
            StorageSlot.getUint256Slot(TotalStakingSupplySlot).value -= _amount;
        }
    }

    function beforeMint(address _to, uint256 _amount) 
        internal
        override
    {
        if (!isExcluded(_to))
        {
            uint256 rewardPerShare = update();
            uint256 balance = balanceOf(_to);
            updateOwed(_to, rewardPerShare, balance, balance + _amount);
            StorageSlot.getUint256Slot(TotalStakingSupplySlot).value += _amount;
        }
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

import "./Base/IBridgeRERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREUP is IBridgeRERC20, ICanMint, IUpgradeableBase
{
    function isREUP() external view returns (bool);
    function url() external view returns (string memory);
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

import "./Base/IBridgeSelfStakingERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREYIELD is IBridgeSelfStakingERC20, ICanMint, IUpgradeableBase
{
    function isREYIELD() external view returns (bool);
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

/*
    A less bulky version of OpenZeppelin's anti-malleability stuff
*/
library CheapSafeEC
{
    error MalleableSignature();

    /** Recovers the signer address (or address(0)), while disallowing malleable high-S signatures */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (address signer)
    {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) { revert MalleableSignature(); }
        return ecrecover(hash, v, r, s);
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

/**
    Allows for conversions between bytes32 and string

    Not necessarily super efficient, but only used in constructors or view functions

    Used in our upgradeable ERC20 implementation so that strings can be stored as immutable bytes32
 */
library StringHelper
{
    error StringTooLong();

    /**
        Converts the string to bytes32
        Throws if 33 bytes or longer
        The string may not be well-formed and there may be dirty bytes after the null terminator, if there even IS a null terminator
    */
    function toBytes32(string memory str)
        internal
        pure
        returns (bytes32 val)
    {
        val = 0;
        if (bytes(str).length > 0) 
        { 
            if (bytes(str).length >= 33) { revert StringTooLong(); }
            assembly 
            {
                val := mload(add(str, 32))
            }
        }
    }

    /**
        Converts bytes32 back to string
        The string length is minimized; only characters before the first null byte are returned
     */
    function toString(bytes32 val)
        internal
        pure
        returns (string memory)
    {
        unchecked
        {
            uint256 x = 0;
            while (x < 32)
            {
                if (val[x] == 0) { break; }
                ++x;
            }
            bytes memory mem = new bytes(x);
            while (x-- > 0)
            {
                mem[x] = val[x];            
            }
            return string(mem);
        }
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeRERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREUP.sol";

/**
    The mysterious REUP token :)
 */
contract REUP is BridgeRERC20, UpgradeableBase(3), IREUP
{
    bool public constant isREUP = true;
    string public constant url = "https://reup.cash";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        RERC20(_name, _symbol, 18)
    {    
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUP(newImplementation).isREUP());
        BridgeRERC20.checkUpgrade(newImplementation);
    }

    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount)
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeRERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREUSD.sol";

/** REUSD = Real Estate USD, our stablecoin */
contract REUSD is BridgeRERC20, UpgradeableBase(3), IREUSD
{
    bool public constant isREUSD = true;
    string public constant url = "https://reup.cash";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        RERC20(_name, _symbol, 18)
    {    
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUSD(newImplementation).isREUSD());
        BridgeRERC20.checkUpgrade(newImplementation);
    }

    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount)
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeSelfStakingERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREYIELD.sol";

/** REYIELD = Real Estate Yields ... rental income or other income may be distributed to holders */
contract REYIELD is BridgeSelfStakingERC20, UpgradeableBase(4), IREYIELD
{
    bool public constant isREYIELD = true;
    string public constant url = "https://reup.cash";
    
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol)
        SelfStakingERC20(_rewardToken, _name, _symbol, 18)
    {
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREYIELD(newImplementation).isREYIELD());
        BridgeSelfStakingERC20.checkUpgrade(newImplementation);
    }

    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount) 
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/BridgeRERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestBridgeRERC20 is BridgeRERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() 
        RERC20("Test Token", "TST", 18) 
    {        
    }

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }
    
    function checkUpgradeBase(address newImplementation) internal override view {}
    function getMinterOwner() internal override view returns (address) { return owner(); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/BridgeSelfStakingERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestBridgeSelfStakingERC20 is BridgeSelfStakingERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken) 
        SelfStakingERC20(_rewardToken, "Test Token", "TST", 18)
    {        
    }

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view {}
    function getMinterOwner() internal override view returns (address) { return owner(); }
    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/ISelfStakingERC20.sol";
import "../Base/RERC20.sol";

contract TestREClaimer_SelfStakingERC20 is RERC20("Test", "TST", 18), ISelfStakingERC20
{
    address public claimForAddress;

    function isSelfStakingERC20() external view returns (bool) {}
    function rewardToken() external view returns (IERC20) {}
    function isExcluded(address addr) external view returns (bool) {}
    function totalStakingSupply() external view returns (uint256) {}
    function rewardData() external view returns (uint256 lastRewardTimestamp, uint256 startTimestamp, uint256 endTimestamp, uint256 amountToDistribute) {}
    function pendingReward(address user) external view returns (uint256) {}
    function isDelegatedClaimer(address user) external view returns (bool) {}
    function isRewardManager(address user) external view returns (bool) {}

    function claim() external {}
    
    function claimFor(address user) external { claimForAddress = user; }

    function addReward(uint256 amount, uint256 startTimestamp, uint256 endTimestamp) external {}
    function addRewardPermit(uint256 amount, uint256 startTimestamp, uint256 endTimestamp, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {}
    function setExcluded(address user, bool excluded) external {}
    function setDelegatedClaimer(address user, bool enable) external {}
    function setRewardManager(address user, bool enable) external {}
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/RERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestRERC20 is RERC20("Test Token", "TST", 18), UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view {}
    function mintDirect(address user, uint256 amount) public { mintCore(user, amount); }
    function burnDirect(address user, uint256 amount) public { burnCore(user, amount); }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REUP.sol";

contract TestREUP is REUP
{    
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        REUP(_name, _symbol)
    {
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REUSD.sol";

contract TestREUSD is REUSD
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        REUSD(_name, _symbol)
    {
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REYIELD.sol";

contract TestREYIELD is REYIELD
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol)
        REYIELD(_rewardToken, _name, _symbol)
    {
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/SelfStakingERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestSelfStakingERC20 is SelfStakingERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken)
        SelfStakingERC20(_rewardToken, "Test Token", "TST", 18)
    {}

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function burn(uint256 amount) public 
    {
        burnCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view { SelfStakingERC20.checkUpgrade(newImplementation); }
    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
    function _checkUpgrade(address newImplementation) public view { checkUpgrade(newImplementation); }
}