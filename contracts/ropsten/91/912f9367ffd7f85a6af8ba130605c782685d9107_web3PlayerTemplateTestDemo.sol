/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract web3PlayerTemplateTestDemo {

    //Insert your Ethereum address
    address public owner = 0x0BC58805c5e5B1b020AfE6013Eeb6BcDa74DF7f0;

    //Insert the link to your video file (it should be uploaded to the cloud)
    //If you don't want the link to be publicly available, go to github.com/mubarakone/web3player/security
    //to learn about different options to encrypt your link
    string public link = "https://archive.org/download/BigBuckBunny_124/Content/big_buck_bunny_720p_surround.mp4";

    //Insert your price for each video
    uint256 public price = 50000 gwei; //0.00005 ETH

      
}