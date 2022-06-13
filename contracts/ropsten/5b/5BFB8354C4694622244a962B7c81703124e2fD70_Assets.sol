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

contract Assets is Ownable {

    mapping(uint256 => Inventory) public items;
    address public thugCity;
    mapping(uint256 => uint256) public medallions;

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

    function getPoints(uint256 tokenId) external view returns (uint256 points){
        points += items[tokenId].guns;
        points += items[tokenId].cash*9;
        points += items[tokenId].cashBag*8;
        points += items[tokenId].chips*7;
        points += items[tokenId].chipStacks*6;
        points += items[tokenId].gangLeaders*5;
        points += items[tokenId].streetThugs*4;
        points += items[tokenId].superCars*3;
        points += items[tokenId].sportsCars*2;
        points += medallions[tokenId];
        return points;
    }

    function getGuns(uint256 tokenId) external view returns (uint256){
        return items[tokenId].guns;
    }

    function addGun(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].guns += amount;
    }

    function addMedallion(uint256 tokenId, uint256 amount) external onlyThugCity {
        medallions[tokenId] += amount;
    }

    function useMedallion(uint256 tokenId, uint256 amount) external onlyThugCity {
        medallions[tokenId] -= amount;
    }

    function addCash(uint256 tokenId) external onlyThugCity {
        items[tokenId].cash++;
    }

    function addCashBag(uint256 tokenId) external onlyThugCity {
        items[tokenId].cashBag++;
    }

    function addChips(uint256 tokenId) external onlyThugCity {
        items[tokenId].chips++;
    }

    function addChipStacks(uint256 tokenId) external onlyThugCity {
        items[tokenId].chipStacks++;
    }

    function addStreetThugs(uint256 tokenId) external onlyThugCity {
        items[tokenId].streetThugs++;
    }

    function addGangLeaders(uint256 tokenId) external onlyThugCity {
        items[tokenId].gangLeaders++;
    }

    function addSportsCar(uint256 tokenId) external onlyThugCity {
        items[tokenId].sportsCars++;
    }

    function addSuperCar(uint256 tokenId) external onlyThugCity {
        items[tokenId].superCars++;
    }


    // USE FUNCTIONS. USED FOR FUTURE SPENDING OF ASSETS
    function useGun(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].guns -= amount;
    }

    function useCash(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].cash -= amount;
    }

    function useCashBag(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].cashBag -= amount;
    }

    function useChips(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].chips -= amount;
    }

    function useChipStacks(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].chipStacks -= amount;
    }

    function useStreetThugs(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].streetThugs -= amount;
    }

    function useGangLeaders(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].gangLeaders -= amount;
    }

    function useSportsCar(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].sportsCars -= amount;
    }

    function useSuperCar(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].superCars -= amount;
    }

    modifier onlyThugCity() {
        require(msg.sender == thugCity);
        _;
    }

    function setThugCity(address _addr) external onlyOwner {
        thugCity = _addr;
    }

    /*/MISC: Update leaderboard
    function updateLeaderboard(uint256 tokenId, uint256 pointsGained) private {
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
                uint256 temp = leaderBoard[i];
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
    }*/
}