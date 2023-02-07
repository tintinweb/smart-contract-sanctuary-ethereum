// @author: @gizmolab_
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DoriStaking is Ownable {
    bool public stakingEnabled = false;
    bool public burnEnabled = false;
    uint256 public totalStaked;
    uint256 public baseReward = 5;
    address public doriGenesisContract;
    address public dori1776Contract;
    address public sweeperClubContract;

    struct Stake {
        address owner; // 32bits
        uint128 timestamp; // 32bits
    }

    struct Burn {
        address owner; // 32bits
        uint128 timestamp; // 32bits
    }

    mapping(address => mapping(uint256 => Stake)) public vault;
    mapping(address => mapping(address => uint256[])) public userStakeTokens;
    mapping(address => mapping(address => uint256[])) public userBurnTokens;
    mapping(address => bool) public isVaultContract;
    mapping(address => uint256) public vaultMultiplier;
    mapping(address => uint256) public burnClaimed;

    event NFTStaked(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    );
    event NFTUnstaked(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    );
    event NFTBurned(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    );

    /*==============================================================
    ==                    User Staking Functions                  ==
    ==============================================================*/

    function stakeNfts(address _contract, uint256[] calldata tokenIds)
        external
    {
        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(isVaultContract[_contract] == true, "Contract not allowed");

        IERC721 nftContract = IERC721(_contract);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                nftContract.ownerOf(tokenIds[i]) == msg.sender,
                "You do not own this token"
            );
            nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
            vault[_contract][tokenIds[i]] = Stake(
                msg.sender,
                uint128(block.timestamp)
            );
            userStakeTokens[msg.sender][_contract].push(tokenIds[i]);
            emit NFTStaked(msg.sender, _contract, tokenIds[i], block.timestamp);
            totalStaked++;
        }
    }

    function unstakeNfts(address _contract, uint256[] calldata tokenIds)
        external
    {
        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(isVaultContract[_contract] == true, "Contract not allowed");
        IERC721 nftContract = IERC721(_contract);

        for (uint256 i; i < tokenIds.length; i++) {
            bool isTokenOwner = false;
            uint256 tokenIndex = 0;

            for (
                uint256 j;
                j < userStakeTokens[msg.sender][_contract].length;
                j++
            ) {
                if (userStakeTokens[msg.sender][_contract][j] == tokenIds[i]) {
                    isTokenOwner = true;
                    tokenIndex = j;
                }
            }

            require(isTokenOwner == true, "You do not own this Token");

            nftContract.transferFrom(address(this), msg.sender, tokenIds[i]);

            delete vault[_contract][tokenIds[i]];
            totalStaked--;

            userStakeTokens[msg.sender][_contract][
                tokenIndex
            ] = userStakeTokens[msg.sender][_contract][
                userStakeTokens[msg.sender][_contract].length - 1
            ];
            userStakeTokens[msg.sender][_contract].pop();

            emit NFTUnstaked(
                msg.sender,
                _contract,
                tokenIds[i],
                block.timestamp
            );
        }
    }

    /*==============================================================
    ==                    Burn Function                           ==
    ==============================================================*/

    function burnNfts(uint256[] calldata tokenIds) external {
        require(burnEnabled, "Burn is not yet Live");
        require(dori1776Contract != address(0), "DoriGen2 Contract not set");
        IERC721 nftContract = IERC721(dori1776Contract);

        for (uint256 i; i < tokenIds.length; i++) {
            bool isTokenOwner = false;
            uint256 tokenIndex = 0;

            for (
                uint256 j;
                j < userStakeTokens[msg.sender][dori1776Contract].length;
                j++
            ) {
                if (
                    userStakeTokens[msg.sender][dori1776Contract][j] ==
                    tokenIds[i]
                ) {
                    isTokenOwner = true;
                    tokenIndex = j;
                }
            }

            require(isTokenOwner == true, "You do not own this Token");

            nftContract.transferFrom(address(this), address(0), tokenIds[i]);
            emit NFTBurned(
                msg.sender,
                dori1776Contract,
                tokenIds[i],
                block.timestamp
            );
            uint256 reward = _calculateReward(msg.sender, dori1776Contract);
            burnClaimed[msg.sender] += reward;

            delete vault[dori1776Contract][tokenIds[i]];
            totalStaked--;

            userBurnTokens[msg.sender][dori1776Contract].push(tokenIds[i]);
            userStakeTokens[msg.sender][dori1776Contract][
                tokenIndex
            ] = userStakeTokens[msg.sender][dori1776Contract][
                userStakeTokens[msg.sender][dori1776Contract].length - 1
            ];
            userStakeTokens[msg.sender][dori1776Contract].pop();
        }
    }

    /*==============================================================
    ==                    Public Get Functions                    ==
    ==============================================================*/

    function getStakedTokens(address _user, address _contract)
        external
        view
        returns (uint256[] memory)
    {
        return userStakeTokens[_user][_contract];
    }

    function getBurnedTokens(address _user, address _contract)
        external
        view
        returns (uint256[] memory)
    {
        return userBurnTokens[_user][_contract];
    }

    function getRewards(address _user, address[] calldata vaultContracts)
        external
        view
        returns (uint256)
    {
        uint256 reward = 0;
        uint256 i;
        for (i = 0; i < vaultContracts.length; i++) {
            reward += _calculateReward(_user, vaultContracts[i]);
        }
        if (burnClaimed[_user] > 0) {
            reward += burnClaimed[_user] * 1e18;
        }
        return reward;
    }

    function getBurnedRewards(address _user) external view returns (uint256) {
        return burnClaimed[_user];
    }

    /*==============================================================
    ==                    Owner Functions                         ==
    ==============================================================*/

    function addVault(address _contract, uint256 _multiplier) public onlyOwner {
        require(isVaultContract[_contract] == false, "Contract already added");
        isVaultContract[_contract] = true;
        vaultMultiplier[_contract] = _multiplier;
    }

    function setStakingEnabled(bool _enabled) external onlyOwner {
        stakingEnabled = _enabled;
    }

    function setBaseReward(uint256 _reward) external onlyOwner {
        baseReward = _reward;
    }

    function setMultiplier(address _contract, uint256 _multiplier)
        external
        onlyOwner
    {
        require(isVaultContract[_contract] == true, "Contract not added");
        vaultMultiplier[_contract] = _multiplier;
    }

    function setBurnEnabled(bool _enabled) external onlyOwner {
        burnEnabled = _enabled;
    }

    function setDori1776Contract(address _contract) external onlyOwner {
        dori1776Contract = _contract;
    }

    function setSweeperClubContract(address _contract) external onlyOwner {
        sweeperClubContract = _contract;
    }

    /*==============================================================
    ==                     Reward Calculate Functions             ==
    ==============================================================*/

    function _calculateReward(address _user, address _contract)
        internal
        view
        returns (uint256)
    {
        uint256 reward = 0;
        for (uint256 i; i < userStakeTokens[_user][_contract].length; i++) {
            uint256 token = userStakeTokens[_user][_contract][i];
            uint256 timeSinceStake = block.timestamp -
                vault[_contract][token].timestamp;
            uint256 rewardPerToken = baseReward * vaultMultiplier[_contract];
            reward += timeSinceStake * rewardPerToken * 1e18;
        }
        return reward / 86400;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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