// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface IAlphaGang {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IGangToken {
    function mint(address to, uint256 amount) external;
}

contract AGStake is Ownable, ERC1155Holder {
    event Stake(address owner, uint256 tokenId, uint256 count);
    event Unstake(address owner, uint256 tokenId, uint256 count);
    event StakeAll(address owner, uint256[] tokenIds, uint256[] counts);
    event UnstakeAll(address owner, uint256[] tokenIds, uint256[] counts);

    /**
     * Event called when a stake is claimed by user
     * Args:
     * owner: address for which it was claimed
     * amount: amount of $GANG tokens claimed
     * count: count of staked(hard or soft) tokens
     * hardStake: flag indicating wheather the stake is hard or soft
     */
    event Claim(address owner, uint256 amount, uint256 count, bool hardStake);

    // references to the AG contracts
    IAlphaGang alphaGang;
    IGangToken gangToken;

    // 300 per week for hard, 75 for soft staked
    uint256 OGStakeRate = 300;
    uint256 SoftStakeRate = 75;

    // maps tokenId to stake
    mapping(uint256 => mapping(address => uint256)) private vault;
    // records block timestamp when last claim occured
    mapping(address => uint256) lastClaim;
    mapping(address => uint256) lastSoftClaim;
    // default start time for claiming rewards
    uint256 public immutable START;

    constructor(IAlphaGang _nft, IGangToken _token) {
        alphaGang = _nft;
        gangToken = _token;
        START = block.timestamp;
    }

    function stakeSingle(uint256 tokenId, uint256 tokenCount) external {
        uint256 totalStaked = vault[tokenId][msg.sender];

        alphaGang.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            tokenCount,
            ""
        );

        // if user has staked tokens, claim reward before adding to the staked tokens
        if (totalStaked > 0) {
            claimForAddress(msg.sender, true);
        }
        // claim unstaked tokens, since these are bound to change
        claimForAddress(msg.sender, false);

        emit Stake(msg.sender, tokenId, tokenCount);

        vault[tokenId][msg.sender] += tokenCount;
    }

    function unstakeSingle(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;
        // uint256 tokensOwned = nft.balanceOf(msg.sender, tokenId);
        uint256 totalStaked = vault[tokenId][_owner];

        require(
            totalStaked >= 0,
            "You do have any tokens available for unstaking"
        );
        require(
            totalStaked >= tokenCount,
            "You do not have requested token amount available for unstaking"
        );

        vault[tokenId][_owner] -= tokenCount;

        // claim rewards before unstaking
        claimForAddress(_owner, true);

        alphaGang.safeTransferFrom(
            address(this),
            _owner,
            tokenId,
            tokenCount,
            ""
        );

        emit Stake(msg.sender, tokenId, tokenCount);
    }

    function _stakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory totalAvailable = unstakedBalanceOf(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        alphaGang.safeBatchTransferFrom(
            msg.sender,
            address(this),
            tokens,
            totalAvailable,
            ""
        );

        // loop over and update the vault
        for (uint32 i; i < 3; ) {
            vault[i + 1][_owner] += totalAvailable[i];
            unchecked {
                i++;
            }
        }

        emit StakeAll(msg.sender, tokens, totalAvailable);
    }

    function _unstakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory totalStaked = stakedBalanceOf(_owner);
        vault[0][_owner] -= uint32(totalStaked[0]);
        vault[1][_owner] -= uint32(totalStaked[1]);
        vault[2][_owner] -= uint32(totalStaked[2]);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        // loop over and update the vault
        for (uint32 i; i < 3; ) {
            vault[i + 1][_owner] -= totalStaked[i];
            unchecked {
                i++;
            }
        }

        alphaGang.safeBatchTransferFrom(
            address(this),
            _owner,
            tokens,
            totalStaked,
            ""
        );

        emit UnstakeAll(_owner, tokens, totalStaked);
    }

    function _claim(address account, bool hardClaim) internal {
        uint256 _lastClaim = hardClaim
            ? lastClaim[account]
            : lastSoftClaim[account];
        uint256 stakedAt = _lastClaim >= START ? _lastClaim : START;

        uint256 tokenCount;

        // bonus of 6.25% is applied for holding all 3 assets(can only be applied once)
        uint256 triBonusCount = 0;
        // 25%, 37.5%, 43.75% | Order: 50, Mac, Riri
        uint256 bonusBase = 2500; // we round down the staking % to 2 decimals
        uint256 bonus = 10_000;

        uint256 stakeRate = hardClaim ? OGStakeRate : SoftStakeRate;

        uint256[] memory stakedCount = hardClaim
            ? stakedBalanceOf(account)
            : unstakedBalanceOf(account);
        for (uint32 i; i < 3; ) {
            if (stakedCount[i] > 0) {
                tokenCount += stakedCount[i];
                triBonusCount++;
                // calculate total bonus to be applied
                for (uint32 j = 0; j < tokenCount; ) {
                    bonus += bonusBase;
                    bonusBase /= 2;
                    unchecked {
                        i++;
                    }
                }
            }
            unchecked {
                i++;
            }
        }

        // add triBonus if user holds all 3 OGs
        if (triBonusCount == 3) {
            bonus += 625;
        }

        // TODO days but use minutes for testing
        // by default we will have 10*18 decimal points for $GANG, take away factor of 10000 we added to the bonus to get 10**14
        uint256 earned = ((stakeRate * (block.timestamp - stakedAt)) /
            7 minutes) *
            bonus *
            10**14;

        if (hardClaim) {
            lastClaim[account] = block.timestamp;
        } else {
            lastSoftClaim[account] = block.timestamp;
        }

        gangToken.mint(account, earned);

        emit Claim(account, earned, tokenCount, hardClaim);
    }

    /** Views */
    function stakedBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        uint256[] memory tokenBalance = new uint256[](3);
        for (uint32 i; i < 3; ) {
            uint256 stakedCount = vault[i + 1][account];
            if (stakedCount > 0) {
                tokenBalance[i] += stakedCount;
            }
            unchecked {
                i++;
            }
        }
        return tokenBalance;
    }

    function unstakedBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        // Change array building
        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        address[] memory addressArray = new address[](3);
        addressArray[0] = account;
        addressArray[1] = account;
        addressArray[2] = account;

        uint256[] memory totalTokenBalance = alphaGang.balanceOfBatch(
            addressArray,
            tokens
        );

        uint256[] memory unstakedTokenBalance = new uint256[](3);
        for (uint32 i; i < 3; ) {
            unstakedTokenBalance[i] =
                totalTokenBalance[i] -
                vault[i + 1][account];
            unchecked {
                i++;
            }
        }

        return unstakedTokenBalance;
    }

    /**
     * Contract addresses referencing functions in case we make a mistake in constructor setting
     */
    function setAlphaGang(address _alphaGang) external onlyOwner {
        alphaGang = IAlphaGang(_alphaGang);
    }

    function setGangToken(address _gangToken) external onlyOwner {
        gangToken = IGangToken(_gangToken);
    }

    /**
     * FE Call fns
     */
    function claim() external {
        _claim(msg.sender, true);
    }

    function claimSoft() external {
        _claim(msg.sender, false);
    }

    function claimForAddress(address account, bool hardStake) public {
        _claim(account, hardStake);
    }

    function stakeAll() external {
        _claim(msg.sender, true);
        _claim(msg.sender, false);
        _stakeAll();
    }

    function unstakeAll() external {
        _claim(msg.sender, true);
        _claim(msg.sender, false);
        _unstakeAll();
    }
}

// TODO consider:
// eg getPendingReward
// function earningInfo(uint256[] calldata tokenIds)
//     external
//     view
//     returns (uint256[2] memory info)
// {
//     uint256 tokenId;
//     uint256 totalScore = 0;
//     uint256 earned = 0;
//     Stake memory staked = vault[tokenId];
//     uint256 stakedAt = staked.timestamp;
//     earned += (100000 ether * (block.timestamp - stakedAt)) / 1 days;
//     uint256 earnRatePerSecond = (totalScore * 1 ether) / 1 days;
//     earnRatePerSecond = earnRatePerSecond / 100000;
//     // earned, earnRatePerSecond
//     return [earned, earningsInCurrentPeriod];
// }

// function _unstakeMany(address account, uint256[] calldata tokenIds)
//     internal
// {
//     uint256 tokenId;
//     totalStaked -= tokenIds.length;
//     for (uint256 i = 0; i < tokenIds.length; i++) {
//         tokenId = tokenIds[i];
//         Stake memory staked = vault[tokenId];
//         require(staked.owner == msg.sender, "not an owner");

//         delete vault[tokenId];
//         emit NFTUnstaked(account, tokenId, block.timestamp);
//         nft.transferFrom(address(this), account, tokenId);
//     }
// }

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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