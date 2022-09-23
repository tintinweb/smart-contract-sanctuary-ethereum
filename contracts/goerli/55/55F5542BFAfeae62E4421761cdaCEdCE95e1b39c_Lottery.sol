/**
 *Submitted for verification at Etherscan.io on 2022-09-23
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

// File: contracts/aaa.sol



pragma solidity >=0.7.0 <0.9.0;


contract Lottery is Ownable{
    uint8 public duration;
    // 0或1
    enum Result {A, B}
    Result public lastResult;
    uint public minBetVal;
    // enum Result {WIN}
    // 0 未开始 1，正在进行 2.结算上一场
    enum  Status { NotStarted, Running, Pending}
    Status public status;
    mapping(uint => mapping(address => uint))public  bets;
    mapping(uint => mapping(Result => address[]) ) public  betAddrs;
    mapping(uint => mapping(Result => uint)) public  betVals;
    uint public startTime;
    uint public endTime;
    uint public times;
    string  nonce;
    error NotInRange();
    error LessMinBet();
    error NotStarted();
    event RunningStatus();
    event Share(uint);

    //@_duration: 每局的时长
    //@ _minBetVal: 最小投注额 
    constructor(uint8 _duration, uint _minBetVal) {
        duration = _duration;
        minBetVal = _minBetVal;
    }

    //设置随机数
    function setNonce( string calldata  _nonce) external onlyOwner {
        nonce = _nonce;
    }

    //开始
    function start() external onlyOwner{
 
        startTime = block.timestamp;
        endTime = startTime + duration;
        status = Status.Running;
        times += 1;
    }
    
    //投注
    function bet(Result result) external payable {
        if(status != Status.Running ||block.timestamp > endTime ){
          revert NotInRange();
        }

        if (msg.value < minBetVal){
          revert  LessMinBet();
        } 

        bets[times][msg.sender] = msg.value;
        betAddrs[times][result].push(msg.sender);
        betVals[times][result] += msg.value;
    }   

    // 获取开奖结果
    function _getRes() private view returns(Result ){
      return  Result(uint(keccak256(abi.encodePacked(block.timestamp,address(this).balance, nonce, msg.sender))) % 2);
    }

    function checkout() public {
        if(status != Status.Running || block.timestamp < endTime){
           revert NotInRange();
        }

        status = Status.Pending;
        lastResult = _getRes();
        uint winBetVal = betVals[times][lastResult];
        uint lostBetVal = betVals[times][Result(1- uint(lastResult))];
        // 输方总投注额的 95%的作为分红
        uint shares = lostBetVal * 95 / 100;
        for(uint i=0 ; i< betAddrs[times][lastResult].length ;i++){ 
            
            address addr = betAddrs[times][lastResult][i];
            //按投注比例分红
            uint share = bets[times][addr] * shares / winBetVal;
            emit Share(share);
            payable(addr).transfer(share + bets[times][addr]);
           
        }
        payable(owner()).transfer(address(this).balance);
    }
}