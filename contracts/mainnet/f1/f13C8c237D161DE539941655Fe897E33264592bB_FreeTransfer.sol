/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract FreeTransfer {

    function transfer(
        address[] calldata addressList, 
        uint256[] calldata tokenAmountList,
        address tokenAddress
    ) external payable {
        uint256 baseLength = addressList.length;
        require(baseLength == tokenAmountList.length, 'Different Length');
        if (tokenAddress == address(0x0)) {
            for (uint256 i = baseLength; i > 0;) {
                --i;
                payable(addressList[i]).transfer(tokenAmountList[i]);
            }
            uint256 nowBalance = payable(address(this)).balance;
            if (nowBalance > 0) {
                payable(msg.sender).transfer(nowBalance);
            }
        } else {
            require(msg.value == 0, 'NO ETH');
            for (uint256 i = baseLength; i > 0;) {
                --i;
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, addressList[i], tokenAmountList[i]);
            }
        }
    }

    function transferAmount(
        address[] calldata addressList, 
        uint256 amount,
        address tokenAddress
    ) external payable {
        uint256 baseLength = addressList.length;
        if (tokenAddress == address(0x0)) {
            require(msg.value == baseLength * amount, 'amount wrong');
            for (uint256 i = baseLength; i > 0;) {
                --i;
                payable(addressList[i]).transfer(amount);
            }
        } else {
            require(msg.value == 0, 'NO ETH');
            uint256 totalAmount = amount * baseLength;
            TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), totalAmount);
            for (uint256 i = baseLength; i > 0;) {
                --i;
                TransferHelper.safeTransfer(tokenAddress, addressList[i], amount);
            }
        }
    }
}