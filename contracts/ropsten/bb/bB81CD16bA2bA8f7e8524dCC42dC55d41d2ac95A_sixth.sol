/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// File: sixth_flat.sol



// File: diamonds/DiamondStorage.sol





pragma solidity ^0.8.8;



library DiamondStorage{



    bytes32 internal constant NAMESPACE = keccak256("namespace.var.diamondstorage");



    struct Appstorage{

        string text;

        uint256 num;

        address owner;

        string anothertext;

    }



    function getStorage() internal pure returns (Appstorage storage s){

        bytes32 position = NAMESPACE;

        assembly{

            s.slot := position

        }

    }

}



//notes



// Diamond contract 0x866c504C4F4cAa5cE762e20Eb028Cd8340C2Bd91



// modifying the var position, can affect the old var and the new one, it cause lose data



//TODO

// pending to try like aavegotchi vars without getStorage() func - READY, is possible, but may crash the vars



// File: diamonds/sixth.sol





pragma solidity ^0.8.8;





contract sixth {

    function _6readText()external view returns(string memory){

        return DiamondStorage.getStorage().text;

    }



    function _6readAnotherText()external view returns(string memory){

        return DiamondStorage.getStorage().anothertext;

    }



    function _6readNum()external view returns(uint256){

        return DiamondStorage.getStorage().num;

    }



    function _6setText(string memory _text)external{

        DiamondStorage.getStorage().text = _text;

    

    }

    function _6setNum(uint256 _num)external{

        DiamondStorage.getStorage().num = _num;

    

    }

    function _6setAnothertext(string memory _anothertext)external{

        DiamondStorage.getStorage().anothertext = _anothertext;

    

    }

}

// editread 0x3D2827370b6076d33a5aB5135E1CB87A84c13DeD

//second 0xd8Bf767e4124F5729A9e5fcEfC78f2687196Cb52

//third 0x8EED6A3853d992f104359Cc904c9AB8b1CA4f7Ea

//sixth