// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract eventEmitter {

    uint256[] public my_arr = [1,2,3,4,5,6,7];

    event REGENERATION (uint256 indexed avatarId, uint256[] indexed cosmeticIds);

    event MARKETPLACE_MINT(uint256 indexed tokenId, uint256 indexed db_product_id);


    function emit_regeneration() external {
        emit REGENERATION(1,my_arr);
    }

    function emit_marketplace_mint() external 
    {
        emit MARKETPLACE_MINT(1,5);
    }
}