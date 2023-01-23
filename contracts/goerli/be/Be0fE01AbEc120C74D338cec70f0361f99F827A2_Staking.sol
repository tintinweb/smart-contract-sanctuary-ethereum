// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";

abstract contract AFEDCALL {
    function extMint(address _user, uint256 _value) public virtual;
}

contract Staking {
    // address of the FED contract
    address payable public fed;

    // address of the FEDCALL contract
    address payable public fedCall;

    // mapping to keep track of the staked FED balance of each user
    mapping(address => uint256) public stakedBalance;

    // mapping to keep track of the earned FEDCALL tokens of each user
    mapping(address => uint256) public earnedFEDCALL;

    // variable to keep track of the total staked FED balance
    uint256 public totalStakedBalance;

    // variable to keep track of the earning rate
    uint256 public earningRate;

    // event to notify users of their FEDCALL rewards
    event FEDCALLReward(address indexed user, uint256 reward);

    // constructor to initialize the contract with the address of the FED contract
    constructor(address payable _fed, address payable _fedCall) {
        fed = _fed;
        fedCall = _fedCall;
    }

    // function to stake FED tokens
    function stake(uint256 _value) public {
        require(
            IERC20(fed).balanceOf(msg.sender) >= _value,
            "Insufficient token balance"
        );

        // transfer the FED tokens to the contract
        IERC20(fed).transfer(address(this), _value);

        // add the staked FED balance to the user's balance
        stakedBalance[msg.sender] += _value;

        // update the total staked FED balance
        totalStakedBalance += _value;

        // update the earning rate
        earningRate = calculateEarningRate();
    }

    // function to unstake FED tokens
    function unstake(uint256 _value) public {
        require(
            stakedBalance[msg.sender] >= _value,
            "Insufficient staked token balance"
        );

        // collect FEDCALL rewards
        collectFEDCALLRewards();

        // transfer the FED tokens back to the user
        IERC20(fed).transfer(msg.sender, _value);

        // subtract the staked FED balance from the user's balance
        stakedBalance[msg.sender] -= _value;

        // update the total staked FED balance
        totalStakedBalance -= _value;

        // update the earning rate
        earningRate = calculateEarningRate();
    }

    // function to collect FEDCALL rewards
    function collectFEDCALLRewards() public {
        // calculate the reward for the user
        uint256 reward = stakedBalance[msg.sender] * earningRate;

        // mint the FEDCALL tokens for the user
        AFEDCALL(fedCall).extMint(msg.sender, reward);

        // emit the FEDCALL reward event
        emit FEDCALLReward(msg.sender, reward);
    }

    // function to calculate the earning rate
    function calculateEarningRate() private view returns (uint256) {
        // get the total supply of the FED token from the FED contract
        uint256 totalSupply = IERC20(fed).totalSupply();
        // the earning rate is inversely proportional to the total staked FED balance
        return (totalSupply / totalStakedBalance);
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