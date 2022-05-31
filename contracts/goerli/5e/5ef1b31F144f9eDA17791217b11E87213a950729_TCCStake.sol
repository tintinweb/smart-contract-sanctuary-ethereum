// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface ITheChadsClub {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ITCCCoin {
    // Note for this to work you will have the same owner who minted the tokens and owns this contract
    // this can be changed to accommodate
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TCCStake is Ownable, ERC721Holder {
    event Stake(address owner, uint256 tokenId);
    event Unstake(address owner, uint256 tokenId);
    event StakeAll(address owner, uint256[] tokenIds);
    event UnstakeAll(address owner, uint256[] tokenIds);

    /**
     * Event called when a stake is claimed by user
     * Args:
     * owner: address for which it was claimed
     * amount: amount of $GANG tokens claimed
     * count: count of staked(hard or soft) tokens
     */
    event Claim(address owner, uint256 amount, uint256 count);

    // references to the TCC contracts
    ITheChadsClub TheChadsClub;
    ITCCCoin TCCCoin;

    uint256 public g1StakeRate = 13888888888888888; // rate per second for 1200 tokens per day
    uint256 public g2StakeRate = 4629629629629629; // rate per second for 400 tokens per day

    // maps _owner to array of staked [tokenIds]
    // using public since implicit get method can replace stakedTokensOf method
    mapping(address => uint256[]) public vault;
    // records block timestamp when last claim occurred
    mapping(address => uint256) public lastClaim;
    // default start time for claiming rewards
    uint256 public immutable START;

    constructor(ITheChadsClub _nft, ITCCCoin _token) {
        TheChadsClub = _nft;
        TCCCoin = _token;

        // start counting from the moment contract was minted
        START = block.timestamp;
    }

    /**
     * @dev External function to stake a single token.
     * @param tokenId Index of NFT to be staked
     */
    function stakeSingle(uint256 tokenId) external {
        address _owner = msg.sender;

        // claim unstaked tokens, since count/rate will change
        claimForAddress(_owner);

        TheChadsClub.safeTransferFrom(_owner, address(this), tokenId);

        unchecked {
            vault[_owner].push(tokenId);
        }

        emit Stake(_owner, tokenId);
    }

    /**
     * @dev External function to unstake a single token.
     * This should be used for more granular control of tokens and not for gas savings
     * @param tokenId Index of NFT to be staked
     */
    function unstakeSingle(uint256 tokenId) external {
        address _owner = msg.sender;
        uint256[] memory _ownerTokens = vault[_owner];

        // Note this can be extended to also check for approved Addresses
        require(
            TheChadsClub.ownerOf(tokenId) == _owner,
            "You don't own that token"
        );

        uint256 claimedTokenIndex = getVaultIndex(tokenId, _ownerTokens);

        // claim rewards before unstaking
        claimForAddress(_owner);

        // remove token from the vault
        unchecked {
            _ownerTokens[claimedTokenIndex] = _ownerTokens[
                _ownerTokens.length - 1
            ];
            delete vault[_owner][_ownerTokens.length - 1];
            // remove last element
            vault[_owner].pop();
        }

        TheChadsClub.safeTransferFrom(address(this), _owner, tokenId);

        emit Unstake(msg.sender, tokenId);
    }

    function _stakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory _ownerTokens = TheChadsClub.walletOfOwner(_owner);

        // loop over and update the vault
        unchecked {
            for (uint32 i = 0; i < _ownerTokens.length; ++i) {
                TheChadsClub.safeTransferFrom(
                    _owner,
                    address(this),
                    _ownerTokens[i]
                );
                vault[_owner].push(_ownerTokens[i]);
            }
        }

        emit StakeAll(msg.sender, _ownerTokens);
    }

    function _unstakeAll() internal {
        address _owner = msg.sender;
        uint256[] memory _stakedOwnerTokens = vault[_owner];

        // loop over and update the vault
        unchecked {
            for (uint256 i = _stakedOwnerTokens.length; i > 0; i--) {
                uint256 tokenId = _stakedOwnerTokens[i - 1];
                vault[_owner].pop();

                TheChadsClub.safeTransferFrom(address(this), _owner, tokenId);
            }
        }

        emit UnstakeAll(_owner, _stakedOwnerTokens);
    }

    function getVaultIndex(uint256 tokenId, uint256[] memory tokensOwned)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i = 0; i < tokensOwned.length; ++i) {
            if (tokensOwned[i] == tokenId) {
                return i;
            }
        }
    }

    /**
     * Contract addresses referencing functions in case we make a mistake in constructor settings
     */
    function setTheChadsClub(address _TheChadsClub) external onlyOwner {
        TheChadsClub = ITheChadsClub(_TheChadsClub);
    }

    function setTCCCoin(address _token) external onlyOwner {
        TCCCoin = ITCCCoin(_token);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claimForAddress(address account) public {
        _claim(account);
    }

    function stakeAll() external {
        _claim(msg.sender);
        _stakeAll();
    }

    function unstakeAll() external {
        _claim(msg.sender);
        _unstakeAll();
    }

    function _claim(address account) internal {
        uint256 stakedAt = lastClaim[account] >= START
            ? lastClaim[account]
            : START;

        uint256[] memory _stakedOwnerTokens = vault[account];

        uint256 r1staked;
        uint256 r2staked;

        unchecked {
            for (uint32 i; i < _stakedOwnerTokens.length; ++i) {
                if (_stakedOwnerTokens[i] < 778) {
                    r1staked++;
                } else {
                    r2staked++;
                }
            }
        }

        uint256 timestamp = block.timestamp;

        lastClaim[account] = timestamp;

        uint256 earned = ((timestamp - stakedAt) * g1StakeRate * r1staked) +
            ((timestamp - stakedAt) * g2StakeRate * r2staked);

        // This assumes owner has all the tokens and is approved for transfers by this contract
        TCCCoin.transferFrom(owner(), account, earned);

        emit Claim(account, earned, _stakedOwnerTokens.length);
    }

    // if needed see {_claim}
    function getPendingRewards(address account)
        external
        view
        returns (uint256 rewards)
    {
        uint256 stakedAt = lastClaim[account] >= START
            ? lastClaim[account]
            : START;

        uint256[] memory _stakedOwnerTokens = vault[account];

        uint256 r1staked;
        uint256 r2staked;

        unchecked {
            for (uint32 i; i < _stakedOwnerTokens.length; ++i) {
                if (_stakedOwnerTokens[i] < 778) {
                    r1staked++;
                } else {
                    r2staked++;
                }
            }
        }

        uint256 timestamp = block.timestamp;

        return
            ((g1StakeRate * r1staked) + (g2StakeRate * r2staked)) *
            (timestamp - stakedAt);
    }

    function setStakeRate(uint256 _newR1, uint256 _newR2) external onlyOwner {
        g1StakeRate = _newR1;
        g2StakeRate = _newR2;
    }

    function setStakeTimeForAddress(address _owner, uint256 timestamp)
        external
        onlyOwner
    {
        lastClaim[_owner] = timestamp;
    }

    // in case you need to manually send staked tokens
    function setApprovalForAll(address operator, bool approved)
        external
        onlyOwner
    {
        TheChadsClub.setApprovalForAll(operator, approved);
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