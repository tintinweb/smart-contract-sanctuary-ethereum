// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(
            token.transferFrom(from, to, value),
            "SafeERC20: Transfer from failed"
        );
    }
}

contract LinearVesting is Ownable, Pausable {
    using SafeERC20 for IERC20;

    address public immutable tokenAddress;
    uint256 public totalVested;
    uint256 public totalClaimed;
    IERC20 public immutable ERC20Interface;

    struct Vesting {
        uint256 totalAmount;
        uint256 startAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 claimed;
    }

    mapping(address => Vesting) public userVesting;

    event UsersUpdated(address indexed token, uint256 users, uint256 amount);
    event Claimed(address indexed token, address indexed user, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Zero token address");
        tokenAddress = _token;
        ERC20Interface = IERC20(_token);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addUserVesting(
        address _user,
        uint256 _amount,
        uint256 _startAmount,
        uint256 _startTime,
        uint256 _endTime
    ) private {
        require(_user != address(0), "Zero address");
        require(_amount > 0, "Zero amount");
        require(_startAmount <= _amount, "Wrong token values");
        userVesting[_user] = Vesting(
            _amount,
            _startAmount,
            _startTime,
            _endTime,
            0
        );
    }

    function massUpdate(
        address[] calldata _user,
        uint256[] calldata _amount,
        uint256[] calldata _startAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalTokens
    ) external onlyOwner returns (bool) {
        uint256 length = _user.length;
        require(
            length == _amount.length && length == _startAmount.length,
            "Wrong data"
        );
        require(
            _startTime >= block.timestamp && _endTime > _startTime,
            "Invalid timings"
        );

        uint256 total;
        for (uint256 i = 0; i < length; i++) {
            total = total + _amount[i];
        }

        require(total == _totalTokens, "Token amount mismatch");

        for (uint256 j = 0; j < length; j++) {
            addUserVesting(
                _user[j],
                _amount[j],
                _startAmount[j],
                _startTime,
                _endTime
            );
        }

        ERC20Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _totalTokens
        );

        totalVested = totalVested + _totalTokens;

        emit UsersUpdated(tokenAddress, length, total);
        return true;
    }

    function claim() external whenNotPaused returns (bool) {
        uint256 tokens = getClaimableAmount(msg.sender);
        require(tokens > 0, "No claimable tokens available");
        userVesting[msg.sender].claimed =
            userVesting[msg.sender].claimed +
            tokens;
        totalClaimed = totalClaimed + tokens;
        ERC20Interface.safeTransfer(msg.sender, tokens);
        emit Claimed(tokenAddress, msg.sender, tokens);
        return true;
    }

    function getClaimableAmount(
        address _user
    ) public view returns (uint256 claimableAmount) {
        Vesting storage _vesting = userVesting[_user];
        require(_vesting.totalAmount > 0, "No vesting available for user");
        if (_vesting.totalAmount == _vesting.claimed) return 0;

        if (_vesting.startTime > block.timestamp) return 0;

        if (block.timestamp < _vesting.endTime) {
            uint256 timePassedRatio = ((block.timestamp - _vesting.startTime) *
                10 ** 18) / (_vesting.endTime - _vesting.startTime);

            claimableAmount =
                (((_vesting.totalAmount - _vesting.startAmount) *
                    timePassedRatio) / 10 ** 18) +
                _vesting.startAmount;
        } else {
            claimableAmount = _vesting.totalAmount;
        }

        claimableAmount = claimableAmount - _vesting.claimed;
    }
}