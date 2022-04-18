//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ╔═╗─╔╦═══╦════╗╔════╦═══╦═╗╔═╗╔═══╦═══╦═══╦══╦═══╦═══╗
// ║║╚╗║║╔══╣╔╗╔╗║║╔╗╔╗║╔═╗╠╗╚╝╔╝║╔═╗║╔══╣╔══╩╣╠╣╔═╗║╔══╝
// ║╔╗╚╝║╚══╬╝║║╚╝╚╝║║╚╣║─║║╚╗╔╝─║║─║║╚══╣╚══╗║║║║─╚╣╚══╗
// ║║╚╗║║╔══╝─║║────║║─║╚═╝║╔╝╚╗─║║─║║╔══╣╔══╝║║║║─╔╣╔══╝
// ║║─║║║║────║║────║║─║╔═╗╠╝╔╗╚╗║╚═╝║║──║║──╔╣╠╣╚═╝║╚══╗
// ╚╝─╚═╩╝────╚╝────╚╝─╚╝─╚╩═╝╚═╝╚═══╩╝──╚╝──╚══╩═══╩═══╝
// Not Financial Advice: The avoidance of taxes is the only intellectual pursuit that still carries any reward. - John Maynard Keynes
// NFT Tax Office is not a real tax office.

import "./core/Yield.sol";

