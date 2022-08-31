/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

contract Contract { 

    uint256 public time;

    // A view function. The `block.timestamp` will return the same in every call
    // unless a function that modifies the state is called, like the `updateTime` function.
    // Then, this function will continue to return the same new value every time
    // untill another state change happens, and so on.
    function getCurrentContractTimeStamp() public view returns(uint256) {
        return block.timestamp;
    }

    // `block.timestamp` here will be different probably everytime is called.
    // Unless we call it multiple times and each transaction is mined in the same block,
    // in which case the transactions mined in the same block will share the same `block.timestamp`.
    function updateTime() public {
        time = block.timestamp;
    }

 }