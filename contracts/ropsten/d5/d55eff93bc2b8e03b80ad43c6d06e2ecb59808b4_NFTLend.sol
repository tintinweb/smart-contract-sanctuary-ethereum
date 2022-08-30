/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// SPDX-License-Identifier: MIT


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: contracts/lend/DataProvider.sol

pragma solidity ^0.8.0;




contract DataProvider is Ownable, ERC721Holder{

    using SafeERC20 for IERC20;

    // Pause contract
    bool public pause;

    // whitelist lending ERC20 token
    mapping(address => bool) public token;
    // minimum lend amount;
    uint public minimum = 1;

    struct NFT{
        bool status;
        uint price;
    }

    //whitelist NFT token
    mapping(address => NFT) public nftToken;
    //Total lend contract ids
    uint public totalLendID;
    uint public totalBorrowedID;

    modifier isLendExist(uint id) {
        require(id < totalLendID, "Lending contract not created yet");
        _;
    }

    modifier isBorrowExist(uint id) {
        require(id < totalBorrowedID, "Borrowing contract not created yet");
        _;
    }
    
    //events
    event WhitelistERC20(address _whitelistToken);
    event BlacklistERC20(address _blacklistToken);
    event WhitelistNFT(address _whitelistNFT, uint price);
    event BlacklistNFT(address _blacklistNFT);
    event setNFTPrice(address nft,uint price);

    // Modifier details

    modifier whenNotPaused() {
        require(!pause, "Contract Paused");
        _;
    }

    // Internal methods

    function _isTokenWhitelisted(address _tokenAddress) internal view {
        require(token[_tokenAddress], "Only whitlisted token");
    }

    function _isNFTWhitelisted(address _NFTAddress) internal view {
        require(nftToken[_NFTAddress].status, "Only whitlisted token");
    }

    function _transfer(address _token, address _to, uint _amount) internal {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "insufficient funds");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function _transferFrom(address _token, address _from, address to, uint _amount) internal {
        IERC20(_token).safeTransferFrom(_from, to,  _amount);
    }

    function _transferNFT(address nft, address from, address to, uint[] memory id) internal {
        for (uint i=0; i<id.length; i++){
            IERC721(nft).safeTransferFrom(from, to, id[i]);
        }
    }

    function addFund(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    }

}

// File: contracts/lend/LenderStruct.sol

pragma solidity ^0.8.0;

contract LenderStruct is DataProvider{

    // Lending contract details
     struct Lend{
        address user;
        address lendToken;
        // Total lend amount
        uint amount;
        // Interest rate yearly
        uint interestRate;
        // Duration in days. Minimum 1 day
        uint duration;
        // Is Borrowed or not
        bool isBorrowed;
        // Total claimed interest amount
        uint totalClaimedInterest;
        uint totalRepaidAmount;

        bool repaid;
        bool isWithdrawn;
        bool liquidated;
    } 

    struct User{
        mapping(uint => bool) isExist;
        // Total created Contracts
        uint[] totalContract;
    }

    mapping(address => User) internal userInfo;

    mapping(uint => Lend) public lendDetails;        


    function deposit(address _token, uint _amount, uint _duration, uint _interestRate) external {
        _isTokenWhitelisted(_token);

        require(_duration > 0, "Duration in days");

        address _user = msg.sender;
        _transferFrom(_token, _user, address(this), _amount);

        uint _id = totalLendID;
        totalLendID += 1;

        userInfo[_user].isExist[_id] = true;
        userInfo[_user].totalContract.push(_id);

        lendDetails[_id].lendToken = _token;
        lendDetails[_id].amount = _amount;
        lendDetails[_id].duration = _duration;
        lendDetails[_id].interestRate = _interestRate;     
        lendDetails[_id].user = _user;
        // add event
    }

    // withdraw created lend
    function withdraw(uint id) external isLendExist(id) {
        address _user = msg.sender; 
        require(lendDetails[id].user == _user, "Incorrect lender");
        require(lendDetails[id].isBorrowed == false, "Borrowed");
        require(lendDetails[id].isWithdrawn == false, "Already withdrawn");

        lendDetails[id].isWithdrawn = true;

        _transfer(lendDetails[id].lendToken, _user, lendDetails[id].amount);

        // add event      
    }

 
    
}

