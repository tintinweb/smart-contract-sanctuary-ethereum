//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract GroupBuyRequest {
    event GroupBuyRequested(address token, uint buySize, uint duration);
    address payable constant ops = payable(0x133A5437951EE1D312fD36a74481987Ec4Bf8A96);
    receive() external payable {}

    function requestGroupBuy(address token, uint buySize, uint duration) public payable {
        require(buySize >= 2000000000000000000, "2 ETH minimum buy size");
        require(duration >= 1 days, "1 day minimum duration");
        require(msg.value >= buySize / 200, ".5% fee required");
        ops.transfer(address(this).balance);
        emit GroupBuyRequested(token, buySize, duration);
    }
}