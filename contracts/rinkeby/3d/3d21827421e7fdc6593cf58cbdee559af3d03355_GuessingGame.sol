/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract GuessingGame {
    // * 一全域變數owner，使用public: 為合約管理者的address
       address public owner;
    // * 一modifier onlyOwner:用來判斷只有owner可以執行
       modifier onlyOwner(){
           require (msg.sender == owner);
           _;
       }

       event Win(address winner);

    // * 一mapping winCount，使用public:儲存玩家贏的次數
       mapping(address => uint) public winCount;
    // * 取亂數 方法：get_random()，使用private，取0到1000的亂數
    // 作法：
    // 1、首先透過玩遊戲當下區塊鏈上資料(block.timestamp,blockhash(block.number-1))做hash後取得random(型態為bytes32)
    // 2、再將random 轉型成 uint --> uint(random)
    // 3、若假如uint(random)為67，那要取0-100的亂數 --> 67%100=67，故亂數為67，可以發現除數若放100，取出的餘數永遠小於100
    // 4、若假如uint(random)為450，那要取0-300的亂數 --> 450%300=150，故亂數為150，，可以發現除數若放300，取出的餘數永遠小於300
    function get_random() private view returns (uint256) {
        bytes32 random = keccak256(
            abi.encodePacked(block.timestamp, blockhash(block.number - 1))
        );
        return uint(random) % 1000;
    }

    // * 玩遊戲 方法 play，使用public
    // 1、玩遊戲者必須傳送5000 wei。
    // 2、取亂數，取出得值需>500，代表可獲取10000 wei獎勵
    // 3、取亂數，取出得值需<500，代表投入的5000 wei被合約沒收
    // 4、贏家透過mapping紀錄贏的次數
    // 5、最後將贏家的地址使用 event Win 紀錄
       function play() public payable{
           require (msg.value == 5000 wei);
           if (get_random()>500){
                payable(msg.sender).transfer(10000 wei);
                winCount[msg.sender]++;
                emit Win(msg.sender);
           }
       }
    // * 此方法為合約管理者隨時投入資進進入，
    // 故只有 owner 可以使用所以缺了modifier onlyOwner，請將他補上。
    receive() external payable onlyOwner {
        require(msg.value == 1 wei);
    }

    // *一個contructor，部署合約者必須傳入0.01顆Ether
    constructor() payable {
        owner = msg.sender;
        require(msg.value == 0.001 ether);
    }
}