// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DAO is Ownable {
    address public chairPerson;
    address public voteToken;
    uint256 public minimumQuorum;
    uint256 public debatingPeriodDuration;
    mapping(address => uint256) public memberBalances;
    mapping(address => uint256[]) public memberCurrentParticipation;

    struct Proposal {
        uint256 startedAt;
        uint256 votedForTotal;
        uint256 votedAgainstTotal;
        string description;
        bytes callBytecode;
        address recipient;
        bool isFinished;
    }

    Proposal[] public proposals;

    modifier onlyChair() {
        require(msg.sender == chairPerson, "Only chair can make proposals");
        _;
    }

    constructor(address _chairPerson, address _voteToken, uint256 _minimumQuorum, uint256 _debatingPeriodDuration) {
        chairPerson = _chairPerson;
        voteToken = _voteToken;
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    function deposit(uint256 amount) external {
        (bool success, bytes memory data) = voteToken.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
        if(success) { memberBalances[msg.sender] += amount; } else { revert("Deposit unsuccessful"); }
    }

    function withdraw(uint256 amount) external {
        require(memberBalances[msg.sender] >= amount, "Amount exceeds balance");

        bool isWithdrawalAllowed = true;
        uint256[] storage proposalIds = memberCurrentParticipation[msg.sender];

        for (uint256 i = 0; i < proposalIds.length; i++) {
            if(proposals[proposalIds[i]].isFinished) { delete proposalIds[i]; } else { isWithdrawalAllowed = false; }
        }

        require(isWithdrawalAllowed, "Can't withdraw while participating in ongoing proposals");

        (bool success, ) = voteToken.call{value:0}(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        if(success) { memberBalances[msg.sender] -= amount; } else { revert("Withdrawal unsuccessful"); }
    }

    function addProposal(bytes calldata callData, address recipient, string calldata description) external onlyChair {
        Proposal memory proposal = Proposal({
            startedAt: block.timestamp,
            votedForTotal: 0,
            votedAgainstTotal: 0,
            description: description,
            callBytecode: callData,
            recipient: recipient,
            isFinished: false
        });

        proposals.push(proposal);
    }

    function vote(uint256 id, bool supportAgainst) external {
        require(!proposals[id].isFinished || block.timestamp <= proposals[id].startedAt + debatingPeriodDuration, "Voting is no longer possible");
        require(memberBalances[msg.sender] > 0, "Must own at least 1 token to vote");

        for (uint256 i = 0; i < memberCurrentParticipation[msg.sender].length; i++) {
            if(memberCurrentParticipation[msg.sender][i] == id){ revert("Already voted"); }
        }

        supportAgainst 
            ? proposals[id].votedForTotal += memberBalances[msg.sender] 
            : proposals[id].votedAgainstTotal += memberBalances[msg.sender]
        ;

        memberCurrentParticipation[msg.sender].push(id);
    }

    function finishProposal(uint256 id) external {
        require(block.timestamp >= proposals[id].startedAt + debatingPeriodDuration, "Too early to finish");
        require(proposals[id].votedForTotal + proposals[id].votedAgainstTotal >= minimumQuorum, "Not enough tokens voted");

        uint256 votedForTotalPercentage = (proposals[id].votedForTotal * 100) / (proposals[id].votedAgainstTotal + proposals[id].votedForTotal);

        if(votedForTotalPercentage >= 51) { proposals[id].recipient.call(proposals[id].callBytecode); }
        proposals[id].isFinished = true;
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(owner()));
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