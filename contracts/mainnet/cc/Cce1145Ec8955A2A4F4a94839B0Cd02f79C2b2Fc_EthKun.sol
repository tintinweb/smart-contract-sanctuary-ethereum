// SPDX-License-Identifier: MIT
// referenced from original Aribibots render code.

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';

contract BotRenderer {

  mapping(uint256 => uint256) public seeds; // will be copied from OG Arbibots contract
  mapping(uint256 => bool) public flipped;

  string[][] public palettes = [
    ['#b5eaea', '#edf6e5', '#f38ba0'],
    ['#b5c7ea', '#e5f6e8', '#f3bb8b'],
    ['#eab6b5', '#eee5f6', '#8bf3df'],
    ['#c3eab5', '#f6e9e5', '#c18bf3'],
    ['#eab5d9', '#e5e8f6', '#8bf396']
  ];

  bytes[] public bodies = [
    bytes(hex'ff00ba0001010404010111000101060301010f000101080301010d000101090301010d000101090301010d00010109030101'),
    bytes(hex'ff00ba0001010404010111000101060301010f000101080301010d000101090301010d000101090301010d00010109030101'),
    bytes(hex'ff00b90001010504010111000101050301011100010105030101110001010503010111000101050301011100010105030101'),
    bytes(hex'ff00ba000101030401011200010105030101100001010104010103030101010401010e00010103040301030401010c0001010b0401010a0001010d040101'),
    bytes(hex'ff00b9000101050301010f0002010104010103030101010402010c00010104040301040401010a0001010d040101090001010d040101090001010d040101'),
    bytes(hex'ff00ba00010103030101120001010104010101030101010401011000010103040101030401010f000101070401010f000101070401010f00010107040101'),
    bytes(hex'ff00ba0001010104010101030101010401011000010103040101020401010f00010104040101030401010e00010104040101040401010d00010104040101040401010d0001010404010104040101')
  ];

  bytes[] public heads = [
    bytes(hex'96000c010b0001010c030101090001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e03010109000e01'),
    bytes(hex'97000a010d0001010a0301010b0001010c030101090001010e030101080001010e030101080001010e030101080001010e030101080001010e030101080001010e030101090001010c0301010b0001010a0301010d000a01'),
    bytes(hex'9400100107000101100401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e03010401010600010101040e0301040101060001011004010107001001'),
    bytes(hex'96000c010b0001010c030101090001010e030101070001011003010105000101120301010400010112030101040001011203010104000101120301010500010110030101070001010d030201090001010b0301010c000b01'),
    bytes(hex'9400100107000101100301010600010110030101060001011003010106000101100301010600010110030101070001010e030101080001010e030101090001010c0301010a0001010c0301010b0001010a0301010d000a01')
  ];

  bytes[] public eyes = [
    bytes(hex'ff0010000201070002010d0001010104070001010104ff00'),
    bytes(hex'ff001000030105000301ff00'),
    bytes(hex'f8000101070001010e000101010001010500010101000101ff00'),
    bytes(hex'df000301050003010d000301050003010e00010107000101ff00'),
    bytes(hex'ff0011000101070001010f00010107000101ff00'),
    bytes(hex'ff00100001010100010105000101010001010e00010107000101ff00')
  ];

  bytes[] public mouths = [
    bytes(hex'ff004300010101000101010001011400010101000101'),
    bytes(hex'ff00450001011600010101000101'),
    bytes(hex'ff005c000401'),
    bytes(hex'ff00440001010200010115000201'),
    bytes(hex'ff0044000401140001010204010115000201')
  ];

  bytes[] public headgears = [
    bytes(hex'37000101080001010d0001010100010106000101010001010e000101060001011000010106000101ff00'),
    bytes(hex'240001011600010101000101150001011700010117000101ff00'),
    bytes(hex'0c000201150001010200010114000101010001010104010113000101020001011400010117000101ff00'),
    bytes(hex'68000101060001010f000101010301010400010101030101ff00'),
    bytes(hex'50000101060001010f0001010103010104000101010301010e000101020301010200010102030101ff00')
  ];

  struct BotData {
    uint palette;
    uint body;
    uint head;
    uint eyes;
    uint mouth;
    uint headgear;
  }

  function _getSVG(uint256 tokenId) internal view returns (string memory) {
    BotData memory data = _generateBotData(tokenId);
    string[] memory palette = palettes[data.palette];

    bool flip = flipped[tokenId];

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="256" height="256">'
      '<rect width="100%" height="100%" fill="', palette[0], '" />',
      _renderRectsSingleColor(bodies[data.body], '#000000', flip),
      _renderRectsSingleColor(heads[data.head], '#000000', flip),
      _renderRects(eyes[data.eyes], palette, '#ffffff', flip),
      _renderRects(mouths[data.mouth], palette, '#ffffff', flip),
      _renderRects(headgears[data.headgear], palette, '#000000', flip),
      '</svg>'
    ));

    return image;
  }

  function _render(uint256 tokenId) internal view returns (string memory) {
   
    string memory image = _getSVG(tokenId);

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(
        bytes(
          abi.encodePacked('{"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}')
        )
      )
    ));
  }

  function _renderRectsSingleColor(bytes memory data, string memory color, bool flip) private pure returns (string memory) {
    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory rects;
    uint256 drawIndex = 0;
    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (24px)
      uint8 colorIndex = uint8(data[i+1]);
      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 24);
        x = 24-x-runLength; // mirror horizontally
        uint8 y = uint8(drawIndex / 24);

        if (flip) // mirror vertically
            y = 23-y;

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="', color, '" />'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _renderRects(bytes memory data, string[] memory palette, string memory defaultColor, bool flip) private pure returns (string memory) {
    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory rects;
    uint256 drawIndex = 0;
    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (24px)
      uint8 colorIndex = uint8(data[i+1]);
      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 24);
        x = 24-x-runLength; // mirror horizontally
        uint8 y = uint8(drawIndex / 24);
        
        if (flip) // mirror vertically
            y = 23-y;

        string memory color = defaultColor;
        if (colorIndex > 1) {
          color = palette[colorIndex-2];
        }
        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="', color, '" />'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateBotData(uint256 tokenId) private view returns (BotData memory) {
    uint256 seed = seeds[tokenId];

    return BotData({
      palette: seed % palettes.length,
      body: (seed/2) % bodies.length,
      head: (seed/3) % heads.length,
      eyes: (seed/4) % eyes.length,
      mouth: (seed/5) % mouths.length,
      headgear: (seed/6) % headgears.length
    });
  }
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
//
// [ @ _ @ ]
//
// Antibots by @eddietree

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./AntibotRenderer.sol";

