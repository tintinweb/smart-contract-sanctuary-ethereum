/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract test1 {
    // ReviewerName+storeName+productname+rate
    // 0x797577616e617261732b797577616e617261732b797577616e617261732b3500
    // 9 chars and plus sign 
    // text hash
    // 0x2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824

    event Detail(bytes32 _detail, bytes32 _hash);

    function storeDetail2(bytes32  _detail, bytes32 _hash ) public  {        
    emit Detail(_detail, _hash);
    }
}