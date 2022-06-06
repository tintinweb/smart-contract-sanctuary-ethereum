/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test2 {

    mapping(address => uint256) private presaleBalances;

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param addresses address representing the previous owner of the given token ID
     */
    function test3(address[] memory addresses) public {
        for( uint i; i < addresses.length; ++i ){
            presaleBalances[addresses[i]] += 1;
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function up(address address_) public {
        presaleBalances[address_] += 1;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function down(address address_) public {
        presaleBalances[address_] -= 1;
    }
}