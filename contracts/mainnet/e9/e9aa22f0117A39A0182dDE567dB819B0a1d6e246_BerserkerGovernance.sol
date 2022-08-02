// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./interfaces.sol";

contract BerserkerGovernance is GovernorInterface, GovernorEvents {
    /// @notice The minimum setable voting period by seconds
    uint256 public constant MIN_VOTING_PERIOD = 1 minutes; // 24 hours

    /// @notice The max setable voting period by seconds
    uint256 public constant MAX_VOTING_PERIOD = 14 days; // 2 weeks

    /// @notice The min setable voting delay by seconds
    uint256 public constant MIN_VOTING_DELAY = 1 minutes; // 24 hours

    /// @notice The max setable voting delay by seconds
    uint256 public constant MAX_VOTING_DELAY = 1 weeks; // 1 week

    /// @notice The interval time between proposals of one member by seconds
    uint256 public constant INTERVAL_TIME = 10 minutes; // 1 week

    // address public BUSD;
    address public USDC;
    IERC721 public berserker;

    //address of the uniswap v2 router
    address private constant SWAP_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    //address of WETH token.  This is needed because some times it is better to trade through WETH.
    //you might get a better price using WETH.
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private WETH;

    constructor() {
        votingPeriod = 1 minutes; // 5 days
        votingDelay = 1 minutes; // 2 days
        admin = 0xf0Bc35eFCc611eb89181cC73EB712650FCdC9087; // admin's wallet address

        USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        // BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

        // IERC721 _berserker = IERC721(0x8aE20BB9E02Bb7dB0669ba2232319A24D5856073);
        IERC721 _berserker = IERC721(
            0xa99f55a97Ac5c8A9653Fe4ED6A18628bC807CB50
        );
        berserker = _berserker;

        WETH = ISwapRouter(SWAP_ROUTER).WETH();
    }

    /**
     * @notice Function used to propose a new proposal.
     * @param target Target address for proposal calls
     * @param value usdc value for proposal calls
     * @param name String name of the proposal
     * @param description String description of the proposal
     * @return Proposal id of new proposal
     */
    function propose(
        address token,
        address target,
        uint256 value,
        string memory name,
        string memory description
    ) public returns (uint256) {
        // Only Berserker DAO members
        require(
            getNFTBalance(msg.sender) > 0,
            "GovernorBravo::propose: only member can propose"
        );
        // require(dCult.checkHighestStaker(0,msg.sender),"GovernorBravo::propose: only top staker");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            // ProposalState proposersLatestProposalState = state(latestProposalId);
            // require(proposersLatestProposalState != ProposalState.Active, "GovernorBravo::propose: one live proposal per proposer, found an already active proposal");
            // require(proposersLatestProposalState != ProposalState.Pending, "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal");
            require(add256(proposals[latestProposalId].startTime, INTERVAL_TIME) < block.timestamp, "GovernorBravo::propose: members can propose only once per week");
        }

        uint256 startTime = add256(block.timestamp, votingDelay);
        uint256 endTime = add256(startTime, votingPeriod);

        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.token = token;
        newProposal.target = target;
        newProposal.value = value;
        newProposal.name = name;
        newProposal.description = description;
        newProposal.startTime = startTime;
        newProposal.endTime = endTime;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            target,
            value,
            startTime,
            endTime,
            name,
            description
        );
        return newProposal.id;
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external payable {
        require(
            state(proposalId) == ProposalState.Queued,
            "GovernorBravo::execute: proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[proposalId];

        require(
            msg.sender == admin,
            "GovernorBravo::execute: Only admin can execute proposal"
        );
        proposal.executed = true;

        // require(
        //     IERC20(BUSD).balanceOf(address(this)) >= proposal.value,
        //     "GovernorBravo::execute: No enough amount"
        // );
        // if (proposal.token == BUSD) {
        //     IERC20(BUSD).transfer(proposal.target, proposal.value);
        // } else {
        //     // uint256 amountOutMin = getAmountOutMin(BUSD, proposal.token, proposal.value);
        //     swap(BUSD, proposal.token, proposal.value, 0, proposal.target);
        // }

        require(
            IERC20(USDC).balanceOf(address(this)) >= proposal.value,
            "GovernorBravo::execute: No enough amount"
        );
        if (proposal.token == USDC) {
            IERC20(USDC).transfer(proposal.target, proposal.value);
        } else {
            // uint256 amountOutMin = getAmountOutMin(BUSD, proposal.token, proposal.value);
            swap(USDC, proposal.token, proposal.value, 0, proposal.target);
        }

        emit ProposalExecuted(proposalId);
    }

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) internal {
        IERC20(_tokenIn).approve(SWAP_ROUTER, _amountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        ISwapRouter(SWAP_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external {
        require(
            state(proposalId) != ProposalState.Executed,
            "GovernorBravo::cancel: cannot cancel executed proposal"
        );

        Proposal storage proposal = proposals[proposalId];

        require(
            msg.sender == proposal.proposer || msg.sender == admin,
            "GovernorBravo::cancel: Only proposer and admin can cancel proposal"
        );

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter)
        external
        view
        returns (Receipt memory)
    {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(
            proposalCount >= proposalId,
            "GovernorBravo::state: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (
            proposal.forVotes <= proposal.againstVotes ||
            proposal.forVotes + proposal.againstVotes < 3
        ) {
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for
     */
    function castVote(uint256 proposalId, uint8 support) external {
        castVoteInternal(msg.sender, proposalId, support);
        emit VoteCast(msg.sender, proposalId, support);
    }

    /*
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for
     * @return The number of votes cast
     */
    function castVoteInternal(
        address voter,
        uint256 proposalId,
        uint8 support
    ) internal {
        // Only DAO member can vote
        require(
            getNFTBalance(voter) > 0,
            "GovernorBravo::castVoteInternal: only member can vote"
        );
        // require(!dCult.checkHighestStaker(0,msg.sender),"GovernorBravo::castVoteInternal: Top staker cannot vote");
        require(
            state(proposalId) == ProposalState.Active,
            "GovernorBravo::castVoteInternal: voting is closed"
        );
        require(
            support < 2,
            "GovernorBravo::castVoteInternal: invalid vote type"
        );
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(
            receipt.hasVoted == false,
            "GovernorBravo::castVoteInternal: voter already voted"
        );
        receipt.votes = getNFTBalance(voter);

        if (support == 0) {
            proposal.againstVotes += receipt.votes;
        } else if (support == 1) {
            proposal.forVotes += receipt.votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
    }

    function canVote(address user, uint256 proposalId)
        public
        view
        returns (bool)
    {
        if (
            getNFTBalance(user) > 0 &&
            user != proposals[proposalId].proposer &&
            proposals[proposalId].receipts[user].hasVoted == false
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Admin function for setting the voting delay
     * newVotingDelay new voting delay, in blocks
     */
    function _setVotingDelay(uint256 newVotingDelay) external {
        require(
            msg.sender == admin,
            "GovernorBravo::_setVotingDelay: admin only"
        );
        require(
            newVotingDelay >= MIN_VOTING_DELAY &&
                newVotingDelay <= MAX_VOTING_DELAY,
            "GovernorBravo::_setVotingDelay: invalid voting delay"
        );
        uint256 oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /**
     * @notice Admin function for setting the voting period
     * newVotingPeriod new voting period, in blocks
     */
    function _setVotingPeriod(uint256 newVotingPeriod) external {
        require(
            msg.sender == admin,
            "GovernorBravo::_setVotingPeriod: admin only"
        );
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD &&
                newVotingPeriod <= MAX_VOTING_PERIOD,
            "GovernorBravo::_setVotingPeriod: invalid voting period"
        );
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    function _setAdmin(address newAdmin) external {
        require(msg.sender == admin, "GovernorBravo::_setAdmin: admin only");
        admin = newAdmin;
    }

    // function getNeedBUSD() external {

    // }

    function add256(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getNFTBalance(address account) internal view returns (uint8) {
        uint8 _balance = 0;
        for (uint256 i = 0; i < 40; i++) {
            if (berserker.ownerOf(i) == account) {
                _balance += 1;
            }
        }
        return _balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ISwapRouter {
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

contract GovernorEvents {
    // @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address target, uint value, uint startBlock, uint endBlock, string name, string description);

    // @notice An event emitted when a vote has been cast on a proposal
    // @param voter The address which casted a vote
    // @param proposalId The proposal id which was voted on
    // @param support Support value for the vote. 0=against, 1=for
    // @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint proposalId, uint8 support);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint oldVotingDelay, uint newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint oldVotingPeriod, uint newVotingPeriod);
}

contract GovernorInterface{
    /// @notice Administrator for this contract
    address public admin;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint public votingPeriod;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;


    struct Proposal {
        // Unique id for looking up a proposal
        uint id;

        // Creator of the proposal
        address proposer;

        // token address to be swapped.
        address token;

        // the ordered target address for calls to be made
        address target;

        // The ordered usdc value
        uint256 value;

        // The name of the proposal
        string name;

        // The description of the proposal
        string description;

        // The time at which voting begins
        uint startTime;

        // The time at which voting ends
        uint endTime;

        // Current number of votes in favor of this proposal
        uint forVotes;

        // Current number of votes in opposition to this proposal
        uint againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal or abstains
        uint8 support;

        // The number of votes the voter had, which were cast
        uint8 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Queued,
        Executed
    }
}