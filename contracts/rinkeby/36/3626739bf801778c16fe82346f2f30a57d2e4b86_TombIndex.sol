//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????: 
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B [email protected]@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7 
//    [email protected]@@@@#                                                                [email protected]@@@@@ [email protected]@@@@G                                 
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~   
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B  
//         [email protected]@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J 
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&[email protected]@@@@@! 
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7  
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^    

//  _______________________________________________________ Tomb Series  ___________________________________________________

//       :!JYYYYJ!.                   .JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?~.   7YYYYYYYYY?~.              ^JYYYYYYYYY^ 
//     ~&@@@@@@@@@@#7.                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P  &@@@@@@@@@@@@B!           :@@@@@@@@@@@5 
//    ^@@@@@@[email protected]@@@@@@B!              [email protected]@@@@&PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@@@# JGGGGGGG#@@@@@@@G^         !PGGGGGGGGG! 
//    [email protected]@@@@5  .7#@@@@@@@P^           [email protected]@@@@P                                [email protected]@@@@@.         .J&@@@@@@&5:                   
//    [email protected]@@@@Y     .J&@@@@@@&5:        [email protected]@@@@G                                 @@@@@@.            :Y&@@@@@@&J.                
//    [email protected]@@@@5        :5&@@@@@@&J.     [email protected]@@@@G                                 @@@@@@.               ^[email protected]@@@@@@#7.             
//    [email protected]@@@@5           ^[email protected]@@@@@@#7.  [email protected]@@@@G                                 @@@@@@.                  [email protected]@@@@@@B!           
//    [email protected]@@@@5              [email protected]@@@@@@[email protected]@@@@@! PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@# JGPPPPPPPP5:        .7#@@@@@@@GPPPPPPG~ 
//    [email protected]@@@@5                .7#@@@@@@@@@@&! [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G  &@@@@@@@@@@&           .J&@@@@@@@@@@@@5 
//    ^5YYY5~                   .!JYYYYY7:    Y5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~.   ?5YYYYYYY5J.              :7JYYYYYYYY5^ 

//  _______________________________________________________ Tomb Index  _____________________________________________________

// _________________________________________________ Deployed by TERRAIN 2022 _______________________________________________

// _____________________________________________ All tombs drawn by David Rudnick ___________________________________________

// ______________________________________________ Contract architect: Luke Miles ____________________________________________


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./lib.sol";

