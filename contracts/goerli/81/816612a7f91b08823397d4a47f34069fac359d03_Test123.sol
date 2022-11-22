// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.7;

interface Vm {

    function startBroadcast() external;

    function stopBroadcast() external;

}

contract Test123 {

    uint256 public value;

    function setValue(uint256 value_) external {
        value = value_;
    }

}

contract Test123Deployer {

    Vm vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external {
        vm.startBroadcast();

        Test123 test = new Test123();

        vm.stopBroadcast();
    }

}