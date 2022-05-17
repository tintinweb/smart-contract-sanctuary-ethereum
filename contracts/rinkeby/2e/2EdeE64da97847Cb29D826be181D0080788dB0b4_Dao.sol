//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dao {
    address private chairman;
    address private voteToken;
    uint256 private mininumQuorum;
    uint256 private debatePeriodDuration;

    uint256 private numVotes;

    struct Referendum {
        bytes callData;
        address recipient;
        string description;
        uint256 endDate;
        uint256 acceptCount;
        uint256 rejectCount;
        bool ended;
    }

    struct Deposit {
        uint256 totalDeposit;
        uint256 holdDuration;
    }

    mapping(uint256 => Referendum) private referendums;
    mapping(address => Deposit) private deposits;
    mapping(uint256 => mapping(address => uint256)) private votes;

    event ReferendumCreated(uint256 indexed id, string description);
    event VoteMade(
        uint256 indexed id,
        address voter,
        uint256 amount,
        bool accept
    );
    event ReferendumEnded(uint256 indexed id, bool decision, bool successCall);

    constructor(
        address _chairman,
        address _voteToken,
        uint256 _minimumQuorum,
        uint256 _debatePeriodDuration
    ) {
        chairman = _chairman;
        voteToken = _voteToken;
        mininumQuorum = _minimumQuorum;
        debatePeriodDuration = _debatePeriodDuration;
    }

    function deposit(uint256 _amount) external {
        IERC20(voteToken).transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender].totalDeposit += _amount;
    }

    function withdraw(uint256 _amount) external {
        require(
            deposits[msg.sender].holdDuration < block.timestamp,
            "You funds are locked, try later."
        );
        require(
            deposits[msg.sender].totalDeposit >= _amount,
            "You deposit is less."
        );

        deposits[msg.sender].totalDeposit -= _amount;
        IERC20(voteToken).transfer(msg.sender, _amount);
    }

    function addProposal(
        bytes memory _callData,
        address _recipient,
        string memory _description
    ) external {
        require(msg.sender == chairman, "You are not chairman.");

        Referendum storage v = referendums[numVotes];
        v.callData = _callData;
        v.recipient = _recipient;
        v.description = _description;
        v.endDate = block.timestamp + debatePeriodDuration;

        emit ReferendumCreated(numVotes, _description);

        numVotes++;
    }

    function vote(uint256 _id, bool _accept) external {
        require(_id <= numVotes, "Wrong _id was provided.");
        Deposit memory d = deposits[msg.sender];

        require(d.totalDeposit >= 1, "Please transfer some funds first.");

        Referendum storage v = referendums[_id];
        require(!v.ended, "Referendum already ended.");

        uint256 add;
        if (votes[_id][msg.sender] == 0) {
            add = d.totalDeposit;
        } else {
            require(
                d.totalDeposit > votes[_id][msg.sender],
                "You already used all balance."
            );
            add = d.totalDeposit - votes[_id][msg.sender];
        }

        d.holdDuration = d.holdDuration > v.endDate
            ? d.holdDuration
            : v.endDate;

        votes[_id][msg.sender] += add;

        if (_accept) {
            v.acceptCount += add;
        } else {
            v.rejectCount += add;
        }

        emit VoteMade(_id, msg.sender, add, _accept);
    }

    function endVote(uint256 _id) external {
        require(_id <= numVotes, "Wrong id was provided.");
        Referendum storage v = referendums[_id];
        require(
            block.timestamp >= v.endDate,
            "Referendum can not end right now."
        );

        require(
            v.acceptCount + v.rejectCount >= mininumQuorum,
            "Minimum quorum requirement not met."
        );

        require(v.acceptCount != v.rejectCount, "Parity of votes.");

        bool decision = v.acceptCount > v.rejectCount;
        bool successCall = false;
        if (decision) {
            (successCall, ) = v.recipient.call(v.callData);
        }

        emit ReferendumEnded(_id, decision, successCall);
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