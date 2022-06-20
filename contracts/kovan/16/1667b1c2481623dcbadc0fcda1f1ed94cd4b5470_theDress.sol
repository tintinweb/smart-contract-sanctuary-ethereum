/**
 *Submitted for verification at Etherscan.io on 2022-06-20
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

// File: github/sherzed/solidityProject-1/thedress.sol


pragma solidity ^0.8.7;

contract theDress is Ownable {
    mapping(address => uint256) public userGold;
    mapping(address => uint256) public userBlue;
    uint256 public constant PRICE = 1 ether / 100;
    uint256 public constant STEP = 5 minutes;
    uint256 public ownerShare;
    uint256 public winnerShare;
    uint256 public constant OWNER_PERCENTAGE = 40;
    uint256 private goldOrBlue = 2;
    uint256 private constant GOLD = 0;
    uint256 private constant BLUE = 1;
    uint256 public totalGold;
    uint256 public totalBlue;
    uint256 timeDifference;
    uint256 total_ownerPercentage;
    uint256 public immutable start_time;
    address _chairperson = 0x6a411Be2a84eaf31d9F6092CA08F364Fb9Fe1350;

    error InsufficientFunds();
    error InvalidWinnerID();
    error TransferTxError();

    constructor() {
        start_time = block.timestamp;
    }

     struct Voter {
        uint vote;
        bool votedBlue;
        bool votedGold;
    }
    mapping(address => Voter) private _voters;

    struct Owner {
        bool blueWon;
        bool goldWon;
    }
    mapping(address => Owner) private _owner;

    function calculatePrice() internal view returns (uint256) {
        uint256 timeDif = block.timestamp - start_time;
        return PRICE + (timeDif / STEP) * 0.00001 ether;
    }

    function blue(uint256 quantity) external payable {
        uint256 enterPrice = calculatePrice();
        uint256 fullPrice = quantity * enterPrice;
        if (msg.value < fullPrice) revert InsufficientFunds();
        Voter storage sender = _voters[msg.sender];
        totalBlue += quantity;
        userBlue[msg.sender] += quantity;
        sender.votedBlue=true;
        updateShares();
    }

    function updateShares() private {
        ownerShare += (msg.value * OWNER_PERCENTAGE) / 100;
        winnerShare += (msg.value * (100 - OWNER_PERCENTAGE)) / 100;
    }

    function gold(uint256 quantity) public payable {
        uint256 enterPrice = calculatePrice();
        uint256 fullPrice = quantity * enterPrice;
        if (msg.value < fullPrice) revert InsufficientFunds();
        userGold[msg.sender] += quantity;
        totalGold += quantity;
        Voter storage sender = _voters[msg.sender];
        sender.votedGold=true;
        updateShares();
    }

    function winner(uint256 whichColor) public {
        Owner storage chairperson = _owner[msg.sender];
        require(msg.sender==_chairperson,"U are not owner.");
        if(whichColor==1){
            chairperson.blueWon=false;
            chairperson.goldWon=true;
        }
        else{
            chairperson.blueWon=true;
            chairperson.goldWon=false;
        }
    }

    function ownerWithdraw() external onlyOwner {
        uint256 share = ownerShare;
        ownerShare = 0;
        (bool isSuccess, ) = payable(owner()).call{ value: share }("");
        if (!isSuccess) revert TransferTxError();
    }

    function winnerWithdraw() external {
        uint256 withdrawAmount;
        Owner storage chairperson = _owner[msg.sender];
        require(!chairperson.blueWon||!chairperson.goldWon,"Any dresses has not win!");
        Voter storage sender = _voters[msg.sender];
        require(!sender.votedGold||!sender.votedBlue,"You didn't vote for the winning dress!");
        if(chairperson.blueWon){
            withdrawAmount = (winnerShare * userBlue[msg.sender]) / totalGold;
            userBlue[msg.sender] = 0;
        }
        if(chairperson.goldWon){
            withdrawAmount = (winnerShare * userGold[msg.sender]) / totalGold;
            userGold[msg.sender] = 0;
        }
         (bool isSuccess, ) = payable(msg.sender).call{ value: withdrawAmount }(
            ""
        );
        if (!isSuccess) revert TransferTxError();
    }
}