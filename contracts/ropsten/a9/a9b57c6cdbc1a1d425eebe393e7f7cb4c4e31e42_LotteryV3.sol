/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity ^0.4.23;

/**
 * @title 以太坊彩票投注合约，主要功能点：1）投注；2）开奖；3）退奖；4）获取奖池奖金；5）返回当前期数；6）返回中奖者地址；7）返回参与彩民的地址 每期投注金额 0.001 ehter ~= 2.5 usd
 * @dev Martin
 */
contract LotteryV3 {
    address manager;            // 管理员
    address[] players;          // 投了注的彩民
    address winner;             // 上期彩票的胜出者
    uint256 round = 1;          // 第几期

    constructor() public {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(manager == msg.sender);
        _;
    }

    // 投注
    function play() public payable {
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }

    //开奖
    function lottery() public payable {
        // 生成随机下标
        bytes memory v1 = abi.encodePacked(block.difficulty, now, players.length);
        bytes32 v2 = keccak256(v1);
        uint v3 = uint256(v2) % players.length;
        // 获取中奖者
        winner = players[v3];
        // 清空plays
        delete players;
        // 期数加1
        round++;
        // 把奖池的金额转账给中奖者
        winner.transfer(address(this).balance);
    }

    // 退奖
    function refund() public onlyManager {
        require(players.length != 0);
        // 清空plays
        delete players;
        // 期数加1
        round++;
        // 把奖池的金额退还给每一个玩家
        for (uint i = 0; i < players.length; i++) {
            players[i].transfer(1 ether);
        }
    }

    // 获取奖金池的金额
    function getAmount() public view returns(uint256) {
        return address(this).balance;
    }

    // 获取管理员地址
    function getManagerAddress() public view returns(address) {
        return manager;
    }

    // 返回当前期数
    function getRound() public view returns(uint256) {
        return round;
    }

    // 返回中奖者地址
    function getWinner() public view returns(address) {
        return winner;
    }

    // 返回参与彩民的地址
    function getPlays() public view returns(address[]) {
        return players;
    }
}