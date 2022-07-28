/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library Utils {

    function libMint(NFT nft)   public   {
        nft.mint();
    }
}

contract NFT {

    address public minter ;

    event Mint(address);

    function mint() public {
        minter = msg.sender;
        emit Mint(minter);
    }


}

contract Proxy {

    NFT public nft = new NFT();

    function proxyMint() public {
        nft.mint();
    }

    function libMint() public {
        Utils.libMint(nft);
    }

    function delegateMint() public returns (bool) {
         (bool res, ) = address(nft).delegatecall(abi.encodeWithSignature("mint()")); 
         return res;
    }
}