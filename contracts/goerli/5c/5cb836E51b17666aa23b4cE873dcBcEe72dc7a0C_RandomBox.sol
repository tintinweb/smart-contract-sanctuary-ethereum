// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
//*************************
// 2022 블록체인 텀프로젝트
//*************************
contract RandomBox
{
    //******************************
    struct Box {
        string name;    // 뽑기 이름
        Item[] items;   // 아이템들
        uint remainPercents;  // 남은 확률 (=꽝 확률)
        string comment; // 내용
    }
    //******************************
    struct Item {
        string name;  // 아이템 이름
        uint percent;   // 뽑힐 확률
        string comment; // 내용
    }
    //*******************************************************
    address admin;
    mapping(string => Box) public randomBoxs;
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
    function createBox(string calldata boxName, string calldata comment) onlyAdmin() public {  // 뽑기 생성
        randomBoxs[boxName].name = boxName;
        randomBoxs[boxName].remainPercents = 1000;
        randomBoxs[boxName].comment = comment;
    }
    //*****************************************************************************************************************************************
    function setItem(string calldata boxName, string calldata name, uint percent, string calldata comment) onlyAdmin() public returns (uint) {
        require(keccak256(abi.encodePacked(randomBoxs[boxName].name)) == keccak256(abi.encodePacked(boxName)), "Unknown RandomBox");  // 뽑기 should exist

        for (uint i=0; i<randomBoxs[boxName].items.length; i++)
            if (randomBoxs[boxName].items[i].percent == percent)
                return 1; //[Fail]:중복된 아이템 확률

        if ((randomBoxs[boxName].remainPercents - percent) < 0 )
            return 2; //[Fail]:퍼센트 초과

        for (uint i=0; i<randomBoxs[boxName].items.length; i++){
            if (keccak256(abi.encodePacked(randomBoxs[boxName].items[i].name)) == keccak256(abi.encodePacked(name))){    // if Item name exists
                randomBoxs[boxName].remainPercents += randomBoxs[boxName].items[i].percent;

                randomBoxs[boxName].items[i].percent = percent;    // set percent
                randomBoxs[boxName].items[i].comment = comment;    // set comment
                randomBoxs[boxName].remainPercents -= percent;
                return 0; //[Success]:아이템 수정
            }
        }

        // if Item ID doesn't exists
        randomBoxs[boxName].items.push(Item(name, percent, comment));    // Add Item
        randomBoxs[boxName].remainPercents -= percent;
        return 0; //[Success]:아이템 추가
    }
    //*****************************************************************************************************************************************
    function getItemPercent(string calldata boxName, uint num) public view returns (uint) {  // get 아이템 뽑기 확률
        require(num <= randomBoxs[boxName].items.length);    // reason : Invalid item number.
        return randomBoxs[boxName].items[num].percent;
    }

    function getItemsLengthOfBox(string calldata boxName) public view returns (uint) {    // get 랜덤박스의 아이템 갯수
        return randomBoxs[boxName].items.length;
    }

    function getKkwangPercent(string calldata boxName) public view returns (uint) {  // get 랜덤박스 꽝 뽑힐 확률
        return randomBoxs[boxName].remainPercents;
    }
    //*****************************************************************************************************************************************
    function openRandomBox(string calldata boxName) public returns (string memory) {
        require(keccak256(abi.encodePacked(randomBoxs[boxName].name)) == keccak256(abi.encodePacked(boxName)), "Unknown RandomBox");  // 뽑기 should exist
        
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 1000;
        randNonce++;

        uint randomGauge = 0;

        for (uint i=0; i<randomBoxs[boxName].items.length; i++){
            randomGauge += randomBoxs[boxName].items[i].percent;
            if (random < randomGauge)
                return randomBoxs[boxName].items[i].name;
        }
        return "kkwang";
    }
    //*****************************************************************************************************************************************
}