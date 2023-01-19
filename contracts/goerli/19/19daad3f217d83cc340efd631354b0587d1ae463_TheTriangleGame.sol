/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

pragma solidity ^0.8.0;

contract TheTriangleGame {
    //Fixed supply of 10,987,654,321
    mapping(address => uint256) public balanceOf;
    string public constant symbol = "TTG";
    string public constant name = "The Triangle Game";
   // decimals
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10987654321000000000000000000;

    //No minting
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    //Transfer tokens
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }

    //Check balance
    function checkBalance(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

    // Limited supply
    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;
    }

    // No pause trading or blacklist
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address owner;

    receive() external payable {
        require(msg.value == 0);
    }
}