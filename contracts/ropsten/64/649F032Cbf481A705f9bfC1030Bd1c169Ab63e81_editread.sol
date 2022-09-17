// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Appstorage} from "./DiamondStorage.sol";

contract editread {

    Appstorage internal ds;

    function readOwner()external view returns(address){
        return ds.owner;
    }

    function readText()external view returns(string memory){
        return ds.text;
    }

    function readNum()external view returns(uint256){
        return ds.num;
    }

    function setText(string memory _text)external{
        ds.text = _text;
    
    }

    function setNum(uint256 _num)external{
        ds.num = _num;
    }

}

//0x866c504C4F4cAa5cE762e20Eb028Cd8340C2Bd91 libdiamond
//0x649F032Cbf481A705f9bfC1030Bd1c169Ab63e81 editread deployed

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

struct Appstorage{
    string text;
    uint256 num;
    address owner;
}