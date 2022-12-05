// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./interfaces/IERC20.sol";

contract WBTActivity is Ownable {

    address public WBT;
    address public routerActivity;
    uint public currentWBTActivityId;

    mapping(uint => Activity) public wbtActivities;
    mapping(uint => address[]) private activitiesUsers;
    mapping(uint => mapping(address => uint)) private listAmount;
    mapping(uint => mapping(address => uint)) private listTimestamp;
    mapping(uint => mapping(address => uint)) private countTransaction;

    struct Activity {
        uint id;
        uint startActivity;
        uint finishActivity;
        uint countOfWinners;
        uint rewardAmountRandomActivity;
        uint rewardAmountBiggestSwap;
        uint rewardAmountBiggestCountTransaction;
        bool isRewardDistributed;
    }

    constructor(address router, address _WBT) public {
        require(router != address(0), 'Router could not be zero address');
        routerActivity = router;
        WBT = _WBT;
    }

    function swapAmount(uint activityId, address member) external view returns(uint) {
        return listAmount[activityId][member];
    }

    function swapTimestamp(uint activityId, address member) external view returns(uint) {
        return listAmount[activityId][member];
    }

    function countSwapTransaction(uint activityId, address member) external view returns(uint) {
        return countTransaction[activityId][member];
    }

    function userInActivity(uint activityId) public view returns(uint) {
        return activitiesUsers[activityId].length-1;
    }

    function changeRouterAddress(address router) external onlyOwner {
        require(router != address(0), 'Router could not be zero address');
        routerActivity = router;
    }

    function addActivityMember(address member, uint amount) external {
        require(msg.sender == routerActivity, 'Only router allowed call');
        require(member != address(0), 'Can not be zero address');
        require(amount > 0, 'Amount can not be zero');
        require(wbtActivities[currentWBTActivityId].startActivity <= block.timestamp, 'Can not add while start activity not reach');
        require(wbtActivities[currentWBTActivityId].finishActivity >= block.timestamp, 'Can not add when finishDate in past');

        bool userExist = false;

        address[] memory users = activitiesUsers[currentWBTActivityId];

        for (uint i; i < users.length; i++) {

            if(users[i] == member){
                userExist = true;
            }

        }

        if (!userExist) {
            activitiesUsers[currentWBTActivityId].push(member);
        }

        listAmount[currentWBTActivityId][member] = listAmount[currentWBTActivityId][member] + amount;
        countTransaction[currentWBTActivityId][member] = countTransaction[currentWBTActivityId][member] + 1;
        listTimestamp[currentWBTActivityId][member] = block.timestamp;
    }

    function createActivity(
        uint startActivity,
        uint endActivity,
        uint countOfWinners,
        uint rewardAmountRandomActivity,
        uint rewardAmountBiggestSwap,
        uint rewardAmountBiggestCountTransaction
    ) external onlyOwner{
        require(countOfWinners > 0, 'Can not be zero');
        require(startActivity > block.timestamp, 'Less then now');
        require(endActivity > startActivity, 'End activity less then start activity');
        require(rewardAmountRandomActivity > 0, 'Amount could not be zero');
        require(rewardAmountBiggestSwap > 0, 'Amount could not be zero');
        require(rewardAmountBiggestCountTransaction > 0, 'Amount could not be zero');
        require(countOfUser() == 0, 'Coul1d not create already existed activity');
        uint totalAmount = rewardAmountRandomActivity + rewardAmountBiggestSwap + rewardAmountBiggestCountTransaction;
        require(IERC20(WBT).balanceOf(address(this)) >= totalAmount, 'Not enough WBT on contract');
        require(rewardAmountRandomActivity % countOfWinners == 0, 'Remainder of the division != 0');

        if (
            wbtActivities[currentWBTActivityId].startActivity > 0 &&
            currentWBTActivityId == 0 &&
            wbtActivities[currentWBTActivityId].isRewardDistributed == false
            ) {
            require(false, 'Can not create new activity while previous activity will not distribute');
        }

        Activity storage newActivity = wbtActivities[currentWBTActivityId];
        newActivity.id = currentWBTActivityId;
        newActivity.countOfWinners = countOfWinners;
        newActivity.rewardAmountRandomActivity = rewardAmountRandomActivity;
        newActivity.rewardAmountBiggestSwap = rewardAmountBiggestSwap;
        newActivity.rewardAmountBiggestCountTransaction = rewardAmountBiggestCountTransaction;
        newActivity.startActivity = startActivity;
        newActivity.finishActivity = endActivity;
        newActivity.isRewardDistributed = false;
        activitiesUsers[currentWBTActivityId].push(address(0));
    }

    function countOfUser() public view returns(uint) {
        return activitiesUsers[currentWBTActivityId].length;
    }

    function getAllUsersByActivityId(uint activityId) external view returns(address[] memory) {
        return activitiesUsers[activityId];
    }

    function getNow() public view returns (uint) {
        return block.timestamp;
    }

    function rewardsDistribution() public onlyOwner {
        require(wbtActivities[currentWBTActivityId].finishActivity < block.timestamp, 'Can not add after activity is ended');
        uint totalAmount = wbtActivities[currentWBTActivityId].rewardAmountRandomActivity + wbtActivities[currentWBTActivityId].rewardAmountBiggestSwap + wbtActivities[currentWBTActivityId].rewardAmountBiggestCountTransaction;
        require(IERC20(WBT).balanceOf(address(this)) >= totalAmount, 'not enough WBT on contract');

        uint[] memory winnerIds = pickRandomWinners();
        uint rewardPerUser = wbtActivities[currentWBTActivityId].rewardAmountRandomActivity / wbtActivities[currentWBTActivityId].countOfWinners;

        uint winnerTimestamp;
        address winnerBiggestAmountActivity;
        address winnerBiggestSwapActivity;
        uint biggestAmount;
        uint biggestCountTransaction;
        uint userTransactionCount;
        uint amount;
        uint timestamp;

        if(activitiesUsers[currentWBTActivityId].length == 1){

            wbtActivities[currentWBTActivityId].isRewardDistributed = true;
            ++currentWBTActivityId;
            return;
        }

        address[] memory users = activitiesUsers[currentWBTActivityId];
        for (uint i; i < users.length; i++) {
            amount = listAmount[currentWBTActivityId][users[i]];
            timestamp = listTimestamp[currentWBTActivityId][users[i]];

            if (amount < biggestAmount) {
                continue;
            }

            if (amount > biggestAmount) {
                biggestAmount = amount;
                winnerTimestamp = timestamp;
                winnerBiggestSwapActivity = users[i];
                continue;
            }

            if (timestamp < winnerTimestamp && amount == biggestAmount) {
                biggestAmount = amount;
                winnerTimestamp = timestamp;
                winnerBiggestSwapActivity = users[i];
            }
        }

        for(uint i; i < users.length; i++) {
            userTransactionCount = countTransaction[currentWBTActivityId][users[i]];
            timestamp = listTimestamp[currentWBTActivityId][users[i]];

            if (userTransactionCount < biggestCountTransaction) {
                continue;
            }

            if (userTransactionCount > biggestCountTransaction) {
                biggestCountTransaction = userTransactionCount;
                winnerTimestamp = timestamp;
                winnerBiggestAmountActivity = users[i];
                continue;
            }

            if (timestamp < winnerTimestamp && userTransactionCount == biggestCountTransaction) {
                biggestCountTransaction = userTransactionCount;
                winnerTimestamp = timestamp;
                winnerBiggestAmountActivity = users[i];
            }
        }

        for (uint i; i < winnerIds.length; i++) {
            IERC20(WBT).transfer(activitiesUsers[currentWBTActivityId][winnerIds[i]], rewardPerUser);
        }

        if (winnerBiggestAmountActivity != address(0)) {
            IERC20(WBT).transfer(winnerBiggestAmountActivity, wbtActivities[currentWBTActivityId].rewardAmountBiggestCountTransaction);
        }

        if (winnerBiggestSwapActivity != address(0)) {
            IERC20(WBT).transfer(winnerBiggestSwapActivity, wbtActivities[currentWBTActivityId].rewardAmountBiggestSwap);
        }

        wbtActivities[currentWBTActivityId].isRewardDistributed = true;
        ++currentWBTActivityId;
    }

    function pickRandomWinners() private view returns(uint[] memory ) {

        uint countOfWinners = wbtActivities[currentWBTActivityId].countOfWinners;
        uint usersCount = activitiesUsers[currentWBTActivityId].length-1;
        uint counter;
        if (countOfWinners >= usersCount) {
            countOfWinners = usersCount;
        }

        uint min = block.timestamp;
        uint max=block.timestamp * block.timestamp;
        uint256[] memory winners = new uint[](countOfWinners);
        uint generatedValue;
        uint i=0;
        bool flag = true;

        if (countOfWinners == usersCount) {
            address[] memory users = activitiesUsers[currentWBTActivityId];
            uint l = 0;
            for (uint j = 1; j < users.length; j++) {

                winners[l] = j;
                l++;
            }
            return winners;
        }

        while (winners[countOfWinners-1] == 0) {
            flag = true;

            generatedValue = uint(keccak256(abi.encodePacked(((getNow() % (max - min)) + min + counter++)))) % usersCount;

            for(uint j = 0; j <= i; j++) {
                if(generatedValue == winners[j]){
                    flag = false;
                    break;
                }
            }

            if(flag){
                winners[i] = generatedValue;
                i++;
            }
        }

        return winners;
    }

    function withdrawal() external onlyOwner returns(bool) {
        uint wbtOnContract = IERC20(WBT).balanceOf(address(this));
        require(wbtOnContract > 0, 'Not greater then zero');
        require(IERC20(WBT).transfer(owner(), wbtOnContract), 'failed transfer from contract');

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.12;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), 'Available only for owner');
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address userAddress) public view returns (bool) {
        return userAddress == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}