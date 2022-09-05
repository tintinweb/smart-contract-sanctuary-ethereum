// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "/tokens/GMCRoot.sol";

contract MockGMCRoot is GMC {
    constructor(address checkpointManager, address fxRoot) GMC(checkpointManager, fxRoot) {}

    function freeMint(
        address to,
        uint256 quantity,
        bool lock
    ) public {
        if (lock) _mintLockedAndTransmit(to, quantity);
        else _mint(to, quantity);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxERC721MRootUDS} from "fx-contracts/extensions/FxERC721MRootUDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {ERC20UDS as ERC20} from "UDS/tokens/ERC20UDS.sol";

import "./lib/LibString.sol";
import "./lib/LibECDSA.sol";

error ExceedsLimit();
error IncorrectValue();
error InvalidSignature();
error NonexistentToken();
error WhitelistNotActive();
error PublicSaleNotActive();
error SignatureExceedsLimit();
error ContractCallNotAllowed();

contract GMC is OwnableUDS, FxERC721MRootUDS {
    using LibString for uint256;
    using LibECDSA for bytes32;

    event SaleStateUpdate();

    bool public publicSaleActive;

    string public constant override name = "Gangsta Mice City";
    string public constant override symbol = "GMC";

    string private baseURI;
    string private unrevealedURI = "ipfs://QmRuQYxmdzqfVfy8ZhZNTvXsmbN9yLnBFPDeczFvWUS2HU/";

    uint256 private constant MAX_SUPPLY = 5555;
    uint256 private constant MAX_PER_WALLET = 20;

    uint256 private constant price = 0.02 ether;
    uint256 private constant whitelistPrice = 0.01 ether;
    uint256 private constant PURCHASE_LIMIT = 5;

    address private signer = 0x68442589f40E8Fc3a9679dE62884c85C6E524888;

    constructor(address checkpointManager, address fxRoot) FxERC721MRootUDS(checkpointManager, fxRoot) {
        __Ownable_init();
    }

    /* ------------- external ------------- */

    function mint(uint256 quantity, bool lock) external payable onlyEOA {
        if (!publicSaleActive) revert PublicSaleNotActive();
        if (PURCHASE_LIMIT < quantity) revert ExceedsLimit();
        if (msg.value != price * quantity) revert IncorrectValue();
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsLimit();
        if (numMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsLimit();

        if (lock) _mintLockedAndTransmit(msg.sender, quantity);
        else _mint(msg.sender, quantity);
    }

    function whitelistMint(
        uint256 quantity,
        bool lock,
        uint256 limit,
        bytes calldata signature
    ) external payable onlyEOA {
        if (!validSignature(signature, limit)) revert InvalidSignature();
        if (msg.value != whitelistPrice * quantity) revert IncorrectValue();
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsLimit();
        if (numMinted(msg.sender) + quantity > MAX_PER_WALLET) revert ExceedsLimit();

        if (lock) _mintLockedAndTransmit(msg.sender, quantity);
        else _mint(msg.sender, quantity);
    }

    function lockAndTransmit(address from, uint256[] calldata tokenIds) external {
        _lockAndTransmit(from, tokenIds);
    }

    function unlockAndTransmit(address from, uint256[] calldata tokenIds) external {
        _unlockAndTransmit(from, tokenIds);
    }

    function transferOwnershipAndTransmit(address from, uint256[] calldata tokenIds) external {
        _unlockAndTransmit(from, tokenIds);
        _lockAndTransmit(from, tokenIds);
    }

    /* ------------- private ------------- */

    function validSignature(bytes calldata signature, uint256 limit) private view returns (bool) {
        bytes32 hash = keccak256(abi.encode(address(this), msg.sender, limit));
        return hash.toEthSignedMsgHash().isValidSignature(signature, signer);
    }

    /* ------------- owner ------------- */

    function setPublicSaleActive(bool active) external onlyOwner {
        publicSaleActive = active;
        emit SaleStateUpdate();
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string calldata _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function airdrop(
        address[] calldata users,
        uint256[] calldata amounts,
        bool locked
    ) external onlyOwner {
        if (locked) for (uint256 i; i < users.length; ++i) _mintLockedAndTransmit(users[i], amounts[i]);
        else for (uint256 i; i < users.length; ++i) _mint(users[i], amounts[i]);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function _authorizeTunnelController() internal override onlyOwner {}

    /* ------------- modifier ------------- */

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert ContractCallNotAllowed();
        _;
    }

    /* ------------- ERC721 ------------- */

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) revert NonexistentToken();

        return bytes(baseURI).length == 0 ? unrevealedURI : string.concat(baseURI, id.toString(), ".json");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721M} from "ERC721M/ERC721M.sol";
import {FxERC721RootTunnelUDS} from "../FxERC721RootTunnelUDS.sol";

error Disabled();
error InvalidSignature();

/// @title ERC721M FxPortal extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract FxERC721MRootUDS is FxERC721RootTunnelUDS, ERC721M {
    constructor(address checkpointManager, address fxRoot) FxERC721RootTunnelUDS(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) external view virtual override returns (string memory);

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _mintLockedAndTransmit(address to, uint256 quantity) internal virtual {
        uint256 startId = _nextTokenId();

        _mintAndLock(to, quantity, true);

        uint256[] memory ids = new uint256[](quantity);

        unchecked {
            for (uint256 i; i < quantity; ++i) ids[i] = startId + i;
        }

        _registerERC721IdsWithChildMem(to, ids);
    }

    function _lockAndTransmit(address from, uint256[] calldata ids) internal virtual {
        unchecked {
            for (uint256 i; i < ids.length; ++i) _lock(from, ids[i]);
        }

        _registerERC721IdsWithChild(from, ids);
    }

    // @notice using `_unlockAndTransmit` is simple and easy
    // this assumes L1 state as the single source of truth
    // messages are always pushed L1 -> L2 without knowing state on L2
    // this means that NFTs should not be allowed to be traded/sold on L2
    function _unlockAndTransmit(address from, uint256[] calldata ids) internal virtual {
        unchecked {
            for (uint256 i; i < ids.length; ++i) _unlock(from, ids[i]);
        }

        _deregisterERC721IdsWithChild(ids);
    }

    // // @notice using `_unlockWithProof` is the 'correct' way for transmitting messages L2 -> L1
    // // validate ERC721 burn on L2 first, then unlock on L1 with tx inclusion proof
    // // NFTs can be traded/sold on L2 if adapted to transfer to a new owner
    // function _unlockWithProof(bytes calldata proofData) internal virtual {
    //     bytes memory message = _validateAndExtractMessage(proofData);

    //     (bytes32 sig, bytes memory data) = abi.decode(message, (bytes32, bytes));

    //     if (sig != MINT_SIG) revert InvalidSignature();

    //     (address from, uint256[] memory ids) = abi.decode(data, (address, uint256[]));

    //     uint256 idsLength = ids.length;

    //     unchecked {
    //         for (uint256 i; i < idsLength; ++i) _unlock(from, ids[i]);
    //     }
    // }
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
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 n) internal pure returns (string memory str) {
        if (n == 0) {
            return "0";
        } // Otherwise it'd output an empty string for 0.

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibECDSA {
    function toEthSignedMsgHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata signature,
        address signer
    ) internal pure returns (bool) {
        address recovered = ecrecover(
            hash,
            uint8(bytes1(signature[64:65])),
            bytes32(signature[0:32]),
            bytes32(signature[32:64])
        );
        return recovered != address(0) && recovered == signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721MLibrary.sol";
import {EIP712PermitUDS as EIP712Permit} from "UDS/auth/EIP712PermitUDS.sol";

// ------------- storage

struct ERC721MStorage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
    mapping(uint256 => uint256) tokenData;
    mapping(address => uint256) userData;
}

// keccak256("diamond.storage.erc721m.lockable") == 0xacef0a52ec0e8b948b85810f48a276692a03896348e0958ead290f1909a95599;
bytes32 constant DIAMOND_STORAGE_ERC721M_LOCKABLE = 0xacef0a52ec0e8b948b85810f48a276692a03896348e0958ead290f1909a95599;

function s() pure returns (ERC721MStorage storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ERC721M_LOCKABLE } // prettier-ignore
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
/// @author ERC721A (https://github.com/chiru-labs/ERC721A)
/// @author Solmate (https://github.com/Rari-Capital/solmate)
/// @notice Integrates EIP712Permit
abstract contract ERC721M is EIP712Permit {
    using TokenDataOps for uint256;
    using UserDataOps for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    uint256 constant startingIndex = 1;

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

    function balanceOf(address user) public view returns (uint256) {
        return s().userData[user].balance();
    }

    function getApproved(uint256 id) external view returns (address) {
        return s().getApproved[id];
    }

    function isApprovedForAll(address owner, address spender) external view returns (bool) {
        return s().isApprovedForAll[owner][spender];
    }

    function ownerOf(uint256 id) public view returns (address) {
        return _tokenDataOf(id).owner(warden());
    }

    function warden() public view virtual returns (address) {
        return address(this);
    }

    function totalSupply() public view returns (uint256) {
        return s().totalSupply;
    }

    function numMinted(address user) public view returns (uint256) {
        return s().userData[user].numMinted();
    }

    function trueOwnerOf(uint256 id) public view returns (address) {
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
        address owner = _tokenDataOf(id).owner(warden());

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
        if (to == address(0)) revert TransferToZeroAddress();
        if (to == warden()) revert TransferFromInvalidTo();

        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (tokenData.owner(warden()) != from) revert TransferFromIncorrectOwner();
        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        delete s().getApproved[id];

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);
        }

        s().tokenData[id] = tokenData.setOwner(to).flagNextTokenDataSet();

        s().userData[from] = s().userData[from].decreaseBalance(1);
        s().userData[to] = s().userData[to].increaseBalance(1);

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

    function _exists(uint256 id) internal view returns (bool) {
        return startingIndex <= id && id < _nextTokenId();
    }

    function _nextTokenId() internal view returns (uint256) {
        return startingIndex + s().totalSupply;
    }

    function _tokenDataOf(uint256 id) internal view returns (uint256) {
        if (!_exists(id)) revert NonexistentToken();

        unchecked {
            uint256 tokenData;

            for (uint256 curr = id; ; curr--) {
                tokenData = s().tokenData[curr];

                if (tokenData != 0) return curr == id ? tokenData : tokenData.copy();
            }
        }

        // unreachable
        return 0;
    }

    function _ensureTokenDataSet(uint256 id, uint256 tokenData) internal {
        if (!tokenData.nextTokenDataSet() && s().tokenData[id] == 0 && _exists(id)) s().tokenData[id] = tokenData;
    }

    function _mint(address to, uint256 quantity) internal {
        _mintAndLock(to, quantity, false);
    }

    function _mintAndLock(
        address to,
        uint256 quantity,
        bool lock_
    ) internal {
        unchecked {
            if (to == address(0)) revert MintToZeroAddress();
            if (quantity == 0) revert MintZeroQuantity();

            uint256 supply = s().totalSupply;
            uint256 startTokenId = startingIndex + supply;

            uint256 tokenData = uint160(to);
            if (lock_) tokenData = tokenData.setConsecutiveLocked().lock();

            // don't have to care about next token data if only minting one
            if (quantity == 1) tokenData = tokenData.flagNextTokenDataSet();

            if (lock_) {
                // @note: to reduce gas costs when locking individually, user numLocked is not tracked
                // userData = userData.increaseNumLocked(quantity).setLockStart(block.timestamp);

                uint256 id;
                for (uint256 i; i < quantity; ++i) {
                    id = startTokenId + i;

                    emit Transfer(address(0), to, id);
                    emit Transfer(to, warden(), id);
                }
            } else {
                for (uint256 i; i < quantity; ++i) emit Transfer(address(0), to, startTokenId + i);
            }

            // @note: to reduce gas costs, user numLocked is not tracked, balances stay constant when locking
            s().userData[to] = s().userData[to].increaseNumMinted(quantity).increaseBalance(quantity);
            s().tokenData[startTokenId] = tokenData;

            s().totalSupply = supply + quantity;
        }
    }

    function _lock(address from, uint256 id) internal {
        uint256 tokenData = _tokenDataOf(id);

        bool isApprovedOrOwner = (msg.sender == from ||
            s().isApprovedForAll[from][msg.sender] ||
            s().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();
        if (tokenData.owner(warden()) != from) revert IncorrectOwner();

        delete s().getApproved[id];

        s().tokenData[id] = tokenData.lock();

        unchecked {
            _ensureTokenDataSet(id + 1, tokenData);

            tokenData = tokenData.unsetConsecutiveLocked().flagNextTokenDataSet();
        }

        // @note: to reduce gas costs, user numLocked is not tracked, balances stay constant when locking
        // s().userData[from] = s().userData[from].decreaseBalance(1).increaseNumLocked(1).setLockStart(block.timestamp);

        emit Transfer(from, warden(), id);
    }

    function _unlock(address from, uint256 id) internal {
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

        emit Transfer(warden(), from, id);
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

import {FxBaseRootTunnelUDS} from "./base/FxBaseRootTunnelUDS.sol";

bytes32 constant REGISTER_SIG = keccak256("registerERC721IdsWithChild(address,uint256[])");
bytes32 constant DEREGISTER_SIG = keccak256("deregisterERC721IdsWithChild(uint256[])");

error Disabled();
error InvalidSignature();

/// @title ERC721 FxRootTunnel
/// @author phaze (https://github.com/0xPhaze/fx-contracts)
abstract contract FxERC721RootTunnelUDS is FxBaseRootTunnelUDS {
    constructor(address checkpointManager, address fxRoot) FxBaseRootTunnelUDS(checkpointManager, fxRoot) {}

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual override;

    /* ------------- internal ------------- */

    function _registerERC721IdsWithChild(address to, uint256[] calldata ids) internal virtual {
        _sendMessageToChild(abi.encode(REGISTER_SIG, abi.encode(to, ids)));
    }

    function _registerERC721IdsWithChildMem(address to, uint256[] memory ids) internal virtual {
        _sendMessageToChild(abi.encode(REGISTER_SIG, abi.encode(to, ids)));
    }

    function _deregisterERC721IdsWithChild(uint256[] calldata ids) internal virtual {
        _sendMessageToChild(abi.encode(DEREGISTER_SIG, abi.encode(ids)));
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

    /// used in extensions

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

    function lockStart(uint256 userData) internal pure returns (uint256) {
        return (userData >> 60) & 0xFFFFFFFFFF;
    }

    function setLockStart(uint256 userData, uint256 timestamp) internal pure returns (uint256) {
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
    function copy(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ((uint256(1) << (160 + (((tokenData >> 160) & 1) << 1))) - 1);
    }

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

    function owner(uint256 tokenData, address warden) internal pure returns (address) {
        return locked(tokenData) ? warden : trueOwner(tokenData);
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

    function lock(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 161);
    }

    function unlock(uint256 tokenData) internal pure returns (uint256) {
        return tokenData & ~(uint256(1) << 161);
    }

    /* ------------- nextTokenDataSet: [162, 163) ------------- */

    function nextTokenDataSet(uint256 tokenData) internal pure returns (bool) {
        return ((tokenData >> 162) & uint256(1)) != 0;
    }

    function flagNextTokenDataSet(uint256 tokenData) internal pure returns (uint256) {
        return tokenData | (uint256(1) << 162); // nextTokenDatatSet flag (don't repeat the read/write)
    }

    // /* ------------- aux: [168, 256) ------------- */

    // function aux(uint256 tokenData) internal pure returns (uint256) {
    //     return (tokenData >> 168) & 0xFFFFFFFFFFFFFFFFFFFFFF;
    // }
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
error InvalidSignature();
error InvalidReceiptProof();
error InvalidFxChildTunnel();
error ExitAlreadyProcessed();

abstract contract FxBaseRootTunnelUDS {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    bytes32 private constant SEND_MESSAGE_EVENT_SIG =
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

    function fxChildTunnel() public view returns (address) {
        return s().fxChildTunnel;
    }

    function processedExits(bytes32 exitHash) public view returns (bool) {
        return s().processedExits[exitHash];
    }

    function setFxChildTunnel(address fxChildTunnel_) public virtual {
        _authorizeTunnelController();

        s().fxChildTunnel = fxChildTunnel_;
    }

    /* ------------- internal ------------- */

    function _sendMessageToChild(bytes memory message) internal {
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

        if (bytes32(topics.getField(0).toUint()) != SEND_MESSAGE_EVENT_SIG) revert InvalidSignature();

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message

        return message;
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