// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract rateLimit {
    mapping(address => uint256) public rate; //tracks amount sent for the last timeLimit time
    mapping(address => uint256) public timestamp; //tracks most recent send
    uint256 public timeLimit = 3600; //how long in seconds to limit within, recommend 1h = 3600
    uint16 public rateLimit = 1000; //the basis points (00.0x%) to allow as the max sent within the last timeLimit time

    //updates the time as well as the relative amount in basis points to track and rate limit outflows in which to track
    //_rateLimit = 00.x%, _timeLimit = time in seconds
    function updateLimits(uint16 _rateLimit, uint256 _timeLimit) internal {
        rateLimit = _rateLimit;
        timeLimit = _timeLimit;
    }

    //used to replace ERC20 erc20token.transfer() and ETH address.transfer() fns in all public accessible fns which change the balances for the contract as outflow transactions.
    //to used for the recipient address, amount for value amount in raw value, token as the tokens contract address to check, for ETH use address(0x0)
    function transferL(
        address to,
        uint256 amount,
        address token
    ) internal {
        //used if the asset is ETH and not an ERC20 token
        if (address(token) == address(0)) {
            //used to get around solidity 0.8 reverts
            unchecked {
                //checks to see if the last transaction was outside the time window to track outflow for limiting
                if (timeLimit <= block.timestamp - timestamp[token]) {
                    rate[token] = 0;
                }
                //if the last transaction was within the time window, decreases the tracked outflow rate relative to the time elapsed, so that the limit is able to update in realtime rather than in blocks, making flows smooth, and increasing the rate available as time increases without a transaction
                else {
                    rate[token] -=
                        (address(this).balance * rateLimit) /
                        (timeLimit / (block.timestamp - timestamp[token])) /
                        10000;
                }
            }
            //increases the tracked rate for the current time window by the amount sent out
            rate[token] += amount;
            //revert if the outflow exceeds rate limit
            require(rate[token] <= (rateLimit * address(this).balance) / 10000);
            //sets the current time as the last transfer for the token
            timestamp[token] = block.timestamp;
            //transfers out
            payable(to).transfer(amount);
            //if the token is a ERC20 token
        } else {
            //used to get around solidity 0.8 reverts
            unchecked {
                //checks to see if the last transaction was outside the time window to track outflow for limiting
                if (timeLimit <= block.timestamp - timestamp[token]) {
                    rate[token] = 0;
                }
                //if the last transaction was within the time window, decreases the tracked outflow rate relative to the time elapsed, so that the limit is able to update in realtime rather than in blocks, making flows smooth, and increasing the rate available as time increases without a transaction
                else {
                    rate[token] -=
                        (IERC20(token).balanceOf(address(this)) * rateLimit) /
                        (timeLimit / (block.timestamp - timestamp[token])) /
                        10000;
                }
                //increases the tracked rate for the current time window by the amount sent out
                rate[token] += amount;
                //revert if the outflow exceeds rate limit
                require(
                    rate[token] <=
                        (rateLimit * IERC20(token).balanceOf(address(this))) /
                            10000
                );
                //sets the current time as the last transfer for the token
                timestamp[token] = block.timestamp;
                //transfers out
                IERC20(token).transfer(to, amount);
            }
        }
    }
}