// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library Creator {

    event Source(address indexed sender, address indexed source);
    event Created(address indexed sender, address indexed source, address indexed destination);

    function create(bytes memory sourceAddressOrBytecode) external returns(address destination, address source) {
        if(sourceAddressOrBytecode.length == 32) {
            source = abi.decode(sourceAddressOrBytecode, (address));
        } else if(sourceAddressOrBytecode.length == 20) {
            assembly {
                source := div(mload(add(sourceAddressOrBytecode, 32)), 0x1000000000000000000000000)
            }
        } else {
            assembly {
                source := create(0, add(sourceAddressOrBytecode, 32), mload(sourceAddressOrBytecode))
            }
            emit Source(msg.sender, source);
        }
        require(source != address(0), "source");
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(source)
        }
        require(codeSize > 0, "source");
        destination = address(new GeneralPurposeProxy{value : msg.value}(source));
        emit Created(msg.sender, source, destination);
    }
}

contract GeneralPurposeProxy {

    constructor(address source) payable {
        assembly {
            sstore(0xf7e3126f87228afb82c9b18537eed25aaeb8171a78814781c26ed2cfeff27e69, source)
        }
    }

    fallback() external payable {
        assembly {
            let _singleton := sload(0xf7e3126f87228afb82c9b18537eed25aaeb8171a78814781c26ed2cfeff27e69)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch success
                case 0 {revert(0, returndatasize())}
                default { return(0, returndatasize())}
        }
    }
}