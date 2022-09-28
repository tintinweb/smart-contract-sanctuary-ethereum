contract MockPriceFeed {
    address public admin;

    uint8 _decimals;
    uint80 _roundId;
    int256 _answer;
    uint256 _startedAt;
    uint256 _updatedAt;
    uint80 _answeredInRound;

    constructor(
        uint8 decimals_,
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint80 answeredInRound
    ) {
        _decimals = decimals_;

        _roundId = roundId;
        _answer = answer;
        _startedAt = startedAt;
        _updatedAt = block.timestamp;
        _answeredInRound = answeredInRound;

        admin = msg.sender;
    }

    function setRoundData(
        int256 answer
    ) external {
        require(msg.sender == admin, "ONLY_ADMIN");

        _roundId = _roundId + 1;
        _answer = answer;
        _answeredInRound = _roundId;
        _updatedAt = block.timestamp;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function description() external view returns (string memory) {
        return ("");
    }

    function version() external view returns (uint256) {
        return 1;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 roundId_)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (roundId_, _answer, _startedAt, _updatedAt, _answeredInRound);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
    }
}