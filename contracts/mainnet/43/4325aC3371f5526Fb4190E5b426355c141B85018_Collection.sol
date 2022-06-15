// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/Base64.sol";
import "./utils/MerkleProof.sol";

import "./CollectionDescriptor.sol";

/*
___________.__             __________                                _____                             
\__    ___/|  |__   ____   \______   \ ____   ____   _____     _____/ ____\                            
  |    |   |  |  \_/ __ \   |       _//  _ \ /  _ \ /     \   /  _ \   __\                             
  |    |   |   Y  \  ___/   |    |   (  <_> |  <_> )  Y Y  \ (  <_> )  |                               
  |____|   |___|  /\___  >  |____|_  /\____/ \____/|__|_|  /  \____/|__|                               
                \/     \/          \/                    \/                                            
.___        _____.__       .__  __           __________        .__        __  .__                      
|   | _____/ ____\__| ____ |__|/  |_  ____   \______   \_____  |__| _____/  |_|__| ____    ____  ______
|   |/    \   __\|  |/    \|  \   __\/ __ \   |     ___/\__  \ |  |/    \   __\  |/    \  / ___\/  ___/
|   |   |  \  |  |  |   |  \  ||  | \  ___/   |    |     / __ \|  |   |  \  | |  |   |  \/ /_/  >___ \ 
|___|___|  /__|  |__|___|  /__||__|  \___  >  |____|    (____  /__|___|  /__| |__|___|  /\___  /____  >
         \/              \/              \/                  \/        \/             \//_____/     \/ 

Lost in the simulation, a painter spent the rest of their infinite life, painting the feeling of their infinite room.
No one knows how far it goes, but apparently, it is infinite.
What is known, however is that over time, the painter resorted to increasing minimalism.
Up to the 1 million mints, the odds of increasingly painting with more minimal features becomes possible.

CC0 On-Chain SVG Generative Art.
Untitled Frontier Project by @simondlr (Simon de la Rouviere).
Logged Universe Season 1 Interlude Art.
Free to mint. Infinite Supply.
*/


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for opensea integration. doesn't do anything else.

    CollectionDescriptor public descriptor;

    mapping (uint256 => bytes) public hashes;
    uint256 public totalSupply = 0;

    // todo: for testing
    // uint256 public newlyMinted;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        descriptor = new CollectionDescriptor();

        // mint #1 to UF to kickstart it
        _createNFT(owner);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes memory hash = hashes[tokenId];

        string memory name = descriptor.generateName(tokenId); 
        string memory description = "The Room of Infinite Paintings: a simulated mind's infinite attempt for meaning.";

        string memory image = generateBase64Image(hash, tokenId);
        string memory attributes = generateTraits(hash, tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(hash, tokenId));
        return Base64.encode(img);
    }

    function generateImageFromTokenID(uint256 tokenId) public view returns (string memory) {
        bytes memory hash = hashes[tokenId];
        return descriptor.generateImage(hash, tokenId);
    }

    function generateImage(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(hash, tokenId);
    }

    function generateTraits(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(hash, tokenId);
    }

    function mint() public {
        _mint(msg.sender);
    }

    // internal mint (not necessary, but keeping it for vestigial reasons based on the template used)
    function _mint(address _owner) internal {
        _createNFT(_owner);
    }

    function _createNFT(address _owner) internal {
        totalSupply+=1;
        bytes memory hash = abi.encodePacked(keccak256(abi.encodePacked(totalSupply, block.timestamp, _owner))); 
        hashes[totalSupply] = hash;
        super._mint(_owner, totalSupply);

        // newlyMinted = totalSupply;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC721Metadata.sol";
import "./utils/Address.sol";
// import "../../utils/Context.sol";
import "./utils/Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty 
     * by default, can be overriden in child contracts.
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

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        // _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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

        // _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // modified from ERC721 template:
    // removed BeforeTokenTransfer
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

// import "hardhat/console.sol";

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
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
    ) internal view returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal view returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            // console.logBytes32(computedHash);
            // console.logBytes32(proofElement);
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                //computedHash = _efficientHash(computedHash, proofElement);
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                // computedHash = _efficientHash(proofElement, computedHash);
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import './SVG.sol';
import './Utils.sol';

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

