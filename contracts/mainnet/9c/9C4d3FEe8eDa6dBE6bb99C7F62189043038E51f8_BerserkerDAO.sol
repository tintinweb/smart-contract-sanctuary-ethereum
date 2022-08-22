/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ISwapRouter {
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
}

enum State
{
    Default,
    Canceled,
    Executed
}

enum ProposalType
{
    Invalid,
    Swap,
    Transfer
}

struct SwapProposal
{
    // Swap Variables
    address tokenIn;
    address tokenOut;
    uint amountIn;
    uint amountOutMin;

    // Voting variables
    uint timestamp;
    string name;
    string description;
    string image;
    uint berserkerId;

    uint8 forVotes;
    uint8 againstVotes;

    State state;
}

struct TransferProposal
{
    // Swap Variables
    address tokenAddress;
    address to;
    uint amount;

    // Voting variables
    uint timestamp;
    string name;
    string description;
    string image;
    uint berserkerId;

    uint8 forVotes;
    uint8 againstVotes;

    State state;
}

struct GenericProposal
{
    uint proposalId;
    ProposalType proposalType;
}

contract BerserkerDAO is Ownable {

    IERC721 public berserkerNFT;
    ISwapRouter public swapRouter;

    uint public totalProposalCount;
    uint public swapProposalsCount;
    uint public transferProposalsCount;
    mapping(uint => GenericProposal) public  allProposals;
    mapping(uint => SwapProposal) public  swapProposals;
    mapping(uint => TransferProposal) public transferProposals;
    mapping(uint => uint) public lastSwapProposalTimestamp;
    mapping(uint => uint) public lastTransferProposalTimestamp;
    mapping(uint => mapping(uint => bool)) berserkerVotedSwapProposal;  // [Swap Proposal Id][Berserker][Voted]
    mapping(uint => mapping(uint => bool)) berserkerVotedTransferProposal;  // [Transfer Proposal Id][Berserker][Voted]

    uint public VOTE_DURATION = 3 days;
    uint public PROPOSAL_COOLDOWN = 3 days;
    uint public MIN_QUORUM = 3;

    event CreateSwapProposal(uint swapProposalId);
    event CreateTransferProposal(uint transferProposalId);
    event VoteSwapProposal(uint berserkerId, uint swapProposalId, bool supportSwap);
    event VoteTransferProposal(uint berserkerId, uint transferProposalId, bool supportTransfer);
    event ExecuteSwapProposal(uint swapProposalId);
    event ExecuteTransferProposal(uint transferProposalId);
    event CancelSwapProposal(uint swapProposalId);
    event CancelTransferProposal(uint transferProposalId);
    event SetVoteDuration(uint voteDuration);
    event SetProposalCooldown(uint proposalCooldown);
    event SetMinQuorum(uint minQuorum);

    constructor()
    {
        berserkerNFT = IERC721(0x8aE20BB9E02Bb7dB0669ba2232319A24D5856073);
        swapRouter = ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    // Modifiers

    modifier onlyBerserkerHolder(uint berserkerId)
    {
        require(berserkerNFT.ownerOf(berserkerId) == msg.sender, "Must be the NFT holder");
        _;
    }

    // View functions
    function berserkerByIndex(address account, uint index) external view returns(uint){
        uint256 j;
        for (uint i = 0; i < 40; i++) {
            if(berserkerNFT.ownerOf(i) == account){
                if(j == index)
                {
                    return i;
                }
                j++;
            }
        }
        return 0;
    }

    function berserkerBalanceOf(address account) external view returns (uint) {
        uint256 j;
        for (uint i = 0; i < 40; i++) {
            if(berserkerNFT.ownerOf(i) == account){
                
                j++;
            }
        }
        return j;
    }

    function getSwapProposalByIndex(uint index, State state) public view returns(uint, bool)
    {
        uint i;
        uint j;
        while(swapProposals[i].timestamp != 0)
        {
            if(swapProposals[i].state == state)
            {
                if(j == index)
                {
                    return (i, true);
                }
                j++;
            }
            i++;
        }
        return (0,false);
    }

    function getTransferProposalByIndex(uint index, State state) public view returns(uint, ProposalType)
    {
        uint i;
        uint j;
        while(transferProposals[i].timestamp != 0)
        {
            if(transferProposals[i].state == state)
            {
                if(j == index)
                {
                    return (i, ProposalType.Transfer);
                }
                j++;
            }
            i++;
        }
        return (0, ProposalType.Invalid);
    }

    function getProposalByIndex(uint index, State state) public view returns(uint, ProposalType)
    {
        uint i;
        uint j;
        while(allProposals[i].proposalType != ProposalType.Invalid)
        {
            if(
                (
                    allProposals[i].proposalType == ProposalType.Swap
                    && swapProposals[allProposals[i].proposalId].state == state
                ) ||
                (
                    allProposals[i].proposalType == ProposalType.Transfer
                    && transferProposals[allProposals[i].proposalId].state == state
                )
            )
            {
                if(j == index)
                {
                    return (allProposals[i].proposalId, allProposals[i].proposalType);
                }
                j++;
            }
            i++;
        }
        return (0, ProposalType.Invalid);
    }

    // NFT Holder Functions
    function createSwapProposal(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        uint berserkerId,
        string memory name,
        string memory description,
        string memory image
    ) public onlyBerserkerHolder(berserkerId)
    {
        require(lastSwapProposalTimestamp[berserkerId] + PROPOSAL_COOLDOWN < block.timestamp);

        allProposals[totalProposalCount] = GenericProposal(swapProposalsCount, ProposalType.Swap);
        totalProposalCount += 1;

        lastSwapProposalTimestamp[berserkerId] = block.timestamp;
        swapProposals[swapProposalsCount].tokenIn = tokenIn;
        swapProposals[swapProposalsCount].tokenOut = tokenOut;
        swapProposals[swapProposalsCount].amountIn = amountIn;
        swapProposals[swapProposalsCount].amountOutMin = amountOutMin;

        swapProposals[swapProposalsCount].timestamp = block.timestamp;
        swapProposals[swapProposalsCount].name = name;
        swapProposals[swapProposalsCount].description = description;
        swapProposals[swapProposalsCount].image = image;
        swapProposals[swapProposalsCount].berserkerId = berserkerId;

        emit CreateSwapProposal(swapProposalsCount);
        swapProposalsCount += 1;
    }

    function createTransferProposal(
        address tokenAddress,
        address to,
        uint amount,
        uint berserkerId,
        string memory name,
        string memory description,
        string memory image
    ) public onlyBerserkerHolder(berserkerId)
    {
        require(lastTransferProposalTimestamp[berserkerId] + PROPOSAL_COOLDOWN < block.timestamp);

        allProposals[totalProposalCount] = GenericProposal(transferProposalsCount, ProposalType.Transfer);
        totalProposalCount += 1;

        lastSwapProposalTimestamp[berserkerId] = block.timestamp;
        transferProposals[transferProposalsCount].tokenAddress = tokenAddress;
        transferProposals[transferProposalsCount].to = to;
        transferProposals[transferProposalsCount].amount = amount;

        transferProposals[transferProposalsCount].timestamp = block.timestamp;
        transferProposals[transferProposalsCount].name = name;
        transferProposals[transferProposalsCount].description = description;
        transferProposals[transferProposalsCount].image = image;
        transferProposals[transferProposalsCount].berserkerId = berserkerId;

        emit CreateTransferProposal(transferProposalsCount);
        transferProposalsCount += 1;
    }

    function voteSwapProposalWithAccount(uint swapProposalId, bool supportSwap) external {
        bool hasAtLeastABerserker;
        for (uint i = 0; i < 40; i++) {
            if(berserkerNFT.ownerOf(i) == msg.sender){
                hasAtLeastABerserker = true;
                voteSwapProposalWithNFT(i, swapProposalId, supportSwap);
            }
        }
        require(hasAtLeastABerserker, "You don't own a berserker");
    }

    function voteTransferProposalWithAccount(uint transferProposalId, bool supportTransfer) external {
        bool hasAtLeastABerserker;
        for (uint i = 0; i < 40; i++) {
            if(berserkerNFT.ownerOf(i) == msg.sender){
                hasAtLeastABerserker = true;
                voteTransferProposalWithNFT(i, transferProposalId, supportTransfer);
            }
        }
        require(hasAtLeastABerserker, "You don't own a berserker");
    }

    function voteSwapProposalWithNFT(uint berserkerId, uint swapProposalId, bool supportSwap)
        public onlyBerserkerHolder(berserkerId)
    {
        
        require(!berserkerVotedSwapProposal[swapProposalId][berserkerId], "This berserker already voted");
        require(swapProposals[swapProposalId].state != State.Canceled, "Swap is canceled");
        require(swapProposals[swapProposalId].state != State.Executed, "Swap is executed");
        require(block.timestamp < swapProposals[swapProposalId].timestamp + VOTE_DURATION, "Voting period is over");
        berserkerVotedSwapProposal[swapProposalId][berserkerId] = true;
        if(supportSwap)
        {
            swapProposals[swapProposalId].forVotes += 1;
        }else
        {
            swapProposals[swapProposalId].againstVotes += 1;
        }
        emit VoteSwapProposal(berserkerId, swapProposalId, supportSwap);
    }

    function voteTransferProposalWithNFT(uint berserkerId, uint transferProposalId, bool supportTransfer)
        public onlyBerserkerHolder(berserkerId)
    {
        require(!berserkerVotedTransferProposal[transferProposalId][berserkerId], "This berserker already voted");
        require(transferProposals[transferProposalId].state != State.Canceled, "Transfer is canceled");
        require(transferProposals[transferProposalId].state != State.Executed, "Transfer is executed");
        require(block.timestamp < transferProposals[transferProposalId].timestamp + VOTE_DURATION, "Voting period is over");
        berserkerVotedTransferProposal[transferProposalId][berserkerId] = true;
        if(supportTransfer)
        {
            transferProposals[transferProposalId].forVotes += 1;
        }else
        {
            transferProposals[transferProposalId].againstVotes += 1;
        }
        emit VoteTransferProposal(berserkerId, transferProposalId, supportTransfer);
    }

    function executeSwap(uint swapProposalId) public
    {
        require(berserkerNFT.ownerOf(swapProposals[swapProposalId].berserkerId) == msg.sender, "Only the proposal creator can execute.");
        require(block.timestamp >= swapProposals[swapProposalId].timestamp + VOTE_DURATION, "Must wait for voting period to finish");
        require(swapProposals[swapProposalId].state != State.Canceled, "Swap is canceled");
        require(swapProposals[swapProposalId].state != State.Executed, "Swap is executed");
        require(swapProposals[swapProposalId].forVotes + swapProposals[swapProposalId].againstVotes
            >= MIN_QUORUM, "There must be at least 3 votes as a quorum");
        require(swapProposals[swapProposalId].forVotes > swapProposals[swapProposalId].againstVotes, "For votes must be greater than against votes");

        swapProposals[swapProposalId].state = State.Executed;
        address[] memory path;
        path = new address[](2);
        path[0] = swapProposals[swapProposalId].tokenIn;
        path[1] = swapProposals[swapProposalId].tokenOut;
        IERC20(path[0]).approve(address(swapRouter), swapProposals[swapProposalId].amountIn);
        swapRouter.swapExactTokensForTokens(
            swapProposals[swapProposalId].amountIn,
            swapProposals[swapProposalId].amountOutMin,
            path,
            address(this),
            block.timestamp
        );

        emit ExecuteSwapProposal(swapProposalId);
    }

    function executeTransfer(uint transferProposalId) public
    {
        require(berserkerNFT.ownerOf(transferProposals[transferProposalId].berserkerId) == msg.sender, "Only the proposal creator can execute.");
        require(block.timestamp >= transferProposals[transferProposalId].timestamp + VOTE_DURATION, "Must wait for voting period to finish");
        require(transferProposals[transferProposalId].state != State.Canceled, "Transfer is canceled");
        require(transferProposals[transferProposalId].state != State.Executed, "Transfer is executed");
        require(transferProposals[transferProposalId].forVotes + transferProposals[transferProposalId].againstVotes
            >= MIN_QUORUM, "There must be at least 3 votes as a quorum");
        require(transferProposals[transferProposalId].forVotes > transferProposals[transferProposalId].againstVotes, "For votes must be greater than against votes");

        transferProposals[transferProposalId].state = State.Executed;

        IERC20(transferProposals[transferProposalId].tokenAddress).transfer(
            transferProposals[transferProposalId].to,
            transferProposals[transferProposalId].amount
        );
        emit ExecuteTransferProposal(transferProposalId);
    }

    // Admin Functions

    function cancelSwapProposal(uint swapProposalId) public onlyOwner
    {
        swapProposals[swapProposalId].state = State.Canceled;
        emit CancelSwapProposal(swapProposalId);
    }

    function cancelTransferProposal(uint transferProposalId) public onlyOwner
    {
        transferProposals[transferProposalId].state = State.Canceled;
        emit CancelTransferProposal(transferProposalId);
    }

    function setVoteDuration(uint voteDuration) public onlyOwner
    {
        VOTE_DURATION = voteDuration;
        emit SetVoteDuration(voteDuration);
    }

    function setProposalCooldown(uint proposalCooldown) public onlyOwner
    {
        PROPOSAL_COOLDOWN = proposalCooldown;
        emit SetProposalCooldown(proposalCooldown);
    }

    function setMinQuorum(uint minQuorum) public onlyOwner
    {
        MIN_QUORUM = minQuorum;
        emit SetMinQuorum(minQuorum);
    }

    function adminWithdraw(address tokenAddress, uint amount) public onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function adminWithdrawETH(uint amount) public onlyOwner
    {
        (bool sent, bytes memory data) = owner().call{value: amount}("");
        data;
        require(sent, "Failed to send Ether");
    }
}