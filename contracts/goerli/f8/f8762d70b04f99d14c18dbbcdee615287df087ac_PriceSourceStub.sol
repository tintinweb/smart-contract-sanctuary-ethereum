// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IPriceSource.sol";

contract PriceSourceStub is IPriceSource{
    uint80 _roundId = 0;
    int256 _answer = 500 * 10**8;
    uint256 _startedAt = 0;
    uint256 _updatedAt = 0;
    uint80 _answeredInRound = 0;
	function latestRoundData() external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (_roundId,_answer,_startedAt,_updatedAt,_answeredInRound);
    }

    function setRoundData(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)  public
    {
        _roundId = roundId;
        _answer = answer;
        _startedAt = startedAt;
        _updatedAt = updatedAt;
        _answeredInRound = answeredInRound; 
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceSource {
	function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}