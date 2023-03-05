/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/utils/escrow/Escrow.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;



/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// File: @openzeppelin/contracts/utils/escrow/ConditionalEscrow.sol


// OpenZeppelin Contracts v4.4.1 (utils/escrow/ConditionalEscrow.sol)

pragma solidity ^0.8.0;


/**
 * @title ConditionalEscrow
 * @dev Base abstract escrow to only allow withdrawal if a condition is met.
 * @dev Intended usage: See {Escrow}. Same usage guidelines apply here.
 */
abstract contract ConditionalEscrow is Escrow {
    /**
     * @dev Returns whether an address is allowed to withdraw their funds. To be
     * implemented by derived contracts.
     * @param payee The destination address of the funds.
     */
    function withdrawalAllowed(address payee) public view virtual returns (bool);

    function withdraw(address payable payee) public virtual override {
        require(withdrawalAllowed(payee), "ConditionalEscrow: payee is not allowed to withdraw");
        super.withdraw(payee);
    }
}

// File: nilli-prod/RefundEscrowNilli.sol


// We will be using Solidity version 0.8.14
// OpenZeppelin Contracts v4.4.1 (utils/escrow/RefundEscrow.sol)
pragma solidity 0.8.18;




/**
 * @title RefundEscrowNilli
 * @dev Escrow that holds funds for a beneficiary, deposited from multiple
 * parties.
 * @dev Intended usage: See {Escrow}. Same usage guidelines apply here.
 * @dev The owner account (that is, the contract that instantiates this
 * contract) may deposit, close the deposit period, and allow for either
 * withdrawal by the beneficiary, or refunds to the depositors. All interactions
 * with `RefundEscrow` will be made through the owner contract.
 * @dev This contract is slightly modified from OZ to also include depositing, refunding,
 * and withdrawing ERC-20 tokens
 */

