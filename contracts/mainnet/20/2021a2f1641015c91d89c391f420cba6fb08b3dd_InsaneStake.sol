/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
}

// File: @openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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

// File: contracts/TransparentPattern/InsaneStaking/ItfInsaneRules.sol



pragma solidity 0.8.15;



interface ItfInsaneRules{

    function getTokenReward(uint256 _tokenId) external view returns (uint256);

    function getStakeReward(uint256 _startTime, uint256 _currentTime,  uint256 _tokenId, uint256 _claimedReward) external view returns (uint256 _reward);

    function isAdmin(address _address) external view returns(bool);

    function isActive() external view returns (bool);

}
// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// File: contracts/TransparentPattern/InsaneToken_ERC20/ItfInsaneToken.sol



pragma solidity 0.8.15;





interface ItfInsaneToken is IERC20Upgradeable, IERC20MetadataUpgradeable{

    function mintToken(address _account, uint256 _amount) external;

    function burnToken(address _account, uint256 _amount) external;

}
// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
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

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: contracts/TransparentPattern/Other/AdminUpgradeable.sol



pragma solidity 0.8.15;





abstract contract AdminUpgradeable is Initializable, OwnableUpgradeable{

    event AddAdminLog(address indexed newAdmin);

    event RemoveAdminLog(address indexed removedAdmin);

    address[] admin;

    mapping(address=>bool) records;

    

    /**

    * @dev Modifier to check if function called by registered admins.

    */

    modifier onlyAdmin(){

        require(records[msg.sender]==true, "msg.sender must be admin");

        _;

    }



    /**

    * @dev Constructor. Set the creator of the contract as one of admin.

    */

    function ___Adminable_init() internal onlyInitializing{

        __Ownable_init();

        admin.push(msg.sender);

        records[msg.sender] = true;

    }

    

    /**

    * @dev function to add new admin.

    * @param _address Address of new admin.

    */

    function addAdmin(address _address) onlyOwner() external {

        if (!records[_address]) {

            admin.push(_address);

            records[_address] = true;

            emit AddAdminLog(_address);

        }

    }



    /**

    * @dev function to remove an admin

    * @param _address Address of the admin that is going to be removed.

    */

    function removeAdmin(address _address) onlyOwner() external{

        for (uint i = 0; i < admin.length; i++) {

            if (admin[i] == _address) {

                delete admin[i];

                records[_address] = false;

                emit RemoveAdminLog(_address);

            }

        }

    }



    /**

    * @dev function to check whether the address is registered admin or not

    * @param _address Address to be checked.

    */

    function isAdmin(address _address) public view returns(bool) {

        return records[_address];

    }

}
// File: contracts/TransparentPattern/InsaneStaking/InsaneStake.sol



pragma solidity 0.8.15;












