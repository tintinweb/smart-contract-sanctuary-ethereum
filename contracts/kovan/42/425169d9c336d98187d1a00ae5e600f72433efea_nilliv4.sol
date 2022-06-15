/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: nilliv4.sol


// We will be using Solidity version 0.8.14
pragma solidity 0.8.14;




contract nilliv4 is Ownable {

    // List of existing endowments
    Endowment[] private endowments;

    // Event that will be emitted whenever a new project is started
    event EndowmentStarted(
        address contractAddress,
        address endowmentStarter,
        string endowmentAthlete,
        string endowmentGenCond,
        string endowmentCondition
    );

    /** @dev Function to start a new endowment.
      * @param athlete Title of the project to be created
      * @param genericCond i.e. the school
      * @param specificCond variable condition to set!
      */
    function startEndowment(
        string calldata athlete,
        string calldata genericCond,
        string calldata specificCond
    ) external {
        Endowment newEndowment = new Endowment(payable(msg.sender), athlete, genericCond, specificCond, owner());
        endowments.push(newEndowment);
        address starter = msg.sender;
        emit EndowmentStarted(
            address(newEndowment),
            starter,
            athlete,
            genericCond,
            specificCond
        );
    }

    /** @dev Function to get all projects' contract addresses.
      * @return A list of all projects' contract addreses
      */
    function returnAllEndowments() external view returns(Endowment[] memory){
        return endowments;
    }

}

contract Endowment is Ownable {

    // Data structures
    enum State {
        Locked,
        Expired,
        Successful,
        Paused
    }

    // State variables
    address payable private endStarter;
    string private endAthlete;
    string private endGenericCond;
    string private endSpecCond;
    State private endState = State.Locked; // initialize on create
    address private endOwner;
    // mapping (address => uint) public contributions;
    uint private contribution = 0;

    // Event that will be emitted whenever state changes
    event StateChange(string athleteChange, string schoolChange, string conditionChange , State newState);
    // Event that will be emitted whenever transfer occurs
    event Transfer(address transferFrom, address transferTo, uint tokenz);
        // Event that will be emitted whenever transfer occurs
    event TransferETH(address transferFrom, address transferTo, uint amtETH);

    // Modifier to check if the function caller is the project creator
    modifier isStarter() {
        require(msg.sender == endStarter);
        _;
    }

    constructor
    (
        address payable endowmentStarter,
        string memory endowmentAthlete,
        string memory endowmentGenCond,
        string memory endowmentSpecCond,
        address parentOwner
    ) {
        endStarter = endowmentStarter;
        endAthlete = endowmentAthlete;
        endGenericCond = endowmentGenCond;
        endSpecCond = endowmentSpecCond;
        endState = State.Locked;
        endOwner = parentOwner;
        transferOwnership(endOwner);
    }

    /** @dev Function expireEndowment force endowment to expire.
      */
    function expireEndowment() public onlyOwner returns (bool) {
        require(endState == State.Locked);
        endState = State.Expired;
        emit StateChange(endAthlete, endGenericCond, endSpecCond, endState);
        return true;
    }

    /** @dev Function successfulEndowment force endowment to success.
      */
    function successfulEndowment() public onlyOwner returns (bool) {
        require(endState == State.Locked);
        endState = State.Successful;
        emit StateChange(endAthlete, endGenericCond, endSpecCond, endState);
        return true;
    }

    /** @dev Function pauseEndowment force endowment to pause.
      */
    function pauseEndowment() public onlyOwner returns (bool) {
        endState = State.Paused;
        emit StateChange(endAthlete, endGenericCond, endSpecCond, endState);
        return true;
    }

     /** @dev Function to fund a certain project.
    */
    function contributeETH() external payable returns (bool) {
        require(endState != State.Paused);
        require(endState == State.Locked);
        require(msg.sender == endStarter);
        uint256 contribAmt = msg.value;
        contribution += contribAmt;
        emit TransferETH(endStarter, address(this), contribAmt);
        return true;
    }

    function transferToken(address ERC20tokAddr, address receiver, uint numTokens) public onlyOwner returns (bool) {
        require(endState != State.Paused);
        IERC20 token = IERC20(ERC20tokAddr);
        uint currBalance = token.balanceOf(address(this));
        require(numTokens <= currBalance);
        bool successTrans = token.transfer(receiver, numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return successTrans;
    }

    function transferNFT(address ERC721NFTAddr, address receiver, uint tokenID) public onlyOwner {
        require(endState != State.Paused);
        IERC721 token = IERC721(ERC721NFTAddr);
        address owner = token.ownerOf(tokenID);
        require(owner == address(this));
        token.transferFrom(address(this), receiver, tokenID);
        emit Transfer(msg.sender, receiver, tokenID);
    }

    /** @dev Function allows payout to endowment athlete.
    */
    function payOutETH(address receiverAddr) public onlyOwner returns (bool) {
        require(endState == State.Successful || endState == State.Expired);
        require(endState != State.Paused);
        uint256 payoutAmt = address(this).balance;

        if (payable(receiverAddr).send(payoutAmt)) {
            emit TransferETH(address(this), receiverAddr, payoutAmt);
            return true;
        } else {
            return false;
        }
    }
       
    function getDetails() public view returns
    (
        address payable endowmentStarter,
        string memory endowmentAthlete,
        string memory endowmentGenCond,
        string memory endowmentSpecCond,
        State endowmentState,
        uint endowETHHoldings
    ) {
        endowmentStarter = endStarter;
        endowmentAthlete = endAthlete;
        endowmentGenCond = endGenericCond;
        endowmentSpecCond = endSpecCond;
        endowmentState = endState;
        endowETHHoldings = address(this).balance;
    }
}