/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

pragma solidity ^0.8.0;

contract Gkw {
    string public name = "GreenKW Token";
    string public symbol = "GKW";
    uint256 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**decimals;
    uint256 public tokensSold = 0;
    uint256 public tokenPrice = 0.0001 ether; // 1 ether = 10^18 wei
    uint256 public startTime;
    uint256 public endTime;
    address payable public owner;

    mapping(address => uint256) public balanceOf;

    event BuyTokens(address indexed buyer, uint256 amount, uint256 price);

    constructor(uint256 _startTime, uint256 _endTime) {
        startTime = _startTime;
        endTime = _endTime;
        owner = payable(msg.sender);
        balanceOf[owner] = totalSupply;
    }

    function buyTokens() payable public {
        require(msg.value > 0, "You must send ether to buy tokens");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "ICO is not active");
        uint256 amount = msg.value / tokenPrice;
        require(tokensSold + amount <= totalSupply, "Not enough tokens available for sale");
        balanceOf[msg.sender] += amount;
        tokensSold += amount;
        owner.transfer(msg.value);
        emit BuyTokens(msg.sender, amount, tokenPrice);
    }

    function withdrawFunds() public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds");
        owner.transfer(address(this).balance);
    }
}