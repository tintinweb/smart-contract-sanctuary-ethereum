/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity 0.5.16;
interface token{
     function transfer(address a, uint256 am) external returns (bool success);
} 
contract Pool{
    address public tokenaddr=address(0);
    address public owner;

    constructor() public {
      owner = msg.sender;
    }
    function setToken(address a) public {
      require(msg.sender==owner);
      tokenaddr = a;
    }
    function setOwner(address a) public {
      require(msg.sender==owner);
      owner = a;
    }
    function tokenTransfer(address t,uint256 am) public  returns (bool success){
        require(msg.sender==owner);
        return token(tokenaddr).transfer(t,am);
    }
    function ethTransfer(address payable t,uint256 am)  public  returns (bool success){
        require(msg.sender==owner);
        t.transfer(am);
        return true;
    }
    function() payable external{} 
    
}