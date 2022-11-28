pragma solidity 0.8.10;

import "./Ownable.sol";
import "./interfaces/IERC20.sol";

contract WBTActivity is Ownable {

    address public routerActivity;
    mapping(uint => Activity) public wbtActivities;
    uint public currentWBTActivityId;
    mapping(uint => address[]) public activitiesUsers;
    uint public initialNumber;
    address public WBT;
    mapping(uint => mapping(address => uint)) public listAmount;
    mapping(uint => mapping(address => uint)) public listTimestamp;
    mapping(uint => mapping(address => uint)) public countTransaction;

    struct Activity {
        uint id;
        uint startActivity;
        uint finishActivity;
        uint countOfWinners;
        uint rewardAmountRandomActivity;
        uint rewardAmountBiggestSwap;
        uint rewardAmountBiggestCountTransaction;
    }

    constructor(address router, address _WBT) {
        require(router != address(0), 'Router could not be zero address');
        routerActivity = router;
        WBT = _WBT;
    }

    function changeRouterAddress(address router) external onlyOwner {
        require(router != address(0), 'Router could not be zero address');
        routerActivity = router;
    }

    function AddActivityMember(address member, uint amount) external {
        require(msg.sender == routerActivity, 'Only router allowed call');
        require(wbtActivities[currentWBTActivityId].finishActivity > block.timestamp, 'Can not add after activity is ended');

        activitiesUsers[currentWBTActivityId].push(member);
        address[] memory users = activitiesUsers[currentWBTActivityId];
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
    ) external onlyOwner {
        require(
            wbtActivities[currentWBTActivityId].finishActivity == 0 ||
            wbtActivities[currentWBTActivityId].finishActivity > endActivity,
            'Can not be added before previous will end'
        );
        require(startActivity > block.timestamp, 'Less then now');
        require(endActivity > startActivity, 'End activity less then start activity');
        require(rewardAmountRandomActivity > 0, 'Amount could not be zero');
        require(IERC20(WBT).balanceOf(address(this)) >= rewardAmountRandomActivity);

        ++currentWBTActivityId;
        Activity storage newActivity = wbtActivities[currentWBTActivityId];
        newActivity.id = currentWBTActivityId;
        newActivity.countOfWinners = countOfWinners;
        newActivity.rewardAmountRandomActivity = rewardAmountRandomActivity;
        newActivity.rewardAmountBiggestSwap = rewardAmountBiggestSwap;
        newActivity.rewardAmountBiggestCountTransaction = rewardAmountBiggestCountTransaction;
        newActivity.startActivity = startActivity;
        newActivity.finishActivity = endActivity;
        activitiesUsers[currentWBTActivityId].push(address(0));
    }


    function countOfUser() external view returns(uint) {
        return activitiesUsers[currentWBTActivityId].length;
    }

    function getAllUsersByActivityId(uint activityId) external view returns(address[] memory) {
        return activitiesUsers[activityId];
    }

    function getNow() public view returns (uint) {
        return block.timestamp;
    }

    function dropRewardRandomActivity() public {
        require(wbtActivities[currentWBTActivityId].finishActivity < block.timestamp, 'Can not add after activity is ended');
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

        address[] memory users = activitiesUsers[currentWBTActivityId];
        for(uint i; i < users.length; i++) {
            userTransactionCount = listAmount[currentWBTActivityId][users[i]];
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

            if(timestamp < winnerTimestamp && amount == biggestAmount){
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

            if(timestamp < winnerTimestamp && userTransactionCount == biggestCountTransaction){
                biggestCountTransaction = userTransactionCount;
                winnerTimestamp = timestamp;
                winnerBiggestAmountActivity = users[i];
            }
        }

        for (uint i; i < winnerIds.length; i++) {
            IERC20(WBT).transfer(activitiesUsers[currentWBTActivityId][winnerIds[i]], 1);
        }

        IERC20(WBT).transfer(winnerBiggestAmountActivity, wbtActivities[currentWBTActivityId].rewardAmountBiggestCountTransaction);
        IERC20(WBT).transfer(winnerBiggestSwapActivity, wbtActivities[currentWBTActivityId].rewardAmountBiggestSwap);
    }

    function pickRandomWinners() public view returns(uint[] memory) {

        uint countOfWinners = wbtActivities[currentWBTActivityId].countOfWinners;
        uint usersCount = activitiesUsers[currentWBTActivityId].length;
        require(usersCount >= countOfWinners, 'Not enough users in activity');

        uint min = block.timestamp;
        uint max=block.timestamp * block.timestamp;
        uint counter;
        uint256[] memory winners = new uint[](countOfWinners);
        uint generatedValue;
        uint i=0;
        bool flag = true;

        while(winners[countOfWinners-1] == 0){
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
pragma solidity =0.8.10;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

pragma solidity =0.8.10;

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
    constructor () {
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