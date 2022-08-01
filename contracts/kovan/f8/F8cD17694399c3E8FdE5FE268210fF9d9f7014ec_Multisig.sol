//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error Multisig__VotingNotEnded();
error Multisig__ProposalExpired();
error Multisig__UserIsNotSigner();
error Multisig__OnlyContract();
error Multisig__AlreadyVoted();
error Multisig__AlreadyExecuted();
error Multisig__UserAlreadySigner();
error Multisig__ProposalDidNotPass();
error Multisig__CannotSetVotesToZero();
error Multisig__ProposalExecutionFailed();
error Multisig__NumVotesLessThanMembers();

contract Multisig {
    event TimeoutChanged(uint256 newTimeout);
    event SignerAdded(address indexed newSigner);
    event ProposalExecuted(uint256 indexed index);
    event SignerRemoved(address indexed removedSigner);
    event SignerVoted(address indexed signer, uint256 indexed index);
    event ProposalAdded(address indexed from, string title, uint256 expiration);
    event MinimumVotesChanged(uint256 indexed amount);

    struct Proposal {
        address from;
        address target;
        address[] voteYes;
        uint256 value;
        uint256 expiration;
        string func;
        string description;
        bytes data;
        bytes result;
        bool passed;
        bool executed;
    }

    uint256 public s_minVotes;
    address[] public s_signers;
    Proposal[] public s_proposals;
    uint256 public s_expirationTimeout;
    mapping(address => bool) public s_isSigner;
    mapping(uint256 => mapping(address => bool)) public s_hasVoted;

    constructor(
        address[] memory _signers,
        uint256 _timeout,
        uint256 _minVotes
    ) {
        if(_signers.length < _minVotes) { revert Multisig__NumVotesLessThanMembers(); }

        s_expirationTimeout = _timeout;
        s_signers = _signers;
        s_minVotes = _minVotes;

        for (uint256 i = 0; i < _signers.length; i++) {
            s_isSigner[_signers[i]] = true;
        }
    }

    modifier OnlySigners() {
        if (!s_isSigner[msg.sender]) {
            revert Multisig__UserIsNotSigner();
        }
        _;
    }

    modifier OnlyContract() {
        if (msg.sender != address(this)) {
            revert Multisig__OnlyContract();
        }
        _;
    }

    // ---------
    // Getters
    // ----------
    function getSigners() public view returns (address[] memory){
        return s_signers;
    }

    function getProposals() public view returns (Proposal[] memory){
        return s_proposals;
    }
    // ---------------------------------------------------------------
    // Main Multisig Operations
    // ---------------------------------------------------------------
    function changeTimeout(uint256 _newTimeout) public OnlyContract {
        s_expirationTimeout = _newTimeout;
        emit TimeoutChanged(_newTimeout);
    }

    function addSigner(address _signer) public OnlyContract {
        if (s_isSigner[_signer]) {
            revert Multisig__UserAlreadySigner();
        }

        s_isSigner[_signer] = true;
        s_signers.push(_signer);
        emit SignerAdded(_signer);
    }

    function removeSigner(address _signer) public OnlyContract {
        if (!s_isSigner[_signer]) {
            revert Multisig__UserIsNotSigner();
        }

        uint256 removeIndex = findIndexOfSigner(_signer);
        _removeFromSignersArray(removeIndex);
        s_isSigner[_signer] = false;

        // Ensure removing a signer doesnt brick contract
        if(s_signers.length < s_minVotes) { s_minVotes -= 1; }

        emit SignerRemoved(_signer);
    }

    function setMinVotes(uint256 _minVotes) public OnlyContract {
        if (_minVotes == 0) { revert Multisig__CannotSetVotesToZero(); }
        if (_minVotes > s_signers.length) { revert Multisig__NumVotesLessThanMembers(); }
        
        s_minVotes = _minVotes;
        emit MinimumVotesChanged(_minVotes);
    }

    /**
     * @notice A fair bit of this is stolen shamelessly from https://solidity-by-example.org/app/time-lock/
     * @notice I didn't cheat by looking at the multi-sig example ;)
     *
     * @dev this function submits proposals to the multisig queue
     *
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _function Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send.
     */
    function submitProposal(
        address _target,
        uint256 _value,
        string memory _function,
        bytes memory _data,
        string memory _description
    ) external OnlySigners {
        uint256 _expirationTime = block.timestamp + s_expirationTimeout;

        Proposal memory _newProposal = Proposal({
            from: msg.sender,
            target: _target,
            value: _value,
            func: _function,
            data: _data,
            description: _description,
            voteYes: new address[](0),
            expiration: block.timestamp + s_expirationTimeout,
            passed: false,
            executed: false,
            result: ""
        });
        s_proposals.push(_newProposal);
        emit ProposalAdded(msg.sender, _description, _expirationTime);
    }

    function voteOnProposal(uint256 _index) external OnlySigners {
        Proposal storage _proposal = s_proposals[_index];

        if (block.timestamp > _proposal.expiration) {
            revert Multisig__ProposalExpired();
        }

        if (s_hasVoted[_index][msg.sender]) {
            revert Multisig__AlreadyVoted();
        }

        s_hasVoted[_index][msg.sender] = true;
        _proposal.voteYes.push(msg.sender);

        if(_proposal.voteYes.length >= s_minVotes) {
            _proposal.passed = true;
        }

        emit SignerVoted(msg.sender, _index);
    }

    function executeProposal(uint256 _index) external OnlySigners {
        Proposal memory _proposal = s_proposals[_index];

        if (_proposal.voteYes.length < s_minVotes) {
            revert Multisig__ProposalDidNotPass();
        }

        if (_proposal.executed == true) {
            revert Multisig__AlreadyExecuted();
        }

        bytes memory _result = _executeProposal(_proposal);

        s_proposals[_index].executed = true;
        s_proposals[_index].result = _result;
        emit ProposalExecuted(_index);
    }

    /**
     * @dev Splitting this out was done for testing purposes
     */
    function _executeProposal(Proposal memory _proposal)
        public
        OnlySigners
        returns (bytes memory)
    {
        (bool success, bytes memory result) = _proposal.target.call{
            value: _proposal.value
        }(_proposal.data);

        if (!success) {
            revert Multisig__ProposalExecutionFailed();
        }

        return result;
    }

    // ---------------------------------------------------------------
    // to support receiving ETH by default
    // ---------------------------------------------------------------
    receive() external payable {}

    fallback() external payable {}

    // ---------------------------------------------------------------
    // Array operations Helper methods
    // ---------------------------------------------------------------
    function findIndexOfSigner(address _signer)
        public
        view
        returns (uint256 index)
    {
        if (!s_isSigner[_signer]) {
            revert Multisig__UserIsNotSigner();
        }
        for (uint256 i = 0; i < s_signers.length; i++) {
            if (s_signers[i] == _signer) {
                index = i;
                break;
            }
        }
    }

    // Shamelessly stolen from: https://solidity-by-example.org/array/
    // Last element copied over the element we want to delete, then we pop the last element
    function _removeFromSignersArray(uint _index) public OnlyContract {
        s_signers[_index] = s_signers[s_signers.length - 1];
        s_signers.pop();
    }
}