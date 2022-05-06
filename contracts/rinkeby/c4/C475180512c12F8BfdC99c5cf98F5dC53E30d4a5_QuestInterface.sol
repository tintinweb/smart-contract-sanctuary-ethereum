/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IGetNumber {
    function getNumber() external view returns (uint256);
    function selfDestruct() external;
}

contract QuestInterface {

    function getNumber(address _metamorphicContractAddress) public view returns (uint256){
        return IGetNumber(_metamorphicContractAddress).getNumber();
    }

    function destroy(address _metamorphicContractAddress) external {
        IGetNumber(_metamorphicContractAddress).selfDestruct();
    }
    
}