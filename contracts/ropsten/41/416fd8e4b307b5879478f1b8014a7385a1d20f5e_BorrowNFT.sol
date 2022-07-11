/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


pragma solidity ^0.8.0;

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: contracts/IERC721Extended.sol

pragma solidity ^0.8.0;

interface IERC721Extended is IERC721 {

        function mint(address receiver) external returns(uint256) ;

        function burn(uint256 tokenId) external returns(uint256) ;

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/BorrowNFT.sol

pragma solidity ^0.8.0;



contract BorrowNFT is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;

    IERC721Extended public immutable collateralNFT;
    IERC721Extended public immutable receiptNFT;

    IERC20 public USDT;

    // Price of collateralNFT
    uint256 public nftPrice;
    // Price of collateral ETH
    uint256 public price;
    // Borrowing fee percentage
    uint256 public feePcent = 35; // 0.035 up to 2 decimal
    // Pause contract
    bool public pause;
    // collateral contract return end time
    uint256 public endTime = 30 minutes;
    uint256 public interval = 10 minutes;
    // Minimum eth collateral amount
    uint256 public minETH = 0.1e18;
    uint256 public minUSDTLoan = 1e6;

    struct Borrower {
        // Borrowed status
        bool status;
        // Staked nft ids
        bool isNFT;
        uint256[] ids;
        // or Staked eth amount
        uint256 amount;
        // borrowed timestamp
        uint256 timestamp;
        // Total Borrowed usdt amount
        uint256 usdtAmount;
        uint256 receiptID;
        // Total repaid amount
        uint256 repaidAmount;
        // total interest paid
        uint256 feePaid;
    }

    mapping(address => Borrower) public borrowerInfo;

    // Event details

    event BorrowETH(
        address user,
        uint256 borrowedUSDT,
        uint256 ethValue,
        uint256 ethPrice
    );
    event BorrowNFTs(
        address borrower,
        uint256 borrowUSDT,
        uint256[] tokenID,
        uint256 tokenPrice
    );
    event RepayandRedemption(address borrower, uint256 usdt);
    event ETHRedemption(uint256 ethValue);
    event NFTRedemption(uint256[] tokenId);
    event Repay(address borrower, uint256 usdt);
    event LiquidateCollateralLoan(
        address caller,
        address borrowerAddr,
        address receiver
    );
    event ETHPrice(uint256 newPrice);
    event NFTPrice(uint256 nftNewPrice);
    event SetMinimumETHCollateral(uint256 newMinETH);
    event SetMinimumUSDTLoan(uint256 newMinUSDTLoan);

    // Modifier details

    modifier whenNotPaused() {
        require(!pause, "Contract Paused");
        _;
    }

    modifier ifNotBorrowed() {
        require(!borrowerInfo[msg.sender].status, "Already borrowed");
        _;
    }

    modifier ifOnlyBorrowed(address _user) {
        require(borrowerInfo[_user].status, "Only borrowed user");
        _;
    }

    modifier checkRedemptionTime(address _borrower) {
        require(
            (borrowerInfo[_borrower].timestamp + endTime) > block.timestamp,
            "Too late!.."
        );
        _;
    }

    constructor(
        address _collateralNFT,
        address _receiptNFT,
        address _USDT, 
        uint256 _ETHPrice, // ETH price in USDT
        uint256 _NFTPrice // NFT price in USDT
    ) {
        collateralNFT = IERC721Extended(_collateralNFT);
        USDT = IERC20(_USDT);
        receiptNFT = IERC721Extended(_receiptNFT);
        price = _ETHPrice;
        nftPrice = _NFTPrice;

        emit ETHPrice(_ETHPrice);
        emit NFTPrice(_NFTPrice);
    }

    function borrowUSDTbyETH() external payable whenNotPaused ifNotBorrowed {
        uint256 msgValue = msg.value;
        address user = msg.sender;
        require(msgValue >= minETH, "Less than minETH amount");

        uint256 usdtReturn = calculateETHReturn(msgValue);

        checkUSDTBalance(usdtReturn);

        borrowerInfo[user].status = true;
        borrowerInfo[user].amount = msgValue;
        borrowerInfo[user].timestamp = block.timestamp;
        borrowerInfo[user].receiptID = _mintReceiptNFT(user);
        borrowerInfo[user].usdtAmount = usdtReturn;

        USDT.safeTransfer(user, usdtReturn);
        emit BorrowETH(user, usdtReturn, msgValue, price);
    }

