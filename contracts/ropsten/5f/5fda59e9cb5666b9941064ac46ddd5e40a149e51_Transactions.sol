/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;

contract Transactions {

    uint public  transactionCount ; 
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    mapping(address => uint256) private _balances;


    constructor() {
        _name = "DAT-T";
        _symbol = "DAT-T";
        _totalSupply = 100000*10**decimals();
        _balances[msg.sender] = _totalSupply;
    }



     function _msgSender()public  view  returns (address) {
        return msg.sender;
    }


    function name() public view  returns (string memory) {
        return _name;
    }
      function symbol() public view   returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }
     function decimals() public view   returns (uint8) {
        return 18;
    }

  function balanceOf(address account) public view   returns (uint256) {
        return _balances[account];
    }
    


    function transfer(address to, uint256 amount) public   returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal  {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
      _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        transactionCount+=1;
        emit Transfer(from, to, amount);
    }

  function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;

    }

    event Transfer(address from , address receiver , uint amount );

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
    }
}