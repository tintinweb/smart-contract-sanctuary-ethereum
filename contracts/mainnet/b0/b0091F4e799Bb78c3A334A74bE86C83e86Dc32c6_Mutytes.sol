// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * #######################################   ######################################
 * #####################################       ####################################
 * ###################################           ##################################
 * #################################               ################################
 * ################################################################################
 * ################################################################################
 * ################       ####                           ###        ###############
 * ################      ####        #############        ####      ###############
 * ################     ####          ###########          ####     ###############
 * ################    ###     ##       #######       ##    ####    ###############
 * ################  ####    ######      #####      ######    ####  ###############
 * ################ ####                                       #### ###############
 * ####################                #########                ###################
 * ################                     #######                     ###############
 * ################   ###############             ##############   ################
 * #################   #############               ############   #################
 * ###################   ##########                 ##########   ##################
 * ####################    #######                   #######    ###################
 * ######################     ###                     ###    ######################
 * ##########################                             #########################
 * #############################                       ############################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 *
 * The Mutytes have invaded Ethernia! We hereby extend access to the lab and
 * its facilities to any individual or party that may locate and retrieve a
 * Mutyte sample. We believe their mutated Bit Signatures hold the key to
 * unraveling many great mysteries.
 * Join our efforts in understanding these creatures and witness Ethernia's
 * future unfold.
 *
 * Founders: @nftyte & @tuyumoo
 */

import "./token/ERC721GeneticData.sol";
import "./access/Reservable.sol";
import "./access/ProxyOperated.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./mutations/IMutationInterpreter.sol";

interface ILabArchive {
    function getMutyteInfo(uint256 tokenId)
        external
        view
        returns (string memory name, string memory info);

    function getMutationInfo(uint256 mutationId)
        external
        view
        returns (string memory name, string memory info);
}

interface IBineticSplicer {
    function getSplices(uint256 tokenId)
        external
        view
        returns (uint256[] memory);
}

