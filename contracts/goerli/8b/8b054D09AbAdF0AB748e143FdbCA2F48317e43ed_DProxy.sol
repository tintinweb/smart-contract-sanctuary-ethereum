// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DProxy {
    event Data(
        address nftAddress,
        uint256 assetId,
        uint256 price,
        bytes fingerprint);

    function proxyDERC721(address coin, address target, uint amount, bytes calldata data) public {
        address addr;
        uint256 asset;
        uint256 price;
        bytes memory fprint;

        (addr, asset, price, fprint) = abi.decode(data[4:], (address, uint256, uint256, bytes));

        emit Data(addr, asset, price, fprint);
    }
}