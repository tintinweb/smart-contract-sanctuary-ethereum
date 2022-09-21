/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;


library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
library StorageSlotUpgradeable {
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

library SafeERC20 {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
         
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


interface interfaceful{
    function mintNFT(uint256 tokenId,string memory name, string memory tokenURI_,address user,string memory position, string memory rarity) external;
    function toLockId(uint _id, uint duration)external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) external;
    function burnNFT(uint256 tokenId,address user)external;
    function ownerOfNft(uint _id)external view returns(address);
    function upgradeToken(uint256 NftId,string memory rarity, string memory tokenURI_ )external;
    function rarityOfNft(uint256 nftId)external view returns(string memory);

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}



abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


  /**
    * @title "FulMint" contract.
    *       
    * @author Arpit Anand
    * @dev This smart contract is main contract which intract with FulNftGenerator contract to mint NFT
    *      This contact's functions is calling FULNftGenerator contract function to perform Mint, burn, Lock machanism.
    * 
    **/

contract FulMint is UUPSUpgradeable, OwnableUpgradeable{

    using SafeMathUpgradeable for uint;
    using SafeERC20 for IERC20;
    
    address ful;
    IERC20 private fulToken;

    uint private packId;
  

    event whiteListed(string  WhitelistingConfirmation);  
    event blackListed(string  BlackListingConfirmation);
    event RemovedwhiteListedUser(string  RemoveFromWhitelist);
    event RemovedwhiteListedUserForFreeMint(string  RemoveFromWhitelist);
    event packIdMinted(uint256 packid,uint256 nftID1, uint256 nftID2,uint256 nftID3);
    event burnNFTNewNFTMinted(uint256 nftID1, uint256 nftID2,uint256 nftID3, uint256  NftId);
    event rarityUpgraded(string  upgradedRarity,string updatedUri);
    
    mapping(uint256 => uint256) public ethPriceOfPack;       // Ehther Price of every pack.
    mapping(uint256 => uint256) public tokenPriceOfPack;     // Native Token(ERC20) price of every pack.
    mapping(address => uint) noOfBurnedNFT;                  // Burned NFT Id of user address.
    mapping(address => bool) public whitelistedAddresses;    // Whitelisted user by admin
    mapping(address => bool) public blackListedAddress;      // BlackListed user
    mapping(uint256 => bytes32) private rootOfPack;           // Storing root of all packs.
    mapping(address => uint256)public mintingCount;          // To restict user to buy only 5 pack by ETH.
    mapping(address => bool) public WhitelistedUserFreeMint; // these user can buy 5 random Pack for free. 

    modifier isWhitelisted() {
      require(whitelistedAddresses[msg.sender] == true || WhitelistedUserFreeMint[msg.sender] == true, "Whitelist: You need to be whitelisted");
      _;
    }
    
    constructor() {
        _disableInitializers();
    }
    

    function initialize(address _fulToken, address _FulNftGenerator) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        ful = _FulNftGenerator;
        fulToken = IERC20(_fulToken);
    }
    /**
     * @dev If some pack has need to updated or added so we need to update the root.
     *
     * @param packNumbers takes array of pack number.
     * @param root_ takes array of Root of packs.
     *
     **/
    function updateRoot(uint256[] memory packNumbers, bytes32[] memory root_)external onlyOwner{
        for(uint256 i = 0; i < packNumbers.length; i++){
            rootOfPack[packNumbers[i]] = root_[i];
        } 
        
    }

    /**
     * @dev The size of pack should be length of 13, same for the Root as well
     *
     * @param sizeOfPack Array Should must be length of 13.
     * @param rootHash Array of rootHash of packs.
     *
    **/

    function setRootOfPack(uint256[]memory sizeOfPack, bytes32[]memory rootHash) public onlyOwner{
        require(sizeOfPack.length <=14, "only 14 packs are allowed " );
        for(uint i=0; i<sizeOfPack.length;i++){
        rootOfPack[sizeOfPack[i]] = rootHash[i];
        }
    }

    
    /**
     * @dev one time a user can buy one pack only, by using this function pack can be bought by native token of platform.
     *      Only whiteListed user can buy Pack.
     *
     * @param _leaf takes 3 length of array of leafHash of NFT.
     * @param _proof takes array of hash to verify desired leaf is stored on IPFS or not.
     * @param  _noOfPack basically players are shorted inorder to rarity so in every pack there are set of players.
     * @param nftIDs takes array length of 3 NFT Id, which is passed by frontend.
     * @param nftName takes array length of 3 NFT player name.
     * @param tokenUri takes array length of 3 NFT matadata path of IPFS.
     * @param nftPosition To set Every NFT of their position of playing area like he is midfielder, attacker or defender.
     * @param nftRarity To set rarity of NFT.
     *
     **/
    function buyPackOfNFTByToken( bytes32[] memory _leaf, bytes32[][] memory _proof, uint _noOfPack,uint256[] memory nftIDs,string[] memory nftName, string[] memory tokenUri, string[] memory nftPosition,string[] memory nftRarity)public isWhitelisted{
        require(_noOfPack <= 13, "please choose pack between 1 to 13 ");
        require(verifyPacks(rootOfPack[_noOfPack], _leaf,_proof) == true,"unable to verify.");
    
        uint amount = tokenPriceOfPack[_noOfPack];
        fulToken.safeTransferFrom(msg.sender,address(this), amount);
        
        for(uint256 i=0;i<3;i++){
            interfaceful(ful).mintNFT(nftIDs[i], nftName[i],tokenUri[i], msg.sender, nftPosition[i],nftRarity[i]);
        }
        packId++;
        emit packIdMinted(packId, nftIDs[0],nftIDs[1],nftIDs[2]);

    }

    /**
     * @dev one time a user can buy one pack only, by using this function pack can be bought by ETH only.
     *      Only whiteListed user can buy Pack.
     *
     * @param _leaf takes 3 length of array of leafHash of NFT.
     * @param _proof takes array of hash to verify desired leaf is stored on IPFS or not.
     * @param  _noOfPack basically players are shorted inorder to rarity so in every pack there are set of players.
     * @param nftIDs takes array length of 3 NFT Id, which is passed by frontend.
     * @param nftName takes array length of 3 NFT player name.
     * @param tokenUri takes array length of 3 NFT matadata path of IPFS.
     * @param nftPosition To set Every NFT of their position of playing area like he is midfielder, attacker or defender.
     * @param nftRarity To set rarity of NFT.
     *
    **/

    function buyPackOfNFTByEth( bytes32[] memory _leaf, bytes32[][] memory _proof, uint _noOfPack,uint256[] memory nftIDs,string[] memory nftName, string[] memory tokenUri, string[] memory nftPosition,string[] memory nftRarity)public payable isWhitelisted{
        require(_noOfPack == 1, "You can buy only random pack by ETH");
        require(verifyPacks(rootOfPack[_noOfPack], _leaf,_proof) == true,"unable to verify.");
        require(mintingCount[msg.sender]<5,"A user can mint NFT 5 times only ");

        if(WhitelistedUserFreeMint[msg.sender]){
            for(uint256 i=0;i<3;i++){
            interfaceful(ful).mintNFT(nftIDs[i], nftName[i],tokenUri[i], msg.sender, nftPosition[i],nftRarity[i]);
            }
            packId++;
            mintingCount[msg.sender] = mintingCount[msg.sender].add(1);
            emit packIdMinted(packId, nftIDs[0], nftIDs[1],nftIDs[2]);
        }else{
            uint amount = ethPriceOfPack[_noOfPack];
            require(amount == msg.value,"Pack price Error");
        
            for(uint256 i=0;i<3;i++){
            interfaceful(ful).mintNFT(nftIDs[i], nftName[i],tokenUri[i], msg.sender, nftPosition[i],nftRarity[i]);
            }
            packId++;
            mintingCount[msg.sender] = mintingCount[msg.sender].add(1);
            emit packIdMinted(packId, nftIDs[0], nftIDs[1],nftIDs[2]);
        }
        

    }

    
    /**
     * @dev To proof leaf that exist in merkle tree or not we need proof path of Leaf.
     *      called internally by 'buyPack' function.
     *
     * @param root_ takes root hash of merkle tree.
     * @param _leaf takes array of leaf hash.
     * @param _proof path of leaf hash.
     *
     * @return if leaf is existing is root then it will return true otherwise return false.
     **/
    function verifyPacks(bytes32 root_, bytes32[] memory _leaf, bytes32[][] memory _proof) public pure returns(bool) {
        for(uint256 i=0; i<3; i++){
            if(verify(root_, _leaf[i], _proof[i]) == false){
                return false;
            }
        }
        return true;
    }

    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof)public pure returns (bool){
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
            // Hash(current computed hash + current element of the proof)
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            }   else {
            // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /**
     * @dev admin needs to allow user to use platform to mint NFT on their address,
     *      To allow Minting, needs to whiteList user first.
     *
     * @param _addressToWhitelist List of array of user whome admin wants to whitelist.
     *
     **/
    function addUserToWhiteList(address[] memory _addressToWhitelist) public onlyOwner {
        uint length = _addressToWhitelist.length;
        for(uint i=0 ; i<length ; i++){
            whitelistedAddresses[_addressToWhitelist[i]] = true;
        }
        emit whiteListed("WhiteListing Done");
      
    }

    /**
     * @dev admin needs to allow some user who can mint NFT for free,
     *      To allow minting, needs to whiteList user first.
     *
     * @param _addressToWhitelist List of array of user whome admin wants to whitelist.
     *
     **/
    function addUserToWhiteListForFreeMint(address[] memory _addressToWhitelist) public onlyOwner {
        uint length = _addressToWhitelist.length;
        for(uint i=0;i< length ; i++){
            WhitelistedUserFreeMint[_addressToWhitelist[i]] = true;
        }
      emit whiteListed("WhiteListing Done");
      
    }

    function removeUserfromFreeWhitelist(address[] memory _addressToRemove) public onlyOwner {
        uint length = _addressToRemove.length;
        for(uint i=0;i< length ; i++){
            WhitelistedUserFreeMint[_addressToRemove[i]] = false;
        }
        emit RemovedwhiteListedUserForFreeMint("Removed successfully");
      
    }

    /**
     * @dev admin can remove user from whitelist.
     *     
     * @param _addressToRemove List of array of user whome admin wants to remove from whitelist.
     *
    **/

    function removeWhiteListedUser(address[]memory _addressToRemove)public onlyOwner{
        uint256 length = _addressToRemove.length;
        for(uint i=0;i < length;i++){
            whitelistedAddresses[_addressToRemove[i]] = false;
        }
        emit RemovedwhiteListedUser("User removed");
    }

    /**
     * @dev admin can Blacklist user to not use thair plateform.
     *     
     * @param _addressToBlackList List of array of user whome admin wants to blacklist.
     *
    **/
    function addUserToBlackList(address[] calldata _addressToBlackList) public onlyOwner {
        uint256 length = _addressToBlackList.length;
        for(uint i=0 ; i< length ; i++){
            blackListedAddress[_addressToBlackList[i]] = true;
        }
        emit blackListed("BlackListing Done");
      
    }

    // To Check address is whiteListed or Not.
    function verifyUser(address _whitelistedAddress) public view returns(bool) {
      bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }

    /**
     * @dev Before minting owner needs to set every pack price in ETH.
     *
     * @param packNumber takes  pack number to set price for pack.
     * @param _price of  pack in ETH.
     *
     **/
    function setPackPriceForEth(uint256  packNumber, uint256 _price)public onlyOwner{
        ethPriceOfPack[packNumber] = _price;  
    }

    /**
     * @dev Before minting owner needs to set every pack price in native Token.
     *
     * @param packNumber takes array of pack number to set price for each pack.
     * @param _price of each pack in native Token.
     *
    **/
    function setPackPriceForToken(uint256[]memory  packNumber, uint256[]memory _price)public onlyOwner{
        uint256 length_ =  packNumber.length;
        for(uint256 i; i < length_; i++){
            tokenPriceOfPack[packNumber[i]] = _price[i];
        }   
    }

   
    /**
    * @dev if user want to burn their NFT they can burn and after burning 3 NFT user will get 1 random NFT.
    *
    * @param NftID is list of NFT id user want to burn.
    * @param _leaf is which leaf of nft will be mint to user who has burned 3 NFT.
    * @param nftId is id of NFT which user will get.
    * @param nftName takes NFT player name.
    * @param tokenUri takes NFT matadata path of IPFS.
    * @param nftPosition To set NFT of their position of playing area like he is midfielder, attacker or defender.
    * @param nftRarity To set rarity of NFT.
    **/
    function burnNFTId(uint256[]memory NftID, bytes32  _leaf, bytes32[] memory _proof, uint256 nftId, string memory nftName,string memory tokenUri,string memory nftPosition, string memory nftRarity)public {
        require(verify(rootOfPack[14], _leaf,_proof) == true,"Getting wrong leaf or proof ");
        for(uint i = 0; i<=2; i++){
            require(interfaceful(ful).ownerOfNft(NftID[i]) == msg.sender," Only NFT owner can burn token  ");
            interfaceful(ful).burnNFT(NftID[i],msg.sender);
            noOfBurnedNFT[msg.sender] = noOfBurnedNFT[msg.sender].add(1);
            if(noOfBurnedNFT[msg.sender] == 3){
                noOfBurnedNFT[msg.sender]=0;
                interfaceful(ful).mintNFT(nftId, nftName,tokenUri, msg.sender, nftPosition,nftRarity);
            }
        }
        emit burnNFTNewNFTMinted(NftID[0], NftID[1],NftID[2],nftId);
    } 

    function burnNFT(uint256 NFTId)external {
        require(interfaceful(ful).ownerOfNft(NFTId) == msg.sender," Only NFT owner can burn token  ");
        interfaceful(ful).burnNFT(NFTId,msg.sender);

    }

    
    
    // /**
    //  * @dev if any user want to upgrade their NFT rarity then user need to burn  common or rare NFT.
    //  *       To upgrade common to Rare user need to pay 500 native token .
    //  *       To upgrade rare to legendary user need to pay 1000 native token. 
    //  *
    //  * @param NftId which user wants to upgrade.
    //  * @param rarity current rarity of id which user wants to upgrade.
    //  * @param nftIdToBurn this NFT id should be "rare" rarity.
    //  * @param tokenURI_ updated TokenUri of NFT.
    //  *
    // **/
    function upgradeNftRarity(uint256 nftIdToUpgrade, string memory tokenURI_, string memory _rarity)public  {
        require(keccak256(bytes(interfaceful(ful).rarityOfNft(nftIdToUpgrade))) == keccak256(bytes("common")) ||keccak256(bytes(interfaceful(ful).rarityOfNft(nftIdToUpgrade))) == keccak256(bytes("rare")),"Only common or rare Nft is allowed to upgrade");
        require(interfaceful(ful).ownerOfNft(nftIdToUpgrade) == msg.sender," Only NFT owner can upgrade Their Token ");
    
        if(keccak256(bytes(interfaceful(ful).rarityOfNft(nftIdToUpgrade))) == keccak256(bytes("common"))){
            fulToken.safeTransferFrom(msg.sender,address(this), 500);
        }

        if(keccak256(bytes(interfaceful(ful).rarityOfNft(nftIdToUpgrade))) == keccak256(bytes("rare"))){
            fulToken.safeTransferFrom(msg.sender,address(this), 1000);
        }
        interfaceful(ful).upgradeToken(nftIdToUpgrade,_rarity,tokenURI_ );
        emit rarityUpgraded(_rarity,tokenURI_);
        
    }

    /**
     * @dev Safely transfers `tokenId` token from `userAddress` to `to`.
    **/
    function tansferNFT(address to, uint _id)public  {
        interfaceful(ful).transferFrom(msg.sender, to, _id);
    }

    /**
     * @dev Returns the number of tokens in contract address.
    **/
    function balanceOf()public view returns(uint){
        return fulToken.balanceOf(address(this));

    }

    /**
     * @dev Returns the ETH stored in contract address.
    **/
    function ethBalance()public view returns(uint256){
        return address(this).balance;
    }

    receive() external payable {
        // React to receiving ether
    }

    function withdrawEther() public onlyOwner  {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawToken(uint _amount)public onlyOwner{
        fulToken.transfer(msg.sender, _amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}



}