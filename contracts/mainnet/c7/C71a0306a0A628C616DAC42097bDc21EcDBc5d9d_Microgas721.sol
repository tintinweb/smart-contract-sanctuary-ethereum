/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Joyride

// File: microgasFactory.sol
// Some parts modified 2022 from github.com/divergencetech/ethier
pragma solidity ^0.8.11;

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
        require(value == 0, "BAD_HEX_LENGTH");
        return string(buffer);
    }
}

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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "REENTRANT");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
        require(owner() == _msgSender(), "NOT_OWNER");
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
        require(newOwner != address(0), "BAD_OWNER");
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

interface IAllowsProxy {
    function isProxyActive() external view returns (bool);

    function proxyAddress() external view returns (address);

    function isApprovedForProxy(address _owner, address _operator)
        external
        view
        returns (bool);
}

interface IFactoryMintable {
    function factoryMint(uint256 _optionId, address _to) external;
    function factoryCanMint(uint256 _optionId) external view returns (bool);
}

contract OwnableDelegateProxy {}
/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract AllowsConfigurableProxy is IAllowsProxy, Ownable {
    bool internal isProxyActive_;
    address internal proxyAddress_;

    constructor(address _proxyAddress, bool _isProxyActive) {
        proxyAddress_ = _proxyAddress;
        isProxyActive_ = _isProxyActive;
    }

    function setIsProxyActive(bool _isProxyActive) external onlyOwner {
        isProxyActive_ = _isProxyActive;
    }

    function setProxyAddress(address _proxyAddress) public onlyOwner {
        proxyAddress_ = _proxyAddress;
    }

    function proxyAddress() public view returns (address) {
        return proxyAddress_;
    }

    function isProxyActive() public view returns (bool) {
        return isProxyActive_;
    }

    function isApprovedForProxy(address owner, address _operator)
        public
        view
        returns (bool)
    {
        if (
            isProxyActive_ && proxyAddress_ == _operator
        ) {
            return true;
        }
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyAddress_);
        if (
            isProxyActive_ && address(proxyRegistry.proxies(owner)) == _operator
        ) {
            return true;
        }
        return false;
    }
}

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface IFactoryERC721 {
    /**
     * Returns the name of this factory.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol for this factory.
     */
    function symbol() external view returns (string memory);

    /**
     * Number of options the factory supports.
     */
    function numOptions() external view returns (uint256);

    /**
     * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
     * restrict a total supply per option ID (or overall).
     */
    function canMint(uint256 _optionId) external view returns (bool);

    /**
     * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
     * same structure as the ERC721 metadata.
     */
    function tokenURI(uint256 _optionId) external view returns (string memory);

    /**
     * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
     */
    function supportsFactoryInterface() external view returns (bool);

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) external;
}

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

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

