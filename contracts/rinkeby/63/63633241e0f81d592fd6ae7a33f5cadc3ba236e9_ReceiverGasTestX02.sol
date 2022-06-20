/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GLWTPL

pragma solidity ^0.8.14;

contract ReceiverGasTestX02 {

    event Invoked(uint256 gasLeft);
    event ReceiveNumber(uint256 number);

    function anyExecute(bytes memory _data) external returns (bool success, bytes memory result) {
        emit Invoked(gasleft());

        (uint256 number) = abi.decode(_data, (uint256));

        emit ReceiveNumber(number);

        uint256 resultNumber = ourFact(number);

        success = true;
        result = abi.encode(resultNumber);
    }

    function ourFact(uint256 x) public returns (uint256) { // non-pure on purpose
        if (x == 0 || x == 1) {
            return 1; 
        }

        uint256 result = x;

        while (x > 1) { 
            x--;

            unchecked {
                result *= x;
            }
        }

        return result;    
    }
  }