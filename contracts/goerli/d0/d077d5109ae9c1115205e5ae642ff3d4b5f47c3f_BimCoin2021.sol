/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.8.0;

contract BimCoin2021 {
    address public minter;
    mapping (address => uint256) public balances;
    
    uint8 public decimals = 18;
    string public symbol = "BIM3";                
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    constructor() {
        minter = msg.sender;
    }

    function name() public pure returns (string memory) { 
        return "BimCoin2021-3"; 
    }
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function mint(address receiver, uint256 amount) public {
        if (msg.sender != minter) revert("only minter can mint");
        balances[receiver] += amount;
    }
    
    function transfer(address receiver, uint256 amount) public returns (bool success) {
        if (balances[msg.sender] < amount) revert("insufficient funds");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }
}