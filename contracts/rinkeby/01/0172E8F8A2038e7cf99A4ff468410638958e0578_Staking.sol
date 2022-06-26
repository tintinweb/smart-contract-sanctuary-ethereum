//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IStaking.sol";

contract Staking is IStaking {

    struct StakingInfo {
        uint256 staked;
        uint256 accumulated;
        uint256 unfreeze;
        uint256 startStaking;
    }

    IERC20Mintable public immutable stakeToken;
    IERC20Mintable public immutable rewardToken;
    address public dao;
    uint256 public immutable rewardPercent;
    uint256 public immutable rewardInterval;
    uint256 public lockTime;

    mapping(address => StakingInfo) public staking;

    constructor(address _dao, address _stakeToken, address _rewardToken, uint256 _percent, uint256 _interval) {
        dao = _dao; 
        stakeToken = IERC20Mintable(_stakeToken);
        rewardToken = IERC20Mintable(_rewardToken);
        rewardPercent = _percent;
        rewardInterval = _interval;
        lockTime = 3 days;
    }   

    modifier onlyDAO () {
        require(msg.sender == dao, "DAO Only");
        _;
    }

    function _updateRewards(address _from) internal {
        if (rewardInterval < block.timestamp - staking[_from].startStaking)
            staking[_from].accumulated += (staking[_from].staked * rewardPercent / 100) * (block.timestamp - staking[_from].startStaking) / rewardInterval;
        staking[_from].startStaking = block.timestamp;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount cant be null");

        address _sender = msg.sender;
        stakeToken.transferFrom(_sender, address(this), _amount);

        _updateRewards(_sender);
        staking[_sender].staked += _amount;
        if (lockTime + block.timestamp > staking[_sender].unfreeze)
            staking[_sender].unfreeze = lockTime + block.timestamp;
    }

    function getRewards() public {
        address _sender = msg.sender;
        require(staking[_sender].staked > 0, "You not staking");

        _updateRewards(_sender);
        uint256 amount = staking[_sender].accumulated;

        if (amount > 0) {
            staking[_sender].accumulated = 0;
            rewardToken.transfer(_sender, amount);
        }
    }

    function unstake() external {
        address _sender = msg.sender;
        require(staking[_sender].unfreeze < block.timestamp, "Cant unstake yet");

        getRewards();
        uint amount = staking[_sender].staked;
        staking[_sender].staked = 0;
        stakeToken.transfer(_sender, amount);
    }

    function changeLockTime(uint256 _lockTime) external onlyDAO {
        require(_lockTime > 0, "Cant be null");
        lockTime = _lockTime;
    }

    function updateFreezing(address _staker, uint256 _unfreeze) external override onlyDAO {
        if (_unfreeze > staking[_staker].unfreeze) staking[_staker].unfreeze = _unfreeze;
    }

    function staked(address _from) external view override returns (uint256) {
        return staking[_from].staked;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address _account, uint _amount) external;
    function burn(address _account, uint _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStaking {
    function updateFreezing(address _staker, uint256 _unfreeze) external;
    function staked(address _from) external view returns (uint256);
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