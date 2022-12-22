// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

interface IERC20MetadataUppercase {
    function NAME() external view returns (string memory); // solhint-disable-line func-name-mixedcase

    function SYMBOL() external view returns (string memory); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

/// @title Library that implements address array on mapping, stores array length at 0 index.
library AddressArray {
    error IndexOutOfBounds();
    error PopFromEmptyArray();
    error OutputArrayTooSmall();

    /// @dev Data struct containing raw mapping.
    struct Data {
        mapping(uint256 => uint256) _raw;
    }

    /// @dev Length of array.
    function length(Data storage self) internal view returns (uint256) {
        return self._raw[0] >> 160;
    }

    /// @dev Returns data item from `self` storage at `i`.
    function at(Data storage self, uint256 i) internal view returns (address) {
        return address(uint160(self._raw[i]));
    }

    /// @dev Returns list of addresses from storage `self`.
    function get(Data storage self) internal view returns (address[] memory arr) {
        uint256 lengthAndFirst = self._raw[0];
        arr = new address[](lengthAndFirst >> 160);
        _get(self, arr, lengthAndFirst);
    }

    /// @dev Puts list of addresses from `self` storage into `output` array.
    function get(Data storage self, address[] memory output) internal view returns (address[] memory) {
        return _get(self, output, self._raw[0]);
    }

    function _get(
        Data storage self,
        address[] memory output,
        uint256 lengthAndFirst
    ) private view returns (address[] memory) {
        uint256 len = lengthAndFirst >> 160;
        if (len > output.length) revert OutputArrayTooSmall();
        if (len > 0) {
            output[0] = address(uint160(lengthAndFirst));
            unchecked {
                for (uint256 i = 1; i < len; i++) {
                    output[i] = address(uint160(self._raw[i]));
                }
            }
        }
        return output;
    }

    /// @dev Array push back `account` operation on storage `self`.
    function push(Data storage self, address account) internal returns (uint256) {
        unchecked {
            uint256 lengthAndFirst = self._raw[0];
            uint256 len = lengthAndFirst >> 160;
            if (len == 0) {
                self._raw[0] = (1 << 160) + uint160(account);
            } else {
                self._raw[0] = lengthAndFirst + (1 << 160);
                self._raw[len] = uint160(account);
            }
            return len + 1;
        }
    }

    /// @dev Array pop back operation for storage `self`.
    function pop(Data storage self) internal {
        unchecked {
            uint256 lengthAndFirst = self._raw[0];
            uint256 len = lengthAndFirst >> 160;
            if (len == 0) revert PopFromEmptyArray();
            self._raw[len - 1] = 0;
            if (len > 1) {
                self._raw[0] = lengthAndFirst - (1 << 160);
            }
        }
    }

    /// @dev Set element for storage `self` at `index` to `account`.
    function set(
        Data storage self,
        uint256 index,
        address account
    ) internal {
        uint256 len = length(self);
        if (index >= len) revert IndexOutOfBounds();

        if (index == 0) {
            self._raw[0] = (len << 160) | uint160(account);
        } else {
            self._raw[index] = uint160(account);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "./AddressArray.sol";

/** @title Library that is using AddressArray library for AddressArray.Data
 * and allows Set operations on address storage data:
 * 1. add
 * 2. remove
 * 3. contains
 */
library AddressSet {
    using AddressArray for AddressArray.Data;

    /** @dev Data struct from AddressArray.Data items
     * and lookup mapping address => index in data array.
     */
    struct Data {
        AddressArray.Data items;
        mapping(address => uint256) lookup;
    }

    /// @dev Length of data storage.
    function length(Data storage s) internal view returns (uint256) {
        return s.items.length();
    }

    /// @dev Returns data item from `s` storage at `index`.
    function at(Data storage s, uint256 index) internal view returns (address) {
        return s.items.at(index);
    }

    /// @dev Returns true if storage `s` has `item`.
    function contains(Data storage s, address item) internal view returns (bool) {
        return s.lookup[item] != 0;
    }

    /// @dev Adds `item` into storage `s` and returns true if successful.
    function add(Data storage s, address item) internal returns (bool) {
        if (s.lookup[item] > 0) {
            return false;
        }
        s.lookup[item] = s.items.push(item);
        return true;
    }

    /// @dev Removes `item` from storage `s` and returns true if successful.
    function remove(Data storage s, address item) internal returns (bool) {
        uint256 index = s.lookup[item];
        if (index == 0) {
            return false;
        }
        if (index < s.items.length()) {
            unchecked {
                address lastItem = s.items.at(s.items.length() - 1);
                s.items.set(index - 1, lastItem);
                s.lookup[lastItem] = index;
            }
        }
        s.items.pop();
        delete s.lookup[item];
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

/// @title Revert reason forwarder.
library RevertReasonForwarder {
    /// @dev Forwards latest externall call revert.
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../libraries/RevertReasonForwarder.sol";

/// @title Implements efficient safe methods for ERC20 interface.
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /// @dev If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry.
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /// @dev Allowance increase with safe math check.
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /// @dev Allowance decrease with safe math check.
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    /// @dev Calls either ERC20 or Dai `permit` for `token`, if unsuccessful forwards revert from external call.
    function safePermit(IERC20 token, bytes calldata permit) internal {
        if (!tryPermit(token, permit)) RevertReasonForwarder.reRevert();
    }

    function tryPermit(IERC20 token, bytes calldata permit) internal returns(bool) {
        if (permit.length == 32 * 7) {
            return _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        }
        if (permit.length == 32 * 8) {
            return _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        }
        revert SafePermitBadLength();
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function _makeCalldataCall(
        IERC20 token,
        bytes4 selector,
        bytes calldata args
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

/// @title Library with gas-efficient string operations
library StringUtil {
    function toHex(uint256 value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    function toHex(address value) internal pure returns (string memory) {
        return toHex(abi.encodePacked(value));
    }

    /// @dev this is the assembly adaptation of highly optimized toHex16 code from Mikhail Vladimirov
    /// https://stackoverflow.com/a/69266989
    function toHex(bytes memory data) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            function _toHex16(input) -> output {
                output := or(
                    and(input, 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000),
                    shr(64, and(input, 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000))
                )
                output := or(
                    and(output, 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000),
                    shr(32, and(output, 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000))
                )
                output := or(
                    and(output, 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000),
                    shr(16, and(output, 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000))
                )
                output := or(
                    and(output, 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000),
                    shr(8, and(output, 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000))
                )
                output := or(
                    shr(4, and(output, 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000)),
                    shr(8, and(output, 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00))
                )
                output := add(
                    add(0x3030303030303030303030303030303030303030303030303030303030303030, output),
                    mul(
                        and(
                            shr(4, add(output, 0x0606060606060606060606060606060606060606060606060606060606060606)),
                            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F
                        ),
                        7 // Change 7 to 39 for lower case output
                    )
                )
            }

            result := mload(0x40)
            let length := mload(data)
            let resultLength := shl(1, length)
            let toPtr := add(result, 0x22) // 32 bytes for length + 2 bytes for '0x'
            mstore(0x40, add(toPtr, resultLength)) // move free memory pointer
            mstore(add(result, 2), 0x3078) // 0x3078 is right aligned so we write to `result + 2`
            // to store the last 2 bytes in the beginning of the string
            mstore(result, add(resultLength, 2)) // extra 2 bytes for '0x'

            for {
                let fromPtr := add(data, 0x20)
                let endPtr := add(fromPtr, length)
            } lt(fromPtr, endPtr) {
                fromPtr := add(fromPtr, 0x20)
            } {
                let rawData := mload(fromPtr)
                let hexData := _toHex16(rawData)
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
                hexData := _toHex16(shl(128, rawData))
                mstore(toPtr, hexData)
                toPtr := add(toPtr, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IERC20MetadataUppercase.sol";
import "./SafeERC20.sol";
import "./StringUtil.sol";

/// @title Library, which allows usage of ETH as ERC20 and ERC20 itself. Uses SafeERC20 library for ERC20 interface.
library UniERC20 {
    using SafeERC20 for IERC20;

    error InsufficientBalance();
    error ApproveCalledOnETH();
    error NotEnoughValue();
    error FromIsNotSender();
    error ToIsNotThis();
    error ETHTransferFailed();

    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;
    IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    /// @dev Returns true if `token` is ETH.
    function isETH(IERC20 token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }

    /// @dev Returns `account` ERC20 `token` balance.
    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    /// @dev `token` transfer `to` `amount`.
    /// Note that this function does nothing in case of zero amount.
    function uniTransfer(
        IERC20 token,
        address payable to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (address(this).balance < amount) revert InsufficientBalance();
                // solhint-disable-next-line avoid-low-level-calls
                (bool success, ) = to.call{value: amount, gas: _RAW_CALL_GAS_LIMIT}("");
                if (!success) revert ETHTransferFailed();
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    /// @dev `token` transfer `from` `to` `amount`.
    /// Note that this function does nothing in case of zero amount.
    function uniTransferFrom(
        IERC20 token,
        address payable from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                if (msg.value < amount) revert NotEnoughValue();
                if (from != msg.sender) revert FromIsNotSender();
                if (to != address(this)) revert ToIsNotThis();
                if (msg.value > amount) {
                    // Return remainder if exist
                    unchecked {
                        // solhint-disable-next-line avoid-low-level-calls
                        (bool success, ) = from.call{value: msg.value - amount, gas: _RAW_CALL_GAS_LIMIT}("");
                        if (!success) revert ETHTransferFailed();
                    }
                }
            } else {
                token.safeTransferFrom(from, to, amount);
            }
        }
    }

    /// @dev Returns `token` symbol from ERC20 metadata.
    function uniSymbol(IERC20 token) internal view returns (string memory) {
        return _uniDecode(token, IERC20Metadata.symbol.selector, IERC20MetadataUppercase.SYMBOL.selector);
    }

    /// @dev Returns `token` name from ERC20 metadata.
    function uniName(IERC20 token) internal view returns (string memory) {
        return _uniDecode(token, IERC20Metadata.name.selector, IERC20MetadataUppercase.NAME.selector);
    }

    /// @dev Reverts if `token` is ETH, otherwise performs ERC20 forceApprove.
    function uniApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (isETH(token)) revert ApproveCalledOnETH();

        token.forceApprove(to, amount);
    }

    /// @dev 20K gas is provided to account for possible implementations of name/symbol
    /// (token implementation might be behind proxy or store the value in storage)
    function _uniDecode(
        IERC20 token,
        bytes4 lowerCaseSelector,
        bytes4 upperCaseSelector
    ) private view returns (string memory result) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{gas: 20000}(
            abi.encodeWithSelector(lowerCaseSelector)
        );
        if (!success) {
            (success, data) = address(token).staticcall{gas: 20000}(abi.encodeWithSelector(upperCaseSelector));
        }

        if (success && data.length >= 0x40) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            /*
                return data is padded up to 32 bytes with ABI encoder also sometimes
                there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that overall data length is greater or equal than string length + extra 64 bytes
            */
            if (offset == 0x20 && data.length >= 0x40 + len) {
                /// @solidity memory-safe-assembly
                assembly { // solhint-disable-line no-inline-assembly
                    result := add(data, 0x40)
                }
                return result;
            }
        }
        if (success && data.length == 32) {
            uint256 len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                unchecked {
                    len++;
                }
            }

            if (len > 0) {
                /// @solidity memory-safe-assembly
                assembly { // solhint-disable-line no-inline-assembly
                    mstore(data, len)
                }
                return string(data);
            }
        }

        return StringUtil.toHex(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../WhitelistRegistry.sol";

contract WhitelistHelper {
    WhitelistRegistry public immutable whitelistRegistry;
    IERC20 public immutable delegation;

    constructor(WhitelistRegistry whitelistRegistry_) {
        whitelistRegistry = whitelistRegistry_;
        delegation = IERC20(whitelistRegistry.token());
    }

    function getMinAmountForWhitelisted() external view returns (uint256) {
        address [] memory whitelist = whitelistRegistry.getWhitelist();
        uint256 whitelistLength = whitelist.length;
        uint256 threshold = whitelistRegistry.resolverThreshold();

        if (whitelistLength < whitelistRegistry.whitelistLimit()) {
            return threshold;
        }

        uint256 minBalance = delegation.balanceOf(whitelist[0]);
        for (uint256 i = 1; i < whitelistLength; ++i) {
            uint256 balance = delegation.balanceOf(whitelist[i]);
            if (balance < minBalance) {
                minBalance = balance;
            }
        }
        if (minBalance < threshold) {
            return threshold;
        }
        return minBalance + 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVotable is IERC20 {
    /// @dev we assume that voting power is a function of balance that preserves order
    function votingPowerOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/solidity-utils/contracts/libraries/UniERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/AddressSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVotable.sol";

/// @title Contract with trades resolvers whitelist
contract WhitelistRegistry is Ownable {
    using UniERC20 for IERC20;
    using AddressSet for AddressSet.Data;
    using AddressArray for AddressArray.Data;

    error BalanceLessThanThreshold();
    error NotEnoughBalance();
    error AlreadyRegistered();
    error NotWhitelisted();

    event Registered(address addr);
    event Unregistered(address addr);
    event ResolverThresholdSet(uint256 resolverThreshold);
    event WhitelistLimitSet(uint256 whitelistLimit);
    event Promotion(address promoter, uint256 chainId, address promotee);

    IVotable public immutable token;

    mapping(address => mapping(uint256 => address)) public promotions;
    uint256 public resolverThreshold;
    uint256 public whitelistLimit;

    AddressSet.Data private _whitelist;

    constructor(
        IVotable token_,
        uint256 resolverThreshold_,
        uint256 whitelistLimit_
    ) {
        token = token_;
        _setResolverThreshold(resolverThreshold_);
        _setWhitelistLimit(whitelistLimit_);
    }

    function rescueFunds(IERC20 token_, uint256 amount) external onlyOwner {
        token_.uniTransfer(payable(msg.sender), amount);
    }

    function setResolverThreshold(uint256 resolverThreshold_) external onlyOwner {
        _setResolverThreshold(resolverThreshold_);
    }

    function setWhitelistLimit(uint256 whitelistLimit_) external onlyOwner {
        uint256 whitelistLength = _whitelist.length();
        if (whitelistLimit_ < whitelistLength) {
            _shrinkPoorest(_whitelist, whitelistLength - whitelistLimit_);
        }
        _setWhitelistLimit(whitelistLimit_);
    }

    function register() external {
        if (token.votingPowerOf(msg.sender) < resolverThreshold) revert BalanceLessThanThreshold();
        uint256 whitelistLength = _whitelist.length();
        if (whitelistLength == whitelistLimit) {
            address minResolver = msg.sender;
            uint256 minBalance = token.balanceOf(msg.sender);
            for (uint256 i = 0; i < whitelistLength; ++i) {
                address curWhitelisted = _whitelist.at(i);
                uint256 balance = token.balanceOf(curWhitelisted);
                if (balance < minBalance) {
                    minResolver = curWhitelisted;
                    minBalance = balance;
                }
            }
            if (minResolver == msg.sender) revert NotEnoughBalance();
            _removeFromWhitelist(minResolver);
        }
        if (!_whitelist.add(msg.sender)) revert AlreadyRegistered();
        emit Registered(msg.sender);
    }

    function promote(uint256 chainId, address promotee) external {
        promotions[msg.sender][chainId] = promotee;
        emit Promotion(msg.sender, chainId, promotee);
    }

    function clean() external {
        uint256 whitelistLength = _whitelist.length();
        unchecked {
            for (uint256 i = 0; i < whitelistLength; ) {
                address curWhitelisted = _whitelist.at(i);
                if (token.votingPowerOf(curWhitelisted) < resolverThreshold) {
                    _removeFromWhitelist(curWhitelisted);
                    whitelistLength--;
                } else {
                    i++;
                }
            }
        }
    }

    function getWhitelist() external view returns (address[] memory) {
        return _whitelist.items.get();
    }

    function getPromotees(uint256 chainId) external view returns (address[] memory promotees) {
        promotees = _whitelist.items.get();
        unchecked {
            uint256 len = promotees.length;
            for (uint256 i = 0; i < len; ++i) {
                promotees[i] = promotions[promotees[i]][chainId];
            }
        }
    }

    function _shrinkPoorest(AddressSet.Data storage set, uint256 size) private {
        uint256 richestIndex = 0;
        address[] memory addresses = set.items.get();
        uint256 addressesLength = addresses.length;
        uint256[] memory balances = new uint256[](addressesLength);
        for (uint256 i = 0; i < addressesLength; ++i) {
            balances[i] = token.balanceOf(addresses[i]);
            if (balances[i] > balances[richestIndex]) {
                richestIndex = i;
            }
        }

        for (uint256 i = size; i < addressesLength; ++i) {
            if (balances[i] <= balances[richestIndex]) {
                // Swap i-th and richest-th elements
                (addresses[i], addresses[richestIndex]) = (addresses[richestIndex], addresses[i]);
                (balances[i], balances[richestIndex]) = (balances[richestIndex], balances[i]);

                // Find new richest in first size elements
                richestIndex = 0;
                for (uint256 j = 1; j < size; ++j) {
                    if (balances[j] > balances[richestIndex]) {
                        richestIndex = j;
                    }
                }
            }
        }

        // Remove poorest elements from set
        for (uint256 i = 0; i < size; ++i) {
            _removeFromWhitelist(addresses[i]);
        }
    }

    function _setResolverThreshold(uint256 resolverThreshold_) private {
        resolverThreshold = resolverThreshold_;
        emit ResolverThresholdSet(resolverThreshold_);
    }

    function _setWhitelistLimit(uint256 whitelistLimit_) private {
        whitelistLimit = whitelistLimit_;
        emit WhitelistLimitSet(whitelistLimit_);
    }

    function _removeFromWhitelist(address account) private {
        _whitelist.remove(account);
        emit Unregistered(account);
    }
}