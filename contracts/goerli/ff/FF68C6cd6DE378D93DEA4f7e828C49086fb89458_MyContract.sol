// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IScoracle {
    struct ScoreData {
        uint40 lastUpdated;
        uint216 score;
        bytes extraData;
    }

    //===============Events===============

    /**
     * @dev emitted upon callback function of chainlink call. emits the address that was updated, the time it was updatedand the tick that was returned
     * @param addressToScore The address whose score is being updated
     * @param lastUpdated Timestamp of last update
     * @param score The new score
     * @param extraData Extra data to the type of score request
     **/
    event ScoreUpdated(
        address indexed addressToScore,
        uint256 lastUpdated,
        uint256 score,
        bytes extraData
    );

    /**
     * @dev Added a new score type
     * @param scoreTypeJobId The new adapter job id
     * @param scoreTypeName The new score type name
     **/
    event ScoreTypeAdded(bytes32 indexed scoreTypeJobId, string scoreTypeName);

    /**
     * @dev Deactivated a score type
     * @param scoreTypeJobId The new adapter job id
     **/
    event ScoreTypeDeactivated(bytes32 indexed scoreTypeJobId);

    /**
     * @dev Updated the chainlink node address
     * @param chainlinkNode The new chainlink node address
     **/
    event ChainlinkNodeUpdated(address indexed chainlinkNode);

    /**
     * @dev Updated the chainlink oracle address
     * @param chainlinkOracle The new chainlink oracle address
     **/
    event ChainlinkOracleUpdated(address indexed chainlinkOracle);

    /**
     * @dev Updated the base fee
     * @param baseFee Base fee updated
     **/
    event BaseFeeUpdated(uint256 baseFee);

    /**
     * @dev Updated the chainlink fee
     * @param chainlinkFee The new chainlink fee
     **/
    event ChainlinkFeeUpdated(uint256 chainlinkFee);

    //===============Main Functions===============

    function scoreRequest(
        address addressToScore,
        bytes32 _scoreTypeJobId,
        bytes memory _userSignature
    ) external payable;

    //===============Governance/Admin Functions===============

    function addScoreType(
        bytes32 _scoreTypeJobId,
        string memory _scoreTypeName
    ) external;

    function deactivateScoreType(bytes32 _scoreTypeJobId) external;

    function updateChainlinkNode(address chainlinkNode) external;

    function updateChainlinkOracle(address chainlinkOracle) external;

    function updateBaseFee(uint256 baseFee) external;

    function updateChainlinkFee(uint256 chainlinkFee) external;

    function depositLINK(uint256 amount) external;

    function withdrawLINK(uint256 amount) external;

    function withdrawETH(uint256 amount) external;

    //===============Get Functions===============

    function getScore(
        address _user,
        bytes32 _scoreTypeJobId
    ) external view returns (ScoreData memory scoreData);

    function checkScoreTypeExists(
        bytes32 _scoreTypeJobId
    ) external view returns (bool, string memory, bytes32);

    function getChainlinkNode() external view returns (address);

    function getChainlinkOracle() external view returns (address);

    function getBaseFee() external view returns (uint256);

    function getChainlinkFee() external view returns (uint256);

    function getScoreBounds() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IScoracle.sol";

contract MyContract {
    address constant SCORACLE_ADDRESS =
        0xe953f329041dA0D5Cf23159abc4b45f6fbf8Ab17;

    constructor() {}

    function calculateMacroScore(
        bytes32 _scoreTypeJobId,
        bytes memory _userSignature
    ) external {
        IScoracle scoracle = IScoracle(SCORACLE_ADDRESS);
        scoracle.scoreRequest(msg.sender, _scoreTypeJobId, _userSignature);
    }

    function prequalifyUser(
        bytes32 _scoreTypeJobId
    ) public view returns (bool prequalified, uint256 score) {
        IScoracle scoracle = IScoracle(SCORACLE_ADDRESS);

        // Scoracle's getScore will read an already calculated score from the Scoracle contract's state.
        IScoracle.ScoreData memory scoreData = scoracle.getScore(
            msg.sender,
            _scoreTypeJobId
        );

        prequalified = (scoreData.score > 650) ? true : false;

        return (prequalified, scoreData.score);
    }
}