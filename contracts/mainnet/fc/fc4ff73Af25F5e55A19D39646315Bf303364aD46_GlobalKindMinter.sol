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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../weth/IWeth9.sol";
import "../niftykit/INiftyKit.sol";
import "./IGlobalKindMinter.sol";

/// @title A minter contract that owns a nifty kit proxy contract and splits mint fees between the
///    NiftyKit and the WETH recipient.
/// @author skymagic
/// @custom:security-contact [email protected]
contract GlobalKindMinter is Ownable, IGlobalKindMinter {

    INiftyKit public niftykit;
    address  public wethRecipient;
    IWETH9 public weth;

    uint128 public basisPointsWeth = 3750; // 37.5%

    constructor(address _niftykit, address _wethRecipient, address payable _weth)  {
        niftykit = INiftyKit(_niftykit);
        wethRecipient = _wethRecipient;
        weth = IWETH9(_weth);
    }

    function setNiftyKit(address _niftykit) external onlyOwner {
        niftykit = INiftyKit(_niftykit);
    }

    function setWethRecipient(address _wethRecipient) external onlyOwner {
        wethRecipient = _wethRecipient;
    }

    function setBasisPointsWeth(uint128 _basisPointsWeth) external onlyOwner {
        require(_basisPointsWeth <= 10000, "Invalid basis points");
        basisPointsWeth = _basisPointsWeth;
    }

    function transferOwnershipProxy(address newOwner) external onlyOwner {
        niftykit.transferOwnership(newOwner);
    }

    function startSaleProxy(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyOwner {
        niftykit.startSale(newMaxAmount, newMaxPerMint, newMaxPerWallet, newPrice, presale);
    }

    function mintTo(address to, uint64 quantity) external payable {
        _mint(to, quantity);
    }

    function mint(uint64 quantity) external payable {
        _mint(msg.sender, quantity);
    }

    function _mint(address to, uint64 quantity) internal {
        payoutWeth(to, quantity);
        address[] memory toArray = new address[](1);
        toArray[0] = to;
        uint64[] memory quantityArray = new uint64[](1);
        quantityArray[0] = quantity;

        niftykit.batchAirdrop(quantityArray, toArray);
    }

    /// @notice Pay out the WETH recipient.
    /// @dev Swap Eth to WETH. Transfer WETH to the user. Then Transfer WETH to the recipient so that the contribution
    ///     appears to come from the msg sender.
    function payoutWeth(address from, uint64 quantity) internal {
        require(quantity > 0, "Quantity too low");
        uint256 price = niftykit.price();
        require(msg.value == price * quantity, "Not enough funds sent");
        uint256 wethCut = msg.value * basisPointsWeth / 10000;

        // swap half of eth to weth, and send back to sender
        weth.deposit{value : wethCut}();
        weth.transfer(from, wethCut);
        // send weth from sender to recipient2
        weth.transferFrom(from, wethRecipient, wethCut);
    }

    function withdraw(address payable _ethRecipient) external onlyOwner {
        require(_ethRecipient != address(0), "Invalid address");
        _ethRecipient.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title An interface to split mint fees between the NiftyKit and the WETH recipient and act as proxy owner of the
///  NiftyKit contract.
/// @author skymagic
/// @custom:security-contact [email protected]
interface IGlobalKindMinter {

    /// @notice Public mint function targeting an address.
    /// @dev Mint to an address. Send Weth from the `to` address.
    /// @param to address and quantity to mint
    function mintTo(address to, uint64 quantity) external payable;

    /// @notice Public mint function
    /// @dev Mint to message sender. Send Weth from the sender address.
    /// @param quantity to mint
    function mint(uint64 quantity) external payable;

    /// @notice Admin function to transfer ownership of the underlying NiftyKit contract.
    /// @dev Use `transferOwnership` to transfer ownership of this contract instead.
    function transferOwnershipProxy(address newOwner) external;

    /// @notice Admin function to change mint price of underlying NiftyKit contract.
    function startSaleProxy(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external;

    /// @notice Admin function to change the underlying NiftyKit contract address.
    /// @dev Must be owner to call.
    function setNiftyKit(address _niftykit) external;
    /// @notice Admin function to change the weth recipient address.
    /// @dev Must be owner to call.
    function setWethRecipient(address _wethRecipient) external;
    /// @notice Change the basis points of the mint fee that goes to the WETH recipient.
    /// @dev Must be owner to call.
    function setBasisPointsWeth(uint128 _basisPointsWeth) external;
    /// @notice Withdraw ether from the contract.
    /// @dev Must be owner to call.
    function withdraw(address payable _ethRecipient) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INiftyKit is IERC721 {
    function transferOwnership(address newOwner) external;
    function batchAirdrop(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external;
    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external;

    function price() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWETH9 {
    event  Transfer(address indexed src, address indexed dst, uint wad);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}