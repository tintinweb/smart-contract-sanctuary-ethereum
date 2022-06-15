// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NFT/ICrownNFT.sol";

contract Staking {
    uint256 public totalStaked;

    struct Package {
        uint256 apr;
        uint256 duration;
        uint8 id;
        uint256 testLockTime;
    }

    /**
     * @param owner: address of user staked
     * @param timestamp: last time check
     * @param amount: amount that user spent
     */
    struct Stake {
        uint256 stakeId;
        address owner;
        uint256 timestamp;
        uint256 amount;
        uint256 nftId;
        uint256 duration;
        uint256 apr;
        uint256 testLockTime;
    }

    event Staked(
        uint256 indexed stakeId,
        address indexed owner,
        uint256 amount,
        uint256 duration,
        uint256 apr,
        uint256 nftId
    );

    event Unstaked(
        uint256 indexed stakeId,
        address indexed owner,
        uint256 claimed
    );

    event Claimed(
        uint256 indexed stakeId,
        address indexed owner,
        uint256 indexed amount
    );

    address _WDAtokenAddress;
    address _owner;
    address _DaoTreasuryWallet;

    ICrownNFT CrownContract;

    // maps address of user to stake
    Stake[] vault;
    Package[4] packages;

    constructor(address _token) {
        _WDAtokenAddress = _token;
        _owner = msg.sender;
    }

    //** -------------- TEST ONLY --------------- */
    function setDuration(uint256 stakingId, uint256 newDurationTime) public {
        vault[stakingId].duration = newDurationTime;
    }

    function setCrownContract(address _CrownAddress) external {
        CrownContract = ICrownNFT(_CrownAddress);
    }

    function setDaoTreasuryWallet(address newAddress) external {
        _DaoTreasuryWallet = newAddress;
    }

    uint256 maxPercent = 10;

    function setMaxPercent(uint256 maxP) external {
        maxPercent = maxP;
    }

    address WinDaoAddress;

    function setWinDAOAddress(address _newDAOAddress) external {
        WinDaoAddress = _newDAOAddress;
    }

    uint256 unitToSecond = 60 * 60;

    function setToSecond(uint256 newUnit) external {
        unitToSecond = newUnit;
    }

    function decreasingTime(uint256 stakingId, uint256 decreasingAmount)
        external
    {
        vault[stakingId].timestamp -= decreasingAmount;
    }

    //** -------------- END OF TEST ONLY --------------- */

    function initialize() external {
        require(msg.sender == _owner, "Ownable: Not owner");
        packages[0].apr = 100;
        packages[0].duration = 30;
        packages[0].id = 0;
        packages[0].testLockTime = 1;
        packages[1].apr = 138;
        packages[1].duration = 90;
        packages[1].id = 1;
        packages[1].testLockTime = 2;
        packages[2].apr = 220;
        packages[2].duration = 180;
        packages[2].testLockTime = 3;
        packages[2].id = 2;
        packages[3].apr = 5;
        packages[3].duration = 0;
        packages[3].id = 3;
    }

    /**
     * @dev function for the future voting for update staking v2
     */
    function withdrawWDAToDAOTreasury() external {
        require(msg.sender == _owner);
        uint256 amount = IERC20(_WDAtokenAddress).balanceOf(address(this));
        IERC20(_WDAtokenAddress).transfer(_DaoTreasuryWallet, amount);
    }

    /**
     * @param percentChange: update percent proposal
     * @param action: 0 deceasing, 1: increasting
     */
    function setProposal(uint256 percentChange, uint8 action) external {
        require(
            msg.sender == _owner || msg.sender == WinDaoAddress,
            "Ownable: Not owner"
        );
        require(percentChange <= maxPercent, "Percentage too big");
        if (action == 0) {
            packages[0].apr -= percentChange;
            packages[1].apr -= percentChange;
            packages[2].apr = percentChange;
        } else {
            packages[0].apr += percentChange;
            packages[1].apr += percentChange;
            packages[2].apr += percentChange;
        }
    }

    /**
     * @param nftId: 0-unuse
     */

    function getListPackage(uint256 nftId)
        public
        view
        returns (Package[4] memory)
    {
        Package[4] memory finalPackage = packages;

        if (nftId != 0) {
            ICrownNFT.CrownTraits memory nftDetail = CrownContract.getTraits(
                nftId
            );
            finalPackage[0].apr += nftDetail.aprBonus;
            finalPackage[1].apr += nftDetail.aprBonus;
            finalPackage[2].apr += nftDetail.aprBonus;
        }
        return finalPackage;
    }

    function _calculateEarned(uint256 stakingId, bool isGetAll)
        internal
        view
        returns (uint256)
    {
        Stake memory ownerStaking = vault[stakingId];
        uint256 finalApr = ownerStaking.apr;
        if (ownerStaking.duration == 0) {
            uint256 stakedTimeClaim = (block.timestamp -
                ownerStaking.timestamp) / 1 days;
            uint256 earned = (ownerStaking.amount *
                finalApr *
                stakedTimeClaim) /
                100 /
                12 /
                30; // tiền lãi theo ngày * số ngày

            return isGetAll ? ownerStaking.amount + earned : earned;
        } else {
            return
                ownerStaking.amount +
                ((ownerStaking.duration * ownerStaking.amount * finalApr) /
                    100 /
                    30 /
                    12); // tiền lãi theo ngày * số ngày
        }
    }

    /**
     * @param _stakingId: 0 fixed - 30, 1 fixed - 90, 2 fixed - 180, 3: unfixed
     * @param _nftId: nft id for more % bonus nft
     * @param _amount: amount user spent
     */
    function stake(
        uint8 _stakingId,
        uint256 _nftId,
        uint256 _amount
    ) external {
        Package memory finalPackage = packages[_stakingId];
        if (_nftId != 0 && _stakingId != 3) {
            require(
                CrownContract.ownerOf(_nftId) == msg.sender,
                "Ownable: Not owner"
            );
            ICrownNFT.CrownTraits memory nftDetail = CrownContract.getTraits(
                _nftId
            );
            require(nftDetail.staked == false, "Crown staked");
            finalPackage.apr += nftDetail.aprBonus;
        }

        uint256 allowance = IERC20(_WDAtokenAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= _amount, "Over allowance WDA");
        IERC20(_WDAtokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (_nftId != 0 && _stakingId != 3) {
            CrownContract.stakeOrUnstake(_nftId, true);
        }

        totalStaked += _amount;
        uint256 newStakeId = vault.length;
        vault.push(
            Stake(
                newStakeId,
                msg.sender,
                block.timestamp,
                _amount,
                _stakingId != 3 ? _nftId : 0,
                finalPackage.duration,
                finalPackage.apr,
                finalPackage.testLockTime
            )
        );
        emit Staked(
            newStakeId,
            msg.sender,
            _amount,
            finalPackage.duration,
            finalPackage.apr,
            _nftId
        );
    }

    function claim(uint256 _stakingId) external {
        Stake memory staked = vault[_stakingId];
        require(msg.sender == staked.owner, "Ownable: Not owner");
        uint256 lastTimeCheck = staked.timestamp;
        uint256 stakeDuration = staked.duration;
        if (stakeDuration != 0) {
            require(
                block.timestamp >=
                    (lastTimeCheck + (staked.testLockTime * unitToSecond)),
                "Staking locked"
            );
        }
        uint256 earned = _calculateEarned(_stakingId, false);
        if (stakeDuration != 0) {
            totalStaked -= staked.amount;
            _deleteStakingPackage(_stakingId); // gói cố định rút xong thì unstake luôn
        } else {
            vault[_stakingId].timestamp = uint32(block.timestamp);
        }
        if (earned > 0) {
            IERC20(_WDAtokenAddress).transfer(msg.sender, earned);
            emit Claimed(_stakingId, msg.sender, earned);
        }
    }

    function unstake(uint256 _stakingId) external {
        Stake memory staked = vault[_stakingId];
        require(staked.duration == 0, "Cannot unstake fixed staking package");
        require(msg.sender == staked.owner, "Ownable: Not owner");
        // xoá staking
        uint256 earned = _calculateEarned(_stakingId, true);
        totalStaked -= staked.amount;
        _deleteStakingPackage(_stakingId);
        emit Unstaked(_stakingId, msg.sender, earned);
        if (earned > 0) {
            IERC20(_WDAtokenAddress).transfer(msg.sender, earned);
            emit Claimed(_stakingId, msg.sender, earned);
        }
    }

    function getEarned(uint256 stakingId) external view returns (uint256) {
        return _calculateEarned(stakingId, true);
    }

    function _deleteStakingPackage(uint256 stakingId) internal {
        if (vault[stakingId].nftId != 0) {
            CrownContract.stakeOrUnstake(vault[stakingId].nftId, false);
        }
        delete vault[stakingId];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        require(msg.sender == _owner, "Ownable: Not owner");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICrownNFT is IERC721, IERC721Enumerable {
    struct CrownTraits {
        uint256 reduce;
        uint256 aprBonus;
        uint256 lockDeadline;
        bool staked;
    }

    function getTraits(uint256) external view returns (CrownTraits memory);

    function mintValidTarget(uint256 number) external returns(uint256);

    function burn(uint256 tokenId) external;

    function stakeOrUnstake(uint256, bool) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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