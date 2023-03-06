// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IKelePoolStaking {
    function depositV2(bytes32 source) external payable;

    function createValidatorV2(
        uint8 role,
        bytes32 source,
        bytes calldata pubkeys,
        bytes calldata withdrawal_credentials,
        bytes calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable;
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

    function createValidator(
        uint8 _role,
        bytes memory _pubkeys,
        bytes memory _withdrawal_credentials,
        bytes memory _signatures,
        bytes32[] memory _deposit_data_roots
    ) public payable {
        IKelePoolStaking(keleProxyAddr).createValidatorV2{value: msg.value}(
            _role,
            source,
            _pubkeys,
            _withdrawal_credentials,
            _signatures,
            _deposit_data_roots
        );
    }

    function stringToBytes32(
        string memory _source
    ) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(_source, 32))
        }
    }
}