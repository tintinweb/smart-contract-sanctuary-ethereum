// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;


interface ISigner {

    function setAgentSigner(address signer) external;

    function setUp(bytes memory initParams) external;

}

contract DelaySignerFactory {
    event ModuleProxyCreation(
        address indexed proxy,
        address indexed masterCopy
    );

    uint256 internal _saltCounter;

    function createProxy(address target, bytes32 salt)
        internal
        returns (address result)
    {
        require(
            address(target) != address(0),
            "createProxy: address can not be zero"
        );
        bytes memory deployment = abi.encodePacked(
            hex"602d8060093d393df3363d3d373d3d3d363d73",
            target,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := create2(0, add(deployment, 0x20), mload(deployment), salt)
        }
        require(result != address(0), "createProxy: address already taken");
    }

    function deployModule(
        address masterCopy,
        address owner,
        address avatar,
        address target,
        uint256 cooldown,
        uint256 expiration,
        address agentSigner
    ) public returns (address proxy) {

        bytes memory initializer = abi.encode(owner, avatar, target, cooldown, expiration);

        proxy = createProxy(
            masterCopy,
            keccak256(abi.encodePacked(keccak256(initializer), _saltCounter))
        );

        ISigner(proxy).setAgentSigner(agentSigner);

        ISigner(proxy).setUp(initializer);

        emit ModuleProxyCreation(proxy, masterCopy);

        _saltCounter++;
    }
}