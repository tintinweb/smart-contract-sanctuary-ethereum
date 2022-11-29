// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

contract MinimalProxyFactory {
    event ProxyCreated(address indexed _proxy);

    function createProxy(
        address _implementation,
        bytes32 _salt,
        bytes memory _data
    ) public virtual returns (address addr) {
        bytes32 salt = keccak256(abi.encodePacked(_salt, msg.sender));

        // solium-disable-next-line security/no-inline-assembly
        bytes memory slotcode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            _implementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );

        assembly {
            addr := create2(0, add(slotcode, 0x20), mload(slotcode), salt)
        }

        require(
            addr != address(0),
            "MinimalProxyFactory#createProxy: CREATION_FAILED"
        );

        if (_data.length > 0) {
            (bool success, ) = addr.call(_data);
            require(success, "MinimalProxyFactory#createProxy: CALL_FAILED");
        }

        emit ProxyCreated(addr);
    }
}