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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IMonNFT {
    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function ownerOf(uint256 _tokenID) external view returns (address owner);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IMonNFT.sol';

// import 'hardhat/console.sol';

contract MonMarketplace is Ownable, Pausable {
    uint256 public marketplaceFee = 3 * 1000; // 3%
    address public monsterToken;
    address public feeReceiver; // fees will be transfered to this address

    mapping(uint256 => uint256) public apartmentIDs; // slotId => appartmentId
    mapping(uint256 => uint256) public prices; // slotId => price
    mapping(uint256 => address) public actualMonOwner; // slotId -> a Mon owner

    event Cancel(uint256 indexed id, address indexed user);
    event ListToken(uint256 indexed id, uint256 price, address indexed user);
    event BuyToken(
        uint256 indexed id,
        uint256 price,
        address indexed buyer,
        address indexed seller
    );

    modifier onlyMonOwner(uint256 _id) {
        _checkMonOwner(_id);
        _;
    }

    constructor(address _monsterToken, address _owner) {
        require(_monsterToken != address(0), 'The monster address can not be zero');
        require(_owner != address(0), 'The owner address can not be zero');
        monsterToken = _monsterToken;
        transferOwnership(_owner);
    }

    /**
     * @dev Get list prices for Mon token ids
     * @param _ids is a list of Mon token IDs. Max 50 Ids
     */
    function getTokenPrices(uint256[] memory _ids) public view returns (uint256[] memory) {
        require(_ids.length <= 50, 'Limit of length is 50');
        uint256[] memory _prices = new uint256[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            _prices[i] = prices[_ids[i]];
        }
        return _prices;
    }

    /**
     * @dev Cancel listed token
     * @param _id is a Mon token ID
     */
    function cancel(uint256 _id) public whenNotPaused {
        require(prices[_id] != 0, 'Token should be listed');
        require(msg.sender == actualMonOwner[_id], 'Listing can be canceled only by owner');
        _cancel(_id);

        emit Cancel(_id, msg.sender);
    }

    /**
     * @dev The function of cancel multiple listings
     * @param _tokenIDs is a list with IDs of Mon NFT token
     */
    function cancelTokens(uint256[] memory _tokenIDs) public whenNotPaused {
        require(_tokenIDs.length > 0, 'The list of IDs can not be empty');
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            cancel(_tokenIDs[i]);
        }
    }

    /**
     * @dev Pause the smart contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the smart contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates a new fee receiver address
     * @param _newReeReceiver is a new fee receiver address
     */
    function updateFeeReceiver(address _newReeReceiver) public onlyOwner {
        require(_newReeReceiver != address(0), 'The address can not be zero');
        feeReceiver = _newReeReceiver;
    }

    /**
     * @dev Updates fee amount
     * @param _newMarketplaceFee is a new fee value. Set 3570 if
     * it needs 3.57%, set 45700 if it needs 45.7%
     */
    function setMarketplaceFee(uint256 _newMarketplaceFee) public onlyOwner {
        require(_newMarketplaceFee < 100 * 1000, 'The percentage must less then 100%');
        marketplaceFee = _newMarketplaceFee;
    }

    /**
     * @dev List token to the marketplace with provided value
     * @param _id is an ID of Mon NFT token
     * @param _price is a listed price that can not be changed. Check cancel() to
     * cancel listings
     */
    function listToken(uint256 _id, uint256 _price) public onlyMonOwner(_id) whenNotPaused {
        require(_price > 0, 'The price can not be a zero value');
        require(prices[_id] == 0, 'The token was already listed');
        prices[_id] = _price;
        actualMonOwner[_id] = msg.sender;

        emit ListToken(_id, _price, msg.sender);
    }

    /**
     * The function of buying multiple tokens
     * @param _tokenIDs is a list with IDs of Mon NFT token
     */
    function listTokens(uint256[] memory _tokenIDs, uint256[] memory _prices) public whenNotPaused {
        require(_tokenIDs.length > 0, 'The list of IDs can not be empty');
        require(_prices.length > 0, 'The list of prices can not be empty');
        require(_tokenIDs.length == _prices.length, 'The length of lists should be the same');
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            listToken(_tokenIDs[i], _prices[i]);
        }
    }

    /**
     * @dev Buy listed tokens. Buyer can buy a token only if actual owner made an approve for
     * monster marketplace, otherwise it is not possible to buy a token
     * @param _id is an ID of Mon NFT token
     */
    function buyToken(uint256 _id) public payable whenNotPaused {
        require(prices[_id] > 0, 'This token was not listed');
        require(prices[_id] == msg.value, 'Sent value should be the same as price');

        _buyToken(_id);
    }

    /**
     * @dev Buy listed tokens
     * @param _id is an ID of Mon NFT token
     */
    function _buyToken(uint256 _id) internal {
        address _monsterOwner = IMonNFT(monsterToken).ownerOf(_id);
        require(msg.sender != _monsterOwner, 'You can not buy your own token');

        _transferFees(_id, prices[_id]);
        IMonNFT(monsterToken).transferFrom(actualMonOwner[_id], msg.sender, _id);
        _cancel(_id);

        emit BuyToken(_id, prices[_id], msg.sender, _monsterOwner);
    }

    /**
     * @dev The function of buying multiple tokens
     * @param _tokenIDs is a list with IDs of Mon NFT token
     */
    function buyTokens(uint256[] memory _tokenIDs) public payable whenNotPaused {
        require(_tokenIDs.length > 0, 'The list of IDs can not be empty');
        // check sum for prices and total msg.value provided by the user
        uint256 sum = 0;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(prices[_tokenIDs[i]] > 0, 'This token was not listed');
            sum += prices[_tokenIDs[i]];
        }
        require(sum == msg.value, 'Sent value should be the same as price');
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            _buyToken(_tokenIDs[i]);
        }
    }

    /**
     * @dev The function can send any lost tokens to the owner
     * @param _token lost erc20 token address
     */
    function sendLostERC20Tokens(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    /**
     * @dev The function can send any lost NFTs to the owner exept monsters
     * @param _token lost ERC721 token address
     * @param _id is an ID of lost ERC721 token
     */
    function sendLostERC721Token(address _token, uint256 _id) external onlyOwner {
        require(_token != monsterToken, 'Address is not supported');
        IERC721(_token).safeTransferFrom(address(this), msg.sender, _id);
    }

    /**
     * @dev The function returns error if the sender is not the monster owner
     * @param _id is an ID of Mon token
     */
    function _checkMonOwner(uint256 _id) internal view {
        address _monsterOwner = IMonNFT(monsterToken).ownerOf(_id);
        require(_monsterOwner == msg.sender, 'You are not the owner of the monster token');
    }

    /**
     * @dev The function calculates an amount of fee for marketplace fee (can be zero)
     * and sends to the feeReceiver address. Other amount of Mon cost is sent to seller
     * @param _id is an ID of Mon token
     * @param _amount is a current price of a Mon token
     */
    function _transferFees(uint256 _id, uint256 _amount) internal {
        // get the marketplace amount of fee
        uint256 amount = (marketplaceFee * _amount) / 100 / 1000;
        if (amount > 0) {
            require(feeReceiver != address(0), 'Fee receiver should be set');
            payable(feeReceiver).transfer(amount);
        }
        payable(actualMonOwner[_id]).transfer(_amount - amount);
    }

    /**
     * @dev The function reset price and actual monster owner for provided Mon token
     * @param _id is an ID of Mon token
     */
    function _cancel(uint256 _id) internal {
        prices[_id] = 0;
        actualMonOwner[_id] = address(0);
    }
}