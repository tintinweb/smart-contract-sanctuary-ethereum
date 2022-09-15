/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./POAPBoard.sol";
import "./POAPLibrary.sol";
import "./IDescriptor.sol";
import "./IBadgesVerifier.sol";
import "./ICheeth.sol";

contract AnonymiceBadges is POAPBoard {
    address public cheethAddress;
    address public descriptorAddress;
    address public badgesVerifierAddress;
    bool public isPaused = true;
    mapping(uint256 => uint256) public boardPrices;
    mapping(address => string) public boardNames;
    mapping(address => bool) private _auth;

    constructor() POAPBoard("Anonymice Collector Cards", "AnonymiceCollectorCards") {}

    function mint() external pure override {
        revert("no free mint");
    }

    function claimAll(
        uint256[] calldata ids,
        bytes32[][] calldata proofs,
        uint256[] calldata genesisMice,
        uint256[] calldata babyMice
    ) external {
        for (uint256 index = 0; index < ids.length; index++) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(proofs[index], merkleRootsByPOAPId[ids[index]], leaf), "not in whitelist");
            _claimPOAP(ids[index], msg.sender);
        }

        uint256[] memory badgeIds = IBadgesVerifier(badgesVerifierAddress).claimableBadges(
            genesisMice,
            babyMice,
            msg.sender
        );

        for (uint256 index = 0; index < badgeIds.length; index++) {
            uint256 badgeId = badgeIds[index];
            if (badgeId == 0) break;
            if (!_poapOwners[badgeId][msg.sender]) {
                _claimPOAP(badgeIds[index], msg.sender);
            }
        }
    }

    function claimVerifiedBadge(
        uint256[] calldata genesisMice,
        uint256[] calldata babyMice,
        uint256 badgeIdToClaim
    ) external {
        uint256[] memory badgeIds = IBadgesVerifier(badgesVerifierAddress).claimableBadges(
            genesisMice,
            babyMice,
            msg.sender
        );

        for (uint256 index = 0; index < badgeIds.length; index++) {
            uint256 badgeId = badgeIds[index];
            if (badgeId == 0) break;
            if (badgeIdToClaim == badgeId) {
                if (!_poapOwners[badgeId][msg.sender]) {
                    _claimPOAP(badgeIds[index], msg.sender);
                }
            }
        }
    }

    function getVerifiedBadges(uint256[] memory genesisMice, uint256[] memory babyMice)
        external
        view
        returns (uint256[] memory)
    {
        return IBadgesVerifier(badgesVerifierAddress).claimableBadges(genesisMice, babyMice, msg.sender);
    }

    function buyBoard(uint256 boardId) external {
        require(boardPrices[boardId] > 0, "price not set");
        ICheeth(cheethAddress).burnFrom(msg.sender, boardPrices[boardId]);
        if (!_minted(msg.sender)) {
            _mint(msg.sender);
            currentBoard[msg.sender] = boardId;
        }
        _claimBoard(boardId, msg.sender);
    }

    function setBoardName(string memory name) external {
        boardNames[msg.sender] = name;
    }

    function externalClaimBoard(uint256 boardId, address to) external {
        require(_auth[msg.sender], "no auth");
        _claimBoard(boardId, to);
    }

    function externalClaimPOAP(uint256 id, address to) external {
        require(_auth[msg.sender], "no auth");
        _claimPOAP(id, to);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return IDescriptor(descriptorAddress).tokenURI(id);
    }

    function rearrangeBoardAndName(
        uint256 boardId,
        uint256[] memory slots,
        string memory text
    ) external {
        if (boardId != currentBoard[msg.sender]) _swapBoard(boardId, false);
        _rearrangePOAPs(slots);
        boardNames[msg.sender] = text;
    }

    function previewBoard(
        uint256 boardId,
        uint256[] calldata badges,
        string memory text
    ) external view returns (string memory) {
        return IDescriptor(descriptorAddress).buildSvg(boardId, badges, text, true);
    }

    function setDescriptorAddress(address _descriptorAddress) external onlyOwner {
        descriptorAddress = _descriptorAddress;
    }

    function setCheethAddress(address _cheethAddress) external onlyOwner {
        cheethAddress = _cheethAddress;
    }

    function setBadgesVerifierAddress(address _badgesVerifierAddress) external onlyOwner {
        badgesVerifierAddress = _badgesVerifierAddress;
    }

    function setAuth(address wallet, bool value) external onlyOwner {
        _auth[wallet] = value;
    }

    function setIsPaused(bool value) external onlyOwner {
        isPaused = value;
    }

    function setBoardPrice(uint256 boardId, uint256 boardPrice) external onlyOwner {
        boardPrices[boardId] = boardPrice;
    }
}
/* solhint-enable quotes */

/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721UniqueBound.sol";
import "./IPOAPBoard.sol";
import "./POAPLibrary.sol";

