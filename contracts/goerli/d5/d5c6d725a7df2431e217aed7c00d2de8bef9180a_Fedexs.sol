//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract TokenTMT is ERC20 {

uint256 initialSupply = 1000000;
    constructor() ERC20("TreMT", "TMT") {
        _mint(msg.sender, initialSupply);
    }
}

contract Fedexs is TokenTMT, Ownable{

    TokenTMT myToken;
    uint256 public tokensPerEther = 10;

    event Bought(address buyer, uint256 amount);
    event Sold(address vendor, uint256 amount);

    constructor(address tokenAddress) {
       myToken = TokenTMT(tokenAddress);
    }

    
    function buy() payable public returns (uint256 Amount) {
        uint256 amount = msg.value * tokensPerEther;
        uint256 dexBalance = myToken.balanceOf(address(this));
        require(amount > 0, "You need to send some ether");
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        (bool sent) = myToken.transfer(msg.sender, amount);
        require(sent, "Failed to transfer token to user");
        emit Bought(msg.sender, amount);
        return amount;
    }

    function sell(uint256 amount) public {
        require(amount > 0, "Specify an amount of token greater than zero");
        uint256 allowance = myToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        uint256 amountOfEtherToTransfer = amount / tokensPerEther;
        uint256 ownerEtherBalance = address(this).balance;
        require(ownerEtherBalance >= amountOfEtherToTransfer, "Vendor has insufficient funds");
        (bool sent) = myToken.transferFrom(msg.sender, address(this), amount);
        require(sent, "Failed to transfer tokens from user to vendor");
        payable(msg.sender).transfer(amount);
        emit Sold(msg.sender, amount);
    }


    function withdraw() public onlyOwner {
         uint256 ownerBalance = address(this).balance;
         require(ownerBalance > 0, "No Ether present in Vendor");
         (bool sent,) = msg.sender.call{value: address(this).balance}("");
         require(sent, "Failed to withdraw");
    }

}