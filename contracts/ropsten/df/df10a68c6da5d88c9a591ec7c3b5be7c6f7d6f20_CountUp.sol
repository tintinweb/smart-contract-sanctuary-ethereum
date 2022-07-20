/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.8.15;

contract CountUp {

    uint16 cnt = 0;

    function countUp() external returns(uint16){
        cnt++;
        return cnt;
    }

    function getCount() external view returns(uint16){
        return cnt;
    }

    function countDown() external returns(uint16){
        cnt--;
        return cnt;
    }
}