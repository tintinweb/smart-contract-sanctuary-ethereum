//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "./ERC721TokenReceiver.sol";
import "./MultiSigWalletWithPermit.sol";
import "./ERC1155TokenReceiver.sol";

/// @title MultiSigV1
/// @author [email protected]
contract MultiSigV1 is
    MultiSigWalletWithPermit,
    ERC721TokenReceiver,
    ERC1155TokenReceiver
{
    constructor(address[] memory _owners, uint256 _required,
        bool _immutable)
        MultiSigWalletWithPermit(_owners, _required, _immutable)
    {}

    function eipFeatures() public pure returns (uint256[3] memory fs) {
        fs = [uint256(165), uint256(721), uint256(1155)];
    }

    function version() public pure returns (uint256) {
        return 1;
    }
}