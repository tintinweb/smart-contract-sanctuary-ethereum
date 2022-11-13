/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AirPort {
    struct Firm {
        uint256 coins;
        uint256 money;
        uint256 money2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[8] crews;
        uint8[8] planes;
    }
    mapping(address => Firm) public firms;
    uint256 public totalCrews;
    uint256 public totalPlanes;
    uint256 public totalInvested;
    uint256 public totalFirms;
    address public manager = msg.sender;

    function addCoins(address ref) public payable {
        uint256 coins = msg.value / 2e13;
        require(coins > 0, "Zero coins");
        address user = msg.sender;
        totalInvested += msg.value;
        if (firms[user].timestamp == 0) {
            totalFirms++;
            ref = firms[ref].timestamp == 0 ? manager : ref;
            firms[ref].refs++;
            firms[user].ref = ref;
            firms[user].timestamp = block.timestamp;
        }
        ref = firms[user].ref;
        firms[ref].coins += (coins * 7) / 100;
        firms[ref].money += (coins * 100 * 3) / 100;
        firms[ref].refDeps += coins;
        firms[user].coins += coins;
        payable(manager).transfer((msg.value * 3) / 100);
    }

    function withdrawMoney() public {
        address user = msg.sender;
        uint256 money = firms[user].money;
        firms[user].money = 0;
        uint256 amount = money * 2e11;
        payable(user).transfer(address(this).balance < amount ? address(this).balance : amount);
    }

    function collectMoney() public {
        address user = msg.sender;
        syncFirm(user);
        firms[user].hrs = 0;
        firms[user].money += firms[user].money2;
        firms[user].money2 = 0;
    }

    function buyPlane(uint256 planeId) public {
        require(planeId < 8, "Max 8 class 0f plane");
        address user = msg.sender;
        require(firms[user].planes[planeId] == 0, "Already own plane");
        syncFirm(user);
        totalPlanes++;
        firms[user].planes[planeId]++;
        firms[user].coins -= getPlanePrice(planeId);
        firms[user].yield += getYield(planeId, 0);
    }

    function hireCrew(uint256 planeId) public {
        require(planeId < 8, "Max 8 class 0f plane");
        address user = msg.sender;
        require(firms[user].planes[planeId] > 0, "No plane");
        syncFirm(user);
        firms[user].crews[planeId]++;
        totalCrews++;
        uint256 crews = firms[user].crews[planeId];
        firms[user].coins -= getUpgradePrice(planeId, crews);
        firms[user].yield += getYield(planeId, crews);
    }

    function sellFirm() public {
        collectMoney();
        address user = msg.sender;
        uint8[8] memory crews = firms[user].crews;
        uint8[8] memory planes = firms[user].planes;
        totalCrews -= crews[0] + crews[1] + crews[2] + crews[3] + crews[4] + crews[5] + crews[6] + crews[7];
        totalPlanes -= planes[0] + planes[1] + planes[2] + planes[3] + planes[4] + planes[5] + planes[6] + planes[7];
        firms[user].money += firms[user].yield * 24 * 14;
        firms[user].crews = [0, 0, 0, 0, 0, 0, 0, 0];
        firms[user].planes = [0, 0, 0, 0, 0, 0, 0, 0];
        firms[user].yield = 0;
    }

    function sellPlane(uint256 planeId) public {
        collectMoney();
        address user = msg.sender;
        uint256 crews = firms[user].crews[planeId];
        totalCrews -= crews;
        totalPlanes -= 1;
        firms[user].money += firms[user].yield * 24 * 14;
        firms[user].yield -= getYield(planeId, crews);
        firms[user].crews[planeId] = 0;
        firms[user].planes[planeId] = 0;
    }

    function getCrews(address addr) public view returns (uint8[8] memory) {
        return firms[addr].crews;
    }

    function getPlanes(address addr) public view returns (uint8[8] memory) {
        return firms[addr].planes;
    }

    function syncFirm(address user) internal {
        require(firms[user].timestamp > 0, "Not registered");
        if (firms[user].yield > 0) {
            uint256 hrs = block.timestamp / 3600 - firms[user].timestamp / 3600;
            if (hrs + firms[user].hrs > 24) {
                hrs = 24 - firms[user].hrs;
            }
            firms[user].money2 += hrs * firms[user].yield;
            firms[user].hrs += hrs;
        }
        firms[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 planeId, uint256 crewId) internal pure returns (uint256) {
        if (crewId == 1) return [500, 1500, 4500, 13500, 40500, 120000, 365000, 1000000][planeId];
        if (crewId == 2) return [625, 1800, 5600, 16800, 50600, 150000, 456000, 1200000][planeId];
        if (crewId == 3) return [780, 2300, 7000, 21000, 63000, 187000, 570000, 1560000][planeId];
        if (crewId == 4) return [970, 3000, 8700, 26000, 79000, 235000, 713000, 2000000][planeId];
        if (crewId == 5) return [1200, 3600, 11000, 33000, 98000, 293000, 890000, 2500000][planeId];
        revert("Incorrect crewId");
    }

    function getYield(uint256 planeId, uint256 crewId) internal pure returns (uint256) {
        if (crewId == 0) return [42, 135, 430, 1376, 4404, 14092, 45097, 144310][planeId];
        if (crewId == 1) return [41, 130, 399, 1220, 3750, 11400, 36200, 104000][planeId];
        if (crewId == 2) return [52, 157, 498, 1530, 4700, 14300, 45500, 126500][planeId];
        if (crewId == 3) return [65, 201, 625, 1920, 5900, 17900, 57200, 167000][planeId];
        if (crewId == 4) return [82, 264, 780, 2380, 7400, 22700, 72500, 216500][planeId];
        if (crewId == 5) return [103, 318, 995, 3050, 9300, 28700, 91500, 275000][planeId];
        revert("Incorrect crewId");
    }

    function getPlanePrice(uint256 planeId) internal pure returns (uint256) {
        return [500, 1600, 5120, 16300, 52420, 167000, 536000, 1700000][planeId];
    }
}