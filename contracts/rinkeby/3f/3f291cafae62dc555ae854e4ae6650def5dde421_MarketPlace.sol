/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library DataTypes {
    struct Order {
        address owner;
        address nftAddress;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    struct Royalty {
        address receiver;
        uint256 percentage; // multiply by 100
    }

    // note struct for web3Entry
    struct Note {
        bytes32 linkItemType;
        bytes32 linkKey;
        string contentUri;
        address linkModule;
        address mintModule;
        address mintNFT;
        bool deleted;
        bool locked;
    }
}

interface IMarketPlace {
    function getRoyalty(address token) external view returns (DataTypes.Royalty memory);

    function setRoyalty(
        uint256 characterId,
        uint256 noteId,
        address receiver,
        uint256 percentage
    ) external;

    function ask(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function updateAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _newPrice,
        uint256 _deadline
    ) external;

    function cancelAsk(address _nftAddress, uint256 _tokenId) external;

    function acceptAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) external payable;

    function bid(
        address _nftAddress,
        uint256 _tokenId,
        address payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function cancelBid(address _nftAddress, uint256 _tokenId) external;

    function updateBid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    ) external;

    function acceptBid(
        address _nftAddress,
        uint256 _tokenId,
        address _creator
    ) external;
}

interface IWeb3Entry {
    function getNote(uint256 characterId, uint256 noteId)
        external
        view
        returns (DataTypes.Note memory);
}

library Constants {
    uint256 constant MAX_ROYALTY = 10000;
    address constant NATIVE_CSB = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;
}

