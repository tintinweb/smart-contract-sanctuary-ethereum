// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./extensions/Signature.sol";

import { MadWorldStruct } from "./libs/MadWorldStruct.sol";

contract MadWorldStakingV2 is
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    uint256 public decimalsForAPR;

    bytes32 public constant OPERATOR_ADD_POOL = keccak256("OPERATOR_ADD_POOL");

    bytes32 public constant STAKE_SIGNER = keccak256("STAKE_SIGNER");

    uint256 public secondInDay;
    uint256 public dayInYear;

    //pool
    mapping(uint256 => MadWorldStruct.Pool) public pools;
    uint256 public poolLength;

    //user
    // poolId -> user address -> nonce
    mapping(uint256 => mapping(address => uint256)) public userNonce;
    // mapping pooldID -> useraddress -> ...
    mapping(uint256 => mapping(address => mapping(uint256 => MadWorldStruct.Vault)))
        public vaultStorage;

    mapping(uint256 => mapping(address => uint256))
        private latestVaultIndexForUser;

    mapping(uint256 => mapping(address => MadWorldStruct.UserState))
        public userState;

    // poolId -> user -> vault -> collection -> tokenId
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => MadWorldStruct.StakeData)))))
        private stateStakeBooster;

    // poolId -> user -> vault -> tokenId
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(uint256 => MadWorldStruct.StakeData))))
        private stateStakePrimary;

    mapping(uint256 => bool) public usedUidOffchain;

    bytes32 public DOMAIN_SEPARATOR;

    // event
    event AddedPool(uint256 poolId, uint256 uidOffchain);
    event UpdatedPool(uint256 poolId, string name);
    event StakeSuccessful(uint256 vaultIndex, bytes32 hashMess);
    event UnStakeSuccessful(bytes32 hashMess);
    event Harvest(uint256 poolId, address user, uint256 vaultIndex);

    function __Madworld_init() external initializer {
        __ReentrancyGuard_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x3236c7e1c7479a488a1000bdf2eb6cfdcb5dc45b066bad5f370df675dd79dc76, // keccak256("MadWorldStakingV2")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );
        decimalsForAPR = 100000;
        secondInDay = 86400;
        dayInYear = 365;
    }

    modifier validatePoolById(uint256 _poolId) {
        require(_poolId < poolLength, "MADworld: Pool are not exist");
        _;
    }

    function _getVaultStorage(
        uint256 poolId,
        address user,
        uint256 vaultIndex
    ) public view returns (MadWorldStruct.Vault memory) {
        return vaultStorage[poolId][user][vaultIndex];
    }

    function getVaultStorage(
        uint256 poolId,
        address user,
        uint256 vaultIndex
    ) public view returns (MadWorldStruct.Vault memory) {
        // get amount token primary not unstake yet
        uint256 amountPrimary;

        for (
            uint256 i = 0;
            i < vaultStorage[poolId][user][vaultIndex].tokenIdForPrimary.length;

        ) {
            if (
                !stateStakePrimary[poolId][user][vaultIndex][
                    vaultStorage[poolId][user][vaultIndex].tokenIdForPrimary[i]
                ].unstaked
            ) {
                amountPrimary++;
            }
            unchecked {
                i++;
            }
        }

        uint256[] memory newTokenIdForPrimary = new uint256[](amountPrimary);

        uint256 index;

        for (
            uint256 i = 0;
            i < vaultStorage[poolId][user][vaultIndex].tokenIdForPrimary.length;

        ) {
            if (
                !stateStakePrimary[poolId][user][vaultIndex][
                    vaultStorage[poolId][user][vaultIndex].tokenIdForPrimary[i]
                ].unstaked
            ) {
                newTokenIdForPrimary[index] = vaultStorage[poolId][user][
                    vaultIndex
                ].tokenIdForPrimary[i];
                index++;
            }
            unchecked {
                i++;
            }
        }

        uint256 amountBooster;

        for (
            uint256 i = 0;
            i < vaultStorage[poolId][user][vaultIndex].booster.length;

        ) {
            if (
                !stateStakeBooster[poolId][user][vaultIndex][
                    address(
                        vaultStorage[poolId][user][vaultIndex]
                            .booster[i]
                            .collectionBooster
                    )
                ][vaultStorage[poolId][user][vaultIndex].booster[i].tokenId]
                    .unstaked
            ) {
                amountBooster++;
            }
            unchecked {
                i++;
            }
        }

        MadWorldStruct.Booster[]
            memory newBooster = new MadWorldStruct.Booster[](amountBooster);

        index = 0;
        for (
            uint256 i = 0;
            i < vaultStorage[poolId][user][vaultIndex].booster.length;

        ) {
            if (
                !stateStakeBooster[poolId][user][vaultIndex][
                    address(
                        vaultStorage[poolId][user][vaultIndex]
                            .booster[i]
                            .collectionBooster
                    )
                ][vaultStorage[poolId][user][vaultIndex].booster[i].tokenId]
                    .unstaked
            ) {
                newBooster[index] = MadWorldStruct.Booster(
                    vaultStorage[poolId][user][vaultIndex]
                        .booster[i]
                        .collectionBooster,
                    vaultStorage[poolId][user][vaultIndex].booster[i].tokenId
                );
                index++;
            }
            unchecked {
                i++;
            }
        }

        (uint256 pendingRew, ) = getPendingRewardDaily(poolId, user);

        return
            MadWorldStruct.Vault(
                newTokenIdForPrimary,
                newBooster,
                vaultStorage[poolId][user][vaultIndex].amountUmadValue,
                vaultStorage[poolId][user][vaultIndex].topUpUmadValue,
                vaultStorage[poolId][user][vaultIndex].startStake,
                (vaultIndex + 1 == latestVaultIndexForUser[poolId][user])
                    ? pendingRew
                    : vaultStorage[poolId][user][vaultIndex].endVaultReward
            );
    }

    function getRewardForUser(
        uint256 poolId,
        address user
    ) external view returns (uint256[] memory rewards) {
        if (userState[poolId][user].latestUpdate == 0) return new uint256[](0);
        rewards = new uint256[](userState[poolId][user].indexVault + 1);
        (uint256 pendingRew, ) = getPendingRewardDaily(poolId, user);
        for (uint256 i = 0; i < rewards.length; i++) {
            rewards[i] = (i + 1 == latestVaultIndexForUser[poolId][user])
                ? pendingRew
                : vaultStorage[poolId][user][i].endVaultReward;
        }
    }

    function getTotalRewardForUser(
        address user
    ) external view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < poolLength; i++) {
            if (userState[i][user].latestUpdate == 0) continue;
            (uint256 pendingRew, ) = getPendingRewardDaily(i, user);
            // total += getPendingRewardDaily(i, user);
            for (uint256 j = 0; j < userState[i][user].indexVault + 1; j++) {
                total += (j + 1 == latestVaultIndexForUser[i][user])
                    ? pendingRew
                    : vaultStorage[i][user][j].endVaultReward;
            }
        }
        return total;
    }

    function getHarvestStatus(
        address user
    ) external view returns (MadWorldStruct.HarvestStatus[] memory) {
        uint256 length;
        for (uint256 i = 0; i < poolLength; i++) {
            if (userState[i][user].latestUpdate == 0) continue;
            (uint256 pendingRew, ) = getPendingRewardDaily(i, user);
            // total += getPendingRewardDaily(i, user);
            for (uint256 j = 0; j < userState[i][user].indexVault + 1; j++) {
                if (
                    pools[i].harvestLockDuration +
                        vaultStorage[i][user][j].startStake <=
                    block.timestamp
                ) {
                    if (
                        j + 1 == latestVaultIndexForUser[i][user] &&
                        pendingRew > 0
                    ) {
                        length++;
                    } else if (vaultStorage[i][user][j].endVaultReward > 0)
                        length++;
                }
            }
        }
        MadWorldStruct.HarvestStatus[]
            memory results = new MadWorldStruct.HarvestStatus[](length);
        uint256 index;
        for (uint256 i = 0; i < poolLength; i++) {
            if (userState[i][user].latestUpdate == 0) continue;
            (uint256 pendingRew, ) = getPendingRewardDaily(i, user);
            // total += getPendingRewardDaily(i, user);
            for (uint256 j = 0; j < userState[i][user].indexVault + 1; j++) {
                if (
                    pools[i].harvestLockDuration +
                        vaultStorage[i][user][j].startStake <=
                    block.timestamp
                ) {
                    if (
                        j + 1 == latestVaultIndexForUser[i][user] &&
                        pendingRew > 0
                    ) {
                        results[index] = MadWorldStruct.HarvestStatus(i, j);
                        index++;
                    } else if (vaultStorage[i][user][j].endVaultReward > 0) {
                        results[index] = MadWorldStruct.HarvestStatus(i, j);
                        index++;
                    }
                }
            }
        }
        return results;
    }

    function setSecond(uint256 second) public onlyRole(OPERATOR_ADD_POOL) {
        secondInDay = second;
    }

    function setDayYear(uint256 day) public onlyRole(OPERATOR_ADD_POOL) {
        dayInYear = day;
    }

    function addPool(
        string memory _name,
        uint256 _uidOffchain,
        IERC721 _collectionAddress,
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _totalPoolSize,
        uint256 _startJoinTime,
        uint256 _endJoinTime,
        uint256 _harvestLockDuration,
        bool _isPoolRequiredUmad
    ) external onlyRole(OPERATOR_ADD_POOL) {
        require(
            _endJoinTime >= block.timestamp && _endJoinTime > _startJoinTime,
            "MADworld: invalid end join time"
        );
        require(
            address(_collectionAddress) != address(0),
            "MADworld: _nft can not be zero address"
        );
        require(
            address(_stakingToken) != address(0),
            "MADworld: _stakingToken can not be zero address"
        );
        require(
            address(_rewardToken) != address(0),
            "MADworld: _rewardToken can not be zero address"
        );

        require(
            !usedUidOffchain[_uidOffchain],
            "MADworld: _reward must be a non exist"
        );

        usedUidOffchain[_uidOffchain] = true;
        MadWorldStruct.Pool storage newPool = pools[poolLength];

        {
            newPool.name = _name;
            newPool.collectionAddress = _collectionAddress;
            newPool.stakingToken = _stakingToken;
            newPool.rewardToken = _rewardToken;
            newPool.totalPoolSize = _totalPoolSize;
            newPool.startJoinTime = _startJoinTime;
            newPool.endJoinTime = _endJoinTime;
            newPool.harvestLockDuration = _harvestLockDuration;
            newPool.isRequiredUmad = _isPoolRequiredUmad;
        }

        emit AddedPool(poolLength, _uidOffchain);

        poolLength++;
    }

    function updatePool(
        uint256 _poolId,
        string memory _name
    ) external onlyRole(OPERATOR_ADD_POOL) validatePoolById(_poolId) {
        MadWorldStruct.Pool storage pool = pools[_poolId];
        pool.name = _name;
        emit UpdatedPool(_poolId, _name);
    }

    function stake(
        MadWorldStruct.VaultPayload memory _payload
    ) public validatePoolById(_payload.poolId) {
        require(_payload.user == msg.sender, "invalid user");

        (address signer, bytes32 hashMessage) = Signature.getSignerForPayload(
            DOMAIN_SEPARATOR,
            _payload
        );

        require(hasRole(STAKE_SIGNER, signer), "Invalid stake signer signaure");

        MadWorldStruct.Pool storage poolInfo = pools[_payload.poolId];

        require(
            block.timestamp >= poolInfo.startJoinTime,
            "MADworld: pool is not started yet"
        );
        require(
            block.timestamp <= poolInfo.endJoinTime,
            "MADworld: pool is already closed"
        );

        require(
            userNonce[_payload.poolId][msg.sender] == _payload.nonce,
            "Invalid nonce"
        );
        userNonce[_payload.poolId][msg.sender]++;

        //update for pool

        poolInfo.totalStaked =
            poolInfo.totalStaked +
            _payload.amountUmadValueOrNftValue +
            _payload.topUpUmadValue;

        require(
            poolInfo.totalPoolSize >= poolInfo.totalStaked,
            "Out of range for staking"
        );

        // transfer

        // transfer primary
        for (uint256 i = 0; i < _payload.tokenIdForPrimary.length; ) {
            poolInfo.collectionAddress.safeTransferFrom(
                msg.sender,
                address(this),
                _payload.tokenIdForPrimary[i]
            );

            stateStakePrimary[_payload.poolId][msg.sender][
                latestVaultIndexForUser[_payload.poolId][msg.sender]
            ][_payload.tokenIdForPrimary[i]] = MadWorldStruct.StakeData(
                true,
                false
            );

            unchecked {
                i++;
            }
        }

        //transfer booster
        for (uint256 i = 0; i < _payload.booster.length; ) {
            _payload.booster[i].collectionBooster.safeTransferFrom(
                msg.sender,
                address(this),
                _payload.booster[i].tokenId
            );
            unchecked {
                i++;
            }
        }

        //transfer umad
        bool isRequiredUmadForPool = poolInfo.isRequiredUmad;
        if (isRequiredUmadForPool) {
            poolInfo.stakingToken.transferFrom(
                msg.sender,
                address(this),
                _payload.amountUmadValueOrNftValue + _payload.topUpUmadValue
            );
        } else {
            poolInfo.stakingToken.transferFrom(
                msg.sender,
                address(this),
                _payload.topUpUmadValue
            );
        }

        // update old vault
        updateLatestVault(_payload.poolId, msg.sender);

        // push new vault
        pushToNewVault(isRequiredUmadForPool, _payload, msg.sender);

        //update user
        {
            MadWorldStruct.UserState storage userInfo = userState[
                _payload.poolId
            ][msg.sender];
            userInfo.APR = _payload.APR;
            userInfo.valueInUMad =
                userInfo.valueInUMad +
                _payload.amountUmadValueOrNftValue +
                _payload.topUpUmadValue;
            userInfo.latestUpdate = block.timestamp;
            userInfo.indexVault =
                latestVaultIndexForUser[_payload.poolId][msg.sender] -
                1;
            userInfo.rewardWaitting = 0;
        }

        emit StakeSuccessful(
            latestVaultIndexForUser[_payload.poolId][msg.sender] - 1,
            hashMessage
        );
    }

    function pushToNewVault(
        bool isRequiedUmad,
        MadWorldStruct.VaultPayload memory _payload,
        address _user
    ) private {
        uint256 latestVaultIndex = latestVaultIndexForUser[_payload.poolId][
            _user
        ];

        vaultStorage[_payload.poolId][_user][latestVaultIndex]
            .tokenIdForPrimary = _payload.tokenIdForPrimary;

        vaultStorage[_payload.poolId][_user][latestVaultIndex]
            .amountUmadValue = isRequiedUmad
            ? _payload.amountUmadValueOrNftValue
            : 0;
        vaultStorage[_payload.poolId][_user][latestVaultIndex]
            .topUpUmadValue = _payload.topUpUmadValue;
        vaultStorage[_payload.poolId][_user][latestVaultIndex]
            .startStake = block.timestamp;
        vaultStorage[_payload.poolId][_user][latestVaultIndex]
            .endVaultReward = 0;

        for (uint256 i = 0; i < _payload.booster.length; ) {
            vaultStorage[_payload.poolId][_user][latestVaultIndex].booster.push(
                    MadWorldStruct.Booster(
                        _payload.booster[i].collectionBooster,
                        _payload.booster[i].tokenId
                    )
                );

            stateStakeBooster[_payload.poolId][_user][latestVaultIndex][
                address(_payload.booster[i].collectionBooster)
            ][_payload.booster[i].tokenId] = MadWorldStruct.StakeData(
                true,
                false
            );

            unchecked {
                i++;
            }
        }
        latestVaultIndexForUser[_payload.poolId][_user]++;
    }

    function harvest(uint256 _poolId, uint256 _vaultIndex) public nonReentrant {
        _harvest(_poolId, _vaultIndex);
    }

    function batchHarvest(
        uint256 _poolId,
        uint256[] memory _vaultIndexs
    ) public nonReentrant {
        for (uint256 i = 0; i < _vaultIndexs.length; ) {
            _harvest(_poolId, _vaultIndexs[i]);
            unchecked {
                i++;
            }
        }
    }

    function _harvest(uint256 _poolId, uint256 _vaultIndex) private {
        require(
            pools[_poolId].harvestLockDuration +
                vaultStorage[_poolId][msg.sender][_vaultIndex].startStake <=
                block.timestamp,
            "not pass lock duration yet"
        );

        // if current vault
        if (_vaultIndex == latestVaultIndexForUser[_poolId][msg.sender] - 1) {
            (uint256 reward, uint256 newUpdate) = getPendingRewardDaily(
                _poolId,
                msg.sender
            );
            if (reward > 0) {
                pools[_poolId].rewardToken.transfer(msg.sender, reward);
                // update reward
                userState[_poolId][msg.sender].latestUpdate = newUpdate;
                userState[_poolId][msg.sender].rewardWaitting = 0;
            }
        } else if (
            _vaultIndex < latestVaultIndexForUser[_poolId][msg.sender] - 1
        ) {
            pools[_poolId].rewardToken.transfer(
                msg.sender,
                vaultStorage[_poolId][msg.sender][_vaultIndex].endVaultReward
            );
            vaultStorage[_poolId][msg.sender][_vaultIndex].endVaultReward = 0;
        }
        // else

        emit Harvest(_poolId, msg.sender, _vaultIndex);
    }

    function unstake(
        MadWorldStruct.UnStakeCardPayload memory _payload
    ) public nonReentrant {
        require(_payload.user == msg.sender, "invalid user");

        (address signer, bytes32 hashMessage) = Signature
            .getSignerForUnstakePayload(DOMAIN_SEPARATOR, _payload);

        require(hasRole(STAKE_SIGNER, signer), "Invalid stake signer signaure");

        MadWorldStruct.Pool storage poolInfo = pools[_payload.poolId];

        require(
            block.timestamp >= poolInfo.startJoinTime,
            "MADworld: pool is not started yet"
        );

        require(
            userNonce[_payload.poolId][msg.sender] == _payload.nonce,
            "Invalid nonce"
        );
        userNonce[_payload.poolId][msg.sender]++;

        _transferToUserAndDelete(_payload);

        MadWorldStruct.UserState storage userInfo = userState[_payload.poolId][
            msg.sender
        ];

        userInfo.rewardWaitting = getPendingRewardRealTime(
            _payload.poolId,
            msg.sender
        );
        userInfo.latestUpdate = block.timestamp;
        userInfo.APR = _payload.APR;
        //update for pool

        if (
            _payload.unstakeType == MadWorldStruct.UnStakeType.NFT ||
            _payload.unstakeType == MadWorldStruct.UnStakeType.UMADVALUE
        ) {
            poolInfo.totalStaked -= _payload
                .amountUmadValueUnStakeOrNftValueUnStake;
            userInfo.valueInUMad -= _payload
                .amountUmadValueUnStakeOrNftValueUnStake;
        } else if (_payload.unstakeType == MadWorldStruct.UnStakeType.TOPUP) {
            poolInfo.totalStaked -= _payload.topUpUmadValue;
            userInfo.valueInUMad -= _payload.topUpUmadValue;
        }

        emit UnStakeSuccessful(hashMessage);
    }

    function _transferToUserAndDelete(
        MadWorldStruct.UnStakeCardPayload memory payload
    ) private {
        MadWorldStruct.Vault storage vaultInfo = vaultStorage[payload.poolId][
            payload.user
        ][payload.vaultIndex];
        if (payload.unstakeType == MadWorldStruct.UnStakeType.NFT) {
            if (payload.tokenIdForPrimary.length > 0) {
                for (uint256 i = 0; i < payload.tokenIdForPrimary.length; ) {
                    require(
                        stateStakePrimary[payload.poolId][payload.user][
                            payload.vaultIndex
                        ][payload.tokenIdForPrimary[i]].staked ==
                            true &&
                            stateStakePrimary[payload.poolId][payload.user][
                                payload.vaultIndex
                            ][payload.tokenIdForPrimary[i]].unstaked ==
                            false,
                        "Wrong token"
                    );

                    //transfer nft
                    pools[payload.poolId].collectionAddress.safeTransferFrom(
                        address(this),
                        payload.user,
                        payload.tokenIdForPrimary[i]
                    );

                    stateStakePrimary[payload.poolId][payload.user][
                        payload.vaultIndex
                    ][payload.tokenIdForPrimary[i]] = MadWorldStruct.StakeData(
                        true,
                        true
                    );

                    unchecked {
                        i++;
                    }
                }
            }

            if (payload.booster.length > 0) {
                for (uint256 i = 0; i < payload.booster.length; ) {
                    require(
                        stateStakeBooster[payload.poolId][payload.user][
                            payload.vaultIndex
                        ][address(payload.booster[i].collectionBooster)][
                            payload.booster[i].tokenId
                        ].staked ==
                            true &&
                            stateStakeBooster[payload.poolId][payload.user][
                                payload.vaultIndex
                            ][address(payload.booster[i].collectionBooster)][
                                payload.booster[i].tokenId
                            ].unstaked ==
                            false,
                        "Wrong token"
                    );

                    //transfer nft
                    payload.booster[i].collectionBooster.safeTransferFrom(
                        address(this),
                        payload.user,
                        payload.booster[i].tokenId
                    );

                    stateStakeBooster[payload.poolId][payload.user][
                        payload.vaultIndex
                    ][address(payload.booster[i].collectionBooster)][
                        payload.booster[i].tokenId
                    ] = MadWorldStruct.StakeData(true, true);

                    unchecked {
                        i++;
                    }
                }
            }
        } else if (
            payload.unstakeType == MadWorldStruct.UnStakeType.UMADVALUE
        ) {
            require(
                payload.amountUmadValueUnStakeOrNftValueUnStake <=
                    vaultInfo.amountUmadValue,
                "Out of your bound"
            );

            pools[payload.poolId].stakingToken.transfer(
                msg.sender,
                payload.amountUmadValueUnStakeOrNftValueUnStake
            );
            vaultInfo.amountUmadValue -= payload
                .amountUmadValueUnStakeOrNftValueUnStake;
        } else if (payload.unstakeType == MadWorldStruct.UnStakeType.TOPUP) {
            require(
                payload.topUpUmadValue <= vaultInfo.topUpUmadValue,
                "Out of your bound"
            );

            pools[payload.poolId].stakingToken.transfer(
                msg.sender,
                payload.topUpUmadValue
            );
            vaultInfo.topUpUmadValue -= payload.topUpUmadValue;
        }
    }

    function getPendingRewardDaily(
        uint256 _poolId,
        address _user
    ) public view returns (uint256, uint256) {
        // block.timestamp
        uint256 toTime;
        if (
            block.timestamp > pools[_poolId].endJoinTime &&
            block.timestamp / secondInDay >
            pools[_poolId].endJoinTime / secondInDay
        ) toTime = pools[_poolId].endJoinTime;
        else toTime = (block.timestamp / secondInDay) * secondInDay;

        // formular = token * APR / decimalsForAPR * (toTime - latestUpdate) / (dayInYear * secondInDay )

        MadWorldStruct.UserState memory userInfo = userState[_poolId][_user];
        uint256 diff;
        if (toTime > userInfo.latestUpdate)
            diff = toTime - userInfo.latestUpdate;
        else return (0, 0);

        return (
            (userInfo.valueInUMad * userInfo.APR * diff) /
                decimalsForAPR /
                (dayInYear * secondInDay) +
                userInfo.rewardWaitting,
            toTime
        );
    }

    function updateLatestVault(uint256 _poolId, address _user) private {
        uint256 latestVaultIndex = latestVaultIndexForUser[_poolId][_user];
        if (latestVaultIndex > 0) {
            vaultStorage[_poolId][_user][latestVaultIndex - 1]
                .endVaultReward = getPendingRewardRealTime(_poolId, _user);
        }
    }

    function getPendingRewardRealTime(
        uint256 _poolId,
        address _user
    ) private view returns (uint256) {
        // block.timestamp
        uint256 toTime;
        if (block.timestamp > pools[_poolId].endJoinTime)
            toTime = pools[_poolId].endJoinTime;
        else toTime = block.timestamp;
        // formular = token * APR / decimalsForAPR * (toTime - latestUpdate) / (dayInYear * secondInDay )

        MadWorldStruct.UserState memory userInfo = userState[_poolId][_user];

        uint256 diff;
        if (toTime > userInfo.latestUpdate)
            diff = toTime - userInfo.latestUpdate;
        else diff = 0;

        return
            (userInfo.valueInUMad * userInfo.APR * diff) /
            decimalsForAPR /
            (dayInYear * secondInDay) +
            userInfo.rewardWaitting;
    }

    // function _updateUser(address user,) private {}

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { MadWorldStruct } from "../libs/MadWorldStruct.sol";

