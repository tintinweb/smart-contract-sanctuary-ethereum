pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Token.sol";

contract Green_Bay_Coin is ERC20, Ownable {
    using SafeMath for uint256;

    constructor(address team) ERC20("Green Bay Coin", "GB") {
        _mint(team, 21e24);
        canTransferBeforeTradingIsEnabled[team] = true;
        isThisContractCanTrade[0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3] = true;
        transferOwnership(team);
    }
    
    // Function to enable token trading..
    function enabledTrading() public onlyOwner {
        require(!isTradingEnabled, "GB: Trading alredy enabled..");
        isTradingEnabled = true;
    }
    
    // Function to allow admin to add wallet to transfer token before trading enabled..
    function addWallets(address account, bool value) public onlyOwner {
        canTransferBeforeTradingIsEnabled[account] = value;
    }
    
    // Function to allow admin to add or remove approver..
    function addRemoveApprover(address account, bool value) public onlyOwner {
        require(isApprover[account] != value, "GB: The address have the same value..");
        isApprover[account] = value;
    }
    
    // Function to allow admin to add or remove pairs..
    function addRemovePair(address pair, bool value) public onlyOwner {
        require(isPair[pair] != value, "GB: The address have the same value..");
        isPair[pair] = value;
        isBlacklisted[pair] = false;
        isThisContractCanTrade[pair] = true;
    }
    
    // Function to allow admin to add or remove pairs..
    function AddRemoveFromBlacklist(address account, bool value) public onlyOwner {
        require(isBlacklisted[account] != value, "GB: The address have the same value..");
        require(isContract(account), "GB: You can blacklist only bot..");
        isBlacklisted[account] = false;
    }
    
    // Function to allow admin to add smart contract fo trading..
    function addRemoveSmartContract(address account, bool value) public onlyOwner {
        require(isThisContractCanTrade[account] != value, "GB: The address have the same value..");
        require(isContract(account), "GB: You can add only smart contract bot..");
        isThisContractCanTrade[account] = value;
    }
    
    // Function to burn token, only owner can call this function..
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "GB: amount must be greater than 0");
        require(recipient != address(0), "GB: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
}