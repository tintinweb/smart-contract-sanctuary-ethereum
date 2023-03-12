pragma solidity ^0.5.9;

import "./ERC20Interface.sol";
import "./OwnerHelper.sol";
import "./SafeMath.sol";

contract SightnGovernanceToken is ERC20Interface, OwnerHelper {
    using SafeMath for uint;

    string public name;
    uint public decimals;
    string public symbol;

    uint private constant E18 = 1000000000000000000;

    uint public totalTokenSupply;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public approvals;

    constructor() public {
        name = "Sightn Governance Token";
        decimals = 18;
        symbol = "SGT";

        totalTokenSupply = 1000000000 * E18;
        balances[owner] = totalTokenSupply;
    }

    function totalSupply() public view returns (uint) {
        return totalTokenSupply;
    }

    function balanceOf(address _who) public view returns (uint) {
        return balances[_who];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require(balances[msg.sender] >= _value);

        approvals[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint) {
        return approvals[_owner][_spender];
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) public returns (bool) {
        require(balances[_from] >= _value);
        require(approvals[_from][msg.sender] >= _value);

        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function transferAnyERC20Token(
        address tokenAddress,
        uint tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}