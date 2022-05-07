/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

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

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function TA() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(TA() == _msgSender(), "Ownable: caller is not the owner");
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

contract Cluster is Context{

    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private allowedMember;
    mapping(address =>  mapping(address => string)) private messageToOther;
    mapping(address =>  string) private ping;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => mapping(address => bool)) private reportedVehicles;
    mapping(address => uint256) totalReports;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address private _head;
    address private _admin;

    struct requestLoc {
    address applicant;
    uint256 lat;
    uint256 long;
    string request;
    string response;
    uint256 randNum;
    }

    mapping(address => requestLoc) public requestService;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Ping(address indexed sender, string ping);

    constructor(string memory name_, string memory symbol_, address head_) {
        _name = name_;
        _symbol = symbol_;
        allowedMember[_msgSender()] = true;
        _transferOwnership(head_);
    }

    function name() public view  returns (string memory) {
        return _name;
    }
    
    function setName(string memory name_) public onlyOwner  returns (bool) {
        _name = name_;
        return true;
    }


    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    function setSymbol(string memory symbol_) public onlyOwner  returns (bool) {
        _symbol = symbol_;
        
        return true;
    }


    function addMember(address newMember) public onlyOwner returns (bool) {
        allowedMember[newMember] = true;
        _totalSupply = _totalSupply.add(1);
        return true;
    }

    //revoke or block a member onlly by head
    function revokeMembership(address newMember) public onlyOwner returns (bool) {
        require( _totalSupply.div(2) >= 50, "need 50% reports");
        allowedMember[newMember] = false;
        return true;
    }
    
    // to report a vehicle
    function reportVehicle(address _addressToReport) public returns (bool) {
        require(allowedMember[_msgSender()] == true, "Must be a member to report");
         reportedVehicles[_addressToReport][msg.sender] = true;
         totalReports[_addressToReport].add(1);
        return true;
    }

    // to check number of reprts on a single vehicle
    function numberOfReports(address _address) public view returns (uint256) {
        return totalReports[_address];
    }

    function requestLocation(uint256 _lat, uint256 _long, string memory _request) public returns (uint256) {
        require(allowedMember[_msgSender()] == true, "Must be a member to get any service");
        //generate a random number between 0 - 5
        uint256 random2 = uint(keccak256(abi.encodePacked(_lat, msg.sender, _long))) % 5;


        requestLoc memory reqStr = requestLoc({
        applicant : msg.sender,

        //add random number to latitude
        lat : _lat.add(random2),

         //add random number to logitude
        long : _long.add(random2),
        request : _request,
        response : "",
        randNum : random2
        });

        requestService[msg.sender] = reqStr;
        return random2;
    }

    function sendPing(string memory info) public returns (bool) {
          require(allowedMember[_msgSender()] == true, "You Are not Allowed to send signals");
          ping[_msgSender()] = info;
          return true;
    }

    function readPing(address _sender) public view returns (string memory _message) {
          require(allowedMember[_msgSender()] == true, "You Are not Allowed to read signals");
          return ping[_sender];
    }

    function sendMessage(string memory info, address reciever) public returns (bool) {
          require(allowedMember[_msgSender()] == true, "You Are not Allowed to send the Message");
          messageToOther[reciever][_msgSender()] = info;
          return true;
    }

    function readMessages(address sender) public view returns (string memory) {
          require(allowedMember[_msgSender()] == true, "You Are not Allowed to read the Message");
          return messageToOther[_msgSender()][sender];
    }
    
    function head() public view virtual returns (address) {
        return _head;
    }

    modifier onlyOwner() {
        require(head() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyTrafficAuthority() {
        require(_admin == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyTrafficAuthority {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyTrafficAuthority {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _head;
        _head = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract FactoryCluster is Ownable {
    mapping(uint256 => address) private contractAddress;
    mapping(address =>  address) private contractAddressToHead;
    uint256 public contractIndex = 0;
    mapping(address => mapping(address => string)) private headsPing;
  
    event newCollection(address indexed contractAddress);

    function sendPing(string memory info, address reciever, address addressofcontracttohead) public returns (bool) {
        require(_msgSender() == contractAddressToHead[addressofcontracttohead], "not a head of any cluster");
          headsPing[_msgSender()][reciever] = info;
          return true;
    }

    function readPing(address _sender, address addressofcontracttohead) public view returns (string memory _message) {
         require(_msgSender() == contractAddressToHead[addressofcontracttohead], "not a head of any cluster");
          return headsPing[_sender][_msgSender()];
    }

    function checkCusterAddressOnIndex(uint _index) public view returns (address){
        return contractAddress[_index];
    }

    function deployNewCollection(string memory name, string memory symbol, address head) public onlyOwner returns (address){
       
        Cluster toDeploy = new Cluster(name, symbol, head);
        contractAddress[contractIndex] = address(toDeploy);
        contractAddressToHead[address(toDeploy)] = head;
        contractIndex++;
        emit newCollection(address(toDeploy));

        return address(toDeploy);

    }
}