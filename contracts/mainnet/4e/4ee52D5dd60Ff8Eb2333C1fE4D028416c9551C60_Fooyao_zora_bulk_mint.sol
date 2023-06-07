/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// 微信 fooyaoeth 发送加群自动进群

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface interfaceMaster {
function zoro_mint(address to, address target, uint8 times, int offset) external payable;
}


contract Fooyao_zora_bulk_mint {
    interfaceMaster fooyao = interfaceMaster(0xE013Af5b6128Fa54c7903E31Ae6D85f4A1302f79);

    /**
    * @dev zora_bluk_mint
    * @param target mint_contract_address, nftContract
    * @param times mint_times
    * @param offset totalSupply_offset_0~9
    */
    function batch_mint_withdrawal(address target, uint8 times, int offset) external payable{
		fooyao.zoro_mint{value: msg.value}(msg.sender, target, times, offset);
	}

}