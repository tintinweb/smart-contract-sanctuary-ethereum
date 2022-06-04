pragma solidity >=0.7.0 <0.9.0;
 
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public elapsed;
    uint256 public count;
    mapping(uint256 => uint256) public _data;
    function store(uint256 num) public {
        _data[num] = num;
        count++;
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        endTime = block.timestamp;
        elapsed = endTime - startTime;
    }
}