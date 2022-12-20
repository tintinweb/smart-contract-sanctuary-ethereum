// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract ModuleProxyFactory {
    event ModuleProxyCreation(
        address indexed proxy,
        address indexed masterCopy
    );

    /// `target` can not be zero.
    error ZeroAddress(address target);

    /// `address_` is already taken.
    error TakenAddress(address address_);

    /// @notice Initialization failed.
    error FailedInitialization();

    function createProxy(address target, bytes32 salt)
        internal
        returns (address result)
    {
        if (address(target) == address(0)) revert ZeroAddress(target);
        bytes memory deployment = abi.encodePacked(
            hex"602d8060093d393df3363d3d373d3d3d363d73",
            target,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := create2(0, add(deployment, 0x20), mload(deployment), salt)
        }
        if (result == address(0)) revert TakenAddress(result);
    }

    function deployModule(
        address masterCopy,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (address proxy) {
        proxy = createProxy(
            masterCopy,
            keccak256(abi.encodePacked(keccak256(initializer), saltNonce))
        );
        (bool success, ) = proxy.call(initializer);
        if (!success) revert FailedInitialization();

        emit ModuleProxyCreation(proxy, masterCopy);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;
import {ModuleProxyFactory} from "@gnosis.pm/zodiac/contracts/factory/ModuleProxyFactory.sol";

contract Deployer {
    ModuleProxyFactory public immutable PROXY_FACTORY;

    address public immutable TEMPLATE;

    constructor(address _template, address _factory) {
        PROXY_FACTORY = ModuleProxyFactory(_factory);
        TEMPLATE = _template;
    }

    function create(string memory _value) external returns (address proxy) {
        proxy = PROXY_FACTORY.deployModule(
            TEMPLATE,
            abi.encodeWithSignature("setUp(bytes)", abi.encode(_value)),
            0 // salt
        );
    }
}