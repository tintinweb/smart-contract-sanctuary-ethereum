/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

/** 
 *  SourceUnit: /home/superman/Desktop/solidity/stakingcontract/contracts/staking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/superman/Desktop/solidity/stakingcontract/contracts/staking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /home/superman/Desktop/solidity/stakingcontract/contracts/staking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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


/** 
 *  SourceUnit: /home/superman/Desktop/solidity/stakingcontract/contracts/staking.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.9;
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";

//users stake stakableTokens
//user get 20% APY CVIII as reward;
// token ratio 1: 1

contract StakERC20 is Ownable {
    IERC20 public rewardToken;
    IERC20[] public stakableTokens;
    IERC20 public SpecialToken;

    uint256 constant SECONDS_PER_YEAR = 31536000;

    struct User {
        uint256 stakedAmount;
        uint256 startTime;
        uint256 rewardAccrued;
        IERC20 stakeToken;
    }

    mapping(address => User) user;
    error tryAgain();

    constructor(address _rewardToken, address _undead) {
        rewardToken = IERC20(_rewardToken);
        SpecialToken = IERC20(_undead);
    }

// function setStakeToken(address _token)
//     external
//     returns (address _newToken)
// {
//     require(isStakable(_token) == false, "token already stakable");
//     require(IERC20(_token) != rewardToken, "cannot stake reward");
//     require(_token != address(0), "cannot set address zero");

//     _newToken = address(IERC20(_token));
//     stakableTokens.push(IERC20(_token));

//     // Update the stakeToken for each user who has staked the token
//     for (uint256 i = 0; i < stakableTokens.length; i++) {
//         if (address(stakableTokens[i]) == _token) {
//             User storage _user = user[msg.sender];
//             _user.stakeToken = IERC20(_token);
//         }
//     }
// }



    function stake(address token, uint256 amount) external {
        User storage _user = user[msg.sender];
        require(token != address(0), "address zero unstakabble");
        require(token != address(rewardToken), "cannot stake reward");
        require(isStakable(token), "token not stakable");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (_user.stakedAmount == 0) {
            _user.stakeToken = IERC20(token);
            _user.stakedAmount = amount;
            _user.startTime = block.timestamp;
        } else {
            require(token == address(_user.stakeToken), "user already staked a different token");
            updateReward();
            _user.stakedAmount += amount;
        }
    }

    function isStakable(address token) internal view returns (bool) {
        for (uint256 i = 0; i < stakableTokens.length; i++) {
            if (address(stakableTokens[i]) == token) {
                return true;
            }
        }
        return false;
    }

    function addStakableToken(address token) external onlyOwner {
        require(!isStakable(token), "Token already stakable");
        require(token != address(0), "cannot add address zero");
        require(token != address(rewardToken), "cannot stake reward");

        stakableTokens.push(IERC20(token));
    }

 function removeStakableToken(address token) external onlyOwner {
    require(isStakable(token), "Token not stakable");
    for (uint256 i = 0; i < stakableTokens.length; i++) {
        if (address(stakableTokens[i]) == token) {
            if (i != stakableTokens.length - 1) {
                stakableTokens[i] = stakableTokens[stakableTokens.length - 1];
            }
            stakableTokens.pop();
            return;
        }
    }
}



    function calcReward() public view returns (uint256 _reward) {
        User storage _user = user[msg.sender];
        uint256 _amount = _user.stakedAmount;
        uint256 _startTime = _user.startTime;
        uint256 duration = block.timestamp - _startTime;

            if (_user.stakeToken == SpecialToken) {
                _reward = ((20 * _amount) / 100);
            }
            else{
                _reward = (duration * 20 * _amount) / (SECONDS_PER_YEAR * 100);
            }
    }

    function claimReward(uint256 amount) public {
        User storage _user = user[msg.sender];
        updateReward();
        uint256 _claimableReward = _user.rewardAccrued;
        require(_claimableReward >= amount, "insufficient funds");
        _user.rewardAccrued -= amount;
        if (amount > rewardToken.balanceOf(address(this))) revert tryAgain();
        rewardToken.transfer(msg.sender, amount);
    }

    function updateReward() public {
        User storage _user = user[msg.sender];
        uint256 _reward = calcReward();
        _user.rewardAccrued += _reward;
        _user.startTime = block.timestamp;
    }

function withdrawStaked(uint256 amount) public {
    User storage _user = user[msg.sender];
    uint256 staked = _user.stakedAmount;
    require(staked >= amount, "insufficient fund");
    updateReward();
    _user.stakedAmount -= amount;
    require(_user.stakeToken.transfer(msg.sender, amount), "transfer failed");
}



    function closeAccount() external {
        User storage _user = user[msg.sender];
        uint256 staked = _user.stakedAmount;
        withdrawStaked(staked);
        uint256 reward = _user.rewardAccrued;
        claimReward(reward);
    }

    function userInfo(address _user) external view returns (User memory) {
        return user[_user];
    }
}