contract TokenFactory is
    AllowsConfigurableProxy,
    ReentrancyGuard,
    IERC721
{
    using Strings for uint256;
    uint256 public immutable NUM_OPTIONS;

    /// @notice Contract that deployed this factory.
    IFactoryMintable public token;

    /// @notice Factory name and symbol.
    string public name;
    string public symbol;

    string public optionURI;

    bool public paused = false;

    error NotOwnerOrProxy();
    error InvalidOptionId();

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _numOptions,
        address _proxyAddress,
        IFactoryMintable _token
    ) AllowsConfigurableProxy(_proxyAddress, true) {
        name = _name;
        symbol = _symbol;
        token = _token;
        NUM_OPTIONS = _numOptions;
        optionURI = "https://onjoyride.mypinata.cloud/ipfs/QmWY6ZTnvd7Zaw2hSLzDudvv5GxJ47hMNXhZQVQQqnoWxu/";
        // first owner will be the token that deploys the contract
        transferOwnership(_owner);
        createOptionsAndEmitTransfers();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    modifier onlyOwnerOrProxy() {
        if (
            _msgSender() != owner() &&
            !isApprovedForProxy(owner(), _msgSender())
        ) {
            revert NotOwnerOrProxy();
        }
        _;
    }

    modifier checkValidOptionId(uint256 _optionId) {
        // options are 0-indexed so check should be inclusive
        if (_optionId >= NUM_OPTIONS) {
            revert InvalidOptionId();
        }
        _;
    }

    modifier interactBurnInvalidOptionId(uint256 _optionId) {
        _;
        _burnInvalidOptions();
    }

    modifier whenNotPaused() {
        require(!paused, "PAUSED");
        _;
    }

    function setPaused(bool state) external onlyOwner {
        paused = state;
    }

    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    /**
    @notice Emits standard ERC721.Transfer events for each option so NFT indexers pick them up.
    Does not need to fire on contract ownership transfer because once the tokens exist, the `ownerOf`
    check will always pass for contract owner.
     */
    function createOptionsAndEmitTransfers() internal {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(address(0), owner(), i);
        }
    }

    /// @notice Sets the base URI for constructing tokenURI values for options.
    function setBaseOptionURI(string memory _baseOptionURI) public onlyOwner {
        optionURI = _baseOptionURI;
    }

     /**
    @notice hack: transferFrom is called on sale � this method mints the real token
     */
    function transferFrom(
        address,
        address _to,
        uint256 _optionId
    )
        public
        nonReentrant
        onlyOwnerOrProxy
        whenNotPaused
        interactBurnInvalidOptionId(_optionId)
    {
        token.factoryMint(_optionId, _to);
    }

    function safeTransferFrom(
        address,
        address _to,
        uint256 _optionId
    )
        public override
        nonReentrant
        onlyOwnerOrProxy
        whenNotPaused
        interactBurnInvalidOptionId(_optionId)
    {
        token.factoryMint(_optionId, _to);
    }

    function safeTransferFrom(
        address,
        address _to,
        uint256 _optionId,
        bytes calldata
    ) external {
        safeTransferFrom(_to, _to,_optionId);
    }

    /**
    @dev Return true if operator is an approved proxy of Owner
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        return isApprovedForProxy(_owner, _operator);
    }

    /**
    @notice Returns owner if _optionId is valid so posted orders pass validation
     */
    function ownerOf(uint256 _optionId) public view returns (address) {
        return token.factoryCanMint(_optionId) ? owner() : address(0);
    }

    /**
    @notice Returns a URL specifying option metadata, conforming to standard
    ERC1155 metadata format.
     */
    function tokenURI(uint256 _optionId) external view returns (string memory) {
        return string(abi.encodePacked(optionURI, _optionId.toString()));
    }
    
    ///@notice public facing method for _burnInvalidOptions in case state of tokenContract changes
    function burnInvalidOptions() public onlyOwner {
        _burnInvalidOptions();
    }

    ///@notice "burn" option by sending it to 0 address. This will hide all active listings. Called as part of interactBurnInvalidOptionIds
    function _burnInvalidOptions() internal {
        for (uint256 i; i < NUM_OPTIONS; ++i) {
            if (!token.factoryCanMint(i)) {
                emit Transfer(owner(), address(0), i);
            }
        }
    }

    /**
    @notice emit a transfer event for a "burnt" option back to the owner if factoryCanMint the optionId
    @dev will re-validate listings on OpenSea frontend if an option becomes eligible to mint again
    eg, if max supply is increased
    */
    function restoreOption(uint256 _optionId) external onlyOwner {
        if (token.factoryCanMint(_optionId)) {
            emit Transfer(address(0), owner(), _optionId);
        }
    }

    function totalSupply() external pure returns (uint256) { return 3333; }
    function approve(address operator, uint256) external onlyOwner { setProxyAddress(operator); }
    function getApproved(uint256) external view returns (address operator) {return proxyAddress();}
    function setApprovalForAll(address operator, bool) external onlyOwner { setProxyAddress(operator); }
    function balanceOf(address _owner) external view returns (uint256) {return _owner==owner()?NUM_OPTIONS:0;}
}
// File: microgas721.sol

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "TOO_POOR");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "CANT_SEND");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "LL_FAILED");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "LL_FAILED");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "TOO_POOR");
        require(isContract(target), "NOT_CONTRACT");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "LL_FAILED");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "NOT_CONTRACT");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "LL_FAILED");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "NOT_CONTRACT");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    uint256 public constant MAX_UINT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    //mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "BAD_ADDRESS");
        //return _balances[owner];
        //balanceOf in ERC-721 is pointless and nearly useless without the ERC721Enumerable extension.
        //returns max value just in case anything is actually relying on it for anything.
        //This should indicate that the method is not implemented without throwing or returning 0 which could cause confusion.
        return MAX_UINT;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner > address(1), "BAD_ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "BAD_ID");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "INVALID");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "NOT_OWNER"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "BAD_TOKEN");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NOT_APPROVED");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NOT_APPROVED");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "NOT_RECEIVER");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] > address(1);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "BAD_ID");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "NOT_RECEIVER"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to > address(1), "ZERO_ADDRESS");
        require(!_exists(tokenId), "ALREADY_MINTED");

        _beforeTokenTransfer(address(0), to, tokenId);

        //_balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        //_balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "NOT_OWNER");
        require(to > address(1), "ZERO_ADDRESS");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        //_balances[from] -= 1;
        //_balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "INVALID_APPROVE");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("NOT_RECEIVER");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "INITIALIZED");
        _;
        inited = true;
    }
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "BAD_SIGNER"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "FAILED");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

