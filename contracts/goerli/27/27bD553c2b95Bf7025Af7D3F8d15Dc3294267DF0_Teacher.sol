// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Bribery {
    // 教师专项用款地址
    address public owner;

    // 映射表，表示 { 存储用户地址: 余额 }
    mapping(address => uint) public balances;

    // 部署合约时，可以接受存款，
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You aren't the owner");
        _;
    }

    // 存款
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // 查询余额
    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    // 行贿扣款金额，1分 = 1 wei
    function withdraw(address to, uint amount) internal onlyOwner {
        require(balances[to] > 0, "Insufficient balance");
        balances[to] -= amount;
        payable(owner).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IScoreSheet {
    event SetScore(address indexed student, uint8 score, string course);

    /**
     * 设置学生成绩,
     * @param student 学生地址，表示学生昵称
     * @param score 成绩
     * @param course 课目
     *
     */
    function setScore(
        address student,
        uint8 score,
        string memory course
    ) external;

    /**
     * 获取学生成绩
     * @param student 学生地址，表示昵称
     * @param course 课目
     */
    function getScore(
        address student,
        string memory course
    ) external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IScoreSheet.sol";

contract ScoreSheet is IScoreSheet {
    // 存储老师地址
    address public teacher;
    // 映射表，表示 { 学生地址 : { 课目: 分数 } }
    mapping(address => mapping(string => uint8)) public scores;

    // 定义错误抛出
    error InvalidScore();

    // 构造函数
    constructor() payable {
        teacher = msg.sender;
    }

    modifier onlyTeacher() {
        require(msg.sender == teacher, "You aren't the teacher");
        _;
    }

    function setScore(
        address student,
        uint8 score,
        string memory course
    ) external onlyTeacher {
        if (score > 100) revert InvalidScore();
        scores[student][course] = score;
        emit SetScore(student, score, course);
    }

    function getScore(
        address student,
        string memory course
    ) external view returns (uint8) {
        return scores[student][course];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ScoreSheet.sol";
import "./Bribery.sol";

contract Teacher is Bribery {
    // 合约拥有者
    address public scoreSheet;
    uint public buySocreAmount = 1;

    // 部署合约时，可以接受存款，
    constructor() payable {
        owner = msg.sender;

        // 部署成绩表合约，用于存储分数
        ScoreSheet _scoreSheet = new ScoreSheet();
        scoreSheet = address(_scoreSheet);
    }

    // 定义错误抛出
    error BuyScoreByNotAmount();

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    // 设置学生成绩
    function setScore(
        address student,
        uint8 score,
        string memory course
    ) external onlyOwner {
        IScoreSheet(scoreSheet).setScore(student, score, course);
    }

    function setScoreByBuy(
        address student,
        uint8 score,
        string memory course
    ) external payable onlyOwner {
        uint _amount = buySocreAmount * score;
        if (_amount > balances[student]) revert BuyScoreByNotAmount();

        uint8 _score = IScoreSheet(scoreSheet).getScore(student, course);
        IScoreSheet(scoreSheet).setScore(student, _score + score, course);

        withdraw(student, _amount);
    }

    // 查询学生成绩
    function getScore(
        address student,
        string memory course
    ) external view returns (uint8) {
        return IScoreSheet(scoreSheet).getScore(student, course);
    }
}