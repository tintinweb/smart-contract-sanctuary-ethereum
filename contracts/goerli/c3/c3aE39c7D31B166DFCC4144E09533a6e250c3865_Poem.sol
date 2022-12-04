// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Renderable.sol";

/// Index should be > 0 and <= MAX_INDEX_VAL
error InvalidIndexMin1Max25();
error MintFeeNotMet();
error OutOfTokens();
error YouCanOnlyMint1Token();
error OneCanHoldMax3Tokens(address to);

contract Poem is ERC721A, Ownable, RenderableMetadata {
    uint8 internal constant MAX_NUM_JITTERS = 3;
    uint8 internal constant MAX_INDEX_VAL = 25;
    uint8 public constant MAX_NUM_NFTS = 7;
    uint256 private constant VALUE_FILTER = 0x0000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 private immutable _deployedBlockNumber;

    uint8[9] public path = [1, 0, 0, 0, 0, 0, 0, 0, 25];
    uint8 public currStep = 0;
    uint256 internal _historicalInput = 1;
    uint256 public mintFee; // In wei
    uint256[26] internal _nodes = [
        0,
        909926238360867929735398212882603035651154206890943763432627265628419941664,
        1818085630288831225152556248451971318888503523798382480318670550428524307488,
        2272165325726251414518349332747065322088826020657626361753819989959403463712,
        3180324987148369089773348128288666447838811641617614208638020369611860767520,
        3634404682585789279139141212583760451039134138476858583137030637339093005088,
        4088484324313940717540769080940660335567536152699603319147880213682479002400,
        4996747404196785874318577405850053296304456278064491627768569074979230526496,
        5450827099634206063684370490145147299505383335278118719355313680067884952608,
        5904906741362357502085998358502047184033180789146480233733677844117077961760,
        6358972633517708693661330946683849285079837964484281646812318644041703173152,
        28401173286392137062282498244147996712585788310297368222521403865233190432,
        7267042491568102673472288079791435007277491848695276522382272216462879777824,
        7721122187005522862838081164086529010477816706585060482103526844235668026144,
        8175201828733674301239709033108001331624392849233692055307543228010251776544,
        8594068814520393617499124365727618858396950975904160398476206872148189541152,
        35337536625952488945442353345468866105503576651487143313660503028163503136,
        9083360762342544255095990558673540698909844224853249164312911225587916694560,
        9537440457779964444461783642968634702110166721712493522744180277778267598368,
        9950883237096986387747710946149794462226042099961420753510984315443664479264,
        40637485017397839625788323267119790410909743057208080281411575484228316704,
        10445599846969808156496454824392134265572084798328785506672366718191527996960,
        10855508368420576029336595138616605997968481005738390565983096147756436368928,
        44171176619459608239582437518572962895687103158953280726063294786640307488,
        11307821214581659709333104004754678501295898408692039780574742603076044219680,
        2662277745920782326914498756153016221122324270
    ];

    /**
     * _mintPrice is denominated in wei
     *
     */
    constructor(uint256 _mintPrice) ERC721A("Pathfinder_RealMetadataNoImage", "POEM") {
        _deployedBlockNumber = block.number;
        mintFee = _mintPrice;
    }

    // ========= VALIDATION =========
    function indexIsValid(uint256 _index) internal pure {
        if (_index <= 0 || _index > MAX_INDEX_VAL) {
            revert InvalidIndexMin1Max25();
        }
    }

    // ========= PAYMENTS =========
    // withdraw funds, royalties

    function withdrawAllEth() external {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAllERC20(IERC20 _erc20Token) external {
        _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
    }

    function updateMintFee(uint256 mintFeeWei) external onlyOwner {
        mintFee = mintFeeWei;
    }

    // ========= PUBLIC FUNCTIONS =========
    // mint, burn, tokenURI, SVG

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function totalMintedTo(address to) external view returns (uint256) {
        return _numberMinted(to);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken(); // do we want this check?
        TokenOwnership memory info = _ownershipOf(_tokenId);
        uint64 lastTransferBlockNumber = _getAux(info.addr);
        uint24 numOwners = info.extraData;
        uint256 numBlocksHeld = block.number - _deployedBlockNumber - lastTransferBlockNumber;

        return
            _getTokenUri(
                _tokenId,
                currStep,
                path,
                _jitterLevel(numOwners),
                _hiddenLevel(numBlocksHeld),
                _shouldRenderDiamond()
            );
    }

    function getDefaultSvg() external view returns (string memory) {
        return _getSvg(0, currStep, path, 0, 0, _shouldRenderDiamond());
    }

    function getHiddenLevel(uint8 _tokenId) external view returns (uint8) {
        TokenOwnership memory info = _ownershipOf(_tokenId);
        uint64 lastTransferBlockNumber = _getAux(info.addr);

        uint256 numBlocksHeld = block.number - _deployedBlockNumber - lastTransferBlockNumber;
        return _hiddenLevel(numBlocksHeld);
    }

    function getJitterLevel(uint8 _tokenId) external view returns (uint8) {
        TokenOwnership memory info = _ownershipOf(_tokenId);
        uint24 numOwners = info.extraData;

        return _jitterLevel(numOwners);
    }

    function mint() external payable {
        if (msg.value != mintFee) {
            revert MintFeeNotMet();
        }
        address to = msg.sender;
        if (_totalMinted() >= MAX_NUM_NFTS) {
            revert OutOfTokens();
        }
        if (_numberMinted(to) != 0) {
            revert YouCanOnlyMint1Token();
        }
        _safeMint(to, 1);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    // ========= HOOKS=========
    // beforeTransfer, afterTransfer

    // TODO: prevent transferring to contracts? Or does it matter?
    // TODO: Do I have a re-entrancy risk on minting, burning, or transferring?

    function _beforeTokenTransfers(
        address,
        address to,
        uint256 startTokenId,
        uint256
    ) internal override {
        // If we're burning the token and we're not done, take the next step.
        // Note that calling this in _beforeTokenTransfers instead of in the public burn function
        // to ensure that the owner check on burning happens BEFORE we take the step.
        if (uint160(to) == 0) {
            if (currStep < MAX_NUM_NFTS) {
                _takeNextStep(startTokenId);
            }
        } else {
            // If we're not burning, the receiver can only hold 3 tokens at a time.
            if (balanceOf(to) > 2) {
                revert OneCanHoldMax3Tokens(to);
            }
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256,
        uint256
    ) internal override {
        _historicalInput = _newHistoricalInput(
            _historicalInput,
            uint256(uint160(from)),
            uint256(uint160(to)),
            block.difficulty,
            block.number
        );
        if (to != address(0)) {
            // If it's not being burned, store transfer timestamp
            //      Because we only have 64 bits, we can't store the full block number.
            //      Instead, we'll store the difference between this block and the deploy block.
            //      That's enough bits to store roughly 77M centuries from deployment.
            uint256 newBlockNumber = block.number - _deployedBlockNumber;
            // Unchecked because we can let it wrap around to zero after 77M centuries
            unchecked {
                _setAux(to, uint64(newBlockNumber));
            }
        } else {
            // If we've burning the last token, set our currStep to the end.
            //    It's MAX_NUM_NFTs-1 because the burn counter is
            //    incremented after this function is called
            if (_totalBurned() == MAX_NUM_NFTS - 1) {
                currStep = 8;
            }
        }
    }

    // ========= MODIFYING INTERNAL DATA =========
    // storing owner count, transfer blockstamp, historical data,
    // taking the next step in our poem path

    function _newHistoricalInput(
        uint256 currInput,
        uint256 from,
        uint256 to,
        uint256 difficulty,
        uint256 blockNumber
    ) internal pure returns (uint256) {
        // We're okay with an overflow or underflow here.
        // This is about storing the "essence" of history, not keep an accurate record.
        unchecked {
            uint256 part1 = uint160(from) + difficulty;
            uint256 part2 = uint160(to) + blockNumber;
            if (part1 > part2) {
                return currInput + part1 - part2;
            } else {
                return currInput + part2 - part1;
            }
        }
    }

    function _extraData(
        address,
        address to,
        uint24 previousExtraData
    ) internal pure override returns (uint24) {
        if (to == address(0)) {
            // If it's being burned, we don't need to store anything
            return previousExtraData;
        }

        uint24 maxVal = 16777215;
        uint32 numOwnersHad;
        unchecked {
            // This will never overflow
            numOwnersHad = previousExtraData + 1;
        }
        if (numOwnersHad >= maxVal) {
            return maxVal;
        } else {
            return uint24(numOwnersHad);
        }
    }

    function _takeNextStep(uint256 tokenId) private {
        TokenOwnership memory info = _ownershipOf(tokenId);
        uint64 lastTransferBlockNumber = _getAux(info.addr);
        uint24 numOwners = info.extraData;

        // 1: figure out opacity
        uint256 numBlocksHeld = block.number - _deployedBlockNumber - lastTransferBlockNumber;
        uint8 hiddenPercentage = _hiddenLevel(numBlocksHeld);
        if (hiddenPercentage == 100) {
            currStep += 1;
            return;
        }

        // 2: figure out jitter
        uint8 remainingPercentage = 100 - hiddenPercentage;
        uint8 jitterLevel = _jitterLevel(numOwners);
        uint8 jitterPercentage = uint8((uint16(remainingPercentage) * uint16(jitterLevel)) / 100);
        uint8 childPercentage = (remainingPercentage - uint8(jitterPercentage)) / 2;

        // 3: Determine % chance of each outcome type
        uint8 leftMax = childPercentage;
        uint8 rightMax = 2 * childPercentage;
        uint8 jitterMax = rightMax + uint8(jitterPercentage);

        // We don't care about over/underflow.
        uint256 historicalSeed;
        unchecked {
            historicalSeed = uint256(_historicalInput + uint160(info.addr));
        }
        uint8 seed = uint8(historicalSeed % 100);

        uint8 currIndex = _getCurrIndex(uint160(info.addr));
        currStep += 1;
        uint8 leftChild = _getLeftChild(currIndex);
        uint8 rightChild = _getRightChild(currIndex);
        if (seed <= leftMax) {
            path[currStep] = _preferNonZeroVal(leftChild, rightChild, leftChild);
        } else if (seed <= rightMax) {
            path[currStep] = _preferNonZeroVal(leftChild, rightChild, rightChild);
        } else if (seed <= jitterMax) {
            path[currStep] = _getJitterChild(currIndex, historicalSeed >> 30);
        }
        // else, it's in the "hiddenPercentage" zone and we don't pick a child
        return;
    }

    // ========= INTERNAL GETTERS =========

    function _shouldRenderDiamond() internal view returns (bool) {
        return (_historicalInput >> 3) % 2 == 1;
    }

    function _getNode(uint8 index) internal view returns (bytes32) {
        return bytes32(_nodes[index]);
    }

    function _getLeftChild(uint8 index) internal view returns (uint8) {
        indexIsValid(index);
        return uint8(_getNode(index)[0]);
    }

    function _getRightChild(uint8 index) internal view returns (uint8) {
        indexIsValid(index);
        return uint8(_getNode(index)[1]);
    }

    function _getValueBytes(uint8 index) internal view override returns (bytes32) {
        indexIsValid(index);
        return _getNode(index) & bytes32(VALUE_FILTER);
    }

    function _getJitterKids(uint8 index) internal view returns (uint8[3] memory) {
        indexIsValid(index);
        uint8[3] memory jitters;
        bytes32 node = _getNode(index);
        for (uint8 i = 0; i < MAX_NUM_JITTERS; i++) {
            jitters[i] = uint8(node[2 + i]);
        }
        return jitters;
    }

    function _preferNonZeroVal(
        uint8 option1,
        uint8 option2,
        uint8 preferred
    ) private pure returns (uint8) {
        if (preferred > 0) {
            return preferred;
        } else if (option1 > 0) {
            return option1;
        }
        return option2;
    }

    function _getJitterChild(uint8 index, uint256 seed) internal view returns (uint8) {
        indexIsValid(index);

        uint8[3] memory jitters = _getJitterKids(index);
        // "jittering" usually takes us off the expected path.
        for (uint8 i = 0; i < MAX_NUM_JITTERS; i++) {
            uint8 thisOne = uint8(seed % 2);
            uint8 j = jitters[i];
            if (thisOne == 1 && j > 0) {
                return j;
            }
            seed = seed >> 1;
        }
        // but sometimes, we stay on the path
        uint8 left = _getLeftChild(index);
        uint8 right = _getRightChild(index);
        if (seed % 2 == 1) {
            return _preferNonZeroVal(left, right, left);
        }
        return _preferNonZeroVal(left, right, right);
    }

    function _numBlocksToEstMonths(uint256 numBlocks) internal pure returns (uint256) {
        return numBlocks / (7000 * 30);
    }

    function _hiddenLevel(uint256 numBlocksHeld) internal pure returns (uint8) {
        uint256 estNumMonthsHeld = _numBlocksToEstMonths(numBlocksHeld);
        if (estNumMonthsHeld <= 4) {
            return 0;
        } else if (estNumMonthsHeld <= 12) {
            return uint8(12 * estNumMonthsHeld - 54);
        }
        return 100;
    }

    function _jitterLevel(uint24 numOwners) internal pure returns (uint8) {
        if (numOwners < 5) {
            return 0;
        } else if (numOwners < 10) {
            return 10;
        } else if (numOwners < 20) {
            return 15;
        } else if (numOwners < 30) {
            return 20;
        } else if (numOwners < 40) {
            return 25;
        } else {
            return 30;
        }
    }

    /**
     * Return the index of the node we're currently on. If our current node is
     * "hidden", return a node we _could_ be on.
     */
    function _getCurrIndex(uint160 fromSeed) internal view returns (uint8) {
        // If our currIndex is non-zero, return it.
        uint8 currIndex = path[currStep];
        if (currIndex != 0) {
            return currIndex;
        }

        // If we had an opacity issue and don't know where we are,
        // pick a random place we _could_ be to decide where to go next.
        // 1. Figure out the last time we had a value
        uint8 nonZeroStep = currStep;
        while (currIndex == 0 && nonZeroStep > 0) {
            nonZeroStep -= 1;
            currIndex = path[nonZeroStep];
        }

        // 2. Take a pseudorandom walk to a place we could be
        for (uint8 i = nonZeroStep; i < currStep; i++) {
            uint8 leftChild = _getLeftChild(currIndex);
            uint8 rightChild = _getRightChild(currIndex);
            if (fromSeed % 2 == 0) {
                currIndex = _preferNonZeroVal(leftChild, rightChild, leftChild);
            } else {
                currIndex = _preferNonZeroVal(leftChild, rightChild, rightChild);
            }
            fromSeed >> 1;
        }
        return currIndex;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
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
    function _toString(uint256 value) internal pure virtual returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

/* solhint-disable quotes */
abstract contract RenderableMetadata {
    uint256 private indexLocation = 0x15242633353742444648515355575962646668737577848695000000000000;

    function _getValueBytes(uint8 index) internal view virtual returns (bytes32);

    function _getTokenUri(
        uint256 _tokenId,
        uint8 currStep,
        uint8[9] storage path,
        uint8 jitterLevel,
        uint8 hiddenLevel,
        bool _shouldRenderDiamond
    ) internal view returns (string memory) {
        string memory svgString = _getSvg(_tokenId, currStep, path, jitterLevel, hiddenLevel, _shouldRenderDiamond);
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        _getJSON(
                            _tokenId,
                            jitterLevel,
                            hiddenLevel,
                            getSentence(currStep, path),
                            Base64.encode(bytes(svgString))
                        )
                    )
                )
            );
    }

    function _getSvg(
        uint256 tokenId,
        uint8 currStep,
        uint8[9] storage path,
        uint16 jitterLevel,
        uint16 hiddenLevel,
        bool _shouldRenderDiamond
    ) internal view returns (string memory) {
        uint16 blur = 100 - hiddenLevel;
        string memory opacity = string.concat("0.", uint2str(blur));
        if (blur == 100) {
            opacity = "1";
        }
        string memory jitterVal = uint2str(jitterLevel * 10);
        string memory id = uint2str(uint16(uint256(keccak256(abi.encode(jitterLevel, hiddenLevel, tokenId)))));
        string memory svgString = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" height="100%" width="100%" viewBox="0 0 800 800" style="background:#1a1a1a"><defs><filter id="adj',
            id,
            '" x="0" y="0"><feTurbulence type="turbulence" baseFrequency="0.001" seed="',
            uint2str(tokenId + 1),
            '" numOctaves="',
            jitterVal,
            '" result="turbulence" /><feDisplacementMap  in2="turbulence"  in="SourceGraphic"  scale="',
            jitterVal,
            '" /></filter></defs>'
        );
        if (_shouldRenderDiamond) {
            svgString = string.concat(svgString, renderLine(path, currStep, opacity, id));
        } else {
            svgString = string.concat(svgString, renderLine(path, currStep, opacity, id));
        }
        return svgString;
    }

    function _getJSON(
        uint256 _tokenId,
        uint16 jitterLevel,
        uint16 hiddenLevel,
        string memory poem,
        string memory _imageData
    ) internal pure returns (string memory) {
        /* solhint-disable max-line-length */
        return
            string.concat(
                '{"name": "Gem #',
                uint2str(_tokenId),
                '","description": "POEM is a collaborative poetry pathfinder. As gems are found, sold, and held, the path before us changes. To take the next step, we must burn a token. Let us see what we create together.","attributes": [{"trait_type":"energy","value":',
                uint2str(100 - hiddenLevel),
                '},{"trait_type":"chaos","value":',
                uint2str(jitterLevel),
                '},{"trait_type":"poem","value":"',
                poem,
                "}]}"
            );
    }

    function renderDiamond(
        uint8[9] storage path,
        uint8 currStep,
        string memory opacity,
        string memory id
    ) private view returns (string memory) {
        string memory returnVal = string.concat(
            unicode"<style>[class*='node",
            id,
            unicode"-']{font-size:18px;font-family:serif;height:100%;overflow:auto;opacity:",
            opacity,
            "} .node",
            id,
            "-default{color:#a9a9a9;} .node",
            id,
            "-notSelected{color:#555555;} .node",
            id,
            "-selected{color:white;} .node",
            id,
            '-hidden{color:#333333;text-decoration:line-through;}</style><svg filter="url(#adj',
            id,
            ')">'
        );
        for (uint8 i = 1; i <= 25; i++) {
            bytes32 phraseBytes = _getValueBytes(i);
            uint8[2] memory dimen = nodeIndexToRowColumn(i);
            returnVal = string.concat(
                returnVal,
                renderNodeWord(path[dimen[0] - 1], currStep, bytes32ToString(phraseBytes), i, dimen[0], dimen[1], id)
            );
        }
        return string.concat(returnVal, "</svg></svg>");
    }

    function renderLine(
        uint8[9] storage path,
        uint8 currStep,
        string memory opacity,
        string memory id
    ) private view returns (string memory) {
        string memory returnVal = string.concat(
            "<style>.sentence",
            id,
            "{font-size:70px;text-align:left;font-family:serif;color:white;height:100%;overflow-wrap:break-word;opacity:",
            opacity,
            "}</style>"
        );
        string memory sentenceWrapped = Svg.wrapText(
            getSentence(currStep, path),
            Svg.prop("class", string.concat("sentence", id)),
            string.concat(
                Svg.prop("x", "30"),
                Svg.prop("y", "20"),
                Svg.prop("width", "760"),
                Svg.prop("height", "760"),
                Svg.prop("filter", string.concat("url(#adj", id, ")"))
            )
        );
        return string.concat(returnVal, sentenceWrapped, "</svg>");
    }

    function getSentence(uint8 currStep, uint8[9] storage path) private view returns (string memory) {
        string memory sentence = "";
        for (uint8 i = 0; i < 9; i++) {
            uint8 index = path[i];
            sentence = string.concat(sentence, getNodeText(i, currStep, index));
        }
        return sentence;
    }

    function getNodeText(
        uint8 row,
        uint8 _currStep,
        uint8 index
    ) private view returns (string memory) {
        if (row > _currStep) {
            return unicode"█████";
        }
        if (index == 0) {
            return unicode"█████ ";
        }
        return bytes32ToString(_getValueBytes(index));
    }

    function nodeIndexToRowColumn(uint8 nodeIndex) private view returns (uint8[2] memory) {
        bytes1 info = bytes32(indexLocation)[nodeIndex];
        uint8 row = uint8(info >> 4);
        uint8 col = uint8((info << 4) >> 4);
        return [row, col];
    }

    function renderNodeWord(
        uint8 pathVal,
        uint8 currStep,
        string memory value,
        uint8 index,
        uint256 row,
        uint256 column,
        string memory id
    ) private pure returns (string memory) {
        if (row - 1 > currStep) {
            value = "?";
        }
        return
            Svg.wrapText(
                value,
                Svg.prop("class", getTextClass(pathVal, currStep, index, row, id)),
                string.concat(
                    Svg.prop("x", uint2str(column * 80 - 40)),
                    Svg.prop("y", uint2str(row * 75)),
                    Svg.prop("width", "130"),
                    Svg.prop("height", "60")
                )
            );
    }

    function getTextClass(
        uint8 pathVal,
        uint8 currStep,
        uint8 index,
        uint256 row,
        string memory id
    ) private pure returns (string memory) {
        if (currStep >= row - 1) {
            if (pathVal == index) {
                return string.concat("node", id, "-selected");
            }
            if (pathVal == 0) {
                return string.concat("node", id, "-hidden");
            }
            // If we're passed this row and this node wasn't selected
            return string.concat("node", id, "-notSelected");
        }
        // If this node could be selected in the future
        return string.concat("node", id, "-default");
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 numNonZeroBytes = 0;
        for (uint8 i = 0; i < 32; i++) {
            if (_bytes32[i] != 0) {
                numNonZeroBytes++;
            }
        }

        bytes memory bytesArray = new bytes(numNonZeroBytes);
        uint8 bytesArrayIndex = 0;
        for (uint8 k = 0; k < 32; k++) {
            if (_bytes32[k] != 0) {
                bytesArray[bytesArrayIndex] = _bytes32[k];
                bytesArrayIndex++;
            }
        }
        return string(bytesArray);
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
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

// These library functions are copied from the Hot Chain Svg project.
library Svg {
    function text(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("text", _props, _children);
    }

    function wrapText(
        string memory _text,
        string memory _textProps,
        string memory _boxProps
    ) internal pure returns (string memory) {
        return
            el(
                "foreignObject",
                _boxProps,
                el("div", string.concat(prop("xmlns", "http://www.w3.org/1999/xhtml"), _textProps), _text)
            );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return string.concat("<", _tag, " ", _props, ">", _children, "</", _tag, ">");
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val) internal pure returns (string memory) {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}

// This library function is copied from the WatchfacesWorld project
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        /* solhint-disable no-inline-assembly, no-empty-blocks */
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
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