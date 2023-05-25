// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Clones.sol";
import "./LondonTokenBase.sol";

contract LondonTokenFactory {
    address immutable tokenImplementation;

    constructor() {
        tokenImplementation = address(new LondonTokenBase());
    }

    function createCollection(
        string memory uri_,
        address minter_,
        address gatewayManager_,
        string memory contractName_,
        uint256 royaltyValue_
    ) external returns (address) {
        address clone = Clones.clone(tokenImplementation);
        LondonTokenBase(clone).initialize(uri_, minter_, gatewayManager_, contractName_, royaltyValue_);
        return clone;
    }
}