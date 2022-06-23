/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the UAP token(ERC20) as defined in the EIP.
 */
interface IUAP {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function releaseLiquidityToken(address liquidityAddress, uint256 tAmount) external;
    function releaseLegalToken(address legalAddress, uint256 tAmount) external;
    function releaseGrantToken(address grantAddress, uint256 tAmount) external;
    function releaseInvestmentToken(address investmentAddress, uint256 tAmount) external;
    function releaseGeneralFundToken(address generalFundAddress, uint256 tAmount) external;
}

interface IUAPProposal {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `proposalId` token.
     *
     * Requirements:
     *
     * - `proposalId` must exist.
     */
    function ownerOf(uint256 proposalId) external view returns (address owner);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function proposalOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 proposalId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function proposalByIndex(uint256 index) external view returns (uint256);
}

contract UAPProposal is Ownable, IUAPProposal {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _gProposalId;

    // Name
    string private _name = "UAP Vote";
    // Symbol
    string private _symbol = "UAPV";

    // Mapping from proposal ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to proposal count
    mapping(address => uint256) private _balances;

    // Mapping from owner to list of owned proposal IDs
    mapping(address => mapping(uint256 => uint256)) internal _ownedProposals;

    // Mapping from proposal ID to index of the owner proposals list
    mapping(uint256 => uint256) private _ownedProposalsIndex;

    // Array with all proposal ids, used for enumeration
    uint256[] private _allProposals;

    // Mapping from proposal id to position in the allProposals array
    mapping(uint256 => uint256) private _allProposalsIndex;

    uint256 constant LEGAL = 1;
    uint256 constant LIQUIDITY = 2;
    uint256 constant GRANTANDGIFT = 3;
    uint256 constant INVESTMENT = 4;
    uint256 constant FUND = 5;
    uint256 constant OTHER = 6;

    enum ProposalStatus {
        Pending,
        Open,
        Close
    }
    enum VoterState { Absent, Yes, No }

    struct Proposal {
        string id;
        uint256 taxation;             // Legal: 1, Liquidity: 2, GrantAndGift: 3, Investment: 4, Fund: 5, Other: 6
        ProposalStatus status;
        uint256 votes_yes;
        uint256 votes_no;
        uint256 start_at;
        uint256 end_at;
        address proposer;
        uint256 amount;
        address receiver;
        bool executed;        
    }

    // Mapping from proposal id to Proposal struct map
    mapping(uint256 => Proposal) private _proposals;
    mapping(string => uint256) private _proposalIds;
    // Mapping proposal id => user => vote
    mapping(uint256 => mapping(address => VoterState)) public votes;
    // Mapping user => proposal id => voted
    mapping(address => mapping(uint256 => bool)) private _voted;

    address public uapContract = 0x016026DB4e4EA0BCE24c870DFa432DFA53379A07;

    // To create a proposal you need to have 1,000,000 UAP tokens
    uint256 public proposalAllowedAmount = 10**6 * 10**18; 

    // 1 UAP Token equal 1 Vote and allowed to vote from 1 UAP token(1 Vote)
    uint256 public voteAllowedAmount = 10**18;

    uint256 public denominator = 10000;
    mapping (uint256 => uint256) public approvalPercents;

    modifier authOwner(uint256 _proposalId) {
        require(msg.sender == _owners[_proposalId] || msg.sender == owner(), "You are not owner of proposal.");
        _;
    }

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `proposalId` proposal is created to `to`.
     */
    event CreatedProposal(address indexed to, uint256 indexed proposalId, string id);

    /**
     * @dev Emitted when voted `proposalId` proposal.
     */
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votes_yes, uint256 votes_no, bool approved);

    /**
     * @dev Initializes the contract
     */
    constructor() {
        setApprovalAmountPercents(3300, 5100, 6700, 3300, 3300, 5000);
    }

    /**
     * @dev See {IUAPProposal-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IUAPProposal-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Create Proposal `proposalId` to `to`.
     *
     * Requirements:
     *
     * - `proposalId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _createProposal(address to, uint256 proposalId) internal virtual {
        require(to != address(0), "UAPProposal: mint to the zero address");
        require(!_exists(proposalId), "UAPProposal: proposal already exists");

        _beforeCreateProposal(to, proposalId);

        _balances[to] += 1;
        _owners[proposalId] = to;

        emit Transfer(address(0), to, proposalId);
    }

    function createProposal(string memory id, uint256 taxation, uint256 start, uint256 end, uint256 amount, address receiver) external {
        // Check proposer is real address not contract.
        require(tx.origin == msg.sender, "The caller is another contract");
        
        // Check ability to create the proposal
        uint256 uapBalance = IUAP(uapContract).balanceOf(msg.sender);
        require(uapBalance >= proposalAllowedAmount, "You do not have enough UAP token to create proposal");

        // Check end time
        require(end > block.timestamp, "This motion is already ended.");

        // Check Taxation value
        require(taxation > 0, "Taxation should be defined.");
        require(taxation <= 6, "This taxation is not allowed.");

        _gProposalId.increment();

        uint256 newProposalId = _gProposalId.current();

        _proposals[newProposalId] = Proposal({
            status: ProposalStatus.Open,
            id: id,
            taxation: taxation,
            start_at: start,
            end_at: end,
            votes_yes: 0,
            votes_no: 0,
            proposer: msg.sender,
            amount: amount,
            receiver: receiver,
            executed: false
        });

        _createProposal(msg.sender, newProposalId);

        _proposalIds[id] = newProposalId;

        emit CreatedProposal(msg.sender, newProposalId, id);
    }

    function closeProposal(uint256 proposalId) external authOwner(proposalId) {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Open, "Proposal is already closed");
        proposal.status = ProposalStatus.Close;
    }

    function executeProposal(uint256 proposalId) external authOwner(proposalId) {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Open, "Proposal is closed");
        require(!proposal.executed, "Proposal was already executed");

        bool approved = checkApproved(proposalId);
        require(approved, "This proposal is not approved");

        uint256 taxation = proposal.taxation;
        if (taxation == LEGAL) { // Legal
            IUAP(uapContract).releaseLegalToken(proposal.receiver, proposal.amount);
        }
        else if (taxation == LIQUIDITY) { // Liquidity
            IUAP(uapContract).releaseLiquidityToken(proposal.receiver, proposal.amount);
        }
        else if (taxation == GRANTANDGIFT) { // Grant and Gift
            IUAP(uapContract).releaseGrantToken(proposal.receiver, proposal.amount);
        }
        else if (taxation == INVESTMENT) { // Investment
            IUAP(uapContract).releaseInvestmentToken(proposal.receiver, proposal.amount);
        }
        else if (taxation == FUND) { // Fund
            IUAP(uapContract).releaseGeneralFundToken(proposal.receiver, proposal.amount);
        }

        proposal.status = ProposalStatus.Close;
        proposal.executed = true;
    }

    function vote(uint256 proposalId, bool yes) external {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(_exists(proposalId), "Unexistent proposal");
        require(!_voted[msg.sender][proposalId], "You voted already.");

        // Check ability to vote
        uint256 uapBalance = IUAP(uapContract).balanceOf(msg.sender);
        require(uapBalance >= voteAllowedAmount, "You do not have enough UAP token to vote");

        Proposal storage proposal = _proposals[proposalId];
        require(proposal.status == ProposalStatus.Open, "Proposal is closed");
        require(proposal.start_at <= block.timestamp && block.timestamp <= proposal.end_at, "No live proposal");

        if (yes) {
            proposal.votes_yes = proposal.votes_yes + uapBalance;
            votes[proposalId][msg.sender] = VoterState.Yes;
        }
        else {
            proposal.votes_no = proposal.votes_no + uapBalance;
            votes[proposalId][msg.sender] = VoterState.No;
        }

        _proposals[proposalId] = proposal;
        _voted[msg.sender][proposalId] = true;

        bool approved = checkApproved(proposalId);

        emit Voted(msg.sender, proposalId, proposal.votes_yes, proposal.votes_no, approved);
    }

    /**
     * @dev See {IUAPProposal-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "UAPProposal: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IUAPProposal-ownerOf}.
     */
    function ownerOf(uint256 proposalId) public view returns (address) {
        address owner = _owners[proposalId];
        require(owner != address(0), "UAPProposal: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev Returns whether `proposalId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 proposalId) internal view virtual returns (bool) {
        return _owners[proposalId] != address(0);
    }

    /**
     * @dev See {IUAPProposal-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _allProposals.length;
    }

    /**
     * @dev See {IUAPProposal-proposalOfOwnerByIndex}.
     */
    function proposalOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "IUAPProposal: owner index out of bounds");
        return _ownedProposals[owner][index];
    }

    /**
     * @dev See {IUAPProposal-proposalByIndex}.
     */
    function proposalByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "IUAPProposal: global index out of bounds");
        return _allProposals[index];
    }

    function _beforeCreateProposal(
        address to,
        uint256 proposalId
    ) internal {
        _addProposalToAllProposalsEnumeration(proposalId);
        _addProposalToOwnerEnumeration(to, proposalId);
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param proposalId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addProposalToOwnerEnumeration(address to, uint256 proposalId) private {
        uint256 length = balanceOf(to);
        _ownedProposals[to][length] = proposalId;
        _ownedProposalsIndex[proposalId] = length;
    }

    /**
     * @dev Private function to add a proposal to this extension's token tracking data structures.
     * @param proposalId uint256 ID of the token to be added to the tokens list
     */
    function _addProposalToAllProposalsEnumeration(uint256 proposalId) private {
        _allProposalsIndex[proposalId] = _allProposals.length;
        _allProposals.push(proposalId);
    }

    function setUAPContract(address contractAddress) external onlyOwner {
        uapContract = contractAddress;
    }

    function setProposalAllowedAmount(uint256 amoount) external onlyOwner {
        proposalAllowedAmount = amoount;
    }

    function setVoteAllowedAmount(uint256 amoount) external onlyOwner {
        voteAllowedAmount = amoount;
    }

    function setApprovalAmountPercents(uint256 legalPercent, uint256 liquidityPercent, uint256 grantAndGiftPercent, uint256 investmentPercent, uint256 fundPercent, uint256 otherPercent) public onlyOwner {
        approvalPercents[LEGAL] = legalPercent;
        approvalPercents[LIQUIDITY] = liquidityPercent;
        approvalPercents[GRANTANDGIFT] = grantAndGiftPercent;
        approvalPercents[INVESTMENT] = investmentPercent;
        approvalPercents[FUND] = fundPercent;
        approvalPercents[OTHER] = otherPercent;
    }

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(_exists(proposalId), "Unexistent proposal");

        return _proposals[proposalId];
    }

    function getProposalById(string memory id) external view returns (Proposal memory) {
        uint256 proposalId = _proposalIds[id];
        require(_exists(proposalId), "Unexistent proposal");

        return _proposals[proposalId];
    }

    function checkAbilityProposal(address user) external view returns (bool) {
        // Check ability for proposal
        uint256 uapBalance = IUAP(uapContract).balanceOf(user);
        return uapBalance >= proposalAllowedAmount;
    }

    function checkApproved(uint256 proposalId) public view returns (bool) {
        require(_exists(proposalId), "Unexistent proposal");
        
        // Check approval for proposal
        uint256 totalUAPAmount = IUAP(uapContract).totalSupply();
        uint256 approvalAmount = totalUAPAmount.mul(approvalPercents[_proposals[proposalId].taxation]).div(denominator);
        
        return _proposals[proposalId].votes_yes >= approvalAmount;
    }

    function getVoteCount(address user) external view returns (uint256) {
        // Check ability to vote
        uint256 uapBalance = IUAP(uapContract).balanceOf(user);

        if (uapBalance > voteAllowedAmount) {
            return uapBalance;
        }
        else {
            return 0;
        }
    }
}