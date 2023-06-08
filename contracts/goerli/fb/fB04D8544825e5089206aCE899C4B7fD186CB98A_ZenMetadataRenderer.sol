// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import './Base64.sol';
import './Conversion.sol';
import {MetadataRenderAdminCheck} from "zora-drops-contracts/metadata/MetadataRenderAdminCheck.sol";
import './IZenLibrary.sol';

contract ZenMetadataRenderer is IMetadataRenderer, MetadataRenderAdminCheck {


    string public DSP = "let history0 = history();let history1 = history();let history2 = history();let history3 = history();let history4 = history();let history5 = history();let history6 = history();let history7 = history();let history8 = history();let history9 = history();let history10 = history();let history11 = history();let history12 = history();let history13 = history();let data0 = data(24, 1, new Float32Array([1,1,0,1,1,1,0,0,0,0,0,0,0,0,1,1]));let param0  = param (0.632758406141118);let mult1  = mult (    param0 ,    0.7853981633974483);let tan2  = tan (    mult1 );let add3  = add (    tan2 ,    1);let div4  = div (    tan2 ,    add3 );let param5  = param (1);let reciprical6  = reciprical (    param5 );let add7  = add (    div4 ,    reciprical6 );let mult8  = mult (    history2 (),    add7 );let add9  = add (    history0 (),    mult8 );let sub10  = sub (    history1 (),    add9 );let mult11  = mult (    div4 ,    div4 );let mult12  = mult (    div4 ,    reciprical6 );let add13  = add (    mult11 ,    mult12 );let add14  = add (    add13 ,    1);let reciprical15  = reciprical (    add14 );let mult16  = mult (    sub10 ,    reciprical15 );let mult17  = mult (    mult16 ,    div4 );let add18  = add (    mult17 ,    history2 ());let mult19  = mult (    add18 ,    div4 );let add20  = add (    mult19 ,    history0 ());let add21  = add (    add20 ,    mult19 );let history022  = history0 (    add21 );let add23  = add (    mult17 ,    add18 );let history224  = history2 (    add23 );let param25  = param (2);let phasor26  = phasor (    param25 );let rampToTrig27  = rampToTrig (    phasor26 );let param28  = param (8);let mult29  = mult (    param28 ,    1);let param30  = param (1);let mult31  = mult (    param30 ,    1);let div32  = div (    mult29 ,    mult31 );let history533  = history5 (    div32 );let history534  = history5 (    div32 );let sub35  = sub (    history534 ,    div32 );let add36  = add (    history534 ,    div32 );let div37  = div (    s (    s (    history533 ),    sub35 ),    s (    s (    history533 ),    add36 ));let abs38  = abs (    div37 );let gt39  = gt (    abs38 ,    0.012480772600712632);let param40  = param (1);let and41  = and (    gt39 ,    param40 );let zswitch42  = zswitch (    and41 ,    and41 ,    history6 ());let zswitch43  = zswitch (    rampToTrig27 ,    zswitch42 ,    0);let or44  = or (    zswitch43 ,    0);let delta45  = delta (    phasor26 );let wrap46  = wrap (    delta45 ,    -0.5,    0.5);let reciprical47  = reciprical (    div32 );let mult48  = mult (    wrap46 ,    reciprical47 );let add49  = add (    mult48 ,    history4 ());let mult50  = mult (    phasor26 ,    reciprical47 );let sub51  = sub (    add49 ,    mult50 );let round52  = round (    sub51 ,    reciprical47 ,\"nearest\");let add53  = add (    round52 ,    mult50 );let zswitch54  = zswitch (    or44 ,    add53 ,    add49 );let wrap55  = wrap (    zswitch54 ,    0,    1);let history456  = history4 (    wrap55 );let param57  = param (8);let add58  = add (    param57 ,    0);let floor59  = floor (    add58 );let mult60  = mult (    history456 ,    floor59 );let param61  = param (2);let add62  = add (    param61 ,    0);let floor63  = floor (    add62 );let wrap64  = wrap (    mult60 ,    0,    1);let rampToTrig65  = rampToTrig (    wrap64 );let latch66  = latch (    floor63 ,    rampToTrig65 );let sub67  = sub (    mult60 ,    latch66 );let param68  = param (35);let add69  = add (    param68 ,    0);let floor70  = floor (    add69 );let latch71  = latch (    floor70 ,    rampToTrig65 );let param72  = param (12);let add73  = add (    param72 ,    0);let floor74  = floor (    add73 );let latch75  = latch (    floor74 ,    rampToTrig65 );let div76  = div (    latch71 ,    latch75 );let sign77  = sign (    div76 );let mult78  = mult (    sub67 ,    sign77 );let wrap79  = wrap (    mult78 ,    0,    latch75 );let floor80  = floor (    wrap79 );let abs81  = abs (    div76 );let mult82  = mult (    floor80 ,    abs81 );let floor83  = floor (    mult82 );let div84  = div (    floor83 ,    abs81 );let ceil85  = ceil (    div84 );let sub86  = sub (    wrap79 ,    ceil85 );let ceil87  = ceil (    abs81 );let add88  = add (    floor83 ,    ceil87 );let div89  = div (    add88 ,    abs81 );let ceil90  = ceil (    div89 );let sub91  = sub (    ceil90 ,    ceil85 );let div92  = div (    sub86 ,    sub91 );let sub93  = sub (    ceil87 ,    1);let exp294  = exp2 (    sub93 );let mult95  = mult (    div92 ,    exp294 );let wrap96  = wrap (    mult95 ,    0,    1);let rampToTrig97  = rampToTrig (    wrap96 );let accum98  = accum (    rampToTrig97 ,    history3 (),{\"min\":0,\"max\":4000});let rampToTrig99  = rampToTrig (    wrap96 );let param100  = param (12);let history9101  = history9 (    param100 );let history9102  = history9 (    param100 );let sub103  = sub (    history9102 ,    param100 );let add104  = add (    history9102 ,    param100 );let div105  = div (    s (    s (    history9101 ),    sub103 ),    s (    s (    history9101 ),    add104 ));let abs106  = abs (    div105 );let gt107  = gt (    abs106 ,    0.012480772600712632);let param108  = param (1);let and109  = and (    gt107 ,    param108 );let zswitch110  = zswitch (    and109 ,    and109 ,    history8 ());let zswitch111  = zswitch (    rampToTrig99 ,    zswitch110 ,    0);let zswitch112  = zswitch (    zswitch111 ,    0,    zswitch110 );let history8113  = history8 (    zswitch112 );let or114  = or (    zswitch111 ,    0);let delta115  = delta (    wrap96 );let wrap116  = wrap (    delta115 ,    -0.5,    0.5);let reciprical117  = reciprical (    param100 );let mult118  = mult (    wrap116 ,    reciprical117 );let add119  = add (    mult118 ,    history7 ());let mult120  = mult (    wrap96 ,    reciprical117 );let sub121  = sub (    add119 ,    mult120 );let round122  = round (    sub121 ,    reciprical117 ,\"nearest\");let add123  = add (    round122 ,    mult120 );let zswitch124  = zswitch (    or114 ,    add123 ,    add119 );let wrap125  = wrap (    zswitch124 ,    0,    1);let history7126  = history7 (    wrap125 );let mult127  = mult (    history7126 ,    param100 );let floor128  = floor (    mult127 );let param129  = param (0);let peek130  = peek (data0,     floor128 ,    param129 );let latch131  = latch (    peek130 ,    rampToTrig97 );let add132  = add (    latch131 ,    1);let mod133  = mod (    accum98 ,    add132 );let eq134  = eq (    mod133 ,    latch131 );let mult135  = mult (    eq134 ,    rampToTrig97 );let history3136  = history3 (    mult135 );let latch137  = latch (    peek130 ,    history3 ());let history10138  = history10 (    latch137 );let accum139  = accum (    history3 (),    0,{\"min\":0,\"max\":2});let zswitch140  = zswitch (    accum139 ,    1,    0);let history10141  = history10 (    latch137 );let latch142  = latch (    s (    s (    history3136 ),    history10141 ),    rampToTrig97 );let param143  = param (0.1286935038464456);let param144  = param (0.04321191445654965);let zswitch145  = zswitch (    s (    s (    history10138 ),    latch142 ),    param143 ,    param144 );let mult146  = mult (    rampToTrig97 ,    zswitch145 );let eq147  = eq (    latch131 ,    1);let history3148  = history3 (    mult135 );let mult149  = mult (    eq147 ,    history3148 );let latch150  = latch (    latch131 ,    history3148 );let delta151  = delta (    latch150 );let abs152  = abs (    delta151 );let add153  = add (    mult149 ,    abs152 );let accum154  = accum (    mult146 ,    add153 ,{\"min\":0,\"max\":100});let not_sub155  = not_sub (    accum154 );let clamp156  = clamp (    not_sub155 ,    0,    1);let eq157  = eq (    latch142 ,    1);let zswitch158  = zswitch (    eq157 ,    1,    0);let add159  = add (    clamp156 ,    zswitch158 );let scale160  = scale (    add159 ,    0,    2,    0,    1);let mult161  = mult (    zswitch140 ,    scale160 );let mult162  = mult (    mult161 ,    noise ());let param163  = param (0.022878394014959724);let param164  = param (0.948);let scale165  = scale (    accum139 ,    0,    1,    param163 ,    param164 );let eq166  = eq (    scale165 ,    1);let triangle167  = triangle (    wrap96 ,    scale165 );let not_sub168  = not_sub (    zswitch158 );let not_sub169  = not_sub (    not_sub168 );let sub170  = sub (    triangle167 ,    not_sub169 );let gt171  = gt (    sub170 ,    0);let not_sub172  = not_sub (    scale165 );let reciprical173  = reciprical (    not_sub172 );let mult174  = mult (    sub170 ,    reciprical173 );let add175  = add (    mult174 ,    not_sub169 );let clamp176  = clamp (    add175 ,    0,    1);let zswitch177  = zswitch (    eq166 ,    gt171 ,    clamp176 );let sine178  = sine (    zswitch177 );let param179  = param (0.5805979184620986);let mix180  = mix (    zswitch177 ,    sine178 ,    param179 );let mult181  = mult (    mult162 ,    mix180 );let param182  = param (0.9964338564194668);let mult183  = mult (    param182 ,    0.7853981633974483);let tan184  = tan (    mult183 );let add185  = add (    tan184 ,    1);let div186  = div (    tan184 ,    add185 );let add187  = add (    0.7130824687484376,    zswitch158 );let reciprical188  = reciprical (    add187 );let add189  = add (    div186 ,    reciprical188 );let mult190  = mult (    history13 (),    add189 );let add191  = add (    history12 (),    mult190 );let sub192  = sub (    mult181 ,    add191 );let mult193  = mult (    div186 ,    div186 );let mult194  = mult (    div186 ,    reciprical188 );let add195  = add (    mult193 ,    mult194 );let add196  = add (    add195 ,    1);let reciprical197  = reciprical (    add196 );let mult198  = mult (    sub192 ,    reciprical197 );let mult199  = mult (    mult198 ,    div186 );let add200  = add (    mult199 ,    history13 ());let param201  = param (0.6361719677695505);let mix202  = mix (    add200 ,    history11 (),    param201 );let param203  = param (457.5635756023213);let mult204  = mult (    param203 ,    scale160 );let delay205  = delay (    mix202 ,    mult204 );let history11206  = history11 (    delay205 );let mult207  = mult (    add200 ,    div186 );let add208  = add (    mult207 ,    history12 ());let add209  = add (    add208 ,    mult207 );let history12210  = history12 (    add209 );let add211  = add (    mult199 ,    add200 );let history13212  = history13 (    add211 );let history7213  = history7 (    wrap125 );let param214  = param (48.144702842377264);let add215  = add (    peek130 ,    2.5);let mult216  = mult (    param214 ,    add215 );let cycle217  = cycle (    mult216 );let add218  = add (    cycle217 ,    zswitch158 );let mult219  = mult (    add218 ,    scale160 );let mult220  = mult (    mult219 ,    scale160 );let cycle221  = cycle (    param214 ,    mult220 );let mult222  = mult (    cycle221 ,    mix180 );let mult223  = mult (    mult222 ,    scale160 );let not_sub224  = not_sub (    zswitch140 );let mult225  = mult (    mult223 ,    not_sub224 );let param226  = param (0.3519936502299796);let mix227  = mix (    s (    s (    history11206 ),    mix202 ),    mult225 ,    param226 );let mult228  = mult (    scale160 ,    mix180 );let add229  = add (    mult228 ,    s (    s (    history022 ),    add20 ));let mult230  = mult (    add229 ,    0.4);let param231  = param (0.7244701003120698);let mix232  = mix (    mix227 ,    mult230 ,    param231 );let param233  = param (10533.78587164751);let mult234  = mult (    param233 ,    1);let add235  = add (    mult234 ,    500);let delay236  = delay (    mix232 ,    add235 );let history1237  = history1 (    delay236 );return s (    history022 ,    history224 ,    history3136 ,    history10138 ,    history11206 ,    history12210 ,    history13212 ,    history9101 ,    history8113 ,    history7213 ,    history1237 ,    mix232 )";

 

    constructor() {
    }

    struct MetadataURIInfo {
        string contractURI;
    }

    /// @notice NFT metadata by contract
    mapping(address => MetadataURIInfo) public metadataBaseByContract;

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return IZenLibrary(address(0x55DC058eF9876c71bc0CF8E485861421b58A4e67)).getLibrary();
            
        /*
        return string(abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(bytes(
            abi.encodePacked(
              "{",
              "\"description\": \"testing open-sea.\", ", 
              "\"image\": \"https://zequencer.mypinata.cloud/ipfs/QmYhU3QWeQHDbxY1Wab3shAh4dpp8ZLrmgjnEMNGVUQ2ps\", ", 
              "\"name\": \"ZEN!\", ", 
              "\"animation_url\": \"",generateHTML(), "\"", 
              "}"
                             )))));
        */
    }

    function generateHTML() public view returns (string memory) {
        return string(abi.encodePacked(
            "data:text/html;base64,",
            Base64.encode(abi.encodePacked(
            '<!DOCTYPE html><html lang="en"><head>',
            '<meta charset="UTF-8">',
            '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
            '<title>Music Generator</title>'
            '</head>'
            '<body>'
            '<script>',
            IZenLibrary(address(0x55DC058eF9876c71bc0CF8E485861421b58A4e67)).getLibrary(),
            '</script>'
            'Hello World'
            '</body>'
            '</html>'))));
            /*
            '<div id="playButton" onclick="generateMusic()" style="position: absolute; z-index: 30; width: 0; height: 0; border-top: 30px solid transparent; border-bottom: 30px solid transparent; border-left: 60px solid #fff; margin: auto; position: absolute; top: 0; right: 0; bottom: 0; left: 0;"></div>'
            '<canvas style="position: absolute; top: 0px; left: 0px;" id="glCanvas"/>',
            '<script>',
            zen.getLibrary(),
            ';let isPlaying = false;'
            ';let workletNode;'
            '\nfunction dsp() { \n',
                     'let history = window.ZEN_LIB.history;\n',
            DSP,
            '\n}\n'
            '\nfunction generateMusic() {'
            'const button = document.getElementById("playButton");'
            'if (isPlaying) {'
                'button.style.borderTop = "30px solid transparent";'
                'button.style.borderBottom = "30px solid transparent";'
                'button.style.borderLeft = "60px solid #fff";'
                'button.style.width= "0";'
                'button.style.height= "0";'
                'button.style.borderRight = "0";'
            '} else {'
                'button.style.width= "30px";'
                'button.style.height= "80px";'
                'button.style.borderTop = "0";'
                'button.style.borderBottom = "0";'
                'button.style.borderLeft = "30px solid #fff";'
                'button.style.borderRight = "30px solid #fff";'
            '}'
            'isPlaying = !isPlaying;\n'
            'let x = dsp();\n'
            'let y = new (window.AudioContext || window.webkitAudioContext)();\n'
            'if (y.state === "suspended") {\n y.resume();\n}\n'
            'createWorklet(y, zen(x)).then(z => z.workletNode.connect(y.destination));' 
            '  ', 
            '}',
            '</script>',
            '</body>',
            '</html>'
            ))));
            */
    }

    function contractURI() external view returns (string memory) {
        string memory uri = metadataBaseByContract[msg.sender].contractURI;
        if (bytes(uri).length == 0) revert();
        return uri;
    }

    function initializeWithData(bytes memory data) external {
        // data format: string baseURI, string newContractURI
        (string memory initialContractURI) = abi
            .decode(data, (string));

        metadataBaseByContract[msg.sender] = MetadataURIInfo({
            contractURI: initialContractURI}
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
   Conversion library from unsigned integer to string
 */
library Conversion {
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
   }

    function int2float(int i) internal pure returns (string memory) {
        //     3 -> 0.003 
        //    30 -> 0.03
        //   300 -> 0.30
        //  3000 -> 3.0
        // 30000 -> 30
        //uint decimalSize = 3;
        if (i == 0) {
            return "0.0";
        }
        string memory str = uint2str(abs(i));
        uint256 len = strlen(str);
        if (len <= 3) {
            return string(abi.encodePacked(
                i < 0 ? "-" : "", "0.", repeat("0", 3 - len), str));
        } else {
            return string(abi.encodePacked(
                i < 0 ? "-" : "",
                substring(str, 0, len - 3), ".",
                substring(str, len - 3, len)
            ));
        }
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function repeat(string memory a, uint256 repeats) public pure returns (string memory) {
        string memory b = "";
        for (uint256 i=0; i < repeats; i++) {
            b = string(
                abi.encodePacked(
                    b, a
                ));
        }
        return b;
    }

    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    } 


    function abs(int x) private pure returns (uint) {
        return x >= 0 ? uint(x) : uint(-x);
    }       
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721Drop} from "../interfaces/IERC721Drop.sol";

contract MetadataRenderAdminCheck {
    error Access_OnlyAdmin();

    /// @notice Modifier to require the sender to be an admin
    /// @param target address that the user wants to modify
    modifier requireSenderAdmin(address target) {
        if (target != msg.sender && !IERC721Drop(target).isAdmin(msg.sender)) {
            revert Access_OnlyAdmin();
        }

        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;

interface IZenLibrary {
    function getLibrary() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IMetadataRenderer} from "../interfaces/IMetadataRenderer.sol";

/**

 ________   _____   ____    ______      ____
/\_____  \ /\  __`\/\  _`\ /\  _  \    /\  _`\
\/____//'/'\ \ \/\ \ \ \L\ \ \ \L\ \   \ \ \/\ \  _ __   ___   _____     ____
     //'/'  \ \ \ \ \ \ ,  /\ \  __ \   \ \ \ \ \/\`'__\/ __`\/\ '__`\  /',__\
    //'/'___ \ \ \_\ \ \ \\ \\ \ \/\ \   \ \ \_\ \ \ \//\ \L\ \ \ \L\ \/\__, `\
    /\_______\\ \_____\ \_\ \_\ \_\ \_\   \ \____/\ \_\\ \____/\ \ ,__/\/\____/
    \/_______/ \/_____/\/_/\/ /\/_/\/_/    \/___/  \/_/ \/___/  \ \ \/  \/___/
                                                                 \ \_\
                                                                  \/_/

*/

/// @notice Interface for ZORA Drops contract
interface IERC721Drop {
    // Access errors

    /// @notice Only admin can access this function
    error Access_OnlyAdmin();
    /// @notice Missing the given role or admin access
    error Access_MissingRoleOrAdmin(bytes32 role);
    /// @notice Withdraw is not allowed by this user
    error Access_WithdrawNotAllowed();
    /// @notice Cannot withdraw funds due to ETH send failure.
    error Withdraw_FundsSendFailure();

    /// @notice Thrown when the operator for the contract is not allowed
    /// @dev Used when strict enforcement of marketplaces for creator royalties is desired.
    error OperatorNotAllowed(address operator);

    /// @notice Thrown when there is no active market filter DAO address supported for the current chain
    /// @dev Used for enabling and disabling filter for the given chain.
    error MarketFilterDAOAddressNotSupportedForChain();

    /// @notice Used when the operator filter registry external call fails
    /// @dev Used for bubbling error up to clients. 
    error RemoteOperatorFilterRegistryCallFailed();

    // Sale/Purchase errors
    /// @notice Sale is inactive
    error Sale_Inactive();
    /// @notice Presale is inactive
    error Presale_Inactive();
    /// @notice Presale merkle root is invalid
    error Presale_MerkleNotApproved();
    /// @notice Wrong price for purchase
    error Purchase_WrongPrice(uint256 correctPrice);
    /// @notice NFT sold out
    error Mint_SoldOut();
    /// @notice Too many purchase for address
    error Purchase_TooManyForAddress();
    /// @notice Too many presale for address
    error Presale_TooManyForAddress();

    // Admin errors
    /// @notice Royalty percentage too high
    error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
    /// @notice Invalid admin upgrade address
    error Admin_InvalidUpgradeAddress(address proposedAddress);
    /// @notice Unable to finalize an edition not marked as open (size set to uint64_max_value)
    error Admin_UnableToFinalizeNotOpenEdition();

    /// @notice Event emitted for each sale
    /// @param to address sale was made to
    /// @param quantity quantity of the minted nfts
    /// @param pricePerToken price for each token
    /// @param firstPurchasedTokenId first purchased token ID (to get range add to quantity for max)
    event Sale(
        address indexed to,
        uint256 indexed quantity,
        uint256 indexed pricePerToken,
        uint256 firstPurchasedTokenId
    );

    /// @notice Sales configuration has been changed
    /// @dev To access new sales configuration, use getter function.
    /// @param changedBy Changed by user
    event SalesConfigChanged(address indexed changedBy);

    /// @notice Event emitted when the funds recipient is changed
    /// @param newAddress new address for the funds recipient
    /// @param changedBy address that the recipient is changed by
    event FundsRecipientChanged(
        address indexed newAddress,
        address indexed changedBy
    );

    /// @notice Event emitted when the funds are withdrawn from the minting contract
    /// @param withdrawnBy address that issued the withdraw
    /// @param withdrawnTo address that the funds were withdrawn to
    /// @param amount amount that was withdrawn
    /// @param feeRecipient user getting withdraw fee (if any)
    /// @param feeAmount amount of the fee getting sent (if any)
    event FundsWithdrawn(
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount,
        address feeRecipient,
        uint256 feeAmount
    );

    /// @notice Event emitted when an open mint is finalized and further minting is closed forever on the contract.
    /// @param sender address sending close mint
    /// @param numberOfMints number of mints the contract is finalized at
    event OpenMintFinalized(address indexed sender, uint256 numberOfMints);

    /// @notice Event emitted when metadata renderer is updated.
    /// @param sender address of the updater
    /// @param renderer new metadata renderer address
    event UpdatedMetadataRenderer(address sender, IMetadataRenderer renderer);

    /// @notice General configuration for NFT Minting and bookkeeping
    struct Configuration {
        /// @dev Metadata renderer (uint160)
        IMetadataRenderer metadataRenderer;
        /// @dev Total size of edition that can be minted (uint160+64 = 224)
        uint64 editionSize;
        /// @dev Royalty amount in bps (uint224+16 = 240)
        uint16 royaltyBPS;
        /// @dev Funds recipient for sale (new slot, uint160)
        address payable fundsRecipient;
    }

    /// @notice Sales states and configuration
    /// @dev Uses 3 storage slots
    struct SalesConfiguration {
        /// @dev Public sale price (max ether value > 1000 ether with this value)
        uint104 publicSalePrice;
        /// @notice Purchase mint limit per address (if set to 0 === unlimited mints)
        /// @dev Max purchase number per txn (90+32 = 122)
        uint32 maxSalePurchasePerAddress;
        /// @dev uint64 type allows for dates into 292 billion years
        /// @notice Public sale start timestamp (136+64 = 186)
        uint64 publicSaleStart;
        /// @notice Public sale end timestamp (186+64 = 250)
        uint64 publicSaleEnd;
        /// @notice Presale start timestamp
        /// @dev new storage slot
        uint64 presaleStart;
        /// @notice Presale end timestamp
        uint64 presaleEnd;
        /// @notice Presale merkle root
        bytes32 presaleMerkleRoot;
    }

    /// @notice Return value for sales details to use with front-ends
    struct SaleDetails {
        // Synthesized status variables for sale and presale
        bool publicSaleActive;
        bool presaleActive;
        // Price for public sale
        uint256 publicSalePrice;
        // Timed sale actions for public sale
        uint64 publicSaleStart;
        uint64 publicSaleEnd;
        // Timed sale actions for presale
        uint64 presaleStart;
        uint64 presaleEnd;
        // Merkle root (includes address, quantity, and price data for each entry)
        bytes32 presaleMerkleRoot;
        // Limit public sale to a specific number of mints per wallet
        uint256 maxSalePurchasePerAddress;
        // Information about the rest of the supply
        // Total that have been minted
        uint256 totalMinted;
        // The total supply available
        uint256 maxSupply;
    }

    /// @notice Return type of specific mint counts and details per address
    struct AddressMintDetails {
        /// Number of total mints from the given address
        uint256 totalMints;
        /// Number of presale mints from the given address
        uint256 presaleMints;
        /// Number of public mints from the given address
        uint256 publicMints;
    }

    /// @notice External purchase function (payable in eth)
    /// @param quantity to purchase
    /// @return first minted token ID
    function purchase(uint256 quantity) external payable returns (uint256);

    /// @notice External purchase presale function (takes a merkle proof and matches to root) (payable in eth)
    /// @param quantity to purchase
    /// @param maxQuantity can purchase (verified by merkle root)
    /// @param pricePerToken price per token allowed (verified by merkle root)
    /// @param merkleProof input for merkle proof leaf verified by merkle root
    /// @return first minted token ID
    function purchasePresale(
        uint256 quantity,
        uint256 maxQuantity,
        uint256 pricePerToken,
        bytes32[] memory merkleProof
    ) external payable returns (uint256);

    /// @notice Function to return the global sales details for the given drop
    function saleDetails() external view returns (SaleDetails memory);

    /// @notice Function to return the specific sales details for a given address
    /// @param minter address for minter to return mint information for
    function mintedPerAddress(address minter)
        external
        view
        returns (AddressMintDetails memory);

    /// @notice This is the opensea/public owner setting that can be set by the contract admin
    function owner() external view returns (address);

    /// @notice Update the metadata renderer
    /// @param newRenderer new address for renderer
    /// @param setupRenderer data to call to bootstrap data for the new renderer (optional)
    function setMetadataRenderer(
        IMetadataRenderer newRenderer,
        bytes memory setupRenderer
    ) external;

    /// @notice This is an admin mint function to mint a quantity to a specific address
    /// @param to address to mint to
    /// @param quantity quantity to mint
    /// @return the id of the first minted NFT
    function adminMint(address to, uint256 quantity) external returns (uint256);

    /// @notice This is an admin mint function to mint a single nft each to a list of addresses
    /// @param to list of addresses to mint an NFT each to
    /// @return the id of the first minted NFT
    function adminMintAirdrop(address[] memory to) external returns (uint256);

    /// @dev Getter for admin role associated with the contract to handle metadata
    /// @return boolean if address is admin
    function isAdmin(address user) external view returns (bool);
}