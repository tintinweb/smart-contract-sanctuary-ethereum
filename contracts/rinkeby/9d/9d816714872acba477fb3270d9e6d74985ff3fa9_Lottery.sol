/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

pragma solidity ^0.8.16;

contract Lottery {
    address public Admin;
    address payable[] public players;
    address private houseAddress = 0x7a029a259EdA95c0e35B383F1a3baf68aE98C193;
    uint256 houseCut = 5;
    uint256 winnerCut = 95;
    uint256 public entryPrice = .01 ether;
    uint256 public potFullAmount = .02 ether;

    constructor() {
        Admin = msg.sender;
    }

    // Only manager block
    modifier restricted() {
        require(msg.sender == Admin, "You are not the owner");
        _;
    }

    modifier isPotFull() {
        require(address(this).balance == potFullAmount, "Pot is not full");
        _;
    }

    function enter() public payable {
        require(msg.value == entryPrice, "incorrent value sent to contract");
        players.push(payable(msg.sender));
        if (address(this).balance == potFullAmount) {
            pickWinner();
        }
    }

    //Pick a winning address based on a sudo-random hash converted to initergers.
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, players)
                )
            );
    }

    //pickWinner() picks the winning address, Only manager can call this function. After each round the player array is reset to 0.
    function pickWinner() public isPotFull {
        uint256 index = random() % players.length;
        uint256 balance = address(this).balance;
        players[index].transfer((balance * winnerCut) / 100);
        payable(houseAddress).transfer((balance * houseCut) / 100);
        delete players;
    }

    function setEntryPrice(uint256 _newEntryPrice) external restricted {
        entryPrice = _newEntryPrice;
    }

    function setWinnerCut(uint256 _newWinnerCut) external restricted {
        winnerCut = _newWinnerCut;
    }

    function setHouseCut(uint256 _newHouseCut) external restricted {
        houseCut = _newHouseCut;
    }

    //Return all the players who entered.
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}