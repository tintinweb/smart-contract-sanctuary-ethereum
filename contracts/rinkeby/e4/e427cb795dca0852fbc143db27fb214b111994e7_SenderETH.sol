// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external;
}

error NotOwner();

contract SenderETH {
    address private owner;
    address public receiveAddr;
    uint256 public chainID;
    CallProxy public anyCallProxy;

    event SendMsg(string msg);

    modifier OnlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function send(string calldata _msg) external {
        anyCallProxy.anyCall(receiveAddr, abi.encode(_msg), address(0), chainID, 0);

        emit SendMsg(_msg);
    }

    function setAnyCallProxy(address _proxy) external OnlyOwner {
        anyCallProxy = CallProxy(_proxy);
    }

    function setReceiveAddr(address _receiveAddr) external OnlyOwner {
        receiveAddr = _receiveAddr;
    }

    function setChainID(uint256 _chainid) external OnlyOwner {
        chainID = _chainid;
    }
}