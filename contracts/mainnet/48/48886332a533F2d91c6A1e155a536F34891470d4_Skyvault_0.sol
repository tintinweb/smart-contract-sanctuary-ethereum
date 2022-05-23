/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/* ----------------------------------------- Imports ------------------------------------------ */

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/* -------------------------------------- Main Contract --------------------------------------- */

contract Skyvault_0 is Ownable {

    using SafeERC20 for IERC20;

    /* ------------------------------------ State Variables ----------------------------------- */

    IERC20 public immutable skywardToken;
    address public immutable skyRewards;
    bool public poolOpened;
    uint256 public poolOpenedTime;
    uint256 public poolClosedTime;
    uint256 public totalStaked;

    struct staker {
        uint256 owedRewards;
        uint256 stakerBalance;
        uint256 stakeTime;
    }

    mapping (address => staker) public stakers;

    event RewardsCompounded(address staker, uint256 amount);
    event RewardsClaimed(address staker, uint256 amount);
    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);

    /* --------------------------------- Contract Constructor --------------------------------- */

    constructor(address _skywardToken, address _skyRewards) {
        skywardToken = IERC20(_skywardToken); 
        skyRewards = _skyRewards;
        transferOwnership(msg.sender);
    }

    /* ------------------------------- Main Contract Functions -------------------------------- */

    // Claim pending rewards (manual implementation)
    function claimManual() external {
        require(stakers[msg.sender].stakerBalance > 0 || stakers[msg.sender].owedRewards > 0, "Not a staker");
        uint256 rewards = getPendingRewards();
        require(rewards > 0, "No rewards to claim");
        require(rewards <= skywardToken.balanceOf(skyRewards), "Insufficient rewards in rewards pool");

        skywardToken.safeTransferFrom(skyRewards, msg.sender, rewards);
        if (stakers[msg.sender].owedRewards > 0) {
            stakers[msg.sender].owedRewards = 0;
        }
        
        if (poolOpened) {
            stakers[msg.sender].stakeTime = block.timestamp;
        } else {
            stakers[msg.sender].stakeTime = poolClosedTime;
        }

        emit RewardsClaimed(msg.sender, rewards);
    }

    // Compound pending rewards
    function compound() external {
        require(poolOpened, "Staking pool not open");
        require(stakers[msg.sender].stakerBalance > 0, "Not a staker");
        uint256 rewards = getPendingRewards();
        require(rewards > 0, "No rewards to compound");
        require(rewards <= skywardToken.balanceOf(skyRewards), "Insufficient rewards in rewards pool");

        totalStaked += rewards;
        stakers[msg.sender].stakerBalance += rewards;
        stakers[msg.sender].stakeTime = block.timestamp;
        if (stakers[msg.sender].owedRewards > 0) {
            stakers[msg.sender].owedRewards = 0;
        }

        skywardToken.safeTransferFrom(skyRewards, address(this), rewards);
        emit RewardsCompounded(msg.sender, rewards);
    }

    // Stake the specified amount of tokens
    function stake(uint256 _amount) external {
        require(poolOpened, "Staking pool not open");
        require(skywardToken.balanceOf(msg.sender) > 0, "No wallet balance to stake");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= skywardToken.balanceOf(msg.sender), "Amount greater than wallet balance");

        uint256 rewards = getPendingRewards();
        claim(rewards);

        totalStaked += _amount;
        stakers[msg.sender].stakerBalance += _amount;
        stakers[msg.sender].stakeTime = block.timestamp;

        skywardToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    // Unstake the specified amount of tokens
    function unstake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakers[msg.sender].stakerBalance >= _amount, "Amount must be less than or equal to staked balance");

        uint256 rewards = getPendingRewards();
        claim(rewards);
        
        totalStaked -= _amount;
        stakers[msg.sender].stakerBalance -= _amount;
        if (poolOpened) {
            stakers[msg.sender].stakeTime = block.timestamp;
        } else {
            stakers[msg.sender].stakeTime = poolClosedTime;
        }

        uint256 fees = _amount * 5 / 100;
        _amount -= fees;

        skywardToken.safeTransfer(skyRewards, fees);
        skywardToken.safeTransfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    /* ----------------------------------- Owner Functions ------------------------------------ */

    // Open the staking pool
    function openPool() external onlyOwner {
        require(poolOpenedTime == 0, "Staking pool already opened");
        poolOpened = true;
        poolOpenedTime = block.timestamp;
    }

    // Close the staking pool
    function closePool() external onlyOwner {
        require(poolOpened, "Staking pool not open");
        poolOpened = false;
        poolClosedTime = block.timestamp;
    }

    /* ------------------------------- Private Helper Functions ------------------------------- */

    // Claim pending rewards
    function claim(uint256 rewards) private {
        if (rewards > 0) {
            if (rewards > skywardToken.balanceOf(skyRewards)) {
                stakers[msg.sender].owedRewards += rewards - stakers[msg.sender].owedRewards;
            } else {
                skywardToken.safeTransferFrom(skyRewards, msg.sender, rewards);
                if (stakers[msg.sender].owedRewards > 0) {
                    stakers[msg.sender].owedRewards = 0;
                }
            }
        }
    }

    /* -------------------------------- Public View Functions --------------------------------- */

    // Get pending rewards
    function getPendingRewards() public view returns (uint256) { 
        if (poolOpened) {
            return (block.timestamp - stakers[msg.sender].stakeTime) * (getStakerRewardRate() / 86400) + stakers[msg.sender].owedRewards;
        } else {
            return (poolClosedTime - stakers[msg.sender].stakeTime) * (getStakerRewardRate() / 86400) + stakers[msg.sender].owedRewards;
        }
    }

    // Get staked balance
    function getStakerBalance() public view returns (uint256) {
        return stakers[msg.sender].stakerBalance;
    }

    // Get daily reward yield rate
    function getStakerRewardRate() public view returns (uint256) { 
        return stakers[msg.sender].stakerBalance / 100;
    }
}