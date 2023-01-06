// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract dataPoints {
    uint256[365] public points;
}

contract AInspiration {
    uint256[4] colors =[
        24066577235375297085971535403738548135016062406472700414573393295897994142224,
        29435790778697023544073812981973364591917375865438874992895174236349192688913,
        23582564667309630432401974638787966993633956084611825904573132888052585275921,
        87942784784877401446432867171348959454979876838046004956601547756354
    ];
    uint256[24] palettes = [
        1669818191555439946056615641677821030291262219801108036404377734994722815,
        1697558914912415785758807769538416997275336105957535357676861135322611637,
        1676772494938209514295252245138238388363876460146223723126638219230183423,
        1690924897136532352123750948368779589802805921709266280929042418204934087,
        1690709221218667771805135708614913064650943568574965308328881152692584391,
        1690709167739925220685290679031702021353709699599023560741912611685138431,
        795843513696767927636713408451257626308121108354474154509628195756572671,
        428320549903823041774426368985668659717347365096027118253420563866306503,
        83449143824075386490141232574190263674405590881704673742036276900501796,
        1182881877110262091345611268055604260642551805345970476498379292649976442,
        615040422452344861742025556215458644083849095569544233786579720668688777,
        615934407940682200026533689163429103704448096984144621231191777240212672,
        635935546325729233146786391791275807951391742172516850509501437442784255,
        1766846969571598743850062053243403803937529773948451591650949026715533311,
        1766847020515809453141885857391620930014073257118645563264861076656750550,
        1766847020515809453141897475987949925490213602326884835354244916128510678,
        1766847025515552368683091571327226659924394995588781770950235533296533503,
        1766847020433792839741072082491138939831279361968157667020902029330477729,
        1669818133557739550821714925251366230166915151927139308285876483418750975,
        1766487205272911248842089089338117111187321805789830213596177213738186705,
        1628270824427742969944580405482399453816388236505076175823861028165316848,
        1379511377143812065110042033080132609977535301329938217252211712754512112,
        707905882700643122159784988313461979289510208486326187623784526904862431,
        1766089160313182875008630385850658848532705604207925138508410569128668653
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function toHashCode(uint256 value) internal pure returns (string memory) {
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(value % 16)));

            value /= 16;
        }
        return string(buffer);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
    
   function getPoly(uint16 num,uint16 pal_num) internal view returns (string memory) {
        dataPoints contr = dataPoints(0x320d431cA203e62ab9f92ab816270C0C189b7A40);

        uint256[4]memory opst = [
            6357115739072961060953910277651470886161170040177374449902266926741955053088,
            122188909001257227327926074323072424538964184866200367022797955792896,
            3619386212202017850218502073188472595836577610761538997677367205418100343816,
            430345756352147751824114182023497773466682086715592236566945395638400
        ];


        uint16 i;
        uint256 k;
        uint16 pos;
        string memory res;
        uint256 result;
        
        res = '';
    
        for(i = uint16((contr.points(num/28) / (512**(num%28)))%512); i<=400; i++) {
            if (contr.points(i) == 0)
                break;
    
            k=0;
            for(pos=0;pos<=27;pos++) {
                result = (contr.points(i) /  (512 ** pos)) % 512;

                if (result == 511)
                    break;
    
                if (k%2 == 0) {
                        res = string(abi.encodePacked(res, toString(result*3), ','));

                }
                else {
                    res = string(abi.encodePacked(res, toString(result*3), ' '));

                }
                k++;
             }   
            if (result == 511)
                break;
        }
        
        if (num==0)
                return string(abi.encodePacked('<polygon opacity="1" points="', res, '" fill="url(#b)" />'));

        k = (num<132?0:5) + ((colors[num/64] / (16**(num % 64))) % 16) - 1;
        result =  5*((opst[num/64] / (16**(num % 64))) % 16);
        return string(abi.encodePacked('<polygon opacity="0.',result==5?'05':toString(result==0?99:(result==35?80:result)),'" points="', res, '" fill="#',toHashCode(palettes[pal_num-1] / (16777216 ** k) % 16777216),'" />'));
    }

    function tokenData(uint256 tokenId) public view  returns (string memory) {
        string memory output;

        uint16[12] memory params;
        uint16 i;
        uint16 from;
        uint16 to;


        uint256 rand = random(string(abi.encodePacked('Inspiration',toString(tokenId))));


        params[0] = uint16(1 + (rand % 24)); // palette
        params[1] = params[0] < 7 ? 1 : (params[0] < 14 ? 2 : (params[0] < 19 ? 3 : 4));// element
        params[2] = uint16(1 + ((rand/1000) % 4)); // eyes
        params[3] = uint16(1 + ((rand/10000) % 3)); // head
        params[4] = uint16(1 + ((rand/1000000) % 20)); // stones
        params[4] = params[4] == 20 ? 2 : (params[4] > 15 ? 1 : 0); 
        params[5] = uint16(1 + ((rand/100000000) % 10)); // lag



        from = params[1] == 2 ? 9 : (params[1] == 3 ? 8 : 5);
        to = params[1] == 2 ? 7 : (params[1] == 3 ? 6 : 8);
        
        output = string(abi.encodePacked('<?xml version="1.0" encoding="utf-8"?><svg xmlns="http://www.w3.org/2000/svg" width="1000px" height="1000px" viewBox="0 0 1000 1000"><linearGradient id="a" gradientUnits="userSpaceOnUse" x1="500" y1="1000" x2="500" y2="0"><stop  offset="0" style="stop-color:#',toHashCode(palettes[params[0]-1] / (16777216 ** to) % 16777216),'"/><stop  offset="1" style="stop-color:#',toHashCode(palettes[params[0]-1] / (16777216 ** from) % 16777216),'"/></linearGradient><linearGradient id="b" gradientUnits="userSpaceOnUse" x1="294" y1="77" x2="294" y2="387" gradientTransform="matrix(1 0 0 -1 202.4 1078)"><stop  offset="0" style="stop-color:#',toHashCode(palettes[params[0]-1] / (16777216 ** 7) % 16777216),'"/><stop  offset="1" style="stop-color:#',toHashCode(palettes[params[0]-1] / (16777216 ** 3) % 16777216),'"/></linearGradient><polygon fill="url(#a)" points="1000,1000 0,1000 0,0 1000,0 1000,1000 "/>'));

        for(i=(params[1] ==1 ? 143 : (params[1] ==2 ? 199 : (params[1] ==3 ? 222 : 242)));i<=(params[1] ==1 ? 158 : (params[1] ==2 ? 215 : (params[1] ==3 ? 230 : 249)));i++) {
            output = string(abi.encodePacked(output,getPoly(i, params[0])));
        }

        for(i=0;i<=59;i++) {
            output = string(abi.encodePacked(output,getPoly(i, params[0])));
        }

        from = params[2] == 1 ? 60 : (params[2] == 2 ? 66 : (params[2] == 3 ? 72 : 78));
        to = params[2] == 1 ? 65 : (params[2] == 2 ? 71 : (params[2] == 3 ? 77 : 83));

        for(i=from;i<=to;i++) {
            output = string(abi.encodePacked(output,getPoly(i, params[0])));
        }

        from = params[3] == 1 ? 90 : (params[3] == 2 ? 104 : 121);
        to = params[3] == 1 ? 103 : (params[3] == 2 ? 120 : 131);

        for(i=from;i<=to;i++) {
            output = string(abi.encodePacked(output,getPoly(i, params[0])));
        }

        for(i=(params[1] ==1 ? 132 : (params[1] ==2 ? 159 : (params[1] ==3 ? 216 : 231)));i<=(params[1] ==1 ? 142 : (params[1] ==2 ? 198 : (params[1] ==3 ? 221 : 241)));i++) {
            output = string(abi.encodePacked(output,getPoly(i, params[0])));
        }
        
        output = string(abi.encodePacked(output,
        '<g opacity="0"><polygon fill="',
        toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
        '" points="362,459 369,455 367,460 "/><polygon fill="#',
        toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
        '" points="669,459 662,455 664,460 "/><polygon fill="#',
        toHashCode(palettes[params[0]-1] / (16777216 ** 3) % 16777216),
        '" points="361,457 389,446 425,446 449,461 458,470 463,481 455,476 432,480 403,479 376,470 366,464 357,462 361,457"/><polygon opacity="0.15" fill="#',
        toHashCode(palettes[params[0]-1] / (16777216 ** 1) % 16777216)
        ));

        output = string(abi.encodePacked(output,
        '" points="453,468 438,455 424,448 430,453 431,464 420,470 361,459 376,468 403,477 430,479 453,474 453,468"/><polygon fill="#',
        toHashCode(palettes[params[0]-1] / (16777216 ** 3) % 16777216),
        '" points="670,457 643,446 607,446 582,461 574,470 569,481 577,476 600,480 629,479 656,470 666,464 675,462 670,456"/><polygon opacity="0.15" fill="#',
        toHashCode(palettes[params[0]-1] / (16777216 ** 1) % 16777216),
        '" points="579,468 594,455 608,448 602,453 601,464 612,470 671,459 656,468 629,477 601,479 579,474 579,468"/><animate begin="',toString(params[5]),'s" attributeName="opacity" values="0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0" dur="6s" repeatCount="indefinite"/></g>'
        ));

        if (params[4] > 0) {
            output = string(
                abi.encodePacked(output,
                '<g opacity="0.6"><polygon fill="#',
                toHashCode(palettes[params[0]-1] / (16777216 ** 3) % 16777216),
                '" points="178,559 203,522 233,530 242,563 224,621 204,626 183,589"/><polygon opacity="0.6" fill="#',
                toHashCode(palettes[params[0]-1] / (16777216 ** 1) % 16777216),
                '" points="203,522 202,562 215,622 204,626 183,589 178,559 186,547 188,563 198,597 192,558 190,540"/><polygon opacity="0.4" fill="#',
                toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
                '" points="233,530 242,563 224,621 231,567 217,530 227,567 203,522"/><polygon fill="#',
                toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
                '" points="181,553 183,551 184,554 192,561 210,579 235,582 238,575 235,583 233,582 218,581 208,583 205,576"/><polygon fill="#',
                toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
                '" points="230,600 215,609 199,611 193,606 198,615 197,612 216,611 217,610"/><animateMotion path="M 0 0 V -40 Z" dur="7s" repeatCount="indefinite" /></g>'
                ));
        }

        if (params[4] > 1) {
            output = string(
            abi.encodePacked(output,
            '<g opacity="0.6"><polygon fill="#',
            toHashCode(palettes[params[0]-1] / (16777216 ** 3) % 16777216),
            '" points="803,181 837,209 838,272 819,329 801,352 783,313 775,231"/><polygon opacity="0.6" fill="#',
            toHashCode(palettes[params[0]-1] / (16777216 ** 1) % 16777216),
            '" points="801,352 783,313 775,231 786,294 787,272 790,276 798,242"/><polygon opacity="0.5" fill="#',
            toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
            '" points="802,236 804,184 838,272 837,209 803,181 798,242 801,352 836,275 816,307"/><polygon fill="#',
            toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
            '" points="780,284 786,294 793,314 800,313 804,347 801,351 799,315 792,316 785,295 781,291"/><polygon fill="#',
            toHashCode(palettes[params[0]-1] / (16777216 ** 0) % 16777216),
            '" points="792,201 795,221 799,239 817,302 825,292 822,320 823,298 816,307 799,248 792,224 791,207 785,214"/><animateMotion path="M 0 0 V 30 Z" dur="10s" repeatCount="indefinite" /></g>'
            ));
        }

        output = string(abi.encodePacked(output,
        '</svg>'
        ));
        
        string memory strparams;

        strparams = string(abi.encodePacked('[{ "trait_type": "Palette", "value": "',
        toString(params[0]),
        '" }, { "trait_type": "Element", "value": "',
        toString(params[1]),
        '" }, { "trait_type": "Eyes", "value": "',
        toString(params[2])));
        
        strparams = string(abi.encodePacked(strparams, 
        '" }, { "trait_type": "Head", "value": "',
        toString(params[3])));

        strparams = string(abi.encodePacked(strparams, 
        '" }, { "trait_type": "Stones", "value": "',
        toString(params[4]),
        '" }]'));
    


        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Onchain: Inspiration", "description": "The image of the elements, for inspiration or the search for meaning. Completely generated OnChain.","attributes":', strparams, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    
}




/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}