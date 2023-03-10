/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.0;

/*
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function withdraw(uint256 wad) external payable;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:ERC1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

interface ITest {
    function isERC1155(address nftAddress) external returns (bool);
    function isERC721(address nftAddress) external returns (bool);
}

interface MarketPlace {
    function owner() external view returns (address owner);
}

contract SeaGoldMarketplace is  ITest, IERC165,Ownable {

    error BalErro(bytes23 msgVal);
    error OwnErro(bytes23 msgVal);
    error QtyErro(bytes23 msgVal);
    error AmtErro(bytes23 msgVal);
    error SignErro(bytes23 msgVal);
    
    struct saleStruct {
        uint256 amount;
        uint64 tokenId;
        uint64 nooftoken;
        uint64 nftType;
        address from;
        address _conAddr;
    }

    using ERC165Checker for address;
    bytes4 public constant IID_ITEST = type(ITest).interfaceId;
    bytes4 public constant IID_IERC165 = type(IERC165).interfaceId;
    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    struct royaltyInfo {
        bool status;
        bool isMutable;
        address royaltyAddress;
        uint256 royaltyPercentage;
    }

    mapping(address => royaltyInfo) public RoyaltyInfo;
    address[] address721;
    mapping(address => bool) public address721Exists;

    function acceptBId(
        uint256 amount,
        uint64 tokenId,
        uint64 nooftoken,
        uint64 nftType,
        address bidaddr,
        address _conAddr
    ) public {
        if(IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).allowance(bidaddr, address(this)) < amount && IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).balanceOf(bidaddr) > amount){
            revert BalErro("balError");
        }

        if (nftType == 721) {
            if(IERC721(_conAddr).ownerOf(tokenId) != msg.sender){
                revert OwnErro("OwnErr");
            }
            IERC721(_conAddr).safeTransferFrom(msg.sender, bidaddr, tokenId);
        } else {
            if(IERC1155(_conAddr).balanceOf(msg.sender,tokenId) < nooftoken){
               revert  QtyErro("InsuffQty");
            }
            IERC1155(_conAddr).safeTransferFrom(msg.sender,bidaddr,tokenId,nooftoken,"");
        }

        (,,address royAddress, uint256 royPercentage ) = getRoyaltyInfo(_conAddr);

        uint256 goldfees = ( amount * 5 * 1e17 ) / 1e20 ;
        uint256 royalty = ( amount * royPercentage ) / 1e20 ;
        uint256 netAmount = amount - ( goldfees + royalty  );
        if(goldfees + royalty + netAmount > amount){
           revert  AmtErro("AmtErr");
        }

        IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).transferFrom(bidaddr, 0xdC6A32D60002274A16A4C1E93784429D4F7D1C6a, goldfees);
        IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).transferFrom(bidaddr, msg.sender, netAmount);
        if (royalty > 0) {
            IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).transferFrom(bidaddr, royAddress, royalty);
        }

        if (IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).balanceOf(address(this)) > (600000 * 1e18)) {
            IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(msg.sender, (amount * 500000));
            IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(bidaddr, (amount * 100000));
        }
    }

    function buyToken(
        bytes[] memory signature,
        address[] memory from,
        address[] memory _conAddr,
        uint64[] memory tokenId,
        uint64[] memory nooftoken,
        uint64[] memory nftType,
        uint256[] memory amount,
        uint256[] memory nonce,
        uint256 totalamount
    ) public payable {
        if(msg.value < totalamount){
           revert  AmtErro("AmtErr");
        }
        for (uint256 i; i < from.length;) {
            saleStruct memory salestruct;

            salestruct.amount = amount[i];
            salestruct.tokenId = tokenId[i];
            salestruct.nooftoken = nooftoken[i];
            salestruct.from = from[i];
            salestruct.nftType = nftType[i];
            salestruct._conAddr = _conAddr[i];
            
            bytes32 message = prefixed(keccak256(abi.encodePacked(salestruct.from, nonce[i])));
             if(recoverSigner(message, signature[i]) != salestruct.from){
                revert  SignErro("SigWrn");
            }
            
            (,, address royAddress, uint256 royPercentage) = getRoyaltyInfo(_conAddr[i]);

            uint256 goldfees = ( salestruct.amount * 5 * 1e17 ) / 1e20;
            uint256 royalty = ( salestruct.amount * royPercentage ) / 1e20;
            uint256 netAmount = salestruct.amount - ( goldfees + royalty);
            if(goldfees + royalty + netAmount > salestruct.amount){
                revert  AmtErro("AmtErr");
            }

            payable(salestruct.from).transfer(netAmount);
            payable(0xdC6A32D60002274A16A4C1E93784429D4F7D1C6a).transfer(goldfees);
            if (royalty > 0) {
                payable(royAddress).transfer(royalty);
            }

            if (IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).balanceOf(address(this)) > 600000 * 1e18) {
                IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(salestruct.from, salestruct.amount * 500000);
                IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(msg.sender, salestruct.amount * 100000);
            } 

            if (salestruct.nftType == 721) {
                if(IERC721(salestruct._conAddr).ownerOf(salestruct.tokenId) != salestruct.from){
                    revert OwnErro("OwnErr");
                }
                IERC721(salestruct._conAddr).safeTransferFrom(salestruct.from, msg.sender, salestruct.tokenId);
            } else {
                if(IERC1155(salestruct._conAddr).balanceOf(salestruct.from,salestruct.tokenId) < salestruct.nooftoken){
                    revert  QtyErro("InsuffQty");
                }
                IERC1155(salestruct._conAddr).safeTransferFrom(salestruct.from,msg.sender,salestruct.tokenId,salestruct.nooftoken,"");
            }

            unchecked {
                i++;
            }
        }
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }


    function isERC1155(address nftAddress) external view override returns (bool) {
        return nftAddress.supportsInterface(IID_IERC1155);
    }    
    
    function isERC721(address nftAddress) external view override returns (bool) {
        return nftAddress.supportsInterface(IID_IERC721);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == IID_ITEST || interfaceId == IID_IERC165;
    }

    function update721Address(
        address _contractAddress
    ) public onlyOwner {
        require(!address721Exists[_contractAddress],"Already Exist");
        address721.push(_contractAddress);
        address721Exists[_contractAddress] = true;
    }

    function getAddressCount() public view  returns (uint256) {
        return address721.length;
    }
    function AddressExist (address _contractAddress) public view  returns (bool) {
        return address721Exists[_contractAddress];
    }

    function get721Address( )public view returns(address[] memory) {
        return address721;
    }
    
    function setRoyalty(
        address _contractAddress,
        address _royaltyAddress,
        uint256 _royaltyPercentage,
        bool _isMutable  // True means Royalty Settings can be changed. False means Royalty Settings cannot be changed.
    ) public {
        require(
            _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        if ( _contractAddress.supportsInterface(IID_IERC721)) {
            require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
            );
        } else if (_contractAddress.supportsInterface(IID_IERC1155)) {
            require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
            );
        }
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        require(!royalty.status, "Royalty Already Set");
        require(_royaltyAddress!= address(0) && _royaltyPercentage >= 1 && _royaltyPercentage <= 10, "Not valid data");
        royalty.status = true;
        royalty.isMutable = _isMutable;
        royalty.royaltyAddress = _royaltyAddress;
        royalty.royaltyPercentage = _royaltyPercentage * 1e18;
    }

    function updateRoyalty(
        address _contractAddress,
        address _royaltyAddress,
        uint256 _royaltyPercentage,
        bool _isMutable  // True means Royalty Settings can be changed. False means Royalty Settings cannot be changed.
    ) public {
        require(
             _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        if ( _contractAddress.supportsInterface(IID_IERC721)) {
            require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
            );
        } else if (_contractAddress.supportsInterface(IID_IERC1155)) {
            require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
            );
        }
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        require(royalty.status, "Set the royalty");
        require(royalty.isMutable, "Not mutable");
        require(_royaltyAddress!= address(0) && _royaltyPercentage >= 1 && _royaltyPercentage <= 10, "Not valid data");
        royalty.isMutable = _isMutable;
        royalty.royaltyAddress = _royaltyAddress;
        royalty.royaltyPercentage = _royaltyPercentage * 1e18;
    }

    function updateMutability(address _contractAddress)
        public
    {
        require(
             _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        if ( _contractAddress.supportsInterface(IID_IERC721)) {
            require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
            );
        } else if (_contractAddress.supportsInterface(IID_IERC1155)) {
            require(
                msg.sender == MarketPlace(_contractAddress).owner(),
                "Not the Owner"
            );
        }
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        require(royalty.status, "Set the royalty");
        require(royalty.isMutable, "Not mutable");
        royalty.isMutable = false;
    }

    function getRoyaltyInfo(address _contractAddress)
        public
        view
        returns (bool,bool,address,uint256)
    {
        require(
             _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        return (royalty.status,royalty.isMutable,royalty.royaltyAddress,royalty.royaltyPercentage);
    }

    function checkRoyalty(address _contractAddress) external view returns(bool){
        require(
             _contractAddress.supportsInterface(IID_IERC721) || _contractAddress.supportsInterface(IID_IERC1155),
            "Not a NFT Contract"
        );
        royaltyInfo storage royalty = RoyaltyInfo[_contractAddress];
        return royalty.status;
    }
}