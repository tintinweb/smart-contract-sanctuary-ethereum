// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {ValenftinesDescriptors} from "../libraries/ValenftinesDescriptors.sol";


struct Valentine {
    uint8 h1;
    uint8 h2;
    uint8 h3;
    uint24 requitedTokenId;
    address to;
    address from;
}

/// Reverts
/// 1 - value less than mint fee
/// 2 - mint started yet 
/// 3 - mint ended
/// 4 - GTAP mint ended
/// 5 - GTAP mint claimed
/// 6 - invalid proof
/// 7 - inavlid heart type
/// 8 - token does not exist
contract Valenftines is ERC721, Ownable {
    uint256 public immutable mintStartTimestamp;
    uint256 public immutable mintEndTimestamp;
    bytes32 public immutable merkleRoot;
    mapping(uint256 => Valentine) public _valentineInfo;
    mapping(uint256 => uint256) public matchOf;
    mapping(address => bool) public gtapEarlyMintClaimed;

    uint24 private _nonce;

    function valentineInfo(uint256 tokenId) view public returns(Valentine memory){
        require(tokenId <= _nonce, '8');
        return _valentineInfo[tokenId];
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        require(id <= _nonce, '8');
        return ValenftinesDescriptors.tokenURI(id, address(this));
    }

    function svgImage(uint256 id) external view returns (bytes memory) {
        require(id <= _nonce, '8');
        uint256 copy = matchOf[id];
        if(copy > 0){
            Valentine memory vc = _valentineInfo[copy];
            return ValenftinesDescriptors.svgImage(true, copy, vc);
        } else {
            Valentine memory v = _valentineInfo[id];
            return ValenftinesDescriptors.svgImage(false, id, v);
        }
    }

    constructor(
        address _owner,
        uint256 _mintStartTimestamp, 
        uint256 _mintEndTimestamp,
        bytes32 _merkleRoot
    ) 
        ERC721("Valenftines", "GTAP3")
    {
        transferOwnership(_owner);
        mintStartTimestamp = _mintStartTimestamp;
        mintEndTimestamp = _mintEndTimestamp;
        merkleRoot = _merkleRoot;
    }

    /// Mint

    function mint(address to, uint8 h1, uint8 h2, uint8 h3) payable external returns(uint256 id) {
        require(heartMintCostWei(h1) + heartMintCostWei(h2) + heartMintCostWei(h3) <= msg.value, '1');
        require(block.timestamp > mintStartTimestamp, '2');
        require(block.timestamp < mintEndTimestamp, '3');
        
        id = ++_nonce;
        Valentine storage v = _valentineInfo[id];
        v.from = msg.sender;
        v.to = to;
        v.h1 = h1;
        v.h2 = h2;
        v.h3 = h3;
        _safeMint(to, id);
    }

    function gtapMint(address to, uint8 h1, uint8 h2, uint8 h3, bytes32[] calldata merkleProof) payable external returns(uint256 id) {
        require((((heartMintCostWei(h1) + heartMintCostWei(h2) + heartMintCostWei(h3)) * 50) / 100)  <= msg.value, '1');
        require(block.timestamp < mintStartTimestamp, '4');
        require(!gtapEarlyMintClaimed[msg.sender], '5');

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), '6');

        gtapEarlyMintClaimed[msg.sender] = true;
        
        id = ++_nonce;
        Valentine storage v = _valentineInfo[id];
        v.from = msg.sender;
        v.to = to;
        v.h1 = h1;
        v.h2 = h2;
        v.h3 = h3;
        _safeMint(to, id);
    }

    function heartMintCostWei(uint8 heartType) public pure returns(uint256) {
        require(heartType > 0 && heartType < 24, '7');
        return (heartType < 11 ? 1e16 : 
            (heartType < 18 ? 2e16 : 
                (heartType < 23 ? 1e17 : 1e18)));
    }

    /// Transfer

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.transferFrom(from, to, id);
    } 

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override {
        _beforeTransfer(from, to, id);
        super.safeTransferFrom(from, to, id, data);
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 id
    ) private {
        Valentine storage v = _valentineInfo[id];
        if (v.requitedTokenId == 0 && matchOf[id] == 0){
            if(to == v.from){
                uint24 nId = ++_nonce;
                _mint(from, nId);
                v.requitedTokenId = nId;
                matchOf[nId] = id;
            } else {
                v.from = from;
                v.to = to;
            }
        }
    }

    function payOwner(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "amount too high");
        payable(to).transfer(amount);
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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "base64-sol/base64.sol";

import {HexStrings} from "./HexStrings.sol";
import {Valenftines, Valentine} from '../valenftines//Valenftines.sol';