contract RefundEscrowNilli is ConditionalEscrow {
    using Address for address payable;

    enum State {
        Locked,
        Unlocked,
        Refunded,
        Delivered
    }

    struct crowdContract {
        string recDisplayName;
        string title;
        string creator;
        string condition1;
        string condition2;
        string condition3;
        bool[3] conditionFlags;
        bool isVerified;
        uint targetAmount;
        uint expirationDate;
        uint qtySigners;
        State curState;
    }

    event StateChange(State _oldState, State _newState);

    crowdContract public _crowdContract;
    
    /**
     * @dev escrowBalance Records the ERC-20 deposits to the contract.
     * Depositor address => ERC-20 address => Depositor amount.
     * Depositor address => ERC-721 token address => ERC-721 tokenID => bool (if in contract).
     */
    mapping(address => mapping(address => uint256)) public escrowBalance;
    mapping(address => mapping(address => mapping(uint256 => bool))) public escrowBalanceNFT;

    /**
     * @dev Constructor.
     */
    constructor(
        string memory recDisplayName,
        string memory title,
        string memory creator,
        string memory condition1,
        string memory condition2,
        string memory condition3,
        uint targetAmount,
        uint expirationDate) 
    {
        _crowdContract = crowdContract({
            recDisplayName : recDisplayName,
            title : title,
            creator : creator,
            condition1 : condition1,
            condition2 : condition2,
            condition3 : condition3,
            conditionFlags : [false, false, false],
            isVerified : false,
            targetAmount : targetAmount,
            expirationDate : expirationDate,
            qtySigners : 0,
            curState : State.Locked
        });
    }

     /**
     * @return The current state of the escrow.
     */
    function state() public view virtual returns (State) {
        State _state = _crowdContract.curState;
        return _state;
    }

    /**
     * @return The beneficiary of the escrow.
     */
    function beneficiary() public view virtual returns (address) {
        return owner();
    }

    /**
     * @return The conditional flags of the escrow.
     */
    function conditionFlags() public view returns (bool[3] memory) {
        return _crowdContract.conditionFlags;
    }

    /**
     * @dev verifies the crowdContract
     */    
    function verify() public onlyOwner {
        require(_crowdContract.isVerified == false, "RefundEscrow: contract is already verified");
        _crowdContract.isVerified = true;
        // TODO: do we need an event here?
    }

    /**
     * @dev adjusts the conditional flags
     */    
    function updateConditionFlags(bool[3] memory updatedFlags) public onlyOwner {
        _crowdContract.conditionFlags = updatedFlags;
        // TODO: do we need an event here?
    }

    /**
     * @dev Stores funds that may later be refunded.
     * @param refundee The address funds will be sent to if a refund occurs.
     */
    function deposit(address refundee) public payable virtual override {
        require(_crowdContract.curState == State.Locked, "RefundEscrow: can only deposit while active");
        super.deposit(refundee);
    }

    /**
     * @dev Allows for the beneficiary to withdraw their funds, rejecting
     * further deposits.
     */
    function stateChangeContract(State newState) public virtual onlyOwner {
        // require(_crowdContract.curState == State.Locked, "RefundEscrow: can only close while active");
        State oldState = _crowdContract.curState;
        _crowdContract.curState = newState;
        emit StateChange(oldState, _crowdContract.curState);
        //TODO: change owner to a beneficiary address
    }

    /**
     * @dev Withdraws the beneficiary's funds.
     */
     // TODO: change this to refund ETH to donator (I believe) - the `withdraw` fx should withdraw ETH to owner
    function withdrawETHOwner(address payable _owner) public virtual onlyOwner {
        require(_crowdContract.curState == State.Unlocked, "RefundEscrow: beneficiary can only withdraw while closed");
        _owner.sendValue(address(this).balance);
    }

    /**
     * @dev Returns whether refundees can withdraw their deposits (be refunded). The overridden function receives a
     * 'payee' argument, but we ignore it here since the condition is global, not per-payee.
     */
    function withdrawalAllowed(address) public view override returns (bool) {
        return _crowdContract.curState == State.Refunded;
    }

    // Customized addition of escrowing ERC-20 and ERC-721 tokens!*********************************************************
    /**
     * @dev Depositor can deposit ERC-20 token.
     * @param token The specific ERC-20 token to deposit to this contract.
     */
    function depositToken(IERC20 token, address depositor, uint256 amount) public onlyOwner {
        require(_crowdContract.curState == State.Locked, "RefundEscrow: can only deposit token while active");
        require(token.transferFrom(depositor, address(this), amount));
        escrowBalance[depositor][address(token)] += amount;
    }

    /**
     * @dev Depositors can withdraw their deposited ERC-20 tokens.
     * @param token The specific ERC-20 token to withdraw to depositor.
     */
    function withdrawToken(IERC20 token, address withdrawer) public onlyOwner {
        require(_crowdContract.curState == State.Refunded, "RefundEscrow: can only refund token when the state is refunding");
        uint256 amount = escrowBalance[withdrawer][address(token)];
        escrowBalance[withdrawer][address(token)] = 0;
        require(token.transfer(withdrawer, amount));
    }

    /**
     * @dev Beneficiary can withdraw a specific ERC-20.
     * @param token The specific ERC-20 token to withdraw to beneficiary.
     */
    function tokenWithdrawOwner(IERC20 token) public onlyOwner {
        require(_crowdContract.curState == State.Unlocked, "RefundEscrow: beneficiary can only withdraw token what closed");
        uint256 amount = token.balanceOf(address(this));
        require(token.transfer(owner(), amount));
    }

    /**
     * @dev Depositor can dump in some ERC-721 tokens here.
     * @param token The specific ERC-721 contract being deposited.
     * @param from The depositor address.
     * @param tokenId The NFT tokenID specific to this NFT collection.
     */
    function nftDepositContract(IERC721 token, address from, uint256 tokenId) public onlyOwner {
        require(_crowdContract.curState == State.Locked, "RefundEscrow: can only deposit NFT while active");
        escrowBalanceNFT[from][address(token)][tokenId] = true;
        token.safeTransferFrom(from, address(this), tokenId);
    }

    /**
     * @dev Depositor can dump in some ERC-721 tokens here.
     * @param token The specific ERC-721 contract being deposited.
     * @param tokenId The NFT tokenID specific to this NFT collection.
     */
    function nftWithdrawOwner(IERC721 token, uint256 tokenId) public onlyOwner {
        require(_crowdContract.curState == State.Unlocked, "RefundEscrow: beneficiary can only withdraw NFT when closed");
        require(token.ownerOf(tokenId) == address(this), "RefundEscrow: this NFT isn't currently owned by this contract");
        // TODO: doesn't currently remove/deduct from ERC721 mapping of recorded NFTs
        token.safeTransferFrom(address(this), owner(), tokenId);
    }

    /**
     * @dev Depositor can dump in some ERC-721 tokens here.
     * @param token The specific ERC-721 contract being deposited.
     * @param depositor The depositor address.
     * @param tokenId The NFT tokenID specific to this NFT collection.
     */
    function nftRefundContract(IERC721 token, address depositor, uint256 tokenId) public onlyOwner {
        require(_crowdContract.curState == State.Refunded, "RefundEscrow: depositors can only withdraw NFT refunds when the state is refunding");
        require(escrowBalanceNFT[depositor][address(token)][tokenId] == true, "RefundEscrow: this wasn't the original NFT owner");
        require(token.ownerOf(tokenId) == address(this), "RefundEscrow: this NFT isn't currently owned by this contract");
        escrowBalanceNFT[depositor][address(token)][tokenId] = false;
        token.safeTransferFrom(address(this), depositor, tokenId);
    }
    // End of customized addition of escrowing ERC-20 and ERC-721 tokens!*********************************************************

}
// File: nilli-prod/ParentEscrow.sol


