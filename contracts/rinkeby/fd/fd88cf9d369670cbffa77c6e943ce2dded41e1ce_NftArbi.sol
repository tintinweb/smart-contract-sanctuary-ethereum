/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract NftArbi {
    address internal immutable OPENSEA;

    constructor(
        address _OPENSEA
    ) {
        OPENSEA = _OPENSEA;
    }

    function buyOpensea(
        bytes calldata data
    ) external payable {
        (bool success, bytes memory result) = OPENSEA.call{
            value: msg.value
        }(data);
        require(success, string(result));
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0x150b7a02;
    }

    receive() external payable {}
}