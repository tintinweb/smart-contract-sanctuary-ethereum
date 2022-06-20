/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity 0.6.7;

abstract contract AuctionHouseLike {
  function bids(uint256) external virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint48, address, address);
}

abstract contract SafeEngineLike {
  function modifyCollateralBalance(bytes32, address, int256) external virtual;
}

contract Proposal {
  // addresses
  AuctionHouseLike public constant auctionHouse = AuctionHouseLike(0x9fC9ae5c87FD07368e87D1EA0970a6fC1E6dD6Cb);
  SafeEngineLike   public constant safeEngine   = SafeEngineLike(0xCC88a9d330da1133Df3A7bD823B95e52511A6962);


  function execute(bool) public {
    uint256[7] memory pendingAuctions = [uint256(88), 89, 106, 107, 115, 116, 117];
    uint256 amountToSell;
    address forgoneCollateralReceiver;
    uint256 totalAmount;
    for (uint i; i < pendingAuctions.length; i++) {
      // get auction data
      (amountToSell,,,,,,, forgoneCollateralReceiver,) = auctionHouse.bids(pendingAuctions[i]);

      // transfer to owner
      safeEngine.modifyCollateralBalance("ETH-A", forgoneCollateralReceiver, int256(amountToSell));

      // save total transferred to deduct from auctionHouse later // overflows are not an issue here
      totalAmount += amountToSell;
    }

    safeEngine.modifyCollateralBalance("ETH-A", address(auctionHouse), int256(totalAmount) * -1);
  }
}