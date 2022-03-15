//SPDX-License-Identifier:MIT
pragma solidity 0.8.12;

contract Which {
    uint256[] public s_playerFunds;
    uint256 public s_totalFunds;

    constructor() {
        s_playerFunds = [
            1,
            15,
            22,
            199,
            234,
            5,
            234,
            5,
            2345,
            234,
            555,
            23424,
            55
        ];
    }

    function a() public {
        uint256 totalFunds;
        for (uint256 i = 0; i < s_playerFunds.length; i++) {
            totalFunds = totalFunds + s_playerFunds[i];
        }
        s_totalFunds = totalFunds;
    }

    function b() external {
        for (uint256 i = 0; i < s_playerFunds.length; i++) {
            s_totalFunds += s_playerFunds[i];
        }
    }

    function c() public {
        uint256 totalFunds;
        uint256[] memory playerFunds = s_playerFunds;
        for (uint256 i = 0; i < playerFunds.length; i++) {
            totalFunds = totalFunds + playerFunds[i];
        }
        s_totalFunds = totalFunds;
    }
}