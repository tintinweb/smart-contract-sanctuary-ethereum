// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DiamondStorage.sol";

contract secondlib {


    function _readText()external view returns(string memory){
        return DiamondStorage.getStorage().text;
    }

    function _readNum()external view returns(uint256){
        return DiamondStorage.getStorage().num;
    }

    function _setText(string memory _text)external{
        DiamondStorage.getStorage().text = _text;
    
    }

    function _setNum(uint256 _num)external{
        DiamondStorage.getStorage().num = _num;
    }
}
// editread 0x3D2827370b6076d33a5aB5135E1CB87A84c13DeD
//second 0xd8Bf767e4124F5729A9e5fcEfC78f2687196Cb52

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