// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//                                        ╓                                          //
//                             └⌐        ▓▌  ,▓¬        ,▄▓                          //
//                ²▄,        ╫⌐ ▓ ▌    ╒J▓⌐ ▓▓¬    ╓▄▄▓▓▓▓▀         ,▄▄▓▀            //
//                 ▐▓▌ ▓     ▓▄▓▓ ▓⌐   j▓▓ ▓▓▌ ▄▓▓▓▓▓▓▓▀▐▄▌▓▓▓▓▓▓▓▓▓▓▓▓              //
//                 ▐▓▓ ▓    ▓▓▓▓▓ ▓▓   ▓▓▓ ▓▓▌▐▓▀▀▀▓▓▓ ▐▓▓▓▓▓█▀▀╙¬¬└▀▓               //
//                 ▓▓▓▓▓   ▓▓▓▓▓ ▐▓▓  ▐▓▓▌ ▓▓▌▐▌   j▓▓ ▓▓▓▓▀                         //
//                ▐▓▓▓▓▓   ▓▓▓▓▓ ▓▓▓  ▐▓▓▓ ▓▓▌     ]▓▓ ▓▓▓▌    ▄▄                    //
//                 ▓▓▓▓▓  ▄▓▓▓▓▓ ╫▓▓▓▓▓▓▓▌ ▓▓▌     ▓▓▓ ▐▓▓µ ,▓▓▓                     //
//                  ▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▀▓▓▓▌ ▓▓▌    ▄▓▓▓ ▐▓▓▓▓█▀▀Γ                     //
//                  ▀▓▓▓▓▓▓▓▓▓▓  ▓▓▓▄ ▐▓▓▌ ▓▓▌   ▀▓▓▓▌ ╫▓▓▀                          //
//                   ▓▓▓▓▓▓▓█▓▓  ▀▓▓b ▐▓▓▓ ▓▓▌    ▓▓▓  ▓▓▓       ╓▌                  //
//                   ▐▓▓▌╙¬¬ j▓▌  ▓▓   ▓▓▓ ▓▓▄   ▐▓▓  ▐▓▓▓   ▓▓▓▓▓                   //
//                  ,▓▓█`   ,▓█` ▄▓▀  ▄▓▓▀▄▓▀   ╓▓█¬ ▄▓▓▓▀ ,▓▓▓▓▓▀                   //
//                 ▓▓▓     ▓▓  ▄▓╙  ▄▓▓`▄▓▀   ╒▓▓  ╓▓▓▓▀  ▓▓▓▓▓▀                     //
//                 ▀▓▓▄    ▀▓▄ ╙▓▄  ╙█▓▄╙▓▓µ   ▀▓▄  ▀▓▓▌⌐ ▀▓▓▓▓▌                     //
//                  ▐▓█▌    ▀▓  ▐▓    ▓▓ ╫▓▀   ▐▓¬  ▐▓▓▓▓▓▓▓▓▓▓▓                     //
//                   ▓ ▀     ▀  ▐     ▀▌ ▓▌    ▓¬   ▀▀¬ ▐▓▓▓█▀▀                      //
//                   ▓                ▐▓ ▓⌐   ▐▓         ▓\                          //
//                   ▐                 ▓ ▓    ▐¬        '▌                           //
//                                   ▓∩.         ]▄                                  //
//       ▓µ             ╓▌         ▄▓▓▓ ▓       ▄▐▓              ╓▄Æ            µ    //
//       ▓▓▓           ▓▓       ,▄▓▓▓▓▓ ▓▓     ▄▓▓▌  ,▄▄▄▄▄▄▄▓▓▓▓▓▓         ,▄▓▓     //
//     ▄▓▓▓▓▄          ▓▓    ▄▓▓▓▓▓▓▓▓  ▓▓▌    ▓▓▓ ]▓▓▓███▓▓▓▓▓█▓▓▓ ▄▓▓▓▓▓▓▓▓▓▓      //
//     █▀▓▓▓           ▓▓µ  ▓▓▓▓▀▀╙¬   ▐▓▓▓    ▓▓▓ ▓▓█    ▐▓▓▓  ▓▓ ▓▓▓▓▓█▀▀▀▀`       //
//      ╓▓▓▓           ▓▓▌ ▓▓▓▀     ▄▓⌐j▓▓▓▄▄╓▄▓▓▌ ▓      ▓▓▓b  ` ▐▓▓▓▓,             //
//     ▄▓▓▓▓          ]▓▓▌ ▓▓▓   ▓▓▓▓▓µ ▓▓▓▓▓▓▓▓▓▌       .▓▓▓    , ▀▓▓▓▓▓▓▄,         //
//    ╚`  ▓▓▌       ╫▄▐▓▓ ╫▓▓▓▌     ▓▓▌ ▓▓▓█▀╙▀▓▓▓       j▓▓▓    ▐▓   ▀▀▓▓▓▓▓▄       //
//       j▓▓▌       ▓▌.▓▓ ▐▓▓▓▓▓   ▐▓▓▓ ▐▓▓    ╫▓▓        ▓▓▌    ▐▓▓     ▓▓▓▓▓       //
//        ▓▓▓       ▓▓ ▓▓ ▐▓▓▓▓▓µ  └▓▓▓ ▐▓▓    ▐▓▓µ       ▓▓▓    ▐▓▓     ▓▓▓▓▓       //
//       ▓▓▓╙      ▄▓,▓▓▀,▓▓▓▓▓█   ▓▓▓▀,▓▓▀   ,▓▓█       ▄▓▓"   ,▓▓▀    ╓▓▓▓▓▀       //
//     ▄▓▓▀      ╓▓▀▄▓▀,▓▓▓▓▓█¬  ▄▓▓▀.▓▓▀    ▓▓█¬      ▄▓▓▀    ▓▓▀    ,▓▓▓▓▀         //
//     ╙▀▓▓▄     ╙╙▀▓▀█▌▀▀▓▓▓▓▄ç ▀▀▓▓▄▀▀▓▄  ¬▀▀▓▄µ     ╙▀▓▓▄  ¬▀▀▓▄   ╙▀█▓▓▓▄        //
//       ▐▓▓▄     ▄▓▓b▐▓▌ ▐▓▓▓▓▓▓▓▓▓▓▓▌ ▓▓▌    ▓▓▓       j▓▓∩   ,▓▓▓▓     ▓▓▓▌       //
//       └▓▓▓▓▓▓▓▓▓█▀ ▐▓▌   █▓▓▓▓▓▓▓▓▓▌ ▓▓▓    ▓▓▓        ▓▓⌐    └▀▓▓▓▓▓▓▓▓▓▓        //
//        ▓▓▓▓█▀▀¬    j▓▌      ¬    ▓▓▓ ▓▓▓    ▀▓▓        ▓▓        ╙▓▓▓▓▓▓¬         //
//        ▓▓▀          ▓▌           ▓▓▀ ╫▓▓     ▓▌       j▓▌          ▓▓▓█▀          //
//       .▓            ▓            ▓   ╫▓      ▓▌       ▓▀           ╫▓             //
//       Å             ▀            ▓   ▓       ▓       ▓▀            ▓¬             //
//                                              ▌      ▐▀                            //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////
///
/// @title:  a quantum entanglement
/// @author: whitelights.eth | @iamwhitelights
/// @author: manifold.xyz
///
/// This extension mints and controls a diptych series perpetually in a state of quantum entanglement
/// enforced by the blockchain. Each generative piece behaves as an entangled particle, where mining
/// a block on the Ethereum blockchain causes its wave function to collapse, resulting in each
/// artwork revealing itself. The outcome is random, with each possibility having a
/// probability of 50% before the block is mined. Still, the results are always anti-correlated.
/// Between blocks, their state is considered unknown, a seemingly paradoxical phenomenon.
///
/// The hope is to humanize Quantum Mechanics by drawing a link between Schrödinger's
/// paradox and the human condition of oscillating between happiness and sadness. I never know how
/// to describe my feelings until I’m asked, begging the follow-up, how does one illustrate the
/// limbo state before introspection? All possibilities seem equal to me.
///
/// These artworks are on-chain and have no dependencies besides Ethereum and a browser. The HTML,
/// JS, and SVGs have no 3rd party dependencies, are supported in all modern browsers, and do not
/// require an active internet connection.
///

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract AQuantumEntanglement is AdminControl, ICreatorExtensionTokenURI {
    using Strings for uint256;

    address private _creator;
    uint256 private _tokenId1;
    uint256 private _tokenId2;
    string public script;
    string public description;

    constructor(address creator) {
      _creator = creator;
    }

    function initialize() external adminRequired {
      script = "</script><style>body,html{display:flex;flex-direction:column;justify-content:center;height:100%;width:100%;margin:0}canvas{max-width:100%;max-height:100%;object-fit:contain;padding:40px;box-sizing:border-box}</style></head><body><script>let e=seed==='1';const o=e?'okay':'sad';var r=document.createElement('canvas');document.body.appendChild(r);r.height=r.width=2020;let d=r.getContext('2d');let f='source-over';function t(e){d.globalCompositeOperation=f;var n=101;var t=r.height/n;for(var a=0;a<n*2;a++){d.beginPath();d.strokeStyle=a%2?'white':'black';d.lineWidth=t;d.moveTo(a*t+t/2-r.width,0);d.lineTo(0+a*t+t/2,r.height);d.stroke()}const c=400*r.height/2020;d.globalCompositeOperation='difference';d.fillStyle='white';d.textBaseline='middle';d.font=`italic ${c}px sans-serif`;d.textAlign='left';const i=d.measureText('i am '+o).width;if(f==='difference'){d.fillText(parseInt(e)%6!==1&&f==='difference'?'i am '+(o==='sad'?'okay':'sad'):'i am '+o,(r.width-i)/2,r.height/2)}else{d.fillText('i am '+o,(r.width-i)/2,r.height/2)}}const a=60;let c=0;let n=0;function i(e){window.requestAnimationFrame(i);if(e-c<1e3/a)return;var n=d.getImageData(0,0,r.width,r.height);t(e);c=e}document.addEventListener('DOMContentLoaded',()=>{i(0);r.addEventListener('click',()=>{f=f==='difference'?'source-over':'difference'})});</script></body></html>";
      description =  'i exist in the interference. pause to introspect, i collapse the emotional wave function. somewhere between the blocks, there lies the truth. somewhere in the ether, we are not always opposed.\\n\\n--------------------\\n\\nthis blockchain performance exhibits a system of emotional entanglement between two separate generative artworks, enforced by smart contract. both the artwork and renderer live on chain as one without external dependencies.\\n\\n--------------------\\n\\ndiptych\\n\\nhtml,js,solidity,performance\\n\\nwhite lights (b. 1993) 2022\\n\\n--------------------\\n\\ntrigger warning: flashing lights upon interaction';
      _tokenId1 = IERC721CreatorCore(_creator).mintExtension(
        msg.sender
      );
      _tokenId2 = IERC721CreatorCore(_creator).mintExtension(
        msg.sender
      );
    }

    function setScript(string memory newScript) public adminRequired {
      script = newScript;
    }

    function setDescription(string memory newDescription) public adminRequired {
      description = newDescription;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
      return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
        || AdminControl.supportsInterface(interfaceId)
        || super.supportsInterface(interfaceId);
    }

    function getAnimationURL(bool quantumStateBool, string memory restOfScript) private pure returns (string memory) {
      return string(
        abi.encodePacked(
          "data:text/html;base64,",
          Base64.encode(abi.encodePacked(
            "<html><head><meta charset='utf-8'><script type='application/javascript'>const seed='",
            quantumStateBool ? "1" : "0",
            "'",
            restOfScript
          ))
         )
      );
    }

    function getPreviewImage(bool quantumStateBool) private pure returns (string memory) {
      return string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='2020' height='2020'><style>text {font: italic 400px sans-serif; mix-blend-mode: difference;}</style><defs><pattern id='str' patternUnits='userSpaceOnUse' width='20' height='20' patternTransform='rotate(125)'><rect x='0' y='0' width='20' height='20' fill='white'></rect><line x1='0' y='0' x2='0' y2='20' stroke='#000000' stroke-width='20'></line></pattern></defs><rect width='100%' height='100%' fill='url(#str)' opacity='1'></rect><rect x='0' y='0' width='2020' height='2020' stroke='red' fill='transparent'></rect><text class='text' x='50%' y='50%' dominant-baseline='middle' fill='white' text-anchor='middle'>",
            quantumStateBool ? "i am okay" : "i am sad",
            "</text></svg>"
          ))
        )
      );
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
      require(creator == _creator, "Invalid token");
      require((tokenId == _tokenId1 || tokenId == _tokenId2), "Invalid token");

      bool quantumStateBool = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 2 == 0 ? false : true;

      if (tokenId == 1) {
        quantumStateBool = !quantumStateBool;
      }

      // updateable description would be nice
      return string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(abi.encodePacked(
          '{"name":"a quantum entanglement #',
          tokenId.toString(),
          '","created_by":"white lights","description":"',
          description,
          '","animation_url":"',
          getAnimationURL(quantumStateBool, script),
          '","image":"',
          getPreviewImage(quantumStateBool),
          '","attributes":[{"trait_type":"Spin","value":"',
            quantumStateBool ? 'Up' : 'Down',
          '"}]',
          '}'
        ))
      ));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {

    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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