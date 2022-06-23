// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IAnyswapV6CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external;
}

error NotOwner();

contract Crosschain {
    address private owner;

    IAnyswapV6CallProxy public anyCallProxy;

    event SendMsg(string msg);
    event Fallback(address to);
    event ReceiveMsg(string msg);

    modifier OnlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    constructor(address _anyCallProxy) {
        owner = msg.sender;

        anyCallProxy = IAnyswapV6CallProxy(_anyCallProxy);
    }

    // anyCall
    function send(
        string calldata _msg,
        address _receiveAddr,
        uint256 _chainID
    ) external {
        anyCallProxy.anyCall(_receiveAddr, abi.encode(_msg), address(0), _chainID, 2);

        emit SendMsg(_msg);
    }

    // anyFallback
    function anyFallback(address _to, bytes calldata _data) external {
        emit Fallback(_to);
    }

    // anyExecute
    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result) {
        string memory _msg = abi.decode(_data, (string));

        emit ReceiveMsg(_msg);

        return (true, "");
    }

    // set anycallproxy
    function setAnyCallProxy(IAnyswapV6CallProxy _anyCallProxy) external OnlyOwner {
        anyCallProxy = _anyCallProxy;
    }
}