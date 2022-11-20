// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract NyxNFT {
    uint256 public currentTokenId;
    address public vault_address;

    function getCurrentSupply() public virtual view returns(uint256);
    function isHolder(address addr, uint256 tokenId) public virtual view returns(bool);
    function balanceOf(address addr, uint256 tokenId) public virtual view returns(uint256);
}


abstract contract ProposalHandlerInterface
{
    function createProposal(uint256 proposalId, bytes[] memory params) public virtual returns (bytes memory);
    function getProposal(bytes memory proposalBytes) public view virtual returns (bytes[] memory);
}


abstract contract NyxProposalHandler
{
    struct ProposalType
    {
        uint256 id;
        string name;
    }

    struct ProposalConf
    {
        uint256 id;
        uint256 proposalTypeInt;
        bool settled;
        address proposer;
        address settledBy;
        bool approved;
    }

    struct ProposalReadable
    {
        bytes[] params;
        ProposalConf conf;
    }

    uint256 public numOfProposalTypes;
    mapping(uint256 => uint256) public numOfProposals;
    mapping(uint256 => ProposalType) public proposalTypeMapping;
    mapping(uint256 => ProposalHandlerInterface) public proposalHandlerAddresses;

    function addProposalType(string memory proposalTypeName, address proposalHandlerAddr) external virtual;
    function setConverterAddress(address addr) external virtual;
    function setProposalInterfaceAddress(uint256 proposalTypeInt, address addr) external virtual;
    function setProposalTypeName(uint256 proposalTypeInt, string memory newProposalTypeName) external virtual;
    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns(ProposalConf memory);
    function setProposalConf(uint256 proposalTypeInt, uint256 proposalId, ProposalConf memory proposalConf) public virtual;
    function createProposal(uint256 proposalTypeInt, bytes[] memory params) public virtual returns(uint256);
    // function getProposals(uint256 proposalTypeInt) public view virtual returns (ProposalReadable[] memory);
    function getProposals(uint256 proposalTypeInt) public view virtual returns (bytes[] memory);
}


