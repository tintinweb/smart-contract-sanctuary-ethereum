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

abstract contract Bridgeable is IBridgeable
{
    bytes32 private constant BridgeInstructionFulfilledSlotPrefix = keccak256("SLOT:Bridgeable:bridgeInstructionFulfilled");

    bool public constant isBridgeable = true;
    bytes32 private constant bridgeInTypeHash = keccak256("BridgeIn(uint256 instructionId,address to,uint256 value)");

    function bridgeCanMint(address user) internal virtual view returns (bool);
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

    function bridgeInCore(BridgeInstruction calldata instruction)
        private
        returns (uint256)
    {
        if (instruction.value == 0) { return 1; }
        if (!bridgeCanMint(
                ecrecover(
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

    function bridgeIn(BridgeInstruction calldata instruction)
        public
    {
        uint256 status = bridgeInCore(instruction);
        if (status != 0) { throwStatus(status); }
    }

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
import "./UUPSERC20.sol";
import "./IBridgeUUPSERC20.sol";
import "./Bridgeable.sol";

abstract contract BridgeUUPSERC20 is UUPSERC20, Minter, Bridgeable, IBridgeUUPSERC20
{
    function bridgeCanMint(address user) internal override view returns (bool) { return isMinter(user); }
    function bridgeSigningHash(bytes32 dataHash) internal override view returns (bytes32) { return getSigningHash(dataHash); }
    function bridgeMint(address to, uint256 amount) internal override { return mintCore(to, amount); }
    function bridgeBurn(address from, uint256 amount) internal override { return burnCore(from, amount); }
    
    function checkUpgrade(address newImplementation)
        internal
        virtual
        override(UUPSERC20, Bridgeable)
        view
    {
        Bridgeable.checkUpgrade(newImplementation);
        UUPSERC20.checkUpgrade(newImplementation);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

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
import "./IUUPSERC20.sol";
import "./IBridgeable.sol";

interface IBridgeUUPSERC20 is IBridgeable, IMinter, IUUPSERC20
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

import "./IUUPSUpgradeableVersion.sol";
import "./IRECoverable.sol";
import "./IOwned.sol";

interface IUpgradeableBase is IUUPSUpgradeableVersion, IRECoverable, IOwned
{
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./IERC20Full.sol";

interface IUUPSERC20 is IERC20Full
{
    error InsufficientAllowance();
    error InsufficientBalance();
    error TransferFromZeroAddress();
    error MintToZeroAddress();
    error DeadlineExpired();
    error InvalidPermitSignature();
    error NameMismatch();
    
    function isUUPSERC20() external view returns (bool);
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

abstract contract Minter is IMinter
{
    bytes32 private constant MinterRole = keccak256("ROLE:Minter");

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

abstract contract RECoverable is IRECoverable 
{
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

import "./UUPSUpgradeableVersion.sol";
import "./RECoverable.sol";
import "./Owned.sol";
import "./IUpgradeableBase.sol";

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

import "./EIP712.sol";
import "./IUUPSERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../Library/StringHelper.sol";

abstract contract UUPSERC20 is EIP712, IUUPSERC20
{
    bytes32 private constant TotalSupplySlot = keccak256("SLOT:UUPSERC20:totalSupply");
    bytes32 private constant BalanceSlotPrefix = keccak256("SLOT:UUPSERC20:balanceOf");
    bytes32 private constant AllowanceSlotPrefix = keccak256("SLOT:UUPSERC20:allowance");
    bytes32 private constant NoncesSlotPrefix = keccak256("SLOT:UUPSERC20:nonces");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable nameBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable symbolBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint8 public immutable decimals;

    bool public constant isUUPSERC20 = true;
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
        assert(IUUPSERC20(newImplementation).isUUPSERC20());
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
        address signer = ecrecover(getSigningHash(keccak256(abi.encode(permitTypeHash, _owner, _spender, _amount, nonce, _deadline))), _v, _r, _s);
        if (signer != _owner || signer == address(0)) { revert InvalidPermitSignature(); }
        approveCore(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "./IUUPSUpgradeable.sol";

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

import "./Base/IBridgeUUPSERC20.sol";
import "./Base/ICanMint.sol";
import "./Base/IUpgradeableBase.sol";

interface IREUSD is IBridgeUUPSERC20, ICanMint, IUpgradeableBase
{
    function isREUSD() external view returns (bool);
    function url() external view returns (string memory);
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

library CheapSafeCall
{
    function callOptionalBooleanNoThrow(address addr, bytes memory data) 
        internal
        returns (bool)
    {
        (bool success, bytes memory result) = addr.call(data);
        return success && (result.length == 0 ? addr.code.length > 0 : abi.decode(result, (bool)));        
    }
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
import "./CheapSafeCall.sol";

library CheapSafeERC20 
{
    error TransferFailed();
    error ApprovalFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transfer.selector, to, value))) { revert TransferFailed(); }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) 
        internal 
    {
        if (!CheapSafeCall.callOptionalBoolean(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value))) { revert TransferFailed(); }
    }

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

    modifier onlyRole(bytes32 role)
    {
        if (!hasRole(role, msg.sender)) { revert MissingRole(); }
        _;
    }
}

// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

library StringHelper
{
    error StringTooLong();

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

import "./Base/BridgeUUPSERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREUSD.sol";

contract REUSD is BridgeUUPSERC20, UpgradeableBase(1), IREUSD
{
    bool public constant isREUSD = true;
    string public constant url = "https://reup.cash";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        UUPSERC20(_name, _symbol, 18)
    {    
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUSD(newImplementation).isREUSD());
        BridgeUUPSERC20.checkUpgrade(newImplementation);
    }

    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount)
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}