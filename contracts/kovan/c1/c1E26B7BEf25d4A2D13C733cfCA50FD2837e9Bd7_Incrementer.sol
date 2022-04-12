/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity ^0.8.0;

contract Incrementer {
        uint256 public number;

        constructor(uint256 _initValue){
                number = _initValue;
        }

        function increment() public {
                number++;
        }

        function reset() public {
                number = 0;
        }

}