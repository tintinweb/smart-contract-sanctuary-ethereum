// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DiamondStorage.sol";

contract editread {


    function readOwner()external view returns(address){
        //DiamondStorage.getStorage();
        return DiamondStorage.getStorage().owner;
    }

    function readText()external view returns(string memory){
        return DiamondStorage.getStorage().text;
    }

    function readNum()external view returns(uint256){
        return DiamondStorage.getStorage().num;
    }

    function setText(string memory _text)external{
        DiamondStorage.getStorage().text = _text;
    
    }

    function setNum(uint256 _num)external{
        DiamondStorage.getStorage().num = _num;
    }

}

//0x866c504C4F4cAa5cE762e20Eb028Cd8340C2Bd91 libdiamond

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library DiamondStorage{

    bytes32 internal constant NAMESPACE = keccak256("namespace.var.diamondstorage");

    struct Appstorage{
        string text;
        uint256 num;
        address owner;
    }

    function getStorage() internal pure returns (Appstorage storage s){
        bytes32 position = NAMESPACE;
        assembly{
            s.slot := position
        }
    }
}