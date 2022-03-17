/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
     event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed owner, address indexed spender, uint256 value);



    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

abstract contract ERC20 is IERC20 {
    string _name;
    string _symbol;
    uint _totalSupply;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;

    constructor(string memory name_,string memory symbol_,uint totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
    }

    function name() public  override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

     function totalSupply() public override view returns (uint) {
         return _totalSupply;
     }

    function balanceOf(address _owner) public override view returns (uint balance) {
         return _balances[_owner];
      }
    function transfer(address _to, uint _value) public override returns (bool success) {
        _transfer(msg.sender, _to , _value);
        return true;
    }
     function approve(address _spender, uint _value) public override returns (bool success) {
            _approve(msg.sender,_spender,_value);
            return true;
     }

     function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
         return _allowances[_owner][_spender];
     }
     function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
            if (_from != msg.sender) {
              uint allowanceValue =  _allowances[_from] [msg.sender];
              require(_value <= allowanceValue,"transfer value exceeds allowance");
              _approve(_from , msg.sender, allowanceValue - _value);
            }
            _transfer(_from , _to , _value);
            return true;
     }

      ///=== private Function =====

      function _transfer(address from, address to,uint value) internal {
          require(from != address(0),"transfer from zero address");
          require(to != address(0),"transfer to zero address");
          require(value <= _balances[from],"transfer value exceeds balance");
          
          _balances[from] -= value;
          _balances[to]  += value;

          emit Transfer(from,to,value);
      }

      function _approve(address owner , address spender , uint value) internal {
            require(owner != address(0),"approve from zero address");
            require(spender != address(0),"approve spender zero address");
            
            _allowances[owner] [spender] =value;

            emit Approval(owner, spender , value);
      }
}
contract Free is ERC20 {
    constructor() ERC20("Free Coin","Free",10000000000000000000000000) {

    }
}