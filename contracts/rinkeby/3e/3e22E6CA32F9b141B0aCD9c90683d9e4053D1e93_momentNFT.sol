pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract momentNFT is ERC721 {

  //TODO: Change Price
  uint256 public immutable claimPrice = 0.001 ether; 
  address public immutable withdrawAddress = 0x245E32DbA4E30b483F618A3940309236AaEbBbC5 ;
  uint public tokenCounter; 
  uint32 constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint16 constant SECONDS_PER_HOUR = 60 * 60;
  uint8 constant SECONDS_PER_MINUTE = 60;
  string public svgTop ;
  string public svgBot ; 
  
  mapping(address => bool) public claimed;
  mapping(address => uint256) public userNFTTokenId;
  mapping(uint256 => address) public ownerOfNFTId;
  mapping (uint256 => int8) public timeZoneHour; 
  mapping (uint256 => int8) public timeZoneMin; 

  event CreatedMomentNFT(uint256 indexed tokenId);

  constructor() ERC721 ("Moment NFT", "momentNFT") {
    tokenCounter = 0 ;
    svgTop = ' <svg width="400" height="400" viewBox="0 0 400 400" fill="none" xmlns="http://www.w3.org/2000/svg">    <def>      <style>      .minute-arm {        fill: none;        stroke: #A3A3A3;        stroke-width: 6;        stroke-miterlimit: 8;      }      .hour-arm {        fill: none;        stroke: #fff;        stroke-width: 6;        stroke-miterlimit: 8;      }      #minute,#hour {        transform-origin: 200px 200px;      }    </style>    </def>    <rect width="400" height="400" fill="white" />    <circle cx="200" cy="200" r="147" stroke="black" stroke-width="6" />    <circle cx="200" cy="200" r="145" fill="black" stroke="#393939" stroke-width="2" />    <mask id="mask0_7_61" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="61" y="61" width="278" height="278">      <rect x="198" y="61" width="4" height="38" fill="#C4C4C4" />      <rect x="198" y="301" width="4" height="38" fill="#C4C4C4" />      <rect x="61" y="202" width="4" height="38" transform="rotate(-90 61 202)" fill="#C4C4C4" />      <rect x="301" y="202" width="4" height="38" transform="rotate(-90 301 202)" fill="#C4C4C4" />      <rect x="132.232" y="321.378" width="4" height="38" transform="rotate(-150 132.232 321.378)" fill="#C4C4C4" />      <rect x="252.232" y="113.531" width="4" height="38" transform="rotate(-150 252.232 113.531)" fill="#C4C4C4" />      <rect x="80.6224" y="271.232" width="4" height="38" transform="rotate(-120 80.6224 271.232)" fill="#C4C4C4" />      <rect x="288.469" y="151.232" width="4" height="38" transform="rotate(-120 288.469 151.232)" fill="#C4C4C4" />      <rect x="78.6224" y="132.232" width="4" height="38" transform="rotate(-60 78.6224 132.232)" fill="#C4C4C4" />      <rect x="286.469" y="252.232" width="4" height="38" transform="rotate(-60 286.469 252.232)" fill="#C4C4C4" />      <rect x="271.232" y="319.378" width="4" height="38" transform="rotate(150 271.232 319.378)" fill="#C4C4C4" />      <rect x="151.232" y="111.531" width="4" height="38" transform="rotate(150 151.232 111.531)" fill="#C4C4C4" />    </mask>    <g mask="url(#mask0_7_61)">      <mask id="mask1_7_61" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="45" y="41" width="324" height="316">        <rect x="45" y="41" width="324" height="316" fill="url(#paint0_linear_7_61)" />      </mask>      <g mask="url(#mask1_7_61)">        <rect x="13" y="9" width="387" height="359" fill="#F584FF" />        <g filter="url(#filter0_f_7_61)">          <circle cx="82.5" cy="117.5" r="117.5" fill="#FF84CE" />        </g>        <g filter="url(#filter1_f_7_61)">          <circle cx="349.5" cy="239.5" r="117.5" fill="#84A7FF" />        </g>        <g filter="url(#filter2_f_7_61)">          <circle cx="113.5" cy="345.5" r="117.5" fill="#E09191" />        </g>      </g>    </g> ';
    svgBot = '<circle cx="200" cy="200" r="5" fill="white" />    <defs>      <filter id="filter0_f_7_61" x="-135" y="-100" width="435" height="435" filterUnits="userSpaceOnUse"        color-interpolation-filters="sRGB">        <feFlood flood-opacity="0" result="BackgroundImageFix" />        <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape" />        <feGaussianBlur stdDeviation="50" result="effect1_foregroundBlur_7_61" />      </filter>      <filter id="filter1_f_7_61" x="132" y="22" width="435" height="435" filterUnits="userSpaceOnUse"        color-interpolation-filters="sRGB">        <feFlood flood-opacity="0" result="BackgroundImageFix" />        <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape" />        <feGaussianBlur stdDeviation="50" result="effect1_foregroundBlur_7_61" />      </filter>      <filter id="filter2_f_7_61" x="-104" y="128" width="435" height="435" filterUnits="userSpaceOnUse"        color-interpolation-filters="sRGB">        <feFlood flood-opacity="0" result="BackgroundImageFix" />        <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape" />        <feGaussianBlur stdDeviation="50" result="effect1_foregroundBlur_7_61" />      </filter>      <linearGradient id="paint0_linear_7_61" x1="207" y1="41" x2="207" y2="357" gradientUnits="userSpaceOnUse">        <stop stop-color="#FF84CE" />        <stop offset="1" stop-color="#923DFF" />      </linearGradient>    </defs>  </svg>';
  }

  function create(int8 _timeZoneHour, int8 _timeZoneMin) public payable {
    require(msg.value >= claimPrice, "Insufficient payment");
    require(claimed[msg.sender] == false, "Already Claimed");
    _safeMint(msg.sender, tokenCounter);
    setTimeZone(_timeZoneHour,_timeZoneMin,tokenCounter) ; 
    claimed[msg.sender] = true;
    userNFTTokenId[msg.sender] = tokenCounter ; 
    ownerOfNFTId[tokenCounter] = msg.sender ; 
    emit CreatedMomentNFT(tokenCounter);
    tokenCounter = tokenCounter + 1 ; 
    uint256 refund = msg.value - claimPrice;
    if (refund > 0) {
      payable(msg.sender).transfer(refund);
    }
  }

  function withdraw() public {
    payable(withdrawAddress).transfer(address(this).balance);
  }

  function getUserNFTTokenId(address _userAddress) public view returns (uint256 tokenId){
    return userNFTTokenId[_userAddress];
  }

  function getOwnerOfNFTId(uint256 _id) public view returns (address owner){
    return ownerOfNFTId[_id];
  }

  function setTimeZone(int8 _timeZoneHour,int8 _timeZoneMin, uint tokenId) public{
    timeZoneHour[tokenId] = _timeZoneHour ;
    timeZoneMin[tokenId] = _timeZoneMin ;  
  }

  function svgToImageURI(string memory _svg) public pure returns (string memory){
    string memory svgBase64Encoded = base64(bytes(string(abi.encodePacked(_svg))))  ; 
    string memory imageURI = string(abi.encodePacked(svgBase64Encoded));
    return imageURI;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    int hr = int(getHour(block.timestamp)) ; 
    int min = int(getMinute(block.timestamp));
    int sec = int(getSecond(block.timestamp)) ;
    int hrPosition = ((hr+ timeZoneHour[id] + (timeZoneMin[id] /60)) * 360) / 12 + ((min+ timeZoneMin[id]) * (360 / 60)) / 12 ;
    int minPosition = ((min +timeZoneMin[id]) * 360) / 60 + (sec * (360 / 60)) / 60;
    string memory sHrPosition = Strings.toString(uint(hrPosition)) ; 
    string memory sMinPosition = Strings.toString(uint(minPosition)) ; 
    string memory svgMid = string(abi.encodePacked(' <g id="minute" transform = "rotate(',sMinPosition,'  )">      <path class="minute-arm" d="M200 200V78" />      <circle class="sizing-box" cx="200" cy="200" r="130" />    </g>    <g id="hour" transform = "rotate(',sHrPosition,'  )">      <path class="hour-arm" d="M200 200V140" />      <circle class="sizing-box" cx="200" cy="200" r="130" />    </g>  '));
    string memory svg = string(abi.encodePacked(svgTop, svgMid, svgBot )) ; 
    string memory imageURI = svgToImageURI(svg) ;
    string memory json = base64(bytes(abi.encodePacked('{"name": "Moment NFT", "description": "Fully on-chain clock NFT that shows you the current time.", "image": "data:image/svg+xml;base64,',imageURI ,'"}')));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

  function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

  function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

  function base64(bytes memory data) internal pure returns (string memory) {
    bytes memory TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
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

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
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

        require(owner != address(0), "NOT_MINTED");

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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