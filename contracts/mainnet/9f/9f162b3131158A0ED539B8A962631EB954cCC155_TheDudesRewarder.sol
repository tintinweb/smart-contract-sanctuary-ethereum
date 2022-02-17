//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "./../core/CoreRewarder.sol";

contract TheDudesRewarder is CoreRewarder {
    constructor(
        address targetAddress,
        address rewardAddress,
        uint256 rewardRate,
        uint256 rewardFrequency,
        uint256 initialReward,
        uint256 boostRate
    )
        CoreRewarder(
            targetAddress,
            rewardAddress,
            rewardRate,
            rewardFrequency,
            initialReward,
            boostRate
        )
    {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./CoreStaking.sol";
import "./../../common/interfaces/ICoreRewarder.sol";
import "./../../common/interfaces/ICollection.sol";
import "./../../common/interfaces/IINT.sol";

contract CoreRewarder is CoreStaking, ICoreRewarder, Ownable, ReentrancyGuard {
    bool public isStakingEnabled;
    bool public isClaimingEnabled;
    address public immutable rewardAddress;

    uint256 public immutable rewardRate;
    uint256 public immutable rewardFrequency;
    uint256 public immutable initialReward;
    uint256 public startTime;
    uint256 public finishTime;

    mapping(uint256 => uint256) public lastClaimTimes;
    mapping(address => uint256) public pendingRewards;

    constructor(
        address _targetAddress,
        address _rewardAddress,
        uint256 _rewardRate,
        uint256 _rewardFrequency,
        uint256 _initialReward,
        uint256 _boostRate
    ) CoreStaking(_targetAddress, _boostRate) {
        rewardAddress = _rewardAddress;
        rewardRate = _rewardRate;
        rewardFrequency = _rewardFrequency;
        initialReward = _initialReward;
    }

    // OWNER CONTROLS

    function setStartTime(uint256 _startTime) public onlyOwner {
        require(startTime == 0, "Start time is already set");
        startTime = _startTime;
    }

    function start() public onlyOwner {
        require(startTime == 0, "Start time is already set");
        startTime = block.timestamp;
    }

    function setFinishTime(uint256 _finishTime) public onlyOwner {
        finishTime = _finishTime;
    }

    function finish() public onlyOwner {
        finishTime = block.timestamp;
    }

    function setIsStakingEnabled(bool _isStakingEnabled) public onlyOwner {
        isStakingEnabled = _isStakingEnabled;
    }

    function setIsClaimingEnabled(bool _isClaimingEnabled) public onlyOwner {
        isClaimingEnabled = _isClaimingEnabled;
    }

    // PUBLIC - CONTROLS

    function stake(
        address _owner,
        uint256[] calldata tokenIdsForClaim,
        uint256[] calldata tokenIds
    ) public override nonReentrant {
        require(isStakingEnabled, "Stakig is not enabled");
        _updateRewards(_owner, tokenIdsForClaim);
        _stake(tokenIds);
    }

    function withdraw(
        address _owner,
        uint256[] calldata tokenIdsForClaim,
        uint256[] calldata tokenIds
    ) public override nonReentrant {
        _updateRewards(_owner, tokenIdsForClaim);
        _withdraw(tokenIds);
    }

    function claim(address owner, uint256[] calldata tokenIds)
        public
        override
        nonReentrant
    {
        require(isClaimingEnabled, "Claiming is not enabled");
        _claim(owner, tokenIds);
    }

    function earned(address owner, uint256[] calldata tokenIds)
        public
        view
        override
        returns (uint256)
    {
        return _earnedTokenRewards(tokenIds) + pendingRewards[owner];
    }

    // PUBLIC - UTILITY

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _lastClaimTimesOfTokens = new uint256[](
            tokenIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _lastClaimTimesOfTokens[i] = lastClaimTimes[tokenIds[i]];
        }
        return _lastClaimTimesOfTokens;
    }

    function isOwner(address owner, uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        return _isOwner(owner, tokenId);
    }

    function stakedTokensOfOwner(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _stakedTokensOfOwner[owner];
    }

    function tokensOfOwner(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = ICollection(targetAddress).tokensOfOwner(
            owner
        );
        uint256[] memory stakedTokensIds = _stakedTokensOfOwner[owner];
        uint256[] memory mergedTokenIds = new uint256[](
            tokenIds.length + stakedTokensIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mergedTokenIds[i] = tokenIds[i];
        }
        for (uint256 i = 0; i < stakedTokensIds.length; i++) {
            mergedTokenIds[i + tokenIds.length] = stakedTokensIds[i];
        }
        return mergedTokenIds;
    }

    // INTERNAL

    function _updateRewards(address _owner, uint256[] memory _tokenIds)
        internal
    {
        require(
            _tokenIds.length == _allBalanceOf(_owner),
            "Invalid tokenIds for update rewards"
        );
        uint256 rewardAmount = _earnedTokenRewards(_tokenIds);
        _resetTimes(_owner, _tokenIds);
        pendingRewards[_owner] += rewardAmount;
    }

    function _claim(address _owner, uint256[] memory _tokenIds) internal {
        require(
            _tokenIds.length == _allBalanceOf(_owner),
            "Invalid tokenIds for claim"
        );
        uint256 rewardAmount = _earnedTokenRewards(_tokenIds);
        if (rewardAmount == 0) {
            return;
        }
        _resetTimes(_owner, _tokenIds);
        rewardAmount += pendingRewards[_owner];
        pendingRewards[_owner] = 0;
        emit RewardClaimed(_owner, rewardAmount);
        IINT(rewardAddress).mint(_owner, rewardAmount);
    }

    function _resetTimes(address _owner, uint256[] memory _tokenIds) internal {
        uint256 _currentTime = block.timestamp;
        if (finishTime != 0 && finishTime < _currentTime) {
            _currentTime = finishTime;
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _isOwner(_owner, _tokenIds[i]),
                "You need to own this token"
            );
            lastClaimTimes[_tokenIds[i]] = _currentTime;
        }
    }

    function _earnedTokenRewards(uint256[] memory _tokenIds)
        internal
        view
        returns (uint256)
    {
        uint256 _startTime = startTime;
        uint256 _currentTime = block.timestamp;
        uint256 _boostRate = boostRate;

        uint256 rewardAmount;
        if (finishTime != 0 && finishTime < _currentTime) {
            _currentTime = finishTime;
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            rewardAmount += _earnedFromToken(
                _tokenIds[i],
                _startTime,
                _currentTime,
                _boostRate
            );
        }
        return rewardAmount;
    }

    function _earnedFromToken(
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _currentTime,
        uint256 _boostRate
    ) internal view returns (uint256) {
        uint256 _lastClaimTimeOfToken = lastClaimTimes[_tokenId];
        uint256 lastClaimTime;

        if (_startTime > _lastClaimTimeOfToken) {
            lastClaimTime = _startTime;
        } else {
            lastClaimTime = _lastClaimTimeOfToken;
        }

        uint256 amount;

        if (_startTime != 0 && _startTime <= _currentTime) {
            uint256 multiplier = stakedTokenOwners[_tokenId] != address(0)
                ? _boostRate
                : 1;
            amount +=
                ((_currentTime - lastClaimTime) / rewardFrequency) *
                rewardRate *
                multiplier *
                1e18;
        }

        if (_lastClaimTimeOfToken == 0) {
            return amount + initialReward;
        }

        return amount;
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

    function _allBalanceOf(address _owner) internal view returns (uint256) {
        return
            ICollection(targetAddress).balanceOf(_owner) +
            _stakedTokensOfOwner[_owner].length;
    }

    // EVENTS
    event RewardClaimed(address indexed user, uint256 reward);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CoreStaking is IERC721Receiver {
    address public immutable targetAddress;
    uint256 public immutable boostRate;

    uint256 public stakedSupply;

    mapping(address => uint256[]) internal _stakedTokensOfOwner;
    mapping(uint256 => address) public stakedTokenOwners;

    constructor(address _targetAddress, uint256 _boostRate) {
        targetAddress = _targetAddress;
        boostRate = _boostRate;
    }

    // ERC721 Receiever

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // INTERNAL

    function _stake(uint256[] calldata tokenIds) internal {
        stakedSupply += tokenIds.length;
        IERC721 target = IERC721(targetAddress);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                target.ownerOf(tokenId) == msg.sender,
                "You must own the token."
            );

            stakedTokenOwners[tokenId] = msg.sender;

            _stakedTokensOfOwner[msg.sender].push(tokenId);
            target.safeTransferFrom(msg.sender, address(this), tokenId);
        }

        emit Staked(msg.sender, tokenIds.length);
    }

    function _withdraw(uint256[] calldata tokenIds) internal {
        stakedSupply -= tokenIds.length;
        IERC721 target = IERC721(targetAddress);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                stakedTokenOwners[tokenId] == msg.sender,
                "You must own the token."
            );

            stakedTokenOwners[tokenId] = address(0);

            // Remove tokenId from the user staked tokenId list
            uint256[] memory newStakedTokensOfOwner = _stakedTokensOfOwner[
                msg.sender
            ];
            for (uint256 q = 0; q < newStakedTokensOfOwner.length; q++) {
                if (newStakedTokensOfOwner[q] == tokenId) {
                    newStakedTokensOfOwner[q] = newStakedTokensOfOwner[
                        newStakedTokensOfOwner.length - 1
                    ];
                }
            }

            _stakedTokensOfOwner[msg.sender] = newStakedTokensOfOwner;
            _stakedTokensOfOwner[msg.sender].pop();

            target.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        emit Withdrawn(msg.sender, tokenIds.length);
    }

    // EVENTS

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface ICoreRewarder {
    function stake(
        address _owner,
        uint256[] calldata tokenIdsForClaim,
        uint256[] calldata tokenIds
    ) external;

    function withdraw(
        address _owner,
        uint256[] calldata tokenIdsForClaim,
        uint256[] calldata tokenIds
    ) external;

    function claim(address owner, uint256[] calldata tokenIds) external;

    function earned(address owner, uint256[] memory tokenIds)
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

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function stakedTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface ICollection {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface IINT {
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