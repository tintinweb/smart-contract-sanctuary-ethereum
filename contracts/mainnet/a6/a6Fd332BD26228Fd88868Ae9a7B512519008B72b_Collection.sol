// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/Base64.sol";
import "./utils/MerkleProof.sol";

import "./CollectionDescriptor.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for opensea integration. doesn't do anything else.
    address payable public recipient; // in this instance, it will be a 0xSplit on mainnet

    CollectionDescriptor public descriptor;

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    mapping(uint256 => bool) randomMints;

    // for loyal mints
    mapping (address => bool) public claimed;
    bytes32 public loyaltyRoot;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address payable recipient_, uint256 startDate_, uint256 endDate_, bytes32 root_) ERC721(name_, symbol_) {
        descriptor = new CollectionDescriptor();
        recipient = recipient_;
        startDate = startDate_;
        endDate = endDate_;
        loyaltyRoot = root_;

        // mint #1 to UF to kickstart it. this is from the loyal mint so also set claim to true.
        // a random mint
        _createNFT(owner, block.timestamp, true);
        claimed[owner] = true;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory name = descriptor.generateName(tokenId); 
        string memory description = "Capsules containing visualizations of all the lives lived by simulated minds in the school of unlearning.";

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);
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

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(tokenId));
        return Base64.encode(img);
    }

    /*
    NOTE: Calling this when the token doesn't exist will result in it being defined
    as a "chosen seed" because randomMint will be 0 (or false) if it's not initialized.
    */
    function generateImage(uint256 tokenId) public view returns (string memory) {
        bool randomMint = randomMints[tokenId];
        return descriptor.generateImage(tokenId, randomMint);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        bool randomMint = randomMints[tokenId];
        return descriptor.generateTraits(tokenId, randomMint);
    }

    /*
    VM Viewers:
    These drawing functions are used inside the browser vm to display the capsule without having to call a live network.
    */

    // Generally used inside the browser VM to preview a capsule for seed mints
    function generateImageFromSeedAndAddress(uint256 _seed, address _owner) public view returns (string memory) {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        return generateImage(tokenId);
    }

    // a forced random mint viewer, used when viewing in the browser vm after a successful random mint
    function generateRandomMintImageFromTokenID(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenId, true);
    }

    /* PUBLIC MINT OPTIONS */
    function mintWithSeed(uint256 _seed) public payable {
        require(msg.value >= 0.074 ether, "MORE ETH NEEDED"); // ~$100
        _mint(msg.sender, _seed, false);
    }

    function mint() public payable {
        require(msg.value >= 0.022 ether, "MORE ETH NEEDED"); // ~$30
        _mint(msg.sender, block.timestamp, true);
    }

    function loyalMint(bytes32[] calldata proof) public {
        loyalMintLeaf(proof, msg.sender);
    }

    // anyone can mint for someone in the merkle tree
    // you just need the correct proof
    function loyalMintLeaf(bytes32[] calldata proof, address leaf) public {
        // if one of addresses in the overlap set
        require(claimed[leaf] == false, "Already claimed");
        claimed[leaf] = true;

        bytes32 hashedLeaf = keccak256(abi.encodePacked(leaf));
        require(MerkleProof.verify(proof, loyaltyRoot, hashedLeaf), "Invalid Proof");
        _mint(leaf, block.timestamp, true); // mint a random mint for loyal collector
    }

    // FOR TESTING: UNCOMMENT TO RUN TESTS
    // For testing, we need to able to generate a specific random capsule.
    /*function mintWithSeedForcedRandom(uint256 _seed) public payable {
        require(msg.value >= 0.074 ether, "MORE ETH NEEDED"); // $100
        _mint(msg.sender, _seed, true);
    }*/

    /* INTERNAL MINT FUNCTIONS */
    function _mint(address _owner, uint256 _seed, bool _randomMint) internal {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        _createNFT(_owner, _seed, _randomMint);
    }

    function _createNFT(address _owner, uint256 _seed, bool _randomMint) internal {
        uint256 tokenId = uint(keccak256(abi.encodePacked(_seed, _owner)));
        if(_randomMint) { randomMints[tokenId] = _randomMint; }
        super._mint(_owner, tokenId);
    }

    // WITHDRAWING ETH
    function withdrawETH() public {
        recipient.call{value: address(this).balance}(""); // this is safe because the recipient is known
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

pragma solidity ^0.8.11;

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

import "./Words.sol";
import "./Definitions.sol";

contract CollectionDescriptor {

    Words public words;
    Definitions public defs;

    constructor() {
        words = new Words();
        defs = new Definitions();
    }

    function render(uint256 _tokenId, bool randomMint) internal view returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(_tokenId));

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#fff">',
                defs.defs(hash),
                craftSand(hash),
                cutOut(hash, randomMint),
                capsuleOutline(),
                '</svg>'
            );
    }

    /* RE-USABLE SHAPES */
    function sandRect(string memory y, string memory h, string memory fill, string memory opacity) internal pure returns (string memory) {
        return svg.rect(
            string.concat(
                svg.prop('width', '300'),
                svg.prop('y',y),
                svg.prop('height',h),
                svg.prop('fill',fill),
                svg.prop('stroke','black'),
                svg.prop('filter','url(#sandFilter)'),
                svg.prop('opacity', opacity)
            )
        );        
    }

    /* CONSTRUCTIONS */
    function craftSand(bytes memory hash) internal pure returns (string memory) {
        string memory sandRects = '<rect width="100%" height="100%" filter="url(#fineSandFilter)"/> '; // background/fine sand

        uint amount = utils.getAmount(hash); // 2 - 18
        uint range = utils.getRange(hash);
        uint height; // = 0
        uint y; // = 0
        uint shift = 3;
        uint colour =  utils.getColour(hash);// 0 - 360
        uint cShift = utils.getColourShift(hash); // 0 - 255
        string memory opacity = "1";
        for (uint i = 1; i <= amount; i+=1) {
            y+=height;
            if(i % 2 == 0) {
                height = range*shift/2 >> shift;
                shift += 1;
            }
            opacity = "1";
            if ((y+colour) % 5 == 0) { opacity = "0"; }
            sandRects = string.concat(
                sandRects,
                sandRect(utils.uint2str(y), utils.uint2str(height), string.concat('hsl(',utils.uint2str(colour),',70%,50%)'), opacity)
            );
            colour+=cShift;
        }

        return sandRects;
    }

    function capsuleOutline() internal pure returns (string memory) {
        return string.concat(
            // top half of capsule
            svg.rect(string.concat(svg.prop('x', '111'), svg.prop('y', '50'), svg.prop('width', '78'), svg.prop('height', '150'), svg.prop('ry', '40'), svg.prop('rx', '40'), svg.prop('mask', 'url(#cutoutMask)'), svg.prop('clip-path', 'url(#clipBottom)'))),
            // bottom half of capsule
            svg.rect(string.concat(svg.prop('x', '113'), svg.prop('y', '50'), svg.prop('width', '74'), svg.prop('height', '205'), svg.prop('ry', '35'), svg.prop('rx', '50'), svg.prop('mask', 'url(#cutoutMask)'))),
            // crossbar of capsule 
            svg.rect(string.concat(svg.prop('x', '111'), svg.prop('y', '150'), svg.prop('width', '78'), svg.prop('height', '4'))),
            // top reflection
            svg.rect(string.concat(svg.prop('x', '115'), svg.prop('y', '45'), svg.prop('width', '70'), svg.prop('height', '40'), svg.prop('ry', '100'), svg.prop('rx', '10'), svg.prop('fill', 'white'), svg.prop('opacity', '0.4'), svg.prop('mask', 'url(#topReflectionMask)'))),
            // long reflection
            svg.rect(string.concat(svg.prop('x', '122'), svg.prop('y', '55'), svg.prop('width', '56'), svg.prop('height', '184'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('fill', 'white'), svg.prop('opacity', '0.4'))),
            // drop shadow
            svg.rect(string.concat(svg.prop('x', '115'), svg.prop('y', '180'), svg.prop('width', '70'), svg.prop('height', '70'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('filter', 'url(#dropShadowFilter)'), svg.prop('clip-path', 'url(#clipShadow)')))
        );
    }

    function cutOut(bytes memory hash, bool randomMint) internal view returns (string memory) {
        return svg.el('g', svg.prop('mask', 'url(#cutoutMask)'),
            string.concat(
                svg.whiteRect(),
                words.whatIveDone(hash, randomMint)
            )
        );
    }

    function generateName(uint nr) public pure returns (string memory) {
        return string(abi.encodePacked('Capsule #', utils.substring(utils.uint2str(nr),0,8)));
    }
    
    function generateTraits(uint256 tokenId, bool randomMint) public view returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        (uint256 rareCount, uint256 allCount, uint256[3][10] memory indices) = utils.getIndices(hash, randomMint);

        string memory nrOfWordsTrait = createTrait("Total Experiences", utils.uint2str(allCount));
        string memory nrOfRareWordsTrait = createTrait("Rare Experiences", utils.uint2str(rareCount));
        string memory slots;
        string memory typeOfMint;
        
        if(randomMint) {
            typeOfMint = createTrait("Type of Mint", "Random");
        } else {
            typeOfMint = createTrait("Type of Mint", "Chosen Seed");
        }

        for(uint i; i < 10; i+=1) {
            if(indices[i][0] == 1) { // slot is assigned or not
                string memory slotPosition = string.concat("Slot ", utils.uint2str(i));
                string memory action;
                if(indices[i][1] == 1) { // there's a rare word there or not
                    action = words.rareActions(indices[i][2]);
                } else {
                    action = words.actions(indices[i][2]);
                }

                slots = string.concat(slots, ",", createTrait(slotPosition, action));
            }
        }

        return string(abi.encodePacked(
            '"attributes": [',
            nrOfWordsTrait,
            ",",
            nrOfRareWordsTrait,
            ",",
            typeOfMint,
            slots,
            ']'
        ));
    }

    function createTrait(string memory traitType, string memory traitValue) internal pure returns (string memory) {
        return string.concat(
            '{"trait_type": "',
            traitType,
            '", "value": "',
            traitValue,
            '"}'
        );
    }

    function generateImage(uint256 tokenId, bool randomMint) public view returns (string memory) {
        return render(tokenId, randomMint);
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
pragma solidity ^0.8.11;

import './svg.sol';
import './utils.sol';

contract Words {

    // 33
    string[] public rareActions = [
        'DIVINATED CORALS',
        'PLANTED RUNES',
        'LED EXODUS',
        'CRAFTED IRIDESCENCE',
        'ACCUMULATED DUNES',
        'DECIPHERED CAVES',
        'STOLE GUILT',
        'WROTE SAND',
        'BRAIDED GEMS',
        'TOUCHED LIGHTNING',
        'SPARKED AWAKENING',
        'TORE FEAR',
        'ALIGNED COLLECTIVE',
        'HACKED CONFUSION',
        'STEERED WEBS',
        'GUIDED MOVEMENTS',
        'PROGRESSED PERCEPTION',
        'ABSORBED THOUGHT',
        'CONSTRUCTED EMPIRES',
        'BYPASSED EGOS',
        'RETRIEVED RIDDLES',
        'MET FROGS',
        'TURNED PHYSICS',
        'SLEPT AURAS',
        'FOUND SILLINESS',
        'COOKED SURVEILLANCE',
        'BUILT BIO-ARMOUR',
        'ALLEVIATED COGNITION',
        'INTENSIFIED LUCIDITY',
        'PAINTED INTERBEINGS',
        'DRANK CULTURES',
        'EMERGENT KNOWING',
        'SWEPT SUNSHINE'
    ];

    // 62
    string[] public actions = [
        'LENGTHENED PLANETS',
        'BREATHED SONIC',
        'BEAMED RHYTHMS',
        'MERGED CONTENTION',
        'DEPLOYED PUZZLES',
        'RECREATED MYTHS',
        'GREW ROOTS',
        'UNDERSTOOD RAIN',
        'REVITALISED ELECTRICITY',
        'THOUGHT CRYSTAL',
        'SURPRISED BEINGS',
        'PLAYED INFINITELY',
        'SNUGGLED DANGER',
        'PINCHED MAGMA',
        'JUGGLED MOMENTS',
        'SPOKE WATER',
        'SCULPTED SOUND',
        'BEGAN BEGINNINGS',
        'BECAME ECOLOGY',
        'TASTED LIGHT',
        'THOUGHT STORMS',
        'CIRCULATED GRAVITY',
        'SWAM COLOURFULLY',
        'GALVANISED BASS',
        'HEARTENED ROCKS',
        'KINDLED EARTHSTORY',
        'AWAKENED GRIMOIRE',
        'INCITED ABUNDANCE',
        'EVOLVED SEEDS',
        'DANCED COSMIC',
        'REGENERATED',
        'FLIRTED FLOWERS',
        'CHERISHED WINTER',
        'TOYED RIVERS',
        'CREATED BEAUTY',
        'EMBOLDENED DUST',
        'LOVED MOSS',
        'DANCED WORLDS',
        'WHISPERED DARKNESS',
        'CODED DIVINITY',
        'LAUGHED DEEPLY',
        'DREAMED FUNGI',
        'VENTURED DEPTHS',
        'WANDERED FORESTS',
        'SCULPTED SUN',
        'SUBVERTED ECLIPSE',
        'EMBODIED MOUNTAIN',
        'EXPLORED DIVINITY',
        'DEEPENED STILLNESS',
        'REFLECTED STARS',
        'UNITED FRIENDS',
        'BEFRIENDED DARKNESS',
        'FELT UNIVERSAL',
        'INITIATED EARTHSTORY',
        'EMBRACED ALL',
        'ROAMED UNIVERSE',
        'NOURISHED DEATH',
        'FLOATED CLOUDS',
        'MOVED EVERYBODY',
        'FELT COSMIC',
        'SHOOK TRAUMA',
        'HEALED PAIN'
    ];

    struct WordDetails {
        string lineX1;
        string lineX2;
        string lineY;
        string textX;
        string textY;
        string textAnchor;
    }

    function whatIveDone(bytes memory hash, bool randomMint) public view returns (string memory) {
        string memory wordList;

        uint256[3][10] memory indices;
        
        uint256 leftY = utils.getLeftY(hash); // 100 - 116
        uint256 rightY = utils.getRightY(hash); // 100 - 116
        uint256 diffLeft = utils.getDiffLeft(hash); // 10 - 33
        uint256 diffRight = utils.getDiffRight(hash); // 10 - 33

        (,, indices) = utils.getIndices(hash, randomMint);
        WordDetails memory details;

        for(uint i; i < 10; i+=1) {
            // 10 slots. 5 a side.
            // words are drawn left-right, then down.
            uint y;
            if(i % 2 == 0) {
                details.lineX1 = '10'; //x1
                details.lineY = utils.uint2str(leftY-3); //y1, y2
                details.lineX2 = '150'; //x2
                details.textY = utils.uint2str(leftY);
                details.textX = '10';
                details.textAnchor = 'start';
                y = leftY;

                leftY += diffLeft;
            } else {
                details.lineX1 = '150'; //x1
                details.lineY = utils.uint2str(rightY-3); //y1, y2
                details.lineX2 = '280'; //x2
                details.textY = utils.uint2str(rightY);
                details.textX = '290';
                details.textAnchor = 'end';
                y = rightY;

                rightY += diffRight;
            }

            if(indices[i][0] == 1) { // if the slot is assigned
                wordList = string.concat(wordList, 
                        singularAction(details, indices[i][1], indices[i][2], randomMint)
                );
            }
        }

        return wordList;
    }

    function singularAction(WordDetails memory details, uint256 rarity, uint256 wordIndex, bool randomMint) public view returns (string memory) {
        string memory dottedProp;
        string memory action;
        if(randomMint && rarity == 1) { // if a rare word
            action = rareActions[wordIndex];
            dottedProp = svg.prop('stroke-dasharray', '4'); 
        } else {
            action = actions[wordIndex];
        }
        return string.concat(
            svg.el('line', string.concat(svg.prop('x1', details.lineX1), svg.prop('y1', details.lineY), svg.prop('x2', details.lineX2), svg.prop('y2', details.lineY), svg.prop('stroke', 'black'), dottedProp)),
            svg.el('text', string.concat(
            svg.prop('text-anchor', details.textAnchor),
            svg.prop('x', details.textX),
            svg.prop('y', details.textY),
            svg.prop('font-family', 'Helvetica'),
            svg.prop('fill', 'black'),
            svg.prop('font-weight', 'bold'),
            svg.prop('font-size', '6'),
            svg.prop('filter', 'url(#solidTextBGFilter)')),
            action
        ));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './svg.sol';
import './utils.sol';

contract Definitions {
    /*PUBLIC*/
    function defs(bytes memory hash) public pure returns (string memory) {
        return string.concat(
            masks(),
            clipPaths(),
            filters(hash)
        );
    }
    /*MASKS*/
   function masks() internal pure returns (string memory) {
        return string.concat(
            svg.el('mask', svg.prop('id','cutoutMask'), 
                string.concat(
                    svg.whiteRect(),
                    svg.rect(string.concat(svg.prop('x','118'), svg.prop('y', '55'), svg.prop('width', '64'), svg.prop('height', '108'), svg.prop('ry', '30'), svg.prop('rx', '30'))),
                    svg.rect(string.concat(svg.prop('x','118'), svg.prop('y', '110'), svg.prop('width', '64'), svg.prop('height', '140'), svg.prop('ry', '30'), svg.prop('rx', '30')))
                )
            ),
            svg.el('mask', svg.prop('id','topReflectionMask'), 
                string.concat(
                    svg.whiteRect(),
                    svg.rect(string.concat(svg.prop('x','122'), svg.prop('y', '55'), svg.prop('width', '56'), svg.prop('height', '190'), svg.prop('ry', '30'), svg.prop('rx', '30'), svg.prop('fill', 'black')))
                )
            )
        );
    }

    /*CLIP-PATHS*/
    function clipPaths() internal pure returns (string memory) {
        return string.concat(
            svg.el('clipPath', svg.prop('id', 'clipBottom'),
                svg.rect(string.concat(svg.prop('height', '150'), svg.prop('width', '300')))
            ),
            svg.el('clipPath', svg.prop('id', 'clipShadow'),
                string.concat(
                    svg.rect(string.concat(svg.prop('y', '220'), svg.prop('height', '300'), svg.prop('width', '300'))),
                    svg.rect(string.concat(svg.prop('y', '180'), svg.prop('height', '300'), svg.prop('width', '115'))),
                    svg.rect(string.concat(svg.prop('y', '180'), svg.prop('x', '185'), svg.prop('height', '300'), svg.prop('width', '115')))
                )
            )
        );
    }

    /*FILTERS*/
    function filters(bytes memory hash) internal pure returns (string memory) {
        return string.concat(
            sandFilter(hash),
            svg.filter(
                string.concat(svg.prop('id','dropShadowFilter'), svg.prop('height', '300'), svg.prop('width', '300'), svg.prop('y', '-25%'), svg.prop('x', '-50%')),
                string.concat(
                    svg.el('feGaussianBlur', string.concat(svg.prop('in', 'SourceAlpha'), svg.prop('stdDeviation', '6'))),
                    svg.el('feOffset', svg.prop('dy', '8')),
                    svg.el('feComposite', string.concat(svg.prop('operator', 'out'), svg.prop('in2', 'SourceAlpha')))
                )
            ),
            fineSandFilter(hash),
            svg.filter(
                string.concat(svg.prop('id','solidTextBGFilter')),
                string.concat(
                    svg.el('feFlood', string.concat(svg.prop('flood-color', 'white'), svg.prop('result', 'bg'))),
                    svg.el('feMerge', '', string.concat(
                            svg.el('feMergeNode', svg.prop('in', 'bg')),
                            svg.el('feMergeNode', svg.prop('in', 'SourceGraphic'))
                        )
                    )
                )
            )
        );
    }

    /*INTERNALS*/
    function sandFilter(bytes memory hash) internal pure returns (string memory) {
        uint256 seed = utils.getSandSeed(hash);
        uint256 scale = utils.getSandScale(hash);
        uint256 octaves = utils.getSandOctaves(hash);
        return svg.filter(
                string.concat(svg.prop('id','sandFilter'), svg.prop('height', '800%'), svg.prop('y', '-250%')),
                string.concat(
                    svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', '0.01'), svg.prop('numOctaves', utils.uint2str(octaves)), svg.prop('seed', utils.uint2str(seed)), svg.prop('result', 'turbs'))),
                    svg.el('feDisplacementMap', string.concat(svg.prop('in2', 'turbs'), svg.prop('in', 'SourceGraphic'), svg.prop('scale', utils.uint2str(scale)), svg.prop('xChannelSelector', 'R'), svg.prop('yChannelSelector', 'G')))
                )
        );
    }

    function fineSandFilter(bytes memory hash) internal pure returns (string memory) {
        string memory redOffset;
        string memory greenOffset;
        string memory blueOffset;
        {
            redOffset = getColourOffset(hash, 0);
            greenOffset = getColourOffset(hash, 1);
            blueOffset = getColourOffset(hash, 2);
        }

        uint256 seed = utils.getFineSandSeed(hash);
        uint256 octaves = utils.getFineSandOctaves(hash);

        return svg.filter(
            svg.prop('id','fineSandFilter'),
            string.concat(
                fineSandfeTurbulence(seed, octaves),
                svg.el('feComponentTransfer', '', string.concat(
                    svg.el('feFuncR', string.concat(svg.prop('type', 'gamma'), svg.prop('offset', redOffset))),
                    svg.el('feFuncG', string.concat(svg.prop('type', 'gamma'), svg.prop('offset', greenOffset))),
                    svg.el('feFuncB', string.concat(svg.prop('type', 'gamma'), svg.prop('offset', blueOffset))),
                    svg.el('feFuncA', string.concat(svg.prop('type', 'linear'), svg.prop('intercept', '1')))
                ))
            )
        );
    }

    function fineSandfeTurbulence(uint256 seed, uint256 octaves) internal pure returns (string memory) {
        return svg.el('feTurbulence', string.concat(svg.prop('baseFrequency', '0.01'), svg.prop('numOctaves', utils.uint2str(octaves)), svg.prop('seed', utils.uint2str(seed)), svg.prop('result', 'turbs')));
    }

    function getColourOffset(bytes memory hash, uint256 offsetIndex) internal pure returns (string memory) {
        uint256 shift = utils.getColourOffsetShift(hash, offsetIndex); // 0 or 1. Positive or Negative
        uint256 change = utils.getColourOffsetChange(hash, offsetIndex); // 0 - 99 
        string memory sign = "";
        if(shift == 1) { sign = "-"; }
        return string(abi.encodePacked(
            sign, utils.generateDecimalString(change,1)
        ));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

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

    function whiteRect() internal pure returns (string memory) {
        return rect(
            string.concat(
                prop('width','100%'),
                prop('height', '100%'),
                prop('fill', 'white')
            )
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.

// modified from original to take away functions that I'm not using
// also includes the random number parser 
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

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function generateDecimalString(uint nr, uint decimals) internal pure returns (string memory) {
        if(decimals == 1) { return string(abi.encodePacked('0.', uint2str(nr))); }
        if(decimals == 2) { return string(abi.encodePacked('0.0', uint2str(nr))); }
        if(decimals == 3) { return string(abi.encodePacked('0.00', uint2str(nr))); }
        if(decimals == 4) { return string(abi.encodePacked('0.000', uint2str(nr))); }
    }

    // entropy carving
    // extrapolated into utils file in order to re-use between drawing + trait generation
    // 19 random variables
    function getAmount(bytes memory hash) internal pure returns (uint256) { return 2+uint256(toUint8(hash, 0))/16;  }  // 2 - 18
    function getRange(bytes memory hash) internal pure returns (uint256) { return 220 + uint256(toUint8(hash, 1))/4;  } // 180 - 240
    function getColour(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 2))*360/256;  } // 0 - 360
    function getColourShift(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 3));  } // 0 - 255
    function getSandSeed(bytes memory hash) internal pure returns (uint256) { return uint256(toUint8(hash, 4));  } 
    function getSandScale(bytes memory hash) internal pure returns (uint256) { return 1 + uint256(toUint8(hash, 5))/8;  } 
    function getSandOctaves(bytes memory hash) internal pure returns (uint256) {return 1 + uint256(toUint8(hash, 6))/64;  } 
    function getFineSandSeed(bytes memory hash) internal pure returns (uint256) {return uint256(toUint8(hash, 7)); } 
    function getFineSandOctaves(bytes memory hash) internal pure returns (uint256) {return 1 + uint256(toUint8(hash, 8))/64; } 
    function getColourOffsetShift(bytes memory hash, uint256 offsetIndex) internal pure returns (uint256) {
        
        if(offsetIndex == 0 ) { return uint256(toUint8(hash, 9))/128; } // red
        if(offsetIndex == 1 ) { return uint256(toUint8(hash, 10))/128; } // green
        if(offsetIndex == 2 ) { return uint256(toUint8(hash, 11))/128; } // blue
    } 
    function getColourOffsetChange(bytes memory hash, uint256 offsetIndex) internal pure returns (uint256) {

        if(offsetIndex == 0 ) { return uint256(toUint8(hash, 12))*100/256; } // red
        if(offsetIndex == 1 ) { return uint256(toUint8(hash, 13))*100/256; } // green
        if(offsetIndex == 2 ) { return uint256(toUint8(hash, 14))*100/256; } // blue
    } 
    function getLeftY(bytes memory hash) internal pure returns (uint256) {return 100+uint256(toUint8(hash, 15))/16; } 
    function getRightY(bytes memory hash) internal pure returns (uint256) {return 100+uint256(toUint8(hash, 16))/16; } 
    function getDiffLeft(bytes memory hash) internal pure returns (uint256) {return 10+uint256(toUint8(hash, 17))/16; } 
    function getDiffRight(bytes memory hash) internal pure returns (uint256) {return 10+uint256(toUint8(hash, 18))/16; } 

    function getIndices(bytes memory hash, bool randomMint) internal pure returns (uint256 _rareCount, uint256 _allCount, uint256[3][10] memory) {
        uint256[3][10] memory indices; // solidity's array assignents are reversed.
        // 0 -> assigned slot or not (0 or 1)
        // 1 -> rare word or not (0 or 1)
        // 2 -> index in word list (default list (0-52) or rare list (0-31))
        uint256 allCount;
        uint256 rareCount;

        uint leftY = getLeftY(hash);
        uint rightY = getRightY(hash);
        uint diffLeft = getDiffLeft(hash);
        uint diffRight = getDiffRight(hash);

        for(uint i = 0; i < 10; i+=1) {
            uint y;
            if(i % 2 == 0) {
                y = leftY;
                leftY += diffLeft;
            } else {
                y = rightY;
                rightY += diffRight;
            }
            if((y+i) % 4 == 0) { // 1 in 4 chance for an experience to be shown
                uint256 entropy = uint256(toUint8(hash, 19+i));
                uint256[3] memory IS;
                IS[0] = 1; // assigned slot (0 or 1)
                // default for IS[0] is 0, so don't have to assign it
                if(randomMint && (y+i+entropy) % 3 == 0) { // if its a random mint, the action has 1/3 chance of being rare
                    IS[1] = 1; // it's a rare word/action
                    IS[2] = entropy*33/256; // index in rare actions list
                    rareCount+=1;
                } else {
                    // don't have to assign IS[1] because it's 0 on default
                    IS[2] = entropy*62/256; // index in actions list
                }
                indices[i] = IS;
                allCount+=1; 
            } 
        }

        return (rareCount, allCount, indices);
    }
}