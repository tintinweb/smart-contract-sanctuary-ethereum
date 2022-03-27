// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./MultiSigWallet.sol";

contract DeployMultiSig {
    MultiSigWallet[] public deployedMultiSig;
    function createNewMultiSig (address[] memory addresses, uint _required, uint _timelock) public {
        MultiSigWallet newWallet = new MultiSigWallet(addresses, _required, _timelock);
        deployedMultiSig.push(newWallet);
    }

    function returnAllWallets() external view returns(MultiSigWallet[] memory){
        return deployedMultiSig;
    }
}