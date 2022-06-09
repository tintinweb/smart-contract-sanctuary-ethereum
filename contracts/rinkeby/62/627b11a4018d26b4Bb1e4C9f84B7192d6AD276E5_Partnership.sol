// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Partnership is  Pausable, Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;

    event PayeeAdded(address account, uint256 shares);
    event PayeeRemoved(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event ShareChanged(address partner, uint shares);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 private _totalPartners;
    uint256 private _totalVoters;

    mapping(address => uint256) private _released;
    
    bool public closePartnership;
    bool public consensus;

    struct Partner {
        uint weight;
        bool voted;
        uint shares;
        bool isPartner;
    }

    struct ManagementProposal {
        string title;
        string proposal;
        uint voteCount;
        address createdBy;
        address addressedTo;
        address[] voters;
        bool shareChange;
        bool voting;
    }

    struct Proposal {
        string title;
        string proposal;
        uint voteCount;
        address createdBy;
        address[] voters;
    }

    mapping(address => Partner) public partners;
    mapping(uint => ManagementProposal) public mProposals;
    mapping(uint256 => Proposal) public proposals;

    constructor(address[] memory _partners, uint256[] memory _shares) public payable {
        require(_partners.length > 0, "PaymentSplitter: no payees");

        for(uint256 i = 0; i < _partners.length; i++) {
            partners[_partners[i]].isPartner = true;
            partners[_partners[i]].shares = _shares[i]; 
            partners[_partners[i]].weight = 1;
        }
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function shares(address account) public view returns (uint256) {
        return partners[account].shares;
    }

    function released(address account) public view returns(uint256) {
        return _released[account];
    }

    function release(address payable account) public virtual nonReentrant whenNotPaused {
        require(partners[account].shares > 0, 'PaymentSplitter: account has no shares');

        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(partners[account].shares).div(_totalShares).sub(_released[account]);

        require(payment != 0, 'PaymentSplitter: account is not due payment');

        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);

        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }

    function _removePayee(address account, uint256 shares_) internal onlyOwner whenNotPaused {
        require(account != address(0), 'PaymentSplitter: account is the zero address');
        require(shares_ < 0, 'PaymentSplitter: account already has shares');

        partners[account].shares = 0;
        _totalShares = _totalShares.sub(shares_);
        emit PayeeRemoved(account, partners[account].shares);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier onlyPartners(address partner) {
        require(partners[partner].weight == 1, 'You are not a partner!');
        _;
    }

    function makeProposal(string memory _title, string memory _proposal, uint256 _proposalNumber) public onlyPartners(msg.sender) { 
        proposals[_proposalNumber].title = _title;
        proposals[_proposalNumber].proposal = _proposal;
        proposals[_proposalNumber].voteCount = 0;
        proposals[_proposalNumber].createdBy = msg.sender;                                                   
    }

    function propForRightToVote(address partner, uint256 _proposalNumber, string memory _title, string memory _proposal) external onlyPartners(msg.sender) whenNotPaused{
        mProposals[_proposalNumber].title = _title;
        mProposals[_proposalNumber].proposal = _proposal;
        mProposals[_proposalNumber].voteCount = 0;
        mProposals[_proposalNumber].createdBy = msg.sender;
        mProposals[_proposalNumber].addressedTo = partner;
        mProposals[_proposalNumber].shareChange = false;
        mProposals[_proposalNumber].voting = true;
    }

    function propRightToVoteConsensus(uint _proposalNumber) public onlyOwner {
        require(mProposals[_proposalNumber].voting == true, 'Proposal not for right to vote');
        require(mProposals[_proposalNumber].voteCount > _totalVoters.div(2), 'No majority votes');

       giveRightToVote(mProposals[_proposalNumber].addressedTo);
    }

    function giveRightToVote(address partner) internal onlyOwner {
        require(!partners[partner].voted, 'You have already voted.');
        require(partners[partner].weight == 0, 'You are already allowed to vote');

        partners[partner].weight = 1;
        _totalVoters.add(1);
    }

    function propForRemoveVoting(address partner, uint256 _proposalNumber, string memory _title, string memory _proposal) external onlyPartners(msg.sender) whenNotPaused {
        mProposals[_proposalNumber].title = _title;
        mProposals[_proposalNumber].proposal = _proposal;
        mProposals[_proposalNumber].voteCount = 0;
        mProposals[_proposalNumber].createdBy = msg.sender;
        mProposals[_proposalNumber].addressedTo = partner;
        mProposals[_proposalNumber].shareChange = false;
        mProposals[_proposalNumber].voting = true;
    }

    function removeVoteConsensus(uint _proposalNumber) external onlyOwner whenNotPaused {
        require(mProposals[_proposalNumber].voting == true, 'Proposal not for voting');
        require(mProposals[_proposalNumber].voteCount > mProposals[_proposalNumber].voters.length / 2, 'No majority votes received');
       renounceRightToVote(mProposals[_proposalNumber].addressedTo);
    }

    function renounceRightToVote(address partner) internal onlyOwner {
        require(partners[partner].voted, 'You have not voted.');
        require(partners[partner].weight == 1, 'You are not allowed to vote');

        partners[partner].weight = 0;
        _totalVoters.sub(1);
    }

    function voteForApproval(string memory _title, address partner, string memory _proposal, uint256 _proposalNumber) external onlyOwner {
        mProposals[_proposalNumber].title = _title;
        mProposals[_proposalNumber].proposal  = _proposal;
        mProposals[_proposalNumber].voteCount = 0;
        mProposals[_proposalNumber].createdBy = msg.sender;
        mProposals[_proposalNumber].addressedTo = partner;
    }

    function approveOnConsensus(uint256 _proposalNumber, uint share) public onlyOwner {
        require(mProposals[_proposalNumber].voteCount > mProposals[_proposalNumber].voters.length / 2, 'No majority votes received');
        addPartner(mProposals[_proposalNumber].addressedTo, share);
    }

    function addPartner(address partner, uint shares_) internal onlyOwner {
         require(partner != address(0), 'PaymentSplitter: account is the zero address');
        require(shares_ > 0, 'PaymentSplitter: account already has shares');

        partners[partner].shares = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(partner, shares_);
        partners[partner].isPartner = true;
    }

    function propForRemoval(string memory _title, address _partner, string memory _proposal, uint256  _proposalNumber) external onlyPartners(msg.sender){
        ManagementProposal memory mprop = mProposals[_proposalNumber];
        require(partners[_partner].isPartner == true, 'Recipient is not a partner');
        require(partners[msg.sender].weight > 0, 'You do not have voting rights');
         
         mprop.title = _title;
         mprop.proposal  = _proposal;
         mprop.voteCount = 0;
         mprop.createdBy = msg.sender;
         mprop.addressedTo = _partner;
    }

    function removeOnConsensus(uint256 _proposalNumber) public onlyOwner {
        require(mProposals[_proposalNumber].voteCount > mProposals[_proposalNumber].voters.length / 2, 'No majority votes received');
             removePartner(mProposals[_proposalNumber].addressedTo);
    }

    function removePartner(address partner) internal onlyOwner {
        delete partners[partner];
    }

    function propToChangeShare(address _partner, uint256 _proposalNumber, string memory _title, string memory _proposal) external onlyPartners(msg.sender) {
        ManagementProposal memory mprop = mProposals[_proposalNumber];
        mprop.title = _title;
        mprop.proposal  = _proposal;
        mprop.voteCount = 0;
        mprop.createdBy = msg.sender;
        mprop.addressedTo = _partner;
    }

    function changeShareOnConsensus(uint256 _proposalNumber, uint shares_) public onlyOwner {
        ManagementProposal memory mprop = mProposals[_proposalNumber];
        require(mprop.voteCount > mprop.voters.length / 2, 'No majority votes received');

        changeShare(mprop.addressedTo, shares_);
        
    }

    function changeShare(address _partner, uint shares_) internal onlyOwner {
        Partner storage ptnr = partners[_partner];
        ptnr.shares =  shares_;
        emit ShareChanged(_partner, ptnr.shares);
    }


    function vote(uint256 proposal) external onlyPartners(msg.sender) whenNotPaused nonReentrant {
        Partner storage partner = partners[msg.sender];
        
        Proposal memory prop = proposals[proposal];
        require(partner.weight != 0, 'You have no right to vote');
        require(prop.voters.length <= _totalVoters, 'Total votes are received');
        
        prop.voteCount += partner.weight;
    }

    function managementVote(uint256 proposal) external onlyPartners(msg.sender) whenNotPaused nonReentrant {
        Partner storage partner = partners[msg.sender];
        ManagementProposal memory mprop = mProposals[proposal];
        require(partner.weight != 0, 'You have no right to vote');
        require(mprop.voters.length <= _totalVoters, 'Total votes are received');

        mprop.voteCount += partner.weight;
    }

    function readProposal(uint _proposalNumber) public onlyPartners(msg.sender) view returns (string memory _title, string memory _proposal, uint _voteCount, address _createdBy) {
        return (proposals[_proposalNumber].title,
        proposals[_proposalNumber].proposal,
        proposals[_proposalNumber].voteCount,
        proposals[_proposalNumber].createdBy);
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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