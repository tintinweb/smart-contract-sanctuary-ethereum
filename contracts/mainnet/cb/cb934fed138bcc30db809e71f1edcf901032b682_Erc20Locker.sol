/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// File: contracts/Ownable.sol

pragma solidity ^0.8.7;

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
// File: contracts/Erc20Locker.sol



//import "hardhat/console.sol";

contract PositionLock {
    address public token;
    uint256 public unlockTime;
    address public locker;

    constructor(
        address token_,
        uint256 unlockTime_,
        address locker_
    ) {
        token = token_;
        unlockTime = unlockTime_;
        locker = locker_;
    }

    function withdraw(address addressToWithdraw) external {
        require(msg.sender == locker, "only for locker");
        require(block.timestamp >= unlockTime, "position locked");

        _withdraw(addressToWithdraw);
    }

    function _withdraw(address addressToWithdraw) internal {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(addressToWithdraw, amount);
    }

    function getUnlockTime() external view returns (uint256) {
        return unlockTime;
    }

    function getToken() external view returns (address) {
        return token;
    }
}

contract Erc20Locker is Ownable {
    mapping(uint256 => address) public positions;
    uint256 public positionsCount;

    event OnLock(
        uint256 indexed positionId,
        address indexed token,
        uint256 amount,
        uint256 unlockTime
    );
    event OnUnlock(
        uint256 indexed positionId,
        address indexed token,
        uint256 amount
    );

    function lock(
        address token,
        uint256 amount,
        uint256 daysCount
    ) external onlyOwner {
        PositionLock lock = new PositionLock(
            token,
            block.timestamp + daysCount * 1 days,
            address(this)
        );
        IERC20(token).transferFrom(msg.sender, address(lock), amount);
        ++positionsCount;
        positions[positionsCount] = address(lock);

        emit OnLock(positionsCount, token, amount, lock.getUnlockTime());
    }

    function unLock(uint256 positionId) external onlyOwner {
        require(positions[positionId] != address(0), "has no position with id");
        PositionLock lock = PositionLock(positions[positionId]);

        uint256 balance = IERC20(lock.getToken()).balanceOf(
            positions[positionId]
        );
        lock.withdraw(msg.sender);
        emit OnUnlock(positionId, lock.getToken(), balance);
    }

    function lapsedMinutes(uint256 positionId) external view returns (uint256) {
        require(positions[positionId] != address(0), "has no position with id");
        PositionLock lock = PositionLock(positions[positionId]);
        if (block.timestamp >= lock.getUnlockTime()) return 0;
        return (lock.getUnlockTime() - block.timestamp) / (1 minutes);
    }
}