// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IApeXPool2.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";

contract ApeXPool2 is IApeXPool2, Ownable {
    address public immutable override apeX;
    address public immutable override esApeX;

    mapping(address => mapping(uint256 => uint256)) public override stakingAPEX;
    mapping(address => mapping(uint256 => uint256)) public override stakingEsAPEX;

    bool public override paused;

    constructor(address _apeX, address _esApeX, address _owner) {
        apeX = _apeX;
        esApeX = _esApeX;
        owner = _owner;
    }

    function setPaused(bool newState) external override onlyOwner {
        require(paused != newState, "same state");
        paused = newState;
        emit PausedStateChanged(newState);
    }

    function stakeAPEX(uint256 accountId, uint256 amount) external override {
        require(!paused, "paused");
        TransferHelper.safeTransferFrom(apeX, msg.sender, address(this), amount);
        stakingAPEX[msg.sender][accountId] += amount;
        emit Staked(apeX, msg.sender, accountId, amount);
    }

    function stakeEsAPEX(uint256 accountId, uint256 amount) external override {
        require(!paused, "paused");
        TransferHelper.safeTransferFrom(esApeX, msg.sender, address(this), amount);
        stakingEsAPEX[msg.sender][accountId] += amount;
        emit Staked(esApeX, msg.sender, accountId, amount);
    }

    function unstakeAPEX(address to, uint256 accountId, uint256 amount) external override {
        require(amount <= stakingAPEX[msg.sender][accountId], "not enough balance");
        stakingAPEX[msg.sender][accountId] -= amount;
        TransferHelper.safeTransfer(apeX, to, amount);
        emit Unstaked(apeX, msg.sender, to, accountId, amount);
    }

    function unstakeEsAPEX(address to, uint256 accountId, uint256 amount) external override {
        require(amount <= stakingEsAPEX[msg.sender][accountId], "not enough balance");
        stakingEsAPEX[msg.sender][accountId] -= amount;
        TransferHelper.safeTransfer(esApeX, to, amount);
        emit Unstaked(esApeX, msg.sender, to, accountId, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IApeXPool2 {
    event PausedStateChanged(bool newState);
    event Staked(address indexed token, address indexed user, uint256 accountId, uint256 amount);
    event Unstaked(address indexed token, address indexed user, address indexed to, uint256 accountId, uint256 amount);

    function apeX() external view returns (address);

    function esApeX() external view returns (address);

    function stakingAPEX(address user, uint256 accountId) external view returns (uint256);

    function stakingEsAPEX(address user, uint256 accountId) external view returns (uint256);

    function paused() external view returns (bool);

    function setPaused(bool newState) external;

    function stakeAPEX(uint256 accountId, uint256 amount) external;

    function stakeEsAPEX(uint256 accountId, uint256 amount) external;

    function unstakeAPEX(address to, uint256 accountId, uint256 amount) external;

    function unstakeEsAPEX(address to, uint256 accountId, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}