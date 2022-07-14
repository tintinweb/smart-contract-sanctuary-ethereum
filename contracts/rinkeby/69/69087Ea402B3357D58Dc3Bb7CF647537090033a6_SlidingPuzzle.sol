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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
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
    function isApprovedForAll(address account, address operator) external view returns (bool);

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
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRewardCard.sol";

contract SlidingPuzzle is Ownable {
    // lv 1 3x3
    // lv 2 4x4
    // lv 3 5x5
    struct Level {
        uint8 totalStage;
        uint256 point;
        uint8 tileCount;
    }

    struct User {
        uint8 level;
        uint8 stage;
        uint256 time;
    }

    event StartGame(address _user, uint8 _level, uint8 _stage);
    event Submit(address _user, uint256 _points);
    event Claim(address _user, uint256[] _tokenIds);
    event Redeem(address _user);
    event UpdateReward(address _reward);

    uint256 public constant CLAIM_POINT = 3000;

    uint256 public constant STAGE_TIME_LIMIT = uint256(3600);

    mapping(uint8 => Level) public levels;

    uint256[] public rewardCardForRedeem = [0, 1, 2, 3, 4];

    // level to stage to results
    mapping(uint8 => mapping(uint8 => uint8[])) private results;

    // storage what stage user playing
    mapping(address => User) private users;
    mapping(address => uint256) public userPoints;

    IRewardCard public reward;

    constructor(address _reward) {
        reward = IRewardCard(_reward);
        /// define level info
        levels[1] = Level(0, 300, 8);
        levels[2] = Level(0, 700, 15);
        levels[3] = Level(0, 1000, 24);
    }

    function setReward(address _reward) public onlyOwner {
        reward = IRewardCard(_reward);
        emit UpdateReward(_reward);
    }

    function addNewStage(
        uint8 _level,
        uint8 _stage,
        uint8[] calldata _results
    ) public onlyOwner {
        require(results[_level][_stage].length == 0, "stage existed");
        require(_results.length == levels[_level].tileCount, "results invalid");
        levels[_level].totalStage += 1;
        results[_level][_stage] = _results;
    }

    function editStage(
        uint8 _level,
        uint8 _stage,
        uint8[] calldata _results
    ) public onlyOwner {
        require(results[_level][_stage].length != 0, "stage invalid");
        require(_results.length == levels[_level].tileCount, "results invalid");
        results[_level][_stage] = _results;
    }

    function claimReward(uint8 _quantity) public {
        require(userPoints[msg.sender] >= CLAIM_POINT * _quantity, "points insufficient");
        for (uint8 i = 0; i < _quantity; i++) {
            uint8 tokenId = uint8(random(i, 5));
            reward.claim(msg.sender, uint256(tokenId), 1);
        }
        userPoints[msg.sender] -= CLAIM_POINT * _quantity;
    }

    function random(uint8 index, uint8 randomRange) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                        block.number +
                        index
                )
            )
        );
        /// return rd value from 1 - randomNum
        return (seed - ((seed / randomRange) * randomRange)) + 1;
    }

    function getStageResults(uint8 _level, uint8 _stage) public view onlyOwner returns (uint8[] memory) {
        return results[_level][_stage];
    }

    function redeem() public {
        bool checker = true;
        uint256[] memory amounts;
        for (uint8 i; i < rewardCardForRedeem.length; i++) {
            if (reward.balanceOf(msg.sender, rewardCardForRedeem[i]) == 0) {
                checker = false;
            }
            amounts[i] = 1;
        }
        require(checker, "Not enough reward card");
        reward.burnBatch(msg.sender, rewardCardForRedeem, amounts);
        emit Redeem(msg.sender);
    }

    function updateLevelInfo(uint8 _level, uint256 _point) public onlyOwner {
        levels[_level].point = _point;
    }

    function startGame(uint8 _level) public {
        uint8 stage = uint8(random(_level, levels[_level].totalStage));
        User storage user = users[msg.sender];
        user.level = _level;
        user.stage = stage;
        user.time = block.timestamp;
        emit StartGame(msg.sender, _level, stage);
    }

    function sendResults(uint8[] memory _results) public returns (bool) {
        User storage user = users[msg.sender];
        require(block.timestamp <= user.time + STAGE_TIME_LIMIT, "expired");
        require(_results.length == results[user.level][user.stage].length, "wrong result");
        bool checker = true;
        for (uint8 i = 0; i < results[user.level][user.stage].length; i++) {
            if (_results[i] != results[user.level][user.stage][i]) {
                checker = false;
            }
        }
        require(checker, "wrong result");
        userPoints[msg.sender] += levels[user.level].point;
        emit Submit(msg.sender, levels[user.level].point);
        // user.level = 0;
        user.stage = 0;
        user.time = 0;
        return true;
    }

    function updateRewardForReedem(uint256[] memory _rewardCards) public onlyOwner {
        rewardCardForRedeem = _rewardCards;
    }
}

// SPDX-License-Identifier: UNLINCENSE
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IRewardCard is IERC1155 {
    function claim(
        address to,
        uint256 tokenId,
        uint256 quantity
    ) external;

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}