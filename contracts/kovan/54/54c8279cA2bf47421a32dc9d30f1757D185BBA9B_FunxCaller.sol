pragma solidity ^0.8.0;

import {ISimpleStore} from "./ISimpleStore.sol";

contract FunxCaller {
    ISimpleStore public simpleStoreAddress;

    constructor(ISimpleStore _simplestoreAddress) {
        simpleStoreAddress = _simplestoreAddress;
    }

    function setItem0(uint256 _val) public {
        simpleStoreAddress.setUsingStorage(0, _val);
    }

    function getItemAt0() external returns (uint256) {
        return simpleStoreAddress.getItemAtIndex(0);
    }
}

pragma solidity ^0.8.0;

interface ISimpleStore {
    function setUsingStorage(uint256 _itemIdx, uint256 _val) external;
    function getItemAtIndex(uint256 _itemIdx) external returns (uint256);
}