contract Renderer {

    function render(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        uint256 midPoint = uint256(toUint8(hash,0))*300/256; // 0 - 299
        uint256 midPoint2 = uint256(toUint8(hash,1))*300/256; // 0 - 299
        uint256 gap = 10 + uint256(toUint8(hash,2))/4; // 0 - 63 
        uint256 shiftTopY = 300 - midPoint;
        uint256 shiftBottomY = 300 + midPoint;

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#000">',
                definitions(hash, _tokenId),
                room(shiftTopY, shiftBottomY),
                gradientRects(shiftTopY, shiftBottomY),
                stars(shiftTopY, shiftBottomY),
                polygons(gap, midPoint, midPoint2),
                '</svg>'
            );
    }

    function definitions(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        return string.concat(gradients(), filters(hash, _tokenId));
    }

    /*
    To emphasise the feeling of the horizon disappearing.
    */
    function gradients() public pure returns (string memory) {
        return string.concat(
                svg.linearGradient(
                    string.concat(svg.prop('id', 'topGradient'),svg.prop('gradientTransform', 'rotate(90)')),
                    string.concat(svg.gradientStop(80, 'white',svg.prop('stop-opacity', '0')),svg.gradientStop(100, 'white', svg.prop('stop-opacity', '1')))
                )
        );
    }

    function filters(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        string memory roomBF = generateBaseFrequency(hash, 3, 4, ['0.0', '0.00', '0.000']);
        string memory starsBF = generateBaseFrequency(hash, 5, 6, ['0.', '0.0', '0.00']);
        string memory starsOctaves = utils.uint2str(1 + uint256(toUint8(hash,7))*4/256); // 1 - 4

        string memory roomSeed = utils.uint2str(uint256(toUint8(hash,8))*uint256(toUint8(hash,9))*uint256(toUint8(hash,10))); // 0 - 16581375
        string memory starSeed = utils.uint2str(uint256(toUint8(hash,11))*uint256(toUint8(hash,12))*uint256(toUint8(hash,13))); // 0 - 16581375

        return string.concat(
            svg.filter(
                svg.prop('id','room'),
                string.concat(
                    svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', roomBF),svg.prop('seed', roomSeed), svg.prop('result', 'turb'))),
                    svg.el('feColorMatrix', svg.prop('values', generateColorMatrix(hash, _tokenId)))
                )
            ),
            svg.filter(
                svg.prop('id', 'stars'),
                string.concat(
                    svg.el('feTurbulence', string.concat(svg.prop('type', 'fractalNoise'), svg.prop('numOctaves', starsOctaves), svg.prop('baseFrequency', starsBF), svg.prop('seed', starSeed), svg.prop('result', 'turb'))),
                    svg.el('feColorMatrix', svg.prop('values', '15 0 0 0 0 0 15 0 0 0 0 0 15 0 0 0 0 0 -15 5'))
                )
            )
        );
    }

    function generateBaseFrequency(bytes memory hash, uint256 index1, uint index2, string[3] memory decimalStrings) public pure returns (string memory) {
        string memory strNr = utils.uint2str(1 + uint256(toUint8(hash,index1))*1000/256); // 1 - 997 (ish)
        uint256 dec = uint256(toUint8(hash, index2))*3/256; // 0 - 2
        string memory bf = string.concat(decimalStrings[dec], strNr);
        return bf;
    }

    /* DRAWING SVG */
    function room(uint256 shiftTopY, uint256 shiftBottomY) public pure returns (string memory) {
        string memory rectProps = string.concat(
            svg.prop('width', '300'),
            svg.prop('height', '300'),
            svg.prop('filter', 'url(#room)')
        );
        string memory topTranslate = string.concat('translate(0,-',utils.uint2str(shiftTopY+30),')'); // move it up to horizon
        string memory bottomTranslate = string.concat('translate(0,', utils.uint2str(shiftBottomY+30),') scale(-1,1) rotate(180)'); // move it down to floor of horizon, flip and rotate to mirror

        return string.concat(
            svg.rect(
                string.concat(
                    rectProps,
                    svg.prop('transform', topTranslate) 
                )
            ),
            svg.rect(
                string.concat(
                    rectProps,
                    svg.prop('transform', bottomTranslate)
                )
            )
        );
    }

    function generateColorMatrix(bytes memory hash, uint256 _tokenId) public pure returns (string memory) {
        string memory strMatrix;

        for(uint i = 0; i<20; i+=1) {
            // re-uses entropy
            uint matrixOffset = uint256(toUint8(hash, i))/4; // 0 - 64
            uint negOrPos = toUint8(hash, i); // 0 - 255

            if(i == 18) {
                // the minimalism factor is defined by the alpha/alpha offset in the color matrix.
                // positive == changing to more colour
                // negative == taking colour away
                // the range is +64 -> -64 (128 digits)
                // max minimalism arrives at 1m mints.
                uint256 diff = generateMinimalismFactor(hash, i, _tokenId);

                // signed ints would've been better, but using unsigned<->string utils, so just manually adding pos/neg signs.
                string memory modStr;
                if (diff > 64) {
                   modStr = string.concat("-", utils.uint2str(diff-64), ' ');
                } else {
                   modStr = string.concat(utils.uint2str(64-diff), ' ');
                }

                strMatrix = string.concat(strMatrix, modStr); 

            } else if(i==4 || i == 9 || i== 14 || i == 19) {
                strMatrix = string.concat(strMatrix, '1 '); // end multiplier of channels (should be linear change, not multiplied)
            } else if(negOrPos < 128) { // random chance of adding or taking away colour (or alpha) from rgba
                strMatrix = string.concat(strMatrix, utils.uint2str(matrixOffset), ' ');
            } else {
                strMatrix = string.concat(strMatrix, '-', utils.uint2str(matrixOffset), ' ');
            }
        }
        return strMatrix;
    }

    /*
    A number in between 0 - 128, where 0 is most maximal. No attempt at minimalism.
    128 is the most minimal (given the constraints of the artist).

    It becomes more likely to produce a more minimal painting as it approaches 1 million.
    eg, at mint 1 -> minimalism factor is 0.
    at mint 1,000,000 -> minimalism factor could be between 0 - 128.
    */
    function generateMinimalismFactor(bytes memory hash, uint256 index, uint256 _tokenId) public pure returns (uint256) {
        uint256 rnr = uint256(toUint8(hash, index))/2 + 1; // 1 - 128

        uint256 diff;
        if(_tokenId > 1000000) { 
            diff = rnr; 
        } else {
            diff = _tokenId*rnr/1000000;
        }

        return diff;
    }

    /*
    Some distant stars or nearby galactic nebula. Adds a shine to the room of infinite paintings.
    */
    function stars(uint256 shiftTopY, uint256 shiftBottomY) public pure returns (string memory) {
        string memory rectProps = string.concat(
            svg.prop('width', '300'),
            svg.prop('height', '300'),
            svg.prop('filter', 'url(#stars)')
        );
        string memory topTranslate = string.concat('translate(0,-',utils.uint2str(shiftTopY+30),')');
        string memory bottomTranslate = string.concat('translate(0,', utils.uint2str(shiftBottomY+30),') scale(-1,1) rotate(180)');
        return string.concat(
                svg.rect(
                    string.concat(
                        rectProps, 
                        svg.prop('transform', topTranslate)
                    )
                ),
                svg.rect(
                    string.concat(
                        rectProps, 
                        svg.prop('transform', bottomTranslate)
                    )
                )
        );
    }

    function gradientRects(uint256 shiftTopY, uint256 shiftBottomY) public pure returns (string memory) {
        return string.concat(
                svg.rect(string.concat(svg.prop('width', '300'), svg.prop('height', '300'), svg.prop('fill', 'url(#topGradient)'), svg.prop('transform', string.concat('translate(0,-',utils.uint2str(shiftTopY),')')))),
                svg.rect(string.concat(svg.prop('width', '300'), svg.prop('height', '300'), svg.prop('fill', 'url(#topGradient)'), svg.prop('transform', string.concat('translate(0,', utils.uint2str(shiftBottomY),') scale(-1,1) rotate(180)'))))
        );
    }

    /*
    The polygons are to give the feeling of a room/area stretching into the horizon.
    If the background canvas is white, it fulfills this better.
    If the background is dark, however, the corner polygons make the polygons feel more like it ends in the corners. More artistic than the idea of a line fading into the horizon.
    It's a subtle point to emphasise that the context of the infinite painting matters where it is viewed.
    The initial intent goal was for it to be merely infinite, but instead of taking out the corner lines, I've kept it in to change the feeling of the painting based on what background canvas is used.
    */
    function polygons(uint256 gap, uint256 midPoint, uint256 midPoint2) public pure returns (string memory) {
        uint256[8] memory polyPoints1 = [gap, 0, 0, 0, 0, gap, midPoint2, midPoint];
        uint256[8] memory polyPoints2 = [0, 300-gap, 0, 300, gap, 300, midPoint2, midPoint];
        uint256[8] memory polyPoints3 = [300-gap, 0, 300, 0, 300, gap, midPoint2, midPoint];
        uint256[8] memory polyPoints4 = [300, 300-gap, 300, 300, 300-gap, 300, midPoint2, midPoint];

        return string.concat(
                polygon(polyPoints1), 
                polygon(polyPoints2), 
                polygon(polyPoints3), 
                polygon(polyPoints4)
        );
    }

    function polygon(uint256[8] memory points) public pure returns (string memory) {
        string memory poly = string.concat(utils.uint2str(points[0]),',',utils.uint2str(points[1]),' ',utils.uint2str(points[2]),',',utils.uint2str(points[3]),' ',utils.uint2str(points[4]),',',utils.uint2str(points[5]),' ',utils.uint2str(points[6]),',',utils.uint2str(points[7]));
        return svg.el('polygon', 
            string.concat(
                svg.prop('points', poly),
                svg.prop('fill', 'none'),
                svg.prop('stroke', 'white')
            )
        );
    }

    /* HELPER */

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint; 

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }
}

