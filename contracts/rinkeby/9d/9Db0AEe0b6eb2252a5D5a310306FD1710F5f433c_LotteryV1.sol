pragma solidity ^0.8.0;

contract LotteryV1 {
    address private adminAddress;
    mapping(address => uint256) public playersMap;
    //    address[] public playersArr;
    uint public STAKE; // Gwei
    uint totalStake;
    bool rewardSent;

    function initialize(uint _stake) external {
        adminAddress = msg.sender;
        STAKE = _stake;
    }

    modifier ifActive() {
        require(!rewardSent, "We have a winner already!");
        _;
    }

    function join() public ifActive payable {
        if (playersMap[msg.sender] == 0) {
            require(msg.value == STAKE, "Wrong amount, must be: 5000000 GWEI");
            totalStake += msg.value;
            playersMap[msg.sender] = msg.value;
            //            playersArr.push(msg.sender);
        } else if (rewardSent) {
            revert("We have a winner already!");
        }
        else {
            revert("You have already staked");
        }
    }

    function rewardWinner(address winner) public ifActive {
        if (playersMap[winner] == 0) {
            revert("Address has no entry");
        }
        revert("Not implemented yet");
    }
}