// File: contracts/lend/BorrowStruct.sol

pragma solidity ^0.8.0;

contract BorrowStruct is LenderStruct {

    struct Borrow {
        address user;
        // NFT address
        address NFT; 
        uint[] assestIds;
        // lending contract index
        uint lendId;
        // borrowedDetails timestamp
        uint256 timestamp;
        bool claim;
    }

    struct BorrowUser{
        mapping(uint => bool) isExist;
        // Total created Contracts
        uint[] totalContract;
    }

    mapping(address => BorrowUser) internal borrowedUserInfo;
    mapping(uint => Borrow) public borrowedDetails;

    function borrow(address nftAddress, uint[] memory id, uint lendId) external isLendExist(lendId) {
        uint _amount = _checkBorrowRequired(nftAddress, id, lendId);
        uint _id = totalBorrowedID;
        address _user = msg.sender;
        totalBorrowedID += 1;

        _transferNFT(nftAddress, _user, address(this), id);

        borrowedDetails[_id] = Borrow(_user, nftAddress, id, lendId, block.timestamp, false);
        
        _transfer(lendDetails[lendId].lendToken, _user, _amount);

        // Add event               
    }

    function _checkBorrowRequired(address nft, uint[] memory id, uint lendId) internal view returns(uint) {
        _isNFTWhitelisted(nft);
        require((!lendDetails[lendId].isBorrowed) && (!lendDetails[lendId].isWithdrawn), "Lending contract is not valid");
        
        uint amount = lendDetails[lendId].amount;
        
        require(((id.length * nftToken[nft].price)) >= amount, "Insufficient collateral assets");

        return amount;
    }

    function payInterest(uint borrowedId, uint amount) external {
        address _user = msg.sender;
        _requiredRepay(borrowedId, _user);
        uint lendId = borrowedDetails[borrowedId].lendId;
        uint interst = getPendingIntrest(lendId);
        if(amount == 0){
            amount = interst;
        }else if(amount >interst){
            amount = interst;
        }

       _transferFrom(lendDetails[lendId].lendToken, _user, lendDetails[lendId].user, amount);
       
       lendDetails[lendId].totalClaimedInterest += lendDetails[lendId].totalClaimedInterest + amount;

       _claimNFT(lendId, borrowedId, _user);
       
    }

    function _claimNFT(uint lendId, uint borrowedId, address user) internal {
        if( (lendDetails[lendId].totalClaimedInterest ==  getTotalIntrest(lendId)) && (lendDetails[lendId].amount == lendDetails[lendId].totalRepaidAmount) )
        {
            borrowedDetails[borrowedId].claim = true;
            lendDetails[lendId].repaid = true;
       
            _transferNFT(borrowedDetails[borrowedId].NFT, address(this), user, borrowedDetails[borrowedId].assestIds);
        }

    }

    function payLoan(uint borrowedId, uint amount) external {
         address _user = msg.sender;
        _requiredRepay(borrowedId, _user);
         uint lendId =  borrowedDetails[borrowedId].lendId;   
         uint totalamount = (lendDetails[lendId].amount - lendDetails[lendId].totalRepaidAmount) ;
        
        if( (amount == 0) || (amount > totalamount)){
            amount = totalamount;
        } 

        _transferFrom(lendDetails[lendId].lendToken, _user, lendDetails[lendId].user, amount);

        lendDetails[lendId].totalRepaidAmount += lendDetails[lendId].totalRepaidAmount + amount;
        
        _claimNFT(lendId, borrowedId, _user);

    }

    function payLoanRedemptionsNFT(uint borrowedId) external {
        address _user = msg.sender;
        _requiredRepay(borrowedId, _user);

        uint lendId = borrowedDetails[borrowedId].lendId;
        uint remaingAmount = ((lendDetails[lendId].amount - lendDetails[lendId].totalRepaidAmount) + getPendingIntrest(lendId));
        
        _transferFrom(lendDetails[lendId].lendToken, _user, lendDetails[lendId].user, remaingAmount);
        
        borrowedDetails[borrowedId].claim = true;
        lendDetails[lendId].repaid = true;
       
        _transferNFT(borrowedDetails[borrowedId].NFT, address(this), _user, borrowedDetails[borrowedId].assestIds);

        // add event        

    }

    function _requiredRepay(uint borrowedId, address user) internal view isBorrowExist(borrowedId) {
        require(user == borrowedDetails[borrowedId].user, "Invalid user");
        uint lendId = borrowedDetails[borrowedId].lendId;
        uint time = (block.timestamp - borrowedDetails[borrowedId].timestamp)/ 1 days;
        require(lendDetails[lendId].duration >= time, "loan repay time ended");

        require(!lendDetails[lendId].liquidated, "Already liquidated");

        require((!borrowedDetails[borrowedId].claim) && !(lendDetails[lendId].repaid), "Repaid loan");
    }

    function liquidateBorrowLoan(uint borrowedId) external {
        address _user = msg.sender;
        uint lendId = borrowedDetails[borrowedId].lendId;

        require(_user == lendDetails[lendId].user, "Only lender");
        uint time = (block.timestamp - borrowedDetails[borrowedId].timestamp)/ 1 days;

        require(time > lendDetails[lendId].duration, "Too early");
        require(!lendDetails[lendId].liquidated, "Already liquidated");
        
        lendDetails[lendId].liquidated = true; 
        _transferNFT(borrowedDetails[borrowedId].NFT, address(this), _user, borrowedDetails[borrowedId].assestIds);

    }


    function getTotalIntrest(uint lendId) public view returns(uint interst){
        interst = ((lendDetails[lendId].amount * lendDetails[lendId].interestRate) / 100) / 365;
        return interst;
    }

    function getPendingIntrest(uint lendId) public view returns(uint interst){
        interst = getTotalIntrest(lendId);
        interst = interst -  lendDetails[lendId].totalClaimedInterest;
        return interst;
    }




}

