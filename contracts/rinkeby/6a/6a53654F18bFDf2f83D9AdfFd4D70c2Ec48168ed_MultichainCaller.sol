// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICallProxy.sol";

contract MultichainCaller {
    ICallProxy public immutable callProxy;
    address public receiver;

    event DataReceived(bytes);
    event TestFallback(address,bytes);

    event MessageSent(string message, uint256 number, uint256 fee);
    event Fallback(address from, bytes data, string message, uint256 number);

    constructor (ICallProxy _callProxy) {
        callProxy = _callProxy;
    }

    receive() payable external {}

    // @notice call contract  with paying fees on receiver side
    function callReceiverWhoWillPay(
        string calldata message,
        uint256 number
    ) external {
        callProxy.anyCall(
            receiver,
            abi.encode(message, number),
            address(this),
            0xfa2,  //Fantom testnet
            0       //Gas fee paid on destination chain
        );

        emit MessageSent(message, number, 0);
    }


    // @notice call contract  with paying fees from contract balance
    function callReceiverPayNow(
        string calldata message,
        uint256 number
    ) external {
        bytes memory data = abi.encode(message, number);
        uint256 fee = callProxy.calcSrcFees('0', 0xfa2, data.length);
        require(address(this).balance >= fee, "Can't pay fee");

        callProxy.anyCall{value: fee}(
            receiver,
            data,
            address(this),
            0xfa2,  //Fantom testnet
            2       //Gas fee paid on source chain
        );

        emit MessageSent(message, number, fee);
    }

    // @notice to receive fallback
    function anyExecute(bytes calldata _data)
    external
    returns (bool success, bytes memory result)
    {
        emit DataReceived(_data);
        bytes4 selector = bytes4(_data[:4]);
        if (selector == IFallback.anyFallback.selector) {
            (address from, bytes memory fallbackData) = abi.decode(_data[4:], (address, bytes));
            (string memory message, uint256 number) = abi.decode(fallbackData, (string, uint256));
            emit Fallback(from, fallbackData, message, number);
        }
        return (true, "");
    }

    function setReceiver(address _receiver) external {
        receiver = _receiver;
    }

    function withdrawExecutionBugdet() external {
        uint256 amount = callProxy.executionBudget(address(this));
        require(amount > 0, "nothing to withdraw");
        callProxy.withdraw(amount);
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}

interface IFallback {
    function anyFallback(address _to, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICallProxy{
    function executor() external view returns (address executor);

    function executionBudget(address depositor) external view returns (uint256);
    function withdraw(uint256 amount) external;

    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,          //address(0) or address(this)
        uint256 _toChainID,
        uint256 _flags              //pay fees on: 0 - destination chain, 2 - source chain
    ) external payable;

    function calcSrcFees(
        string calldata _appID,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);

    function deposit(address _account) external payable;
}

interface IExecutor{
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
}