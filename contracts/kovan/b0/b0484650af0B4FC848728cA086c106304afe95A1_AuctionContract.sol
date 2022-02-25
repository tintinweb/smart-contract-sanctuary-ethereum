/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;

/**
 * @dev
 */
contract AuctionContract is Ownable {
    //----------------------- VARIABLES ---------------------------

    string url = "https://www.youtube.com/watch?v=t3f_hmWWQuY"; // Url of the artwork
    bool currentActionRound = false;

    address payable public immutable beneficiaryAddress;
    // The address of the user with the current max bid of the current round
    address maximalBidder;

    struct Funds {
        uint256 value;
        bool exists;
    }

    mapping(address => uint256) public fundsByBidder;
    mapping(address => bool) public hasIncreased;

    uint256 public soldTickets;
    uint256 reservePrice = 10;
    uint256 maximalBid = reservePrice;
    // The value underneath which the bid is not valid
    uint256 immutable incrementValue = 10;

    //----------------------- CONSTRUCTOR ---------------------------

    constructor(address _contractOwner, address payable _beneficiaryAddress) {
        beneficiaryAddress = _beneficiaryAddress;
        transferOwnership(_contractOwner);
        maximalBidder = _contractOwner;
    }

    //----------------------- GETTER ---------------------------

    /* @dev: we're using public visibility even though external consume less gas because we need getters for modifiers */
    function getFunds() external view returns (uint256 _fundsByBidder) {
        _fundsByBidder = fundsByBidder[_msgSender()];
    }

    function getBalance() external view returns (uint256 _balance) {
        _balance = address(this).balance;
    }

    function getMaximalBid() public view returns (uint256 _maximalBid) {
        _maximalBid = maximalBid;
    }

    function getMaximalBidder() public view returns (address _maximalBidder) {
        _maximalBidder = maximalBidder;
    }

    function getReservePrice() public view returns (uint256 _reservePrice) {
        _reservePrice = reservePrice;
    }

    function getHasIncreased(address a) public view returns (bool value) {
        value = hasIncreased[a];
    }

    function getFundsByBidder(address a) public view returns (uint256 value) {
        value = fundsByBidder[a];
    }

    function getUrl() public view returns (string memory _url) {
        _url = url;
    }

    //----------------------- METHODS ---------------------------

    function buy(uint256 nbTickets) external payable {
        require(msg.value == (nbTickets * 3e9));
        fundsByBidder[_msgSender()] += nbTickets;
        soldTickets += nbTickets;
    }

    function sell(uint256 nbTickets)
        external
        payable
        notBiddenCheck(nbTickets)
    {
        require(msg.value == nbTickets * (3e9));
        fundsByBidder[_msgSender()] -= nbTickets;
    }

    function giveForFree(address a) external ownerCheck {
        transferOwnership(a);
    }

    function increaseMinimalPrice() external ownerCheck onlyOnceCheck {
        hasIncreased[owner()] = true;
        reservePrice += 10;
    }

    function check() external view returns (bool, bool) {
        return (
            (soldTickets * (3e9) <= this.getBalance()),
            (soldTickets * (3e9) >= this.getBalance())
        );
    }

    function newBid(uint256 nbTickets)
        external
        reservePriceCheck(nbTickets)
        maximalBidCheck(nbTickets)
        onlyNotOwner
    {
        if (currentActionRound == false) currentActionRound = true;

        maximalBid = nbTickets;
        maximalBidder = _msgSender();
    }

    function closeAuction() external payable canCloseCheck {
        require(msg.value > 0, "No ether was sent.");
        require(
            msg.sender == beneficiaryAddress || msg.sender == owner(),
            "Only owner or beneficiary can fund contract."
        );

        // Closing the action round
        currentActionRound = false;

        // Tranfer the bid between old/new owner
        fundsByBidder[maximalBidder] -= maximalBid;
        fundsByBidder[owner()] += maximalBid;

        // Update ownership of contract and reservePrice
        transferOwnership(maximalBidder);
        hasIncreased[owner()] = false;
        reservePrice = maximalBid;
    }

    //----------------------- MODIFIER ---------------------------

    modifier canCloseCheck() {
        require(getMaximalBid() < getReservePrice());
        _;
    }

    modifier maximalBidCheck(uint256 nbTickets) {
        if (getMaximalBid() >= nbTickets) revert();
        _;
    }

    modifier reservePriceCheck(uint256 nbTickets) {
        if (getReservePrice() > nbTickets) revert();
        _;
    }

    modifier ownerCheck() {
        if (owner() != _msgSender()) revert();
        _;
    }

    modifier onlyOnceCheck() {
        if (getHasIncreased(owner()) == true) revert();
        _;
    }

    modifier notBiddenCheck(uint256 nbTickets) {
        if (
            getMaximalBidder() == _msgSender() &&
            nbTickets > (getFundsByBidder(_msgSender()) - getMaximalBid())
        ) revert();
        _;
    }

    modifier onlyNotOwner() {
        if (_msgSender() == owner()) revert();
        _;
    }
}