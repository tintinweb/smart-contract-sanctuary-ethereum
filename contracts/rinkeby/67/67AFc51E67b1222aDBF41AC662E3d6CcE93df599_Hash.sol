// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
pragma abicoder v2;

contract Hash {
    constructor() {}

    function hash(string calldata _input) external pure returns (bytes32) {
        return keccak256((abi.encode(_input)));
    }

    function hashes(string[] calldata _inputs)
        external
        pure
        returns (bytes32[] memory)
    {
        require(
            _inputs.length > 0,
            "Hash: input shoud have at least one element."
        );
        bytes32[] memory _outputs = new bytes32[](_inputs.length);
        for (uint256 i = 0; i < _inputs.length; i++) {
            _outputs[i] = keccak256((abi.encode(_inputs[i])));
        }
        return _outputs;
    }
}