library ValenftinesDescriptors {
    function tokenURI(uint256 id, address valenftines) public view returns (string memory) {
        Valentine memory v = Valenftines(valenftines).valentineInfo(id);
        uint256 copy = Valenftines(valenftines).matchOf(id);
        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"'
                                    '#',
                                    Strings.toString(id),
                                    _tokenName(id, v.requitedTokenId, valenftines),
                                    '", "description":"',
                                    'Valenftines are on-chain art for friends and lovers. They display the address of the sender and recipient along with messages picked by the minter. When the Valenftine is transferred back to the most recent sender, love is REQUITED and the NFT transforms and clones itself so both parties have a copy.',
                                    '", "attributes": [',
                                    tokenAttributes(id, v.requitedTokenId, v.to, v.from),
                                    ']',
                                    ', "image": "'
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(copy > 0 ? svgImage(true, copy, Valenftines(valenftines).valentineInfo(copy)) : svgImage(false, id, v)),
                                    '"}'
                                )
                            )
                        )
                )
            );
    }

    function _tokenName(uint256 tokenId, uint24 requitedTokenId, address valenftines) private view returns(string memory){
        uint256 copy = Valenftines(valenftines).matchOf(tokenId);
        return requitedTokenId == 0 && copy == 0 ?
                '' : 
                string(
                    abi.encodePacked(
                        ' (match of #',
                        copy == 0 ? 
                            Strings.toString(requitedTokenId)
                            : Strings.toString(copy) 
                        , 
                        ')'
                    )
                );
    }

    function tokenAttributes(uint256 tokenId, uint24 requitedTokenId, address to, address from) public view returns(string memory) {
        return string(
            abi.encodePacked(
                '{',
                '"trait_type": "Love",', 
                '"value":"',
                requitedTokenId == 0 ? 'UNREQUITED' : 'REQUITED',
                '"}'
            )
        );
    }

    /// TOKEN ART 

    function svgImage(
        bool isCopy,
        uint256 tokenId, 
        Valentine memory v
    ) 
        public view returns (bytes memory)
    {
        return abi.encodePacked(
            '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="400" height="400" class="container" ',
	            'viewBox="0 0 400 400" style="enable-background:new 0 0 400 400;" xml:space="preserve">',
            styles(tokenId),
            '<defs>',
                '<g id="heart">',
                    '<path d="M79.2-43C71.2-78.4,30.8-84.9,5-60.9c-2.5,2.3-6.4,2.1-8.8-0.3c-25-25.9-75.1-15-76.7,28.2C-82.6,22.3-14,75.2,1.5,75.1C17.3,75.1,91.3,10.7,79.2-43z"/>',
                '</g>',
                '<radialGradient id="rainbow" cx="58%" cy="49%" fr="0%" r="70%" spreadMethod="repeat">',
                '<stop offset="0%" style="stop-color:#ffb9b9" />',
                '<stop offset="30%" style="stop-color:#',
                isCopy ? 'cfbcff' : 'fff7ad',
                '" />',
                '<stop offset="50%" style="stop-color:#97fff3" />',
                '<stop offset="80%" style="stop-color:#',
                isCopy ? 'fff7ad' : 'cfbcff',
                '" />',
                '<stop offset="100%" style="stop-color:#ffb9b9" />',
                '</radialGradient>',
            '</defs>',

            '<rect ',
            v.requitedTokenId != 0 ? 'fill="url(#rainbow)"' : 'class="background"',
            ' width="400" height="400"/>',

            '<animate xlink:href="#rainbow" ',
                'attributeName="fr" ',
                'dur="16s" ',
                'values="0%;25%;0%" ',
                'repeatCount="indefinite"',
            '/>',

            '<animate xlink:href="#rainbow" ',
                'attributeName="r" ',
                'dur="16s" ',
                'values="70%;180%;70%" ',
                'repeatCount="indefinite"',
            '/>',
           
            heartsSVGs(tokenId, v),
            '</svg>'
        );
    }

    function styles(uint256 tokenId) private pure returns(bytes memory) {
        return abi.encodePacked(
            '<style type="text/css">',
                '.container{font-size:28px; font-family: monospace, monospace; font-weight: 500; letter-spacing: 2px;}',
                '.whitetext{fill:#ffffff; text-anchor:middle;}',
                '.blacktext{fill:#000000; text-anchor:middle;}',
                '.pinktext{fill:#FA0F95; text-anchor:middle;}',
                '.whiteheart{fill:#ffffff;}',
                '.whiteheartoutline{fill:#ffffff; stroke: #000000; stroke-width: 6px;}',
                '.black{fill:#000000;}',
                '.pink{fill:#FFC9DF;}',
                '.blue{fill:#A2E2FF;}',
                '.orange{fill:#FFCC99;}',
                '.green{fill:#A4FFCA;}',
                '.purple{fill:#DAB5FF;}',
                '.yellow{fill:#FFF6AE;}',
                '.background{fill:#FFDBDB;}',
            '</style>'
        );
    }

    function heartsSVGs(
        uint256 tokenId,
        Valentine memory v
    ) 
        public view returns (bytes memory)
    {
        bool requited = v.requitedTokenId != 0;
        return abi.encodePacked(
            addrHeart(true, tokenId, requited, v.from),

            addrHeart(false, tokenId, requited, v.to),

            textHeart(1, v.h1, tokenId, requited, v.to, v.from),
            textHeart(2, v.h2, tokenId, requited, v.from, v.to),
            textHeart(3, v.h3, tokenId, requited, address(this), v.from),

            emptyHeart(true, tokenId, requited, v.to),
            emptyHeart(false, tokenId, requited, v.from)
        );
    }

    function addrHeart(bool first, uint256 tokenId, bool requited, address account) private pure returns (bytes memory) {
        string memory xy = first ? '93,96' : '236,209';
        return abi.encodePacked(
            '<g transform="translate(',
            xy,
            ') rotate(',
            rotation(tokenId + (first ? 100 : 101)),
            ')">',
                '<use xlink:href="#heart" class="whiteheart',
                requited ? '' : 'outline',
                '"/>',
                '<text class="',
                requited ? 'pinktext' : 'blacktext',
                '">',
                    '<tspan x="0" y="-10">',
                    HexStrings.partialHexString(uint160(account), 4, 40),
                    '</tspan>',
                '</text>',
            '</g>'
        );
    }

    function textHeart(uint256 index, uint8 heartType, uint256 tokenId, bool requited, address addr1, address addr2) private pure returns (bytes memory) {
        string memory xy = (index < 2 ? '327,62' :
                                index < 3 ? '102,325' : '336,348');
        return abi.encodePacked(
            '<g transform="translate(',
            xy,
            ') rotate(',
            rotation(tokenId + 101 + index),
            ')">',
                '<use xlink:href="#heart" class="',
                requited ? heartColorClass(addr1, addr2) : 'black',
                '"/>',
                '<text class="',
                requited ? 'pinktext' : 'whitetext',
                '">',
                    heartMessageTspans(heartType),
                '</text>',
            '</g>'
        );
    }

    function heartMessageTspans(uint8 heartType) private pure returns(bytes memory){
        return (heartType < 2 ? bullishForYou() :
                (heartType < 3 ? beMine() : 
                (heartType < 4 ? toTheMoon() : 
                (heartType < 5 ? coolCat() : 
                (heartType < 6 ? cutiePie() :
                (heartType < 7 ? zeroXZeroX() : 
                (heartType < 8 ? bestFren() : 
                (heartType < 9 ? bigFan() : 
                (heartType < 10 ? gm() : 
                (heartType < 11 ? coinBae() : 
                (heartType < 12 ? sayIDAO() :
                (heartType < 13 ? wagmi() : 
                (heartType < 14 ? myDegen() : 
                (heartType < 15 ? payMyTaxes() :
                (heartType < 16 ? upOnly() : 
                (heartType < 17 ? lilMfer() : 
                (heartType < 18 ? onboardMe() : 
                (heartType < 19 ? letsMerge() : 
                (heartType < 20 ? hodlMe() : 
                (heartType < 21 ? looksRare() :
                (heartType < 22 ? wenRing() : 
                (heartType < 23 ? idMintYou() : simpForYou()))))))))))))))))))))));
    }

    function emptyHeart(bool first, uint256 tokenId, bool requited, address account) private view returns (bytes memory) {
        string memory xy = first ? '-40,210' : '460,190';
        return abi.encodePacked(
            '<g transform="translate(',
            xy,
            ') rotate(',
            rotation(tokenId + (first ? 104 : 105)),
            ')">',
                '<use xlink:href="#heart" class="',
                requited ? heartColorClass(account, address(this)) : 'black',
                '"/>',
            '</g>'
        );
    }

    function rotation(uint256 n) private pure returns (string memory) {
        uint256 r = n % 30;
        bool isPos = (n % 2) > 0 ? true : false;
        return string(
            abi.encodePacked(
                isPos ? '' : '-',
                Strings.toString(r)
            )
        );
    }

    function heartColorClass(address addr1, address addr2) private pure returns(string memory){
        uint256 i = numberFromAddresses(addr1, addr2, 100) % 6;
        return (i < 1 ? 'pink' : 
            (i < 2 ? 'blue' : 
                (i < 3 ? 'orange' : 
                    (i < 4 ? 'green' : 
                        (i < 5 ? 'purple' : 'yellow')))));

    }

    // gives a number from address where 
    // numberFromAddresses(addr1, addr2, mod) != numberFromAddresses(addr2, addr1, mod)
    function numberFromAddresses(address addr1, address addr2, uint256 mod) private pure returns(uint256) {
        return ((uint160(addr1) % 201) + (uint160(addr2) % 100)) % mod;
    } 

    function gm() private pure returns(bytes memory){
        return oneLineText("GM");
    }

    function zeroXZeroX() private pure returns(bytes memory){
        return oneLineText("0x0x");
    }

    function wagmi() private pure returns(bytes memory){
        return oneLineText("WAGMI");
    }
    
    function bullishForYou() private pure returns(bytes memory){
        return twoLineText("BULLISH", "4YOU");
    }

    function beMine() private pure returns(bytes memory){
        return twoLineText("BE", "MINE");
    }

    function toTheMoon() private pure returns(bytes memory){
        return twoLineText("2THE", "MOON");
    }

    function coolCat() private pure returns(bytes memory){
        return twoLineText("COOL", "CAT");
    }

    function cutiePie() private pure returns(bytes memory){
        return twoLineText("CUTIE", "PIE");
    }

    function bestFren() private pure returns(bytes memory){
        return twoLineText("BEST", "FREN");
    }

    function bigFan() private pure returns(bytes memory){
        return twoLineText("BIG", "FAN");
    }
    
    function coinBae() private pure returns(bytes memory){
        return twoLineText("COIN", "BAE");
    }

    function sayIDAO() private pure returns(bytes memory){
        return twoLineText("SAY I", "DAO");
    }

    function myDegen() private pure returns(bytes memory){
        return twoLineText("MY", "DEGEN");
    }

    function payMyTaxes() private pure returns(bytes memory){
        return twoLineText("PAY MY", "TAXES");
    }

    function upOnly() private pure returns(bytes memory){
        return twoLineText("UP", "ONLY");
    }

    function lilMfer() private pure returns(bytes memory){
        return twoLineText("LIL", "MFER");
    }

    function onboardMe() private pure returns(bytes memory){
        return twoLineText("ONBOARD", "ME");
    }

    function letsMerge() private pure returns(bytes memory){
        return twoLineText("LETS", "MERGE");
    }

    function hodlMe() private pure returns(bytes memory){
        return twoLineText("HODL", "ME");
    }

    function looksRare() private pure returns(bytes memory){
        return twoLineText("LOOKS", "RARE");
    }

    function wenRing() private pure returns(bytes memory){
        return twoLineText("WEN", "RING");
    }

    function simpForYou() private pure returns(bytes memory){
        return twoLineText("SIMP", "4U");
    }

    function idMintYou() private pure returns(bytes memory){
        return threeLineText('ID', 'MINT', 'YOU');
    }

    function oneLineText(string memory text) private pure returns(bytes memory){
        return abi.encodePacked(
            '<tspan x="0" y="-10">',
            text,
            '</tspan>'
        );
    }

    function twoLineText(string memory line1, string memory line2) private pure returns(bytes memory){
        return abi.encodePacked(
            '<tspan x="0" y="-15">',
            line1,
            '</tspan>',
            '<tspan x="0" y="20">',
            line2,
            '</tspan>'
        );
    }

    function threeLineText(string memory line1, string memory line2, string memory line3) private pure returns(bytes memory){
        return abi.encodePacked(
            '<tspan x="0" y="-25">',
            line1,
            '</tspan>',
            '<tspan x="0" y="10">',
            line2,
            '</tspan>',
            '<tspan x="0" y="45">',
            line3,
            '</tspan>'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
pragma solidity 0.8.10;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    // @notice returns value as a hex string of desiredPartialStringLength length,
    // adding '0x' to the start
    // Designed to be used for shortening addresses for display purposes.
    // @param value The value to return as a hex string
    // @param desiredPartialStringLength How many hex characters of `value` to return in the string
    // @param valueLengthAsHexString The length of `value` as a hex string
    function partialHexString(
        uint160 value,
        uint8 desiredPartialStringLength,
        uint8 valueLengthAsHexString
    ) 
        internal pure returns (string memory) 
    {
        bytes memory buffer = new bytes(desiredPartialStringLength + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        uint8 offset = desiredPartialStringLength + 1;
        // remove values not in partial length, four bytes for every hex character
        value >>= 4 * (valueLengthAsHexString - desiredPartialStringLength);
        for (uint8 i = offset; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'HexStrings: hex length insufficient');

        return string(buffer);
    }
}