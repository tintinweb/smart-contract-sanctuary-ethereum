/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

pragma solidity  0.5.12;

contract minter{
    address public minter;
    mapping(address => uint) public balances;
    constructor() public {
        minter = msg.sender;
    }
    function add (uint amount) public {
        require(msg.sender == minter , "You are not owner");
        balances[minter] += amount; 
    }
    function transfer (address sender , address receiver , uint amount) public {
        require(sender == msg.sender , "You are not have permission");
        require(balances[sender] >= amount , "Your balances is daun");
        balances[sender] -= amount;
        balances[receiver] += amount;
    }

}