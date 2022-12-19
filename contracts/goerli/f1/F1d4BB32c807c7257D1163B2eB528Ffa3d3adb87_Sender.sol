//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface Interface {
    function attempt() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './Interface.sol';

/** CREATOR: Christian Armato */
contract Sender {
    function call(address _contract) external {
        Interface(_contract).attempt();
    }
}