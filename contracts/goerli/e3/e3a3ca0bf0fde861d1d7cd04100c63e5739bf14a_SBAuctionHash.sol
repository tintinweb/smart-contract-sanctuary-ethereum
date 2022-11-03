/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

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

// File: contracts/SBAuctionHash.sol




pragma solidity ^0.8.0;

contract SBAuctionHash is Ownable {

    enum AuctionStates{Setup, BiddersPhase, RevealBid, PayBack, ClosedAuction}
    AuctionStates public states;

    struct Bidder {
        bytes32 hashedBid;
        bytes32 blindingFactor;
        bytes32 revealedBid;
        bool validBid;
        bool paidBack;
    }

// bidders = {{address: Bidder}, {address2: Bidder}}
    mapping (address => Bidder) public bidders;
    address[] public listOfBidders;

    address public auctioneerAddress;
    uint256 public bidFee;
    bytes32 public testHash;
    bytes32 public testHashWithout;
    string public auctionName;

    constructor(string memory _name, uint256 _bidFee)  {
        auctionName = _name;
        states = AuctionStates.Setup;
        bidFee = _bidFee; // ETH Kommastellen/Format beachten
    }

    function StartAuction()public onlyOwner{
        states = AuctionStates.BiddersPhase;
        // auctioneerAddress = msg.sender;
    }

    function commitBid(bytes32 hashedBid) public payable {
        // only one bid is allowed
        // require(bidders[msg.sender] == );
        // check validity of input hashedBid
        // require(hashedBid.length == 64);
        // check if enough ether was sent
        // require(msg.value >= bidFee);
        require(states == AuctionStates.BiddersPhase);
        if (bidders[msg.sender].hashedBid.length == 0){
            require(msg.value >= bidFee);
            listOfBidders.push(msg.sender);
        }
        bidders[msg.sender] = Bidder(hashedBid,'','',false,false);
    }

    function revealBid(bytes32  _blindingFactor, bytes32  _revealBid) public {
        // check if input data is correct - correct hex code
        // only msg.sender is allowed to change - think of it
        // 
        require(states == AuctionStates.RevealBid);
        // require(bidders[msg.sender].hashedBid !=0);
        bidders[msg.sender].blindingFactor = _blindingFactor;
        bidders[msg.sender].revealedBid = _revealBid;
    }

    // should be called automatically in the future
    function checkBidValidity() public {
        // only for testing
        testHashWithout = keccak256(abi.encode(bidders[msg.sender].revealedBid));
        // only for testing
        testHash = keccak256(abi.encode(bidders[msg.sender].revealedBid, bidders[msg.sender].blindingFactor));
        // this is the magic
        // 
        if(keccak256(abi.encode(bidders[msg.sender].revealedBid, bidders[msg.sender].blindingFactor)) == bidders[msg.sender].hashedBid){
           bidders[msg.sender].validBid = true;   
        }
    }

    // D
    function checkAllBidsValidity() public {
        // use a for loop over listOfBidders to check bidders struct
        // case 1: all good
        // case 2: no reveal
        // case 3: ...

    }

    // B
    // only for development phase
    // will be replaced by time functions
    function changeAuctionState(uint _stateNumber) public onlyOwner{
        // switch states ToDo
        // states = AuctionStates[_stateNumber];
    }

    // The D
    function payBackBidders() public onlyOwner{
        // require(
        // if validBid => pay back the biddersfee
    }

    // The D
    function findHighestBid() public onlyOwner{
        // for i = 0;  listOfBidders[]:
    }
    
}