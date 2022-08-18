// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ownable.sol";

/**
 * @title Storage
 */
contract Storage is Ownable {

    struct Num1{
        uint a;
        uint b;
    }

    struct Num2{
        uint32 a;
        uint32 b;
    }

    uint256 public number;
    Num1 public num1;
    Num2 public num2;
    uint lastUpdated;

    uint[5] numbers = [1,2,3,4,5];

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public onlyOwner{
        number = num;
    }
      function store1(uint256 _a, uint256 _b) public {
        num1 = Num1(_a,_b);
    }

      function store2(uint32 _c, uint32 _d) public {
        num2 = Num2(_c,_d);
    }

      function checkIfNumberIsEven() public view returns (bool) {
    return (number % 2 == 0);
    }

    function notFreeViewCallV1(uint _num) public {
    number = _num;
    }
    function notFreeViewCallV2(uint _num) public {
    if(checkIfNumberIsEven()) {
    number = _num;
    } else {
    number = 0;
    }
    }

    // Set `lastUpdated` to `now`
    function updateTimestamp() public {
    lastUpdated = block.timestamp;
    }

    function fiveMinutesHavePassed() public view returns (bool) {
        return (block.timestamp >= (lastUpdated + 5 minutes));
    }

    function evenNos() external view returns (uint[] memory evenNumbers){
        uint length = numbers.length;
        evenNumbers = new uint[] (length);
        uint index = 0;

        for(uint i=0 ; i < length ; i++){
            if(numbers[i] %2 == 0){
                evenNumbers[index] = numbers[i];
                index++;
            }
        }
    }
    
    // uint8 can store values from 0 to 255 else it overflows and reseted to 0
    function uint8Overflows(uint8 n1, uint8 n2) external pure returns (uint8) {
        return (n1 + n2);
    }

}