// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTXInvetoryStaking {
    function xTokenShareValue(uint256 vaultId) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol';

interface IOracle is AggregatorInterface {
    function submit(uint256 roundId, int256 price) external;

    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/INFTXInvetoryStaking.sol';
import './interfaces/IOracle.sol';

contract XTokenOracle {
    /// @notice address of NFTX vaultID
    uint256 public immutable nftxVaultID;

    /// @notice address of oracle contract
    IOracle public immutable oracle;

    /// @notice address of NFTX inventory staking
    INFTXInvetoryStaking public immutable nftxInventoryStaking;

    // /// @notice address of NFTX inventory staking
    // uint8 public constant decimals = 18;

    constructor(uint256 vaultId, IOracle oracleAddr, INFTXInvetoryStaking staking) {
        nftxVaultID = vaultId;
        oracle = oracleAddr;
        nftxInventoryStaking = staking;
    }

    function latestAnswer() external view returns (int256 answer) {
        uint256 shareVaule = nftxInventoryStaking.xTokenShareValue(nftxVaultID);
        answer = (int256(shareVaule) * oracle.latestAnswer()) / 1e18;
    }

    function decimals() external view returns (uint8) {
        return oracle.decimals();
    }
}