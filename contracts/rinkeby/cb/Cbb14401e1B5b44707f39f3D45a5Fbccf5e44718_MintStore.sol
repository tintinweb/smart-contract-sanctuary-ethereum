// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol"; 
/*
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
*/
import "./IMintable.sol";

/**
 * @title Badium ERC20 Token MintStore
 * @author John R. Kosinski
 * 
 * @dev This contract handles only the selling and minting functionality of the Badium token. 
 * I prefer to keep the logic of commerce loosely coupled from the core logic of what the 
 * ERC20 is. 
 * 
 * The MintStore is coupled to the Badium token by calling the Badium token contract's 
 * setDesignatedMinter method, and passing in the address of the MintStore. In the future 
 * another contract could be substituted for this one without needing to break the core Badium 
 * logic. This relies on Badium implementing { IMintable }. 
 * 
 * See the README for more details. 
 * 
 * - Any address can buy tokens. 
 * 
 * - Only contract owner may withdraw funds from this contract. 
 * 
 * - The IMintable (token) address is specified on construction and cannot be changed.
 * 
 * - This contract may only mint an IMintable for which it has been granted permission 
 * to mint. Therefore permission is two-way; this contract must hold the address of the 
 * IMintable, and the IMintable must allow this contract to be a minter. 
 * 
 * - This contract can be disabled by revoking its permissions to mint, on the token contract.
 * Pausing the token contract will also effectively disable purchasing/minting.
 */
contract MintStore is Ownable {
    IMintable public token; //address of token to sell
    uint256 public price;   //price per token to charge 
    uint256 public totalPurchased;
    
    /**
     * @dev Emits when a purchase is made. 
     * 
     * @param buyer Address of the purchaser. 
     * @param quantity The number of tokens successfully purchased. 
     */
    event TokenPurchase(
        address indexed buyer, 
        uint256 quantity 
    );
    
    error FailedWithdraw();
    
    /**
     * @dev Emits when a withdrawal of funds is made by the owner of the contract. 
     * 
     * @param amount The amount withdrawn. 
     */
    event Withdrawal(
        uint256 amount 
    );
    
    /**
     * @dev Error thrown when either a purchase is not supplied enough funds to complete, 
     * or a withdrawal is requested that cannot be completed because of insufficient funds.
     * 
     * @param needed The amount required. 
     * @param actual The insufficient amount available or supplied. 
     */
    error InsufficientAmount(
        uint256 needed, 
        uint256 actual
    );
    
    /**
     * @dev Constructor. 
     * 
     * @param tokenAddress Address of the Badium (or any IMintable) token. 
     * @param _price The price to charge per token minted. 
     */
    constructor(address tokenAddress, uint256 _price) {
        token = IMintable(tokenAddress);
        price = _price;
    }
    
    /**
     * @dev Allows anyone to buy a certain number of Badium tokens for a certain price. 
     * 
     * Emits {TokenPurchase} event. 
     * 
     * Requirements: 
     * - reverts {InsufficientAmount} if the provided amount of ether is not sufficient 
     * for the purchase. 
     * - calls { Badium-mint }
     * 
     * @param quantity The number of tokens to purchase. 
     */
    function buyTokens(uint256 quantity) external payable {
        //calculate price 
        uint256 minPrice = (price * quantity);
        
        //make sure that enough funds were passed in
        if (msg.value < minPrice)
            revert InsufficientAmount(minPrice, msg.value); 
        
        //mint to caller
        totalPurchased += quantity;
        token.mint(msg.sender, quantity); 
        
        //emit 
        emit TokenPurchase(msg.sender, quantity);
    }
    
    /**
     * @dev Allows the owner to withdraw an amount of funds that have accumulated from 
     * user purchases. 
     * 
     * Emits {Withdrawal} event. 
     * 
     * Requirements:
     * - {amount} must be greater than the current balance in the contract
     * - reverts if the transfer to the caller fails for any reason
     * 
     * @param amount The amount to withdraw. 
     */
    function withdraw(uint256 amount) external onlyOwner {
        //check balance against amount
        if (address(this).balance < amount) 
            revert InsufficientAmount(amount, address(this).balance);
        
        //transfer the amount
        (bool success,) = owner().call{value:amount}("");
        
        //check the result 
        if (!success) 
            revert FailedWithdraw();
        
        //emit 
        emit Withdrawal(amount);
    }
}