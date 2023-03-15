/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;


/**
 * IERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


interface IERC20Permit {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
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

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


contract Furr_Stake is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;

    uint public duration = 30 days;
    uint public minimumStake = 0;
    uint public finishAt;
    uint public updatedAt;
    uint public rewardRate;
    uint public rewardPerTokenStored;
    uint public earlyWithdrawalFee = 0;
    uint public earlyWithdrawalFeesCollected = 0;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => bool) public hasMetMinimum;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    event Stake(address indexed user, uint256 amount);
    event Rewarded(address indexed user, uint256 amount);
    event WithdrawStaked(address indexed user, uint256 amount);
    event RewardAmountAdded(uint256 amount);

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    constructor(address _stakingToken, address _rewardToken) {

        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
	    require(finishAt < block.timestamp, "reward duration not finished");
	    duration = _duration;
    }

    function startPool(uint _amount) external onlyOwner updateReward(address(0)){
	    if(block.timestamp > finishAt) { 
	        rewardRate = _amount / duration; 
            rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
	    } else {
	        uint remainingRewards = rewardRate * (finishAt - block.timestamp);
	        rewardRate = (remainingRewards + _amount) / duration;
            rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
	}

	    require(rewardRate > 0, "Reward rate = 0");
	    require(rewardRate * duration <= rewardToken.balanceOf(address(this)),"Reward amount > balance");

	    finishAt = block.timestamp + duration;
	    updatedAt = block.timestamp;

        emit RewardAmountAdded(_amount);
    }

    function addRewardFunds(uint _amount) external onlyOwner updateReward(address(0)) {
        require(block.timestamp < finishAt, "Pool no longer active, restart");

	    uint remainingRewards = rewardRate * (finishAt - block.timestamp);
	    rewardRate = (remainingRewards + _amount) / duration;
        rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);

	    require(rewardRate > 0, "Reward rate = 0");
	    require(rewardRate * duration <= rewardToken.balanceOf(address(this)),"Reward amount > balance");

	    updatedAt = block.timestamp;

        emit RewardAmountAdded(_amount);
    }

    function emergencyEndPool() external onlyOwner updateReward(address(0)) {
        require(block.timestamp <= finishAt, "Pool no longer active");

        updatedAt = block.timestamp;
        finishAt = block.timestamp;
    }

    function changeMinimumStake(uint _newMinimum) external onlyOwner {
        minimumStake = _newMinimum;
    }

    function stake(uint _amount) external updateReward(msg.sender) nonReentrant {
        require(_amount > 0, "amount = 0");
        if(_amount < minimumStake) { require(hasMetMinimum[msg.sender] == true); }
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        if(!hasMetMinimum[msg.sender]) { hasMetMinimum[msg.sender] = true; }

        emit Stake(msg.sender, _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) nonReentrant {
        require(_amount > 0, "amount = 0");
        require(block.timestamp > finishAt);
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.safeTransfer(msg.sender, _amount);

        emit WithdrawStaked(msg.sender, _amount);
    }

    function emergencyWithdrawal(uint _amount) external updateReward(msg.sender) nonReentrant {
        require(_amount > 0, "amount = 0");
	    uint fee = _amount * earlyWithdrawalFee / 100;
	    uint finalAmountAfterFee = _amount - fee;

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.safeTransfer(msg.sender, finalAmountAfterFee);
	    earlyWithdrawalFeesCollected += fee;

        emit WithdrawStaked(msg.sender, _amount);
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(block.timestamp, finishAt);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (rewardRate * 
            (lastTimeRewardApplicable() - updatedAt) * 1e18
        ) / totalSupply;
    }

    function earned(address _account) public view returns (uint) {
        return (balanceOf[_account] * 
            (rewardPerToken() - userRewardPerTokenPaid[_account]))
            / 1e18 + rewards[_account]; 
    }
    function getReward() external updateReward(msg.sender) nonReentrant {
        uint reward = rewards[msg.sender];
            if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
        }
        emit Rewarded(msg.sender, reward);
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function collectWithdrawalFees() external onlyOwner {
	    require(earlyWithdrawalFeesCollected > 0, "No Fees Collected");
	    uint _fees = earlyWithdrawalFeesCollected;
	    earlyWithdrawalFeesCollected = 0;

	    stakingToken.safeTransfer(msg.sender, _fees);
    }

    function clearStuckETH() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0){          
            payable(owner()).transfer(contractETHBalance);
        }
    }

    function clearStuckTokens(address contractAddress) external onlyOwner {
        if (IERC20(contractAddress) == IERC20(rewardToken)) { require(block.timestamp > finishAt, "Staking Period Not Complete"); }
        if (IERC20(contractAddress) == IERC20(stakingToken)) { require(block.timestamp > finishAt, "Staking Period Not Complete"); }
        IERC20 stuckTokens = IERC20(contractAddress);
        uint256 balance = stuckTokens.balanceOf(address(this));
        stuckTokens.safeTransfer(owner(), balance);
    }

}