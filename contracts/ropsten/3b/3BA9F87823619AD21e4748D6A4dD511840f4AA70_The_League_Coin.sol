pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Token.sol";

contract The_League_Coin is ERC20, Ownable {
    using SafeMath for uint256;

    constructor(address team) ERC20("The League Coin", "TLC") {
        _mint(team, 21e24);
        canTransferBeforeTradingIsEnabled[team] = true;
        isThisContractCanTrade[0xC36442b4a4522E871399CD717aBDD847Ab11FE88] = true;
        transferOwnership(team);
    }
    
    // Function to enable token trading..
    function enabledTrading() public onlyOwner {
        require(!isTradingEnabled, "TLC: Trading alredy enabled..");
        isTradingEnabled = true;
    }
    
    // Function to allow admin to add wallet to transfer token before trading enabled..
    function addWallets(address account, bool value) public onlyOwner {
        canTransferBeforeTradingIsEnabled[account] = value;
    }
    
    // Function to allow admin to add or remove approver..
    function addRemoveApprover(address account, bool value) public onlyOwner {
        require(isApprover[account] != value, "TLC: The address have the same value..");
        isApprover[account] = value;
    }
    
    // Function to allow admin to add or remove pairs..
    function addRemovePair(address pair, bool value) public onlyOwner {
        require(isPair[pair] != value, "TLC: The address have the same value..");
        isPair[pair] = value;
        isBlacklisted[pair] = false;
        isThisContractCanTrade[pair] = true;
    }
    
    // Function to allow admin to add or remove pairs..
    function AddRemoveFromBlacklist(address account, bool value) public onlyOwner {
        require(isBlacklisted[account] != value, "TLC: The address have the same value..");
        require(isContract(account), "TLC: You can blacklist only bot..");
        isBlacklisted[account] = false;
    }
    
    // Function to allow admin to add smart contract fo trading..
    function addRemoveSmartContract(address account, bool value) public onlyOwner {
        require(isThisContractCanTrade[account] != value, "TLC: The address have the same value..");
        require(isContract(account), "TLC: You can add only smart contract bot..");
        isThisContractCanTrade[account] = value;
    }
    
    // Function to burn token, only owner can call this function..
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public {
        require(amount > 0, "TLC: amount must be greater than 0");
        require(recipient != address(0), "TLC: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
}