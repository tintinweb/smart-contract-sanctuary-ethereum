// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Proxy {
    address public minter;
    address public immutable owner;
    address public immutable implementation;
    address public immutable ctfCoin;

    constructor(address _implementation, address _ctfCoin) {
        minter = msg.sender;
        owner = msg.sender;
        implementation = _implementation;
        ctfCoin = _ctfCoin;
    }

    function redeemWinnings() public {
        require(ctfCoin != address(0), "Contract not initialized!");
        require(minter == msg.sender, "Only the minter of the contract can call this!");

        (bool success, ) = ctfCoin.call(
            abi.encodeWithSignature("challengeThreeSolved(address)", tx.origin)
        );
        require(success, "Call failed!");
    }

    fallback() external {
        (bool success, ) = implementation.delegatecall(msg.data);
        require(success, "Delegatecall failed!");
    }
}

contract ctf2 {
    address minter;
    address helper;

    constructor() {}

    function initialize(address _helper) public {
        helper = _helper;
    }

    // helper function that will transfer ERC-20 tokens from one account to another
    function transferTokens(address toAddr, uint256 amt) public {
        (bool success, ) = helper.delegatecall(
            abi.encodeWithSignature("safeTransferFrom(address,address,address,uint256)",
            helper,
            msg.sender,
            toAddr,
            amt
            )
        );
        require(success, "safeTransferFrom failed!");
    }
}