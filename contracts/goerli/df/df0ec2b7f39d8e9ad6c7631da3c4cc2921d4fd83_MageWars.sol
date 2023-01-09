/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract MageWars {
    struct Tower {
        uint256 runes;
        uint256 money;
        uint256 money2;
        uint256 spellLevel;
        uint256 altarLevel;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        uint256 maxHrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[8] mages;
    }

    struct Wars {
        uint256 wins;
        uint256 loses;
    }

    struct Arena {
        address player1;
        address player2;
        uint256 runes;
        uint256 timestamp;
        address winner;
    }

    mapping(address => Tower) public towers;
    mapping(address => Arena) public arenas;
    mapping(address => Wars) public wars;
    mapping(uint256 => address) public waitingArenas;

    uint256 public totalMages;
    uint256 public totalTowers;
    uint256 public totalInvested;
    uint256 public totalWars;
    address public manager = msg.sender;

    function addRunes(address ref) public payable {
        require(ref != msg.sender, "Invalid ref");
        uint256 runes = msg.value / 2e11;
        require(runes > 0, "Zero runes");
        address user = msg.sender;
        totalInvested += msg.value;
        if (towers[user].timestamp == 0) {
            totalTowers++;
            ref = towers[ref].timestamp == 0 ? manager : ref;
            towers[ref].refs++;
            towers[user].ref = ref;
            towers[user].maxHrs = 24;
            towers[user].timestamp = block.timestamp;
        }

        ref = towers[user].ref;
        towers[ref].runes += (runes * 7) / 100;
        towers[ref].money += (runes * 100 * 3) / 100;
        towers[ref].refDeps += runes;

        // Owner FEE
        uint256 runesFee = (runes * 3) / 100;
        towers[manager].runes += runesFee;
        payable(manager).transfer((msg.value * 5) / 100);

        towers[user].runes += runes;
    }

    function withdrawMoney(uint256 amount) public {
        require(amount >= 100, "Invalid amount");
        address user = msg.sender;
        towers[user].money -= amount;
        uint256 real = amount * 2e11;
        payable(user).transfer(
            address(this).balance < real ? address(this).balance : real
        );
    }

    function collectMoney() public {
        address user = msg.sender;
        syncTower(user);
        towers[user].hrs = 0;
        towers[user].money += towers[user].money2;
        towers[user].money2 = 0;
    }

    function swapMoney(uint256 amount) public {
        require(amount >= 100, "Invalid amount");
        address user = msg.sender;
        towers[user].money -= amount;
        towers[user].runes += amount / 100;
    }

    function upgradeTower(uint256 floorId) public {
        require(floorId < 8, "Max 8 floors");
        address user = msg.sender;
        syncTower(user);
        towers[user].mages[floorId]++;
        totalMages++;
        uint256 mages = towers[user].mages[floorId];
        towers[user].runes -= getUpgradeTowerPrice(floorId, mages);
        towers[user].yield += getTowerYield(floorId, mages);
    }

    function upgradeAltar() public {
        address user = msg.sender;
        syncTower(user);
        towers[user].runes -= getUpgradeAltarPrice(towers[user].altarLevel);
        towers[user].maxHrs = getAltarHours(towers[user].altarLevel);
        towers[user].altarLevel += 1;
    }

    function upgradeSpells() public {
        address user = msg.sender;
        syncTower(user);

        towers[user].runes -= getUpgradeSpellPrice(towers[user].spellLevel);
        towers[user].spellLevel += 1;
    }

    function sellTower() public {
        collectMoney();
        address user = msg.sender;
        uint8[8] memory mages = towers[user].mages;
        totalMages -=
            mages[0] +
            mages[1] +
            mages[2] +
            mages[3] +
            mages[4] +
            mages[5] +
            mages[6] +
            mages[7];
        towers[user].money += towers[user].yield * 24 * 14;
        towers[user].mages = [0, 0, 0, 0, 0, 0, 0, 0];
        towers[user].spellLevel = 0;
        towers[user].altarLevel = 0;
        towers[user].maxHrs = 0;
        towers[user].yield = 0;
    }

    function getMages(address addr) public view returns (uint8[8] memory) {
        return towers[addr].mages;
    }

    function syncTower(address user) internal {
        require(towers[user].timestamp > 0, "User is not registered");
        if (towers[user].yield > 0) {
            uint256 hrs = block.timestamp /
                3600 -
                towers[user].timestamp /
                3600;

            if (hrs + towers[user].hrs > towers[user].maxHrs) {
                hrs = towers[user].maxHrs - towers[user].hrs;
            }

            uint256 money = hrs * towers[user].yield;
            uint256 bonusPercent = getLeaderBonusPercent(towers[user].refs);

            if (towers[user].spellLevel > 0) {
                bonusPercent += getSpellYield(towers[user].spellLevel - 1);
            }

            money += (money * bonusPercent) / 100 / 100;

            towers[user].money2 += money;
            towers[user].hrs += hrs;
        }

        towers[user].timestamp = block.timestamp;
    }

    function getUpgradeTowerPrice(uint256 floorId, uint256 mageId)
        internal
        pure
        returns (uint256)
    {
        if (mageId == 1)
            return
                [500, 1500, 4500, 13500, 40500, 120000, 365000, 1000000][
                    floorId
                ];
        if (mageId == 2)
            return
                [625, 1800, 5600, 16800, 50600, 150000, 456000, 1200000][
                    floorId
                ];
        if (mageId == 3)
            return
                [780, 2300, 7000, 21000, 63000, 187000, 570000, 1560000][
                    floorId
                ];
        if (mageId == 4)
            return
                [970, 3000, 8700, 26000, 79000, 235000, 713000, 2000000][
                    floorId
                ];
        if (mageId == 5)
            return
                [1200, 3600, 11000, 33000, 98000, 293000, 890000, 2500000][
                    floorId
                ];
        revert("Incorrect mageId");
    }

    function getUpgradeSpellPrice(uint256 level)
        internal
        pure
        returns (uint256)
    {
        return [10000, 20000, 50000, 120000, 160000][level];
    }

    function getUpgradeAltarPrice(uint256 level)
        internal
        pure
        returns (uint256)
    {
        return [2000, 6000, 10000, 12000][level];
    }

    function getTowerYield(uint256 floorId, uint256 mageId)
        internal
        pure
        returns (uint256)
    {
        if (mageId == 1)
            return [41, 130, 399, 1220, 3750, 11400, 36200, 104000][floorId];
        if (mageId == 2)
            return [52, 157, 498, 1530, 4700, 14300, 45500, 126500][floorId];
        if (mageId == 3)
            return [65, 201, 625, 1920, 5900, 17900, 57200, 167000][floorId];
        if (mageId == 4)
            return [82, 264, 780, 2380, 7400, 22700, 72500, 216500][floorId];
        if (mageId == 5)
            return [103, 318, 995, 3050, 9300, 28700, 91500, 275000][floorId];
        revert("Incorrect mageId");
    }

    function getLeaderBonusPercent(uint256 refs)
        internal
        pure
        returns (uint256)
    {
        if (refs >= 100) return 100;
        if (refs >= 50) return 50;
        return 0;
    }

    function getSpellYield(uint256 level) internal pure returns (uint256) {
        return [10, 20, 30, 40, 50][level];
    }

    function getAltarHours(uint256 level) internal pure returns (uint256) {
        return [24, 30, 36, 42, 48][level];
    }

    // Arena:
    function createArena(uint256 arenaType) public {
        require(arenaType < 3, "Incorrect type");

        address arenaCreator = waitingArenas[arenaType];
        require(msg.sender != arenaCreator, "You are already in arena");

        if (arenaCreator == address(0)) {
            _createArena(arenaType);
        } else {
            _joinArena(arenaType, arenaCreator);
            _fightArena(arenaCreator);
        }
    }

    function getArenaType(uint256 arenaType) internal pure returns (uint256) {
        return [1000, 10000, 50000][arenaType];
    }

    function _randomNumber() internal view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return randomnumber % 100;
    }

    function _createArena(uint256 arenaType) internal {
        arenas[msg.sender].timestamp = block.timestamp;
        arenas[msg.sender].player1 = msg.sender;
        arenas[msg.sender].player2 = address(0);
        arenas[msg.sender].winner = address(0);
        arenas[msg.sender].runes = getArenaType(arenaType);
        towers[msg.sender].runes -= arenas[msg.sender].runes;
        waitingArenas[arenaType] = msg.sender;
    }

    function _joinArena(uint256 arenaType, address arenaCreator) internal {
        arenas[arenaCreator].timestamp = block.timestamp;
        arenas[arenaCreator].player2 = msg.sender;
        towers[msg.sender].runes -= arenas[arenaCreator].runes;
        waitingArenas[arenaType] = address(0);
    }

    function _fightArena(address arenaCreator) internal {
        uint256 random = _randomNumber();
        uint256 wAmount = arenas[arenaCreator].runes * 2;
        uint256 fee = (wAmount * 10) / 100;

        address winner = random < 50
            ? arenas[arenaCreator].player1
            : arenas[arenaCreator].player2;
        address loser = random >= 50
            ? arenas[arenaCreator].player1
            : arenas[arenaCreator].player2;

        towers[winner].runes += wAmount - fee;
        arenas[arenaCreator].winner = winner;

        wars[winner].wins++;
        wars[loser].loses++;
        totalWars++;

        towers[manager].runes += fee;
    }
}