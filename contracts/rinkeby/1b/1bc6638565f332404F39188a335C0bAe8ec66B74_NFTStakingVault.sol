// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interfaces/IKryptoPunks.sol";
import "./interfaces/IKryptoPunksToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStakingVault is Ownable, IERC721Receiver {
    //--------------------------------------------------------------------
    // VARIABLES

    uint256 public totalItemsStaked;
    uint256 private constant MONTH = 30 days;

    IKryptoPunks nft;
    IKryptoPunksToken token;

    struct Stake {
        address owner;
        uint256 stakedAt;
    }

    mapping(uint256 => Stake) vault;

    //--------------------------------------------------------------------
    // EVENTS

    event ItemStaked(uint256 tokenId, address owner, uint256 timestamp);
    event ItemUnstaked(uint256 tokenId, address owner, uint256 timestamp);
    event Claimed(address owner, uint256 reward);

    //--------------------------------------------------------------------
    // ERRORS

    error NFTStakingVault__ItemAlreadyStaked();
    error NFTStakingVault__NotItemOwner();

    //--------------------------------------------------------------------
    // CONSTRUCTOR

    constructor(address _nftAddress, address _tokenAddress) {
        nft = IKryptoPunks(_nftAddress);
        token = IKryptoPunksToken(_tokenAddress);
    }

    //--------------------------------------------------------------------
    // FUNCTIONS

    function stake(uint256[] calldata tokenIds) external {
        uint256 tokenId;
        uint256 stakedCount;
        
        uint256 len = tokenIds.length;
        for (uint256 i; i < len; ) {
            tokenId = tokenIds[i];
            if (vault[tokenId].owner != address(0)) {
                revert NFTStakingVault__ItemAlreadyStaked();
            }
            if (nft.ownerOf(tokenId) != msg.sender) {
                revert NFTStakingVault__NotItemOwner();
            }

            nft.safeTransferFrom(msg.sender, address(this), tokenId);

            vault[tokenId] = Stake(msg.sender, block.timestamp);

            emit ItemStaked(tokenId, msg.sender, block.timestamp);

            unchecked {
                stakedCount++;
                ++i;
            }
        }
        totalItemsStaked = totalItemsStaked + stakedCount;
    }

    function unstake(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, true);
    }

    function claim(uint256[] calldata tokenIds) external {
        _claim(msg.sender, tokenIds, false);
    }

    function _claim(
        address user,
        uint256[] calldata tokenIds,
        bool unstakeAll
    ) internal {
        uint256 tokenId;
        uint256 calculatedReward;
        uint256 rewardEarned;
        
        uint256 len = tokenIds.length;
        for (uint256 i; i < len; ) {
            tokenId = tokenIds[i];
            if (vault[tokenId].owner != user) {
                revert NFTStakingVault__NotItemOwner();
            }
            uint256 _stakedAt = vault[tokenId].stakedAt;

            uint256 stakingPeriod = block.timestamp - _stakedAt;
            uint256 _dailyReward = _calculateReward(stakingPeriod);
            calculatedReward +=
                (100 * _dailyReward * stakingPeriod * 1e18) /
                1 days;

            vault[tokenId].stakedAt = block.timestamp;

            unchecked {
                ++i;
            }
        }

        rewardEarned = calculatedReward / 100;

        emit Claimed(user, rewardEarned);

        if (rewardEarned != 0) {
            token.mint(user, rewardEarned);
        }

        if (unstakeAll) {
            _unstake(user, tokenIds);
        }
    }

    function _unstake(address user, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        uint256 unstakedCount;
        
        uint256 len = tokenIds.length;
        for (uint256 i; i < len; ) {
            tokenId = tokenIds[i];
            require(vault[tokenId].owner == user, "Not Owner");

            nft.safeTransferFrom(address(this), user, tokenId);

            delete vault[tokenId];

            emit ItemUnstaked(tokenId, user, block.timestamp);

            unchecked {
                unstakedCount++;
                ++i;
            }
        }
        totalItemsStaked = totalItemsStaked - unstakedCount;
    }

    // calculate the daily staking reward based on the NFT staking period
    function _calculateReward(uint256 stakingPeriod)
        internal
        pure
        returns (uint256 dailyReward)
    {
        if (stakingPeriod <= MONTH) {
            dailyReward = 1;
        } else if (stakingPeriod < 3 * MONTH) {
            dailyReward = 2;
        } else if (stakingPeriod < 6 * MONTH) {
            dailyReward = 4;
        } else if (stakingPeriod >= 6 * MONTH) {
            dailyReward = 8;
        }
    }

    //--------------------------------------------------------------------
    // VIEW FUNCTIONS

    function getDailyReward(uint256 stakingPeriod)
        external
        pure
        returns (uint256 dailyReward)
    {
        dailyReward = _calculateReward(stakingPeriod);
    }

    function getTotalRewardEarned(address user)
        external
        view
        returns (uint256 rewardEarned)
    {
        uint256 calculatedReward;
        uint256[] memory tokens = tokensOfOwner(user);
        
        uint256 len = tokens.length;
        for (uint256 i; i < len; ) {
            uint256 _stakedAt = vault[tokens[i]].stakedAt;
            uint256 stakingPeriod = block.timestamp - _stakedAt;
            uint256 _dailyReward = _calculateReward(stakingPeriod);
            calculatedReward +=
                (100 * _dailyReward * stakingPeriod * 1e18) /
                1 days;
            unchecked {
                ++i;
            }
        }
        rewardEarned = calculatedReward / 100;
        
    }

    function getRewardEarnedPerNft(uint256 _tokenId)
        external
        view
        returns (uint256 rewardEarned)
    {
        uint256 _stakedAt = vault[_tokenId].stakedAt;
        uint256 stakingPeriod = block.timestamp - _stakedAt;
        uint256 _dailyReward = _calculateReward(stakingPeriod);
        uint256 calculatedReward = (100 * _dailyReward * stakingPeriod * 1e18) /
            1 days;
        rewardEarned = calculatedReward / 100;
    }

    function balanceOf(address user)
        public
        view
        returns (uint256 nftStakedbalance)
    {
        uint256 supply = nft.totalSupply();
        unchecked {
            for (uint256 i; i <= supply; ++i) {
                if (vault[i].owner == user) {
                    nftStakedbalance += 1;
                }
            }
        }
    }

    function tokensOfOwner(address user)
        public
        view
        returns (uint256[] memory tokens)
    {
        uint256 balance = balanceOf(user);
        uint256 supply = nft.totalSupply();
        tokens = new uint256[](balance);

        uint256 counter;

        if (balance == 0) {
            return tokens;
        }

        unchecked {
            for (uint256 i; i <= supply; ++i) {
                if (vault[i].owner == user) {
                    tokens[counter] = i;
                    counter++;
                }
                if (counter == balance) {
                    return tokens;
                }
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IKryptoPunks {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function mint(uint256 _mintAmount) external;

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKryptoPunksToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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