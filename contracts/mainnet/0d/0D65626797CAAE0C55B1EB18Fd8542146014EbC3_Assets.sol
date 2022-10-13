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

    mapping(address => Inventory) public items;
    address public thugCity;
    mapping(address => uint256) public medallions;
    mapping(uint256 => uint256) public characterGuns;

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

    function getPoints(address addr) public view returns (uint256 points){
        points += items[addr].guns;
        points += items[addr].cashBag*47;
        points += items[addr].cash*31;
        points += items[addr].chipStacks*23;
        points += items[addr].chips*15;
        points += items[addr].gangLeaders*11;
        points += items[addr].streetThugs*7;
        points += items[addr].superCars*5;
        points += items[addr].sportsCars*3;
        points += medallions[addr];
        return points;
    }

    function addReward(address addr, uint256 location, uint256 reward) external onlyThugCity {
        if(location == 4){
            if(reward == 1){
                items[addr].cash++;
            }else {
                items[addr].cashBag++;
            }
        }else if (location == 3) {
            if(reward == 1){
                items[addr].chips++;
            }else {
                items[addr].chipStacks++;
            }
        }else if (location == 2) {
            if(reward == 1){
                items[addr].streetThugs++;
            }else {
                items[addr].gangLeaders++;
            }
        }else if (location == 1) {
            if(reward == 1){
                items[addr].sportsCars++;
            }else {
                items[addr].superCars++;
            }
        }
    }

    function redeemReward(address addr, uint256 location, uint256 reward) external onlyThugCity {
        if(location == 4){
            if(reward == 1){
                items[addr].cash--;
            }else {
                items[addr].cashBag--;
            }
        }else if (location == 3) {
            if(reward == 1){
                items[addr].chips--;
            }else {
                items[addr].chipStacks--;
            }
        }else if (location == 2) {
            if(reward == 1){
                items[addr].streetThugs--;
            }else {
                items[addr].gangLeaders--;
            }
        }else if (location == 1) {
            if(reward == 1){
                items[addr].sportsCars--;
            }else {
                items[addr].superCars--;
            }
        }
    }

    function getGuns(uint256 tokenId) external view returns (uint256){
        return characterGuns[tokenId];
    }

    function addGun(uint256 tokenId, address addr, uint256 amount) external onlyThugCity {
        characterGuns[tokenId] += amount;
        items[addr].guns += amount;
    }

    function useGun(address addr, uint256 amount) external onlyThugCity {
        items[addr].guns -= amount;
    }

    function addMedallion(address _user, uint256 amount) external onlyThugCity {
        medallions[_user] += amount;
    }

    function useMedallion(address addr, uint256 amount) external onlyThugCity {
        medallions[addr] -= amount;
    }
    
    modifier onlyThugCity() {
        require(msg.sender == thugCity);
        _;
    }

    function setThugCity(address _addr) external onlyOwner {
        thugCity = _addr;
    }
}