contract NyxDAO is Ownable {
    // Uniswap variables
    /////////////////////////////////////////
    //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER =  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WETH =  0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Structs
    ///////////////////

    struct Vote
    {
        uint votedDatetime;
        address voter;
        bool approved;
    }

    struct VoteConf
    {
        uint256 proposalTypeInt;
        uint256 proposalId;
        bool isProposedToVote;
        bool votingPassed;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 livePeriod;
        address[] voters;
    }

    // Attributes
    ///////////////////

    NyxProposalHandler public proposalCreator;

    // bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER");
    uint32 constant public minimumVotingPeriod = 1 weeks;
    
    mapping(uint256 => mapping(uint256 => VoteConf)) public voteConfMapping;

    mapping(address => Vote[]) public stakeholderInvestmentVotes;
    mapping(address => Vote[]) public stakeholderRevenueVotes;
    mapping(address => Vote[]) public stakeholderGovernanceVotes;
    mapping(address => Vote[]) public stakeholderAllocationVotes;
    mapping(address => Vote[]) public stakeholderFreeVotes;
    // mapping(NyxProposalHandler.ProposalType => mapping(address => uint256[])) public stakeholderVotes;
    mapping(uint256 => mapping(address => Vote[])) public stakeholderVotes;
    mapping(uint256 => mapping(uint256 => Vote[])) public proposalVotes;

    address public nft_contract_address;
    address public vault_contract_address;
    address public founder_contract_address;
    NyxNFT public nft_contract;
    mapping(address => address[]) public delegateOperatorToVoters;
    mapping(address => address) public delegateVoterToOperator;

    // remplacer mapping(uint256 => uint8) par un enumerable set ? ?
    mapping(address => mapping(uint256 => uint8)) public representativeRights;

    // Events
    ///////////////////

    event NewProposal(address indexed proposer, uint256 proposalType, uint256 proposalId);
    event ApprovedForVoteProposal(address indexed proposer, uint256 proposalTypeInt, uint256 proposalId);
    event ApprovedProposal(address indexed proposer, uint256 proposalType, uint256 proposalId);
    event SettledProposal(address indexed proposer, uint256 proposalType, uint256 proposalId);

    event ContributionReceived(address indexed fromAddress, uint256 amount);
    event PaymentTransfered(address indexed stakeholder, address indexed tokenAddress, uint256 amount);

    // Modifiers
    ///////////////////

    modifier onlyStakeholder(string memory message)
    {
        // require(hasRole(STAKEHOLDER_ROLE, msg.sender), message);
        require(isStakeholder(msg.sender));
        _;
    }

    modifier onlyAllowedRepresentatives(uint256 proposalTypeInt)
    {
        // require(hasRole(STAKEHOLDER_ROLE, msg.sender), message);
        require(representativeRights[msg.sender][proposalTypeInt] == 1, "not representative for this proposal type");
        _;
    }

    modifier withProposalHandlerSetted()
    {
        require(address(proposalCreator) != address(0), "you have to set proposal handler contract first");
        _;
    }

    modifier withNftSetted()
    {
        require(address(nft_contract) != address(0), "you have to set nft contract address first");
        _;
    }

    // Constructor
    /////////////////

    constructor()
    {        
    }

    // Attributes Getters & Setters
    /////////////////////////////////////

    function setProposalHandlerContract(address addr)
        public
    {
        proposalCreator = NyxProposalHandler(addr);
    }

    // Functions
    ////////////////////

    function createVoteConf(uint256 proposalTypeInt, uint256 proposalId)
        internal
        returns (VoteConf memory)
    {
        address[] memory voters;
        VoteConf memory voteConf = VoteConf(proposalTypeInt, proposalId, false, false, 0, 0, block.timestamp + minimumVotingPeriod, voters);
        voteConfMapping[proposalTypeInt][proposalId] = voteConf;
        return voteConf;        
    }

    function getNftTotalBalance(address addr)
        public view
        withNftSetted
        returns (uint256)
    {
        uint256 currentTokenId = nft_contract.currentTokenId();
        uint256 totalBalance;
        for (uint256 tokenId = 0; tokenId <= currentTokenId; tokenId++)
        {
            totalBalance += nft_contract.balanceOf(addr, tokenId);
        }
        return totalBalance;
    }

    function getVotingPower(address addr)
        public view
        withNftSetted
        returns (uint256)
    {
        uint256 votingPower = 0;
        for (uint tid = 0; tid <= nft_contract.currentTokenId(); tid++)
        {
            votingPower += nft_contract.balanceOf(addr, tid);
        }
        return votingPower;
    }

    function makeVotable(uint256 proposalTypeInt, uint256 proposalId)
        external
        onlyAllowedRepresentatives(proposalTypeInt)
    {
        VoteConf storage voteConf = voteConfMapping[proposalTypeInt][proposalId];
        require(!voteConf.isProposedToVote);
        voteConf.isProposedToVote = true;

        emit ApprovedForVoteProposal(proposalCreator.getProposalConf(proposalTypeInt, proposalId).proposer, proposalTypeInt, proposalId);
    }

    function voteOne(address voter, uint256 proposalTypeInt, uint256 proposalId, VoteConf storage voteConf, bool supportProposal)
        internal
        onlyStakeholder("Only stakeholders are allowed to vote")
        returns (VoteConf storage)
    {
        uint256 votingPower = getVotingPower(voter);
        votable(voter, voteConf);

        Vote memory senderVote = Vote(block.timestamp, voter, supportProposal);
        stakeholderVotes[proposalTypeInt][voter].push(senderVote);
        proposalVotes[proposalTypeInt][proposalId].push(senderVote);

        if (supportProposal)
        {
            voteConf.votesFor = voteConf.votesFor + votingPower;
        }
        else
        {
            voteConf.votesAgainst = voteConf.votesAgainst + votingPower;
        }

        return voteConf;
    }

    function vote(uint256 proposalTypeInt, uint256 proposalId, bool supportProposal)
        external
        onlyStakeholder("Only stakeholders are allowed to vote")
    {
            
        VoteConf storage conf = voteConfMapping[proposalTypeInt][proposalId];
        address[] memory voters = delegateOperatorToVoters[msg.sender];

        for (uint256 iVoter = 0; iVoter < voters.length; iVoter++)
        {
            address voter = voters[iVoter];
            conf = voteOne(voter, proposalTypeInt, proposalId, conf, supportProposal);
        }
        voteOne(msg.sender, proposalTypeInt, proposalId, conf, supportProposal);
    }

    function votable(address votingAddress, VoteConf memory voteConf)
        private view
    {
        if (voteConf.votingPassed || voteConf.livePeriod <= block.timestamp)
        {
            string memory message = "Voting period has passed on this proposal : ";
            message = string(abi.encodePacked(message, Strings.toString(voteConf.livePeriod)));
            message = string(abi.encodePacked(message, " <= "));
            message = string(abi.encodePacked(message, Strings.toString(block.timestamp)));
            revert(message);
        }

        if (!voteConf.isProposedToVote)
        {
            revert("Proposal wasn't approved for vote yet");
        }

        for (uint256 iVote = 0; iVote < voteConf.voters.length; iVote++)
        {
            if (voteConf.voters[iVote] == votingAddress)
            {
                revert("This stakeholder already voted on this proposal");                
            }
        }
    }

    function setNftContract(address addr)
        public onlyOwner
    {
        nft_contract_address = addr;
        nft_contract = NyxNFT(nft_contract_address);
    }

    function getStakeholderVotes(uint256 proposalTypeInt, address addr)
        public
        view
        onlyStakeholder("User is not a stakeholder")
        returns (Vote[] memory)
    {
        return stakeholderVotes[proposalTypeInt][addr];
    }

    function getProposalVotes(uint256 proposalTypeInt, uint256 proposalId)
        external view
        onlyStakeholder("User is not a stakeholder")
        returns (Vote[] memory)
    {
        Vote[] memory _proposalVotes = proposalVotes[proposalTypeInt][proposalId];
        return _proposalVotes;
    }

    function isStakeholder(address addr)
        public view
        withNftSetted
        returns (bool)
    {
        uint256 totalBalance = getNftTotalBalance(addr);      
        return totalBalance > 0;
    }

    // Proposal Handler Wrappers
    ///////////////////////////////////

    function getNumOfProposalTypes()
        external view
        withProposalHandlerSetted
        returns (uint256)
    {
        return proposalCreator.numOfProposalTypes();
    }

    function getNumOfProposals(uint256 proposalTypeInt)
        external view
        withProposalHandlerSetted
        returns (uint256)
    {
        return proposalCreator.numOfProposals(proposalTypeInt);
    }

    function addProposalType(string memory proposalTypeName, address proposalHandlerAddr)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalCreator.addProposalType(proposalTypeName, proposalHandlerAddr);
    }

    function setConverterAddress(address addr)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalCreator.setConverterAddress(addr);
    }

    function setProposalInterfaceAddress(uint256 proposalTypeInt, address addr)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalCreator.setProposalInterfaceAddress(proposalTypeInt, addr);
    }

    function setProposalTypeName(uint256 proposalTypeInt, string memory newProposalTypeName)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalCreator.setProposalTypeName(proposalTypeInt, newProposalTypeName);
    }

    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId)
        external view
        onlyOwner withProposalHandlerSetted
    {
        proposalCreator.getProposalConf(proposalTypeInt, proposalId);
    }

    function setProposalConf(uint256 proposalTypeInt, uint256 proposalId, NyxProposalHandler.ProposalConf memory proposalConf)
        external
        onlyOwner withProposalHandlerSetted
    {
        proposalCreator.setProposalConf(proposalTypeInt, proposalId, proposalConf);
    }

    function createProposal(uint256 proposalTypeInt, bytes[] memory params)
        external
        onlyStakeholder("Only stakeholders are allowed to create proposals") withProposalHandlerSetted
    {
        uint256 proposalId = proposalCreator.createProposal(proposalTypeInt, params);
        createVoteConf(proposalTypeInt, proposalId);
    }

    function getProposals(uint256 proposalTypeInt)
        external view
        withProposalHandlerSetted
        // returns (NyxProposalHandler.ProposalReadable[] memory)
        returns (bytes[] memory)
    {
        return proposalCreator.getProposals(proposalTypeInt);
    }

    function settleProposal(uint256 proposalTypeInt, uint256 proposalId)
        external
        onlyAllowedRepresentatives(proposalId) withProposalHandlerSetted
    {
        NyxProposalHandler.ProposalConf memory proposalConf = proposalCreator.getProposalConf(proposalTypeInt, proposalId);
        VoteConf memory voteConf = voteConfMapping[proposalTypeInt][proposalId];

        if (proposalConf.settled)
        {
            revert("Proposal have already been settled");
        }
        
        proposalConf.approved = voteConf.votesFor > voteConf.votesAgainst;
        proposalConf.settled = true;
        proposalConf.settledBy = msg.sender;

        proposalCreator.setProposalConf(proposalTypeInt, proposalId, proposalConf);

        emit SettledProposal(proposalConf.proposer, proposalTypeInt, proposalId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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