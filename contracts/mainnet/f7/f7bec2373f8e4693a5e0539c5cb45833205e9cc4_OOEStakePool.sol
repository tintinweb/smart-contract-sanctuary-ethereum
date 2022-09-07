/**
 *Submitted for verification at Etherscan.io on 2022-09-07
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: DAO/dao.sol



pragma solidity 0.8.11;





contract OOEStakePool is ReentrancyGuard,Ownable{

    struct Lock{
        address locker;
        uint256 lockId;
        uint256 timestampLockStart;
        uint256 timestampLockEnd;
        uint256 OOELockedAmount;
        uint256 XOOEBaseAmount;
        uint256 lockTimeUnit;
        State state;       
    }

    enum State {
        UNSTART,
        LOCKING,
        COMPLETE
    }

    enum MixLockType {
        AllEXTERNAL,
        ALLREVERSE,
        MIX
    }
   
   
    bool public pause;
    IERC20 public OOE;
    uint256 public period;
    uint256 public punishmentDegree;         // 4 default
    uint256 public minimumIncrease;         //6.5% == 6500

    mapping (address => uint256) public totalOOE;
    mapping (address => uint256) public availableOOE;
    mapping (uint256 => Lock) public lockDetail;
    mapping (address => uint256[]) private _locksId;
    mapping (uint256 => uint256) public rates; //rates, not APY. eg. need 12% : insert 1200000000
    
    event logAddOOEToPool(uint256 amount);
    event logHarvest(address user, Lock lock);
    event logLocks(address user, Lock[] lock);
    event logLock(address user, Lock lock);
    event logUnLock(address user,Lock lock);
    event logUserWithdrew(address user, uint256 amount);


    modifier notPause() {
        require(!pause, "OPENOCEAN_STAKING_POOL_V1:PAUSE_NOW");
        _;
    }

    constructor(IERC20 OOE_) {
        OOE = OOE_;
    }


    function setPause(bool pauseOrNot) external onlyOwner {
        pause = pauseOrNot;
    }

    function setRates(uint256[] memory months, uint256[] memory _rates) external onlyOwner {
        require(months.length == _rates.length, "OPENOCEAN_STAKING_POOL_V1:WRONG_INPUT");
        uint256 locksAmount = months.length;
        for(uint256 i = 0; i<locksAmount; i++){
            rates[months[i]] = _rates[i];
        }
    }

    function setMinimumIncrease(uint256 minimum) public onlyOwner{
        minimumIncrease = minimum;
    }

    function setPeriod(uint256 _period) public onlyOwner{
        period = _period;
    }

    function setPunishmentDegree(uint256 degree) public onlyOwner{
        punishmentDegree = degree;
    }

    function getVotingPower(address voter) public view returns(uint256){
        uint256 locksAmount = _locksId[voter].length;
        uint256 power;
        for(uint256 i = 0; i < locksAmount; i++){
            Lock memory lo = lockDetail[_locksId[voter][i]];
            if(lo.state == State.LOCKING){
                if(lo.timestampLockEnd > block.timestamp){
                    power = power + lo.OOELockedAmount + (lo.XOOEBaseAmount - lo.OOELockedAmount) * (block.timestamp - lo.timestampLockStart)/(lo.timestampLockEnd - lo.timestampLockStart);
                }else{
                    power = power + lo.XOOEBaseAmount + (block.timestamp - lo.timestampLockEnd) * minimumIncrease * lo.XOOEBaseAmount / 3110400000000;
                }
            }
        }
        return power;
    }

    function getOOEAmountInpool() public view returns(uint256){
        return OOE.balanceOf(address(this));
    }

    function getUserAllLockId(address user_) public view returns(uint256[] memory){
        return _locksId[user_];
    }

    function getUserStakingOOE(address user) public view returns(uint256){
        return totalOOE[user] - availableOOE[user];
    }

    function getBatchStakeAmount(Lock[] memory _lock) public pure returns(uint256){
        uint256 amount;
        for(uint256 i; i<_lock.length;i++){
            amount = amount + _lock[i].OOELockedAmount;
        }
        return amount;
    }

    function addOOEToPool(uint256 amount) external{
        OOE.transferFrom(msg.sender, address(this), amount);
        emit logAddOOEToPool(amount);
    }

// harvest all the locks OOE
    function harvestall() external notPause{
        uint256 locksAmount = _locksId[msg.sender].length;
        for(uint256 i = 0; i<locksAmount; i++){
            Lock storage lo = lockDetail[_locksId[msg.sender][i]];
            if(block.timestamp > lo.timestampLockEnd && lo.state == State.LOCKING){
            lo.state = State.COMPLETE;
            availableOOE[msg.sender] = availableOOE[msg.sender] + lo.XOOEBaseAmount + (block.timestamp - lo.timestampLockEnd) * minimumIncrease * lo.XOOEBaseAmount / 3110400000000;
            totalOOE[msg.sender] = totalOOE[msg.sender] + lo.XOOEBaseAmount - lo.OOELockedAmount + (block.timestamp - lo.timestampLockEnd) * minimumIncrease * lo.XOOEBaseAmount / 3110400000000;
            emit logHarvest(msg.sender,lo);
            }
        }
    }
//harvest aimed locks
    function harvest(uint256[] calldata lockid) external notPause{
        uint256 locksAmount = lockid.length;
        for(uint256 i = 0; i<locksAmount; i++){
            Lock storage lo = lockDetail[lockid[i]];
            require(lo.state == State.LOCKING,"OPENOCEAN_STAKING_POOL_V1:BAD_ORDER");
            if(block.timestamp > lo.timestampLockEnd){
            lo.state = State.COMPLETE;
            availableOOE[msg.sender] = availableOOE[msg.sender] + lo.XOOEBaseAmount + (block.timestamp - lo.timestampLockEnd) * minimumIncrease * lo.XOOEBaseAmount / 3110400000000;
            totalOOE[msg.sender] = totalOOE[msg.sender] + lo.XOOEBaseAmount - lo.OOELockedAmount + (block.timestamp - lo.timestampLockEnd) * minimumIncrease * lo.XOOEBaseAmount / 3110400000000;
            emit logHarvest(msg.sender,lo);
            }
        }
    }

    function unlock(uint256[] calldata lockid) external notPause{
        for(uint256 i = 0; i < lockid.length; i++){
            require(lockDetail[lockid[i]].locker == msg.sender,"OPENOCEAN_STAKING_POOL_V1:NOT_ORDER_LOCKER");
            require(lockDetail[lockid[i]].timestampLockEnd > block.timestamp,"OPENOCEAN_STAKING_POOL_V1:THIS_LOCK_WAS_ALREADY_COMPLETED");
            require(lockDetail[lockid[i]].state == State.LOCKING,"OPENOCEAN_STAKING_POOL_V1:BAD_ORDER");
            Lock storage lo = lockDetail[lockid[i]];
            lo.state=State.COMPLETE;
            availableOOE[msg.sender] = availableOOE[msg.sender] + lo.OOELockedAmount + (lo.XOOEBaseAmount - lo.OOELockedAmount) * (block.timestamp - lo.timestampLockStart)/(lo.timestampLockEnd - lo.timestampLockStart) - _punishment(lo);
            totalOOE[msg.sender] = totalOOE[msg.sender] + (lo.XOOEBaseAmount - lo.OOELockedAmount) * (block.timestamp - lo.timestampLockStart)/(lo.timestampLockEnd - lo.timestampLockStart) - _punishment(lo);
            emit logUnLock(msg.sender, lo);
        }  
    }

    function lock(Lock memory _lock) external notPause{
        _receiveOOE(_lock.OOELockedAmount); 
        _singleLock(_lock);
        emit logLock(msg.sender, _lock);
    }

    function lockWithReverse(Lock memory _lock) public notPause{
        _singleLock(_lock); 
        emit logLock(msg.sender, _lock);
    }

    function batchMixLock(Lock[] memory _lock, MixLockType type_, uint256 externalOOEAmount) external notPause{
        if(type_ == MixLockType.AllEXTERNAL){ 
            _receiveOOE(getBatchStakeAmount(_lock)); 
            for(uint256 i; i<_lock.length; i++){
                 _singleLock(_lock[i]);
            }
        }else if(type_ == MixLockType.ALLREVERSE){
            for(uint256 i; i<_lock.length; i++){
                lockWithReverse(_lock[i]);
            }
        }else if(type_ == MixLockType.MIX){
            uint256 lockAmount = externalOOEAmount + availableOOE[msg.sender];
            require(lockAmount >= getBatchStakeAmount(_lock), "OPENOCEAN_STAKING_POOL_V1:EXTERNALOOE_NOT_ENOUGH");
            _receiveOOE(externalOOEAmount);
            for(uint256 i; i<_lock.length; i++){
                lockWithReverse(_lock[i]);
            }
        }
        emit logLocks(msg.sender, _lock);
    }

    function adminWithdrew(uint256 amount) external onlyOwner{
        require(OOE.balanceOf(address(this)) >= amount,"OPENOCEAN_STAKING_POOL_V1:WITHDREW_TOO_MUCH");
        OOE.transfer(msg.sender,amount);
    }

    function withdrew(uint256 amount) external notPause{
        _sendOOE(amount, msg.sender);
        emit logUserWithdrew(msg.sender, amount);
    }

    function _sendOOE(uint256 amount, address destination_) internal nonReentrant{
        require(availableOOE[msg.sender] >= amount,"OPENOCEAN_STAKING_POOL_V1:WITHDREW_TOO_MUCH");
        totalOOE[msg.sender] = totalOOE[msg.sender] - amount;
        availableOOE[msg.sender] = availableOOE[msg.sender] - amount;
        OOE.transfer(destination_,amount);
    }

    function _receiveOOE(uint256 amount) internal nonReentrant{
        totalOOE[msg.sender] = totalOOE[msg.sender] + amount;
        availableOOE[msg.sender] = availableOOE[msg.sender] + amount;
        OOE.transferFrom(msg.sender, address(this), amount);
    }

    function _punishment(Lock memory _lock) internal returns(uint256){
        uint256 punishmentAmount = punishmentDegree * (_lock.XOOEBaseAmount - _lock.OOELockedAmount) * (block.timestamp - _lock.timestampLockStart) / (_lock.timestampLockEnd - _lock.timestampLockStart) / 5;
        return punishmentAmount;
    }

    function _singleLock(Lock memory _lock) internal{
        require(_lock.locker == msg.sender, "OPENOCEAN_STAKING_POOL_V1:ONLY_ALLOW_SELFLOCK");

        require(block.timestamp > _lock.timestampLockStart && block.timestamp - _lock.timestampLockStart < 120,"OPENOCEAN_STAKING_POOL_V1:WRONG_START_TIME");
        require(lockDetail[_lock.lockId].OOELockedAmount == 0, "OPENOCEAN_STAKING_POOL_V1:LOCK_ALREADY_EXIST");
        require((_lock.timestampLockEnd - _lock.timestampLockStart) == _lock.lockTimeUnit * period, "OPENOCEAN_STAKING_POOL_V1:WRONG_ENDTIME");

        require(rates[_lock.lockTimeUnit] != 0, "OPENOCEAN_STAKING_POOL_V1:ILLEGAL_MONTH_OR_MONTH_RATES_NOT_SET");

        //Deliberately round off decimals to adapt to the front-end 'max input' function.
        require(_lock.XOOEBaseAmount == _lock.OOELockedAmount * (rates[_lock.lockTimeUnit] + 10000000000) / 10000000000,"OPENOCEAN_STAKING_POOL_V1:NOT_CORRECT_AMOUNT");
        require(availableOOE[msg.sender] >= _lock.OOELockedAmount,"OPENOCEAN_STAKING_POOL_V1:AVAILABLEOOE_NOT_ENOUGH");
        availableOOE[msg.sender] = availableOOE[msg.sender] - _lock.OOELockedAmount;
        _locksId[_lock.locker].push(_lock.lockId);
        lockDetail[_lock.lockId] = _lock;
    }
    
}