// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./DiamondStorage.sol";

contract thirdlib {
    function _3readText()external view returns(string memory){
        return DiamondStorage.getStorage().text;
    }

    function _3readNum()external view returns(uint256){
        return DiamondStorage.getStorage().num;
    }

    function _3setText(string memory _text)external{
        DiamondStorage.getStorage().text = _text;
    
    }
    function _3setAnothertext(string memory _anothertext)external{
        DiamondStorage.getStorage().anothertext = _anothertext;
    
    }
}
// editread 0x3D2827370b6076d33a5aB5135E1CB87A84c13DeD
//second 0xd8Bf767e4124F5729A9e5fcEfC78f2687196Cb52
//third 0x8EED6A3853d992f104359Cc904c9AB8b1CA4f7Ea

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library DiamondStorage{

    bytes32 internal constant NAMESPACE = keccak256("namespace.var.diamondstorage");

    struct Appstorage{
        string text;
        string anothertext;
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