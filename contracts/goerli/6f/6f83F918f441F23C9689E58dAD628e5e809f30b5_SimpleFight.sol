// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract SimpleFight {
    LinkTokenInterface controltoken;
    event FinishedOneFight(address winner, uint256 roomnum);
    event EnterFirstroom(address enterer, uint256 roomnum);

    struct Roominfo {
        bool status;
        address[] fighters;
        uint256[] randoms;
    }

    mapping(address => uint256) public reward;
    mapping(uint256 => Roominfo) public roominfo;

    uint256 public firstrandom;
    uint256 public secondrandom;
    uint256 public maxroomnum;
    uint256 public firstether;
    uint256 public secondether;
    uint256 public firstlink;
    uint256 public secondlink;
    
    address public chainlinkaddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    constructor () {
        controltoken = LinkTokenInterface(chainlinkaddress);
    }

    function enterroom(uint256 _roomnum) public payable {
        require(msg.value >= 10, "You don't have enough balance!");
        firstlink = controltoken.balanceOf(msg.sender);
        firstether = msg.value;
        if(_roomnum > maxroomnum) {
            maxroomnum = _roomnum;
            roominfo[_roomnum] = Roominfo({
                status: false,
                randoms: new uint256[](0),
                fighters: new address[](0)
            });
            firstrandom = 0;
            secondrandom = 0;
        }
        firstrandom = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000 + 1;
        roominfo[_roomnum].fighters.push(msg.sender);
        emit EnterFirstroom(msg.sender, _roomnum);
    }

    function fight(uint256 _roomnum) public payable {
        secondether = msg.value;
        secondlink = controltoken.balanceOf(msg.sender);
        require(msg.value >= 10, "You don't have enough balance!");
        require(roominfo[_roomnum].status != true, "This betting game is already finished!");
        require(roominfo[_roomnum].fighters.length != 2, "There are already enough players!");
        roominfo[_roomnum].fighters.push(msg.sender);
        require(roominfo[_roomnum].fighters.length == 2, "There aren't enough players!");
        secondrandom = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000 + 1;
        uint256 benifit = 1000000000000000000;
        if(firstrandom > secondrandom) {
            controltoken.transferFrom(roominfo[_roomnum].fighters[1], roominfo[_roomnum].fighters[0], benifit);
        } else {
            controltoken.transferFrom(roominfo[_roomnum].fighters[0], roominfo[_roomnum].fighters[1], benifit);
        }
        roominfo[_roomnum].status = true;
        emit FinishedOneFight(roominfo[_roomnum].fighters[0], _roomnum);
    }
}