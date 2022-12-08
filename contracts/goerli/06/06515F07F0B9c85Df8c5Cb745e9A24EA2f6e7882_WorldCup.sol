/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "hardhat/console.sol";

contract WorldCup {
    // 1. 状态变量：管理员、所有玩家、获奖者地址、第几期、参赛球队
    // 2. 核心方法：下注、开奖、兑现
    // 3. 辅助方法：获取奖金池金额、管理员地址、当前期数、参与人数、所有玩家、参赛球队

    // 管理员
    address public admin;
    // 第几期
    uint8 public currRound;

    // 参赛球队
    string[] public countries = [
        "GERMANY",
        "FRANCH",
        "CHINA",
        "BRIZAL",
        "KOREA"
    ];
    // 期数 => 玩家
    mapping(uint8 => mapping(address => Player)) players;
    // 期数 => 投注各球队的玩家
    mapping(uint8 => mapping(Country => address[])) public countryToPlayers;
    // 玩家对应赢取的奖金
    mapping(address => uint256) public winnerVaults;

    // 投注截止时间-使用不可变量，可通过构造函数传值，部署后无法改变
    uint256 public immutable deadline;
    // 所有玩家待兑现的奖金
    uint256 public lockedAmts;

    enum Country {
        GERMANY,
        FRANCH,
        CHINA,
        BRAZIL,
        KOREA
    }

    event Play(uint8 _currRound, address _player, Country _country);
    event Finialize(uint8 _currRound, uint256 _country);
    event ClaimReward(address _claimer, uint256 _amt);

    // 验证管理员身份
    modifier onlyAdmin() {
        require(msg.sender == admin, "not authorized!");
        _;
    }

    // 玩家投注信息
    struct Player {
        // 是否开奖
        bool isSet;
        // 投注的球队份额
        mapping(Country => uint256) counts;
    }

    constructor(uint256 _deadline) {
        admin = msg.sender;
        require(
            _deadline > block.timestamp,
            "WorldCupLottery: invalid deadline!"
        );
        deadline = _deadline;
    }

    // 下注过程
    function play(Country _selected) external payable {
        // 参数校验
        require(msg.value == 1 gwei, "invalid funds provided!");

        require(block.timestamp < deadline, "it's all over!");

        // 更新 countryToPlayers
        countryToPlayers[currRound][_selected].push(msg.sender);
        // 更新 players（storage 是引用传值，修改会同步修改原变量）
        Player storage player = players[currRound][msg.sender];
        // player.isSet = false;
        player.counts[_selected] += 1;

        emit Play(currRound, msg.sender, _selected);
    }

    // 开奖过程
    function finialize(Country _country) external onlyAdmin {
        // 找到 winners
        address[] memory winners = countryToPlayers[currRound][_country];
        // 分发给所有压中玩家的实际奖金
        uint256 distributeAmt;

        // 本期总奖励金额（奖池金额 - 所有玩家待兑现的奖金）
        uint currAvalBalance = getVaultBalance() - lockedAmts;
        // console.log(
        //     "currAvalBalance:",
        //     currAvalBalance,
        //     "winners count:",
        //     winners.length
        // );

        for (uint i = 0; i < winners.length; i++) {
            address currWinner = winners[i];

            // 获取每个地址应该得到的份额
            Player storage winner = players[currRound][currWinner];
            if (winner.isSet) {
                // console.log(
                //     "this winner has been set already, will be skipped!"
                // );
                continue;
            }

            winner.isSet = true;
            // 玩家购买的份额
            uint currCounts = winner.counts[_country];

            // （本期总奖励 / 总获奖人数）* 当前地址持有份额
            uint amt = (currAvalBalance /
                countryToPlayers[currRound][_country].length) * currCounts;
            // 玩家对应赢取的奖金
            winnerVaults[currWinner] += amt;
            distributeAmt += amt;
            // 放入待兑现的奖金池
            lockedAmts += amt;

            // console.log("winner:", currWinner, "currCounts:", currCounts);
            // console.log(
            //     "reward amt curr:",
            //     amt,
            //     "total:",
            //     winnerVaults[currWinner]
            // );
        }

        // 未分完的奖励即为平台收益
        uint giftAmt = currAvalBalance - distributeAmt;
        if (giftAmt > 0) {
            winnerVaults[admin] += giftAmt;
        }

        emit Finialize(currRound++, uint256(_country));
    }

    // 奖金兑现
    function claimReward() external {
        uint256 rewards = winnerVaults[msg.sender];
        require(rewards > 0, "nothing to claim!");

        // 玩家领取完奖金置为 0
        winnerVaults[msg.sender] = 0;
        // 从待兑现奖金池中移除该玩家份额
        lockedAmts -= rewards;
        // 向玩家地址转赢得的奖金
        (bool succeed, ) = msg.sender.call{value: rewards}("");
        require(succeed, "claim reward failed!");

        //console.log("rewards:", rewards);

        emit ClaimReward(msg.sender, rewards);
    }

    // 获取奖池金额
    function getVaultBalance() public view returns (uint256 bal) {
        bal = address(this).balance;
    }

    // 获取当期下注当前球队的人数
    function getCountryPlayers(
        uint8 _round,
        Country _country
    ) external view returns (uint256) {
        return countryToPlayers[_round][_country].length;
    }

    // 获取当前玩家当期押注份额
    function getPlayerInfo(
        uint8 _round,
        address _player,
        Country _country
    ) external view returns (uint256 _counts) {
        return players[_round][_player].counts[_country];
    }
}