contract POAPBoard is Ownable, ERC721UniqueBound {
    mapping(uint256 => mapping(address => bool)) internal _poapOwners;
    mapping(address => mapping(uint256 => uint256)) internal _poaps;

    uint256 public boardCount;
    uint256 public poapCount;
    mapping(uint256 => POAPLibrary.Board) public boards;
    mapping(address => uint256) public currentBoard;
    mapping(address => uint256) public poapsBalanceOf;
    mapping(uint256 => bytes32) public merkleRootsByPOAPId;
    mapping(uint256 => bytes32) public merkleRootsByBoardId;
    mapping(address => mapping(uint256 => bool)) public availableBoards;
    mapping(address => mapping(uint256 => uint256)) public poapPositions;

    constructor(string memory name_, string memory symbol_) ERC721UniqueBound(name_, symbol_) {}

    function mint() external virtual {
        _mint(msg.sender);
        availableBoards[msg.sender][1] = true;
        currentBoard[msg.sender] = 1;
    }

    function claimBoard(uint256 boardId, bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRootsByBoardId[boardId], leaf), "not in whitelist");
        _claimBoard(boardId, msg.sender);
    }

    function claimPOAP(uint256 id, bytes32[] calldata proof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRootsByPOAPId[id], leaf), "not in whitelist");
        _claimPOAP(id, msg.sender);
    }

    function setCurrentBoard(uint256 boardId) external {
        _swapBoard(boardId, true);
    }

    function rearrangeBoard(uint256 boardId, uint256[] memory slots) external {
        if (boardId != currentBoard[msg.sender]) _swapBoard(boardId, false);
        _rearrangePOAPs(slots);
    }

    function rearrangePOAPs(uint256[] memory slots) external {
        _rearrangePOAPs(slots);
    }

    function _rearrangePOAPs(uint256[] memory slots) internal {
        POAPLibrary.Board memory selectedBoard = boards[currentBoard[msg.sender]];
        require(slots.length == selectedBoard.slots.length, "wrong size");
        for (uint256 index = 0; index < slots.length; index++) {
            uint256 poapId = slots[index];
            for (uint256 innerIndex = 0; innerIndex < index; innerIndex++) {
                require(poapId == 0 || poapId != slots[innerIndex], "already used");
            }
            poapPositions[msg.sender][index] = _poapOwners[poapId][msg.sender] ? poapId : 0;
        }
    }

    function _swapBoard(uint256 boardId, bool shouldWipe) internal {
        require(currentBoard[msg.sender] != boardId, "same board");
        require(availableBoards[msg.sender][boardId], "locked board");

        currentBoard[msg.sender] = boardId;
        if (shouldWipe) {
            POAPLibrary.Board memory selectedBoard = boards[boardId];
            for (uint256 index = 0; index < selectedBoard.slots.length; index++) {
                poapPositions[msg.sender][index] = 0;
            }
        }
    }

    function getAllPOAPs(address wallet) public view returns (uint256[] memory) {
        uint256 poapsCount = poapsBalanceOf[wallet];
        uint256[] memory poaps = new uint256[](poapsCount);
        for (uint256 index = 0; index < poapsCount; index++) {
            poaps[index] = _poaps[wallet][index];
        }
        return poaps;
    }

    function getBoardPOAPs(address wallet) public view returns (uint256[] memory) {
        POAPLibrary.Board memory selectedBoard = boards[currentBoard[wallet]];
        uint256[] memory poaps = new uint256[](selectedBoard.slots.length);
        for (uint256 index = 0; index < poaps.length; index++) {
            poaps[index] = poapPositions[wallet][index];
        }
        return poaps;
    }

    function getBoards(address wallet) public view returns (POAPLibrary.Board[] memory) {
        uint256 walletCount;
        for (uint256 boardId = 1; boardId <= boardCount; boardId++) {
            if (availableBoards[wallet][boardId]) {
                walletCount++;
            }
        }
        POAPLibrary.Board[] memory walletBoards = new POAPLibrary.Board[](walletCount);
        uint256 walletBoardsIndex;
        for (uint256 boardId = 1; boardId <= boardCount; boardId++) {
            if (availableBoards[wallet][boardId]) {
                walletBoards[walletBoardsIndex++] = boards[boardId];
            }
        }
        return walletBoards;
    }

    function getCurrentBoard(address wallet) public view returns (POAPLibrary.Board memory) {
        return boards[currentBoard[wallet]];
    }

    function getWalletState(address wallet)
        external
        view
        returns (
            uint256[] memory,
            POAPLibrary.Board[] memory,
            POAPLibrary.Board memory
        )
    {
        return (getAllPOAPs(wallet), getBoards(wallet), getCurrentBoard(wallet));
    }

    function getBoard(uint256 boardId) external view returns (POAPLibrary.Board memory) {
        return boards[boardId];
    }

    function _claimPOAP(uint256 poapId, address to) internal existingPOAP(poapId) {
        if (_poapOwners[poapId][to]) return;
        _poapOwners[poapId][to] = true;
        _poaps[to][poapsBalanceOf[to]] = poapId;
        poapsBalanceOf[to]++;
    }

    function _claimBoard(uint256 boardId, address to) internal existingBoard(boardId) {
        require(_minted(to), "mint required");
        require(!availableBoards[to][boardId], "already claimed");
        availableBoards[to][boardId] = true;
    }

    // OWNER FUNCTIONS

    function registerBoard(
        uint64 width,
        uint64 height,
        POAPLibrary.Slot[] memory slots
    ) external onlyOwner {
        boardCount++;
        POAPLibrary.Board storage newBoard = boards[boardCount];
        newBoard.id = uint128(boardCount);
        newBoard.width = width;
        newBoard.height = height;
        for (uint256 index = 0; index < slots.length; index++) {
            newBoard.slots.push(slots[index]);
        }
    }

    function registerPOAP() external onlyOwner {
        poapCount++;
    }

    function setPOAPCount(uint256 count) external onlyOwner {
        poapCount = count;
    }

    function overrideBoard(
        uint128 id,
        uint64 width,
        uint64 height,
        POAPLibrary.Slot[] memory slots
    ) external onlyOwner existingBoard(id) {
        POAPLibrary.Board storage newBoard = boards[id];
        newBoard.id = id;
        newBoard.width = width;
        newBoard.height = height;
        uint256 oldSlotsSize = newBoard.slots.length; // 3
        for (uint256 index = 0; index < slots.length; index++) {
            if (oldSlotsSize <= index) {
                newBoard.slots.push(slots[index]);
            } else {
                newBoard.slots[index] = slots[index];
            }
        }
    }

    function setMerkleRootsByPOAPId(uint256 poapId, bytes32 merkleRoot) external onlyOwner {
        merkleRootsByPOAPId[poapId] = merkleRoot;
    }

    function setMerkleRootsByBoardId(uint256 boardId, bytes32 merkleRoot) external onlyOwner {
        merkleRootsByBoardId[boardId] = merkleRoot;
    }

    modifier existingBoard(uint256 boardId) {
        require(boardId <= boardCount, "unknown board");
        _;
    }

    modifier existingPOAP(uint256 poapId) {
        require(poapId <= poapCount, "unknown poap");
        _;
    }
}
/* solhint-enable quotes */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library POAPLibrary {
    struct Slot {
        uint32 x;
        uint32 y;
        uint32 scale;
    }
    struct Board {
        uint128 id;
        uint64 width;
        uint64 height;
        Slot[] slots;
    }

    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
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

    function _toString(uint256 value) internal pure returns (string memory ptr) {
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
                // Write the character to the pointer. 48 is the ASCII index of '0'.
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

pragma solidity ^0.8.7;

interface IDescriptor {
    function badgeImages(uint256 badgeId) external view returns (string memory);

    function boardImages(uint256 boardId) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getSvg(uint256 id) external view returns (string memory);

    function buildSvg(
        uint256 boardId,
        uint256[] memory poaps,
        string memory boardName,
        bool isPreview
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./POAPLibrary.sol";

interface IBadgesVerifier {
    function claimableBadges(
        uint256[] memory genesisMice,
        uint256[] memory babyMice,
        address wallet
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICheeth is IERC20 {
    function burnFrom(address account, uint256 amount) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.7;

import "./IERC721UniqueBound.sol";

contract ERC721UniqueBound is IERC721UniqueBound {
    uint256 private _currentIndex;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _ownerships;

    mapping(address => uint256) private _ownerToTokenId;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _minted(owner) ? 1 : 0;
    }

    function _minted(address owner) internal view returns (bool) {
        uint256 tokenId = _ownerToTokenId[owner];
        return _ownerships[tokenId] == owner;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownerships[tokenId];
    }

    function tokenOf(address owner) public view override returns (uint256) {
        return _ownerToTokenId[owner];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex;
    }

    function _mint(address to) internal {
        if (to == address(0)) revert MintToZeroAddress();
        if (_minted(to)) revert MintToExistingOwnerAddress();

        _ownerships[_currentIndex] = to;
        _ownerToTokenId[to] = _currentIndex;
        emit Transfer(address(0), to, _currentIndex);
        _currentIndex++;
    }

    function _toString(uint256 value) internal pure returns (string memory ptr) {
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
                // Write the character to the pointer. 48 is the ASCII index of '0'.
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

pragma solidity ^0.8.7;

import "./POAPLibrary.sol";

interface IPOAPBoard {
    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getAllPOAPs(address wallet) external view returns (uint256[] memory);

    function getBoardPOAPs(address wallet) external view returns (uint256[] memory);

    function currentBoard(address wallet) external view returns (uint256);

    function getBoard(uint256 boardId) external view returns (POAPLibrary.Board memory);
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

pragma solidity ^0.8.7;

interface IERC721UniqueBound {
    error MintZeroQuantity();
    error MintToZeroAddress();
    error MintToExistingOwnerAddress();
    error BalanceQueryForZeroAddress();
    error URIQueryForNonexistentToken();

    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}