/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/
//  0xcCb0Fd390A5777cECfF400Fe10016b4Dce3d0e82
/**
 *Submitted for verification at BscScan.com on 2022-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
            // return returndata;

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
            // return returndata;
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
/**
 * @title ProjectStarter Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */






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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;


    // custom minting functionality with id and uri.
    function mintPro(address recipient, string memory uri, uint256 mintIndex) external payable returns (uint256);
    
}


contract Marketplace is Ownable {
    using SafeMath for uint256;

    IERC20 public weth;

    address public ownerWalletAddress;
    uint256 public platformFee;
    address public feeWallet;


    event Offerandmint(address _owner, address _bidder, uint256 _amount, string  uri, uint256 mintIndex, IERC721 contractAddress);
    event Acceptbidandmint(address _seller, address _bidder, uint256 _amount, uint256 mintIndex, IERC721 contractAddress);
    event Buyandmint(address _seller, address _buyer, uint256 _amount, string  uri, uint256 mintIndex, IERC721 contractAddress);
    event Offerandtransfer(address _owner, address _bidder, uint256 _amount, uint256 tokenId, IERC721 contractAddress);
    event Acceptbidandtransfer(address  _seller, address _bidder, uint256 _amount, uint256 tokenId, uint256 deadline, IERC721 contractAddress);
    event Buyandtransfer(address _seller, address _buyer, uint256 _amount, uint256 tokenId, IERC721 contractAddress);
    event Withdrawstoredinaccount(address recipient, uint256 amount);


    constructor() {
        ownerWalletAddress = owner();
        weth = IERC20(0x7eBDA8DDBd2De8d719662654347bDfc507327DB4);
        platformFee = 0;
        feeWallet = msg.sender;
    }

    struct tuple{
        address _seller;
        address _bidder;
        uint256 _amount;
        uint256 tokenId;
    }

    /**
    * Mints ProjectStarter
    */
    function OfferAndMint(tuple memory values, string memory uri, uint8 sv, bytes32 sr, bytes32 ss, uint8 bv, bytes32 br, bytes32 bs, IERC721 contractAddress) public returns (uint256) {
        require(weth.allowance(values._bidder, address(this)) >= values._amount, "allowance not given");
        require(weth.balanceOf(values._bidder) >= values._amount, "not enought balaance");

        IERC721 Nft = IERC721(contractAddress);

        // require(deadline >= block.timestamp, "deadline passed");
        require(values._seller == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._seller , values._amount))), sv, sr, ss), "Owner signature is Invalid");

        require(values._bidder == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._bidder, values._amount))), bv, br, bs), "Bidder signature is Invalid");

        // uint256 _fee = platformFee.mul(values._amount).div(100);

        // weth.transferFrom(values._seller, feeWallet, _fee);
        // weth.transferFrom(values._bidder, values._seller, values._amount.sub(_fee));

        processTokenPayments(values._bidder, values._seller, values._amount);

        Nft.mintPro(values._bidder, uri, values.tokenId);
        emit Offerandmint(values._seller, values._bidder, values._amount , uri , values.tokenId , contractAddress);

        return values.tokenId;
    }

    function AcceptBidAndMint(tuple memory values, string memory uri, uint256 deadline, uint8 sv, bytes32 sr, bytes32 ss,  uint8 bv, bytes32 br, bytes32 bs, IERC721 contractAddress) public returns (uint256) {
        require(weth.allowance(values._bidder, address(this)) >= values._amount, "allowance not provided");
        require(weth.balanceOf(values._bidder) >= values._amount, "not enought balaance");

        IERC721 Nft = IERC721(contractAddress);

        require(deadline >= block.timestamp, "deadline passed");
        signVerification(values._seller, values._bidder , deadline , values._amount, sv, sr, ss ,  bv, br, bs);

        processTokenPayments(values._bidder, values._seller, values._amount);


        Nft.mintPro(values._bidder, uri, values.tokenId);
        emit Acceptbidandmint(values._seller, values._bidder, values._amount , values.tokenId, contractAddress);

        return values.tokenId;
    }

    function BuyAndMint(tuple memory values, string memory uri, uint8 sv, bytes32 sr, bytes32 ss,  uint8 bv, bytes32 br, bytes32 bs, IERC721 contractAddress) public payable returns (uint256) {
        require(msg.value == values._amount, "Value sent is not Correct");
        IERC721 Nft = IERC721(contractAddress);

        require(values._seller == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._seller , values._amount))), sv, sr, ss), "Seller signature is Invalid");
        require(values._bidder == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._bidder , values._amount))), bv, br, bs), "Buyer signature is Invalid");
 
        processEthPayments(values._seller, values._amount);

        Nft.mintPro(values._bidder, uri, values.tokenId);
        // emit Buyandmint(values._seller, values._bidder, values._amount, uri, values.tokenId, contractAddress);

        return values.tokenId;
    }
        
    function OfferAndTransfer(tuple memory values, uint8 sv, bytes32 sr, bytes32 ss,  uint8 bv, bytes32 br, bytes32 bs, IERC721 contractAddress) public returns (uint256) {
        require(weth.allowance(values._bidder, address(this)) >= values._amount, "Allowance not given");
        require(weth.balanceOf(values._bidder) >= values._amount, "not enought balance");

        IERC721 Nft = IERC721(contractAddress);
        
        require(Nft.ownerOf(values.tokenId) == values._seller, "seller is not the owner");
        require(Nft.isApprovedForAll(values._seller, address(this)), "Allowance is not provided");

        // require(deadline >= block.timestamp, "deadline passed");
        require(values._seller == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._seller , values._amount))), sv, sr, ss), "Owner signature is Invalid");
        require(values._bidder == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._bidder , values._amount))), bv, br, bs), "Bidder signature is Invalid");

        processTokenPayments(values._bidder, values._seller, values._amount);

        Nft.safeTransferFrom(values._seller, values._bidder, values.tokenId);
        emit Offerandtransfer(values._seller, values._bidder, values._amount ,values.tokenId , contractAddress);

        return values.tokenId;
    }

    function AcceptBidAndTransfer(tuple memory values, uint256 deadline, uint8 sv, bytes32 sr, bytes32 ss,  uint8 bv, bytes32 br, bytes32 bs, IERC721 contractAddress) public returns (uint256) {
        require(weth.allowance(values._bidder, address(this)) >= values._amount, "Allowance not given");
        require(weth.balanceOf(values._bidder) >= values._amount, "not enought balaance");

        IERC721 Nft = IERC721(contractAddress);
        
        require(Nft.ownerOf(values.tokenId) == values._seller, "seller is not the owner");
        require(Nft.isApprovedForAll(values._seller, address(this)), "Allowance is not provided");

        require(deadline >= block.timestamp, "deadline passed");

        require(values._seller == ecrecover(getSignedHash(keccak256(abi.encodePacked(address(this), values._seller , deadline , values._amount))), sv, sr, ss), "Seller signature is Invalid");
        
        require(values._bidder == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._bidder , deadline , values._amount))), bv, br, bs), "Buyer signature is Invalid");

        processTokenPayments(values._bidder, values._seller, values._amount);

        Nft.safeTransferFrom(values._seller, values._bidder, values.tokenId);
        emit Acceptbidandtransfer(values._seller, values._bidder, values._amount ,values.tokenId , deadline, contractAddress);

        return values.tokenId;
    }


    function BuyAndTransfer(tuple memory values, uint8 sv, bytes32 sr, bytes32 ss,  uint8 bv, bytes32 br, bytes32 bs, IERC721 contractAddress) public payable returns (uint256) {
        require(msg.value == values._amount, "Value sent is not Correct");

        IERC721 Nft = IERC721(contractAddress);
        
        require(Nft.ownerOf(values.tokenId) == values._seller, "seller is not the owner");
        require(Nft.isApprovedForAll(values._seller, address(this)), "Allowance is not provided");
        

        require(values._seller == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._seller , values._amount))), sv, sr, ss), "Seller signature is Invalid");

        require(values._bidder == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, values._bidder , values._amount))), bv, br, bs), "Buyer signature is Invalid");

        processEthPayments(values._seller, values._amount);

        Nft.safeTransferFrom(values._seller, values._bidder, values.tokenId);
        emit Buyandtransfer(values._seller, values._bidder, values._amount ,values.tokenId, contractAddress);

        return values.tokenId;
    }

    function processTokenPayments(address _seller, address _bidder, uint256 amount) internal{
        uint256 _fee = platformFee.mul(amount).div(100);
        weth.transferFrom(_bidder, feeWallet, _fee);
        weth.transferFrom(_bidder, _seller, amount.sub(_fee));
    }

    function processEthPayments(address _seller, uint256 amount) internal{
        uint256 _fee = platformFee.mul(amount).div(100);
        payable(feeWallet).transfer(_fee);
        payable(_seller).transfer(amount.sub(_fee));
    }

    function signVerification (address seller, address buyer, uint256 deadline, uint256 amount, uint8 sv, bytes32 sr, bytes32 ss,  uint8 bv, bytes32 br, bytes32 bs) public view returns (bool){
        require(seller == ecrecover(getSignedHash(keccak256(abi.encodePacked(this, seller , deadline , amount))), sv, sr, ss), "Seller signature is Invalid");
        require( buyer == ecrecover(getSignedHash(keccak256(abi.encodePacked(this,  buyer , deadline , amount))), bv, br, bs), "Buyer signature is Invalid");
        return true;
    }

    function getSignedHash(bytes32 _messageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
        emit Withdrawstoredinaccount(recipient, amount);
    }

    function withdrawStoredInAccount() public {
        require(msg.sender == owner() || msg.sender == ownerWalletAddress, "Can only be called by the contract owner or the project owner");
        sendValue(payable(ownerWalletAddress), address(this).balance); //transfers funds to ownerWallet
    }

    function setToken (IERC20 addres) public onlyOwner{
        weth = addres;
    }


    function setfeewallet(address addres) public onlyOwner{
        feeWallet = addres;
    }

}