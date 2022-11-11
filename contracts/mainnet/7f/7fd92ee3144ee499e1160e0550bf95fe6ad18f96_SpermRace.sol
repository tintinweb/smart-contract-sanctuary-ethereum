// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./console.sol";

contract SpermRace is Ownable {
    using ECDSA for bytes32;

    uint internal immutable MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint internal immutable LEFTMOST_ONE_BIT = 0x8000000000000000000000000000000000000000000000000000000000000000;

    IERC721 spermGameContract;

    bool inProgress;
    bool enforceRaceEntrySignature;

    uint public constant TOTAL_EGGS = 1778;
    uint public constant TOTAL_SUPPLY = 8888;
    uint public constant MAX_TRAIT_SCORE = 12;

    uint private constant NUM_NEGATIVE_EVENTS = 8;
    uint private constant NUM_POSITIVE_EVENTS = 6;

    uint public raceEntryFee = 0 ether;
    uint public bettingFee = 0 ether;
    // The higher the individual event threshold, the less likely it is
    uint public individualEventThreshold = 15;
    // The lower the global even threshold, the less likely it is
    uint public globalEventThreshold = 30;

    bytes32[] public participantsRootHashArray;
    bytes32[] public betsPlacedRootHashArray;
    bytes32[] public fertilizationsRootHashArray;

    uint[][] public raceRandomNumbers;

    address private operatorAddress;

    event EnterRace(address _sender, uint[] _participants, uint _value, uint _raceIndex);
    event PlaceBet(address _sender, uint[] _eggTokenIds, uint[] _spermTokenIds, uint _value, uint _raceIndex);

    enum EventType {
        BLUE_BALL,
        IUD,
        CONDOM,
        COITUS_INTERRUPTUS,
        VASECTOMY,
        WHITE_BLOOD_CELL,
        MOUNTAIN_DEW,
        WHISKEY,
        VIAGRA,
        EDGING,
        PUMP,
        LUBE,
        PINEAPPLE,
        ZINC,
        NONE
    }
    struct TokenRoundResult {
        uint tokenId;
        int progress;
        int individualEventProgress;
        int globalEventProgress;
        EventType individualEvent;
        EventType globalEvent;
    }

    constructor(address _spermGameContractAddress) {
        spermGameContract = IERC721(_spermGameContractAddress);
        operatorAddress = msg.sender;
    }

    function enterRace(uint[] calldata tokenIds, bytes[] calldata signatures) external payable enforceSignatureEntry(tokenIds, signatures) {
        require(!inProgress, "Race is in progress");
        require(msg.value >= raceEntryFee, "Insufficient fee supplied to enter race");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(!isEgg(tokenIds[i]), "Token must be a sperm");
            require(spermGameContract.ownerOf(tokenIds[i]) == msg.sender, "Not the owner of the token");
        }
        uint upcomingRaceIndex;
        unchecked {
            upcomingRaceIndex = getRaceIndex() + 1;
        }
        emit EnterRace(msg.sender, tokenIds, msg.value, upcomingRaceIndex);
    }

    function startRace(bytes32 participantsRootHash, bytes32 betsPlacedRootHash) external onlyOwner {
        inProgress = true;
        participantsRootHashArray.push(participantsRootHash);
        betsPlacedRootHashArray.push(betsPlacedRootHash);
        raceRandomNumbers.push(new uint[](0));
    }

    function placeBet(uint[] calldata eggTokenIds, uint[] calldata spermTokenIds, bytes[] calldata signatures) external payable enforceSignatureEntry(eggTokenIds, signatures) {
        require(!inProgress, "Race is in progress");
        require(msg.value >= bettingFee, "Insufficient fee supplied to place bet");
        require(eggTokenIds.length == spermTokenIds.length, "One egg required for each bet placed on a sperm");
        for (uint i = 0; i < eggTokenIds.length; i++) {
            require(isEgg(eggTokenIds[i]), "All tokens in eggTokenIds must be an egg");
            require(!isEgg(spermTokenIds[i]), "All tokens in spermTokenIds must be a sperm");
            require(spermGameContract.ownerOf(eggTokenIds[i]) == msg.sender, "Must be the owner of all the eggs used to place bets");
        }
        uint upcomingRaceIndex;
        unchecked {
            upcomingRaceIndex = getRaceIndex() + 1;
        }
        emit PlaceBet(msg.sender, eggTokenIds, spermTokenIds, msg.value, upcomingRaceIndex);
    }

    // TODO: Figure out how to make tokenId a uint
    function isInRace(uint round, string calldata tokenId, bytes32[] calldata _merkleProof) external view {
        bytes32 leafNode = keccak256(abi.encodePacked(tokenId));
        require(MerkleProof.verify(_merkleProof, participantsRootHashArray[round], leafNode), "tokenId is not in race");
    }

    function recordFertilizations(bytes32 fertilizationsRootHash) external onlyOwner {
        require(!inProgress, "Race is in progress");
        fertilizationsRootHashArray.push(fertilizationsRootHash);
    }

    function calculateTraitsFromTokenId(uint tokenId) public pure returns (uint) {
        if ((tokenId == 409) || (tokenId == 1386) || (tokenId == 1499) || (tokenId == 1556) || (tokenId == 1971) || (tokenId == 2561) || (tokenId == 3896) || (tokenId == 4719) || (tokenId == 6044) || (tokenId == 6861) || (tokenId == 8348) || (tokenId == 8493)) {
            return 12;
        }

        uint magicNumber = 69420;
        uint iq = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "IQ"))) % 4) + 1;
        uint speed = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "Speed"))) % 4) + 1;
        uint strength = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "Strength"))) % 4) + 1;

        return iq + speed + strength;
    }

    function progressRace256Rounds() external onlyOwner {
        require(inProgress, "Race must be in progress to progress");
        uint raceIndex = getRaceIndex();
        raceRandomNumbers[raceIndex].push(random(raceIndex));
    }

    function endRace() external onlyOwner {
        inProgress = false;
    }

    function setOperatorAddress(address _address) external onlyOwner {
        operatorAddress = _address;
    }

    function resetRace() external onlyOwner {
        require(inProgress, "Sperm race is not in progress");

        uint raceIndex = getRaceIndex();
        delete raceRandomNumbers[raceIndex];
    }

    function leaderboard(uint index) external view returns (TokenRoundResult[] memory) {
        uint raceIndex = getRaceIndex();
        require((raceRandomNumbers[raceIndex].length * 256) > index, "Need to progress more rounds before leaderboard results are available");
        TokenRoundResult[] memory roundResult = new TokenRoundResult[](TOTAL_SUPPLY);
        for (uint i = 0; i < TOTAL_SUPPLY; i++) {
            roundResult[i] = TokenRoundResult(i, 0, 0, 0, EventType.NONE, EventType.NONE);
        }

        // Fisher-Yates shuffle
        uint randomNumber = (raceRandomNumbers[raceIndex][(index / 256)] >> (index % 256));
        for (uint k = 0; k < TOTAL_SUPPLY; k++) {
            uint randomIndex = randomNumber % (TOTAL_SUPPLY - k);
            TokenRoundResult memory randomRes = roundResult[randomIndex];
            roundResult[randomIndex] = roundResult[k];
            roundResult[k] = randomRes;
        }
        for (uint j = 0; j < TOTAL_SUPPLY; j = j + 2) {
            uint tokenA = roundResult[j].tokenId;
            uint scoreA = calculateTraitsFromTokenId(tokenA);
            uint tokenB = roundResult[j+1].tokenId;
            uint scoreB = calculateTraitsFromTokenId(tokenB);
            if ((randomNumber % (scoreA + scoreB)) < scoreA) {
                roundResult[j].progress += 100;
            } else {
                roundResult[j+1].progress += 100;
            }
        }

        uint numEvents = NUM_NEGATIVE_EVENTS + NUM_POSITIVE_EVENTS;
        for (uint j = 0; j < TOTAL_SUPPLY; j++) {
            uint token = roundResult[j].tokenId;
            uint score = calculateTraitsFromTokenId(token);
            uint tokenBasedRandomNum;
            unchecked {
                tokenBasedRandomNum = randomNumber + (token * 2);
            }
            // Individual Events are more likely to happen for higher scores
            if ((randomNumber % individualEventThreshold) < score) {
                uint eventIndex = tokenBasedRandomNum % numEvents;
                roundResult[j].individualEvent = EventType(eventIndex);
                // Since there are more negative events, expected value for event will be negative
                if (eventIndex >= NUM_NEGATIVE_EVENTS) {
                    roundResult[j].progress += 50;
                    roundResult[j].individualEventProgress = 50;
                } else {
                    roundResult[j].progress -= 50;
                    roundResult[j].individualEventProgress = -50;
                }
            }

            // Global Events are more likely to happen for lower scores, and always help
            if ((randomNumber % globalEventThreshold) > score) {
                uint positiveEventIndex = tokenBasedRandomNum % NUM_POSITIVE_EVENTS;
                roundResult[j].globalEvent = EventType(NUM_NEGATIVE_EVENTS + positiveEventIndex);
                roundResult[j].progress += 25;
                roundResult[j].globalEventProgress = 25;
            }

            // Random jitter up to +0.03 score
            roundResult[j].progress += int(tokenBasedRandomNum % 4);
        }

        return roundResult;
    }

    function setIndividualEventThreshold(uint _individualEventThreshold) external onlyOwner {
        require(_individualEventThreshold >= MAX_TRAIT_SCORE, "Needs to be at least equal to max trait score");
        individualEventThreshold = _individualEventThreshold;
    }

    function setGlobalEventThreshold(uint _globalEventThreshold) external onlyOwner {
        require(_globalEventThreshold >= MAX_TRAIT_SCORE, "Needs to be at least equal to max trait score");
        globalEventThreshold = _globalEventThreshold;
    }

    function setRaceEntryFee(uint _entryFee) external onlyOwner {
        raceEntryFee = _entryFee;
    }

    function setBettingFee(uint _bettingFee) external onlyOwner {
        bettingFee = _bettingFee;
    }

    function random(uint seed) internal view returns (uint) {
        uint randomNum = uint(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed)));
        return (randomNum | LEFTMOST_ONE_BIT);
    }

    function numOfRounds() external view returns (uint) {
        uint raceIndex = getRaceIndex();
        return raceRandomNumbers[raceIndex].length * 256;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getRaceIndex() private view returns (uint) {
        if (participantsRootHashArray.length == 0) {
            return MAX_INT;
        }
        return participantsRootHashArray.length - 1;
    }

    function isEgg(uint tokenId) private pure returns (bool) {
        return (tokenId % 5) == 0;
    }

    function setEnforceRaceEntrySignature (bool _enableSignature) external onlyOwner {
        enforceRaceEntrySignature = _enableSignature;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == operatorAddress;
    }

    modifier enforceSignatureEntry(uint[] calldata tokenIds, bytes[] calldata signatures) {
        if (enforceRaceEntrySignature) {
            require(tokenIds.length == signatures.length, "Number of signatures must match number of tokenIds");
            for (uint i = 0; i < tokenIds.length; i++) {
                bytes32 msgHash = keccak256(abi.encodePacked(tokenIds[i]));
                require(isValidSignature(msgHash, signatures[i]), "Invalid signature");
            }
        }
        _;
    }
}