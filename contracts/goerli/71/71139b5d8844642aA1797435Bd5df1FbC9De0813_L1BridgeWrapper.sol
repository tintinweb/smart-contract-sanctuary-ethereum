/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IMessengerWrapper {
    function consensysL1Bridge() external view returns (address);
}

interface IConsensysMessenger {
    function minimumFee() external view returns (uint256);
}

interface IL1Bridge {
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    )
        external
        payable;
}

contract L1BridgeWrapper {
    address public messengerWrapperAddress;
    address public l1BridgeAddress;
    bool public isNativeToken;
    address tokenAddress;

    constructor (address _messengerWrapperAddress, address _l1BridgeAddress, address _tokenAddress) {
        messengerWrapperAddress = _messengerWrapperAddress;
        l1BridgeAddress = _l1BridgeAddress;
        tokenAddress = _tokenAddress;
        if (tokenAddress == address(0)) {
            isNativeToken = true;
        } else {
            isNativeToken = false;
            IERC20(tokenAddress).approve(l1BridgeAddress, type(uint256).max);
        }
    }

    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    )
        external
        payable
    {
        address consensysL1BridgeAddress = IMessengerWrapper(messengerWrapperAddress).consensysL1Bridge();
        uint256 fee = IConsensysMessenger(consensysL1BridgeAddress).minimumFee();
        messengerWrapperAddress.call{value: fee}("");

        uint256 bridgeAmount = amount;
        if (!isNativeToken) {
            bridgeAmount = 0;
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        }
        IL1Bridge(l1BridgeAddress).sendToL2{value: bridgeAmount}(
            chainId,
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );
    }
}