//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/*
 * This smart contract implements voting for tokenholders of ERC20 tokens based on the principle
 * "one token - one vote"
 * It requires external script to count votes.
 *
 * Rules:
 * Voting can be started for any contract with ERC20 tokens, to start a voting an address have to own at lest one token.
 * To start a voting, voting creator must provide:
 * 1) address of a contract with tokens (ERC20),
 * 2) text of the proposal,
 * 3) number of block on witch voting will be finished and results have to be calculated.
 *
 * Every proposal for a contract receives a sequence number that serves as a proposal ID for this contract.
 * Each smart contract with tokens has its own numbering.
 * So proposal can be identified by contract address with tokens + number (ID) of the proposal.
 *
 * To vote 'for' or 'against' voter has to provide an address of a contract with tokens + proposal ID.
 *
 * In most scenarios only votes 'for' can be used, who did not voted 'for' can be considered as voted 'against'.
 * But our dApp also supports votes 'against'
 *
 * To calculate results we collect all voted addresses by an external script, which is also open sourced.
 * Than we check their balances in tokens on resulting block, and and sum up the voices.
 * Thus, for the results, the number of tokens of the voter at the moment of voting does not matter
 * (it should just has at least one).
 * What matters is the number of tokens on the voter's address on the block where the results should calculated.
 *
 */

abstract contract ERC20TokensContract {
    /*
     * These are functions that smart contract needs to have to work with our dApp
     */

    function balanceOf(address _owner)
        external
        view
        virtual
        returns (uint256 balance);

    function totalSupply() external view virtual returns (uint256);

    string public name;

    string public symbol;
}

contract VotingForERC20 {
    mapping(address => uint256) public votingCounterForContract;
    mapping(address => mapping(uint256 => string)) public proposalText;
    mapping(address => mapping(uint256 => uint256)) public numberOfVotersFor;
    mapping(address => mapping(uint256 => uint256))
        public numberOfVotersAgainst;
    mapping(address => mapping(uint256 => mapping(uint256 => address)))
        public votedFor;
    mapping(address => mapping(uint256 => mapping(uint256 => address)))
        public votedAgainst;
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public boolVotedFor;
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public boolVotedAgainst;
    mapping(address => mapping(uint256 => uint256)) public startTimestamp;
    mapping(address => mapping(uint256 => uint256)) public endTimestamp;

    event Proposal(
        address indexed forContract,
        uint256 indexed proposalId,
        address indexed by,
        string proposalText,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    function create(
        address _erc20ContractAddress,
        string calldata _proposalText,
        uint256 _endTimestamp
    ) public returns (uint256 proposalId) {
        proposalId = _create(
            _erc20ContractAddress,
            _proposalText,
            _endTimestamp,
            block.timestamp
        );
        return proposalId;
    }

    function create(
        address _erc20ContractAddress,
        string calldata _proposalText,
        uint256 _endTimestamp,
        uint256 _startTimestamp
    ) public returns (uint256 proposalId) {
        proposalId = _create(
            _erc20ContractAddress,
            _proposalText,
            _endTimestamp,
            _startTimestamp
        );
        return proposalId;
    }

    function _create(
        address _erc20ContractAddress,
        string calldata _proposalText,
        uint256 _endTimestamp,
        uint256 _startTimestamp
    ) internal returns (uint256 proposalId) {
        ERC20TokensContract erc20TokensContract = ERC20TokensContract(
            _erc20ContractAddress
        );

        require(
            erc20TokensContract.balanceOf(msg.sender) > 0,
            "Only tokenholder can start voting"
        );

        require(
            _endTimestamp > block.timestamp && _endTimestamp > _startTimestamp,
            "Voting end timestamp should be later than the current moment and the voting start timestamp"
        );

        // votingCounterForContract[_erc20ContractAddress]++; // < does not work
        votingCounterForContract[_erc20ContractAddress] =
            votingCounterForContract[_erc20ContractAddress] +
            1;
        proposalId = votingCounterForContract[_erc20ContractAddress];

        proposalText[_erc20ContractAddress][proposalId] = _proposalText;
        startTimestamp[_erc20ContractAddress][proposalId] = _startTimestamp;
        endTimestamp[_erc20ContractAddress][proposalId] = _endTimestamp;

        emit Proposal(
            _erc20ContractAddress,
            proposalId,
            msg.sender,
            _proposalText,
            _startTimestamp,
            _endTimestamp
        );

        return proposalId;
    }

    event VoteFor(
        address indexed forContract,
        uint256 indexed proposalId,
        address indexed by
    );

    event VoteAgainst(
        address indexed forContract,
        uint256 indexed proposalId,
        address indexed by
    );

    function voteFor(
        address _erc20ContractAddress, //..1
        uint256 _proposalId //.............2
    ) public returns (bool success) {
        ERC20TokensContract erc20TokensContract = ERC20TokensContract(
            _erc20ContractAddress
        );

        require(
            erc20TokensContract.balanceOf(msg.sender) > 0,
            "Only tokenholder can vote"
        );

        require(
            startTimestamp[_erc20ContractAddress][_proposalId] <= block.timestamp,
            "Voting has not started yet."
        );

        require(
            endTimestamp[_erc20ContractAddress][_proposalId] > block.timestamp,
            "Voting has finished!"
        );

        require(
            !boolVotedFor[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );
        require(
            !boolVotedAgainst[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );

        numberOfVotersFor[_erc20ContractAddress][_proposalId] =
            numberOfVotersFor[_erc20ContractAddress][_proposalId] +
            1;
        uint256 voterId = numberOfVotersFor[_erc20ContractAddress][_proposalId];

        votedFor[_erc20ContractAddress][_proposalId][voterId] = msg.sender;
        boolVotedFor[_erc20ContractAddress][_proposalId][msg.sender] = true;

        emit VoteFor(_erc20ContractAddress, _proposalId, msg.sender);

        return true;
    }

    function voteAgainst(
        address _erc20ContractAddress, //..1
        uint256 _proposalId //.............2
    ) public returns (bool success) {
        ERC20TokensContract erc20TokensContract = ERC20TokensContract(
            _erc20ContractAddress
        );

        require(
            erc20TokensContract.balanceOf(msg.sender) > 0,
            "Only tokenholder can vote"
        );

        require(
            startTimestamp[_erc20ContractAddress][_proposalId] <= block.timestamp,
            "Voting has not started yet."
        );

        require(
            endTimestamp[_erc20ContractAddress][_proposalId] > block.timestamp,
            "Voting has finished!"
        );

        require(
            !boolVotedFor[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );
        require(
            !boolVotedAgainst[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );

        numberOfVotersAgainst[_erc20ContractAddress][_proposalId] =
            numberOfVotersAgainst[_erc20ContractAddress][_proposalId] +
            1;
        uint256 voterId = numberOfVotersAgainst[_erc20ContractAddress][
            _proposalId
        ];

        votedAgainst[_erc20ContractAddress][_proposalId][voterId] = msg.sender;
        boolVotedAgainst[_erc20ContractAddress][_proposalId][msg.sender] = true;

        emit VoteAgainst(_erc20ContractAddress, _proposalId, msg.sender);

        return true;
    }
}