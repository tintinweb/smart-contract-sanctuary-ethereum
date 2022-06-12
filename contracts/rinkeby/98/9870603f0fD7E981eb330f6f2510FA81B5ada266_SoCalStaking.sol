// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract SoCalStaking is Ownable, ReentrancyGuard, Pausable{

    uint256 private USDREWARDPERCENT;
    uint256 private MAXMARKETCAP = 100000000 * 10 ** 18 ;
    uint256 _count = 0;
    address private STAKECONTRACTADDRESS;
    address private REWARDUSDTADDRESS;

    struct userStakeData{
        uint256  _count;
        uint256 _amount;
        bool _hasdeposited;
        uint256 _timestamp;
        uint256 _locktime;
        bool _rewardTaken;

    }

    event Deposited(address indexed payee, uint256 soCalAmount, uint timeStamp);
    event Withdrawn(address indexed payee, uint256 soCalAmount, uint timeStamp);

    // mapping(address => uint256) private _deposits;
    // mapping(address =>  bool) private  _hasdeposited;
    // mapping(uint => uint) internal _countTotimePeriod;
    // mapping(address => bool) public _rewardTaken; // USDT
    mapping(address => userStakeData) private _stakeData;

    constructor (uint256 _usdtRewardPercent, address _rewardContract, address _stakeContract) {

        USDREWARDPERCENT = _usdtRewardPercent;
        STAKECONTRACTADDRESS = _stakeContract;
        REWARDUSDTADDRESS = _rewardContract;
    }

    // Depost to stake amount in SOCAL token and lock time period 30 or 60 days only.
    function stakeSoCal(uint256 _amount, uint256 _locktime) public {
        require(_stakeData[msg.sender]._hasdeposited == false, "Already Staked cannot stake again");
        // require(_locktime == 30 || _locktime == 60, "Socal token can only be stakes for either 30 or 60 days");
        require(_amount > 0, "Value must be greater than zero");
        
        _count++;
        // _deposits[msg.sender] = _amount;
        // _hasdeposited[msg.sender] = true;
        // _countTotimePeriod[_count] = block.timestamp;
        
        _stakeData[msg.sender]._count = _count;        
        _stakeData[msg.sender]._amount = _amount;
        _stakeData[msg.sender]._hasdeposited = true;
        _stakeData[msg.sender]._timestamp = block.timestamp;
        _stakeData[msg.sender]._locktime = (_locktime * 1 days) + block.timestamp;

        IERC20(STAKECONTRACTADDRESS).transferFrom(msg.sender, address(this), _amount);
        
          emit Deposited(msg.sender, _amount, block.timestamp);
    }

    //  REWARD FUNCTION to distribute rewards in usdt
    function reward() external nonReentrant() returns(uint256 usdtReward, address user){
        // require(_stakeData[msg.sender]._hasdeposited == true, "You do not have staked");
        // uint256 amount = ((_stakeData[msg.sender]._amount/100) * 5); // take calculated REWARD here and set in AMOUNT
      (,usdtReward) = calculateReward(msg.sender);
        _stakeData[msg.sender]._rewardTaken = true;
        IERC20(REWARDUSDTADDRESS).transfer(msg.sender, usdtReward);
        return(usdtReward, msg.sender);
    } 

    // UNSTAKE SOCAL TOKEN AND GET REWARDS IN SOCAL TOKEN
    function unstake() external nonReentrant() returns(uint256 nativeAmount, address user){
    // require(_stakeData[msg.sender]._hasdeposited == true," You have no stakes");
    require(_stakeData[msg.sender]._locktime <= block.timestamp, "cannot calculate Reward");
    // require(_stakeData[msg.sender]._timestamp + _stakeData[msg.sender]._locktime <= block.timestamp);
        (nativeAmount,) = calculateReward(msg.sender); //tranfers stake amount and reward amount
         nativeAmount = nativeAmount+ _stakeData[msg.sender]._amount;
        IERC20(STAKECONTRACTADDRESS).transfer(msg.sender, nativeAmount);

    emit Withdrawn(msg.sender, nativeAmount, block.timestamp);
    return(nativeAmount, msg.sender);
    }
    
    // REWARD CALCULATION FOR TIME LOCK PERIOD IN SOCAL AND USDT TOKEN
    function calculateReward(address _caller)public view returns(uint256 nativeAmount, uint256 usdtReward){
    userStakeData memory cache =_stakeData[_caller] ;
    require(cache._hasdeposited == true," You have no stakes");
   
    if(cache._locktime >= cache._timestamp + 3 minutes && _count <= 500){
        nativeAmount = ((cache._amount/100) * 150);
    }else if(cache._locktime >= cache._timestamp + 3 minutes && _count > 500 && _count < 1250){
        nativeAmount = ((cache._amount/100) * 100) ;

    }else if(cache._locktime >= cache._timestamp + 3 minutes && _count > 1250 && _count < 2250){
        nativeAmount = ((cache._amount/100) * 75) ;
    } else if(cache._locktime >= cache._timestamp + 6 minutes  && _count <= 500){
        nativeAmount = ((cache._amount/100) * 300) ;
        
    }else if(cache._locktime >= cache._timestamp + 6 minutes  && _count > 500 && _count < 1250){
        nativeAmount = ((cache._amount/100) * 150) ;

    }else if(cache._locktime > cache._timestamp + 6 minutes && _count > 1250 && _count < 2250){
        nativeAmount = ((cache._amount/100) * 100) ;
    }
    else{
        require(IERC20(STAKECONTRACTADDRESS).totalSupply() <= MAXMARKETCAP,"Market Cap Reached threshold");
        nativeAmount = ((cache._amount/100) * 50) ;
    }
    usdtReward = ((_stakeData[msg.sender]._amount/100) * 5);

    }

    // returns the total amount stake/deposited in the contract, callable by contract owner only
    function totalStake()external view onlyOwner returns(uint256 amount){
        amount = IERC20(REWARDUSDTADDRESS).balanceOf(address(this));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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