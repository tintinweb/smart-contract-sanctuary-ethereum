/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// contract to test different contract failures processing
contract FailedStateTestContract {
    function triggerAssert() public {
        assert(false);
    }

    function triggerRequire() public {
        require(false, "Test tx failed require");
    }

    function triggerRevert() public {
        revert("Test tx revert");
    }
}