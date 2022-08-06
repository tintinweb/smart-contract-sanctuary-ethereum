// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICallProxy.sol";

contract MultichainReceiver {
    ICallProxy public immutable callProxy;
    IExecutor public immutable executor;
    address public caller;

    event MsgReceived(string message, uint256 number);
    event FallbackShouldBeInitiated(string message);
    event CallerSet(address);
    event DataReceived(bytes);

    modifier onlyAuthorized() {
        IExecutor _executor = executor;
        require(msg.sender == address(_executor), "Not executor");
        (address from, uint256 fromChainID, uint256 nonce) = _executor.context();
        require(caller == from, "Not a caller");
        require(fromChainID == 4, "Wrong chain Id");
        _;
    }

    constructor (
        ICallProxy _callProxy,
        address _caller
    ) {
        callProxy = _callProxy;
        executor = IExecutor(_callProxy.executor());

        caller = _caller;
    }

    function anyExecute(bytes calldata _data)
        external
        onlyAuthorized
        returns (bool success, bytes memory result)
    {
        (string memory message, uint256 number) = abi.decode(_data, (string, uint256));
        emit MsgReceived(message, number);

        if (number > 1000) {
            emit FallbackShouldBeInitiated(message);
            return(false, _data);
        }

        return(true, _data);
    }

    function setCaller(address _caller) external {
        caller = _caller;
        emit CallerSet(_caller);
    }


    function withdrawExecutionBugdet() external {
        uint256 amount = callProxy.executionBudget(address(this));
        require(amount > 0, "nothing to withdraw");
        callProxy.withdraw(amount);
        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
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