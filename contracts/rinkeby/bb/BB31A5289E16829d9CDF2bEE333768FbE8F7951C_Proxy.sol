/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

//SPDX-License-Identifier: Innopolis

pragma solidity 0.8.1;

abstract contract Upgradeable {
    mapping(bytes4 => uint32) _sizes;
    address _dest;

    function initialize() virtual public ;

    function replace(address target) public {
        _dest = target;
        target.delegatecall(abi.encodeWithSelector(bytes4(keccak256("initialize()"))));
    }
}

contract Proxy is Upgradeable {

    constructor(address target) {
        replace(target);
    }

    function initialize() override pure public{
        // Should be called by on target contracts only, not on the proxy
        assert(false);
    }
    
    function getLogicContract() public view returns (address) {
        return _dest;
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
            return(0, len) //throw away any return data
        }
    }
}

contract Box is Upgradeable {
    uint value;

    function initialize() override public {
        _sizes[bytes4(keccak256("getUint()"))] = 32;
    }

    function getUint() public view returns (uint) {
        return value;
    }

    function setUint(uint _value) public {
        value = _value;
    }
}