contract TombIndex is ERC721, Ownable {
    string public imageURI;
    bool public isFrozen;

    event TombUpdated(uint256 id);
    string[] private houses = ["GENESIS", "LUX", "X2", "SHADOW", "COMETS", "DEVASTATORS", "TERRA", "RONIN"];

    struct deployment {
        uint16 chainID;
        bool deployed;
        address hostContract;
        uint256 tokenID;
    }

    struct Tomb {
        bool _initialized;
        uint32 weight;
        uint8 numberInHouse;
        uint house;
        deployment deployment;
    }

    mapping(uint8 => Tomb) public tombByID;
    mapping(uint8 => string) public tombNameByID;

    constructor(
        string memory _imageURI,
        address artistAddress
    ) ERC721("Tomb Series", "TOMB") {
        _initializeTombs(artistAddress);
        imageURI = _imageURI;
    }

    function freezeContract() public onlyOwner {
        isFrozen = true;
    }

    modifier notFrozen() {
        require(!isFrozen, "Contract is frozen");
        _;
    }

    function _saveTomb(uint256 id, string memory name, Tomb memory tomb) internal {
        require(id > 0 && id <= 177, "Tomb out of bounds");
        uint8 id8 = uint8(id);
        tombByID[id8] = tomb;
        tombNameByID[id8] = name;
        emit TombUpdated(id);
    }

    function saveTombs(uint256[] calldata ids, string[] calldata names, Tomb[] calldata tombs) public onlyOwner notFrozen {
        require(ids.length == tombs.length, "invalid input");
        require(names.length == tombs.length, "invalid input");
        for (uint256 i = 0; i < tombs.length; i++) {
            _saveTomb(ids[i], names[i], tombs[i]);   
        }
    }

    function _initializeTombs(address artistAddress) internal onlyOwner {
        _saveTomb(1, "AEON", Tomb({
            _initialized: true,
            weight: 18762694,
            numberInHouse: 1,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20583,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(2, "TAROT", Tomb({
            _initialized: true,
            weight: 21598168,
            numberInHouse: 2,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20586,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(3, "CADMIUM", Tomb({
            _initialized: true,
            weight: 24129641,
            numberInHouse: 3,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20592,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(4, "NIAGARA", Tomb({
            _initialized: true,
            weight: 22108549,
            numberInHouse: 4,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20609,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(5, "ARK", Tomb({
            _initialized: true,
            weight: 23257493,
            numberInHouse: 5,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20614,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(6, "ORION", Tomb({
            _initialized: true,
            weight: 23205361,
            numberInHouse: 6,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20616,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(7, "MIDNIGHT", Tomb({
            _initialized: true,
            weight: 19431160,
            numberInHouse: 7,
            house: 0,
            deployment: deployment({
                hostContract: 0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405,
                tokenID: 20617,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(8, "ORIGIN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(9, "TURING", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(10, "HOME", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(11, "EPOCH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(12, "TEMPO", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(13, "THE NEW JEWS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(14, "ORIGIN UNKNOWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(15, "HEAT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(16, "FFF", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(17, "NEW FORM ZONE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(18, "ANAMNESIS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(19, "SYNTAX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(20, "NUXUI-N", Tomb({
            _initialized: true,
            weight: 18447712,
            numberInHouse: 3,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(21, "EQUINOX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(22, "EUROPE AFTER THE RAIN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(23, "SEA OF SQUARES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(24, "STORM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(25, "FANTAZIA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(26, "DREAMSCAPE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(27, "HYPERSPECTRAL DAWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(28, "SKYLINE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(29, "KHAOS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(30, "ON REMAND", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(31, "OUTER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(32, "ORDER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(33, "ALPHA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 1,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(34, "VAPOUR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(35, "HYPER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(36, "EXODUS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(37, "DAWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(38, "TOTAL ECLIPSE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(39, "VANISHING POINT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(40, "FAINT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(41, "IRIDIUM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(42, "KILO", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(43, "CENSER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(44, "QUARTO", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(45, "KINGFISHER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(46, "UNITE OR PERISH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(47, "NANGA PARBAT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(48, "DUAL EVENT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(49, "OPACITY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(50, "NEXUS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(51, "POINT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(52, "HALON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(53, "VOID", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(54, "EXCEEDING LIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(55, "BLACK HOLES IN THE NOW", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(56, "UNKNOWN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(57, "TRANSPARENCY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(58, "UNANIMOUS NIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(59, "GHOST", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(60, "ENTIRE WORLDS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(61, "ANTIGEN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(62, "FREED FROM DESIRE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(63, "PARADISE CONQUISTADORS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(64, "HARD LEADERS II", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(65, "WHITE 001", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(66, "JUNGLIST", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(67, "VOID ARROWS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(68, "EARTH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(69, "THE KNOT TIES ITSELF", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 6,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(70, "DEATH IMITATES LANGUAGE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(71, "NECTAR AND LIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(72, "RECUR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(73, "PAX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 2,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(74, "FLOW COMA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(75, "TOTAL XSTACY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(76, "TRAGEDY [FOR YOU]", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(77, "VERDANT PERJURY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(78, "ACEN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(79, "PROTOCOL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(80, "NONREAL PACKET MAZE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(81, "ABSOLUTE POWER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(82, unicode"TANTŌ", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(83, "JAG MANDIR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(84, "NATION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(85, "SESSION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(86, "HERE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 20,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(87, "TACTA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 21,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(88, "WING OF A BLUE ROLLER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 7,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(89, "SHADDAI", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 3,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(90, "DEFENSOR MUNDI", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(91, "TIME PASSES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 22,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(92, "DYNAMICS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 23,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(93, "CONFUSION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 24,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(94, unicode"IDEEËN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 25,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(95, "ZEITUNG", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 26,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(96, "MONUMENT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 27,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(97, "ENERGY REMAINS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 28,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(98, "HACKED AMAZON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(99, "SUPRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 8,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(100, unicode"ÆTHER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 4,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(101, "RADAR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(102, "ARRAY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(103, "QUADRATIC EMPIRE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(104, "ENERGY FLASH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(105, "INTO DREAMS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(106, "SLOW", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(107, "VENOM HORIZON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(108, "2099", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 20,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(109, "LEMUR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(110, "SUBTROPICAL SHRINES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(111, "TERRAIN", Tomb({
            _initialized: true,
            weight: 22862184,
            numberInHouse: 10,
            house: 7,
            deployment: deployment({
                hostContract: address(this),
                tokenID: 111,
                chainID: 1,
                deployed: true
            })
        }));

        _saveTomb(112, "AEGIS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 9,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(113, "VIBE SARCOPHAGI", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(114, "HALCYON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 21,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(115, "JOYRIDER 2", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 22,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(116, "WORLD [PRICE OF LOVE]", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 23,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(117, "OZYMANDIAS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(118, "FOREVER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(119, "FRONTIER", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 10,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(120, "STRAYLIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(121, "HYDRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(122, "SWIFT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(123, "ANON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(124, "INDEX", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 20,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(125, "HARD TARGET", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 21,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(126, "BLACKBIRD", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 22,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(127, "OBSERVE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 23,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(128, "AFTER EARTH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 24,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(129, "UMBRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 25,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(130, "POEM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 26,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(131, "MONT BLANC", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 29,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(132, "TOURBILLON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 30,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(133, "CALIBAN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 31,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(134, "CYGNUS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 32,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(135, "VOYAGES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 33,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(136, "LOAM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 34,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(137, "HNX_T01", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 35,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(138, "ENDSTATE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 27,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(139, "TERMINAL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 28,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(140, "FORGERY", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 11,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(141, "NOMAD", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(142, "XENON", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(143, "REVEAL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 29,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(144, "LONE AND LEVEL", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 30,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(145, "PHANTOM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 31,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(146, "TRUE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 32,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(147, "STEALTH", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 33,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(148, "VANTA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 34,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(149, "KAIROS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 35,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(150, "SHADOW", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 36,
            house: 3,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(151, "TRANCE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(152, "REPLICA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 12,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(153, "THE FOG OF JUNK PSALMS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(154, "VALLEY OF THE SHADOWS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 24,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(155, "THE END", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 25,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(156, "PHOSPHOR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 26,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(157, "ABOUT PLATO'S CAVE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 17,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(158, "IX. SECTOR", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(159, "FICTION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 13,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(160, "SOLUTION", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(161, "TOPOS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 15,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(162, "LIGHT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 4,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(163, "THE BEZEL EPOQUE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 18,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(164, "I STILL DREAM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 27,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(165, "TIME PROBLEM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 28,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(166, "ARCOURS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 29,
            house: 5,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(167, "SELBSTVERSELBSTLICHUNG", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 19,
            house: 2,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(168, "ISENHEIM", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 14,
            house: 6,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(169, unicode"T1A–T [RONIN]", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 16,
            house: 7,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(170, "ETERNA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 5,
            house: 1,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(171, "EMPYREAN", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 36,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(172, "TACIT BLUE", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 37,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(173, "ARDENNES", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 38,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(174, "VOYAGES 2", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 39,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(175, "INPUT", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 40,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(176, "ULTRA", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 41,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _saveTomb(177, "GENESIS", Tomb({
            _initialized: true,
            weight: 0,
            numberInHouse: 42,
            house: 0,
            deployment: deployment({
                hostContract: 0x0000000000000000000000000000000000000000,
                tokenID: 0,
                chainID: 0,
                deployed: false
            })
        }));

        _mint(artistAddress, 111);
    }

    function setImageURI(string memory _url) public onlyOwner notFrozen {
        imageURI = _url;
    }

    function _tombName(uint8 id) internal view returns (string memory) {
        return string(abi.encodePacked("Tomb ", RomanNumeral.ofNum(id), unicode' — ', tombNameByID[id]));
    }

    function _ordinalString(uint8 number) internal pure returns (string memory) {
        if (number <= 0) {
            return "0";
        }

        string memory suffix = "th";
        uint8 j = number % 10;
        uint8 k = number % 100;

        if (j == 1 && k != 11) {
            suffix = "st";
        } else if (j == 2 && k != 12) {
            suffix = "nd";
        } else if (j == 3 && k != 13) {
            suffix = "rd";
        }

        return string(abi.encodePacked(_u256toString(number), suffix));
    }

    function _tombDescription(uint8 id, Tomb memory tomb) internal view returns (string memory) {
        return string(abi.encodePacked(tombNameByID[id], " is the ", _ordinalString(id), " Tomb in the Tomb Series. It is the ", _ordinalString(tomb.numberInHouse), " Tomb in the ",
            houses[tomb.house], " house, at a weight of ", _periodSeparatedNum(tomb.weight), "."));
    }

    function ownerOfTomb(uint8 id) public view returns (address) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        require(tomb.deployment.chainID == 1, "Can only check ownership value for Ethereum mainnet based Tombs");
        return ERC721(tomb.deployment.hostContract).ownerOf(tomb.deployment.tokenID);
    }

    function _makeAttribute(string memory name, string memory value, bool isJSONString) internal pure returns (string memory) {
        string memory strDelimiter = '';
        if (isJSONString) {
            strDelimiter = '"';
        }

        return string(abi.encodePacked(
            '{"trait_type":"', name, '","value":', strDelimiter, value, strDelimiter, '}'
        ));
    }

    function jsonForTomb(uint8 id) public view returns (bytes memory) {
        Tomb memory tomb = tombByID[id];
        require(tomb._initialized, "Tomb doesn't exist");
        return abi.encodePacked('{"name":"',_tombName(id),
                '","description":"', _tombDescription(id, tomb),
                '","image":"',
                imageURI, _u256toString(id), '.png","attributes":[', 
                _makeAttribute('House', houses[tomb.house], true), ',',
                _makeAttribute('Weight', _u256toString(tomb.weight), false), ',',
                _makeAttribute('Number in house', _u256toString(tomb.numberInHouse), false),
              ']}');
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(jsonForTomb(uint8(id)))));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }

    function _concatDotParts(string memory base, uint256 part, bool needsDot) internal pure returns (string memory) {  
        string memory glue = ".";
        if (!needsDot) {
            glue = "";
        }

        return string(abi.encodePacked(_u256toString(part), glue, base));
    }

    function _periodSeparatedNum(uint256 value) internal pure returns (string memory) {
        string memory result = "";
        uint128 index;
        while(value > 0) {
            uint256 part = value % 10;
            bool needsDot = index != 0 && index % 3 == 0;

            result = _concatDotParts(result, part, needsDot);
            value = value / 10;
            index += 1;
        }
 
        return result;
    }

    function _u256toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed output.
                success := 0
            }
        }
    }
}
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
error NumberTooBig();

// Only includes information to encode a subset of roman numerals
library RomanNumeral {
    function ofNum(uint n) internal pure returns (string memory) {
        uint8[9] memory key = [100, 90, 50, 40, 10, 9, 5, 4, 1];
        string[9] memory numerals = ["C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        if (n >= 400) revert NumberTooBig();
        bytes memory res = "";
        for (uint i = 0; i < key.length; i++) {
            while (n >= key[i]) {
                n -= key[i];
                res = abi.encodePacked(res, numerals[i]);
            } 
        }
        return string(res);
    }
}