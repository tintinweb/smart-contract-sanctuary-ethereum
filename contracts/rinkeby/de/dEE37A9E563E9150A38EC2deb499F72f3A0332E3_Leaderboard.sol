// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.7;

/*$$$$$$$ /$$                            /$$$$$$  /$$   /$$              
|__  $$__/| $$                           /$$__  $$|__/  | $$              
   | $$   | $$$$$$$  /$$   /$$  /$$$$$$ | $$  \__/ /$$ /$$$$$$   /$$   /$$
   | $$   | $$__  $$| $$  | $$ /$$__  $$| $$      | $$|_  $$_/  | $$  | $$
   | $$   | $$  \ $$| $$  | $$| $$  \ $$| $$      | $$  | $$    | $$  | $$
   | $$   | $$  | $$| $$  | $$| $$  | $$| $$    $$| $$  | $$ /$$| $$  | $$
   | $$   | $$  | $$|  $$$$$$/|  $$$$$$$|  $$$$$$/| $$  |  $$$$/|  $$$$$$$
   |__/   |__/  |__/ \______/  \____  $$ \______/ |__/   \___/   \____  $$
                               /$$  \ $$                         /$$  | $$
                              |  $$$$$$/                        |  $$$$$$/
                               \______/                          \______*/

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Leaderboard is Ownable, ReentrancyGuard {

    uint16[] public leaderBoard;
    mapping(uint16 => uint256) public leaderBoardPosition;
    mapping(uint16 => uint256) public points;
    mapping(uint256 => Inventory) public items;
    address public thugCity;

    //DECLARE: Store item quantities
    struct Inventory {
        uint256 guns;
        uint256 cash;
        uint256 cashBag;
        uint256 chips;
        uint256 chipStacks;
        uint256 streetThugs;
        uint256 gangLeaders;
        uint256 superCars;
        uint256 sportsCars;
    }

    function setPoints(uint16 tokenId, uint256 _points) external onlyOwner{
        points[tokenId] = _points;
    }

    function getPoints(uint16 tokenId) external view returns (uint256){
        return points[tokenId];
    }

    function getGuns(uint16 tokenId) external view returns (uint256){
        return items[tokenId].guns;
    }

    function addGun(uint16 tokenId, uint256 amount) external onlyThugCity nonReentrant {
        items[tokenId].guns += amount;
        updateLeaderboard(tokenId, amount);
    }

    function addCash(uint16 tokenId) external onlyThugCity nonReentrant{
        items[tokenId].cash++;
        updateLeaderboard(tokenId, 5);
    }

    function addCashBag(uint16 tokenId) external onlyThugCity nonReentrant{
        items[tokenId].cashBag++;
        updateLeaderboard(tokenId, 6);
    }

    function addChips(uint16 tokenId) external onlyThugCity nonReentrant {
        items[tokenId].chips++;
        updateLeaderboard(tokenId, 4);
    }

    function addChipStacks(uint16 tokenId) external onlyThugCity nonReentrant {
        items[tokenId].chipStacks++;
        updateLeaderboard(tokenId, 5);
    }

    function addStreetThugs(uint16 tokenId) external onlyThugCity nonReentrant {
        items[tokenId].streetThugs++;
        updateLeaderboard(tokenId, 3);
    }

    function addGangLeaders(uint16 tokenId) external onlyThugCity nonReentrant {
        items[tokenId].gangLeaders++;
        updateLeaderboard(tokenId, 4);
    }

    function addSportsCar(uint16 tokenId) external onlyThugCity nonReentrant {
        items[tokenId].sportsCars++;
        updateLeaderboard(tokenId, 2);
    }

    function addSuperCar(uint16 tokenId) external onlyThugCity nonReentrant {
        items[tokenId].superCars++;
        updateLeaderboard(tokenId, 3);
    }


    //MISC: Update leaderboard
    function updateLeaderboard(uint16 tokenId, uint256 pointsGained) private {
        points[tokenId] += pointsGained;
        if (points[tokenId] == pointsGained) {
            // if not on leaderboard
            leaderBoard.push(tokenId);
            leaderBoardPosition[tokenId] = leaderBoard.length - 1;
        }
        uint256 previousPosition = leaderBoardPosition[tokenId];
        for (uint256 i = 0; i < leaderBoardPosition[tokenId]; i++) {
            // loop from end of leaderboard to find position user is higher than
            if (points[tokenId] > points[leaderBoard[i]]) {
                // if more points than user i
                uint16 temp = leaderBoard[i];
                leaderBoard[i] = tokenId;
                leaderBoardPosition[tokenId] = i;
                for (uint256 j = previousPosition - 1; j > i; j--) {
                    leaderBoard[j + 1] = leaderBoard[j];
                }
                leaderBoard[i + 1] = temp;
                leaderBoardPosition[temp] = i + 1;
                break;
            }
        }
    }

    modifier onlyThugCity() {
        require(msg.sender == thugCity);
        _;
    }

    function setThugCity(address _addr) external onlyOwner {
        thugCity = _addr;
    }
}