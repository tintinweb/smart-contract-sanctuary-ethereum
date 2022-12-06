// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.7;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";

import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IUniswapV2Router02.sol";

import "../interfaces/ImainDao.sol";

import "../libraries/Ownable.sol";
import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

contract TomiDAOEvents {

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        string description,
        string title
    );

    event ProposalCreatedForEmissionUpdate(
        uint256 id,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        string description,
        string title
    );

    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        uint256 quorumVotes,
        string description,
        string title
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice An event emitted when a proposal has been executed in the TomiDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);

    /// @notice Emitted when fees are transferred for proposals
    event ProposalFee(address proposer, uint256 amount);
}

contract TomiStates {

    /// @notice Vetoer who has the ability to veto any proposal
    address public vetoer;

    // goerli tokens
    IERC20 public usdToken = IERC20(0x85fcb519c06cb48A74fd0baD6438ABF25D42cdb4);
    IERC20 public tomiToken = IERC20(0x85fcb519c06cb48A74fd0baD6438ABF25D42cdb4);
    IERC20 public wethToken = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    /// @notice The address of the Tomi tokens
    IERC721 public tomiNFT;

    /// @notice address of the control dao
    ImainDao public mainTomiDao;

    /// @notice address of the treasury
    address public treasury;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping (uint256 => Proposal) public proposals;
    mapping (uint256 => ProposalChangeEmissionData) public proposalsChangeEmissionData;
    mapping (uint256 => ProposalWalletData) public proposalsWalletData;

    /// @notice The latest proposal for each proposer
    mapping (address => uint256) public latestProposalIds;

    /**
     * uniswap v2 router to calculate the token"s reward on run-time
     * usd balance equivalent token
     */
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    struct emissionCriteria {
        // tomi mints before auction first 2 weeks of NFT Minting
        uint256 beforeAuctionBuyer;
        uint256 beforeAuctionTomi;
        uint256 beforeAuctionMarketing;

        // tomi mints after two weeks // auction everyday of NFT Minting
        uint256 afterAuctionBuyer;
        uint256 afterAuctionTomi;
        uint256 afterAuctionMarketing;

        // booleans for checks of minting
        bool mintAllowed;

        // Mining Criteria and checks
        bool miningAllowed;
        uint8 poolPercentage;
        uint8 tomiPercentage;
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice nft used to make this proposal with
        uint256[] nftIds;
        /// @notice function id of proposal
        uint256 functionId;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice max amount of allowed votes in a given proposal
        uint256 quorumVotes;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    struct ProposalChangeEmissionData {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Emission data to update
        IERC20.emissionCriteria emission;
    }

    struct ProposalWalletData {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Wallet to update
        address wallet;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
        /// @notice Whether or not a vote has been cast by the id
        uint256[] nftIds;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        // Queued,
        // Expired,
        Executed,
        Vetoed
    }
}

contract TomiTokenDao is TomiStates, TomiDAOEvents, Ownable {
    using SafeMath for uint256;

    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    struct ProposalTemp {
        uint256 quorumVotes;
        uint256 latestProposalId;
        uint256 startBlock;
        uint256 endBlock;
    }

    // NFTs used to create each current proposal
    mapping (uint256 => bool) public nftUsed;

    // NFTs used to vote in each proposal
    mapping (uint256 => mapping (uint256 => bool)) public nftVoted;

    // The current saved state for each proposal
    mapping (uint256 => uint256) public proposalState;

    constructor(ImainDao maindao) {
        mainTomiDao = maindao;
    }

    function proposeChangeEmissionWithEth(
        string calldata description,
        uint256[] calldata nftIds,
        string calldata title,
        uint256 functionId,
        IERC20.emissionCriteria calldata emission
    ) public payable {
        require(msg.value >= priceOfUSDinETH(), "send Correct Ether value");
        require(nftIds.length == mainTomiDao.amountNFTRequiredToPropose(), "insufficient NFT amount for proposal");
        require(functionId == 1, "incorrect function id");
        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        for (uint8 i = 0 ; i < nftIds.length ; i++) {
            require(nftUsed[nftIds[i]] != true, "proposal already exists on one of the NFTs");
            require(tomiNFT.ownerOf(nftIds[i]) == _msgSender(), "caller is not owner");
        }
        ProposalChangeEmissionData storage newProposalData = proposalsChangeEmissionData[proposalCount];

        ProposalTemp memory temp;
        temp.quorumVotes = tomiNFT.totalSupply().mul(mainTomiDao.proposalCriteria(functionId).qourumVotes);
        temp.quorumVotes = temp.quorumVotes.mod(100) == 0 ? temp.quorumVotes.div(100) : temp.quorumVotes.div(100).add(1);

        temp.latestProposalId = latestProposalIds[_msgSender()];
        {
            if (temp.latestProposalId != 0) {
                checkPreviousLiveProposals(temp.latestProposalId);
            }
        }
        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock.add(mainTomiDao.proposalCriteria(functionId).votingPeriod);

        newProposal.id = proposalCount;
        newProposal.nftIds = nftIds;
        newProposal.functionId = functionId;
        newProposal.proposer = _msgSender();
        newProposal.quorumVotes = temp.quorumVotes;
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;

        newProposalData.id = proposalCount;
        newProposalData.emission = emission;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        emit ProposalCreated(proposalCount, _msgSender(), newProposal.startBlock, newProposal.endBlock, description, title);
    }

    function proposeUpdateWalletWithEth(
        string calldata description,
        uint256[] calldata nftIds,
        string calldata title,
        uint8 functionId,
        address wallet
    ) public payable {
        require(msg.value >= priceOfUSDinETH(), "send Correct Ether value");
        require(nftIds.length == mainTomiDao.amountNFTRequiredToPropose(), "insufficient NFT amount for proposal");
        require(2 <= functionId && functionId <= 4, "incorrect function id");
        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        for (uint8 i = 0 ; i < nftIds.length ; i++) {
            require(nftUsed[nftIds[i]] != true, "proposal already exists on one of the NFTs");
            require(tomiNFT.ownerOf(nftIds[i]) == _msgSender(), "caller is not owner");
        }
        ProposalWalletData storage newProposalData = proposalsWalletData[proposalCount];

        ProposalTemp memory temp;
        temp.quorumVotes = tomiNFT.totalSupply().mul(mainTomiDao.proposalCriteria(functionId).qourumVotes);
        temp.quorumVotes = temp.quorumVotes.mod(100) == 0 ? temp.quorumVotes.div(100) : temp.quorumVotes.div(100).add(1);

        temp.latestProposalId = latestProposalIds[_msgSender()];
        {
            if (temp.latestProposalId != 0) {
                checkPreviousLiveProposals(temp.latestProposalId);
            }
        }
        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock.add(mainTomiDao.proposalCriteria(functionId).votingPeriod);

        newProposal.id = proposalCount;
        newProposal.nftIds = nftIds;
        newProposal.functionId = functionId;
        newProposal.proposer = _msgSender();
        newProposal.quorumVotes = temp.quorumVotes;
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;

        newProposalData.id = proposalCount;
        newProposalData.wallet = wallet;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        emit ProposalCreated(proposalCount, _msgSender(), newProposal.startBlock, newProposal.endBlock, description, title);
    }

    function checkPreviousLiveProposals(uint256 id) internal view {
        ProposalState proposersLatestProposalState = state(id);
        require(proposersLatestProposalState != ProposalState.Active,
            "TomiDAO::propose: one live proposal per proposer, found an already active proposal");
        require(proposersLatestProposalState != ProposalState.Pending,
            "TomiDAO::propose: one live proposal per proposer, found an already pending proposal");
    }

    function getConsensusVotes(uint256 quorumVotes, uint256 functionId) internal view returns (uint256) {
        uint256 consensusVotes = quorumVotes.mul(mainTomiDao.proposalCriteria(functionId).consensusVotes);
        consensusVotes = consensusVotes.mod(100) == 0 ? consensusVotes.div(100) : consensusVotes.div(100).add(1);

        return consensusVotes;
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "TomiDAO::state: invalid proposal id");

        Proposal storage proposal = proposals[proposalId];

        uint256 consensusVotes = getConsensusVotes(proposal.quorumVotes, proposal.functionId);

        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes < consensusVotes) {
            return ProposalState.Defeated;
        } else {
            return ProposalState.Succeeded;
        }
    }

    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @param nftIds The IDs of NFTs for vote
     */
    function castVote(uint256 proposalId, uint8 support, uint256[] calldata nftIds) external {
        emit VoteCast(_msgSender(), proposalId, support, castVoteInternal(_msgSender(), proposalId, support, nftIds), "");
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return votes The number of votes cast
     */
    function castVoteInternal(
        address voter,
        uint256 proposalId,
        uint8 support,
        uint256[] calldata nftIds
    ) internal returns (uint96 votes) {
        require(state(proposalId) == ProposalState.Active, "TomiDAO::castVoteInternal: voting is closed");
        require(support <= 2, "TomiDAO::castVoteInternal: invalid vote type");
        require(nftIds.length == mainTomiDao.amountNFTRequiredToVote(), "TomiDAO::castVoteInternal: incorrect nft amount");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(!receipt.hasVoted, "TomiDAO::castVoteInternal: voter already voted");

        for (uint8 i = 0 ; i < nftIds.length ; i++) {
            require(!nftVoted[proposalId][nftIds[i]], "this nft has already voted");
            nftVoted[proposalId][nftIds[i]] = true;
        }

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
        receipt.nftIds = nftIds;

        return votes;
    }

    function processUsdTokenPayments() internal {
        uint256 fee = mainTomiDao.initialFee().div(10**18);

        SafeERC20.safeTransferFrom(usdToken,_msgSender(), address(treasury), fee);

        emit ProposalFee(_msgSender(), fee);
    }

    function processTomiTokenPayments() internal {
        address[] memory path;
        path[0] = address(usdToken);
        path[1] = address(wethToken);
        path[2] = address(tomiToken);

        uint256[] memory fee = priceOfToken(mainTomiDao.initialFee().div(10**8), path);

        SafeERC20.safeTransferFrom(usdToken,_msgSender(), address(treasury), fee[2]);

        emit ProposalFee(_msgSender(), fee[2]);
    }

    /**
     * get the price of token, input amount of USDC and addresses of udsc and state token, it will return
     * usdc amount equal state tokens
     */
    function priceOfToken(uint256 amount, address[] memory path) public view returns (uint256[] memory amounts){
        amounts = uniswapRouter.getAmountsOut(amount, path);
        return amounts;
    }

    function priceOfUSDinETH() public view returns (uint256) {
        return mainTomiDao.initialFee().div(getLatestPrice());
    }

    // latest Eth Price
    function getLatestPrice() public view  returns (uint256) {
        (/*uint80 roundID*/, int price, /*uint256 startedAt*/, /*uint256 timeStamp*/, /*uint80 answeredInRound*/) =
            priceFeed.latestRoundData();

        return uint256(price);
    }

    function veto(uint256 proposalId) external {
        require(vetoer != address(0), "TomiDAO::veto: veto power burned");
        require(_msgSender() == vetoer, "TomiDAO::veto: only vetoer");

        require(proposalState[proposalId] != uint256(ProposalState.Executed), "TomiDAO::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];


        for (uint8 i = 0 ; i < proposal.nftIds.length ; i++) {
            nftUsed[proposal.nftIds[i]] = false;
        }

        proposal.vetoed = true;

        proposalState[proposalId] = uint256(ProposalState.Vetoed);

        emit ProposalVetoed(proposalId);
    }

    function executeChangeEmission(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.functionId == 1, "incorrect function id");
        require(state(proposalId) == ProposalState.Succeeded || state(proposalId) == ProposalState.Defeated,
            "TomiDAO::execute: proposal can only be executed if it has succeeded or failed");
        require(block.timestamp >= proposal.endBlock, "proposal is currently active");

        proposal.executed = true;

        for (uint8 i = 0 ; i < proposal.nftIds.length ; i++) {
            nftUsed[proposal.nftIds[i]] = false;
        }

        proposalState[proposalId] = uint256(ProposalState.Executed);

        if (state(proposalId) == ProposalState.Succeeded) {
            IERC20.emissionCriteria memory proposalEmission = proposalsChangeEmissionData[proposal.id].emission;
            tomiToken.updateEmissions(proposalEmission);
        }

        emit ProposalExecuted(proposalId);
    }

    function executeUpdateWallet(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(2 <= proposal.functionId && proposal.functionId <= 4, "incorrect function id");
        require(state(proposalId) == ProposalState.Succeeded || state(proposalId) == ProposalState.Defeated,
            "TomiDAO::execute: proposal can only be executed if it has succeeded or failed");
        require(block.timestamp >= proposal.endBlock, "proposal is currently active");

        proposal.executed = true;

        for (uint8 i = 0 ; i < proposal.nftIds.length ; i++) {
            nftUsed[proposal.nftIds[i]] = false;
        }

        proposalState[proposalId] = uint256(ProposalState.Executed);

        if (state(proposalId) == ProposalState.Succeeded) {
            address wallet = proposalsWalletData[proposal.id].wallet;
            if (proposal.functionId == 2) {
                tomiToken.updateMarketingWallet(wallet);
            } else if (proposal.functionId == 3) {
                tomiToken.updateTomiWallet(wallet);
            } else if (proposal.functionId == 4) {
                tomiToken.changeBlockState(wallet);
            }
        }

        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) external {
        require(proposalState[proposalId] != uint256(ProposalState.Executed), "TomiDAO::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];

        require(_msgSender() == proposal.proposer, "TomiDAO::cancel: caller is not proposer");

        for (uint8 i = 0 ; i < proposal.nftIds.length ; i++) {
            nftUsed[proposal.nftIds[i]] = false;
        }

        proposal.canceled = true;

        proposalState[proposalId] = uint256(ProposalState.Canceled);

        emit ProposalCanceled(proposalId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.7;

import "./Context.sol";

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.7;

interface ImainDao {

    struct Proposaltype {
        uint256 qourumVotes;
        uint256 consensusVotes;
        uint256 votingPeriod;
        string name;
    }

    function amountNFTRequiredToPropose() external view returns (uint256);

    function amountNFTRequiredToVote() external view returns (uint256);

    function proposalCriteria(uint256 id) external view returns (Proposaltype memory);

    function initialFee() external view returns (uint256);

    function getVetoer() external view returns(address);
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: BSD-3-Clause

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function totalSupply() external view returns (uint256);
    function blockWallet() external;
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint256);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  struct emissionCriteria{
        // tomi mints before auction first 2 weeks of NFT Minting
       uint256 beforeAuctionBuyer;
       uint256 beforeAuctionTomi;
       uint256 beforeAuctionMarketing;

        // tomi mints after two weeks // auction everyday of NFT Minting
       uint256 afterAuctionBuyer;
       uint256 afterAuctionTomi;
       uint256 afterAuctionMarketing;

       // booleans for checks of minting
       bool mintAllowed;

       // Mining Criteria and checks
       bool miningAllowed;
       uint8 poolPercentage;
       uint8 tomiPercentage;
   }
  
  function updateEmissions(emissionCriteria calldata emissions_) external;
  function updateMarketingWallet(address newAddress) external;
  function updateTomiWallet(address newAddress) external;
  function changeBlockState(address newAddress) external;

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

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.7;

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}