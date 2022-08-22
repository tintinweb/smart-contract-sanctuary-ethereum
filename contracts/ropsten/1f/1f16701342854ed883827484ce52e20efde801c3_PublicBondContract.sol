/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// File: contracts/IERC20.sol



pragma solidity ^0.8.0;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 quantity) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract PublicBondContract is IERC20 {
    using SafeMath for uint256;

    string public isin;
    uint256 public totalSupply_ = 0;
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;


   constructor(string memory  _isin) {
        isin = _isin;
        balances[msg.sender] = totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 quantity) public override returns (bool) {
        require(quantity <= balances[msg.sender], "Fail to transfer due to insufficient token quantity in your account.");
        
        balances[msg.sender] = balances[msg.sender].sub(quantity);
        balances[receiver] = balances[receiver].add(quantity);
        emit Transfer(msg.sender, receiver, quantity);
        return true;
    }

    function _mint(address account, uint256 quantity) public virtual {
        _beforeTokenTransfer(address(0), account, quantity);

        totalSupply_ += quantity;
        balances[account] += quantity;
        emit Transfer(address(0), account, quantity);

        _afterTokenTransfer(address(0), account, quantity);
    }

    function _burn(address account, uint256 quantity) public virtual {
        require(quantity <= balances[account], "Failed to burn token as it excides available token in your account.");
        _beforeTokenTransfer(address(0), account, quantity);

        totalSupply_ -= quantity;
        balances[account] -= quantity;
        emit Transfer(account, address(0), quantity);

        _afterTokenTransfer(address(0), account, quantity);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 quantity
    ) internal virtual {}
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}