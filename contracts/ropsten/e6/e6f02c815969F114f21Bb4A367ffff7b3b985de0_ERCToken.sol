/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.5.16;

contract ERCToken{

    
    string public constant name =" RapidSwap1";
    string public constant symbol ="RIS1";
    uint public constant decimal =18;
    uint public  totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address =>uint)) public Approved; 

    function _mint(address to, uint value) public {
        totalSupply += value;
        balanceOf[to] += value; 
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
    }

    function approve(address owner,address spender, uint value)internal returns(bool){
        require(balanceOf[owner]>=value);
        Approved[owner][spender]=value;
        return(true);
    }

    function transfer(address to, uint value) public {
        require(totalSupply >= value);
         balanceOf[msg.sender] -=value;
        balanceOf[to] += value;
        totalSupply -= value;
    }

    function transferFrom(address from ,address to, uint value) internal{
        require(balanceOf[from] >= value);
        require(Approved[from][msg.sender] >= value);
        balanceOf[from] -= value;
        balanceOf[to] += value;
    }
    event checkgetbal(address owner);
    function getbal(address owner)external  returns(uint){
        emit checkgetbal(owner);
    return(balanceOf[owner]);

    }

    function getsymbol() public pure returns(string memory){
        return(symbol);
    }

    
}