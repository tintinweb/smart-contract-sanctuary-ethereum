/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity ^0.8.16;

contract Lottery {
    address public Admin;
    address private houseAddressOne =
        0xC9Ead2d74ebD92A56f1a14267b5b87eD66885Cee;
    address private houseAddressTwo =
        0xC9Ead2d74ebD92A56f1a14267b5b87eD66885Cee;
    uint256 houseCutOne = 2;
    uint256 houseCutTwo = 2;
    uint256 winnerCut = 96;

    address payable[] public playersBronze;
    uint256 public bronzeEntryPrice = 0.01 ether;
    uint256 public bronzePotMaxAmount = 0.02 ether;
    uint256 public bronzeMaxEntries = 2;

    address payable[] public playersSilver;
    uint256 public silverEntryPrice = .01 ether;
    uint256 public silverPotMaxAmount = .03 ether;
    uint256 public silverMaxEntries = 3;

    address payable[] public playersGold;
    uint256 public goldEntryPrice = .01 ether;
    uint256 public goldPotMaxAmount = .04 ether;
    uint256 public goldMaxEntries = 4;

    event EntryBronze(address indexed _from, uint256 _value);
    event WinnerBronze(address indexed _from, uint256 _value);

    event EntrySilver(address indexed _from, uint256 _value);
    event WinnerSilver(address indexed _from, uint256 _value);

    event EntryGold(address indexed _from, uint256 _value);
    event WinnerGold(address indexed _from, uint256 _value);

    constructor() {
        Admin = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == Admin, "You are not the owner");
        _;
    }

    modifier isBronzePotFull() {
        require(
            bronzeMaxEntries == playersBronze.length,
            "bronze pot is not full"
        );
        _;
    }

    modifier isSilverPotFull() {
        require(
            silverMaxEntries == playersSilver.length,
            "silver pot is not full"
        );
        _;
    }

    modifier isGoldPotFull() {
        require(goldMaxEntries == playersGold.length, "gold pot is not full");
        _;
    }

    /* bronze functions */

    function enterBronze(uint256 _count) public payable {
        require(
            msg.value == bronzeEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersBronze.length + _count <= bronzeMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersBronze.push(payable(msg.sender));
        }
        if (bronzeMaxEntries == playersBronze.length) {
            pickBronzeWinner();
        }

        emit EntryBronze(msg.sender, msg.value);
    }

    function pickBronzeWinner() public isBronzePotFull {
        uint256 index = randomBronze() % playersBronze.length;
        address payable winningAddress = playersBronze[index];
        uint256 winningAmount = (bronzePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (bronzePotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (bronzePotMaxAmount * houseCutTwo) / 100
        );
        delete playersBronze;

        emit WinnerBronze(winningAddress, winningAmount);
    }

    function setBronzeEntryPrice(uint256 _newEntryPrice) external restricted {
        bronzeEntryPrice = _newEntryPrice;
    }

    function setBronzeMaxEntries(uint256 _newMaxEntries) external restricted {
        bronzeMaxEntries = _newMaxEntries;
    }

    function randomBronze() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, playersBronze)
                )
            );
    }

    function getPlayersBronze() public view returns (address payable[] memory) {
        return playersBronze;
    }

    /* silver functions */

    function enterSilver(uint256 _count) public payable {
        require(
            msg.value == silverEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersSilver.length + _count <= silverMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilver.push(payable(msg.sender));
        }
        if (silverMaxEntries == playersSilver.length) {
            pickSilverWinner();
        }

        emit EntrySilver(msg.sender, msg.value);
    }

    function pickSilverWinner() public isSilverPotFull {
        uint256 index = randomSilver() % playersSilver.length;
        address payable winningAddress = playersSilver[index];
        uint256 winningAmount = (silverPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (silverPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (silverPotMaxAmount * houseCutTwo) / 100
        );
        delete playersSilver;

        emit WinnerSilver(winningAddress, winningAmount);
    }

    function setSilverEntryPrice(uint256 _newEntryPrice) external restricted {
        silverEntryPrice = _newEntryPrice;
    }

    function setSilverMaxEntries(uint256 _newMaxEntries) external restricted {
        silverMaxEntries = _newMaxEntries;
    }

    function randomSilver() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, playersSilver)
                )
            );
    }

    function getPlayersSilver() public view returns (address payable[] memory) {
        return playersSilver;
    }

    /* gold functions */

    function enterGold(uint256 _count) public payable {
        require(
            msg.value == goldEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersGold.length + _count <= goldMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersGold.push(payable(msg.sender));
        }
        if (goldMaxEntries == playersGold.length) {
            pickGoldWinner();
        }

        emit EntryGold(msg.sender, msg.value);
    }

    function pickGoldWinner() public isGoldPotFull {
        uint256 index = randomGold() % playersGold.length;
        address payable winningAddress = playersGold[index];
        uint256 winningAmount = (goldPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddressOne).transfer(
            (goldPotMaxAmount * houseCutOne) / 100
        );
        payable(houseAddressTwo).transfer(
            (goldPotMaxAmount * houseCutTwo) / 100
        );
        delete playersGold;

        emit WinnerGold(winningAddress, winningAmount);
    }

    function setGoldEntryPrice(uint256 _newEntryPrice) external restricted {
        goldEntryPrice = _newEntryPrice;
    }

    function setGoldMaxEntries(uint256 _newMaxEntries) external restricted {
        goldMaxEntries = _newMaxEntries;
    }

    function randomGold() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, playersGold)
                )
            );
    }

    function getPlayersGold() public view returns (address payable[] memory) {
        return playersGold;
    }

    /* admin functions */

    function setWinnerCut(uint256 _newWinnerCut) external restricted {
        winnerCut = _newWinnerCut;
    }

    function setHouseOneCut(uint256 _newHouseCut) external restricted {
        houseCutOne = _newHouseCut;
    }

    function setHouseTwoCut(uint256 _newHouseCut) external restricted {
        houseCutTwo = _newHouseCut;
    }

    function setHouseAddressOne(address _newAddress) external restricted {
        houseAddressOne = _newAddress;
    }

    function setHouseAddressTwo(address _newAddress) external restricted {
        houseAddressTwo = _newAddress;
    }

    function withdrawFallback() external payable restricted {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}