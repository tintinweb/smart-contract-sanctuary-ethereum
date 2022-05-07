// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.7;


/* interface ITrace {

    function writeOrder(uint256 order_) external;

    function doesOrderExist(uint256 order_) external view returns (bool); 
}
 */

// TODO:
//  1. Upgradable
contract ITrace {

    mapping (uint256 => bool) public orders;

    address contractOwner;
    address backendAddress;


    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only owner");
        _;
    }

    modifier onlyBackend() {
        require(msg.sender == backendAddress, "Only backendAddress");
        _;
    }

   /*  constructor(address backendAddress_) {
        contractOwner = msg.sender;
        backendAddress = backendAddress_;
    }
 */
    function writeOrder(uint256 order_) external onlyBackend {

        orders[order_];

    }

    function doesOrderExist(uint256 order_ )external view returns (bool) {
        
        return orders[order_];
        
    }


}