/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: contracts/HouseWrap.sol

// contracts/HouseTokenWrapper.sol

pragma solidity ^0.8.0;


interface Iwrapper {
    function changeHolder(address nft, uint256 id, address usr) external;
}

contract HouseWrap {
    address                                         public wrapper;
    address                                         public holder;
    uint256                                         public constant totalSupply = 1;
    mapping(address => mapping(address => uint256)) public allowance;
    string                                          public symbol;
    uint8                                           public constant decimals = 0;
    string                                          public name = "HouseWrap";
    IERC721Metadata                                 public immutable erc721;
    uint256                                         public immutable tokenId;

    constructor(
        address w,
        IERC721Metadata t,
        uint256 id,
        string memory tokenSymbol
    ) {
        wrapper = w;
        erc721 = t;
        tokenId = id;
        symbol = tokenSymbol;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function tokenURI() external view returns (string memory)  {
        return erc721.tokenURI(tokenId);
    }

    function balanceOf(address account) external view returns (uint256) {
        return account == holder ? totalSupply : 0;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(amount == 1, "HouseTokenWrapper: invalid-amount");
        require(sender == holder, "HouseTokenWrapper: insufficient-balance");
        require(recipient != address(0), "HouseTokenWrapper: recipient is the zero address");

        if (sender != msg.sender) {
            require(
                allowance[sender][msg.sender] >= amount,
                "HouseTokenWrapper: insufficient-approval"
            );
            allowance[sender][msg.sender] = allowance[sender][msg.sender] - amount;
        }

        holder = recipient;
        Iwrapper(wrapper).changeHolder(address(erc721), tokenId, recipient);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function withdraw() external {
        require(holder != address(0), "HouseTokenWrapper: holder is the zero address");
        require(holder == msg.sender, "HouseTokenWrapper: only holder");

        erc721.transferFrom(address(this), holder, tokenId);
        holder = address(0);
        Iwrapper(wrapper).changeHolder(address(erc721), tokenId, address(0));
        emit Transfer(holder, address(0), totalSupply);
    }

    function deposit() public {
        erc721.transferFrom(msg.sender, address(this), tokenId);
        holder = msg.sender;
        Iwrapper(wrapper).changeHolder(address(erc721), tokenId, msg.sender);
        emit Transfer(address(0), holder, totalSupply);
    }

    function depositAndApprove(address spender) external {
        deposit();
        approve(spender, totalSupply);
    }
}

// File: contracts/HouseWrapper.sol

// contracts/HouseTokenFactory.sol

pragma solidity ^0.8.0;





interface houseToken is IERC721Metadata{
    function mint(address) external returns(uint256);
}

contract HouseWrapper is Ownable {
    using Strings for uint256;
    
    houseToken public  erc721;
    mapping(address => mapping(uint256=>address)) public wrapOf;
    event Wrapper(address nft, uint256 tokenId, address wrap, address owner);
    event ChangeHolder(address wrap, address holder);

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth {  wards[usr] = 1; }
    function deny(address usr) external auth {  wards[usr] = 0; }
    modifier auth {
        require(owner() == msg.sender || wards[msg.sender] == 1 , "not-authorized");
        _;
    }

    function changeHolder(address nft, uint256 id, address usr) public {
        require(msg.sender == wrapOf[nft][id], "HouseWrapper: only HouseTokenWrap");
        emit ChangeHolder(msg.sender, usr);
    }

    function getWrapHolder(address wrap) public view returns(address) {
        return HouseWrap(wrap).holder();
    }

    function setHouseToken(address token) public onlyOwner {
        erc721 = houseToken(token);
    }

    function mint(address to) public auth returns (uint256, HouseWrap) {
        require(address(erc721)!= address(0), "HouseWrapper: set HouseToken");
        require(to != address(0), "HouseWrapper: zero address");

        uint256 newTokenId = erc721.mint(to);

        HouseWrap wrap = new HouseWrap(
            address(this),
            erc721,
            newTokenId,
            string(abi.encodePacked(erc721.symbol(), newTokenId.toString()))
        );

        wrapOf[address(erc721)][newTokenId]=address(wrap);

        emit Wrapper(address(erc721), newTokenId, address(wrap), to);

        return (newTokenId, wrap);
    }

    function mint(address to, uint256 mintAmount) public onlyOwner{
        require(address(erc721)!= address(0), "HouseWrapper: set HouseToken");
        require(to != address(0), "HouseWrapper: zero address");
        for(uint256 i=0; i< mintAmount; i++){
            uint256 newTokenId = erc721.mint(to);

            HouseWrap wrap = new HouseWrap(
                address(this),
                erc721,
                newTokenId,
                string(abi.encodePacked(erc721.symbol(), "_", newTokenId.toString()))
            );

            wrapOf[address(erc721)][newTokenId]=address(wrap);

            emit Wrapper(address(erc721), newTokenId, address(wrap), to);
        }
    }

    function wrapper(address nft, uint256 tokenId, address owner) public auth {
        require(IERC721Metadata(nft).ownerOf(tokenId) == owner, "HouseWrapper: token ownership errors");

        HouseWrap wrap = new HouseWrap(
                address(this),
                erc721,
                tokenId,
                string(abi.encodePacked(erc721.symbol(), "_", tokenId.toString()))
            );
        wrapOf[nft][tokenId]=address(wrap);

        emit Wrapper(nft, tokenId, address(wrap), owner);
    }
}