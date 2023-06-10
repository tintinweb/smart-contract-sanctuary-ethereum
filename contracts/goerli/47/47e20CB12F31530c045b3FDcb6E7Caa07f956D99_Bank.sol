// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IUSD {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Bank {
    address public governance;
    address public pendingGovernance;
    address public operator;
    uint256 public effectTime;

    constructor(address operator_) {
        governance = msg.sender;
        operator = operator_;
        effectTime = block.timestamp + 180 days;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pendingGovernance");
        governance = msg.sender;
        pendingGovernance = address(0);
    }
    function setPendingGovernance(address pendingGovernance_) external {
        require(msg.sender == governance, "!governance");
        pendingGovernance = pendingGovernance_;
    }

    function setOperator(address operator_) external {
        require(msg.sender == governance, "!governance");
        require(block.timestamp > effectTime, "!effectTime");
        operator = operator_;
    }

    function totalAssets(address USD_) external view returns (uint256) {
        return  IUSD(USD_).balanceOf(address(this));
    }

    function withdraw(address USD_, address recipient_, uint256 amount_) external {
        require(msg.sender == operator, "!operator");
        IUSD(USD_).transfer(recipient_, amount_);
    }

    function sweepGuardian(address token_) external {
        require(msg.sender == governance, "!guardian");
        require(block.timestamp > effectTime, "!effectTime");

        uint256 _balance = IUSD(token_).balanceOf(address(this));
        IUSD(token_).transfer(governance, _balance);
    }
}