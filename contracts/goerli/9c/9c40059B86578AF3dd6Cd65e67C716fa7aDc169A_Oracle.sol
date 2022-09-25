// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.6.0;

contract Oracle {
    // defines a general api request
    struct Request {
        uint256 roundId; //round id
        string eventId; //event id
        string queryUrl; //API url
        string attributeToFetch;
        uint256 createdAt;
        // Answer is uint256[4]: 3 elements is odds
        // and last is match result: default: 0, 1: home win, 2: draw, 3: away win.
        // Answers provided by the oracle nodes, mapping with oracle node address.
        mapping(address => uint256[]) answers;
        // Quorum is an mapping of address oracle nodes and a value,
        // use to mark which nodes is already answer,
        // 1=oracle hasn't answered, 2=oracle has answered
        // avoid spam answer from single node.
        mapping(address => uint256) quorum;
    }

    struct ConsensusAnswer {
        uint256[] answer;
        uint256 createdAt;
        uint256 lastUpdatedAt;
    }
    // PROPERTIES
    address public owner;
    uint256 currentRoundId = 0; //increasing round id
    Request[] public requests; //list of requests made to the contract
    address[] public oracles; // list address of valid oracles (can update data)
    // mapping of roundId and eventId
    mapping(uint256 => mapping(string => ConsensusAnswer))
        public consensusAnswers;

    // CONFIG
    uint256 public SOURCE = 1; // API Provider ID, where oracle nodes get answer
    uint256 public MIN_QUORUM = 3; //minimum number of responses to receive before declaring final result
    uint256 public SLIPPAGE = 5; // %
    uint256 public TIMEOUT = 120 seconds;

    modifier isOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function latestRoundId() public view returns (uint256) {
        if (currentRoundId == 0) return 0;
        else return currentRoundId - 1;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function setSource(uint256 _source) public isOwner {
        SOURCE = _source;
    }

    function setMinQuorum(uint256 _minQuorum) public isOwner {
        MIN_QUORUM = _minQuorum;
    }

    function setSlippage(uint256 _slippage) public isOwner {
        require(SLIPPAGE <= 100, "setSlippage: invalid slippage");
        SLIPPAGE = _slippage;
    }

    function setTimeout(uint256 _timeout) public isOwner {
        TIMEOUT = _timeout;
    }

    function getLatestAnswer(uint256 _roundId, string memory _eventId)
        public
        view
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        return (
            consensusAnswers[_roundId][_eventId].answer,
            consensusAnswers[_roundId][_eventId].createdAt,
            consensusAnswers[_roundId][_eventId].lastUpdatedAt
        );
    }

    function addOracle(address _oracle) public isOwner {
        for (uint i = 0; i < oracles.length; i++) {
            require(oracles[i] != _oracle, "addOracle: address exists!");
        }
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
        emit NewRound(currentRoundId, _eventId, _urlToQuery, _attributeToFetch);

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
        require(
            currRequest.createdAt + TIMEOUT >= now,
            "updateAnswer: Timeout!"
        );
        require(_valueRetrieved.length == 4, "updateAnswer: invalid answer");

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

                if (answers.length > 0 && _validate(answers, _valueRetrieved)) {
                    currentQuorum++;
                    if (currentQuorum >= MIN_QUORUM) {
                        _updateAnswer(_roundId, _eventId, _valueRetrieved);
                        emit AnswerUpdated(
                            currRequest.roundId,
                            currRequest.eventId,
                            currRequest.queryUrl,
                            currRequest.attributeToFetch
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
        // validate result: result must be equal.
        if (proposal[3] != current[3]) return false;
        else {
            // validate odds: odds must be in range current * (1 +- slippage/100)
            for (uint256 i = 0; i < 3; i++) {
                (uint256 lowerBound, uint256 upperBound) = _calcBoundary(
                    current[i]
                );
                if (lowerBound > proposal[i] || upperBound < proposal[i]) {
                    return false;
                }
            }
        }
        return true;
    }

    function _calcBoundary(uint256 value)
        internal
        view
        returns (uint256 lowerBound, uint256 upperBound)
    {
        lowerBound = (value * (100 - SLIPPAGE)) / 100;
        upperBound = (value * (100 + SLIPPAGE)) / 100;
    }

    function _updateAnswer(
        uint256 _roundId,
        string memory _eventId,
        uint256[] memory _answer
    ) internal {
        uint256 createdAt = consensusAnswers[_roundId][_eventId].createdAt;
        uint256 lastUpdatedAt = 0;
        if (createdAt == 0) {
            createdAt = now;
            lastUpdatedAt = 0;
        }
        consensusAnswers[_roundId][_eventId] = ConsensusAnswer(
            _answer,
            createdAt,
            lastUpdatedAt
        );
    }

    //event that triggers oracle outside of the blockchain
    event NewRound(
        uint256 roundId,
        string eventId,
        string queryUrl,
        string attributeToFetch
    );

    //triggered when there's a consensus on the final result
    event AnswerUpdated(
        uint256 roundId,
        string eventId,
        string queryUrl,
        string attributeToFetch
    );
}