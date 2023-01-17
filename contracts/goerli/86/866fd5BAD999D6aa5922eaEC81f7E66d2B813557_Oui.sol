/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Tractor {

    function drive(
        bytes calldata _instructions, 
        address _target
    ) external {
        (bool result, ) = _target.call(_instructions);
        require(result, "Call failed");
    }

}

contract Oui  {
    
    Tractor tractor;
    
    constructor(address _t) {
        tractor = Tractor(_t);
    }

    function write() public {
        tractor.drive(
            abi.encodeWithSignature("harvestCrops(uint256)", 100), 
            address(0xB2bF9883B44fCf195D0c140085Ca9E92056c3979)
        );
        tractor.drive(
            abi.encodeWithSignature("feedCow(uint32,uint32)", 8, 10000), 
            address(0xB2bF9883B44fCf195D0c140085Ca9E92056c3979)
        );
    }
}