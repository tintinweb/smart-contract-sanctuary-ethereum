/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeBEP20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract Staking is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;
    
    bool isStakingStart;
    uint256 public minimumDeposit;
    uint256 public maximumDeposit;
    IBEP20 public stakedToken;
    uint256 public stakedTokenDecimal;

    struct Stake {
        uint256 amount;
        uint256 depositTime;
        uint256 duration;
        uint256 claimedRewards;
    }

    mapping(address => Stake[]) public stakesOfUser;
 
    struct RewardRate {
        uint256 APY;
        uint256 TPS;
    }

    mapping(uint256 => RewardRate) public rewardRates;
    
    constructor() {
        isStakingStart = true;
        stakedToken = IBEP20(0x91Da16198DDB95bfb885FB4Afd37C7E36b9c73aD);
        stakedTokenDecimal = 18;

        minimumDeposit = 100 * 10 ** stakedTokenDecimal;
        maximumDeposit = 100000 * 10 ** stakedTokenDecimal;

        setAPY(2 minutes, 10);
        setAPY(5 minutes, 20);
        setAPY(10 minutes, 40);
        setAPY(20 minutes, 60);
    }

    // =================== Public ===================
    function deposit(uint256 _amount, uint256 _duration) public {
        require(isStakingStart, "Staking is paused right now!");
        
        require(_amount > 0, "Can't stake zero amount!");
        require(rewardRates[_duration].APY != 0, "Invalid duration!");

        require(_amount >= minimumDeposit, "Must stake greater than the minimum deposit!");
        require(_amount <= maximumDeposit, "Must stake less than the maximum deposit!");
        
        // Handle staking
        require(
            stakedToken.allowance(msg.sender, address(this)) >= _amount,
            "Insufficient allowance!"
        );

        stakedToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Handle info storage
        Stake memory _stake;

        _stake.amount = _amount;
        _stake.depositTime = block.timestamp;
        _stake.claimedRewards = 0;
        _stake.duration = _duration;

        stakesOfUser[msg.sender].push(_stake);

        emit Staked(msg.sender, stakesOfUser[msg.sender].length - 1, _amount);
    }
   
    function claim(uint256 _index) public {
        Stake memory _stake = stakesOfUser[msg.sender][_index];
        require(_stake.amount > 0, "There is no such stake!");

        require(block.timestamp > _stake.depositTime.add(_stake.duration), "Can't withdraw before the withdrawal time!");

        uint256 reward = calculateReward(msg.sender, _index);
        uint256 claimableRewards = reward.sub(_stake.claimedRewards);

        stakedToken.safeTransfer(msg.sender, _stake.amount);
        stakedToken.safeTransfer(msg.sender, claimableRewards);

        stakesOfUser[msg.sender][_index] = stakesOfUser[msg.sender][stakesOfUser[msg.sender].length - 1];
        stakesOfUser[msg.sender].pop();

        emit Claimed(msg.sender, _index, _stake.amount, claimableRewards);
    }


    function claimMonthlyRewards(uint256 _index) external {
        Stake memory _stake = stakesOfUser[msg.sender][_index];
        require(_stake.amount > 0, "There is no such stake!");

        uint256 wholeMonths = ((block.timestamp).sub(_stake.depositTime)).div(30 days);
        
        uint256 reward = (_stake.amount)
            .mul(rewardRates[_stake.duration].TPS)
            .mul(wholeMonths * 30 days)
            .div(1e18);

        uint256 claimableRewards = reward.sub(_stake.claimedRewards);

        if(claimableRewards == 0) {
            revert("Zero rewards claimable currently.");
        }
        
        stakedToken.safeTransfer(msg.sender, claimableRewards);

        stakesOfUser[msg.sender][_index].claimedRewards += claimableRewards;

        emit RewardClaimed(msg.sender, _index, claimableRewards);
    }


    // =================== Getters ===================
    function calculateReward(address _userAddress, uint256 _index) public view returns (uint256) {
        Stake memory _stake = stakesOfUser[_userAddress][_index];
        
        uint256 timeDiff = (block.timestamp).sub(_stake.depositTime);

        uint256 reward = (_stake.amount).mul(rewardRates[_stake.duration].TPS).mul(timeDiff).div(1e18);

        return reward;
    }

    function stakesListOfUser(address _userAddress) external view returns (Stake[] memory) {
        uint256 l = stakesOfUser[_userAddress].length;
        Stake[] memory tStakeList = new Stake[](l);
        for (uint256 i = 0; i < l; i++) {
            tStakeList[i] = stakesOfUser[_userAddress][i];
        }
        return tStakeList;
    }

    // =================== Admin ===================
    function setStakingStatus(bool _newStatus) public onlyOwner {
        isStakingStart = _newStatus;
    }

    function setAPY(uint256 _duration, uint256 _APY) public onlyOwner {
        RewardRate memory tRewardRate;
        
        tRewardRate.APY = _APY;
        tRewardRate.TPS = (_APY.mul(1e18)).div(365 days * 100);
        
        rewardRates[_duration] = tRewardRate;
    }

    function setDepositLimits(uint256 _minimumAmount, uint256 _maximumAmount) public onlyOwner {
        minimumDeposit = _minimumAmount;
        maximumDeposit = _maximumAmount;
    }

    function withdrawBNB(uint256 _amount, address _to) external onlyOwner {
        payable(_to).transfer(_amount);
    }

    function withdrawTokens(IBEP20 _wsToken, uint256 _amount, address _to) external onlyOwner {
        _wsToken.transfer(_to, _amount);
    }
    // =================== Admin End ===================

    // =================== Events ===================
    event Staked(address indexed userAddress, uint256 indexed index, uint256 amount);
    event Claimed(address indexed userAddress, uint256 indexed index, uint256 stakeAmount, uint256 rewardAmount);
    event RewardClaimed(address indexed userAddress, uint256 indexed index, uint256 rewardAmount);
}