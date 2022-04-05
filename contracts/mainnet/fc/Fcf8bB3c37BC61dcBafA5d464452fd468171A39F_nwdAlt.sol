/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface nwdInt {
    
    function currentDay() external view returns (uint256);

    function gamers(address) external returns (uint256, uint256);

    function balanceOf(address) external view returns (uint256);

    function gameDay(uint256) external view returns (uint256);

    function totalSupply() external view returns (uint256);

}


pragma solidity ^0.8.0;

contract nwdAlt {

    uint256 contBalance;

    mapping (address => uint256) public withdrawDay;

    function deposit() public payable {
        require(msg.value > 0, "E01");
        contBalance = contBalance + msg.value;
    }


    function earningsNFT(address whothis) public view returns (uint256 myBalance) {
        nwdInt nwd = nwdInt(0x580E2a87dAe999c240d394d6BD107420F9e49701);

        uint256 tokenCount = nwd.balanceOf(whothis);
        require(tokenCount > 0, "E95");
        uint256 myAmount;
        uint256 cDay = nwd.currentDay();
        
        uint256 tempDay = withdrawDay[whothis];

        uint256 supply = nwd.totalSupply();

        if (cDay == tempDay) {
            return 0;
        }

        uint256 dayPot;
        for (uint256 wDay = tempDay; wDay < cDay; wDay++) {
            dayPot = nwd.gameDay(wDay);
            myAmount = myAmount + (tokenCount * ((dayPot * 30) / 100) / supply);
        }

        return myAmount;
    }

    function withdrawNFT(address whothis) public returns (uint256 myBalance) {
        uint256 myAmount = earningsNFT(whothis);

        require(myAmount > 0, "E96");
        require(contBalance >= myAmount, "E97");

        nwdInt nwd = nwdInt(0x580E2a87dAe999c240d394d6BD107420F9e49701);
        uint256 cDay = nwd.currentDay();

        withdrawDay[whothis] = cDay - 1;

        contBalance = contBalance - myAmount;

        payable(msg.sender).transfer(myAmount);
        return myAmount;
    }

}