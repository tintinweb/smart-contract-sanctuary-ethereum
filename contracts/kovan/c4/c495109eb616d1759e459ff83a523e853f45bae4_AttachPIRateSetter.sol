/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(bytes32, uint256) public virtual;
    function modifyParameters(bytes32, address) public virtual;
}

contract AttachPIRateSetter {

    function execute(bool) public {

        address pidCalculator = 0xDCa42df4C02DC16dbA80f4893203F91fADbC5018; // new
        address setterRelayer = 0xED26c78563f98f60B718f7d39e9BFB03A725b015;
        address rateSetter = 0x97533CD0c5997bce2504378CB29a091830de0F94;

        Setter(rateSetter).modifyParameters("defaultLeak", 0);
        Setter(rateSetter).modifyParameters("pidCalculator", pidCalculator);
        Setter(pidCalculator).modifyParameters("seedProposer", rateSetter);
        Setter(setterRelayer).modifyParameters("setter", rateSetter);
    }
}