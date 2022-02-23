/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
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


 
library SafeMath {


 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {



        unchecked {



            uint256 c = a + b;



            if (c < a) return (false, 0);



            return (true, c);



        }



    }


 

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {



        unchecked {



            if (b > a) return (false, 0);



            return (true, a - b);



        }



    }




 

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {



        unchecked {



            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the



            // benefit is lost if 'b' is also tested.



            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522



            if (a == 0) return (true, 0);



            uint256 c = a * b;



            if (c / a != b) return (false, 0);



            return (true, c);



        }



    }


 

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {



        unchecked {



            if (b == 0) return (false, 0);



            return (true, a / b);



        }



    }






 

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {



        unchecked {



            if (b == 0) return (false, 0);



            return (true, a % b);



        }



    }




 

    function add(uint256 a, uint256 b) internal pure returns (uint256) {



        return a + b;



    }


 

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {



        return a - b;



    }



 


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        return a * b;



    }






 



    function div(uint256 a, uint256 b) internal pure returns (uint256) {



        return a / b;



    }




 


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {



        return a % b;



    }




 

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {



        unchecked {



            require(b <= a, errorMessage);



            return a - b;



        }



    }




 


    /**



     * @dev Returns the integer division of two unsigned integers, reverting with custom message on



     * division by zero. The result is rounded towards zero.



     *



     * Counterpart to Solidity's `%` operator. This function uses a `revert`



     * opcode (which leaves remaining gas untouched) while Solidity uses an



     * invalid opcode to revert (consuming all remaining gas).



     *



     * Counterpart to Solidity's `/` operator. Note: this function uses a



     * `revert` opcode (which leaves remaining gas untouched) while Solidity



     * uses an invalid opcode to revert (consuming all remaining gas).



     *



     * Requirements:



     *



     * - The divisor cannot be zero.



     */



    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {



        unchecked {



            require(b > 0, errorMessage);



            return a / b;



        }



    }


 


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {



        unchecked {



            require(b > 0, errorMessage);



            return a % b;



        }



    }



} 



contract Bonding is ReentrancyGuard, Pausable{
   
    using SafeMath for uint256;
 
    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;       
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    struct Deposit{
        uint256 bondedAt;
        uint256 bondedQty;
    }

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint256 private _totalSupply;
    mapping(address => Deposit[]) private _balances;

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event RewardRateUpdated(uint256 newRate);
 

    /* ========== CONSTRUCTOR ========== */

    constructor( 
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardRate,
        uint256 _rewardsDuration
    )  {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken); 
        rewardRate = _rewardRate;
        rewardsDuration = _rewardsDuration; 
    }
/* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /*function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }*/

    function getBonds(address bonder) public view returns (Deposit[] memory){
        Deposit[] memory d = _balances[bonder];
        return (d);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(86400).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        uint256 totalBalance = 0;
        for(uint i = 0; i < _balances[account].length; i++){
            if(_balances[account][i].bondedQty > 0){ //dont really need to check this but why not
                totalBalance += _balances[account][i].bondedQty;
            }
        }

        return totalBalance.mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(86400).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

   
    /* ========== MUTATIVE FUNCTIONS ========== */

    function bond(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        address bonder = msg.sender;
        _totalSupply = _totalSupply.add(amount);

        _balances[bonder].push(
            Deposit(
                block.timestamp,
                amount
            )
        );

        //_balances[msg.sender] = _balances[msg.sender].add(amount);

        stakingToken.transferFrom(bonder, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 id, uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(
            _balances[msg.sender].length > id, 
            "Deposit does not exist"
        );
        require(
            _balances[msg.sender][id].bondedQty > 0,
            "There is nothing to withdraw"
        );
        require(
            amount >= 0,
            "Can only withdraw a positive quantity"
        );
        require(
            _balances[msg.sender][id].bondedQty >= amount,
            "Cannot withdraw more than this deposit contains"
        );

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender][id].bondedQty.sub(amount);

        stakingToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        //assume that this will just withdraw everything
        for(uint i = 0; i < _balances[msg.sender].length; i++){
            if(_balances[msg.sender][i].bondedQty > 0){ //check here to save gas
                withdraw(i, _balances[msg.sender][i].bondedQty);
            }
        }
        
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
 

    function setRewardsDuration(uint256 _rewardsDuration) external   {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setRewardRate(uint256 _rewardRate) external{
        require(block.timestamp > periodFinish);
        rewardRate = _rewardRate;
        emit RewardRateUpdated(rewardRate);
    }
    
    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
 
}