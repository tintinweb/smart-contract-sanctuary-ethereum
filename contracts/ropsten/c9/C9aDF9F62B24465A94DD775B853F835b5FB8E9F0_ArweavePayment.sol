/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Get a link to ERC20 contract
interface IERC20 {
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
 * @title Arweave Payment Version 1.0
 *
 * @author Agora-labs
 */
contract ArweavePayment {
    //---Set of addresses---//
    address public admin;
    address public immutable treasury;
    address public immutable paymentToken;

    /// @dev Content Id -> amount of paymentToken received
    mapping(bytes => uint256) public amountReceived;

    /**
     * @dev Fired in transferAdminship() when adminship is transferred
     *
     * @param previousAdmin an address of previous admin
     * @param newAdmin an address of new admin
     */
    event AdminshipTransferred(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Fired in pay() when amount for content is paid
     *
     * @param payer an address of payer
     * @param id content id for which amount is paid
     * @param amount paymentToken amount received for given content id 
     */
    event Paid(address indexed payer, bytes indexed id, uint256 amount);

    /**
     * @dev Creates/deploys Arweave Payment Version 1.0
     *
     * @param admin_ address of admin
     * @param admin_ address of treasury
     * @param paymentToken_ address of paymentToken
     */
    constructor(
        address admin_,
        address treasury_,
        address paymentToken_
    )
    {
        //---Setup smart contract internal state---//
        admin = admin_;
        treasury = treasury_;
        paymentToken = paymentToken_;
    }

    /**
     * @dev Transfer adminship to given address
     *
     * @notice restricted function, should be called by admin only
     * @param newAdmin_ address of new owner
     */
    function transferAdminship(address newAdmin_) external {
        require(msg.sender == admin, "Only admin can transfer ownership");

        // Update admin address
        admin = newAdmin_;
    
        // Emit an event
        emit AdminshipTransferred(msg.sender, newAdmin_);
    }

    /**
     * @dev Pays paymentToken to host content on arweave
     *
     * @param contentId_ content id for which amount is paid
     * @param amount_ paymentToken amount to be paid for given content id 
     */
    function pay(bytes calldata contentId_, uint256 amount_) external {
        // Transfer paymentToken amount to treasury address
        IERC20(paymentToken).transferFrom(msg.sender, treasury, amount_);
        
        // Record received amount to given content id
        amountReceived[contentId_] += amount_;
        
        // Emit an event
        emit Paid(msg.sender, contentId_, amount_);
    }

    /**
     * @dev Withdraw Funds
     *
     * @param token_ address of ERC20 token to withdraw
     */
    function withdraw(address token_) external {
        require(msg.sender == admin, "Only admin can withdraw funds");

	    // Value to send
	    uint256 _value = IERC20(token_).balanceOf(address(this));

	    // Verify balance is positive (non-zero)
	    require(_value > 0, "zero balance");

	    // Send the entire balance to the transaction sender
	    IERC20(token_).transfer(msg.sender, _value);
    }
}