// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**************************************************
 *
 *                       . . . .
 *                       ,`,`,`,`,
 * . . . .               `\`\`\`\;
 * `\`\`\`\`,            ~|;!;!;\!
 *  ~\;\;\;\|\          (--,!!!~`!       .
 * (--,\\\===~\         (--,|||~`!     ./
 *  (--,\\\===~\         `,-,~,=,:. _,//
 *   (--,\\\==~`\        ~-=~-.---|\;/J,
 *    (--,\\\((```==.    ~'`~/       a |
 *      (-,.\\('('(`\\.  ~'=~|     \_.  \
 *         (,--(,(,(,'\\. ~'=|       \\_;>
 *           (,-( ,(,(,;\\ ~=/        \
 *           (,-/ (.(.(,;\\,/          )
 *            (,--/,;,;,;,\\         ./------.
 *              (==,-;-'`;'         /_,----`. \
 *      ,.--_,__.-'                    `--.  ` \
 *     (='~-_,--/        ,       ,!,___--. \  \_)
 *    (-/~(     |         \   ,_-         | ) /_|
 *    (~/((\    )\._,      |-'         _,/ /
 *     \\))))  /   ./~.    |           \_\;
 *  ,__/////  /   /    )  /
 *   '===~'   |  |    (, <.
 *            / /       \. \
 *          _/ /          \_\
 *         /_!/            >_\
 * ------------------------------------------------
 *
 * Unifriends NFT
 * https://unifriends.io
 * Developed By: @sbmitchell.eth
 *
 **************************************************/

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";
import "./UnifriendsRenderer.sol";
import "./ERC721Enumerable.sol";

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Unifriends is ERC721Enumerable, Ownable {
    using UnifriendsRenderer for *;

    string constant NAME = "Unifriends";
    string constant SYMBOL = "Unifriends";
    uint256 public constant MAX_PER_TX = 11;

    uint256 public constant whitelistPriceInWei = 0.069420 ether;
    uint256 public publicPriceInWei = 0.1337 ether;

    string public baseURI;
    string public animationURI;
    address public proxyRegistryAddress;
    address public treasury;
    bytes32 public whitelistMerkleRoot;
    uint256 public maxSupply;
    uint256 public reserves = 251;
    uint256 mintNonce = 0;
    bool public isRevealed = false;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    constructor(
        string memory _baseURI,
        string memory _animationURI,
        address _proxyRegistryAddress,
        address _treasury
    ) ERC721(NAME, SYMBOL) {
        baseURI = _baseURI;
        animationURI = _animationURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        treasury = payable(_treasury);
    }

    /*
        Derives a leaf node for the merkle tree which aligns w/ the algorithm off-chain to derive merkle root
    */
    function _toLeaf(address _address, uint256 _allowance)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    string(abi.encodePacked(_address)),
                    Strings.toString(_allowance)
                )
            );
    }

    /*
       Mint a unifriend NFT w/ pseudo-randomness

       - Basis mint was 53k gas but added seeds mapping which increased gas to ~80-85k
       - Chainlink VRF was initially implemented but drove mint costs from 80k -> 170k gas which we found unacceptable for this use case
         Note: We will use provably random in longer lasting contracts involving game mechanics
       - `tokenIdToRandomNumber` stores a random number to tokenId to use a basis for tokenURI rendering

       Avg gas limit for public mint ~85-90k
       Avg gas limit for whitelist mint ~120k due to merkle proof
    */
    function _mint(address to, uint256 tokenId) internal virtual override {
        require(!_exists(tokenId), "Token already minted");
        mintNonce++;
        _owners.push(to);
        tokenIdToRandomNumber[tokenId] = pseudorandom(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    function setPublicPriceInWei(uint256 _publicPriceInWei) public onlyOwner {
        publicPriceInWei = _publicPriceInWei;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    function setReserves(uint256 _reserves) public onlyOwner {
        reserves = _reserves;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function toggleRevealed() public onlyOwner {
        isRevealed = !isRevealed;
    }

    function setAnimationURI(string memory _animationURI) public onlyOwner {
        animationURI = _animationURI;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function togglePublicSale(uint256 _maxSupply) external onlyOwner {
        delete whitelistMerkleRoot;
        maxSupply = _maxSupply;
    }

    function preRevealMetadata() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                UnifriendsRenderer.toJSONProperty(
                                    "name",
                                    "Hidden"
                                ),
                                ",",
                                '"attributes": []',
                                ",",
                                UnifriendsRenderer.toJSONProperty(
                                    "image",
                                    baseURI
                                ),
                                ",",
                                UnifriendsRenderer.toJSONProperty(
                                    "external_url",
                                    baseURI
                                ),
                                ",",
                                UnifriendsRenderer.toJSONProperty(
                                    "animation_url",
                                    baseURI
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*
        Derived on-chain metadata based on randomness seed
        Returns a base64 encoded json string
        `image` asset will still live in IPFS based on `baseURI` set
        `attributes` are derived based on seed within the `UnifriendsRenderer` library
    */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");

        if (!isRevealed) {
            return preRevealMetadata();
        }

        return
            UnifriendsRenderer.base64TokenURI(
                tokenId,
                baseURI,
                animationURI,
                tokenIdToRandomNumber[tokenId]
            );
    }

    /*
       Founder and legendary collection
       Can only run before whitelist sale
       First 10 -> legndaries which will be distributed via DAO or as giveaways
       10-110 -> Giveaways/Gifted NFTs for first 100 based on collabs and discord contests
       110-250 -> Team, mods, etc
    */
    function collectReserves(uint256 amount) external onlyOwner {
        require(_owners.length + amount < reserves, "Reserves already taken.");
        uint256 totalSupply = _owners.length;
        for (uint256 i = 0; i < amount; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    /*
       Whitelist sale - only valid with merkle tree root set
       Avg gas limit for public mint ~120k-130k due to merkle proof
    */
    function whitelistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable {
        require(
            count * whitelistPriceInWei == msg.value,
            "Invalid funds provided."
        );

        require(
            MerkleProof.verify(
                proof,
                whitelistMerkleRoot,
                _toLeaf(_msgSender(), allowance)
            ),
            "Invalid Merkle Tree proof supplied."
        );

        require(
            addressToMinted[_msgSender()] + count <= allowance,
            "Exceeds whitelist supply."
        );

        addressToMinted[_msgSender()] += count;

        uint256 totalSupply = _owners.length;

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    /*
       Public sale - only valid after whitelist sale is complete
       Avg gas limit for public mint ~85-90k
    */
    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;

        require(totalSupply + count < maxSupply, "Excedes max supply.");

        require(count < MAX_PER_TX, "Exceeds max per transaction.");

        require(
            count * publicPriceInWei == msg.value,
            "Invalid funds provided."
        );

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to treasury.");
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    /*
       OS Pre-approvals and future project integration approvals for extensibility
    */
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );

        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;

        return super.isApprovedForAll(_owner, operator);
    }

    /*
     * Random enough for all intents and purposes of this NFT
     * I would be more concerned if it were more of a recurring lottery.
     */
    function pseudorandom(address to, uint256 tokenId)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        to,
                        Strings.toString(mintNonce),
                        Strings.toString(tokenId)
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
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

pragma solidity ^0.8.9;

/**************************************************
 *
 * Unifriends NFT
 * https://unifriends.io
 * Developed By: @sbmitchell.eth
 *
 **************************************************/

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

library UnifriendsRenderer {
    struct Traits {
        string wearable;
        string skin;
        string item;
        string horn;
        string hair;
        string eyes;
        string background;
    }

    struct Unifriend {
        uint256 strength;
        uint256 speed;
        uint256 intelligence;
        string name;
        string description;
        bool isLegendary;
        Traits trait;
    }

    function toJSONProperty(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', key, '" : "', value, '"'));
    }

    function getLegendary(uint256 tokenId)
        internal
        pure
        returns (Unifriend memory)
    {
        Traits memory trait;

        if (tokenId == 0) {
            return
                Unifriend({
                    strength: 92,
                    speed: 92,
                    intelligence: 98,
                    name: "Dr. X",
                    description: "Dr. X is pure evil. The antithesis of the genesis unicorns and Unifriends. The meticulous planning with unparalleled genius make Dr. X a complex and difficult adversary for the Unifriends.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 1) {
            return
                Unifriend({
                    strength: 90,
                    speed: 99,
                    intelligence: 91,
                    name: "Cyber Pegasus",
                    description: "They got a second chance at life. From not being able to walk or fly they have beccome the fastest wings in the entire metaverse.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 2) {
            return
                Unifriend({
                    strength: 94,
                    speed: 93,
                    intelligence: 95,
                    name: "Uni-Force General",
                    description: "A strategic and battle-hardened unifriend. The General protects the metaverse and ensures stability.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 3) {
            return
                Unifriend({
                    strength: 94,
                    speed: 93,
                    intelligence: 97,
                    name: "King Bastion",
                    description: "King Bastion is the oldest and wisest unifriend in the galaxy. Always in gold he shines and rules the metaverse.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 4) {
            return
                Unifriend({
                    strength: 92,
                    speed: 93,
                    intelligence: 96,
                    name: "Queen Bastion",
                    description: "Queen Bastion is the smartest unifriend in the metaverse. Her unique kinetic aura keeps the metaverse at peace.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 5) {
            return
                Unifriend({
                    strength: 94,
                    speed: 93,
                    intelligence: 92,
                    name: "Mutated Uni",
                    description: "This unifriend was engulfed by toxic slime during an epic battle. They emerged out of a cocoon as a mutated unicorn.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 6) {
            return
                Unifriend({
                    strength: 98,
                    speed: 96,
                    intelligence: 95,
                    name: "Shadow Uni",
                    description: "The darkest unicorn in the metaverse. A black hole dweller, isolated, but free.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 7) {
            return
                Unifriend({
                    strength: 93,
                    speed: 93,
                    intelligence: 93,
                    name: "Uni Bot",
                    description: "He is mech robot of the metaverse. Cunning intellect and perfect posture.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 8) {
            return
                Unifriend({
                    strength: 95,
                    speed: 93,
                    intelligence: 92,
                    name: "Experiment 73",
                    description: "An escapee from Dr. X's lab. They are one of the strongest and most devious inhabitors of he metaverse.",
                    isLegendary: true,
                    trait: trait
                });
        } else if (tokenId == 9) {
            return
                Unifriend({
                    strength: 93,
                    speed: 97,
                    intelligence: 94,
                    name: "Spurr",
                    description: "The loner that's never around. Her name is Spurr, she is fast, witted and always secretly up to no good.",
                    isLegendary: true,
                    trait: trait
                });
        }
    }

    function getUnifriendProperties(uint256 tokenId, uint256 randomness)
        internal
        pure
        returns (Unifriend memory)
    {
        // 10 Legendaries
        if (tokenId < 10) {
            return getLegendary(tokenId);
        } else {
            Traits memory trait;

            string[356] memory GROUPS = [
                // WEARABLES - 44
                // Common 4x
                // 28
                "Bandana",
                "Bandana",
                "Bandana",
                "Bandana",
                "Dog Collar Red",
                "Dog Collar Red",
                "Dog Collar Red",
                "Dog Collar Blue",
                "Dog Collar Blue",
                "Dog Collar Blue",
                "Neon Collar Pink",
                "Neon Collar Pink",
                "Neon Collar Pink",
                "Glass Collar",
                "Glass Collar",
                "Glass Collar",
                "Chain Collar",
                "Chain Collar",
                "Chain Collar",
                "Spiked Chain Collar",
                "Spiked Chain Collar",
                "Spiked Chain Collar",
                "Tshirt Red",
                "Tshirt Red",
                "Tshirt Red",
                "Vynil Bandana",
                "Vynil Bandana",
                "Vynil Bandana",
                // Rare 2x
                // 12
                "Tactical Vest",
                "Tactical Vest",
                "Gold Collar",
                "Gold Collar",
                "Tshirt Blue",
                "Tshirt Blue",
                "Chalk Collar",
                "Chalk Collar",
                "Neon Collar Green",
                "Neon Collar Green",
                "Spiked Collar Purple",
                "Spiked Collar Purple",
                // Super Rare 1x
                // 4
                "Headphones",
                "Headphones Red",
                "Cyberpunk Collar",
                "Tactical Vest Red",
                // ITEMS - 55
                // Common 4x
                // 40
                "Fishing Rod",
                "Fishing Rod",
                "Fishing Rod",
                "Fishing Rod",
                "Mug",
                "Mug",
                "Mug",
                "Mug",
                "Dumbell",
                "Dumbell",
                "Dumbell",
                "Dumbell",
                "Camera",
                "Camera",
                "Camera",
                "Camera",
                "Keyboard",
                "Keyboard",
                "Keyboard",
                "Keyboard",
                "Football",
                "Football",
                "Football",
                "Football",
                "Pencil and Paper",
                "Pencil and Paper",
                "Pencil and Paper",
                "Pencil and Paper",
                "Phone",
                "Phone",
                "Phone",
                "Phone",
                "Soccer Ball",
                "Soccer Ball",
                "Soccer Ball",
                "Soccer Ball",
                "Tablet",
                "Tablet",
                "Tablet",
                "Tablet",
                // Rare 2x
                // 12
                "Popcorn",
                "Popcorn",
                "Test Tube",
                "Test Tube",
                "Glizzy",
                "Glizzy",
                "Laptop",
                "Laptop",
                "Selfie Stick",
                "Selfie Stick",
                "Spray Can",
                "Spray Can",
                // Super Rare 1x
                // 3
                "Drone",
                "Controller",
                "Sword",
                // SKINS - 71
                // Common 3x
                // 48
                "Concrete Black Skin",
                "Concrete Black Skin",
                "Concrete Black Skin",
                "Black Skin",
                "Black Skin",
                "Black Skin",
                "Brown Skin",
                "Brown Skin",
                "Brown Skin",
                "Gold Skin",
                "Gold Skin",
                "Gold Skin",
                "Dino Red Skin",
                "Dino Red Skin",
                "Dino Red Skin",
                "Purple Skin",
                "Purple Skin",
                "Purple Skin",
                "Yellow Skin",
                "Yellow Skin",
                "Yellow Skin",
                "White Skin",
                "White Skin",
                "White Skin",
                "Vortex Skin",
                "Vortex Skin",
                "Vortex Skin",
                "Pastel Yellow Skin",
                "Pastel Yellow Skin",
                "Pastel Yellow Skin",
                "Pastel Blue Skin",
                "Pastel Blue Skin",
                "Pastel Blue Skin",
                "Pastel Green Skin",
                "Pastel Green Skin",
                "Pastel Green Skin",
                "Pastel Red Skin",
                "Pastel Red Skin",
                "Pastel Red Skin",
                "Vynil Orange Skin",
                "Vynil Orange Skin",
                "Vynil Orange Skin",
                "Vynil Mint Skin",
                "Vynil Mint Skin",
                "Vynil Mint Skin",
                "Chalk Light Pink Skin",
                "Chalk Light Pink Skin",
                "Chalk Light Pink Skin",
                // Rare 2x
                // 18
                "Plasma Skin",
                "Plasma Skin",
                "Blue Titanium Skin",
                "Blue Titanium Skin",
                "Robot Skin",
                "Robot Skin",
                "Dino Green Skin",
                "Dino Green Skin",
                "Silver Skin",
                "Silver Skin",
                "Kaiju Skin",
                "Kaiju Skin",
                "Moon Rock Skin",
                "Moon Rock Skin",
                "Chalk Light Blue Skin",
                "Chalk Light Blue Skin",
                "Pastel Pink Skin",
                "Pastel Pink Skin",
                // Super Rare 1x
                // 5
                "Glass Skeleton Skin",
                "Zebra Skin",
                "Camo Skin",
                "Poison Frog Skin",
                "Martian Skin",
                // HORNS - 58
                // Common 4x
                // 36
                "Spring Horn",
                "Spring Horn",
                "Spring Horn",
                "Spring Horn",
                "White Horn",
                "White Horn",
                "White Horn",
                "White Horn",
                "Broken Horn",
                "Broken Horn",
                "Broken Horn",
                "Broken Horn",
                "Chain Horn",
                "Chain Horn",
                "Chain Horn",
                "Chain Horn",
                "Lollipop Horn",
                "Lollipop Horn",
                "Lollipop Horn",
                "Lollipop Horn",
                "Drill Horn",
                "Drill Horn",
                "Drill Horn",
                "Drill Horn",
                "Slime Horn",
                "Slime Horn",
                "Slime Horn",
                "Slime Horn",
                "Chalk Horn",
                "Chalk Horn",
                "Chalk Horn",
                "Chalk Horn",
                "Striped Metallic Horn",
                "Striped Metallic Horn",
                "Striped Metallic Horn",
                "Striped Metallic Horn",
                // Rare 2x
                // 16
                "Gold Horn",
                "Gold Horn",
                "Cucumber Horn",
                "Cucumber Horn",
                "Carrot Horn",
                "Carrot Horn",
                "Candy Cane Horn",
                "Candy Cane Horn",
                "Tesla Horn",
                "Tesla Horn",
                "Pencil Horn",
                "Pencil Horn",
                "Donut Horn",
                "Donut Horn",
                "Rainbow Horn",
                "Rainbow Horn",
                // Super Rare 1x
                // 6
                "Antler Horn",
                "Cyberpunk Horn",
                "Ethereum Horn",
                "Mech Horn",
                "Tri Horn",
                "Invisible Horn",
                // HAIR - 49
                // Common 4x
                // 36
                "Black Hair",
                "Black Hair",
                "Black Hair",
                "Black Hair",
                "White Hair",
                "White Hair",
                "White Hair",
                "White Hair",
                "Blue Hair",
                "Blue Hair",
                "Blue Hair",
                "Blue Hair",
                "Green Hair",
                "Green Hair",
                "Green Hair",
                "Green Hair",
                "Burgundy Hair",
                "Burgundy Hair",
                "Burgundy Hair",
                "Burgundy Hair",
                "Red Hair",
                "Red Hair",
                "Red Hair",
                "Red Hair",
                "Pastel Pink Hair",
                "Pastel Pink Hair",
                "Pastel Pink Hair",
                "Pastel Pink Hair",
                "Plastic Hair",
                "Plastic Hair",
                "Plastic Hair",
                "Plastic Hair",
                "Silver Hair",
                "Silver Hair",
                "Silver Hair",
                "Silver Hair",
                // Rare 2x
                // 10
                "Glass Hair",
                "Glass Hair",
                "Chalk Blue Hair",
                "Chalk Blue Hair",
                "Chalk Pink Hair",
                "Chalk Pink Hair",
                "Punk Hair",
                "Punk Hair",
                "Solid Gold Hair",
                "Solid Gold Hair",
                // Super Rare 1x
                // 3
                "Flames Hair",
                "Glowing Hair",
                "Funky Hair",
                // EYES - 35
                // Common 4x
                // 24
                "Standard Eyes",
                "Standard Eyes",
                "Standard Eyes",
                "Standard Eyes",
                "Chalk Eyes",
                "Chalk Eyes",
                "Chalk Eyes",
                "Chalk Eyes",
                "Metallic Eyes",
                "Metallic Eyes",
                "Metallic Eyes",
                "Metallic Eyes",
                "Glowing Eyes",
                "Glowing Eyes",
                "Glowing Eyes",
                "Glowing Eyes",
                "Black Eyes",
                "Black Eyes",
                "Black Eyes",
                "Black Eyes",
                "Gold Eyes",
                "Gold Eyes",
                "Gold Eyes",
                "Gold Eyes",
                // Rare 2x
                // 8
                "Sunglasses",
                "Sunglasses",
                "Blue Laser Eyes",
                "Blue Laser Eyes",
                "Futuristic Shades",
                "Futuristic Shades",
                "Robot Eyes",
                "Robot Eyes",
                // Super Rare 1x
                // 3
                "VR Headset",
                "Night Vision",
                "Pink Laser Eyes",
                // BACKGROUNDS - 44
                // Common 3x
                // 27
                "Purple",
                "Purple",
                "Purple",
                "Blue",
                "Blue",
                "Blue",
                "Red",
                "Red",
                "Red",
                "Yellow",
                "Yellow",
                "Yellow",
                "Dark",
                "Dark",
                "Dark",
                "Sky",
                "Sky",
                "Sky",
                "Chalk",
                "Chalk",
                "Chalk",
                "Green Pattern",
                "Green Pattern",
                "Green Pattern",
                "Blue Pattern",
                "Blue Pattern",
                "Blue Pattern",
                // Rare 2x
                // 14
                "Forest",
                "Forest",
                "Glacier",
                "Glacier",
                "Spring",
                "Spring",
                "Void",
                "Void",
                "Marsh",
                "Marsh",
                "Rainbow",
                "Rainbow",
                "Red Pattern",
                "Red Pattern",
                // Super Rare 1x
                // 3
                "Volcano",
                "Cyberpunk",
                "Space"
            ];

            uint256 cursor = 44;

            // 19 Wearables
            trait.wearable = GROUPS[
                ((randomness % 100000000) / 1000000) % cursor
            ];

            // 20 Items
            trait.item = GROUPS[
                (cursor + (((randomness % 10000000000) / 100000000) % 55))
            ];

            cursor += 55;

            // 29 Skins
            trait.skin = GROUPS[
                (cursor + (((randomness % 1000000000000) / 10000000000) % 71))
            ];

            cursor += 71;

            // 22 Horns
            trait.horn = GROUPS[
                (cursor +
                    (((randomness % 100000000000000) / 1000000000000) % 58))
            ];

            cursor += 58;

            // 17 Hairs
            trait.hair = GROUPS[
                (cursor +
                    (((randomness % 10000000000000000) / 100000000000000) % 49))
            ];

            cursor += 49;

            // 13 Eyes
            trait.eyes = GROUPS[
                (cursor +
                    (((randomness % 1000000000000000000) / 10000000000000000) %
                        35))
            ];

            cursor += 35;

            // 19 Backgrounds
            trait.background = GROUPS[
                (cursor +
                    (((randomness % 100000000000000000000) /
                        1000000000000000000) % 44))
            ];

            uint256 strength = 41 + (randomness % 50);
            uint256 speed = 41 + (((randomness % 10000) / 100) % 50);
            uint256 intelligence = 41 + (((randomness % 1000000) / 10000) % 50);

            return
                Unifriend({
                    strength: strength,
                    speed: speed,
                    intelligence: intelligence,
                    name: string(
                        abi.encodePacked(
                            "Genesis Unicorn: #",
                            Strings.toString(tokenId)
                        )
                    ),
                    description: string(
                        abi.encodePacked(
                            "The Unifriends metaverse began with the genesis unicorns. **#",
                            Strings.toString(tokenId),
                            "** is very special and one-of-a-kind. The unicorns have unparalleled purity and grace.",
                            "<br>Your unicorn has **",
                            Strings.toString(strength),
                            "** strength, **",
                            Strings.toString(speed),
                            "** speed, and **",
                            Strings.toString(intelligence),
                            "** intelligence."
                        )
                    ),
                    isLegendary: false,
                    trait: trait
                });
        }
    }

    function toProperties(Unifriend memory instance)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type": "Legendary", "value": "',
                    instance.isLegendary ? "true" : "false",
                    '"}',
                    ', { "trait_type": "Strength", "display_type": "number", "value": "',
                    Strings.toString(instance.strength),
                    '"}',
                    ', { "trait_type": "Speed", "display_type": "number", "value": "',
                    Strings.toString(instance.speed),
                    '"}',
                    ', { "trait_type": "Intelligence", "display_type": "number", "value": "',
                    Strings.toString(instance.intelligence),
                    '"}'
                )
            );
    }

    function toTraits(Unifriend memory instance)
        internal
        pure
        returns (string memory)
    {
        if (instance.isLegendary) {
            return "";
        }

        return
            string(
                abi.encodePacked(
                    ', { "trait_type": "Wearable", "value": "',
                    instance.trait.wearable,
                    '"}',
                    ', { "trait_type": "Item", "value": "',
                    instance.trait.item,
                    '"}',
                    ', { "trait_type": "Horn", "value": "',
                    instance.trait.horn,
                    '"}',
                    ', { "trait_type": "Skin", "value": "',
                    instance.trait.skin,
                    '"}',
                    ', { "trait_type": "Hair", "value": "',
                    instance.trait.hair,
                    '"}',
                    ', { "trait_type": "Eyes", "value": "',
                    instance.trait.eyes,
                    '"}',
                    ', { "trait_type": "Background", "value": "',
                    instance.trait.background,
                    '"}'
                )
            );
    }

    function base64TokenURI(
        uint256 tokenId,
        string memory _baseURI,
        string memory _animationURI,
        uint256 _randomness
    ) public pure returns (string memory) {
        Unifriend memory instance = getUnifriendProperties(
            tokenId,
            _randomness
        );

        // Base64 encoding
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                toJSONProperty("name", instance.name),
                                ",",
                                toJSONProperty(
                                    "description",
                                    instance.description
                                ),
                                ",",
                                string(
                                    abi.encodePacked(
                                        '"attributes": ',
                                        string(
                                            abi.encodePacked(
                                                "[",
                                                string(
                                                    abi.encodePacked(
                                                        toProperties(instance),
                                                        toTraits(instance)
                                                    )
                                                ),
                                                "]"
                                            )
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "image",
                                    string(
                                        abi.encodePacked(
                                            _baseURI,
                                            Strings.toString(tokenId)
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            _animationURI,
                                            Strings.toString(tokenId)
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            _animationURI,
                                            Strings.toString(tokenId)
                                        )
                                    )
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account but rips out the core of the gas-wasting processing that comes from OpenZeppelin.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < _owners.length, "ERC721Enumerable: global index out of bounds");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint count;
        for(uint i; i < _owners.length; i++){
            if(owner == _owners[i]){
                if(count == index) return i;
                else count++;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./Address.sol";

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count;
        for( uint i; i < _owners.length; ++i ){
          if( owner == _owners[i] )
            ++count;
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        _owners.push(to);

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

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

pragma solidity ^0.8.9;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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