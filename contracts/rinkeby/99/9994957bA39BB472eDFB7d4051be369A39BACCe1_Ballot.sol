pragma solidity ^0.5.4;  //solidity编译器版本
contract Ballot{
    struct Voter {  //结构类型，代表一个选民
        uint weight;  //权重是通过授权累积的
        bool voted;  //true代表已经投票
        address delegate;  //委托人
        uint vote;  //投票提案索引
    }

    // 单个提案的类型
    struct Proposal {
        bytes32 name;
        uint voteCount;  //累计投票数
    }

    address public chairperson;  //主席

    // 声明了一个状态变量，为每个可能的地址存储一个选民的结构
    mapping(address => Voter) public voters;

    // 动态大小的"Proposal"结构数组
    Proposal[] public proposals;

    //未指定可加性，需要添加public？
    constructor(bytes32[] memory proposalNames) public {
        chairperson = msg.sender;  //第一次部署合约时的地址存储到chairperson
        voters[chairperson].weight = 1;

        for(uint i=0; i<proposalNames.length; i++){
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // 给予选民在本地投票中的投票权，只能由主席召集
    function giveRightToVote(address voter) external{
        //检查主持人是否是主席
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote.");
        //检查选民是否已投票
        require(
            !voters[voter].voted,
                "The voter already voted.");
        //检查选民权重是否是0
        require(voters[voter].weight == 0);
        // 授权选民权重为1
        voters[voter].weight = 1;
    }

    // 将投票权委托到某个投票人
    function delegate(address to) external {
        //把voters中的地址，赋值给Voter类型的变量sender（代表选民）
        //msg.sender是主席吗？如果不是，代表什么？
        Voter storage sender = voters[msg.sender];
        //检查选民是否已投票，如果是，提示You already voted.
        require(!sender.voted, "You already voted.");
        //检查委托地址与选民地址不一致，如果不是，提示Self-delegation is disallowed.
        require(to != msg.sender, "Self-delegation is disallowed.");
        /*
        1. 循环语句，判断被委托人的地址是否为空。如果非空，把被委托人的委托地址赋值给to
        （相当于如果A想委托为B，但是B已经委托给C了，那么直接让A委托给C就行）
        2. 检查被委托人地址与委托人地址是否不同，如果相等，提示Found loop in delegation.
        */
        while(voters[to].delegate != address(0)){  // 如果被委托人也委托别人了
            to = voters[to].delegate;
            // 防止自己委托给自己
            require(to != msg.sender, "Found loop in delegation.");
        }
        // 把被委托人赋值给Voter类型的变量delegate_
        Voter storage delegate_ = voters[to];
        // 检查被委托人的权重大于等于1
        require(delegate_.weight >= 1);
        // 赋值委托人的voted为true
        sender.voted = true;
        // 赋值委托人的delegate是to
        sender.delegate = to;
        // 如果被委托人的voted是true，则 某个提案的累计投票数=委托人的权重+某个提案的累计投票数；
        //否则，被委托人的权重=被委托人的权重+委托人权重
        //（如果被委托人已经投过票，直接把委托人的票投到某个提案中；否则，被委托人权重增加）
        if(delegate_.voted){
            proposals[delegate_.vote].voteCount += sender.weight;
        }else{
            delegate_.weight += sender.weight;
        }
    }

    //把票投到提案中
    function vote(uint proposal) external {
        // 定义和赋值Voter类型的sender变量
        Voter storage sender = voters[msg.sender];
        // 检查投票者权重是否等于0，如果是，则提示Has no right to vote
        require(sender.weight !=0, "Has no right to vote");
        //检查投票者是否已投票，如果是，则提示Already voted.
        require(!sender.voted, "Already voted.");
        //赋值投票者voted为true（开始投票）
        sender.voted = true;
        //赋值投票者投票提案索引为函数参数值
        sender.vote = proposal;
        //该提案的总投票数增加
        proposals[proposal].voteCount += sender.weight;
    }

    // 计算获胜提案，考虑之前的投票。返回提案索引
    function winningProposal() public view returns (uint winningProposal_){
        // 定义并赋值获胜的总票数为0，类型是uint，名称是winningVoteCount
        uint winningVoteCount  = 0;
        // for循环：循环遍历总提案的数量，如果某提案数量大于winningVoteCount
        //则把该数量赋值给winningVoteCount，且该提案索引赋值给winningProposal_
        for(uint p=0; p<proposals.length; p++){
            if(proposals[p].voteCount > winningVoteCount){
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    //返回获胜提案的名称
    function winnerName() external view returns (bytes32 winnerName_){
        // 省略return的写法
        winnerName_ = proposals[winningProposal()].name;
    }

    function voterHasRight(address voter) external view returns (bool){
        // 省略return的写法
//        weight = voters[voter].weight;
        require(voter != address(0));
        return voters[voter].weight == 1;
    }
}