pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./ERC1967Proxy.sol";

// This contract doesn't change the bytecode of ERC1967Proxy. It exists solely to make it compatible with hardhat-deploy plugin.
// https://github.com/wighawag/hardhat-deploy/issues/146#issuecomment-907755963

// Kept for backwards compatibility with older versions of Hardhat and Truffle plugins.
contract WavpointCreatorProxy is ERC1967Proxy {
    
    constructor(
        address _logic,
        address,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {}
}