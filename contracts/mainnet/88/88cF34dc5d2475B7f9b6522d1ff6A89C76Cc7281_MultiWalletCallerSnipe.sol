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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.17;

interface IChildStorage {
    function addChildAddress_EPEzCt7SLk (address _user, address _newChild) external;
    function child (address, uint256) external view returns (address);
    function childCount (address) external view returns (uint256);
    function controller (address) external view returns (bool);
    function delegateRegistry () external view returns (address);
    function kudasai () external view returns (address);
    function operator () external view returns (address);
    function ownedNFTId (address) external view returns (uint256);
    function owner () external view returns (address);
    function renounceOwnership () external;
    function setController (address _contract, bool _set) external;
    function setDelegateRegistry (address _contract) external;
    function setKudasai (address _contract) external;
    function setNFTId (address _user, uint256 _nftId) external;
    function setOperator (address _contract) external;
    function setSpaceId (string calldata _str) external;
    function spaceId () external view returns (bytes32);
    function transferOwnership (address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMinterChild {
    function initialize_puB (address _deployer) external;
    function run_Ozzfvp4CEc (address _callContract, bytes calldata _callData, uint256 _value) external;
    function withdrawERC1155_wcC (address _contract, uint256 _tokenId, address _to) external;
    function withdrawERC20_ATR (address _contract, address _to) external;
    function withdrawERC721_VKo (address _contract, uint256 _tokenId, address _to) external;
    function withdrawETH_RBf (address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMultiWalletCallerOperator {
    function checkHolder (address _from) external view;
    function checkId (uint256 _startId, uint256 _endId, address _from) external view;
    function createWallets (uint256 _quantity, address _from) external;
    function sendERC20 (uint256 _startId, uint256 _endId, address _token, uint256 _amount, address _from) external;
    function sendETH (uint256 _startId, uint256 _endId, address _from) external payable;
    function setNFTId (uint256 _nftId, address _from) external;
    function withdrawERC1155 (uint256 _startId, uint256 _endId, address _contract, uint256 _tokenId, address _from) external;
    function withdrawERC20 (uint256 _startId, uint256 _endId, address _contract, address _from) external;
    function withdrawERC721 (uint256 _startId, uint256 _endId, address _contract, uint256[] calldata _tokenIds, address _from) external;
    function withdrawETH (uint256 _startId, uint256 _endId, address _from) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMultiWalletCallerOperator.sol";
import "./interface/IMinterChild.sol";
import "./interface/IChildStorage.sol";

contract MultiWalletCallerSnipe is Ownable {
    IChildStorage private immutable _ChildStorage;

    constructor(address childStorage_) {
        _ChildStorage = IChildStorage(childStorage_);
    }
    receive() external payable {}

    modifier onlyHolder() {
        IMultiWalletCallerOperator(_ChildStorage.operator()).checkHolder(msg.sender);
        _;
    }

    modifier checkId(uint256 _startId, uint256 _endId) {
        IMultiWalletCallerOperator(_ChildStorage.operator()).checkId(_startId, _endId, msg.sender);
        _;
    }

    /**
     * @dev Sets the NFT ID for the caller
     * @param _nftId uint256 ID of the NFT to be set
     */
    function setNFTId(uint256 _nftId) external {
        IMultiWalletCallerOperator(_ChildStorage.operator()).setNFTId(_nftId, msg.sender);
    }

    /**
     * @dev create multiple wallets for a user
     * @param _quantity number of wallets to be created
     */
    function createWallets(uint256 _quantity) external onlyHolder {
        IMultiWalletCallerOperator(_ChildStorage.operator()).createWallets(_quantity, msg.sender);
    }

    /**
     * @dev send ETH to multiple wallets
     * @param _startId start index of wallet to send ETH to
     * @param _endId end index of wallet to send ETH to
     */
    function sendETH(uint256 _startId, uint256 _endId)
        external
        payable
        onlyHolder
        checkId(_startId, _endId)
    {
        IMultiWalletCallerOperator(_ChildStorage.operator()).sendETH{value: msg.value}(_startId, _endId, msg.sender);
    }

    function run(
        uint256 _startId,
        address _callContract,
        bytes calldata _callData,
        uint256 _value,
        address _nft,
        uint256 _id,
        uint256 _margin
    ) external onlyHolder checkId(_startId, _startId+_margin) {
        uint256 totalSupply = IERC20(_nft).totalSupply();
        _id -= 2;
        require(totalSupply < _id && totalSupply + _margin > _id, "MultiWalletCallerBaseSnipe: Id error");
        uint256 loop = _id - totalSupply;
        for (uint256 i = _startId; i <= _startId + loop; ) {
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(_callContract, _callData, _value);
            unchecked {
                i++;
            }
        }
    }

    function withdrawETH(uint256 _startId, uint256 _endId)
        external
        checkId(_startId, _endId)
    {
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawETH(_startId, _endId, msg.sender);
    }

    function withdrawERC721(
        uint256 _startId,
        uint256 _endId,
        uint256 _startNFTId,
        address _contract
    ) external checkId(_startId, _endId) {
        uint256[] memory tokenIds = new uint256[](_endId - _startId + 1);
        
        uint256 counter = 0;
        for (uint256 i = _startId; i <= _endId; ) {
            tokenIds[counter] = _startNFTId;
            unchecked {
                counter++;
                _startNFTId++;
                i++;
            }
        }
        IMultiWalletCallerOperator(_ChildStorage.operator()).withdrawERC721(_startId, _endId, _contract, tokenIds, msg.sender);
    }

    /**
     * @dev Only Owner
     * @dev Recover the Ethereum balance to the owner's wallet.
     */
    function recoverETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}