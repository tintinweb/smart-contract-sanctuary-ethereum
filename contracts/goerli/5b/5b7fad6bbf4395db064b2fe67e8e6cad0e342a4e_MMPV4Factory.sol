pragma solidity ^0.5.0;

import "./MMPV4.sol";

contract MMPV4Factory {

    event NewMMPV4(address mmpV4);

    function newMMPV4(address owner, address operator) external {
        MarketMakerProxy mmpV4 = new MarketMakerProxy();
        mmpV4.setOperator(operator);
        mmpV4.transferOwnership(owner);

        emit NewMMPV4(address(mmpV4));
    }
}