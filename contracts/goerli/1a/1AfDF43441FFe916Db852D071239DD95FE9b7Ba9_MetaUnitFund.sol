// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MetaUnitFund
 * @notice Manages token distribution to users 
 */
contract MetaUnitFund is ReentrancyGuard {
    enum ProposalType { transfer, destroy }
    struct Proposal { address eth_address; uint256 amount; uint256 start_time; bool resolved; ProposalType proposal_type; }
    struct Voice { address eth_address; bool voice; }

    address private _owner_of;
    address private _meta_unit_address;
    uint256 private _metaunit_supply = 4000000 ether;
    
    Proposal[] private _proposals;
    mapping (uint256 => mapping(address => bool)) private _is_voted;
    mapping (uint256 => Voice[]) private _voices;
    mapping (uint256 => uint256) private _submited;

    /**
     * @dev setup MetaUnit address and owner of this contract
     */
    constructor(address meta_unit_address_, address owner_of_) {
        _meta_unit_address = meta_unit_address_;
        _owner_of = owner_of_;
    }

    /**
     * @dev emits when new propsal creates
     */
    event proposalCreated(uint256 uid, address eth_address, uint256 amount, ProposalType proposal_type);

    /**
     * @dev emits when new voice submites
     */
    event voiceSubmited(address eth_address, bool voice);

    /**
     * @dev emits when proposal resolves
     */
    event proposalResolved(uint256 uid, bool submited);
    event withdrawed(uint256 amount);


    /**
     * @dev allows to create new proposal
     * @param eth_address_ address of user who should receive metaunits via goverance
     * @param amount_ amount of metaunits which should transfers to eth_address_
     */
    function createProposal(address eth_address_, uint256 amount_, ProposalType proposal_type_) public {
        require(_submited[block.timestamp / 30 days] + amount_ <= (_metaunit_supply * 2) / 100, "Contract can't unlock more then 2% of metaunit supply");
        uint256 newProposalUid = _proposals.length;
        _proposals.push(Proposal(eth_address_, amount_, block.timestamp, false, proposal_type_));
        emit proposalCreated(newProposalUid, eth_address_, amount_, proposal_type_);
    }

    /**
     * @dev allows to submit voices
     * @param uid_ unique id of proposal
     * @param voice_ if `true` - means that user vote for, else means that user vote against
     */
    function vote(uint256 uid_, bool voice_) public nonReentrant {
        require(!_is_voted[uid_][msg.sender], "You vote has been submited already");
        Proposal memory proposal = _proposals[uid_];
        require(msg.sender != proposal.eth_address, "You can't vote for our proposal");
        require(block.timestamp < proposal.start_time + 5 days, "Governance finished");
        require(IERC20(_meta_unit_address).balanceOf(msg.sender) > 0, "Not enough metaunits for voting");
        _voices[uid_].push(Voice(msg.sender, voice_));
        emit voiceSubmited(msg.sender, voice_);
        _is_voted[uid_][msg.sender] = true;
    }

    /**
     * @dev calculate voices and transfer metaunits if voices for is greater than voices against
     * @param uid_ unique id of proposal
     */
    function resolve(uint256 uid_) public nonReentrant {
        Proposal memory proposal = _proposals[uid_];
        require(!_proposals[uid_].resolved, "Already resolved");
        require(block.timestamp < proposal.start_time + 5 days, "Governance finished");
        require(proposal.eth_address == msg.sender, "You can't claim reward");
        uint256 voices_for = 0;
        uint256 voices_against = 0;
        for (uint256 i = 0; i < _voices[uid_].length; i++) {
            Voice memory voice = _voices[uid_][i];
            uint256 balance = IERC20(_meta_unit_address).balanceOf(voice.eth_address);
            if (voice.voice) voices_for += balance;
            else voices_against += balance;
        }
        bool submited = voices_for > voices_against;
        if (submited) {
            if (proposal.proposal_type == ProposalType.transfer) {
                IERC20(_meta_unit_address).transfer(msg.sender, proposal.amount);
                _submited[block.timestamp / 30 days] += proposal.amount;
            }
            else if (proposal.proposal_type == ProposalType.destroy) {
                IERC20(_meta_unit_address).transfer(_owner_of, IERC20(_meta_unit_address).balanceOf(address(this)));
                selfdestruct(payable(_owner_of));
            }
        }
        emit proposalResolved(uid_, submited);
        _proposals[uid_].resolved = true;
        
    }

    function claim() public nonReentrant {
        require(msg.sender == _owner_of, "Permission denied");
        uint256 amount = (_metaunit_supply * 2) / 100 - _submited[block.timestamp / 30 days];
        IERC20(_meta_unit_address).transfer(msg.sender, amount);
        emit withdrawed(amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}