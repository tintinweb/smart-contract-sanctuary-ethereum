// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MetaTx1 {
    function forward(address _to, bytes calldata _data)
        external
        returns (bytes memory _result)
    {
        bool success;

        (success, _result) = _to.call(_data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}