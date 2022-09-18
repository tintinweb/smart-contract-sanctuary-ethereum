// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract GatewayDub {
    uint256 public number;
    
    event result(
        uint256 resultnum
    );
    
    /*//////////////////////////////////////////////////////////////
                             Initialization
    //////////////////////////////////////////////////////////////*/

    address public masterVerificationAddress;

    /// @notice Initialize the verification address
    /// @param _masterVerificationAddress The input address
    function initialize(address _masterVerificationAddress) public {
        masterVerificationAddress = _masterVerificationAddress;
    }

    function DabFunc1(uint256 newNumber) public {
        number = newNumber;
    }

    function DabFunc2(uint256 a , uint256 b) public {
        uint256 resultNum = a + b;
        emit result(resultNum);
    }

    function DabFunc3() public {
        number++;
    }
}