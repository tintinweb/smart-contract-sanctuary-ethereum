/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

contract Test {

    enum Status {
        open,
        closed
    }

    uint256 public currentId;

    mapping(uint256 => uint256) public endTimes;

    mapping(uint256 => Status) public statuses;

    function set(uint id,uint _endTime) external {
        currentId++;
        endTimes[id] = _endTime;
    }

    function closeLottery(uint256 id) external {
        require(block.timestamp >= endTimes[id]);
        statuses[id] = Status.closed;
    }

    function getTime() external view returns (uint){
        return block.timestamp;
    }
}