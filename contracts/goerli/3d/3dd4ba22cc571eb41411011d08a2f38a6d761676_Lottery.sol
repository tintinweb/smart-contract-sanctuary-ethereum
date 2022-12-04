/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// File: gist-1bb62664cfad04de04d9dc5d059eb519/GovernanceInterface.sol

pragma solidity 0.6.6;

interface GovernanceInterface {
    function lottery() external view returns (address);
    function randomness() external view returns (address);
}
// File: gist-1bb62664cfad04de04d9dc5d059eb519/RandomnessInterface.sol

pragma solidity 0.6.6;

interface RandomnessInterface {
    function randomNumber(uint) external view returns (uint);
    function getRandom(uint, uint) external;
}
// File: gist-1bb62664cfad04de04d9dc5d059eb519/LotteryNoAlarm.sol

pragma solidity ^0.6.6;
//import "github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/ChainlinkClient.sol";



contract Lottery {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    uint256 public lotteryId;
    address payable[] public players;
    GovernanceInterface public governance;
    // .01 ETH
    uint256 public MINIMUM = 1000000000000000;
    address payable MANAGER = 0x270252c5FAd90804CE9288F2C643d26EfA568cFC;
    
    constructor(address _governance) public
    {
        //setPublicChainlinkToken();
        lotteryId = 1;
        lottery_state = LOTTERY_STATE.CLOSED;
        governance = GovernanceInterface(_governance);
    }

    function enter() public payable {
        assert(msg.value == MINIMUM);
        assert(lottery_state == LOTTERY_STATE.OPEN);
        players.push(msg.sender);
    } 
    
  function start_new_lottery() public {
    require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery yet");
    require(msg.sender == MANAGER, "only manager can call this");
    lottery_state = LOTTERY_STATE.OPEN;
  }
  
  function finish_lottery() public {
        require(lottery_state == LOTTERY_STATE.OPEN, "The lottery hasn't even started!");
        require(msg.sender == MANAGER, "only manager can call this");
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        lotteryId = lotteryId + 1;
        pickWinner();
    }


    function pickWinner() private {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        RandomnessInterface(governance.randomness()).getRandom(lotteryId, lotteryId);
        //this kicks off the request and returns through fulfill_random
    }
    
    function fulfill_random(uint256 randomness) external {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        require(randomness > 0, "random-not-found");
        // assert(msg.sender == governance.randomness());
        uint256 index = randomness % players.length;
        players[index].transfer((address(this).balance * 9) / 10); // send 90% to the winner
        MANAGER.transfer(address(this).balance);  //send the remaining 10% to the manager
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        // You could have this run forever
        //start_new_lottery();
        // or with a cron job from a chainlink node would allow you to 
        // keep calling "start_new_lottery" as well
    }

    function get_players() public view returns (address payable[] memory) {
        return players;
    }
    
    function get_pot() public view returns(uint256){
        return address(this).balance;
    }
}