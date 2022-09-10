/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

pragma solidity ^0.8.16;

contract Lottery {
    address public Admin;
    address private houseAddress = 0x7a029a259EdA95c0e35B383F1a3baf68aE98C193;
    uint256 houseCut = 5;
    uint256 winnerCut = 95;

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
        require(goldMaxEntries == playersGold.length, 
            "gold pot is not full"
        );
        _;
    }

    /* bronze functions */

    function enterBronze() public payable {
        require(
            msg.value == bronzeEntryPrice,
            "incorrent value sent to contract"
        );
        playersBronze.push(payable(msg.sender));
        if (bronzeMaxEntries == playersBronze.length) {
            pickBronzeWinner();
        }

        emit EntryBronze(msg.sender, msg.value);
    }

    function pickBronzeWinner() public {
        uint256 index = randomBronze() % playersBronze.length;
        address payable winningAddress = playersBronze[index];
        uint256 winningAmount = (bronzePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer((bronzePotMaxAmount * houseCut) / 100);
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

    function enterSilver() public payable {
        require(
            msg.value == silverEntryPrice,
            "incorrent value sent to contract"
        );
        playersSilver.push(payable(msg.sender));
        if (silverPotMaxAmount / playersSilver.length == silverEntryPrice) {
            pickSilverWinner();
        }

        emit EntrySilver(msg.sender, msg.value);
    }

    function pickSilverWinner() public isSilverPotFull {
        uint256 index = randomSilver() % playersSilver.length;
        address payable winningAddress = playersSilver[index];
        uint256 winningAmount = (silverPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer((silverPotMaxAmount * houseCut) / 100);
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

    function enterGold() public payable {
        require(
            msg.value == goldEntryPrice,
            "incorrent value sent to contract"
        );
        playersGold.push(payable(msg.sender));
        if (goldPotMaxAmount / playersGold.length == goldEntryPrice) {
            pickGoldWinner();
        }

        emit EntryGold(msg.sender, msg.value);
    }

    function pickGoldWinner() public isGoldPotFull {
        uint256 index = randomGold() % playersGold.length;
        address payable winningAddress = playersGold[index];
        uint256 winningAmount = (goldPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer((goldPotMaxAmount * houseCut) / 100);
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

    function setHouseCut(uint256 _newHouseCut) external restricted {
        houseCut = _newHouseCut;
    }

    function setHouseAddress(address _newAddress) external restricted {
        houseAddress = _newAddress;
    }
}