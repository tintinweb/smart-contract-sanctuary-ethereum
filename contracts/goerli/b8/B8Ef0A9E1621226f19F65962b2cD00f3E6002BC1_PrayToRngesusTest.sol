// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "IRNGesus.sol";

contract PrayToRngesusTest {

    event RequestId(uint256 requestId, uint256 gweiToUse);

    function prayToRngesus(uint256 _gweiForFulfillPrayer) public payable returns (uint256) {

        uint256 _requestId = IRNGesus(0x3D01696Db490eF68c87749D30DC107f5195eB392).prayToRngesus{value: msg.value}(_gweiForFulfillPrayer);

        emit RequestId(_requestId, _gweiForFulfillPrayer);

        return _requestId;

    }

    function getRandomNumber(uint256 _requestId) public view returns (uint256) {

        uint256 _randomNumber = IRNGesus(0x3D01696Db490eF68c87749D30DC107f5195eB392).randomNumbers(_requestId); 

        return _randomNumber;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IRNGesus {

    function prayToRngesus(uint256 _gweiForFulfillPrayer) external payable returns (uint256);
    function randomNumbers(uint256 _requestId) external view returns (uint256);

}