    function BorrowUSDTbyNFT(uint256[] memory tokenIds)
        external
        whenNotPaused
        ifNotBorrowed
    {
        require(tokenIds.length != 0, "Invalid input");
        address user = msg.sender;

        transferFromcolletralNFT(user, tokenIds);
        uint256 usdtReturn = calculateNFTReturn(tokenIds.length);
        checkUSDTBalance(usdtReturn);

        borrowerInfo[user].status = true;
        borrowerInfo[user].isNFT = true;
        borrowerInfo[user].ids = tokenIds;
        borrowerInfo[user].timestamp = block.timestamp;
        borrowerInfo[user].usdtAmount = usdtReturn;

        borrowerInfo[user].receiptID = _mintReceiptNFT(user);

        USDT.safeTransfer(user, usdtReturn);
        emit BorrowNFTs(user, usdtReturn, tokenIds, nftPrice);
    }

    function repayRedemptionCollateral(uint256 _usdtAmount)
        public
        whenNotPaused
        ifOnlyBorrowed(msg.sender)
        checkRedemptionTime(msg.sender)
    {
        address _user = msg.sender;
        uint256 pendingPayment = calculateRedemptionWithInterest(_user);
        require(
            _usdtAmount >= pendingPayment,
            "Insufficient usdt amount to redeem collateral"
        );

        USDT.transferFrom(_user, address(this), pendingPayment);

        _burnReceiptNFT(borrowerInfo[_user].receiptID);
        borrowerInfo[_user].receiptID = 0;
        borrowerInfo[_user].status = false;

        if (borrowerInfo[_user].isNFT) {
            repayNFTcollateral(_user);
        } else {
            repayETHcollateral(payable(_user));
        }

        emit RepayandRedemption(_user, pendingPayment);
    }

    function repay(uint256 _usdtAmount)
        external
        ifOnlyBorrowed(msg.sender)
        checkRedemptionTime(msg.sender)
    {
        require(_usdtAmount > 0, "Zero usdt value");

        if (_usdtAmount >= calculateRedemptionWithInterest(msg.sender)) {
            repayRedemptionCollateral(_usdtAmount);
        } else {
            _repay(msg.sender, _usdtAmount);
        }
    }

    function _repay(address _user, uint256 _usdtAmount) private {
        USDT.transferFrom(_user, address(this), _usdtAmount);
        uint256 Interest = getInterest(_user);
        if (_usdtAmount < Interest) {
            borrowerInfo[_user].feePaid =
                borrowerInfo[_user].feePaid +
                _usdtAmount;
        } else {
            borrowerInfo[_user].feePaid =
                borrowerInfo[_user].feePaid +
                Interest;
            borrowerInfo[_user].usdtAmount =
                borrowerInfo[_user].usdtAmount +
                (_usdtAmount - Interest);
        }

        emit Repay(_user, _usdtAmount);
    }

    function repayETHcollateral(address payable _borrower) private {
        uint256 _eth = borrowerInfo[_borrower].amount;
        delete borrowerInfo[_borrower];
        _borrower.transfer(_eth);
        emit ETHRedemption(_eth);
    }

    function repayNFTcollateral(address _borrower) private {
        borrowerInfo[_borrower].status = false;
        uint256[] memory tokenIds = borrowerInfo[_borrower].ids;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            collateralNFT.safeTransferFrom(
                address(this),
                _borrower,
                tokenIds[i]
            );
        }
        delete borrowerInfo[_borrower];

