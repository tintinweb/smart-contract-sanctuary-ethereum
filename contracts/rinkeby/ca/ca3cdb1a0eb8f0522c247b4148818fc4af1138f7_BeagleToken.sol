/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity ^0.4.24;

/*
*   A smart contract for Fax Token(ERC20 Standard Token).
*   Fax Token was a digital token that published in Ethereum Network (Main/Test network).
*   Fax Token has a total fixed number of 210,000,000.
*
*   Version: 1.0.0
*   Update Time: 2019/04/17
*
*/
contract BeagleToken {

    string public name = "Beagle Token";
    string public symbol = "BG";
    string public standard = "Beagle Token v1.0.0";
    uint256 public totalSupply = 210000000;
    address public owner;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor () public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }
}