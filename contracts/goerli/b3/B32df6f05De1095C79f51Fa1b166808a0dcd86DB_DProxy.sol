// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DProxy {
    event Data(
        address nftAddress,
        uint256 assetId,
        uint256 price,
        bytes fingerprint);
    event Input(address coin, address target, uint amount, bytes data);

    function proxy1(address coin, address target, uint amount, bytes calldata data) external {
        address addr;
        uint256 asset;
        uint256 price;
        bytes memory fprint;

        emit Data(addr, asset, price, fprint);
        emit Input(coin, target, amount, data);
    }

    function proxy2(address coin, address target, uint amount, bytes calldata data) external {
        address addr;
        uint256 asset;
        uint256 price;
        bytes memory fprint;

        (addr) = abi.decode(data[4:], (address));

        emit Data(addr, asset, price, fprint);
        emit Input(coin, target, amount, data);
    }

    function proxy3(address coin, address target, uint amount, bytes calldata data) external {
        address addr;
        uint256 asset;
        uint256 price;
        bytes memory fprint;

        (addr, asset) = abi.decode(data[4:], (address, uint256));

        emit Data(addr, asset, price, fprint);
        emit Input(coin, target, amount, data);
    }

    function proxy4(address coin, address target, uint amount, bytes calldata data) external {
        address addr;
        uint256 asset;
        uint256 price;
        bytes memory fprint;

        (addr, asset, price) = abi.decode(data[4:], (address, uint256, uint256));

        emit Data(addr, asset, price, fprint);
        emit Input(coin, target, amount, data);
    }

    function proxy5(address coin, address target, uint amount, bytes calldata data) external {
        address addr;
        uint256 asset;
        uint256 price;
        bytes memory fprint;

        (addr, asset, price, fprint) = abi.decode(data[4:], (address, uint256, uint256, bytes));

        emit Data(addr, asset, price, fprint);
        emit Input(coin, target, amount, data);
    }

    struct Test {
        address addr;
        uint256 asset;
        uint256 price;
        bytes fprint;
    }


    function proxy6(address coin, address target, uint amount, bytes calldata data) external {
        Test memory test = abi.decode(data[4:], (Test));

        emit Data(test.addr, test.asset, test.price, test.fprint);
        emit Input(coin, target, amount, data);
    }

}