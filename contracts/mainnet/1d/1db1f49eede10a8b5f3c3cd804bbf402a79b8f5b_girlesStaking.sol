/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

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

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/girlesStaking.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract girlesStaking is Ownable, ReentrancyGuard{

    IERC20 public rewardToken;
    IERC20 public stakedToken;

    uint public rewardTokenSupply;
    uint public totalStakedToken;

    struct info{
        uint amount;
        uint lastClaim;
        uint stakeTime;
        uint durationCode;
        uint position;
        uint earned;
    }

    uint[4] public durations = [14 days, 90 days, 365 days];
    uint[4] public rates = [10, 60, 150];

    mapping(address=>mapping(uint=>info)) public userStaked; //USER > ID > INFO
    mapping(address=>uint) public userId;
    mapping(address=>uint) public userTotalEarnedReward;
    mapping(address=>uint) public userTotalStaked;
    mapping(address=>uint[]) public stakedIds;

    bool public paused = true;

    event StakeAdded(
        address indexed _usr,
        uint _amount,
        uint startStakingTime,
        uint8 _durationCode,
        uint _stakedIndex
    );
    event Unstaked(address indexed _usr, uint _stakeIndex);
    event ClaimReward(address indexed _from, uint _claimedTime, uint _stakeIndex);
    event ClaimRewardAll(address indexed _from, uint _claimedTime, uint _amount);
    event RewardTokenAdded(address indexed _from, uint256 _amount);
    event RewardTokenRemoved(address indexed _to, uint256 _amount);
    event UpdateDuration(address indexed _from);
    event UpdateRate(address indexed _from);

    constructor(address _rewardToken, address _stakedToken) {
        rewardToken = IERC20(_rewardToken);
        stakedToken = IERC20(_stakedToken);
    }

    function addReward(uint256 _amount)
        external
        onlyOwner
    {
        //transfer from (need allowance)
        rewardTokenSupply += _amount;

        rewardToken.transferFrom(msg.sender, address(this), _amount);

        emit RewardTokenAdded(msg.sender, _amount);
    }

    function removeStakedTokenReward(uint256 _amount)
        external
        onlyOwner
    {
        require(_amount <= rewardTokenSupply, "you cannot withdraw this amount");
        rewardTokenSupply -= _amount;

        rewardToken.transfer(msg.sender, _amount);
        emit RewardTokenRemoved(msg.sender, _amount);
    }

    function updateDuration(uint[3] memory _durations) external onlyOwner {
        durations = _durations;
        emit UpdateDuration(msg.sender);
    }

    function updateRate(uint[3] memory _rates) external onlyOwner {
        rates = _rates;
        emit UpdateRate(msg.sender);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function stake(uint _amount, uint8 _durationCode) external {
        require(!paused,"Execution paused");
        require(_durationCode < 4,"Invalid duration");

        userId[msg.sender]++;
        userStaked[msg.sender][userId[msg.sender]] = info(_amount, block.timestamp, block.timestamp,
                                                _durationCode, stakedIds[msg.sender].length, 0);

        stakedIds[msg.sender].push(userId[msg.sender]);

        require(stakedToken.transferFrom(msg.sender, address(this), _amount), "Amount not sent");

        totalStakedToken += _amount;
        userTotalStaked[msg.sender] += _amount;
        emit StakeAdded(
            msg.sender,
            _amount,
            block.timestamp,
            _durationCode,
            stakedIds[msg.sender].length - 1
        );
    }

    function getRewardById(address _user, uint _id) public view returns(uint) {
        info storage userInfo = userStaked[_user][_id];
        uint timeDiff = block.timestamp - userInfo.lastClaim;

        uint reward = userInfo.amount * timeDiff * rates[userInfo.durationCode] / 
                        (durations[userInfo.durationCode] * 100);

        return reward;
    }

    function getAllReward(address _user, uint _durationCode) public view returns(uint) {
        uint amount = 0;
        uint length = stakedIds[_user].length;
        for(uint i=0; i<length; i++){
            info storage userInfo = userStaked[_user][stakedIds[_user][i]];
            if (userInfo.amount == 0)
                continue;

            if (userInfo.durationCode != _durationCode)
                continue;

            uint amountIndex = getRewardById(_user, stakedIds[_user][i]);
            amount += amountIndex;
        }

        return amount;
    }

    function getStakedInfo(address _user) public view 
        returns (info[] memory infors, uint[] memory claimable, uint[] memory pending) {
        uint length = stakedIds[_user].length;
        infors = new info[](length);
        claimable = new uint[](length);
        pending = new uint[](length);

        for(uint i=0; i<length; i++){
            info storage userInfo = userStaked[_user][stakedIds[_user][i]];
            infors[i] = userInfo;
            pending[i] = getRewardById(_user, stakedIds[_user][i]);
            claimable[i] = claimableReward(_user, stakedIds[_user][i]);
        }
    }

    function claimableReward(address _user, uint _id) public view returns(uint) {
        info storage userInfo = userStaked[_user][_id];

        if (block.timestamp - userInfo.stakeTime < durations[userInfo.durationCode])
            return 0;

        return getRewardById(_user, _id);
    }

    function claimableAllReward(address _user, uint _durationCode) public view returns(uint) {
        uint amount = 0;
        uint length = stakedIds[_user].length;
        for(uint i=0; i<length; i++){
            info storage userInfo = userStaked[_user][stakedIds[_user][i]];
            if (userInfo.amount == 0)
                continue;

            if (userInfo.durationCode != _durationCode)
                continue;

            if (block.timestamp - userInfo.stakeTime < durations[userInfo.durationCode])
                continue;

            uint amountIndex = getRewardById(_user, stakedIds[_user][i]);
            amount += amountIndex;
        }

        return amount;
    }

    function claimReward(uint _id) public nonReentrant {
        info storage userInfo = userStaked[msg.sender][_id];
        require (block.timestamp - userInfo.stakeTime >= durations[userInfo.durationCode], 
            "Not claim yet, Locked period still.");

        claim(_id);

        emit ClaimReward(msg.sender, block.timestamp, _id);
    }

    function claim(uint _id) private {
        uint amount = 0;
        require(userStaked[msg.sender][_id].amount != 0, "Invalid ID");

        amount = getRewardById(msg.sender, _id);
        require(
            rewardToken.balanceOf(address(this)) >= amount,
            "Insufficient token to pay your reward right now"
        );

        rewardToken.transfer(msg.sender, amount);

        info storage userInfo = userStaked[msg.sender][_id];
        userInfo.lastClaim = block.timestamp;
        userInfo.earned += amount;

        userTotalEarnedReward[msg.sender] += amount;
        rewardTokenSupply -= amount;
    }

    function claimAllReward(uint _durationCode) public nonReentrant {
        uint amount = 0;
        uint length = stakedIds[msg.sender].length;
        for(uint i=0; i<length; i++){
            info storage userInfo = userStaked[msg.sender][stakedIds[msg.sender][i]];
            if (userInfo.amount == 0)
                continue;

            if (userInfo.durationCode != _durationCode)
                continue;

            if (block.timestamp - userInfo.stakeTime < durations[userInfo.durationCode])
                continue;

            uint amountIndex = getRewardById(msg.sender, stakedIds[msg.sender][i]);
            if (amountIndex == 0)
                continue;

            userInfo.lastClaim = block.timestamp;
            userInfo.earned += amountIndex;
            amount += amountIndex;
        }

        rewardToken.transfer(msg.sender, amount);
        rewardTokenSupply -= amount;
        userTotalEarnedReward[msg.sender] += amount;

        emit ClaimRewardAll(msg.sender, block.timestamp, amount);
    }

    function unstake(uint _amount, uint _id) external nonReentrant{
        claim(_id);

        info storage userInfo = userStaked[msg.sender][_id];
        require(userInfo.amount != 0 && _amount <= userInfo.amount ,"Invalid ID");
        require(block.timestamp - userInfo.stakeTime >= durations[userInfo.durationCode], "Not unlocked yet");

        if (_amount == userInfo.amount) {
            popSlot(_id);

            delete userStaked[msg.sender][_id];
        }
        else
            userInfo.amount -= _amount;

        require(
            stakedToken.balanceOf(address(this)) >= _amount,
            "Insufficient token to unstake right now"
        );

        stakedToken.transfer(msg.sender, _amount);

        totalStakedToken -= _amount;
        userTotalStaked[msg.sender] -= _amount;

        emit Unstaked(msg.sender, _id);
    }

    function unstake(uint _id) external nonReentrant{
        claim(_id);

        info storage userInfo = userStaked[msg.sender][_id];
        require(userInfo.amount != 0,"Invalid ID");
        require(block.timestamp - userInfo.stakeTime >= durations[userInfo.durationCode], "Not unlocked yet");

        require(
            stakedToken.balanceOf(address(this)) >= userInfo.amount,
            "Insufficient token to unstake right now"
        );

        stakedToken.transfer(msg.sender, userInfo.amount);

        popSlot(_id);
        delete userStaked[msg.sender][_id];

        totalStakedToken -= userInfo.amount;
        userTotalStaked[msg.sender] -= userInfo.amount;

        emit Unstaked(msg.sender, _id);
    }

    function popSlot(uint _id) internal {
        uint length = stakedIds[msg.sender].length;
        bool replace = false;
        for (uint256 i=0; i<length; i++) {
            if (stakedIds[msg.sender][i] == _id)
                replace = true;
            if (replace && i<length-1)
                stakedIds[msg.sender][i] = stakedIds[msg.sender][i+1];
        }
        stakedIds[msg.sender].pop();
    }
}