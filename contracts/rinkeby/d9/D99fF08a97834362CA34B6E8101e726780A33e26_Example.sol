// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Upgradeable {
    mapping(bytes4 => uint32) _sizes;
    address _dest;

    function initialize() virtual public ;

    function replace(address target) public returns(bool,bytes memory){
        _dest = target;
        (bool success, bytes memory returndata) = target.delegatecall{ gas: 10000 }(abi.encodeWithSelector(bytes4(keccak256("initialize()"))));
        return(success,returndata);
    }
}

contract Dispatcher is Upgradeable {

    constructor(address target) {
        replace(target);
    }

    function initialize() override pure public{
        // Should only be called by on target contracts, not on the dispatcher
        assert(false);
    }

    fallback() external {
        bytes4 sig;
        assembly { sig := calldataload(0) }
        uint len = _sizes[sig];
        address target = _dest;

        assembly {
            // return _dest.delegatecall(msg.data)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(sub(gas(), 10000), target, 0x0, calldatasize(), 0, len)
            return(0, len) //we throw away any return data
        }
    }
}

contract Example is Upgradeable {
    uint _value;

    function initialize() override public {
        _sizes[bytes4(keccak256("getUint()"))] = 32;
    }

    function getUint() public view returns (uint) {
        return _value + 5;
    }

    function setUint(uint value) public {
        _value = value;
    }
}