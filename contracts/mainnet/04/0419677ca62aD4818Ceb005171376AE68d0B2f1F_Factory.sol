// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Factory {
    event Created(address indexed created);

    function create(
        bytes memory code,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        address created;

        assembly {
            created := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(created)) {
                revert(0, 0)
            }
        }

        if (initData.length > 0) {
            (bool success, ) = created.call(initData);
            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        emit Created(created);

        return created;
    }
}