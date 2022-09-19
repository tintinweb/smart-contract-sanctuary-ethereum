// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Appstorage} from "./DiamondStorage.sol";

contract fifth {
    Appstorage internal s;
    function _5readText()external view returns(string memory){
        return s.text;
    }
    function _5readAnotherText()external view returns(string memory){
        return s.anothertext;
    }

    function _5readNum()external view returns(uint256){
        return s.num;
    }

    function _5setText(string memory _text)external{
        s.text = _text;
    
    }
    function _5setAnothertext(string memory _anothertext)external{
        s.anothertext = _anothertext;
    
    }
}
// editread 0x3D2827370b6076d33a5aB5135E1CB87A84c13DeD
//second 0xd8Bf767e4124F5729A9e5fcEfC78f2687196Cb52
//third 0x8EED6A3853d992f104359Cc904c9AB8b1CA4f7Ea
// fourth 0x538885fF262E7E97040bE893569C2A50898eFE36
// fifth 0xBF539c525955daAE0824491348Ac201cde1C9BC8

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// library DiamondStorage{

//     bytes32 internal constant NAMESPACE = keccak256("namespace.var.diamondstorage");

//     struct Appstorage{
//         string text;
//         string anothertext;
//         uint256 num;
//         address owner;
//     }

//     function getStorage() internal pure returns (Appstorage storage s){
//         bytes32 position = NAMESPACE;
//         assembly{
//             s.slot := position
//         }
//     }
// }

    struct Appstorage{
        string text;
        string anothertext;
        uint256 num;
        address owner;
    }

//notes

// Diamond contract 0x866c504C4F4cAa5cE762e20Eb028Cd8340C2Bd91

// modifying the var position, can affect the old var and the new one, it cause lose data

//TODO
// pending to try like aavegotchi vars without getStorage() func
// pending to try reduce  DiamondStorage.getStorage() with Xstore storage s =  DiamondStorage.getStorage()