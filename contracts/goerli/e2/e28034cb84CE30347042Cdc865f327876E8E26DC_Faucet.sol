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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Faucet {
    uint public timeout = 12*60*60; // 12h

    address payable public owner;

    mapping(address => uint) public timeouts;

    // restriction storage
    enum RestrictionMode { NONE, TIMEOUT, AUTHORIZED }
    RestrictionMode public restrictionMode;
    mapping(address => bool) private _authorizedUsers;


    event FaucetFundedNative(address user, uint256 amount);
    event FaucetWithdrawnNative(address user, uint256 amount);
    event FaucetFundedToken(address token, address user, uint256 amount);
    event FaucetWithdrawnToken(address token, address user, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        restrictionMode = RestrictionMode.NONE;
    }

    modifier _onlyOwner() {
        require(msg.sender == owner, "Function restricted to owner only");

        _;
    }

    modifier _percentage(uint8 percentage) {
        require(percentage < 100, "Cannot request more than 100% funds");
        require(percentage > 0, "Requesting no funds is not allowed");

        _;
    }

    modifier _restricted(address user) {
        if(restrictionMode == RestrictionMode.TIMEOUT) {
            _timeRestricted(user);
        } else if(restrictionMode == RestrictionMode.AUTHORIZED) {
            _authorizationRestricted(user);
        }

        _;
    }

    function _timeRestricted(address user) private {
        if(timeouts[user] == 0 || timeouts[user] < block.timestamp) {
            timeouts[user] = block.timestamp + timeout;
        } else {
            require(timeouts[user] < block.timestamp, "Too soon");
        }
    }

    function _authorizationRestricted(address user) private view {
        require(_authorizedUsers[user], "Unauthorized");
    }

    function setTimeout(uint newTimeout) external _onlyOwner {
        require(newTimeout > 0, "New timeout must be greater than 0");
        timeout = newTimeout;
    }

    function changeOwner(address payable newOwner) external _onlyOwner {
        owner = newOwner;
    }

    function authorize(address user, bool enabled) external _onlyOwner {
        _authorizedUsers[user] = enabled;
    }

    function setRestrictionMode(RestrictionMode mode) external _onlyOwner {
        restrictionMode = mode;
    }

    function donateNative() public payable {
        emit FaucetFundedNative(msg.sender, msg.value);
    }

    function requestNative(address payable to, uint8 percentage) external
        _percentage(percentage)
        _restricted(to)
    {
        require(to != address(0), "Receiver address is 0");
        require(address(this).balance > 0, "Not enough funds");

        uint amount = address(this).balance * percentage / 100;
        to.transfer(amount);
        emit FaucetWithdrawnNative(to, amount);
    }

    function donateToken(address token, uint256 amount) external {
        require(token != address(0), "ERC20: token address is 0");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit FaucetFundedToken(token, msg.sender, amount);
    }

    function requestToken(address token, address payable to, uint8 percentage) external
        _percentage(percentage)
        _restricted(to)
    {
        require(token != address(0), "ERC20: token address is 0");
        require(to != address(0), "Receiver address is 0");

        IERC20 tokenObj = IERC20(token);
        uint amount = tokenObj.balanceOf(address(this)) * percentage / 100;
        require(amount > 0, "Not enough funds");

        tokenObj.transfer(to, amount);
        emit FaucetWithdrawnToken(token, to, amount);
    }

    function balanceOf(address token) external view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

}