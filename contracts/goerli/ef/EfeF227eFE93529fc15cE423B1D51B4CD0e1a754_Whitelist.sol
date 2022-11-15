/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//WhiteListコントラクトはNFTを優先的にミントできるアドレスを登録するため
contract Whitelist{

  uint public maxWhitelistedAddresses;

  mapping(address=>bool) public whitelistedAddresses;

  uint public numAddressesWhitelisted;

  constructor(uint  _maxWhitelistedAddresses){
    maxWhitelistedAddresses = _maxWhitelistedAddresses;
  }

  function addAddressToWhitelist() public {

    require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");

    require(numAddressesWhitelisted < maxWhitelistedAddresses, "More addresses cant be added, limit reached");

    whitelistedAddresses[msg.sender] = true;

    numAddressesWhitelisted += 1;
  }
}