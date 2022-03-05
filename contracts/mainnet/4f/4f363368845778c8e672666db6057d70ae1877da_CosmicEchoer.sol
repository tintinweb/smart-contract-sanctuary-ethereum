/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// Cosmic Kiss Mixer
// https://cosmickiss.io/

pragma solidity ^0.5.0;

contract CosmicEchoer {
  
  event Echo(address indexed signer, bytes data);
  function echo(bytes calldata _data) external {
    emit Echo(msg.sender, _data);
  }

}