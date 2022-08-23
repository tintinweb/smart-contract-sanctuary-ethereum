/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity 0.5.17;

// 合同，所有人都可以用
contract Counter {

    event ValueChanged(uint oldValue, uint256 newValue);

    // Private variable of type unsigned int to keep the number of counts
    uint256 private count = 0;

    //增加一个数值 
    // Function that increments our counter
    function increment() public {
        count += 1;
        emit ValueChanged(count - 1, count);
    }

    // 
    // Getter to get the count value
    function getCount() public view returns (uint256) {
        return count;
    }

}