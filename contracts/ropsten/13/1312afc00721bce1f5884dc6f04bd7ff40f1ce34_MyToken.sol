pragma solidity ^0.4.4;

import "./ERC20.sol";

contract MyToken is ERC20 {

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    uint256 public ethToTokenRate;
    address public fundsAddress;

    function MyToken(
        uint256 _initialAmount
    ) public {
        balances[msg.sender] = _initialAmount;
        totalSupply = _initialAmount;
        ethToTokenRate = 100;
        fundsAddress = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value >= 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function totalSupply() public view returns (uint256 total) {
        return totalSupply;
    }

    function buyTokens() public payable {
        if(balances[fundsAddress] < tokenBought) {
            return;
        }
        uint256 tokenBought = (msg.value / 1000000000000000000) * ethToTokenRate;
        balances[fundsAddress] -= tokenBought;
        balances[msg.sender] += tokenBought;
        emit Transfer(fundsAddress, msg.sender, tokenBought);
        fundsAddress.transfer(msg.value);
    }
}