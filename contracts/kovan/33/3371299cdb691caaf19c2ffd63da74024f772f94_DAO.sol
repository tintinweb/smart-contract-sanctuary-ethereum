// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/PLBTStaking/IPLBTStaking.sol";
import "./interfaces/DAO/IDAO.sol";
import "./sushiswap/IUniswapV2Router02.sol";
import "./gysr/interfaces/IRewardModule.sol";
import "./gysr/interfaces/IPoolFactory.sol";
import "./gysr/interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

///@title DAO contract
contract DAO is IDAO, AccessControl {
    using SafeERC20 for IERC20;

    /// status of vote
    enum Decision {
        none,
        votedFor,
        votedAgainst
    }

    /// type of proposal types
    enum ChangesType {
        none,
        strategy,
        allocation,
        quorum,
        majority,
        treasury,
        cancel
    }

    /// state of proposal
    enum Status {
        none,
        proposal,
        finished,
        voting
    }

    /// struct represents a vote
    struct Vote {
        // amount of tokens in vote
        uint256 amount;
        // voting decision
        Decision decision;
    }

    /// struct for storing proposal
    struct Voting {
        // voting id
        uint256 id;
        // in support of votes
        uint256 votesFor;
        // against votes
        uint256 votesAgainst;
        // when started
        uint256 startTime;
        // voting may execute only after voting ended
        uint256 endTime;
        // this time increases if this voting is being cancelled
        uint256 finishTime;
        // time when changes come in power
        uint256 implementationTime;
        // creator address
        address creator;
        // address of proposal creator
        ChangesType changesType;
        // proposal status
        Status status;
        // indicator showing if proposal was cancelled
        bool wasCancelled;
        // bytecode to run on the finishvote
        bytes data;
    }

    /// represents allocation percentage
    struct Allocation {
        uint8 plbtStakers;
        uint8 osomStakers;
        uint8 lpStakers;
        uint8 buyback;
    }

    /// represents amount of tokens in percentage put on investing strategies
    struct Strategy {
        uint8 autopilot;
        uint8 uniswap;
        uint8 aave;
        uint8 anchor;
    }

    ///@dev emmited when new proposal created
    ///@param creator address of proposal creator
    ///@param key hash passed to event in order to match with backend, for storing proposal descriptions
    ///@param id id of proposal
    ///@param startTime time when voting on proposal starts
    ///@param endTime time when voting on proposal ends
    event ProposalAdded(
        address indexed creator,
        bytes32 key,
        uint256 indexed id,
        uint256 startTime,
        uint256 endTime
    );
    ///@dev emmited when proposal transitioned to main voting status
    ///@param id id of proposal
    ///@param startTime time when main voting starts
    ///@param endTime time when main voting ends
    event VotingBegan(uint256 indexed id, uint256 startTime, uint256 endTime);

    ///@dev emmited when voting is finished
    ///@param id id of finished proposal
    ///@param executed shows if finish was successfully executed
    ///@param votesFor with how many tokens voted for proposal
    ///@param votesAgainst with how many tokens voted against proposal
    event Finished(
        uint256 indexed id,
        bool indexed executed,
        uint256 votesFor,
        uint256 votesAgainst
    );

    ///@dev emmited when someone voted on proposal
    ///@param voter address of voter
    ///@param id id of proposal
    ///@param decision shows if voted for or against
    ///@param amount amount of tokens voted with
    event CastedOnProposal(
        address indexed voter,
        uint256 indexed id,
        bool decision,
        uint256 amount
    );

    ///@dev emmited when someone voted in main voting
    ///@param voter address of voter
    ///@param id id of proposal
    ///@param decision shows if voted for or against
    ///@param amount amount of tokens voted with
    event CastedOnVoting(
        address indexed voter,
        uint256 indexed id,
        bool decision,
        uint256 amount
    );

    ///@dev modifier used for restricted function execution
    modifier onlyDAO() {
        require(
            msg.sender == address(this),
            "DAO: only dao can call this function."
        );
        _;
    }

    /// role of treasury holder
    bytes32 public TREASURY_ROLE = keccak256("TREASURY_ROLE");
    /// threshold for proposal to pass
    uint256 public proposalMajority;
    ///threshold for voting to pass
    uint256 public votingMajority;
    /// threshold for proposal to become valid
    uint256 public proposalQuorum;
    /// threshold for voting to become valid
    uint256 public votingQuorum;
    /// debating period duration
    uint256 public votingPeriod;
    /// voting count
    uint256 public votingsCount;
    /// regular timelock
    uint256 public regularTimelock;
    /// cancel timelock
    uint256 public cancelTimelock;
    /// Allocation
    Allocation public allocation;
    /// Strategy
    Strategy public strategy;
    /// Treasury owner
    address treasury;
    /// for percent calculations
    uint256 private precision = 1e6;
    /// staking contracts
    IPLBTStaking private staking;
    /// tokens
    IERC20 private plbt;
    IERC20 private weth;
    IERC20 private wbtc;
    /// Router
    IUniswapV2Router02 router;
    ///pool address
    address public pool;
    ///GYSR Pool
    address public gysr;

    ///OSOM address
    address OSOM;
    ///array of function selectors
    bytes4[6] selectors = [
        this.changeStrategy.selector,
        this.changeAllocation.selector,
        this.changeQuorum.selector,
        this.changeMajority.selector,
        this.changeTreasury.selector,
        this.cancelVoting.selector
    ];
    /// active proposals
    uint256[10] public proposals;
    /// initialized
    bool private initialized;

    /// current voting
    uint256 public activeVoting;
    /// current cancel
    uint256 public activeCancellation;

    mapping(uint256 => Voting) public votings;
    /// storing votes from a certain address for voting
    mapping(uint256 => mapping(address => Vote)) public votingDecisions;
    /// current proposals per user
    mapping(address => uint256) public userProposals;

    ///@param _proposalMajority initial percent of proposal majority of votes to become valid
    ///@param _votingMajority initial percent of main voting majority of votes to become valid
    ///@param _proposalQuorum initial percent of proposal quorum
    ///@param _votingQuorum initial percent of main voting quorum
    ///@param _votingPeriod initial voting period time
    ///@param _regularTimelock initial timelock period
    ///@param _cancelTimelock initial cancel timelock period
    ///@param _allocation initial allocation config
    ///@param _strategy initial strategy config
    constructor(
        uint256 _proposalMajority,
        uint256 _votingMajority,
        uint256 _proposalQuorum,
        uint256 _votingQuorum,
        uint256 _votingPeriod,
        uint256 _regularTimelock,
        uint256 _cancelTimelock,
        Allocation memory _allocation,
        Strategy memory _strategy
    ) {
        proposalMajority = _proposalMajority;
        votingMajority = _votingMajority;
        proposalQuorum = _proposalQuorum;
        votingQuorum = _votingQuorum;
        votingPeriod = _votingPeriod;
        regularTimelock = _regularTimelock;
        cancelTimelock = _cancelTimelock;
        allocation = _allocation;
        strategy = _strategy;
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setRoleAdmin(TREASURY_ROLE, DEFAULT_ADMIN_ROLE);
    }

    ///@dev initializing DAO with settings
    ///@param _router SushiSwap router address
    ///@param _treasury address of the treasury holder
    ///@param _stakingAddr address of staking
    ///@param _plbt Polybius token address
    ///@param _weth address of wEth
    ///@param _wbtc address of wBTC
    ///@param _poolFactory address of GYSR pool factory
    ///@param _stakingFactory address of GYSR staking module Factory
    ///@param _rewardFactory address of GYSR reward module factory
    ///@param _slpAddress address of PLBT-wETH LP token address
    ///@param _OSOM address of OSOM
    function initialize(
        address _router,
        address _treasury,
        address _stakingAddr,
        address _plbt,
        address _weth,
        address _wbtc,
        address _poolFactory,
        address _stakingFactory,
        address _rewardFactory,
        address _slpAddress,
        address _OSOM
    ) external {
        require(!initialized, "DAO: Already initialized.");
        treasury = _treasury;
        _setupRole(TREASURY_ROLE, treasury);
        staking = IPLBTStaking(_stakingAddr);
        plbt = IERC20(_plbt);
        weth = IERC20(_weth);
        wbtc = IERC20(_wbtc);
        IPoolFactory factory = IPoolFactory(_poolFactory);
        bytes memory stakingdata = (abi.encode(_slpAddress));
        bytes memory rewarddata = (abi.encode(_plbt, 10**18, 2592000));
        pool = factory.create(
            _stakingFactory,
            _rewardFactory,
            stakingdata,
            rewarddata
        );
        gysr = IPool(pool).rewardModule();
        OSOM = _OSOM;
        router = IUniswapV2Router02(_router);
        initialized = true;
    }

    ///@dev distributing fund to parties and staking contracts, and buying back PLBT from Sushiswap pool
    ///@param toStakersWETH amount of wETH to distribute to PLBTStakers
    ///@param toStakersWBTC amount of wBTC to distribute to PLBTStakers
    ///@param toLPStakers amount of PLBT to distribute to LPStakers on GYSR
    ///@param toOSOMWETH amount of wETH to distribute to PLBTStakers on OSOM
    ///@param toOSOMWBTC amount of wBTC to distribute to PLBTStakers on OSOM
    ///@param toBuyback amount of wETH to swap for PLBT
    ///@param minOutput min amount of PLBT expected after the swap
    function distribute(
        uint256 toStakersWETH,
        uint256 toStakersWBTC,
        uint256 toLPStakers,
        uint256 toOSOMWETH,
        uint256 toOSOMWBTC,
        uint256 toBuyback,
        uint256 minOutput
    ) external onlyRole(TREASURY_ROLE) {
        if (toStakersWETH != 0) {
            weth.safeTransferFrom(treasury, address(staking), toStakersWETH); //возможно лучше через апрву?
        }
        if (toStakersWBTC != 0) {
            wbtc.safeTransferFrom(treasury, address(staking), toStakersWBTC);
        }
        staking.setReward(toStakersWETH, toStakersWBTC);
        if (toLPStakers != 0) {
            plbt.safeTransferFrom(treasury, address(this), toLPStakers);
            plbt.approve(gysr, toLPStakers);
            IRewardModule(gysr).fund(toLPStakers, 36000);
        }
        if (toOSOMWETH != 0) {
            weth.safeTransferFrom(treasury, OSOM, toOSOMWETH);
        }
        if (toOSOMWBTC != 0) {
            wbtc.safeTransferFrom(treasury, OSOM, toOSOMWBTC);
        }
        if (toBuyback != 0) {
            uint256 total = plbt.balanceOf(address(this));
            weth.safeTransferFrom(treasury, address(this), toBuyback);
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(plbt);
            uint256[] memory amounts = router.getAmountsOut(toBuyback, path);
            require(
                amounts[1] >= minOutput,
                "DAO: amount of tokens is lower than expected"
            );
            weth.approve(address(router), amounts[0]);
            router.swapTokensForExactTokens(
                amounts[1],
                amounts[0],
                path,
                address(this),
                block.timestamp + 600
            );
            uint256 current = plbt.balanceOf(address(this));
            uint256 burn = current - total;
            plbt.safeTransfer(address(0), burn);
        }
    }

    ///@dev transfers GYSR controller role to another user
    ///@param _address address of the new gysr controller
    function transferGYSROwnership(address _address)
        external
        onlyRole(TREASURY_ROLE)
    {
        require(_address != address(0), "DAO: can't set zero-address");
        IPool(pool).transferControl(_address);
    }

    ///@dev changes OSOM address
    ///@param _address new OSOM address
    function changeOSOM(address _address) external onlyRole(TREASURY_ROLE) {
        require(_address != address(0), "DAO: can't set zero-address");
        OSOM = _address;
    }

    ///@dev function which matches function selector with bytecode
    ///@param _changesType shows which function selector is expected
    ///@param _data bytecode to match
    modifier matchChangesTypes(ChangesType _changesType, bytes memory _data) {
        require(
            _changesType != ChangesType.none,
            "DAO: addProposal bad arguments."
        );
        bytes4 outBytes4;
        assembly {
            outBytes4 := mload(add(_data, 0x20))
        }

        require(
            outBytes4 == selectors[uint256(_changesType) - 1],
            "DAO: bytecode is wrong"
        );
        _;
    }

    ///@dev function which will be called on Finish; changes proposal or main voting quorums
    ///@param or shows what quorum to change
    ///@param _quorum new quorum percent value
    function changeQuorum(bool or, uint256 _quorum) public onlyDAO {
        or ? votingQuorum = _quorum : proposalQuorum = _quorum;
    }

    ///@dev function which will be called on Finish; changes proposal or main voting Majority
    ///@param or shows what Majority to change
    ///@param _majority new Majority percent value
    function changeMajority(bool or, uint256 _majority) public onlyDAO {
        or ? votingMajority = _majority : proposalMajority = _majority;
    }

    ///@dev function which will be called on Finish of cancellation voting
    ///@param id id of main voting
    function cancelVoting(uint256 id) public onlyDAO {
        votings[id].status = Status.finished;
    }

    ///@dev function which will be called on Finish; changes allocation parameters
    ///@param _allocation new allocation config
    function changeAllocation(Allocation memory _allocation) public onlyDAO {
        allocation = _allocation;
    }

    ///@dev function which will be called on Finish; changes strategy parameters
    ///@param _strategy new strategy config
    function changeStrategy(Strategy memory _strategy) public onlyDAO {
        strategy = _strategy;
    }

    ///@dev function which will be called on Finish; changes treasury holder address
    ///@param _treasury new treasury holder address
    function changeTreasury(address _treasury) public onlyDAO {
        revokeRole(TREASURY_ROLE, treasury);
        treasury = _treasury;
        grantRole(TREASURY_ROLE, treasury);
        staking.changeTreasury(_treasury);
    }

    ///@dev check if proposal passed quorum and majority thresholds
    ///@param proposal proposal sent to validate
    function validate(Voting memory proposal) private view returns (bool) {
        uint256 total = proposal.votesFor + proposal.votesAgainst;
        if (total == 0) {
            return false;
        }
        bool quorum;
        uint256 supply = plbt.totalSupply() - plbt.balanceOf(address(0));
        bool majority;
        if (proposal.status == Status.voting) {
            quorum = ((total * precision) / supply) > votingQuorum;
            majority = (proposal.votesFor * precision) / total > votingMajority;
        } else {
            quorum = ((total * precision) / supply) > proposalQuorum;
            majority =
                (proposal.votesFor * precision) / total > proposalMajority;
        }
        return majority && quorum;
    }

    ///@dev picks next proposal out of proposal pool
    function pickProposal() private view returns (uint256 id, bool check) {
        if (votings[activeVoting].status == Status.voting) {
            return (0, false);
        }
        uint256 temp = 0;
        Voting memory proposal;
        for (uint256 i = 0; i < proposals.length; i++) {
            proposal = votings[proposals[i]];
            if (proposal.status == Status.proposal && validate(proposal)) {
                (temp == 0 || proposal.startTime < votings[temp].startTime)
                    ? temp = proposal.id
                    : 0;
            }
        }
        if (temp != 0 && validate(votings[temp])) {
            return (temp, true);
        }
        return (0, false);
    }

    ///@dev send proposal to main voting round
    ///@param id id of proposal
    function sendProposalToVoting(uint256 id) private {
        Voting storage proposal = votings[id];
        proposal.status = Status.voting;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.finishTime = proposal.endTime + regularTimelock;
        activeVoting = id;
        emit VotingBegan(proposal.id, proposal.startTime, proposal.endTime);
    }

    ///@dev adds proposal to proposal pool
    ///@param _changesType type of proposal
    ///@param _data executable bytecode to execute on Finish
    ///@param id key for matching frontend request with this contract logs
    function addProposal(
        ChangesType _changesType,
        bytes memory _data,
        bytes32 id
    ) public matchChangesTypes(_changesType, _data) {
        bool cancel = _changesType == ChangesType.cancel;
        require(
            staking.getStakedTokens(msg.sender) > 0,
            "DAO: Only stakers can propose"
        );
        require(
            !(cancel && votings[activeCancellation].status == Status.voting),
            "Cancel Voting already exists"
        );
        require(
            getActiveProposals(msg.sender) < 2,
            "addProposal: can't add more than 2 proposals"
        );
        if (cancel) {
            Voting storage voting = votings[activeVoting];
            require(
                voting.wasCancelled == false && voting.status == Status.voting,
                "DAO: Can't cancel twice."
            );
            require(
                voting.endTime < block.timestamp &&
                    voting.finishTime > block.timestamp,
                "DAO: can only cancel during timelock"
            );
            voting.finishTime = block.timestamp + cancelTimelock;
            voting.wasCancelled = true;
        }
        votingsCount++;
        Voting memory proposal = Voting({
            id: votingsCount,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            finishTime: 0,
            implementationTime: 0,
            creator: msg.sender,
            changesType: _changesType,
            status: Status.proposal,
            wasCancelled: false,
            data: _data
        });
        votings[votingsCount] = proposal;
        if (cancel) {
            activeCancellation = votingsCount;
            votings[activeCancellation].status = Status.voting;
            votings[activeCancellation].finishTime = votings[activeCancellation]
                .endTime;

            emit ProposalAdded(
                msg.sender,
                id,
                votingsCount,
                proposal.startTime,
                proposal.endTime
            );
            return;
        }
        bool proposalAdded = false;
        bool check;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (
                votings[proposals[i]].status != Status.proposal ||
                proposals[i] == 0
            ) {
                check = true;
            } else {
                if (
                    votings[proposals[i]].endTime <= block.timestamp &&
                    votings[proposals[i]].status == Status.proposal
                ) {
                    check = !(validate(votings[proposals[i]]));
                }
            }
            if (check) {
                proposals[i] = proposal.id;
                proposalAdded = true;
                break;
            }
        }
        require(proposalAdded, "DAO: proposals list is full");

        emit ProposalAdded(
            msg.sender,
            id,
            votingsCount,
            proposal.startTime,
            proposal.endTime
        );
    }

    ///@dev participate in main voting round
    ///@param id id of proposal
    ///@param amount amount of tokens to vote with
    ///@param decision shows if voted for or against
    function participateInVoting(
        uint256 id,
        uint256 amount,
        bool decision
    ) external {
        // check if proposal is active
        bool check = votings[id].status == Status.voting &&
            votings[id].endTime >= block.timestamp;
        require(check, "DAO: voting ended");
        // check if voted
        Vote storage vote = votingDecisions[id][msg.sender];
        require(
            vote.decision == Decision.none && vote.amount == 0,
            "DAO: you have already voted"
        );
        // check if msg.sender has available tokens
        uint256 possible = getAvailableTokens(msg.sender);
        require(amount > 0 && amount <= possible, "DAO: incorrect amount");
        Voting storage voting = votings[id];
        vote.amount += amount;
        if (decision) {
            voting.votesFor += amount;
            vote.decision = Decision.votedFor;
        } else {
            voting.votesAgainst += amount;
            vote.decision = Decision.votedAgainst;
        }
        emit CastedOnVoting(msg.sender, id, decision, amount);
    }

    ///@dev participate in proposal
    ///@param id id of proposal
    ///@param amount amount of tokens to vote with
    ///@param decision shows if voted for or against
    function participateInProposal(
        uint256 id,
        uint256 amount,
        bool decision
    ) external {
        // check if proposal is active
        bool check = votings[id].status == Status.proposal &&
            votings[id].endTime >= block.timestamp;
        require(check, "DAO: proposal ended");
        // check if voted
        Voting storage proposal = votings[id];
        Vote storage vote = votingDecisions[proposal.id][msg.sender];
        require(
            vote.decision == Decision.none && vote.amount == 0,
            "DAO: you have already voted"
        );
        // check if msg.sender has available tokens
        uint256 possible = getAvailableTokens(msg.sender);
        require(amount > 0 && amount <= possible, "DAO: incorrect amount");
        vote.amount += amount;
        if (decision) {
            proposal.votesFor += amount;
            vote.decision = Decision.votedFor;
        } else {
            proposal.votesAgainst += amount;
            vote.decision = Decision.votedAgainst;
        }
        (uint256 picked, bool found) = pickProposal();
        if (found) {
            sendProposalToVoting(picked);
        }
        emit CastedOnProposal(msg.sender, id, decision, amount);
    }

    ///@dev to finish main voting round and run changes on success
    ///@param id id of proposal to finish
    function finishVoting(uint256 id) public {
        Voting storage voting = votings[id];
        require(
            (voting.status == Status.voting),
            "DAO: the result of the vote has already been completed,"
        );
        require(
            block.timestamp > (voting.finishTime),
            "DAO: Voting can't be finished yet."
        );
        bool result = validate(voting);
        if (result && voting.changesType != ChangesType.cancel) {
            (bool success, ) = address(this).call{value: 0}(voting.data);
            voting.implementationTime = block.timestamp;
        }
        if (voting.changesType == ChangesType.cancel) {
            if (result) {
                address(this).call{value: 0}(voting.data);
            } else {
                bytes memory data = voting.data;
                uint256 id_;
                assembly {
                    let sig := mload(add(data, add(4, 0)))
                    id_ := mload(add(data, 36))
                }
                votings[id_].finishTime = votings[id_].endTime;
                finishVoting(id_);
            }
        }
        voting.status = Status.finished;
        (uint256 picked, bool found) = pickProposal();
        if (found) {
            sendProposalToVoting(picked);
        }
        emit Finished(id, result, voting.votesFor, voting.votesAgainst);
    }

    ///@dev used for situations, when previously passed proposal wasn't finished and proposal pool is full
    ///@param finishId id of proposal to finish
    ///@param _changesType type of proposal
    ///@param _data executable bytecode to execute on Finish
    ///@param id key for matching frontend request with this contract logs
    function finishAndAddProposal(
        uint256 finishId,
        ChangesType _changesType,
        bytes calldata _data,
        bytes32 id
    ) external {
        finishVoting(finishId);
        addProposal(_changesType, _data, id);
    }

    ///@dev get all locked tokens for address `staker`, so user cannot unstake or vote with tokens used in proposals
    ///@param staker address of staker
    function getLockedTokens(address staker)
        public
        view
        override
        returns (uint256 locked)
    {
        for (uint256 i = 0; i < proposals.length; i++) {
            if (
                (votings[proposals[i]].endTime > block.timestamp ||
                    validate(votings[proposals[i]])) &&
                votings[proposals[i]].status == Status.proposal
            ) locked += votingDecisions[proposals[i]][staker].amount;
        }
        if (
            votings[activeVoting].status == Status.voting &&
            votings[activeVoting].finishTime > block.timestamp
        ) {
            locked += votingDecisions[activeVoting][staker].amount;
        }
        if (
            votings[activeCancellation].status == Status.voting &&
            votings[activeCancellation].finishTime > block.timestamp
        ) {
            locked += votingDecisions[activeCancellation][staker].amount;
        }
        return locked;
    }

    ///@dev get available tokens for address `staker`, so user cannot unstake or vote with tokens used in proposals
    ///@param staker address of staker
    function getAvailableTokens(address staker)
        public
        view
        override
        returns (uint256 available)
    {
        uint256 locked = getLockedTokens(staker);
        uint256 staked = staking.getStakedTokens(staker);
        available = staked - locked;
        return available;
    }

    ///@dev returns all proposals from pool
    function getAllProposals() external view returns (Voting[] memory) {
        Voting[] memory proposalsList = new Voting[](10); // allocate array memory
        for (uint256 i = 0; i < proposals.length; i++) {
            {
                proposalsList[i] = votings[proposals[i]];
            }
        }
        return proposalsList;
    }

    ///@dev returns all votings
    ///@return array of proposals from pool
    function getAllVotings() external view returns (Voting[] memory) {
        Voting[] memory votingsList = new Voting[](votingsCount); // allocate array memory
        for (uint256 i = 0; i < votingsCount; i++) {
            {
                votingsList[i] = votings[i + 1];
            }
        }
        return votingsList;
    }

    ///@dev returns proposal info with additional information for frontend
    ///@return proposal struct
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveVoting()
        external
        view
        returns (
            Voting memory,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeVoting].creator
        );
        return (
            votings[activeVoting],
            creatorAmountStaked,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@return proposal struct
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveCancellation()
        external
        view
        returns (
            Voting memory,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeCancellation].creator
        );
        return (
            votings[activeCancellation],
            creatorAmountStaked,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param user address of the user
    ///@return proposal struct
    ///@return vote struct
    ///@return available amount of available for voting tokens by `user`
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveVoting(address user)
        external
        view
        returns (
            Voting memory,
            Vote memory,
            uint256 available,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        available = getAvailableTokens(user);
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeVoting].creator
        );
        return (
            votings[activeVoting],
            votingDecisions[activeVoting][user],
            creatorAmountStaked,
            available,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param user address of the user
    ///@return proposal struct
    ///@return vote struct
    ///@return available amount of available for voting tokens by `user`
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getActiveCancellation(address user)
        external
        view
        returns (
            Voting memory,
            Vote memory,
            uint256 available,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        available = getAvailableTokens(user);
        creatorAmountStaked = staking.getStakedTokens(
            votings[activeCancellation].creator
        );
        return (
            votings[activeCancellation],
            votingDecisions[activeCancellation][user],
            creatorAmountStaked,
            available,
            votingQuorum,
            votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param id id of proposal
    ///@return proposal struct
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getProposalInfo(uint256 id)
        external
        view
        returns (
            Voting memory,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        creatorAmountStaked = staking.getStakedTokens(votings[id].creator);
        return (
            votings[id],
            creatorAmountStaked,
            votings[id].status == Status.proposal
                ? proposalQuorum
                : votingQuorum,
            votings[id].status == Status.proposal
                ? proposalMajority
                : votingMajority
        );
    }

    ///@dev returns proposal info with additional information for frontend
    ///@param id id of proposal
    ///@param user address of the user
    ///@return proposal struct
    ///@return vote struct
    ///@return available amount of available for voting tokens by `user`
    ///@return creatorAmountStaked amount of staked tokens by proposal creator
    ///@return quorum
    ///@return majority
    function getProposalInfo(uint256 id, address user)
        external
        view
        returns (
            Voting memory,
            Vote memory,
            uint256 available,
            uint256 creatorAmountStaked,
            uint256,
            uint256
        )
    {
        available = getAvailableTokens(user);
        creatorAmountStaked = staking.getStakedTokens(votings[id].creator);
        return (
            votings[id],
            votingDecisions[id][user],
            creatorAmountStaked,
            available,
            votings[id].status == Status.proposal
                ? proposalQuorum
                : votingQuorum,
            votings[id].status == Status.proposal
                ? proposalMajority
                : votingMajority
        );
    }

    ///@dev returns DAO configuration parameters
    ///@return allocation config
    ///@return strategy config
    ///@return proposal majority
    ///@return main voting round majority
    ///@return proposal quorum
    ///@return main voting round quorum
    function InfoDAO()
        external
        view
        returns (
            Allocation memory,
            Strategy memory,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            allocation,
            strategy,
            proposalMajority,
            votingMajority,
            proposalQuorum,
            votingQuorum
        );
    }

    ///@dev returns all proposals from pool
    ///@param _address address of the user
    function getActiveProposals(address _address) public view returns (uint8) {
        Voting memory proposal;
        uint8 counter;
        for (uint256 i = 0; i < proposals.length; i++) {
            proposal = votings[proposals[i]];
            if (
                ((proposal.endTime >= block.timestamp) ||
                    (proposal.endTime <= block.timestamp &&
                        validate(proposal))) &&
                _address == proposal.creator &&
                proposal.status == Status.proposal
            ) {
                counter++;
            }
        }
        return counter;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


///@title Interface for PLBTSTaking contract for DAO interactions
interface IPLBTStaking {

    ///@dev returns amount of staked tokens by user `_address`
    ///@param _address address of the user
    ///@return amount of tokens
    function getStakedTokens(address _address) external view returns (uint256);

    ///@dev sets reward for next distribution time
    ///@param _amountWETH amount of wETH tokens
    ///@param _amountWBTC amount of wBTC tokens
    function setReward(uint256 _amountWETH, uint256 _amountWBTC) external;

    ///@dev changes treasury address
    ///@param _treasury address of the treasury
    function changeTreasury(address _treasury) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IDAO {
 
    function getLockedTokens(address staker) external view returns(uint256 locked);
    
    function getAvailableTokens(address staker) external view returns(uint256 locked);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/*
IRewardModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";

import "../OwnerController.sol";

/**
 * @title Reward module interface
 *
 * @notice this contract defines the common interface that any reward module
 * must implement to be compatible with the modular Pool architecture.
 */
abstract contract IRewardModule is OwnerController, IEvents {
    // constants
    uint256 public constant DECIMALS = 18;

    /**
     * @return array of reward tokens
     */
    function tokens() external view virtual returns (address[] memory);

    /**
     * @return array of reward token balances
     */
    function balances() external view virtual returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for reward module
     */
    function usage() external view virtual returns (uint256);

    /**
     * @return address of module factory
     */
    function factory() external view virtual returns (address);

    /**
     * @notice perform any necessary accounting for new stake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of new shares minted
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function stake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice reward user and perform any necessary accounting for unstake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares burned
     * @param data additional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function unstake(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice reward user and perform and necessary accounting for existing stake
     * @param account address of staking account
     * @param user address of user
     * @param shares number of shares being claimed against
     * @param data addtional data
     * @return amount of gysr spent
     * @return amount of gysr vested
     */
    function claim(
        address account,
        address user,
        uint256 shares,
        bytes calldata data
    ) external virtual returns (uint256, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @param user address of user for update
     * @dev will only be called ad hoc and should not contain essential logic
     */
    function update(address user) external virtual;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     */

    function clean() external virtual;

    function fund(uint256 amount, uint256 duration) external virtual;
}

/*
IPoolFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Pool factory interface
 *
 * @notice this defines the Pool factory interface, primarily intended for
 * the Pool contract to interact with
 */
interface IPoolFactory {
    /**
     * @return GYSR treasury address
     */
    function treasury() external view returns (address);

    /**
     * @return GYSR spending fee
     */
    function fee() external view returns (uint256);

    function create(
        address staking,
        address reward,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external returns (address);
}

/*
IPool

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Pool interface
 *
 * @notice this defines the core Pool contract interface
 */
interface IPool {
    /**
     * @return staking tokens for Pool
     */
    function stakingTokens() external view returns (address[] memory);

    /**
     * @return reward tokens for Pool
     */
    function rewardTokens() external view returns (address[] memory);

    /**
     * @return staking balances for user
     */
    function stakingBalances(address user)
        external
        view
        returns (uint256[] memory);

    /**
     * @return total staking balances for Pool
     */
    function stakingTotals() external view returns (uint256[] memory);

    /**
     * @return reward balances for Pool
     */
    function rewardBalances() external view returns (uint256[] memory);

    /**
     * @return GYSR usage ratio for Pool
     */
    function usage() external view returns (uint256);

    /**
     * @return address of staking module
     */
    function stakingModule() external view returns (address);

    /**
     * @return address of reward module
     */
    function rewardModule() external view returns (address);

    /**
     * @notice stake asset and begin earning rewards
     * @param amount number of tokens to unstake
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function stake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice unstake asset and claim rewards
     * @param amount number of tokens to unstake
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function unstake(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice claim rewards without unstaking
     * @param amount number of tokens to claim against
     * @param stakingdata data passed to staking module
     * @param rewarddata data passed to reward module
     */
    function claim(
        uint256 amount,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) external;

    /**
     * @notice method called ad hoc to update user accounting
     */
    function update() external;

    /**
     * @notice method called ad hoc to clean up and perform additional accounting
     */
    function clean() external;

    /**
     * @return gysr balance available for withdrawal
     */
    function gysrBalance() external view returns (uint256);

    /**
     * @notice withdraw GYSR tokens applied during unstaking
     * @param amount number of GYSR to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice transfer control of the Pool and modules to another account
     * @param newController address of new controller
     */
    function transferControl(address newController) external;

    function controller() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/*
IEvents

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.4;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUnlocked(address indexed token, uint256 shares);
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}

/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}