contract Mutytes is
    ERC721GeneticData,
    IERC721Metadata,
    Reservable,
    ProxyOperated
{
    string constant NAME = "Mutytes";
    string constant SYMBOL = "TYTE";
    uint256 constant MINT_PER_ADDR = 10;
    uint256 constant MINT_PER_ADDR_EQ = MINT_PER_ADDR + 1; // Skip the equator
    uint256 constant MINT_PRICE = 0.1 ether;

    address public labArchiveAddress;
    address public bineticSplicerAddress;
    string public externalURL;

    constructor(
        string memory externalURL_,
        address interpreter,
        address proxyRegistry,
        uint8 reserved
    )
        Reservable(reserved)
        ProxyOperated(proxyRegistry)
        MutationRegistry(interpreter)
    {
        externalURL = externalURL_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(uint256 count) external payable {
        uint256 id = maxSupply;

        require(id > 0, "Mutytes: public mint not open");

        require(
            id + count < MAX_SUPPLY_EQ - reserved,
            "Mutytes: amount exceeds available supply"
        );

        require(
            count > 0 && _getBalance(_msgSender()) + count < MINT_PER_ADDR_EQ,
            "Mutytes: invalid token count"
        );

        require(
            msg.value == count * MINT_PRICE,
            "Mutytes: incorrect amount of ether sent"
        );

        _mint(_msgSender(), id, count);
    }

    function mintReserved(uint256 count) external fromAllowance(count) {
        _mint(_msgSender(), maxSupply, count);
    }

    function setLabArchiveAddress(address archive) external onlyOwner {
        labArchiveAddress = archive;
    }

    function setBineticSplicerAddress(address splicer) external onlyOwner {
        bineticSplicerAddress = splicer;
    }

    function setExternalURL(string calldata url) external onlyOwner {
        externalURL = url;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public pure override returns (string memory) {
        return NAME;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public pure override returns (string memory) {
        return SYMBOL;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        uint256 mutationId = getTokenMutation(tokenId);
        IMutationInterpreter interpreter = IMutationInterpreter(
            getMutation(mutationId).interpreter
        );
        IMutationInterpreter.TokenData memory token;
        token.id = tokenId;
        IMutationInterpreter.MutationData memory mutation;
        mutation.id = mutationId;
        mutation.count = _countTokenMutations(tokenId);

        if (bineticSplicerAddress != address(0)) {
            IBineticSplicer splicer = IBineticSplicer(bineticSplicerAddress);
            token.dna = getTokenDNA(tokenId, splicer.getSplices(tokenId));
        } else {
            token.dna = getTokenDNA(tokenId);
        }

        if (labArchiveAddress != address(0)) {
            ILabArchive archive = ILabArchive(labArchiveAddress);
            (token.name, token.info) = archive.getMutyteInfo(tokenId);
            (mutation.name, mutation.info) = archive.getMutationInfo(
                mutationId
            );
        }

        return interpreter.tokenURI(token, mutation, externalURL);
    }

    function burn(uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
        _burn(tokenId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721Enumerable, IERC721)
        returns (bool)
    {
        return
            _isProxyApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function withdraw() public payable onlyOwner {
        (bool owner, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(owner, "Mutytes: withdrawal failed");
    }

    function _mint(
        address to,
        uint256 tokenId,
        uint256 count
    ) private {
        uint256 inventory = _getOrSubscribeInventory(to);
        bytes32 dna;

        unchecked {
            uint256 max = tokenId + count;
            while (tokenId < max) {
                if (dna == 0) {
                    dna = keccak256(
                        abi.encodePacked(
                            tokenId,
                            inventory,
                            block.number,
                            block.difficulty,
                            reserved
                        )
                    );
                }
                _tokenToInventory[tokenId] = uint16(inventory);
                _tokenBaseGenes[tokenId] = uint64(bytes8(dna));
                dna <<= 64;

                emit Transfer(address(0), to, tokenId++);
            }
        }

        _increaseBalance(to, count);
        maxSupply = tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721GeneticData.sol";
import "../mutations/MutationRegistry.sol";

/**
 * @dev An ERC721 extension that provides access to storage and expansion of token information.
 * Initial data is stored in the base genes map. Newly introduced data will be stored in the extended genes map.
 * Token information may be extended whenever a token unlocks new mutations from the mutation registry.
 * Mutation catalysts may forcefully unlock or cause mutations.
 * Implementation inspired by nftchance's Mimetic Metadata concept.
 */
abstract contract ERC721GeneticData is
    ERC721Enumerable,
    MutationRegistry,
    IERC721GeneticData
{
    // Mapping from token ID to base genes
    uint64[MAX_SUPPLY] internal _tokenBaseGenes;

    // Mapping from token ID to extended genes
    uint8[][MAX_SUPPLY] private _tokenExtendedGenes;

    // Mapping from token ID to active mutation
    uint8[MAX_SUPPLY] private _tokenMutation;

    // Mapping from token ID to unlocked mutations
    bool[MAX_MUTATIONS][MAX_SUPPLY] public tokenUnlockedMutations;

    // List of mutation catalysts
    mapping(address => bool) public mutationCatalysts;

    modifier onlyMutationCatalyst() {
        require(
            mutationCatalysts[_msgSender()],
            "ERC721GeneticData: caller is not catalyst"
        );
        _;
    }

    /**
     * @dev Returns the token's active mutation.
     */
    function getTokenMutation(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (uint256)
    {
        return _tokenMutation[tokenId];
    }

    /**
     * @dev Returns the token's DNA sequence.
     */
    function getTokenDNA(uint256 tokenId)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory splices;
        return getTokenDNA(tokenId, splices);
    }

    /**
     * @dev Returns the token's DNA sequence.
     * @param splices DNA customizations to apply
     */
    function getTokenDNA(uint256 tokenId, uint256[] memory splices)
        public
        view
        override
        tokenExists(tokenId)
        returns (uint256[] memory)
    {
        uint8[] memory genes = _tokenExtendedGenes[tokenId];
        uint256 geneCount = genes.length;
        uint256 spliceCount = splices.length;
        uint256[] memory dna = new uint256[](geneCount + 1);
        dna[0] = uint256(keccak256(abi.encodePacked(_tokenBaseGenes[tokenId])));

        for (uint256 i; i < geneCount; i++) {
            // Expand genes and add to DNA sequence
            dna[i + 1] = uint256(keccak256(abi.encodePacked(dna[i], genes[i])));

            // Splice previous genes
            if (i < spliceCount) {
                dna[i] ^= splices[i];
            }
        }

        // Splice final genes
        if (spliceCount == geneCount + 1) {
            dna[geneCount] ^= splices[geneCount];
        }

        return dna;
    }

    /**
     * @dev Gets the number of unlocked token mutations.
     */
    function countTokenMutations(uint256 tokenId)
        external
        view
        override
        tokenExists(tokenId)
        returns (uint256)
    {
        return _countTokenMutations(tokenId);
    }

    /**
     * @dev Checks whether the token has unlocked a mutation.
     * note base mutation is always unlocked.
     */
    function isMutationUnlocked(uint256 tokenId, uint256 mutationId)
        external
        view
        override
        tokenExists(tokenId)
        mutationExists(mutationId)
        returns (bool)
    {
        return _isMutationUnlocked(tokenId, mutationId);
    }

    /**
     * @dev Checks whether the token can mutate to a mutation safely.
     */
    function canMutate(uint256 tokenId, uint256 mutationId)
        external
        view
        override
        tokenExists(tokenId)
        mutationExists(mutationId)
        returns (bool)
    {
        return _canMutate(tokenId, mutationId);
    }

    /**
     * @dev Toggles a mutation catalyst's state.
     */
    function toggleMutationCatalyst(address catalyst) external onlyOwner {
        mutationCatalysts[catalyst] = !mutationCatalysts[catalyst];
    }

    /**
     * @dev Unlocks a mutation for the token.
     * @param force unlocks mutation even if it can't be mutated to.
     */
    function safeCatalystUnlockMutation(
        uint256 tokenId,
        uint256 mutationId,
        bool force
    ) external override tokenExists(tokenId) mutationExists(mutationId) {
        require(
            !_isMutationUnlocked(tokenId, mutationId),
            "ERC721GeneticData: unlock to unlocked mutation"
        );
        require(
            force || _canMutate(tokenId, mutationId),
            "ERC721GeneticData: unlock to unavailable mutation"
        );

        catalystUnlockMutation(tokenId, mutationId);
    }

    /**
     * @dev Unlocks a mutation for the token.
     */
    function catalystUnlockMutation(uint256 tokenId, uint256 mutationId)
        public
        override
        onlyMutationCatalyst
    {
        _unlockMutation(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation if it's unlocked.
     */
    function safeCatalystMutate(uint256 tokenId, uint256 mutationId)
        external
        override
        tokenExists(tokenId)
        mutationExists(mutationId)
    {
        require(
            _tokenMutation[tokenId] != mutationId,
            "ERC721GeneticData: mutate to active mutation"
        );

        require(
            _isMutationUnlocked(tokenId, mutationId),
            "ERC721GeneticData: mutate to locked mutation"
        );

        catalystMutate(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation.
     */
    function catalystMutate(uint256 tokenId, uint256 mutationId)
        public
        override
        onlyMutationCatalyst
    {
        _mutate(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation.
     */
    function mutate(uint256 tokenId, uint256 mutationId)
        external
        payable
        override
        onlyApprovedOrOwner(tokenId)
        mutationExists(mutationId)
    {
        if (_isMutationUnlocked(tokenId, mutationId)) {
            require(
                _tokenMutation[tokenId] != mutationId,
                "ERC721GeneticData: mutate to active mutation"
            );
        } else {
            require(
                _canMutate(tokenId, mutationId),
                "ERC721GeneticData: mutate to unavailable mutation"
            );
            require(
                msg.value == getMutation(mutationId).cost,
                "ERC721GeneticData: incorrect amount of ether sent"
            );

            _unlockMutation(tokenId, mutationId);
        }

        _mutate(tokenId, mutationId);
    }

    /**
     * @dev Allows owner to regenerate cloned genes.
     */
    function unclone(uint256 tokenA, uint256 tokenB) external onlyOwner {
        require(tokenA != tokenB, "ERC721GeneticData: unclone of same token");
        uint256 genesA = _tokenBaseGenes[tokenA];
        require(
            genesA == _tokenBaseGenes[tokenB],
            "ERC721GeneticData: unclone of uncloned tokens"
        );
        _tokenBaseGenes[tokenA] = uint64(bytes8(_getGenes(tokenA, genesA)));
    }

    /**
     * @dev Gets the number of unlocked token mutations.
     */
    function _countTokenMutations(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 count = 1;
        bool[MAX_MUTATIONS] memory mutations = tokenUnlockedMutations[tokenId];
        for (uint256 i = 1; i < MAX_MUTATIONS; i++) {
            if (mutations[i]) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Checks whether the token has unlocked a mutation.
     * note base mutation is always unlocked.
     */
    function _isMutationUnlocked(uint256 tokenId, uint256 mutationId)
        private
        view
        returns (bool)
    {
        return mutationId == 0 || tokenUnlockedMutations[tokenId][mutationId];
    }

    /**
     * @dev Checks whether the token can mutate to a mutation.
     */
    function _canMutate(uint256 tokenId, uint256 mutationId)
        private
        view
        returns (bool)
    {
        uint256 activeMutationId = _tokenMutation[tokenId];
        uint256 nextMutationId = getMutation(activeMutationId).next;
        Mutation memory mutation = getMutation(mutationId);

        return
            mutation.enabled &&
            (nextMutationId == 0 || nextMutationId == mutationId) &&
            (mutation.prev == 0 || mutation.prev == activeMutationId);
    }

    /**
     * @dev Unlocks a token's mutation.
     */
    function _unlockMutation(uint256 tokenId, uint256 mutationId) private {
        tokenUnlockedMutations[tokenId][mutationId] = true;
        _addGenes(tokenId, getMutation(mutationId).geneCount);
        emit UnlockMutation(tokenId, mutationId);
    }

    /**
     * @dev Changes a token's active mutation.
     */
    function _mutate(uint256 tokenId, uint256 mutationId) private {
        _tokenMutation[tokenId] = uint8(mutationId);
        emit Mutate(tokenId, mutationId);
    }

    /**
     * @dev Adds new genes to the token's DNA sequence.
     */
    function _addGenes(uint256 tokenId, uint256 maxGeneCount) private {
        uint8[] storage genes = _tokenExtendedGenes[tokenId];
        uint256 geneCount = genes.length;
        bytes32 newGenes;
        while (geneCount < maxGeneCount) {
            if (newGenes == 0) {
                newGenes = _getGenes(tokenId, geneCount);
            }
            genes.push(uint8(bytes1(newGenes)));
            newGenes <<= 8;
            unchecked {
                geneCount++;
            }
        }
    }

    /**
     * @dev Gets new genes for a token's DNA sequence.
     */
    function _getGenes(uint256 tokenId, uint256 seed)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    tokenId,
                    seed,
                    ownerOf(tokenId),
                    block.number,
                    block.difficulty
                )
            );
    }

    function _burn(uint256 tokenId) internal override {
        delete _tokenMutation[tokenId];
        delete _tokenBaseGenes[tokenId];
        delete _tokenExtendedGenes[tokenId];
        delete tokenUnlockedMutations[tokenId];
        super._burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev An extension to manage token allowances.
 */
contract Reservable is Ownable {
    uint256 public reserved;

    mapping(address => uint256) public allowances;

    modifier fromAllowance(uint256 count) {
        require(
            count > 0 && count <= allowances[_msgSender()] && count <= reserved,
            "Reservable: reserved tokens mismatch"
        );

        _;

        unchecked {
            allowances[_msgSender()] -= count;
            reserved -= count;
        }
    }

    constructor(uint256 reserved_) {
        reserved = reserved_;
    }

    function reserve(address[] calldata addresses, uint256[] calldata allowance)
        external
        onlyOwner
    {
        uint256 count = addresses.length;

        require(count == allowance.length, "Reservable: data mismatch");

        do {
            count--;
            allowances[addresses[count]] = allowance[count];
        } while (count > 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev An extension that grants approvals to proxy operators.
 * Inspired by NuclearNerds' implementation.
 */
contract ProxyOperated is Ownable {
    address public proxyRegistryAddress;
    mapping(address => bool) public projectProxy;

    constructor(address proxy) {
        proxyRegistryAddress = proxy;
    }

    function toggleProxyState(address proxy) external onlyOwner {
        projectProxy[proxy] = !projectProxy[proxy];
    }

    function setProxyRegistryAddress(address proxy) external onlyOwner {
        proxyRegistryAddress = proxy;
    }

    function _isProxyApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        bool isApproved;

        if (proxyRegistryAddress != address(0)) {
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
                proxyRegistryAddress
            );
            isApproved = address(proxyRegistry.proxies(owner)) == operator;
        }

        return isApproved || projectProxy[operator];
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
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

pragma solidity ^0.8.0;

interface IMutationInterpreter {
    struct TokenData {
        uint256 id;
        string name;
        string info;
        uint256[] dna;
    }

    struct MutationData {
        uint256 id;
        string name;
        string info;
        uint256 count;
    }

    function tokenURI(
        TokenData calldata token,
        MutationData calldata mutation,
        string calldata externalURL
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// Modified from OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./TokenInventories.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Enumerable extension, but not including the Metadata extension. This implementation was modified to
 * make use of a token inventories layer instead of the original data-structures.
 */
abstract contract ERC721Enumerable is
    Context,
    TokenInventories,
    ERC165,
    IERC721Enumerable
{
    using Address for address;

    // Number of tokens minted
    uint256 public maxSupply;

    // Number of tokens burned
    uint256 public burned;

    // Mapping from token ID to inventory
    uint16[MAX_SUPPLY] internal _tokenToInventory;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    modifier tokenExists(uint256 tokenId) {
        require(
            _exists(tokenId),
            "ERC721Enumerable: query for nonexistent token"
        );
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Enumerable: caller is not owner nor approved"
        );
        _;
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
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return maxSupply - burned;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );

        uint256 i;
        for (uint256 j; true; i++) {
            if (_tokenToInventory[i] != 0 && j++ == index) {
                break;
            }
        }

        return i;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721Enumerable: balance query for the zero address"
        );
        return _getBalance(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        tokenExists(tokenId)
        returns (address)
    {
        return _getInventoryOwner(_tokenToInventory[tokenId]);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: index query for nonexistent token"
        );

        uint256 i;
        for (uint256 count; count <= index; i++) {
            if (_getInventoryOwner(_tokenToInventory[i]) == owner) {
                count++;
            }
        }

        return i - 1;
    }

    /**
     * @dev Returns the owner's tokens.
     */
    function walletOfOwner(address owner)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner);
        if (balance == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokens = new uint256[](balance);
        for (uint256 j; balance > 0; j++) {
            if (ownerOf(j) == owner) {
                tokens[tokens.length - balance--] = j;
            }
        }
        return tokens;
    }

    /**
     * @dev Checks if multiple tokens belong to an owner.
     */
    function isOwnerOf(address owner, uint256[] memory tokenIds)
        public
        view
        virtual
        returns (bool)
    {
        for (uint256 i; i < tokenIds.length; i++) {
            if (ownerOf(tokenIds[i]) != owner) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721Enumerable: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Enumerable: approve caller is not owner nor approved for all"
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
        tokenExists(tokenId)
        returns (address)
    {
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
    ) public virtual override onlyApprovedOrOwner(tokenId) {
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
    ) public virtual override onlyApprovedOrOwner(tokenId) {
        _safeTransfer(from, to, tokenId, _data);
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public virtual {
        for (uint256 i; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        bytes memory data_
    ) public virtual {
        for (uint256 i; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i], data_);
        }
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
            "ERC721Enumerable: transfer to non ERC721Receiver implementer"
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
        return tokenId < MAX_SUPPLY && _tokenToInventory[tokenId] != 0;
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
        tokenExists(tokenId)
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        delete _tokenToInventory[tokenId];
        _decreaseBalance(owner, 1);
        burned++;

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
            ownerOf(tokenId) == from,
            "ERC721Enumerable: transfer from incorrect owner"
        );
        require(
            to != address(0),
            "ERC721Enumerable: transfer to the zero address"
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _decreaseBalance(from, 1);
        _tokenToInventory[tokenId] = uint16(_getOrSubscribeInventory(to));
        _increaseBalance(to, 1);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721Enumerable: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
                        "ERC721Enumerable: transfer to non ERC721Receiver implementer"
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../mutations/IMutationRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721GeneticData is IERC721Enumerable, IMutationRegistry {
    event UnlockMutation(uint256 tokenId, uint256 mutationId);
    event Mutate(uint256 tokenId, uint256 mutationId);

    function getTokenMutation(uint256 tokenId) external view returns (uint256);

    function getTokenDNA(uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    function getTokenDNA(uint256 tokenId, uint256[] memory splices)
        external
        view
        returns (uint256[] memory);

    function countTokenMutations(uint256 tokenId)
        external
        view
        returns (uint256);

    function isMutationUnlocked(uint256 tokenId, uint256 mutationId)
        external
        view
        returns (bool);

    function canMutate(uint256 tokenId, uint256 mutationId)
        external
        view
        returns (bool);

    function safeCatalystUnlockMutation(
        uint256 tokenId,
        uint256 mutationId,
        bool force
    ) external;

    function catalystUnlockMutation(uint256 tokenId, uint256 mutationId)
        external;

    function safeCatalystMutate(uint256 tokenId, uint256 mutationId) external;

    function catalystMutate(uint256 tokenId, uint256 mutationId) external;

    function mutate(uint256 tokenId, uint256 mutationId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMutationRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Mutation data storage and operations.
 */
contract MutationRegistry is Ownable, IMutationRegistry {
    uint256 constant MAX_MUTATIONS = 256;

    // List of mutations
    mapping(uint256 => Mutation) private _mutations;

    modifier mutationExists(uint256 mutationId) {
        require(
            _mutations[mutationId].interpreter != address(0),
            "MutationRegistry: query for nonexistent mutation"
        );
        _;
    }

    /**
     * @dev Initialize a new instance with an active base mutation.
     */
    constructor(address interpreter) {
        loadMutation(0, true, false, 0, 0, 0, interpreter, 0);
    }

    /**
     * @dev Retrieves a mutation.
     */
    function getMutation(uint256 mutationId)
        public
        view
        override
        returns (Mutation memory)
    {
        return _mutations[mutationId];
    }

    /**
     * @dev Loads a new mutation.
     * @param enabled mutation can be mutated to
     * @param finalized mutation can't be updated
     * @param prev mutation link, 0 is any
     * @param next mutation link, 0 is any
     * @param geneCount required for the mutation
     * @param interpreter address for the mutation
     * @param cost of unlocking the mutation
     */
    function loadMutation(
        uint8 mutationId,
        bool enabled,
        bool finalized,
        uint8 prev,
        uint8 next,
        uint8 geneCount,
        address interpreter,
        uint256 cost
    ) public onlyOwner {
        require(
            _mutations[mutationId].interpreter == address(0),
            "MutationRegistry: load to existing mutation"
        );

        require(
            interpreter != address(0),
            "MutationRegistry: invalid interpreter"
        );

        _mutations[mutationId] = Mutation(
            enabled,
            finalized,
            prev,
            next,
            geneCount,
            interpreter,
            cost
        );
    }

    /**
     * @dev Toggles a mutation's enabled state.
     * note finalized mutations can't be toggled.
     */
    function toggleMutation(uint256 mutationId)
        external
        onlyOwner
        mutationExists(mutationId)
    {
        Mutation storage mutation = _mutations[mutationId];

        require(
            !mutation.finalized,
            "MutationRegistry: toggle to finalized mutation"
        );

        mutation.enabled = !mutation.enabled;
    }

    /**
     * @dev Marks a mutation as finalized, preventing it from being updated in the future.
     * note this action can't be reverted.
     */
    function finalizeMutation(uint256 mutationId)
        external
        onlyOwner
        mutationExists(mutationId)
    {
        _mutations[mutationId].finalized = true;
    }

    /**
     * @dev Updates a mutation's interpreter.
     * note finalized mutations can't be updated.
     */
    function updateMutationInterpreter(uint256 mutationId, address interpreter)
        external
        onlyOwner
        mutationExists(mutationId)
    {
        Mutation storage mutation = _mutations[mutationId];

        require(
            interpreter != address(0),
            "MutationRegistry: zero address interpreter"
        );

        require(
            !mutation.finalized,
            "MutationRegistry: update to finalized mutation"
        );

        mutation.interpreter = interpreter;
    }

    /**
     * @dev Updates a mutation's links.
     * note finalized mutations can't be updated.
     */
    function updateMutationLinks(
        uint8 mutationId,
        uint8 prevMutationId,
        uint8 nextMutationId
    ) external onlyOwner mutationExists(mutationId) {
        Mutation storage mutation = _mutations[mutationId];

        require(
            !mutation.finalized,
            "MutationRegistry: update to finalized mutation"
        );

        mutation.prev = prevMutationId;
        mutation.next = nextMutationId;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity ^0.8.0;

/**
 * @dev A subscription-based inventory system that can be used as a middle layer between owners and tokens.
 * There may be MAX_SUPPLY + 1 inventory owners in total, as the zero-address owns the first inventory.
 * Inventory IDs are packed together with inventory balances to save storage.
 * Implementation inspired by Azuki's batch-minting technique.
 */
contract TokenInventories {
    uint256 constant MAX_SUPPLY = 10101;
    uint256 constant MAX_SUPPLY_EQ = MAX_SUPPLY + 1;

    uint16[] private _vacantInventories;
    address[] private _inventoryToOwner;
    mapping(address => uint256) private _ownerToInventory;

    constructor() {
        _inventoryToOwner.push(address(0));
    }

    function _getInventoryOwner(uint256 inventory)
        internal
        view
        returns (address)
    {
        return _inventoryToOwner[inventory];
    }

    function _getInventoryId(address owner) internal view returns (uint256) {
        return _ownerToInventory[owner] & 0xFFFF;
    }

    function _getBalance(address owner) internal view returns (uint256) {
        return _ownerToInventory[owner] >> 16;
    }

    function _setBalance(address owner, uint256 balance) internal {
        _ownerToInventory[owner] = _getInventoryId(owner) | (balance << 16);
    }

    function _increaseBalance(address owner, uint256 count) internal {
        unchecked {
            _setBalance(owner, _getBalance(owner) + count);
        }
    }

    /**
     * @dev Decreases an owner's inventory balance and unsubscribes from the inventory when it's empty.
     * @param count must be equal to owner's balance at the most
     */
    function _decreaseBalance(address owner, uint256 count) internal {
        uint256 balance = _getBalance(owner);
        
        if (balance == count) {
            _unsubscribeInventory(owner);
        } else {
            unchecked {
                _setBalance(owner, balance - count);
            }
        }
    }

    /**
     * @dev Returns an owner's inventory ID. If the owner doesn't have an inventory they are assigned a
     * vacant one.
     */
    function _getOrSubscribeInventory(address owner)
        internal
        returns (uint256)
    {
        uint256 id = _getInventoryId(owner);
        return id == 0 ? _subscribeInventory(owner) : id;
    }

    /**
     * @dev Subscribes an owner to a vacant inventory and returns its ID.
     * The inventory list's length has to be MAX_SUPPLY + 1 before inventories from the vacant inventories
     * list are assigned.
     */
    function _subscribeInventory(address owner) private returns (uint256) {
        if (_inventoryToOwner.length < MAX_SUPPLY_EQ) {
            _ownerToInventory[owner] = _inventoryToOwner.length;
            _inventoryToOwner.push(owner);
        } else if (_vacantInventories.length > 0) {
            unchecked {
                uint256 id = _vacantInventories[_vacantInventories.length - 1];
                _vacantInventories.pop();
                _ownerToInventory[owner] = id;
                _inventoryToOwner[id] = owner;
            }
        }
        return _ownerToInventory[owner];
    }

    /**
     * @dev Unsubscribes an owner from their inventory and updates the vacant inventories list.
     */
    function _unsubscribeInventory(address owner) private {
        uint256 id = _getInventoryId(owner);
        delete _ownerToInventory[owner];
        delete _inventoryToOwner[id];
        _vacantInventories.push(uint16(id));
    }
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

interface IMutationRegistry {
    struct Mutation {
        bool enabled;
        bool finalized;
        uint8 prev;
        uint8 next;
        uint8 geneCount;
        address interpreter;
        uint256 cost;
    }

    function getMutation(uint256 mutationId)
        external
        view
        returns (Mutation memory);
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