contract NFTTaxReturns is Yield {
    constructor(
        address targetAddress,
        address rewardAddress,
        uint256 baseRate,
        uint256 rewardFrequency,
        uint256 initialReward,
        uint256 stakeMultiplier
    )
        Yield(
            targetAddress,
            rewardAddress,
            baseRate,
            rewardFrequency,
            initialReward,
            stakeMultiplier
        )
    {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ╔═╗─╔╦═══╦════╗╔════╦═══╦═╗╔═╗╔═══╦═══╦═══╦══╦═══╦═══╗
// ║║╚╗║║╔══╣╔╗╔╗║║╔╗╔╗║╔═╗╠╗╚╝╔╝║╔═╗║╔══╣╔══╩╣╠╣╔═╗║╔══╝
// ║╔╗╚╝║╚══╬╝║║╚╝╚╝║║╚╣║─║║╚╗╔╝─║║─║║╚══╣╚══╗║║║║─╚╣╚══╗
// ║║╚╗║║╔══╝─║║────║║─║╚═╝║╔╝╚╗─║║─║║╔══╣╔══╝║║║║─╔╣╔══╝
// ║║─║║║║────║║────║║─║╔═╗╠╝╔╗╚╗║╚═╝║║──║║──╔╣╠╣╚═╝║╚══╗
// ╚╝─╚═╩╝────╚╝────╚╝─╚╝─╚╩═╝╚═╝╚═══╩╝──╚╝──╚══╩═══╩═══╝

import "../access/Ownable.sol";
import "../token/ERC721/IERC721.sol";

import "./Stake.sol";
import "../common/interfaces/Iyield.sol";
import "../common/interfaces/Icollection.sol";
import "../common/interfaces/IIRS.sol";

contract Yield is Iyield, Stake, Ownable {
    struct TokenStatus {
        uint128 lastClaimTime;
        uint128 pendingReward;
    }

    bool public isStakingEnabled;
    bool public isClaimingEnabled;

    address public immutable rewardAddress;
    uint256 public immutable rewardRate;
    uint256 public immutable rewardFrequency;
    uint256 public immutable initialReward;

    uint256 public startTime;
    uint256 public finishTime;

    mapping(uint256 => TokenStatus) public tokenStatusses;

    constructor(
        address _targetAddress,
        address _rewardAddress,
        uint256 _rewardRate,
        uint256 _rewardFrequency,
        uint256 _initialReward,
        uint256 _stakeMultiplier
    ) Stake(_targetAddress, _stakeMultiplier) {
        rewardAddress = _rewardAddress;
        rewardRate = _rewardRate;
        rewardFrequency = _rewardFrequency;
        initialReward = _initialReward;
    }

    // OWNER CONTROLS

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(startTime == 0, "Error - Start time is already set");
        startTime = _startTime;
    }

 /*   function start() external onlyOwner {
        require(startTime == 0, "Error - Start time is already set");
        startTime = block.timestamp;
    }
*/
    function setFinishTime(uint256 _finishTime) external onlyOwner {
        finishTime = _finishTime;
    }
/*
    function finish() external onlyOwner {
        finishTime = block.timestamp;
    }
*/
    function setIsStakingEnabled(bool _isStakingEnabled) external onlyOwner {
        isStakingEnabled = _isStakingEnabled;
    }

    function setIsClaimingEnabled(bool _isClaimingEnabled) external onlyOwner {
        isClaimingEnabled = _isClaimingEnabled;
    }

    // PUBLIC - CONTROLS

    function stake(uint256[] calldata tokenIds) external override {
        require(isStakingEnabled, "Error - Staking is not enabled");
        if (_isRewardingStarted(startTime)) {
            _updatePendingRewards(msg.sender, tokenIds);
        }
        _stake(msg.sender, tokenIds);
    }

    function unstake(uint256[] calldata tokenIds) external override {
        if (_isRewardingStarted(startTime)) {
            _updatePendingRewards(msg.sender, tokenIds);
        }
        _unstake(msg.sender, tokenIds);
    }

    function claim(uint256[] calldata tokenIds) external override {
        require(isClaimingEnabled, "Error - Claiming is not enabled");
        _claim(msg.sender, tokenIds);
    }

    function earned(uint256[] calldata tokenIds)
        external
        view
        override
        returns (uint256)
    {
        if (!_isRewardingStarted(startTime)) {
            return initialReward * tokenIds.length;
        }
        return _earnedRewards(tokenIds);
    }

    // PUBLIC - UTILITY

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _lastClaimTimesOfTokens = new uint256[](
            tokenIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _lastClaimTimesOfTokens[i] = tokenStatusses[tokenIds[i]]
                .lastClaimTime;
        }
        return _lastClaimTimesOfTokens;
    }

    function isOwner(address owner, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isOwner(owner, tokenId);
    }

    function stakedTokensOfOwner(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _stakedTokensOfOwner[owner];
    }

    // INTERNAL

    function _claim(address _owner, uint256[] memory _tokenIds) internal {
        uint256 rewardAmount = _earnedRewards(_tokenIds);
        _resetPendingRewards(_owner, _tokenIds);

        require(rewardAmount != 0, "Error - No Rewards To Claim");

        emit RewardClaimed(_owner, rewardAmount);
        IIRS(rewardAddress).mint(_owner, rewardAmount);
    }

    function _updatePendingRewards(address _owner, uint256[] memory _tokenIds)
        internal
    {
        uint256 _startTime = startTime;
        uint256 _currentTime = _fixedCurrentTime();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isOwner(_owner, _tokenIds[i]),
                "Error - You Need To Own This Token"
            );

            TokenStatus memory status = tokenStatusses[_tokenIds[i]];
            status.pendingReward += uint128(
                _earnedTokenReward(_tokenIds[i], _startTime, _currentTime)
            );
            status.lastClaimTime = uint128(_currentTime);
            tokenStatusses[_tokenIds[i]] = status;
        }
    }

    function _resetPendingRewards(address _owner, uint256[] memory _tokenIds)
        internal
    {
        uint256 _currentTime = _fixedCurrentTime();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isOwner(_owner, _tokenIds[i]),
                "Error - You Do Not Own This Token"
            );

            TokenStatus memory status = tokenStatusses[_tokenIds[i]];
            status.pendingReward = 0;
            status.lastClaimTime = uint128(_currentTime);
            tokenStatusses[_tokenIds[i]] = status;
        }
    }

    function _earnedRewards(uint256[] memory _tokenIds)
        internal
        view
        returns (uint256)
    {
        uint256 _startTime = startTime;
        uint256 _currentTime = _fixedCurrentTime();
        uint256 rewardAmount;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            rewardAmount += _earnedTokenReward(
                _tokenIds[i],
                _startTime,
                _currentTime
            );
            rewardAmount += tokenStatusses[_tokenIds[i]].pendingReward;
        }
        return rewardAmount;
    }

    function _earnedTokenReward(
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _currentTime
    ) internal view returns (uint256) {
        uint256 _lastClaimTimeOfToken = tokenStatusses[_tokenId].lastClaimTime;
        uint256 fixedLastClaimTimeOfToken = _fixedLastClaimTimeOfToken(
            _startTime,
            _lastClaimTimeOfToken
        );

        uint256 multiplier = _stakingMultiplierForToken(_tokenId);
        uint256 amount = ((_currentTime - fixedLastClaimTimeOfToken) /
            rewardFrequency) *
            rewardRate *
            multiplier *
            1e18;

        if (_lastClaimTimeOfToken == 0) {
            return amount + initialReward;
        }

        return amount;
    }

    function _isRewardingStarted(uint256 _startTime)
        internal
        view
        returns (bool)
    {
        if (_startTime != 0 && _startTime < block.timestamp) {
            return true;
        }
        return false;
    }

    function _fixedLastClaimTimeOfToken(
        uint256 _startTime,
        uint256 _lastClaimTimeOfToken
    ) internal pure returns (uint256) {
        if (_startTime > _lastClaimTimeOfToken) {
            return _startTime;
        }
        return _lastClaimTimeOfToken;
    }

    function _fixedCurrentTime() internal view returns (uint256) {
        uint256 period = (block.timestamp - startTime) / rewardFrequency;
        uint256 currentTime = startTime + rewardFrequency * period;
        if (finishTime != 0 && finishTime < currentTime) {
            return finishTime;
        }
        return currentTime;
    }

    function _isOwner(address _owner, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        if (stakedTokenOwners[_tokenId] == _owner) {
            return true;
        }
        return IERC721(targetAddress).ownerOf(_tokenId) == _owner;
    }

    // EVENTS
    event RewardClaimed(address indexed user, uint256 reward);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IIRS {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Icollection {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Iyield {
     function stake(
        uint256[] calldata tokenIds
    ) external;

    function unstake(
        uint256[] calldata tokenIds
    ) external;

    function claim(uint256[] calldata tokenIds) external;

    function earned(uint256[] memory tokenIds)
        external
        view
        returns (uint256);

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);

    function isOwner(address owner, uint256 tokenId)
        external
        view
        returns (bool);

    function stakedTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ╔═╗─╔╦═══╦════╗╔════╦═══╦═╗╔═╗╔═══╦═══╦═══╦══╦═══╦═══╗
// ║║╚╗║║╔══╣╔╗╔╗║║╔╗╔╗║╔═╗╠╗╚╝╔╝║╔═╗║╔══╣╔══╩╣╠╣╔═╗║╔══╝
// ║╔╗╚╝║╚══╬╝║║╚╝╚╝║║╚╣║─║║╚╗╔╝─║║─║║╚══╣╚══╗║║║║─╚╣╚══╗
// ║║╚╗║║╔══╝─║║────║║─║╚═╝║╔╝╚╗─║║─║║╔══╣╔══╝║║║║─╔╣╔══╝
// ║║─║║║║────║║────║║─║╔═╗╠╝╔╗╚╗║╚═╝║║──║║──╔╣╠╣╚═╝║╚══╗
// ╚╝─╚═╩╝────╚╝────╚╝─╚╝─╚╩═╝╚═╝╚═══╩╝──╚╝──╚══╩═══╩═══╝
// Not Financial Advice: The avoidance of taxes is the only intellectual pursuit that still carries any reward. - John Maynard Keynes
// NFT Tax Office is not a real tax office.

import "../token/ERC721/IERC721.sol";
import "../token/ERC721/IERC721Receiver.sol";

contract Stake is IERC721Receiver {
    address public immutable targetAddress;
    uint256 public immutable stakeMultiplier;

    mapping(address => uint256[]) internal _stakedTokensOfOwner;
    mapping(uint256 => address) public stakedTokenOwners;

    constructor(address _targetAddress, uint256 _stakeMultiplier) {
        targetAddress = _targetAddress;
        stakeMultiplier = _stakeMultiplier;
    }

    // ERC721 Receiever

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // INTERNAL

    function _stake(address _owner, uint256[] calldata tokenIds) internal {
        IERC721 target = IERC721(targetAddress);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            stakedTokenOwners[tokenId] = _owner;
            _stakedTokensOfOwner[_owner].push(tokenId);
            target.safeTransferFrom(_owner, address(this), tokenId);
        }

        emit Staked(_owner, tokenIds);
    }

    function _unstake(address _owner, uint256[] calldata tokenIds) internal {
        IERC721 target = IERC721(targetAddress);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                stakedTokenOwners[tokenId] == _owner,
                "Error - You must own the token."
            );

            stakedTokenOwners[tokenId] = address(0);

            // Remove tokenId from the user staked tokenId list
            uint256[] memory newStakedTokensOfOwner = _stakedTokensOfOwner[
                _owner
            ];
            for (uint256 q = 0; q < newStakedTokensOfOwner.length; q++) {
                if (newStakedTokensOfOwner[q] == tokenId) {
                    newStakedTokensOfOwner[q] = newStakedTokensOfOwner[
                        newStakedTokensOfOwner.length - 1
                    ];
                }
            }

            _stakedTokensOfOwner[_owner] = newStakedTokensOfOwner;
            _stakedTokensOfOwner[_owner].pop();

            target.safeTransferFrom(address(this), _owner, tokenId);
        }

        emit Unstaked(_owner, tokenIds);
    }

    function _stakingMultiplierForToken(uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        return stakedTokenOwners[_tokenId] != address(0) ? stakeMultiplier : 1;
    }

    // EVENTS

    event Staked(address indexed user, uint256[] tokenIds);
    event Unstaked(address indexed user, uint256[] tokenIds);
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