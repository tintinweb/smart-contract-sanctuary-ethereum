/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

pragma solidity ^0.8.7;
//@SPDX-License-Identifier: UNLICENSED
// v1.0: inital design
// v1.1: save SLOAD by using immutable keyword
// v1.2: use calldata instead of memory
// invis was here

interface RocketStorage {
    function getBool(bytes32 key) external view returns (bool);
}

contract EventEmitter {
    RocketStorage public immutable rocketStorage;

    constructor(address _rocketStorage) {
        rocketStorage = RocketStorage(_rocketStorage);
    }

    event Event(address indexed callee, string metadata);

    function emitEvent(string calldata metadata) public onlyRegisteredMember {
        emit Event(msg.sender, metadata);
    }

    modifier onlyRegisteredMember() {
        require(rocketStorage.getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", msg.sender))), "Wallet is not a registered trusted node");
        _;
    }
}