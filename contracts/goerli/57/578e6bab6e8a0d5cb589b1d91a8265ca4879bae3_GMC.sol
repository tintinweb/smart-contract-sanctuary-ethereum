//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {LibCrumbMap} from "../lib/LibCrumbMap.sol";
import {FxERC721MRoot} from "ERC721M/extensions/FxERC721MRoot.sol";
import {ERC20UDS as ERC20} from "UDS/tokens/ERC20UDS.sol";

import "solady/utils/ECDSA.sol";
import "solady/utils/LibString.sol";

error ExceedsLimit();
error TransferFailed();
error TimelockActive();
error IncorrectValue();
error MaxSupplyLocked();
error InvalidSignature();
error NonexistentToken();
error InvalidPriceUnits();
error InvalidMintChoice();
error WhitelistNotActive();
error PublicSaleNotActive();
error SignatureExceedsLimit();
error ContractCallNotAllowed();

/// @title Gangsta Mice City Root
/// @author phaze (https://github.com/0xPhaze)
contract GMC is OwnableUDS, FxERC721MRoot {
    using ECDSA for bytes32;
    using LibString for uint256;
    using LibCrumbMap for LibCrumbMap.CrumbMap;

    event SaleStateUpdate();
    event FirstLegendaryRaffleEntered(address user);
    event SecondLegendaryRaffleEntered(address user);

    uint16 public constant MAX_PER_WALLET = 20;
    uint256 public constant PURCHASE_LIMIT = 5;
    uint256 public constant BRIDGE_RAFFLE_LOCK_DURATION = 24 hours;
    uint256 private constant PRICE_UNIT = 0.001 ether;
    uint256 private constant GENESIS_CLAIM = 555;

    bool public maxSupplyLocked;
    uint16 public supply;
    uint16 public maxSupply;
    uint32 public mintStart;
    uint8 private publicPriceUnits;
    uint8 private whitelistPriceUnits;
    address private signer;

    string private baseURI;
    string private postFixURI = ".json";
    string private unrevealedURI = "ipfs://QmRuQYxmdzqfVfy8ZhZNTvXsmbN9yLnBFPDeczFvWUS2HU/";

    LibCrumbMap.CrumbMap gangs;

    constructor(address checkpointManager, address fxRoot)
        FxERC721MRoot("Gangsta Mice City", "GMC", checkpointManager, fxRoot)
    {
        __Ownable_init();

        maxSupply = 6666;
        signer = msg.sender;

        publicPriceUnits = toPriceUnits(0.049 ether);
        whitelistPriceUnits = toPriceUnits(0.039 ether);
    }

    /* ------------- view ------------- */

    function totalSupply() public view override returns (uint256) {
        return supply;
    }

    function publicPrice() public view returns (uint256) {
        return toPrice(publicPriceUnits);
    }

    function whitelistPrice() public view returns (uint256) {
        return toPrice(whitelistPriceUnits);
    }

    function gangOf(uint256 id) public view returns (uint256) {
        return gangs.get(id);
    }

    /* ------------- external ------------- */

    function mint(uint256 quantity, bool lock)
        external
        payable
        onlyEOA
        requireMintableSupply(quantity)
        requireMintableByUser(quantity, MAX_PER_WALLET)
    {
        unchecked {
            if (msg.value != publicPrice() * quantity) revert IncorrectValue();
            if (block.timestamp < mintStart || mintStart == 0) revert PublicSaleNotActive();

            mintWithPerks(msg.sender, quantity, lock);
        }
    }

    function whitelistMint(
        uint256 quantity,
        bool lock,
        uint256 limit,
        bytes calldata signature
    ) external payable onlyEOA requireMintableSupply(quantity) requireMintableByUser(quantity, limit) {
        unchecked {
            if (!validSignature(signature, limit)) revert InvalidSignature();
            if (mintStart + 2 hours < block.timestamp) revert WhitelistNotActive();
            if (msg.value != whitelistPrice() * quantity) revert IncorrectValue();

            mintWithPerks(msg.sender, quantity, lock);
        }
    }

    function lockAndTransmit(address from, uint256[] calldata tokenIds) external {
        unchecked {
            if (tokenIds.length > 10) revert ExceedsLimit();
            if (tokenIds.length != 0 && block.timestamp < mintStart + 2 hours) emit SecondLegendaryRaffleEntered(from);

            _lockAndTransmit(from, tokenIds);
        }
    }

    function unlockAndTransmit(address from, uint256[] calldata tokenIds) external {
        if (block.timestamp < mintStart + BRIDGE_RAFFLE_LOCK_DURATION) {
            revert TimelockActive();
        }

        _unlockAndTransmit(from, tokenIds);
    }

    /* ------------- private ------------- */

    function validSignature(bytes calldata signature, uint256 limit) private view returns (bool) {
        bytes32 hash = keccak256(abi.encode(address(this), msg.sender, limit));
        address recovered = hash.toEthSignedMessageHash().recover(signature);

        return recovered != address(0) && recovered == signer;
    }

    function toPrice(uint16 priceUnits) private pure returns (uint256) {
        unchecked {
            return uint256(priceUnits) * PRICE_UNIT;
        }
    }

    function toPriceUnits(uint256 price) private pure returns (uint8) {
        unchecked {
            uint256 units;

            if (price % PRICE_UNIT != 0) revert InvalidPriceUnits();
            if ((units = price / PRICE_UNIT) > type(uint8).max) revert InvalidPriceUnits();

            return uint8(units);
        }
    }

    function mintWithPerks(
        address to,
        uint256 quantity,
        bool lock
    ) private {
        unchecked {
            if (quantity > 2) {
                emit FirstLegendaryRaffleEntered(to);

                if (supply < 500 + GENESIS_CLAIM) ++quantity;
            }

            if (lock && block.timestamp < mintStart + 2 hours) emit SecondLegendaryRaffleEntered(to);

            if (lock) _mintLockedAndTransmit(to, quantity);
            else _mint(to, quantity);
        }
    }

    /* ------------- owner ------------- */

    function pause() external onlyOwner {
        mintStart = 0;
    }

    function lockMaxSupply() external onlyOwner {
        maxSupplyLocked = true;
    }

    function setSigner(address addr) external onlyOwner {
        signer = addr;
    }

    function setMaxSupply(uint16 value) external onlyOwner {
        if (maxSupplyLocked) revert MaxSupplyLocked();

        maxSupply = value;
    }

    function setMintStart(uint32 time) external onlyOwner {
        mintStart = time;
    }

    function setPublicPrice(uint256 value) external onlyOwner {
        publicPriceUnits = toPriceUnits(value);
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setPostFixURI(string calldata postFix) external onlyOwner {
        postFixURI = postFix;
    }

    function setWhitelistPrice(uint256 value) external onlyOwner {
        whitelistPriceUnits = toPriceUnits(value);
    }

    function setUnrevealedURI(string calldata uri) external onlyOwner {
        unrevealedURI = uri;
    }

    function setGangs(uint256[] calldata chunkIndices, uint256[] calldata chunks) external onlyOwner {
        for (uint256 i; i < chunkIndices.length; ++i) gangs.set32BytesChunk(chunkIndices[i], chunks[i]);
    }

    function airdrop(
        address[] calldata users,
        uint256 quantity,
        bool locked
    ) external onlyOwner requireMintableSupply(quantity * users.length) {
        if (locked) for (uint256 i; i < users.length; ++i) _mintLockedAndTransmit(users[i], quantity);
        else for (uint256 i; i < users.length; ++i) _mint(users[i], quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");

        if (!success) revert TransferFailed();
    }

    function recoverToken(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));

        token.transfer(msg.sender, balance);
    }

    /* ------------- override ------------- */

    function _authorizeTunnelController() internal override onlyOwner {}

    function _increaseTotalSupply(uint256 amount) internal override {
        supply += uint16(amount);
    }

    /* ------------- modifier ------------- */

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }

    modifier requireMintableByUser(uint256 quantity, uint256 limit) {
        unchecked {
            if (quantity > PURCHASE_LIMIT) revert ExceedsLimit();
            if (quantity + numMinted(msg.sender) > limit) revert ExceedsLimit();
        }
        _;
    }

    modifier requireMintableSupply(uint256 quantity) {
        unchecked {
            if (quantity + supply > maxSupply) revert ExceedsLimit();
        }
        _;
    }

    /* ------------- ERC721 ------------- */

    function tokenURI(uint256 id) public view override returns (string memory) {
        return 
            bytes(baseURI).length == 0 
              ? unrevealedURI 
              : string.concat(baseURI, id.toString(), postFixURI); // prettier-ignore
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "../utils/Context.sol";
import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_OWNABLE = keccak256("diamond.storage.ownable");

function s() pure returns (OwnableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_OWNABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct OwnableDS {
    address owner;
}

// ------------- errors

error CallerNotOwner();

/// @title Ownable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev Requires `__Ownable_init` to be called in proxy
abstract contract OwnableUDS is Context, Initializable {
    OwnableDS private __storageLayout; // storage layout for upgrade compatibility checks

    event OwnerChanged(address oldOwner, address newOwner);

    function __Ownable_init() internal initializer {
        s().owner = _msgSender();
    }

    /* ------------- external ------------- */

    function owner() public view returns (address) {
        return s().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(_msgSender(), newOwner);
    }

    /* ------------- modifier ------------- */

    modifier onlyOwner() {
        if (_msgSender() != s().owner) revert CallerNotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

using LibCrumbMap for LibCrumbMap.CrumbMap;


/// @notice Efficient crumb map library for mapping integers to crumbs.
/// @author phaze (https://github.com/0xPhaze)
/// @author adapted from Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBytemap.sol)
library LibCrumbMap {
    struct CrumbMap {
        mapping(uint256 => uint256) map;
    }

    /* ------------- CrumbMap ------------- */

    function get(CrumbMap storage crumbMap, uint256 index) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            result := and(shr(shl(1, and(index, 0x7f)), sload(keccak256(0x00, 0x20))), 0x03)
        }
    }

    function get32BytesChunk(CrumbMap storage crumbMap, uint256 bytesIndex) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            result := sload(keccak256(0x00, 0x20))
        }
    }

    function set32BytesChunk(
        CrumbMap storage crumbMap,
        uint256 bytesIndex,
        uint256 value
    ) internal {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            sstore(keccak256(0x00, 0x20), value)
        }
    }

    function set(
        CrumbMap storage crumbMap,
        uint256 index,
        uint256 value
    ) internal {
        require(value < 4);

        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            let storageSlot := keccak256(0x00, 0x20)
            let shift := shl(1, and(index, 0x7f))
            // Unset crumb at index and store.
            let chunkValue := and(sload(storageSlot), not(shl(shift, 0x03)))
            // Set crumb to `value` at index and store.
            chunkValue := or(chunkValue, shl(shift, value))
            sstore(storageSlot, chunkValue)
        }
    }

    /* ------------- mapping(uint256 => uint256) ------------- */

    function get(mapping(uint256 => uint256) storage crumbMap, uint256 index) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            result := and(shr(shl(1, and(index, 0x7f)), sload(keccak256(0x00, 0x20))), 0x03)
        }
    }

    function get32BytesChunk(mapping(uint256 => uint256) storage crumbMap, uint256 bytesIndex) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            result := sload(keccak256(0x00, 0x20))
        }
    }

    function set32BytesChunk(
        mapping(uint256 => uint256) storage crumbMap,
        uint256 bytesIndex,
        uint256 value
    ) internal {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            sstore(keccak256(0x00, 0x20), value)
        }
    }

    function set(
        mapping(uint256 => uint256) storage crumbMap,
        uint256 index,
        uint256 value
    ) internal {
        require(value < 4);

        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            let storageSlot := keccak256(0x00, 0x20)
            let shift := shl(1, and(index, 0x7f))
            // Unset crumb at index and store.
            let chunkValue := and(sload(storageSlot), not(shl(shift, 0x03)))
            // Set crumb to `value` at index and store.
            chunkValue := or(chunkValue, shl(shift, value))
            sstore(storageSlot, chunkValue)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721M} from "../ERC721M.sol";
