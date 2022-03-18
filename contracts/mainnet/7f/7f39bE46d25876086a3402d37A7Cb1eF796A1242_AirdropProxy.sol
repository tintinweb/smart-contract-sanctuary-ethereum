//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IPilgrimCore.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AirdropProxy is IPilgrimCore, Ownable {

    struct _Claimable {
        address _to;
        address _nft;
        uint256 _tokenId;
        bytes32[] _params;
    }

    struct _Droppable {
        address _to;
        address _nft;
        uint256 _tokenId;
        uint256 _amount;
        bytes32[] _params;
    }

    address public pilgrimCore;
    address public pilgrimToken;
    address public pilgrimMetaNft;

    address public uniLockup;
    address public nftLockup;

    mapping(bytes32 => uint256) public claims;

    mapping(address => mapping(address => mapping(uint256 => uint128))) prelisted;

    event Claim(address indexed _to, address indexed _nft, uint256 _tokenId, bytes32[] _params);

    event Drop(address indexed _to, address indexed _nft, uint256 _tokenId, uint256 _amount, bytes32[] _params);

    event ProxyList(address indexed owner, address indexed _nft, uint256 _tokenId);

    event Prelist(address indexed owner, address indexed _nft, uint256 _tokenId, uint128 _initPrice);

    function setPilgrimAddrs(address _pilgrimCore, address _pilgrimToken, address _pilgrimMetaNft) external onlyOwner {
        pilgrimCore = _pilgrimCore;
        pilgrimToken = _pilgrimToken;
        pilgrimMetaNft = _pilgrimMetaNft;
    }

    function setLockupAddrs(address _uniLockup, address _nftLockup) external onlyOwner {
        uniLockup = _uniLockup;
        nftLockup = _nftLockup;
    }

    function _claimKey(_Claimable memory _claimable) private view returns (bytes32 _key) {
        bytes memory data = abi.encodePacked(_claimable._to, _claimable._nft, _claimable._tokenId);
        for(uint256 j = 0; j < _claimable._params.length; j++) {
            data = abi.encodePacked(data, _claimable._params[j]);
        }
        _key = keccak256(data);
    }

    function _dropKey(_Droppable calldata _droppable) private view returns (bytes32 _key) {
        bytes memory data = abi.encodePacked(_droppable._to, _droppable._nft, _droppable._tokenId);
        for(uint256 j = 0; j < _droppable._params.length; j++) {
            data = abi.encodePacked(data, _droppable._params[j]);
        }
        _key = keccak256(data);
    }

    function _claim(bytes32 _key, _Claimable memory _claimable) private {
        require(claims[_key] > 0, "No claims avaialble");
        uint256 amount = claims[_key];
        claims[_key] = 0;
        require(IERC20(pilgrimToken).transfer(_claimable._to, amount), "Can't transfer PILs");

        emit Claim(_claimable._to, _claimable._nft, _claimable._tokenId, _claimable._params);
    }

    function drop(_Droppable[] calldata droppables) external onlyOwner {
        for(uint256 i = 0; i < droppables.length; i++) {
            require(droppables[i]._amount > 0, "Can't drop zero PIL");

            bytes32 key = _dropKey(droppables[i]);
            claims[key] += droppables[i]._amount;

            emit Drop(droppables[i]._to, droppables[i]._nft, droppables[i]._tokenId, droppables[i]._amount, droppables[i]._params);
        }
    }

    function getAirdropAmount(_Claimable calldata _claimable) external view returns (uint256 _amount) {
        bytes32 key = _claimKey(_claimable);
        _amount = claims[key];
    }

    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint128 _initPrice,
        address _baseToken,
        string[] calldata _tags,
        bytes32 _descriptionHash
    ) external override {
        require(msg.sender == nftLockup || msg.sender == uniLockup, "Caller must be lockup contract");
        require(pilgrimCore != address(0), "Pilgrim address must be set");

        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        IERC721(_nftAddress).approve(pilgrimCore, _tokenId);

        address to = tx.origin;
        uint128 initPrice = prelisted[to][_nftAddress][_tokenId];
        require(initPrice > 0, "Must set listing price");

        IPilgrimCore(pilgrimCore).list(
            _nftAddress,
            _tokenId,
            initPrice,
            _baseToken,
            _tags,
            _descriptionHash
        );

        uint256 metaNftId = IPilgrimCore(pilgrimCore).getMetaNftId(_nftAddress, _tokenId);
        IERC721(pilgrimMetaNft).safeTransferFrom(address(this), msg.sender, metaNftId);

        emit ProxyList(to, _nftAddress, _tokenId);

        bytes32[] memory params;
        _Claimable memory claimable = _Claimable(to, _nftAddress, _tokenId, params);
        bytes32 key = _claimKey(claimable);
        if (claims[key] > 0) {
            _claim(key, claimable);
        }
    }

    function prelistWithInitPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint128 _initPrice
    ) external {
        prelisted[msg.sender][_nftAddress][_tokenId] = _initPrice;
        emit Prelist(msg.sender, _nftAddress, _tokenId, _initPrice);
    }

    function getMetaNftId(address _nftAddress, uint256 _tokenId) external view override returns (uint256 _metaNftId) {
        _metaNftId = IPilgrimCore(pilgrimCore).getMetaNftId(_nftAddress, _tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 amount = IERC20(pilgrimToken).balanceOf(address(this));
        IERC20(pilgrimToken).transfer(msg.sender, amount);
    }

    function onERC721Received(
    /* solhint-disable no-unused-vars */
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    /* solhint-enable no-unused-vars */
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPilgrimCore {
    function list(
        address _nftAddress,
        uint256 _tokenId,
        uint128 _initPrice,
        address _baseToken,
        string[] calldata _tags,
        bytes32 _descriptionHash
    ) external;

    function getMetaNftId(address _nftAddress, uint256 _tokenId) external view returns (uint256 _metaNftId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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