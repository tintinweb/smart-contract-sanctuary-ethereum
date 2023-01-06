// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IModule {
    function setA(address impl) external ;

    function getA() external view returns (address);
}

contract Proxy {
    address internal immutable _MODULE;

    constructor(address module_) payable {
        _MODULE = module_;
    }

    function implementation() public view returns (address) {
        (bool success, bytes memory response) = _MODULE.staticcall(
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("getA()"))),
                address(this)
            )
        );

        if (success) {
            return abi.decode(response, (address));
        } else {
            return address(0);
        }
    }

    fallback() external {
        if (msg.sender == address(0)) {
            assembly {
                pop(delegatecall(gas(), 0, 0, 0, 0, 0))
            }
        }
    }
}