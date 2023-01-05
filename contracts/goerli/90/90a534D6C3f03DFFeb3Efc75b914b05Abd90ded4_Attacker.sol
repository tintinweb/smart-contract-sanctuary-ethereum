/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface Contract {
    function attempt() external;
}

contract Attacker {
    
    event Triggered(address sender);

    fallback() external {
        Contract(msg.sender).attempt();
        emit Triggered(msg.sender);
    }

    function attack(address c) public {
        (bool success,) = c.call("0x0001");
        require(success);
    }


}