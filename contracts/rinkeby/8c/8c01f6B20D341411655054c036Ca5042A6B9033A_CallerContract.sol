// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IGatekeeperOne.sol";

contract CallerContract {
    IGatekeeperOne public gatekeeperOne;

    bytes8 key = bytes8(uint64(uint16(0xBbd3b61B47D93469C757121b8C5A0a1e40B6bFBA)) + 2**32);

    constructor(IGatekeeperOne _gatekeeperOne) public {
        gatekeeperOne = _gatekeeperOne;
    }

    function callEnter(uint256 _gas) public {
        (bool result, bytes memory data) = address(gatekeeperOne).call.gas(_gas)(
            abi.encodeWithSignature(("enter(bytes8)"), key)
        );

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IGatekeeperOne {
    function enter(bytes8 _gateKey) external returns (bool);
}