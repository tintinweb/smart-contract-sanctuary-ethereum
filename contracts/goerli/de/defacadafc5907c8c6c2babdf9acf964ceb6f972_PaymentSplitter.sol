/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/1Transfer.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract PaymentSplitter {
    address private owner;
    uint256 private surplus;
    mapping (IERC20 => uint256) private tokenSurplus;
    uint256 private constant ethDecimals = 18;

    constructor() {
        owner = msg.sender;
    }

    function getSurplus() public view returns (uint256) {
        require(msg.sender == owner, "Call is not the owner");
        return surplus;
    }

    function getTokenSurplus(IERC20 token) public view returns (uint256) {
        require(msg.sender == owner, "Call is not the owner");
        return tokenSurplus[token];
    }

    function withdrawSurplus() external {
        require(msg.sender == owner, "Call is not the owner");
        require(surplus > 0, "No surplus available");
        address payable own = payable(owner);
        own.transfer(surplus);
        surplus = 0;
    }

    function withdrawTokenSurplus(IERC20 token) external {
        require(msg.sender == owner, "Call is not the owner");
        require(tokenSurplus[token] > 0, "No surplus available for the given token");
        token.transfer(owner, tokenSurplus[token]);
        tokenSurplus[token] = 0;
    }

   function modulo(uint256 a, uint256 b) public pure returns (uint256) {
        require(b > 0, "Value can not be zero");
        require(a > b, "Divisible can not be less than divisor");
        return a % b;
    }

    function getUserTokenBalance(IERC20 token) public view returns (uint) {
        uint tokenBalance = token.balanceOf(msg.sender);
        return tokenBalance;
    }

    // Calculate the modular value into the 0.01 field of 1 eth.
    function calculateRemaining(uint amount, uint recipients, uint decimals) public pure returns (uint) {
        return modulo(amount, recipients * (10 **  decimals));
    }

    // Calculate an equal division value
    function calculatePayment(uint amount, uint recipients, uint decimals) public pure returns (uint256) {
        // Get the remaining value in a 0.01 field
        uint remaining = calculateRemaining(amount, recipients, decimals);
        // Remove this value from the total amount
        uint divisibleValue = amount - remaining;
        // Now we can properly divide the number without having floating points
        return divisibleValue / recipients;
    }

    /**
     * @dev Splits value between several users
     * Expects to recive a value bigger than the amount of recipients
     * Each recipient needs to be an address
     */
    function splitPayment(address[] memory recipients) public payable {
        // get the amount of recipients
        uint nrOfrecipients = recipients.length;
        // calculate how much each recipient will receive
        uint256 values = calculatePayment(msg.value, nrOfrecipients, ethDecimals - 4);
        uint256 index = 0;
        for (index = 0; index < nrOfrecipients; index++) {
            // convert each recipient and transfer them the amount
            address payable target = payable(recipients[index]);
            target.transfer(values);
        }
        // get the remaining and add it to the surplus
        uint256 remaining = calculateRemaining(msg.value, nrOfrecipients, ethDecimals - 4);
        surplus += remaining;
    }

    /**
     * @dev Splits an amount of tokens between several users
     * Expects to receive an amount bigger than the amount of recipients
     * Each recipient needs to be an address
     * The token needs to be an ERC20 token that implements the transfer, decimals and allowance methods
     * Token needs to have been approved to be used by this contract address
     */
    function splitTokenPayment(address[] memory recipients, uint256 amount, IERC20Metadata token) public {
        require(token.allowance(msg.sender, address(this)) >= amount, "Insuficient Allowance");
        require(token.transferFrom(msg.sender, address(this),amount), "Transfer Failed");

        uint nrOfrecipients = recipients.length;
        // see if the values has enough decimals to split evenly
        uint decimals = token.decimals();
        uint decimalsToDivide = decimals > 4 ? decimals - 2 : decimals;
        // calculate how much each recipient will receive
        uint256 values = calculatePayment(amount, nrOfrecipients, decimalsToDivide);
        uint256 index = 0;
        for (index = 0; index < nrOfrecipients; index++) {
            // transfer to each recipient the mentioned amount
            token.transfer(recipients[index], values);
        }

        // get the remaining and add it to the surplus
        uint256 remaining = calculateRemaining(amount, nrOfrecipients, decimalsToDivide);
        tokenSurplus[token] += remaining;
    }
}