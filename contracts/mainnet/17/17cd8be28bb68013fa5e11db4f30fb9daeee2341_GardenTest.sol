/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract GardenTest {
    event SomebodyWasHere();

    address public reserveAsset = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function claimRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _fee,
        address _signer,
        bytes memory _signature
    ) external {
        _babl;
        _profits;
        _nonce;
        _maxFee;
        _fee;
        _signer;
        _signature;
        emit SomebodyWasHere();
    }
}