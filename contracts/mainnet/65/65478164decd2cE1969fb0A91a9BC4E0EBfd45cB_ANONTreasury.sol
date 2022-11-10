/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: ANONDAO.sol



pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}

interface IdaoContract {
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin,address[] calldata path,address to,uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external;
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract ANONTreasury is ReentrancyGuard {

    /////////////////////////////////// DAO Stuff //////////////////////////////////////

    address public owner;
    uint256 public nextProposal;
    uint256 public nextVote;
    uint256 public nextPosition;
    uint256 public nextBurn;
    uint256 public treasuryProfitsEth;
    address public burnAddress;
    address[] public validTokens;
    IdaoContract daoContract;

    constructor () {
        owner = msg.sender;
        nextProposal = 1;
        nextVote = 1;
        nextPosition = 1;
        nextBurn = 1;
        treasuryProfitsEth = 0;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        daoContract = IdaoContract(0xb8F33C298917E23c81cE5252887eD96299009afe); // ANON CA
        validTokens = [0xb8F33C298917E23c81cE5252887eD96299009afe]; // ANON CA
    }

   struct option {
        uint256 id;
        bool exists;
        string option;
        uint256 totalvotes;
    }
   
   struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        bool countConducted;
        bool open;
        mapping(address => bool) voteStatus;
        uint256 numberOfOptions;
        mapping(uint256 => option) options;
        uint256 totalVotes;
    }

    struct vote {
        uint256 id;
        bool exists;
        address voter1;
        uint256 proposal;
        uint256 votedFor;
    }

    struct position {
        uint256 id;
        bool exists;
        string symbol;
        address tokenAddress;
        uint256 currentTokenPrice;
        uint256 amountOfEthBought;
    }

    struct burn {
        uint256 id;
        bool exists;
        uint256 amountOfEth;
        uint256 amountOfTokensBought;
        address tokenAddress;
    }

    mapping(uint256 => proposal) public Proposals;

    mapping(uint256 => vote) public Votes;

    mapping(uint256 => position) public Positions;
    
    mapping(uint256 => burn) public Burns;

