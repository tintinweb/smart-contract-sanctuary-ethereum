/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract Vesting {
    uint256 public lock;
    address public owner;

    struct Vest {
        address token;
        uint256 amount;
        address owner;
        address receiver;
        uint256 startTime;
        uint256 endTime;
        uint256 claimed;
    }

    mapping(uint256 => Vest) public vesting;

    event LockCreated(
        uint256 indexed _id,
        address indexed _token,
        uint256 _amount,
        address indexed _owner,
        address _receiver,
        uint256 _startTime,
        uint256 _endTime
    );

    event TokensClaimed(
        uint256 indexed _id,
        address indexed _token,
        address indexed _receiver,
        uint256 _claimedAmount
    );

    event ReceiverUpdated(
        address prevValue,
        address newValue,
        uint256 timestamp
    );

    constructor(address _owner) {
        require(_owner != address(0), "Zero address");
        owner = _owner;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Zero address");
        owner = _newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function createLock(
        address _token,
        uint256 _amount,
        address _receiver,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner returns (bool) {
        require(
            _token != address(0) && _receiver != address(0),
            "Zero address"
        );
        require(_amount > 0, "Zero amount");
        require(
            _startTime > block.timestamp && _endTime > _startTime,
            "Invalid time"
        );
        IERC20 ERC20Interface = IERC20(_token);
        lock++;
        vesting[lock] = Vest(
            _token,
            _amount,
            msg.sender,
            _receiver,
            _startTime,
            _endTime,
            0
        );

        require(
            ERC20Interface.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        emit LockCreated(
            lock,
            _token,
            _amount,
            msg.sender,
            _receiver,
            _startTime,
            _endTime
        );
        return true;
    }

    function getClaimableAmount(uint256 _lock) public view returns (uint256) {
        require(_lock > 0 && _lock <= lock, "Invalid lock id");
        Vest memory _vest = vesting[_lock];
        if (_vest.amount == _vest.claimed) return 0;

        if (block.timestamp <= _vest.startTime) return 0;

        if (block.timestamp >= _vest.endTime)
            return _vest.amount - _vest.claimed;

        uint256 timePassedRatio = ((block.timestamp - _vest.startTime) *
            10**18) / (_vest.endTime - _vest.startTime);

        uint256 claimableAmount = (_vest.amount * timePassedRatio) / (10**18);

        return claimableAmount - _vest.claimed;
    }

    function claim(uint256 _lock) external onlyOwner returns (bool) {
        uint256 claimableAmount = getClaimableAmount(_lock);
        require(claimableAmount > 0, "Zero claimable amount");

        vesting[_lock].claimed += claimableAmount;
        require(
            IERC20(vesting[_lock].token).transfer(
                vesting[_lock].receiver,
                claimableAmount
            )
        );
        emit TokensClaimed(
            _lock,
            vesting[_lock].token,
            vesting[_lock].receiver,
            claimableAmount
        );
        return true;
    }

    function changeReceiver(uint256 _lock, address user)
        external
        onlyOwner
        returns (bool)
    {
        require(_lock > 0 && _lock <= lock, "Invalid lock id");
        require(user != address(0), "Zero receiver address");
        address prevValue = vesting[_lock].receiver;
        vesting[_lock].receiver = user;
        emit ReceiverUpdated(prevValue, user, block.timestamp);
        return true;
    }
}