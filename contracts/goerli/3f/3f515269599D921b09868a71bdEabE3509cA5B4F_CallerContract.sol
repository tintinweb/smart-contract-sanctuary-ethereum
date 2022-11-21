// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGatekeeperOne.sol";

contract CallerContract {
    IGatekeeperOne public gatekeeperOne;

    bytes8 key = 0x0000000100001684;

    constructor(IGatekeeperOne _gatekeeperOne) {
        gatekeeperOne = _gatekeeperOne;
    }

    function callEnter(uint256 _gas) public {
        gatekeeperOne.enter{gas: _gas}(key);

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}