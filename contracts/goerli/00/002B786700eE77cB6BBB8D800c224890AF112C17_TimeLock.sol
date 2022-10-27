// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TimeLock {
    event NewLock(
        address token,
        uint256 amount,
        uint256 unlockTime,
        address owner
    );

    event Claim(address token, uint256 amount, address owner);

    struct lock {
        uint256 amount;
        uint64 releaseTime;
    }

    mapping(address => mapping(address => lock)) public locks;

    function lockTokens(
        address _token,
        uint256 amount,
        uint64 duration
    ) external {
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        locks[msg.sender][_token] = lock(
            amount,
            uint64(block.timestamp + duration)
        );
        emit NewLock(
            _token,
            amount,
            uint64(block.timestamp + duration),
            msg.sender
        );
    }

    function unlockTokens(address _token) external {
        require(
            locks[msg.sender][_token].releaseTime <= block.timestamp,
            "TimeLock: Tokens are still locked"
        );
        IERC20(_token).transfer(msg.sender, locks[msg.sender][_token].amount);
        locks[msg.sender][_token] = lock(0, 0);
        emit Claim(_token, locks[msg.sender][_token].amount, msg.sender);
    }

    function getLock(address _token, address _owner)
        external
        view
        returns (lock memory)
    {
        return locks[_owner][_token];
    }
}