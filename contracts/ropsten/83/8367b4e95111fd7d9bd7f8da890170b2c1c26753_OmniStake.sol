/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



// source: OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        _transferOwnership(owner_);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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


interface IERC721 {
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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract OmniStake is Ownable {
    // fired when NFT minimum stake time changes
    event MinimumStakeTimeChanged(
        address[] asset,
        uint24[] newMinimumStakeTime
    );

    // fired when NFT stake created
    event StakeCreated(address staker, address asset, uint256[] tokenIds);

    // fired when NFT stake cancelled
    event StakeWithdrawn(address staker, address asset, uint256[] tokenIds);

    // NFT minimum stake time, address(0) for default value
    mapping(address => uint24) public AssetMinimumStakeTime;

    /**
     * NFT stakes map
     * key: keccak256(abi.encodePacked(stacker,asset,tokenId))
     * value unlockTime
     */
    mapping(bytes32 => uint64) private Stake;

    constructor(address owner_) Ownable(owner_) {
        AssetMinimumStakeTime[address(0)] = 7 days; // default stake time
    }

    /**
     * @dev update the minimum stake time
     * @param newMinimumStakeTime new minimum stake time max value is 0.5 years
     *
     * Emits a {MinimumStakeTimeUpdated} event.
     */
    function setMinimumStakeTime(
        address[] calldata asset,
        uint24[] calldata newMinimumStakeTime
    ) public onlyOwner {
        require(
            asset.length > 0 && asset.length == newMinimumStakeTime.length,
            "Invalid input"
        );
        for (uint256 i = 0; i < asset.length; ) {
            address _asset = asset[i];
            uint24 _newMinimumStakeTime = newMinimumStakeTime[i];
            if (_asset == address(0)) {
                require(
                    _newMinimumStakeTime > 0,
                    "Invalid default minimum stake time"
                );
            }
            if (_newMinimumStakeTime == 0) {
                delete AssetMinimumStakeTime[_asset];
            } else {
                AssetMinimumStakeTime[_asset] = _newMinimumStakeTime;
            }
            unchecked {
                i++;
            }
        }
        emit MinimumStakeTimeChanged(asset, newMinimumStakeTime);
    }

    /**
     * @dev get stake time
     * @param asset ERC721 token address
     * @return stake time
     */
    function getMinimumStakeTime(address asset) public view returns (uint24) {
        uint24 time = AssetMinimumStakeTime[asset];
        if (time == 0) {
            return AssetMinimumStakeTime[address(0)];
        }
        return time;
    }

    /**
     * @dev calculate stakeMap key

     */
    function getStakeKey(
        address staker,
        address asset,
        uint256 tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(staker, asset, tokenId));
    }

    /**
     * @dev create a new NFT stake
     * @param asset NFT address
     * @param tokenIds tokenIds of the NFT
     *
     * Emits a {StakeCreated} event.
     */
    function createStake(address asset, uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0, "Stake: No tokens provided");
        address sender = msg.sender;
        IERC721 ERC721 = IERC721(asset);
        require(
            ERC721.isApprovedForAll(sender, address(this)),
            "Stake: Not approved for all"
        );
        uint24 stakeTime = getMinimumStakeTime(asset);
        uint64 unlockTime;
        unchecked {
            unlockTime = uint64(block.timestamp) + stakeTime;
        }
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            ERC721.transferFrom(sender, address(this), tokenId);
            Stake[getStakeKey(sender, asset, tokenId)] = unlockTime;
            unchecked {
                i++;
            }
        }

        emit StakeCreated(sender, asset, tokenIds);
    }

    /**
     * @dev get the NFT stake info
     */
    function getUnlockTime(
        address staker,
        address asset,
        uint256 tokenId
    ) public view returns (uint64) {
        return Stake[getStakeKey(staker, asset, tokenId)];
    }

    /**
     * @dev withdraw a NFT stake
     * @param asset NFT address
     * @param tokenIds tokenIds of the NFT
     *
     * Emits a {StakeWithdrawn} event.
     */
    function withdrawStake(address asset, uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0, "Stake: No tokens provided");
        address sender = msg.sender;
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 _tokenId = tokenIds[i];
            bytes32 key = getStakeKey(sender, asset, _tokenId);
            uint64 unlockTime = Stake[key];
            require(unlockTime > 0, "Stake: Not staked");
            require(unlockTime < block.timestamp, "Stake: Not unlocked");
            delete Stake[key];
            IERC721(asset).transferFrom(address(this), sender, _tokenId);
            unchecked {
                i++;
            }
        }
        emit StakeWithdrawn(sender, asset, tokenIds);
    }
}