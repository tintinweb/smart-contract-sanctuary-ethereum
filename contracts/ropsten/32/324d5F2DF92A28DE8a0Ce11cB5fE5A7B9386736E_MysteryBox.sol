// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

interface IMetakicks {
    function mint(address to) external returns (uint256);
}

/// @title Mintable ERC1155 MysteryBox to claim your Metakicks.
contract MysteryBox is ERC1155, Ownable, ReentrancyGuard {
    enum SaleStatus {
        NotStarted,
        Whitelist,
        Public,
        Migration
    }

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emmited when a MysteryBox is migrated to a Metakicks
    /// @param tokenId MysteryBox migrated token Id
    /// @param metakicksId Minted metakicks tokenId
    event TokenMigrated(uint256 tokenId, uint256 metakicksId);

    /// @dev Emitted when the mint price is updated
    /// @param mintPrice The new mintPrice
    event MintPriceUpdated(uint256 mintPrice);

    /// @dev Emitted when the current sale status is updated
    /// @param status The new sale status
    event CurrentSaleStatusUpdated(SaleStatus status);

    /// @dev Emitted when maxPerTx is updated
    /// @param maxPerTx The new maxPerTx
    event MaxPerTxUpdated(uint256 maxPerTx);

    /// @dev Emitted when the URI is updated
    /// @param uri The new URI
    event UriUpdated(string uri);

    /// @dev Emitted when the Metakicks contract is updated
    /// @param metakicksContract The new metakicks contract address
    event MetakicksContractUpdated(address metakicksContract);

    /// @dev Emitted when the funds are withdrawed to the treasury
    /// @param amount The amount withdrawed
    event FundsWithdrawed(uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev Max amount, can't mint more
    uint256 public constant MAX_AMOUNT = 6250;

    /// @dev The mint price for each box
    uint256 public mintPrice = 0.15 ether;

    /// @dev Treasury (multisig) address to receiving the funds
    address public immutable treasury;

    /// @dev Current tokenID
    uint256 public currentTokenId;

    /// @dev Current amount minted
    uint256 public currentAmountMinted;

    /// @dev Max amount to mint per address (public sale)
    uint256 public maxPerTx = 3;

    /// @dev Address of the "OpenedBox" contract to migrate tokens
    address public metakicksContract;

    /// @dev Common URI for all the boxes
    string public _uri;

    /// @dev Current sale status (inital is "NotStarted")
    SaleStatus public currentSaleStatus;

    /// @dev Whitelisted addresses with allowed quantity to mint (whitelist sale)
    mapping(address => uint256) public whitelist;

    /// @dev Whitelisted addresses with allowed quantity to mint (private sale)
    mapping(address => uint256) public privateList;

    /// @dev Addresses that have already minted (public sale) with the amount.
    mapping(address => uint256) public minted;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory uri_, address treasury_) {
        require(treasury_ != address(0), "Invalid address");
        _uri = uri_;
        treasury = treasury_;
    }

    /*///////////////////////////////////////////////////////////////
                           METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view override returns (string memory) {
        (id); // Unused, same URI for all the boxes.
        return _uri;
    }

    /*///////////////////////////////////////////////////////////////
                           MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Public sale, 1 Token/Amount per users
    /// @param amount The amount to mint (ERC1155 amount)
    function publicSale(uint256 amount) external payable nonReentrant {
        require(amount != 0, "MINT: invalid amount");
        require(
            currentSaleStatus == SaleStatus.Public,
            "MINT: not in public sale"
        );
        require(
            minted[msg.sender] + amount <= maxPerTx,
            "MINT: Can't mint more"
        );
        require(msg.value >= mintPrice * amount, "MINT: Not enough eth");
        require(
            currentAmountMinted + amount <= MAX_AMOUNT,
            "MINT: Max amount reached"
        );

        unchecked {
            minted[msg.sender] += amount;
            currentTokenId++;
            currentAmountMinted += amount;
        }
        _mint(msg.sender, currentTokenId, amount, "");
    }

    /// @notice Whitelist sale for whitelisted users
    /// Note: Will mint the amount specified during the whitelist (by the owner)
    function whitelistSale() external payable nonReentrant {
        require(
            currentSaleStatus == SaleStatus.Whitelist,
            "MINT: not in whitelist sale"
        );
        uint256 amount = whitelist[msg.sender];
        require(amount != 0, "MINT: Not allowed");
        require(msg.value >= mintPrice * amount, "MINT: Not enough eth");
        require(
            currentAmountMinted + amount <= MAX_AMOUNT,
            "MINT: Max amount reached"
        );

        whitelist[msg.sender] = 0;
        unchecked {
            currentTokenId++;
            currentAmountMinted += amount;
        }
        _mint(msg.sender, currentTokenId, amount, "");
    }

    /// @notice Private sale (free)
    /// Note: Will mint the amount specified while adding to the private list
    ///       (by the owner). The private sale is during the whitelist sale.
    function privateSale() external nonReentrant {
        require(
            currentSaleStatus == SaleStatus.Whitelist,
            "MINT: not in private sale"
        );
        uint256 amount = privateList[msg.sender];
        require(amount != 0, "MINT: Not allowed");
        require(
            currentAmountMinted + amount <= MAX_AMOUNT,
            "MINT: Max amount reached"
        );

        privateList[msg.sender] = 0;
        unchecked {
            currentTokenId++;
            currentAmountMinted += amount;
        }
        _mint(msg.sender, currentTokenId, amount, "");
    }

    /// @notice Migrate MysteryBox to OpenedBox (only one).
    /// @param id The MysteryBox token Id to migrate
    function migrateToken(uint256 id) external nonReentrant {
        require(
            currentSaleStatus == SaleStatus.Migration,
            "Migration disabled"
        );
        require(balanceOf[msg.sender][id] > 0, "Not owner of tokens");
        _burn(msg.sender, id, 1);
        uint256 metakicksId = IMetakicks(metakicksContract).mint(msg.sender);
        emit TokenMigrated(id, metakicksId);
    }

    /*///////////////////////////////////////////////////////////////
                           OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Force the token migration by the owner. One by one.
    /// Might be used in a very long time.
    /// @param id The token Id to migrate
    /// @param recipient The owner of the MysteryBox that will receive the Metakicks
    function forceMigrateToken(uint256 id, address recipient)
        external
        onlyOwner
    {
        require(
            currentSaleStatus == SaleStatus.Migration,
            "Migration disabled"
        );
        require(recipient != address(0), "invalid recipient");
        require(balanceOf[recipient][id] > 0, "Not owner of tokens");
        _burn(recipient, id, 1);
        uint256 metakicksId = IMetakicks(metakicksContract).mint(recipient);
        emit TokenMigrated(id, metakicksId);
    }

    /// @notice Update the price for the Whitelist and Public Sale
    /// @param _mintPrice The new mint price
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceUpdated(_mintPrice);
    }

    /// @notice Update the sale status
    /// @param _status The new status
    function setCurrentSaleStatus(SaleStatus _status) external onlyOwner {
        currentSaleStatus = _status;
        emit CurrentSaleStatusUpdated(_status);
    }

    /// @notice Update the maximum amount per Tx (public sale)
    /// @param _maxPerTx The new amount
    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx != 0, "Invalid amount");
        maxPerTx = _maxPerTx;
        emit MaxPerTxUpdated(_maxPerTx);
    }

    /// @notice Add addresses to the whitelist
    /// Note: If an address is already added, it will update the amount
    /// @param addrs List of addresses to whitelist
    /// @param amounts Respective amounts for each addresses
    function addToWhitelist(address[] memory addrs, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(addrs.length == amounts.length, "Length error");
        uint256 length = addrs.length;
        for (uint256 i; i < length; ) {
            whitelist[addrs[i]] = amounts[i];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Add addresses to the private list
    /// Note: If an address is already added, it will update the amount
    /// @param addrs List of addresses to add to the private list
    /// @param amounts Respective amounts for each addresses
    function addToPrivateList(address[] memory addrs, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(addrs.length == amounts.length, "Length error");
        uint256 length = addrs.length;
        for (uint256 i; i < length; ) {
            privateList[addrs[i]] = amounts[i];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Update the common URI
    /// @param uri_ The new URI
    function setURI(string memory uri_) external onlyOwner {
        _uri = uri_;
        emit UriUpdated(uri_);
    }

    /// @notice Update the Metakicks contract address
    /// @param _metakicksContract The new contract address
    function setMetakicksContract(address _metakicksContract)
        external
        onlyOwner
    {
        metakicksContract = _metakicksContract;
        emit MetakicksContractUpdated(_metakicksContract);
    }

    /// @notice Allow the owner to withdraw the funds from the sale.
    function withdrawFunds() external onlyOwner {
        uint256 toWithdraw = address(this).balance;
        payable(treasury).transfer(toWithdraw);
        emit FundsWithdrawed(toWithdraw);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
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

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: MIT

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