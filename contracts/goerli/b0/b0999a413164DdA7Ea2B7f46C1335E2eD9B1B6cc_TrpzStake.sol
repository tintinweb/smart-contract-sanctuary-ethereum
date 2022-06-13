//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TrpzStake is IERC721Receiver, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter public stakingId;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 lastYieldUpdate;
    uint64 public historicId;
    bool public paused;
    address public trpzToken;
    address public OGAddress = 0x22552e90D8921Eb7e74215cF85a8B1E5F4b20f66;

    struct stakedNFT {
        uint256 tokenId;
        address nftContract;
        address owner;
    }

    struct historicReward {
        uint256 timestamp;
        uint64 rewardId;
        uint64 reward;
        uint64 next;
    }

    mapping(uint256 => stakedNFT) public stakedNFTIds;
    mapping(address => historicReward) public historicRewardHead;
    mapping(uint64 => historicReward) public historicRewardToId;
    mapping(address => uint256[]) public ownerToIds;
    mapping(address => uint256) public ownerToRewards;
    mapping(address => uint256) public ownerToLastUpdate;
    mapping(address => bool) public whitelistedContracts;
    mapping(address => uint64) public dailyContractRewards;
    mapping(address => uint64) public OGBalance;

    // ========================= MODIFIERS ================= //
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor(address _trpzToken) {
        _setupRole(ADMIN_ROLE, msg.sender);
        trpzToken = _trpzToken;
    }

    //=========================== EXTERNAL FUNCTIONS =============== //
    /// @dev Approval for all need to be called followed by a zero address or false call
    /// Will need to provide address - tokenId for each array item
    /// Correct amount of each will be required to correctly match

    function batchDeposit(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenId
    ) external whenNotPaused {
        for (uint256 i; i < _contractAddress.length; i++) {
            IERC721(_contractAddress[i]).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId[i]
            );
        }
    }

    /// @dev Function update rewards for a user making them eligible every 24 hours
    function updateRewards() external whenNotPaused nonReentrant {
        require(ownerToIds[msg.sender].length != 0, "No staked NFTs");
        require(
            block.timestamp - ownerToLastUpdate[msg.sender] > 1 days,
            "No rewards to claim"
        );
        uint256 rewards;
        if (ownerToLastUpdate[msg.sender] < lastYieldUpdate) {
            rewards = _updateHistoricRewards(msg.sender);
        } else {
            rewards = _updateRewards(msg.sender);
        }
        ownerToRewards[msg.sender] += rewards;
        ownerToLastUpdate[msg.sender] =
            block.timestamp -
            (ownerToLastUpdate[msg.sender] % 1 days);
    }

    /// @dev Function to let owner withdraw their rewards
    /// If we are minting then may want to remove balance check
    function withdrawRewards() external whenNotPaused nonReentrant {
        uint256 rewards = ownerToRewards[msg.sender];
        require(rewards != 0, "No rewards to claim");
        require(
            IERC20(trpzToken).balanceOf(address(this)) >= rewards,
            "No reward funds"
        );
        ownerToRewards[msg.sender] = 0;
        bool success = IERC20(trpzToken).transfer(msg.sender, rewards);
        require(success, "Transfer did not work");
    }

    /// @dev Receiving an NFT - call approve then transfer on front-end for NFT
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) public virtual override nonReentrant whenNotPaused returns (bytes4) {
        require(whitelistedContracts[msg.sender], "Contract not whitelisted");
        if (msg.sender != OGAddress) {
            require(OGBalance[_operator] > 1, "STAKE_OG_TO_UNLOCK");
        }

        /// Updates rewards and aligns last updated timestamp
        uint256 rewards;
        if (ownerToIds[_operator].length >= 1) {
            if (ownerToLastUpdate[_operator] < lastYieldUpdate) {
                rewards = _updateHistoricRewards(_operator);
            } else {
                rewards = _updateRewards(_operator);
            }
            ownerToRewards[_operator] += rewards;
            ownerToLastUpdate[_operator] =
                block.timestamp -
                (ownerToLastUpdate[_operator] % 1 days);
        } else {
            ownerToLastUpdate[_operator] = block.timestamp;
        }

        stakingId.increment();
        uint256 nftstakingId = stakingId.current();
        stakedNFTIds[nftstakingId] = stakedNFT(_tokenId, msg.sender, _operator);
        ownerToIds[_operator].push(nftstakingId);
        if (msg.sender == OGAddress) {
            OGBalance[_operator] += 1;
        }
        return this.onERC721Received.selector;
    }

    /// @dev Withdraw an NFT
    function withdrawToken(uint256 _stakingId) external nonReentrant {
        require(stakedNFTIds[_stakingId].owner == msg.sender, "Not owner");
        require(ownerToIds[msg.sender].length >= 1, "Nothing staked");

        /// Claim rewards before withdrawal
        uint256 rewards;
        if (ownerToLastUpdate[msg.sender] < lastYieldUpdate) {
            rewards = _updateHistoricRewards(msg.sender);
        } else {
            rewards = _updateRewards(msg.sender);
        }
        if (rewards != 0) {
            ownerToRewards[msg.sender] += rewards;
            ownerToLastUpdate[msg.sender] =
                block.timestamp -
                (ownerToLastUpdate[msg.sender] % 1 days);
        }

        address nftContract;
        uint256 tokenId;
        if (ownerToIds[msg.sender].length == 1) {
            nftContract = stakedNFTIds[ownerToIds[msg.sender][0]].nftContract;
            tokenId = stakedNFTIds[ownerToIds[msg.sender][0]].tokenId;
            /// OG Decrement
            if (nftContract == OGAddress) {
                OGBalance[msg.sender] -= 1;
            }
            delete stakedNFTIds[ownerToIds[msg.sender][0]];
            ownerToIds[msg.sender].pop();
        } else {
            for (uint256 i; i < ownerToIds[msg.sender].length; i++) {
                if (
                    ownerToIds[msg.sender][i] == _stakingId &&
                    i != ownerToIds[msg.sender].length - 1
                ) {
                    nftContract = stakedNFTIds[ownerToIds[msg.sender][i]]
                        .nftContract;
                    tokenId = stakedNFTIds[ownerToIds[msg.sender][i]].tokenId;
                    ownerToIds[msg.sender][i] ==
                        ownerToIds[msg.sender][
                            ownerToIds[msg.sender].length - 1
                        ];
                    // OG Decrement
                    if (nftContract == OGAddress) {
                        OGBalance[msg.sender] -= 1;
                    }
                    delete stakedNFTIds[ownerToIds[msg.sender][i]];
                    ownerToIds[msg.sender].pop();
                    break;
                }
                if (ownerToIds[msg.sender][i] == _stakingId) {
                    nftContract = stakedNFTIds[ownerToIds[msg.sender][i]]
                        .nftContract;
                    tokenId = stakedNFTIds[ownerToIds[msg.sender][i]].tokenId;
                    // OG Decrement
                    if (nftContract == OGAddress) {
                        OGBalance[msg.sender] -= 1;
                    }
                    delete stakedNFTIds[ownerToIds[msg.sender][i]];
                    ownerToIds[msg.sender].pop();
                    break;
                }
            }
        }
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function batchWithdrawTokens() external nonReentrant {
        require(ownerToIds[msg.sender].length >= 2, "Nothing staked");

        /// Claim rewards before withdrawal
        uint256 rewards;
        if (ownerToLastUpdate[msg.sender] < lastYieldUpdate) {
            rewards = _updateHistoricRewards(msg.sender);
        } else {
            rewards = _updateRewards(msg.sender);
        }
        if (rewards != 0) {
            ownerToRewards[msg.sender] += rewards;
            ownerToLastUpdate[msg.sender] =
                block.timestamp -
                (ownerToLastUpdate[msg.sender] % 1 days);
        }

        for (uint256 i; i < ownerToIds[msg.sender].length; i++) {
            IERC721(stakedNFTIds[ownerToIds[msg.sender][i]].nftContract)
                .safeTransferFrom(
                    address(this),
                    msg.sender,
                    stakedNFTIds[ownerToIds[msg.sender][i]].tokenId
                );
            delete stakedNFTIds[ownerToIds[msg.sender][i]];
        }
        delete ownerToIds[msg.sender];
        OGBalance[msg.sender] = 0;
    }

    function emergencyWithdrawal(uint256 _stakingId) external {
        require(stakedNFTIds[_stakingId].owner == msg.sender, "Not owner");
        address nftContract = stakedNFTIds[ownerToIds[msg.sender][0]]
            .nftContract;
        uint256 tokenId = stakedNFTIds[ownerToIds[msg.sender][0]].tokenId;
        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    // ==================== INTERNAL FUNCTIONS ==================== //
    /// @dev Internal function used to calculate rewards for NFTs held
    // Modulo used to carry up to get reward up to previous day passed
    function _updateRewards(address _addr) internal view returns (uint256) {
        uint256[] memory ownerStakingIds = ownerToIds[_addr];
        uint256 rewards;
        for (uint256 i; i < ownerStakingIds.length; i++) {
            rewards += (dailyContractRewards[
                stakedNFTIds[ownerStakingIds[i]].nftContract
            ] * ((block.timestamp - ownerToLastUpdate[_addr]) / 86400));
        }
        return rewards;
    }

    function _updateHistoricRewards(address _addr)
        internal
        view
        returns (uint256)
    {
        uint256[] memory ownerStakingIds = ownerToIds[_addr];
        uint256 rewards;
        uint256 rewardTime;
        for (uint256 i; i < ownerStakingIds.length; i++) {
            /// We take the first Id in wallet and related contract
            uint64 previous = historicRewardHead[
                stakedNFTIds[ownerStakingIds[i]].nftContract
            ].rewardId;
            /// For the first block we calculate like normal
            rewards +=
                (dailyContractRewards[
                    stakedNFTIds[ownerStakingIds[i]].nftContract
                ] *
                    (block.timestamp -
                        historicRewardToId[previous].timestamp)) /
                86400;
            uint64 current = historicRewardToId[previous].rewardId;
            /// If last update > historic reward start then last reward was in this block
            while (
                ownerToLastUpdate[_addr] < historicRewardToId[current].timestamp
            ) {
                /// Otherwise we want the start of the next block and start of current
                /// We take that timeframe and multiply by daily reward
                /// Minus the start of next from the start of current to get timeframe
                rewardTime =
                    historicRewardToId[previous].timestamp -
                    historicRewardToId[current].timestamp;
                /// Divide reward time into days and multiply by next rewards
                /// Set the current to next
                rewards +=
                    historicRewardToId[current].reward *
                    (rewardTime / 86400);
                previous = current;
                current = historicRewardToId[current].next;
            }
            /// Calc final segment with last block start - last update
            rewardTime =
                ownerToLastUpdate[_addr] -
                historicRewardToId[current].timestamp;
            rewards +=
                historicRewardToId[current].reward *
                (rewardTime / 86400);
        }
        return rewards;
    }

    // ===================== ADMIN FUNCTIONS ====================== //
    /// @dev Setter for the TRPZ coin address
    function setTrpzAddr(address _addr) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "You are not an admin");
        trpzToken = _addr;
    }

    /// @dev Pause function for the main functionality in contract
    function pauseContract() external {
        require(hasRole(ADMIN_ROLE, msg.sender), "You are not an admin");
        paused = !paused;
    }

    /// @dev Whitelist function to add new NFT addresses
    function whitelistContract(address _addr) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "You are not an admin");
        whitelistedContracts[_addr] = !whitelistedContracts[_addr];
    }

    /// @dev Setter function for daily rewards of each NFT contract
    /// Setting new reward to the head + adding to historicIds + pointing the linked list down the chain
    function yieldSetter(address _addr, uint64 _dailyReward) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "You are not an admin");
        require(whitelistedContracts[_addr], "Address not whitelisted");
        lastYieldUpdate = block.timestamp;
        uint64 previousHeadId = historicRewardHead[_addr].rewardId;
        historicId++;
        historicRewardHead[_addr] = historicReward(
            block.timestamp,
            historicId,
            _dailyReward,
            previousHeadId
        );
        historicRewardToId[historicId] = historicRewardHead[_addr];
        dailyContractRewards[_addr] = _dailyReward;
    }

    // ====================== GETTER FUNCTIONS =================== //
    function getStakedNFT(uint256 _stakingId)
        external
        view
        returns (
            uint256 tokenId,
            address contractAddr,
            address owner
        )
    {
        stakedNFT memory nft = stakedNFTIds[_stakingId];
        require(nft.nftContract != address(0), "Doesn't exist");
        uint256 nftId = nft.tokenId;
        address nftContract = nft.nftContract;
        address nftOwner = nft.owner;
        return (nftId, nftContract, nftOwner);
    }

    function getStakedList(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return ownerToIds[_address];
    }

    function getRewards(address _address) external view returns (uint256) {
        uint256 rewards;
        if (ownerToLastUpdate[_address] < lastYieldUpdate) {
            rewards = _updateHistoricRewards(_address);
        } else {
            rewards = _updateRewards(_address);
        }
        return rewards;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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