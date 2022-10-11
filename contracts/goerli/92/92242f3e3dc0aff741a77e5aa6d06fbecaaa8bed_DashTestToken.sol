/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract DashTestToken {

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public  _Name = '';
    string public  _Symbol = '';
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;
    uint256 formatNumberOfTokens;

    //constructor(uint256 total) {
    constructor(string memory name, string memory symbol, uint256 total) {
      _Name = name;
      _Symbol = symbol;
      totalSupply_ = total * 10 ** 18;
      balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        formatNumberOfTokens = numTokens * 10 ** 18;
        require( formatNumberOfTokens <= balances[msg.sender]);
        balances[msg.sender] -= formatNumberOfTokens;
        balances[receiver] += formatNumberOfTokens;
        emit Transfer(msg.sender, receiver, formatNumberOfTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed [owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        formatNumberOfTokens = numTokens * 10 ** 18;
        require(formatNumberOfTokens <= balances[owner]);
        require(formatNumberOfTokens <= allowed[owner][msg.sender]);
        balances[owner] -= formatNumberOfTokens;
        allowed[owner][msg.sender] -= formatNumberOfTokens;
        balances[buyer] += formatNumberOfTokens;
        emit Transfer(owner, buyer, formatNumberOfTokens);
        return true;
    }

    // function burn(uint256 numTokens) public {
    //     formatNumberOfTokens = numTokens * 10 ** 18;
    //     _burn(msg.sender, formatNumberOfTokens);
    // }

    // function _burn(address account, uint256 amount) internal virtual {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     //_beforeTokenTransfer(account, address(0), amount);

    //     uint256 accountBalance = balances[account];
    //     require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    //     unchecked {
    //         balances[account] = accountBalance - amount;
    //     }
    //     totalSupply_ -= amount;

    //     emit Transfer(account, address(0), amount);

    //     //_afterTokenTransfer(account, address(0), amount);
    // }

}