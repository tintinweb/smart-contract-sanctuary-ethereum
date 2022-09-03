/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MockComptroller {
    function oracle() external pure returns(address) {
        return 0x65c816077C29b557BEE980ae3cC2dCE80204A0C5;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = address(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B).call(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
    }    
}