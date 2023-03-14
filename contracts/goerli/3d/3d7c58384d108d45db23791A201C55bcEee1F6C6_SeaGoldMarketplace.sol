/**
 *Submitted for verification at Etherscan.io on 2023-03-14
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

interface RoyaltyRegistry {
    function getRoyaltyInfo(address _contractAddress)
        external
        view
        returns 
        (bool,bool,address,uint256);
}

contract SeaGoldMarketplace is Ownable {

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

    function acceptBId(
        uint256 amount,
        uint64 tokenId,
        uint64 nooftoken,
        uint64 nftType,
        address bidaddr,
        address _conAddr
    ) public {
        if(IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).allowance(bidaddr, address(this)) < amount || IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).balanceOf(bidaddr) < amount){
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

        RoyaltyRegistry royReg = RoyaltyRegistry(0xA8dB87247BA1CC2fCdAbE091D6024C5397135850);
        (,,address royAddress, uint256 royPercentage) = royReg.getRoyaltyInfo(_conAddr);

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

        uint256 sellerRewards = amount * 500000;
        uint256 buyerRewards = amount * 100000;
        if (IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).balanceOf(address(this)) > (sellerRewards + buyerRewards)) {
            IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(msg.sender, sellerRewards);
            IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(bidaddr, buyerRewards);
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
        uint256 totalBuyerRewards;
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
            
            RoyaltyRegistry royReg = RoyaltyRegistry(0xA8dB87247BA1CC2fCdAbE091D6024C5397135850);
            (,,address royAddress, uint256 royPercentage) = royReg.getRoyaltyInfo(_conAddr[i]);

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

            uint256 sellerRewards = salestruct.amount * 500000;
            uint256 buyerRewards = salestruct.amount * 100000;
            if (IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).balanceOf(address(this)) > (sellerRewards + buyerRewards)) {
            IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(salestruct.from, sellerRewards);
            totalBuyerRewards = totalBuyerRewards + buyerRewards;
            }

            unchecked {
                i++;
            }
        }
        IERC20(0xdC9175Ce5eEB959740be95923133B66a8A445d3d).transfer(msg.sender, totalBuyerRewards);
        totalBuyerRewards = 0;
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
}