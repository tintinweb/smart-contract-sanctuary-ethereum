// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Factory {
    event Created(address indexed addr);

    function create(
        bytes memory code,
        uint256 salt,
        bytes calldata data
    ) external returns (address) {
        address addr;

        bytes32 newsalt = keccak256(abi.encodePacked(salt, msg.sender));

        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), newsalt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        if (data.length > 0) {
            (bool success, ) = addr.call(data);
            if (!success) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        emit Created(addr);

        return addr;
    }
}