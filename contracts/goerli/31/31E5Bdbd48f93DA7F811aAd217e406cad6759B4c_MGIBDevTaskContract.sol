/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IlliniBlockchainDevTaskFa22 {
    function publicKey() external view returns (bytes memory); //for the state variable publicKey

    function sendTask(string calldata data) external; //for the sendTask function
}

contract MGIBDevTaskContract {
    
    //to get public key from IB contract
    //address = 0xf192Ed383b8C03F1a22eD52Bf9f45a5a700F285d
    //public key for IB contract: 0x8c0456ac31fb6f53a15ff1ad5555c71d96760f8119dc9a8a992f02c89ad226e1f0cf81273a8017c8409d210cf4969135bb53ea2be22fd3e2eab093830a5c2ad3
    function getPublicKey(address _IBContract) external view returns (bytes memory) {
        return IlliniBlockchainDevTaskFa22(_IBContract).publicKey();
    }

    //performs send task function from IB contract
    function sendTaskIB(address _IBContract, string calldata data) public{
        IlliniBlockchainDevTaskFa22(_IBContract).sendTask(data);
    }    
}