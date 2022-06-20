// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Staker {
    mapping(address => uint256) public depositTimestamps;
    bool public stakingDone;
    address public immutable ownerAdx;
    // update these in stake func
    address private uniqueUserAdx;
    uint private uniqueUserBalance;

    uint256 public constant rewardRatePerSecond = 0.01 ether;
    uint256 public depositDeadline;
    uint256 public claimDeadline;

    // Events
    event Stake(address indexed sender, uint256 amount);
    event Received(address, uint);
    event Execute(address indexed sender, uint256 amount);

    constructor(uint256 _depositTimeLimit, uint256 _claimTimeLimit) {
        depositDeadline = block.timestamp + _depositTimeLimit;
        claimDeadline = block.timestamp + _claimTimeLimit;

        ownerAdx = msg.sender;
    }

    //*Modifier's helpers
    /** @dev Checks if there's time left to make a deposit*/
    function depositTimeLeft() public view returns (uint256 _depositTimeLeft) {
        if (block.timestamp >= depositDeadline) {
            return (0);
        } else {
            return (depositDeadline - block.timestamp);
        }
    }

    /**@dev Checks if there's time left to claim staking rewards */
    function claimPeriodLeft() public view returns (uint256 _claimPeriodLeft) {
        if (block.timestamp >= claimDeadline) {
            return (0);
        } else {
            return (claimDeadline - block.timestamp);
        }
    }

    //* Modifiers
    /**@param requireReached ? false : stops everything if there's NOT time left*/
    /**@param requireReached ? stops : everything if there IS time left*/
    modifier depositDeadlineReached(bool requireReached) {
        uint256 timeRemaining = depositTimeLeft();

        if (requireReached) {
            require(timeRemaining == 0, "deposit period is not reached yet");
        } else {
            require(timeRemaining > 0, "deposit period has been reached");
        }
        _;
    }

    /**@param requireReached ? false : stops everything if there's NOT time left*/
    /**@param requireReached ? stops : everything if there IS time left*/
    modifier claimDeadlineReached(bool requireReached) {
        uint256 timeRemaining = claimPeriodLeft();

        if (requireReached) {
            require(timeRemaining == 0, "Claim deadline is not reached yet");
        } else {
            require(timeRemaining > 0, "Claim deadline has been reached");
        }
        _;
    }

    /**@dev Makes sure that the contract whole operation has only been run once*/
    modifier notCompleted() {
        require(
            !stakingDone,
            "Staking process has already been completed once, please reset!"
        );

        stakingDone = true;
        _;
    }

    /**@dev A classic one  */
    modifier onlyOwner() {
        require(
            msg.sender == ownerAdx,
            "You are not the owner of this contract!!"
        );
        _;
    }

    /**@dev Only allow the current user to deposit & retire gains */
    modifier onlyCurrentUser() {
        _;
        // since the function itself runs first it's better to revert changes made in the blockchain!
        if (!(msg.sender == uniqueUserAdx)) {
            revert("You are not the one that staked that money!");
        }
    }

    //* Staking Logic functions
    // Stake function for a user to stake ETH in our contract
    function stake()
        public
        payable
        depositDeadlineReached(false)
        claimDeadlineReached(false)
        onlyCurrentUser
    {
        // cumulative to allow multiple calls
        uniqueUserBalance += msg.value;
        depositTimestamps[msg.sender] = block.timestamp;

        emit Stake(msg.sender, msg.value);
    }

    /**@dev Rewards the user depending on the time that left the founds (within the 2 min period for staking) */
    function withdraw()
        public
        depositDeadlineReached(true)
        claimDeadlineReached(false)
        notCompleted
        onlyCurrentUser
    {
        require(uniqueUserBalance > 0, "You have no balance to withdraw!");

        uint256 indBalanceRewards = uniqueUserBalance +
            (((block.timestamp - depositTimestamps[msg.sender])**2) *
                rewardRatePerSecond);

        uniqueUserBalance = 0;

        (
            bool sent, /*bytes memory data*/

        ) = msg.sender.call{value: indBalanceRewards}("");
        require(sent, "RIP; deposit failed :( ");
    }

    //* Reusablity function
    /**@dev reset function to be able to run the whole process over again, while keeping the funds it may have got whit `execute()` */
    function stakingReset()
        public
        claimDeadlineReached(true)
        notCompleted
        onlyOwner
    {
        stakingDone = false;
        //same as 0x0000000000000000000000000000000000000000
        uniqueUserAdx = address(0);
        uniqueUserBalance = 0;
    }

    function changeTimeLimits(uint _newDepositTime, uint _newClaimTime)
        public
        onlyOwner
    {
        depositDeadline = _newDepositTime;
        claimDeadline = _newClaimTime;
    }

    /**@dev an smart contract must have this function to be able to receive ETH */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}