/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: lockDrop.sol


// File: lockDrop.sol
pragma solidity 0.8.1;




contract OwnerPausable is Ownable, Pausable {
    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        Pausable._pause();
    }
    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        Pausable._unpause();
    }

}
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MerchantLockDrop  is OwnerPausable {


    uint16 public  adminPoint =1 ;
    uint256 public constant TIMEUINT = 1 seconds;//  hardhat:seconds   eth:days  goerly: seconds
    uint256 public constant RELEASEUINT = 6 seconds ; //hardhat: ( 6 seconds  ); eth: (182 days) ; goerly:( 10 minutes)
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    mapping ( address => LockInfoList)   merchantLocksInfo;
    mapping ( address => string)   userToUri;
    mapping ( address => uint256)   adminTokenFee;

    struct Lock {
        uint amount;
        uint256 numOfTokens;
        uint256 releasedToken;
        uint256 lockEnding;
    }
    struct LockInfo{
        address inToken;
        address  outToken;
        address owner;
        uint256 ending;
        uint256 startTime;
        uint256    inTokenCapacity;
        uint256     inTokenAmount;
        uint256    outTokenCapacity;
        uint256    outTokenSupply;
        uint16 lockPeriod;
        string name;
        mapping(address =>  Lock) lockUser;
    }
    struct LockInfoList{
        LockInfo[] LIL;
        uint id;
    }

    event MerchantInitial(address indexed sender  ,uint index ,uint inTokenCapacity,uint outTokenCapacity, address inToken , address outToken, uint startTime , uint endTime ,uint16 lockPeriod,string proName);
    event Deposit(address indexed sender, address merchant ,uint index,uint initAmount, uint rewardAmount);
    event Unlock(address indexed sender, uint index);
    event WithdrawEvent(address indexed sender, uint rewardAmount,uint index,address merchant);
    event AdvanceLock(address indexed sender,uint index);
    event MerchantWithdraw(address indexed sender,uint index);
    event userUri(address indexed sender,string uri );

    constructor()  {
    }

    function userUriSet(string memory uri) external {
        userToUri[msg.sender] = uri;
        emit userUri(msg.sender,uri);
    }

    function merchantInitial(uint inTokenCapacity,uint outTokenCapacity, address inToken , address outToken, uint startTime , uint endTime ,uint16 lockPeriod ,string memory proName  )external  onlyOwner  {

        require( (startTime < endTime) && (startTime > block.timestamp),"time is  not regularly");
        require(inTokenCapacity>0,"tokenCapacity need >0");
        require((inToken != address(0) && (outToken != address(0))) ,"token address wrong");
        {
            LockInfoList storage lil =  merchantLocksInfo[msg.sender];
            LockInfo storage li = lil.LIL.push();
            li.startTime = startTime;
            li.ending = endTime;
            li.inToken = inToken;
            li.outToken = outToken;
            li.inTokenCapacity = inTokenCapacity;
            li.inTokenAmount = 0;
            li.outTokenCapacity = outTokenCapacity;
            li.outTokenSupply = outTokenCapacity;
            li.lockPeriod = lockPeriod;
            li.owner = msg.sender;
            li.name =proName;
            emit MerchantInitial(msg.sender, lil.LIL.length, inTokenCapacity, outTokenCapacity, inToken ,  outToken, startTime ,  endTime , lockPeriod ,proName );
        }
        {
        unchecked{
            bool success = IERC20(outToken).transferFrom(msg.sender, address(this), inTokenCapacity);
            require(success, "Call failed");
            uint amount = inTokenCapacity*adminPoint/10000;
            adminTokenFee[outToken] +=amount;
            bool outTokenSuccess = IERC20(outToken).transferFrom(msg.sender, address(this), amount);
            require(outTokenSuccess, "Call failed");
        }
        }
    }

    function changeAdminPoint(uint16 point) external onlyOwner{
        require(point >0 && point < 1000,"valid point");
        adminPoint = point;
    }

    function adminTokenFeeWithdraw(address token)external onlyOwner{
        require(adminTokenFee[token] >0,"token need bigger than 0");
        uint amount = adminTokenFee[token];
        adminTokenFee[token] = 0;
        bool outTokenSuccess = IERC20(token).transfer(msg.sender, amount);
        require(outTokenSuccess, "Call failed");
    }

    function merchantInitialTest(uint inTokenCapacity,uint outTokenCapacity, address inToken , address outToken, uint startTime , uint endTime ,uint16 lockPeriod,string memory proName   )external    {

        require( (startTime < endTime) && (startTime > block.timestamp),"time is  not regularly");
        require(inTokenCapacity>0,"tokenCapacity need >0");
        require((inToken != address(0) && (outToken != address(0))) ,"token address wrong");

        LockInfoList storage lil =  merchantLocksInfo[msg.sender];
        LockInfo storage li =  lil.LIL.push();

        li.startTime = block.timestamp;
        li.ending = block.timestamp + 5 seconds;
        li.inToken = inToken;
        li.outToken = outToken;
        li.inTokenCapacity = inTokenCapacity;
        li.inTokenAmount = 0;
        li.outTokenCapacity = outTokenCapacity;
        li.outTokenSupply = outTokenCapacity;
        li.lockPeriod = lockPeriod;
        li.owner = msg.sender;

        emit MerchantInitial(msg.sender, lil.LIL.length, inTokenCapacity, outTokenCapacity, inToken ,  outToken, startTime ,  endTime , lockPeriod ,proName );
        bool success = IERC20(outToken).transferFrom(msg.sender, address(this), outTokenCapacity);
        require(success, "Call failed");

    }

    function merchantInitialTest2(uint inTokenCapacity,uint outTokenCapacity, address inToken , address outToken, uint startTime , uint endTime ,uint16 lockPeriod ,string memory proName  )external    {
        require( (startTime < endTime) && (startTime > block.timestamp),"time is  not regularly");
        require(inTokenCapacity>0,"tokenCapacity need >0");
        require((inToken != address(0) && (outToken != address(0))) ,"token address wrong");

        LockInfoList storage lil =  merchantLocksInfo[msg.sender];
        LockInfo storage li =  lil.LIL.push();

        li.startTime = block.timestamp+5 seconds;
        li.ending = block.timestamp + 15 seconds;
        li.inToken = inToken;
        li.outToken = outToken;
        li.inTokenCapacity = inTokenCapacity;
        li.inTokenAmount = 0;
        li.outTokenCapacity = outTokenCapacity;
        li.outTokenSupply = outTokenCapacity;
        li.lockPeriod = lockPeriod;
        li.owner = msg.sender;

        emit MerchantInitial(msg.sender, lil.LIL.length, inTokenCapacity, outTokenCapacity, inToken ,  outToken, startTime ,  endTime , lockPeriod ,proName );
        bool success = IERC20(outToken).transferFrom(msg.sender, address(this), outTokenCapacity);
        require(success, "Call failed");
    }

    function lockERC20(uint index,uint initAmount,address merchant)  external  whenNotPaused{
        require( merchantLocksInfo[merchant].LIL.length   >= index+1 ,"invalid index");
        require(initAmount >0 ,"invalid-value");
        LockInfo  storage  lInfo = merchantLocksInfo[merchant].LIL[index];
        require(lInfo.outTokenCapacity > 0, "no-more-tokens-available");
    unchecked{
        uint _numOfTokens = (initAmount* lInfo.outTokenSupply / lInfo.inTokenCapacity);
        require(_numOfTokens <= lInfo.outTokenCapacity, "amount-exceeds-available-tokens");

        lInfo.outTokenCapacity = (lInfo.outTokenCapacity - _numOfTokens);
        lInfo.inTokenAmount = (lInfo.inTokenAmount + initAmount);

        if (lInfo.lockUser[msg.sender].amount == 0){
            Lock memory l = Lock({
            amount: initAmount,
            numOfTokens: _numOfTokens,
            lockEnding: ( lInfo.ending+ (lInfo.lockPeriod* TIMEUINT)),
            releasedToken:0
            });
            lInfo.lockUser[msg.sender]=l;
        }else{
            lInfo.lockUser[msg.sender].amount +=  initAmount;
            lInfo.lockUser[msg.sender].numOfTokens += _numOfTokens;
        }

        emit Deposit(msg.sender,merchant , index, initAmount, _numOfTokens );
        bool success = IERC20(lInfo.inToken).transferFrom(msg.sender, address(this), initAmount);
        require(success, "Call failed");
    }
    }

    function advanceLock(uint index)external {
        require( merchantLocksInfo[msg.sender].LIL.length   >= index+1 ,"invalid index");
        require ( merchantLocksInfo[msg.sender].LIL[index].owner == msg.sender, "not the owner");
        require ( merchantLocksInfo[msg.sender].LIL[index].startTime < block.timestamp, "time are not in start");
        merchantLocksInfo[msg.sender].LIL[index].ending = block.timestamp;
        emit AdvanceLock(msg.sender,index);
        }

    function unlock(uint index) external   whenNotPaused{
        require( merchantLocksInfo[msg.sender].LIL.length   >= index+1 ,"invalid index");
        LockInfo storage l = merchantLocksInfo[msg.sender].LIL[index];
        require(l.startTime >  block.timestamp, "not before start");
        require(l.outTokenSupply > 0, "deposit-already-unlocked");
        require(l.owner ==  msg.sender, "need the owner");
        uint amount = l.outTokenSupply;
        l.outTokenSupply = 0;
        emit Unlock(msg.sender, index);
        bool success =  IERC20(l.outToken).transfer(msg.sender, amount);
        require(success, "Call failed");
    }

    function merchantWithdraw(uint index)external  whenNotPaused{
        require( merchantLocksInfo[msg.sender].LIL.length   >= index+1 ,"invalid index");
        require ( merchantLocksInfo[msg.sender].LIL[index].ending < block.timestamp, "time are not after ending");
        LockInfo storage   lInfo = merchantLocksInfo[msg.sender].LIL[index];
        emit MerchantWithdraw(msg.sender, index);
        bool success = IERC20(lInfo.outToken).transfer(msg.sender,  lInfo.outTokenCapacity);
        require(success, "Call failed");

        bool inTokenSuccess = IERC20(lInfo.inToken).transfer(msg.sender,  lInfo.inTokenAmount);
        require(inTokenSuccess, "Call failed");
    }

    function withdraw(uint index,address merchant ) external   whenNotPaused{
        require( merchantLocksInfo[merchant].LIL.length   >= index+1 ,"invalid index");
        require( merchantLocksInfo[merchant].LIL[index].ending <  block.timestamp, "time is too early");

        LockInfo storage   lInfo = merchantLocksInfo[merchant].LIL[index];
        require((  lInfo.lockUser[msg.sender].numOfTokens - lInfo.lockUser[msg.sender].releasedToken) > 0,
            "no-token-withdraw");
        Lock memory l = lInfo.lockUser[msg.sender];

    unchecked{

        uint256 rewardAmount = vestedAmount( l , uint256(block.timestamp)  );
        lInfo.lockUser[msg.sender].releasedToken += rewardAmount;
        require(rewardAmount > 0, "no-locked-amount-found");
        emit WithdrawEvent(msg.sender, rewardAmount,index ,merchant );
        bool success = IERC20(lInfo.outToken).transfer(msg.sender,  rewardAmount);
        require(success, "Call failed");
    }
    }

    // function withdrawAll() external hasEnded whenNotPaused{
    //     uint totalWithdraw = 0;
    //     for(uint i=0;i<PERIOD.length; i++){
    //     unchecked{
    //         if ((locks[PERIOD[i]][msg.sender].numOfTokens - locks[PERIOD[i]][msg.sender].releasedToken) <= 0){
    //             continue;
    //         }
    //         Lock memory l = locks[PERIOD[i]][msg.sender];
    //         uint256 rewardAmount = vestedAmount( l , uint256(block.timestamp)  );
    //         if( rewardAmount <=0){
    //             continue;
    //         }
    //         locks[PERIOD[i]][msg.sender].releasedToken += rewardAmount;
    //         totalWithdraw += rewardAmount;
    //         emit WithdrawEvent(msg.sender, rewardAmount,PERIOD[i]);
    //     }
    //     }
    //     require(totalWithdraw > 0, "no-locked-amount-found");
    //     bool success = IERC20(rewardToken).transfer(msg.sender,  totalWithdraw);
    //     require(success, "Call failed");
    // }

    function getLockAt(address user, address merchant, uint index) external view returns (uint amount, uint numOfTokens, uint lockEnding,uint releaseToken) {
        require( merchantLocksInfo[merchant].LIL.length   >= index+1 ,"invalid index");
        LockInfoList storage  lInfoList = merchantLocksInfo[merchant];
        LockInfo storage  lInfo = lInfoList.LIL[index];

        return ( lInfo.lockUser[user].amount,  lInfo.lockUser[user].numOfTokens,  lInfo.lockUser[user].lockEnding, lInfo.lockUser[user].releasedToken);
    }

    function getMerchantLockInfo( address merchant, uint index) external view returns (uint inTokenCapacity, address inToken, uint outTokenSupply,uint outTokenCapacity,
address outToken,uint startTime, uint ending,uint16 lockPeriod) {
        require( merchantLocksInfo[merchant].LIL.length   >= index+1 ,"invalid index");

        LockInfo storage  lInfo = merchantLocksInfo[merchant].LIL[index];
        return ( lInfo.inTokenCapacity,  lInfo.inToken,  lInfo.outTokenSupply, lInfo.outTokenCapacity,lInfo.outToken,
            lInfo.startTime,lInfo.ending,lInfo.lockPeriod);
    }


    function vestedAmount(Lock  memory lock ,uint256 timestamp ) public pure returns (uint256) {

    unchecked{
        if (timestamp < lock.lockEnding) {
            return 0;
        } else if (timestamp > lock.lockEnding + RELEASEUINT ) {
            return lock.numOfTokens  - lock.releasedToken ;
        } else {
            return (lock.numOfTokens * (timestamp - lock.lockEnding)) / RELEASEUINT  - lock.releasedToken;
        }
    }
    }

    function fund() public payable {
        require(msg.value> 0, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdrawETH() external onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}