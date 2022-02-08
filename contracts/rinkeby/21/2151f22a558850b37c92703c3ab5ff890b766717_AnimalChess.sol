/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
// import "hardhat/console.sol";
contract AnimalChess {

    address admins;
    mapping (address => bool) private owners;
    address [] private ownersArr;
    mapping (string=>GameRoom) public play_list;

    enum animalType {
        animal1,
        animal2,
        animal3,
        animal4,
        animal5,
        animal6,
        animal7,
        animal8
    }

    enum winner {
        A,
        B,
        none
    }

    enum Game {
        A,
        B,
        draw
    }

    struct GameRoom {
        userInfo playA;
        userInfo playB;
        winner Final_Result; // 最後結果
    }

    struct userInfo {
        address player;
        uint[] aniArr;
        uint amount;
    }

    event winnerEvent(uint winnerUint);
    event roomIDEvent(string roomIDUint);
    event animalArrAEvent(uint[] animalArrA);
    event animalArrBEvent(uint[] animalArrB);

    constructor(){
        admins = msg.sender;
    }

    modifier onlyAdmins() {
        require(msg.sender == admins, "Not owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    modifier onlyOwners() {
        require(msg.sender == admins || owners[msg.sender], "Not owner");
        _;
    }

    function Init(string memory roomID) public payable{
        userInfo memory deplayer;
        deplayer.player = msg.sender;
        deplayer.amount = msg.value;
        if(play_list[roomID].playA.player == address(0x0)){
            play_list[roomID].playA = deplayer;
        }else if (play_list[roomID].playB.player == address(0x0)){
            require(play_list[roomID].playA.player != deplayer.player," the same player");
            play_list[roomID].playB = deplayer;
        }
    }

    function addOwner(address newOwner) external onlyAdmins validAddress(newOwner){
        require(ownersArr.length < 3,"owner already maximum");
        require(!owners[newOwner],"owner already exist");
        owners[newOwner] = true;
        ownersArr.push(address(newOwner));
    }

    function deleteOwner(address delOwner) external onlyAdmins validAddress(delOwner){
        deleteOwnerArr(delOwner);
        delete owners[delOwner];
    }

    function deleteOwnerArr(address delOwner) private validAddress(delOwner){
        for(uint i = 0; i < ownersArr.length; i++) {
             if(delOwner == ownersArr[i]) {
                 delete ownersArr[i];
                 ownersArr[i] = ownersArr[ownersArr.length - 1];
                 ownersArr.length-1;
             }
        }
    }

    function struggleAction(string memory roomID , address _addrA , uint[] memory _animalArrA, address _addrB , uint[] memory _animalArrB) public onlyOwners {
        require(_animalArrA.length == _animalArrB.length,"_animalArrA.length != _animalArrB.length");
        require(play_list[roomID].playA.player == _addrA || play_list[roomID].playA.player == _addrB,"_addrA not Include playA");        
        require(play_list[roomID].playB.player == _addrA || play_list[roomID].playB.player == _addrB,"_addrB not Include playB");       
        if (play_list[roomID].playA.player == _addrA){
            play_list[roomID].playA.aniArr = _animalArrA;
            play_list[roomID].playB.aniArr = _animalArrB;
        } else if (play_list[roomID].playB.player == _addrA){
            play_list[roomID].playA.aniArr = _animalArrB;
            play_list[roomID].playB.aniArr = _animalArrA;
        }
        animalStruggle(roomID);
    }

    function animalStruggle(string memory roomID) private {
        uint winA = 0;
        uint winB = 0;
        uint[] memory aniAArr = play_list[roomID].playA.aniArr;
        uint[] memory aniBArr = play_list[roomID].playB.aniArr;
        for (uint i = 0; i < aniAArr.length; i++) {
            Game win = gameAction(aniAArr[i], aniBArr[i]);
            if (win == Game.A){
                winA++;
            } else if (win == Game.B){
                winB++;
            }
            uint remainGame = aniAArr.length - i;
            if (winA > remainGame/2 || winB > remainGame/2) {
                break;
            }
        }
        uint winnerNum;
        if (winA > winB) {
            play_list[roomID].Final_Result = winner.A;
            winnerNum = 1;
        } else if (winB > winA) {
            play_list[roomID].Final_Result = winner.B;
            winnerNum = 2;
        } else if (winA == winB) {
            play_list[roomID].Final_Result = winner.none;
            winnerNum = 0;
        }
        emit winnerEvent(winnerNum);
        emit animalArrAEvent(aniAArr);
        emit animalArrBEvent(aniBArr);
        emit roomIDEvent(roomID);
        giveMoney(roomID,SafeMath.add(play_list[roomID].playA.amount,play_list[roomID].playB.amount));
    }

    function gameAction(uint aniA ,uint aniB) private pure returns (Game) {

        if (aniA == 1 && aniB == 8) {
            return Game.A;
        }

        if (aniA == 8 && aniB == 81) {
            return Game.B;
        }

        if (aniA > aniB) {
            return Game.A;
        } else if (aniB > aniA) {
            return Game.B;
        } else {
            return Game.draw;
        }
    }

    function giveMoney(string memory roomID ,uint totalAmount) public onlyOwners {
        winner result = play_list[roomID].Final_Result;
        if (result == winner.A){
            addValue(play_list[roomID].playA.player,totalAmount);
        } else if (result == winner.B){
            addValue(play_list[roomID].playB.player,totalAmount);
        } else if (result == winner.none){
            addValue(play_list[roomID].playA.player, play_list[roomID].playA.amount);
            addValue(play_list[roomID].playB.player, play_list[roomID].playB.amount);
        }
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function addValue(address _to, uint value1) public onlyOwners validAddress(_to) {
        payable(_to).transfer(value1);
    }

}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a); // underflow 
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a); // overflow
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}