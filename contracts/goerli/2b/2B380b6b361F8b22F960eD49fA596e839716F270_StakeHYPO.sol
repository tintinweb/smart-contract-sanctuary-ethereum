/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: src/components/stakingContract/staking.sol


pragma solidity ^0.8.7;





interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);    
}

contract StakeHYPO is Pausable, Ownable, ReentrancyGuard {

    Token hypo;

    uint8 public interestRate = 5;
    uint256 private planExpire;
    uint8 private totalStakers;
    uint256 minStake;
    uint256 minDuration = 300;  // 5 Minutes
    // uint256 minDuration = 2630000; // 1 month

    struct StakeInfo {
        uint256 id;
        uint256 startTS;
        uint256 endTS;        
        uint256 amount; 
        uint256 claimed;
        uint256 userPlan;
    }

    struct AllStakes{
        uint256 amount;
        uint256 date;
    }
    
    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);

    error InvalidTokenAddress();
    error notParticipant();
    error stakeNotOver();
    error alreadyClaimed();
    error notCorrectAmount();
    error planIsExpired();
    error insufficientAllownace();
    error NoSuchStakingExists();

    AllStakes[] private allStakes;
    uint256 totalLockedTokens;
    address[] private stakers;
    mapping(address => uint256) private stakeCount;
    mapping(address => bool) public addressStaked;
    mapping(address => uint256[])private stakingId;
    mapping(address => mapping(uint256 => StakeInfo)) private stakerTokensInfo;
    mapping(address => uint256) private userLockedTokens;


    constructor(Token _tokenAddress, uint256 planExpire_, uint256 minimumStake_) {
        if(address(_tokenAddress) == address(0))
        revert InvalidTokenAddress();
        hypo = _tokenAddress;
        minStake = minimumStake_;
        planExpire = block.timestamp + planExpire_;
        totalStakers = 0;
    }    

    function transferToken(uint256 amount) external onlyOwner returns (bool){
        hypo.transfer(address(this), amount);
        return true; 
    }

    function stakeToken(uint256 stakeAmount, uint256 userPlan_) external whenNotPaused {
        if(stakeAmount < minStake)
        revert notCorrectAmount();
        if(block.timestamp > planExpire)
        revert planIsExpired();
        if(hypo.allowance(_msgSender(), address(this))< stakeAmount)
        revert insufficientAllownace();

        hypo.transferFrom(_msgSender(), address(this), stakeAmount);
        if(stakers.length == 0){
            stakers.push(msg.sender);
            totalStakers++;
        }
        else{
            for(uint256 i = 0; i < stakers.length; i++){
                if(msg.sender != stakers[i]){
                    stakers.push(msg.sender);
                    totalStakers++;
                }
            }
        }
        allStakes.push(AllStakes(stakeAmount, block.timestamp));
        totalLockedTokens +=stakeAmount;
        userLockedTokens[msg.sender] += stakeAmount;
        stakeCount[msg.sender] +=1;
        stakingId[msg.sender].push(stakeCount[msg.sender]);
        if(addressStaked[_msgSender()] == true){
            setStakingInfo(stakeAmount, userPlan_);
        }
        else{
            setStakingInfo(stakeAmount, userPlan_);
            addressStaked[_msgSender()] = true;
        }
        
        emit Staked(_msgSender(), stakeAmount);
    }

    function setStakingInfo(uint256 stakeAmount, uint256 userPlan_) internal{
        stakerTokensInfo[_msgSender()][stakeCount[msg.sender]] = StakeInfo({  
        id: stakeCount[msg.sender],          
        startTS: block.timestamp,
        endTS: block.timestamp + (minDuration * userPlan_),
        amount: stakeAmount,
        claimed: 0,
        userPlan: userPlan_
        });
    }

     function claimReward(uint256 stakeId) external nonReentrant returns (bool){
        if(addressStaked[_msgSender()] == false)
        revert notParticipant();
        if(stakerTokensInfo[_msgSender()][stakeId].endTS > block.timestamp)
        revert stakeNotOver();
        if(stakerTokensInfo[_msgSender()][stakeId].claimed > 0)
        revert alreadyClaimed();
        for(uint256 i =0; i< stakingId[msg.sender].length; i++){
            if(stakeId != stakingId[msg.sender][i]){
            revert NoSuchStakingExists();
            }
            else{
                break;
            }
        }

        uint256 stakeAmount = stakerTokensInfo[_msgSender()][stakeId].amount;
        uint256 userPlan = stakerTokensInfo[_msgSender()][stakeId].userPlan;
        uint256 rateOfMonths = userPlan * interestRate;
        uint256 totalTokens = stakeAmount + (stakeAmount * rateOfMonths / 100);
        stakerTokensInfo[_msgSender()][stakeId].claimed == totalTokens;
        stakeCount[_msgSender()] = stakeCount[_msgSender()] - 1;
        removeStaking(stakeId);
        if(stakeCount[_msgSender()] == 0){
            addressStaked[_msgSender()] = false;
        }
        userLockedTokens[msg.sender] = userLockedTokens[msg.sender] - stakeAmount;
        hypo.transfer(_msgSender(), totalTokens);
        emit Claimed(_msgSender(), totalTokens);
        return true;
    }

    function removeStaking(uint256 stakeId) internal{
        uint256 ids = stakingId[msg.sender].length;
        for(uint256 i=0; i< ids; i++){
            if(stakeId == stakingId[msg.sender][i]){
                for (uint256 j = i + 1; j < ids; j++) {
                    stakingId[msg.sender][j - 1] = stakingId[msg.sender][j];
                }
            }
        }
        stakingId[msg.sender].pop();
    }

    function getExpiry(uint256 stakeId) external view returns (uint256, uint256) {
        if(addressStaked[_msgSender()] != true)
        revert notParticipant();
        uint256 remainingTime = 0;
        if(stakerTokensInfo[_msgSender()][stakeId].endTS > block.timestamp){
            remainingTime = (stakerTokensInfo[_msgSender()][stakeId].endTS - block.timestamp);
        }
        return (remainingTime, stakerTokensInfo[_msgSender()][stakeId].id);
    }

    function amountWithReward(uint256 stakeId)external view returns(uint256){
        uint256 stakeAmount = stakerTokensInfo[_msgSender()][stakeId].amount;
        uint256 userPlan = stakerTokensInfo[_msgSender()][stakeId].userPlan;
        uint256 rateOfMonths = userPlan * interestRate;
        return  stakeAmount + (stakeAmount * rateOfMonths / 100);
    }

    function valueLocked()external view returns(uint256){
        return totalLockedTokens;
    }

    function userLockedToken()external view returns(uint256){
        return userLockedTokens[msg.sender];
    }

    function stakingIds() external view returns(uint256[] memory){
        return stakingId[msg.sender];
    }

    function allStake()external view returns(AllStakes[] memory){
        return allStakes;
    }

    function totalStaker()external view returns(uint256){
        return totalStakers;
    }

    function userStakes()external view returns(uint256){
        return stakeCount[msg.sender];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function minimumStake() external view returns (uint256){
        return minStake;
    }
}