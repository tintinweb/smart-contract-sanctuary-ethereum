// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {Backgrounds} from "./backgrounds.sol";
import {utils} from "../src/utils.sol";
import {png} from "../src/png.sol";
import {wav} from "../src/wav.sol";

contract retroWAVs is ERC721, ERC2981, Owned(msg.sender) {

    constructor() ERC721("retroWAVs", "WAV") {
        _setDefaultRoyalty(msg.sender, uint96(690));
    }

    struct GAMEDATA{
         
        bytes32 startHash;
        // startHash is assigned at mint time, from it we derive:
        // slot[0] - player
        // slot[1-3] - player colour
        // slot[4-6] - background colour
        // slot[7-9] - ground colour
        // slot[10] - WAV track
        // ALL slots used to define pillar heights

        bool saveGame;
        uint64 lastMove;
    }

    GAMEDATA[] private gameData;
    uint256 nextId;

    uint256 constant saveCost = 0.0025 ether;

    string[] private playerNames = [
        "italian man",
        "monke",
        "ghoul",
        "turtle",
        "pepe",
        "node runner",
        "lambo",
        "pengu",
        "npc",
        "ghoul ball"
    ];

    function tokenURI(uint256 id) public view override returns (string memory) {

        string memory img;

        bytes32 idHash = getHash(id);

        img = string.concat(
            Backgrounds.groundblocks(),
            Backgrounds.basicBlocks(idHash),
            Backgrounds.jumpingPNG(getPlayerPNG(id), idHash)
        );

        string memory encodedImg = string.concat('data:image/svg+xml;base64,', utils.encode(bytes(Backgrounds.SVGheader(id, getScore(id), img, Backgrounds.skybackground()))));

        string memory encodedAudio = getTunes();

        return utils.formattedMetadata(
            'retroWAVs',
            'retroWAVs test',
            encodedImg,
            encodedAudio
        );

    }

    function getScore(uint256 id) public view returns (uint256) {
        return (block.timestamp-uint256(gameData[id].lastMove))/86400;
    }

    function getSaveStatus(uint256 id) public view returns (bool) {
        return gameData[id].saveGame;
    }

    function getHash(uint256 id) public view returns (bytes32) {
        return gameData[id].startHash;
    }

    function getPlayerIndex(uint256 id) public view returns (uint256) {
        return uint8(gameData[id].startHash[0])%10;
    }

    function getPlayerName(uint256 id) public view returns (string memory) {
        return playerNames[getPlayerIndex(id)];
    }

    function getPlayerPixels(uint256 id) public view returns (bytes memory pixels) {
        uint256 playerIdx = getPlayerIndex(id);
        
        pixels = new bytes(64);
        
        for(uint256 i = 0; i<64; i++) {
            pixels[i] = Backgrounds.playersRawPixels[playerIdx*64+i];
        }
    }

    bytes3 constant palette1 = hex'30811a';
    bytes3 constant palette2 = hex'ffa441';
    bytes3 constant palette3 = hex'ac7c01';

    function getPlayerPNG(uint256 id) public view returns (string memory) {
        unchecked{
            
            bytes memory imgData = getPlayerPixels(id);

            bytes memory pixels;

            for(uint256 i = 0; i<64; i++){
                if(i%4==0){
                    pixels = bytes.concat(pixels, hex'00', (imgData[i] >> 6), (imgData[i] << 2 >> 6), (imgData[i] << 4 >> 6), (imgData[i] << 6 >> 6));
                } else{
                    pixels = bytes.concat(pixels, (imgData[i] >> 6), (imgData[i] << 2 >> 6), (imgData[i] << 4 >> 6), (imgData[i] << 6 >> 6));
                }
            }

            bytes3[] memory _palette = new bytes3[](3);
            _palette[0] = palette1;
            _palette[1] = palette2;
            _palette[2] = palette3;

            return png.encodedPNG(uint32(16), uint32(16), _palette, pixels, false);

        }
    }

    function getTunes() public pure returns (string memory) {  

        uint256 length = 8000*5;

        bytes memory buf = new bytes(length);

        unchecked{

            for (uint24 i = 0; i<length; i++) {
                buf[i] = bytes1(uint8((i>>5)|(i<<4)|((i&1023)^1981)|uint24((int24(i)-67)>>4)));           
            }

        }

        return wav.encodeWAV(buf, uint32(8000));

    }

    function saveGame(uint256 id) public payable {
        require(!gameData[id].saveGame, "NEXT_GAME_ALREADY_SAVED");
        require(msg.value >= saveCost, "NO CREDIT");

        gameData[id].saveGame = true;

    }

    function _rand() internal view returns (bytes32) {
        return keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        nextId
                    )
                );
    }

    function _claim() internal {

        bytes32 random = _rand();

        gameData.push(GAMEDATA(random, false, uint64(block.timestamp)));
        _safeMint(msg.sender, nextId);
        nextId++;
    }

    function claim() public {
        require(nextId<9999, "MINTED OUT");
        _claim();      
    }

    function claim(uint256 claiming) public {
        require((nextId+claiming)<9999, "MINTED OUT");
        require(claiming<=10, "MAX_10_PER_CLAIM");
        for(uint256 i=0; i<claiming; i++){
            _claim();
        }
    }


    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC2981) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(ERC2981).interfaceId; // ERC165 Interface ID for ERC2981
    }

    // we override transferFrom to check if the game data should be saved or zeroed
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override (ERC721) {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        if(gameData[id].saveGame){
            gameData[id].saveGame = false;
        }
        else {
            gameData[id].lastMove = uint64(block.timestamp);
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

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
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
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
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.13;

import {utils} from './utils.sol';

library Backgrounds {
    using utils for *;
   
    bytes constant playersRawPixels = bytes(hex'005555000155554003FAAE000EEAAAA00FAAEAA003AAFFF000AAAA8000FAF0000FDA7F000FDF7FC02BD57FA02BD57FA0295555A0015455000FF03FC03FF03FF0_00000000000155400007EB90001FEAA4001FA6640007AAA900079AA915076A697F416AA47747D5507F47F7407F57F74017FFDF7400155A99006A869900554554_003FC0000AFFFC002AFFFC00AABFFF00AAA7F7C0AA95D5C0AAB7F7C0AAF7F7C02AFFFF001AB7770006BDDD0006FFF00002FFC00002FC000002F0000002F00000_00000000000000000000000000050028001540AA007AD0AE019F64AA06FAF9A806FAF9A0059F6580257AD580A6E5B980055555000A0028000A802A000AC02B00_0055540001A6A900069AAA401AAAAA901A9569545A4314316A4F14F16A9569546AA5AA906AAAAA945AAAAAA41AAAAFFF1AAAFFFF05ABFA54005AA50000155400_000000000000000000000000000000000000000000000000003FF0003CE9A800F0E9AA00F3A9AA80FFFFFFF0FFFDFFF8FD7FFD7EF69FF69F369FF69F01400140_000010000000A8000000A8000000A8000002A0000000AA00002AA8A80280A8000000FC000000FC000000FC0007FF0C0004000C0000000C0000000C0000000500_000000000015540000569500015AA54005A69A5006A69A9006A69A9016ABEA945AAAAAA55AAAAAA55AAAAAA55AAAAAA55AAAAAA515AAAA5401AAAA4000F55F00_FFF5FFFFFFDA5FFFFD6AA5FFF6AAA9FFF6AAA9FFF6AAAA7FF6A6A67FDAAA6A7FDAAA99FFF66AA9FFF66959FFFD96A7FFF6A95FFFF6AA9FFFDAAA9FFFDAAAA5FF_000000000003F000003FFF0000FFFFC003FFFAF00FFFFAFC0FFFFFFC1FFFFFFF15FFFFFF157FFFFF0557FFFC0555FFFC01555FF0005555400015550000015000');

    function SVGheader(uint256 id, uint256 score, string memory img, string memory background) internal pure returns (string memory) {
        return string.concat(
                '<svg version="1.1" viewBox="0 0 250 250" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                '<mask id="screen"><rect width="220" height="220" x="15" y="15" rx="20" fill="white" /></mask>',
                '<filter id="pixelate"><feFlood height="1" width="1"/><feComposite width="2" height="2"/><feTile result="a"/><feComposite in="SourceGraphic" in2="a" operator="in"/><feMorphology operator="dilate" radius="1"/></filter>',
                '<rect width="100%" height="100%"  fill="#47477B"/>',
                '<line x1="0" y1="0" x2="250" y2="250" stroke="black"/><line x1="250" y1="0" x2="0" y2="250" stroke="black"/>',
                '<g mask="url(#screen)">',
                background,
                '<text x="25" y="32" font-style="monospace" font-size="18" filter="url(#pixelate)">ID ',
                id.toString(),
                '</text><text x="108" y="32" font-style="monospace" font-size="18" filter="url(#pixelate)">SCORE ',
                score.toString(),
                '</text>',
                img,
                '</g></svg>'
            );
    }

    function skybackground() internal pure returns (string memory) {
        return '<rect width="100%" height="100%" fill="#77d0ee" />';
    }

    function basicBlockPile(bytes1 height, uint256 offset) private pure returns (string memory output) {
        if (height == bytes1(hex'00')) {
            return output = "";
        }
        unchecked{
            uint256 _height = uint8(height)/32;
            uint256 y = 176;
            
            output = '<g>';

            if(offset > 0){
                uint256 x = offset*6;
                for(uint256 i = 0; i<_height; i++) {
                    output = string.concat(
                        output,
                        '<use href="#basicblock" x="',
                        (226+x).toString(),
                        '" y="',
                        y.toString(),
                        '"/>'
                    );
                    y-=10;
                }

            } else{
                for(uint256 i = 0; i<_height; i++) {
                    output = string.concat(
                        output,
                        '<use href="#basicblock" x="226" y="',
                        y.toString(),
                        '"/>'
                    );
                    y-=10;
                }
            }
            if (offset >9) {
                output = string.concat(output, '<animateMotion repeatCount="indefinite" path="M0,0 -536,0" begin="',(offset/10).toString(),'.', (offset%10).toString(),'s" dur="12s" /></g>');
            } else {
                output = string.concat(output, '<animateMotion repeatCount="indefinite" path="M0,0 -536,0" begin="0.', offset.toString(),'s" dur="12s" /></g>');
            }
            
        }
    }


    function basicBlocks(bytes32 input) internal pure returns(string memory) {
        unchecked{
            string memory defs = '<defs><g id="basicblock"><rect width="10" height="10" fill="#130F01"/><polygon points="0,0 10,0 0,10" fill="#FEC79C"/><rect x="2" y="2" width="6" height="6" fill="#B1571F"/><line x1="0" y1="0" x2="10" y2="10" stroke="#B1571F" stroke-width="0.5"/><line x1="10" y1="0" x2="0" y2="10" stroke="#B1571F" stroke-width="0.5"/></g></defs>';

            string memory blockPiles;

            for(uint256 i=0; i<32; i++){
                blockPiles = string(abi.encodePacked(blockPiles, basicBlockPile(input[i], i)));
            }

            return string.concat(
                defs,
                blockPiles
            );

        }
    }

    

    function jumpPath(bytes32 input) private pure returns (string memory path) {
        path = 'M25,170 40,170  ';


        uint256 y;
        uint256 x = 45;

        for(uint256 i = 0; i<11; i++) {
            y = 138-((uint8(input[i])/32)*10);

            path = string.concat(path, x.toString(),",", y.toString(), " ");
            x +=14;
        }
        
        path = string.concat(path, '220,170 z');
    }

    function jumpingPNG(string memory encodedPNG, bytes32 input) internal pure returns(string memory animatedPNG) {
        animatedPNG = string.concat('<g><image href="', encodedPNG, '"/><animateMotion repeatCount="indefinite" path="');

        animatedPNG = string.concat(
            animatedPNG,
            jumpPath(input),
            '" keyPoints="0; 0.1; 0.15; 0.2; 0.25; 0.3; 0.4; 0.5; 0.7; 0.75; 0.8; 0.76; 0.84; 0.92; 1" keyTimes="0; 0.2;0.4; 0.5; 0.55; 0.6; 0.65; 0.7; 0.75; 0.8; 0.85; 0.9; 0.95; 0.96; 1" dur="12s" calcMode="linear" /></g>'
        );
    }

    function groundblocks() internal pure returns (string memory blocks_comp) {

        unchecked{
            blocks_comp = string.concat(
                '<filter id="blockshadow" width="1.25" height="1.25" color-interpolation-filters="sRGB"><feFlood flood-color="black" result="flood"/><feComposite in="flood" in2="SourceGraphic" operator="in" result="composite1"/><feOffset dx="1.5" dy="1.5" result="offset"/><feComposite in="SourceGraphic" in2="offset" result="composite2"/></filter>',
                '<defs><rect id="groundBlock" width="34" height="15"/></defs>',
                '<g fill="#964e00" filter="url(#blockshadow)">'
            );
            for(uint256 i = 0; i <3; i++) {
                for(uint256 j = 0; j< 7; j++) {
                    blocks_comp = string.concat(
                        blocks_comp,
                        '<use href="#groundBlock" x="',
                        ((j * (36))+(i%2*18)).toString(),
                        '" y="',
                        ((i * (17))+186).toString(),
                        '"/>'
                    );
                }
            }
            blocks_comp = string.concat(blocks_comp, '<rect width="10" height="15" x="6" y="203"/></g>');
        }

    }










}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibString.sol)
library utils {
     function formattedMetadata(
        string memory name,
        string memory description,
        string memory encodedSvgImg,
        string memory encodedAudio
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            'data:application/json;base64,',
            encode(
                bytes(
                    string.concat(
                    '{',
                    _prop('name', name),
                    _prop('description', description),
                    _prop('image', encodedSvgImg),
                    _prop('animation_url', encodedAudio, true),
                    '}'
                    )
                )
            )
        );
    }
    
    
    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) return "0"; // Otherwise it'd output an empty string for 0.

        assembly {
            let k := 78 // Start with the max length a uint256 string could be.

            // We'll store our string at the first chunk of free memory.
            str := mload(0x40)

            // The length of our string will start off at the max of 78.
            mstore(str, k)

            // Update the free memory pointer to prevent overriding our string.
            // Add 128 to the str pointer instead of 78 because we want to maintain
            // the Solidity convention of keeping the free memory pointer word aligned.
            mstore(0x40, add(str, 128))

            // We'll populate the string from right to left.
            // prettier-ignore
            for {} n {} {
                // The ASCII digit offset for '0' is 48.
                let char := add(48, mod(n, 10))

                // Write the current character into str.
                mstore(add(str, k), char)

                k := sub(k, 1)
                n := div(n, 10)
            }

            // Shift the pointer to the start of the string.
            str := add(str, k)

            // Set the length of the string to the correct value.
            mstore(str, sub(78, k))
        }
    }

    function _prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '"', _val, '", ');
    }

    function _prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if(last) {
            return string.concat('"', _key, '": ', '"', _val, '"');
        } else {
            return string.concat('"', _key, '": ', '"', _val, '", ');
        }
        
    }

    function encode(bytes memory data) internal pure returns (string memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Write the length of the string.
                mstore(result, encodedLength)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} iszero(eq(ptr, end)) {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 characters. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))

                    ptr := add(ptr, 4) // Advance 4 bytes.
                }

                // Offset `ptr` and pad with '='. We can simply write over the end.
                // The `byte(...)` part is equivalent to `[0, 2, 1][dataLength % 3]`.
                mstore(sub(ptr, byte(mod(dataLength, 3), "\x00\x02\x01")), "==")

                // Allocate the memory for the string.
                // Add 31 and mask with `not(0x1f)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(0x1f)))
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Onchain PNGs
 * @author Colin Platt <[email protected]>
 *
 * @dev PNG encoding tools written in Solidity for producing read-only onchain PNG files.
 */

