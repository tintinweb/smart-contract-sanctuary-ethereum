/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Store {
    struct Queue{
        string userName;
        string userPassword;
        uint prices;
        uint quantity;
        string mail;
        string times;
    }

    mapping(uint=>Queue) public queueMapping;

    uint queueCount;

    function addQueue(string memory _userName, string memory _userPassword, uint _prices, uint _quantity, string memory _mail, string memory _times) public {
        bytes memory checkName = bytes(_userName);
        bytes memory checkPass = bytes(_userPassword);
        if (checkName.length > 0 && checkPass.length > 0 && _prices > 0){
            queueMapping[queueCount].userName = _userName;
            queueMapping[queueCount].userPassword = _userPassword;
            queueMapping[queueCount].prices = _prices;
            queueMapping[queueCount].quantity = _quantity;
            queueMapping[queueCount].mail = _mail;
            queueMapping[queueCount].times = _times;
            queueCount++;
        }
    }

    function retrieveQueue() public view returns (string[] memory, string[] memory, uint[] memory, uint[] memory, string[] memory, string[] memory){
        string[] memory _userName = new string[](queueCount);
        string[] memory _userPassword = new string[](queueCount);
        uint[] memory _prices = new uint[](queueCount);
        uint[] memory _quantity = new uint[](queueCount);
        string[] memory _mail = new string[](queueCount);
        string[] memory _times = new string[](queueCount);
        for(uint i = 0; i < queueCount; i++){
            _userName[i] = queueMapping[i].userName;
            _userPassword[i] = queueMapping[i].userPassword;
            _prices[i] = queueMapping[i].prices;
            _quantity[i] = queueMapping[i].quantity;
            _mail[i] = queueMapping[i].mail;
            _times[i] = queueMapping[i].times;
        }
        return (_userName,_userPassword,_prices,_quantity,_mail,_times);
    }
}