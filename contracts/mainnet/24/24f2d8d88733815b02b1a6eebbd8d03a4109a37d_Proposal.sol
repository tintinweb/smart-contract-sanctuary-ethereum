/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity 0.6.7;

abstract contract Setter {
  function updateResult(uint) public virtual;
  function modifyParameters(bytes32, uint) public virtual;
}

contract Proposal {
  // addresses
  address public constant GEB_GAS_PRICE_ORACLE      = 0x3a3e9d4D1AfC6f9d7e0E9A4032a7ddBc1500D7a5;
  address public constant GEB_PROT_TOKEN_ORACLE     = 0xF0b9A234C273250F8D3cE047D8b9cea773Ae3adE;
  address public constant GEB_STAKING               = 0x69c6C08B91010c88c95775B6FD768E5b04EFc106;


  function execute(bool) public {
    Setter(GEB_GAS_PRICE_ORACLE).updateResult(100000000000);                               // 100 gwei
    Setter(GEB_PROT_TOKEN_ORACLE).updateResult(250000000000000000000);                     // 250 FLX price
    Setter(GEB_STAKING).modifyParameters("systemCoinsToRequest", 10000000000000000000000); // 10k RAI
  }
}