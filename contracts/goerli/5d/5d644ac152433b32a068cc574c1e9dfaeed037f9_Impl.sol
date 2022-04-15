/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IProxy {
    function setGreeting(uint value) external;
}

contract Test {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }
    function test(uint value) public {
        IProxy(proxy).setGreeting(value);
    }
}

contract Proxy {
    event log(string  values);
    address public impl; //这里应该指定插槽，这里简化了。

    constructor(address _impl) {
        impl = _impl;
    }

    fallback () external payable virtual {
        emit log("in proxy fallback");
        _delegate(impl);
    }


    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

contract Impl {
    address public impl_address; //未使用，用来防止插槽共享冲突
    address public caller;
    event log(string  values);

    //演示获取的msg.sender及相应数据
    fallback () external payable virtual {
        emit log("in impl fallback");
        caller = msg.sender;
        bytes memory data = msg.data;
        uint value = toUint256(data,4);
        emit log("value:");
        deal(value);
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 32 >= _start, 'toUint256_overflow');
        require(_bytes.length >= _start + 32, 'toUint256_outOfBounds');
        uint24 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }
        return tempUint;
    }

    function deal(uint value) internal {
        emit log("in impl deal function:");
    }
}