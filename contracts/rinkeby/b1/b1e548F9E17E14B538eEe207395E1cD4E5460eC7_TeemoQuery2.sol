// SPDX-License-Identifier: MIT
pragma solidity >=0.5.1;



struct Config {
    uint256 minValue;
    uint256 maxValue;
    uint256 maxSpan;
    uint256 value;
    uint256 enable; // 0:disable, 1: enable
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface ITeemoConfig {
    function tokenCount() external view returns (uint256);

    function tokenList(uint256 index) external view returns (address);

    function getConfigValue(bytes32 _name) external view returns (uint256);

    function configs(bytes32 name) external view returns (Config memory);

    function tokenStatus(address token) external view returns (uint256);
}

interface ITeemoPlatform {
    function existPair(address tokenA, address tokenB) external view returns (bool);

    function swapPrecondition(address token) external view returns (bool);

    function getReserves(address tokenA, address tokenB) external view returns (uint256, uint256);
}

interface ITeemoFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface ITeemoDelegate {
    function getPlayerPairCount(address player) external view returns (uint256);

    function playerPairs(address user, uint256 index) external view returns (address);
}

interface ITeemoLP {
    function tokenA() external view returns (address);

    function tokenB() external view returns (address);
}

interface ITeemoPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function lastMintBlock(address user) external view returns (uint256);
}

interface ITeemoGovernance {
    function ballotCount() external view returns (uint256);

    function rewardOf(address ballot) external view returns (uint256);

    function tokenBallots(address ballot) external view returns (address);

    function ballotTypes(address ballot) external view returns (uint256);

    function revenueBallots(uint256 index) external view returns (address);

    function ballots(uint256 index) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function ballotOf(address ballot) external view returns (uint256);

    function allowance(address owner) external view returns (uint256);

    function configBallots(address ballot) external view returns (bytes32);

    function stakingSupply() external view returns (uint256);

    function collectUsers(address ballot, address user) external view returns (uint256);

    function ballotRevenueCount() external view returns (uint256);
}

interface ITeemoBallot {
    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint256 vote; // index of the voted proposal
    }

    function subject() external view returns (string memory);

    function content() external view returns (string memory);

    function createTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function executionTime() external view returns (uint256);

    function result() external view returns (bool);

    function proposer() external view returns (address);

    function proposals(uint256 index) external view returns (uint256);

    function ended() external view returns (bool);

    function value() external view returns (uint256);

    function voters(address user) external view returns (Voter memory);
}

interface ITeemoBallotRevenue {
    struct Participator {
        uint256 weight; // weight is accumulated by delegation
        bool participated; // if true, that person already voted
        address delegate; // person delegated to
    }

    function subject() external view returns (string memory);

    function content() external view returns (string memory);

    function createTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function executionTime() external view returns (uint256);

    function proposer() external view returns (address);

    function proposals(uint256 index) external view returns (uint256);

    function ended() external view returns (bool);

    function participators(address user) external view returns (Participator memory);

    function total() external view returns (uint256);
}

interface ITeemoTransferListener {
    function pairWeights(address pair) external view returns (uint256);
}

pragma experimental ABIEncoderV2;

