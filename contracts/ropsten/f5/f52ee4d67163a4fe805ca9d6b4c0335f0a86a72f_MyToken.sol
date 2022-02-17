/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

//SPDX-License-Identifier: MIT;
pragma solidity >=0.8.0;

contract MyToken {
    string  constant public name = "[Echo]";//constant: should be initialized when defined, can not be changed
    string  constant public symbol = "!";
    string  constant public standard = "v1.0";
    uint256 immutable public totalSupply;//immutable: must be set inside constructor, after set can't be changed
    uint8   immutable public decimal;//num of digits

    event Transfer(
        address indexed _from,//filtering subscription purpose, eg only interested in money transfered from my own account
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

    constructor (uint256 _initialSupply, uint8 _decimal) {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        decimal = _decimal;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {//can be called be anyone/smart contract; external: function can only be callled by people,can not by sc; internal: only by this sc or inherited sc; private: only inside this sc.
        require(balanceOf[msg.sender] >= _value, "Insufficient amount.");//alarm message

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);// emit event so user receive notification/alert upon asset-related event

        return true;// equal to "success = true". (bool success)
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;//allown how much value for someone else to spend [owner][spender]= value

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;
        //defualt behavior if we don't have _to address
        //balanceOf[msg.sender] += _value;

        balanceOf[_to] += _value;

        allowance[_from][msg.sender] -= _value;// update allowance
         //defualt behavior if we don't have _to address
        //emit Transfer(_from, msg.sender, _value);

        emit Transfer(_from, _to, _value);

        return true;
    }
}