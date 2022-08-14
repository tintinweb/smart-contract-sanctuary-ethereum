// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ISimpleToken.sol";

contract SimpleToken is Ownable, ISimpleToken {
    // to know who has how many tokens
    mapping(address => uint256) public coinBalance;

    // to allow other user to spend some amount of our balance
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public frozenAccount;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenAccount(address target, bool frozen);

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        mint(owner, _initialSupply);
    }

    function transfer(address _to, uint256 _amount) public virtual override {
        require(_to != address(0x0));
        require(coinBalance[msg.sender] > _amount);
        require(coinBalance[_to] + _amount > coinBalance[_to]);
        
        coinBalance[msg.sender] -= _amount;
        coinBalance[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
    }

    function authorize(address _authrizedAccount, uint256 _allowance) public returns(bool success) {
        allowance[msg.sender][_authrizedAccount] += _allowance;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual returns(bool success) {
        require(_to != address(0x0));
        require(coinBalance[msg.sender] > _amount);
        require(coinBalance[_to] + _amount > coinBalance[_to]);
        require(_amount <= allowance[_from][msg.sender]);

        coinBalance[_from] -= _amount;
        coinBalance[_to] += _amount;

        allowance[_from][msg.sender] -= _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function mint(address _recipient, uint256 _amount) onlyOwner public override {
        coinBalance[_recipient] += _amount;
        emit Transfer(owner, _recipient, _amount);
    }

    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        emit FrozenAccount(_target, _freeze);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISimpleToken {
    function mint(address _recipient, uint256 _amount) external;
    function transfer(address _to, uint256 amount) external;
}