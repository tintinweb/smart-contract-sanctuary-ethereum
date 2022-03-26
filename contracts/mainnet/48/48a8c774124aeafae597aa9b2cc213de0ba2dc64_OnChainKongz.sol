/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                            @@                               //    
//                                         @@@,,@@(                            //    
//                                     @@@@@@@@@,,#@@@@@@@@@                   //    
//                                @@@@@**,,,,,,,,,,,,,,,,,,,@@@@@              //    
//                           @@@@@**,,,,,,,,,,****,,,,,,,,,,,,,,,@@            //    
//                         @@***,,,,,,,@@@@@@@*******,,,,,@@@@***,,@@          //    
//                       @@**,,,,,,,@@@&&&&%%%@@@@#**,,,,,,,@@@@@,,@@          //    
//                    @@@,,,,,,,**@@%%%%%&&%%%%%%%&@@**,,,,,@@@@@**,,@@@       //    
//                  @@@@@**,,,,,@@%%%%%&&%%&&&%%%%%%%@@,,,,,@@%%%@@**@@@       //    
//                @@@@***,,,,@@@%%&&%%%&&%%&&&%%%%%%%@@***,,@@&&&%%@@          //    
//                @@@@***,,@@&&&&&&&&&&&&&&&&&&&%%%%%@@***@@%%&&&&&&&@@@       //    
//             @@@&&@@***@@@@&&&&&&&@@@@@@@@@@&&&&&&&@@***@@@@@@@@@&&@@@       //    
//             @@@@@@@***@@%%&&&@@@@(((///////@@@@@&&&&@@@@@/////**@@          //    
//           @@&&&&&&&@@@&&&&@@@%%((///***********#@@@@@@@%%//*******@@@       //    
//        (@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       //    
//      @@@&&&&@@@((((@@@@@&&###%%%%(((((*********,,,,,...  ,,,,,  **///       //    
//    @@@@@@@@@///**@@@@@**&&@@@((((**********,,,,...  ,,,,,  ***////(((       //    
// [email protected]@@@@&&@@///**@@%%%&&&&@@@%%((///****,,,,,..   *********/////(((((       //    
// [email protected]@&&&&&@@///**@@@@@**&&%%%@@%%(((/////////@@@@@@@///@@@@@@@**@@          //    
// [email protected]@@@@&&&&@@@////*******&&&%%@@@@@@@(((((((@@&%%@@(((@@##@@@**@@          //    
// @@@&&@@@@@@@&&&@@///////@@&&&&&&&&&&&&@@///(((((((////////////////@@@       //    
// @@@&&&&&&&&&@@@@@@@@@@@@&&&&&&&&&&&&@@/////***********************///@@     //    
// &&&&&&&&&&&&@@@@@@@&&&&&&&&&&&&&&@@@////*****************************@@     //    
// &&&&&@@&%%%%@@@%%%%%%%%%%%%%%&&&&@@@((//@@@@@@@@@@@@@@@@@@@@@@@@@@***@@     //    
// &&&&&&&&&&%%%%%%%%%%%%%%%%%%%&&@@@@@((//((((((((((//////////////((@@@       //    
// &&&&&&&&%%%%%%%%%%%&&&%%%%%%%&&&&@@@%%((//////////****************@@@       //    
// &&&&&%%&&&&&%%%&&%%%%%%%%%%%%&&@@@@@@@%%(((////*****************@@          //    
// @@@&&&&&@@%%&&&&&%%%%%&&&&%%%&&&&&&&&&@@(((///////////////////@@&&@@@       //    
// &&&&&&&&&&%%&&&&&%%%%%&&%%%%%&&&&%%%@@@@@@@@@@@@@@@@@@@@@@@@@@%%&&&&&@@     //    
// &&&&&&&&&&%%&&&&&&&%%%&&&&%%%&&%%%%%%%&&@@@@@@@@@@&&@@@&&&&%%%&&%%%%%&&@@   //    
// @@@&&&&&&&&&&&&&&%%&&&&&@@&&&&&%%%%%%%&&&&&@@&&&&&&&%%%&&%%%%%%%%%&&&%%@@   //    
// @@@&&&&&&&&&&&&%%&&@@@&&&&&&&&&&&&&&&&&&&&&&&%%%%%&&&&&%%%%%%%%%%%%%%&&&&@@@//    
/////////////////////////////////////////////////////////////////////////////////
//           ____             __        _        __ __                         //
//          / __ \___    ____/ /  ___ _(_)__    / //_/__  ___  ___ ____        //
//         / /_/ / _ \  / __/ _ \/ _ `/ / _ \  / ,< / _ \/ _ \/ _ `/_ /        //
//         \____/_//_/  \__/_//_/\_,_/_/_//_/ /_/|_|\___/_//_/\_, //__/        //
//         By: 0xInuarashi.eth                               /___/             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


