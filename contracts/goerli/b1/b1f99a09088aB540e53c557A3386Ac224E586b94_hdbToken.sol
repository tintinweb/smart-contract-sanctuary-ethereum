// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract hdbToken {
    string public name;
    string public symbol;
    uint8 public decimal;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    event TokensRedeemed(address indexed _from, uint _value);
    address public hdbAddress;

    constructor(){
        name = "Simple Token";
        symbol = "ST";
        decimal = 18;
        totalSupply = 1000000 * (10 ** uint256(decimal));
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }

    function redeemTokens(address _user, uint _value) public onlyHDB {
        require(balanceOf[_user] >= _value && _value > 0);
        balanceOf[_user] -= _value;
        totalSupply -= _value; // burn the tokens
        emit TokensRedeemed(_user, _value);
    }

    function getBalanceOf(address _owner) public view returns (uint balance) {
        return balanceOf[_owner];
    }
    modifier onlyHDB() {
        require(msg.sender == hdbAddress);
        _;
    }
}