import {ERC721MQuery} from "./ERC721MQuery.sol";
import {FxERC721Root} from "fx-contracts/FxERC721Root.sol";

/// @title ERC721M FxPortal extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract FxERC721MRoot is FxERC721Root, ERC721M, ERC721MQuery {
    constructor(
        string memory name,
        string memory symbol,
        address checkpointManager,
        address fxRoot
    ) ERC721M(name, symbol) FxERC721Root(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) external view virtual override returns (string memory);

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _mintLockedAndTransmit(address to, uint256 quantity) internal virtual {
        _mintLockedAndTransmit(to, quantity, 0);
    }

    function _mintLockedAndTransmit(
        address to,
        uint256 quantity,
        uint48 auxData
    ) internal virtual {
        uint256 startId = _nextTokenId();

        _mintAndLock(to, quantity, true, auxData);

        uint256[] memory ids = new uint256[](quantity);

        unchecked {
            for (uint256 i; i < quantity; ++i) {
                ids[i] = startId + i;
            }
        }

        _registerERC721IdsWithChildMem(to, ids);
    }

    function _lockAndTransmit(address from, uint256[] calldata ids) internal virtual {
        unchecked {
            for (uint256 i; i < ids.length; ++i) {
                _lock(from, ids[i]);
            }
        }

        _registerERC721IdsWithChild(from, ids);
    }

    // @notice using `_unlockAndTransmit` is simple and easy
    // this assumes L1 state as the single source of truth
    // messages are always pushed L1 -> L2 without knowing state on L2
    // this means that NFTs should not be allowed to be traded/sold on L2
    // alternatively `_unlockWithProof` should be implemented requiring
    // a MPT inclusion proof.
    function _unlockAndTransmit(address from, uint256[] calldata ids) internal virtual {
        unchecked {
            for (uint256 i; i < ids.length; ++i) _unlock(from, ids[i]);
        }

        _registerERC721IdsWithChild(address(0), ids);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Context} from "../utils/Context.sol";
