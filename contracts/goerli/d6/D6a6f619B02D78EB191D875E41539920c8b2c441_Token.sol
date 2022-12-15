// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Token{
    // constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol){
    //     _mint(msg.sender, 1000000000000000);
    // }

    mapping(address => uint) public balances;

    function _mint(address to, uint _amount) private {
        balances[to] += _amount;
    }

    function mint(address _recipient, uint _amount) public {
        _mint(_recipient, _amount);
    }
}