pragma solidity =0.8.13;

import {utils} from "./utils.sol";

library png {
    
    struct RGBA {
        bytes1 red;
        bytes1 green;
        bytes1 blue;
    }

    function rgbToPalette(bytes1 red, bytes1 green, bytes1 blue) internal pure returns (bytes3) {
        return bytes3(abi.encodePacked(red, green, blue));
    }

    function rgbToPalette(RGBA memory _rgb) internal pure returns (bytes3) {
        return bytes3(abi.encodePacked(_rgb.red, _rgb.green, _rgb.blue));
    }

    function calculateBitDepth(uint256 _length) internal pure returns (uint256) {
        if (_length < 3) {
            return 2;
        } else if(_length < 5) {
            return 4;
        } else if(_length < 17) {
            return 16;
        } else {
            return 256;
        }
    }

    function formatPalette(bytes3[] memory _palette, bool _8bit) internal pure returns (bytes memory) {
        unchecked{
            require(_palette.length <= 256, "PNG: Palette too large.");

            uint256 depth = _8bit? uint256(256) : calculateBitDepth(_palette.length);
            bytes memory paletteObj;

            for (uint i = 0; i<_palette.length; i++) {
                paletteObj = abi.encodePacked(paletteObj, _palette[i]);
            }

            for (uint i = _palette.length; i<depth-1; i++) {
                paletteObj = abi.encodePacked(paletteObj, bytes3(0x000000));
            }

            return abi.encodePacked(
                uint32(depth*3),
                'PLTE',
                bytes3(0x000000),
                paletteObj
            );
        }
    }

    function _tRNS(uint256 _bitDepth, uint256 _palette) internal pure returns (bytes memory) {
        unchecked{
            bytes memory tRNSObj = abi.encodePacked(bytes1(0x00));

            for (uint i = 0; i<_palette; i++) {
                tRNSObj = abi.encodePacked(tRNSObj, bytes1(0xFF));
            }

            for (uint i = _palette; i<_bitDepth-1; i++) {
                tRNSObj = abi.encodePacked(tRNSObj, bytes1(0x00));
            }

            return abi.encodePacked(
                uint32(_bitDepth),
                'tRNS',
                tRNSObj
            );
        }
    }

    function rawPNG(uint32 width, uint32 height, bytes3[] memory palette, bytes memory pixels, bool force8bit) internal pure returns (bytes memory) {
        unchecked{
            uint256[256] memory crcTable = calcCrcTable();

            // Write PLTE
            bytes memory plte = formatPalette(palette, force8bit);

            // Write tRNS
            bytes memory tRNS = png._tRNS(
                force8bit ? 256 : calculateBitDepth(palette.length),
                palette.length
                );

            // Write IHDR
            bytes21 header = bytes21(abi.encodePacked(
                    uint32(13),
                    'IHDR',
                    width,
                    height,
                    bytes5(0x0803000000)
                )
            );

            bytes7 deflate = bytes7(
                abi.encodePacked(
                    bytes2(0x78DA),
                    pixels.length > 65535 ? bytes1(0x00) :  bytes1(0x01),
                    png.byte2lsb(uint16(pixels.length)),
                    ~png.byte2lsb(uint16(pixels.length))
                )
            );

            bytes memory zlib = abi.encodePacked('IDAT', deflate, pixels, _adler32(pixels));

            return abi.encodePacked(
                bytes8(0x89504E470D0A1A0A),
                header, 
                _CRC(crcTable, abi.encodePacked(header),4),
                plte, 
                _CRC(crcTable, abi.encodePacked(plte),4),
                tRNS, 
                _CRC(crcTable, abi.encodePacked(tRNS),4),
                uint32(zlib.length-4),
                zlib,
                _CRC(crcTable, abi.encodePacked(zlib), 0), 
                bytes12(0x0000000049454E44AE426082)
            );
        }

    }

    function encodedPNG(uint32 width, uint32 height, bytes3[] memory palette, bytes memory pixels, bool force8bit) internal pure returns (string memory) {
        return string.concat('data:image/png;base64,', utils.encode(rawPNG(width, height, palette, pixels, force8bit)));
    }






    // @dev Does not check out of bounds
    function coordinatesToIndex(uint256 _x, uint256 _y, uint256 _width) internal pure returns (uint256 index) {
            index = _y * (_width + 1) + _x + 1;
	}

    

    








    /////////////////////////// 
    /// Checksums

    // need to check faster ways to do this
    function calcCrcTable() internal pure returns (uint256[256] memory crcTable) {
        uint256 c;

        unchecked{
            for(uint256 n = 0; n < 256; n++) {
                c = n;
                for (uint256 k = 0; k < 8; k++) {
                    if(c & 1 == 1) {
                        c = 0xedb88320 ^ (c >>1);
                    } else {
                        c = c >> 1;
                    }
                }
                crcTable[n] = c;
            }
        }
    }

    function _CRC(uint256[256] memory crcTable, bytes memory chunk, uint256 offset) internal pure returns (bytes4) {

        uint256 len = chunk.length;

        uint32 c = uint32(0xffffffff);
        unchecked{
            for(uint256 n = offset; n < len; n++) {
                c = uint32(crcTable[(c^uint8(chunk[n])) & 0xff] ^ (c >> 8));
            }
        }
        return bytes4(c)^0xffffffff;

    }

    
    function _adler32(bytes memory _data) internal pure returns (bytes4) {
        uint32 a = 1;
        uint32 b = 0;

        uint256 _len = _data.length;

        unchecked {
            for (uint256 i = 0; i < _len; i++) {
                a = (a + uint8(_data[i])) % 65521; //may need to convert to uint32
                b = (b + a) % 65521;
            }
        }

        return bytes4((b << 16) | a);

    }

    /////////////////////////// 
    /// Utilities

    function byte2lsb(uint16 _input) internal pure returns (bytes2) {

        return byte2lsb(bytes2(_input));

    }

    function byte2lsb(bytes2 _input) internal pure returns (bytes2) {

        return bytes2(abi.encodePacked(bytes1(_input << 8), bytes1(_input)));

    }

    function _toBuffer(bytes memory _bytes) internal pure returns (bytes1[] memory) {

        uint256 _length = _bytes.length;

        bytes1[] memory byteArray = new bytes1[](_length);
        bytes memory tempBytes;

        unchecked{
            for (uint256 i = 0; i<_length; i++) {
                assembly {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(1, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, 1)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), i)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, 1)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }

                byteArray[i] = bytes1(tempBytes);

            }
        }
        
        return byteArray;
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.13;

