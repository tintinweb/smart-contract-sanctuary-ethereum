/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// 微信 fooyaoeth 发送加群自动进群

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface interfaceMaster {
  function zora_mint(address to, address target, uint8 times, int offset) external payable;
}

contract Fooyao_zora_bulk_mint {
    interfaceMaster fooyao = interfaceMaster(0xC21475348B380506E6CAf0fa24dF68A73DFDf7BC);

    /**
    * @dev zora_bluk_mint
    * @param target mint_contract_address, nftContract
    * @param times mint_times
    * @param offset totalSupply_offset_0~9
    */
    function batch_mint_withdrawal(address target, uint8 times, int offset) external payable{
      fooyao.zora_mint{value: msg.value}(msg.sender, target, times, offset);
	  }

}