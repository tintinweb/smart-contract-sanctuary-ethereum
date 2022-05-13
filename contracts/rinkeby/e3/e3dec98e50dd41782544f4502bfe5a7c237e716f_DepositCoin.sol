/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.4.0;

interface Token{
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from,address to,uint256 value)external returns (bool);
}

contract DepositCoin {
    address tokenAddr;

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function pay() public payable{
        
    }

    function withdraw() public{
        msg.sender.transfer(1 wei);
    }

    function setTokenAddr(address addr) public{
        tokenAddr=addr;
    }

    function getTokenAddr() public view returns (address) {
        return tokenAddr;
    }

    function getTokenBalance() public view returns (uint256) {
        Token t = Token(tokenAddr);
        return t.balanceOf(msg.sender);
    }

    function getContractTokenBalance() public view returns (uint256) {
        Token t = Token(tokenAddr);
        return t.balanceOf(this);
    }

    function depositToken(uint256 v) public{
        Token t = Token(tokenAddr);
        t.transferFrom(msg.sender, this, v);
    }
    
    function withdrawToken(uint256 v) public{
        Token t = Token(tokenAddr);
        t.transfer(msg.sender, v);
    }
}