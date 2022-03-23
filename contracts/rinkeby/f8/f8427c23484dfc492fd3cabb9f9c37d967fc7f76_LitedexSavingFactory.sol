/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `BEP20Detailed`.
 */

interface IBEP20 {
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.9;

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

library SafeBEP20 {
    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

pragma solidity 0.8.9;

contract LitedexSaving is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /**
     *  @dev Structs to store user staking data.
     */
    struct Deposits {
        uint256 depositAmount;
        uint256 depositTime;
        uint256 endTime;
        uint64 userIndex;
        uint256 rewards;
        bool paid;
    }

    /**
     *  @dev Structs to store interest rate change.
     */
    struct Rates {
        uint64 interestRate;
        uint256 timeStamp;
    }

    mapping(address => Deposits) private deposits;
    mapping(uint64 => Rates) public rates;
    mapping(address => bool) private hasStaked;

    address public tokenAddress;
    uint256 public stakedBalance;
    uint256 public rewardBalance;
    uint256 public stakedTotal;
    uint256 public totalReward;
    uint64 private index;
    uint64 public rate;
    uint256 public lockDuration;
    string private name;
    uint256 public totalParticipants;
    bool public isStopped;
    uint256 public constant interestRateConverter = 10000;
    uint256 public limitPerUser;

    bool private isInitialized;

    // The address of the smart stake factory
    address private SAVING_FACTORY;

    /**
     *  @dev Emitted when user stakes 'stakedAmount' value of tokens
     */
    event Staked(
        address indexed token,
        address indexed staker,
        uint256 stakedAmount
    );

    /**
     *  @dev Emitted when user withdraws his stakings
     */
    event PaidOut(
        address indexed token,
        address indexed staker,
        uint256 amount,
        uint256 reward
    );

    event RateAndLockduration(
        uint64 index,
        uint64 newRate,
        uint256 lockDuration,
        uint256 time
    );

    event RewardsAdded(uint256 rewards, uint256 time);

    event StakingStopped(bool status, uint256 time);

    constructor() {
        SAVING_FACTORY = msg.sender;
    }
    /**
     *   @param
     *   _name          : name of the contract
     *   _tokenAddress  : contract address of the token
     *   _rate          : rate multiplied by 100
     *   _lockduration  : duration in hours
     *   _admin         : owner contract
     */
    function initialize(
        string memory _name,
        address _tokenAddress,
        uint64 _rate,
        uint256 _lockDuration,
        address _admin
    ) external {
        require(!isInitialized, "Litedex: already initialized");
        require(msg.sender == SAVING_FACTORY, "Litedex: not factory");

        // Make this contract initialized
        isInitialized = true;
        name = _name;
        require(_tokenAddress != address(0), "Zero token address");

        tokenAddress = _tokenAddress;
        lockDuration = _lockDuration;

        require(_rate != 0, "Zero interest rate");
        rate = _rate;
        rates[index] = Rates(rate, block.timestamp);

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    function getContractName() external view returns(string memory){
        return name;
    }
    function currentIndex() external view returns(uint64) {
        return index;
    }
    function FACTORY_ADDRESS() external view returns(address){
        return SAVING_FACTORY;
    }

    /**
     *  Requirements:
     *  `_rate`         : New effective interest rate multiplied by 100
     *  @dev to set interest rates
     *  `_lockduration' : lock hours
     *  @dev to set lock duration hours
     */
    function setRnL(uint64 _rate, uint256 _lockduration) external onlyOwner {
        require(_rate != 0, "Litedex: interest rate is 0");
        require(_lockduration != 0, "Litedex: lock duration is 0");
        rate = _rate;
        index++;
        rates[index] = Rates(_rate, block.timestamp);
        lockDuration = _lockduration;
        emit RateAndLockduration(index, _rate, _lockduration, block.timestamp);
    }

    function setStakingStatus(bool _status) external onlyOwner {
        isStopped = _status;
        emit StakingStopped(_status, block.timestamp);
    }

    /**
     *  Requirements:
     *  `rewardAmount` rewards to be added to the staking contract
     *  @dev to add rewards to the staking contract
     *  once the allowance is given to this contract for 'rewardAmount' by the user
     */
    function addReward(uint256 _rewardAmount) external onlyOwner _hasAllowance(msg.sender, _rewardAmount) returns (bool) {
        require(_rewardAmount > 0, "Reward must be positive");
        totalReward = totalReward.add(_rewardAmount);
        rewardBalance = rewardBalance.add(_rewardAmount);
        if (!_payMe(msg.sender, _rewardAmount)) {
            return false;
        }
        emit RewardsAdded(_rewardAmount, block.timestamp);
        return true;
    }

    /**
     *  Requirements:
     *  `user` User wallet address
     *  @dev returns user staking data
     */
    function userDeposits(address user) external view 
        returns (
            uint256 depositAmount,
            uint256 depositTime,
            uint256 endTime,
            uint256 userIndex,
            uint256 rewards,
            bool paid
        )
    {
        if (hasStaked[user]) {
            return (
                deposits[user].depositAmount,
                deposits[user].depositTime,
                deposits[user].endTime,
                deposits[user].userIndex,
                deposits[user].rewards,
                deposits[user].paid
            );
        } else {
            return (0, 0, 0, 0, 0, false);
        }
    }

    function setLimitPerUser(uint256 _limit) external onlyOwner returns(bool){
        limitPerUser = _limit;
        return true;
    }

    /**
     *  Requirements:
     *  `amount` Amount to be staked
     /**
     *  @dev to stake 'amount' value of tokens 
     *  once the user has given allowance to the staking contract
     */

    function stake(uint256 _amount) external _hasAllowance(msg.sender, _amount) returns (bool) {
        require(_amount > 0, "Litedex: can't stake 0 amount");
        require(!isStopped, "Litedex: staking paused");
        _amount = _checkUserLimit(msg.sender, _amount);
        require(_amount > 0, "Litedex: user has reached limit");
        return (_stake(msg.sender, _amount));
    }

    function _checkUserLimit(address _account, uint256 _amount) private view returns (uint256) {
        if(limitPerUser > 0){
            (uint256 _userAmount) = deposits[_account].depositAmount;
            _amount = _amount.sub(_userAmount);
        }
        return _amount;
    }

    function _stake(address _account, uint256 amount) private returns (bool) {
        if (!hasStaked[_account]) {
            hasStaked[_account] = true;

            deposits[_account] = Deposits(
                amount,
                block.timestamp,
                block.timestamp.add((lockDuration.mul(3600))),
                index,
                0,
                false
            );
            totalParticipants = totalParticipants.add(1);
        } else {
            require(block.timestamp < deposits[_account].endTime, "Lock expired, please withdraw and stake again");
            uint256 newAmount = deposits[_account].depositAmount.add(amount);
            uint256 rewards = _calculate(_account, block.timestamp).add(deposits[_account].rewards);
            deposits[_account] = Deposits(
                newAmount,
                block.timestamp,
                block.timestamp.add((lockDuration.mul(3600))),
                index,
                rewards,
                false
            );
        }
        stakedBalance = stakedBalance.add(amount);
        stakedTotal = stakedTotal.add(amount);
        require(_payMe(_account, amount), "Litedex: Payment failed");
        emit Staked(tokenAddress, _account, amount);

        return true;
    }

    /**
     * @dev to withdraw user stakings after the lock period ends.
     */
    function withdraw() external _withdrawCheck(msg.sender) returns (bool) {
        return (_withdraw(msg.sender));
    }

    function _withdraw(address _account) private returns (bool) {
        uint256 _reward = _calculate(_account, deposits[_account].endTime);
        _reward = _reward.add(deposits[_account].rewards);
        uint256 _amount = deposits[_account].depositAmount;

        require(_reward <= rewardBalance, "Not enough rewards");

        stakedBalance = stakedBalance.sub(_amount);
        rewardBalance = rewardBalance.sub(_reward);
        deposits[_account].paid = true;
        hasStaked[_account] = false;
        totalParticipants = totalParticipants.sub(1);

        if (_payDirect(_account, _amount.add(_reward))) {
            emit PaidOut(tokenAddress, _account, _amount, _reward);
            return true;
        }
        return false;
    }

    function emergencyWithdraw() external _withdrawCheck(msg.sender) returns (bool) {
        return (_emergencyWithdraw(msg.sender));
    }

    function _emergencyWithdraw(address _account) private returns (bool) {
        uint256 _amount = deposits[_account].depositAmount;
        stakedBalance = stakedBalance.sub(_amount);
        deposits[_account].paid = true;
        hasStaked[_account] = false; //Check-Effects-Interactions pattern
        totalParticipants = totalParticipants.sub(1);

        bool _principalPaid = _payDirect(_account, _amount);
        require(_principalPaid, "Litedex: Error paying");
        emit PaidOut(tokenAddress, _account, _amount, 0);

        return true;
    }

    /**
     *  Requirements:
     *  `_account` User wallet address
     * @dev to calculate the rewards based on user staked 'amount'
     * 'userIndex' - the index of the interest rate at the time of user stake.
     * 'depositTime' - time of staking
     */
    function calculate(address _account) external view returns (uint256) {
        return _calculate(_account, deposits[_account].endTime);
    }

    function _calculate(address _account, uint256 _endTime) private view returns (uint256) {
        if (!hasStaked[_account]) return 0;
        (uint256 _amount, uint256 _depositTime, uint64 _userIndex) = (
            deposits[_account].depositAmount,
            deposits[_account].depositTime,
            deposits[_account].userIndex
        );

        uint256 _time;
        uint256 _interest;
        uint256 _lockduration = deposits[_account].endTime.sub(_depositTime);
        for (uint64 i = _userIndex; i < index; i++) {
            //loop runs till the latest index/interest rate change
            if (_endTime < rates[i + 1].timeStamp) {
                //if the change occurs after the endTime loop breaks
                break;
            } else {
                _time = rates[i + 1].timeStamp.sub(_depositTime);
                _interest = _amount.mul(rates[i].interestRate).mul(_time).div(
                    _lockduration.mul(interestRateConverter)
                );
                _amount = _amount.add(_interest);
                _depositTime = rates[i + 1].timeStamp;
                _userIndex++;
            }
        }

        if (_depositTime < _endTime) {
            //final calculation for the remaining time period
            _time = _endTime.sub(_depositTime);

            _interest = _time
                .mul(_amount)
                .mul(rates[_userIndex].interestRate)
                .div(_lockduration.mul(interestRateConverter));
        }

        return (_interest);
    }
    function pendingReward(address _account) external view returns(uint256) {
        uint256 _interest = _calculate(_account, deposits[_account].endTime);
        (uint256 _depositTime, uint256 _endTime) = (
            deposits[_account].depositTime,
            deposits[_account].endTime
        );
        uint256 _interestPerSecond = _interest.div(lockDuration.mul(1 hours));

        if(block.timestamp < _endTime){
            uint256 _range = block.timestamp.sub(_depositTime);
            return (_range * _interestPerSecond);
        }else{
            return (_interest);
        }
    }

    function _payMe(address _payer, uint256 _amount) private returns (bool) {
        return _payTo(_payer, address(this), _amount);
    }

    function _payTo(
        address _allower,
        address _receiver,
        uint256 _amount
    ) private _hasAllowance(_allower, _amount) returns (bool) {
        IBEP20 BEP20Interface = IBEP20(tokenAddress);
        BEP20Interface.safeTransferFrom(_allower, _receiver, _amount);
        return true;
    }

    function _payDirect(address _to, uint256 _amount) private returns (bool) {
        IBEP20 BEP20Interface = IBEP20(tokenAddress);
        BEP20Interface.safeTransfer(_to, _amount);
        return true;
    }

    modifier _withdrawCheck(address _account) {
        require(hasStaked[_account], "Litedex: No stakes found for user");
        require(
            block.timestamp >= deposits[_account].endTime,
            "Litedex: requesting before lock time"
        );
        _;
    }

    modifier _hasAllowance(address _allower, uint256 _amount) {
        // Make sure the allower has provided the right allowance.
        IBEP20 BEP20Interface = IBEP20(tokenAddress);
        uint256 _ourAllowance = BEP20Interface.allowance(_allower, address(this));
        require(_amount <= _ourAllowance, "Litedex: Make sure to add enough allowance");
        _;
    }
}
// File: contracts/LitedexSavingFactory.sol

pragma solidity 0.8.9;

contract LitedexSavingFactory is Ownable {
    event NewSavingContract(address indexed saving);

    function deploySaving(
        string memory _name,
        address _tokenAddress,
        uint64 _rate,
        uint256 _lockDuration,
        address _admin
    ) external onlyOwner {
        require(IBEP20(_tokenAddress).totalSupply() >= 0);

        bytes memory bytecode = type(LitedexSaving).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_tokenAddress, _rate, _lockDuration));
        address savingAddress;

        assembly {
            savingAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        LitedexSaving(savingAddress).initialize(
            _name,
            _tokenAddress,
            _rate,
            _lockDuration,
            _admin
        );

        emit NewSavingContract(savingAddress);
    }
}