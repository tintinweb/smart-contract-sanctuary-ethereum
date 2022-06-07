/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// contract FinishContracts {

//     uint finishContractsCount;

//     function finish() public {
//         finishContractsCount++;
//     }
// }

contract Ballot {

    ERC20Basic public token;

    //提案创建完成
    event ProposalCreated(Proposal proposal);
    //投票完成
    event VoteFinish(uint proposalID, bytes option, address sender);
    //提案结束
    event ProposalFinish(uint proposalID);

    //提案状态
    enum ProposalState {
        created, //进行中
        approved, //已通过
        provisioned, //已执行
        rejected //未通过
    }
    // FinishContracts finishContracts;

    //提案
    struct Proposal {
        uint id; //ID
        bytes name; //提案名
        bytes content; //提案内容
        address chairPerson; //发起人
        ProposalState state; //状态
        uint timeStamp; //提案创建时间
    }

    //投票历史
    struct VoteHistory {
        address sender; //地址
        bytes option; //投票类型
    }

    // uint 提案ID
    // bytes 选项
    // address[] 该选项下所有投票者
    mapping(uint => mapping(bytes => address[])) private proposalsVoters;

    //所有提案，类型为动态大小的 Proposal 数组
    Proposal[] private proposals;

    //所有提案选项
    mapping(uint => bytes[]) private proposalOptionsMap;

    //投票历史
    mapping(uint => VoteHistory[]) private voteHistoryMap;

    //新用户发币历史历史（已发过币的新用户记录下，下次就不发了）
    constructor() {
        token = new ERC20Basic();
    }

    //创建提案
    function createProposal(
        bytes memory proposalName,
        bytes memory proposalContent,
        bytes[] memory options
    ) public {
        Proposal memory proposal = Proposal({
            id: proposals.length,
            name: proposalName,
            content: proposalContent,
            chairPerson: msg.sender,
            state: ProposalState.created,
            timeStamp: getNowTime()
        });
        proposals.push(proposal);
        for (uint i = 0; i < options.length; i++) {
            bytes memory option = options[i];
            bytes[] storage proposalOptions = proposalOptionsMap[proposal.id];
            proposalOptions.push(option);
        }
        emit ProposalCreated(proposal);
    }

    //投票
    function vote(uint proposalID, bytes[] memory options) public {
        //禁止给自己投票
        Proposal storage proposal = proposals[proposalID];
        require(
            msg.sender != proposal.chairPerson,
            "You can't vote on your own proposal"
        );
        //禁止给结束的提案投票
        require(proposal.state == ProposalState.created, "The proposal is finished");
        //查看是否投过票
        bool voted = false;
        for (uint index = 0; index < options.length; index++) {
            bytes memory option = options[index];
            address[] memory voters = proposalsVoters[proposalID][option];
            for (uint vIndex = 0; vIndex < voters.length; vIndex++) {
                address voterAddress = voters[vIndex];
                if (voterAddress == msg.sender) {
                    //已投过
                    voted = true;
                    break;
                }
            }
        }
        require(!voted, "Already voted");
        //开始投票
        for (uint index = 0; index < options.length; index++) {
            bytes memory option = options[index];
            address[] storage voters = proposalsVoters[proposalID][option];
            voters.push(msg.sender);
            emit VoteFinish(proposalID,option,msg.sender);
        }
        //更新投票历史
        VoteHistory[] storage historyList = voteHistoryMap[proposalID];
        for (uint index = 0; index < options.length; index++) {
            bytes memory option = options[index];
            historyList.push(
                VoteHistory({sender: msg.sender, option: option})
            );
        }
    }

    //所有提案列表
    function allProposal() public view returns (Proposal[] memory) {
        return proposals;
    }

    //获取某个提案某个选项所有投票
    function getVoters(uint proposalID, bytes memory option)
        public
        view
        returns (address[] memory)
    {
        return proposalsVoters[proposalID][option];
    }

    //获取某个提案下所有选项
    function getProposalOptions(uint proposalID) public view returns (bytes[] memory) {
        return proposalOptionsMap[proposalID];
    }

    //初始化结束合约
    function initFinishContract(address a) public {

    }

    //手动结束提案
    function finishProposal(uint proposalID) public {
        Proposal storage proposal = proposals[proposalID];
        proposal.state = ProposalState.provisioned;
        // finishContracts = FinishContracts(0x5fb1B12Fe0FdCF13c772cf96B2CcD44c4a5a3619);
        // finishContracts.finish();
        emit ProposalFinish(proposalID);
    }

    // 获取某个提案下投票历史
    function proposalVoteHistory(uint proposalID)
        public
        view
        returns (VoteHistory[] memory)
    {
        return voteHistoryMap[proposalID];
    }

    //获取当前时间
    function getNowTime() private view returns (uint) {
        return block.timestamp;
    }


    //新用户请求币给自己
    function requestCoin() public {
        token.requestToken();
    }
    

}


// 这是对应的币：此币在每个新用户加入的时候都会自动分发10个币。暂时没设置条件

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "TouPiao1001";
    string public constant symbol = "tpCoin";
    uint8 public constant decimals = 18;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 100000 ether;


   constructor() {
        balances[msg.sender] = 10 ether; //默认给智能合约作者10个
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }


    //新用户发币
    function requestToken() public{
        balances[msg.sender] = 10 ether;
    }
}