/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

pragma solidity 0.8.10;
pragma abicoder v2;

interface IVRFConsumer {
    /// @dev The function is called by the VRF provider in order to deliver results to the consumer.
    /// @param seed Any string that used to initialize the randomizer.
    /// @param time Timestamp where the random data was created.
    /// @param result A random bytes for given seed anfd time.
    function consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) external;
}


interface IVRFProvider {
    /// @dev The function for consumers who want random data.
    /// Consumers can simply make requests to get random data back later.
    /// @param seed Any string that used to initialize the randomizer.
    function requestRandomData(string calldata seed) external payable;

    function relayProof(bytes calldata proof) external;
}

abstract contract VRFConsumerBase is IVRFConsumer {
    IVRFProvider public provider;

    function consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) external override {
        require(msg.sender == address(provider), "Caller is not the provider");
        _consume(seed, time, result);
    }

    function _consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) internal virtual {
        revert("Unimplemented");
    }
}

contract MockVRFConsumer is VRFConsumerBase {
    string public latestSeed;
    uint64 public latestTime;
    bytes32 public latestResult;

    event RandomDataRequested(address provider, string seed, uint256 bounty);
    event Consume(string seed, uint64 time, bytes32 result);

    constructor(IVRFProvider _provider) {
        provider = _provider;
    }

    function setProvider(IVRFProvider _provider) external {
        provider = _provider;
    }

    function requestRandomDataFromProvider(string calldata seed)
        external
        payable
    {
        provider.requestRandomData{value: msg.value}(seed);

        emit RandomDataRequested(address(provider), seed, msg.value);
    }

    function _consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) internal override {
        latestSeed = seed;
        latestTime = time;
        latestResult = result;

        emit Consume(seed, time, result);
    }
}


contract MockVRFConsumerReentrant is VRFConsumerBase {
    event RandomDataRequested(address provider, string seed, uint256 bounty);
    event Consume(string seed, uint64 time, bytes32 result);

    constructor(IVRFProvider _provider) {
        provider = _provider;
    }

    function setProvider(IVRFProvider _provider) external {
        provider = _provider;
    }

    function requestRandomDataFromProvider(string calldata seed)
        external
        payable
    {
        provider.requestRandomData{value: msg.value}(seed);

        emit RandomDataRequested(address(provider), seed, msg.value);
    }


    bytes public proofStorage;
    uint256 entranceCount = 0;

    function saveProof(bytes memory proof) external {
        proofStorage = proof;
    }

    function lenProofStorage() external view returns(uint256) {
        return proofStorage.length;
    }

    function relayProofReentrant() external {
        provider.relayProof(proofStorage);
    }

    function _consume(
        string calldata seed,
        uint64 time,
        bytes32 result
    ) internal override {
        entranceCount = entranceCount + 1;

        if (entranceCount < 2) {
            provider.relayProof(proofStorage);
        }

        entranceCount = 0;

        emit Consume(seed, time, result);
    }
}