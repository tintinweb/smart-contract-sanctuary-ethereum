/**
 *Submitted for verification at Etherscan.io on 2022-12-09
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

// File: Staking.sol



pragma solidity ^0.8.14;


interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) view external returns (uint256);
    function decimals() view external returns (uint256);

}

contract Staking is Ownable{

    bool pause;
    uint time;
    uint endTime;
    uint32 txId;
    uint8 constant idNetwork = 1;
    uint32 constant months = 2629743;

    constructor(){
        addPairV2("LP-CELL-ETH",0x9C4CC862F51B1Ba90485De3502AA058CA4331F32);
    }

    struct pairParams{
        address tokenAddr;
    }

    struct Participant{
        address sender;
        uint timeLock;
        string addrCN;
        address token;
        uint sum;
        uint timeUnlock;
        bool staked;
    }


    event staked(
        address sender,
        uint value,
        uint8 countMonths,
        string walletCN,
        address token,
        uint time,
        uint timeUnlock,
        uint32 txId,
        uint8 procentage,
        uint8 networkID,
        uint _block
    );

    event unlocked(
        address sender,
        uint sumUnlock,
        uint32 txID

    );

    Participant participant;

    mapping(address => uint) balanceLP;
    mapping(string => pairParams) tokens;
    mapping(address => mapping(uint32 => Participant)) timeTokenLock;
    mapping(uint32 => Participant) checkPart;


    function pauseLock(bool answer) external onlyOwner returns(bool){
        pause = answer;
        return pause;
    }


    function addPairV2(string memory tokenName, address tokenAddr) public onlyOwner{
        tokens[tokenName] = pairParams({tokenAddr:tokenAddr});
    }

    function getPair(string memory pair) view public returns (address){
        return tokens[pair].tokenAddr;
    }


    //@dev calculate months in unixtime
    function timeStaking(uint _time,uint8 countMonths) internal pure returns (uint){
        require(countMonths >=3 , "Minimal month 3");
        require(countMonths <=24 , "Maximal month 24");
        return _time + (months * countMonths);
    }

    function seeAllStaking(address token) view public returns(uint){
        return IERC20(token).balanceOf(address(this));
    }


    function stake(uint _sum,uint8 count,string memory addrCN,uint8 procentage,string memory pairName) public  returns(uint32) {
        require(procentage <= 100,"Max count procent 100");
        require(!pause,"Staking paused");
        require(getPair(pairName) != address(0));

        uint _timeUnlock = timeStaking(block.timestamp,count);
        //creating a staking participant
        participant = Participant(msg.sender,block.timestamp,addrCN,getPair(pairName),_sum,_timeUnlock,true);

        //identifying a participant by three keys (address, transaction ID, token address)
        timeTokenLock[msg.sender][txId] = participant;
        checkPart[txId] = participant;


        IERC20(getPair(pairName)).transferFrom(msg.sender,address(this),_sum);
        
        emit staked(msg.sender,_sum,count,addrCN,getPair(pairName),block.timestamp,
            _timeUnlock,txId,procentage,idNetwork,block.number);

        txId ++;
        return txId -1;
    }

    function claimFund(uint32 _txID) external {
        require(
            block.timestamp >= timeTokenLock[msg.sender][_txID].timeUnlock,
           "The time has not yet come" 
           );
        require(timeTokenLock[msg.sender][_txID].staked,"The steak was taken");
        require(msg.sender == timeTokenLock[msg.sender][_txID].sender,"You are not a staker");
        require(timeTokenLock[msg.sender][_txID].timeLock != 0);

        IERC20(timeTokenLock[msg.sender][_txID].token).transfer(msg.sender,
                                                                timeTokenLock[msg.sender][_txID].sum
                                                                );
    
        timeTokenLock[msg.sender][_txID].staked = false;
        checkPart[_txID].staked = false;
        emit unlocked(msg.sender,timeTokenLock[msg.sender][_txID].sum,_txID);

    }


    function seeStaked (uint32 txID) view public returns
                                                        (uint timeLock,
                                                        string memory addrCN,
                                                        uint sum,
                                                        uint timeUnlock,
                                                        bool _staked){
        return (checkPart[txID].timeLock,
                checkPart[txID].addrCN,
                checkPart[txID].sum,
                checkPart[txID].timeUnlock,
                checkPart[txID].staked);
    }


}