contract CollectionDescriptor {

    Renderer public renderer;

    constructor() {
        renderer = new Renderer();
    }

    function generateName(uint nr) public pure returns (string memory) {
        return string(abi.encodePacked('Infinite Painting #', utils.uint2str(nr)));
    }

    /*
    While the painting has many random variables (using & re-using ~34 random variables), the only trait to log and keep track of is the minimalism factor.
    The rest should be collected/desired based on aesthetic appeal.
    */
    function generateTraits(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        uint256 minimalFactor = renderer.generateMinimalismFactor(hash, 18, tokenId); 
        string memory traitType = '{"trait_type": "Minimalism Factor", "value":';
        string memory traitValue = string.concat('"', utils.uint2str(minimalFactor), '"}');

        return string(abi.encodePacked(
            '"attributes": [',
            traitType,
            traitValue,
            ']'
        ));
    }

    function generateImage(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        return renderer.render(hash, tokenId);
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC721.sol";

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

pragma solidity ^0.8.9;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.9;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IERC165.sol";

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

pragma solidity ^0.8.9;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.

// modified from original to take away functions that I'm not using

library svg {
    /* MAIN ELEMENTS */

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('filter', _props, _children);
    }

    
    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                'stop',
                string.concat(
                    prop('stop-color', stopColor),
                    ' ',
                    prop('offset', string.concat(utils.uint2str(offset), '%')),
                    ' ',
                    _props
                )
            );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '>',
                _children,
                '</',
                _tag,
                '>'
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<',
                _tag,
                ' ',
                _props,
                '/>'
            );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.

// modified from original to take away functions that I'm not using
library utils {
    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}