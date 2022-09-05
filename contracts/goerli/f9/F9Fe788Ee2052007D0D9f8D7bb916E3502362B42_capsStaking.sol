// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/* Note:- This Contract Is Under Development */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burnTokens(uint256 amount) external;
}

contract capsStaking is Ownable {
    event Stacked(address indexed by, uint stackCount, uint amount, uint at);
    event WithdrawReward(address indexed by, uint amount, uint at);
    event Claimed(
        address indexed by,
        uint tokenAmount,
        uint rewardAmount,
        uint at
    );

    struct User {
        uint totalStakes;
        uint totalWithdrawableReward;
        uint claimFrom;
        uint rewardFrom;
        bool isActiveUser;
        mapping(uint => uint) stackedAt;
        mapping(uint => uint) rewardPerStake;
        mapping(uint => uint) amountStaked;
    }

    struct stackData {
        uint stackNum;
        uint amount;
        uint at;
    }

    struct RewardHistory {
        uint rewardAmount;
        uint totalStackedTokens;
    }

    mapping(address => User) private usersData;
    mapping(uint => RewardHistory) public rewardHistory;
    address[] private activeStakers;
    uint private totalStakedAmount;
    uint private availableRewards;
    uint public maxDataFetchSizeLimit = 20;
    uint public claimTime = 10 days;
    uint public totalRewardCount;
    IERC20 private capsTokenContract_Ins;

    constructor(address _capsTokenContract) {
        capsTokenContract_Ins = IERC20(_capsTokenContract);
    }

    function stake(uint amount) external returns (bool) {
        require(amount > 0, "Amount Should Be Greater Than Zero");
        address msgSender = msg.sender;
        require(
            capsTokenContract_Ins.allowance(msgSender, address(this)) >= amount,
            "Please Provide Allowance To 'CAPsStakingPool' Contract"
        );
        capsTokenContract_Ins.transferFrom(msgSender, address(this), amount);
        totalStakedAmount += amount;
        uint curStakCount = usersData[msgSender].totalStakes + 1;
        uint curTime = block.timestamp;
        User storage tempUserData = usersData[msgSender];

        if (tempUserData.claimFrom == 0) {
            tempUserData.claimFrom = 1;
            tempUserData.isActiveUser = true;
        } else {
            usersData[msgSender].rewardPerStake[
                curStakCount - 1
            ] = calculateRewardPerStack(msgSender);
        }

        if (availableRewards != 0) {
            tempUserData.rewardPerStake[curStakCount] = availableRewards;
            availableRewards = 0;
        }
        tempUserData.rewardFrom = totalRewardCount + 1;

        tempUserData.totalStakes = curStakCount;
        tempUserData.amountStaked[curStakCount] = amount;
        tempUserData.stackedAt[curStakCount] = curTime;

        emit Stacked(msgSender, curStakCount, amount, curTime);
        return true;
    }

    function claimRewards() external {
        address msgSender = msg.sender;
        User storage tempUserData = usersData[msgSender];
        (
            uint _withdrawableReward,
            uint _claimableTokens,
            uint _claimFrom
        ) = getClaimableRewardAndTokens(msgSender);
        require(_claimFrom != 0, "Nothing To Claim");
        totalStakedAmount -= _claimableTokens;
        tempUserData.totalWithdrawableReward += _withdrawableReward;
        tempUserData.claimFrom = _claimFrom;
        tempUserData.rewardFrom = totalRewardCount + 1;
        capsTokenContract_Ins.burnTokens(_claimableTokens);
        emit Claimed(
            msgSender,
            _claimableTokens,
            _withdrawableReward,
            block.timestamp
        );
    }

    function withdrawReward(uint amount) external {
        address msgSender = msg.sender;
        require(
            amount <= usersData[msgSender].totalWithdrawableReward,
            "Entered Amount Is More Than Your Balance"
        );
        usersData[msgSender].totalWithdrawableReward -= amount;
        payable(msgSender).transfer(amount);
        emit WithdrawReward(msgSender, amount, block.timestamp);
    }

    function notifyReward() external payable {
        uint msgValue = msg.value;
        if (msgValue > 0) {
            totalRewardCount++;
            if (totalStakedAmount == 0) {
                availableRewards += msgValue;
            }
            rewardHistory[totalRewardCount] = RewardHistory(
                msgValue,
                totalStakedAmount
            );
        }
    }

    /********** Setter Functions **********/

    function setClaimTime(uint newTime) external onlyOwner {
        claimTime = newTime;
    }

    function setMaxDataFetchSizeLimit(uint newSize) external onlyOwner {
        maxDataFetchSizeLimit = newSize;
    }

    /********** View Functions **********/

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getCapsTokenContractAddress() external view returns (address) {
        return address(capsTokenContract_Ins);
    }

    function getTotalStakedAmount() external view returns (uint) {
        return totalStakedAmount;
    }

    function getUserData(address userAddress)
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint,
            bool,
            uint,
            uint
        )
    {
        User storage tempUserData = usersData[userAddress];
        return (
            tempUserData.totalStakes,
            tempUserData.totalWithdrawableReward,
            tempUserData.claimFrom,
            tempUserData.rewardFrom,
            tempUserData.isActiveUser,
            getUserTotalStackedAmount(userAddress),
            getUserTotalReward(userAddress)
        );
    }

    function calculateRewardPerStack(address userAddress)
        private
        view
        returns (uint)
    {
        uint totalRewardPerStake;
        uint _totalRewardCount = totalRewardCount;
        uint _userTotalStackedAmount = getUserTotalStackedAmount(userAddress);

        for (
            uint256 i = usersData[userAddress].rewardFrom;
            i <= _totalRewardCount;

        ) {
            uint _rewardAmount = rewardHistory[i].rewardAmount;
            uint _totalStakedAmount = rewardHistory[i].totalStackedTokens;
            if (_userTotalStackedAmount != 0) {
                if (_totalStakedAmount != 0) {
                    uint userRewardAmount = uint(
                        (((_rewardAmount * (1e18)) / _totalStakedAmount) *
                            (_userTotalStackedAmount)) / (1e18)
                    );
                    totalRewardPerStake += userRewardAmount;
                } else {
                    totalRewardPerStake += _rewardAmount;
                }
            }
            unchecked {
                i++;
            }
        }
        totalRewardPerStake += usersData[userAddress].rewardPerStake[
            usersData[userAddress].totalStakes
        ];
        return totalRewardPerStake;
    }

    function getClaimableRewardAndTokens(address userAddress)
        public
        view
        returns (
            uint,
            uint,
            uint
        )
    {
        User storage tempUserData = usersData[userAddress];
        uint withdrawableReward;
        uint claimableTokens;
        uint lastClaim;
        uint _claimTime = claimTime;
        if (tempUserData.totalStakes > 0) {
            for (
                uint256 i = tempUserData.claimFrom;
                i <= tempUserData.totalStakes;

            ) {
                if (tempUserData.stackedAt[i] + _claimTime < block.timestamp) {
                    if (i == tempUserData.totalStakes) {
                        withdrawableReward += calculateRewardPerStack(
                            userAddress
                        );
                    } else {
                        withdrawableReward += tempUserData.rewardPerStake[i];
                    }
                    claimableTokens += tempUserData.amountStaked[i];
                    lastClaim = i + 1;
                } else {
                    break;
                }
                unchecked {
                    i++;
                }
            }
        }
        return (withdrawableReward, claimableTokens, lastClaim);
    }

    function getUserTotalReward(address userAddress)
        public
        view
        returns (uint)
    {
        uint _totalReward;
        User storage tempUserData = usersData[userAddress];
        for (
            uint256 i = tempUserData.claimFrom;
            i <= tempUserData.totalStakes;

        ) {
            if (i == tempUserData.totalStakes) {
                _totalReward += calculateRewardPerStack(userAddress);
            } else {
                _totalReward += tempUserData.rewardPerStake[i];
            }
            unchecked {
                i++;
            }
        }
        return _totalReward;
    }

    function getUserTotalStackedAmount(address userAddress)
        public
        view
        returns (uint)
    {
        uint _totalStackedAmount;
        User storage tempUserData = usersData[userAddress];
        for (
            uint256 i = tempUserData.claimFrom;
            i <= tempUserData.totalStakes;

        ) {
            _totalStackedAmount += tempUserData.amountStaked[i];
            unchecked {
                i++;
            }
        }
        return _totalStackedAmount;
    }

    function getStackData(address userAddress, uint stackNum)
        external
        view
        returns (uint, uint)
    {
        return (
            usersData[userAddress].amountStaked[stackNum],
            usersData[userAddress].stackedAt[stackNum]
        );
    }

    function getStacksData_Arr(address userAddress)
        external
        view
        returns (stackData[] memory)
    {
        User storage tempUserData = usersData[userAddress];
        int arrSize = int(
            (tempUserData.totalStakes - tempUserData.claimFrom) + 1
        );
        if (arrSize < 0) {
            arrSize = 0;
        }
        stackData[] memory tempStackData = new stackData[](uint(arrSize));
        uint j;
        for (
            uint256 i = tempUserData.claimFrom;
            i <= tempUserData.totalStakes;

        ) {
            tempStackData[j] = stackData(
                i,
                tempUserData.amountStaked[i],
                tempUserData.stackedAt[i]
            );
            unchecked {
                i++;
                j++;
            }
        }
        return tempStackData;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}