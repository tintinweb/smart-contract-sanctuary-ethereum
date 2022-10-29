/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: Metacademy.sol

contract Metacademy is Ownable{
    address[] public students; // Students Wallet Addresses
    uint256[] private studentsID; // Students ID's 
    mapping(uint256 => address) public idToWalletAddress; // Map students ID to wallet address
    mapping(string => string) public nameToLastName;
    mapping(uint256 => uint256) public idToStudentBalance; // Students payment balance
    mapping(uint256 => bytes1) public studentToActive; // Students active mapping
    uint256 usdEntranceFees;
    IERC20 public metcademyCoin;
    AggregatorV3Interface internal ethUsdPriceFeed;
    
    
    constructor(uint256 _usdEntranceFees, address _metacademyCoin, address _ethPriceFeedAddress) { 
        ethUsdPriceFeed = AggregatorV3Interface(_ethPriceFeedAddress); // Get price feed instance
        metcademyCoin = IERC20(_metacademyCoin); // Initiate MetaCademy Coin contract
        usdEntranceFees = _usdEntranceFees; // Initiate registration fees based on creation contract decided value
    }

    function getEntranceFees() public view returns(uint256){
        (,int256 price,,,) = ethUsdPriceFeed.latestRoundData(); // Get latest eth/usd rate
        uint256 adjustedPrice = uint256(price) * (10**10); // latestRoundData returns 8 decimals
        uint256 costToEnter = (usdEntranceFees * 10**18) / adjustedPrice; // Math to get our entrance fees in eth (converted)
        return costToEnter;
    }

    function newStudent(uint256 studentID) public payable{
        uint256 registrationFees = getEntranceFees();
        require(msg.value >= registrationFees, "You need to pay registration fees");
        students.push(msg.sender);
        setWalletAddress(studentID, msg.sender);
        addToStudentBalance(studentID, msg.value);
    }

    function addToStudentBalance(uint256 studentID, uint256 value) onlyOwner private{
        idToStudentBalance[studentID] += value;
    }

    function setWalletAddress(uint256 studentID, address studentWalletAddress) onlyOwner private{
        idToWalletAddress[studentID] = studentWalletAddress;
    }

    function getStudentWalletAddress(uint256 studentID) public returns(address){
        return idToWalletAddress[studentID];
    } 
    
    function getPaymentsBalance(uint256 studentID) public returns (uint256){
        address studentWalletAddress = msg.sender;
        require(studentWalletAddress == idToWalletAddress[studentID], "Unrecognize wallet address for this student!, please log in with your registered wallet address.");
        return idToStudentBalance[studentID];
    }

    function payToStudentBalance(uint256 studentID) payable public {
        require(msg.value > 0, "Payment needs to be greater than 0");
        idToStudentBalance[studentID] -= msg.value;
    }

    
}