import {Initializable} from "../utils/Initializable.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC20 = keccak256("diamond.storage.erc20");

function s() pure returns (ERC20DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC20;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct ERC20DS {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
}

/// @title ERC20 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
abstract contract ERC20UDS is Context, Initializable, EIP712PermitUDS {
    ERC20DS private __storageLayout; // storage layout for upgrade compatibility checks

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed operator, uint256 amount);

    /* ------------- init ------------- */

    function __ERC20_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initializer {
        s().name = _name;
        s().symbol = _symbol;
        s().decimals = _decimals;
    }

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return s().decimals;
    }

    function totalSupply() external view virtual returns (uint256) {
        return s().totalSupply;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return s().balanceOf[owner];
    }

    function allowance(address owner, address operator) public view virtual returns (uint256) {
        return s().allowance[owner][operator];
    }

    /* ------------- public ------------- */

    function approve(address operator, uint256 amount) public virtual returns (bool) {
        s().allowance[_msgSender()][operator] = amount;

        emit Approval(_msgSender(), operator, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        s().balanceOf[_msgSender()] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(_msgSender(), to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = s().allowance[from][_msgSender()];

        if (allowed != type(uint256).max) s().allowance[from][_msgSender()] = allowed - amount;

        s().balanceOf[from] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    // EIP-2612 permit
    function permit(
        address owner,
        address operator,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, value, deadline, v, r, s_);

        s().allowance[owner][operator] = value;

        emit Approval(owner, operator, value);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 amount) internal virtual {
        s().totalSupply += amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        s().balanceOf[from] -= amount;

        unchecked {
            s().totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
library ECDSA {
    function recover(bytes32 hash, bytes calldata signature) internal view returns (address result) {
        assembly {
            if eq(signature.length, 65) {
                // Copy the free memory pointer so that we can restore it later.
                let m := mload(0x40)
                // Directly copy `r` and `s` from the calldata.
                calldatacopy(0x40, signature.offset, 0x40)

                // If `s` in lower half order, such that the signature is not malleable.
                // prettier-ignore
                if iszero(gt(mload(0x60), 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                    mstore(0x00, hash)
                    // Compute `v` and store it in the scratch space.
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
                    pop(
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            0x01, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x40, // Start of output.
                            0x20 // Size of output.
                        )
                    )
                    // Restore the zero slot.
                    mstore(0x60, 0)
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    result := mload(sub(0x60, returndatasize()))
                }
                // Restore the free memory pointer.
                mstore(0x40, m)
            }
        }
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (address result) {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            // prettier-ignore
            let s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)

            // If `s` in lower half order, such that the signature is not malleable.
            // prettier-ignore
            if iszero(gt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                mstore(0x00, hash)
                mstore(0x20, add(shr(255, vs), 27))
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes (i.e. 0x1a).
            // The next multiple of 32 above 78 + 26 is 128 (i.e. 0x80).

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            // prettier-ignore
            for { let temp := sLength } 1 {} {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Copy the header over to the memory.
            mstore(sub(ptr, 0x20), "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n")
            // Compute the keccak256 of the memory.
            result := keccak256(sub(ptr, 0x1a), sub(end, sub(ptr, 0x1a)))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = uint256(int256(-1));

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     DECIMAL OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   HEXADECIMAL OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x02 + 0x28) is 0x60.
            str := add(start, 0x60)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   OTHER STRING OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `subject` all occurances of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            // Zeroize the slot after the string.
            mstore(resultRemainder, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, add(result, and(add(k, 63), not(31))))
            result := sub(result, 0x20)
            mstore(result, k)
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                // `from = min(from, fromMax)`.
                from := xor(from, mul(xor(from, fromMax), lt(fromMax, from)))
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    function slice(
        string memory subject,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            // `end = min(end, subjectLength)`.
            end := xor(end, mul(xor(end, subjectLength), lt(subjectLength, end)))
            // `start = min(start, subjectLength)`.
            start := xor(start, mul(xor(start, subjectLength), lt(subjectLength, start)))
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), not(31)) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behaviour is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        assembly {
            // Grab the free memory pointer.
            result := mload(0x40)
            // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(0x40, add(result, 0x40))
            // Zeroize the length slot.
            mstore(result, 0)
            // Store the length and bytes.
            mstore(add(result, 0x1f), packed)
            // Right pad with zeroes.
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        assembly {
            let aLength := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes of `a` and `b`.
                or(shl(shl(3, sub(0x1f, aLength)), mload(add(a, aLength))), mload(sub(add(b, 0x1e), aLength))),
                // `totalLength != 0 && totalLength < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLength, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behaviour is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        assembly {
            // Grab the free memory pointer.
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        assembly {
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(add(a, 0x20), mload(a)), 0)
            // Store the return offset.
            // Assumes that the string does not start from the scratch space.
            mstore(sub(a, 0x20), 0x20)
            // End the transaction, returning the string.
            return(sub(a, 0x20), add(mload(a), 0x40))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Context
/// @notice Overridable context for meta-transactions
/// @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
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

import {s as erc1967ds} from "../proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @title Initializable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev functions using the `initializer` modifier are only callable during proxy deployment
/// @dev functions using the `reinitializer` modifier are only callable through a proxy
/// @dev and only before a proxy upgrade migration has completed
/// @dev (only when `upgradeToAndCall`'s `initCalldata` is being executed)
/// @dev allows re-initialization during upgrades
abstract contract Initializable {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this).code.length != 0) revert AlreadyInitialized();
        _;
    }

    modifier reinitializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967ds().implementation == __implementation) revert AlreadyInitialized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EIP712PermitUDS} from "UDS/auth/EIP712PermitUDS.sol";
import {UserDataOps, TokenDataOps} from "./ERC721MLibrary.sol";

// ------------- storage

struct ERC721MStorage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) userData;
    mapping(uint256 => uint256) tokenData;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

bytes32 constant DIAMOND_STORAGE_ERC721M_LOCKABLE = keccak256("diamond.storage.erc721m.lockable");

function s() pure returns (ERC721MStorage storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC721M_LOCKABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

// ------------- errors

error IncorrectOwner();
error TokenIdUnlocked();
error NonexistentToken();
error MintZeroQuantity();
error MintToZeroAddress();
error TransferFromInvalidTo();
error TransferToZeroAddress();
error CallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721Receiver();

/// @title ERC721M (Integrated Token Locking)
/// @author phaze (https://github.com/0xPhaze/ERC721M)
/// @author modified from ERC721A (https://github.com/chiru-labs/ERC721A)
/// @author modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @notice Integrates EIP712Permit
abstract contract ERC721M is EIP712PermitUDS {
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    uint256 constant startingIndex = 1;

    constructor(string memory name_, string memory symbol_) {
        __ERC721_init(name_, symbol_);
    }

    /* ------------- init ------------- */

    function __ERC721_init(string memory name_, string memory symbol_) internal {
        s().name = name_;
        s().symbol = symbol_;
    }

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function balanceOf(address user) public view virtual returns (uint256) {
        return s().userData[user].balance();
    }

    function getApproved(uint256 id) external view virtual returns (address) {
        return s().getApproved[id];
    }

    function isApprovedForAll(address owner, address spender) external view virtual returns (bool) {
        return s().isApprovedForAll[owner][spender];
    }

    function ownerOf(uint256 id) public view virtual returns (address) {
        return _tokenDataOf(id).owner();
    }

    function totalSupply() public view virtual returns (uint256) {
        return s().totalSupply;
    }

    function getAux(uint256 id) public view returns (uint256) {
        return _tokenDataOf(id).aux();
    }

    function getLockStart(uint256 id) public view returns (uint256) {
        return _tokenDataOf(id).tokenLockStart();
    }

    function numMinted(address user) public view virtual returns (uint256) {
        return s().userData[user].numMinted();
    }

    function numLocked(address user) public view virtual returns (uint256) {
        return s().userData[user].numLocked();
    }

    function getLockStart(address user) public view virtual returns (uint256) {
        return s().userData[user].userLockStart();
    }

    function trueOwnerOf(uint256 id) public view virtual returns (address) {
        return _tokenDataOf(id).trueOwner();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- public ------------- */

    function approve(address spender, uint256 id) public virtual {
        address owner = _tokenDataOf(id).owner();

        if (msg.sender != owner && !s().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        s().getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        s().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _isApprovedOrOwner(address from, uint256 id) private view returns (bool) {
        return (msg.sender == from || s().isApprovedForAll[from][msg.sender] || s().getApproved[id] == msg.sender);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(this)) revert TransferFromInvalidTo();
        if (to == address(0)) revert TransferToZeroAddress();

        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (tokenData.owner() != from) revert TransferFromIncorrectOwner();

        delete s().getApproved[id];

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.setOwner(to).flagNextTokenDataSet();

        s().userData[to] = s().userData[to].increaseBalance(1);
        s().userData[from] = s().userData[from].decreaseBalance(1);

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);
        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            IERC721Receiver(to).onERC721Received.selector
        ) revert TransferToNonERC721Receiver();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        _usePermit(owner, operator, 1, deadline, v, r, s_);

        s().isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    /* ------------- internal ------------- */

    function _exists(uint256 id) internal view virtual returns (bool) {
        return startingIndex <= id && id < _nextTokenId();
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        return startingIndex + totalSupply();
    }

    function _increaseTotalSupply(uint256 amount) internal virtual {
        if (amount != 0) s().totalSupply = _nextTokenId() + amount - 1;
    }

    function _tokenDataOf(uint256 id) internal view virtual returns (uint256 out) {
        if (!_exists(id)) revert NonexistentToken();

        unchecked {
            uint256 tokenData;

            for (uint256 curr = id; ; curr--) {
                tokenData = s().tokenData[curr];

                if (tokenData != 0) return tokenData;
            }
        }
    }

    function _ensureTokenDataSet(uint256 id, uint256 tokenData) internal virtual {
        if (!tokenData.nextTokenDataSet() && s().tokenData[id] == 0 && _exists(id)) s().tokenData[id] = tokenData;
    }

    function _mint(address to, uint256 quantity) internal virtual {
        _mintAndLock(to, quantity, false, 0);
    }

    function _mint(
        address to,
        uint256 quantity,
        uint48 auxData
    ) internal virtual {
        _mintAndLock(to, quantity, false, auxData);
    }

    function _mintAndLock(
        address to,
        uint256 quantity,
        bool lock
    ) internal virtual {
        _mintAndLock(to, quantity, lock, 0);
    }

    function _mintAndLock(
        address to,
        uint256 quantity,
        bool lock,
        uint48 auxData
    ) internal virtual {
        unchecked {
            if (quantity == 0) revert MintZeroQuantity();
            if (to == address(0)) revert MintToZeroAddress();

            uint256 startTokenId = _nextTokenId();
            uint256 tokenData = uint256(uint160(to)).setAux(auxData);
            uint256 userData = s().userData[to];

            // don't have to care about next token data if only minting one
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();
            if (lock) {
                tokenData = tokenData.setConsecutiveLocked().lock();

                userData = userData.increaseNumLocked(quantity).setUserLockStart(block.timestamp);

                for (uint256 i; i < quantity; ++i) {
                    emit Transfer(address(0), to, startTokenId + i);
                    emit Transfer(to, address(this), startTokenId + i);
                }
            } else {
                for (uint256 i; i < quantity; ++i) {
                    emit Transfer(address(0), to, startTokenId + i);
                }
            }

            s().userData[to] = userData.increaseNumMinted(quantity).increaseBalance(quantity);
            s().tokenData[startTokenId] = tokenData;

            _increaseTotalSupply(quantity);
        }
    }

    function _setAux(uint256 id, uint48 aux) internal virtual {
        uint256 tokenData = _tokenDataOf(id);

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.setAux(aux);
    }

    function _lock(address from, uint256 id) internal virtual {
        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (tokenData.owner() != from) revert IncorrectOwner();

        delete s().getApproved[id];

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.lock().unsetConsecutiveLocked().flagNextTokenDataSet();
        s().userData[from] = s().userData[from].increaseNumLocked(1).setUserLockStart(block.timestamp);

        emit Transfer(from, address(this), id);
    }

    function _unlock(address from, uint256 id) internal virtual {
        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (!tokenData.locked()) revert TokenIdUnlocked();
        if (tokenData.trueOwner() != from) revert IncorrectOwner();

        // if isConsecutiveLocked flag is set, we need to make sure that next tokenData is set
        // because tokenData in this case is implicit and needs to carry over
        if (tokenData.isConsecutiveLocked()) {
            unchecked {
                _ensureTokenDataSet(id + 1, tokenData);

                tokenData = tokenData.unsetConsecutiveLocked().flagNextTokenDataSet();
            }
        }

        s().tokenData[id] = tokenData.unlock();
        s().userData[from] = s().userData[from].decreaseNumLocked(1).setUserLockStart(block.timestamp);

        emit Transfer(address(this), from, id);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721MLibrary.sol";
import {ERC721M, s} from "../ERC721M.sol";

/// @title ERC721M Query Extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract ERC721MQuery is ERC721M {
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    /* ------------- O(n) read-only ------------- */

    function getOwnedIds(address user) external view returns (uint256[] memory) {
        return utils.getOwnedIds(s().tokenData, user, startingIndex, totalSupply());
    }

    function getLockedIds(address user) external view returns (uint256[] memory) {
        return utils.getLockedIds(s().tokenData, user, startingIndex, totalSupply());
    }

    function getUnlockedIds(address user) external view returns (uint256[] memory) {
        return utils.getUnlockedIds(s().tokenData, user, startingIndex, totalSupply());
    }

    function totalNumLocked() external view returns (uint256) {
        uint256 data;
        uint256 count;
        uint256 endIndex = _nextTokenId();
        uint256 currentData;

        unchecked {
            for (uint256 i = startingIndex; i < endIndex; ++i) {
                data = s().tokenData[i];
                if (data != 0) currentData = data;
                if (currentData.locked()) ++count;
            }
        }

        return count;
    }
}

/// @title ERC721M Query Utils
/// @author phaze (https://github.com/0xPhaze/ERC721M)
library utils {
    using TokenDataOps for uint256;

    function getOwnedIds(
        mapping(uint256 => uint256) storage tokenDataOf,
        address user,
        uint256 start,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 0x20)
        }

        unchecked {
            uint256 data;
            uint256 currentData;
            uint256 end = collectionSize + start;
            for (uint256 id = start; id < end; ++id) {
                data = tokenDataOf[id];
                if (data != 0) currentData = data;
                if (user == address(uint160(currentData))) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 0x20)
                    }
                }
            }
        }

        assembly {
            mstore(ids, shr(5, sub(sub(memPtr, ids), 0x20)))
            mstore(0x40, memPtr)
        }
    }

    function getLockedIds(
        mapping(uint256 => uint256) storage tokenDataOf,
        address user,
        uint256 start,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 0x20)
        }

        unchecked {
            uint256 data;
            uint256 currentData;
            uint256 end = collectionSize + start;
            for (uint256 id = start; id < end; ++id) {
                data = tokenDataOf[id];
                if (data != 0) currentData = data;
                if (user == address(uint160(currentData)) && currentData.locked()) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 0x20)
                    }
                }
            }
        }

        assembly {
            mstore(ids, shr(5, sub(sub(memPtr, ids), 0x20)))
            mstore(0x40, memPtr)
        }
    }

    function getUnlockedIds(
        mapping(uint256 => uint256) storage tokenDataOf,
        address user,
        uint256 start,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 0x20)
        }

        unchecked {
            uint256 data;
            uint256 currentData;
            uint256 end = collectionSize + start;
            for (uint256 id = start; id < end; ++id) {
                data = tokenDataOf[id];
                if (data != 0) currentData = data;
                if (user == address(uint160(currentData)) && !currentData.locked()) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 0x20)
                    }
                }
            }
        }

        assembly {
            mstore(ids, shr(5, sub(sub(memPtr, ids), 0x20)))
            mstore(0x40, memPtr)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "./base/FxBaseRootTunnel.sol";

bytes4 constant REGISTER_ERC721_IDS_SELECTOR = bytes4(keccak256("registerERC721IdsWithChild(address,uint256[])"));
bytes4 constant DEREGISTER_ERC721_IDS_SELECTOR = bytes4(keccak256("deregisterERC721IdsWithChild(uint256[])"));

/// @title ERC721 FxRootTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721Root is FxBaseRootTunnel {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnel(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _registerERC721IdsWithChild(address to, uint256[] calldata ids) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721_IDS_SELECTOR, to, ids));
    }

    function _registerERC721IdsWithChildMem(address to, uint256[] memory ids) internal virtual {
        _sendMessageToChild(abi.encodeWithSelector(REGISTER_ERC721_IDS_SELECTOR, to, ids));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = keccak256("diamond.storage.eip.712.permit");

function s() pure returns (EIP2612DS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_EIP_712_PERMIT;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @title EIP712Permit (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @dev `DOMAIN_SEPARATOR` needs to be re-computed every time
/// @dev for use with a proxy due to `address(this)`
abstract contract EIP712PermitUDS {
    EIP2612DS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256("EIP712"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        if (deadline < block.timestamp) revert DeadlineExpired();

        unchecked {
            uint256 nonce = s().nonces[owner]++;

            address recovered = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v_,
                r_,
                s_
            );

            if (recovered == address(0) || recovered != owner) revert InvalidSigner();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @title ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        if (ERC1822(logic).proxiableUUID() != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();

        if (data.length != 0) {
            (bool success, ) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }

        s().implementation = logic;

        emit Upgraded(logic);
    }
}

/// @title Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @title ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Library used for bitmap manipulation for ERC721M
/// @author phaze (https://github.com/0xPhaze/ERC721M)
library UserDataOps {
    /* ------------- balance: [0, 20) ------------- */

    function balance(uint256 userData) internal pure returns (uint256) {
        return userData & 0xFFFFF;
    }

    function increaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + amount;
        }
    }

    function decreaseBalance(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - amount;
        }
    }

    /* ------------- numMinted: [20, 40) ------------- */

    function numMinted(uint256 userData) internal pure returns (uint256) {
        return (userData >> 20) & 0xFFFFF;
    }

    function increaseNumMinted(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 20);
        }
    }

    /* ------------- numLocked: [40, 60) ------------- */

    function numLocked(uint256 userData) internal pure returns (uint256) {
        return (userData >> 40) & 0xFFFFF;
    }

    function increaseNumLocked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData + (amount << 40);
        }
    }

    function decreaseNumLocked(uint256 userData, uint256 amount) internal pure returns (uint256) {
        unchecked {
            return userData - (amount << 40);
        }
    }

    /* ------------- lockStart: [60, 100) ------------- */

    function userLockStart(uint256 userData) internal pure returns (uint256) {
        return (userData >> 60) & 0xFFFFFFFFFF;
    }

    function setUserLockStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
        return (userData & ~uint256(0xFFFFFFFFFF << 60)) | (timestamp << 60);
    }

    // /* ------------- aux: [100, 256) ------------- */

    // function aux(uint256 userData) internal pure returns (uint256) {
    //     return (userData >> 100) & 0xFFFFFFFFFF;
    // }

    // function setAux(uint256 userData, uint256 aux_) internal pure returns (uint256) {
    //     return (userData & ~((uint256(1) << 100) - 1)) | (aux_ << 100);
    // }
}

