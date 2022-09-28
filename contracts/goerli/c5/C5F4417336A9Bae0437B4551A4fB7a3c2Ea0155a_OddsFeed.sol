// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./SignValidator.sol";

contract OddsFeed is SignValidator {
    // defines a general api request
    struct Round {
        uint256 roundId; //round id
        string eventId; //event id
        string urlToQuery; //url to query
        string attributeToFetch;
        uint256 createdAt;
    }

    struct Report {
        string sign;
        uint256[] odds;
    }

    struct ConsensusAnswer {
        uint256[] answer;
        uint256 createdAt;
        uint256 lastUpdatedAt;
    }
    // PROPERTIES
    address public owner;
    mapping(string => uint256) currentRoundId; //increasing round id
    mapping(string => Round[]) public rounds; //list of rounds made to the contract
    address[] public reporters; // list address of valid reporter, use for verify sign
    address[] public posters; // list address of valid poster, can update data
    // for check valid poster/reporter, when add new, set value is 1. when remove, set value is 0
    mapping(address => uint) private reporterVerify;
    mapping(address => uint) private posterVerify;

    // mapping of eventId and roundId
    mapping(string => mapping(uint256 => ConsensusAnswer))
        public consensusAnswers;

    // CONFIG
    uint256 public SOURCE = 1; // API Provider ID, where reporter get the data
    uint256 public MIN_QUORUM = 3; //minimum number of responses to receive before declaring final result
    uint256 public SLIPPAGE = 5; // %
    uint256 public TIMEOUT = 120 seconds;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function latestRoundId(string memory eventId)
        public
        view
        returns (uint256)
    {
        uint256 latestId = currentRoundId[eventId];
        if (latestId == 0) return 0;
        else return latestId - 1;
    }

    function answer(uint256 _roundId, string memory _eventId)
        public
        view
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        return (
            consensusAnswers[_eventId][_roundId].answer,
            consensusAnswers[_eventId][_roundId].createdAt,
            consensusAnswers[_eventId][_roundId].lastUpdatedAt
        );
    }

    function latestAnswer(string memory _eventId)
        public
        view
        returns (
            uint256[] memory,
            uint256,
            uint256
        )
    {
        uint256 roundId = latestRoundId(_eventId);
        return (
            consensusAnswers[_eventId][roundId].answer,
            consensusAnswers[_eventId][roundId].createdAt,
            consensusAnswers[_eventId][roundId].lastUpdatedAt
        );
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function addPoster(address _poster) public isOwner {
        require(posterVerify[_poster] == 0, "addPoster: address exists");
        posters.push(_poster);
        posterVerify[_poster] = 1;
    }

    function removePoster(address _poster) public isOwner {
        require(
            reporterVerify[_poster] == 1,
            "removePoster: address not exists"
        );
        // find the index of _oracle
        uint256 index = 0;
        while (posters[index] != _poster) {
            index++;
        }
        // remove by index
        while (index < posters.length - 1) {
            posters[index] = posters[index + 1];
            index++;
        }
        posters.pop(); // remove last element
    }

    function addReporter(address _reporter) public isOwner {
        require(reporterVerify[_reporter] == 0, "addReporter: address exists");
        reporters.push(_reporter);
        reporterVerify[_reporter] = 1;
    }

    function removeReporter(address _reporter) public isOwner {
        require(
            reporterVerify[_reporter] == 1,
            "removeReporter: address not exists"
        );
        // find the index of _oracle
        uint256 index = 0;
        while (reporters[index] != _reporter) {
            index++;
        }
        // remove by index
        while (index < reporters.length - 1) {
            reporters[index] = reporters[index + 1];
            index++;
        }
        reporters.pop(); // remove last element
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

    function createRound(
        string memory _eventId,
        string memory _urlToQuery,
        string memory _attributeToFetch
    ) public {
        uint256 roundId = currentRoundId[_eventId];
        rounds[_eventId].push(
            Round(
                roundId,
                _eventId,
                _urlToQuery,
                _attributeToFetch,
                block.timestamp
            )
        );

        // launch an event to be detected by oracle outside of blockchain
        emit NewRound(
            roundId,
            _eventId,
            _urlToQuery,
            _attributeToFetch,
            block.timestamp,
            TIMEOUT
        );

        // increase round id
        currentRoundId[_eventId] += 1;
    }

    function updateReport(
        uint256 _roundId,
        string memory _eventId,
        bytes[] memory _signs,
        uint256[][] memory _oddsArr
    ) public {
        require(
            _signs.length == _oddsArr.length,
            "updateReport: invalid report"
        );
        require(posterVerify[msg.sender] == 1, "Caller is not the poster");

        uint256 maxVote = 0;
        uint index = 0;
        for (uint j = 0; j < _oddsArr.length; j++) {
            // verify sign
            verifySign(_roundId, _signs[j], _oddsArr[j]);
            // vote for odds
            uint vote = _countVote(_oddsArr[j], _oddsArr);
            // find odds has maximum vote
            if (maxVote <= vote) {
                maxVote = vote;
                index = j;
            }
        }
        if (maxVote >= MIN_QUORUM) {
            // update consensus answer
            _updateAnswer(_roundId, _eventId, _oddsArr[index]);
        }
    }

    function verifySign(
        uint256 _roundId,
        bytes memory _signature,
        uint256[] memory _odds
    ) public view {
        for (uint i = 0; i < reporters.length; i++) {
            address recover = recoverSigner(
                getEthSignedMessageHash(getMessageHash(_odds, _roundId)),
                _signature
            );
            require(reporterVerify[recover] == 1);
        }
    }

    function _countVote(uint256[] memory _odds, uint256[][] memory _oddsArr)
        internal
        view
        returns (uint)
    {
        uint vote = 0;
        for (uint i = 0; i < _oddsArr.length; i++) {
            if (_validate(_odds, _oddsArr[i])) {
                vote++;
            }
        }
        return vote;
    }

    function _validate(uint256[] memory current, uint256[] memory proposal)
        internal
        view
        returns (bool)
    {
        // validate odds: odds must be in range current * (1 +- slippage/100)
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
        lowerBound = (value * (100 - SLIPPAGE)) / 100;
        upperBound = (value * (100 + SLIPPAGE)) / 100;
    }

    //called by the poster to record answer
    function _updateAnswer(
        uint256 _roundId,
        string memory _eventId,
        uint256[] memory _answer
    ) internal {
        uint256 createdAt = consensusAnswers[_eventId][_roundId].createdAt;
        uint256 lastUpdatedAt = 0;
        if (createdAt == 0) {
            createdAt = block.timestamp;
            lastUpdatedAt = block.timestamp;
        }
        consensusAnswers[_eventId][_roundId] = ConsensusAnswer(
            _answer,
            createdAt,
            lastUpdatedAt
        );
        emit AnswerUpdated(_roundId, _eventId, createdAt, lastUpdatedAt);
    }

    //event that triggers oracle outside of the blockchain
    event NewRound(
        uint256 roundId,
        string eventId,
        string _urlToQuery,
        string attributeToFetch,
        uint256 createdAt,
        uint256 TIMEOUT
    );

    //triggered when there's a consensus on the final result
    event AnswerUpdated(
        uint256 roundId,
        string eventId,
        uint256 createdAt,
        uint256 lastUpdatedAt
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract SignValidator {
    function getMessageHash(
        uint256[] memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_message, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _signer,
        uint256[] memory _message,
        uint256 _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}