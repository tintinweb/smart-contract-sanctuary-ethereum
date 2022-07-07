//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ISimpleStore} from "./ISimpleStore.sol";

contract FunxCaller {
    ISimpleStore immutable simpleStoreContract;

    constructor() {
        simpleStoreContract = ISimpleStore(
            address(0x1a427057402192E7a6034B23eb62d1b4a2E6Be4C)
        );
    }

    function setUsingStorageFunxCaller(uint256 _itemIdx, uint256 _val)
        external
    {
        simpleStoreContract.setUsingStorage(_itemIdx, _val);
    }
}

pragma solidity ^0.8.0;

interface ISimpleStore {
    function setUsingStorage(uint256 _itemIdx, uint256 _val) external;
}