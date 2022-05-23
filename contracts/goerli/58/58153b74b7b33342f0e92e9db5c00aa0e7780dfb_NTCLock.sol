pragma solidity >=0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";

contract NTCLock {
    using SafeMath for uint256;

    struct Lock {
        address user;
        uint256 amount;
    }

    mapping(address => uint256) private addressLockIndex;
    Lock[] public lockList;

    // 总锁仓数量
    uint256 public totalLockAmount;

    // LP地址
    // address lpAddress = address(0xE4bc4F428688CeB50864c2b4734Cf74E08ca45a3);

    event AddLock(address indexed owner, uint256 amount);
    event RemoveLock(address indexed owner, uint256 amount);

    function lockLength() public view returns (uint256) {
        return lockList.length;
    }

    //這個鎖倉 沒有真的transferFrom (先不考慮這方式)
    function addLockWithoutTransfer(uint256 amount) public {
        address sender = msg.sender;

        uint256 index = addressLockIndex[sender];
        if (index == 0) {
            lockList.push(Lock({user: sender, amount: amount}));
            addressLockIndex[sender] = lockList.length;
        } else {
            Lock storage lock = lockList[index - 1];
            lock.amount = lock.amount.add(amount);
        }

        totalLockAmount = totalLockAmount.add(amount);
    }

    function addLock(address lp, uint256 amount) public {
        address sender = msg.sender;
        // 转移
        require(IERC20(lp).transferFrom(sender, address(this), amount));

        uint256 index = addressLockIndex[sender];
        if (index == 0) {
            lockList.push(Lock({user: sender, amount: amount}));
            addressLockIndex[sender] = lockList.length;
        } else {
            Lock storage lock = lockList[index - 1];
            lock.amount = lock.amount.add(amount);
        }

        totalLockAmount = totalLockAmount.add(amount);
    }

    function removeLock(address lp, uint256 amount) public {
        address sender = msg.sender;

        uint256 index = addressLockIndex[sender];
        require(index > 0);
        Lock storage lock = lockList[index - 1];
        require(lock.amount >= amount);

        require(IERC20(lp).transfer(sender, amount));

        lock.amount = lock.amount.sub(amount);
        totalLockAmount = totalLockAmount.sub(amount);
    }
}