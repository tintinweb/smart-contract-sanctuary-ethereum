/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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


contract Pool {
    address token1;
    address token2;

    struct Stake_t {
        address user;
        uint256 stakedToken1Amount;
        uint256 stakedToken2Amount;
        uint256 totalRewardAmount;
        uint256 rewardTime;
    }

    Stake_t[] public stakers;  

    uint256 cooldownTime = 3 minutes;


    constructor (address _token1, address _token2) {
        token1 = _token1;
        token2 = _token2;
    }


    function getTotalBalance() public view returns(uint, uint) {
        uint token1Amount = IERC20(token1).balanceOf(address(this));
        uint token2Amount = IERC20(token2).balanceOf(address(this));

        return (token1Amount, token2Amount);
    }


    function stake(address _user, uint256 _token1Amount, uint256 _token2Amount) public returns(bool) {
        stakers.push(Stake_t(_user, _token1Amount, _token2Amount, 0, block.timestamp + cooldownTime));

        return true;
    }
    function divRewardForToken1(uint totalFee) private {
        for(uint i = 0; i < stakers.length; i++) {
            uint pros = stakers[i].stakedToken1Amount * 100 / IERC20(token1).balanceOf(address(this));
            stakers[i].totalRewardAmount += totalFee * pros / 100;
        }
    }
    function divRewardForToken2(uint totalFee) private {
        for(uint i = 0; i < stakers.length; i++) {
            uint pros = stakers[i].stakedToken2Amount * 100 / IERC20(token2).balanceOf(address(this));
            stakers[i].totalRewardAmount += totalFee * pros / 100;
        }
    }

    function withdrawReward() private {

    }
}