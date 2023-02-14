// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IGhostFaucet.sol";
import "./interfaces/IERC721Envious.sol";
import "./interfaces/IERC721EnviousDynamic.sol";
import "./libraries/Sigmoid.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./openzeppelin/token/ERC721/IERC721.sol";
import "./openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";

contract GhostFaucet is IGhostFaucet {

	using SafeERC20 for IERC20;
	using Sigmoid for Sigmoid.SigmoidParams;

	uint256 public immutable override baseDisperse;
	uint256 public immutable override baseAmount;
	address public immutable override nftAddress;
	address public immutable override tokenAddress;

	uint256 public override totalTokensMinted;
	mapping(address => uint256) public override nftsMinted;
	mapping(address => uint256) public override tokensMinted;
	mapping(address => uint256) public override referralsNumber;

	Sigmoid.SigmoidParams private _sigmoid;

	constructor (
		address collection, 
		address token, 
		uint256 disperse, 
		uint256 amount,
		int256[3] memory sigmoidParams
	) {
		require(
			IERC721(collection).supportsInterface(type(IERC721EnviousDynamic).interfaceId) &&
			IERC721(collection).supportsInterface(type(IERC721Enumerable).interfaceId), 
			"Not a dynamic collection"
		);
		require(token != address(0), "Bad constructor addresses");
		
		nftAddress = collection;
		tokenAddress = token;
		baseDisperse = disperse;
		baseAmount = amount;

		_sigmoid = Sigmoid.SigmoidParams(sigmoidParams[0], sigmoidParams[1], sigmoidParams[2]);

		IERC20(token).approve(collection, type(uint256).max);
	}

	function sendMeGhostNft(address friend) external payable override {
		// NOTE: function `tokenOfOwnerByIndex` should revert if zero balance of address `friend`
		uint256 tokenId = IERC721Enumerable(nftAddress).tokenOfOwnerByIndex(friend, 0);
		uint256 ownedNfts = nftsMinted[msg.sender];
		uint256 amount = baseAmount + baseAmount * sigmoidValue(referralsNumber[friend]);

		referralsNumber[friend] += 1;
		nftsMinted[msg.sender] += 1;

		tokensMinted[friend] += amount;
		totalTokensMinted += amount;

		if (ownedNfts > 0) {
			uint256 disperseAmount = baseDisperse + baseDisperse * sigmoidValue(ownedNfts);
			(uint256[] memory values, address[] memory etherAddresses) = _prepareValues(disperseAmount, address(0));
			// NOTE: function `disperse` should revert if `disperseAmount` less then msg.value
			IERC721Envious(nftAddress).disperse{value: disperseAmount}(values, etherAddresses);
		}

		(uint256[] memory amounts, address[] memory tokenAddresses) = _prepareValues(amount, tokenAddress);
		IERC721EnviousDynamic(nftAddress).mint(msg.sender);
		IERC721Envious(nftAddress).collateralize(tokenId, amounts, tokenAddresses);

		// solhint-disable-next-line
		emit AssetAirdropped(msg.sender, friend, amount, block.timestamp);
	}

	function sigmoidValue(uint256 x) public override view returns (uint256) {
		return _sigmoid.sigmoid(x);
	}

	function _prepareValues(
		uint256 amount,
		address collateralAddress
	) private pure returns (uint256[] memory, address[] memory) {
		uint256[] memory amounts = new uint256[](1);
		address[] memory tokenAddresses = new address[](1);
		
		amounts[0] = amount;
		tokenAddresses[0] = collateralAddress;

		return (amounts, tokenAddresses);
	}
}

