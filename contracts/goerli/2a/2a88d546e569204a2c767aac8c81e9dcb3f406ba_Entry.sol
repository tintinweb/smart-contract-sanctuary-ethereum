/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract Target {
    mapping (address => uint256) public aMapping;

    function setValue(uint256 _value) public {
        aMapping[msg.sender] = _value;
    }

    function selfDestruct(address _addr) public {
        selfdestruct(payable(_addr));
    }
}


contract Intermediate {
    address public targetAddr;
    Target public target;

    function setTarget(address _target) public {
        targetAddr = _target;
        target = Target(targetAddr);
    }

    function relayAndSetValue(uint256 _value) public {
        target.setValue(_value);
    }
}


contract Entry {
    Intermediate public intermediate;

    constructor (address _intermediate) {
        intermediate = Intermediate(_intermediate);
        relayAndSetTarget(address(0xdead));
    }

    function createTarget() public returns (address) {
        bytes32 salt = keccak256(abi.encode(0xbadda));
        bytes memory bytecode = type(Target).creationCode;
        bytes memory initCode = abi.encodePacked(bytecode); // ...args
        address _address;
        assembly {
          
            _address := create2(0, add(initCode, 0x20), mload(initCode), salt)

            if iszero(extcodesize(_address)) {
                revert(0, 0)
            }
        }
        relayAndSetTarget(_address);
        return _address;
    }

    function relayAndSetTarget(address _target) public {
        intermediate.setTarget(_target);
    }
    

    function doubleRelayAndSetValue(uint256 _value) public {
        intermediate.relayAndSetValue(_value);
    }

    function destroyTarget() public {
        Target target = Target(intermediate.targetAddr());
        target.selfDestruct(address(this));
    }
}