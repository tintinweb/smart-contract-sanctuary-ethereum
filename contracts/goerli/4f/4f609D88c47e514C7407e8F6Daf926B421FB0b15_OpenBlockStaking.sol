// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IKelePoolStaking {
    function depositV2(bytes32 source) external payable;
}

contract OpenBlockStaking {
    address keleProxyAddr;
    bytes32 public source;

    constructor(address _keleProxyAddr, string memory _source) {
        keleProxyAddr = _keleProxyAddr;
        source = stringToBytes32(_source);
    }

    function deposit() public payable {
        IKelePoolStaking(keleProxyAddr).depositV2{value: msg.value}(source);
    }

    function stringToBytes32(
        string memory _source
    ) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(_source, 32))
        }
    }
}