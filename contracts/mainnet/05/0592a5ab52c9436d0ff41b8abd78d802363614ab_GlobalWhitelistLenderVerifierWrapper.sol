// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ILenderVerifier {
    function isAllowed(address lender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IGlobalWhitelistLenderVerifier {
    function isAllowed(
        address lender,
        uint256 amount,
        bytes memory signature
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILenderVerifier} from "ILenderVerifier.sol";
import {IGlobalWhitelistLenderVerifier} from "IGlobalWhitelistLenderVerifier.sol";

contract GlobalWhitelistLenderVerifierWrapper is ILenderVerifier {
    IGlobalWhitelistLenderVerifier public immutable globalWhitelistLenderVerifier;

    constructor(IGlobalWhitelistLenderVerifier _globalWhitelistLenderVerifier) {
        globalWhitelistLenderVerifier = _globalWhitelistLenderVerifier;
    }

    function isAllowed(address lender) external view returns (bool) {
        return globalWhitelistLenderVerifier.isAllowed(lender, 0, new bytes(0));
    }
}