/**
 *Submitted for verification at Etherscan.io on 2022-03-24
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

interface IPongoProposal {
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

contract PongoProposal is Ownable, IPongoProposal {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _gProposalId;

    // Name
    string private _name = "PONGO PROPOSAL";
    // Symbol
    string private _symbol = "PONGOPT4";

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

    struct Proposal {
        string id;
        uint256 votes_yes;
        uint256 votes_no;
        uint256 start_at;
        uint256 end_at;
        address proposer;
    }

    // Mapping from proposal id to Proposal struct map
    mapping(uint256 => Proposal) private _proposals;
    mapping(string => uint256) private _proposalIds;
    mapping(address => bool) private _voted;

    address public pongoContract = 0xB9d8620Fd438A842fF0CF53C416a055F36F53Ad5;

    // To create a proposal you need to have  0.15% tokens of Pongo total supply (150.000.000.000)
    uint256 public proposalPrice = 15 * 10**10 * 10**9; 

    // 10.000.000.000 Tokens equal 1 Vote
    uint256 public votePrice = 10**10 * 10**9;

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
    event Voted(uint256 indexed proposalId, uint256 votes_yes, uint256 votes_no);

    /**
     * @dev Initializes the contract
     */
    constructor() {
    }

    /**
     * @dev See {IPongoProposal-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IPongoProposal-ownerOf}.
     */
    function ownerOf(uint256 proposalId) public view returns (address) {
        address owner = _owners[proposalId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IPongoProposal-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IPongoProposal-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
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
     * @dev See {IPongoProposal-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _allProposals.length;
    }

    /**
     * @dev See {IPongoProposal-proposalOfOwnerByIndex}.
     */
    function proposalOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "IPongoProposal: owner index out of bounds");
        return _ownedProposals[owner][index];
    }

    /**
     * @dev See {IPongoProposal-proposalByIndex}.
     */
    function proposalByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "IPongoProposal: global index out of bounds");
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

    function setPongoContract(address contractAddress) external onlyOwner {
        pongoContract = contractAddress;
    }

    function setProposalPrice(uint256 price) external onlyOwner {
        proposalPrice = price;
    }

    function setVotePrice(uint256 price) external onlyOwner {
        votePrice = price;
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
        uint256 pongoBalance = IERC20(pongoContract).balanceOf(user);
        return pongoBalance >= proposalPrice;
    }

    function getVoteCount(address user) external view returns (uint256) {
        // Check ability to vote
        uint256 pongoBalance = IERC20(pongoContract).balanceOf(user);
        // Check the count for user to vote
        uint256 voteCount = pongoBalance.div(votePrice);

        return voteCount;
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
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(proposalId), "ERC721: token already minted");

        _beforeCreateProposal(to, proposalId);

        _balances[to] += 1;
        _owners[proposalId] = to;

        emit Transfer(address(0), to, proposalId);
    }

    function createProposal(string memory id, uint256 start, uint256 end) external {
        // Check proposer is real address not contract.
        require(tx.origin == msg.sender, "The caller is another contract");
        
        // Check ability to create the proposal
        uint256 pongoBalance = IERC20(pongoContract).balanceOf(msg.sender);
        require(pongoBalance >= proposalPrice, "You do not have enough PONGO token to create proposal");

        _gProposalId.increment();

        uint256 newProposalId = _gProposalId.current();

        _proposals[newProposalId] = Proposal({
            id: id,
            start_at: start,
            end_at: end,
            votes_yes: 0,
            votes_no: 0,
            proposer: msg.sender
        });

        _createProposal(msg.sender, newProposalId);

        _proposalIds[id] = newProposalId;

        emit CreatedProposal(msg.sender, newProposalId, id);
    }

    function vote(uint256 proposalId, bool yes) external {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(_exists(proposalId), "Unexistent proposal");
        require(!_voted[msg.sender], "You voted already.");

        // Check ability to vote
        uint256 pongoBalance = IERC20(pongoContract).balanceOf(msg.sender);
        require(pongoBalance >= votePrice, "You do not have enough PONGO token to vote");

        // Check the count for user to vote
        uint256 voteCount = pongoBalance.div(votePrice);        

        Proposal storage proposal = _proposals[proposalId];
        require(proposal.start_at <= block.timestamp && block.timestamp <= proposal.end_at, "No live proposal");

        if (yes) {
            proposal.votes_yes = proposal.votes_yes + voteCount;
        }
        else {
            proposal.votes_no = proposal.votes_no + voteCount;
        }

        _proposals[proposalId] = proposal;
        _voted[msg.sender] = true;

        emit Voted(proposalId, proposal.votes_yes, proposal.votes_no);
    }
}