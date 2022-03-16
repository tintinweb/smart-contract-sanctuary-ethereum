// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma abicoder v2;

contract MultiCall {
    function multicall(address target, bytes[] calldata data)
        external
        view
        returns (bytes[] memory)
    {
        bytes[] memory results = new bytes[](data.length);

        for (uint i; i < data.length; i++) {
            (bool success, bytes memory result) = target.staticcall(data[i]);
            require(success, "call failed");
            results[i] = result;
        }
        return results;
    }
    function gg() public returns (bytes memory)
    {
        return abi.encodeWithSignature("unpause()");
    }
}