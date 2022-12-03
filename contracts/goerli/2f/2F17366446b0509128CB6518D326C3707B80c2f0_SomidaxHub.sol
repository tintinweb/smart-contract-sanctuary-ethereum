// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Nft__PriceMustBeAboveZero();
error Nft__NotApprovedForMarket();
error Nft_AlreadyListed(address nftAddress, uint256 tokenId);
error Nft__NotOwner(address owner);
error Nft__NotListed(address nftAddress, uint256 tokenId);
error Nft__NotOwnerEth();
error Nft__TransferFailed();

contract SomidaxHub is ReentrancyGuard {
    constructor() {}

    address public constant SMDXADDRESS =
        0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
    address public constant USDTADDRESS =
        0x509Ee0d083DdF8AC028f2a56731412edD63223B9;

    struct Proceeds {
        uint256 ethBalance;
        uint256 bnbBalance;
        uint256 smdxBalance;
        uint256 usdtBalance;
    }

    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed price,
        uint256 tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId
    );

    event Transfer(
        address indexed receiver,
        address indexed sender,
        uint256 amount,
        string symbol
    );
    event Deposit(
        address indexed depositAddress,
        string indexed symbol,
        uint256 amount
    );
    event Withdraw(
        address indexed withdrawalAddress,
        string indexed symbol,
        uint256 amount
    );

    event buyCofee(
        address indexed userAddress,
        address indexed sender,
        uint256 smdxAmout
    );

    modifier NotListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert Nft_AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier IsOwner(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);

        if (owner != sender) {
            revert Nft__NotOwner(sender);
        }
        _;
    }

    modifier IsListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];

        if (listing.price <= 0) {
            revert Nft__NotListed(nftAddress, tokenId);
        }

        _;
    }

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => Proceeds) private s_procceeds;

    function list_item(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        NotListed(nftAddress, tokenId, msg.sender)
        IsOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert Nft__PriceMustBeAboveZero();
        }

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert Nft__NotApprovedForMarket();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, price, tokenId);
    }

    function buy_item(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external IsListed(nftAddress, tokenId) {
        // the user clicks onn buy nft
        // sends the amout to smdx wallet address
        //we transfer the nft to the buyer then
        //increase the seller amount
        Listing memory listing = s_listings[nftAddress][tokenId];

        if (price < listing.price) {
            revert("Listing Price is greater than amount sent");
        }

        IERC20(SMDXADDRESS).transferFrom(msg.sender, address(this), price);

        s_procceeds[listing.seller].smdxBalance =
            s_procceeds[listing.seller].smdxBalance +
            price;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId
        );
        emit ItemBought(msg.sender, nftAddress, tokenId, listing.price);
    }

    function cancel_listing(
        address nftAddress,
        uint256 tokenId
    )
        external
        IsOwner(nftAddress, tokenId, msg.sender)
        IsListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function update_listing(
        uint256 price,
        address nftAddress,
        uint256 tokenId
    )
        public
        IsListed(nftAddress, tokenId)
        IsOwner(nftAddress, tokenId, msg.sender)
    {
        s_listings[nftAddress][tokenId].price = price;
        emit ItemListed(msg.sender, nftAddress, price, tokenId);
    }

    function transfer(
        address receiver,
        uint256 amount,
        string memory symbol
    ) external {
        Proceeds memory proceed = s_procceeds[msg.sender];
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            if (proceed.smdxBalance < amount) {
                revert("Insufficient Funds");
            }
            s_procceeds[msg.sender].smdxBalance -= amount;
            s_procceeds[receiver].smdxBalance += amount;

            emit Transfer(receiver, msg.sender, amount, symbol);
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("eth"))
        ) {
            if (proceed.ethBalance < amount) {
                revert("Insufficient Funds");
            }
            s_procceeds[msg.sender].ethBalance -= amount;
            s_procceeds[receiver].ethBalance += amount;

            emit Transfer(receiver, msg.sender, amount, symbol);
        } else {
            if (proceed.bnbBalance < amount) {
                revert("Insufficient Funds");
            }
            s_procceeds[msg.sender].bnbBalance -= amount;
            s_procceeds[receiver].bnbBalance += amount;

            emit Transfer(receiver, msg.sender, amount, symbol);
        }
    }

    function depositEth(string memory symbol) external payable {
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        s_procceeds[msg.sender].ethBalance += msg.value;
        emit Deposit(msg.sender, symbol, msg.value);
    }

    function withdrawEth(string memory symbol, uint256 amount) external {
        Proceeds memory proceeds = s_procceeds[msg.sender];

        if (proceeds.ethBalance < amount) {
            revert("Not Enough Funds");
        }

        s_procceeds[msg.sender].ethBalance -= amount;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(msg.sender, symbol, amount);
    }

    function deposit(string memory symbol, uint256 amount) external {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            IERC20(SMDXADDRESS).transferFrom(msg.sender, address(this), amount);

            s_procceeds[msg.sender].smdxBalance += amount;
            emit Deposit(msg.sender, symbol, amount);
        } else {
            IERC20(USDTADDRESS).transferFrom(msg.sender, address(this), amount);

            s_procceeds[msg.sender].usdtBalance += amount;
            emit Deposit(msg.sender, symbol, amount);
        }
    }

    function withdraw_proceeds(string memory symbol, uint256 amount) external {
        Proceeds memory proceeds = s_procceeds[msg.sender];

        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            if (proceeds.smdxBalance < amount) {
                revert("Not Enough Funds");
            }

            s_procceeds[msg.sender].smdxBalance -= amount;
            IERC20(SMDXADDRESS).transfer(msg.sender, amount);

            emit Withdraw(msg.sender, symbol, amount);
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("usdt"))
        ) {
            if (proceeds.usdtBalance < amount) {
                revert("Not Enough Funds");
            }

            s_procceeds[msg.sender].usdtBalance -= amount;
            IERC20(USDTADDRESS).transfer(msg.sender, amount);

            emit Withdraw(msg.sender, symbol, amount);
        }
    }

    function buy_cofee(
        address userAddress,
        string memory symbol,
        uint256 amount
    ) public {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("eth"))
        ) {
            (bool sent, ) = payable(address(this)).call{value: amount}("");
            require(sent, "Failed to send Ether");

            s_procceeds[userAddress].ethBalance += amount;
            emit buyCofee(userAddress, msg.sender, amount);
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("smdx"))
        ) {
            IERC20(SMDXADDRESS).transferFrom(msg.sender, address(this), amount);

            s_procceeds[userAddress].smdxBalance += amount;
            emit buyCofee(userAddress, msg.sender, amount);
        } else {
            IERC20(USDTADDRESS).transferFrom(msg.sender, address(this), amount);

            s_procceeds[userAddress].usdtBalance += amount;
            emit buyCofee(userAddress, msg.sender, amount);
        }
    }

    receive() external payable {}

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(
        address seller
    ) external view returns (Proceeds memory) {
        return s_procceeds[seller];
    }
}