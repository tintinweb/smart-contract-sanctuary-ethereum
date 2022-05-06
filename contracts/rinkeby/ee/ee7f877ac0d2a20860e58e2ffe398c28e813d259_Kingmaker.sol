pragma solidity ^0.8.0;

import "./IKing.sol";

contract Kingmaker {
    address payable king = payable(0x7198bd3631F5A3F1699Ac01c3ADFc47A061bDf52);
    bool getPay = true;

function _switch() external {
    0x7198bd3631F5A3F1699Ac01c3ADFc47A061bDf52;
    getPay = !getPay;
}

function claim() external {
    king.transfer(0.002 ether);
}

receive() external payable {
    if (getPay) {
    } else {
        king.transfer(0.000001 ether);
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IKing {
    function pay() external;
}