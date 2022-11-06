//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IProxy {

    // Set new implementation address.
    function setImplementationAddress(address newAddress) external;

    // Return the current Implementation Address
    // ex. 0x976EA74026E726554dB657fA54763abd0C3a0aa9
    function getImplementationAddress() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IProxy.sol";

contract Proxy is IProxy{
    address implementationAddress;

    constructor(address implementationAddress_) {
        implementationAddress = implementationAddress_;
    }

    function setImplementationAddress(address newAddress) external override {
        implementationAddress = newAddress;
    }

    function getImplementationAddress() external view override returns (address) {
        return implementationAddress;
    }
}