library TokenDataOps {
    /// @dev Big question whether copy should transfer over data, such as,
    ///      aux data and timestamps
    function copy(uint256 tokenData) internal pure returns (uint256) {
        return tokenData;
    }

    // return tokenData & ((uint256(1) << (160 + (((tokenData >> 160) & 1) << 1))) - 1);
    /// ^ equivalent code:
    // function copy2(uint256 tokenData) internal pure returns (uint256) {
    //     uint256 copiedData = uint160(tokenData);
    //     if (isConsecutiveLocked(tokenData)) {
    //         copiedData = setConsecutiveLocked(copiedData);
    //         if (locked(tokenData)) copiedData = lock(copiedData);
    //     }
    //     return copiedData;
    // }

    /* ------------- owner: [0, 160) ------------- */

    function owner(uint256 tokenData) internal view returns (address) {
        return locked(tokenData) ? address(this) : trueOwner(tokenData);
    }

    function setOwner(uint256 tokenData, address owner_) internal pure returns (uint256) {
        return (tokenData & 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000) | uint160(owner_);
    }

    function trueOwner(uint256 tokenData) internal pure returns (address) {
        return address(uint160(tokenData));
    }

    /* ------------- consecutiveLock: [160, 161) ------------- */

    function isConsecutiveLocked(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 160) & uint256(1)) != 0;
    }

    function setConsecutiveLocked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 160);
    }

    function unsetConsecutiveLocked(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 160);
    }

    /* ------------- locked: [161, 162) ------------- */

    function locked(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 161) & uint256(1)) != 0; // Note: this is not masked and can carry over when calling 'ownerOf'
    }

    function lock(uint256 tokenData) internal view returns (uint256) {
        return setTokenLockStart(tokenData, block.timestamp) | (uint256(1) << 161);
    }

    function unlock(uint256 tokenData) internal view returns (uint256) {
        return setTokenLockStart(tokenData, block.timestamp) & ~(uint256(1) << 161);
    }

    /* ------------- nextTokenDataSet: [162, 163) ------------- */

    function nextTokenDataSet(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 162) & uint256(1)) != 0;
    }

    function flagNextTokenDataSet(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 162); // nextTokenDatatSet flag (don't repeat the read/write)
    }

    /* ------------- lockStart: [168, 208) ------------- */

    function tokenLockStart(uint256 tokenData) internal pure returns (uint256) {
        return (tokenData >> 168) & 0xFFFFFFFFFF;
    }

    function setTokenLockStart(uint256 tokenData, uint256 timestamp) internal pure returns (uint256) {
        return (tokenData & ~uint256(0xFFFFFFFFFF << 168)) | (timestamp << 168);
    }

    /* ------------- aux: [208, 256) ------------- */

    function aux(uint256 tokenData) internal pure returns (uint256) {
        return tokenData >> 208;
    }

    function setAux(uint256 tokenData, uint256 auxData) internal pure returns (uint256) {
        return (tokenData & ~uint256(0xFFFFFFFFFFFF << 208)) | (auxData << 208);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Merkle} from "../lib/Merkle.sol";
