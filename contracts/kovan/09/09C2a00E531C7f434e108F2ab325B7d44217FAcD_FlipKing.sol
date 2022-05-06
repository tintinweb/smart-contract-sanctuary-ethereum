// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract FlipKing {
    mapping(address => uint256) public rewardBalances;
    mapping(uint256 => betStruct) public allBets;
    uint256 public totalBetCount;
    betQueue public currentQueue;

    address payable public owner;
    mapping(address => address) public affiliateAddress;
    uint256 public queueSize;
    mapping(address => uint256) public totalClaimedRewardsAddress;
    mapping(address => uint256) public houseTokenBalances;
    uint256 public houseTokenSupply;
    uint256 public liquidityPool;

    struct betQueue {
        uint256 start;
        uint256 last;
    }

    struct betStruct {
        address better;
        bool winner;
        bool completed;
        uint256 sidePicked;
        uint256 betSize;
        uint256 blockNumber;
        uint256 seed;
    }

    event betPlaced(
        uint256 betId,
        address better,
        uint256 side,
        uint256 amount
    );

    event betResolved(uint256 betId, uint256 betResult);

    constructor() {
        totalBetCount = 0;
        currentQueue = betQueue(0, 0);
        queueSize = 0;
        owner = payable(msg.sender);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance - liquidityPool;
    }

    function setAffiliate(address _address) external {
        affiliateAddress[msg.sender] = _address;
    }

    function withdrawWinnings() external {
        require(
            rewardBalances[msg.sender] < getBalance(),
            "Smart Contract Doesnt have enough funds"
        );
        uint256 rewardsForPlayer = rewardBalances[msg.sender];
        rewardBalances[msg.sender] = 0;
        liquidityPool +=
            ((rewardsForPlayer - (rewardsForPlayer % 100)) / 100) *
            5;
        payable(msg.sender).transfer(
            ((rewardsForPlayer - (rewardsForPlayer % 100)) / 100) * 95
        );
    }

    function placeBet(uint256 _side) external payable {
        require(
            msg.value < getBalance(),
            "Contract Doesn't have enough to payout on winner"
        );
        allBets[totalBetCount] = betStruct(
            msg.sender,
            false,
            false,
            _side % 2,
            msg.value,
            block.number,
            0
        );
        totalBetCount += 1;
        currentQueue.last = totalBetCount;
        queueSize += 1;
        houseTokenBalances[msg.sender] += msg.value;
        houseTokenSupply += msg.value;
        houseTokenBalances[owner] += (msg.value - (msg.value % 3)) / 3;
        houseTokenSupply += (msg.value - (msg.value % 3)) / 3;
        if (affiliateAddress[msg.sender] != address(0)) {
            houseTokenBalances[affiliateAddress[msg.sender]] +=
                (msg.value - (msg.value % 10)) /
                10;
            houseTokenSupply += (msg.value - (msg.value % 10)) / 10;
        }

        emit betPlaced(totalBetCount - 1, msg.sender, _side, msg.value);
        resolveBets();
    }

    function loadSC() external payable {
        require(msg.sender == owner, "only owner can load the SC");
    }

    function claimRewards(uint256 _amount) external {
        require(_amount >= 100000, "Amount needs to be more than 100,000");

        uint256 tempSupply = (houseTokenSupply -
            (houseTokenSupply % 100000) +
            100000);
        uint256 tempAmount = (_amount - (_amount % 100000));
        uint256 claimableRewards = ((liquidityPool * tempAmount) / tempSupply);
        totalClaimedRewardsAddress[msg.sender] += claimableRewards;
        houseTokenBalances[msg.sender] -= tempAmount;
        houseTokenSupply -= tempAmount;
        liquidityPool -= claimableRewards;
        payable(msg.sender).transfer(claimableRewards);
    }

    function resolveBets() internal {
        while (queueSize > 0) {
            betStruct storage bet = allBets[currentQueue.start];
            if (bet.blockNumber >= block.number) {
                break;
            }
            uint256 roll = uint256(
                keccak256(abi.encodePacked(msg.sender, currentQueue.last))
            );
            bet.winner = bet.sidePicked == roll % 2;
            bet.completed = true;
            bet.seed = roll;
            rewardBalances[bet.better] += 2 * bet.betSize;
            emit betResolved(currentQueue.start, roll);
            queueSize--;
            currentQueue.start++;
        }
    }
}