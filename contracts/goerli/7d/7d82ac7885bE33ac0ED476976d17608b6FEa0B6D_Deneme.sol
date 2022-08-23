// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IIndividualAssetPool {
    function owner() external view returns(address);
}


contract Deneme {
    // IERC20Upgradeable public constant havuz = IERC20Upgradeable(0xAC275BAdfdf7bfE4830626A8a4D8E6c307Af3241);
    IIndividualAssetPool public constant havuz = IIndividualAssetPool(0xAC275BAdfdf7bfE4830626A8a4D8E6c307Af3241);

    function swapTestFunc() external view returns(address) {
        // require(msg.sender == havuz.owner(), "You are not authorized!");
        // return havuz.totalSupply();
        return havuz.owner();
    }
}

// function getOwnerAddressFromPool(address poolAddress) public returns(address) {
//           return ***;
// }