interface IToken {
    function approve(address spender, uint256 amount) external returns (bool);
}

abstract contract FactoryMintable is Context {
    address public tokenFactory;

    error NotTokenFactory();
    error FactoryCannotMint();

    modifier onlyFactory() {
        if (_msgSender() != tokenFactory) {
            revert NotTokenFactory();
        }
        _;
    }

    modifier canMint(uint256 _optionId) {
        if (!factoryCanMint(_optionId)) {
            revert FactoryCannotMint();
        }
        _;
    }

    function factoryMint(uint256 _optionId, address _to) external virtual;

    function factoryCanMint(uint256 _optionId)
        public
        view
        virtual
        returns (bool);
}

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

struct mintTier {
    uint8 tierIndex;
    uint32 finneyPrice;

    uint32 startIndex;
    uint32 endIndex;

    uint32 nextIDPlusOne; //must initialize as 1
}

enum purchaseType {
    PUBLIC_SALE,
    FREE_MINT,
    WHITE_LIST
}

struct purchaseData {
    uint256 tierID;
    uint256 quantity;
    purchaseType purchaseType;
    uint256[] whitelistBits;
    uint256[] freeMintIDs;
    bytes32 sigR;
    bytes32 sigS;
    uint8 sigV;
}

struct remainingNFTData {
    uint256 tierID;
    uint256 remaining;
    uint256 weiPrice;
    uint256 wlWeiPrice;
}

struct webData {
    remainingNFTData[] remaining;
    uint256 whiteListStartTimestamp;
    uint256 publicStartTimestamp;
    bool revealed;
}

