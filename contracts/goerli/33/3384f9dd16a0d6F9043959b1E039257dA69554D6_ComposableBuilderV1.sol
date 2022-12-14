// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IBuilders } from "./IBuilders.sol";

contract ComposableBuilderV1 {
    address public gmr;
    address[] public builders;

    constructor (address _gmr, address[] memory _builders) {
        gmr = _gmr;
        require(_builders.length == 3);
        builders = _builders;
    }

    function create721 (string calldata name) external returns (address) {
        return IBuilders(builders[0]).create721(name, gmr);
    }

    function create1155 (string calldata name) external returns (address) {
        return IBuilders(builders[1]).create1155(name, gmr);
    }

    function createCondensed (string calldata name) external returns (address) {
        return IBuilders(builders[2]).createCondensed(name, gmr);
    }

    function _setGMR (address _gmr) external {
        gmr = _gmr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBuilders {
    function create721 (string calldata name, address gmr) external returns (address);
    function create1155 (string calldata name, address gmr) external returns (address);
    function createCondensed (string calldata name, address gmr) external returns (address);
}