import {RLPReader} from "../lib/RLPReader.sol";
import {ExitPayloadReader} from "../lib/ExitPayloadReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";

// ------------- interfaces

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

interface ICheckpointManager {
    function headerBlocks(uint256 headerNumber)
        external
        view
        returns (
            bytes32 root,
            uint256 start,
            uint256 end,
            uint256 createdAt,
            address proposer
        );
}

// ------------- storage

bytes32 constant DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL = keccak256("diamond.storage.fx.base.root.tunnel");

function s() pure returns (FxBaseRootTunnelDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct FxBaseRootTunnelDS {
    address fxChildTunnel;
    mapping(bytes32 => bool) processedExits;
}

// ------------- errors

error FxChildUnset();
error InvalidHeader();
error InvalidSelector();
error InvalidReceiptProof();
error InvalidFxChildTunnel();
error ExitAlreadyProcessed();

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    bytes32 private constant SEND_MESSAGE_EVENT_SELECTOR =
        0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    IFxStateSender private immutable fxRoot;
    ICheckpointManager private immutable checkpointManager;

    constructor(address checkpointManager_, address fxRoot_) {
        checkpointManager = ICheckpointManager(checkpointManager_);
        fxRoot = IFxStateSender(fxRoot_);
    }

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual;

    /* ------------- view ------------- */

    function fxChildTunnel() public view virtual returns (address) {
        return s().fxChildTunnel;
    }

    function processedExits(bytes32 exitHash) public view virtual returns (bool) {
        return s().processedExits[exitHash];
    }

    function setFxChildTunnel(address fxChildTunnel_) public virtual {
        _authorizeTunnelController();

        s().fxChildTunnel = fxChildTunnel_;
    }

    /* ------------- internal ------------- */

    function _sendMessageToChild(bytes memory message) internal virtual {
        if (s().fxChildTunnel == address(0)) revert FxChildUnset();

        fxRoot.sendMessageToChild(s().fxChildTunnel, message);
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param proofData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function _validateAndExtractMessage(bytes memory proofData) internal returns (bytes memory) {
        address childTunnel = s().fxChildTunnel;

        if (childTunnel == address(0)) revert FxChildUnset();

        ExitPayloadReader.ExitPayload memory payload = proofData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );

        if (s().processedExits[exitHash]) revert ExitAlreadyProcessed();

        s().processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        if (childTunnel != log.getEmitter()) revert InvalidFxChildTunnel();

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        if (!MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot))
            revert InvalidReceiptProof();

        (bytes32 headerRoot, uint256 startBlock, , , ) = checkpointManager.headerBlocks(payload.getHeaderNumber());

        bytes32 leaf = keccak256(
            abi.encodePacked(blockNumber, payload.getBlockTime(), payload.getTxRoot(), receiptRoot)
        );

        if (!leaf.checkMembership(blockNumber - startBlock, headerRoot, payload.getBlockProof()))
            revert InvalidHeader();

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        if (bytes32(topics.getField(0).toUint()) != SEND_MESSAGE_EVENT_SELECTOR) revert InvalidSelector();

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message

        return message;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant WORD_SIZE = 32;

    struct ExitPayload {
        RLPReader.RLPItem[] data;
    }

    struct Receipt {
        RLPReader.RLPItem[] data;
        bytes raw;
        uint256 logIndex;
    }

    struct Log {
        RLPReader.RLPItem data;
        RLPReader.RLPItem[] list;
    }

    struct LogTopics {
        RLPReader.RLPItem[] data;
    }

    // copy paste of private copy() from RLPReader to avoid changing of existing contracts
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
        RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
        receipt.raw = payload.data[6].toBytes();
        RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

        if (receiptItem.isList()) {
            // legacy tx
            receipt.data = receiptItem.toList();
        } else {
            // pop first byte before parsting receipt
            bytes memory typedBytes = receipt.raw;
            bytes memory result = new bytes(typedBytes.length - 1);
            uint256 srcPtr;
            uint256 destPtr;
            assembly {
                srcPtr := add(33, typedBytes)
                destPtr := add(0x20, result)
            }

            copy(srcPtr, destPtr, result.length);
            receipt.data = result.toRlpItem().toList();
        }

        receipt.logIndex = getReceiptLogIndex(payload);
        return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[9].toUint();
    }

    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns (Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns (address) {
        return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns (LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns (bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
        return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
        return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }

        return false;
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}