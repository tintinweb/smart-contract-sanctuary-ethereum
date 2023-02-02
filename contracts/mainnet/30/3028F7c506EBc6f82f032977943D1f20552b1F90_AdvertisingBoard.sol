// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IOpsProxyFactory} from "./IOpsProxyFactory.sol";

contract AdvertisingBoard {
    IOpsProxyFactory public constant opsProxyFactory =
        IOpsProxyFactory(0x370BC2D643637F4eC19F6cbA5244c8EA6146a6D9);

    mapping(address => string) public messages;

    function postMessage(string calldata _message) external {
        messages[msg.sender] = _message;
    }

    function viewMessage(address _eoa) external view returns (string memory) {
        (address dedicatedMsgSender, ) = opsProxyFactory.getProxyOf(_eoa);

        return messages[dedicatedMsgSender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpsProxyFactory {
    /**
     * @notice Emitted when an OpsProxy is deployed.
     *
     * @param deployer Address which initiated the deployment
     * @param owner The address which the proxy is for.
     * @param proxy Address of deployed proxy.
     */
    event DeployProxy(
        address indexed deployer,
        address indexed owner,
        address indexed proxy
    );

    /**
     * @notice Emitted when OpsProxy implementation to be deployed is changed.
     *
     * @param oldImplementation Previous OpsProxy implementation.
     * @param newImplementation Current OpsProxy implementation.
     */
    event SetImplementation(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    /**
     * @notice Emitted when OpsProxy implementation is added or removed from whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelisted Added or removed from whitelist.
     */
    event UpdateWhitelistedImplementation(
        address indexed implementation,
        bool indexed whitelisted
    );

    /**
     * @notice Deploys OpsProxy for the msg.sender.
     *
     * @return proxy Address of deployed proxy.
     */
    function deploy() external returns (address payable proxy);

    /**
     * @notice Deploys OpsProxy for another address.
     *
     * @param owner Address to deploy the proxy for.
     *
     * @return proxy Address of deployed proxy.
     */
    function deployFor(address owner) external returns (address payable proxy);

    /**
     * @notice Sets the OpsProxy implementation that will be deployed by OpsProxyFactory.
     *
     * @param newImplementation New implementation to be set.
     */
    function setImplementation(address newImplementation) external;

    /**
     * @notice Add or remove OpsProxy implementation from the whitelist.
     *
     * @param implementation OpsProxy implementation.
     * @param whitelist Added or removed from whitelist.
     */
    function updateWhitelistedImplementations(
        address implementation,
        bool whitelist
    ) external;

    /**
     * @notice Determines the OpsProxy address when it is not deployed.
     *
     * @param account Address to determine the proxy address for.
     */
    function determineProxyAddress(address account)
        external
        view
        returns (address);

    /**
     * @return address Proxy address owned by account.
     * @return bool Whether if proxy is deployed
     */
    function getProxyOf(address account) external view returns (address, bool);

    /**
     * @return address Owner of deployed proxy.
     */
    function ownerOf(address proxy) external view returns (address);

    /**
     * @return bool Whether if implementation is whitelisted.
     */
    function whitelistedImplementations(address implementation)
        external
        view
        returns (bool);
}