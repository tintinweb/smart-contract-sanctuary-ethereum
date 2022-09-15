// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract BasicToken {
    string public name;
    string public symbol;
    uint256 private supplies;

    address owner;
    mapping(address => uint256) balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);

    constructor() {
        owner = msg.sender;
        name = "Basic Token";
        symbol = "BATK";
    }

    modifier onlyOnwer {
        require(msg.sender == owner);
        _;
    }

    function mint(address _to, uint256 _value) public onlyOnwer returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        supplies += _value;
        balances[_to] += _value;
        emit Mint(_to, _value);

        return true;
    }

    function totalSupply() public view returns (uint256) {
        return supplies;
    }

    function changeOwner(address _newOwner) public onlyOnwer {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] -= _value;
        supplies -= _value;

        emit Burn(burner, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value > 0);
        require(_to != address(0));
        require(_from != address(0));

        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}