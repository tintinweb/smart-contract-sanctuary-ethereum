/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

library dexUtils {
    function checkSignature(address signer, bytes32 messageHash, bytes memory signature) public pure returns(bool) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
        if(ecrecover(ethSignedMessageHash, v, r, s) == signer) {
            return true;
        } else {
            return false;
        }
    }

    function getOrderHash(address maker, address makerCoinContract, address takerCoinContract, uint256 makerQty, uint256 takerQty, uint256 deadline, uint256 nonce, bool increaseNonceOnCompleteFill) public pure returns (bytes32) {
        return keccak256(abi.encode(maker, makerCoinContract, takerCoinContract, makerQty, takerQty, deadline, nonce, increaseNonceOnCompleteFill));
    }

    function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function checkQuoteContract(address makerContract, address takerContract, address[] memory _quoteContracts) internal pure returns(address) {
        address _quoteContract = address(0);
        
        if(_checkContractAddress(makerContract, _quoteContracts)) {
            _quoteContract = makerContract;
        
        } else if(_checkContractAddress(takerContract, _quoteContracts)) {
            _quoteContract = takerContract;
        }

        return _quoteContract;
    }

    function _checkContractAddress(address contractToBeChecked, address[] memory contractsList) internal pure returns(bool) {        
        for(uint256 n = 0; n < contractsList.length; n++) {
            if(contractsList[n] == contractToBeChecked) return true;
        }

        return false;
    }

    // Returns answers with 8 decimal places, change this function eventually and get price directly from price oracle.

    function getAEXPrice() public pure returns(uint256) {
        // $0.1
        return(10000000);
    }
}