// File: contracts/NFTLend.sol

pragma solidity ^0.8.0;

contract NFTLend is BorrowStruct{

     function whiteListERC20(address[] memory whitelistToken) external onlyOwner {
        for(uint i=0; i<whitelistToken.length; i++){
            require(token[whitelistToken[i]] == false, "Already whitelisted");
            token[whitelistToken[i]] = true;
            emit WhitelistERC20(whitelistToken[i]);
        }
    } 

    function blackListERC20(address[] memory blacklistToken) external onlyOwner { 
        for(uint i=0; i<blacklistToken.length; i++){
            require(token[blacklistToken[i]] == true, "Already blacklisted");
            token[blacklistToken[i]] = false;
            emit BlacklistERC20(blacklistToken[i]);
        }
    }

    function whiteListNFT(address[] memory whitelistNFT, uint[] memory price) external onlyOwner {
        for(uint i=0; i<whitelistNFT.length; i++){
            require(nftToken[whitelistNFT[i]].status == false, "Already NFT whitelisted");
            nftToken[whitelistNFT[i]] = NFT(true, price[i]);
            emit WhitelistNFT(whitelistNFT[i], price[i]);
        }
    } 

    function blackListNFT(address[] memory blacklistNFT) external onlyOwner { 
        for(uint i=0; i<blacklistNFT.length; i++){
            require(nftToken[blacklistNFT[i]].status == true, "Already NFT blacklisted");
            nftToken[blacklistNFT[i]].status = false;
            emit BlacklistNFT(blacklistNFT[i]);
        }
    }

    function setPrice(address nft, uint price) external onlyOwner {
        nftToken[nft].price = price;
        emit setNFTPrice(nft, price);
    }


    
}