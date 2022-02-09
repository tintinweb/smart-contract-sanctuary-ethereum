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

        address PIcontroller = 0xDCa42df4C02DC16dbA80f4893203F91fADbC5018; // new
        address setterRelayer = 0xED26c78563f98f60B718f7d39e9BFB03A725b015;
        address rateSetter = 0xE46fC0653dc22A089C052ACF14760d55374c9c3d;   // new

        Setter(rateSetter).modifyParameters("defaultLeak", 1);

        // auth
        Setter(PIcontroller).modifyParameters("seedProposer", rateSetter);
        Setter(setterRelayer).modifyParameters("setter", rateSetter);
    }
}