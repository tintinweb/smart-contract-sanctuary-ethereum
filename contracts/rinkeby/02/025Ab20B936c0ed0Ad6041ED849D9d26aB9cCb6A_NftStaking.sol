// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IERC20.sol";
import "./libs/Address.sol";
import "./libs/SafeERC20.sol";

contract NftStaking is IERC721Receiver, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    struct Pool {
        IERC721 nft;
        IERC20 stakingToken;
        IERC20 rewardToken;
        string name;
        uint256 totalStaked;
        uint256 totalPoolSize;
        ApyStruct[] apyStruct;
        uint256 unstakeFee;
        uint256 unstakeFeeDuration;
        address feeReceiverAddress;
        mapping(address => uint256) userLastStakeTime;
        mapping(address => uint256[]) higherTierCardsStaked;
        mapping(address => uint256[]) lowerTierCardsStaked;
        mapping(address => uint256) tokensStaked;
        mapping(address => uint256) lastUserClaim;
        mapping(address => uint256) userApy;
        mapping(uint256 => uint256) higherTierCards;
        mapping(uint256 => uint256) lowerTierCards;
        mapping(uint256 => uint256) goatCards;
        uint256 totalHigherTierCardsPerUser;
        uint256 totalLowerTierCardsPerUser;
        uint256 startJoinTime;
        uint256 endJoinTime;
    }

    uint256 public poolLength;
    mapping(uint256 => Pool) public pools;

    struct ApyStruct {
        uint256 amount;
        uint256 apy;
    }

    event AddedPool(
        uint256 poolId,
        address nft,
        address stakingToken,
        address rewardToken,
        string name,
        uint256 totalPoolSize,
        uint256 totalHigherTierCardsPerUser,
        uint256 totalLowerTierCardsPerUser,
        uint256 unstakeFeeDuration,
        uint256 unstakeFee,
        address feeReceiverAddress,
        uint256 startJoinTime,
        uint256 endJoinTime
    );

    event UpdatedPool(uint256 poolId, string name, uint256 totalPoolSize);

    event Staked(
        address indexed userAddress,
        uint256[] ids,
        uint256 tokenAmount
    );
    event Withdrawn(
        address indexed userAddress,
        uint256[] ids,
        uint256 tokenAmount,
        uint256 fee
    );
    event RewardClaimed(
        address indexed userAddress,
        uint256 requiredRewardAmount,
        uint256 rewardAmount
    );

    modifier updateState(uint256 _poolId, address _userAddress) {
        updateUser(_poolId, _userAddress);
        _;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _poolId id of the pool
     */
    modifier validatePoolById(uint256 _poolId) {
        require(_poolId < poolLength, "Lympo: Pool are not exist");
        _;
    }

    function __Lympo_init() public initializer {
        __AccessControl_init();

        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);
    }

    function getUserCardsStaked(uint256 _poolId, address _userAddress)
        public
        view
        validatePoolById(_poolId)
        returns (uint256[] memory, uint256[] memory)
    {
        Pool storage poolInfo = pools[_poolId];
        return (
            poolInfo.higherTierCardsStaked[_userAddress],
            poolInfo.lowerTierCardsStaked[_userAddress]
        );
    }

    function getPoolData(
        uint256 _poolId,
        address /*_userAddress*/
    )
        external
        view
        validatePoolById(_poolId)
        returns (
            uint256 _totalStaked,
            uint256 _poolSize,
            uint256 _remaining,
            uint256 _roiMin,
            uint256 _roiMax
        )
    {
        Pool storage poolInfo = pools[_poolId];

        _totalStaked = poolInfo.totalStaked;
        _poolSize = poolInfo.totalPoolSize;
        _remaining = poolInfo.totalPoolSize - poolInfo.totalStaked;

        if (poolInfo.apyStruct.length > 0) {
            _roiMin = poolInfo.apyStruct[0].apy;
            _roiMax = poolInfo.apyStruct[poolInfo.apyStruct.length - 1].apy;
        }
    }

    function getPoolData2(uint256 _poolId, address _userAddress)
        external
        view
        validatePoolById(_poolId)
        returns (
            uint256 _earnedReward,
            uint256 _roi,
            uint256 _roiBoost,
            uint256 _stakedNft,
            uint256 _userStakedTokens
        )
    {
        Pool storage poolInfo = pools[_poolId];

        _roi = getTotalApy(_poolId, _userAddress);
        _roiBoost = getBoostedApy(_poolId, _userAddress);
        _stakedNft =
            poolInfo.higherTierCardsStaked[_userAddress].length +
            poolInfo.lowerTierCardsStaked[_userAddress].length;
        _userStakedTokens = poolInfo.tokensStaked[_userAddress];
        _earnedReward = getReward(_poolId, _userAddress);
    }

    function updateUsers(uint256 _poolId, address[] calldata _userAddresses)
        external
    {
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            updateUser(_poolId, _userAddresses[i]);
        }
    }

    function update(uint256 _poolId) public {
        updateUser(_poolId, msg.sender);
    }

    function updateUser(uint256 _poolId, address _userAddress)
        public
        validatePoolById(_poolId)
    {
        Pool storage poolInfo = pools[_poolId];

        uint256 reward = getReward(_poolId, _userAddress);
        uint256 balance = poolInfo.rewardToken.balanceOf(address(this));

        uint256 userReward = reward < balance ? reward : balance;
        poolInfo.lastUserClaim[_userAddress] = block.timestamp;

        if (userReward > 0) {
            poolInfo.rewardToken.safeTransfer(_userAddress, userReward);
            emit RewardClaimed(_userAddress, reward, userReward);
        }
    }

    function addPool(
        string memory _name,
        IERC721 _nft,
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _totalPoolSize,
        uint256 _totalHigherTierCardsPerUser,
        uint256 _totalLowerTierCardsPerUser,
        uint256 _startJoinTime,
        uint256 _endJoinTime
    ) external onlyRole(ADMIN) {
        require(
            _endJoinTime >= block.timestamp && _endJoinTime > _startJoinTime,
            "Lympo: invalid end join time"
        );

        Pool storage newPool = pools[poolLength++];

        newPool.name = _name;
        newPool.nft = _nft;
        newPool.stakingToken = _stakingToken;
        newPool.rewardToken = _rewardToken;

        newPool.totalPoolSize = _totalPoolSize;

        newPool.unstakeFeeDuration = 7 days;
        newPool.unstakeFee = 0.02e18; //2%
        newPool.feeReceiverAddress = msg.sender; // need to be changed

        newPool.totalHigherTierCardsPerUser = _totalHigherTierCardsPerUser;
        newPool.totalLowerTierCardsPerUser = _totalLowerTierCardsPerUser;

        newPool.startJoinTime = _startJoinTime;
        newPool.endJoinTime = _endJoinTime;

        setApyStruct(poolLength - 1);

        emit AddedPool(
            poolLength - 1,
            address(_nft),
            address(_stakingToken),
            address(_rewardToken),
            _name,
            _totalPoolSize,
            _totalHigherTierCardsPerUser,
            _totalLowerTierCardsPerUser,
            newPool.unstakeFeeDuration,
            newPool.unstakeFee,
            newPool.feeReceiverAddress,
            _startJoinTime,
            _endJoinTime
        );
    }

    function updatePool(
        uint256 _poolId,
        string memory _name,
        uint256 _totalPoolSize
    ) external onlyRole(ADMIN) validatePoolById(_poolId) {
        Pool storage pool = pools[_poolId];
        pool.name = _name;
        pool.totalPoolSize = _totalPoolSize;

        emit UpdatedPool(_poolId, _name, _totalPoolSize);
    }

    function getReward(uint256 _poolId, address _userAddress)
        public
        view
        validatePoolById(_poolId)
        returns (uint256)
    {
        Pool storage poolInfo = pools[_poolId];

        return
            (block.timestamp - poolInfo.lastUserClaim[msg.sender]) *
            ((poolInfo.tokensStaked[_userAddress] *
                (getTotalApy(_poolId, _userAddress))) /
                1e18 /
                (30 days));
    }

    function stakeCards(uint256 _poolId, uint256[] calldata _ids)
        external
        validatePoolById(_poolId)
        updateState(_poolId, msg.sender)
    {
        Pool storage poolInfo = pools[_poolId];

        require(
            block.timestamp >= poolInfo.startJoinTime,
            "Lympo: pool is not started yet"
        );

        require(
            block.timestamp <= poolInfo.endJoinTime,
            "Lympo: pool is already closed"
        );

        uint256 totalPrice;

        for (uint256 i = 0; i < _ids.length; i++) {
            bool isHigherTier;
            uint256 price;

            uint256 higherTierPrice = poolInfo.higherTierCards[_ids[i]];
            if (higherTierPrice > 0) {
                isHigherTier = true;
                price = higherTierPrice;
            } else {
                uint256 lowerTierPrice = poolInfo.lowerTierCards[_ids[i]];
                require(lowerTierPrice != 0, "Lympo: card is not stakable");
                price = lowerTierPrice;
            }

            if (isHigherTier) {
                require(
                    poolInfo.higherTierCardsStaked[msg.sender].length <
                        poolInfo.totalHigherTierCardsPerUser,
                    "Lympo: exceed higher tier staking limit"
                );
                poolInfo.higherTierCardsStaked[msg.sender].push(_ids[i]);
            } else {
                require(
                    poolInfo.lowerTierCardsStaked[msg.sender].length <
                        poolInfo.totalLowerTierCardsPerUser,
                    "Lympo: exceed lower tier staking limit"
                );
                poolInfo.lowerTierCardsStaked[msg.sender].push(_ids[i]);
            }

            poolInfo.nft.safeTransferFrom(
                msg.sender,
                address(this),
                _ids[i],
                "0x"
            );
            totalPrice += price;
        }

        poolInfo.stakingToken.safeTransferFrom(
            msg.sender,
            address(this),
            totalPrice
        );
        poolInfo.tokensStaked[msg.sender] += totalPrice;
        poolInfo.totalStaked += totalPrice;

        require(
            poolInfo.tokensStaked[msg.sender] >= poolInfo.apyStruct[0].amount,
            "Lympo: total stake less than minimum"
        );
        require(
            poolInfo.totalStaked <= poolInfo.totalPoolSize,
            "Lympo: exceed pool limit"
        );

        bool isGoatExists;
        for (
            uint256 i = 0;
            i < poolInfo.higherTierCardsStaked[msg.sender].length;
            i++
        ) {
            if (
                poolInfo.goatCards[
                    poolInfo.higherTierCardsStaked[msg.sender][i]
                ] > 0
            ) {
                if (!isGoatExists) {
                    isGoatExists = true;
                } else {
                    revert("Lympo: cannot stake more than 1 goat card");
                }
            }
        }

        poolInfo.lastUserClaim[msg.sender] = block.timestamp;

        poolInfo.userLastStakeTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, _ids, totalPrice);
    }

    // solhint-disable-next-line
    function withdraw(uint256 _poolId, uint256[] calldata _ids)
        external
        validatePoolById(_poolId)
        updateState(_poolId, msg.sender)
    {
        Pool storage poolInfo = pools[_poolId];
        uint256 totalPrice;

        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] != 0, "Lympo: invalid input");

            uint256 price;
            bool found;

            for (
                uint256 j = 0;
                j < poolInfo.higherTierCardsStaked[msg.sender].length;
                j++
            ) {
                if (poolInfo.higherTierCardsStaked[msg.sender][j] == _ids[i]) {
                    found = true;
                    price = poolInfo.higherTierCards[_ids[i]];
                    poolInfo.higherTierCardsStaked[msg.sender][j] = 0;
                    break;
                }
            }

            if (!found) {
                for (
                    uint256 j = 0;
                    j < poolInfo.lowerTierCardsStaked[msg.sender].length;
                    j++
                ) {
                    if (
                        poolInfo.lowerTierCardsStaked[msg.sender][j] == _ids[i]
                    ) {
                        found = true;
                        price = poolInfo.lowerTierCards[_ids[i]];
                        poolInfo.lowerTierCardsStaked[msg.sender][j] = 0;
                        break;
                    }
                }
            }

            require(found, "Lympo: token is not staked");
            poolInfo.nft.safeTransferFrom(
                address(this),
                msg.sender,
                _ids[i],
                "0x"
            );
            totalPrice += price;
        }

        poolInfo.tokensStaked[msg.sender] -= totalPrice;
        poolInfo.totalStaked -= totalPrice;

        uint256 _fee;
        if (
            block.timestamp <
            poolInfo.userLastStakeTime[msg.sender] +
                (poolInfo.unstakeFeeDuration) &&
            poolInfo.rewardToken.balanceOf(address(this)) > 0
        ) //You do not pay unstaking fee when staking event is over
        {
            //charge fee
            _fee = (totalPrice * (poolInfo.unstakeFee)) / 1e18;
            poolInfo.stakingToken.safeTransfer(
                poolInfo.feeReceiverAddress,
                _fee
            );
        }

        poolInfo.stakingToken.safeTransfer(msg.sender, totalPrice - _fee);

        uint256[] memory _higherTierCardsStaked = poolInfo
            .higherTierCardsStaked[msg.sender];
        uint256[] memory _lowerTierCardsStaked = poolInfo.lowerTierCardsStaked[
            msg.sender
        ];

        poolInfo.higherTierCardsStaked[msg.sender] = new uint256[](0);
        poolInfo.lowerTierCardsStaked[msg.sender] = new uint256[](0);

        for (uint256 i = 0; i < _higherTierCardsStaked.length; i++) {
            if (_higherTierCardsStaked[i] > 0) {
                poolInfo.higherTierCardsStaked[msg.sender].push(
                    _higherTierCardsStaked[i]
                );
            }
        }

        for (uint256 i = 0; i < _lowerTierCardsStaked.length; i++) {
            if (_lowerTierCardsStaked[i] > 0) {
                poolInfo.lowerTierCardsStaked[msg.sender].push(
                    _lowerTierCardsStaked[i]
                );
            }
        }

        emit Withdrawn(msg.sender, _ids, totalPrice, _fee);
    }

    function setApyStruct(uint256 _poolId) private validatePoolById(_poolId) {
        Pool storage poolInfo = pools[_poolId];

        poolInfo.apyStruct.push(ApyStruct({ amount: 2000e18, apy: 0.02e18 })); //1e18 - 100%
        poolInfo.apyStruct.push(ApyStruct({ amount: 10000e18, apy: 0.05e18 }));
        poolInfo.apyStruct.push(ApyStruct({ amount: 20000e18, apy: 0.085e18 }));
        poolInfo.apyStruct.push(ApyStruct({ amount: 40000e18, apy: 0.1e18 }));
        poolInfo.apyStruct.push(ApyStruct({ amount: 60000e18, apy: 0.115e18 }));
        poolInfo.apyStruct.push(ApyStruct({ amount: 80000e18, apy: 0.13e18 }));
        poolInfo.apyStruct.push(
            ApyStruct({ amount: 100000e18, apy: 0.145e18 })
        );
        poolInfo.apyStruct.push(ApyStruct({ amount: 120000e18, apy: 0.16e18 }));
        poolInfo.apyStruct.push(
            ApyStruct({ amount: 140000e18, apy: 0.175e18 })
        );
    }

    function getApyByStake(uint256 _poolId, uint256 _amount)
        public
        view
        validatePoolById(_poolId)
        returns (uint256)
    {
        Pool storage poolInfo = pools[_poolId];

        if (
            poolInfo.apyStruct.length == 0 ||
            _amount < poolInfo.apyStruct[0].amount
        ) {
            return 0;
        }

        for (uint256 i = 0; i < poolInfo.apyStruct.length; i++) {
            if (_amount <= poolInfo.apyStruct[i].amount) {
                return poolInfo.apyStruct[i].apy;
            }
        }

        return poolInfo.apyStruct[poolInfo.apyStruct.length - 1].apy;
    }

    //Only one goat card gives boosted APY
    function getBoostedApy(uint256 _poolId, address _userAddress)
        public
        view
        validatePoolById(_poolId)
        returns (uint256)
    {
        Pool storage poolInfo = pools[_poolId];

        for (
            uint256 i = 0;
            i < poolInfo.higherTierCardsStaked[_userAddress].length;
            i++
        ) {
            uint256 boosted = poolInfo.goatCards[
                poolInfo.higherTierCardsStaked[_userAddress][i]
            ];
            if (boosted > 0) {
                return boosted;
            }
        }

        return 0;
    }

    function getTotalApy(uint256 _poolId, address _userAddress)
        public
        view
        validatePoolById(_poolId)
        returns (uint256)
    {
        Pool storage poolInfo = pools[_poolId];

        uint256 baseAPY = getApyByStake(
            _poolId,
            poolInfo.tokensStaked[_userAddress]
        );
        uint256 boostedApy = getBoostedApy(_poolId, _userAddress);

        return (baseAPY * (1e18 + boostedApy)) / 1e18;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    //_boosts - 1e18 = 100%
    function setGoatCards(
        uint256 _poolId,
        uint256[] calldata _ids,
        uint256[] calldata _boosts
    ) external onlyRole(ADMIN) validatePoolById(_poolId) {
        Pool storage poolInfo = pools[_poolId];

        for (uint256 i = 0; i < _ids.length; i++) {
            poolInfo.goatCards[_ids[i]] = _boosts[i];
        }
    }

    function setHigherTierCards(
        uint256 _poolId,
        uint256[] calldata _ids,
        uint256[] calldata _prices
    ) external onlyRole(ADMIN) validatePoolById(_poolId) {
        Pool storage poolInfo = pools[_poolId];

        for (uint256 i = 0; i < _ids.length; i++) {
            poolInfo.higherTierCards[_ids[i]] = _prices[i];
        }
    }

    function setLowerTierCards(
        uint256 _poolId,
        uint256[] calldata _ids,
        uint256[] calldata _prices
    ) external onlyRole(ADMIN) validatePoolById(_poolId) {
        Pool storage poolInfo = pools[_poolId];

        for (uint256 i = 0; i < _ids.length; i++) {
            poolInfo.lowerTierCards[_ids[i]] = _prices[i];
        }
    }

    function getCardPrices(uint256 _poolId, uint256[] calldata _ids)
        external
        view
        validatePoolById(_poolId)
        returns (uint256[] memory res)
    {
        Pool storage poolInfo = pools[_poolId];

        res = new uint256[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            if (poolInfo.higherTierCards[_ids[i]] > 0) {
                res[i] = poolInfo.higherTierCards[_ids[i]];
            } else {
                res[i] = poolInfo.lowerTierCards[_ids[i]];
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./SafeMath.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using Address for address;
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}