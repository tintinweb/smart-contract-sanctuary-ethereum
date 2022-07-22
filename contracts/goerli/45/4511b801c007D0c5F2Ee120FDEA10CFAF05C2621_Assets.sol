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

    function getPoints(uint256 tokenId) public view returns (uint256 points){
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

    function getAllUserPoints() external view returns (uint256[] memory){
        uint256[] memory allPoints = new uint256[](100);
        for (uint256 i; i < 100; i++) {
            allPoints[i] = getPoints(i);
        }
        return allPoints;
    }

    function addReward(uint256 tokenId, uint256 location, uint256 reward) external onlyThugCity {
        if(location == 4){
            if(reward == 1){
                items[tokenId].cash++;
            }else {
                items[tokenId].cashBag++;
            }
        }else if (location == 3) {
            if(reward == 1){
                items[tokenId].chips++;
            }else {
                items[tokenId].chipStacks++;
            }
        }else if (location == 2) {
            if(reward == 1){
                items[tokenId].streetThugs++;
            }else {
                items[tokenId].gangLeaders++;
            }
        }else if (location == 1) {
            if(reward == 1){
                items[tokenId].sportsCars++;
            }else {
                items[tokenId].superCars++;
            }
        }
    }

    function getGuns(uint256 tokenId) external view returns (uint256){
        return items[tokenId].guns;
    }

    function addGun(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].guns += amount;
    }

    function useGun(uint256 tokenId, uint256 amount) external onlyThugCity {
        items[tokenId].guns -= amount;
    }

    function addMedallion(uint256 tokenId, uint256 amount) external onlyThugCity {
        medallions[tokenId] += amount;
    }

    function useMedallion(uint256 tokenId, uint256 amount) external onlyThugCity {
        medallions[tokenId] -= amount;
    }
    
    modifier onlyThugCity() {
        require(msg.sender == thugCity);
        _;
    }

    function setThugCity(address _addr) external onlyOwner {
        thugCity = _addr;
    }
}