        emit NFTRedemption(tokenIds);
    }

    function checkUSDTBalance(uint256 _amount) private view {
        require(_amount >= minUSDTLoan, "Less than minUSDTLoan amount");
        require(
            USDT.balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );
    }

    function _mintReceiptNFT(address receiver) private returns (uint256) {
        return receiptNFT.mint(receiver);
    }

    function _burnReceiptNFT(uint256 _tokenId) private returns (uint256) {
        return receiptNFT.burn(_tokenId);
    }

    function transferFromcolletralNFT(address user, uint256[] memory tokenIds)
        private
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            collateralNFT.safeTransferFrom(user, address(this), tokenIds[i]);
        }
    }

    // Read only functions

    function getInterest(address _user) public view returns (uint256) {
        uint256 intrst;
        if ((borrowerInfo[_user].timestamp + endTime) > block.timestamp) {
            intrst =
                1 +
                ((block.timestamp - borrowerInfo[_user].timestamp) / interval);
            intrst =
                ((intrst * (feePcent)) * borrowerInfo[_user].usdtAmount) /
                10000;
        } else {
            intrst =
                ((3 * (feePcent)) * borrowerInfo[_user].usdtAmount) /
                10000;
        }

        if (borrowerInfo[_user].feePaid > 0) {
            intrst = intrst - borrowerInfo[_user].feePaid;
        }

        return intrst;
    }

    function calculateRedemptionWithInterest(address _user)
        public
        view
        returns (uint256)
    {
        uint256 pay;
        if (borrowerInfo[_user].repaidAmount > 0) {
            pay =
                borrowerInfo[_user].usdtAmount -
                borrowerInfo[_user].repaidAmount;
        } else {
            pay = borrowerInfo[_user].usdtAmount;
        }
        return (pay + getInterest(_user));
    }

    function calculateETHReturn(uint256 ethValue)
        public
        view
        returns (uint256)
    {
        ethValue = (ethValue * price)/1e18;
        return ((ethValue * 80) / 100);
    }

    function calculateNFTReturn(uint256 totalNFT)
        public
        view
        returns (uint256)
    {
        totalNFT = totalNFT * nftPrice;
        return ((totalNFT * 80) / 100);
    }

    // Only owner can invoke these following methods

    function liquidate(address _borrowerAddr, address payable _receiver)
        external
        onlyOwner
    {
        require(
            (borrowerInfo[_borrowerAddr].timestamp + endTime) < block.timestamp,
            "Too earley!.."
        );

        if (borrowerInfo[_borrowerAddr].isNFT) {
            uint256 _eth = borrowerInfo[_borrowerAddr].amount;
            delete borrowerInfo[_borrowerAddr];
            _receiver.transfer(_eth);
            emit ETHRedemption(_eth);
        } else {
            uint256[] memory tokenIds = borrowerInfo[_borrowerAddr].ids;
            delete borrowerInfo[_borrowerAddr];
            for (uint256 i = 0; i < tokenIds.length; i++) {
                collateralNFT.safeTransferFrom(
                    address(this),
                    _receiver,
                    tokenIds[i]
                );
            }
            emit NFTRedemption(tokenIds);
        }

        emit LiquidateCollateralLoan(msg.sender, _borrowerAddr, _receiver);
    }

    function addFund(uint256 amount) external onlyOwner {
        USDT.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address receiver, uint256 amount) external onlyOwner {
        USDT.safeTransfer(receiver, amount);
    }

    function setMinimumETHCollateral(uint256 _newMinETH) external onlyOwner{
        require(_newMinETH > 0, "Zero minimun ETH collateral");
        minETH = _newMinETH;
        emit SetMinimumETHCollateral( _newMinETH);
    }
    
    function setMinimumUSDTLoan(uint256 _newMin) external onlyOwner{
        require(_newMin > 0, "Zero USDT loan amount");
        minUSDTLoan = _newMin;
        emit SetMinimumUSDTLoan( _newMin);
    }
       
    function setETHPrice(uint256 _newPrice) external onlyOwner{
        require(_newPrice > 0, "Zero ETH price");
        price = _newPrice;
        emit ETHPrice(_newPrice);
    }

    function setNFTPrice(uint256 _nftNewPrice) external onlyOwner{
        require(_nftNewPrice > 0, "Zero NFT price");
        nftPrice = _nftNewPrice;
        emit NFTPrice(_nftNewPrice);
    }

}