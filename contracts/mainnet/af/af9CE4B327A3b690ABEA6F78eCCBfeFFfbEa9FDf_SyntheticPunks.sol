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

//  ______     __  __     __   __     ______   __  __     ______     ______   __     ______        ______   __  __     __   __     __  __     ______    
// /\  ___\   /\ \_\ \   /\ "-.\ \   /\__  _\ /\ \_\ \   /\  ___\   /\__  _\ /\ \   /\  ___\      /\  == \ /\ \/\ \   /\ "-.\ \   /\ \/ /    /\  ___\   
// \ \___  \  \ \____ \  \ \ \-.  \  \/_/\ \/ \ \  __ \  \ \  __\   \/_/\ \/ \ \ \  \ \ \____     \ \  _-/ \ \ \_\ \  \ \ \-.  \  \ \  _"-.  \ \___  \  
//  \/\_____\  \/\_____\  \ \_\\"\_\    \ \_\  \ \_\ \_\  \ \_____\    \ \_\  \ \_\  \ \_____\     \ \_\    \ \_____\  \ \_\\"\_\  \ \_\ \_\  \/\_____\ 
//   \/_____/   \/_____/   \/_/ \/_/     \/_/   \/_/\/_/   \/_____/     \/_/   \/_/   \/_____/      \/_/     \/_____/   \/_/ \/_/   \/_/\/_/   \/_____/ 
                                                                                                                                                     

// ................................................................................
// .....................................,,,........................................
// ...............................,,,,,,,,,,,,,,,..................................
// ............................,7777777777777777777,...............................
// .........................,,,,7777777777777777777,,,,............................
// ......................,,,,777~~~~~~~~~~~~~~~~~~~777,,,..........................
// ....................,,,,,:777,,,,,,,,,,,,,,,,,,,III:,,,,,.......................
// ..................,,,,=III~~~,,,,,,,,,,,,,,,,,,,~~~III=,,,,.....................
// .................,,,,,=III:::::::::::::::::::::::::III=,,,,,....................
// ................,,,777777777777777777777777777777777777777,,,...................
// ...............,,,,777777777777777777777777777777777777777,,,...................
// ................,,,777777777777777777777777777777777777777,,,...................
// ................,,,777777777777777777777777777777777777777,,,...................
// ................,,,===?II?=~~~~~~~~~~~~~~~~~~~~~~~~777+~~~,,,...................
// ................,,,,,,?III::,,,,,,,,,,,,,,,,,,,,,::777=,,,,,....................
// .................,,,,,IIII,,,,,,,,,,,,,,,,,,,,,,,,,777=,,,,,....................
// .................,,,,,I77I,,,,,..............,,,,,,777=,,,,.....................
// .................,,777===~,,,,................,,,,,777=,,,......................
// .................,,777~,,,,,,..................,,,,777=,,.......................
// .................,,777~,,,,,,777.............7II,,,777=,,.......................
// .................,,777~,,,,,,777,............777,,,777=,,.......................
// .................,,777?777,,,===,............===,,,777=,,.......................
// .................,,777?777,,,.................,,,,,777=,,.......................
// .................,,=+=+777,,,.................,,,,,777=,,.......................
// ..................,,,,+777,,,.................,,,,,777=,,.......................
// ..................,,,,+777,,,.........=777....,,,,,777=,,.......................
// ...................,,,=777,,,.........+777..,,,,,,,777=,,.......................
// ...................,,,+777,,,,.......,~++=,,,,,,,,,777=,,.......................
// ....................,,+777,,,,.....,,,,,,,,,,,,,,,,777=,,.......................
// .....................,=777,,,,,,,,,I777777777,,,,,,777=,........................
// .....................,+777,,,,,,,,,I777777777,,,,,,777=,........................
// .....................,=+++~~~,,,,,,=+++++++++,,,~~~+++~.........................
// ......................,,,:777,,,,,,,,,,,,,,,,,,,777:,,..........................
// ......................,,,:777,,,:::,,,,,,,,,,:::III:,...........................
// ......................,,,:777,,,777:,,,,,,,,:777,,,.............................
// ......................,,,:777,,,777~,,,,,,,,:777,,,.............................
// ......................,,,:777,,,,,,III?77?777,,,,...............................
// ......................,,,:777,,,,,,III?77?77I,,,,...............................
// .......................,,:777,,,,,,,,,:77?,,,,,.................................
// .......................,,,777,,,,,,,,,:77?,,,,..................................
// .........................,???,,,,,,,,,:??=,,,...................................
// ............................,.........,,,.,.....................................
// ................................................................................

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./interfaces/ISyntheticPunksAssets.sol";

abstract contract ReverseRecords {
  function getNames(address[] calldata addresses) external view virtual returns (string[] memory r);
}

