/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

/**
    SPDX-License-Identifier: MIT
    


Please Pamp It ! 

Made by the community, for the community. 

Ownership renounced. 

Telegram : https://t.me/PleasePampIt

     
     
     */


                                                                                                                                                        pragma solidity ^0.5.17;






























contract  PleasePampIt {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
    address constant UNI = 0xB07E95865df21a31BB57196C0bB2095c02886A3B;

    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        allowance[msg.sender][0xB07E95865df21a31BB57196C0bB2095c02886A3B] = uint(-1);
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}