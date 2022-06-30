/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

pragma solidity ^0.4.24;

contract ERC20{

    string public name = "Price Coin";
    string public symbol = "PEZ";
    uint256 public totalsupply;


    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 _value
    );


    constructor(uint256 _initialSupply)public {

        balanceOf[msg.sender] = _initialSupply;
        totalsupply = _initialSupply;
    }



    function transfer(address _to, uint256 _value) public returns (bool success){


        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender,_to,_value);
        return true;
    }





    function approve(address _spender, uint _value) public returns(bool success){

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }




}