import './utils.sol';

library wav {

    bytes4 constant RIFF_HDR = hex'52_49_46_46'; // RIFF
    bytes16 constant WAV_FMT_HDR = hex'57_41_56_45_66_6d_74_20_10_00_00_00_01_00_01_00'; // WAVE_fmt _ and constant from header  


    function reverse(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) |
            ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function fmtByteRate(uint32 sampleRate) internal pure returns (bytes12) {

        bytes4 lsbSampleRate = bytes4(reverse(sampleRate));


        return bytes12(
            bytes.concat(
                lsbSampleRate,
                lsbSampleRate,
                hex'01_00',
                hex'08_00'
            )
        );

    }

    function formatDataChunk(bytes memory audioData) internal pure returns (bytes memory) {
        return bytes.concat(
            bytes4('data'),
            bytes4(reverse(uint32(audioData.length))),
            audioData
        );
    }

    function encodeWAV(bytes memory _audioData, uint32 _sampleRate) internal pure returns (string memory) {

        uint32 audioSize = uint32(_audioData.length);

        return string.concat(
            'data:audio/wav;base64,',
            utils.encode(
                bytes.concat(
                    RIFF_HDR,
                    bytes4(reverse(audioSize+12)),
                    WAV_FMT_HDR,
                    bytes12(fmtByteRate(_sampleRate)),
                    formatDataChunk(_audioData)
                )
            )
        );

    } 

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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