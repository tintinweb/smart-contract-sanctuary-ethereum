/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

interface IMetakicks {
    function mint(address to) external returns (uint256);
}

/// @title Mintable ERC1155 MysteryBox to claim your Metakicks.
contract MysteryBox is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

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

    /// @dev Emitted when the baseURI is updated
    /// @param baseURI The new baseURI
    event BaseUriUpdated(string baseURI);

    /// @dev Emitted when maxPerTx is updated
    /// @param maxPerTx The new maxPerTx
    event MaxPerTxUpdated(uint256 maxPerTx);

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

    /// @dev Max amount to mint per address (public sale)
    uint256 public maxPerTx = 3;

    /// @dev Address of the "OpenedBox" contract to migrate tokens
    address public metakicksContract;

    /// @dev baseURI for the boxes
    string public baseURI;

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

    constructor(string memory _baseURI, address treasury_)
        ERC721("Metakicks: The Box", "MTKSBOX")
    {
        require(treasury_ != address(0), "Invalid address");
        baseURI = _baseURI;
        treasury = treasury_;
    }

    /*///////////////////////////////////////////////////////////////
                           METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
            currentTokenId + amount <= MAX_AMOUNT,
            "MINT: Max amount reached"
        );

        unchecked {
            minted[msg.sender] += amount;
        }

        for (uint256 i = 0; i < amount; ++i) {
            unchecked {
                currentTokenId++;
            }
            _safeMint(msg.sender, currentTokenId);
        }
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
            currentTokenId + amount <= MAX_AMOUNT,
            "MINT: Max amount reached"
        );
        whitelist[msg.sender] = 0;

        unchecked {
            minted[msg.sender] += amount;
        }

        for (uint256 i = 0; i < amount; ++i) {
            unchecked {
                currentTokenId++;
            }
            _safeMint(msg.sender, currentTokenId);
        }
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
            currentTokenId + amount <= MAX_AMOUNT,
            "MINT: Max amount reached"
        );

        privateList[msg.sender] = 0;
        unchecked {
            minted[msg.sender] += amount;
        }

        for (uint256 i = 0; i < amount; ++i) {
            unchecked {
                currentTokenId++;
            }
            _safeMint(msg.sender, currentTokenId);
        }
    }

    /// @notice Migrate MysteryBox to OpenedBox (only one).
    /// @param id The MysteryBox token Id to migrate
    function migrateToken(uint256 id) external nonReentrant {
        require(
            currentSaleStatus == SaleStatus.Migration,
            "Migration disabled"
        );
        require(ownerOf[id] == msg.sender, "Not owner of token");
        _burn(id);
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
        require(ownerOf[id] == recipient, "Not owner of token");
        _burn(id);
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

    /// @notice Update the baseURI
    /// @param _baseURI the new _baseURI
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseUriUpdated(_baseURI);
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