// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../interface/ICryprosaurus.sol";
import "../dependencies/contracts/access/Ownable.sol";
import "../dependencies/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract CryptosaurusSale is Ownable {

    address public _treasury;

    ICryprosaurus private immutable _NFT;
    IERC20Metadata private immutable _ERC20;
    address public _recipient;             // who will receive payment

    uint public _bodySkinScope;            // initialization value: 3
    uint public _eyeSkinScope;             // initialization value: 16
    uint public _scaleScope;               // initialization value: 100
    uint public _blindPrice;               // initialization value: 0

    struct initInput{
        uint kind;
        uint salePrice;
        uint numberLimit;
    }

    struct saurusContext{
        uint kind;
        uint salePrice;
        uint numberLimit;
        uint number;
    }

    saurusContext[] public _saurus;

    event SaurusUpdate(initInput input, uint updateMethod);
    event UpdatePrice(uint indexed kind, uint price);
    event UpdateNumberLimit(uint indexed kind, uint numberLimit);
    event Purchase(address indexed to, uint price, uint kind);
    event UpdateBlindPrice(uint price);

    constructor(address nft, address erc20, address recipient) {
        _NFT = ICryprosaurus(nft);
        _ERC20 = IERC20Metadata(erc20);
        _recipient = recipient;

        _bodySkinScope = 3;
        _eyeSkinScope = 16;
        _scaleScope = 100;
        _blindPrice = 0;
    }

    function saurusKindAmount() external view returns(uint256){
        return _saurus.length;
    }

    function setRecipient(address recipient) external onlyOwner {
        _recipient = recipient;
    }

    function setBodySkinScope(uint value) external onlyOwner {
        _bodySkinScope = value;
    }

    function setEyeSkinScope(uint value) external onlyOwner {
        _eyeSkinScope = value;
    }

    function setScaleScope(uint value) external onlyOwner {
        _scaleScope = value;
    }

    function batchInitialization(initInput[] calldata input) external onlyOwner {
        require(_saurus.length == 0, "batchInit fail for _saurus no empty");
        require(input.length > 0, "batchInit fail for input is empty");

        for (uint i = 0; i < input.length; i++) {
            _updateSaurus(input[i], 0, 0);
        }

        _updateBlindPrice();
    }

    function addSaurus(initInput calldata input) external onlyOwner {
        require(_saurus.length > 0, "addSaurus fail for _saurus is empty");

        for (uint i = 0; i < _saurus.length; i++) {
            if ( _saurus[i].kind == input.kind ) {
                require(false, "addSaurus fail for kind has existed");
            }
        }

        _updateSaurus(input, 0, 1);
        _updateBlindPrice();
    }

    function updatePrice(uint kind, uint price) external onlyOwner {
        require(price > 0, "revisePrice fail for price zero");

        uint pos = _findSaurus(kind);
        require(pos < _saurus.length, "revisePrice fail for not find kind");
        _saurus[pos].salePrice = price;

        _updateBlindPrice();
        emit UpdatePrice(kind, price);
    }

    function updateNumber(uint kind, uint numberLimit) external onlyOwner {
        uint pos = _findSaurus(kind);

        require( numberLimit > _saurus[pos].number ,"numberLimit fail for Limit less than current number");

        require(pos < _saurus.length, "revisePrice fail for not find kind");
        _saurus[pos].numberLimit = numberLimit;
        emit UpdateNumberLimit(kind, numberLimit);
    }

    function blindBox(uint price, address to) external {
        require(_saurus.length > 0, "blindBox fail for _saurus is empty");
        require(_blindPrice > 0, "blindBox fail for _blindPrice is zero");
        require(price >= _blindPrice, "blindBox fail for price < _blindPrice");
        uint pos = 0;
        uint selects = 0;

        while ( selects < 3 ) {
            pos = _rand(to)%_saurus.length;
            if ( _saurus[pos].number < _saurus[pos].numberLimit ) {
                break;
            }
            selects++;
        }
        require(selects < 3, "blindBox fail for select overtime");
        _purchase(_saurus[pos], msg.sender, price, to);
    }

    function purchase(uint kind, uint price, address to) external {
        uint pos = _findSaurus(kind);
        require(pos < _saurus.length, "purchase fail for not find kind");
        require(_saurus[pos].number < _saurus[pos].numberLimit, "purchase fail for number over");
        _purchase(_saurus[pos], msg.sender, price, to);
    }

    function _updateBlindPrice() internal {
        uint totalPrice = 0;
        uint tmp = 0;
        require(_saurus.length > 0, "_updateBlindPrice fail for _saurus empty");
        for (uint i = 0; i < _saurus.length; i++) {
            tmp = totalPrice;
            totalPrice = tmp + _saurus[i].salePrice;
            require(totalPrice > tmp, "_updateBlindPrice fail for price overflow");
        }
        _blindPrice = totalPrice / _saurus.length;
        emit UpdateBlindPrice(_blindPrice);
    }

    function _purchase(
        saurusContext storage context,
        address user,
        uint price,
        address to
    )
        internal
    {
        ICryprosaurus.mintInput memory input;
        input.context.kind = context.kind;
        input.context.bodySkin = _rand(user)%_bodySkinScope;
        input.context.eyeSkin = _rand(user)%_eyeSkinScope;
        input.context.scale = _rand(user)%_scaleScope + 1;
        input.to = to;
        _NFT.mint(input);
        context.number = context.number + 1;
        _ERC20.transferFrom(user, _recipient, price);
        emit Purchase(to, price, context.kind);
    }

    function _updateSaurus(initInput calldata input, uint number, uint method) internal {
        saurusContext memory context;

        require(input.salePrice > 0, "Set sale price is zero");

        context.kind = input.kind;
        context.salePrice = input.salePrice;
        context.numberLimit = input.numberLimit;
        context.number = number;
        _saurus.push(context);

        emit SaurusUpdate(input, method);
    }

    function _findSaurus(uint kind) internal view returns (uint) {
        uint i = 0;
        while ( i < _saurus.length ) {
            if ( _saurus[i].kind == kind ) {
                break;
            }
            i++;
        }

        return i;
    }

    function _rand(address user) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tx.gasprice,user)));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "../dependencies/contracts/token/ERC721/IERC721.sol";

interface ICryprosaurus is IERC721 {

    /**** the key parameter for Cryprosaurus ****/
    /*
    * the context of Cryprosaurus
    *   the kind of dinosaur:    0~50;
    *   the skin of body:        0~3;
    *   the skin of eye:         0~15;
    *   the scale of dinosaur:   1~100
    */
    struct dinosaurContext {
        uint kind;
        uint bodySkin;
        uint eyeSkin;
        uint scale;
    }

    struct mintInput {
        dinosaurContext context;
        address to;
    }

    event Mint(address to, uint tokenId, dinosaurContext context);

    function mint(mintInput calldata input) external;
    function getProperty(address user) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}