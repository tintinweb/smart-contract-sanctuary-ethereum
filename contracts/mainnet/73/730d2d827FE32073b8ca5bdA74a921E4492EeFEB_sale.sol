// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../sale/SaleContract.sol";

contract sale is SaleContract {
    constructor(SaleConfiguration memory config) SaleContract(config) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ISaleContract.sol";
import "../token/IToken.sol";
import "../extras/recovery/BlackHolePrevention.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct SaleConfiguration {
    uint256 projectID; 
    address token;
    address payable[] wallets;
    uint16[] shares;

    uint256 maxMintPerTransaction;      // How many tokens a transaction can mint
    uint256 maxPresale;                 // Max sold in presale across presale eth
    uint256 maxPresalePerAddress;       // Limit discounts per address
    uint256 maxSalePerAddress;

    uint256 presaleStart;
    uint256 presaleEnd;
    uint256 saleStart;
    uint256 saleEnd;

    uint256 fullPrice;
    address signer;
}

struct SaleInfo {
    SaleConfiguration config;
    uint256 _userMinted;
    uint256 _MaxUserMintable;
    bool    _presaleIsActive;
    bool    _saleIsActive;
}


contract SaleContract is ISaleContract, Ownable, BlackHolePrevention {
    using Strings  for uint256;

    uint256 immutable   public  projectID;
    IToken  immutable   public  token;

    address payable []  _wallets;
    uint16[]            _shares;
    uint256             _maxMintPerTransaction;
    uint256             _maxPresale;
    uint256             _maxMintPerAddress;
    uint256             _maxPresalePerAddress;
    uint256             _maxSalePerAddress;
    address             _projectSigner;
    uint256             _presaleStart;
    uint256             _presaleEnd;
    uint256             _saleStart;
    uint256             _saleEnd;
    uint256             _fullPrice;

    uint256 immutable   _MaxUserMintable;
    uint256             _userMinted;
    mapping(address => uint256) public _mintedByWallet;


    event PreSale(address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);
    event Sale   (address _buyer, address _receiver, uint256 _number_of_items, uint256 _amount);

    constructor(SaleConfiguration memory config) {

        require(config.projectID > 0, "Sale: Project id must be higher than 0");
        require(config.token != address(0), "Sale: Token address can not be address(0)");
 
        projectID = config.projectID;
        token = IToken(config.token);

        TokenInfoForSale memory tinfo = token.getTokenInfoForSale();
        require(config.projectID == tinfo._projectID, "Sale: Project id must match");

        // Calculate how many tokens can be minted through the sale contract by normal users
        _MaxUserMintable = tinfo._maxSupply - tinfo._reservedSupply;

        UpdateSaleConfiguration(config);

        UpdateWalletsAndShares(config.wallets, config.shares);
    }

    function UpdateSaleConfiguration(SaleConfiguration memory config) public onlyAllowed {

        // How many tokens a transaction can mint
        _maxMintPerTransaction = config.maxMintPerTransaction;

        // Number of tokens to be sold in presale 
        _maxPresale = config.maxPresale;

        // Limit presale mints per address
        _maxPresalePerAddress = config.maxPresalePerAddress;

        // Limit sale mints per address ( must include _maxPresalePerAddress value )
        _maxSalePerAddress = config.maxSalePerAddress;

        _presaleStart   = config.presaleStart;
        _presaleEnd     = config.presaleEnd;
        _saleStart      = config.saleStart;
        _saleEnd        = config.saleEnd;

        _fullPrice      = config.fullPrice;

        // Signed data signer address
        _projectSigner = config.signer;
    }

    /**
     * @dev Admin: Update wallets and shares
     */
    function UpdateWalletsAndShares(
        address payable[] memory _newWallets,
        uint16[] memory _newShares
    ) public onlyAllowed {
        require(_newWallets.length == _newShares.length && _newWallets.length > 0, "Sale: Must have at least 1 output wallet");
        uint16 totalShares = 0;
        for (uint8 j = 0; j < _newShares.length; j++) {
            totalShares+= _newShares[j];
        }
        require(totalShares == 10000, "Sale: Shares total must be 10000");
        _shares = _newShares;
        _wallets = _newWallets;
    }

    /**
     * @dev Admin mint tokens
     */
    function admin_mint(address _destination, uint8 _count) external onlyAllowed {
        _mintCards(_count, _destination);
    }
    
    /**
     * @dev Public Sale minting
     */
    function mint(uint256 _numberOfCards) external payable {
        _internalMint(_numberOfCards, msg.sender);
    }

    /**
     * @dev Public Sale cross mint
     */
    function crossmint(uint256 _numberOfCards, address _receiver) external payable {
        _internalMint(_numberOfCards, _receiver);
    }

    /**
     * @dev Public Sale minting
     */
    function _internalMint(uint256 _numberOfCards, address _receiver) internal {
        require(checkSaleIsActive(),                            "Sale: Sale is not open");
        require(_numberOfCards <= _maxMintPerTransaction,       "Sale: Over maximum number per transaction");

        uint256 number_of_items = msg.value / _fullPrice;
        require(number_of_items == _numberOfCards,              "Sale: ETH sent does not match items requested");
        require(number_of_items * _fullPrice == msg.value,      "Sale: Incorrect ETH amount sent");

        uint256 _sold = _mintedByWallet[_receiver];
        require(_sold < _maxSalePerAddress,                     "Sale: You have already minted your allowance");
        require(_sold + number_of_items <= _maxSalePerAddress,  "Sale: That would put you over your presale limit");
        _mintedByWallet[_receiver]+= number_of_items;

        _mintCards(number_of_items, _receiver);
        _split(msg.value);

        emit Sale(msg.sender, _receiver, number_of_items, msg.value);
    }


    /**
     * @dev Internal mint method
     */
    function _mintCards(uint256 numberOfCards, address recipient) internal {
        _userMinted+= numberOfCards;
        require(
            _userMinted <= _MaxUserMintable,
            "Sale: Exceeds maximum number of user mintable cards"
        );
        token.mintIncrementalCards(numberOfCards, recipient);
    }

    /**
     * @dev Mint tokens as specified in the signed payload
     */
    struct SignedPayload {
        uint256 projectID;
        uint256 chainID;  // 1 mainnet / 4 rinkeby / 11155111 sepolia / 137 polygon / 80001 mumbai
        bool free;
        uint16 max_mint;
        address receiver;
        uint256 valid_from;
        uint256 valid_to;
        uint256 eth_price;
        uint256 dust_price;
        bytes signature;
    }

    function mint_approved(SignedPayload memory _payload, uint256 _numberOfCards) external payable {

        require(_numberOfCards <= _maxMintPerTransaction, "Sale: Over maximum number per transaction");
        require(_numberOfCards + _userMinted <= _maxPresale, "Sale: Presale maximum reached");

        // Make sure it can only be called if presale is active
        require(checkPresaleIsActive(), "Sale: Presale is not active");

        // First make sure the received payload was signed by _projectSigner
        require(verify(_payload), "Sale: SignedPayload verification failed");

        // Make sure that msg.sender is actually the intended receiver
        require(_payload.receiver == msg.sender, "Sale Verify: Invalid receiver");

        // Make sure that payload.projectID matches
        require(_payload.projectID == projectID, "Sale Verify: Invalid projectID");

        // Make sure that payload.chainID matches
        require(_payload.chainID == block.chainid, "Sale Verify: Invalid chainID");

        // Make sure in date range
        require(_payload.valid_from < _payload.valid_to, "Sale: Invalid from/to range in payload");
        require(
            getBlockTimestamp() >= _payload.valid_from &&
            getBlockTimestamp() <= _payload.valid_to,
            "Sale: Contract time outside from/to range"
        );

        uint256 number_of_items = msg.value / _payload.eth_price;
        require(number_of_items == _numberOfCards, "Sale: ETH sent does not match items requested");
        require(number_of_items * _payload.eth_price == msg.value, "Sale: Incorrect ETH amount sent");

        uint256 _presold = _mintedByWallet[msg.sender];
        require(_presold < _payload.max_mint, "Sale: You have already minted your allowance");
        require(_presold + number_of_items <= _payload.max_mint, "Sale: That would put you over your presale limit");

        _mintedByWallet[msg.sender]+= number_of_items;

        // Cards will be minted into the specified receiver
        _mintCards(number_of_items, msg.sender);
        _split(msg.value);

        emit PreSale(msg.sender, msg.sender, number_of_items, msg.value);
    }

    /**
     * @dev Verify signed payload
     */
    function verify(SignedPayload memory info) public view returns (bool) {
        require(info.signature.length == 65, "Sale Verify: Invalid signature length");

        bytes memory encodedPayload = abi.encode(
            info.projectID,
            info.chainID,
            info.free,
            info.max_mint,
            info.receiver,
            info.valid_from,
            info.valid_to,
            info.eth_price,
            info.dust_price
        );

        bytes32 hash = keccak256(encodedPayload);

        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        bytes memory signature = info.signature;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address recovered = ecrecover(data, sigV, sigR, sigS);
        return recovered == _projectSigner;
    }

    /**
     * @dev Is presale active?
     */
    function checkPresaleIsActive() public view returns (bool) {
        if ( (_presaleStart <= getBlockTimestamp()) && (_presaleEnd >= getBlockTimestamp())) {
            return true;
        }
        return false;
    }

    /**
     * @dev Is sale active?
     */
    function checkSaleIsActive() public view returns (bool) {
        if ((_saleStart <= getBlockTimestamp()) && (_saleEnd >= getBlockTimestamp())) {
            return true;
        }
        return false;
    }

    /**
     * @dev Royalties splitter
     */
    receive() external payable {
        _split(msg.value);
    }

    /**
     * @dev Internal output splitter
     */
    function _split(uint256 amount) internal {
        bool sent;
        uint256 _total;

        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = (amount * _shares[j]) / 10000;
            if (j == _wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent,) = _wallets[j].call{value: _amount}("");
            require(sent, "Sale: Splitter failed to send ether");
        }
    }

    modifier onlyAllowed() {
        require(token.isAllowed(msg.sender) || msg.sender == owner(), "Sale: Unauthorised");
        _;
    }

    function tellEverything() external view returns (SaleInfo memory) {
        
        return SaleInfo(
            SaleConfiguration(
                projectID,
                address(token),
                _wallets,
                _shares,
                _maxMintPerTransaction,
                _maxPresale,
                _maxPresalePerAddress,
                _maxSalePerAddress,
                _presaleStart,
                _presaleEnd,
                _saleStart,
                _saleEnd,
                _fullPrice,
                _projectSigner
            ),
            _userMinted,
            _MaxUserMintable,
            checkPresaleIsActive(),
            checkSaleIsActive()
        );
    }

    function getBlockTimestamp() public view virtual returns(uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


interface ISaleContract {

    function getBlockTimestamp() external view returns(uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


struct revealStruct {
    bytes32 REQUEST_ID;
    uint256 RANDOM_NUM;
    uint256 SHIFT;
    uint256 RANGE_START;
    uint256 RANGE_END;
    bool processed;
}

struct TokenInfoForSale {
    uint256 _projectID;
    uint256 _maxSupply;
    uint256 _reservedSupply;
}

struct TokenInfo {
    string _name;
    string _symbol;
    uint256 _projectID;
    uint256 _maxSupply;
    uint256 _mintedSupply;
    uint256 _mintedReserve;
    uint256 _reservedSupply;
    uint256 _giveawaySupply;
    string _tokenPreRevealURI;
    string _tokenRevealURI;
    bool _transferLocked;
    bool _lastRevealRequested;
    uint256 _totalSupply;
    revealStruct[] _reveals;
}

interface IToken {

    function mintIncrementalCards(uint256, address) external;
    function mintReservedCards(uint256, address) external;
    function mintGiveawayCard(uint256, address) external;

    function setPreRevealURI(string calldata) external;
    function setRevealURI(string calldata) external;

    function revealAtCurrentSupply() external;
    function lastReveal() external;
    function process(uint256, bytes32) external;
    
    function uri(uint256) external view returns (uint256);
    function tokenURI(uint256) external view returns (string memory);

    function setTransferLock(bool) external;
    function setAllowed(address, bool) external;
    function isAllowed(address) external view returns(bool);

    function getFirstGiveawayCardId() external view returns (uint256);
    function tellEverything() external view returns (TokenInfo memory);
    function getTokenInfoForSale() external view returns (TokenInfoForSale memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackHolePrevention is Ownable {
    // blackhole prevention methods
    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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