/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.7;

/**
 *Submitted for verification at polygonscan.com on 2022-03-02
*/
contract Tatic {


    address payable private commissionWallet;

    constructor(address payable wallet) {
		require(!isContract(wallet));
		commissionWallet = wallet;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function withdraw() public payable{
        commissionWallet.transfer(msg.value);
    }

}