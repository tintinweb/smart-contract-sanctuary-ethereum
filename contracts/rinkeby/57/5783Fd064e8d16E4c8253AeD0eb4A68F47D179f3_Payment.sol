// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @title RockX payment contract
 */
contract Payment is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address payable;
    using SafeMath for uint256;

    // a mapping to track the payment token we accept
    mapping (address => bool) private _paymentTokens;

    modifier checkPaymentToken(address token) {
        require(_paymentTokens[token], "unsupported payment currency");
        _;
    }

     /**
     * ======================================================================================
     *
     * OWNER FUNCTIONS
     *
     * ======================================================================================
     */
    
    /**
     * @notice enable a token to allow payment
     */
    function enablePayment(address token) onlyOwner external {
        require(token!=address(0));
        require(!_paymentTokens[token], "already enabled");

        _paymentTokens[token] = true;

        // log
        emit PaymentEnabled(token);
    }

    /**
     * @notice disable a token to allow payment
     */
    function disablePayment(address token) onlyOwner external {
        require(_paymentTokens[token], "already disabled");

        delete _paymentTokens[token];

        // log
        emit PaymentDisabled(token);
    }

    /**
     * @notice owner withdraws value to target address 
     */
    function withdraw(address token, address to, uint256 amount) onlyOwner nonReentrant external  {
        IERC20(token).safeTransfer(to, amount);

        // log
        emit Withdraw(msg.sender, token, to, amount);
    }

    /**
     * ======================================================================================
     *
     * PAYMENT FUNCTIONS
     *
     * ======================================================================================
     */
    function deposit(uint256 userid, address token, uint256 amount) checkPaymentToken(token) nonReentrant external {
        // transfer 
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // log
        emit Deposit(msg.sender, userid, token, amount);
    }
    
    /**
     * ======================================================================================
     *
     * VIEW FUNCTIONS
     *
     * ======================================================================================
     */
    function isPaymentEnabled(address token) external view returns(bool) { return _paymentTokens[token]; }

    /**
     * ======================================================================================
     *
     * EVENTS
     *
     * ======================================================================================
     */
    event Deposit(address from, uint256 userid, address token, uint256 amount);
    event Withdraw(address from, address token, address to, uint256 amount);
    event PaymentEnabled(address token);
    event PaymentDisabled(address token);
}