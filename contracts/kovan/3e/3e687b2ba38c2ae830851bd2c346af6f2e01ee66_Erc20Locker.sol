/**
 *Submitted for verification at Etherscan.io on 2022-08-16
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




struct LockPosition {
    address token;
    uint256 amount;
    uint256 unlockTime;
    bool isActive;
}

contract Erc20Locker is Ownable {
    mapping(uint256 => LockPosition) public positions;
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
        uint256 amount,
        uint256 unlockTime
    );

    function Lock(
        address token,
        uint256 amount,
        uint256 daysCount
    ) external onlyOwner {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        ++positionsCount;
        positions[positionsCount].token = token;
        positions[positionsCount].amount = amount;
        positions[positionsCount].unlockTime =
            block.timestamp +
            daysCount *
            1 minutes;
        positions[positionsCount].isActive = true;

        emit OnLock(
            positionsCount,
            token,
            amount,
            positions[positionsCount].unlockTime
        );
    }

    function UnLock(uint256 positionId) external onlyOwner {
        require(positions[positionId].isActive, "position is not active");
        require(
            positions[positionId].unlockTime >= block.timestamp,
            "position locked"
        );

        IERC20(positions[positionId].token).transferFrom(
            address(this),
            msg.sender,
            positions[positionId].amount
        );
        positions[positionId].isActive = false;

        emit OnUnlock(
            positionId,
            positions[positionId].token,
            positions[positionId].amount,
            positions[positionId].unlockTime
        );
    }

    function lapsedMinutes(uint256 positionId) external view returns (uint256) {
        if (block.timestamp > positions[positionId].unlockTime) return 0;
        return
            (positions[positionId].unlockTime - block.timestamp) /
            (1 minutes);
    }
}