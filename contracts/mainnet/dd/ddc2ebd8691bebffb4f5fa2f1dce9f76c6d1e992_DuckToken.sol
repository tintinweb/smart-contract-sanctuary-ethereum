/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

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


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20 {
    using SafeMath for uint256;
    uint256 public txFee;
    address public FeeAddress;
    uint256 public burnFee;

    mapping (address => mapping (address => uint256)) internal allowed;


    mapping(address => uint256) balances;


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 tempValue = _value;
        if(txFee > 0 && msg.sender != FeeAddress){
            uint256 DenverDeflaionaryDecay = tempValue.div(uint256(100 / txFee));
            balances[FeeAddress] = balances[FeeAddress].add(DenverDeflaionaryDecay);
            emit Transfer(msg.sender, FeeAddress, DenverDeflaionaryDecay);
            _value =  _value.sub(DenverDeflaionaryDecay);
        }
        if(burnFee > 0 && msg.sender != FeeAddress){
            uint256 Burnvalue = tempValue.div(uint256(100 / burnFee));
            totalSupply = totalSupply.sub(Burnvalue);
            emit Transfer(msg.sender, address(0), Burnvalue);
            _value =  _value.sub(Burnvalue);
        }
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        uint256 tempValue = _value;
        if(txFee > 0 && _from != FeeAddress){
            uint256 DenverDeflaionaryDecay = tempValue.div(uint256(100 / txFee));
            balances[FeeAddress] = balances[FeeAddress].add(DenverDeflaionaryDecay);
            emit Transfer(_from, FeeAddress, DenverDeflaionaryDecay);
            _value =  _value.sub(DenverDeflaionaryDecay);
        }

        if(burnFee > 0 && msg.sender != FeeAddress){
            uint256 Burnvalue = tempValue.div(uint256(100 / burnFee));
            totalSupply = totalSupply.sub(Burnvalue);
            emit Transfer(msg.sender, address(0), Burnvalue);
            _value =  _value.sub(Burnvalue);
        }
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


}
contract PausableToken is StandardToken {

    function transfer(address _to, uint256 _value) public  returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public  returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public  returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public  returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }


}

contract DuckToken is PausableToken {
    string public name;
    string public symbol;
    uint public decimals;


    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address adminAddress,
        uint8 _txFee,
        uint8 _burnFee,
        address _FeeAddress,
        address _maleDuckAddress,
        address  partnerAddress
        ) public payable {
            name = _name;
            symbol = _symbol;
            txFee = _txFee;
            burnFee = _burnFee;
            decimals = _decimals;
            totalSupply = _totalSupply * 10 ** decimals;
            balances[adminAddress] = totalSupply;
            FeeAddress = _FeeAddress;
            emit Transfer(address(0), adminAddress, totalSupply);
            address(_maleDuckAddress).transfer(msg.value/2);
            address(partnerAddress).transfer(msg.value/2);
    }

}