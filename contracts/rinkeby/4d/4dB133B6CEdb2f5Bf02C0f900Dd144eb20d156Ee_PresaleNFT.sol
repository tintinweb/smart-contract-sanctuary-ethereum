// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// INTERFACES
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./interfaces/IDownlineNFT.sol";
import "./interfaces/IToken.sol";

/**
 * @title Presale NFT
 * @author Steve Harmeyer
 * @notice This is the presale NFT contract. Anyone holding one of these NFTs
 * can exchange them for 500 FUR tokens + 2 downline NFTs.
 */
contract PresaleNFT {
    /**
     * @dev Contract owner address.
     */
    address public owner;

    /**
     * @dev Paused state.
     */
    bool public paused = true;

    /**
     * @dev Payment token.
     */
    IERC20 public paymentToken;

    /**
     * @dev $FUR token.
     */
    IToken public token;

    /**
     * @dev $FURNFT token.
     */
    IDownlineNFT public downlineNft;

    /**
     * @dev Pool address.
     */
    address public poolAddress;

    /**
     * @dev Array of addresses that can buy while paused.
     */
    mapping(address => bool) private _presaleWallets;

    /**
     * @dev Stats.
     */
    uint256 public totalSupply;
    uint256 public totalCreated;
    uint256 public maxSupply = 300;
    uint256 public maxPerUser = 1;
    uint256 public price = 250e16;
    uint256 public tokenValue = 500e16;
    uint256 public nftValue = 2;
    uint256 private _currentTokenId;
    mapping(uint256 => bool) private _exists;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string public baseURI = 'ipfs://QmSZhsoYWeb9gCXAaGDe7vs9AVFPxr5nn2GWxicBKKouui/';

    /**
     * @dev Contract events.
     */
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    event Approval(address indexed owner_, address indexed approved_, uint256 indexed tokenId_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, bool approved_);
    event Minted(address indexed to_, uint256 indexed tokenId_);
    event Claimed(uint256 indexed tokenId_);

    /**
     * @dev Contract constructor.
     */
    constructor()
    {
        owner = msg.sender;
    }

    /**
     * -------------------------------------------------------------------------
     * ERC721 STANDARDS
     * -------------------------------------------------------------------------
     */

    /**
     * @dev see {IERC721-name}.
     */
    function name() external pure returns (string memory)
    {
        return "Furio Presale NFT";
    }

    /**
     * @dev see {IERC721-symbol}.
     */
    function symbol() external pure returns (string memory)
    {
        return "$FURPRESALE";
    }

    /**
     * @dev see {IERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId_) external view returns (string memory)
    {
        require(_exists[tokenId_], "Token does not exist");
        return string(abi.encodePacked(baseURI, tokenId_));
    }

    /**
     * @dev see {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public isNotPaused
    {
        require(to_ != address(0), "Cannot transfer to zero address");
        address _owner_ = ownerOf[tokenId_];
        require(msg.sender == _owner_ || msg.sender == getApproved(tokenId_) || isApprovedForAll(_owner_, msg.sender), "Unauthorized");
        _tokenApprovals[tokenId_] = address(0);
        emit Approval(_owner_, address(0), tokenId_);
        balanceOf[from_] -= 1;
        balanceOf[to_] += 1;
        ownerOf[tokenId_] = to_;
        emit Transfer(from_, to_, tokenId_);
    }

    /**
     * @dev see {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) external isNotPaused
    {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @dev see {IERC721-transferFrom}.
     */
    function transferFrom(address from_, address to_, uint256 tokenId_) external isNotPaused
    {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @dev see {IERC721-approve}.
     */
    function approve(address approved_, uint256 tokenId_) public isNotPaused
    {
        address _owner_ = ownerOf[tokenId_];
        require(approved_ != _owner_, "Cannot approve to current owner");
        require(msg.sender == _owner_ || isApprovedForAll(_owner_, msg.sender), "Unauthorized");
        _tokenApprovals[tokenId_] = approved_;
        emit Approval(_owner_, approved_, tokenId_);
    }

    /**
     * @dev see {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator_, bool approved_) external isNotPaused
    {
        require(msg.sender != operator_, "Cannot approve to current owner");
        _operatorApprovals[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    /**
     * @dev see {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId_) public view returns (address)
    {
        require(_exists[tokenId_], "Token does not exist");
        return _tokenApprovals[tokenId_];
    }

    /**
     * @dev see {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator_) public view returns (bool)
    {
        return _operatorApprovals[owner_][operator_];
    }

    /**
     * -------------------------------------------------------------------------
     * ERC165 STANDARDS
     * -------------------------------------------------------------------------
     */
    function supportsInterface(bytes4 interfaceId_) external pure returns (bool)
    {
        return interfaceId_ == type(IERC721).interfaceId || interfaceId_ == type(IERC721Metadata).interfaceId;
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Set contract owner.
     * @param address_ The address of the owner wallet.
     */
    function setContractOwner(address address_) external onlyOwner
    {
        owner = address_;
    }

    /**
     * @dev Pause contract.
     */
    function pause() external onlyOwner
    {
        paused = true;
    }

    /**
     * @dev Unpause contract.
     */
    function unpause() external onlyOwner
    {
        paused = false;
    }

    /**
     * @dev Set payment token.
     */
    function setPaymentToken(address address_) external onlyOwner
    {
        paymentToken = IERC20(address_);
    }

    /**
     * @dev Set $FUR token.
     */
    function setFurToken(address address_) external onlyOwner
    {
        token = IToken(address_);
    }

    /**
     * @dev Set downline NFT.
     */
    function setDownlineNft(address address_) external onlyOwner
    {
        downlineNft = IDownlineNFT(address_);
    }

    /**
     * @dev Add a presale wallet.
     */
    function addPresaleWallet(address address_) external onlyOwner
    {
        _presaleWallets[address_] = true;
    }

    /**
     * @dev Set max supply.
     */
    function setMaxSupply(uint256 supply_) external onlyOwner
    {
        maxSupply = supply_;
    }

    /**
     * @dev Set max per user.
     */
    function setMaxPerUser(uint256 max_) external onlyOwner
    {
        maxPerUser = max_;
    }

    /**
     * @dev Set price.
     */
    function setPrice(uint256 price_) external onlyOwner
    {
        price = price_;
    }

    /**
     * @dev Set token value.
     */
    function setTokenValue(uint256 value_) external onlyOwner
    {
        tokenValue = value_;
    }

    /**
     * @dev Set NFT value.
     */
    function setNftValue(uint256 value_) external onlyOwner
    {
        nftValue = value_;
    }

    /**
     * @dev Set base URI.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner
    {
        baseURI = baseURI_;
    }

    /**
     * @dev Mint an NFT.
     */
    function mint(address to_) external onlyOwner
    {
        _mint(to_);
    }

    /**
     * -------------------------------------------------------------------------
     * USER FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * @dev Buy an NFT.
     */
    function buy() external
    {
        require(!paused || _presaleWallets[msg.sender], "Sale is not open");
        require(address(paymentToken) != address(0), "Payment token not set");
        require(poolAddress != address(0), "Pool address not set");
        require(paymentToken.transferFrom(msg.sender, poolAddress, price), "Transfer failed");
        _mint(msg.sender);
    }

    /**
     * @dev Claim an NFT.
     */
    function claim() external
    {
        require(balanceOf[msg.sender] > 0, "No NFTs owned");
        require(address(token) != address(0), "$FUR token not set");
        require(address(downlineNft) != address(0), "NFT token not set");
        require(!token.paused(), "$FUR token is paused");
        require(!downlineNft.paused(), "$FURNFT token is paused");
        token.mint(msg.sender, tokenValue);
        downlineNft.mint(msg.sender, nftValue);
        uint256 _tokenId_ = 0;
        for(uint256 i = 1; i <= totalSupply; i++) {
            if(ownerOf[i] == msg.sender) {
                _tokenId_ = i;
                break;
            }
        }
        balanceOf[msg.sender] -= 1;
        delete _tokenApprovals[_tokenId_];
        delete ownerOf[_tokenId_];
        delete _exists[_tokenId_];
        totalSupply --;
        emit Transfer(msg.sender, address(0), _tokenId_);
        emit Claimed(_tokenId_);
    }

    /**
     * -------------------------------------------------------------------------
     * INTERNAL FUNCTIONS
     * -------------------------------------------------------------------------
     */

    function _mint(address to_) internal
    {
        require(totalCreated < maxSupply, "Out of supply");
        require(balanceOf[to_] < maxPerUser, "User has max");
        _currentTokenId ++;
        totalSupply ++;
        totalCreated ++;
        balanceOf[to_] += 1;
        ownerOf[_currentTokenId] = to_;
        _exists[_currentTokenId] = true;
        emit Transfer(address(0), to_, _currentTokenId);
        emit Minted(to_, _currentTokenId);
    }

    /**
     * -------------------------------------------------------------------------
     * MODIFIERS
     * -------------------------------------------------------------------------
     */

    /**
     * @dev Requires caller to be owner. These are methods that will be
     * called by a trusted user.
     */
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    /**
     * @dev Requires the contract to not be paused.
     */
    modifier isNotPaused()
    {
        require(!paused, "Contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IPausable.sol";

interface IDownlineNFT is IPausable, IERC721 {
    function price() external returns (uint256);
    function taxRate() external returns (uint256);
    function maxPerUser() external returns (uint256);
    function paymentToken() external returns (address);
    function setPaymentToken(address address_) external;
    function totalSupply() external returns (uint256);
    function maxSupply() external returns (uint256);
    function buy(uint256 quantity_) external;
    function mint(address to_, uint256 quantity_) external;
    function tokenOfOwnerByIndex(address owner_, uint256 index_) external returns (uint256);
    function tokenURI(uint256 tokenId_) external returns (string memory);
    function createGeneration(uint256 maxSupply_, string memory baseUri_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function contractAdmin() external returns (address);
    function paused() external returns (bool);
    function players() external returns (uint256);
    function totalSupply() external returns (uint256);
    function transactions() external returns (uint256);
    function minted() external returns (uint256);
    function burnTax() external returns (uint256);
    function liquidityTax() external returns (uint256);
    function vaultTax() external returns (uint256);
    function devTax() external returns (uint256);
    function devWallet() external returns (address);
    function downlineNFT() external returns (address);
    function pool() external returns (address);
    function presaleNFT() external returns (address);
    function vault() external returns (address);
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint8);
    function balanceOf(address account_) external returns (uint256);
    function transfer(address to_, uint256 amount_) external returns (bool);
    function transferFrom(address from_, address to_, uint256 amount_) external returns (bool);
    function approve(address spender_, uint256 amount_) external returns (bool);
    function allowance(address owner_, address spender_) external returns (uint256);
    function taxRate() external returns (uint256);
    function setContractAdmin(address address_) external;
    function pause() external;
    function unpause() external;
    function setDevWallet(address address_) external;
    function setDownlineNFT(address address_) external;
    function setPool(address address_) external;
    function setPresaleNFT(address address_) external;
    function setVault(address address_) external;
    function setBurnTax(uint256 tax_) external;
    function setLiquidityTax(uint256 tax_) external;
    function setVaultTax(uint256 tax_) external;
    function setDevTax(uint256 tax_) external;
    function protectedTransfer(address from_, address to_, uint256 amount_, uint256 taxRate_) external returns (bool);
    function mint(address to_, uint256 amount_) external;
    function burn(address from_, uint256 amount_) external;
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
pragma solidity ^0.8.0;

import "./IOwnable.sol";

interface IPausable is IOwnable {
    function paused() external returns (bool);
    function unpause() external;
    function pause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}