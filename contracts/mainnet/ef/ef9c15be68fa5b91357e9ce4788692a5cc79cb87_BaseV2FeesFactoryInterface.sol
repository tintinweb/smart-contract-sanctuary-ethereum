// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract BaseV2FeesFactoryInterface {
    function childInterfaceAddress()
        external
        view
        returns (address _childInterface)
    {}

    function childSubImplementationAddress()
        external
        view
        returns (address _childSubImplementation)
    {}

    function createFees() external returns (address fees) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function interfaceSourceAddress() external view returns (address) {}

    function updateChildInterfaceAddress(address _childInterfaceAddress)
        external
    {}

    function updateChildSubImplementationAddress(
        address _childSubImplementationAddress
    ) external {}
}