contract InsaneStake is Initializable, AdminUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IERC721ReceiverUpgradeable{

    using SafeMathUpgradeable for uint256;



    address public tokenReward;



    struct StakeData{

        uint256 tokenId;

        uint256 timestamp;

        uint256 claimedReward;

    }

    struct StakeStorage{

        string name;

        address rules;

        mapping(address => mapping(uint256 => StakeData)) StakeMemory;

    }

    mapping(address => StakeStorage) public StakeDatabase;



    event SetTokenReward(address indexed sender, address indexed oldToken, address indexed newToken, uint256 timestamp);

    event CollectionRegistered(address indexed sender, address indexed collection, address indexed rules, uint256 timestamp);

    event RulesChanged(address indexed sender, address indexed collection, address oldRules, address newRules, uint256 timestamp);



    event RewardMinted(address indexed staker, uint256 amount, uint256 timestamp);

    event RewardClaimed(address indexed staker, uint256 tokenId, uint256 amount, uint256 timestamp);



    event StartStake(address indexed staker, address indexed collectionContract, uint256 id, uint256 start);

    event EndStake(address indexed staker, address indexed collectionContract, uint256 id, uint256 start, uint256 end);



    modifier notZeroAddress(address _addr){

        require(_addr != address(0), "must not zero address");

        _;

    }

    modifier haveRules(address _collectionContract){

        require(_collectionContract != address(0), "collection must not zero address");

        require(StakeDatabase[_collectionContract].rules != address(0), "must have stake rules");

        _;

    }



    constructor() initializer {}

    

    function initialize(address _tokenReward) external initializer {

        ___Adminable_init();

        tokenReward =  _tokenReward;

        emit SetTokenReward(msg.sender, address(0), _tokenReward, block.timestamp);

    }



    function version() public pure virtual returns(uint256){

        return 1;

    }



    //pausable part

    function pause() public 

    onlyOwner 

    whenNotPaused {

        return _pause();

    }

    

    function unpause() public 

    onlyOwner 

    whenPaused {

        return _unpause();

    }



    //configuration part

    //set erc20 for staking reward

    function setTokenReward(address _tokenReward) public 

    onlyAdmin 

    notZeroAddress(_tokenReward){

        emit SetTokenReward(msg.sender, tokenReward, _tokenReward, block.timestamp);

        tokenReward = _tokenReward;

    }



    //set new configuration for a collection

    function initRulesConfiguration(address _collectionContract, address _rules) public 

    onlyAdmin 

    notZeroAddress(_collectionContract) 

    notZeroAddress(_rules){

        require(

            StakeDatabase[_collectionContract].rules == address(0),

            "collection contract must not have configuration"

            );



        StakeDatabase[_collectionContract].rules = _rules;

        StakeDatabase[_collectionContract].name = IERC721MetadataUpgradeable(_collectionContract).name();



        emit CollectionRegistered(msg.sender, _collectionContract, _rules, block.timestamp);

    }



    //change new rule contract for registered collection

    function changeRulesContract(address _collectionContract, address _newRules) public 

    whenNotPaused

    notZeroAddress(_collectionContract) 

    notZeroAddress(_newRules)

    {

        require(

            StakeDatabase[_collectionContract].rules != address(0),

            "collection contract must have configuration"

            );

        require(ItfInsaneRules(StakeDatabase[_collectionContract].rules).isAdmin(msg.sender) == true, "only old admin rules");

        

        emit RulesChanged(msg.sender, _collectionContract, StakeDatabase[_collectionContract].rules, _newRules, block.timestamp);



        StakeDatabase[_collectionContract].rules = _newRules;

    }



    //view stake configuration

    function viewConfiguration(address __collectionContract) public view

    returns(

        string memory _name,

        address _rules,

        bool _isActive

    ){

        return(

            StakeDatabase[__collectionContract].name,

            StakeDatabase[__collectionContract].rules,

            ItfInsaneRules(StakeDatabase[__collectionContract].rules).isActive()

        );

    }



    //staking part

    //stake token ids

    function stakeToken(uint256[] memory _tokenIds, address _collectionContract) public 

    whenNotPaused

    haveRules(_collectionContract)

    nonReentrant{



        ItfInsaneRules itfRules = ItfInsaneRules(StakeDatabase[_collectionContract].rules);

        require(itfRules.isActive() == true, "rules must active");

        

        require(_tokenIds.length >0, "token id length must not 0");



        IERC721Upgradeable ierc721 = IERC721Upgradeable(_collectionContract);



        //get current timestamp for recorded as start stake time

        uint256 start_timestamp = block.timestamp; 



        for(uint256 i=0; i<_tokenIds.length; i++){

            require(_tokenIds[i] >0, "token id must not zero");

            require(StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].timestamp == 0, "must not in staking");

            require(ierc721.ownerOf(_tokenIds[i]) == msg.sender, "staker must owner of token");

            

            //create initial value for start stake (token id, start time, claimed reward)

            StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]] = StakeData(_tokenIds[i], start_timestamp, 0);

                        

            //transfer token id to this contract

            ierc721.transferFrom(msg.sender, address(this), _tokenIds[i]);



            emit StartStake(msg.sender, _collectionContract, _tokenIds[i], start_timestamp);

        }

    }



    //unstake token ids

    function unstakeToken(uint256[] memory _tokenIds, address _collectionContract) public 

    whenNotPaused

    haveRules(_collectionContract)

    nonReentrant{

        _unstakeToken(_tokenIds, msg.sender, _collectionContract);



        /*

        ItfInsaneRules itfRules = ItfInsaneRules(StakeDatabase[_collectionContract].rules);

        require(itfRules.isActive() == true, "rules must active");



        require(_tokenIds.length >0, "token id length must not 0");



        IERC721Upgradeable ierc721 = IERC721Upgradeable(_collectionContract);



        //get current timestamp as end stake time

        uint256 end_timestamp = block.timestamp;



        //initial reward calculation

        uint256 reward = 0;



        for(uint256 i=0; i<_tokenIds.length; i++){

            require(_tokenIds[i] >0, "token id must not zero");

            require(StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].timestamp > 0,"must in staking");

            

            emit EndStake(msg.sender, _collectionContract, _tokenIds[i], StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].timestamp,end_timestamp);

            

            //calculate reward from stake rules contract

            uint256 tmpReward = itfRules.getStakeReward(

                                    StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].timestamp,

                                    end_timestamp,

                                    _tokenIds[i],

                                    StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].claimedReward

                                );



            reward = reward.add(tmpReward);



            if(tmpReward >0){

                emit RewardClaimed(

                        msg.sender, 

                        _tokenIds[i], 

                        tmpReward,

                        end_timestamp

                );

            }

            

            //set not active staking

            StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].timestamp = 0;

            

            //transfer token id back to staker from this contract

            ierc721.transferFrom(address(this), msg.sender, _tokenIds[i]);

        }



        //mint already calculate reward

        mintReward(msg.sender, reward, end_timestamp);

        */

    }



    function unstakeTokenByAdmin(uint256[] memory _tokenIds, address _account, address _collectionContract) public 

    whenNotPaused

    haveRules(_collectionContract)

    notZeroAddress(_account)

    nonReentrant  

    onlyAdmin{

        _unstakeToken(_tokenIds, _account, _collectionContract);

    }



    function _unstakeToken(uint256[] memory _tokenIds, address _account, address _collectionContract) internal {

        

        ItfInsaneRules itfRules = ItfInsaneRules(StakeDatabase[_collectionContract].rules);

        require(itfRules.isActive() == true, "rules must active");



        require(_tokenIds.length >0, "token id length must not 0");



        IERC721Upgradeable ierc721 = IERC721Upgradeable(_collectionContract);



        //get current timestamp as end stake time

        uint256 end_timestamp = block.timestamp;



        //initial reward calculation

        uint256 reward = 0;



        for(uint256 i=0; i<_tokenIds.length; i++){

            require(_tokenIds[i] >0, "token id must not zero");

            require(StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].timestamp > 0,"must in staking");

            

            emit EndStake(_account, _collectionContract, _tokenIds[i], StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].timestamp,end_timestamp);

            

            //calculate reward from stake rules contract

            uint256 tmpReward = itfRules.getStakeReward(

                                    StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].timestamp,

                                    end_timestamp,

                                    _tokenIds[i],

                                    StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].claimedReward

                                );



            reward = reward.add(tmpReward);



            if(tmpReward >0){

                emit RewardClaimed(

                        _account, 

                        _tokenIds[i], 

                        tmpReward,

                        end_timestamp

                );

            }

            

            //set not active staking

            StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].timestamp = 0;

            

            //transfer token id back to staker from this contract

            ierc721.transferFrom(address(this), _account, _tokenIds[i]);

        }



        //mint already calculate reward

        mintReward(_account, reward, end_timestamp);

    }

    

    //claim reward without unstake all token ids

    function claimReward(uint256[] memory _tokenIds, address _collectionContract) public 

    whenNotPaused

    notZeroAddress(_collectionContract)

    haveRules(_collectionContract)

    nonReentrant{



        ItfInsaneRules itfRules = ItfInsaneRules(StakeDatabase[_collectionContract].rules);

        require(itfRules.isActive() == true, "rules must active");

        

        require(_tokenIds.length >0, "token id length must not 0");



        //get current timestamp as end stake time

        uint256 end_timestamp = block.timestamp;



        //initial reward calculation

        uint256 reward = 0;



        for(uint256 i=0; i<_tokenIds.length; i++){

            require(_tokenIds[i] >0, "token id must not zero");

            require(StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].timestamp > 0,"must in staking");



            //calculate reward from stake rules contract

            uint256 tmpReward = ItfInsaneRules(StakeDatabase[_collectionContract].rules).getStakeReward(

                                    StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].timestamp,

                                    end_timestamp,

                                    _tokenIds[i],

                                    StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].claimedReward

                                );



            reward = reward.add(tmpReward);



            if(tmpReward >0){

                emit RewardClaimed(

                    msg.sender, 

                    _tokenIds[i], 

                    tmpReward, 

                    end_timestamp

                );

            }

            

            //store claimed reward

            StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].claimedReward = (StakeDatabase[_collectionContract].StakeMemory[msg.sender][_tokenIds[i]].claimedReward).add(tmpReward);            

        }



        //mint already calculate reward

        mintReward(msg.sender, reward, end_timestamp);

    }



    //view staking reward

    function getStakeReward(uint256[] memory __tokenIds, address _collectionContract, address _account) public view 

    returns (

        uint256[] memory _tokenIds,

        uint256 _totalReward,

        uint256[] memory _rewardPerIds

    ){

        

        require(_collectionContract != address(0), "collection must not zero address");

        require(StakeDatabase[_collectionContract].rules != address(0), "must have stake rules");

        require(ItfInsaneRules(StakeDatabase[_collectionContract].rules).isActive() == true, "rules must active");



        //get current timestamp as end stake time

        uint256 end_timestamp = block.timestamp;



        _tokenIds = __tokenIds;



        //initial reward calculation

        uint256 reward = 0;



        //create array variable

        _rewardPerIds = new uint256[](_tokenIds.length); 



        for(uint256 i=0; i<_tokenIds.length; i++){

            require(_tokenIds[i] >0, "token id must not zero");

            require(StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].timestamp > 0,"must in staking");



            //calculate reward from stake rules contract

            uint256 tmpReward = ItfInsaneRules(StakeDatabase[_collectionContract].rules).getStakeReward(

                                    StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].timestamp,

                                    end_timestamp,

                                    _tokenIds[i],

                                    StakeDatabase[_collectionContract].StakeMemory[_account][_tokenIds[i]].claimedReward

                                );

            _rewardPerIds[i] = tmpReward;



            reward = reward.add(tmpReward);

        }

        return (_tokenIds, reward, _rewardPerIds);

    }



    //view stake detail

    function getStakeDetail(address _collectionContract, address _account, uint256 _tokenId) public view

    returns (

        uint256 _timestamp,

        uint256 _claimedReward

    ){



        return(

            StakeDatabase[_collectionContract].StakeMemory[_account][_tokenId].timestamp,

            StakeDatabase[_collectionContract].StakeMemory[_account][_tokenId].claimedReward

        );

    }



    //mint reward to staker

    function mintReward(address _account, uint256 _amount, uint256 _timestamp) internal{

        ItfInsaneToken itfToken= ItfInsaneToken(tokenReward);

        if(_amount > 0){

            _amount = _amount.mul( 

                            10**uint256(

                                itfToken.decimals() 

                            )  

                    );

            itfToken.mintToken(_account, _amount);

            emit RewardMinted(_account, _amount, _timestamp);

        }

        else{



        }

        

    }



    function onERC721Received(

        address,

        address from,

        uint256,

        bytes calldata

    ) external pure override returns (bytes4) {

        require(from == address(0x0), "Cannot send nfts to Vault directly");

        return IERC721ReceiverUpgradeable.onERC721Received.selector;

    }

}