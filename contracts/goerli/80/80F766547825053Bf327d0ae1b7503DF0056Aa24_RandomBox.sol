// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract RandomBox
{
    //******************************
    struct Box {
        uint id;      // 뽑기 ID
        string name;    // 뽑기 이름
        Item[] items;   // 아이템들
        uint percents;  // 남은 확률 (=꽝 확률)
        string comment; // 내용
    }
    //******************************
    struct Item {
        string itemId;  // 아이템 ID
        uint percent;   // 뽑힐 확률
        string comment; // 내용
    }
    //*******************************************************
    address admin;
    mapping(uint => Box) public blindBoxs;
    uint blindBoxs_Length = 0;
    uint randNonce = 0;
    //********************************************************
    modifier onlyAdmin() {
        require(msg.sender == admin, "Sender not authorized");
        _;
    }
    //********************************************************
    constructor () {
        admin = msg.sender;
    }
    //*****************************************************************************************************************************************
    function createBox(string calldata boxName, string calldata comment) onlyAdmin() public returns (uint) {  // 뽑기 생성
        blindBoxs[blindBoxs_Length].id = blindBoxs_Length;
        blindBoxs[blindBoxs_Length].name = boxName;
        blindBoxs[blindBoxs_Length].percents = 1000;
        blindBoxs[blindBoxs_Length].comment = comment;

        blindBoxs_Length += 1;

        return blindBoxs[blindBoxs_Length-1].id; // 뽑기 ID 반환
    }
    //*****************************************************************************************************************************************
    function setItem(uint boxId, string calldata itemId, uint percent, string calldata comment) onlyAdmin() public returns (uint) {
        require(blindBoxs[boxId].id == boxId);  // 뽑기 should exist

        for (uint i=0; i<blindBoxs[boxId].items.length; i++)
            if (blindBoxs[boxId].items[i].percent == percent)
                return 1; //[Fail]:중복된 아이템 확률

        if ((blindBoxs[boxId].percents - percent) < 0 )
            return 2; //[Fail]:퍼센트 초과

        for (uint i=0; i<blindBoxs[boxId].items.length; i++){
            if (keccak256(abi.encodePacked(blindBoxs[boxId].items[i].itemId)) == keccak256(abi.encodePacked(itemId))){    // if Item ID exists
                blindBoxs[boxId].percents += blindBoxs[boxId].items[i].percent;

                blindBoxs[boxId].items[i].percent = percent;    // set percent
                blindBoxs[boxId].items[i].comment = comment;    // set comment
                blindBoxs[boxId].percents -= percent;
                return 0; //[Success]:아이템 수정
            }
        }

        // if Item ID doesn't exists
        blindBoxs[boxId].items.push(Item(itemId, percent, comment));    // Add Item
        blindBoxs[boxId].percents -= percent;
        return 0; //[Success]:아이템 추가
    }
    //*****************************************************************************************************************************************
    function getPercent(uint boxId, string memory itemId) public view returns (uint percent) {
        for (uint i=0; i<blindBoxs[boxId].items.length; i++){
            if (keccak256(abi.encodePacked(blindBoxs[boxId].items[i].itemId)) == keccak256(abi.encodePacked(itemId))){    // if Item ID exists
                percent = blindBoxs[boxId].items[i].percent;
                return percent;
            }
        }
    }

    function getKkwangPercent(uint boxId) public view returns (uint) {
        return blindBoxs[boxId].percents;
    }
    //*****************************************************************************************************************************************
    function openRandomBox(uint boxId) public returns (string memory) {
        require(blindBoxs[boxId].id == boxId);
        
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 1000;
        randNonce++;

        uint randomBox = 0;

        for (uint i=0; i<blindBoxs[boxId].items.length; i++){
            randomBox += blindBoxs[boxId].items[i].percent;
            if (random < randomBox)
                return blindBoxs[boxId].items[i].itemId;
        }
        return "kkwang";
    }
    //*****************************************************************************************************************************************
}