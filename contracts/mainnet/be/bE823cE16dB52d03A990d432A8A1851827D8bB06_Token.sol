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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

contract Auth is Context {
    error NotAuthorized(uint16 req, address sender);

    mapping(address => uint16) _roles;

    modifier requireRole(uint16 req) {
        if (!_hasRole(_msgSender(), req)) {
            revert NotAuthorized(req, _msgSender());
        }
        _;
    }

    function _setRole(address operator, uint16 mask) internal virtual {
        _roles[operator] = mask;
    }

    function _hasRole(
        address operator,
        uint16 role
    ) internal view virtual returns (bool) {
        return _roles[operator] & role == role;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _isApprovedForAll[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == from || _isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || _isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Auth.sol";
import "./ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

struct TokenConfig {
    bool added;
    bool canMint;
    bool canBurn;
    uint256 supplyLimit;
}

contract Token is ERC1155, Pausable, Ownable, Auth {
    string public name;
    string public symbol;
    string public contractURI;
    string private _uri;

    mapping(address => bool) private _approvalAllowlist;

    uint16 public constant ROLE_ADD_FT = 1 << 0;
    uint16 public constant ROLE_MODIFY_FT = 1 << 1;
    uint16 public constant ROLE_MINT_FT = 1 << 2;
    uint16 public constant ROLE_MINT_NFT = 1 << 3;
    uint16 public constant ROLE_BATCH_MINT_NFT = 1 << 4;
    uint16 public constant ROLE_BURN_FT = 1 << 5;
    uint16 public constant ROLE_BURN_NFT = 1 << 6;
    uint16 public constant ROLE_BATCH_BURN_NFT = 1 << 7;
    uint16 public constant ROLE_REFRESH_METADATA = 1 << 8;
    uint16 public constant ROLE_SET_PAUSED = 1 << 9;
    uint16 public constant ROLE_BYPASS_PAUSE = 1 << 10;

    uint256 public constant FUNGIBLE_TOKEN_UPPER_BOUND = 10_000;

    mapping(uint256 => uint256) private _minted;
    mapping(uint256 => TokenConfig) private _added;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) ERC1155() {
        setMetadata(name_, symbol_, contractURI_, uri_);

        // Contract owner gets all roles by default. (11 roles, so the mask is 2^12 - 1 = 0b111_1111_1111.)
        setRole(msg.sender, (1 << 12) - 1);
    }

    function setMetadata(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) public onlyOwner {
        name = name_;
        symbol = symbol_;
        contractURI = contractURI_;
        _uri = uri_;
    }

    function uri(
        uint256
    ) public view override(ERC1155) returns (string memory) {
        return _uri;
    }

    function setApprovalAllowlist(
        address operator,
        bool approved
    ) public onlyOwner {
        _approvalAllowlist[operator] = approved;
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view override(ERC1155) returns (bool) {
        if (_approvalAllowlist[operator] == true) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setPaused(bool b) public requireRole(ROLE_SET_PAUSED) {
        if (b) {
            require(b && !paused(), "Contract is already paused");
            _pause();
            return;
        }

        require(!b && paused(), "Contract is not paused");
        _unpause();
    }

    function _isFungible(uint256 id) internal pure returns (bool) {
        return id < FUNGIBLE_TOKEN_UPPER_BOUND;
    }

    function _supplyLimit(uint256 id) internal view returns (uint256) {
        if (!_isFungible(id)) {
            return 1;
        }

        return _added[id].supplyLimit;
    }

    function supplyLimit(uint256 id) public view returns (uint256) {
        return _supplyLimit(id);
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _supplyLimit(id);
    }

    function addFT(
        uint256 id,
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public requireRole(ROLE_ADD_FT) {
        require(_added[id].added == false, "Token already added.");

        _added[id] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);

        emit TransferSingle(_msgSender(), address(0), address(0), id, 0);
    }

    function modifyFT(
        uint256 id,
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public requireRole(ROLE_MODIFY_FT) {
        require(_added[id].added == true, "Token not added.");

        _added[id] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);
    }

    function mintFT(
        address to,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_MINT_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canMint, "Token cannot be minted.");
        require(
            supplyLimit(tokenID) == 0 ||
                (_minted[tokenID] + quantity <= supplyLimit(tokenID)),
            "Mint would exceed supply limit."
        );

        _mint(to, tokenID, quantity, "");
        _minted[tokenID] += quantity;
    }

    function mintNFT(
        address to,
        uint256 tokenID
    ) public requireRole(ROLE_MINT_NFT) {
        require(!_isFungible(tokenID), "Token is fungible.");

        _mint(to, tokenID, 1, "");
    }

    function batchMintNFT(
        address to,
        uint256[] calldata ids
    ) public requireRole(ROLE_BATCH_MINT_NFT) {
        _batchMint(to, ids, _repeat(1, ids.length), "");
    }

    function burnFT(
        address owner,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_BURN_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canBurn, "Token cannot be burned.");

        _burn(owner, tokenID, quantity);
    }

    function burnNFT(
        address owner,
        uint256 tokenID
    ) public requireRole(ROLE_BURN_NFT) {
        require(!_isFungible(tokenID), "Token is fungible.");

        _burn(owner, tokenID, 1);
    }

    function batchBurnNFT(
        address owner,
        uint256[] calldata ids
    ) public requireRole(ROLE_BATCH_BURN_NFT) {
        _batchBurn(owner, ids, _repeat(1, ids.length));
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155) {
        if (paused()) {
            if (!_hasRole(_msgSender(), ROLE_BYPASS_PAUSE)) {
                revert("Token is paused");
            }
        }

        return super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override(ERC1155) {
        if (paused()) {
            if (!_hasRole(_msgSender(), ROLE_BYPASS_PAUSE)) {
                revert("Token is paused");
            }
        }

        return super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function updateMetadata(
        uint256 id
    ) public requireRole(ROLE_REFRESH_METADATA) {
        emit MetadataUpdate(id);
    }

    function updateAllMetadata() public requireRole(ROLE_REFRESH_METADATA) {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setRole(address operator, uint16 mask) public onlyOwner {
        _setRole(operator, mask);
    }

    function hasRole(address operator, uint16 role) public view returns (bool) {
        return _hasRole(operator, role);
    }

    function _repeat(
        uint256 value,
        uint256 length
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            array[i] = value;
        }

        return array;
    }
}