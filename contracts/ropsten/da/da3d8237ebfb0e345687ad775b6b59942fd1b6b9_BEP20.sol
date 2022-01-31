/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// File: contracts/libs/Safemath.sol

pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/libs/IBEP20.sol


pragma solidity ^0.8.0;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/BEP20.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;



contract BEP20 is IBEP20 {
     using SafeMath for uint256;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    address internal _owner;
    address public contractAddress;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

 constructor(){
     _name = "HEC PAY";
     _symbol = "HCP";
    _decimals = 18;
    _totalSupply = 1000 * 10 ** 18;
    _balances[msg.sender] = _totalSupply;
    _owner = msg.sender;
    contractAddress = address(this);
   }

 modifier Onlyowner {
     require(msg.sender==_owner,"Caller is not owner");
     _;
 }

 function name()external view returns(string memory){
     return _name;
 }

 function symbol()external view returns(string memory){
     return _symbol;
 }

 function decimals()external view returns(uint8){
     return _decimals;
 }

 function getOwner()external view returns(address) {
     return _owner;
 }

 function totalSupply()external view returns(uint256){
     return _totalSupply;
 }

 function transfer(address recipient,uint256 amount)external returns(bool){
    _transfer(msg.sender,recipient,amount);
    return true;
 }

 function transferFrom(address sender, address recipient, uint256 amount)external returns(bool){
     _transfer(sender,recipient,amount);
     _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount,"Allowance exceeded!"));
     return true;
 }

 function allowance(address owner_, address _spender)external view returns(uint){
     return _allowances[owner_][_spender];
 }

 function balanceOf(address _address)external view returns(uint256){
     return _balances[_address];
 }

 function approve(address spender_, uint256 _quantity)external returns(bool) {
     _approve(msg.sender,spender_,_quantity);
     return true;
 }

 function _approve(address owner_, address spender, uint256 amount)internal{
     _allowances[owner_][spender] = amount;
     emit Approval(owner_,spender,amount);
 }

 function _transfer(address sender_, address rec_, uint256 amount_)internal {
        _balances[sender_] = _balances[sender_].sub(amount_,"Insufficient balance");
        uint tax = 5;
        uint taxDen = 100;
        uint256 amountTotake = amount_.mul(tax.div(taxDen));
        uint256 amountTosend = amount_.sub(amountTotake);
       _balances[rec_] = _balances[rec_].add(amountTosend);
       _balances[contractAddress] = _balances[contractAddress].add(amountTosend);
       emit Transfer(sender_,rec_,amount_);
     }


}