// We will be using Solidity version 0.8.10
// OpenZeppelin Contracts v4.4.1 (utils/escrow/RefundEscrow.sol) -> customized RefundEscrowNilli.sol
pragma solidity 0.8.18;




/**
 * @title nilliv2
 * @dev This is an owner contract for a customized OZ 'RefundEscrow' contract
 * @dev Intended usage: See {Escrow}. Same usage guidelines apply here.
 * @dev This owner account (that is, the contract that instantiates RefundEscrow
 * contract) may deposit, close the deposit period, and allow for either
 * withdrawal by the beneficiary, or refunds to the depositors. All interactions
 * with `RefundEscrow` will be made through this owner contract. The customizations
 * allow for depositing/extraction of both ERC-20 and ERC-721 assets on top
 * of the native ETH deposits/extractions by the original OZ RefundEscrow contract
 */

contract ParentEscrow is Ownable {

    enum State {
        Locked,
        Unlocked,
        Refunded,
        Delivered
    }

    // Event that will be emitted whenever a new endowment is started
    event NilliContract(
        address contractAddress,
        string recDisplayName,
        string title,
        string creator,
        string condition1,
        string condition2,
        string condition3,
        bool[3] conditionFlags, //3 conditions and jury decision is 4th
        uint targetAmount,
        uint expirationDate,
        uint qtySigners,
        State curState
    );

    // Event that will be emitted whenever a deposit is initiated
    event ContractDeposit(
        address endowAddress,
        address depositorAddress,
        address depTokAddr,
        uint amtDeposited,
        string depType
    );

     // Event that will be emitted whenever a withdraw is initiated
    event ContractWithdraw(
        address endowAddress,
        address withdrawerAddress,
        address withdrawTokAddr,
        string withdrawType
    );

    // Event that will be emitted whenever an endowment state changes
    event ContractStateChange(
        address endowAddress,
        RefundEscrowNilli.State newState
    );

    /**
     * @dev Initiates a new endowment. This contract will act as owner
     * to the modified RefundEscrow contract it calls.
     */
    function startContract(
        string memory recDisplayName,
        string memory title,
        string memory creator,
        string memory condition1,
        string memory condition2,
        string memory condition3,
        uint targetAmount,
        uint expirationDate
    ) public {
        RefundEscrowNilli newContract = new RefundEscrowNilli(
            recDisplayName,
            title,
            creator,
            condition1,
            condition2,
            condition3,
            targetAmount, 
            expirationDate);
        emit NilliContract(
            address(newContract),
            recDisplayName,
            title,
            creator,
            condition1,
            condition2,
            condition3,
            [false,false,false],
            targetAmount,
            expirationDate,
            0,
            State.Locked
        );
    }

    /**
     * @dev Deposits ETH to the specific endowment contract.
     */
    function depositToContract(RefundEscrowNilli contractAddress) public payable returns (uint amt) {
        contractAddress.deposit{value: msg.value}(msg.sender);
        emit ContractDeposit(
            address(contractAddress),
            msg.sender,
            address(0),
            msg.value,
            "ETH"
        );
        return(msg.value);
    }
    
    /**
     * @dev Closes endowment so that deposits can no longer be issued. Once closed, the
     * beneficiary is free/allowed to withdraw their assets (via this contract).
     */
    function stateChangeContract(RefundEscrowNilli contractAddress, RefundEscrowNilli.State newState) public onlyOwner {
        contractAddress.stateChangeContract(newState);
        emit ContractStateChange(address(contractAddress), newState);
    }

    function verifyChild(RefundEscrowNilli contractAddress) public onlyOwner {
        contractAddress.verify();
        //TODO: do we need an event to fire?
    }

    function updateConditionFlags(RefundEscrowNilli contractAddress, bool[3] memory condFlags) public onlyOwner {
        contractAddress.updateConditionFlags(condFlags);
        //TODO: do we need an event to fire here?
    }

    /**
     * @dev Deposits a specific token (ERC-20) to the endowment
     */
    function depTokentoContract(RefundEscrowNilli contractAddress, IERC20 token, uint amount) public returns (uint amt) {
        contractAddress.depositToken(token, msg.sender, amount);
        emit ContractDeposit(
            address(contractAddress),
            msg.sender,
            address(token),
            amount,
            "Token"
        );
        return(amount);
    }

    /**
     * @dev if RefundsEnabled, the depositor can withdraw their submitted ERC-20 balance
     */
    function withdrawTokenContract(RefundEscrowNilli contractAddress, IERC20 token) public {
        contractAddress.withdrawToken(token, msg.sender);
        emit ContractWithdraw(
            address(contractAddress),
            msg.sender,
            address(token),
            "Token"
        );
    }

    /**
     * @dev Deposits a specific NFT (ERC-721) to the endowment
     */
    function depNFTtoContract(RefundEscrowNilli contractAddress, IERC721 token, uint tokenId) public {
        contractAddress.nftDepositContract(token, msg.sender, tokenId);
        emit ContractDeposit(
            address(contractAddress),
            msg.sender,
            address(token),
            1,
            "NFT"
        );
    }

    /**
     * @dev if RefundsEnabled, the depositor can withdraw their submitted ERC-721 NFTs
     */
    function withdrawNFTContract(RefundEscrowNilli contractAddress, IERC721 token, uint tokenId) public {
        contractAddress.nftRefundContract(token, msg.sender, tokenId);
        emit ContractWithdraw(
            address(contractAddress),
            msg.sender,
            address(token),
            "NFT"
        );
    }

    /**
     * @dev if endowment Closed, the beneficiary can withdraw ERC-20 tokens from endowment.
     */
    function withdrawTokenOwner(RefundEscrowNilli contractAddress, IERC20 token) public onlyOwner {
        contractAddress.tokenWithdrawOwner(token);
        emit ContractWithdraw(
            address(contractAddress),
            msg.sender,
            address(token),
            "Token"
        );
    }

    /**
     * @dev if endowment Closed, the beneficiary can withdraw ERC-721 NFTs from endowment.
     */
    function withdrawNFTOwner(RefundEscrowNilli contractAddress, IERC721 token, uint tokenId) public onlyOwner {
        contractAddress.nftWithdrawOwner(token, tokenId);
        emit ContractWithdraw(
            address(contractAddress),
            msg.sender,
            address(token),
            "NFT"
        );
    }

     /**
     * @dev if endowment Refunded, the depositor can withdraw ETH from endowment.
     */
    function withdrawETHDepositor(RefundEscrowNilli contractAddress) public {
        contractAddress.withdraw(payable(msg.sender));
        emit ContractWithdraw(
            address(contractAddress),
            msg.sender,
            address(0),
            "ETH"
        );
    }

    // typical renounce ownership - will likely totally shutdown contract as only owners can interact.
    function renounceContractOwnership(RefundEscrowNilli contractAddress) public onlyOwner {
        contractAddress.renounceOwnership();
    }

    // typical transfer of ownership
    function xferContractOwnership(RefundEscrowNilli contractAddress, address newOwner) public onlyOwner {
        contractAddress.transferOwnership(newOwner);
        stateChangeContract(contractAddress, RefundEscrowNilli.State.Delivered);
    }
   
}