//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libraries/EquitoHelper.sol";

contract ERC20Vault {
    address _currency;
    address public owner;
    uint256 public erc20Balance;
    uint256 public usdcBalance;
    uint256 public userCount;

    event LockERC20(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        uint256 amount
    );
    event ReleaseERC20(address indexed erc20Addr, uint256 amount);
    event LockUSDC(
        address indexed erc20Addr,
        string destNetwork,
        string walletAddr,
        uint256 amount
    );
    event ReleaseUSDC(address indexed erc20Addr, uint256 amount);

    constructor() {
        _currency = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        owner = msg.sender;
    }

    function lockERC20(string calldata destNetwork, string calldata algoAddr)
        external
        payable
        returns (uint256 id)
    {
        require(msg.value > 1000000000, "Sending amount is too small!");

        erc20Balance += msg.value;
        userCount++;

        emit LockERC20(msg.sender, destNetwork, algoAddr, msg.value);

        return userCount;
    }

    function releaseERC20(address erc20Addr, uint256 amount) external {
        require(msg.sender == owner, "You are not the owner!");

        require(erc20Balance > 0, "Balance is zero!");
        require(erc20Balance >= amount, "Balance is not enough to withdraw!");

        (bool sent, ) = erc20Addr.call{value: amount}("");
        require(sent, "Failed to send ERC20!");

        erc20Balance -= amount;

        emit ReleaseERC20(msg.sender, amount);
    }

    function lockUSDC(
        uint256 amount,
        string calldata destNetwork,
        string calldata algoAddr
    ) external returns (uint256 id) {
        EquitoHelper.safeTransferFrom(
            _currency,
            msg.sender,
            address(this),
            amount
        );

        userCount++;

        emit LockUSDC(msg.sender, destNetwork, algoAddr, amount);

        return userCount;
    }

    function releaseUSDC(address erc20Addr, uint256 amount) external {
        require(msg.sender == owner, "You are not the owner!");

        require(usdcBalance > 0, "Balance is zero!");
        require(usdcBalance >= amount, "Balance is not enough to withdraw!");

        (bool sent, ) = erc20Addr.call{value: amount}("");
        require(sent, "Failed to send ERC20!");

        usdcBalance -= amount;

        emit ReleaseERC20(msg.sender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

library EquitoHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "EquitoHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "EquitoHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "EquitoHelper::safeTransferETH: ETH transfer failed");
    }

    function safeTransferAsset(
        address token,
        address to,
        uint256 value
    ) internal {
        if (token == address(0)) {
            safeTransferETH(to, value);
        } else {
            safeTransfer(token, to, value);
        }
    }
}