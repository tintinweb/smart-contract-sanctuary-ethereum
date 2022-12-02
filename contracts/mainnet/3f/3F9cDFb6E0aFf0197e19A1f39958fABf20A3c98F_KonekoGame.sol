// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract KonekoGame {
    struct Chef {
        uint256 milk;
        uint256 sushi;
        uint256 sushi2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8 sushiBarLevel;
        uint8[5] nekos;
    }

    mapping(address => Chef) public chefs;

    uint256 public totalNekos;
    uint256 public totalChefs;
    uint256 public totalInvested;
    address private manager;

    uint256 public constant DENOMINATOR = 10;
    uint256 public constant PRICE = 1e14;
    bool public init;

    modifier initialized() {
        require(init, "Not initialized");
        _;
    }

    constructor(address manager_) {
        manager = manager_;
    }

    function initialize() external {
        require(manager == msg.sender, "Not the manager");
        require(!init, "Already initialized");
        init = true;
    }

    function buyMilk(address ref) external payable {
        // slither-disable-next-line divide-before-multiply
        uint256 milk = msg.value / PRICE;
        require(milk > 0, "Zero milk");
        address user = msg.sender;
        totalInvested += msg.value;
        if (chefs[user].timestamp == 0) {
            totalChefs++;
            ref = chefs[ref].timestamp == 0 ? manager : ref;
            chefs[ref].refs++;
            chefs[user].ref = ref;
            // solhint-disable-next-line not-rely-on-time
            chefs[user].timestamp = block.timestamp;
            chefs[user].sushiBarLevel = 0;
        }
        ref = chefs[user].ref;
        // slither-disable-next-line divide-before-multiply
        chefs[ref].milk += (milk * 8) / 100;
        // slither-disable-next-line divide-before-multiply
        chefs[ref].sushi += (milk * 100 * 4) / 100;
        chefs[ref].refDeps += milk;
        chefs[user].milk += milk;
        chefs[manager].milk += (milk * 8) / 100;
        payable(manager).transfer((msg.value * 5) / 100);
    }

    function withdrawSushi(uint256 sushi) external initialized {
        address user = msg.sender;
        require(sushi <= chefs[user].sushi && sushi > 0, "Invalid amount");
        chefs[user].sushi -= sushi;
        uint256 amount = (sushi * PRICE) / 100;
        payable(user).transfer(
            address(this).balance < amount ? address(this).balance : amount
        );
    }

    function collectSushi() public {
        address user = msg.sender;
        syncChef(user);
        chefs[user].hrs = 0;
        chefs[user].sushi += chefs[user].sushi2;
        chefs[user].sushi2 = 0;
    }

    function upgradeChef(uint256 chefId) external {
        require(chefId < 5, "Max 5 chefs");
        address user = msg.sender;
        syncChef(user);
        chefs[user].nekos[chefId]++;
        totalNekos++;
        uint256 nekos = chefs[user].nekos[chefId];
        chefs[user].milk -= getUpgradePrice(chefId, nekos) / DENOMINATOR;
        chefs[user].yield += getYield(chefId, nekos);
    }

    function upgradeSushiBar() external {
        address user = msg.sender;
        uint8 newSushiBarLevel = chefs[user].sushiBarLevel + 1;
        syncChef(user);
        require(newSushiBarLevel < 5, "Max 5 level");
        (uint256 price, ) = getSushiBarConfig(newSushiBarLevel);
        chefs[user].milk -= price / DENOMINATOR;
        chefs[user].sushiBarLevel = newSushiBarLevel;
    }

    function sellChef() external {
        collectSushi();
        address user = msg.sender;
        uint8[5] memory nekos = chefs[user].nekos;
        totalNekos -= nekos[0] + nekos[1] + nekos[2] + nekos[3] + nekos[4];
        chefs[user].sushi += chefs[user].yield * 24 * 5;
        chefs[user].nekos = [0, 0, 0, 0, 0];
        chefs[user].yield = 0;
        chefs[user].sushiBarLevel = 0;
    }

    function getNekos(address addr) external view returns (uint8[5] memory) {
        return chefs[addr].nekos;
    }

    function syncChef(address user) internal {
        require(chefs[user].timestamp > 0, "User is not registered");
        if (chefs[user].yield > 0) {
            (, uint256 timeLimit) = getSushiBarConfig(
                chefs[user].sushiBarLevel
            );
            // solhint-disable-next-line not-rely-on-time
            uint256 hrs = block.timestamp / 3600 - chefs[user].timestamp / 3600;
            if (hrs + chefs[user].hrs > timeLimit) {
                hrs = timeLimit - chefs[user].hrs;
            }
            chefs[user].sushi2 += hrs * chefs[user].yield;
            chefs[user].hrs += hrs;
        }
        // solhint-disable-next-line not-rely-on-time
        chefs[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(
        uint256 chefId,
        uint256 nekoId
    ) internal pure returns (uint256) {
        if (nekoId == 1) return [1000, 5500, 32600, 109400, 246000][chefId];
        if (nekoId == 2) return [1590, 7000, 45400, 122200, 304000][chefId];
        if (nekoId == 3) return [2170, 10200, 58200, 135000, 362000][chefId];
        if (nekoId == 4) return [2760, 13400, 71000, 147800, 420000][chefId];
        if (nekoId == 5) return [3340, 16600, 83800, 160600, 478000][chefId];
        if (nekoId == 6) return [3930, 19800, 96600, 188000, 536000][chefId];
        revert("Incorrect nekoId");
    }

    function getYield(
        uint256 chefId,
        uint256 nekoId
    ) internal pure returns (uint256) {
        if (nekoId == 1) return [8, 50, 321, 1158, 2788][chefId];
        if (nekoId == 2) return [13, 64, 452, 1309, 3483][chefId];
        if (nekoId == 3) return [19, 95, 587, 1463, 4193][chefId];
        if (nekoId == 4) return [24, 127, 725, 1620, 4918][chefId];
        if (nekoId == 5) return [30, 159, 866, 1780, 5875][chefId];
        if (nekoId == 6) return [35, 192, 1010, 2107, 6700][chefId];
        revert("Incorrect nekoId");
    }

    function getSushiBarConfig(
        uint256 sushiBarLevel
    ) internal pure returns (uint256, uint256) {
        if (sushiBarLevel == 0) return (0, 24); // price | value
        if (sushiBarLevel == 1) return (2000, 30);
        if (sushiBarLevel == 2) return (2500, 36);
        if (sushiBarLevel == 3) return (3000, 42);
        if (sushiBarLevel == 4) return (4000, 48);
        revert("Incorrect sushiBarLevel");
    }
}