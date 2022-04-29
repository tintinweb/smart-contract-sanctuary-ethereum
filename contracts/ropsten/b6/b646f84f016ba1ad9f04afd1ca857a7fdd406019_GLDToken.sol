// SPDX-License-Identifier: ISC

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.4.13;

import "./ERC20.sol";

contract GLDToken is ERC20 {
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) balances;
    uint256 public constant decimals = 18;

    string public constant name = "Project GLD Token";
    string public constant symbol = "GLD";


    /* Total mint amount, in tokens (will be reached when all UTXOs are redeemed). */
    uint256 public  totalSupply = 2000000 *(10**decimals);

  function totalSupply() public view returns (uint256){
   return 2000000 *(10**decimals);   
  }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender]- _value;
    balances[_to] = balances[_to]+_value;
    Transfer(msg.sender, _to, _value);
    return true;
  }



    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from]-_value;
        balances[_to] = balances[_to]+_value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender]-_value;
        Transfer(_from, _to, _value);
        return true;
    }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.4.26;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}