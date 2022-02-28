/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

pragma solidity >=0.4.22 <0.9.0;

/* Standard from https://eips.ethereum.org/EIPS/eip-20 */
/* Background from https://www.toptal.com/ethereum/create-erc20-token-tutorial */
/* EXTRA */

contract RoJo {
  string public constant name = "RoJo";
  string public constant symbol = "ROJO";
  uint8 public constant decimals = 8;

  // Account balances.
  mapping (address => uint256) balance;
  // Each address can withdraw a certain balance from its approved addresses.
  mapping (address => mapping (address => uint256)) approvals;
  // Amount of tokens in the network.
  uint256 private supply;

  constructor(uint256 _initialSupply) public {
    supply = _initialSupply;
    balance[msg.sender] = supply;
  }

  event Approval(address indexed _from, address indexed _to, uint256 _value);
  event Transfer(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() public view returns (uint256) {
    return supply;
  }

  function balanceOf(address _owner) public view returns (uint) {
    return balance[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(balance[msg.sender] >= _value);

    balance[msg.sender] -= _value;
    balance[_to] += _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (msg.sender != _from) {
      require(allowance(_from, msg.sender) >= _value);
    }

    require(balance[_from] >= _value);

    approvals[msg.sender][_from] -= _value;

    balance[_from] -= _value;
    balance[_to] += _value;

    emit Transfer(_from, _to, _value);

    return true;
  }

  function approve(address _spender, uint256 _value)  public returns (bool) {
    approvals[_spender][msg.sender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint) {
    return approvals[_spender][_owner];
  }
}