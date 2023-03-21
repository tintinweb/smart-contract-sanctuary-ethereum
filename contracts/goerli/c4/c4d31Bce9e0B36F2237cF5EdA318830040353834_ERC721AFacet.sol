// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address) {
        address owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                return owner;
            }
        }

        return owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal {
    using PausableStorage for PausableStorage.Layout;

    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query the contracts paused state.
     * @return true if paused, false if unpaused.
     */
    function _paused() internal view virtual returns (bool) {
        return PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Lively modified from Chiru Labs (https://github.com/chiru-labs/ERC721A)

pragma solidity ^0.8.18;

import {Shared} from "../libraries/Shared.sol";
import {
    PausableInternal
} from "@solidstate/contracts/security/PausableInternal.sol";
import {IERC721A} from "../interfaces/IERC721A.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {
    IERC721Receiver
} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC721ALib} from "../libraries/ERC721ALib.sol";
import {
    ERC721AStorage,
    TokenApprovalRef
} from "../utils/ERC721A/ERC721AStorage.sol";
import {EditionsStorage} from "../utils/Editions/EditionsStorage.sol";

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
abstract contract ERC721A is IERC721A, PausableInternal {
    // Reference type for token approval.

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return s.currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as s.burnCounter cannot be incremented
        // more than `s.currentIndex - _startTokenId()` times.
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        unchecked {
            return s.currentIndex - s.burnCounter - ERC721ALib.START_TOKEN_ID;
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `s.currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        unchecked {
            return s.currentIndex - ERC721ALib.START_TOKEN_ID;
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return s.burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return
            s.packedAddressData[owner] & ERC721ALib._BITMASK_ADDRESS_DATA_ENTRY;
    }

    // /**
    //  * Returns the number of tokens minted by `owner`.
    //  */
    function _numberMinted(address owner) internal view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return
            (s.packedAddressData[owner] >> ERC721ALib._BITPOS_NUMBER_MINTED) &
            ERC721ALib._BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return
            (s.packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
            ERC721ALib._BITMASK_ADDRESS_DATA_ENTRY;
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return s.name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return s.symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        EditionsStorage.Layout storage es = EditionsStorage.layout();

        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (es.editionsEnabled) {
            uint256 editionIndex = _ownershipOf(tokenId).extraData;

            return
                bytes(baseURI).length != 0
                    ? string(
                        abi.encodePacked(
                            baseURI,
                            _toString(tokenId),
                            "/",
                            _toString(editionIndex)
                        )
                    )
                    : "";
        } else {
            return
                bytes(baseURI).length != 0
                    ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                    : "";
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return s.baseTokenUri;
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    function ownerOf(uint256 tokenId) public view returns (address) {
        return ERC721ALib.ownerOf(tokenId);
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(
        uint256 tokenId
    ) internal view virtual returns (ERC721ALib.TokenOwnership memory) {
        return
            ERC721ALib._unpackedOwnership(
                ERC721ALib._packedOwnershipOf(tokenId)
            );
    }

    /**
     * @dev Returns the unpacked `ERC721ALib.TokenOwnership` struct at `index`.
     */
    function _ownershipAt(
        uint256 index
    ) internal view virtual returns (ERC721ALib.TokenOwnership memory) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return ERC721ALib._unpackedOwnership(s.packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        if (s.packedOwnerships[index] == 0) {
            s.packedOwnerships[index] = ERC721ALib._packedOwnershipOf(index);
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721ALib.ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        s.tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return s.tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        s.operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return s.operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        return
            ERC721ALib.START_TOKEN_ID <= tokenId &&
            tokenId < s.currentIndex && // If within bounds,
            s.packedOwnerships[tokenId] & ERC721ALib._BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        uint256 _BITMASK_ADDRESS = ERC721ALib._BITMASK_ADDRESS;

        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(
        uint256 tokenId
    )
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        TokenApprovalRef storage tokenApproval = s.tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = s.tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        uint256 prevOwnershipPacked = ERC721ALib._packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
                approvedAddress,
                from,
                _msgSenderERC721A()
            )
        )
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        ERC721ALib._beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete s.tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        unchecked {
            // We can directly increment and decrement the balances.
            --s.packedAddressData[from]; // Updates: `balance -= 1`.
            ++s.packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            s.packedOwnerships[tokenId] = ERC721ALib._packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED |
                    ERC721ALib._nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (s.packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != s.currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        s.packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        ERC721ALib._afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override whenNotPaused {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(
                _msgSenderERC721A(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // // =============================================================
    // //                        MINT OPERATIONS
    // // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        uint256 startTokenId = s.currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
            revert MintERC2309QuantityExceedsLimit();

        ERC721ALib._beforeTokenTransfers(
            address(0),
            to,
            startTokenId,
            quantity
        );

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            s.packedAddressData[to] +=
                quantity *
                ((1 << ERC721ALib._BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            s.packedOwnerships[startTokenId] = ERC721ALib._packOwnershipData(
                to,
                ERC721ALib._nextInitializedFlag(quantity) |
                    ERC721ALib._nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(
                startTokenId,
                startTokenId + quantity - 1,
                address(0),
                to
            );

            s.currentIndex = startTokenId + quantity;
        }
        ERC721ALib._afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        ERC721ALib._mint(to, quantity);
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        unchecked {
            if (to.code.length != 0) {
                uint256 end = s.currentIndex;
                uint256 index = end - quantity;
                do {
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            index++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (s.currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        uint256 prevOwnershipPacked = ERC721ALib._packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (
                !_isSenderApprovedOrOwner(
                    approvedAddress,
                    from,
                    _msgSenderERC721A()
                )
            )
                if (!isApprovedForAll(from, _msgSenderERC721A()))
                    revert TransferCallerNotOwnerNorApproved();
        }

        ERC721ALib._beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete s.tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            s.packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            s.packedOwnerships[tokenId] = ERC721ALib._packOwnershipData(
                from,
                (ERC721ALib._BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
                    ERC721ALib._nextExtraData(
                        from,
                        address(0),
                        prevOwnershipPacked
                    )
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (s.packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != s.currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        s.packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        ERC721ALib._afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as s.burnCounter cannot be exceed s.currentIndex times.
        unchecked {
            s.burnCounter++;
        }
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(
        uint256 value
    ) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Lively modified from Chiru Labs (https://github.com/chiru-labs/ERC721A)

pragma solidity ^0.8.18;

import {Shared} from "../libraries/Shared.sol";
import {ERC721A} from "../abstracts/ERC721A.sol";
import {
    PausableInternal
} from "@solidstate/contracts/security/PausableInternal.sol";
import {AllowList} from "../../shared/utils/AllowList/AllowList.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {ERC721ALib} from "../libraries/ERC721ALib.sol";
import {CoinSwapper} from "../../shared/libraries/CoinSwapper.sol";
import {PriceConsumer} from "../../shared/libraries/PriceConsumer.sol";
import {
    AllowListInternal,
    AllowListStorage
} from "../../shared/utils/AllowList/AllowListInternal.sol";
import {
    OwnableStorage,
    OwnableInternal
} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ERC721AStorage} from "../utils/ERC721A/ERC721AStorage.sol";
import {EditionsStorage} from "../utils/Editions/EditionsStorage.sol";
import {
    PaymentSplitterStorage
} from "../../shared/utils/PaymentSplitter/PaymentSplitterStorage.sol";

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AFacet is ERC721A, AllowListInternal, OwnableInternal {
    uint256 constant MAX_UINT256 = type(uint256).max;
    uint64 constant MAX_UINT64 = type(uint64).max;

    // =============================================================
    //                           Mint functions
    // =============================================================

    modifier mintChecks(address to) {
        AllowListStorage.Layout storage als = AllowListStorage.layout();
        EditionsStorage.Layout storage es = EditionsStorage.layout();

        if (als.allowListEnabled[0])
            require(isAllowListed(0, msg.sender), "Not in allowlist");
        if (es.editionsEnabled) revert EditionsEnabled();

        _;
    }

    function mint(address to) external payable mintChecks(to) whenNotPaused {
        _mintApproved(to, 1);
    }

    function mint(
        address to,
        uint256 quantity
    ) external payable mintChecks(to) whenNotPaused {
        _mintApproved(to, quantity);
    }

    // Minting is allowed, do checks against set limits
    function _mintApproved(
        address to,
        uint256 quantity
    ) internal whenNotPaused {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        PaymentSplitterStorage.Layout storage pss = PaymentSplitterStorage
            .layout();

        quantityCheck(to, quantity);
        s.airdrop ? airdropCheck() : priceCheck(quantity);

        emit Shared.PaymentReceived(msg.sender, msg.value);

        // If conversion is automatically enabled then convert the ETH to USD
        if (pss.automaticUSDConversion) {
            CoinSwapper.convertEthToUSDC();
        }

        ERC721ALib._mint(to, quantity);
    }

    // =============================================================
    //                    Check functions
    // =============================================================
    function quantityCheck(address to, uint256 quantity) private view {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        unchecked {
            if ((s.currentIndex + quantity) > maxSupply())
                revert ExceedsMaxSupply();

            if (ERC721ALib._numberMinted(to) + quantity > maxMintPerAddress())
                revert ExceedsMaxMintPerAddress();

            if (quantity > maxMintPerTx()) revert ExceedsMaxMintPerTx();
        }
    }

    function airdropCheck() private view {
        if (msg.sender != OwnableStorage.layout().owner)
            revert InvalidAirdropCaller();
    }

    function priceCheck(uint256 quantity) private {
        if (msg.value < (quantity * price())) revert InvalidValueSent();
    }

    // =============================================================
    //                        Getters
    // =============================================================
    function airdrop() public view returns (bool) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return s.airdrop;
    }

    function maxMintPerTx() public view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return s.maxMintPerTx == 0 ? MAX_UINT256 : s.maxMintPerTx;
    }

    function maxMintPerAddress() public view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return s.maxMintPerAddress == 0 ? MAX_UINT64 : s.maxMintPerAddress;
    }

    function maxSupply() public view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return s.maxSupply == 0 ? MAX_UINT256 : s.maxSupply;
    }

    function price() public view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        PaymentSplitterStorage.Layout storage pss = PaymentSplitterStorage
            .layout();

        return pss.isPriceUSD ? ERC721ALib.convertUSDtoWei(s.price) : s.price;
    }

    function isSoulbound() external view returns (bool) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return s.isSoulbound;
    }

    // =============================================================
    //                        Setters
    // =============================================================
    function setName(string calldata _name) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.name = _name;
    }

    function setSymbol(string calldata _symbol) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.symbol = _symbol;
    }

    function setTokenURI(string calldata tokenURI) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.baseTokenUri = tokenURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.price = _price;
    }

    function setAirdrop(bool _airdrop) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.airdrop = _airdrop;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.maxMintPerTx = _maxMintPerTx;
    }

    function setMaxMintPerAddress(
        uint256 _maxMintPerAddress
    ) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.maxMintPerAddress = _maxMintPerAddress;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.maxSupply = _maxSupply;
    }

    function setIsPriceUSD(bool _isPriceUSD) external onlyOwner {
        PaymentSplitterStorage.Layout storage pss = PaymentSplitterStorage
            .layout();

        pss.isPriceUSD = _isPriceUSD;
    }

    function setAutomaticUSDConversion(
        bool _automaticUSDConversion
    ) external onlyOwner {
        PaymentSplitterStorage.Layout storage pss = PaymentSplitterStorage
            .layout();

        pss.automaticUSDConversion = _automaticUSDConversion;
    }

    function setSoulbound(bool _isSoulbound) external onlyOwner {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        s.isSoulbound = _isSoulbound;
    }

    // =============================================================
    //                        Other
    // =============================================================
    function burn(uint256 tokenId) public onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        _burn(tokenId, false);

        // Call Royalty Burn

        /** Type safe and more explicity example */
        // RoyaltyFacet(address(this)).royaltyBurn(tokenId);

        /** @dev Gas efficient example, needs testing. If it doesn't work the simpler above way will. */
        bytes4 functionSelector = bytes4(keccak256("royaltyBurn(uint256)"));
        // get facet address of function
        address facet = address(bytes20(ds.facets[functionSelector]));

        bytes memory myFunctionCall = abi.encodeWithSelector(
            functionSelector,
            tokenId
        );
        (bool success, ) = address(facet).delegatecall(myFunctionCall);

        require(success, "myFunction failed");
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Lively modified from Chiru Labs

pragma solidity ^0.8.18;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * Editions are enabled
     */
    error EditionsEnabled();
    /**
     * Merkle proof is invalid
     */
    error InvalidMerkleProof();
    /**
     * Exceed max supply
     */
    error ExceedsMaxSupply();
    /**
     * Exceeds max mint per address
     */
    error ExceedsMaxMintPerAddress();
    /**
     * Exceeds max mint per tx
     */
    error ExceedsMaxMintPerTx();
    /**
     * Invalid value sent
     */
    error InvalidValueSent();
    /**
     * Invalid airdrop caller
     */
    error InvalidAirdropCaller();
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     *
     * Removed for Diamond compatibility
     */
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when a token is minted
     */

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT
// Creator: Lively modified from Chiru Labs (https://github.com/chiru-labs/ERC721A)
pragma solidity ^0.8.18;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {IERC721A} from "../interfaces/IERC721A.sol";
import {PriceConsumer} from "../../shared/libraries/PriceConsumer.sol";
import {ERC721AStorage} from "../utils/ERC721A/ERC721AStorage.sol";

library ERC721ALib {
    error TokenIsSoulbound();
    error OwnershipNotInitializedForExtraData();
    error OwnerQueryForNonexistentToken();

    uint256 constant START_TOKEN_ID = 0;
    // Mask of an entry in packed address data.
    uint256 constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `extraData` in packed ownership.
    uint256 constant _BITPOS_EXTRA_DATA = 232;

    // The mask of the lower 160 bits for addresses.
    uint256 constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 constant _BITPOS_START_TIMESTAMP = 160;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit position of `aux` in packed address data.
    uint256 constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 constant _BITMASK_BURNED = 1 << 224;

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        uint256 startTokenId = s.currentIndex;
        if (quantity == 0) revert IERC721A.MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            s.packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            s.packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert IERC721A.MintToZeroAddress();

            s.currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(
        address owner,
        uint256 flags
    ) internal view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    // /**
    //  * @dev Hook that is called before a set of serially-ordered token IDs
    //  * are about to be transferred. This includes minting.
    //  * And also called before burning one token.
    //  *
    //  * `startTokenId` - the first token ID to be transferred.
    //  * `quantity` - the amount to be transferred.
    //  *
    //  * Calling conditions:
    //  *
    //  * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
    //  * transferred to `to`.
    //  * - When `from` is zero, `tokenId` will be minted for `to`.
    //  * - When `to` is zero, `tokenId` will be burned by `from`.
    //  * - `from` and `to` are never both zero.
    //  */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        // Nested if save gas
        if (s.isSoulbound)
            if ((from != address(0) && to != address(0)))
                revert TokenIsSoulbound();
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {}

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(
        uint256 quantity
    ) internal pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) internal pure returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return
            (s.packedAddressData[owner] >> ERC721ALib._BITPOS_NUMBER_MINTED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    // Convert USD to Wei
    function convertUSDtoWei(uint256 _price) internal view returns (uint256) {
        /** 1e18 is equivalent to one eth in wei. 1e6 needed to convert price return to correct decimals (8).  */
        return (1e18 / (PriceConsumer.getLatestPrice() / 1e6)) * _price;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        return uint64(s.packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        uint256 packed = s.packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed =
            (packed & _BITMASK_AUX_COMPLEMENT) |
            (auxCasted << _BITPOS_AUX);
        s.packedAddressData[owner] = packed;
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        uint256 packed = s.packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed =
            (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
            (extraDataCasted << ERC721ALib._BITPOS_EXTRA_DATA);
        s.packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal pure returns (uint24) {
        return previousExtraData;
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(
        uint256 tokenId
    ) internal view returns (ERC721ALib.TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(
        uint256 tokenId
    ) internal view returns (uint256) {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();

        uint256 curr = tokenId;

        unchecked {
            if (ERC721ALib.START_TOKEN_ID <= curr)
                if (curr < s.currentIndex) {
                    uint256 packed = s.packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = s.packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `ERC721ALib.TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(
        uint256 packed
    ) internal pure returns (ERC721ALib.TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(
            packed >> ERC721ALib._BITPOS_START_TIMESTAMP
        );
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> ERC721ALib._BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) internal view returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {OwnableStorage} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ERC721AStorage} from "../utils/ERC721A/ERC721AStorage.sol";
import {
    PaymentSplitterStorage
} from "../../shared/utils/PaymentSplitter/PaymentSplitterStorage.sol";
import {EditionsStorage, Edition} from "../utils/Editions/EditionsStorage.sol";

library Shared {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReceived(address from, uint256 amount);
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event EditionCreate(
        uint256 editionIndex,
        string name,
        uint256 price,
        uint256 maxSupply
    );

    error PaymentSplitterAccountAddressZero();
    error PaymentSplitterSharesZero();
    error PaymentSplitterAccountHasShares();
    error EditionsDisabled();
    error NameRequired();

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param _shares The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 _shares) internal {
        PaymentSplitterStorage.Layout storage pss = PaymentSplitterStorage
            .layout();

        require(
            OwnableStorage.layout().owner == msg.sender,
            "Only owner can add payee"
        );

        if (account == address(0)) {
            revert PaymentSplitterAccountAddressZero();
        }

        if (_shares == 0) {
            revert PaymentSplitterSharesZero();
        }

        if (pss.shares[account] > 0) {
            revert PaymentSplitterAccountHasShares();
        }

        pss.payees.push(account);
        pss.shares[account] = _shares;
        pss.totalShares = pss.totalShares + _shares;
        emit PayeeAdded(account, _shares);
    }

    // TODO: Need to revamp roles
    // /**
    //  * @dev Grants `role` to `account`.
    //  *
    //  * Internal function without access restriction.
    //  *
    //  * May emit a {RoleGranted} event.
    //  */
    // function _grantRole(bytes32 role, address account) internal {
    //     ERC721AStorage.Layout storage s = ERC721AStorage.layout();

    //     require(
    //         OwnableStorage.layout().owner == msg.sender,
    //         "Only owner can grantRole"
    //     );

    //     if (!hasRole(role, account)) {
    //         s.roles[role].members[account] = true;
    //         emit RoleGranted(role, account, msg.sender);
    //     }
    // }

    // /**
    //  * @dev Returns `true` if `account` has been granted `role`.
    //  */
    // function hasRole(
    //     bytes32 role,
    //     address account
    // ) internal view returns (bool) {
    //     ERC721AStorage.Layout storage s = ERC721AStorage.layout();

    //     return s.roles[role].members[account];
    // }

    function createEdition(
        string memory _name,
        uint256 _maxSupply,
        uint256 _price
    ) internal {
        ERC721AStorage.Layout storage s = ERC721AStorage.layout();
        EditionsStorage.Layout storage es = EditionsStorage.layout();

        require(
            OwnableStorage.layout().owner == msg.sender,
            "Only owner can createEdition"
        );

        if (!es.editionsEnabled) revert EditionsDisabled();
        if (bytes(_name).length == 0) revert NameRequired();

        uint256 index = es.editionsByIndex.length;

        Edition memory _edition = Edition({
            name: _name,
            maxSupply: _maxSupply,
            price: _price,
            totalSupply: 0
        });

        es.editionsByIndex.push(_edition);
        s.maxSupply = s.maxSupply + _maxSupply;

        emit EditionCreate(index, _name, _price, _maxSupply);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

struct Edition {
    string name;
    uint256 maxSupply;
    uint256 totalSupply;
    uint256 price;
}

library EditionsStorage {
    // using EnumerableSet for EnumerableSet.UintSet;

    struct Layout {
        /**
         * @dev Editions
         */
        bool editionsEnabled;
        Edition[] editionsByIndex; // Editions
        mapping(uint256 => uint256) tokenEdition; // idToken => editionIndex // Deprecated
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.Editions");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

struct TokenApprovalRef {
    address value;
}

library ERC721AStorage {
    // using EnumerableSet for EnumerableSet.UintSet;

    struct Layout {
        /**
         * @dev ERC721A Section
         */
        // The tokenId of the next token to be minted.
        uint256 currentIndex;
        // The number of tokens burned.
        uint256 burnCounter;
        // Token name
        string name;
        // Token symbol
        string symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => TokenApprovalRef) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        /**
         * @dev Custom ERC721A Variables
         */
        uint256 price;
        uint256 maxSupply;
        string baseTokenUri;
        bool airdrop;
        // bool paused; // Shouldn't be needed with SolidState pausable
        uint256 maxMintPerTx;
        uint256 maxMintPerAddress;
        bool isSoulbound;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.ERC721A");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.18;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibDiamond} from "./LibDiamond.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

library CoinSwapper {
    uint256 constant localId = 31337;
    uint256 constant ethereumId = 1;
    uint256 constant rinkebyId = 4;
    uint256 constant goerliId = 5;
    uint256 constant polygonId = 137;
    uint256 constant mumbaiId = 80001;

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Same on all Nets SwapRouter address

    // Returns the appropriate WETH9 token address for the given network id.
    function getWETH9Address()
        internal
        view
        returns (address priceFeedAddress)
    {
        if (block.chainid == ethereumId || block.chainid == localId) {
            return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == rinkebyId) {
            return 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        } else if (block.chainid == goerliId) {
            return 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        } else if (block.chainid == polygonId) {
            return 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        } else if (block.chainid == mumbaiId) {
            return 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
        }
    }

    // Returns the appropriate USDC token address for the given network id.
    function getUSDCAddress() internal view returns (address priceFeedAddress) {
        if (block.chainid == ethereumId || block.chainid == localId) {
            return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        } else if (block.chainid == rinkebyId) {
            return 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
        } else if (block.chainid == goerliId) {
            return 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C;
        } else if (block.chainid == polygonId) {
            return 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        } else if (block.chainid == mumbaiId) {
            return 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747;
        }
    }

    /** @dev Shortcut function to swap ETH for USDC */
    function convertEthToUSDC() internal {
        wrapMsgEth();
        convertWETHtoUSDC();
    }

    /** @dev Wraps the entire balance of the contract in WETH9 */
    function wrapEth() internal {
        address WETH9 = getWETH9Address();
        IWETH9(WETH9).deposit{value: address(this).balance}();
    }

    /** @dev Wraps the entire balance of the contract in WETH9 */
    function wrapMsgEth() internal {
        address WETH9 = getWETH9Address();
        IWETH9(WETH9).deposit{value: msg.value}();
    }

    /** @dev Converts all WETH owned by contract to USDC */
    function convertWETHtoUSDC() internal {
        address USDC = getUSDCAddress();
        address WETH9 = getWETH9Address();
        uint256 currentBlance = IWETH9(WETH9).balanceOf(address(this));

        // For this example, we will set the pool fee to 0.3%.
        uint24 poolFee = 3000;

        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            address(this),
            currentBlance
        );

        TransferHelper.safeApprove(WETH9, address(swapRouter), currentBlance);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: currentBlance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        swapRouter.exactInputSingle(params);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(
            _selectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibDiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibDiamondCut: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConsumer {
    uint256 constant localId = 31337;
    uint256 constant ethereumId = 1;
    uint256 constant rinkebyId = 4;
    uint256 constant goerliId = 5;
    uint256 constant polygonId = 137;
    uint256 constant mumbaiId = 80001;

    // Returns the appropriate oracle address for the given network id.
    function getPriceFeedAddress()
        internal
        view
        returns (address priceFeedAddress)
    {
        uint256 chainId = block.chainid;

        if (chainId == ethereumId || chainId == localId) {
            return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        } else if (chainId == rinkebyId) {
            return 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        } else if (chainId == goerliId) {
            return 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        } else if (chainId == polygonId) {
            return 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        } else if (chainId == mumbaiId) {
            return 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
        }
    }

    /**
     * @notice Returns the latest price
     *
     * @return latest price
     */
    function getLatestPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = getPriceFeed();
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 newPrice = uint256(price);
        return newPrice; // $1500
    }

    /**
     * @notice Returns the Price Feed address
     *
     * @return Price Feed address
     */
    function getPriceFeed() internal view returns (AggregatorV3Interface) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            getPriceFeedAddress()
        );
        return priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AllowListStorage} from "./AllowListStorage.sol";
import {AllowListInternal} from "./AllowListInternal.sol";
import {
    OwnableInternal
} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowList is AllowListInternal, OwnableInternal {
    using AllowListStorage for AllowListStorage.Layout;

    function _enableAllowList(uint256 tokenId) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (als.allowListEnabled[tokenId]) revert AllowListEnabled();

        als.allowListEnabled[tokenId] = true;

        emit AllowListStatus(tokenId, true);
    }

    function _disableAllowList(uint256 tokenId) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (!als.allowListEnabled[tokenId]) revert AllowListEnabled();

        als.allowListEnabled[tokenId] = false;

        emit AllowListStatus(tokenId, false);
    }

    function addToAllowList(
        uint256 tokenId,
        address account
    ) external onlyOwner {
        _addToAllowList(tokenId, account, 0, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance
    ) external onlyOwner {
        _addToAllowList(tokenId, account, allowance, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance,
        uint256 allowTime
    ) external onlyOwner {
        _addToAllowList(tokenId, account, allowance, allowTime);
    }

    function addToAllowList(
        uint256 tokenId,
        address[] calldata accounts
    ) external onlyOwner {
        _addToAllowList(tokenId, accounts, 0, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address[] calldata accounts,
        uint256 allowance
    ) external onlyOwner {
        _addToAllowList(tokenId, accounts, allowance, 0);
    }

    function addToAllowList(
        uint256 tokenId,
        address[] calldata accounts,
        uint256 allowance,
        uint256 allowTime
    ) external onlyOwner {
        _addToAllowList(tokenId, accounts, allowance, allowTime);
    }

    function removeFromAllowList(
        uint256 tokenId,
        address account
    ) external onlyOwner {
        _removeFromAllowList(tokenId, account);
    }

    function removeFromAllowList(
        uint256 tokenId,
        address[] calldata accounts
    ) external onlyOwner {
        _removeFromAllowList(tokenId, accounts);
    }

    function allowListContains(
        uint256 tokenId,
        address account
    ) external view returns (bool contains) {
        return _allowListContains(tokenId, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AllowListStorage} from "./AllowListStorage.sol";
import {IAllowListInternal} from "./IAllowListInternal.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";

contract AllowListInternal is IAllowListInternal {
    // using AllowListStorage for AllowListStorage.Layout;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier allowListed(uint256 tokenId, address account) {
        if (!AllowListStorage.layout().allowList[tokenId].contains(account)) {
            revert AccountNotAllowListed();
        }

        _;
    }

    function isAllowListed(
        uint256 tokenId,
        address account
    ) internal view returns (bool) {
        return AllowListStorage.layout().allowList[tokenId].contains(account);
    }

    function _allowListAllowance(
        uint256 tokenId,
        address account
    ) internal view allowListed(tokenId, account) returns (uint256) {
        return AllowListStorage.layout().allowance[tokenId][account];
    }

    function _addToAllowList(
        uint256 tokenId,
        address _account,
        uint256 _allowance,
        uint256 _allowTime
    ) internal {
        // If the account is already in the allowList, we don't want to add it again.
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (als.allowList[tokenId].contains(_account)) {
            revert AccountAlreadyAllowListed();
        }

        als.allowList[tokenId].add(_account);
        als.allowance[tokenId][_account] = _allowance;
        als.allowTime[tokenId][_account] = _allowTime;

        emit AllowListAdded(tokenId, _account, _allowance);
    }

    function _addToAllowList(
        uint256 tokenId,
        address[] calldata _accounts,
        uint256 _allowance
    ) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (als.allowList[tokenId].contains(_accounts[i])) {
                revert AccountAlreadyAllowListed();
            }
            als.allowList[tokenId].add(_accounts[i]);
            als.allowance[tokenId][_accounts[i]] = _allowance;
            ++i;
        }

        emit AllowListAdded(tokenId, _accounts, _allowance);
    }

    function _addToAllowList(
        uint256 tokenId,
        address[] calldata _accounts,
        uint256 _allowance,
        uint256 _allowTime
    ) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();
        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (als.allowList[tokenId].contains(_accounts[i])) {
                revert AccountAlreadyAllowListed();
            }
            als.allowList[tokenId].add(_accounts[i]);
            als.allowance[tokenId][_accounts[i]] = _allowance;
            als.allowTime[tokenId][_accounts[i]] = _allowTime;
            ++i;
        }

        emit AllowListAdded(tokenId, _accounts, _allowance);
    }

    function _removeFromAllowList(uint256 tokenId, address _account) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        if (!als.allowList[tokenId].contains(_account)) {
            revert AccountNotAllowListed();
        }

        als.allowList[tokenId].remove(_account);
        delete als.allowance[tokenId][_account];

        emit AllowListRemoved(tokenId, _account);
    }

    function _removeFromAllowList(
        uint256 tokenId,
        address[] calldata _accounts
    ) internal {
        AllowListStorage.Layout storage als = AllowListStorage.layout();

        uint256 accountsLength = _accounts.length;
        uint256 i = 0;
        for (; i < accountsLength; ) {
            if (!als.allowList[tokenId].contains(_accounts[i])) {
                revert AccountNotAllowListed();
            }

            als.allowList[tokenId].remove(_accounts[i]);
            delete als.allowance[tokenId][_accounts[i]];
            ++i;
        }

        emit AllowListRemoved(tokenId, _accounts);
    }

    function _allowListContains(
        uint256 tokenId,
        address _account
    ) internal view returns (bool) {
        return AllowListStorage.layout().allowList[tokenId].contains(_account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {
    Ownable,
    OwnableStorage
} from "@solidstate/contracts/access/ownable/Ownable.sol";

library AllowListStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    // struct AllowListStruct {
    //     bool allowListEnabled;
    //     EnumerableSet.AddressSet allowList; // Users who may mint
    //     mapping(address => uint256) allowance; // How many the user may mint
    //     mapping(address => uint256) allowTime; // When the user may mint
    //     mapping(address => uint256) minted; // How many the user has minted
    // }

    /**
     * @dev Before protocal publication we can remove these deprecated items but for upgradeability we need to keep them
     */
    struct Layout {
        mapping(uint256 => bool) allowListEnabled;
        mapping(uint256 => EnumerableSet.AddressSet) allowList;
        mapping(uint256 => mapping(address => uint256)) allowance;
        mapping(uint256 => mapping(address => uint256)) allowTime;
        mapping(uint256 => mapping(address => uint256)) minted;
        // mapping(uint256 => AllowListStruct) allowLists; // Mapping between tokenId and allowList
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.AllowList");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IAllowListInternal {
    error AccountNotAllowListed();
    error AccountAlreadyAllowListed();
    error AllowListEnabled();
    error AllowListDisabled();
    error MintNotOpen();
    error NotOnAllowList();
    error AllowListAmountExceeded();
    error AllowListMintUnopened();

    event AllowListStatus(bool status);
    event AllowListAdded(address account, uint256 allowance);
    event AllowListAdded(address[] accounts, uint256 allowance);
    event AllowListRemoved(address account);
    event AllowListRemoved(address[] accounts);

    event AllowListStatus(uint256 tokenId, bool status);
    event AllowListAdded(uint256 tokenId, address account, uint256 allowance);
    event AllowListAdded(
        uint256 tokenId,
        address[] accounts,
        uint256 allowance
    );
    event AllowListRemoved(uint256 tokenId, address account);
    event AllowListRemoved(uint256 tokenId, address[] accounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library PaymentSplitterStorage {
    struct Layout {
        uint256 totalShares;
        uint256 totalReleased;
        mapping(address => uint256) shares;
        mapping(address => uint256) released;
        address[] payees;
        mapping(IERC20 => uint256) erc20TotalReleased;
        mapping(IERC20 => mapping(address => uint256)) erc20Released;
        bool isPriceUSD;
        bool automaticUSDConversion;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("lively.contracts.storage.PaymentSplitter");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}