// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DiamondStorage.sol";

contract secondlib {


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
// editread 0x3D2827370b6076d33a5aB5135E1CB87A84c13DeD
//second 0x40CE49A24285056910789fD9c6E2e3189e2e57b4

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