contract Microgas721 is ContextMixin, NativeMetaTransaction, Ownable, ERC721, FactoryMintable, ReentrancyGuard {
    using Strings for uint256;
    using Address for address;

    uint256 public constant FINNEY = 1e15;
    uint256 public constant MAX_PER_TX = 5;

    uint256 public _tierCount;
    uint256 public _maxSupply;

    string private _contractMetadataURI;
    string[] private _tierBaseURI;
    mintTier[] public _packTiers;

    address _allowListSigningAddress;
    uint256 _revealBlock;
    uint256 _revealed;

    uint256 public _publicStartTimestamp = ERC721.MAX_UINT;
    uint256 public _whiteListStartTimestamp = ERC721.MAX_UINT;
    uint256[] _whitelistBits;

    address _openSeaProxy;
    mapping(address => bool) _revokedDefaultPermissions;
    mapping(address => mapping(uint256 => uint256)) _purchasedByOriginPerBlock;

    bool _paused = false;

    constructor(string memory name_, string memory symbol_, address proxy) ERC721(name_, symbol_) { 
        _openSeaProxy = proxy;
        setupInitialData();
    }
    
    function setupInitialData() private {
        _packTiers.push(mintTier(0,79,0,3332,1));
        _tierBaseURI.push("https://onjoyride.mypinata.cloud/ipfs/QmbxXvL1rSTHYye3CN6h1TBKnr3aFcTA4pMuLBYS6bVjBn/tokens/");
        _contractMetadataURI = "https://onjoyride.mypinata.cloud/ipfs/QmbxXvL1rSTHYye3CN6h1TBKnr3aFcTA4pMuLBYS6bVjBn/contract";

        _tierCount = 1;
        _maxSupply = 3333;

        _whiteListStartTimestamp = 1648501200;
        _publicStartTimestamp = 1648587600;

        _allowListSigningAddress = 0x8e69cAc0DBFe68BEfCa549f817F8Ee86c053dEeB;

        for(uint i = 0; i < 14; i++) {
            _whitelistBits.push(ERC721.MAX_UINT);
        }
    }

    modifier validSignature (purchaseData memory purchaseData_) {
        if(purchaseData_.purchaseType != purchaseType.PUBLIC_SALE) {
            bytes memory encodedPurchaseData;

            if(purchaseData_.purchaseType == purchaseType.WHITE_LIST) {
                encodedPurchaseData = abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    purchaseData_.whitelistBits,
                    bytes32(uint256(uint160(msg.sender))));
            } else {
                encodedPurchaseData = abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    purchaseData_.tierID,
                    purchaseData_.freeMintIDs,
                    bytes32(uint256(uint160(msg.sender))));
            }

            bytes32 hash = keccak256(encodedPurchaseData);

            require(
                _allowListSigningAddress == 
                    ecrecover(hash, 
                        purchaseData_.sigV, 
                        purchaseData_.sigR, 
                        purchaseData_.sigS)
                ,"NO_AUTH"
            );
        }

        _;
    }

    modifier beforeSale() {
        require(totalSupply() == 0 || _publicStartTimestamp > block.timestamp && _whiteListStartTimestamp > block.timestamp, "STARTED");
        _;
    }

    modifier publicStarted() {
        require(_publicStartTimestamp < block.timestamp, "BEFORE_PUBLIC");
        _;
    }

    modifier notRevealed() {
        require(_revealed == 0, "REVEALED");
        _;
    }

    modifier notPaused() {
        require(!_paused, "PAUSED");
        _;
    }

    function setOSFactory(ITokenFactory factory) public onlyOwner {
        tokenFactory = address(factory);
    }

    function setContractMetadataURI(string calldata uri) external onlyOwner {
        _contractMetadataURI = uri;
    }

    function setAllowListSigningAddress(address signer) external onlyOwner {
        _allowListSigningAddress = signer;
    }

    function setDropTimestamps(uint256 whiteListStart_, uint256 publicStart_) external onlyOwner beforeSale {
        _publicStartTimestamp = publicStart_;
        _whiteListStartTimestamp = whiteListStart_;
    }

    function setPackTiers(mintTier[] calldata tiers) external onlyOwner beforeSale {
        uint maxSupply = 0;
        for(uint i = 0; i < tiers.length; i++) {
            require(tiers[i].tierIndex == i, "BAD_INDEX");
            if(i < _tierCount) {
                _packTiers[i] = tiers[i];
            } else {
                _packTiers.push(tiers[i]);
                _tierBaseURI.push("");
            }
            maxSupply += tiers[i].endIndex - tiers[i].startIndex;
        }
        
        while(_packTiers.length > tiers.length) {
            _packTiers.pop();
            _tierBaseURI.pop();
        }

        _tierCount = tiers.length;
        _maxSupply = maxSupply;
    }

    function setReducedPackTier(uint mintTierIndex, uint32 newEndIndex) external onlyOwner notRevealed {
        mintTier memory tier = _packTiers[mintTierIndex];
        require(tier.startIndex < newEndIndex && tier.endIndex > newEndIndex, "BAD_TIER");
        _packTiers[mintTierIndex].endIndex = newEndIndex;
        uint oldSupply = tier.endIndex - tier.startIndex;
        uint newSupply = newEndIndex - tier.startIndex;
        _maxSupply -= oldSupply - newSupply;
    }

    function setPaused(bool state) external onlyOwner {
        _paused = state;
    }

    function initializeTierURIs(string[] calldata tierBaseURI_) external onlyOwner {
        require(tierBaseURI_.length == _tierCount, "BAD_URIS");
        for(uint i = 0; i < _tierCount; i++) {
            _tierBaseURI[i] = tierBaseURI_[i];
        }

        if(tokenFactory == address(0))
            ITokenFactory(tokenFactory).setBaseOptionURI(tierBaseURI_);
    }

    function addWhitelistBits(uint blockCount) public onlyOwner {
        for(uint i = 0; i < blockCount; i++) {
            _whitelistBits.push(ERC721.MAX_UINT);
        }
    }

    function prepReveal() external onlyOwner notRevealed {
        _revealBlock = block.number;
    }

    function reveal() external onlyOwner notRevealed {
        require(blockhash(_revealBlock + 10) != 0, "CANT_REVEAL");
        require(blockhash(_revealBlock + 20) != 0, "CANT_REVEAL");
        _revealed = uint256(keccak256(abi.encodePacked(
            blockhash(_revealBlock + 20), 
            blockhash(_revealBlock + 15), 
            blockhash(_revealBlock + 10))));
    }

    function primeThePump(uint256 start_, uint256 count_, uint256 tierID_, address[] calldata freebieAddresses_) external onlyOwner {
        mintTier memory tier = _packTiers[tierID_];
        require(tier.startIndex < start_+1, "NOT_IN_TIER");
        require(tier.endIndex > start_+count_-2, "NOT_IN_TIER");

        for(uint i = start_; i < start_+count_; i++) {
            if(i >= start_ + freebieAddresses_.length) {
                require(_owners[i] == address(0), "ID_INITIALIZED");
                _owners[i] = address(1);
            }
            else {
                require(start_ == tier.startIndex, "BAD_FREEBIE_ID");
                _safeMint(freebieAddresses_[i-start_], i, "");
            }
        }
        tier.nextIDPlusOne += uint32(freebieAddresses_.length);

        _packTiers[tierID_] = tier;
    }

    /**
    * @dev Returns the total unsold tokens from a tier by its index.
    */
    function tierUnsold(uint256 tierIDX) private view returns (uint256) {
        mintTier memory tier = _packTiers[tierIDX];
        return tier.endIndex - tier.startIndex - tier.nextIDPlusOne + 2;
    }

    /**
    * @dev Returns the price of token from a tier by its index.
    */
    function tierPrice(uint256 tierIDX) private view returns (uint256) {
        mintTier memory tier = _packTiers[tierIDX];
        return tier.finneyPrice*FINNEY;
    }

    /**
    * @dev Returns the presale price of token from a tier by its index.
    */
    function tierWLPrice(uint256 tierIDX) private view returns (uint256) {
        mintTier memory tier = _packTiers[tierIDX];
        return tier.finneyPrice*FINNEY;
    }

    function remainingItems() external view returns (webData memory) {
        remainingNFTData[] memory remainingNFT = new remainingNFTData[](_tierCount);
        for(uint i = 0; i < _tierCount; i++) {
            uint256 remaining = tierUnsold(i);
            uint256 weiPrice = tierPrice(i);
            uint256 wlWeiPrice = tierWLPrice(i);
            remainingNFT[i] = remainingNFTData(i,remaining,weiPrice,wlWeiPrice);
        }
        return webData(remainingNFT, _whiteListStartTimestamp, _publicStartTimestamp, _revealed != 0);
    }

    function idToTier(uint256 tokenId_) private view returns (mintTier memory) {
        mintTier memory tier;
        for(uint i = 0; i < _tierCount; i++) {
            tier = _packTiers[i];
            if(tier.startIndex <= tokenId_ && tier.endIndex >= tokenId_) {
                return tier;
            }
        }
        require(false, "INVALID_ID");
        return tier;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "INVALID_ID");
        mintTier memory tier = idToTier(tokenId_);
        string memory baseURI = _tierBaseURI[tier.tierIndex];
        if(_revealed == 0) {
            return string(
                abi.encodePacked(baseURI, "default")
            );
        } else {
            uint id = tokenId_ - tier.startIndex;
            id = (_revealed + id) % (tier.endIndex - tier.startIndex);
            id += tier.startIndex;
            return string(
                abi.encodePacked(baseURI, "revealed/", id.toString())
            );
        }
    }

    /**
     * @dev See {IERC721-balanceOf}.
     * Using a simple naive search of all entries and counting. This costs way too much gas for use on chain. 
     * On-chain ownership-of-any checks should require an ID as parameter and use ownerOf().
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner <= address(1), "BAD_QUERY");
        uint count;
        for( uint i; i < _maxSupply; ++i ){
          if( owner == _owners[i])
            ++count;
        }
        return count;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns (uint256) {
        uint256 sumTotal = 0;
        for(uint i = 0; i < _tierCount; i++) {
            sumTotal += _packTiers[i].nextIDPlusOne;
        }
        return sumTotal - _tierCount;
    }

    function mintTokenComplex(purchaseData[] calldata data_) external payable {
        uint256 valueRemaining = msg.value;
        uint256 totalPurchased = 0;

        for(uint i = 0; i < data_.length; i++) {
            if(data_[i].purchaseType == purchaseType.PUBLIC_SALE) {
                require(_publicStartTimestamp > block.timestamp, "NOT_START");
                uint256 price = tierPrice(data_[i].tierID);
                valueRemaining -= mintTokenBase(data_[i].tierID,data_[i].quantity, valueRemaining, price, msgSender());
                totalPurchased += data_[i].quantity;
            } else {
                require(block.timestamp > _whiteListStartTimestamp && block.timestamp < _publicStartTimestamp, "NOT_WL");
                valueRemaining -= mintTokenPresale(data_[i], valueRemaining);
                totalPurchased += data_[i].quantity;
            }
        }

        if(msg.sender != tx.origin) { //unfortunately for botters (and some people using CA wallets) this costs some extra gas to enforce
            totalPurchased += _purchasedByOriginPerBlock[tx.origin][block.number];
            _purchasedByOriginPerBlock[tx.origin][block.number] = totalPurchased;
        }

        require(totalPurchased < 1+MAX_PER_TX, "TOO_MANY");
    }

    function factoryCanMint(uint256 _optionId)
        public
        view
        virtual
        override
        publicStarted
        notPaused
        returns (bool)
    {
        uint256 packTier = _optionId % _tierCount;
        uint256 quantity = 1 + (_optionId / _tierCount)*2;
        mintTier memory tier = _packTiers[packTier];
        uint256 _firstID = tier.startIndex + tier.nextIDPlusOne - 1;
        if (tokenFactory == address(0) || _firstID + quantity > tier.endIndex + 1) {
            return false;
        }

        return true;
    }

    function factoryMint(uint256 _optionId, address _to)
        public
        override
        nonReentrant
        onlyFactory
        canMint(_optionId)
    {
        uint256 packTier = _optionId % _tierCount;
        uint256 quantity = 1 + (_optionId / _tierCount)*2;
        mintTokenBase(packTier, quantity, 0, 0, _to);
    }

    function mintTokenSimple(uint256 tierID_, uint256 quantity_) external payable publicStarted {
        require(quantity_ < MAX_PER_TX+1, "TOO_MANY");
        uint256 price = tierPrice(tierID_);
        mintTokenBase(tierID_, quantity_, msg.value, price, msgSender());
    }

    function mintTokenBase(uint256 tierID_, uint256 quantity_, uint256 valueRemaining, uint256 price, address recipient) internal notPaused returns (uint256 cost) {
        require(tierID_ < _tierCount, "BAD_TIER");

        mintTier memory tier = _packTiers[tierID_];
        uint256 finalPrice = price * quantity_;
        require(valueRemaining+1 > finalPrice, "LOW_PAY");

        uint256 _firstID = tier.startIndex + tier.nextIDPlusOne - 1;
        require(_firstID + quantity_ - 1 < tier.endIndex + 1, "TOO_MANY");

        for(uint256 i = 0; i < quantity_; i++) {
            _safeMint(recipient, _firstID, "");
            _firstID++;
        }

        tier.nextIDPlusOne += uint32(quantity_);
        _packTiers[tierID_] = tier;

        return finalPrice;
    }

    function mintTokenPresale(purchaseData memory data_, uint256 valueRemaining_) internal validSignature(data_) returns (uint256 valueRemaining) {
        require(data_.tierID < _tierCount, "BAD_TIER");

        uint quantityMintable = 0;
        for(uint i = 0; i < _whitelistBits.length && quantityMintable < data_.quantity; i++) {
            uint256 wlBitBlock = _whitelistBits[i];
            if(data_.whitelistBits[i] & wlBitBlock > 0) {
                wlBitBlock = wlBitBlock &~ data_.whitelistBits[i];
                quantityMintable++;
                _whitelistBits[i] = wlBitBlock;
            }
        }

        require(quantityMintable >= data_.quantity, "TOO_MANY_WL");
        uint256 price = tierWLPrice(data_.tierID);
        return mintTokenBase(data_.tierID, data_.quantity, valueRemaining_, price, msgSender());
    }

    function getPreMintRemaingSlotsCount(uint256[] calldata whitelistBits) external view returns (uint) {
        uint quantityMintable = 0;
        for(uint i = 0; i < _whitelistBits.length; i++) {
            uint256 wlBitBlock = _whitelistBits[i];
            if(whitelistBits[i] & wlBitBlock > 0) {
                quantityMintable++;
            }
        }
        return quantityMintable;
    }

    /**
     * @dev Allows users to deny default approval addresses such as OpenSea
     */
    function toggleOpenSeaApproval(bool revoked) external {
        _revokedDefaultPermissions[msg.sender] = revoked;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxy);
        if (!_revokedDefaultPermissions[owner] && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * Override to handle locked presales
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
        require(_exists(tokenId), "BAD_ID");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function withdrawEther(address recipient) external onlyOwner {
        address payable _this = payable(address(this));
        require(_this.balance > 0, "NO_ETHER");
        (bool success, ) = recipient.call{value: _this.balance}("");
        require(success, "SEND_FAILED"); //Address: unable to send value, recipient may have reverted
    }

    function setTokenApprovalsForOwner(IToken token_) external onlyOwner {
        token_.approve(owner(), ERC721.MAX_UINT);
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }
}

interface ITokenFactory {
    function setBaseOptionURI(string[] memory _baseOptionURIs) external;
}