// SPDX-License-Identifier: GPL-3.0

/*
    Copyright 2023 association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

import "./verifier.sol";

contract PublicAttestor {
    address private owner;
    uint256[] public valitRoots;
    uint256 public latestChallenge;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

        constructor() {
        owner = msg.sender;
    }

    function checkRoot(uint256 value) public view returns (bool) {
        for (uint256 i = 0; i < valitRoots.length; i++) {
            if (valitRoots[i] == value) {
                return true;
            }
        }
        return false;
    }
    function attest(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[3] calldata _pubSignals) public {
        
        address convertedAddress = address(uint160(_pubSignals[1]));
        
        // check authenticity of the device address
        if (convertedAddress != msg.sender) { revert(); } 

        // check validity of the Merkle root
        if (checkRoot(_pubSignals[0])) { revert(); } 

        // check if the challenge is up-to-date
        if (_pubSignals[2] != latestChallenge) { revert(); }
        
        // verify zkSNARK proof
        bool proofVerification;
        Groth16Verifier verifier = new Groth16Verifier();
        proofVerification = verifier.verifyProof(_pA, _pB, _pC, _pubSignals);    
        if (!proofVerification) { revert(); }

        return;
    }

    function publishChallenge(uint256 challenge) external onlyOwner {
        latestChallenge = challenge;
        return; 
    }

    function addRoot(uint256 newRoot) external onlyOwner {
        valitRoots.push(newRoot);
        return; 
    }
}