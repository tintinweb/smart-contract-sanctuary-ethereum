pragma solidity ^0.7.0;

import "./MMPV5.sol";

contract MMPV5Factory {

    event NewMMPV5(address mmpV5);

    function newMMPV5(address owner, address operator) external {
        MarketMakerProxy mmpV5 = new MarketMakerProxy();
        mmpV5.setOperator(operator);
        mmpV5.transferOwnership(owner);

        emit NewMMPV5(address(mmpV5));
    }
}