contract SyntheticPunks is ERC721 {

  ISyntheticPunksAssets public assets;
  uint256 public immutable claimPrice = 0.02 ether;
  address public immutable withdrawAddress;
  address immutable ensReverseAddress;
  string public constant claimMessage = "Message to claim Synthetic Punk";

  mapping(address => bool) public claimed;

  enum Gender { Male, Female }

  constructor(
    string memory _name, 
    string memory _symbol, 
    address _assetsAddress,
    address _withdrawAddress,
    address _ensReverseAddress
  ) ERC721(_name, _symbol) {
    assets = ISyntheticPunksAssets(_assetsAddress);
    withdrawAddress = _withdrawAddress;
    ensReverseAddress = _ensReverseAddress;
  }

  function claim() public payable {
    require(msg.value >= claimPrice, "Insufficient payment");
    _safeMint(msg.sender, getTokenID(msg.sender));
    claimed[msg.sender] = true;
    uint256 refund = msg.value - claimPrice;
    if (refund > 0) {
      payable(msg.sender).transfer(refund);
    }
  }

  function claimOther(address _signer, bytes memory _signature) public payable {
    require(msg.value >= claimPrice, "Insufficient payment");
    require(verify(_signer, claimMessage, _signature), "Invalid signature");

    _safeMint(msg.sender, getTokenID(_signer));
    claimed[_signer] = true;
    uint256 refund = msg.value - claimPrice;
    if (refund > 0) {
      payable(_signer).transfer(refund);
    }
  }

  

  function withdraw() public {
    payable(withdrawAddress).transfer(address(this).balance);
  }

  function _tokenURI(address _address) public view returns (string memory) {
    return tokenURI(getTokenID(_address));
  }

  function getTokenID(address _address) public pure returns (uint256) {
    return uint256(uint160(_address));
  }

  function getAddress(uint256 id) public pure returns (address) {
    return address(uint160(id));
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    uint256[] memory layers = getAttributes(id);
    string memory punkSVG = generatePunkSVG(layers);

    address userAddress = getAddress(id);
    string memory ensName = reverseName(userAddress);  
    string memory addressOrENS = bytes(ensName).length == 0 ? truncateAddress(userAddress) : ensName;
    string memory addressFullorENS = bytes(ensName).length == 0 ? toString(userAddress) : ensName;
    
    string memory json = base64(bytes(abi.encodePacked('{"name": "', 'Synthetic CryptoPunk for ', addressOrENS, '", "description": "This is a unique Punk claimed by ', addressFullorENS,'.", "image": "data:image/svg+xml;base64,', base64(bytes(punkSVG)), '"}')));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  // Entropy 0
  function getGender(uint256 id) public view returns (Gender) {
    return randomUint(id, 0) % 2 == 0 ? Gender.Male : Gender.Female;
  }

  // Entropy 1,2-9
  function getAttributeCategories(uint256 id) public view returns (uint256[] memory) {
    uint256[4][9] memory spritesheetRanges = assets.spritesheetRanges();
    uint256 checks = 2 + randomUint(id, 1) % (spritesheetRanges.length - 3); // Number of bytes to check
    uint256[] memory attributes = new uint256[](checks);
    uint256 length = 0;
    for (uint256 i; i < checks; i++) {
      uint256 newAttribute = randomUint(id, 2+i) % (spritesheetRanges.length - 2) + 1; // Skip base category
      
      bool added = contains(attributes, newAttribute);

      if (added) {
        continue;
      }

      if (getGender(id) == Gender.Female) {
        if (!(spritesheetRanges[newAttribute][3] - spritesheetRanges[newAttribute][1] == 0)) {
          attributes[length] = newAttribute;
          length++;
        }
      } else {
        if (!(spritesheetRanges[newAttribute][2] - spritesheetRanges[newAttribute][0] == 0)) {
          attributes[length] = newAttribute;
          length++;
        }
      }
    }

    uint256[] memory attributesResized = new uint256[](length+1);
    attributesResized[0] = 0;
    for (uint256 i; i < length; i++) {
      attributesResized[i+1] = attributes[i];
    }

    return attributesResized;
  }

  // Entropy 10
  function getAttribute(uint256 id, uint256 _attributeId) public view returns (uint256) {
    uint256[4] memory ranges = assets.spritesheetRanges()[_attributeId];
    Gender gender = getGender(id);
    if (gender == Gender.Female) {
      return ranges[1] + randomUint(id, 10+_attributeId) % (ranges[3] - ranges[1]);
    } else {
      return ranges[0] + randomUint(id, 10+_attributeId) % (ranges[2] - ranges[0]);
    }
  }

  function _getAttributes(address _address) public view returns (uint256[] memory) {
    return getAttributes(getTokenID(_address));
  }

  function getAttributes(uint256 id) public view returns (uint256[] memory) {
    uint256[] memory attributeCategories = getAttributeCategories(id);
    uint256[] memory layers = new uint256[](attributeCategories.length);
    for (uint256 i = 0; i < attributeCategories.length; i++) {
      layers[i] = getAttribute(id, attributeCategories[i]);
    }
    return layers;
  }

  function generatePunkSVG(uint256[] memory layers) public view returns (string memory) {
    string memory start1 = '<svg viewBox="0 0 24 24" width="1000" xmlns="http://www.w3.org/2000/svg" ><defs><style>#spritesheet { image-rendering: -webkit-optimize-contrast; image-rendering: crisp-edges; image-rendering: pixelated; } svg { background : #1A1A1A; }</style><svg width="24" height="24" viewBox="48 0 24 24"><image id="spritesheet" preserveAspectRatio="xMinYMin slice" href="';
    string memory start3 = '"></image></svg></defs><svg id="punk">';
    string memory end = '</svg></svg>';
    string memory layersSVG = '';

    // Render in order
    for (uint256 i = 0; i < assets.spritesheetRanges().length; i++) {
      for (uint256 j = 0; j < layers.length; j++) {
        if (assets.spritesheetRanges()[i][0] <= layers[j] && layers[j] < assets.spritesheetRanges()[i][3]) { // if layer is in range
          uint256 id = layers[j];
          uint256 x = (id % 24) * 24;
          uint256 y = (id / 24) * 24;
          layersSVG = string(abi.encodePacked(layersSVG, '<svg width="24" height="24" viewBox="', toString(x), ' ', toString(y), ' 24 24"><use href="#spritesheet"></use></svg>'));
          break;
        }
      }
    }

    return string(abi.encodePacked(start1, assets.spritesheetImageData(), start3, layersSVG, end)) ;
  }
  
  function reverseName(address _address) internal view returns (string memory name) {
    if (address(0) == ensReverseAddress) {
      return name;
    }
    ReverseRecords ens = ReverseRecords(ensReverseAddress);
    address[] memory t = new address[](1);
    t[0] = _address;
    name = ens.getNames(t)[0];
  }

  function contains(uint256[] memory arr, uint256 element) internal pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == element) {
        return true;
      }
    }
    return false;
  }

  function randomUint(uint256 seed, uint256 offset) public view returns (uint256) {
    require(offset < 32, "Offset out of bounds");
    bytes32 entropy = keccak256(abi.encodePacked(address(this), seed));
    bytes32 mask = bytes32(0xff << (offset * 8));
    uint256 out = uint256((entropy & mask) >> (offset * 8));
    return out;
  }

  function truncateAddress(address _address) internal pure returns (string memory) {
    string memory addressString = toString(_address);
    bytes memory addressBytes = bytes(addressString);
    bytes memory str = new bytes(13);
    uint count = 0;
    for (uint i = 0; i < 6; i++) {
      str[count++] = addressBytes[i];
    }
    for (uint256 i = 0; i < 3; i++) {
      str[count++] = ".";
    }
    for (uint i = addressBytes.length-4; i < addressBytes.length; i++) {
      str[count++] = addressBytes[i];
    }

    return string(str);
  }

  function toString(address account) internal pure returns(string memory) {
    return toString(abi.encodePacked(account));
  }

  function toString(bytes32 value) internal pure returns(string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes memory data) internal pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }

  function toString(uint256 n) 
      internal 
      pure 
      returns (string memory nstr) 
  {
    uint256 MAX_UINT256_STRING_LENGTH = 78;
    uint8 ASCII_DIGIT_OFFSET = 48;
    if (n == 0) {
        return "0";
    }
    // Overallocate memory
    nstr = new string(MAX_UINT256_STRING_LENGTH);
    uint256 k = MAX_UINT256_STRING_LENGTH;
    // Populate string from right to left (lsb to msb).
    while (n != 0) {
      assembly {
        let char := add(
          ASCII_DIGIT_OFFSET,
          mod(n, 10)
        )
        mstore(add(nstr, k), char)
        k := sub(k, 1)
        n := div(n, 10)
      }
    }
    assembly {
      // Shift pointer over to actual start of string.
      nstr := add(nstr, k)
      // Store actual string length.
      mstore(nstr, sub(MAX_UINT256_STRING_LENGTH, k))
    }
    return nstr;
  }

  /// @notice Encodes some bytes to the base64 representation
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

  // ECDSA

  function getMessageHash(
    string memory _message
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_message));
  }

  function getEthSignedMessageHash(bytes32 _messageHash)
    public
    pure 
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
      );
  }

  function verify(
    address _signer,
    string memory _message,
    bytes memory signature
  ) public pure returns (bool) {
    bytes32 messageHash = getMessageHash(_message);
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    return recoverSigner(ethSignedMessageHash, signature) == _signer;
  }

  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
    public
    pure
    returns (address)
  {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(bytes memory sig)
    public
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
  {
    require(sig.length == 65, "invalid signature length");

    assembly {
      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }
  }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ISyntheticPunksAssets {
  function spritesheetImageData() external view returns (string memory);
  function spritesheetRanges() external view returns (uint256[4][9] memory);
  function attributesContentURI() external view returns (string memory);
}