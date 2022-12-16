// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DProxy {
    event Data(
        bytes4 method,
        address nftAddress,
        uint256 assetId,
        uint256 price,
        bytes fingerprint);

    function proxyDERC721(address coin, address target, uint amount, bytes memory data) public {
        bytes4 method;
        address addr;
        uint256 asset;
        uint256 price;
        bytes memory fprint;

        (method, addr, asset, price, fprint) = abi.decode(data, (bytes4, address, uint256, uint256, bytes));

        emit Data(method, addr, asset, price, fprint);
    }
}