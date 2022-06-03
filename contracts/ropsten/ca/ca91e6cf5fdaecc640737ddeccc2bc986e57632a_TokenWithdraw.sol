// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

contract TokenWithdraw is Ownable {

    address public token;
    address public transferOperator; // Address to manage the Transfers

    // Modifiers
    modifier onlyOperator() {
        require(
            msg.sender == transferOperator, "Only operator can call this function."
        );
        _;
    }

    constructor(address _token) {
        token = _token;
        transferOperator = msg.sender;
    }

    // Events
    event NewTokenAndOperator(address token, address transferOperator);

    function updateTokenAndOperator(address newToken, address newOperator) public onlyOwner {

        require(newOperator != address(0), "Invalid operator address");
        require(newToken != address(0), "Invalid token address");
        
        transferOperator = newOperator;
        token = newToken;

        emit NewTokenAndOperator(token, transferOperator);
    }

    // To transfer tokens from Contract to address
    function batchTransfer(address to, uint256 amount) public onlyOperator 
    {
        IERC20 erc20 = IERC20(token);
        require(erc20.transfer(to, amount), "Unable to transfer token to the account");
    }


}