// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";

// https://github.com/rstormsf/multisender/blob/master/contracts/contracts/multisender/UpgradebleStormSender.sol
// https://github.com/singnet/batch-token-transfer/blob/main/contracts/TokenBatchTransfer.sol

contract TokenBatchTransfer is Ownable {
    
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
    event WithdrawToken(address indexed owner, uint256 stakeAmount);
    event TokenBatchSend(uint256 total, address tokenAddress);


    function updateTokenAndOperator(address newToken, address newOperator) public onlyOwner {

        require(newOperator != address(0), "Invalid operator address");
        require(newToken != address(0), "Invalid token address");
        
        transferOperator = newOperator;
        token = newToken;

        emit NewTokenAndOperator(token, transferOperator);
    }

    // To transfer tokens from Contract to the provided list of token holders with respective amount
    function tokenBatch(address[] calldata tokenHolders, uint256[] calldata amounts) public onlyOperator 
    {
        require(tokenHolders.length == amounts.length, "Invalid input parameters");
        uint256 total = 0;
        ERC20 erc20 = ERC20(token);
        for(uint256 indx = 0; indx < tokenHolders.length; indx++) {
            require(erc20.transfer(tokenHolders[indx], amounts[indx]), "Unable to transfer token to the account");
            total += amounts[indx];
        }
        emit TokenBatchSend(total, token);
    }

}