// SPDX-License-Identifier: MIT
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
interface IERC165 {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity ^0.8.0;

library Sigmoid {
	struct SigmoidParams {
		int256 a;
		int256 b;
		int256 c;
	}
	
	function sigmoid(SigmoidParams storage params, uint256 x) internal view returns (uint256) {
		int256 numerator = int256(x) - params.b;
		uint256 toDenominator = uint256(numerator * numerator + params.c);
		int256 denominator = _sqrt(toDenominator);
		
		return uint256(params.a + (params.a * numerator / denominator));
	}
	
	function _sqrt(uint256 x) private pure returns (int256) {
		if (x == 0) return 0;
		
		uint256 xx = x;
		uint256 r = 1;
		
		if (xx >= 0x100000000000000000000000000000000) {
			xx >>= 128;
			r <<= 64;
		}
		
		if (xx >= 0x10000000000000000) {
			xx >>= 64;
			r <<= 32;
		}
		
		if (xx >= 0x100000000) {
			xx >>= 32;
			r <<= 16;
		}
		
		if (xx >= 0x10000) {
			xx >>= 16;
			r <<= 8;
		}
		
		if (xx >= 0x100) {
			xx >>= 8;
			r <<= 4;
		}
		
		if (xx >= 0x10) {
			xx >>= 4;
			r <<= 2;
		}
		
		if (xx >= 0x8) {
			r <<= 1;
		}
		
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1;
		r = (r + x / r) >> 1; // Seven iterations should be enough
		
		uint256 r1 = x / r;
		return int256(r < r1 ? r : r1);
	}
}

// SPDX-License-Identifier: MIT
  
pragma solidity ^0.8.0;

interface IGhostFaucet {
	event AssetAirdropped(
		address indexed sender, 
		address indexed friend, 
		uint256 amount, 
		uint256 timestamp
	);

	/**
	 * @dev Minimal amount to be dispersed. Used only for addresses with
	 * multiple NFTs.
	 */
	function baseDisperse() external view returns (uint256);

	/**
	 * @dev Minimal reward amount.
	 */
	function baseAmount() external view returns (uint256);

	/**
	 * @dev Dynamic collection address.
	 */
	function nftAddress() external view returns (address);

	/**
	 * @dev ERC20 token address, which will be distributed as a collateral.
	 */
	function tokenAddress() external view returns (address);

	/**
	 * @dev Amount of tokens minted by faucet smart contract.
	 */
	function totalTokensMinted() external view returns (uint256);

	/**
	 * @dev Number of NFTs minted to address.
	 */
	function nftsMinted(address who) external view returns (uint256);

	/**
	 * @dev Amount of collateral tokens minted to address.
	 */
	function tokensMinted(address who) external view returns (uint256);

	/**
	 * @dev Number of invited referrals.
	 */
	function referralsNumber(address who) external view returns (uint256);

	/**
	 * @dev Used formula:
	 * y = a + (a * (x - B)) / sqrt((x - B)^2 + C)
	 */
	function sigmoidValue(uint256 x) external view returns (uint256);

	/**
	 * @dev Mints new NFT and collateralize NFT of a friend.
	 */
	function sendMeGhostNft(address friend) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Envious.sol";

/**
 * @title Additional extension for IERC721Envious, in order to make 
 * `tokenURI` dynamic, based on actual collateral.
 * @author 571nkY @ghostchain
 * @dev Ability to get royalty payments from collateral NFTs.
 */
interface IERC721EnviousDynamic is IERC721Envious {
	struct Edge {
		uint256 value;
		uint256 offset;
		uint256 range;
	}

