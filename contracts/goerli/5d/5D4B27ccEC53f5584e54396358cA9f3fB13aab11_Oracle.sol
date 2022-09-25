// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.6.0;

contract Oracle {
    // defines a general api request
    struct Request {
        uint256 roundId; //round id
        string eventId; //event id
        string queryUrl; //API url
        string attributeToFetch;
        uint256 createdTimestamp;
        mapping(address => uint256[]) answers; //answers provided by the oracles
        mapping(address => uint256) quorum; //oracles which will query the answer (1=oracle hasn't voted, 2=oracle has voted)
    }

    struct ConsensusAnswer {
        uint256 roundId;
        string eventId;
        uint256[] odds;
        uint256 createdTimestamp;
    }
    // PROPERTIES
    address public owner;
    uint256 public currentRoundId = 0; //increasing round id
    Request[] public requests; //list of requests made to the contract
    address[] public oracles; // list address of valid oracles (can update data)
    ConsensusAnswer[] public consensusAnswers;

    // CONFIG
    uint256 MIN_QUORUM = 3; //minimum number of responses to receive before declaring final result
    uint256 public SLIPPAGE = 5; // %
    uint256 public TIMEOUT = 60 seconds;
    uint256 public MAX_ROUND_SAVED = 100;

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setMinQuorum(uint256 _minQuorum) public isOwner {
        MIN_QUORUM = _minQuorum;
    }

    function setSlippage(uint256 _slippage) public isOwner {
        require(SLIPPAGE <= 100, "invalid slippage");
        SLIPPAGE = _slippage;
    }

    function setTimeout(uint256 _timeout) public isOwner {
        TIMEOUT = _timeout;
    }

    function setMaxRound(uint256 _maxRound) public isOwner {
        MAX_ROUND_SAVED = _maxRound;
    }

    function getLastestConsensusAnswer(string memory eventId)
        public
        view
        returns (
            uint256,
            string memory,
            uint256[] memory,
            uint256
        )
    {
        if (consensusAnswers.length > 0) {
            for (uint i = consensusAnswers.length; i >= 0; i--) {
                ConsensusAnswer memory answer = consensusAnswers[i];
                if (
                    keccak256(bytes(answer.eventId)) ==
                    keccak256(bytes(eventId))
                )
                    return (
                        answer.roundId,
                        answer.eventId,
                        answer.odds,
                        answer.createdTimestamp
                    );
            }
        }
    }

    function addOracle(address _oracle) public isOwner {
        oracles.push(_oracle);
    }

    function removeOracle(address _oracle) public isOwner {
        // find the index of _oracle
        uint256 index = 0;
        while (oracles[index] != _oracle) {
            index++;
        }
        // remove by index
        while (index < oracles.length - 1) {
            oracles[index] = oracles[index + 1];
            index++;
        }
        oracles.pop(); // remove last element
    }

    function getRequestLength() public view returns (uint256) {
        return requests.length;
    }

    function createRequest(
        string memory _eventId,
        string memory _urlToQuery,
        string memory _attributeToFetch
    ) public {
        uint256 length = requests.push(
            Request(
                currentRoundId,
                _eventId,
                _urlToQuery,
                _attributeToFetch,
                now
            )
        );
        Request storage r = requests[length - 1];

        // Update all oracles is unvoted
        for (uint256 i = 0; i < oracles.length; i++) r.quorum[oracles[i]] = 1;

        // launch an event to be detected by oracle outside of blockchain
        emit NewRequest(
            currentRoundId,
            _eventId,
            _urlToQuery,
            _attributeToFetch
        );

        // increase round id
        currentRoundId++;
    }

    //called by the oracle to record its answer
    function updateAnswer(
        uint256 _roundId,
        string memory _eventId,
        uint256[] memory _valueRetrieved
    ) public {
        Request storage currRequest = requests[_roundId];
        require(currRequest.createdTimestamp + TIMEOUT >= now, "Timeout!");

        //check if oracle is in the list of trusted oracles
        //and if the oracle hasn't voted yet
        if (currRequest.quorum[address(msg.sender)] == 1) {
            //marking that this address has voted
            currRequest.quorum[msg.sender] = 2;

            // push value to mapping with address
            currRequest.answers[address(msg.sender)] = _valueRetrieved;

            uint256 currentQuorum = 0;

            //iterate through oracle list and check if enough oracles(minimum quorum)
            //have voted the same answer has the current one
            for (uint256 i = 0; i < oracles.length; i++) {
                uint256[] memory answers = currRequest.answers[oracles[i]];
                if (
                    answers.length > 0 &&
                    _validate(currRequest.answers[oracles[i]], _valueRetrieved)
                ) {
                    currentQuorum++;
                    if (currentQuorum >= MIN_QUORUM) {
                        _updateConsensusAnswer(
                            _roundId,
                            _eventId,
                            _valueRetrieved,
                            now
                        );
                        emit UpdatedAnswer(
                            currRequest.roundId,
                            currRequest.eventId,
                            currRequest.queryUrl,
                            currRequest.attributeToFetch,
                            consensusAnswers[consensusAnswers.length - 1].odds
                        );
                    }
                }
            }
        }
    }

    function _validate(uint256[] memory current, uint256[] memory proposal)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < 3; i++) {
            (uint256 lowerBound, uint256 upperBound) = _calcBoundary(
                current[i]
            );
            if (lowerBound > proposal[i] || upperBound < proposal[i]) {
                return false;
            }
        }
        return true;
    }

    function _calcBoundary(uint256 value)
        internal
        view
        returns (uint256 lowerBound, uint256 upperBound)
    {
        upperBound = (value * (100 + SLIPPAGE)) / 100;
        lowerBound = (value * (100 - SLIPPAGE)) / 100;
    }

    function _updateConsensusAnswer(
        uint256 _roundId,
        string memory _eventId,
        uint256[] memory _answer,
        uint256 createdTimestamp
    ) internal {
        if (consensusAnswers.length >= MAX_ROUND_SAVED) {
            // shift left 1
            for (uint256 i = 0; i < consensusAnswers.length - 1; i++) {
                consensusAnswers[i] = consensusAnswers[i + 1];
            }
            // remove last
            consensusAnswers.pop();
        }
        consensusAnswers.push(
            ConsensusAnswer(_roundId, _eventId, _answer, createdTimestamp)
        );
    }

    //event that triggers oracle outside of the blockchain
    event NewRequest(
        uint256 roundId,
        string eventId,
        string queryUrl,
        string attributeToFetch
    );

    //triggered when there's a consensus on the final result
    event UpdatedAnswer(
        uint256 roundId,
        string eventId,
        string queryUrl,
        string attributeToFetch,
        uint256[] answer
    );
}