library Events {
    /**
     * @notice Emitted when the royalty is set by the mintNFT owner.
     * @param owner The owner of mintNFT.
     * @param nftAddress The mintNFT address.
     * @param receiver The address receiving the royalty.
     * @param receiver The percentage of the royalty.
     */
    event RoyaltySet(
        address indexed owner,
        address indexed nftAddress,
        address receiver,
        uint256 percentage
    );

    /**
     * @notice Emitted when an ask order is created.
     * @param owner The owner of the ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to be sold.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     */
    event AskCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when an ask order is updated.
     * @param owner The owner of the ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new sale price for the NFT.
     * @param deadline The expiration timestamp of the ask order.
     */
    event AskUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when an ask order is canceled.
     * @param owner The owner of the ask order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     */
    event AskCanceled(address indexed owner, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @notice Emitted when a bid order is created.
     * @param owner The owner of the bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT to bid.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     */
    event BidCreated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when a bid  order is canceled.
     * @param owner The owner of the bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     */
    event BidCanceled(address indexed owner, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @notice Emitted when a bid order is updated.
     * @param owner The owner of the bid order.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The new bid price for the NFT.
     * @param deadline The expiration timestamp of the bid order.
     */
    event BidUpdated(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    /**
     * @notice Emitted when a bid/ask order is accepted(matched).
     * @param seller The seller, as well as the owner of nft.
     * @param buyer The buyer who wanted to paying ERC20 tokens for the nft.
     * @param nftAddress The contract address of the NFT.
     * @param tokenId The token id of the NFT.
     * @param payToken The ERC20 token address for buyers to pay.
     * @param price The price the buyer will pay to the seller.
     * @param royaltyReceiver The receiver of the royalty fee.
     * @param feeAmount The amount of the royalty fee.
     */
    event OrdersMatched(
        address indexed seller,
        address indexed buyer,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price,
        address royaltyReceiver,
        uint256 feeAmount
    );
}

contract MarketPlaceStorage {
    address public web3Entry; // slot 10
    address public WCSB;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) public askOrders;

    //  @notice nftAddress -> tokenId -> owner -> Order
    mapping(address => mapping(uint256 => mapping(address => DataTypes.Order))) public bidOrders;

    // @notice nftAddress -> Royalty
    mapping(address => DataTypes.Royalty) public royalties;
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

contract MarketPlace is IMarketPlace, Context, ReentrancyGuard, Initializable, MarketPlaceStorage {
    using SafeERC20 for IERC20;

    uint256 internal constant REVISION = 1;
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    modifier askNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];
        require(askOrder.deadline == 0, "AskExists");
        _;
    }

    modifier askExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];
        require(askOrder.deadline > 0, "AskNotExists");
        _;
    }

    modifier validAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];
        require(askOrder.deadline >= _now(), "AskExpiredOrNotExists");
        _;
    }

    modifier bidNotExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];
        require(bidOrder.deadline == 0, "BidExists");
        _;
    }

    modifier bidExists(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];
        require(bidOrder.deadline > 0, "BidNotExists");
        _;
    }

    modifier validBid(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];
        require(bidOrder.deadline != 0, "BidNotExists");
        require(bidOrder.deadline >= _now(), "BidExpired");
        _;
    }

    modifier validPayToken(address _payToken) {
        require(_payToken == WCSB || _payToken == Constants.NATIVE_CSB, "InvalidPayToken");
        _;
    }

    modifier validDeadline(uint256 _deadline) {
        require(_deadline > _now(), "InvalidDeadline");
        _;
    }

    modifier validPrice(uint256 _price) {
        require(_price > 0, "InvalidPrice");
        _;
    }

    /**
     * @notice Initializes the MarketPlace, setting the initial web3Entry address and WCSB address.
     * @param _web3Entry The address of web3Entry.
     * @param _wcsb The address of WCSB.
     */
    function initialize(address _web3Entry, address _wcsb) external initializer {
        web3Entry = _web3Entry;
        WCSB = _wcsb;
    }

    /**
     * @notice Returns the royalty according to a given nft token address.
     * @param token The nft token address to query with.
     * @return Royalty The royalty struct.
     */
    function getRoyalty(address token) external view returns (DataTypes.Royalty memory) {
        return royalties[token];
    }

    /**
     * @notice Sets the royalty.
     * @param characterId The character ID of note.
     * @param noteId The note ID of note.
     * @param receiver The address receiving the royalty.
     * @param percentage The percentage of the royalty. (multiply by 100, which means 10000 is 100 percent)
     */
    function setRoyalty(
        uint256 characterId,
        uint256 noteId,
        address receiver,
        uint256 percentage
    ) external {
        require(percentage <= Constants.MAX_ROYALTY, "InvalidPercentage");
        // check character owner
        require(msg.sender == IERC721(web3Entry).ownerOf(characterId), "NotCharacterOwner");

        // check mintNFT address
        DataTypes.Note memory note = IWeb3Entry(web3Entry).getNote(characterId, noteId);
        require(note.mintNFT != address(0), "NoMintNFT");

        // set royalty
        royalties[note.mintNFT].receiver = receiver;
        royalties[note.mintNFT].percentage = percentage;

        emit Events.RoyaltySet(msg.sender, note.mintNFT, receiver, percentage);
    }

    /**
     * @notice Creates an ask order for an NFT.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT to be sold.
     * @param _payToken The ERC20 token address for buyers to pay.
     * @param _price The sale price for the NFT.
     * @param _deadline The expiration timestamp of the ask order.
     */
    function ask(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        askNotExists(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");
        require(IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender(), "NotERC721TokenOwner");

        // save sell order
        askOrders[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );

        emit Events.AskCreated(_msgSender(), _nftAddress, _tokenId, WCSB, _price, _deadline);
    }

    /**
     * @notice Updates an ask order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _price The new sale price for the NFT.
     * @param _deadline The new expiration timestamp of the ask order.
     */
    function updateAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        askExists(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        DataTypes.Order storage askOrder = askOrders[_nftAddress][_tokenId][_msgSender()];
        // update ask order
        askOrder.payToken = _payToken;
        askOrder.price = _price;
        askOrder.deadline = _deadline;

        emit Events.AskUpdated(_msgSender(), _nftAddress, _tokenId, _payToken, _price, _deadline);
    }

    /**
     * @notice Cancels an ask order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     */
    function cancelAsk(address _nftAddress, uint256 _tokenId)
        external
        askExists(_nftAddress, _tokenId, _msgSender())
    {
        delete askOrders[_nftAddress][_tokenId][_msgSender()];

        emit Events.AskCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    /**
     * @notice Accepts an ask order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _user The owner of ask order, as well as the  owner of the NFT.
     */
    function acceptAsk(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) external payable nonReentrant validAsk(_nftAddress, _tokenId, _user) {
        DataTypes.Order memory askOrder = askOrders[_nftAddress][_tokenId][_user];

        DataTypes.Royalty memory royalty = royalties[askOrder.nftAddress];
        // pay to owner
        uint256 feeAmount = _payWithFee(
            _msgSender(),
            askOrder.owner,
            askOrder.payToken,
            askOrder.price,
            royalty.receiver,
            royalty.percentage
        );
        // transfer nft
        IERC721(_nftAddress).safeTransferFrom(_user, _msgSender(), _tokenId);

        emit Events.OrdersMatched(
            askOrder.owner,
            _msgSender(),
            _nftAddress,
            _tokenId,
            askOrder.payToken,
            askOrder.price,
            royalty.receiver,
            feeAmount
        );

        delete askOrders[_nftAddress][_tokenId][_user];
    }

    /**
     * @notice Creates an bid order for an NFT.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT to bid.
     * @param _payToken The ERC20 token address for buyers to pay.
     * @param _price The bid price for the NFT.
     * @param _deadline The expiration timestamp of the bid order.
     */
    function bid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        bidNotExists(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        require(_payToken != Constants.NATIVE_CSB, "NativeCSBNotAllowed");
        require(IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721), "TokenNotERC721");

        // save buy order
        bidOrders[_nftAddress][_tokenId][_msgSender()] = DataTypes.Order(
            _msgSender(),
            _nftAddress,
            _tokenId,
            _payToken,
            _price,
            _deadline
        );

        emit Events.BidCreated(_msgSender(), _nftAddress, _tokenId, _payToken, _price, _deadline);
    }

    /**
     * @notice Cancels a bid order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     */
    function cancelBid(address _nftAddress, uint256 _tokenId)
        external
        bidExists(_nftAddress, _tokenId, _msgSender())
    {
        delete bidOrders[_nftAddress][_tokenId][_msgSender()];

        emit Events.BidCanceled(_msgSender(), _nftAddress, _tokenId);
    }

    /**
     * @notice Updates a bid order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _payToken The ERC20 token address for buyers to pay.
     * @param _price The new bid price for the NFT.
     * @param _deadline The new expiration timestamp of the ask order.
     */
    function updateBid(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _deadline
    )
        external
        validBid(_nftAddress, _tokenId, _msgSender())
        validPayToken(_payToken)
        validDeadline(_deadline)
        validPrice(_price)
    {
        DataTypes.Order storage bidOrder = bidOrders[_nftAddress][_tokenId][_msgSender()];
        // update buy order
        bidOrder.payToken = _payToken;
        bidOrder.price = _price;
        bidOrder.deadline = _deadline;

        emit Events.BidUpdated(_msgSender(), _nftAddress, _tokenId, _payToken, _price, _deadline);
    }

    /**
     * @notice Accepts a bid order.
     * @param _nftAddress The contract address of the NFT.
     * @param _tokenId The token id of the NFT.
     * @param _user The owner of bid order.
     */
    function acceptBid(
        address _nftAddress,
        uint256 _tokenId,
        address _user
    ) external nonReentrant validBid(_nftAddress, _tokenId, _user) {
        DataTypes.Order memory bidOrder = bidOrders[_nftAddress][_tokenId][_user];

        DataTypes.Royalty memory royalty = royalties[bidOrder.nftAddress];
        // pay to msg.sender
        uint256 feeAmount = _payWithFee(
            bidOrder.owner,
            _msgSender(),
            bidOrder.payToken,
            bidOrder.price,
            royalty.receiver,
            royalty.percentage
        );
        // transfer nft
        IERC721(_nftAddress).safeTransferFrom(_msgSender(), _user, _tokenId);

        emit Events.OrdersMatched(
            _msgSender(),
            bidOrder.owner,
            _nftAddress,
            _tokenId,
            bidOrder.payToken,
            bidOrder.price,
            royalty.receiver,
            feeAmount
        );

        delete bidOrders[_nftAddress][_tokenId][_user];
    }

    function _payWithFee(
        address from,
        address to,
        address token,
        uint256 amount,
        address feeReceiver,
        uint256 feePercentage
    ) internal returns (uint256 feeAmount) {
        if (token == Constants.NATIVE_CSB) {
            require(msg.value >= amount, "NotEnoughFunds");

            // pay CSB
            if (feeReceiver != address(0)) {
                feeAmount = (amount / 10000) * feePercentage;
                payable(feeReceiver).transfer(feeAmount);
                payable(to).transfer(amount - feeAmount);
            } else {
                payable(to).transfer(amount);
            }
        } else {
            // refund CSB
            if (msg.value > 0) {
                payable(from).transfer(msg.value);
            }
            // pay ERC20
            if (feeReceiver != address(0)) {
                feeAmount = (amount / 10000) * feePercentage;
                IERC20(token).safeTransferFrom(from, feeReceiver, feeAmount);
                IERC20(token).safeTransferFrom(from, to, amount - feeAmount);
            } else {
                IERC20(token).safeTransferFrom(from, to, amount);
            }
        }
    }

    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice returns the revision number of the contract.
     **/
    function getRevision() external pure returns (uint256) {
        return REVISION;
    }
}