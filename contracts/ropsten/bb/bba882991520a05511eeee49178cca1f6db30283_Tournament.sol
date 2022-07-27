/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Tournament {
    struct Match {
        address opponent1;
        address opponent2;
        uint round;
        uint score_1;
        uint score_2;
        address winner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    string public name = "Unnamed Tournament";
    uint public status = 0;
    uint public size;
    uint public round = 2;
    uint256 public prize_pool = 0;
    uint256 public register_fee = 10000;
    address public owner;
    address[] public players;

    Match[] public matches;

    mapping(address => bool) public participants;

    constructor() // string memory _name,
    // uint256 _register_fee,
    // uint _round
    {
        owner = msg.sender;
        name = "New Game";
        round = 2;
        size = 2**round;
        register_fee = 1;
    }

    // [owner] 开始报名
    function startRegister() external onlyOwner {
        require(status == 0, "wrong status");
        status = 1;
    }

    // [选手] 报名
    function register() external payable returns (bool) {
        require(status == 1, "Can not register");
        require(participants[msg.sender] != true, "Already registered");
        require(msg.value == register_fee, "Wrong register fee");
        require(players.length < size, "Enough players");
        participants[msg.sender] = true;
        players.push(msg.sender);
        prize_pool += msg.value;
        return true;
    }

    // [owner] 开始比赛
    function start() external onlyOwner {
        require(players.length == size, "No enough players");
        this._createMatch();
        status = 2;
    }

    function _createMatch() external {
        uint _totalPlayers = players.length;
        for (uint _round = 1; _round <= round; _round++) {
            uint totalMatch = _totalPlayers / (2**_round);

            for (uint _mathIndex = 0; _mathIndex < totalMatch; _mathIndex++) {
                address opponent1 = address(0);
                address opponent2 = address(0);

                if (_round == 1) {
                    opponent1 = players[_mathIndex * 2];
                    opponent2 = players[_mathIndex * 2 + 1];
                }

                Match memory _match = Match(
                    opponent1,
                    opponent2,
                    _round,
                    0,
                    0,
                    address(0)
                );
                matches.push(_match);
            }
        }
    }

    // [owner] 记录比赛结果
    function report(
        uint _matchIndex,
        uint score_1,
        uint score_2,
        address winner
    ) external onlyOwner {
        matches[_matchIndex].score_1 = score_1;
        matches[_matchIndex].score_2 = score_2;
        matches[_matchIndex].winner = winner;

        // find next round and update oppenent
        uint nextMathIndex = 0;
        bool firstPlace = false;
        if (_matchIndex == 0) {
            nextMathIndex = 2;
            firstPlace = true;
        }
        if (_matchIndex == 1) {
            nextMathIndex = 2;
            firstPlace = false;
        }
        if (nextMathIndex != 0) {
            if (firstPlace) {
                matches[nextMathIndex].opponent1 = winner;
            } else {
                matches[nextMathIndex].opponent2 = winner;
            }
        }
    }

    // [all] 获取冠军
    function champaign() external view returns (address _winner) {
        return matches[matches.length - 1].winner;
    }

    // [owner] 结束比赛
    function end() external onlyOwner {
        require(status == 2);
        status = 3;
    }

    // [冠军] 拿奖励
    function claim() external {
        require(msg.sender == this.champaign(), "You are not the champaign");
        prize_pool = 0;
        payable(msg.sender).transfer(prize_pool);
    }
}