// Signature Verification
/// @title RedKite Whitelists - Implement off-chain whitelist and on-chain verification
/// @author CuongTran <[email protected]>

library Signature {
    // Using Openzeppelin ECDSA cryptography library
    // address public signer;

    // function setSigner(address _signer) external {
    //     signer = _signer;
    // }

    function getSignerForPayload(
        bytes32 domain,
        MadWorldStruct.VaultPayload memory payload
    ) internal pure returns (address, bytes32) {
        // merge booster
        bytes32[] memory mergedBooster = new bytes32[](payload.booster.length);

        for (uint256 i = 0; i < payload.booster.length; ) {
            mergedBooster[i] = keccak256(
                abi.encodePacked(
                    payload.booster[i].collectionBooster,
                    payload.booster[i].tokenId
                )
            );
            unchecked {
                i++;
            }
        }
        bytes32 hashMessage = keccak256(
            abi.encodePacked(
                domain,
                payload.poolId,
                payload.user,
                payload.nonce,
                payload.tokenIdForPrimary,
                mergedBooster,
                payload.amountUmadValueOrNftValue,
                payload.topUpUmadValue,
                payload.APR
            )
        );
        return (
            _verifyStakeCardsSignature(hashMessage, payload._signature),
            hashMessage
        );
    }

    function getSignerForUnstakePayload(
        bytes32 domain,
        MadWorldStruct.UnStakeCardPayload memory payload
    ) internal pure returns (address, bytes32) {
        bytes32 hashMessage;
        if (payload.unstakeType == MadWorldStruct.UnStakeType.NFT) {
            bytes32[] memory mergedBooster = new bytes32[](
                payload.booster.length
            );

            for (uint256 i = 0; i < payload.booster.length; ) {
                mergedBooster[i] = keccak256(
                    abi.encodePacked(
                        payload.booster[i].collectionBooster,
                        payload.booster[i].tokenId
                    )
                );
                unchecked {
                    i++;
                }
            }
            hashMessage = keccak256(
                abi.encodePacked(
                    domain,
                    payload.unstakeType,
                    payload.vaultIndex,
                    payload.poolId,
                    payload.user,
                    payload.nonce,
                    payload.tokenIdForPrimary,
                    mergedBooster,
                    payload.APR,
                    payload.amountUmadValueUnStakeOrNftValueUnStake
                )
            );
        } else if (
            payload.unstakeType == MadWorldStruct.UnStakeType.UMADVALUE
        ) {
            hashMessage = keccak256(
                abi.encodePacked(
                    domain,
                    payload.unstakeType,
                    payload.vaultIndex,
                    payload.poolId,
                    payload.user,
                    payload.nonce,
                    payload.amountUmadValueUnStakeOrNftValueUnStake,
                    payload.APR
                )
            );
        } else if (payload.unstakeType == MadWorldStruct.UnStakeType.TOPUP) {
            hashMessage = keccak256(
                abi.encodePacked(
                    domain,
                    payload.unstakeType,
                    payload.vaultIndex,
                    payload.poolId,
                    payload.user,
                    payload.nonce,
                    payload.topUpUmadValue,
                    payload.APR
                )
            );
        }
        return (
            _verifyStakeCardsSignature(hashMessage, payload._signature),
            hashMessage
        );
    }

    // Verify signature function
    function _verifyStakeCardsSignature(
        bytes32 _msgHash,
        bytes memory signature
    ) private pure returns (address) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_msgHash);

        // return getSignerAddress(ethSignedMessageHash, signature);
        return ECDSA.recover(ethSignedMessageHash, signature);
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library MadWorldStruct {
    struct Pool {
        string name;
        IERC721 collectionAddress;
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint256 totalStaked;
        uint256 totalPoolSize;
        uint256 startJoinTime;
        uint256 endJoinTime;
        uint256 harvestLockDuration;
        bool isRequiredUmad;
    }

    struct Booster {
        IERC721 collectionBooster;
        uint256 tokenId;
    }

    struct Vault {
        uint256[] tokenIdForPrimary;
        Booster[] booster;
        uint256 amountUmadValue;
        uint256 topUpUmadValue;
        uint256 startStake;
        uint256 endVaultReward;
    }
    // to sign payload need poolId, useraddress, nonce

    struct VaultPayload {
        uint256 poolId;
        address user;
        uint256 nonce;
        uint256[] tokenIdForPrimary;
        Booster[] booster;
        uint256 amountUmadValueOrNftValue;
        uint256 topUpUmadValue;
        uint256 APR;
        bytes _signature;
    }

    struct UserState {
        uint256 APR;
        uint256 valueInUMad;
        uint256 latestUpdate;
        uint256 indexVault;
        uint256 rewardWaitting;
    }

    struct HarvestStatus {
        uint256 poolId;
        uint256 vaultIndex;
    }

    enum UnStakeType {
        NFT,
        UMADVALUE,
        TOPUP
    }

    struct UnStakeCardPayload {
        UnStakeType unstakeType;
        uint256 vaultIndex;
        uint256 poolId;
        address user;
        uint256 nonce;
        uint256[] tokenIdForPrimary;
        Booster[] booster;
        uint256 amountUmadValueUnStakeOrNftValueUnStake;
        uint256 topUpUmadValue;
        uint256 APR;
        bytes _signature;
    }

    struct StakeData {
        bool staked;
        bool unstaked;
    }
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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}