contract Antibots is BotRenderer, ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    constructor() ERC721("Antibots", "ANTIBOTS") {}

    bool public redeemEnabled = true;

    // original arbibots contract
    IERC721Enumerable public contractArbibots;
    bytes4 constant sigFunc_ownerOf = bytes4(keccak256("ownerOf(uint256)"));
    bytes4 constant sigFunc_balanceOf = bytes4(keccak256("balanceOf(address)"));
    bytes4 constant sigFunc_tokenOfOwnerByIndex = bytes4(keccak256("tokenOfOwnerByIndex(address,uint256)"));
    bytes4 constant sigVariable_seeds = bytes4(keccak256("seeds(uint256)")); // mapping(uint256 => uint256) public seeds;

    event AntibotRedeemed(uint256 indexed tokenId); // emitted when Antibot is redeemed
    event AntibotNinjaFlipped(uint256 indexed tokenId); // emitted when Antibot is flipped!

    function _ninjaFlip(uint256 tokenId) internal {
        require(_exists(tokenId), "Nonexistent token");

        flipped[tokenId] = !flipped[tokenId];
        emit AntibotNinjaFlipped(tokenId);
    }

    function ninjaFlip(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not yours homie.");
        _ninjaFlip(tokenId);
    }

    function ninjaFlipMany(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not yours homie.");
            _ninjaFlip(tokenId);
        }
    }

    function ninjaFlipAll() external {
        uint256 num = balanceOf(msg.sender);
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            _ninjaFlip(tokenId);
        }
    }

    function ninjaFlipAdmin(uint256 tokenId) external onlyOwner {
        _ninjaFlip(tokenId);
    }

    function _redeem(uint256 tokenId, address to) internal {
        require(!_exists(tokenId), "Already redeemed!");

        _mint(to, tokenId);
        seeds[tokenId] = fetchSeedForToken(tokenId);

        emit AntibotRedeemed(tokenId);
    }

    function redeemIndividual(uint256 tokenId) external {
        require(msg.sender == fetchOwnerOfArbibot(tokenId), "Not yours homie.");
        require(redeemEnabled, "Not enabled!");
        _redeem(tokenId, msg.sender);
    }

    // redeem all 
    function redeem() external {
        require(redeemEnabled, "Not enabled!");

        uint256 num = fetchNumArbibotsOwnedBy(msg.sender);
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = fetchArbibotTokenOfOwnerByIndex(msg.sender, i);

            // only redeem if it hasnt been redeemed yet
            if (!_exists(tokenId))
                _redeem(tokenId, msg.sender);
        }
    }

    function redeemMany(uint256[] calldata tokenIds) external {
        require(redeemEnabled, "Not enabled!");

        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == fetchOwnerOfArbibot(tokenId), "Not yours homie.");
            _redeem(tokenId, msg.sender);
        }
    }

    // returns array of redeemable tokenIds and count of redeemable tokens
    // note: count can be less than memory.length
    function getAllRedeemableTokens() external view returns (uint256[] memory, uint count) {

        uint256 num = fetchNumArbibotsOwnedBy(msg.sender);
        uint256[] memory redeemableTokens = new uint256[](num);

        count = 0;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = fetchArbibotTokenOfOwnerByIndex(msg.sender, i);

            // only redeem if it hasnt been redeemed yet
            if (!_exists(tokenId)) {
                redeemableTokens[count] = tokenId;
                count++;
            }
        }

        return (redeemableTokens, count);
    }

    /*function adminRedeem(uint256 tokenId) external onlyOwner { // for testing
        _redeem(tokenId, msg.sender);
    }

    function adminRedeemMany(uint256[] calldata tokenIds) external { // for testing
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _redeem(tokenId, msg.sender);
        }
    }*/

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _render(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRedeemEnabled(bool newEnabled) external onlyOwner {
        redeemEnabled = newEnabled;
    }

    function setContractArbibots(address newAddress) external onlyOwner {
        contractArbibots = IERC721Enumerable(newAddress);
    }

    function fetchSeedForToken(uint256 tokenId) internal returns (uint256) { 
        if (address(contractArbibots) == address(0)) {
            return tokenId;
        }

        bytes memory data = abi.encodeWithSelector(sigVariable_seeds, tokenId);
        (bool success, bytes memory returnedData) = address(contractArbibots).call(data);
        require(success);

        uint256 seed = abi.decode(returnedData, (uint256));
        return seed;
    }

    function fetchOwnerOfArbibot(uint256 arbibotTokenId) public view returns (address) {
        if (address(contractArbibots) == address(0)) {
            return address(0);
        }

        return contractArbibots.ownerOf(arbibotTokenId);
    }

    function fetchNumArbibotsOwnedBy(address from) public view returns (uint256) {
        if (address(contractArbibots) == address(0)) {
            return 0;
        }

        return contractArbibots.balanceOf(from);
    }

    function fetchArbibotTokenOfOwnerByIndex(address from, uint256 index) public view returns (uint256) {
        if (address(contractArbibots) == address(0)) {
            return 0;
        }

        return contractArbibots.tokenOfOwnerByIndex(from, index);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
//import 'base64-sol/base64.sol';


contract UkeToken is ERC20, Ownable {

    uint256 public constant START_TOKEN_SUPPLY = 420;

    constructor() ERC20 ("UkeToken", "UKE") {
      _mint(msg.sender, START_TOKEN_SUPPLY);
    }

    function decimals() public view virtual override returns (uint8) {
      return 16;
    }

    function mintAdmin(address to, uint256 tokenCount) external onlyOwner {
        _mint(to, tokenCount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
/**
                                                                                                    
                                            ethkun <3 u                                                  
                                                                                                    
                                                                                                    
                                               ,,,***.                                              
                                               ,,,***.                                              
                                               ,,,***.                                              
                                            ,,,,,,*******                                           
                                            ,,,,,,*******                                           
                                         ,,,,,,,,,**********                                        
                                         ,,,,,,,,,**********                                        
                                         ,,,,,,,,,**********                                        
                                      ,,,,,,,,,,,,*************                                     
                                      ,,,,,,,,,,,,*************                                     
                                   ,,,,,,,,,,,,,,,****************                                  
                                   ,,,,,,,,,,,,,,,****************                                  
                                   ,,,,,,,,,,,,,,,****************                                  
                                ,,,,,,,,,,,,,,,,,,*******************                               
                                ,,,,,,,,,,,,,,,,,,*******************                               
                            .,,,,,,,,,,,,&&&,,,,,,******&&&*************                            
                            .,,,,,,,,,||||||,,,,,,******|||||||*********                            
                            .,,,,,,,,,||||||,,,,,,******|||||||*********                            
                         ,,,,,,,,,,,,,||||||,,,,,,******|||||||************                         
                         ,,,,,,,,,,,,,,,,,,,,,,,,,***#&&%******************                         
                      ,,,,,,,,,,,,,,,,,,,,,,&&&&&&&&&&&&%*********************.                     
                            .,,,,,,,,,,,,,,,,,,,,,***#&&%***************                            
                            .,,,,,,,,,,,,,,,,,,,,,***#&&%***************                            
                      ,,,,,,.      ,,,,,,,,,,,,,,,****************      ******.                     
                         ,,,,,,,,,,      ,,,,,,,,,**********      *********                         
                            .,,,,,,,,,,,,      ,,,***.      ************                            
                                ,,,,,,,,,,,,,,,      ,***************                               
                                ,,,,,,,,,,,,,,,      ,***************                               
                                   ,,,,,,,,,,,,,,,****************                                  
                                      ,,,,,,,,,,,,*************                                     
                                         ,,,,,,,,,**********                                        
                                            ,,,,,,*******                                           
                                            ,,,,,,*******                                           
                                               ,,,***.                                              
                                                                                                    
                                                                                                    


**/

// ethkun
// a celebration of The Merge
// by @eddietree and @SecondBestDad

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import 'base64-sol/base64.sol';

import "./IEthKunRenderer.sol";
import "./EthKunRenderer.sol";

/// @title ethkun
/// @author @eddietree
/// @notice ethkun is an 100% on-chain experimental NFT project
contract EthKun is ERC721A, Ownable {
    
    // TTD: 58750000000000000000000 
    uint256 public constant MAX_TOKEN_SUPPLY_GENESIS = 5875;

    // contracts
    IEthKunRenderer public contractRenderer;

    enum MintStatus {
        CLOSED, // 0
        PUBLIC // 1
    }

    MintStatus public mintStatus = MintStatus.CLOSED;
    bool public revealEnabled = false;
    bool public mergeEnabled = false;
    bool public demoteRerollEnabled = false;
    bool public burnSacrificeEnabled = false;

    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public level;
    uint256 public maxLevel = 64;
    uint256 public mergeBlockNumber = 0; // estimated block# to be injected

    // tier 0 (free mint)
    uint256 public tier0_supply = 2000;
    uint256 public tier0_price = 0.0 ether;
    uint256 public tier0_maxTokensOwnedInWallet = 2;
    uint256 public tier0_maxMintsPerTransaction = 1;

    // tier 1 (paid)
    uint256 public tier1_price = 0.01 ether;
    uint256 public tier1_maxTokensOwnedInWallet = 64;
    uint256 public tier1_maxMintsPerTransaction = 64;

    uint256 public constant SECS_PER_DAY = 86400;

    // events
    event EthKunLevelUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel); // emitted when an EthKun levels up
    event EthKunDied(uint256 indexed tokenIdDied, uint256 level, uint256 indexed tokenMergedInto); // emitted when an EthKun dies
    event EthKunSacrificed(uint256 indexed tokenId); // emitted when an EthKun gets sacrificed upon the alter of Vitty B
    event EthRerolled(uint256 indexed tokenId, uint256 newLevel); // emitted when an EthKun gets rerolled

    constructor() ERC721A("ethkun", "ETHKUN") {
        //contractRenderer = IEthKunRenderer(this);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Invalid");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "Not approved nor owner"
        );
        
        _;
    }

    modifier verifySupplyGenesis(uint256 numToMint) {
        require(numToMint > 0, "Mint at least 1");
        require(_totalMinted() + numToMint <= MAX_TOKEN_SUPPLY_GENESIS, "Invalid");

        _;
    }

    // randomize seed
    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    /// @notice Burn sacrifice an ethkun at the altar of Lord Vitalik
    /// @param tokenId The tokenID for the EthKun
    function burnSacrifice(uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        //require(msg.sender == ownerOf(tokenId), "Not yours");
        require(burnSacrificeEnabled == true);

        _burn(tokenId);
        emit EthKunSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    function _mintEthKuns(address to, uint256 numToMint) private {
        uint256 startTokenId = _startTokenId() + _totalMinted();
         for(uint256 tokenId = startTokenId; tokenId < startTokenId+numToMint; tokenId++) {
            _saveSeed(tokenId);
            level[tokenId] = 1;
         }

         _safeMint(to, numToMint);
    }

    function reserveEthKuns(address to, uint256 numToMint) external onlyOwner {
        _mintEthKuns(to, numToMint);
    }

    function reserveEthKunsMany(address[] calldata recipients, uint256 numToMint) external onlyOwner {
        uint256 num = recipients.length;
        require(num > 0);

        for (uint256 i = 0; i < num; ++i) {
            _mintEthKuns(recipients[i], numToMint);    
        }
    }

    /// @notice Mint genesis ethkuns into your wallet!
    /// @param numToMint The number of genesis ethkuns to mint 
    function mintEthKunsGenesis(uint256 numToMint) external payable verifySupplyGenesis(numToMint) {
        require(mintStatus == MintStatus.PUBLIC, "Public mint closed");
        require(msg.value >= _getPrice(numToMint), "Incorrect ether sent" );

        // check max mint
        (uint256 maxTokensOwnedInWallet, uint256 maxMintsPerTransaction) = _getMaxMintsData();
        require(_numberMinted(msg.sender) + numToMint <= maxTokensOwnedInWallet, "Exceeds max mints");
        require(numToMint <= maxMintsPerTransaction, "Exceeds transaction max");

        _mintEthKuns(msg.sender, numToMint);
    }

    function _merge(uint256[] calldata tokenIds) private {
        uint256 num = tokenIds.length;
        require(num > 0);

        // all the levels accumulate to the first token
        uint256 tokenIdChad = tokenIds[0];
        uint256 accumulatedTotalLevel = 0;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 tokenLevel = level[tokenId];

            require( _ownershipOf(tokenId).addr == _msgSender() || getApproved(tokenId) == _msgSender(), "Denied");
            require(tokenLevel != 0, "Dead");

            accumulatedTotalLevel += tokenLevel;

            // burn if not main one
            if (i > 0) {
                _burn(tokenId);
                emit EthKunDied(tokenId, tokenLevel, tokenIdChad);

                // reset
                level[tokenId] = 0;
            }
        }

        require(accumulatedTotalLevel <= maxLevel, "Exceeded max level");

        uint256 prevLevel = level[tokenIdChad];
        level[tokenIdChad] = accumulatedTotalLevel;

        //_saveSeed(tokenIdChad);
        emit EthKunLevelUp(tokenIdChad, prevLevel, accumulatedTotalLevel);
    }

    /// @notice Merge several ethkuns into one buff gigachad ethkun, all the levels accumulate into the gigachad ethkun, but the remaining ethkuns are burned, gg
    /// @param tokenIds Array of owned tokenIds. Note that the first tokenId will be the one that remains and accumulates levels of other ethkuns, the other tokens will be BURNT!!
    function merge(uint256[] calldata tokenIds) external {
        require(_isRevealed() && mergeEnabled, "Not mergeable");
        _merge(tokenIds);
    }

    /// @notice Reroll the visuals/stats of ethkun, but unfortunately demotes them by -1 level :(
    /// @param tokenIds Array of owned tokenIds of ethkuns to demote
    function rerollMany(uint256[] calldata tokenIds) external {
        require(_isRevealed() && demoteRerollEnabled);

        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 tokenLevel = level[tokenId];

            require(_ownershipOf(tokenId).addr == _msgSender(), "Must own");
            require(tokenLevel > 1, "At least Lvl 1"); // need to be at least level 1 to reroll
            
            // reroll visuals/stats
            _saveSeed(tokenId); 

            // demote -1 evel
            uint256 tokenLevelDemoted = tokenLevel-1;
            level[tokenId] = tokenLevelDemoted; 

            emit EthRerolled(tokenId, tokenLevelDemoted);
        }
    }

    // taken from 'ERC721AQueryable.sol'
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    ///////////////////////////
    // -- GETTERS/SETTERS --
    ///////////////////////////
    function getNumMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function _getNumBabiesMinted() private view returns (uint256) {
        uint256 numTotalMinted = _totalMinted();

        if (numTotalMinted <= MAX_TOKEN_SUPPLY_GENESIS)
            return 0;

        return numTotalMinted - MAX_TOKEN_SUPPLY_GENESIS;
    }

    function getNumBabiesMinted() external view returns (uint256) {
        return _getNumBabiesMinted();
    }

    function setPricing(uint256[] calldata pricingData) external onlyOwner {
        // tier 0
        tier0_supply = pricingData[0];
        tier0_price = pricingData[1];
        tier0_maxTokensOwnedInWallet = pricingData[2];
        tier0_maxMintsPerTransaction = pricingData[3];

        // tier 1
        tier1_price = pricingData[4];
        tier1_maxTokensOwnedInWallet = pricingData[5];
        tier1_maxMintsPerTransaction = pricingData[6];

        require(tier0_supply <= MAX_TOKEN_SUPPLY_GENESIS);
    }

    function _getPrice(uint256 numToMint) private view returns (uint256) {
        uint256 numMintedAlready = _totalMinted();
        return numToMint * (numMintedAlready < tier0_supply ? tier0_price : tier1_price);
    }

    function getPrice(uint256 numToMint) external view returns (uint256) {
        return _getPrice(numToMint);
    }

    function _getMaxMintsData() private view returns (uint256 maxTokensOwnedInWallet, uint256 maxMintsPerTransaction) {
        uint256 numMintedAlready = _totalMinted();

        return (numMintedAlready < tier0_supply) ? 
            (tier0_maxTokensOwnedInWallet, tier0_maxMintsPerTransaction) 
            : (tier1_maxTokensOwnedInWallet, tier1_maxMintsPerTransaction);
    }

    function getMaxMintsData() external view returns (uint256 maxTokensOwnedInWallet, uint256 maxMintsPerTransaction) {
        return _getMaxMintsData() ;
    }

    function setMaxLevel(uint256 _maxLevel) external onlyOwner {
        maxLevel = _maxLevel;
    }

    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setContractRenderer(address newAddress) external onlyOwner {
        contractRenderer = IEthKunRenderer(newAddress);
    }

    function setRevealed(bool _revealEnabled) external onlyOwner {
        revealEnabled = _revealEnabled;
    }

    function setMergeEnabled(bool _enabled) external onlyOwner {
        mergeEnabled = _enabled;
    }

    function setMergeBlockNumber(uint256 newMergeBlockNumber) external onlyOwner {
        mergeBlockNumber = newMergeBlockNumber;
    }

    function setBurnSacrificeEnabled(bool _enabled) external onlyOwner {
        burnSacrificeEnabled = _enabled;
    }

    function setDemoteRerollEnabled(bool _enabled) external onlyOwner {
        demoteRerollEnabled = _enabled;
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    function isGenesis(uint256 tokenId) external pure returns(bool){
        return tokenId <= MAX_TOKEN_SUPPLY_GENESIS;
    }

    ///////////////////////////
    // -- MERKLE NERD STUFF --
    ///////////////////////////
    bytes32 public merkleRoot = 0x0;
    bool public merkleMintEnabled = false;
    uint256 public constant merkleMintMax = 1;

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleMintEnabled(bool _enabled) external onlyOwner {
        merkleMintEnabled = _enabled;
    }

    function _verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) private view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) external view returns (bool) {
        return _verifyMerkle(_proof, _leaf);
    }

    function verifyMerkleAddress(bytes32[] calldata _proof, address from) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return _verifyMerkle(_proof, leaf);
    }

    function mintMerkle(bytes32[] calldata _merkleProof, uint256 numToMint) external verifySupplyGenesis(numToMint) {
        require(merkleMintEnabled == true, "Merkle closed");
        require(_numberMinted(msg.sender) + numToMint <= merkleMintMax, "Can claim only 1");

        // verify merkle        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verifyMerkle(_merkleProof, leaf), "Invalid proof");

        _mintEthKuns(msg.sender, numToMint);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        //string[13] memory lookup = [  '0', '1', '2', '3', '4', '5', '6', '7', '8','9', '10','11', '12'];

        uint256 seed = seeds[tokenId];
        unchecked{ // unchecked so it can run over
            seed += mergeBlockNumber;
        }

        uint256 currentLevel = level[tokenId];

        string memory image = contractRenderer.getSVG(seed, currentLevel);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"ethkun #', Strings.toString(tokenId),'",',
                    '"description": "ethkun is an 100% on-chain dynamic NFT project with unique functionality and fun merge mechanics, made to celebrate The Merge! Gambatte ethkun!",',
                    '"attributes":[',
                        contractRenderer.getTraitsMetadata(seed),
                        _getStatsMetadata(seed, currentLevel),
                        '{"trait_type":"Genesis", "value":', (tokenId <= MAX_TOKEN_SUPPLY_GENESIS) ? '"Yes"' : '"No"', '},',
                        '{"trait_type":"Steaking", "value":', (steakingStartTimestamp[tokenId] != NULL_STEAKING) ? '"Yes"' : '"No"', '},',
                        '{"trait_type":"Level", "value":',Strings.toString(currentLevel),'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = contractRenderer.getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"ethkun #', Strings.toString(tokenId),'",',
                    '"description": "ethkun is an 100% on-chain dynamic NFT project with unique functionality and fun merge mechanics, made to celebrate The Merge! Gambatte ethkun!",',
                    '"attributes":[{"trait_type":"Waiting for The Merge", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _isRevealed() private view returns (bool) {
        return revealEnabled && block.number > mergeBlockNumber;   
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (_isRevealed()) 
            return _tokenURI(tokenId);
        else
            return _tokenUnrevealedURI(tokenId);
    }

    function _randStat(uint256 seed, uint256 div, uint256 min, uint256 max) private pure returns (uint256) {
        return min + (seed/div) % (max-min);
    }

    function _getStatsMetadata(uint256 seed, uint256 currLevel) private pure returns (string memory) {
        //string[11] memory lookup = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ];

        string memory metadata = string(abi.encodePacked(
          '{"trait_type":"Kimochii", "display_type": "number", "value":', Strings.toString(_randStat(seed, 2, 1, 5+currLevel)), '},',
          '{"trait_type":"UWU", "display_type": "number", "value":', Strings.toString(_randStat(seed, 3, 2, 10+currLevel)), '},',
          '{"trait_type":"Ultrasoundness", "display_type": "number", "value":', Strings.toString(_randStat(seed, 4, 2, 10+currLevel)), '},',
          '{"trait_type":"Fungibility", "display_type": "number", "value":', Strings.toString(_randStat(seed, 5, 2, 10+currLevel)), '},',
          '{"trait_type":"Sugoiness", "display_type": "number", "value":', Strings.toString(_randStat(seed, 6, 2, 10+currLevel)), '},',
          '{"trait_type":"Kakkoii", "display_type": "number", "value":', Strings.toString(_randStat(seed, 7, 2, 10+currLevel)), '},',
          '{"trait_type":"Kawaii", "display_type": "number", "value":', Strings.toString(_randStat(seed, 8, 2, 10+currLevel)), '},',
          '{"trait_type":"Moisturized", "display_type": "number", "value":', Strings.toString(_randStat(seed, 9, 2, 10+currLevel)), '},'
        ));

        return metadata;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    ///////////////////////////
    // -- STEAKING --
    ///////////////////////////

    bool public steakingEnabled = false;
    bool public mintingBabiesEnabled = false;
    uint256 public minSteakingLevel = 8; // ethkun's min level to allow for steaking
    uint256 private constant NULL_STEAKING = 0;

    // steaking curve parameters
    uint256 public steakingMinDays = 2;
    uint256 public steakingCurveDivisor = 8;
    uint256 public steakingLevelBoostDivisor = 16;

    // steaking
    mapping(uint256 => uint256) private steakingStartTimestamp; // tokenId -> steaking start time (0 = not steaking).
    mapping(uint256 => uint256) private steakingTotalTime; // tokenId -> cumulative steaking time, does not include current time if steaking
    
    // events
    event EventStartSteaking(uint256 indexed tokenId);
    event EventEndSteaking(uint256 indexed tokenId);
    event EventForceEndSteaking(uint256 indexed tokenId);
    event EventBirthBaby(uint256 indexed tokenIdParent, uint256 indexed tokenIdBaby);

    // currentSteakingTime: current steaking time in secs (0 = not steaking)
    // totalSteakingTime: total time of steaking (in secs)
    function getSteakingInfoForToken(uint256 tokenId) external view returns (uint256 currentSteakingTime, uint256 totalSteakingTime, bool steaking)
    {
        currentSteakingTime = 0;
        uint256 startTimestamp = steakingStartTimestamp[tokenId];

        // is steaking?
        if (startTimestamp != NULL_STEAKING) { 
            currentSteakingTime = block.timestamp - startTimestamp;
        }

        totalSteakingTime = currentSteakingTime + steakingTotalTime[tokenId];
        steaking = startTimestamp != NULL_STEAKING;
    }

    function setSteakingEnabled(bool allowed) external onlyOwner {
        steakingEnabled = allowed;
    }

    function setMintingBabiesEnabled(bool allowed) external onlyOwner {
        mintingBabiesEnabled = allowed;
    }

    function setSteakingMinLevel(uint256 _minLvl) external onlyOwner {
        minSteakingLevel = _minLvl;
    }

    function _toggleSteaking(uint256 tokenId) private onlyApprovedOrOwner(tokenId)
    {
        uint256 startTimestamp = steakingStartTimestamp[tokenId];

        if (startTimestamp == NULL_STEAKING) { 
            // start steaking
            require(steakingEnabled, "Disabled");
            require(level[tokenId] >= minSteakingLevel, "Not level");
            steakingStartTimestamp[tokenId] = block.timestamp;

            emit EventStartSteaking(tokenId);
        } else { 
            // start unsteaking
            steakingTotalTime[tokenId] += block.timestamp - startTimestamp;
            steakingStartTimestamp[tokenId] = NULL_STEAKING;

            emit EventEndSteaking(tokenId);
        }
    }

    /// @notice Token steaking on multiple ethkun tokens!
    /// @param tokenIds Array of ethkun tokenIds to toggle steaking 
    function toggleSteaking(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _toggleSteaking(tokenId);
        }
    }

    function _resetAndClearSteaking(uint256 tokenId) private {
        // end staking
        if (steakingStartTimestamp[tokenId] != NULL_STEAKING) {
            steakingStartTimestamp[tokenId] = NULL_STEAKING;
            emit EventEndSteaking(tokenId);
        }

        // clear total staking time
        if (steakingTotalTime[tokenId] != NULL_STEAKING)    
            steakingTotalTime[tokenId] = NULL_STEAKING;
    }

    function _adminForceStopSteaking(uint256 tokenId) private {
        require(steakingStartTimestamp[tokenId] != NULL_STEAKING, "Character not steaking");
        
        // accum current time
        uint256 deltaTime = block.timestamp - steakingStartTimestamp[tokenId];
        steakingTotalTime[tokenId] += deltaTime;

        // no longer steaking
        steakingStartTimestamp[tokenId] = NULL_STEAKING;

        emit EventEndSteaking(tokenId);
        emit EventForceEndSteaking(tokenId);
    }

    function adminForceStopSteaking(uint256[] calldata tokenIds) external onlyOwner {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _adminForceStopSteaking(tokenId);
        }
    }

    function _canSpawnEthKunBaby(uint256 tokenId) private view returns (bool) {
        uint256 currentSteakingTime = 0;
        uint256 startTimestamp = steakingStartTimestamp[tokenId];

        // is steaking?
        if (startTimestamp != NULL_STEAKING) { 
            currentSteakingTime = block.timestamp - startTimestamp;
        }

        uint256 totalSteakingTime = currentSteakingTime + steakingTotalTime[tokenId];
        
        return 
            totalSteakingTime >= _getSecsSteakingRequiredToMintBaby(tokenId)  // check staking time
            && level[tokenId] >= minSteakingLevel // check level
            && steakingStartTimestamp[tokenId] != NULL_STEAKING; // is staking
    }

    function canSpawnEthKunBaby(uint256 tokenId) external view returns (bool) {
        return _canSpawnEthKunBaby(tokenId);
    }

    /// @notice Set parameters for steaking
    /// @param _steakingMinDays Minimum days for steaking
    /// @param _steakingCurveDivisor Per baby coefficient divisor
    function setSteakingParams(uint256 _steakingMinDays, uint256 _steakingCurveDivisor, uint256 _steakingLevelBoostDivisor) external onlyOwner {
        steakingMinDays = _steakingMinDays;
        steakingCurveDivisor = _steakingCurveDivisor;
        steakingLevelBoostDivisor = _steakingLevelBoostDivisor;
    }

    function _getSecsSteakingRequiredToMintBaby(uint256 tokenId) private view returns (uint256) {

        // formula goes as such
        // secs requires to mint =
        //      min days
        //      + secsCurveFromBabies
        //      - levelBoost

        // curve for babies minted
        uint256 numBabiesMinted = _getNumBabiesMinted();
        uint256 secsFromBabiesMinted = (SECS_PER_DAY*numBabiesMinted)/steakingCurveDivisor;

        // reduction for higher level
        uint256 secsLevelSubtractor = 0;
        uint256 currLevel = level[tokenId];
        if (currLevel > minSteakingLevel) {
            secsLevelSubtractor = (SECS_PER_DAY*(currLevel - minSteakingLevel)) / steakingLevelBoostDivisor;
        }

        // cannot go below steakingMinDays
        if (secsLevelSubtractor > secsFromBabiesMinted) {
            secsLevelSubtractor = secsFromBabiesMinted;
        }

        uint256 secMinSteaked = steakingMinDays * SECS_PER_DAY + secsFromBabiesMinted - secsLevelSubtractor;
        
        // convert days to seconds
        return secMinSteaked;
    }

    /// @notice Mint a baby ethkun from steaked parent ethkun!
    /// @param parentTokenIds Steaked ethkun tokenIds to spawn from
    function mintEthKunBaby(uint256[] calldata parentTokenIds) external {
        _mintEthKunBabies(parentTokenIds);
    }

    function _mintEthKunBabies(uint256[] calldata parentTokenIds) private {
        require(mintingBabiesEnabled == true, "Babies disabled");
        //require(steakingEnabled == true, "Steaking disabled");

        uint256 num = parentTokenIds.length;
        for (uint256 i = 0; i < num; ++i) {

            uint256 parentTokenId = parentTokenIds[i];

            require(_ownershipOf(parentTokenId).addr == _msgSender() || getApproved(parentTokenId) == _msgSender(), "Denied");
            require(_canSpawnEthKunBaby(parentTokenId), "Not ready");

            // mint a new baby to owner's address!
            _mintEthKuns(_ownershipOf(parentTokenId).addr, 1);

            // reset staking to now
            steakingTotalTime[parentTokenId] = 0;
            steakingStartTimestamp[parentTokenId] = block.timestamp;

            uint256 childTokenId = _totalMinted();
            emit EventBirthBaby(parentTokenId, childTokenId);
        }
    }

     function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        // bypass for minting and burning
        if (from == address(0) || to == address(0))
            return;

        // transfers will cancel+clear steaking
        if (from != address(0)) {
            for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {
                _resetAndClearSteaking(tokenId);
            }
        }
    }

    function getSecsSteakingRequiredToMintBaby(uint256 tokenId) external view returns (uint256) {
        return _getSecsSteakingRequiredToMintBaby(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// coded by @eddietree

pragma solidity ^0.8.0;

interface IEthKunRenderer{
  function getSVG(uint256 seed, uint256 level) external view returns (string memory);
  function getUnrevealedSVG(uint256 seed) external view returns (string memory);
  function getTraitsMetadata(uint256 seed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// coded by @eddietree

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';
import "./IEthKunRenderer.sol";
import "./EthKunData.sol";

contract EthKunRenderer is IEthKunRenderer, EthKunData {

  string[] public bgPaletteColors = [
     'ffffff', 'fdf8db', 'fdeddb', 'fee5e0', 'feddec', 'feddf5', 'f7defe', 'ecddfe', 'dfdbfe', 'e1edfe', 'e4fafe', 'dffef3', 'dffee1', '122026'
  ];

  string[] public bodyColors = [
    '80b0bb','56b7e9','e1624a','85ae36',
    'e7b509','f6b099','85ae36','de953a',
    '56b7e9','dd5bca','80b0bb','56b7e9',
    'e1624a','85ae36','debb45', 'f6b099'
  ];
  
  struct CharacterData {
    uint background;

    uint body;
    uint eyes;
    uint mouth;
  }

  function getSVG(uint256 seed, uint256 level) external view returns (string memory) {
    return _getSVG(seed, level);
  }

  function _getSVG(uint256 seed, uint256 level) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    // clamp to max
    uint256 levelIndex = level;
    if (levelIndex > levels.length) 
    {
      levelIndex = levels.length;
    }
    levelIndex = levelIndex-1;// map from [1,32]->[0,31]

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" shape-rendering="crispEdges" width="512" height="512">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      //_renderRects(levels[levelIndex], fullPalettes),
      _renderRectsSingleColor(levels[levelIndex], fullPalettes, bodyColors[data.body]),
      //_renderRectsSingleColor(levels[seed % (levels.length)], fullPalettes, bodyColors[data.body]),
      _renderRects(bodies[data.body], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getUnrevealedSVG(uint256 seed) external view returns (string memory) {
    return _getUnrevealedSVG(seed);
  }

  function _getUnrevealedSVG(uint256) internal view returns (string memory) {
    //CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" shape-rendering="crispEdges" width="512" height="512">'
      //'<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      '<rect width="100%" height="100%" fill="#122026"/>',
      _renderRects(misc[0], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getTraitsMetadata(uint256 seed) external view returns (string memory) {
    return _getTraitsMetadata(seed);
  }

  function _getTraitsMetadata(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    // just for backgrounds
    string[15] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14'
    ];

    string memory metadata = string(abi.encodePacked(
      '{"trait_type":"Background", "value":"', lookup[data.background+1], '"},',
      '{"trait_type":"Body", "value":"', bodies_traits[data.body], '"},',
      '{"trait_type":"Eyes", "value":"', eyes_traits[data.eyes], '"},',
      '{"trait_type":"Mouth", "value":"', mouths_traits[data.mouth], '"},'
    ));

    return metadata;
  }

  function _renderRects(bytes memory data, string[] memory palette) private pure returns (string memory) {
    string[33] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
      '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
      '30', '31', '32'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (32px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);
        string memory color = palette[colorIndex];

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', color, '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _renderRectsSingleColor(bytes memory data, string[] memory palette, string memory color) private pure returns (string memory) {
    string[33] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
      '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
      '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
      '30', '31', '32'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (32px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex == 0) { // transparent
      }
      else if (colorIndex==1) { // black - replace color

        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', color, '"/>'));
      }
      else { // any othe rcolor
        uint8 x = uint8(drawIndex % 32);
        uint8 y = uint8(drawIndex / 32);

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', palette[colorIndex], '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateCharacterData(uint256 seed) private view returns (CharacterData memory) {
    return CharacterData({
      background: seed % bgPaletteColors.length,
      
      body: bodies_indices[(seed/2) % bodies_indices.length],
      eyes: eyes_indices[(seed/3) % eyes_indices.length],
      mouth: mouths_indices[(seed/4) % mouths_indices.length]
    });
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED FILE by @eddietree on Mon Sep 05 2022 16:40:03 GMT-0700 (Pacific Daylight Time)

pragma solidity ^0.8.0;

contract EthKunData {
	string[] public fullPalettes = ['ff00ff', '000000', 'ffffff', 'ff0000', '00ff00', '0000ff', '1e2528', 'eadece', 'ea6a6a', '80b0bb', '7991a1', 'e1624a', 'cb4227', '56b7e9', '3a88de', '85ae36', '509434', 'e7b509', 'da7e0d', 'f6b099', 'e37d74', 'de953a', 'c36c2d', 'efc567', 'f9dea3', 'e6b64d', '6ddeee', 'fdd3f6', '9ce5de', '276cd7', 'ed8dde', 'be3ccd', 'e56dd3', 'f7baee', 'dd5bca', '9035b4', 'debb45', 'ac622d', '813c22', '211d1a', '979fa1', '6b757d', 'fefefe'];

	///////////////////////////////////////
	// eyes
	bytes[] public eyes = [
		bytes(hex'ff00ff000f00010604000106'),
		bytes(hex'ff00ee00010604000106'),
		bytes(hex'ff008e00010604000106'),
		bytes(hex'ff002f00010602000106'),
		bytes(hex'ff00ce00020602000206'),
		bytes(hex'ff006e00020602000206'),
		bytes(hex'ff00cd000206040002061900020602000206'),
		bytes(hex'ff008d000206040002061900020602000206'),
		bytes(hex'ff00ad0002060400020619000206020002061a00010604000106'),
		bytes(hex'ff00ec0001060200010602000106020001061700020604000206'),
		bytes(hex'ff00cd0002060400020617000106020001060200010602000106'),
		bytes(hex'ff00ce000106040001061b00010602000106'),
		bytes(hex'ff006e000106040001061b00010602000106'),
		bytes(hex'ff00cf000106020001061b00010604000106'),
		bytes(hex'ff004f000106020001061b00010604000106'),
		bytes(hex'ff00ce000106040001061a00010604000106'),
		bytes(hex'ff006e000106040001061a00010604000106'),
		bytes(hex'ff00cd000206040002061900010604000106'),
		bytes(hex'ff00cd000306020003061900010604000106'),
		bytes(hex'ff00ad0003060200030619000206020002063a00020602000206'),
		bytes(hex'ff006d00020604000206180003060200030619000206020002063a00010604000106'),
		bytes(hex'ff00ac00040602000406140003060207040602070306140001060207010602000106020701061700020604000206'),
		bytes(hex'ff00ac0004060200040614000e0614000406020004061700020604000206'),
		bytes(hex'ff008c00030604000306150005060200050614000c0614000506020005061500030604000306'),
		bytes(hex'ff00cd000206040002061700010608000106'),
		bytes(hex'ff008c00020620000206030002061b00060617000206030006061b000206'),
		bytes(hex'ff00ec00010608000106'),
		bytes(hex'ff00ad000206040002061700020601070106020002060107010616000406020004061700020604000206'),
		bytes(hex'ff004d000206040002061700020601070106020002060107010616000406020004061700020604000206'),
		bytes(hex'ff00ad0003060200030638000107010601070200010701060107'),
		bytes(hex'ff004d0003060200030638000107010601070200010701060107'),
		bytes(hex'ff00ad00020604000206190002060200020619000107010601070200010701060107'),
		bytes(hex'ff004d00020604000206190002060200020619000107010601070200010701060107'),
		bytes(hex'ff00ad00020604000206170003070106020001060307160001070206010702000107020601071700020704000207'),
		bytes(hex'ff00ad000207040002071700040702000407160002070106010702000107010602071700020704000207'),
		bytes(hex'ff00cd00020704000207180001070106040001060107'),
		bytes(hex'ff006d00020704000207180001070106040001060107'),
		bytes(hex'ff00cd00030602000306180002070106020001060207180002070106020001060207'),
		bytes(hex'ff008d00030602000306180002070106020001060207180002070106020001060207'),
		bytes(hex'ff00d30002071700040602000107020601071d000207'),
		bytes(hex'ff00ee0001060400010619000208040002081800020804000208'),
		bytes(hex'ff00ac00040602000406140003060207040602070306140001060207010602000106020701061700020604000206160001080100010806000108010001083500010808000108'),
		bytes(hex'ff00ac0003070400030715000107030601070200010703060107140001070306010702000107030601071500030704000307'),
		bytes(hex'ff008e000206020002061900010606000106390001070106020001070106'),
		bytes(hex'ff00ad00030602000306180001070106010702000107010601071900010704000107'),
		bytes(hex'ff00cd00080617000a061800010604000106'),
		bytes(hex'ff004f000106020001061a0002060400020618000207040002071700020702060200020702061600020702060200020702061700020704000207'),
		bytes(hex'ff006d000306020003061700020602070200020702061600010601070206020002060107010615000208010702060200020601070208130004080600040812000408060004081300020808000208'),
		bytes(hex'ff00cd000206040002061700020606000206'),
		bytes(hex'ff008e00020602000206190003060200030618000206040002061a00010602000106')
	];

	string[] public eyes_traits = [
		'Vacant Low',
		'Vacant Medium',
		'Vacant High',
		'Vacant Too High',
		'Sleepy',
		'Sleepy High',
		'Angry',
		'Angry High',
		'Hero',
		'Somber',
		'Happy',
		'Slant',
		'Slant High',
		'Inverse',
		'Inverse High',
		'Cartoon',
		'Cartoon High',
		'Pensive',
		'Judgmental',
		'Dad',
		'Mad Dad',
		'Glasses',
		'Sunglasses',
		'Beeg Sunglasses',
		'Tired',
		'Pirate',
		'Dumb',
		'Animal',
		'Animal High',
		'Unsettling',
		'Unsettling High',
		'Villain',
		'Villain High',
		'Froggish',
		'Wide',
		'Beady',
		'Beady High',
		'JRPG',
		'JRPG High',
		'Wink',
		'Shy',
		'Nerd',
		'Stoned',
		'Sus',
		'Grump',
		'Unibrow',
		'Terrified',
		'Blushing',
		'Ambivalent',
		'Trustworthy'
	];

	uint8[] public eyes_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49];

	///////////////////////////////////////
	// mouths
	bytes[] public mouths = [
		bytes(hex'ff00ff0051000206'),
		bytes(hex'ff00ff0091000206'),
		bytes(hex'ff00ff0050000406'),
		bytes(hex'ff00ff0090000406'),
		bytes(hex'ff00ff0050000106020001061d000206'),
		bytes(hex'ff00ff00510002061d00010602000106'),
		bytes(hex'ff00ff004e0001060600010619000606'),
		bytes(hex'ff00ff004f0006061900010606000106'),
		bytes(hex'ff00ff006e0001060100010601000106010001061a000106010001060100010601000106'),
		bytes(hex'ff00ff00510002061e000206'),
		bytes(hex'ff00ff00910002061e000206'),
		bytes(hex'ff00ff00510002061d0004061c000406'),
		bytes(hex'ff00ff00500004061c0004061d000206'),
		bytes(hex'ff00ff00500004061b0006061a00020602000206'),
		bytes(hex'ff00ff004f000206020002061a0006061b000406'),
		bytes(hex'ff00ff004f0006061b000406'),
		bytes(hex'ff00ff004e0001060100040601000106180008061900020602000206'),
		bytes(hex'ff00ff00500004061b000106040701061a0006061b000406'),
		bytes(hex'ff00ff00530001061c0004061f000106'),
		bytes(hex'ff00ff0050000106020001061c0004061c00010602000106'),
		bytes(hex'ff00ff00540001061a0006061f000106'),
		bytes(hex'ff00ff004f000106040001061a0006061a00010604000106'),
		bytes(hex'ff00ff004f000106050001061a0005061b00010603000106'),
		bytes(hex'ff00ff004f00060619000106030701060207010619000606'),
		bytes(hex'ff00ff00510002061c000206020002061900010606000106'),
		bytes(hex'ff00ff005000010620000206'),
		bytes(hex'ff00ff00530001061d000206'),
		bytes(hex'ff00ff00720001061e000106'),
		bytes(hex'ff00ff00510002061d000106020001061c00010602000106'),
		bytes(hex'ff00ff006d000a06'),
		bytes(hex'ff00ff00510002061c00020602000206'),
		bytes(hex'ff00ff004f00020602000206190001060200020602000106'),
		bytes(hex'ff00ff006c0003060600030617000606'),
		bytes(hex'ff00ff0050000106020001061c000106020001061d000206'),
		bytes(hex'ff00ff006e00010602000206020001061900020602000206'),
		bytes(hex'ff00ff00520003061a00030601070106010701061c000306'),
		bytes(hex'ff00ff006e00020601070206010702061a000406'),
		bytes(hex'ff00ff0070000206010701061d000206'),
		bytes(hex'ff00ff00510002061d0004061c0004061d000206'),
		bytes(hex'ff00ff00300004061b0006061a0006061a0006061b000406'),
		bytes(hex'ff00ff0071000106'),
		bytes(hex'ff00ff0073000106'),
		bytes(hex'ff00ff006f00010620000206'),
		bytes(hex'ff00ff00740002061d000106'),
		bytes(hex'ff00ff00510002061d000106020001061c000106020001061d000206'),
		bytes(hex'ff00ff00700004061b000606'),
		bytes(hex'ff00ff006f00010620000206'),
		bytes(hex'ff00ff004d0001060800010616000a06'),
		bytes(hex'ff00ff0052000106200001061e000106200001061e000106'),
		bytes(hex'ff00ff006f000106040701061b0004061d000207')
	];

	string[] public mouths_traits = [
		'Smol',
		'Smol Low',
		'Normal',
		'Normal Low',
		'Smile',
		'Frown',
		'Wide Smile',
		'Wide Frown',
		'Cursed',
		'Oh',
		'Oh Low',
		'Yell',
		'Announce',
		'Shriek',
		'Address',
		'Naive',
		'Gentleman',
		'Teethy Yell',
		'Acorn',
		'Two Acorns',
		'Chewing',
		'Chomping',
		'Bubblecheeks',
		'Tyson',
		'Froggish',
		'Smirk',
		'Antismirk',
		'Hmm',
		'Unhappy',
		'Mostly Mouth',
		'Chewing Lip',
		'Wavy',
		'Burger',
		'Cute',
		'Cat',
		'Half Shell',
		'Vamp',
		'Scamp',
		'O',
		'OOO',
		'Peck',
		'Dot',
		'Side Smirk',
		'Determined',
		'Outline',
		'Regret',
		'Too Happy',
		'Bracket',
		'Smooch',
		'Car Salesman'
	];

	uint8[] public mouths_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49];

	///////////////////////////////////////
	// bodies
	bytes[] public bodies = [
		bytes(hex'6f000109010a1e000109010a1d000209020a1c000209020a1b000309030a1a000309030a19000409040a18000409040a17000509050a16000509050a15000609060a14000609060a13000709070a12000709070a11000809080a10000809080a0f000909090a10000709070a1000020902000509050a0200020a0f00030902000309030a0200030a1100040902000109010a0200040a130005090200050a15000509050a17000409040a19000309030a1b000209020a1d000109010a'),
		bytes(hex'6f00010d010e1e00010d010e1d00020d020e1c00020d020e1b00030d030e1a00030d030e1900040d040e1800040d040e1700050d050e1600050d050e1500060d060e1400060d060e1300070d070e1200070d070e1100080d080e1000080d080e0f00090d090e1000070d070e1000020d0200050d050e0200020e0f00030d0200030d030e0200030e1100040d0200010d010e0200040e1300050d0200050e1500050d050e1700040d040e1900030d030e1b00020d020e1d00010d010e'),
		bytes(hex'6f00010b010c1e00010b010c1d00020b020c1c00020b020c1b00030b030c1a00030b030c1900040b040c1800040b040c1700050b050c1600050b050c1500060b060c1400060b060c1300070b070c1200070b070c1100080b080c1000080b080c0f00090b090c1000070b070c1000020b0200050b050c0200020c0f00030b0200030b030c0200030c1100040b0200010b010c0200040c1300050b0200050c1500050b050c1700040b040c1900030b030c1b00020b020c1d00010b010c'),
		bytes(hex'6f00010f01101e00010f01101d00020f02101c00020f02101b00030f03101a00030f03101900040f04101800040f04101700050f05101600050f05101500060f06101400060f06101300070f07101200070f07101100080f08101000080f08100f00090f09101000070f07101000020f0200050f0510020002100f00030f0200030f0310020003101100040f0200010f0110020004101300050f020005101500050f05101700040f04101900030f03101b00020f02101d00010f0110'),
		bytes(hex'6f00011101121e00011101121d00021102121c00021102121b00031103121a00031103121900041104121800041104121700051105121600051105121500061106121400061106121300071107121200071107121100081108121000081108120f000911091210000711071210000211020005110512020002120f00031102000311031202000312110004110200011101120200041213000511020005121500051105121700041104121900031103121b00021102121d0001110112'),
		bytes(hex'6f00011301141e00011301141d00021302141c00021302141b00031303141a00031303141900041304141800041304141700051305141600051305141500061306141400061306141300071307141200071307141100081308141000081308140f000913091410000713071410000213020005130514020002140f00031302000313031402000314110004130200011301140200041413000513020005141500051305141700041304141900031303141b00021302141d0001130114'),
		bytes(hex'6f00010f010b1e00010f010b1d00020f020b1c00020f020b1b00030f030b1a00030f030b1900040f040b1800040f040b1700050f050b1600050f050b1500060f060b1400060f060b1300070f070b1200070f070b1100080f080b1000080f080b0f00090f090b1000070f070b1000020e0200050f050b020002150f00030e0200030f030b020003151100040e0200010f010b020004151300050e020005151500050e05151700040e04151900030e03151b00020e02151d00010e0115'),
		bytes(hex'6f0002161e0002161d0001160117011501161c0001160117011501161b0001160217021501161a0001160117021801150116190001160117011502180117011501161800011601170215021701190116170001160117011903150319011616000116011702190315021901161500011601170215021903150219011614000116011703150219031501190116130001160117051502190315011901161200011601170615021903150116110001160117081502190315011610000116011709150219021501160f00011601170b150219021501160e0002160c15021902160e000116011702160a150216011901160f000116021702160615021602190116110001160115021702160215021602190115011613000116021502170216021902150116150001160315021703150116170001160615011619000116041501161b000116021501161d000216'),
		bytes(hex'6f00011a010e1e00011a010e1d00010d011b020e1c00010d011c020e1b00020d011c030e1a00020d011a030e1900030d011a040e1800030d011a040e1700050d050e1600050d050e1500060d060e1400060d060e1300050d010e010d021d050e1200030d030e010d041d030e1100020d050e010d061d020e1000070e010d081d0f00080e010d091d1000060e010d071d1000020e0200040e010d051d0200021d0f00030e0200020e010d031d0200031d1100040e0200010d011d0200041d1300050e0200051d1500040e010d051d1700030e010d041d1900020e010d031d1b00010e010d021d1d00010d011d'),
		bytes(hex'6f00011e011f1e00011e011f1d000120011b021f1c0001200121021f1b0002200121031f1a000220011e031f19000320011e041f180001220220011e041f170003220220051f160004220120051f150005220120061f140005220120061f13000522011f01200223051f12000322031f01200423031f11000222051f01200623021f1000071f012008230f00081f012009231000061f01200723100002220200041f012005230200021f0f0003220200021f012003230200031f110004220200012001230200041f130005220200051f150004220120051f170003220120041f190002220120031f1b0001220120021f1d000120011f'),
		bytes(hex'6f000109010a1e000109010a1d000209020a1c000209020a1b000309030a1a000309030a19000409040a18000409040a17000509050a16000509050a15000609060a14000809040a13000509040a0209030a12000309080a0209010a110002090c0a02091000100a0f00120a10000e0a1000020902000a0a0200020a0f0003090200060a0200030a110004090200020a0200040a130005090200050a15000509050a17000409040a19000309030a1b000209020a1d000109010a'),
		bytes(hex'6f00010d010e1e00010d010e1d00020d020e1c00020d020e1b00030d030e1a00030d030e1900040d040e1800040d040e1700050d050e1600050d050e1500060d060e1400080d040e1300050d040e020d030e1200030d080e020d010e1100020d0c0e020d1000100e0f00120e10000e0e1000020d02000a0e0200020e0f00030d0200060e0200030e1100040d0200020e0200040e1300050d0200050e1500050d050e1700040d040e1900030d030e1b00020d020e1d00010d010e'),
		bytes(hex'6f00010b010c1e00010b010c1d00020b020c1c00020b020c1b00030b030c1a00030b030c1900040b040c1800040b040c1700050b050c1600050b050c1500060b060c1400080b040c1300050b040c020b030c1200030b080c020b010c1100020b0c0c020b1000100c0f00120c10000e0c1000020b02000a0c0200020c0f00030b0200060c0200030c1100040b0200020c0200040c1300050b0200050c1500050b050c1700040b040c1900030b030c1b00020b020c1d00010b010c'),
		bytes(hex'6f00010f01101e00010f01101d00020f02101c00020f02101b00030f03101a00030f03101900040f04101800040f04101700050f05101600050f05101500060f06101400080f04101300050f0410020f03101200030f0810020f01101100020f0c10020f100010100f00121010000e101000020f02000a10020002100f00030f02000610020003101100040f02000210020004101300050f020005101500050f05101700040f04101900030f03101b00020f02101d00010f0110'),
		bytes(hex'6f00012401151e00012401151d00022402151c00022402151b00032403151a00032403151900042404151800042404151700052405151600052405151500062406151400082404151300052404150224031512000324081502240115110002240c150224100010150f00121510000e151000022402000a15020002150f000324020006150200031511000424020002150200041513000524020005151500052405151700042404151900032403151b00022402151d0001240115'),
		bytes(hex'6f00011301141e00011301141d00021302141c00021302141b00031303141a00031303141900041304141800041304141700051305141600051305141500061306141400081304141300051304140213031412000313081402130114110002130c140213100010140f00121410000e141000021302000a14020002140f000313020006140200031411000413020002140200041413000513020005141500051305141700041304141900031303141b00021302141d0001130114')
	];

	string[] public bodies_traits = [
		'Dull',
		'Cool',
		'Hot',
		'Envy',
		'Sand',
		'Flesh',
		'Web2',
		'Gold',
		'Sapphire',
		'Amethyst',
		'Duller',
		'Cooler',
		'Hotter',
		'Jealous',
		'Sandier',
		'Fleshier'
	];

	uint8[] public bodies_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];

	///////////////////////////////////////
	// levels
	bytes[] public levels = [
		bytes(hex'2e0004011c000101020001011b000101040001011a000101040001011900010106000101180001010600010117000101080001011600010108000101150001010a000101140001010a000101130001010c000101120001010c000101110001010e000101100001010e0001010f000101100001010e000101100001010d000101120001010c000101120001010b000101140001010a000101140001010a000101140001010b000101120001010d000101100001010f0001010e000101110001010c000101130001010a0001011500010108000101170001010600010119000101040001011b000101020001011d000201'),
		bytes(hex'0e0004011b0006011a00020102000201190002010400020118000201040002011700020106000201160002010600020115000201080002011400020108000201130002010a000201120002010a000201110002010c000201100002010c0002010f0002010e0002010e0002010e0002010d000201100002010c000201100002010b000201120002010a0002011200020109000201140002010800020114000201080002011400020109000201120002010b000201100002010d0002010e0002010f0002010c000201110002010a00020113000201080002011500020106000201170002010400020119000201020002011b000401'),
		bytes(hex'0d000601190008011800030102000301170003010400030116000301040003011500030106000301140003010600030113000301080003011200030108000301110003010a000301100003010a0003010f0003010c0003010e0003010c0003010d0003010e0003010c0003010e0003010b000301100003010a0003011000030109000301120003010800030112000301070003011400030106000301140003010600030114000301070003011200030109000301100003010b0003010e0003010d0003010c0003010f0003010a000301110003010800030113000301060003011500030104000301170003010200030119000601'),
		bytes(hex'0c00080117000a0116000401020004011500040104000401140004010400040113000401060004011200040106000401110004010800040110000401080004010f0004010a0004010e0004010a0004010d0004010c0004010c0004010c0004010b0004010e0004010a0004010e000401090004011000040108000401100004010700040112000401060004011200040105000401140004010400040114000401040004011400040105000401120004010700040110000401090004010e0004010b0004010c0004010d0004010a0004010f0004010800040111000401060004011300040104000401150004010200040117000801'),
		bytes(hex'0b000a0115000c01140005010200050113000501040005011200050104000501110005010600050110000501060005010f000501080005010e000501080005010d0005010a0005010c0005010a0005010b0005010c0005010a0005010c000501090005010e000501080005010e000501070005011000050106000501100005010500050112000501040005011200050103000501140005010200050114000501020005011400050103000501120005010500050110000501070005010e000501090005010c0005010b0005010a0005010d000501080005010f000501060005011100050104000501130005010200050115000a01'),
		bytes(hex'0a000c0113000e011200060102000601110006010400060110000601040006010f000601060006010e000601060006010d000601080006010c000601080006010b0006010a0006010a0006010a000601090006010c000601080006010c000601070006010e000601060006010e00060105000601100006010400060110000601030006011200060102000601120006010100060114000601060114000601060114000601000101000601120006010300060110000601050006010e000601070006010c000601090006010a0006010b000601080006010d000601060006010f00060104000601110006010200060113000c01'),
		bytes(hex'09000e011100100110000701020007010f000701040007010e000701040007010d000701060007010c000701060007010b000701080007010a00070108000701090007010a000701080007010a000701070007010c000701060007010c000701050007010e000701040007010e00070103000701100007010200070110000701010007011200070107011200070106011400060106011400060106011400060107011200070100010100070110000701030007010e000701050007010c000701070007010a00070109000701080007010b000701060007010d000701040007010f0007010200070111000e01'),
		bytes(hex'080010010f0012010e000801020008010d000801040008010c000801040008010b000801060008010a0008010600080109000801080008010800080108000801070008010a000801060008010a000801050008010c000801040008010c000801030008010e000801020008010e00080101000801100008010801100008010701120007010701120007010601140006010601140006010601140006010701120007010801100008010001010008010e000801030008010c000801050008010a000801070008010800080109000801060008010b000801040008010d000801020008010f001001'),
		bytes(hex'070012010d0014010c000901020009010b000901040009010a000901040009010900090106000901080009010600090107000901080009010600090108000901050009010a000901040009010a000901030009010c000901020009010c000901010009010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010001010009010c000901030009010a0009010500090108000901070009010600090109000901040009010b000901020009010d001201'),
		bytes(hex'060014010b0016010a000a0102000a0109000a0104000a0108000a0104000a0107000a0106000a0106000a0106000a0105000a0108000a0104000a0108000a0103000a010a000a0102000a010a000a0101000a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a01000101000a010a000a0103000a0108000a0105000a0106000a0107000a0104000a0109000a0102000a010b001401'),
		bytes(hex'050016010900180108000b0102000b0107000b0104000b0106000b0104000b0105000b0106000b0104000b0106000b0103000b0108000b0102000b0108000b0101000b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b01000101000b0108000b0103000b0106000b0105000b0104000b0107000b0102000b0109001601'),
		bytes(hex'0400180107001a0106000c0102000c0105000c0104000c0104000c0104000c0103000c0106000c0102000c0106000c0101000c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c01000101000c0106000c0103000c0104000c0105000c0102000c0107001801'),
		bytes(hex'03001a0105001c0104000d0102000d0103000d0104000d0102000d0104000d0101000d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d01000101000d0104000d0103000d0102000d0105001a01'),
		bytes(hex'02001c0103001e0102000e0102000e0101000e0104000e010e0104000e010d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d010e0104000e01000101000e0102000e0103001c01'),
		bytes(hex'01001e01010020010f0102000f010e0104000e010e0104000e010d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d010e0104000e010f0102000f01000101001e01'),
		bytes(hex'200120010f0102000f010e0104000e010e0104000e010d0106000d010d0106000d010c0108000c010c0108000c010b010a000b010b010a000b010a010c000a010a010c000a0109010e00090109010e00090108011000080108011000080107011200070107011200070106011400060106011400060106011400060107011200070108011000080109010e0009010a010c000a010b010a000b010c0108000c010d0106000d010e0104000e010f0102000f0120010001'),
		bytes(hex'0e0104000e010d010100040101000d010d01010001010200010101000d010c01010001010400010101000c010c01010001010400010101000c010b01010001010600010101000b010b01010001010600010101000b010a01010001010800010101000a010a01010001010800010101000a010901010001010a000101010009010901010001010a000101010009010801010001010c000101010008010801010001010c000101010008010701010001010e000101010007010701010001010e000101010007010601010001011000010101000601060101000101100001010100060105010100010112000101010005010501010001011200010101000501040101000101140001010100040104010100010114000101010004010401010001011400010101000401050101000101120001010100050106010100010110000101010006010701010001010e000101010007010801010001010c000101010008010901010001010a000101010009010a01010001010800010101000a010b01010001010600010101000b010c01010001010400010101000c010d01010001010200010101000d010e010100020101000e010001'),
		bytes(hex'0c01010001010400010101000c010b0101000101010004010100010101000b010b010100010101000101020001010100010101000b010a010100010101000101040001010100010101000a010a010100010101000101040001010100010101000a0109010100010101000101060001010100010101000901090101000101010001010600010101000101010009010801010001010100010108000101010001010100080108010100010101000101080001010100010101000801070101000101010001010a0001010100010101000701070101000101010001010a0001010100010101000701060101000101010001010c0001010100010101000601060101000101010001010c0001010100010101000601050101000101010001010e0001010100010101000501050101000101010001010e0001010100010101000501040101000101010001011000010101000101010004010401010001010100010110000101010001010100040103010100010101000101120001010100010101000301030101000101010001011200010101000101010003010201010001010100010114000101010001010100020102010100010101000101140001010100010101000201020101000101010001011400010101000101010002010301010001010100010112000101010001010100030104010100010101000101100001010100010101000401050101000101010001010e0001010100010101000501060101000101010001010c0001010100010101000601070101000101010001010a000101010001010100070108010100010101000101080001010100010101000801090101000101010001010600010101000101010009010a010100010101000101040001010100010101000a010b010100010101000101020001010100010101000b010c0101000101010002010100010101000c010001'),
		bytes(hex'0a010100010101000101040001010100010101000a01090101000101010001010100040101000101010001010100090109010100010101000101010001010200010101000101010001010100090108010100010101000101010001010400010101000101010001010100080108010100010101000101010001010400010101000101010001010100080107010100010101000101010001010600010101000101010001010100070107010100010101000101010001010600010101000101010001010100070106010100010101000101010001010800010101000101010001010100060106010100010101000101010001010800010101000101010001010100060105010100010101000101010001010a00010101000101010001010100050105010100010101000101010001010a00010101000101010001010100050104010100010101000101010001010c00010101000101010001010100040104010100010101000101010001010c00010101000101010001010100040103010100010101000101010001010e00010101000101010001010100030103010100010101000101010001010e0001010100010101000101010003010201010001010100010101000101100001010100010101000101010002010201010001010100010101000101100001010100010101000101010002010101010001010100010101000101120001010100010101000101010001010101010001010100010101000101120001010100010101000101010001010001010001010100010101000101140001010100010101000101020001010100010101000101140001010100010101000101020001010100010101000101140001010100010101000101010001010100010101000101010001011200010101000101010001010100010102010100010101000101010001011000010101000101010001010100020103010100010101000101010001010e00010101000101010001010100030104010100010101000101010001010c00010101000101010001010100040105010100010101000101010001010a0001010100010101000101010005010601010001010100010101000101080001010100010101000101010006010701010001010100010101000101060001010100010101000101010007010801010001010100010101000101040001010100010101000101010008010901010001010100010101000101020001010100010101000101010009010a01010001010100010101000201010001010100010101000a010001'),
		bytes(hex'05010300030103000401030003010300050105010200040102000601020004010200050104010300030103000201020002010300030103000401040102000401020002010400020102000401020004010301030003010300020104000201030003010300030103010200040102000201060002010200040102000301020103000301030002010600020103000301030002010201020004010200020108000201020004010200020101010300030103000201080002010300030103000101010102000401020002010a0002010200040102000101000103000301030002010a0002010300030105000401020002010c0002010200040104000301030002010c0002010300030103000401020002010e0002010200040102000301030002010e0002010300030101000401020002011000020102000401030103000201100002010300030103010200020112000201020003010201030002011200020103000201020102000201140002010200020101010300020114000201030001010101030002011400020103000101020103000201120002010300020103010300020110000201030003010401030002010e00020103000401000101000401030002010c0002010300040103000401030002010a000201030004010500040103000201080002010300040103000101030004010300020106000201030004010300010102010300040103000201040002010300040103000201030103000401030002010200020104000301030003010401030004010300040104000301030004010001'),
		bytes(hex'080103000a0103000801070104000a010400070107010300050102000501030007010601040004010400040104000601060103000501040005010300060105010400040106000401040005010501030005010600050103000501040104000401080004010400040104010300050108000501030004010301040004010a000401040003010301030005010a000501030003010201040004010c000401040002010201030005010c000501030002010101040004010e000401040001010101030005010e000501030001010001040004011000040107000501100005010600040112000401050005011200050104000401140004010300050114000501020005011400050103000501120005010500050110000501070005010e000501090005010c00050105000101050005010a000501050001010201050005010800050105000201030105000501060005010500030104010500050104000501050004010501050005010200050105000501060105000a01050006010001'),
		bytes(hex'05010400010104000401040001010400050105010300010104000601040001010300050104010400010104000201020002010400010104000401040103000101040002010400020104000101030004010301040001010400020104000201040001010400030103010300010104000201060002010400010103000301020104000101040002010600020104000101040002010201030001010400020108000201040001010300020101010400010104000201080002010400010104000101010103000101040002010a0002010400010103000101000104000101040002010a0002010400010107000101040002010c0002010400010106000101040002010c0002010400010105000101040002010e0002010400010104000101040002010e0002010400010103000101040002011000020104000101020001010400020110000201040001010100010104000201120002010400010101010400020112000201040001010001040002011400020108000201140002010800020114000201090002011200020105000101050002011000020105000101000101000101050002010e0002010500010103000101050002010c0002010500010105000101050002010a000201050001010700010105000201080002010500010104000101040001010500020106000201050001010400010102010400010105000201040002010500010104000201030104000101050002010200020105000101040003010401040001010500040105000101040004010001'),
		bytes(hex'06000101120001010c00010107000401070001010800020101000a0102000a01010002010400010102000901040009010200010106000a0104000a0106000b0106000b0102000d0106000d01000102000a0108000a0104000a0108000a01040009010a000901040009010a000901040008010c000801040008010c000801040007010e000701040007010e000701040006011000060104000601100006010400050112000501040005011200050104000401140004010400040114000401040004011400040104000501120005010400060110000601040007010e00070102000a010c000a010001020009010a00090106000801080008010600010102000801060008010200010104000201010009010400090101000201080001010600020102000201060001010c0001010700040107000101'),
		bytes(hex'06000101120001010c00010107000401070001010800020101000a0102000a01010002010400010102000101070001010400010107000101020001010600020101000701040007010100020106000301010007010600070101000301020003010200080106000801020003010001020001010100080108000801010001010400010101000801080008010100010104000101010007010a0007010100010104000101010007010a0007010100010104000101010006010c0006010100010104000101010006010c0006010100010104000101010005010e0005010100010104000101010005010e0005010100010104000101010004011000040101000101040001010100040110000401010001010400010101000301120003010100010104000101010003011200030101000101040001010100020114000201010001010400010101000201140002010100010104000101010002011400020101000101040001010100030112000301010001010400010101000401100004010100010104000101010005010e0005010100010102000301020005010c00050102000301000102000301010005010a000501010003010600020101000501080005010100020106000101020001010500020106000201050001010200010104000201010009010400090101000201080001010600020102000201060001010c0001010700040107000101'),
		bytes(hex'06000101120001010c00010107000401070001010800020101000a0102000a01010002010400010102000101070001010400010107000101020001010600020101000701040007010100020106000301010007010600070101000301020003010200080106000801020003010001020001010100080108000801010001010400010101000801080008010100010104000101010007010a0007010100010104000101010007010a0007010100010104000101010006010c0006010100010104000101010006010c0006010100010104000101010005010e0005010100010104000101010005010e0005010100010104000101010004011000040101000101040001010100040110000401010001010400010101000301120003010100010104000101010003011200030101000101040001010100020114000201010001010400010101000201140002010100010104000101010002011400020101000101040001010100030112000301010001010400010101000401100004010100010104000101010005010e0005010100010102000301020005010c00050102000301000102000301010005010a000501010003010600020101000501080005010100020106000101020001010500020106000201050001010200010104000201010009010400090101000201080001010600020102000201060001010c0001010700040107000101'),
		bytes(hex'06000101120001010700030102000101070004010700010102000301020001010100010101000a0102000a0101000101010001010200030101000101070001010400010107000101010003010600010101000701040007010100010107000401010006010600060101000401020003010300070106000701030003010001020001010100080108000801010001010400010101000801080008010100010104000101010007010a0007010100010104000101010007010a0007010100010104000101010006010c0006010100010104000101010006010c0006010100010104000101010005010e0005010100010104000101010005010e0005010100010104000101010004011000040101000101040001010100040110000401010001010400010101000301120003010100010104000101010003011200030101000101040001010100020114000201010001010400010101000201140002010100010104000101010002011400020101000101040001010100030112000301010001010400010101000401100004010100010104000101010005010e0005010100010102000301030004010c00040103000301000102000401010004010a0004010100040107000101010005010800050101000101060003010100010105000201060002010500010101000301020001010100010101000901040009010100010101000101020003010200010106000201020002010600010102000301070001010700040107000101'),
		bytes(hex'0500010114000101060003010100010108000401080001010100030102000101010001010200090102000901020001010100010102000501010001010500010104000101050001010100050104000101010001010100070104000701010001010100010103000201010003010100060106000601010003010100020100010200010103000701060007010300010104000a0108000a010400010101000801080008010100010104000101010007010a0007010100010104000101010007010a0007010100010104000101010006010c0006010100010104000101010006010c0006010100010104000101010005010e0005010100010104000101010005010e00050101000101040001010100040110000401010001010400010101000401100004010100010104000101010003011200030101000101040001010100030112000301010001010400010101000201140002010100010104000101010002011400020101000101040001010100020114000201010001010400010101000301120003010100010104000101010004011000040101000101040007010e00070104000101030004010c000401030001010200020101000301010004010a00040101000301010002010001030001010100010101000501080005010100010101000101040005010100010103000201060002010300010101000501020001010100010102000801040008010200010101000101020003010100010107000201020002010700010101000301060001010800040108000101'),
		bytes(hex'05000101140001010600030101000101080004010800010101000301020001010100010102000101060002010200020106000101020001010100010102000501010001010500010104000101050001010100050104000101010001010100070104000701010001010100010103000201010003010100060106000601010003010100020100010200010103000701060007010300010105000901080009010700080108000801080007010a000701080007010a000701080006010c000601080006010c000601080005010e000501080005010e000501080004011000040108000401100004010800030112000301080003011200030108000201140002010800020114000201080002011400020108000301120003010800040110000401070006010e00060105000101030004010c000401030001010200020101000301010004010a000401010003010100020100010300010101000101010005010800050101000101010001010400050101000101030002010600020103000101010005010200010101000101020001010500020104000201050001010200010101000101020003010100010107000201020002010700010101000301060001010800040108000101'),
		bytes(hex'05000101140001010600030101000101020001010200010102000401020001010200010102000101010003010200010101000101020001010200020102000201020002010200020102000101020001010100010102000501010001010500010104000101050001010100050104000101010001010100070104000701010001010100010103000201010003010100060106000601010003010100020100010200010103000701060007010300010105000901080009010400010102000801080008010200010102000101020007010a0007010200010103000101010007010a0007010100010104000101010006010c0006010100010103000101020006010c0006010200010102000101020005010e0005010200010103000101010005010e0005010100010104000101010004011000040101000101030001010200040110000401020001010200010102000301120003010200010103000101010003011200030101000101040001010100020114000201010001010300010102000201140002010200010102000101020002011400020102000101030001010100030112000301010001010600040110000401070006010e00060105000101030004010c000401030001010200020101000301010004010a00040101000301010002010001030001010100010101000501080005010100010101000101040005010100010103000201060002010300010101000501020001010100010102000101020001010200020104000201020001010200010102000101010001010200030101000101020001010400020102000201040001010200010101000301060001010800040108000101'),
		bytes(hex'0225012603250126072501270201012707250126032501260225022501260325012606250127040101270625012603250126022500250226032501260127012604250127020102000201012704250126012701260325022600260525012701010127012602250127020104000201012702250126012701010127052504250126012702010327030104000301032702010127012604250225012602270801060008010227012602250025022601270a0106000a01012702260026022501260127080108000801012701260225032501260127070108000701012701260325002501260325012706010a0006010127032501260026012501260225012706010a0006010127022501260125012501260225012705010c0005010127022501260125002501260325012705010c000501012703250126002603250126012704010e00040101270126032503250126012704010e000401012701260325032501270401100004010127032503250127040110000401012703250325012601270201120002010127012603250325012601270201120002010127012603250025012603250127010114000101012703250126002601250126022501270101140001010127022501260125012501260225012701011400010101270225012601250025012603250127020112000201012703250126002603250126012703011000030101270126032502250126012705010e00050101270126022500250226012707010c00070101270226002602250126022706010a000601022701260225042501260127020103270101080001010327020101270126042505250127010101270126022501270101060001010127022501260127010101270525002502260325012601270126042501270101040001010127042501260127012603250226002602250126032501260625012701010200010101270625012603250126022502250126032501260725012702010127072501260325012602250025'),
		bytes(hex'0228012903280129072801270201012707280129032801290228022801290328012906280127040101270628012903280129022800280229032801290127012904280127020102000201012704280129012701290328022900290528012701010127012902280127020104000201012702280129012701010127052804280129012702010327030104000301032702010127012904280228012902270801060008010227012902280028022901270a0106000a01012702290029022801290127080108000801012701290228032801290127070108000701012701290328002801290328012706010a0006010127032801290029012801290228012706010a0006010127022801290128012801290228012705010c0005010127022801290128002801290328012705010c000501012703280129002903280129012704010e00040101270129032803280129012704010e000401012701290328032801270401100004010127032803280127040110000401012703280328012901270201120002010127012903280328012901270201120002010127012903280028012903280127010114000101012703280129002901280129022801270101140001010127022801290128012801290228012701011400010101270228012901280028012903280127020112000201012703280129002903280129012703011000030101270129032802280129012705010e00050101270129022800280229012707010c00070101270229002902280129022706010a000601022701290228042801290127020103270101080001010327020101270129042805280127010101270129022801270101060001010127022801290127010101270528002802290328012901270129042801270101040001010127042801290127012903280229002902280129032801290628012701010200010101270628012903280129022802280129032801290728012702010127072801290328012902280028'),
		bytes(hex'0215011603150116071501270201012707150116031501160215021501160315011606150127040101270615011603150116021500150216031501160127011604150127020102000201012704150116012701160315021600160515012701010127011602150127020104000201012702150116012701010127051504150116012702010327030104000301032702010127011604150215011602270801060008010227011602150015021601270a0106000a01012702160016021501160127080108000801012701160215031501160127070108000701012701160315001501160315012706010a0006010127031501160016011501160215012706010a0006010127021501160115011501160215012705010c0005010127021501160115001501160315012705010c000501012703150116001603150116012704010e00040101270116031503150116012704010e000401012701160315031501270401100004010127031503150127040110000401012703150315011601270201120002010127011603150315011601270201120002010127011603150015011603150127010114000101012703150116001601150116021501270101140001010127021501160115011501160215012701011400010101270215011601150015011603150127020112000201012703150116001603150116012703011000030101270116031502150116012705010e00050101270116021500150216012707010c00070101270216001602150116022706010a000601022701160215041501160127020103270101080001010327020101270116041505150127010101270116021501270101060001010127021501160127010101270515001502160315011601270116041501270101040001010127041501160127011603150216001602150116031501160615012701010200010101270615011603150116021502150116031501160715012702010127071501160315011602150015')
	];

	uint8[] public levels_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];

	///////////////////////////////////////
	// misc
	bytes[] public misc = [
		bytes(hex'6f00022a1e00022a1d00042a1c00042a1b00062a1a00062a1900082a1800082a17000a2a1600032a0400032a1500032a0600032a1400032a0200022a0200032a1300072a0300042a1200062a0300052a1100072a0200072a1000102a0f00082a0200082a1000062a0200062a1000022a02000a2a0200022a0f00032a0200062a0200032a1100042a0200022a0200042a1300052a0200052a15000a2a1700082a1900062a1b00042a1d00022a')
	];
}

// SPDX-License-Identifier: MIT

/*
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  CRYPTO EDDIES  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   by @eddietree  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'....................................:0WWWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNo.                                    ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWWNd'..;looooooooooooooooooooooooooooooooooooc,..;OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNWNl   ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.  .kWNNNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNd,',:llldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxollc;'';OWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ,kOOOOOOOOOOO0000000KKKKKKKKKKKKKKKKK00000000Kx.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOO000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKOl;;ckKKKKKKKKKKKKKKKKkc;;lOXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKk'  .oKKKKKKKKKKKKKKKXo.  .xXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNNNXxllc.   ;kOOOOOO0KKKKKKK0occc::::cxKKKKKKKkc:::cccoOKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWMMX;       ;kOOOOOO0KKKKKKKKKKXO,    cKKKKKKKl   'OXXXKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXNNNKxoolc:::::::okOOOOOO0KKKKKKK0occc:::::xKKKKKKKxc:::cccoOKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKK0OOOOOOO0KKKKKKXk'  .oKKKKKKKKKKKKKKXKo.  .xKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKK000OOOO0KKKKKKKOl;;:kKKKKKKKKK0000KKKkc;;lOKKOl;;:lddd0NNNXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKKKKK0OOO0KKKKKKKKKKKKKKKKKKKKK0kkkOKKKKKKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXNWWKo;;:coooooookKKKK0000KKKKKKKKKKK0xooookKKKxc::d0KKOdood0KKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWWMX;       :0KKKKKKKKKKKKKKKKKXO,    cKKKc   ;0KXo.  .xKKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXo,,,,,,,coodkKKKKKKKKKKKKKKK0c''',codo:''':oddc,'':kXKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNl   ;0KKKKKKKKKKKKKKKKKKKO;   :0K0l.  ,kKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNx,'':dddkKKKKKKKKKKKKKKKX0l..'oKKKd'..:OXKKKKK0kddo:'',xWWWNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNd.  ,OXKKKKKKKKKKKKKKKK000KKKKK0000KKKKKKKk,  .dNNNNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXNXK000o'..;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;..,kWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWMWo...;k0Ol.                                    'xXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXKK0l...c0KKd'............................     ...,OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNl...:kOO0KKX0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.  .xKKXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXX0c...cKKK0OOO0KKKKKKKKKKKKKKKKKKKKKKKKK0OOOl.  '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXc..'cxkk0KKKo...:OKKKKKKKOkkO0KKKK0kkO0KKKo'...   '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   lKKKKKKKl.  ,x000KKKKOkkk0KKKKOkkk0KKKl       ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   cKKKKKKK0xxxl'..;kXKKK000KKKKKK000KKKKl   .oxxo,'.:OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;  .c000KKKKKKKKo.  .xKKKKKKKKKKKKKKKKKKKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXNNX0kkkc'''oKKKKKKKo.  .xKK0dlloxkkkkkkkk0KKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMNc   :0KKKKKKo.  .xKKOl:::oxxxxxxxxOKKKl   'kKKd.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNNNX0xxxc,,,,,,,;loox0KKOl:::oxxxxxxxxOKKKl    ',,:oxxkKNNNXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNMMWl       'kXKKKKKOl;::oxxxxxxxxOKKKl       '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNNN0ddd;   'OXXkc,,;;:::oxxxxxxxxOKKKl   .lddkKNNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OXXd.   ':::oxxxxxxxxOKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKXx.  .lOOO0KKK0o,,,oKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKKd.  .kMMMMMMMNc   :0XKl   ,KMMWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'..:OXXk;..;OWWWWWWWNo...lKKKd'..cKWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";
import "./CryptoDeddies.sol";

/// @title CryptoEddies
/// @author Eddie Lee
/// @notice CryptoEddies is an 100% on-chain experimental NFT character project.
contract CryptoEddies is EddieRenderer, ERC721A, Ownable {
    
    uint256 public constant MAX_TOKEN_SUPPLY = 3500;

    // 3 pricing tiers
    uint256 public tier0_price = 0.01 ether;
    uint256 public tier1_price = 0.015 ether;
    uint256 public tier2_price = 0.02 ether;
    uint256 public tier0_supply = 2000;
    uint256 public tier1_supply = 1000;

    uint256 public maxMintsPerPersonPublic = 150;
    uint256 public maxMintsPerPersonWhitelist = 1;
    uint public constant MAX_HP = 5;

    CryptoDeddies public contractGhost;

    enum MintStatus {
        CLOSED, // 0
        WHITELIST, // 1
        PUBLIC // 2
    }

    MintStatus public mintStatus = MintStatus.CLOSED;
    bool public revealed = false;

    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public hp; // health power

    // events
    event EddieDied(uint256 indexed tokenId); // emitted when an HP goes to zero
    event EddieRerolled(uint256 indexed tokenId); // emitted when an Eddie gets re-rolled
    event EddieSacrificed(uint256 indexed tokenId); // emitted when an Eddie gets sacrificed

    constructor() ERC721A("CryptoEddies", "EDDIE") {
    }

    modifier verifySupply(uint256 numEddiesToMint) {
        //require(tx.origin == msg.sender,  "No bots");
        require(numEddiesToMint > 0, "Mint at least 1");
        require(_totalMinted() + numEddiesToMint <= MAX_TOKEN_SUPPLY, "Exceeds max supply");

        _;
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    function _mintEddies(address to, uint256 numEddiesToMint) private verifySupply(numEddiesToMint) {
        uint256 startTokenId = _startTokenId() + _totalMinted();
         for(uint256 tokenId = startTokenId; tokenId < startTokenId+numEddiesToMint; tokenId++) {
            _saveSeed(tokenId);
            hp[tokenId] = MAX_HP;
         }

         _safeMint(to, numEddiesToMint);
    }

    function reserveEddies(address to, uint256 numEddiesToMint) external onlyOwner {
        _mintEddies(to, numEddiesToMint);
    }

    function reserveEddiesToManyFolk(address[] calldata addresses, uint256 numEddiesToMint) external {
        uint256 num = addresses.length;
        for (uint256 i = 0; i < num; ++i) {
            address to = addresses[i];
            _mintEddies(to, numEddiesToMint);
        }
    }

    /// @notice Mints CryptoEddies into your wallet! payableAmount is the total amount of ETH to mint all numEddiesToMint (costPerCryptoEddie * numEddiesToMint)
    /// @param numEddiesToMint The number of CryptoEddies you want to mint
    function mintEddies(uint256 numEddiesToMint) external payable {
        require(mintStatus == MintStatus.PUBLIC, "Public mint closed");
        require(msg.value >= _getPrice(numEddiesToMint), "Incorrect ether" );
        require(_numberMinted(msg.sender) + numEddiesToMint <= maxMintsPerPersonPublic, "Exceeds max mints");

        _mintEddies(msg.sender, numEddiesToMint);
    }

    function _rerollEddie(uint256 tokenId) verifyTokenId(tokenId) private {
        require(revealed == true, "Not revealed");
        require(hp[tokenId] > 0, "No HP");
        require(msg.sender == ownerOf(tokenId), "Not yours");

        _saveSeed(tokenId);   
        _takeDamageHP(tokenId, msg.sender);

        emit EddieRerolled(tokenId);
    }

    /// @notice Rerolls the visuals and stats of one CryptoEddie, deals -1 HP damage!
    /// @param tokenId The token ID for the CryptoEddie to reroll
    function rerollEddie(uint256 tokenId) external {
        _rerollEddie(tokenId);
    }

    function rerollEddieMany(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _rerollEddie(tokenId);
        }
    }

    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    // @notice Destroys your CryptoEddie, spawning a ghost
    /// @param tokenId The token ID for the CryptoEddie
    function burnSacrifice(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not yours");
        _burn(tokenId);

        // if not already dead, force kill and spawn ghost
        if (hp[tokenId] > 0) {
            hp[tokenId] = 0;
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(msg.sender, tokenId, seeds[tokenId]);
            }
        }

        emit EddieSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    // taken from 'ERC721AQueryable.sol'
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function _getPrice(uint256 numPayable) private view returns (uint256) {
        uint256 numMintedAlready = _totalMinted();

        return numPayable 
            * (numMintedAlready < tier0_supply ? 
                tier0_price 
                : ( (numMintedAlready < (tier0_supply+tier1_supply)) ? tier1_price : tier2_price));
    }

    function setPricing(uint256[] calldata pricingData) external onlyOwner {
        tier0_supply = pricingData[0];
        tier0_price = pricingData[1];

        tier1_supply = pricingData[2];
        tier1_price = pricingData[3];

        tier2_price = pricingData[4];

        require(tier0_supply + tier1_supply <= MAX_TOKEN_SUPPLY);
    }

    function setPublicMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setMaxMints(uint256 _maxMintsPublic, uint256 _maxMintsWhitelist) external onlyOwner {
        maxMintsPerPersonPublic = _maxMintsPublic;
        maxMintsPerPersonWhitelist = _maxMintsWhitelist;
    }

    function setContractGhost(address newAddress) external onlyOwner {
        contractGhost = CryptoDeddies(newAddress);
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    // props to @cygaar_dev
    error SteveAokiNotAllowed();
    address public constant STEVE_AOKI_ADDRESS = 0xe4bBCbFf51e61D0D95FcC5016609aC8354B177C4;

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        if (to == STEVE_AOKI_ADDRESS) { // sorry Mr. Aoki
            revert SteveAokiNotAllowed();
        }

        if (from == address(0) || to == address(0))  // bypass for minting and burning
            return;

        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {
            //require(hp[tokenId] > 0, "No more HP"); // soulbound?

            // transfers reduces HP
            _takeDamageHP(tokenId, from);
        }
    }

    function _takeDamageHP(uint256 tokenId, address mintGhostTo) private verifyTokenId(tokenId){
        if (hp[tokenId] == 0) // to make sure it doesn't wrap around
            return;

        hp[tokenId] -= 1;

        if (hp[tokenId] == 0) {
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(mintGhostTo, tokenId, seeds[tokenId]);
            }
        }
    }

    function rewardHP(uint256 tokenId, uint hpRewarded) external onlyOwner verifyTokenId(tokenId) {
        require(hp[tokenId] > 0, "Already dead");
        hp[tokenId] += hpRewarded;

        if (hp[tokenId] > MAX_HP) 
            hp[tokenId] = MAX_HP;
    }

    function rewardManyHP(uint256[] calldata tokenIds, uint hpRewarded) external {
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];

            if (hp[tokenId] > 0 ) { // not dead
                hp[tokenId] += hpRewarded;

                if (hp[tokenId] > MAX_HP) 
                    hp[tokenId] = MAX_HP;
            }
        }
    }

    /// @notice Retrieves the HP
    /// @param tokenId The token ID for the CryptoEddie
    /// @return hp the amount of HP for the CryptoEddie
    function getHP(uint256 tokenId) external view verifyTokenId(tokenId) returns(uint){
        return hp[tokenId];
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    ///////////////////////////
    // -- MERKLE NERD STUFF --
    ///////////////////////////
    bytes32 public merkleRoot = 0x0;

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) private view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) external view returns (bool) {
        return _verifyMerkle(_proof, _leaf);
    }

    function verifyMerkleAddress(bytes32[] calldata _proof, address from) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return _verifyMerkle(_proof, leaf);
    }

    function mintEddiesMerkle(bytes32[] calldata _merkleProof, uint256 numEddiesToMint) external payable {
        require(mintStatus == MintStatus.WHITELIST || mintStatus == MintStatus.PUBLIC, "Merkle mint closed");
        
        uint256 numMintedAlready = _numberMinted(msg.sender);
        require(numMintedAlready + numEddiesToMint <= maxMintsPerPersonPublic, "Exceeds max mints");

        // calculate how much you need to pay beyond whitelisted amount
        uint256 numToMintFromWhitelist = 0;
        if (numMintedAlready < maxMintsPerPersonWhitelist) {
            numToMintFromWhitelist = (maxMintsPerPersonWhitelist - numMintedAlready);
        }

        // num to actually buy
        uint256 numToMintPayable = numEddiesToMint - numToMintFromWhitelist;
        require(msg.value >= _getPrice(numToMintPayable), "Incorrect ether sent" );
    
        // verify merkle        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verifyMerkle(_merkleProof, leaf), "Invalid proof");

        _mintEddies(msg.sender, numEddiesToMint);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        string[6] memory lookup = [  '0', '1', '2', '3', '4', '5'];
        uint256 seed = seeds[tokenId];
        string memory image = _getSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental NFT character project with unique functionality, inspired by retro Japanese RPGs.",',
                    '"attributes":[',
                        _getTraitsMetadata(seed),
                        _getStatsMetadata(seed),
                        '{"trait_type":"HP", "value":',lookup[hp[tokenId]],', "max_value":',lookup[MAX_HP],'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = _getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental character art project, chillin on the Ethereum blockchain.",',
                    '"attributes":[{"trait_type":"Unrevealed", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (revealed) 
            return _tokenURI(tokenId);
        else
            return _tokenUnrevealedURI(tokenId);
    }

    function _randStat(uint256 seed, uint256 div, uint256 min, uint256 max) private pure returns (uint256) {
        return min + (seed/div) % (max-min);
    }

    function _getStatsMetadata(uint256 seed) private pure returns (string memory) {
        string[11] memory lookup = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ];

        string memory metadata = string(abi.encodePacked(
          '{"trait_type":"Determination", "display_type": "number", "value":', lookup[_randStat(seed, 2, 2, 10)], '},',
          '{"trait_type":"Love", "display_type": "number", "value":', lookup[_randStat(seed, 3, 2, 10)], '},',
          '{"trait_type":"Cringe", "display_type": "number", "value":', lookup[_randStat(seed, 4, 2, 10)], '},',
          '{"trait_type":"Bonk", "display_type": "number", "value":', lookup[_randStat(seed, 5, 2, 10)], '},',
          '{"trait_type":"Magic Defense", "display_type": "number", "value":', lookup[_randStat(seed, 6, 2, 10)], '},'
        ));

        return metadata;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'base64-sol/base64.sol';

import "./EddieData.sol";

contract EddieRenderer is EddieData {

  string[] public bgPaletteColors = [
    'b5eaea', 'b5c7ea', 'eab6b5', 'c3eab5', 'eab5d9',
    'fafc51', '3a89ff', '5eff8f', 'ff6efa', 'a1a1a1'
  ];
  
  struct CharacterData {
    uint background;

    uint body;
    uint head;
    uint eyes;
    uint mouth;
    uint hair;
  }

  function getSVG(uint256 seed) external view returns (string memory) {
    return _getSVG(seed);
  }

  function _getSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      _renderRects(heads[data.head], fullPalettes),
      _renderRects(bodies[data.body], fullPalettes),
      _renderRects(hair[data.hair], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getGhostSVG(uint256 seed) external view returns (string memory) {
    return _getGhostSVG(seed);
  }

  function _getGhostSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#3b89ff"/>',
      //_renderRects(bodies[data.body], fullPalettes),
      //_renderRects(heads[data.head], fullPalettes),
      _renderRects(misc[0], fullPalettes), // ghost body
      _renderRects(hair[data.hair], fullPalettes),
      _renderRects(mouths[data.mouth], fullPalettes),
      _renderRects(eyes[data.eyes], fullPalettes),
      '</svg>'
    ));

    return image;
  }

  function getUnrevealedSVG(uint256 seed) external view returns (string memory) {
    return _getUnrevealedSVG(seed);
  }

  function _getUnrevealedSVG(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string memory image = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges" width="768" height="768">'
      '<rect width="100%" height="100%" fill="#', bgPaletteColors[data.background], '"/>',
      _renderRects(misc[1], fullPalettes), // ghost body
      '</svg>'
    ));

    return image;
  }

  function getTraitsMetadata(uint256 seed) external view returns (string memory) {
    return _getTraitsMetadata(seed);
  }

  function _getTraitsMetadata(uint256 seed) internal view returns (string memory) {
    CharacterData memory data = _generateCharacterData(seed);

    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory metadata = string(abi.encodePacked(
      '{"trait_type":"Background", "value":"', lookup[data.background+1], '"},',
      '{"trait_type":"Outfit", "value":"', bodies_traits[data.body], '"},',
      '{"trait_type":"Class", "value":"', heads_traits[data.head], '"},',
      '{"trait_type":"Eyes", "value":"', eyes_traits[data.eyes], '"},',
      '{"trait_type":"Mouth", "value":"', mouths_traits[data.mouth], '"},',
      '{"trait_type":"Head", "value":"', hair_traits[data.hair], '"},'
    ));

    return metadata;
  }

  function _renderRects(bytes memory data, string[] memory palette) private pure returns (string memory) {
    string[24] memory lookup = [
      '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', '11', '12', '13', '14', '15',
      '16', '17', '18', '19', '20', '21', '22', '23'
    ];

    string memory rects;
    uint256 drawIndex = 0;

    for (uint256 i = 0; i < data.length; i = i+2) {
      uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (24px)
      uint8 colorIndex = uint8(data[i+1]);

      if (colorIndex != 0) { // transparent
        uint8 x = uint8(drawIndex % 24);
        uint8 y = uint8(drawIndex / 24);
        string memory color = palette[colorIndex];

        rects = string(abi.encodePacked(rects, '<rect width="', lookup[runLength], '" height="1" x="', lookup[x], '" y="', lookup[y], '" fill="#', color, '"/>'));
      }
      drawIndex += runLength;
    }

    return rects;
  }

  function _generateCharacterData(uint256 seed) private view returns (CharacterData memory) {
    return CharacterData({
      background: seed % bgPaletteColors.length,
      
      body: bodies_indices[(seed/2) % bodies_indices.length],
      head: heads_indices[(seed/3) % heads_indices.length],
      eyes: eyes_indices[(seed/4) % eyes_indices.length],
      mouth: mouths_indices[(seed/5) % mouths_indices.length],
      hair: hair_indices[(seed/6) % hair_indices.length]
    });
  }
}

// SPDX-License-Identifier: MIT

/*
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000  CRYPTO EDDIE GHOST 0000000000000000000000000000000000000
000000000000000000000000000000000000000000    by @eddietree    0000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK000000000000000000000000000
00000000000000000000000000000000KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK000000000000000000000000000
00000000000000000000000000000KXXKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0XXKK00000000000000000000000
0000000000000000000000000000KNWMK;                                     .kMMWX00000000000000000000000
000000000000000000000000KKKKKOOOxc''''''''''''''''''''''''''''''''''''';dOOO0KKKK0000000000000000000
000000000000000000000000XWWW0,  .xNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNO,  .dWWWX0000000000000000000
000000000000000000000KKKK000x;..,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc..'o000KKKKK000000000000000
00000000000000000000XWWWk'..,kXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXX0c...oNWWXK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWMMMMWWWWWWWWWWWK:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMWKkxxxxxxxxxxxxxxxxKWMWKkxxxxxxxxxxdc,,;xNMMNK00000000000000
00000000000000000000XWMWx.  .OMMMMMMMMMWWOlccccccccccccccclkNWW0lcccccccccccccclkNMMNK00000000000000
0000000000000000KNNXkc::'   .lkkkkkkkkkkxdlccokO0xl;..';cccoxkxdlccok00x;..';cclkNMMNK00000000000000
0000000000000000NWMWo       .;cccccccccccccccxXWM0o'   ,cccccccccccdXWM0,   ,cclkNMMNK00000000000000
000000000000KXXXxlclloolollodkOOOOOOOOOOOdlccxXWM0o'   ,ccldkOOxlccdXWM0,   ,cclkNMMNK00000000000000
00000000000KNWMNc   cNMMMMMMMMMMMMMMMMMMWOlccxXWM0o'   ,cclONWW0lccdXWM0,   ,cclkNMMNK00000000000000
00000000000KNMMNc   cNMMMMMMMMMMMMMMMMMMWOlccokOOxl;..';cclONMW0lccokOOx;..';cccloookKXXK00000000000
00000000000KNMMNc   cNMMMMMMMMMMMMMMMMMMW0lccccccccccccccclONWW0lccccccccccccccc'   ;XMMNK0000000000
00000000000KXNNXd:;:ldxxxxxxONMMMMMMMMMMWKkxxo;,,;coxxxxxxkKWMWXkxxxxxxxxxxxxxxx;   ;XMMNK0000000000
000000000000000KXWWNo.      'OMMMMMMMMMMMMWWWx.  .cOWWWWWWWWMMMMWWWWWWWWWWWWWWWNl   ;XMMNK0000000000
0000000000000000XNNNx;,,,,,,:dkkOXMMMMMMMMMMM0:,,:ldkkkO000O000Okkk0WMMMMMMMMMMNl   ;XMMNK0000000000
00000000000000000000XNNNNNNNO'  .kWMMMMMMMMMMWWNNOo,  .',,,,;,,'.  ;KMMMMMMMMMMNl   ;XMMNK0000000000
00000000000000000000XNWWWWWW0:..,d000XMMMMMMMMMMMKxc..'',,,,,,,''..cKMMMMMMWX00Ol'..lKWWNK0000000000
0000000000000000000000KKK0K0KXXX0:. .dWMMMMMMMMMMWWNXX0l,,,,,,,l0XXNWMMMMMMXc...lKNXXK0K000000000000
0000000000000000000000000KKKKKKKO:...l0KKKKKKKKKKKKKKKOc'''''''cOKKKKKKKKKKOc...oNWWXK00000000000000
000000000000000000000000KNWW0;..'dKK0l.................         ...........'oKKKKKKK0000000000000000
00000000000000000000000KKXXXk,..'kWMNo..       ... .. .............      . .xWWWX0000000000000000000
00000000000000000000XNWNk;..;x00KNMMWX00000000000000000000000000000o.  .o0000KKKK0000000000000000000
00000000000000000000XNNNx.  '0MMMWNNWWMMMMMMMMMMMMMMMMMMMMMMMMMWWNNk.  .kMMWX00000000000000000000000
0000000000000000XNNNx;,,cxkk0NMMXo,,;kWMMMMMMMMMMMMMMMMMMMMMMMWO:,,.   .kMMWX00000000000000000000000
000000000000000KNWMWo   ;KMMMMMMK;   oNWWMMMMMMMMMMMMMMMMMMMMMWd.      .kWWWX00000000000000000000000
0000000KXNNNNNNNWMMWo   ,KMMMMMMW0xddl:;:xNMMMMMMMMMMMMMMMMMMMWd.  .lxddc;;ckXNNK0000000000000000000
0000000KWMMMMMMMMMMWo   ;KMMMMMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0,  .dWMWX0000000000000000000
000KXNN0occccccl0WMWKdoolcccdXMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0'  .dWMWX0000000000000000000
000XWMMO.       oWMMMMMMx.  .OMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0,  .dWMWX0000000000000000000
XXXOollllllllllllllllllllllllllllllllllllkWMMMMMMMMMMMMMMMMMMMWd.  .:lllllloOXXXK0000000000000000000
MMWx.  '0MMMMMMNc       ;KMMO'       oWMMMMMMMMMMMMMMMMMMMMMMMWd.      .kMMWX00000000000000000000000
NNNOl::coddxXMMWkc::::::dNMMXo::::::cOWMMMMMMMMMMMMMMMMMMMMMMMWd.  .,::l0NNXK00000000000000000000000
000XWWWO.  .kWMMMWWMMWMMMMMMMWWWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.  ,0WWNK000000000000000000000000000
000KNNN0c,,:oxxkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkkxo;,;lKNNXK000000000000000000000000000
0000000KNWW0;  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.  :KWWNK0000000000000000000000000000000
0000000KWMMK,   oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   :XMMNK0000000000000000000000000000000
*/
// thx CB1 for the name

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";

contract CryptoDeddies is ERC721A, Ownable {
    struct GhostData {
        uint256 eddieTokenId;
        uint256 eddieTokenSeed;
    }

    EddieRenderer public contractRenderer;

    mapping(uint256 => GhostData) public ghostData; // tokenid => ghost data
    error EddieGhostIsSoulbound();
    event EddieGhostSpawned(uint256 indexed tokenId, uint256 indexed eddieTokenId, uint256 indexed eddieTokenSeed); // emitted when an HP goes to zero

    constructor(address _contractRenderer) ERC721A("CryptoDeddies", "DEDDIE") {
        contractRenderer = EddieRenderer(_contractRenderer);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    function spawnGhost(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) external {
        require(msg.sender == address(contractRenderer), "Only callable from contract");
        _mintGhost(to, eddieTokenId, eddieTokenSeed);
    }

    function spawnGhostAdmin(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) external onlyOwner {
        _mintGhost(to, eddieTokenId, eddieTokenSeed);
    }

    function _mintGhost(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) private {
        _safeMint(to, 1);

        // save ghost data
        uint256 tokenId = _totalMinted();
        ghostData[tokenId] = GhostData({
            eddieTokenId: eddieTokenId,
            eddieTokenSeed: eddieTokenSeed
        });

        emit EddieGhostSpawned(tokenId, eddieTokenId, eddieTokenSeed);
    }

    // block transfers (soulbound)
    function _beforeTokenTransfers(address from, address, uint256, uint256) internal pure override {
        //if (from != address(0) && to != address(0)) {
        if (from != address(0)) { // not burnable
            revert EddieGhostIsSoulbound();
        }
    }

    function setContractRenderer(address newAddress) external onlyOwner {
        contractRenderer = EddieRenderer(newAddress);
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        GhostData memory ghost = ghostData[tokenId];
        uint256 eddieTokenId = ghost.eddieTokenId;
        uint256 seed = ghost.eddieTokenSeed;

        string memory image = contractRenderer.getGhostSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoDeddie Ghost #', Strings.toString(eddieTokenId),'",',
                    '"description": "CryptoDeddie Ghost is a memorialized ghost of your original CryptoEddie, forever soulbound to your wallet.",',
                    '"attributes":[',
                        contractRenderer.getTraitsMetadata(seed),
                        '{"trait_type":"Dead", "value":"True"}, {"trait_type":"Soulbound", "value":"True"}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED FILE by @eddietree on Thu Aug 18 2022 01:31:47 GMT-0700 (Pacific Daylight Time)

pragma solidity ^0.8.0;

contract EddieData {
	string[] public fullPalettes = ['ff00ff', '000000', 'ffffff', 'ff0000', '00ff00', '0000ff', '65656e', '212124', '343438', '212123', 'f83a00', 'fff200', 'ff5900', '0096ff', '2e07f2', '1f1f21', '858ac7', 'e31e27', '7e00de', 'f200ff', '292929', 'f5368f', 'ffff00', 'ff8282', '599cff', 'b2e1f8', 'ff9696', 'ff4747', '919191', 'b8b8b8', 'ff5e00', 'ff995e', 'ff3300', 'd32027', 'f3e106', 'd46a6d', '172f3b', '163545', 'f73b3b', '2c7899', '3fabd9', '2e81a5', '2f82a6', '44b0de', '237843', '47a66b', 'f3f700', 'ba6047', 'a85740', '592f23', '44c3c9', 'ede068', 'ffed4f', '68b84d', '599e42', '038604', '9c9083', '7a7166', '696158', '7ddcff', '00bbff', '009bd4', '5ed4ff', 'edda9d', 'eda200', '004f24', '00c458', '00a44b', '00ad4e', 'ff9500', 'f7ff0f', 'eaf041', 'cfd60d', 'faf5aa', 'ced439', 'b5b535', 'ffa3a3', 'a37b46', '966930', '579aff', '217aff', '4eff00', 'fffc00', 'ffff26', '007dfc', '0067cf', 'fcca97', '8a633c', 'cb8d52', 'fcf0c6', '180d1f', 'a16010', 'e5a925', '3a3a3a', '2057a8', 'b82323', 'ff3030', '3c3c3c', '0004fa', '2b2b2b', 'ff0009', '3150d6', '7c541a', 'ba2b00', 'bfb731', '505050', '729144', '9aa6c1', '3f3556', 'd246e8', 'e74dff', '00974c', '9ec45c', '20d47a', 'eded61', '78573e', 'b89174', '2b478f', '0024ff', '363b3c', '202324', '3587ab', '0044ff', '0145fd', 'b4633b', 'b5643b', '40b2e6', '83c6e5', '115c52', 'ffcc99', '64c0e8', '3a8228', 'fcd502', '165c58', 'f7c328', '8a1212', '008787', '2c3aa8', '8a3c3c', 'e8fd4d', '439958', '5e83ec', '00a800', '006600', '404040', 'c5b2a0', 'fd8c69', 'f7e83e', 'f75a3e', 'fccf03', '68d4cc', 'be8ade', 'b778de', '568746', '67ab50', 'fce2a9', '6edbb7', 'fcb39d', '79dbba', 'c74832', '40cfbc', '7dd8ff', 'dbf4ff', '9ce1ff', 'fbdd97', 'f9de9a', 'f9de9b', 'fade9a', 'f9df9b', 'fadf9b', 'fade9b', 'f8dfa0', 'f8e0a0', 'f7e0a0', 'f5e1a6', 'f4e2a6', 'f5e2a6', 'f4e2a7', 'f5e2a7', 'f2e4ad', 'f3e4ad', 'f2e3ad', 'efe6b5', 'efe5b4', 'f0e5b5', 'efe6b4', 'efe5b5', 'ece8bc', 'ece9bd', 'ece8bd', 'ece9bc', 'e9ebc5', 'e8ebc5', 'e9eac5', 'e9ebc4', 'e6edcd', 'e5eecd', 'e5eece', 'e6eecd', 'e5edcd', 'e5edce', 'e2f0d5', 'e2efd6', 'e2f0d6', 'e2efd5', 'dff2de', 'dcf4e5', 'dcf4e4', 'dcf5e5', 'dbf4e5', 'dcf5e4', 'd9f7ec', 'd9f6ec', 'd7f9f2', 'd7f8f2', 'd6f8f2', 'd4f9f7', 'd4faf7', 'd3fbfb', 'b7c6e8', 'e5edff', 'fae848', 'fae248'];

	///////////////////////////////////////
	// eyes
	bytes[] public eyes = [
		bytes(hex'840003061700020616000206040001020d000106090701020a00040604070108040701020a0004060307010801070108030701020d0001060907010217000102'),
		bytes(hex'c400010201090100010113000102010903020200040a03000101090001020101010201090302010a010b020a0100020101020b000102010901020200030a0300010101020b0003021700010117000101'),
		bytes(hex'e300020e0300020e0d00040e0202030e0202010e0f00010e0202010e0100010e0202010e1000020e0300020e'),
		bytes(hex'd300010101020d00040201000402010101020a0004020205030202030102010101020d000102020501020100010202030102010101020d000402010004020101'),
		bytes(hex'e200040d0100040d0c00040d01020101030d01020101010d0f00010d01020101010d0100010d01020101010d0f00040d0100040d'),
		bytes(hex'e200040c0100040c0c00040c01020101030c01020101010c0f00010c01020101010c0100010c01020101010c0f00040c0100040c'),
		bytes(hex'e30001010400010113000101020001011300010104000101'),
		bytes(hex'df000b011000030102000102010111000301'),
		bytes(hex'df00050f0210020f0210010f0f00010f0210020f0210010f11000110020f01000110020f'),
		bytes(hex'df0003110212021302120213100001120213021202130112110001130212010001130212'),
		bytes(hex'e2000101010001010200010101000101110001010400010111000101010001010200010101000101'),
		bytes(hex'e200040101000301100001020201020001020201'),
		bytes(hex'e30001010400010111000101010001010200010101000101'),
		bytes(hex'e200030102000301110001020101020001020101'),
		bytes(hex'9c00070110000101060201010f0001010802010101020d00010102020101030201010102010101020a000401040201030302010101020d00010102020101030201010102010101020d00010103020301020201010f0001010602010111000601'),
		bytes(hex'9c00070110000101060201010f0001010802010101020d00010101020117010101170102011701010117010101020a00040102020118030201180102010101020d0001010202011801010102010101180102010101020d000101020201180102010101020118010201010f0001010102011803020118010111000601'),
		bytes(hex'9b000801010001020d0001010816010101020c00010108160101010001020c0001010216010103160101011601010e000101081601010e0001010216010103160101011601010e00010103160301021601010f000101081610000801'),
		bytes(hex'e200031402000314100001140115011402000114011501141000031402000314'),
		bytes(hex'e2000302020003021000020201010200010102021000030202000302'),
		bytes(hex'e200030202000302100001020101010202000102010101021000030202000302'),
		bytes(hex'e300030101000301110001020101020001020101120001020101020001020101'),
		bytes(hex'cc0001160300011613000b0301030a0001160103010203160102061601160c000b0301030c00011603000116'),
		bytes(hex'e200030102000301110001020101020001020101120001020101020001020101'),
		bytes(hex'cc000101030001011100020105000101110001020101030001010102110001020101030001010102'),
		bytes(hex'b2000319140005191300011903010119030001010f00011901010103010101190100020101020f000119030101190200010101020f0005191200041914000219'),
		bytes(hex'e200030102000301110001020101020001020101120001010102020001010102'),
		bytes(hex'e3000301010003011100011a0101011a0100011a0101011a1100031a0100031a'),
		bytes(hex'e2000301020003011100010201010200010201011200020202000202'),
		bytes(hex'e900010110000401010002010102110001020101030001010102'),
		bytes(hex'e200020117000102020101000301110001020101030001010102'),
		bytes(hex'e200020105000101110001020201010002010102110001020101030001010102'),
		bytes(hex'e200030102000301290001010102030001010102')
	];

	string[] public eyes_traits = [
		'Virtual Reality',
		'Scouter',
		'Glasses',
		'3D Glasses',
		'Big Blue Glasses',
		'Big Red Glasses',
		'Shut',
		'Pirate',
		'Future Too Bright',
		'Stunners',
		'RIP',
		'Smug',
		'Overjoyed',
		'Sus',
		'Good Face',
		'Sad Face',
		'Happy Note',
		'Corrupted',
		'Dizzy',
		'Low Key Shook',
		'Optimistic',
		'Maximalist',
		'Watchful',
		'Worried',
		'Terminatooor',
		'Senpai',
		'Stoney Baloney',
		'Skyward',
		'Raised Left',
		'Raise Right',
		'U Mad Bro',
		'Naughty'
	];

	uint8[] public eyes_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];

	///////////////////////////////////////
	// mouths
	bytes[] public mouths = [
		bytes(hex'ff004400010118000301'),
		bytes(hex'ff004500010101000101010001011400010101000101'),
		bytes(hex'ff00450001010300010114000301'),
		bytes(hex'ff004400010118000101021b010115000203'),
		bytes(hex'ff001000010117000c010d0001010a1c0e000101021c011d031c011d021c0f000101071c11000101021c011d021c13000101031c15000101011c010116000101'),
		bytes(hex'ff001000010117000c010d0001010a030e0001010203021e0103021e02030f0001010703110001010103021e0203130001010303150001010103010116000101'),
		bytes(hex'2d000102300001022e0001021700010248000102170001022f00010229000101011f0202012015000201'),
		bytes(hex'ff005c000201'),
		bytes(hex'ff004300010f0600010f1100060f'),
		bytes(hex'ff005c0002010102010101020201'),
		bytes(hex'ff00460003011500010101000101'),
		bytes(hex'ff00460003011400010103000101'),
		bytes(hex'ff005e000301'),
		bytes(hex'ff005c000601')
	];

	string[] public mouths_traits = [
		'Smirk',
		'Uwu',
		'Smile',
		'Silly',
		'Grey Bandana',
		'Red Bandana',
		'Smoking',
		'Hmmm',
		'Big Honkin Smile',
		'Buck',
		'Micro Sad',
		'Sad',
		'Blah',
		'Unsatisfied'
	];

	uint8[] public mouths_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13];

	///////////////////////////////////////
	// hair
	bytes[] public hair = [
		bytes(hex'200009020e000102090101020c000102010103240625010101020a000102010102240925010101020500050201010124062502000225010101020500010205010124052504000125010101020500010201010424062504260125010106000202030114000302'),
		bytes(hex'200009020e000102090101020c00010201010921010101020a0001020101042101220121012201210122022101010102090001020101042105220221010101020a0001010b210101010001020900010101210b23020101020b000c230101010214000201010216000102'),
		bytes(hex'200009020e000102090103020a00010201010129022a022b07010102080001020101022a022b0201072a01010102070001020101012a022b0101092a0101010208000101012a012b01010a2a0101010208000101012a01010a2a01010102'),
		bytes(hex'200009020e000102090101020c000102010103270628010101020a000102010102270928010101020500050201010127062802000228010101020500010205010127052804000128010101020500010201010427062804260128010106000202030114000302'),
		bytes(hex'200009020e000102090101020c0001020101032c062d010101020a0001020101022c092d01010102050005020101012c062d0201022d01010102050001020501012c052d0401012d01010102050001020101042c062d042e012d010106000202030114000302'),
		bytes(hex'0b00010201010202130001020101012f02010102110001020101012f0130022f010101020f0001020101033102300131010101020d0001020101012f0630012f010101020b0001020101012f01300731010101020b000102010101310730022f010101020c000a31'),
		bytes(hex'200009020e00020204010102030101020c0002020101043501010335010101020b0001020101013501360137010201010236010201010135010101020a0001020101013509360101010209000102010101350a3601010102090001020101013502360300023603000101010209000102010102360900010101020b0002360900010101020b0002360900010101020b0002360900010101020c000136'),
		bytes(hex'3a00050211000202050102020e00010202010532020101020c00010201010932010101020a000102010101330a34010101020b0001330a34'),
		bytes(hex'2800010216000102010101020e00070201010102010101020c00010207010202010101020b00010201010a02010101020900010201010b020101010209000102010103020300020203000101010209000102010102020900010101020b0002020900010101020b0002020900010101020b0002020900010101020c000102'),
		bytes(hex'2100020201000202010002020f0001020201010202010102020102020c000102010102380101023801010238020101020a000102010102380139013802390138013903380101010209000102010101380a390138010108000102010101380c39010108000102010103390300023903000201010208000102010102390900010101020b0002390900010101020b0002390900010101020b0002390900010101020c000139'),
		bytes(hex'090007020e00030204010102020102020b0001020301043b0101023b02010102090001020101043b033c013b023c023b01010102070001020101023b0b3c01010102060001020101023b043c023d013c023d013c013d013c013b01010102050001020101013b033c0a3d023c01010102040001020101013b013c013d013c033d0600023d013c01010102040001020101013b013c033d0900013d013c01010102040002020101023c023d0900023d01010102040001020101023c033d0900013d01010102050001020101023c033d0900013d01010102060001020101013c0200013d130001020101013d17000101013d160001020101'),
		bytes(hex'090007020f000202070102020c00010202010738020101020a000102010103380139013802390138013902380101010208000102010102380a3901380101010206000102010102380439013a0339013a0339010101020600010201010539073a03390101010204000102010102380239023a0700023a01390101010204000102010101380239023a0900023a0101010204000102010101380139013a0139013a0900023a01010102040001020101013a0139033a0900013a0101010206000102010101390100023a0b00010206000102010101390200013a130001020101013a160001020101013a160001020101'),
		bytes(hex'200009020e000102090101020c00010201010938010101020a0001020101023809390101010209000102010101380a39010101020900010201010b3901010102090001020101033908000101010209000102010102390900010101020b0002390900010101020b0002390900010101020b0002390900010101020c000139'),
		bytes(hex'390008020e000202080101020c0001020201083e010101020a0001020101023e093c01010102080001020101023e0a3c01010102080001020101013e073c0100033c01010102080001020101043c080001010102080001020101033c0900010101020b00023c0900010101020b00023c0900010101020c00013c2b0001020101013c150001020101023c14000202'),
		bytes(hex'2800010216000102010101020e0007020101013f010101020c0001020701013f0140010101020b00010201010a40010101020900010201010b400101010209000102010103400300024003000101010209000102010102400900010101020b0002400900010101020b0002400900010101020b0002400900010101020c000140'),
		bytes(hex'2800010216000102010101020e00070201010138010101020c000102070101380139010101020b00010201010a39010101020900010201010b390101010209000102010103390300023903000101010209000102010102390900010101020b0002390900010101020b0002390900010101020b0002390900010101020c000139'),
		bytes(hex'2100010205000102100001020101010203000102010101020e00010201010103010101020100010201010103010101020d00010201010203010101000101020301010102'),
		bytes(hex'0a0001020141010215000202014103021100010206410102100001410342014101430142014101020e00014104440142014101440142014101020e00014107440141100003410344024113000341'),
		bytes(hex'0b00010203010102110002020101014501010145010101020f00010204010145030101020d00010201010846010101020b00010201010346010201010146010201010246010102020800010201010b460301010209000346014709450101010209000246014702000745010101020a000246014715000146014716000146014716000247170001471700014717000148'),
		bytes(hex'080001020201010203000102010101020d000102010102490101030201010149010101020c00010201010149014602010102010101490146010101020c000102010103460101010001010246010101020e0001010246010102000146020001020d000249064601490e0001490246074a01460d0001490146014a0700014a0d000146014a16000146014a16000146014a16000146014a1700014a'),
		bytes(hex'2100010205000102100001020101010203000102010101020e00010201010102010101020100010201010102010101020d00010201010202010101000101020201010102'),
		bytes(hex'08000b020c00020203010302030102020b000102010103020101010201010302010101020b00010201010102014c01020101010001010102014c0102010101020b00010201000102014c0102010102000102014c0102010101020c000a02010101020b00020216000102170001021700010217000102'),
		bytes(hex'05000402020003020200040209000102020104020101040202010102090001020101014b0101020201010116010102020101011601010102090001020101014b0116020103160201021601010102090001020101024b091601010102090001020101024b011601030216010302160103011601010102090001020101034b081601010b000101'),
		bytes(hex'ff00'),
		bytes(hex'090004021300020203010302100001020101034d0301010211000201014e034d010101020d000102020101000101044e014d010101020b0001020101094e014d010101020900010201010b4e01010102090001020101034e0300024e030001010102090001020101024e0900010101020b00024e0900010101020b00024e0900010101020b00024e0900010101020c00014e'),
		bytes(hex'1d0003021400010203010102120001020101034f0101120001020101014f025003011000010202010b500b00010202000b500a000102020003501500025016000250160002501600025017000150'),
		bytes(hex'1d000302140001020301010212000102010103530101120001020101035303011000010202010b530b00010202000b530a000102020003531500025316000253160002531600025317000153'),
		bytes(hex'800001510152015101520151015203510e0003510152015101520151015203510d0003511500025116000251160002511600025117000151'),
		bytes(hex'63000254170002541700015401550b5401550800025402550b54015507000254'),
		bytes(hex'6300025a1700025a17000e5a0800105a0700025a')
	];

	string[] public hair_traits = [
		'Black Hat',
		'Bear Market Hat',
		'Cap Front',
		'Topo Hat',
		'Chill Green Hat',
		'Poop',
		'Froggy',
		'Eric',
		'Old But Still Cool',
		'Straight Bussin',
		'Clowin',
		'Success Perm',
		'Poppin',
		'Neetori',
		'Blonde',
		'Cool Guy',
		'Devil Horns',
		'Leaf',
		'Ducky',
		'Pipichu',
		'Catbot',
		'Easter',
		'King',
		'Bald',
		'90s',
		'3000',
		'Sun Bun',
		'Too Cool',
		'Blue Bandana',
		'Black Bandana'
	];

	uint8[] public hair_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,23,24,25,26,27,28,29];

	///////////////////////////////////////
	// bodies
	bytes[] public bodies = [
		bytes(hex'ff006e000102010101561400010201010356010112000102010104560157015804560101010209000102010103560159015701580659010101020800010201010256025901570158035901580259010101020800010201010256015901570158075901010102080001020101025601590157015802590158045901010102080001020101025601590157015805590158015901010102080001020101025601590157015801590158055901010102'),
		bytes(hex'ff006e0001020101015b140001020101035b01011200010201010a5b01010102090001020101065b065c01010102080001020101025b025c045b045c01010102080001020101035b055c045b01010102080001020101045b085c01010102080001020101025b015c035b065c01010102080001020101025b035c035b045c01010102'),
		bytes(hex'ff006e0001020101015f140001020101035f01011200010201010a5f01010102090001020101035f096001010102080001020101025f0a6001010102080001020101025f0a6001010102080001020101025f0a6001010102080001020101025f0a6001010102080001020101025f0a6001010102'),
		bytes(hex'ff006d0001020101025d140001020201025d0101120002020101045d0101015d0101025d0c0001020101025d0101025d0101015d0101015d0d0001020101015d02000101055d120006011200065e1200015e0400015e1200015e0400015e'),
		bytes(hex'ff00eb000561120006612a00010304000103'),
		bytes(hex'ff00eb00050214000302'),
		bytes(hex'ff008800010101631600046301010100010102630e00026301000363010102630f0001630300016301010363130005641200066312000163040001631200016304000163'),
		bytes(hex'ff00890001651600046501010100010102650e00026501000365010102650f000165030001650101036513000366010301661200066512000165040001651200016504000165'),
		bytes(hex'ff00b800010316000303070001030e0002030100050201000103100006621200016204000162'),
		bytes(hex'ff008900016f1600096f0e00026f0100026f0370016f0f00016f02710100016f017001720170016f010001710e0002710100016f0370016f010001711000066f1200016f0400016f1200016f0400016f'),
		bytes(hex'ff008900016a1600046a0101016b0101026a0e00026a0100026a0101016c0101016a0f00016a0300016a0101016b0101016a13000268010102681200066912000169040001691200016904000169'),
		bytes(hex'ff00890001021600040201010167010102020e000202010002020101010a010101020f000102030001020101010a0101010213000268010102681200066912000169040001691200016904000169'),
		bytes(hex'ff00890001021600040201010100010102020e00020201000302010102020f00010203000502130005681200060212000102040001021200010204000102'),
		bytes(hex'ff00eb00056d1300046e'),
		bytes(hex'ff00ff00030006761200017604000176'),
		bytes(hex'ff00890001731600027301740173017401730174017301740e00027301000173017401730174017301740f000173030001730174017301740173130005731200067512000175040001751200017504000175'),
		bytes(hex'ff0089000177160009770e000277010006770f00017703000577130005781200067912000179040001791200017904000179'),
		bytes(hex'ff008900017e1600017e017f017e017f018001000180017f017e0e0002810100017f017e017f0180017f017e0f0001810300017f017e017f017e017f1300017e017f017e017f017e1200017e017f017e017f017e017f1200017e0400017e'),
		bytes(hex'ff008900017a1600097a0e00017b017a0100067a0f00017a0300057a1300057a1200017c047d017c1200017c0400017c'),
		bytes(hex'ff0089000182160009820e0002820100028201160182011601820f000182030001820316018213000582120006161200011604000116'),
		bytes(hex'ff00a3000583120003830184028313000183018401830184018313000583120006851200018504000185'),
		bytes(hex'ff00a300010203000102120006021300050213000502120006881200018804000188'),
		bytes(hex'ff0089000189160009890e00028901000389020101890f0001890300018902010289130005891200068a1200018a0400018a'),
		bytes(hex'ff0089000186160009860e00028601000286012b0186012b01860f00018603000286012b0286130005861200068712000187040001871200018704000187'),
		bytes(hex'ff008900018b1600098b0e00028b0100038b018c028b0f00018b0300018b038c018b1300058b1200068d1200018d0400018d1200018d0400018d'),
		bytes(hex'ff00a300019001000190010001901200019001000190010001901400019001000190010001901400019001000190140001900100019001000190'),
		bytes(hex'ff00ed00018e1600038e1500018e018f018e')
	];

	string[] public bodies_traits = [
		'Burrito',
		'Monk',
		'Comfy',
		'Hoodie',
		'Astro',
		'Underwear',
		'Ninja',
		'Jiu Jitsu Gi Blue',
		'Boxer',
		'Andy',
		'Myles',
		'Business Time',
		'Freddie',
		'Hot Speedo',
		'Swimmer',
		'Argyle',
		'Steve',
		'Romphim',
		'Meme Frog',
		'Go Bruins',
		'Staying Fit',
		'LA Summer',
		'Bicyclist',
		'Funktronic',
		'Ganja Shirt From College',
		'Net',
		'Leaf'
	];

	uint8[] public bodies_indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26];

	///////////////////////////////////////
	// heads
	bytes[] public heads = [
		bytes(hex'500009020e000102090101020c00010201010991010101020a00010201010b910101010209000102010103910881010101020900010201010291098101010102090001020101029109810101010208000102020102910981010101020700010201010281029109810101010207000102010103810191058101920481010101020700010202010c81010101020800020201010b81010101020a00010201010981010101020a00010201010181090101020a00010201010981010101020a00010201010281010102810192018101920181020101020a000102010103810101058101010181010101020a000102010102810101058101010181010101020b00010202010681020101020d0001020101018104010181010101020e00010201010181010102020101018101010102'),
		bytes(hex'500009020e000102090101020c00010201010993010101020a00010201010b930101010209000102010103930894010101020900010201010293099401010102090001020101029309940101010208000102020102930994010101020700010201010294029309940101010207000102010103940193059401950494010101020700010202010c94010101020800020201010b94010101020a00010201010994010101020a00010201010194090101020a00010201010994010101020a00010201010294010102940195019401950194020101020a000102010103940101059401010194010101020a000102010102940101059401010194010101020b00010202010694020101020d0001020101019404010194010101020e00010201010194010102020101019401010102'),
		bytes(hex'500009020e000102090101020c00010201010999010101020a00010201010b99010101020900010201010399089a010101020900010201010299099a010101020900010201010299099a010101020800010202010299099a01010102070001020101029a0299099a01010102070001020101039a0199059a0192049a010101020700010202010c9a010101020800020201010b9a010101020a0001020101099a010101020a00010201010136090101020a0001020101099a010101020a0001020101029a01010136059a020101020a0001020101039a01010136049a0101019a010101020a0001020101029a01010136049a0101019a010101020b0001020201069a020101020d0001020101019a0401019a010101020e0001020101019a010102020101019a01010102'),
		bytes(hex'500009020e000102090101020c0001020101099b010101020a00010201010b9b01010102090001020101039b089c01010102090001020101029b099c01010102090001020101029b099c01010102080001020201029b099c01010102070001020101029c029b099c01010102070001020101039c019b059c019d049c010101020700010202010c9c010101020800020201010b9c010101020a0001020101099c010101020a0001020101019e090101020a0001020101099e010101020a0001020101029e0101029e019f019e019f019e020101020a0001020101039e0101059e010101a0010101020a0001020101029e0101059e010101a0010101020b0001020201069e020101020d0001020101019e0401019e010101020e0001020101019e010102020101019e01010102'),
		bytes(hex'500009020e000102090101020c00010201010996010101020a00010201010b960101010209000102010103960897010101020900010201010296099701010102090001020101029609970101010208000102020102960997010101020700010201010297029609970101010207000102010103970196059701920497010101020700010202010c97010101020800020201010b97010101020a00010201010997010101020a00010201010198090101020a00010201010998010101020a00010201010298010102980192019801920198020101020a000102010103980101059801010198010101020a000102010102980101059801010198010101020b00010202010698020101020d0001020101019804010198010101020e00010201010198010102020101019801010102'),
		bytes(hex'500009020e000102090101020c00010201010902010101020a00010201010b02010101020900010201010b02010101020900010201010b02010101020900010201010b02010101020800010202010b02010101020700010201010d0201010102070001020101090201920402010101020700010202010c02010101020800020201010b02010101020a00010201010902010101020a00010201010102090101020a00010201010902010101020a00010201010202010102020192010201920102020101020a000102010103020101050201010102010101020a000102010102020101050201010102010101020b00010202010602020101020d0001020101010204010102010101020e00010201010102010102020101010201010102'),
		bytes(hex'500009020e000102090101020c000102010109a1010101020a00010201010ba10101010209000102010103a108a20101010209000102010102a109a20101010209000102010102a109a20101010209000102010102a109a20101010209000102010102a109a20101010209000102010102a105a2019204a20101010208000102010102a10aa20101010209000102010101a10aa2010101020a000102010109a2010101020a000102010101a3090101020a000102010108a201a3010101020a000102010102a2010101a305a2020101020a000102010103a2010101a304a2010101a2010101020a000102010102a2010101a304a2010101a2010101020b000102020106a2020101020d000102010101a2040101a2010101020e000102010101a201010202010101a201010102'),
		bytes(hex'500009020e000102090101020c000102010109a4010101020a00010201010ba40101010209000102010101a505a601a701a801a901a601aa0101010209000102010101ab01ac01ad01ac01ad01ac01ad01ac03ad0101010209000102010101ae01af01b001b102b001b201ae01b001ae01b00101010208000102020102b301b402b301b401b501b401b501b301b40101010207000102010101b601b701b601b801b901b701ba02b604b90101010207000102010101bb01bc01bd01be01bd02bb03bd01bb01be01bc01bd0101010207000102020102bf01c001c101c202c002bf01c001bf01c00101010208000202010101c301c401c501c401c601c402c702c801c3010101020a000102010101c901ca01c902cb01cc01cb01c901cb010101020a000102010101cd090101020a000102010101ce01cf02ce02d001d101d001d2010101020a000102010101d301d4010102d404d3020101020a000102010101d501d601d7010102d601d702d5010101d6010101020a000102010101d801d9010101d804d9010101d9010101020b000102020106da020101020d000102010101da040101da010101020e000102010101da01010202010101da01010102'),
		bytes(hex'500009020e000102090101020c000102010109dd010101020a000102010102dd070202dd0101010209000102010101dd010209dd0101010209000102010101dd010209dd0101010209000102010101dd010209dd010101020800010202010bdd0101010207000102010102020bdd0101010207000102010103dd010205dd019203dd0102010101020700010202010cdd010101020800020201010bdd010101020a000102010109dd010101020a000102010101de090101020a000102010101dd010207dd010101020a000102010101dd0102010102dd019f01dd019f01dd020101020a000102010102dd0102010105dd01010102010101020a000102010102dd010101dd020202dd010101dd010101020b000102020106dd020101020d000102010101dd040101dd010101020e000102010101dd01010202010101dd01010102')
	];

	string[] public heads_traits = [
		'Human',
		'Tengu',
		'Meme Frog',
		'Orc',
		'Night Elf',
		'Spoopy',
		'AI Bot',
		'Prismatic',
		'Golden Boy'
	];

	uint8[] public heads_indices = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,5,6,6,7,8];

	///////////////////////////////////////
	// misc
	bytes[] public misc = [
		bytes(hex'500009020e000102090101020c000102010109db010101020a000102010103db08dc0101010209000102010102db09dc0101010209000102010102db09dc0101010209000102010102db09dc0101010208000102020102db09dc0101010207000102010104db09dc0101010207000102010103db03dc029203dc029201dc010101020700010202010cdc010101020800020201010bdc010101020a000102010109dc010101020a000102010101db090101020a000102010104db05dc010101020a000102010102db010106dc0201010208000302010101db02dc010105dc010101dc010101020600010202010202010102dc010105dc010101dc0101010205000102010102db020101db020106dc0201010207000102010104db08dc0101010209000102010103db07dc01010102'),
		bytes(hex'500009020e000102090101020c0001020b0101020a0001020d0101020900010205010302050101020900010204010502040101020900010203010202030102020301010208000102040102020301020203010102070001020a010202030101020700010209010202050101020700010207010202060101020800020205010202060101020a0001020b0101020a00010205010202040101020a00010206010202030101020a0001020c0101020a0001020d0101020a0001020c0101020b0001020a0101020d000102080101020e0001020301020203010102')
	];

	string[] public misc_traits = [
		'Ghost',
		'Mystery'
	];
}

// SPDX-License-Identifier: MIT

/*
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  CRYPTO EDDIES  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   by @eddietree  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  (LET TRY THIS AGAIN SHALL WE?) XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'....................................:0WWWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNo.                                    ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWWNd'..;looooooooooooooooooooooooooooooooooooc,..;OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNWNl   ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.  .kWNNNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNd,',:llldkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxollc;'';OWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ,kOOOOOOOOOOO0000000KKKKKKKKKKKKKKKKK00000000Kx.  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOOOOOOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOOO000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKOl;;ckKKKKKKKKKKKKKKKKkc;;lOXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMN:   ;kOOOOOO0KKKKKKKk'  .oKKKKKKKKKKKKKKKXo.  .xXXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNNNXxllc.   ;kOOOOOO0KKKKKKK0occc::::cxKKKKKKKkc:::cccoOKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWMMX;       ;kOOOOOO0KKKKKKKKKKXO,    cKKKKKKKl   'OXXXKKKk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXNNNKxoolc:::::::okOOOOOO0KKKKKKK0occc:::::xKKKKKKKxc:::cccoOKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKK0OOOOOOO0KKKKKKXk'  .oKKKKKKKKKKKKKKXKo.  .xKXk'  .xMMMNXXXXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKK000OOOO0KKKKKKKOl;;:kKKKKKKKKK0000KKKkc;;lOKKOl;;:lddd0NNNXXXXXXXXXXXXX
XXXXXXXXXXXNWMM0'  .oKKKKKKKKKKK0OOO0KKKKKKKKKKKKKKKKKKKKK0kkkOKKKKKKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXNWWKo;;:coooooookKKKK0000KKKKKKKKKKK0xooookKKKxc::d0KKOdood0KKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXNWWMX;       :0KKKKKKKKKKKKKKKKKXO,    cKKKc   ;0KXo.  .xKKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXo,,,,,,,coodkKKKKKKKKKKKKKKK0c''',codo:''':oddc,'':kXKKKKXO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNl   ;0KKKKKKKKKKKKKKKKKKKO;   :0K0l.  ,kKKKKKKKKKKO,   oWMMNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWWWWWNx,'':dddkKKKKKKKKKKKKKKKX0l..'oKKKd'..:OXKKKKK0kddo:'',xWWWNXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNd.  ,OXKKKKKKKKKKKKKKKK000KKKKK0000KKKKKKKk,  .dNNNNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXNXK000o'..;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo;..,kWWWNXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNWMWo...;k0Ol.                                    'xXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXKK0l...c0KKd'............................     ...,OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNWWNl...:kOO0KKX0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.  .xKKXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXX0c...cKKK0OOO0KKKKKKKKKKKKKKKKKKKKKKKKK0OOOl.  '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXNWWXc..'cxkk0KKKo...:OKKKKKKKOkkO0KKKK0kkO0KKKo'...   '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   lKKKKKKKl.  ,x000KKKKOkkk0KKKKOkkk0KKKl       ,ONNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;   cKKKKKKK0xxxl'..;kXKKK000KKKKKK000KKKKl   .oxxo,'.:OWWWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXWMMX;  .c000KKKKKKKKo.  .xKKKKKKKKKKKKKKKKKKKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXNNX0kkkc'''oKKKKKKKo.  .xKK0dlloxkkkkkkkk0KKKl   'kXXx.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXWMMNc   :0KKKKKKo.  .xKKOl:::oxxxxxxxxOKKKl   'kKKd.  .kMMWNXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXNNNX0xxxc,,,,,,,;loox0KKOl:::oxxxxxxxxOKKKl    ',,:oxxkKNNNXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNMMWl       'kXKKKKKOl;::oxxxxxxxxOKKKl       '0MMWNXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXNNNN0ddd;   'OXXkc,,;;:::oxxxxxxxxOKKKl   .lddkKNNNXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OXXd.   ':::oxxxxxxxxOKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKXx.  .lOOO0KKK0o,,,oKKKl   ,KMMWNXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNMMMd   'OKKd.  .kMMMMMMMNc   :0XKl   ,KMMWXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXNWWWx'..:OXXk;..;OWWWWWWWNo...lKKKd'..cKWWNXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
*/
// special thanks to 0xmetazen and troph for reviewing the code

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";
import "./CryptoDeddiesV2.sol";
import "./CryptoEddies.sol"; // OG

/// @title CryptoEddies V2
/// @author @eddietree
/// @notice CryptoEddies is an 100% on-chain experimental NFT character project.
contract CryptoEddiesV2 is ERC721A, Ownable {
    
    uint256 public constant MAX_TOKEN_SUPPLY = 3500;
    uint public constant MAX_HP = 5;

    // contracts
    CryptoDeddiesV2 public contractGhost;
    CryptoEddies public contractEddieOG;
    address public contractHpEffector;

    bool public revealed = true;
    bool public rerollingEnabled = true;
    bool public claimEnabled = true;
    bool public burnSacrificeEnabled = false;

    mapping(uint256 => uint256) public ogTokenId; // tokenId=>ogTokenId (From original contract)
    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public hp; // health power

    // events
    event EddieDied(uint256 indexed tokenId); // emitted when an HP goes to zero
    event EddieRerolled(uint256 indexed tokenId); // emitted when an Eddie gets re-rolled
    event EddieSacrificed(uint256 indexed tokenId); // emitted when an Eddie gets sacrificed

    constructor(address _contractEddieOG) ERC721A("CryptoEddiesV2", "EDDIEV2") {
        contractEddieOG = CryptoEddies(_contractEddieOG);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "Not approved nor owner"
        );
        
        _;
    }

    function claimMany(uint256[] calldata tokenIds) external {
        require(claimEnabled == true);

        // clamp the total minted
        //require(_totalMinted() + tokenIds.length <= MAX_TOKEN_SUPPLY );

        uint256 num = tokenIds.length;
        uint256 startTokenId = _startTokenId() + _totalMinted();
        address sender = msg.sender;

        for (uint256 i = 0; i < num; ++i) {
            uint256 originalTokenId = tokenIds[i];
            uint256 newTokenId = startTokenId + i;

            //require(sender == contractEddieOG.ownerOf(originalTokenId)); // check ownership
            //require(ogTokenId[newTokenId] == 0); // check not already claimed

            // transfer each token to this contract and then call the burn function
            // since the 'burnSacrifice' call can only be called on the owner,
            // we had to first transfer to this contract before excuting burnSacrifice
            contractEddieOG.transferFrom(sender, address(this), originalTokenId);
            contractEddieOG.burnSacrifice(originalTokenId);

            // save data on new token
            ogTokenId[newTokenId] = originalTokenId;
            hp[newTokenId] = MAX_HP;
            _saveSeed(newTokenId); // reshuffle
            //seeds[newTokenId] = contractEddieOG.seeds(originalTokenId); // copy seed over
        }

        //_safeMint(sender, num);
        _mint(sender, num);
    }

    function _rerollEddie(uint256 tokenId) verifyTokenId(tokenId) private {
        require(revealed == true, "Not revealed");
        require(hp[tokenId] > 0, "No HP");
        require(msg.sender == ownerOf(tokenId), "Not yours");

        _saveSeed(tokenId);   
        _takeDamageHP(tokenId, msg.sender);

        emit EddieRerolled(tokenId);
    }

    /// @notice Rerolls the visuals and stats of one CryptoEddie, deals -1 HP damage!
    /// @param tokenId The token ID for the CryptoEddie to reroll
    function rerollEddie(uint256 tokenId) external {
        require(rerollingEnabled == true);
        _rerollEddie(tokenId);
    }

    /// @notice Rerolls the visuals and stats of many CryptoEddies, deals -1 HP damage!
    /// @param tokenIds An array of token IDs
    function rerollEddieMany(uint256[] calldata tokenIds) external {
        require(rerollingEnabled == true);
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _rerollEddie(tokenId);
        }
    }

    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    /// @notice Destroys your CryptoEddie, spawning a ghost
    /// @param tokenId The token ID for the CryptoEddie
    function burnSacrifice(uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        //require(msg.sender == ownerOf(tokenId), "Not yours");
        require(burnSacrificeEnabled == true);

        address ownerOfEddie = ownerOf(tokenId);

        _burn(tokenId);

        // if not already dead, force kill and spawn ghost
        if (hp[tokenId] > 0) {
            hp[tokenId] = 0;
        
             // cancel vibing
            _resetAndCancelVibing(tokenId);

            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(ownerOfEddie, tokenId, seeds[tokenId]);
            }
        }

        emit EddieSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    // taken from 'ERC721AQueryable.sol'
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function setContractEddieOG(address newAddress) external onlyOwner {
        contractEddieOG = CryptoEddies(newAddress);
    }

    function setContractGhost(address newAddress) external onlyOwner {
        contractGhost = CryptoDeddiesV2(newAddress);
    }

    function setClaimEnabled(bool _enabled) external onlyOwner {
        claimEnabled = _enabled;
    }

    function setContractHpEffector(address newAddress) external onlyOwner {
        contractHpEffector = newAddress;
    }

    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setRerollingEnabled(bool _enabled) external onlyOwner {
        rerollingEnabled = _enabled;
    }

    function setBurnSacrificeEnabled(bool _enabled) external onlyOwner {
        burnSacrificeEnabled = _enabled;
    }

    // props to @cygaar_dev
    //error SteveAokiNotAllowed();
    //address public constant STEVE_AOKI_ADDRESS = 0xe4bBCbFf51e61D0D95FcC5016609aC8354B177C4;

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        // removed to optimize gas, u are now re-admitted into the club, Mr. Aoki
        /*if (to == STEVE_AOKI_ADDRESS) { // sorry Mr. Aoki
            revert SteveAokiNotAllowed();
        }*/

        if (from == address(0) || to == address(0))  // bypass for minting and burning
            return;

        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {
            //require(hp[tokenId] > 0, "No more HP"); // soulbound?

            // transfers reduces HP
            _takeDamageHP(tokenId, from);
        }
    }

    function _takeDamageHP(uint256 tokenId, address mintGhostTo) private verifyTokenId(tokenId){
        if (hp[tokenId] == 0) // to make sure it doesn't wrap around
            return;

        hp[tokenId] -= 1;

        // taking damage resets your vibing
        _resetAndCancelVibing(tokenId);

        if (hp[tokenId] == 0) {
            emit EddieDied(tokenId);

            if (address(contractGhost) != address(0)) {
                contractGhost.spawnGhost(mintGhostTo, tokenId, seeds[tokenId]);
            }
        }
    }

    function rewardManyHP(uint256[] calldata tokenIds, int hpRewarded) external /*onlyOwner*/ {
        // only admin or another authorized smart contract can change HP
        // perhaps a hook for future content? ;)
        require(owner() == _msgSender() || (contractHpEffector != address(0) && _msgSender() == contractHpEffector), "Not authorized");

        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];

            if (hp[tokenId] > 0 ) { // not dead

                int newHp = int256(hp[tokenId]) + hpRewarded;

                // clamping between [0,MAX_HP]
                if (newHp > int(MAX_HP)) 
                    newHp = int(MAX_HP);
                
                else if (newHp <= 0) {
                    newHp = 0;

                    // spawn ghost
                    emit EddieDied(tokenId);
                    if (address(contractGhost) != address(0)) {
                        contractGhost.spawnGhost(ownerOf(tokenId), tokenId, seeds[tokenId]);
                    }
                }

                hp[tokenId] = uint256(newHp);

                // taking damage resets your vibing
                if (hpRewarded < 0) {
                     _resetAndCancelVibing(tokenId);
                }
            }
        }
    }

    /// @notice Retrieves the HP
    /// @param tokenId The token ID for the CryptoEddie
    /// @return hp the amount of HP for the CryptoEddie
    function getHP(uint256 tokenId) external view verifyTokenId(tokenId) returns(uint){
        return hp[tokenId];
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        string[6] memory lookup = [  '0', '1', '2', '3', '4', '5'];
        uint256 seed = seeds[tokenId];
        string memory image = contractEddieOG.getSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental NFT character project with unique functionality, inspired by retro Japanese RPGs. Formerly known as CryptoEddie #', Strings.toString(ogTokenId[tokenId]),'.",',
                    '"attributes":[',
                        contractEddieOG.getTraitsMetadata(seed),
                        _getStatsMetadata(seed),
                        '{"trait_type":"Vibing?", "value":', (vibingStartTimestamp[tokenId] != NULL_VIBING) ? '"Yes"' : '"Nah"', '},',
                        //'{"trait_type":"OG TokenID", "value":', Strings.toString(ogTokenId[tokenId]), '},',
                        '{"trait_type":"HP", "value":',lookup[hp[tokenId]],', "max_value":',lookup[MAX_HP],'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = contractEddieOG.getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoEddie #', Strings.toString(tokenId),'",',
                    '"description": "CryptoEddies is an 100% on-chain experimental character art project, chillin on the Ethereum blockchain.",',
                    '"attributes":[{"trait_type":"Unrevealed", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (revealed) 
            return _tokenURI(tokenId);
        else
            return _tokenUnrevealedURI(tokenId);
    }

    function _randStat(uint256 seed, uint256 div, uint256 min, uint256 max) private pure returns (uint256) {
        return min + (seed/div) % (max-min);
    }

    function _getStatsMetadata(uint256 seed) private pure returns (string memory) {
        string[11] memory lookup = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ];

        string memory metadata = string(abi.encodePacked(
          '{"trait_type":"Determination", "display_type": "number", "value":', lookup[_randStat(seed, 2, 2, 10)], '},',
          '{"trait_type":"Love", "display_type": "number", "value":', lookup[_randStat(seed, 3, 2, 10)], '},',
          '{"trait_type":"Cringe", "display_type": "number", "value":', lookup[_randStat(seed, 4, 2, 10)], '},',
          '{"trait_type":"Bonk", "display_type": "number", "value":', lookup[_randStat(seed, 5, 2, 10)], '},',
          '{"trait_type":"Magic Defense", "display_type": "number", "value":', lookup[_randStat(seed, 6, 2, 10)], '},'
        ));

        return metadata;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    ///////////////////////////
    // -- VIBING --
    ///////////////////////////

    bool public isVibingEnabled = false;

    // vibing
    mapping(uint256 => uint256) private vibingStartTimestamp; // tokenId -> vibing start time (0 = not vibing).
    mapping(uint256 => uint256) private vibingTotalTime; // tokenId -> cumulative vibing time, does not include current time if vibing
    
    uint256 private constant NULL_VIBING = 0;
    event EventStartVibing(uint256 indexed tokenId);
    event EventEndVibing(uint256 indexed tokenId);
    event EventForceEndVibing(uint256 indexed tokenId);

    // currentVibingTime: current vibing time in secs (0 = not vibing)
    // totalVibingTime: total time of vibing (in secs)
    function getVibingInfoForToken(uint256 tokenId) external view returns (uint256 currentVibingTime, uint256 totalVibingTime)
    {
        currentVibingTime = 0;
        uint256 startTimestamp = vibingStartTimestamp[tokenId];

        // is vibing?
        if (startTimestamp != NULL_VIBING) { 
            currentVibingTime = block.timestamp - startTimestamp;
        }

        totalVibingTime = currentVibingTime + vibingTotalTime[tokenId];
    }

    function setVibingEnabled(bool allowed) external onlyOwner {
        require(allowed != isVibingEnabled);
        isVibingEnabled = allowed;
    }

    function _toggleVibing(uint256 tokenId) private onlyApprovedOrOwner(tokenId)
    {
        require(hp[tokenId] > 0);

        uint256 startTimestamp = vibingStartTimestamp[tokenId];

        if (startTimestamp == NULL_VIBING) { 
            // start vibing
            require(isVibingEnabled, "Disabled");
            vibingStartTimestamp[tokenId] = block.timestamp;

            emit EventStartVibing(tokenId);
        } else { 
            // start unvibing
            vibingTotalTime[tokenId] += block.timestamp - startTimestamp;
            vibingStartTimestamp[tokenId] = NULL_VIBING;

            emit EventEndVibing(tokenId);
        }
    }

    function toggleVibing(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _toggleVibing(tokenId);
        }
    }

    function _resetAndCancelVibing(uint256 tokenId) private {
        if (vibingStartTimestamp[tokenId] != NULL_VIBING) {
            vibingStartTimestamp[tokenId] = NULL_VIBING;
            emit EventEndVibing(tokenId);
        }

        // clear total time
        if (vibingTotalTime[tokenId] != NULL_VIBING)    
            vibingTotalTime[tokenId] = NULL_VIBING;
    }

    function _adminForceStopVibing(uint256 tokenId) private {
        require(vibingStartTimestamp[tokenId] != NULL_VIBING, "Character not vibing");
        
        // accum current time
        uint256 deltaTime = block.timestamp - vibingStartTimestamp[tokenId];
        vibingTotalTime[tokenId] += deltaTime;

        // no longer vibing
        vibingStartTimestamp[tokenId] = NULL_VIBING;

        emit EventEndVibing(tokenId);
        emit EventForceEndVibing(tokenId);
    }

    function adminForceStopVibing(uint256[] calldata tokenIds) external onlyOwner {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _adminForceStopVibing(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

/*
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000  CRYPTO EDDIE GHOST 0000000000000000000000000000000000000
000000000000000000000000000000000000000000    by @eddietree    0000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK000000000000000000000000000
00000000000000000000000000000000KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK000000000000000000000000000
00000000000000000000000000000KXXKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0XXKK00000000000000000000000
0000000000000000000000000000KNWMK;                                     .kMMWX00000000000000000000000
000000000000000000000000KKKKKOOOxc''''''''''''''''''''''''''''''''''''';dOOO0KKKK0000000000000000000
000000000000000000000000XWWW0,  .xNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNO,  .dWWWX0000000000000000000
000000000000000000000KKKK000x;..,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc..'o000KKKKK000000000000000
00000000000000000000XWWWk'..,kXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXX0c...oNWWXK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWMMMMWWWWWWWWWWWK:   lNMMNK00000000000000
00000000000000000000XWMMx.  .OMMMMMMMMMMWKkxxxxxxxxxxxxxxxxKWMWKkxxxxxxxxxxdc,,;xNMMNK00000000000000
00000000000000000000XWMWx.  .OMMMMMMMMMWWOlccccccccccccccclkNWW0lcccccccccccccclkNMMNK00000000000000
0000000000000000KNNXkc::'   .lkkkkkkkkkkxdlccokO0xl;..';cccoxkxdlccok00x;..';cclkNMMNK00000000000000
0000000000000000NWMWo       .;cccccccccccccccxXWM0o'   ,cccccccccccdXWM0,   ,cclkNMMNK00000000000000
000000000000KXXXxlclloolollodkOOOOOOOOOOOdlccxXWM0o'   ,ccldkOOxlccdXWM0,   ,cclkNMMNK00000000000000
00000000000KNWMNc   cNMMMMMMMMMMMMMMMMMMWOlccxXWM0o'   ,cclONWW0lccdXWM0,   ,cclkNMMNK00000000000000
00000000000KNMMNc   cNMMMMMMMMMMMMMMMMMMWOlccokOOxl;..';cclONMW0lccokOOx;..';cccloookKXXK00000000000
00000000000KNMMNc   cNMMMMMMMMMMMMMMMMMMW0lccccccccccccccclONWW0lccccccccccccccc'   ;XMMNK0000000000
00000000000KXNNXd:;:ldxxxxxxONMMMMMMMMMMWKkxxo;,,;coxxxxxxkKWMWXkxxxxxxxxxxxxxxx;   ;XMMNK0000000000
000000000000000KXWWNo.      'OMMMMMMMMMMMMWWWx.  .cOWWWWWWWWMMMMWWWWWWWWWWWWWWWNl   ;XMMNK0000000000
0000000000000000XNNNx;,,,,,,:dkkOXMMMMMMMMMMM0:,,:ldkkkO000O000Okkk0WMMMMMMMMMMNl   ;XMMNK0000000000
00000000000000000000XNNNNNNNO'  .kWMMMMMMMMMMWWNNOo,  .',,,,;,,'.  ;KMMMMMMMMMMNl   ;XMMNK0000000000
00000000000000000000XNWWWWWW0:..,d000XMMMMMMMMMMMKxc..'',,,,,,,''..cKMMMMMMWX00Ol'..lKWWNK0000000000
0000000000000000000000KKK0K0KXXX0:. .dWMMMMMMMMMMWWNXX0l,,,,,,,l0XXNWMMMMMMXc...lKNXXK0K000000000000
0000000000000000000000000KKKKKKKO:...l0KKKKKKKKKKKKKKKOc'''''''cOKKKKKKKKKKOc...oNWWXK00000000000000
000000000000000000000000KNWW0;..'dKK0l.................         ...........'oKKKKKKK0000000000000000
00000000000000000000000KKXXXk,..'kWMNo..       ... .. .............      . .xWWWX0000000000000000000
00000000000000000000XNWNk;..;x00KNMMWX00000000000000000000000000000o.  .o0000KKKK0000000000000000000
00000000000000000000XNNNx.  '0MMMWNNWWMMMMMMMMMMMMMMMMMMMMMMMMMWWNNk.  .kMMWX00000000000000000000000
0000000000000000XNNNx;,,cxkk0NMMXo,,;kWMMMMMMMMMMMMMMMMMMMMMMMWO:,,.   .kMMWX00000000000000000000000
000000000000000KNWMWo   ;KMMMMMMK;   oNWWMMMMMMMMMMMMMMMMMMMMMWd.      .kWWWX00000000000000000000000
0000000KXNNNNNNNWMMWo   ,KMMMMMMW0xddl:;:xNMMMMMMMMMMMMMMMMMMMWd.  .lxddc;;ckXNNK0000000000000000000
0000000KWMMMMMMMMMMWo   ;KMMMMMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0,  .dWMWX0000000000000000000
000KXNN0occccccl0WMWKdoolcccdXMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0'  .dWMWX0000000000000000000
000XWMMO.       oWMMMMMMx.  .OMMMMMMNc   :XMMMMMMMMMMMMMMMMMMMWd.  ,0MM0,  .dWMWX0000000000000000000
XXXOollllllllllllllllllllllllllllllllllllkWMMMMMMMMMMMMMMMMMMMWd.  .:lllllloOXXXK0000000000000000000
MMWx.  '0MMMMMMNc       ;KMMO'       oWMMMMMMMMMMMMMMMMMMMMMMMWd.      .kMMWX00000000000000000000000
NNNOl::coddxXMMWkc::::::dNMMXo::::::cOWMMMMMMMMMMMMMMMMMMMMMMMWd.  .,::l0NNXK00000000000000000000000
000XWWWO.  .kWMMMWWMMWMMMMMMMWWWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.  ,0WWNK000000000000000000000000000
000KNNN0c,,:oxxkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkkxo;,;lKNNXK000000000000000000000000000
0000000KNWW0;  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.  :KWWNK0000000000000000000000000000000
0000000KWMMK,   oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   :XMMNK0000000000000000000000000000000
*/
// thx CB1 for the name

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./EddieRenderer.sol";
import "./CryptoEddiesV2.sol";

contract CryptoDeddiesV2 is ERC721A, Ownable {
    struct GhostData {
        uint256 eddieTokenId;
        uint256 eddieTokenSeed;
    }

    EddieRenderer public contractRenderer;
    CryptoEddiesV2 public contractEddiesV2;

    mapping(uint256 => GhostData) public ghostData; // tokenid => ghost data
    error EddieGhostIsSoulbound();
    event EddieGhostSpawned(uint256 indexed tokenId, uint256 indexed eddieTokenId, uint256 indexed eddieTokenSeed); // emitted when an HP goes to zero

    constructor(address _contractRenderer) ERC721A("CryptoDeddiesV2", "DEDDIEV2") {
        contractRenderer = EddieRenderer(_contractRenderer);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Out of bounds");
        _;
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    function spawnGhost(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) external {
        require(msg.sender == address(contractEddiesV2), "Only callable from contract");
        _mintGhost(to, eddieTokenId, eddieTokenSeed);
    }

    function spawnGhostAdmin(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) external onlyOwner {
        _mintGhost(to, eddieTokenId, eddieTokenSeed);
    }

    function _mintGhost(address to, uint256 eddieTokenId, uint256 eddieTokenSeed) private {
        _safeMint(to, 1);

        // save ghost data
        uint256 tokenId = _totalMinted();
        ghostData[tokenId] = GhostData({
            eddieTokenId: eddieTokenId,
            eddieTokenSeed: eddieTokenSeed
        });

        emit EddieGhostSpawned(tokenId, eddieTokenId, eddieTokenSeed);
    }

    // block transfers (soulbound)
    function _beforeTokenTransfers(address from, address, uint256, uint256) internal pure override {
        //if (from != address(0) && to != address(0)) {
        if (from != address(0)) { // not burnable
            revert EddieGhostIsSoulbound();
        }
    }

    function setContractRenderer(address newAddress) external onlyOwner {
        contractRenderer = EddieRenderer(newAddress);
    }

    function setContractEddieV2(address newAddress) external onlyOwner {
        contractEddiesV2 = CryptoEddiesV2(newAddress);
    }


    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        GhostData memory ghost = ghostData[tokenId];
        uint256 eddieTokenId = ghost.eddieTokenId;
        uint256 seed = ghost.eddieTokenSeed;

        string memory image = contractRenderer.getGhostSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"CryptoDeddie Ghost #', Strings.toString(eddieTokenId),'",',
                    '"description": "CryptoDeddie Ghost is a memorialized ghost of your original CryptoEddie, forever soulbound to your wallet.",',
                    '"attributes":[',
                        contractRenderer.getTraitsMetadata(seed),
                        '{"trait_type":"Dead", "value":"True"}, {"trait_type":"Soulbound", "value":"True"}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}