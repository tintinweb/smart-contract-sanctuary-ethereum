/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Fomo3D {

    string constant public title = "Jcard Fomo3D Official";

    receive() external payable {}
    fallback() external payable {}

    using Strings for uint;
    mapping (address => uint) keyBalance;
    address winner;
    address owner;
    bool isActive = false;
    uint endTime;
    uint gameTime = 1 minutes;
    uint addTime = 30 seconds;
    uint keyPrice = 0.01 ether;
    
    constructor(address _owner) {
        owner = _owner;
    } 

    modifier onlyOwner() {
        require (msg.sender == owner, "Permission Error.");
        _;
    }

    modifier checkTimer() {
        require (timeLeft() > 0, "Game is over.");
        _;
    }

    function startGame() public onlyOwner {
        isActive = true;
        endTime = block.timestamp + gameTime;
    }
    
    /**
    * @dev Price 0.01 ether 
    */
    function buyKey() public payable checkTimer {
        require(isActive == true, "Game hasn't started.");

        (bool sent, ) = address(this).call{value: msg.value}("");
        if (msg.value < keyPrice) 
            revert("not enough");

        require(sent, "Failed to send Ether");
        keyBalance[msg.sender] += 1;
        endTime += addTime;
        winner = msg.sender;
    }
    
    function Timer() public view returns (string memory) {
        uint temp = timeLeft();
        uint min = temp/60;
        uint sec = temp-60*min;
        return string(abi.encodePacked(min.toString(), ":", sec.toString()));
    }

    function prizePool() public view returns (uint) {
        return address(this).balance;
    }

    function getKey(address _owner) public view returns (uint) {
        return keyBalance[_owner];
    }

    function timeLeft() private view returns(uint) {
        if (block.timestamp > endTime)
            return 0;

        return endTime-block.timestamp;
    }

    function getWinner() public view returns(address) {
        require (timeLeft() == 0, "Game hasn't ended!");
        return winner;
    }

    function withdraw() public {
        require(timeLeft() == 0, "Game hasn't ended!");
        require(msg.sender == winner, "You are not winner!");
        (bool sent, ) = winner.call{value: address(this).balance}("");
        require(sent, "Transfer failed.");
    }

}



library Strings {

    function toString(uint256 value) internal pure returns (string memory) {
 
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}