interface iKongz {
    function tokenNameByIndex(uint256 tokenId_) external view returns (string memory);
    function bio(uint256 tokenId_) external view returns (string memory);
    function kongz(uint256 tokenId_) external view returns (uint256[2] memory);
}

interface iRender {
    function G_Hats(uint32 traitId_) external view returns (string[2] memory);
    function G_Eyes(uint32 traitId_) external view returns (string[2] memory);
    function G_Accessory(uint32 traitId_) external view returns (string[2] memory);
    function G_Mouth(uint32 traitId_) external view returns (string[2] memory);
    function G_Face(uint32 traitId_) external view returns (string[2] memory);
    function G_Body(uint32 traitId_) external view returns (string[2] memory);
    function G_Background(uint32 traitId_) external view returns (string[2] memory);
    function B_Hats(uint32 traitId_) external view returns (string[2] memory);
    function B_Eyes(uint32 traitId_) external view returns (string[2] memory);
    function B_Accessory(uint32 traitId_) external view returns (string[2] memory);
    function B_Mouth(uint32 traitId_) external view returns (string[2] memory);
    function B_Face(uint32 traitId_) external view returns (string[2] memory);
    function B_Body(uint32 traitId_) external view returns (string[2] memory);
    function B_Background(uint32 traitId_) external view returns (string[2] memory);
}

interface iLK {
    function ghostKongz() external view returns (string memory);
    function kongBot() external view returns (string memory);
    function skeletonKongz() external view returns (string memory);
    function diverKongz() external view returns (string memory);
    function astroKongz() external view returns (string memory);
    function pilotKongz() external view returns (string memory);
    function devilKongz() external view returns (string memory);
    function sithKongzPart1() external view returns (string memory);
    function sithKongzPart2() external view returns (string memory);
    function knightKongzPart1() external view returns (string memory);
    function knightKongzPart2() external view returns (string memory);
    function highKongzPart1() external view returns (string memory);
    function highKongzPart2() external view returns (string memory);
    function matabishi() external view returns (string memory);
}

interface iInc {
    function incubator() external view returns (string memory);
}

