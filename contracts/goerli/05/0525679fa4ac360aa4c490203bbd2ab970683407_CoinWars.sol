/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

contract CoinWars {
    struct Gang {
        uint256 diamonds;
        uint256 moneybags;
        uint256 moneybags2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[8] levels;
    }
    mapping(address => Gang) public gangs;
    uint256 public totalLevels;
    uint256 public totalGangs;
    uint256 public totalInvested;
    address public manager = msg.sender;

    function addDiamonds(address ref) public payable {
        uint256 diamonds = msg.value / 2e13;
        require(diamonds > 0, "Zero Diamonds");
        address user = msg.sender;
        totalInvested += msg.value;
        if (gangs[user].timestamp == 0) {
            totalGangs++;
            ref = gangs[ref].timestamp == 0 ? manager : ref;
            gangs[ref].refs++;
            gangs[user].ref = ref;
            gangs[user].timestamp = block.timestamp;
        }
        ref = gangs[user].ref;
        gangs[ref].diamonds += (diamonds * 7) / 100;
        gangs[ref].moneybags += (diamonds * 100 * 3) / 100;
        gangs[ref].refDeps += diamonds;
        gangs[user].diamonds += diamonds;
        payable(manager).transfer((msg.value * 3) / 100);
    }

    function withdrawMoneyBags() public {
        address user = msg.sender;
        uint256 moneybags = gangs[user].moneybags;
        gangs[user].moneybags = 0;
        uint256 amount = moneybags * 2e11;
        payable(user).transfer(address(this).balance < amount ? address(this).balance : amount);
    }

    function collectMoneyBags() public {
        address user = msg.sender;
        syncGang(user);
        gangs[user].hrs = 0;
        gangs[user].moneybags += gangs[user].moneybags2;
        gangs[user].moneybags2 = 0;
    }

    function upgradeGang(uint256 gangsterId) public {
        require(gangsterId < 8, "Max 8 floors");
        address user = msg.sender;
        syncGang(user);
        gangs[user].levels[gangsterId]++;
        totalLevels++;
        uint256 levels = gangs[user].levels[gangsterId];
        gangs[user].diamonds -= getUpgradePrice(gangsterId, levels);
        gangs[user].yield += getYield(gangsterId, levels);
    }

    function sellGang() public {
        collectMoneyBags();
        address user = msg.sender;
        uint8[8] memory levels = gangs[user].levels;
        totalLevels -= levels[0] + levels[1] + levels[2] + levels[3] + levels[4] + levels[5] + levels[6] + levels[7];
        gangs[user].moneybags += gangs[user].yield * 24 * 14;
        gangs[user].levels = [0, 0, 0, 0, 0, 0, 0, 0];
        gangs[user].yield = 0;
    }

    function getLevels(address addr) public view returns (uint8[8] memory) {
        return gangs[addr].levels;
    }

    function syncGang(address user) internal {
        require(gangs[user].timestamp > 0, "User is not registered");
        if (gangs[user].yield > 0) {
            uint256 hrs = block.timestamp / 3600 - gangs[user].timestamp / 3600;
            if (hrs + gangs[user].hrs > 24) {
                hrs = 24 - gangs[user].hrs;
            }
            gangs[user].moneybags2 += hrs * gangs[user].yield;
            gangs[user].hrs += hrs;
        }
        gangs[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 gangsterId, uint256 levelId) internal pure returns (uint256) {
        if (levelId == 1) return [500, 1500, 4500, 13500, 40500, 120000, 365000, 1000000][gangsterId];
        if (levelId == 2) return [625, 1800, 5600, 16800, 50600, 150000, 456000, 1200000][gangsterId];
        if (levelId == 3) return [780, 2300, 7000, 21000, 63000, 187000, 570000, 1560000][gangsterId];
        if (levelId == 4) return [970, 3000, 8700, 26000, 79000, 235000, 713000, 2000000][gangsterId];
        if (levelId == 5) return [1200, 3600, 11000, 33000, 98000, 293000, 890000, 2500000][gangsterId];
        revert("Incorrect levelId");
    }

    function getYield(uint256 gangsterId, uint256 levelId) internal pure returns (uint256) {
        if (levelId == 1) return [41, 130, 399, 1220, 3750, 11400, 36200, 104000][gangsterId];
        if (levelId == 2) return [52, 157, 498, 1530, 4700, 14300, 45500, 126500][gangsterId];
        if (levelId == 3) return [65, 201, 625, 1920, 5900, 17900, 57200, 167000][gangsterId];
        if (levelId == 4) return [82, 264, 780, 2380, 7400, 22700, 72500, 216500][gangsterId];
        if (levelId == 5) return [103, 318, 995, 3050, 9300, 28700, 91500, 275000][gangsterId];
        revert("Incorrect levelId");
    }
}