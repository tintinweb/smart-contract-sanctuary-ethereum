/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;


contract TransferRegistry {
    event LogActionHash(bytes packedActionParameters, bytes32 actionHash, bytes32 signedData,address signer);

    function getActionHash(string memory actionName, bytes memory packedActionParameters)
        internal
        pure
        returns (bytes32 actionHash)
    {
        actionHash = keccak256(abi.encodePacked(actionName, packedActionParameters));
    }

    function forcedTradeActionHash(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return
            getActionHash(
                "FORCED_TRADE",
                abi.encodePacked(
                    starkKeyA,
                    starkKeyB,
                    vaultIdA,
                    vaultIdB,
                    collateralAssetId,
                    syntheticAssetId,
                    amountCollateral,
                    amountSynthetic,
                    aIsBuyingSynthetic,
                    nonce
                )
            );
    }

    function validatePartyBSignature(
        uint256 starkKeyA,
        uint256 starkKeyB,
        uint256 vaultIdA,
        uint256 vaultIdB,
        uint256 collateralAssetId,
        uint256 syntheticAssetId,
        uint256 amountCollateral,
        uint256 amountSynthetic,
        bool aIsBuyingSynthetic,
        uint256 submissionExpirationTime,
        uint256 nonce,
        bytes memory signature
    )  external {
        bytes memory packedActionParameters = abi.encodePacked(
                    starkKeyA,
                    starkKeyB,
                    vaultIdA,
                    vaultIdB,
                    collateralAssetId,
                    syntheticAssetId,
                    amountCollateral,
                    amountSynthetic,
                    aIsBuyingSynthetic,
                    nonce
                );
        bytes32 actionHash = forcedTradeActionHash(
            starkKeyA,
            starkKeyB,
            vaultIdA,
            vaultIdB,
            collateralAssetId,
            syntheticAssetId,
            amountCollateral,
            amountSynthetic,
            aIsBuyingSynthetic,
            nonce
        );

        bytes32 signedData = keccak256(abi.encodePacked(actionHash, submissionExpirationTime));
        address signer;
        {
            uint8 v = uint8(signature[64]);
            bytes32 r;
            bytes32 s;

            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
            }
            signer = ecrecover(signedData, v, r, s);
        }
        emit LogActionHash(packedActionParameters, actionHash, signedData, signer);
    }
}