// SPDX-License-Identifier: MIT
/**

 ________  ___    ___ ________  ___  ___  _______   ________  _________   
|\   __  \|\  \  /  /|\   __  \|\  \|\  \|\  ___ \ |\   ____\|\___   ___\ 
\ \  \|\  \ \  \/  / | \  \|\  \ \  \\\  \ \   __/|\ \  \___|\|___ \  \_| 
 \ \   ____\ \    / / \ \  \\\  \ \  \\\  \ \  \_|/_\ \_____  \   \ \  \  
  \ \  \___|/     \/   \ \  \\\  \ \  \\\  \ \  \_|\ \|____|\  \   \ \  \ 
   \ \__\  /  /\   \    \ \_____  \ \_______\ \_______\____\_\  \   \ \__\
    \|__| /__/ /\ __\    \|___| \__\|_______|\|_______|\_________\   \|__|
          |__|/ \|__|          \|__|                  \|_________|        
                                                                          


 * @title AdventurerStaking
 * AdventurerStaking - a contract for staking PX Quest Adventurers
 */

pragma solidity ^0.8.11;

import "./IAdventurerStaking.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAdventurer {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IChronos {
    function grantChronos(address to, uint256 amount) external;
}

contract AdventurerStaking is IAdventurerStaking, Ownable, ERC721Holder {
    IAdventurer public adventurerContract;
    IChronos public chronosContract;

    // NFT tokenId to time staked and owner's address
    mapping(uint64 => StakedToken) public stakes;

    uint64 private constant NINETY_DAYS = 7776000;
    uint64 public LOCK_IN = 0;
    bool grantChronos = true;
    uint256 public constant BASE_RATE = 5 ether;

    constructor(
        address _adventurerContract,
        address _chronosContract,
        address _ownerAddress
    ) {
        require(
            _adventurerContract != address(0),
            "nft contract cannot be 0x0"
        );
        require(
            _chronosContract != address(0),
            "chronos contract cannot be 0x0"
        );
        adventurerContract = IAdventurer(_adventurerContract);
        chronosContract = IChronos(_chronosContract);
        if (_ownerAddress != msg.sender) {
            transferOwnership(_ownerAddress);
        }
    }

    function viewStakes(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokens = new uint256[](7500);
        uint256 tookCount = 0;
        for (uint64 i = 0; i < 7500; i++) {
            if (stakes[i].user == _address) {
                _tokens[tookCount] = i;
                tookCount++;
            }
        }
        uint256[] memory trimmedResult = new uint256[](tookCount);
        for (uint256 j = 0; j < trimmedResult.length; j++) {
            trimmedResult[j] = _tokens[j];
        }
        return trimmedResult;
    }

    function stake(uint64 tokenId) public override {
        stakes[tokenId] = StakedToken(msg.sender, uint64(block.timestamp));
        emit StartStake(msg.sender, tokenId);
        adventurerContract.safeTransferFrom(
            msg.sender,
            address(this),
            uint256(tokenId)
        );
    }

    function groupStake(uint64[] memory tokenIds) external override {
        for (uint64 i = 0; i < tokenIds.length; ++i) {
            stake(tokenIds[i]);
        }
    }

    function unstake(uint64 tokenId) public override {
        require(stakes[tokenId].user != address(0), "tokenId not staked");
        require(
            stakes[tokenId].user == msg.sender,
            "sender didn't stake token"
        );
        uint64 stakeLength = uint64(block.timestamp) -
            stakes[tokenId].timeStaked;
        require(
            stakeLength > LOCK_IN, "can not remove token until lock-in period is over"
        );
        if (grantChronos) {
            uint256 calcrew = (BASE_RATE * uint256(stakeLength) * 5) /86400;
            chronosContract.grantChronos(msg.sender, calcrew);
        }
        emit Unstake(
            msg.sender,
            tokenId,
            stakeLength > NINETY_DAYS,
            stakeLength
        );
        delete stakes[tokenId];
        adventurerContract.safeTransferFrom(
            address(this),
            msg.sender,
            uint256(tokenId)
        );
    }

    function groupUnstake(uint64[] memory tokenIds) external override {
        for (uint64 i = 0; i < tokenIds.length; ++i) {
            unstake(tokenIds[i]);
        }
    }

    function setGrantChronos(bool _grant) external onlyOwner {
        grantChronos = _grant;
    }

    function setLockIn(uint64 lockin) external onlyOwner {
        LOCK_IN = lockin;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IAdventurerStaking is IERC721Receiver {
    struct StakedToken {
        address user;
        uint64 timeStaked;
    }

    /// @notice Emits when a user stakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being staked.
    /// @param tokenId the tokenId of the Adventurer NFT being staked.
    event StartStake(address indexed owner, uint64 tokenId);

    /// @notice Emits when a user unstakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being unstaked.
    /// @param tokenId the tokenId of the Adventurer NFT being unstaked.
    /// @param success whether or not the user staked the NFT for more than 90 days.
    /// @param duration the duration the NFT was staked for.
    event Unstake(
        address indexed owner,
        uint64 tokenId,
        bool success,
        uint64 duration
    );

    /// @notice Stakes a user's NFT
    /// @param tokenId the tokenId of the NFT to be staked
    function stake(uint64 tokenId) external;

    /// @notice Stakes serveral of a user's NFTs
    /// @param tokenIds the tokenId of the NFT to be staked
    function groupStake(uint64[] memory tokenIds) external;

    /// @notice Retrieves a user's NFT from the staking contract
    /// @param tokenId the tokenId of the staked NFT
    function unstake(uint64 tokenId) external;

    /// @notice Unstakes serveral of a user's NFTs
    /// @param tokenIds the tokenId of the NFT to be staked
    function groupUnstake(uint64[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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