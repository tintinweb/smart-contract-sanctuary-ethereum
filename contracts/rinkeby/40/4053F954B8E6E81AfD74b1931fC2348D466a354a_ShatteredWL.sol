// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IShatteredWL.sol";
import "./interfaces/IPytheas.sol";
import "./interfaces/IOrbitalBlockade.sol";
import "./interfaces/IColonist.sol";
import "./interfaces/ITColonist.sol";
import "./interfaces/IEON.sol";
import "./interfaces/IRAW.sol";
import "./interfaces/IImperialGuild.sol";

contract ShatteredWL is IShatteredWL, Pausable {
    // address => can call
    mapping(address => bool) private admins;

    struct HonorsList {
        bool isHonorsMember;
        bool hasClaimed;
        uint8 honorsId;
    }

    address public auth;

    address payable ImperialGuildTreasury;

    bool public hasPublicSaleStarted;
    bool public isWLactive;
    bool public isHonorsActive;

    uint256 public constant paidTokens = 10000;
    uint256 public constant whitelistPrice = 0.08 ether;
    uint256 public constant publicPrice = 0.08 ether;

    mapping(address => uint8) private _WLmints;

    mapping(address => HonorsList) private _honorsAddresses;

    event newUser(address newUser);

    bytes32 internal merkleRoot =
        0xd60676eb70cb99e173a40e78e3c1d139722ab50092a4afb575ee44c5c3e78e7f;

    bytes32 internal entropySauce;

    // reference to the colonist NFT collection
    IColonist public colonistNFT;

    constructor() {
        _pause();
        auth = msg.sender;
        admins[msg.sender] = true;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(colonistNFT) != address(0),
            "Contracts not set"
        );
        _;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;

        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }
    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    function setContracts(address _colonistNFT) external onlyOwner {
        colonistNFT = IColonist(_colonistNFT);
    }

    /** EXTERNAL */

    function WlMintColonist(uint256 amount, bytes32[] calldata _merkleProof)
        external
        payable
        noCheaters
        whenNotPaused
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint16 minted = colonistNFT.minted();
        require(isWLactive == true, "whitelist mints not yeat active");
        require(amount > 0 && amount <= 5, "5 max mints per tx");
        require(minted + amount <= paidTokens, "All sale tokens minted");
        require(amount * whitelistPrice == msg.value, "Invalid payment amount");
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not on the list"
        );
        require(_WLmints[msg.sender] + amount <= 5, "limit 5 per whitelist");
        _WLmints[msg.sender] += uint8(amount);

        uint256 seed;
        address origin = tx.origin;
        bytes32 blockies = blockhash(block.number - 1);
        bytes32 sauce = entropySauce;
        uint256 blockTime = block.timestamp;
        uint16[] memory tokenIds = new uint16[](amount);
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(origin, blockies, sauce, minted, blockTime);
            tokenIds[i] = minted;
            colonistNFT._mintColonist(msg.sender, seed);
        }
        emit newUser(msg.sender);
    }

    /** Mint colonist.
     */
    function mintColonist(uint256 amount)
        external
        payable
        noCheaters
        whenNotPaused
    {
        uint16 minted = colonistNFT.minted();
        require(amount > 0 && amount <= 5, "5 max mints per tx");
        require(minted + amount <= paidTokens, "All sale tokens minted");
        require(hasPublicSaleStarted == true, "Public sale not open");
        require(msg.value >= amount * publicPrice, "Invalid Payment amount");
        uint256 seed;
        address origin = tx.origin;
        bytes32 blockies = blockhash(block.number - 1);
        bytes32 sauce = entropySauce;
        uint256 blockTime = block.timestamp;
        uint16[] memory tokenIds = new uint16[](amount);
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(origin, blockies, sauce, minted, blockTime);
            tokenIds[i] = minted;
            colonistNFT._mintColonist(msg.sender, seed);
        }
        emit newUser(msg.sender);
    }

    /**Mint to honors */
    function mintToHonors(uint256 amount, address recipient)
        external
        onlyOwner
    {
        uint16 minted = colonistNFT.minted();
        require(minted + amount <= 1000, "Honor tokens have been sent");
        uint16[] memory tokenIds = new uint16[](amount);
        uint256 seed;
        address origin = tx.origin;
        bytes32 blockies = blockhash(block.number - 1);
        bytes32 sauce = entropySauce;
        uint256 blockTime = block.timestamp;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = random(origin, blockies, sauce, minted, blockTime);
            tokenIds[i] = minted;
            colonistNFT._mintToHonors(address(recipient), seed);
        }
        emit newUser(recipient);
    }

    function revealHonors() external noCheaters {
        require(isHonorsActive == true, "Honor mints have not been activated");
        require(
            _honorsAddresses[msg.sender].isHonorsMember,
            "Not an honors student"
        );
        require(
            _honorsAddresses[msg.sender].hasClaimed == false,
            "Already claimed"
        );

        uint8 id = _honorsAddresses[msg.sender].honorsId;
        _honorsAddresses[msg.sender].hasClaimed = true;
        colonistNFT._mintHonors(msg.sender, id);

        emit newUser(msg.sender);
    }

    function addToHonorslist(address honorsAddress, uint8 honorsId)
        external
        onlyOwner
    {
        _honorsAddresses[honorsAddress] = HonorsList({
            isHonorsMember: true,
            hasClaimed: false,
            honorsId: honorsId
        });
    }

    function togglePublicSale(bool startPublicSale) external onlyOwner {
        hasPublicSaleStarted = startPublicSale;
    }

    function toggleHonorsActive(bool _honorsActive) external onlyOwner {
        isHonorsActive = _honorsActive;
    }

    function toggleWLactive(bool _isWLactive) external onlyOwner {
        isWLactive = _isWLactive;
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function random(
        address origin,
        bytes32 blockies,
        bytes32 sauce,
        uint16 seed,
        uint256 blockTime
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(origin, blockies, blockTime, sauce, seed)
                )
            );
    }

    function setImperialGuildTreasury(address payable _ImperialGuildTreasury)
        external
        onlyOwner
    {
        ImperialGuildTreasury = _ImperialGuildTreasury;
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(ImperialGuildTreasury).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IColonist {
    // struct to store each Colonist's traits
    struct Colonist {
        bool isColonist;
        uint8 background;
        uint8 body;
        uint8 shirt;
        uint8 jacket;
        uint8 jaw;
        uint8 eyes;
        uint8 hair;
        uint8 held;
        uint8 gen;
    }

    struct HColonist {
        uint8 Legendary;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isOwner(uint256 tokenId)
        external
        view
        returns (address);

    function minted() external returns (uint16);

    function totalCir() external returns (uint256);

    function _mintColonist(address recipient, uint256 seed) external;

    function _mintToHonors(address recipient, uint256 seed) external;

    function _mintHonors(address recipient, uint8 id) external;

    function burn(uint256 tokenId) external;

    function getMaxTokens() external view returns (uint256);

    function getPaidTokens() external view returns (uint256);

    function getTokenTraitsColonist(uint256 tokenId)
        external
        view
        returns (Colonist memory);

    function getTokenTraitsHonors(uint256 tokenId)
        external
        view
        returns (HColonist memory);

    function tokenNameByIndex(uint256 index)
        external
        view
        returns (string memory);

    function hasBeenNamed(uint256 tokenId) external view returns (bool);

    function nameColonist(uint256 tokenId, string memory newName) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEON {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IImperialGuild {

    function getBalance(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 paymentId,
        uint16 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint16 qty,
        address burnFrom
    ) external;

    function handlePayment(uint256 amount) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IOrbitalBlockade {
    function addPiratesToCrew(address account, uint16[] calldata tokenIds)
        external;
    
    function claimPiratesFromCrew(address account, uint16[] calldata tokenIds, bool unstake)
        external;

    function payPirateTax(uint256 amount) external;

    function randomPirateOwner(uint256 seed) external view returns (address);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IPytheas {
    function addColonistToPytheas(address account, uint16[] calldata tokenIds)
        external;

    function claimColonistFromPytheas(address account, uint16[] calldata tokenIds, bool unstake)
        external;

    function getColonistMined(address account, uint16 tokenId)
        external
        returns (uint256);

    function handleJoinPirates(address addr, uint16 tokenId) external;

    function payUp(
        uint16 tokenId,
        uint256 amtMined,
        address addr
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRAW {

    function updateOriginAccess(address user) external;


    function balanceOf(
        address account,
        uint256 id
    ) external returns(uint256);

    function mint(
        uint256 typeId,
        uint256 qty,
        address recipient
    ) external;

    function burn(
        uint256 typeId,
        uint256 qty,
        address burnFrom
    ) external;

    function updateMintBurns(
        uint256 typeId,
        uint256 mintQty,
        uint256 burnQty
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IShatteredWL {}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface ITColonist {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}