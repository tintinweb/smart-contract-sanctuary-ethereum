// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IScore {
    function setScore(address studentAddress, uint score) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IScore.sol";

contract Teacher is IScore {
    IScore _scoreContract;

    function setScoreContract(IScore scoreContract) external {
        _scoreContract = scoreContract;
    }

    function setScore(address studentAddress, uint score) external {
        _scoreContract.setScore(studentAddress, score);
    }
}