/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptistManifesto {
    string public manifesto = "ipfs://bafkreievtogvlz5ax5p5p4365qcsfx5jdhcgzkslettcjvavptluikw7tq";

    function update(string memory url) public {
        if(msg.sender == 0x929B2E4c1A5229d6B7c1d5039fdB9c296f19Ce80) {
            manifesto = url;
        }
    }
}