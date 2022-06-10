//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MADAO {
    enum Status {
        InProcess,
        Finished,
        Rejected,
        Cancelled
    }

    struct Proposal {
        uint8 status;
        uint64 startDate; //it's ok until (Jul 21 2554)
        address recipient;
        uint128 votesFor;
        uint128 votesAgainst;
        bytes funcSignature;
        string description;
    }

    uint64 private _minimumQuorum;
    uint24 private _votingPeriodDuration; //~6 months max
    address private _voteToken;
    address private _chairperson;
    uint32 private _proposalCounter = 1; //0 is reserved for _lastVoting logic
    mapping(uint256 => Proposal) private _proposals;
    mapping(address => uint256) private _deposit;
    mapping(address => mapping(uint256 => bool)) private _voted;
    mapping(address => uint256) private _lastVoting;
    mapping(address => mapping(uint256 => uint256)) private _allowance;

    constructor(
        address chairperson,
        address voteToken,
        uint64 minimumQuorum,
        uint24 debatingPeriodDuration
    ) {
        _chairperson = chairperson;

        _voteToken = voteToken;
        _minimumQuorum = minimumQuorum;
        _votingPeriodDuration = debatingPeriodDuration;
    }

    modifier proposalExists(uint256 pId) {
        require(pId > 0 && pId < _proposalCounter, "MADAO: no such voting");
        _;
    }

    modifier voteGuard(address voter, uint256 pId) {
        require(!_voted[msg.sender][pId], "MADAO: voted already");
        _voted[msg.sender][pId] = true;
        _;
    }

    function getProposal(uint256 id) external view returns (Proposal memory) {
        return _proposals[id];
    }

    function getDeposit() external view returns (uint256) {
        return _deposit[msg.sender];
    }

    function getVoteToken() external view returns (address) {
        return _voteToken;
    }

    function deposit(uint256 amount) external {
        _deposit[msg.sender] += amount;

        IERC20(_voteToken).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw() external {
        uint256 amount = _deposit[msg.sender];
        require(amount > 0, "MADAO: nothing to withdraw");

        uint256 lvId = _lastVoting[msg.sender];
        if (lvId > 0) {
            // check if user voted
            require(
                _proposals[lvId].status != uint8(Status.InProcess),
                "MADAO: tokens are frozen"
            );
        }

        _deposit[msg.sender] = 0;

        IERC20(_voteToken).transfer(msg.sender, amount);
    }

    function addProposal(
        address recipient,
        bytes memory funcSignature,
        string memory description
    ) external {
        require(msg.sender == _chairperson, "MADAO: no access");
        Proposal storage p = _proposals[_proposalCounter++];
        p.funcSignature = funcSignature;
        p.description = description;
        p.recipient = recipient;
        p.startDate = uint64(block.timestamp);
    }

    function vote(uint32 pId, bool agree)
        external
        proposalExists(pId)
        voteGuard(msg.sender, pId)
    {
        uint128 availableAmount = uint128(_checkAmount(msg.sender, pId));

        Proposal storage p = _proposals[pId];
        require( //now < finishDate
            block.timestamp < p.startDate + _votingPeriodDuration,
            "MADAO: voting period ended"
        );

        // because of the common voting period for all proposals,
        // it's enough to keep the last voting.
        // all votings before will finish before the last one.
        uint256 lastVotingId = _lastVoting[msg.sender];
        if (pId > lastVotingId) _lastVoting[msg.sender] = pId; //this is needed for withdraw

        if (agree) p.votesFor += availableAmount;
        else p.votesAgainst += availableAmount;
    }

    function finish(uint256 pId) external proposalExists(pId) {
        Proposal storage p = _proposals[pId];
        require( //now > finishDate
            block.timestamp > p.startDate + _votingPeriodDuration,
            "MADAO: voting is in process"
        );
        require(p.status == uint8(Status.InProcess), "MADAO: handled already");
        Status resultStatus;
        if (p.votesFor + p.votesAgainst < _minimumQuorum) {
            resultStatus = Status.Cancelled;
        } else {
            resultStatus = p.votesFor > p.votesAgainst
                ? Status.Finished
                : Status.Rejected;
        }
        p.status = uint8(resultStatus);
        if (resultStatus != Status.Finished) return;

        (bool success, ) = p.recipient.call(p.funcSignature);
        require(success, "MADAO: recipient call error");
    }

    function delegate(address aDelegate, uint256 pId)
        external
        proposalExists(pId)
        voteGuard(msg.sender, pId)
    {
        require(!_voted[aDelegate][pId], "MADAO: delegate voted already");
        _allowance[aDelegate][pId] += _checkAmount(msg.sender, pId);
    }

    function _checkAmount(address voter, uint256 pId)
        private
        view
        returns (uint256)
    {
        uint256 availableAmount = _deposit[voter] + _allowance[voter][pId];
        require(availableAmount > 0, "MADAO: no deposit");
        return availableAmount;
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