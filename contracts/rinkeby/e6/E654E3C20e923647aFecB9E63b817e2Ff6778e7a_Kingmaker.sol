pragma solidity ^0.8.0;

contract Kingmaker {
    address payable king = payable(0x7198bd3631F5A3F1699Ac01c3ADFc47A061bDf52);
    bool getPay = true;

function _switch() external {
    getPay = !getPay;
}

function claim() external {
    king.call{gas: 400000, value: 0.001 ether}("");
}

receive() external payable {
    if (getPay) {
    } else {
        king.call{gas: 400000, value: 0.00001 ether}("");
    }
  }
}