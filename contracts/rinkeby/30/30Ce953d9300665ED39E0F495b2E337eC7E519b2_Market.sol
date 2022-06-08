// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMarket {
    event Bought(
        address _seller,
        address _buyer,
        uint256 _tokenId,
        uint256 _price
    );

    event Bid(
        address _seller,
        address _buyer,
        uint256 _tokenId,
        uint256 _price
    );

    event OpenForSell(address _seller, uint256 _price, uint256 _tokenId);

    event CancelSell(address _seller, uint256 _tokenId);
}

struct Bider {
    address seller;
    uint256 price;
    uint256 tokenId;
}

contract MarkerModifier {
    IERC20 internal _wrapETH;
    IERC721 internal _nft;

    mapping(uint256 => uint256) internal _tokenIdToPrice;
    mapping(uint256 => Bider) internal _tokenIdToBider;

    modifier onlyOwner(uint256 _tokenId) {
        require(
            msg.sender == _nft.ownerOf(_tokenId),
            "Owner must be the same as the token owner"
        );
        _;
    }

    modifier notOwner(uint256 _tokenId) {
        require(
            msg.sender != _nft.ownerOf(_tokenId),
            "Owner must be not the same as the token owner"
        );
        _;
    }

    modifier onlyBuy(uint256 _tokenId) {
        require(
            msg.sender != _nft.ownerOf(_tokenId),
            "Owner must be the same as the token owner"
        );
        require(
            _tokenIdToPrice[_tokenId] > 0,
            "Token price must be greater than 0"
        );
        require(
            _wrapETH.allowance(msg.sender, address(this)) >=
                _tokenIdToPrice[_tokenId],
            "Not enough WETH"
        );
        _;
    }
}

contract Market is MarkerModifier, IMarket {
    constructor(address wrapETH, address nft) {
        _wrapETH = IERC20(wrapETH);
        _nft = IERC721(nft);
    }

    function priceOfToken(uint256 _tokenId) public view returns (uint256) {
        return _tokenIdToPrice[_tokenId];
    }

    /*
        call Approve on the NFT contract to allow the market to transfer the token
     */
    function openSellToken(uint256 _tokenId, uint256 _price)
        external
        onlyOwner(_tokenId)
    {
        _tokenIdToPrice[_tokenId] = _price;
        emit OpenForSell(msg.sender, _price, _tokenId);
    }

    /*
        call Approve on the zero to disallow the market to transfer the token
     */
    function cancelSellToken(uint256 _tokenId) external onlyOwner(_tokenId) {
        _tokenIdToPrice[_tokenId] = 0;
        emit CancelSell(msg.sender, _tokenId);
    }

    /*
        call Approve on the NFT contract to allow the market to transfer the token
     */
    function acceptBid(uint256 _tokenId, address _buyer)
        external
        onlyOwner(_tokenId)
    {
        uint256 _price = _tokenIdToBider[_tokenId].price;
        require(_price > 0, "Price must be greater than 0");
        _tokenIdToBider[_tokenId] = Bider(address(0), 0, 0);
        _nft.transferFrom(msg.sender, _buyer, _tokenId);
        _wrapETH.transfer(_buyer, _price);
        emit Bought(msg.sender, _buyer, _tokenId, _price);
    }

    /*
        call Approve on WETH contract to allow the market to transfer the token
     */
    function buy(uint256 _tokenId) external onlyBuy(_tokenId) {
        address _seller = _nft.ownerOf(_tokenId);
        _nft.transferFrom(_seller, msg.sender, _tokenId);
        _wrapETH.transferFrom(_seller, msg.sender, _tokenIdToPrice[_tokenId]);
        _tokenIdToPrice[_tokenId] = 0;
        emit Bought(_seller, msg.sender, _tokenId, _tokenIdToPrice[_tokenId]);
    }

    function bid(uint256 _tokenId, uint256 _price) external notOwner(_tokenId) {
        require(_tokenIdToPrice[_tokenId] == 0, "Token price must not sell");
        require(_price > 0, "Price must be greater than 0");
        require(
            _price > _tokenIdToBider[_tokenId].price,
            "Price must be greater than the current bid price"
        );
        _wrapETH.approve(address(this), _price);
        _tokenIdToBider[_tokenId] = Bider(msg.sender, _price, _tokenId);
        emit Bid(
            msg.sender,
            _nft.ownerOf(_tokenId),
            _tokenId,
            _tokenIdToPrice[_tokenId]
        );
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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