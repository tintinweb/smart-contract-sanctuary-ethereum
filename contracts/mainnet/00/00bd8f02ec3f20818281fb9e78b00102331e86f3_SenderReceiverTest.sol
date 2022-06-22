/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GLWTPL

pragma solidity ^0.8.15;

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (Executor executor);
}

interface Executor {
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
}

 // Mainnet
 contract SenderReceiverTest {

    CallProxy public callProxy = CallProxy(0xC10Ef9F491C9B59f936957026020C321651ac078);

    address public owner;
    Executor public executor;
    mapping(uint256 => address) public allowedSources;

    event SendNumber(uint256 number);
    event ReceiveNumber(uint256 number, uint256 gas);

    event StandardReceiveCalled();
    event StandardFallbackCalled();

    constructor() {
        owner = msg.sender;
        executor = callProxy.executor();
    }

    function send(uint256 _number, address _to, uint256 _toChainID) external payable {
        require(msg.sender == owner);

        emit SendNumber(_number);

        callProxy.anyCall{value : msg.value}(
            _to,
            abi.encode(_number),
            address(0), // no fallback
            _toChainID,
            2 // fees paid on source chain
        );
    }

    function setAllowedSource(uint256 _chainID, address _from) external {
        require(msg.sender == owner);

        allowedSources[_chainID] = _from;
    }

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        uint256 gas = gasleft();

        (address from, uint256 fromChainID,) = executor.context();

        require(
            fromChainID != 0 &&
            allowedSources[fromChainID] == from
        );

        (uint256 number) = abi.decode(_data, (uint256));

        emit ReceiveNumber(number, gas);

        uint256 resultNumber = ourFact(number);

        success = true;
        result = abi.encode(resultNumber);
    }

    function ourFact(uint256 x) public returns (uint256) { // non-pure on purpose
        if (x == 0 || x == 1) {
            return 1;
        }

        uint256 result = x;

        while (x > 1) {
            x--;

            unchecked {
                result *= x;
            }
        }

        return result;
    }

    receive() external payable {
        emit StandardReceiveCalled();
    }

    fallback() external payable {
        emit StandardFallbackCalled();
    }

    function cleanup() external {
        require(msg.sender == owner);

        payable(msg.sender).transfer(address(this).balance);
    }
}