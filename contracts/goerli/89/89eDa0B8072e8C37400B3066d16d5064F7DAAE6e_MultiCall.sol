// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma abicoder v2;

contract MultiCall {
    function multicall(address target, bytes[] calldata data)
        public
        returns (bytes[] memory)
    {
        bytes[] memory results = new bytes[](data.length);

        for (uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = target.call(data[i]);
            require(success, "call failed");
            results[i] = result;
        }
        return results;
    }
}