	/**
	 * @dev Get `tokenURI` for specific token based on edges. Where actual 
	 * collateral should define which edge should be used, range shows
	 * maximum value in current edge, offset shows minimal value in current
	 * edge.
	 *
	 * @param tokenId unique identifier for token
	 */
	function getTokenPointer(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional Envious extension.
 * @author F4T50 @ghostchain
 * @author 571nkY @ghostchain
 * @author 5Tr3TcH @ghostchain
 * @dev Ability to collateralize each NFT in collection.
 */
interface IERC721Envious is IERC721 {
	event Collateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Uncollateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Dispersed(address indexed tokenAddress, uint256 amount);
	event Harvested(address indexed tokenAddress, uint256 amount, uint256 scaledAmount);

	/**
	 * @dev An array with two elements. Each of them represents percentage from collateral
	 * to be taken as a commission. First element represents collateralization commission.
	 * Second element represents uncollateralization commission. There should be 3 
	 * decimal buffer for each of them, e.g. 1000 = 1%.
	 *
	 * @param index of value in array.
	 */
	function commissions(uint256 index) external view returns (uint256);

	/**
	 * @dev Address of token that will be paid on bonds.
	 *
	 * @return address address of token.
	 */
	function ghostAddress() external view returns (address);

	/**
	 * @dev Address of smart contract, that provides purchasing of DeFi 2.0 bonds.
	 *
	 * @return address address of bonding smart.
	 */
	function ghostBondingAddress() external view returns (address);

	/**
	 * @dev 'Black hole' is any address that guarantee tokens sent to it will not be 
	 * retrieved from there. Note: some tokens revert on transfer to zero address.
	 *
	 * @return address address of black hole.
	 */
	function blackHole() external view returns (address);

	/**
	 * @dev Token that will be used to harvest collected commissions.
	 *
	 * @return address address of token.
	 */
	function communityToken() external view returns (address);

	/**
	 * @dev Pool of available tokens for harvesting.
	 *
	 * @param index in array.
	 * @return address of token.
	 */
	function communityPool(uint256 index) external view returns (address);

	/**
	 * @dev Token balance available for harvesting.
	 *
	 * @param tokenAddress addres of token.
	 * @return uint256 token balance.
	 */
	function communityBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Array of tokens that were dispersed.
	 *
	 * @param index in array.
	 * @return address address of dispersed token.
	 */
	function disperseTokens(uint256 index) external view returns (address);

	/**
	 * @dev Amount of tokens that was dispersed.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function disperseBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of tokens that was already taken from the disperse.
	 *
	 * @param tokenAddress address of token.
	 * @return uint256 total amount of tokens already taken.
	 */
	function disperseTotalTaken(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of disperse already taken by each tokenId.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 amount of tokens already taken.
	 */
	function disperseTaken(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Available payouts.
	 *
	 * @param bondId bond unique identifier.
	 * @return uint256 potential payout.
	 */
	function bondPayouts(uint256 bondId) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to array of bonds.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return uint256 index of bond.
	 */
	function bondIndexes(uint256 tokenId, uint256 index) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to token addresses who have collateralized before.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return address address of token.
	 */
	function collateralTokens(uint256 tokenId, uint256 index) external view returns (address);

	/**
	 * @dev Token balances that are stored under `tokenId`.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param tokenAddress address of token.
	 * @return uint256 token balance.
	 */
	function collateralBalances(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Calculator function for harvesting.
	 *
	 * @param amount of `communityToken`s to spend
	 * @param tokenAddress of token to be harvested
	 * @return amount to harvest based on inputs
	 */
	function getAmount(uint256 amount, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Collect commission fees gathered in exchange for `communityToken`.
	 *
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function harvest(uint256[] memory amounts, address[] memory tokenAddresses) external;

	/**
	 * @dev Collateralize NFT with different tokens and amounts.
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function collateralize(
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;

	/**
	 * @dev Withdraw underlying collateral.
	 *
	 * Requirements:
	 * - only owner of NFT
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts array of amounts to collateralize
	 * @param tokenAddresses array of token addresses
	 */
	function uncollateralize(
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external;

	/**
	 * @dev Collateralize NFT with discount, based on available bonds. While
	 * purchased bond will have delay the owner will be current smart contract
	 *
	 * @param bondId the ID of the market
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param amount the amount of quote token to spend
	 * @param maxPrice the maximum price at which to buy bond
	 */
	function getDiscountedCollateral(
		uint256 bondId,
		address quoteToken,
		uint256 tokenId,
		uint256 amount,
		uint256 maxPrice
	) external;

	/**
	 * @dev Claim collateral inside this smart contract and extending underlying
	 * data mappings.
	 *
	 * @param tokenId unique identifier of NFT inside current smart contract
	 * @param indexes array of note indexes to redeem
	 */
	function claimDiscountedCollateral(uint256 tokenId, uint256[] memory indexes) external;

	/**
	 * @dev Split collateral among all existent tokens.
	 *
	 * @param amounts to be dispersed among all NFT owners
	 * @param tokenAddresses of token to be dispersed
	 */
	function disperse(uint256[] memory amounts, address[] memory tokenAddresses) external payable;

	/**
	 * @dev See {IERC721-_mint}
	 */
	function mint(address who) external;
}