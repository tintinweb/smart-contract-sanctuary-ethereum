/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

pragma solidity=0.6.6;
pragma experimental ABIEncoderV2;
contract New {
    function batchExec(address[] calldata taddr,bytes[] calldata tdata) external {
        for (uint i; i < tdata.length - 1; i++) {
            (bool var1 ,bytes memory qdata) = taddr[i].call(tdata[i]);
            string memory converted = string(qdata);
            require(!var1,converted);
        }
    }
}