contract OnChainKongz { 

    // Ownable Mini
    address owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner, "Not Owner"); _; }
    function transferOwnership(address newOwner_) external onlyOwner { 
        owner = newOwner_; 
    }

    // Interfaces
    iKongz public constant Kongz = iKongz(0x57a204AA1042f6E66DD7730813f4024114d74f37);
    // iKongz public Kongz = iKongz(0x57a204AA1042f6E66DD7730813f4024114d74f37);
    // function setKongz(address address_) external onlyOwner {
    //     Kongz = iKongz(address_);
    // }

    iRender public G_Hats =         iRender(0x8fCe50899f315dBb9F16d13149C04DF1Cf246857);
    iRender public G_Eyes =         iRender(0xBBdAbAf1a0aeca577d09238dc3666eB3d12fb601);
    iRender public G_Accessory =    iRender(0xF5944676D8eFe4a282868A9835345A966fFCDb67);
    iRender public G_Mouth =        iRender(0x7f40edb90A0C6140478c7ceb613825eA2a1C2cb4);
    iRender public G_Face =         iRender(0x0b509950e1bd953f4B61f5aD4e03e6545587C1E6);
    iRender public G_Body =         iRender(0x040584325326F4A722E11D725dfD32F92F803A29);
    iRender public G_Background =   iRender(0x9d90994210df742fa1476c154c4d8bccC1AAe571);
    function setG_Assets(address[] calldata addresses_) external onlyOwner {
        require(addresses_.length == 7,
            "You must set all 7 G_Renders!");
        
        G_Hats =            iRender(addresses_[0]);
        G_Eyes =            iRender(addresses_[1]);
        G_Accessory =       iRender(addresses_[2]);
        G_Mouth =           iRender(addresses_[3]);
        G_Face =            iRender(addresses_[4]);
        G_Body =            iRender(addresses_[5]);
        G_Background =      iRender(addresses_[6]);
    }

    iRender public B_Hats =         iRender(0x1a18CE959880EEAc330Aa55Eb75F7B30971dABee);
    iRender public B_Eyes =         iRender(0x1FE59763aD3884680A669B9957Bb2a0c5f9d4026);
    iRender public B_Accessory =    iRender(0x20ad65Cd01bB6C268686bbc48aCCE4e05308a345);
    iRender public B_Mouth =        iRender(0x5612172440693b6312695A1Ad7218BC9647Eae57);
    iRender public B_Face =         iRender(0x5a2F719b0bB35909de771eF9EAFF4DcBF78D1220);
    iRender public B_Body =         iRender(0x56CD030CFA6bba56E062ffFCb4F180d7639AC729);
    iRender public B_Background =   iRender(0x48B07352FC77f7b0344C9495b267c1baB4D09702);
    function setB_Assets(address[] calldata addresses_) external onlyOwner {
        require(addresses_.length == 7,
            "You must set all 7 B_Renders!");
        
        B_Hats =            iRender(addresses_[0]);
        B_Eyes =            iRender(addresses_[1]);
        B_Accessory =       iRender(addresses_[2]);
        B_Mouth =           iRender(addresses_[3]);
        B_Face =            iRender(addresses_[4]);
        B_Body =            iRender(addresses_[5]);
        B_Background =      iRender(addresses_[6]);
    }

    iLK public ghostKongz =         iLK(0x809b660DF37B76f0d5d33e7A6FF5bfC19eFFA14B);
    iLK public kongBot =            iLK(0x809b660DF37B76f0d5d33e7A6FF5bfC19eFFA14B);
    iLK public skeletonKongz =      iLK(0x809b660DF37B76f0d5d33e7A6FF5bfC19eFFA14B);
    iLK public diverKongz =         iLK(0x809b660DF37B76f0d5d33e7A6FF5bfC19eFFA14B);
    iLK public astroKongz =         iLK(0x809b660DF37B76f0d5d33e7A6FF5bfC19eFFA14B);
    iLK public pilotKongz =         iLK(0x809b660DF37B76f0d5d33e7A6FF5bfC19eFFA14B);
    iLK public devilKongz =         iLK(0x8e24D7d7bbb2c95ec183E40971860b9f947372a6);
    iLK public sithKongzPart1 =     iLK(0xaEF813fFF0fc3E27f70Fca0F5bC38A7AD67736ab);
    iLK public sithKongzPart2 =     iLK(0x16Bf612a299FF5b076395eDD023f2CF04e429a5d);
    iLK public knightKongzPart1 =   iLK(0x92B74a2C7F8b69F1493212655544ae7DD2833634);
    iLK public knightKongzPart2 =   iLK(0xAF0F6D63c82bCa37DDba4dc70c2FE7a28585e385);
    iLK public highKongzPart1 =     iLK(0x7dFc76d3533b3bfC177aB811d04b615619abe4aa);
    iLK public highKongzPart2 =     iLK(0x89904FeC136d8fBc462E19c62ed3967743660C41);
    iLK public matabishi =          iLK(0xfFA6D5C554d23382efFa4e2B2Ee1c2F33B4b8692);

    iInc public incubator =         iInc(0x6b12D9b15148cf322700D388452C48E6DCcFB668);

    // public Methods
    function _getDNA(uint256 tokenId_) public view returns (uint32[7] memory) {
        uint256[2] memory _kongzData = Kongz.kongz(tokenId_);
        uint256 _dna = _kongzData[0];
        return decodeDNA(_dna);
    }

    function decodeDNA(uint256 dna_) public pure returns (uint32[7] memory) {
        bytes32 _dna = bytes32(dna_);
        uint32[7] memory _dnas;

        for (uint256 i = 0; i < 7; i++) {
            _dnas[6-i] = uint32( bytes4(_dna << (32*(6-i)) ));
        }

        return _dnas;
    }

    function G_isMetadataShown(uint32 traitCategory_, uint32 traitId_) public pure 
    returns (bool) {
        if      (traitCategory_ == 0) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  ||
            traitId_ == 7  ||
            traitId_ == 8  ||
            traitId_ == 9  ||
            traitId_ == 10 ||
            traitId_ == 11 ||
            traitId_ == 12 ||
            traitId_ == 13 ||
            traitId_ == 14 ||
            traitId_ == 15 ||
            traitId_ == 16 ||
            traitId_ == 17 ||
            traitId_ == 18 ||
            traitId_ == 19 ||
            traitId_ == 20 ||
            traitId_ == 21 ||
            traitId_ == 22
            ) { return true; }
            else { return false; }
        }

        else if (traitCategory_ == 1) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  ||
            traitId_ == 7  ||
            traitId_ == 8  ||
            traitId_ == 9  ||
            traitId_ == 10 ||
            traitId_ == 11 ||
            traitId_ == 12 ||
            traitId_ == 13 ||
            traitId_ == 14 ||
            traitId_ == 15 
            ) { return true; }
            else { return false; }
        }
        
        else if (traitCategory_ == 2) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  ||
            traitId_ == 7  ||
            traitId_ == 8  ||
            traitId_ == 9  ||
            traitId_ == 10 ||
            traitId_ == 11 ||
            traitId_ == 12 ||
            traitId_ == 13 ||
            traitId_ == 14 
            ) { return true; }
            else { return false; }
        }
        
        else if (traitCategory_ == 3) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  
            ) { return true; }
            else { return false; }
        }
        
        else if (traitCategory_ == 4) {
            return false;
        }
        
        else if (traitCategory_ == 5) {
            if (
            traitId_ == 0
            ) { return true; }
            else { return false; }
        }
        
        else if (traitCategory_ == 6) {
            return false;
        }
        
        else return false;
    }
    function B_isMetadataShown(uint32 traitCategory_, uint32 traitId_) public pure
    returns (bool) {
        if      (traitCategory_ == 0) {
            return false;
        }
        else if (traitCategory_ == 1) {
            if (
            traitId_ == 0
            ) { return true; }
            else { return false; }
        }
        else if (traitCategory_ == 2) {
            return false;
        }
        else if (traitCategory_ == 3) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  ||
            traitId_ == 7  ||
            traitId_ == 8  
            ) { return true; }
            else { return false; }
        }
        else if (traitCategory_ == 4) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  ||
            traitId_ == 7  ||
            traitId_ == 8  ||
            traitId_ == 9  ||
            traitId_ == 10 ||
            traitId_ == 11 ||
            traitId_ == 12 ||
            traitId_ == 13 ||
            traitId_ == 14 
            ) { return true; }
            else { return false; }
        }
        else if (traitCategory_ == 5) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  ||
            traitId_ == 7  ||
            traitId_ == 8  ||
            traitId_ == 9  ||
            traitId_ == 10 
            ) { return true; }
            else { return false; }
        }
        else if (traitCategory_ == 6) {
            if (
            traitId_ == 0  ||
            traitId_ == 1  ||
            traitId_ == 2  ||
            traitId_ == 3  ||
            traitId_ == 4  ||
            traitId_ == 5  ||
            traitId_ == 6  ||
            traitId_ == 7  ||
            traitId_ == 8  ||
            traitId_ == 9  ||
            traitId_ == 10 ||
            traitId_ == 11 ||
            traitId_ == 12 ||
            traitId_ == 13 ||
            traitId_ == 14 ||
            traitId_ == 15 ||
            traitId_ == 16 ||
            traitId_ == 17 ||
            traitId_ == 18 ||
            traitId_ == 19 ||
            traitId_ == 20 ||
            traitId_ == 21 ||
            traitId_ == 22 ||
            traitId_ == 23 ||
            traitId_ == 24 ||
            traitId_ == 26 
            ) { return true; }
            else { return false; }
        }
        else return false;
    }

    function G_getTraitName(uint32 traitCategory_) public pure 
    returns (string memory) {
        if      (traitCategory_ == 0) return "Hat";
        else if (traitCategory_ == 1) return "Eyes";
        else if (traitCategory_ == 2) return "Accessories";
        else if (traitCategory_ == 3) return "Mouth";
        else if (traitCategory_ == 4) return "Face";
        else if (traitCategory_ == 5) return "Body";
        else if (traitCategory_ == 6) return "Background";
        else return "";
    }
    function B_getTraitName(uint32 traitCategory_) public pure 
    returns (string memory) {
        if      (traitCategory_ == 6) return "Hat";
        else if (traitCategory_ == 5) return "Eyes";
        else if (traitCategory_ == 4) return "Accessories";
        else if (traitCategory_ == 3) return "Mouth";
        else if (traitCategory_ == 2) return "Face";
        else if (traitCategory_ == 1) return "Body";
        else if (traitCategory_ == 0) return "Background";
        else return "";
    }

    function isLegendary(uint256 tokenId_) public pure returns (bool) {
        if      (tokenId_ == 1   ) return true; // Ghost Kongz
        else if (tokenId_ == 101 ) return true; // Kongbot
        else if (tokenId_ == 201 ) return true; // SkeletonKongz
        else if (tokenId_ == 301 ) return true; // DiverKongz
        else if (tokenId_ == 420 ) return true; // HighKongz
        else if (tokenId_ == 501 ) return true; // AstroKongz
        else if (tokenId_ == 666 ) return true; // Devil Kongz aka Coco D. Bear
        else if (tokenId_ == 701 ) return true; // Pilot Kongz
        else if (tokenId_ == 801 ) return true; // Knight Kongz
        else if (tokenId_ == 1000) return true; // Sith Kongz
        else if (tokenId_ == 1002) return true; // Matabishi
        else return false;
    }

    function getLegendaryBase64(uint256 tokenId_) public view 
    returns (string memory) {
        if      (tokenId_ == 1   ) return ghostKongz.ghostKongz();
        else if (tokenId_ == 101 ) return kongBot.kongBot();
        else if (tokenId_ == 201 ) return skeletonKongz.skeletonKongz();
        else if (tokenId_ == 301 ) return diverKongz.diverKongz();
        else if (tokenId_ == 420 ) return string(abi.encodePacked(highKongzPart1.highKongzPart1(), highKongzPart2.highKongzPart2()));
        else if (tokenId_ == 501 ) return astroKongz.astroKongz();
        else if (tokenId_ == 666 ) return devilKongz.devilKongz();
        else if (tokenId_ == 701 ) return pilotKongz.pilotKongz();
        else if (tokenId_ == 801 ) return string(abi.encodePacked(knightKongzPart1.knightKongzPart1(), knightKongzPart2.knightKongzPart2()));
        else if (tokenId_ == 1000) return string(abi.encodePacked(sithKongzPart1.sithKongzPart1(), sithKongzPart2.sithKongzPart2()));
        else if (tokenId_ == 1002) return matabishi.matabishi();
        else return "";
    }

    function getLegendaryTrait(uint256 tokenId_) public pure returns (string memory) {
        if      (tokenId_ == 1   ) return "Ghost";
        else if (tokenId_ == 101 ) return "Mech";
        else if (tokenId_ == 201 ) return "Skeleton";
        else if (tokenId_ == 301 ) return "Scuba Diver";
        else if (tokenId_ == 420 ) return "Stoner";
        else if (tokenId_ == 501 ) return "Astronaut";
        else if (tokenId_ == 666 ) return "Devil";
        else if (tokenId_ == 701 ) return "Pilot";
        else if (tokenId_ == 801 ) return "Knight";
        else if (tokenId_ == 1000) return "Dark";
        else return "";

    }
    
    function toString(uint256 value_) public pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Base64 Encoder
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encodeBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }
        return result;
    }

    string public constant _svgHeader = "<svg id='cyberkongz' width='100%' height='100%' version='1.1' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>";
    string public constant _svgFooter = "'/><style>#cyberkongz{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

    function _imageWrapper(bool first_) public pure returns (string memory) {
        string memory _wrapper = "<image x='0' y='0' width='60' height='60' image-rendering='pixelated' preserveAspectRatio='xMidYMid' xlink:href='data:image/png;base64,";
        if (!first_) _wrapper = string(abi.encodePacked("'/>", _wrapper));
        return _wrapper;
    }

    function _G_renderTrait(uint32 traitCategory_, uint32 traitId_, bool last_) 
    public view returns (string memory) {
        string memory _trait = string(abi.encodePacked(
            '{"trait_type":"',
            // G_getTraitName(traitCategory_),
            'Genesis Trait',
            '","value":"'
        ));

        if (traitCategory_ == 0) _trait = string(abi.encodePacked(
            _trait, G_Hats.G_Hats(traitId_)[0]
        ));
        if (traitCategory_ == 1) _trait = string(abi.encodePacked(
            _trait, G_Eyes.G_Eyes(traitId_)[0]
        ));
        if (traitCategory_ == 2) _trait = string(abi.encodePacked(
            _trait, G_Accessory.G_Accessory(traitId_)[0]
        ));
        if (traitCategory_ == 3) _trait = string(abi.encodePacked(
            _trait, G_Mouth.G_Mouth(traitId_)[0]
        ));
        if (traitCategory_ == 4) _trait = string(abi.encodePacked(
            _trait, G_Face.G_Face(traitId_)[0]
        ));
        if (traitCategory_ == 5) _trait = string(abi.encodePacked(
            _trait, G_Body.G_Body(traitId_)[0]
        ));
        if (traitCategory_ == 6) _trait = string(abi.encodePacked(
            _trait, G_Background.G_Background(traitId_)[0]
        ));

        string memory _footer = last_ ? '"}' : '"},';
        
        _trait = string(abi.encodePacked(
            _trait,
            _footer
        ));      

        return _trait;
    }
    function _B_renderTrait(uint32 traitCategory_, uint32 traitId_, bool last_) 
    public view returns (string memory) {
        string memory _trait = string(abi.encodePacked(
            '{"trait_type":"',
            // B_getTraitName(traitCategory_),
            'Baby Trait',
            '","value":"'
        ));

        if (traitCategory_ == 6) _trait = string(abi.encodePacked(
            _trait, B_Hats.B_Hats(traitId_)[0]
        ));
        if (traitCategory_ == 5) _trait = string(abi.encodePacked(
            _trait, B_Eyes.B_Eyes(traitId_)[0]
        ));
        if (traitCategory_ == 4) _trait = string(abi.encodePacked(
            _trait, B_Accessory.B_Accessory(traitId_)[0]
        ));
        if (traitCategory_ == 3) _trait = string(abi.encodePacked(
            _trait, B_Mouth.B_Mouth(traitId_)[0]
        ));
        if (traitCategory_ == 2) _trait = string(abi.encodePacked(
            _trait, B_Face.B_Face(traitId_)[0]
        ));
        if (traitCategory_ == 1) _trait = string(abi.encodePacked(
            _trait, B_Body.B_Body(traitId_)[0]
        ));
        if (traitCategory_ == 0) _trait = string(abi.encodePacked(
            _trait, B_Background.B_Background(traitId_)[0]
        ));

        string memory _footer = last_ ? '"}' : '"},';
        
        _trait = string(abi.encodePacked(
            _trait,
            _footer
        ));      

        return _trait;
    }

    function _renderLegendary(uint256 tokenId_) public view returns (string memory) {
        string memory _svg = string(abi.encodePacked(
            _svgHeader,
            _imageWrapper(true),
            getLegendaryBase64(tokenId_),
            _svgFooter
        ));
        
        return _svg;
    }

    function _G_renderSVG(uint32[7] memory _dnas) public view returns (string memory) {
        string memory _svg = string(abi.encodePacked(
            _svgHeader,
            _imageWrapper(true),
            G_Background.G_Background(_dnas[6])[1],
            _imageWrapper(false),
            G_Body.G_Body      (_dnas[5])[1],
            _imageWrapper(false),
            G_Face.G_Face      (_dnas[4])[1]
        ));

        _svg = string(abi.encodePacked(
            _svg,
            _imageWrapper(false),
            G_Mouth.G_Mouth     (_dnas[3])[1],
            _imageWrapper(false),
            G_Accessory.G_Accessory (_dnas[2])[1],
            _imageWrapper(false),
            G_Eyes.G_Eyes      (_dnas[1])[1],
            _imageWrapper(false)
        ));

        _svg = string(abi.encodePacked(
            _svg,
            G_Hats.G_Hats      (_dnas[0])[1],
            _svgFooter
        ));

        return _svg;
    }

    function _B_renderSVG(uint32[7] memory _dnas) public view returns (string memory) {
        bool _isBorn;

        for (uint32 i = 0; i < 7; i++) {
            if (_dnas[i] != 0) _isBorn = true;
        }

        if (_isBorn) {
            string memory _svg = string(abi.encodePacked(
                _svgHeader,
                _imageWrapper(true),
                B_Background.B_Background(_dnas[0])[1],
                _imageWrapper(false),
                B_Body.B_Body      (_dnas[1])[1],
                _imageWrapper(false),
                B_Face.B_Face      (_dnas[2])[1]
            ));

            _svg = string(abi.encodePacked(
                _svg,
                _imageWrapper(false),
                B_Mouth.B_Mouth     (_dnas[3])[1],
                _imageWrapper(false),
                B_Accessory.B_Accessory (_dnas[4])[1],
                _imageWrapper(false),
                B_Eyes.B_Eyes      (_dnas[5])[1],
                _imageWrapper(false)
            ));

            _svg = string(abi.encodePacked(
                _svg,
                B_Hats.B_Hats      (_dnas[6])[1],
                _svgFooter
            ));

            return _svg;
        }

        else {
            return string(abi.encodePacked(
                _svgHeader,
                _imageWrapper(true),
                incubator.incubator(),
                _svgFooter
            ));
        }
    }

    function _G_renderSVG(uint256 tokenId_) public view returns (string memory) {
        return isLegendary(tokenId_) ? _renderLegendary(tokenId_) : _G_renderSVG(_getDNA(tokenId_));
    }

    function _B_renderSVG(uint256 tokenId_) public view returns (string memory) {
        return isLegendary(tokenId_) ? _renderLegendary(tokenId_) : _B_renderSVG(_getDNA(tokenId_));
    }

    function _renderBirthday(uint256 tokenId_) public view returns (string memory) {
        return string(abi.encodePacked(
            '{"display_type":"date","trait_type":"birthday","value":',
            toString(Kongz.kongz(tokenId_)[1]),
            '}'
        ));
    }

    function _G_renderAttributes(uint256 tokenId_) public view returns (string memory) {
        bool _isLegendary = isLegendary(tokenId_);

        if (!_isLegendary) {
            uint32[7] memory _dnas = _getDNA(tokenId_);
            string memory _attributes = string(abi.encodePacked(
                '{"trait_type":"Type","value":"Genesis"}'
                // _renderBirthday(tokenId_),
                // ','
            ));

            // Find the last shown trait
            uint32 _lastTraitShown = 99;
            for (uint32 i = 0; i < 7; i++) {
                _lastTraitShown = G_isMetadataShown(i, _dnas[i]) ? i : _lastTraitShown;
            }

            if (_lastTraitShown != 99) {
                _attributes = string(abi.encodePacked(
                    _attributes,
                    ','
                ));
            }
            
            for (uint32 i = 0; i < 7; i++) {
                if (G_isMetadataShown(i, _dnas[i])) {
                    _attributes = string(abi.encodePacked(
                        _attributes,
                        _G_renderTrait(i, _dnas[i], (i == _lastTraitShown))
                    )); 
                }
            }

            return _attributes;
        }

        else {
            string memory _attributes = string(abi.encodePacked(
                '{"trait_type":"Type","value":"Genesis"},',
                '{"trait_type":"Legendary Trait","value":"',
                getLegendaryTrait(tokenId_),
                '"}'
            ));
            
            return _attributes;
        }
    }
    function _B_renderAttributes(uint256 tokenId_) public view returns (string memory) {
        uint32[7] memory _dnas = _getDNA(tokenId_);
        bool _isBorn;

        for (uint32 i = 0; i < 7; i++) {
            if (_dnas[i] != 0) _isBorn = true;
        }

        if (_isBorn) {
            string memory _attributes = string(abi.encodePacked(
                '{"trait_type":"Type","value":"Baby"}'
                // _renderBirthday(tokenId_),
                // ','
            ));

            // Find the last shown trait
            uint32 _lastTraitShown = 99;
            for (uint32 i = 0; i < 7; i++) {
                _lastTraitShown = B_isMetadataShown(i, _dnas[i]) ? i : _lastTraitShown;
            }

            if (_lastTraitShown != 99) {
                _attributes = string(abi.encodePacked(
                    _attributes,
                    ','
                ));
            }
            
            for (uint32 i = 0; i < 7; i++) {
                if (B_isMetadataShown(i, _dnas[i])) {
                    _attributes = string(abi.encodePacked(
                        _attributes,
                        _B_renderTrait(i, _dnas[i], (i == _lastTraitShown))
                    )); 
                }
            }

            return _attributes;
        } 
        
        else {
            return string(abi.encodePacked(
                '{"trait_type": "Type", "value": "Incubator"}'
            ));
        }
    }

    function renderAttributes(uint256 tokenId_) public view returns (string memory) {
        return tokenId_ <= 1000 ? _G_renderAttributes(tokenId_) 
            : _B_renderAttributes(tokenId_);
    }

    // Name and Bio
    string public _defaultName = "CyberKong"; 
    function setDefaultName(string calldata name_) external onlyOwner {
        _defaultName = name_;
    }

    bool public useDefaultBio;
    function setUseDefaultBio(bool bool_) external onlyOwner { 
        useDefaultBio = bool_;
    }

    string public _defaultBio = "Welcome to an alternate reality, where evolution took a different route and weird apes roam the earth. Some appear normal. Some look weird. And some are just damn cool! Every CyberKong is unique and owns randomized items with different rarities. A few are super rare and even animated! Maybe some of them look familiar!";
    function setDefaultBio(string calldata bio_) external onlyOwner {
        _defaultBio = bio_;
    }

    // // Static Names
    // function _getName(uint256 tokenId_) public pure returns (string memory) {
    //     return string(abi.encodePacked("CyberKongz # ", toString(tokenId_)));
    // }
    // function _getBio(uint256 tokenId_) public view returns (string memory) {
    //     return _defaultBio;
    // }

    function _getName(uint256 tokenId_) public view returns (string memory) {
        string memory _name = Kongz.tokenNameByIndex(tokenId_);
        string memory _newName = bytes(_name).length == 0 ? _defaultName : _name;
        return string(abi.encodePacked(
            _newName,
            ' #',
            toString(tokenId_)
        ));
    }
    function _getBio(uint256 tokenId_) public view returns (string memory) {
        string memory _bio = Kongz.bio(tokenId_);
        string memory _default = useDefaultBio ? _defaultBio : "";
        return bytes(_bio).length == 0 ? _default : _bio;
    }

    // SVG Image
    function renderSVG(uint256 tokenId_) public view returns (string memory) {
        return tokenId_ <= 1000 ? _G_renderSVG(tokenId_) : _B_renderSVG(tokenId_);
    }

    // Metadata
    string public constant _metaHeader = 'data:application/json;base64,';

    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        string memory _metadata = string(abi.encodePacked(
            '{"name":"',
            _getName(tokenId_),
            '", "description":"',
            _getBio(tokenId_),
            '", "image": "data:image/svg+xml;base64,'
        ));

        _metadata = string(abi.encodePacked(
            _metadata,
            encodeBase64(bytes(renderSVG(tokenId_))),
            '","attributes": ['
        ));

        _metadata = string(abi.encodePacked(
            _metadata,
            renderAttributes(tokenId_),
            ']}'
        ));

        return string(abi.encodePacked(
            _metaHeader,
            encodeBase64(bytes(_metadata))
        ));
    }
    function raw_tokenURI(uint256 tokenId_) public view returns (string memory) {
        string memory _metadata = string(abi.encodePacked(
            '{"name":"',
            _getName(tokenId_),
            '", "description":"',
            _getBio(tokenId_),
            '", "image": "data:image/svg+xml;base64,'
        ));

        _metadata = string(abi.encodePacked(
            _metadata,
            encodeBase64(bytes(renderSVG(tokenId_))),
            '","attributes": ['
        ));

        _metadata = string(abi.encodePacked(
            _metadata,
            renderAttributes(tokenId_),
            ']}'
        ));

        return string(abi.encodePacked(
            _metaHeader,
            _metadata
        ));
    }
}