    modifier onlyOwner {
     require (owner == msg.sender, "Only owner may call this function");
     _;
    }

    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for (uint i = 0; i < validTokens.length; i ++) {
            if(daoContract.balanceOf(_proposalist) >= 100000000000000000) {
                return true;
            }
        }
        return false;
    }

    function createProposal (string memory _description, string memory _token1, string memory _token2, string memory _token3, string memory _token4, string memory _token5) external onlyOwner {

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 50000;
        newProposal.countConducted = false;
        newProposal.open = true;
        newProposal.numberOfOptions = 5;
        newProposal.totalVotes = 0;

        option storage newOption1 = newProposal.options[1];
        newOption1.id = 1;
        newOption1.exists = true;
        newOption1.option = _token1;
        newOption1.totalvotes = 0;

        option storage newOption2 = newProposal.options[2];
        newOption2.id = 2;
        newOption2.exists = true;
        newOption2.option = _token2;
        newOption2.totalvotes = 0;

        option storage newOption3 = newProposal.options[3];
        newOption3.id = 3;
        newOption3.exists = true;
        newOption3.option = _token3;
        newOption3.totalvotes = 0;

        option storage newOption4 = newProposal.options[4];
        newOption4.id = 4;
        newOption4.exists = true;
        newOption4.option = _token4;
        newOption4.totalvotes = 0;

        option storage newOption5 = newProposal.options[5];
        newOption5.id = 5;
        newOption5.exists = true;
        newOption5.option = _token5;
        newOption5.totalvotes = 0;

        nextProposal++;
    }

    function AddOption(uint256 _proposalId, string memory _tokenSymbol) external {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 100,000,000 $ANON to add options.');
        require(Proposals[_proposalId].exists, "This proposal doesn't exist.");
        proposal storage p = Proposals[_proposalId];

        option storage newOption = p.options[p.numberOfOptions + 1];
        newOption.id = p.numberOfOptions + 1;
        newOption.exists = true;
        newOption.option = _tokenSymbol;
        newOption.totalvotes = 0;

        p.numberOfOptions++;
    }

    function VoteOnProposal(uint256 _proposalId, uint256 _optionId) external {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 100,000,000 $ANON to put forth votes.');
        require(Proposals[_proposalId].exists, "This proposal doesn't exist.");
        require(Proposals[_proposalId].options[_optionId].exists, "This option doesn't exist.");
        require(!Proposals[_proposalId].voteStatus[msg.sender], 'You have already voted on this proposal.');
        require(block.number <= Proposals[_proposalId].deadline, 'The deadline has passed for this proposal.');
        require(!Proposals[_proposalId].countConducted, 'Count already conducted.');

        uint256 tokenBalance = daoContract.balanceOf(msg.sender);
        uint256 minimumBalanceForOneVote = 100000000000000000;

        uint256 userVoteValue = tokenBalance / minimumBalanceForOneVote;

        proposal storage p = Proposals[_proposalId];
        option storage o = p.options[_optionId];

        o.totalvotes = o.totalvotes + userVoteValue;
        p.totalVotes = p.totalVotes + userVoteValue;
        p.voteStatus[msg.sender] = true;

        vote storage newVote1 = Votes[nextVote];
        newVote1.id = nextVote;
        newVote1.exists = true;
        newVote1.voter1 = msg.sender;
        newVote1.proposal = _proposalId;
        newVote1.votedFor = _optionId;

        nextVote++;
    }

    function countVotes(uint256 _proposalId) external onlyOwner {
        require(Proposals[_proposalId].exists, 'This proposal does not exist.');
        require(!Proposals[_proposalId].countConducted, 'Count already conducted.');

        proposal storage p = Proposals[_proposalId];

        p.countConducted = true;
    }

    function getOption(uint256 _proposalId, uint256 _optionId) public view returns(uint256, bool, string memory, uint256) {
        proposal storage p = Proposals[_proposalId];
        option storage o = p.options[_optionId];

        return (o.id, o.exists, o.option, o.totalvotes);
    }

    /////////////////////////////////// Swap Stuff //////////////////////////////////////

    address _UniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Goerli And Mainnet;
    IUniswapV2Router02 router = IUniswapV2Router02(_UniswapV2Router);

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // MAINNET

   function buyTokenWithEth(address _tokenToBuy, uint256 _amountEth, string memory _symbol, uint256 _tokenPrice) public onlyOwner {

        position storage newPosition = Positions[nextPosition];
        newPosition.id = nextPosition;
        newPosition.exists = true;
        newPosition.symbol = _symbol;
        newPosition.tokenAddress = _tokenToBuy;
        newPosition.currentTokenPrice = _tokenPrice;
        newPosition.amountOfEthBought = _amountEth;

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenToBuy;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: (_amountEth) }(5, path, address(this), block.timestamp + 15);

        nextPosition++;
   }

   function sellSpecificTokenForEth(address _tokenToSell, uint256 _positionProfitEth) public onlyOwner {
        IERC20 token = IERC20(_tokenToSell);
        uint balance = token.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = _tokenToSell;
        path[1] = WETH;

        token.approve(_UniswapV2Router, balance * 2);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 5, path, address(this), block.timestamp + 15);

        treasuryProfitsEth = treasuryProfitsEth + _positionProfitEth;
   }

   function buyBackAndBurn(address _tokenToBuy, uint256 _amountEth) public onlyOwner {

        burn storage newBurn = Burns[nextBurn];
        newBurn.id = nextBurn;
        newBurn.exists = true;
        newBurn.amountOfEth = _amountEth;
        newBurn.tokenAddress = _tokenToBuy;

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenToBuy;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: (_amountEth) }(5, path, address(this), block.timestamp + 15);

        newBurn.amountOfTokensBought = IERC20(_tokenToBuy).balanceOf(address(this));

        IERC20(_tokenToBuy).transfer(burnAddress, newBurn.amountOfTokensBought);

        nextBurn++;
   }

    receive() external payable {

    }

    function withdrawEth() external onlyOwner {
        (bool os,) = payable(owner).call{value:address(this).balance}("");
        require(os);
    }

}