// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardsSystem {

    uint totalSupply;
    IERC20 allowedToken;

    struct TokenInfo {
        uint value;
        uint lastRewardSentAt;
        bool exists;
    }

    mapping(address => TokenInfo) accountsStakedTokens;

    constructor(address _allowedTokenAddress) {
        allowedToken = IERC20(_allowedTokenAddress);
    }

    function stake(uint _amount) public {
        require(_amount > 0, "Amount must be greater than zero!!!");

        uint transferAmount = _amount;

        TokenInfo memory currentTokenInfo = accountsStakedTokens[msg.sender];
        allowedToken.transferFrom(msg.sender, address(this), transferAmount);

        accountsStakedTokens[msg.sender] = TokenInfo(
            currentTokenInfo.exists ? (_amount + currentTokenInfo.value) : _amount,
            block.timestamp,
            true
        );

        totalSupply += _amount;
    }

    function withdraw(uint _amount) public {
        require(_amount > 0, "Amount must be greater than zero!!!");
        require(_amount <= accountsStakedTokens[msg.sender].value, "Withdrawal amount exceeds balance!!!");

        allowedToken.transfer(msg.sender, _amount);
        // TokenInfo storage currentTokenInfo = accountsStakedTokens[msg.sender];

        accountsStakedTokens[msg.sender] = TokenInfo(
            100, // currentTokenInfo.value - _amount,
            block.timestamp, // currentTokenInfo.lastRewardSentAt,
            true
        );

        totalSupply -= _amount;
    }

    function claimReward() public returns (uint) {
        TokenInfo memory currentTokenInfo = accountsStakedTokens[msg.sender];

        require(currentTokenInfo.exists, "Account has not staked any token!!!");
        require(
            (currentTokenInfo.lastRewardSentAt + 1 weeks) < block.timestamp,
            "Cannot withdraw currently!!!"
        );

        uint reward = currentTokenInfo.value / 100;
        totalSupply += reward;

        accountsStakedTokens[msg.sender] = TokenInfo(
            currentTokenInfo.value,
            block.timestamp,
            true
        );

        // allowedToken.transfer(msg.sender, reward);
        return reward;
    }

    function getStakedTokens() public view returns (uint) {
        TokenInfo memory currentTokenInfo = accountsStakedTokens[msg.sender];

        require(currentTokenInfo.exists, "Account has not staked any token!!!");
        return currentTokenInfo.value;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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