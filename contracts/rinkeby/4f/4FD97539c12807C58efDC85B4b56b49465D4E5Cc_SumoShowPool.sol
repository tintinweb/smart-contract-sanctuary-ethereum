// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISumoShow is IERC721Enumerable {
    function getNumberOfMintedSumos() external view returns (uint256 mintedBlue, uint256 mintedGold, uint256 mintedBlack);
    function tokensOfOwner(address _owner) external view returns (uint256[] memory tokens);
}

contract SumoShowPool is Ownable
{
    ISumoShow public immutable sumoShow;

    // royalties round rewards
    mapping(uint256 => mapping(uint256 => bool)) private royaltiesRewardsClaimed;
    mapping(uint256 => uint256) public royaltiesRewards;
    uint256 public nextRoyaltiesRoundId;

    // partnership rewards
    mapping(uint256 => mapping(uint256 => bool)) private partnershipRewardsClaimed;
    mapping(uint256 => uint256) public partnershipRewards;
    uint256 public nextPartnershipId;

    // debt for token id
    mapping(uint256 => uint256) public tokenDebts;

    // percentage attribution for gold rewards (black = 20%, the rest)
    uint256 public constant GOLD_REWARD_PERCENTAGE = 80;

    // number of sumos attributed to owners (non-eligible to mint rewards)
    uint256 public constant GOLD_RESERVE_NUMBER = 14;
    uint256 public constant BLACK_RESERVE_NUMBER = 5;

    uint256 public goldShare;
    uint256 public blackShare;
    uint256 public unallocatedAmount;

    // events
    event Partnership(uint256 indexed partnershipId, uint256 amount);
    event RoyaltiesRound(uint256 indexed roundId, uint256 amount);
    event ClaimPartnershipRewards(address indexed account, uint256 indexed partnershipId, uint256 amount, uint256[] tokenIds);
    event ClaimRoyaltiesRewards(address indexed account, uint256 indexed roundId, uint256 amount, uint256[] tokenIds);
    event ClaimRewards(address indexed account, uint256 amount, uint256[] tokenIds);

    modifier onlySumoShow() {
        require(msg.sender == address(sumoShow), "Not authorized");
        _;
    }

    constructor(ISumoShow _sumoShow) {
        sumoShow = _sumoShow;
    }

    // update pool shares
    function updateShares(uint256 _value) external onlySumoShow {
        (, uint256 mintedGold, uint256 mintedBlack) = sumoShow.getNumberOfMintedSumos();

        uint256 _unallocatedAmount;
        uint256 _goldShare = _value * GOLD_REWARD_PERCENTAGE / 100;
        uint256 _blackShare = _value - _goldShare;

        mintedGold -= GOLD_RESERVE_NUMBER;
        if (mintedGold == 0) {
            _unallocatedAmount += _goldShare;
        } else {
            goldShare += _goldShare / mintedGold;
        }

        mintedBlack -= BLACK_RESERVE_NUMBER;
        if (mintedBlack == 0) {
            _unallocatedAmount += _blackShare;
        } else {
            blackShare += _blackShare / mintedBlack;
        }

        if (_unallocatedAmount > 0) {
            unallocatedAmount += _unallocatedAmount;
        }
    }

    // set token debt
    function setTokenDebt(uint256 _tokenId, bool _isReserve) external onlySumoShow {
        if (_isReserve) {
            tokenDebts[_tokenId] = type(uint256).max;
        } else {
            tokenDebts[_tokenId] = _tokenId <= 100 ? blackShare : _tokenId <= 1000 ? goldShare : type(uint256).max;
        }
    }

    // calculate pending mint rewards for user
    function pendingRewards(address _user) external view returns (uint256 rewards) {
        uint256[] memory tokens = sumoShow.tokensOfOwner(_user);

        uint256 _amount;
        for (uint256 i; i < tokens.length; i++) {
            _amount += getPendingRewardsForToken(tokens[i]);
        }

        return _amount;
    }

    // withdraw pending mint rewards
    function withdrawPendingRewards() external {
        uint256[] memory tokens = sumoShow.tokensOfOwner(msg.sender);

        uint256 _amount;
        for (uint256 i; i < tokens.length;) {
            _amount += getPendingRewardsForToken(tokens[i]);
            unchecked { i++; }
        }

        if (_amount > 0) {
            uint256 balance = address(this).balance;
            if (_amount > balance) {
                _amount = balance;
            }

            // reset debt for each owned token
            for (uint256 i; i < tokens.length;) {
                if (!isReserve(tokens[i])) {
                    tokenDebts[tokens[i]] = tokens[i] <= 100 ? blackShare : tokens[i] <= 1000 ? goldShare : type(uint256).max;
                }
                unchecked { i++; }
            }

            (bool success,) = msg.sender.call{value: _amount}("");
            require(success, "Failed to send ether");

            emit ClaimRewards(msg.sender, _amount, tokens);
        }
    }

    // pending partnership rewards
    function pendingPartnershipRewards(uint256 _partnershipId, address _user) external view returns (uint256 rewards) {
        uint256[] memory tokens = sumoShow.tokensOfOwner(_user);

        uint256 eligibleTokenCount;
        for (uint256 i; i < tokens.length;) {
            if (partnershipRewardsClaimed[_partnershipId][tokens[i]] == false) {
                eligibleTokenCount++;
            }

            unchecked { i++; }
        }

        return eligibleTokenCount * partnershipRewards[_partnershipId] / sumoShow.totalSupply();
    }

    // withdraw partnership rewards
    function withdrawPartnershipRewards(uint256 _partnershipId) external {
        uint256[] memory tokens = sumoShow.tokensOfOwner(msg.sender);

        uint256 eligibleTokenCount;
        for (uint256 i; i < tokens.length;) {
            if (partnershipRewardsClaimed[_partnershipId][tokens[i]] == false) {
                eligibleTokenCount++;
                partnershipRewardsClaimed[_partnershipId][tokens[i]] = true;
            }

            unchecked { i++; }
        }

        if (eligibleTokenCount > 0) {
            uint256 _amount = eligibleTokenCount * partnershipRewards[_partnershipId] / sumoShow.totalSupply();
            uint256 balance = address(this).balance;
            if (_amount > balance) {
                _amount = balance;
            }

            (bool success,) = msg.sender.call{value: _amount}("");
            require(success, "Failed to send ether");

            emit ClaimPartnershipRewards(msg.sender, _partnershipId, _amount, tokens);
        }
    }

    // pending royalties rewards
    function pendingRoyaltiesRewards(uint256 _roundId, address _user) external view returns (uint256 rewards) {
        uint256[] memory tokens = sumoShow.tokensOfOwner(_user);

        uint256 eligibleTokenCount;
        for (uint256 i; i < tokens.length;) {
            if (royaltiesRewardsClaimed[_roundId][tokens[i]] == false) {
                eligibleTokenCount++;
            }

            unchecked { i++; }
        }

        return eligibleTokenCount * royaltiesRewards[_roundId] / sumoShow.totalSupply();
    }

    // withdraw royalties rewards
    function withdrawRoyaltiesRewards(uint256 _roundId) external {
        uint256[] memory tokens = sumoShow.tokensOfOwner(msg.sender);

        uint256 eligibleTokenCount;
        for (uint256 i; i < tokens.length;) {
            if (royaltiesRewardsClaimed[_roundId][tokens[i]] == false) {
                eligibleTokenCount++;
                royaltiesRewardsClaimed[_roundId][tokens[i]] = true;
            }

            unchecked { i++; }
        }

        if (eligibleTokenCount > 0) {
            uint256 _amount = eligibleTokenCount * royaltiesRewards[_roundId] / sumoShow.totalSupply();
            uint256 balance = address(this).balance;
            if (_amount > balance) {
                _amount = balance;
            }

            (bool success,) = msg.sender.call{value: _amount}("");
            require(success, "Failed to send ether");

            emit ClaimRoyaltiesRewards(msg.sender, _roundId, _amount, tokens);
        }
    }

    // add new royalties round
    function addNewRoyaltiesRound(uint256 _amount) external onlyOwner {
        uint256 _nextRoyaltiesRoundId = nextRoyaltiesRoundId++;
        royaltiesRewards[_nextRoyaltiesRoundId] = _amount;

        emit RoyaltiesRound(_nextRoyaltiesRoundId, _amount);
    }

    // deposit partnership rewards
    function depositPartnershipRewards() external payable onlyOwner {
        uint256 _nextPartnershipId = nextPartnershipId++;
        partnershipRewards[_nextPartnershipId] = msg.value;

        emit Partnership(_nextPartnershipId, msg.value);
    }

    // distribute unallocated mint rewards
    function distributeUnallocatedRewards() external onlyOwner {
        uint256 _unallocatedAmount = unallocatedAmount;
        require(_unallocatedAmount > 0, "No unallocated rewards");

        (, uint256 mintedGold, uint256 mintedBlack) = sumoShow.getNumberOfMintedSumos();
        uint256 _goldShare = _unallocatedAmount * GOLD_REWARD_PERCENTAGE / 100;

        // reserve sumos not included
        goldShare += _goldShare / (mintedGold - GOLD_RESERVE_NUMBER);
        blackShare += (_unallocatedAmount - _goldShare) / (mintedBlack - BLACK_RESERVE_NUMBER);

        unallocatedAmount = 0;
    }

    // returns rewards for specified token
    function getPendingRewardsForToken(uint256 _tokenId) public view returns (uint256) {
        uint256 tokenDebt = tokenDebts[_tokenId];
        if (tokenDebt == type(uint256).max) return 0;

        uint256 share = _tokenId <= 100 ? blackShare : goldShare;
        return share - tokenDebt;
    }

    function isReserve(uint256 _tokenId) internal pure returns (bool) {
        return
            (_tokenId >= 1 && _tokenId <= 5) ||
            (_tokenId >= 101 && _tokenId <= 114) ||
            (_tokenId >= 1001 && _tokenId <= 1096) ||
            _tokenId == 10001;
    }

    // receive ether
    receive() external payable {}
    fallback() external payable {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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