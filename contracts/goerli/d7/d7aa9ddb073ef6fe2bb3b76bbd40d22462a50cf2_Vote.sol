/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

/// @dev 单个选项信息：名称+图片
struct VoteOptionObj {
    string name;        // 选项名称
    string url;         // 选项图片地址
}

/// @dev 项目完整信息
struct VotePrjDetail {
    string topicName;                   // 项目名称
    VoteOptionObj[] options;            // 选项列表
    uint256 startTime;                  // 投票开始时间
    uint256 endTime;                    // 投票结束时间
    uint8 voteLimitPerAddr;             // 每个地址投票上限
    string projectDesc;                 // 项目备注信息

    address projectAddr;                // 项目合约地址
    uint256[] voteCountList;            // 选项投票数量
}


contract Vote {
    /// @dev 当前项目状态变量
    string public topicName;
    VoteOptionObj[] public options;
    uint256 public startTime;
    uint256 public endTime;
    uint8 public voteLimitPerAddr;
    string public projectDesc;

    address public owner;
    address public starter;

    mapping(string => bool) public existOption;

    mapping(string => uint256) public optionVoteCount;
    mapping(address => uint8) public userVoteCount;

    /// @dev 投票操作触发的事件
    event DoVote(address indexed voter, string indexed option);

    /// @dev 投票预检修饰符
    modifier checkVote(address _voter, string memory _option){
        // 是否是owner调用
        require(owner == msg.sender, "Error: Forbidden To Vote");

        // starter 不能投票
        require(starter != _voter, "Error: Starter Can't Vote");

        // 是否在投票时间内
        require(startTime < block.timestamp, "Error: Vote Not Start");
        require(block.timestamp < endTime, "Error: Vote Has Ended");

        // 用户投票是否达到上限
        require(userVoteCount[_voter] < voteLimitPerAddr, "Error: No More Vote Chance");

        // 当前选项是否存在
        require(existOption[_option], "Error: Wrong Vote Option");
        _;
    }
    
    /// @dev 创建新的投票项目
    constructor(
        string memory _topicName,  
        VoteOptionObj[] memory _options,
        uint256 _startTime, 
        uint256 _endTime,
        uint8 _voteLimitPerAddr,
        string memory _projectDesc,
        address _starter
    ){
        topicName = _topicName;
        startTime = _startTime;
        endTime = _endTime;
        voteLimitPerAddr = _voteLimitPerAddr;
        projectDesc = _projectDesc;

        owner = msg.sender;
        starter = _starter;

        // 选项处理
        for(uint i=0; i < _options.length; i++){
            options.push(
                VoteOptionObj(
                    _options[i].name,
                    _options[i].url
                )
            );
            existOption[_options[i].name] = true;
        }
    }

    /// @dev 用户投票操作
    /// @param
    ///     _voter: 投票人
    ///     _option: 投票选项
    function doVote(address _voter, string calldata _option) external checkVote(_voter, _option) {
        userVoteCount[_voter] += 1;
        optionVoteCount[_option] += 1;

        emit DoVote(_voter, _option);
    }

    /// @dev 获取投票项目详情
    /// @return votePrjDetail 当前项目的投票详情
    function getVoteDetail() external view returns(VotePrjDetail memory votePrjDetail){
        // 选项投票数
        uint256[] memory voteCountList = new uint256[](options.length);
        for(uint8 i=0; i < options.length; i++){
            voteCountList[i] = optionVoteCount[options[i].name];
        }

        // 投票详情
        votePrjDetail = VotePrjDetail(
            topicName,
            options,
            startTime,
            endTime,
            voteLimitPerAddr,
            projectDesc,
            address(this),
            voteCountList
        );
    }   
}