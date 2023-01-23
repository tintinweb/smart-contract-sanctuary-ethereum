/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract CatFight {
    LinkTokenInterface controltoken;
    IERC721 NFTtoken;
    event FinishedOneFight(address winner, uint256 roomnum);
    event EnterFirstroom(address enterer, uint256 roomnum);

    struct Roominfo {
        bool status;
        address[] fighters;
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
    uint256 public showfirst;
    uint256 public showsecond;
    uint256 public firsttoken;
    uint256 public secondtoken;

    address public chainlinkaddress =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address public nfttokenaddress = 
        0xA3D40B9be89e1074309Ed8EFf9F3215F323C8b19;

    constructor() {
        controltoken = LinkTokenInterface(chainlinkaddress);
        NFTtoken = IERC721(nfttokenaddress);
    }

    function enterroom(uint256 _roomnum, uint256 _tokenId) public payable {
        require(msg.sender == NFTtoken.ownerOf(_tokenId), "This is not your NFT!");
        require(msg.value >= 10, "You don't have enough balance!");
        firstlink = controltoken.balanceOf(msg.sender);
        if (_roomnum > maxroomnum) {
            maxroomnum = _roomnum;
            roominfo[_roomnum] = Roominfo({
                status: false,
                fighters: new address[](0)
            });
            firstrandom = 0;
            secondrandom = 0;
        }
        firstrandom = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000) + 1;
        roominfo[_roomnum].fighters.push(msg.sender);
        firsttoken = _tokenId;
    }

    function fight(uint256 _roomnum, uint256 _tokenId) public payable {
        require(msg.sender == NFTtoken.ownerOf(_tokenId), "This is not your NFT!");
        require(msg.value >= 10, "You don't have enough balance!");
        require(
            roominfo[_roomnum].status != true,
            "This betting game is already finished!"
        );
        require(
            roominfo[_roomnum].fighters.length != 2,
            "There are already enough players!"
        );
        roominfo[_roomnum].fighters.push(msg.sender);
        require(
            roominfo[_roomnum].fighters.length == 2,
            "There aren't enough or more players!"
        );
        secondrandom = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000) + 1;
        secondtoken = _tokenId;
        if (firstrandom > secondrandom) {
//            NFTtoken.approve(roominfo[_roomnum].fighters[0], secondtoken);
            NFTtoken.transferFrom(roominfo[_roomnum].fighters[1], roominfo[_roomnum].fighters[0], secondtoken);
        } else {
//            NFTtoken.approve(roominfo[_roomnum].fighters[1], firsttoken);
            NFTtoken.transferFrom(roominfo[_roomnum].fighters[0], roominfo[_roomnum].fighters[1], firsttoken);
        }
        roominfo[_roomnum].status = true;
        emit FinishedOneFight(roominfo[_roomnum].fighters[0], _roomnum);
    }
}