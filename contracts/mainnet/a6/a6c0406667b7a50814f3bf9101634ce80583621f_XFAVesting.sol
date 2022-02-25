// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract XFAVesting {
    address immutable private wallet;
    address immutable private token;
    uint256 immutable private tokenListingDate;
    uint256 private tokensWithdrawn;
   
    event onUnlockNewTokens(address _user, uint256 _maxTokensUnlocked);
    event onEmergencyWithdraw();

    constructor(address _token, uint256 _listingDate) {
        token = _token;
        tokenListingDate = _listingDate;
        wallet = msg.sender;
    }

    function unlockTokens() external {
        require(tokenListingDate > 0, "NoListingDate");
        require(block.timestamp >= tokenListingDate + 360 days, "NotAvailable");

        uint256 maxTokensAllowed = 0;
        uint256 initTime = tokenListingDate + 360 days;
        if ((block.timestamp >= initTime) && (block.timestamp < initTime + 90 days)) {
            maxTokensAllowed = 18750000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 90 days) && (block.timestamp < initTime + 180 days)) {
            maxTokensAllowed = 37500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 180 days) && (block.timestamp < initTime + 270 days)) {
            maxTokensAllowed = 56250000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 270 days) && (block.timestamp < initTime + 360 days)) {
            maxTokensAllowed = 75000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 360 days) && (block.timestamp < initTime + 450 days)) {
            maxTokensAllowed = 92500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 450 days) && (block.timestamp < initTime + 540 days)) {
            maxTokensAllowed = 110000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 540 days) && (block.timestamp < initTime + 630 days)) {
            maxTokensAllowed = 127500000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 630 days) && (block.timestamp < initTime + 720 days)) {
            maxTokensAllowed = 145000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 720 days) && (block.timestamp < initTime + 810 days)) {
            maxTokensAllowed = 170000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 810 days) && (block.timestamp < initTime + 900 days)) {
            maxTokensAllowed = 195000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 900 days) && (block.timestamp < initTime + 990 days)) {
            maxTokensAllowed = 220000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 990 days) && (block.timestamp < initTime + 1080 days)) {
            maxTokensAllowed = 245000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1080 days) && (block.timestamp < initTime + 1170 days)) {
            maxTokensAllowed = 270000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1170 days) && (block.timestamp < initTime + 1260 days)) {
            maxTokensAllowed = 295000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1260 days) && (block.timestamp < initTime + 1350 days)) {
            maxTokensAllowed = 320000000 * 10 ** 18;
        } else if ((block.timestamp >= initTime + 1350 days) && (block.timestamp < initTime + 1440 days)) {
            maxTokensAllowed = 345000000 * 10 ** 18;
        }

        maxTokensAllowed -= tokensWithdrawn;
        require(maxTokensAllowed > 0, "NoTokensToUnlock");

        tokensWithdrawn += maxTokensAllowed;
        require(IERC20(token).transfer(wallet, maxTokensAllowed));

        emit onUnlockNewTokens(msg.sender, maxTokensAllowed);
    }

    function getTokensInVesting() external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function emegercyWithdraw() external {
        require(msg.sender == wallet, "OnlyOwner");

        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(wallet, balance);

        emit onEmergencyWithdraw();
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