contract TeemoQuery2 {
    bytes32 public constant PRODUCE_TGAS_RATE = bytes32('PRODUCE_TGAS_RATE');
    bytes32 public constant SWAP_FEE_PERCENT = bytes32('SWAP_FEE_PERCENT');
    bytes32 public constant LIST_TGAS_AMOUNT = bytes32('LIST_TGAS_AMOUNT');
    bytes32 public constant UNSTAKE_DURATION = bytes32('UNSTAKE_DURATION');
    bytes32 public constant REMOVE_LIQUIDITY_DURATION = bytes32('REMOVE_LIQUIDITY_DURATION');
    bytes32 public constant TOKEN_TO_TGAS_PAIR_MIN_PERCENT = bytes32('TOKEN_TO_TGAS_PAIR_MIN_PERCENT');
    bytes32 public constant LIST_TOKEN_FAILURE_BURN_PRECENT = bytes32('LIST_TOKEN_FAILURE_BURN_PRECENT');
    bytes32 public constant LIST_TOKEN_SUCCESS_BURN_PRECENT = bytes32('LIST_TOKEN_SUCCESS_BURN_PRECENT');
    bytes32 public constant PROPOSAL_TGAS_AMOUNT = bytes32('PROPOSAL_TGAS_AMOUNT');
    bytes32 public constant VOTE_DURATION = bytes32('VOTE_DURATION');
    bytes32 public constant VOTE_REWARD_PERCENT = bytes32('VOTE_REWARD_PERCENT');
    bytes32 public constant PAIR_SWITCH = bytes32('PAIR_SWITCH');
    bytes32 public constant TOKEN_PENGDING_SWITCH = bytes32('TOKEN_PENGDING_SWITCH');
    bytes32 public constant TOKEN_PENGDING_TIME = bytes32('TOKEN_PENGDING_TIME');

    address public configAddr;
    address public platform;
    address public factory;
    address public owner;
    address public governance;
    address public transferListener;
    address public delegate;

    uint256 public T_REVENUE = 5;

    struct Proposal {
        address proposer;
        address ballotAddress;
        address tokenAddress;
        string subject;
        string content;
        uint256 proposalType;
        uint256 createTime;
        uint256 endTime;
        uint256 executionTime;
        bool end;
        bool result;
        uint256 YES;
        uint256 NO;
        uint256 totalReward;
        uint256 ballotType;
        uint256 weight;
        bool minted;
        bool voted;
        uint256 voteIndex;
        bool audited;
        uint256 value;
        bytes32 key;
        uint256 currentValue;
    }

    struct RevenueProposal {
        address proposer;
        address ballotAddress;
        address tokenAddress;
        string subject;
        string content;
        uint256 createTime;
        uint256 endTime;
        uint256 executionTime;
        uint256 total;
        bool end;
        uint256 totalReward;
        uint256 ballotType;
        uint256 weight;
        bool minted;
        bool participated;
        bool audited;
    }

    struct Token {
        address tokenAddress;
        string symbol;
        uint256 decimal;
        uint256 balance;
        uint256 allowance;
        uint256 allowanceGov;
        uint256 status;
        uint256 totalSupply;
    }

    struct Liquidity {
        address pair;
        address lp;
        uint256 balance;
        uint256 totalSupply;
        uint256 lastBlock;
    }

    constructor() public {
        owner = msg.sender;
    }

    function upgrade(
        address _config,
        address _platform,
        address _factory,
        address _governance,
        address _transferListener,
        address _delegate
    ) public {
        require(owner == msg.sender);
        configAddr = _config;
        platform = _platform;
        factory = _factory;
        governance = _governance;
        transferListener = _transferListener;
        delegate = _delegate;
    }

    function queryTokenList() public view returns (Token[] memory token_list) {
        uint256 count = ITeemoConfig(configAddr).tokenCount();
        if (count > 0) {
            token_list = new Token[](count);
            for (uint256 i = 0; i < count; i++) {
                Token memory tk;
                tk.tokenAddress = ITeemoConfig(configAddr).tokenList(i);
                tk.symbol = IERC20(tk.tokenAddress).symbol();
                tk.decimal = IERC20(tk.tokenAddress).decimals();
                tk.balance = IERC20(tk.tokenAddress).balanceOf(msg.sender);
                tk.allowance = IERC20(tk.tokenAddress).allowance(msg.sender, delegate);
                tk.allowanceGov = IERC20(tk.tokenAddress).allowance(msg.sender, governance);
                tk.status = ITeemoConfig(configAddr).tokenStatus(tk.tokenAddress);
                tk.totalSupply = IERC20(tk.tokenAddress).totalSupply();
                token_list[i] = tk;
            }
        }
    }

    function countTokenList() public view returns (uint256) {
        return ITeemoConfig(configAddr).tokenCount();
    }

    function iterateTokenList(uint256 _start, uint256 _end) public view returns (Token[] memory token_list) {
        require(_start <= _end && _start >= 0 && _end >= 0, 'INVAID_PARAMTERS');
        uint256 count = ITeemoConfig(configAddr).tokenCount();
        if (count > 0) {
            if (_end > count) _end = count;
            count = _end - _start;
            token_list = new Token[](count);
            uint256 index = 0;
            for (uint256 i = _start; i < _end; i++) {
                Token memory tk;
                tk.tokenAddress = ITeemoConfig(configAddr).tokenList(i);
                tk.symbol = IERC20(tk.tokenAddress).symbol();
                tk.decimal = IERC20(tk.tokenAddress).decimals();
                tk.balance = IERC20(tk.tokenAddress).balanceOf(msg.sender);
                tk.allowance = IERC20(tk.tokenAddress).allowance(msg.sender, delegate);
                tk.allowanceGov = IERC20(tk.tokenAddress).allowance(msg.sender, governance);
                tk.status = ITeemoConfig(configAddr).tokenStatus(tk.tokenAddress);
                tk.totalSupply = IERC20(tk.tokenAddress).totalSupply();
                token_list[index] = tk;
                index++;
            }
        }
    }

    function queryLiquidityList() public view returns (Liquidity[] memory liquidity_list) {
        uint256 count = ITeemoDelegate(delegate).getPlayerPairCount(msg.sender);
        if (count > 0) {
            liquidity_list = new Liquidity[](count);
            for (uint256 i = 0; i < count; i++) {
                Liquidity memory l;
                l.lp = ITeemoDelegate(delegate).playerPairs(msg.sender, i);
                l.pair = ITeemoFactory(factory).getPair(ITeemoLP(l.lp).tokenA(), ITeemoLP(l.lp).tokenB());
                l.balance = IERC20(l.lp).balanceOf(msg.sender);
                l.totalSupply = IERC20(l.pair).totalSupply();
                l.lastBlock = ITeemoPair(l.pair).lastMintBlock(msg.sender);
                liquidity_list[i] = l;
            }
        }
    }

    function countLiquidityList() public view returns (uint256) {
        return ITeemoDelegate(delegate).getPlayerPairCount(msg.sender);
    }

    function iterateLiquidityList(uint256 _start, uint256 _end)
        public
        view
        returns (Liquidity[] memory liquidity_list)
    {
        require(_start <= _end && _start >= 0 && _end >= 0, 'INVAID_PARAMTERS');
        uint256 count = ITeemoDelegate(delegate).getPlayerPairCount(msg.sender);
        if (count > 0) {
            if (_end > count) _end = count;
            count = _end - _start;
            liquidity_list = new Liquidity[](count);
            uint256 index = 0;
            for (uint256 i = 0; i < count; i++) {
                Liquidity memory l;
                l.lp = ITeemoDelegate(delegate).playerPairs(msg.sender, i);
                l.pair = ITeemoFactory(factory).getPair(ITeemoLP(l.lp).tokenA(), ITeemoLP(l.lp).tokenB());
                l.balance = IERC20(l.lp).balanceOf(msg.sender);
                l.totalSupply = IERC20(l.pair).totalSupply();
                l.lastBlock = ITeemoPair(l.pair).lastMintBlock(msg.sender);
                liquidity_list[index] = l;
                index++;
            }
        }
    }

    function queryPairListInfo(address[] memory pair_list)
        public
        view
        returns (
            address[] memory token0_list,
            address[] memory token1_list,
            uint256[] memory reserve0_list,
            uint256[] memory reserve1_list
        )
    {
        uint256 count = pair_list.length;
        if (count > 0) {
            token0_list = new address[](count);
            token1_list = new address[](count);
            reserve0_list = new uint256[](count);
            reserve1_list = new uint256[](count);
            for (uint256 i = 0; i < count; i++) {
                token0_list[i] = ITeemoPair(pair_list[i]).token0();
                token1_list[i] = ITeemoPair(pair_list[i]).token1();
                (reserve0_list[i], reserve1_list[i], ) = ITeemoPair(pair_list[i]).getReserves();
            }
        }
    }

    function queryPairReserve(address[] memory token0_list, address[] memory token1_list)
        public
        view
        returns (
            uint256[] memory reserve0_list,
            uint256[] memory reserve1_list,
            bool[] memory exist_list
        )
    {
        uint256 count = token0_list.length;
        if (count > 0) {
            reserve0_list = new uint256[](count);
            reserve1_list = new uint256[](count);
            exist_list = new bool[](count);
            for (uint256 i = 0; i < count; i++) {
                if (ITeemoPlatform(platform).existPair(token0_list[i], token1_list[i])) {
                    (reserve0_list[i], reserve1_list[i]) = ITeemoPlatform(platform).getReserves(
                        token0_list[i],
                        token1_list[i]
                    );
                    exist_list[i] = true;
                } else {
                    exist_list[i] = false;
                }
            }
        }
    }

    function queryConfig()
        public
        view
        returns (
            uint256 fee_percent,
            uint256 proposal_amount,
            uint256 unstake_duration,
            uint256 remove_duration,
            uint256 list_token_amount,
            uint256 vote_percent
        )
    {
        fee_percent = ITeemoConfig(configAddr).getConfigValue(SWAP_FEE_PERCENT);
        proposal_amount = ITeemoConfig(configAddr).getConfigValue(PROPOSAL_TGAS_AMOUNT);
        unstake_duration = ITeemoConfig(configAddr).getConfigValue(UNSTAKE_DURATION);
        remove_duration = ITeemoConfig(configAddr).getConfigValue(REMOVE_LIQUIDITY_DURATION);
        list_token_amount = ITeemoConfig(configAddr).getConfigValue(LIST_TGAS_AMOUNT);
        vote_percent = ITeemoConfig(configAddr).getConfigValue(VOTE_REWARD_PERCENT);
    }

    function queryCondition(address[] memory path_list) public view returns (uint256) {
        uint256 count = path_list.length;
        for (uint256 i = 0; i < count; i++) {
            if (!ITeemoPlatform(platform).swapPrecondition(path_list[i])) {
                return i + 1;
            }
        }

        return 0;
    }

    function generateProposal(address ballot_address) public view returns (Proposal memory proposal) {
        proposal.proposer = ITeemoBallot(ballot_address).proposer();
        proposal.subject = ITeemoBallot(ballot_address).subject();
        proposal.content = ITeemoBallot(ballot_address).content();
        proposal.createTime = ITeemoBallot(ballot_address).createTime();
        proposal.endTime = ITeemoBallot(ballot_address).endTime();
        proposal.executionTime = ITeemoBallot(ballot_address).executionTime();
        proposal.end = block.number > ITeemoBallot(ballot_address).endTime() ? true : false;
        proposal.audited = ITeemoBallot(ballot_address).ended();
        proposal.YES = ITeemoBallot(ballot_address).proposals(1);
        proposal.NO = ITeemoBallot(ballot_address).proposals(2);
        proposal.totalReward = ITeemoGovernance(governance).ballotOf(ballot_address);
        proposal.ballotAddress = ballot_address;
        proposal.voted = ITeemoBallot(ballot_address).voters(msg.sender).voted;
        proposal.voteIndex = ITeemoBallot(ballot_address).voters(msg.sender).vote;
        proposal.weight = ITeemoBallot(ballot_address).voters(msg.sender).weight;
        proposal.minted = ITeemoGovernance(governance).collectUsers(ballot_address, msg.sender) == 1;
        proposal.ballotType = ITeemoGovernance(governance).ballotTypes(ballot_address);
        proposal.tokenAddress = ITeemoGovernance(governance).tokenBallots(ballot_address);
        proposal.value = ITeemoBallot(ballot_address).value();
        proposal.proposalType = ITeemoGovernance(governance).ballotTypes(ballot_address);
        proposal.result = ITeemoBallot(ballot_address).result();

        if (proposal.ballotType == 1) {
            proposal.key = ITeemoGovernance(governance).configBallots(ballot_address);
            proposal.currentValue = ITeemoConfig(governance).getConfigValue(proposal.key);
        }
    }

    function generateRevenueProposal(address ballot_address) public view returns (RevenueProposal memory proposal) {
        proposal.proposer = ITeemoBallotRevenue(ballot_address).proposer();
        proposal.subject = ITeemoBallotRevenue(ballot_address).subject();
        proposal.content = ITeemoBallotRevenue(ballot_address).content();
        proposal.createTime = ITeemoBallotRevenue(ballot_address).createTime();
        proposal.endTime = ITeemoBallotRevenue(ballot_address).endTime();
        proposal.executionTime = ITeemoBallotRevenue(ballot_address).executionTime();
        proposal.end = block.timestamp > ITeemoBallotRevenue(ballot_address).endTime() ? true : false;
        proposal.audited = ITeemoBallotRevenue(ballot_address).ended();
        proposal.totalReward = ITeemoGovernance(governance).ballotOf(ballot_address);
        proposal.ballotAddress = ballot_address;
        proposal.participated = ITeemoBallotRevenue(ballot_address).participators(msg.sender).participated;
        proposal.weight = ITeemoBallotRevenue(ballot_address).participators(msg.sender).weight;
        proposal.minted = ITeemoGovernance(governance).collectUsers(ballot_address, msg.sender) == 1;
        proposal.ballotType = ITeemoGovernance(governance).ballotTypes(ballot_address);
        proposal.tokenAddress = ITeemoGovernance(governance).tokenBallots(ballot_address);
        proposal.total = ITeemoBallotRevenue(ballot_address).total();
    }

    function queryTokenItemInfo(address token)
        public
        view
        returns (
            string memory symbol,
            uint256 decimal,
            uint256 totalSupply,
            uint256 balance,
            uint256 allowance
        )
    {
        symbol = IERC20(token).symbol();
        decimal = IERC20(token).decimals();
        totalSupply = IERC20(token).totalSupply();
        balance = IERC20(token).balanceOf(msg.sender);
        allowance = IERC20(token).allowance(msg.sender, delegate);
    }

    function queryConfigInfo(bytes32 name) public view returns (Config memory config_item) {
        config_item = ITeemoConfig(configAddr).configs(name);
    }

    function queryStakeInfo()
        public
        view
        returns (
            uint256 stake_amount,
            uint256 stake_block,
            uint256 total_stake
        )
    {
        stake_amount = ITeemoGovernance(governance).balanceOf(msg.sender);
        stake_block = ITeemoGovernance(governance).allowance(msg.sender);
        total_stake = ITeemoGovernance(governance).stakingSupply();
    }

    function queryProposalList() public view returns (Proposal[] memory proposal_list) {
        uint256 count = ITeemoGovernance(governance).ballotCount();
        proposal_list = new Proposal[](count);
        for (uint256 i = 0; i < count; i++) {
            address ballot_address = ITeemoGovernance(governance).ballots(i);
            proposal_list[count - i - 1] = generateProposal(ballot_address);
        }
    }

    function queryRevenueProposalList() public view returns (RevenueProposal[] memory proposal_list) {
        uint256 count = ITeemoGovernance(governance).ballotRevenueCount();
        proposal_list = new RevenueProposal[](count);
        for (uint256 i = 0; i < count; i++) {
            address ballot_address = ITeemoGovernance(governance).revenueBallots(i);
            proposal_list[count - i - 1] = generateRevenueProposal(ballot_address);
            (ballot_address);
        }
    }

    function countProposalList() public view returns (uint256) {
        return ITeemoGovernance(governance).ballotCount();
    }

    function iterateProposalList(uint256 _start, uint256 _end) public view returns (Proposal[] memory proposal_list) {
        require(_start <= _end && _start >= 0 && _end >= 0, 'INVAID_PARAMTERS');
        uint256 count = ITeemoGovernance(governance).ballotCount();
        if (_end > count) _end = count;
        count = _end - _start;
        proposal_list = new Proposal[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            address ballot_address = ITeemoGovernance(governance).ballots(i);
            proposal_list[index] = generateProposal(ballot_address);
            index++;
        }
    }

    function iterateReverseProposalList(uint256 _start, uint256 _end)
        public
        view
        returns (Proposal[] memory proposal_list)
    {
        require(_end <= _start && _end >= 0 && _start >= 0, 'INVAID_PARAMTERS');
        uint256 count = ITeemoGovernance(governance).ballotCount();
        if (_start > count) _start = count;
        count = _start - _end;
        proposal_list = new Proposal[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            address ballot_address = ITeemoGovernance(governance).ballots(i);
            proposal_list[index] = generateProposal(ballot_address);
            index++;
        }
    }

    function queryPairWeights(address[] memory pairs) public view returns (uint256[] memory weights) {
        uint256 count = pairs.length;
        weights = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            weights[i] = ITeemoTransferListener(transferListener).pairWeights(pairs[i]);
        }
    }

    function getPairReserve(address _pair)
        public
        view
        returns (
            address token0,
            address token1,
            uint8 decimals0,
            uint8 decimals1,
            uint256 reserve0,
            uint256 reserve1
        )
    {
        token0 = ITeemoPair(_pair).token0();
        token1 = ITeemoPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ITeemoPair(_pair).getReserves();
    }

    function getPairReserveWithUser(address _pair, address _user)
        public
        view
        returns (
            address token0,
            address token1,
            uint8 decimals0,
            uint8 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            uint256 balance0,
            uint256 balance1
        )
    {
        token0 = ITeemoPair(_pair).token0();
        token1 = ITeemoPair(_pair).token1();
        decimals0 = IERC20(token0).decimals();
        decimals1 = IERC20(token1).decimals();
        (reserve0, reserve1, ) = ITeemoPair(_pair).getReserves();
        balance0 = IERC20(token0).balanceOf(_user);
        balance1 = IERC20(token1).balanceOf(_user);
    }
}