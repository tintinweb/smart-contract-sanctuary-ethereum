// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../libraries/paraspace-upgradeability/ParaReentrancyGuard.sol";
import "../libraries/paraspace-upgradeability/ParaVersionedInitializable.sol";
import {PoolStorage} from "./PoolStorage.sol";
import "../../interfaces/IPoolApeStaking.sol";
import "../../interfaces/IPToken.sol";
import "../../dependencies/yoga-labs/ApeCoinStaking.sol";
import "../../interfaces/IXTokenType.sol";
import "../../interfaces/INTokenApeStaking.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ApeStakingLogic} from "../tokenization/libraries/ApeStakingLogic.sol";
import "../libraries/logic/BorrowLogic.sol";
import "../libraries/logic/SupplyLogic.sol";
import "../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IAutoCompoundApe} from "../../interfaces/IAutoCompoundApe.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {Math} from "../../dependencies/openzeppelin/contracts/Math.sol";

contract PoolApeStaking is
    ParaVersionedInitializable,
    ParaReentrancyGuard,
    PoolStorage,
    IPoolApeStaking
{
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeCast for uint256;
    using PercentageMath for uint256;

    IPoolAddressesProvider internal immutable ADDRESSES_PROVIDER;
    IAutoCompoundApe internal immutable APE_COMPOUND;
    IERC20 internal immutable APE_COIN;
    uint256 internal constant POOL_REVISION = 142;

    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     */
    constructor(
        IPoolAddressesProvider provider,
        IAutoCompoundApe apeCompound,
        IERC20 apeCoin
    ) {
        ADDRESSES_PROVIDER = provider;
        APE_COMPOUND = apeCompound;
        APE_COIN = apeCoin;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }

    /// @inheritdoc IPoolApeStaking
    function withdrawApeCoin(
        address nftAsset,
        ApeCoinStaking.SingleNft[] calldata _nfts
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        checkSApeIsNotPaused(ps);

        DataTypes.ReserveData storage nftReserve = ps._reserves[nftAsset];
        address xTokenAddress = nftReserve.xTokenAddress;
        INToken nToken = INToken(xTokenAddress);
        for (uint256 index = 0; index < _nfts.length; index++) {
            require(
                nToken.ownerOf(_nfts[index].tokenId) == msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
        INTokenApeStaking(xTokenAddress).withdrawApeCoin(_nfts, msg.sender);

        require(
            getUserHf(ps, msg.sender) >
                DataTypes.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );
    }

    /// @inheritdoc IPoolApeStaking
    function claimApeCoin(address nftAsset, uint256[] calldata _nfts)
        external
        nonReentrant
    {
        DataTypes.PoolStorage storage ps = poolStorage();
        checkSApeIsNotPaused(ps);

        DataTypes.ReserveData storage nftReserve = ps._reserves[nftAsset];
        address xTokenAddress = nftReserve.xTokenAddress;
        INToken nToken = INToken(xTokenAddress);
        for (uint256 index = 0; index < _nfts.length; index++) {
            require(
                nToken.ownerOf(_nfts[index]) == msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
        INTokenApeStaking(xTokenAddress).claimApeCoin(_nfts, msg.sender);

        require(
            getUserHf(ps, msg.sender) >
                DataTypes.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );
    }

    /// @inheritdoc IPoolApeStaking
    function withdrawBAKC(
        address nftAsset,
        ApeCoinStaking.PairNftWithdrawWithAmount[] calldata _nftPairs
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        checkSApeIsNotPaused(ps);

        address xTokenAddress = ps._reserves[nftAsset].xTokenAddress;
        IERC721 bakcContract = INTokenApeStaking(xTokenAddress).getBAKC();
        address bakcNToken = ps._reserves[address(bakcContract)].xTokenAddress;
        uint256[] memory transferredTokenIds = new uint256[](_nftPairs.length);
        address[] memory transferredTokenOwners = new address[](
            _nftPairs.length
        );
        uint256 actualTransferAmount = 0;
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            require(
                INToken(xTokenAddress).ownerOf(_nftPairs[index].mainTokenId) ==
                    msg.sender,
                Errors.NOT_THE_OWNER
            );

            //only partially withdraw need user's BAKC
            if (!_nftPairs[index].isUncommit) {
                transferredTokenOwners[
                    actualTransferAmount
                ] = validateBAKCOwnerAndTransfer(
                    bakcContract,
                    _nftPairs[index].bakcTokenId,
                    bakcNToken,
                    xTokenAddress,
                    msg.sender
                );
                transferredTokenIds[actualTransferAmount] = _nftPairs[index]
                    .bakcTokenId;
                actualTransferAmount++;
            }
        }
        INTokenApeStaking(xTokenAddress).withdrawBAKC(_nftPairs, msg.sender);

        ////transfer BAKC back for user
        for (uint256 index = 0; index < actualTransferAmount; index++) {
            bakcContract.safeTransferFrom(
                xTokenAddress,
                transferredTokenOwners[index],
                transferredTokenIds[index]
            );
        }

        require(
            getUserHf(ps, msg.sender) >
                DataTypes.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );
    }

    /// @inheritdoc IPoolApeStaking
    function claimBAKC(
        address nftAsset,
        ApeCoinStaking.PairNft[] calldata _nftPairs
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        checkSApeIsNotPaused(ps);

        address xTokenAddress = ps._reserves[nftAsset].xTokenAddress;
        IERC721 bakcContract = INTokenApeStaking(xTokenAddress).getBAKC();
        address bakcNToken = ps._reserves[address(bakcContract)].xTokenAddress;
        address[] memory transferredTokenOwners = new address[](
            _nftPairs.length
        );
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            require(
                INToken(xTokenAddress).ownerOf(_nftPairs[index].mainTokenId) ==
                    msg.sender,
                Errors.NOT_THE_OWNER
            );

            transferredTokenOwners[index] = validateBAKCOwnerAndTransfer(
                bakcContract,
                _nftPairs[index].bakcTokenId,
                bakcNToken,
                xTokenAddress,
                msg.sender
            );
        }

        INTokenApeStaking(xTokenAddress).claimBAKC(_nftPairs, msg.sender);

        //transfer BAKC back for user
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            bakcContract.safeTransferFrom(
                xTokenAddress,
                transferredTokenOwners[index],
                _nftPairs[index].bakcTokenId
            );
        }
    }

    struct BorrowAndStakeLocalVar {
        address nTokenAddress;
        uint256 beforeBalance;
        address bakcNToken;
        IERC721 bakcContract;
        address[] transferredTokenOwners;
    }

    /// @inheritdoc IPoolApeStaking
    function borrowApeAndStake(
        StakingInfo calldata stakingInfo,
        ApeCoinStaking.SingleNft[] calldata _nfts,
        ApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external nonReentrant {
        DataTypes.PoolStorage storage ps = poolStorage();
        checkSApeIsNotPaused(ps);

        require(
            stakingInfo.borrowAsset == address(APE_COIN) ||
                stakingInfo.borrowAsset == address(APE_COMPOUND),
            Errors.INVALID_ASSET_TYPE
        );

        BorrowAndStakeLocalVar memory localVar;
        localVar.nTokenAddress = ps
            ._reserves[stakingInfo.nftAsset]
            .xTokenAddress;
        localVar.beforeBalance = APE_COIN.balanceOf(localVar.nTokenAddress);
        localVar.bakcContract = INTokenApeStaking(localVar.nTokenAddress)
            .getBAKC();
        localVar.bakcNToken = ps
            ._reserves[address(localVar.bakcContract)]
            .xTokenAddress;
        localVar.transferredTokenOwners = new address[](_nftPairs.length);

        DataTypes.ReserveData storage borrowAssetReserve = ps._reserves[
            stakingInfo.borrowAsset
        ];

        // 1, handle borrow part
        if (stakingInfo.borrowAmount > 0) {
            ValidationLogic.validateFlashloanSimple(borrowAssetReserve);
            if (stakingInfo.borrowAsset == address(APE_COIN)) {
                IPToken(borrowAssetReserve.xTokenAddress).transferUnderlyingTo(
                    localVar.nTokenAddress,
                    stakingInfo.borrowAmount
                );
            } else {
                IPToken(borrowAssetReserve.xTokenAddress).transferUnderlyingTo(
                    address(this),
                    stakingInfo.borrowAmount
                );
                APE_COMPOUND.withdraw(stakingInfo.borrowAmount);
                APE_COIN.safeTransfer(
                    localVar.nTokenAddress,
                    stakingInfo.borrowAmount
                );
            }
        }

        // 2, send cash part to xTokenAddress
        if (stakingInfo.cashAmount > 0) {
            APE_COIN.safeTransferFrom(
                msg.sender,
                localVar.nTokenAddress,
                stakingInfo.cashAmount
            );
        }

        // 3, deposit bayc or mayc pool
        for (uint256 index = 0; index < _nfts.length; index++) {
            require(
                INToken(localVar.nTokenAddress).ownerOf(_nfts[index].tokenId) ==
                    msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
        INTokenApeStaking(localVar.nTokenAddress).depositApeCoin(_nfts);

        // 4, deposit bakc pool
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            require(
                INToken(localVar.nTokenAddress).ownerOf(
                    _nftPairs[index].mainTokenId
                ) == msg.sender,
                Errors.NOT_THE_OWNER
            );

            localVar.transferredTokenOwners[
                index
            ] = validateBAKCOwnerAndTransfer(
                localVar.bakcContract,
                _nftPairs[index].bakcTokenId,
                localVar.bakcNToken,
                localVar.nTokenAddress,
                msg.sender
            );
        }
        INTokenApeStaking(localVar.nTokenAddress).depositBAKC(_nftPairs);
        //transfer BAKC back for user
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            localVar.bakcContract.safeTransferFrom(
                localVar.nTokenAddress,
                localVar.transferredTokenOwners[index],
                _nftPairs[index].bakcTokenId
            );
        }

        // 5 mint debt token
        if (stakingInfo.borrowAmount > 0) {
            BorrowLogic.executeBorrow(
                ps._reserves,
                ps._reservesList,
                ps._usersConfig[msg.sender],
                DataTypes.ExecuteBorrowParams({
                    asset: stakingInfo.borrowAsset,
                    user: msg.sender,
                    onBehalfOf: msg.sender,
                    amount: stakingInfo.borrowAmount,
                    referralCode: 0,
                    releaseUnderlying: false,
                    reservesCount: ps._reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle(),
                    priceOracleSentinel: ADDRESSES_PROVIDER
                        .getPriceOracleSentinel()
                })
            );
        }

        //6 checkout ape balance
        require(
            APE_COIN.balanceOf(localVar.nTokenAddress) ==
                localVar.beforeBalance,
            Errors.TOTAL_STAKING_AMOUNT_WRONG
        );

        //7 collateralize sAPE
        uint16 sApeReserveId = ps._reserves[DataTypes.SApeAddress].id;
        DataTypes.UserConfigurationMap storage userConfig = ps._usersConfig[
            msg.sender
        ];
        bool currentStatus = userConfig.isUsingAsCollateral(sApeReserveId);
        if (!currentStatus) {
            userConfig.setUsingAsCollateral(sApeReserveId, true);
            emit ReserveUsedAsCollateralEnabled(
                DataTypes.SApeAddress,
                msg.sender
            );
        }
    }

    /// @inheritdoc IPoolApeStaking
    function unstakeApePositionAndRepay(address nftAsset, uint256 tokenId)
        external
        nonReentrant
    {
        DataTypes.PoolStorage storage ps = poolStorage();
        DataTypes.ReserveData storage nftReserve = ps._reserves[nftAsset];
        address xTokenAddress = nftReserve.xTokenAddress;
        address incentiveReceiver = address(0);
        address positionOwner = INToken(xTokenAddress).ownerOf(tokenId);
        if (msg.sender != positionOwner) {
            require(
                getUserHf(ps, positionOwner) <
                    DataTypes.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
                Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
            incentiveReceiver = msg.sender;
        }

        INTokenApeStaking(xTokenAddress).unstakePositionAndRepay(
            tokenId,
            incentiveReceiver
        );
    }

    /// @inheritdoc IPoolApeStaking
    function repayAndSupply(
        address underlyingAsset,
        address repayAsset,
        address onBehalfOf,
        uint256 totalAmount
    ) external {
        DataTypes.PoolStorage storage ps = poolStorage();
        require(
            msg.sender == ps._reserves[underlyingAsset].xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );

        DataTypes.ReserveData storage apeCoinData = ps._reserves[repayAsset];
        uint256 repayAmount = IERC20(apeCoinData.variableDebtTokenAddress)
            .balanceOf(onBehalfOf);
        if (repayAmount > 0) {
            repayAmount = Math.min(repayAmount, totalAmount);
        }
        if (repayAmount > 0) {
            BorrowLogic.executeRepay(
                ps._reserves,
                ps._usersConfig[onBehalfOf],
                DataTypes.ExecuteRepayParams({
                    asset: repayAsset,
                    amount: repayAmount,
                    onBehalfOf: onBehalfOf,
                    usePTokens: false
                })
            );
        }

        uint256 supplyAmount = totalAmount - repayAmount;
        if (supplyAmount > 0) {
            DataTypes.UserConfigurationMap storage userConfig = ps._usersConfig[
                onBehalfOf
            ];
            SupplyLogic.executeSupply(
                ps._reserves,
                userConfig,
                DataTypes.ExecuteSupplyParams({
                    asset: repayAsset,
                    amount: supplyAmount,
                    onBehalfOf: onBehalfOf,
                    payer: msg.sender,
                    referralCode: 0
                })
            );
            DataTypes.ReserveData storage repayReserve = ps._reserves[
                repayAsset
            ];
            bool currentStatus = userConfig.isUsingAsCollateral(
                repayReserve.id
            );
            if (!currentStatus) {
                userConfig.setUsingAsCollateral(repayReserve.id, true);
                emit ReserveUsedAsCollateralEnabled(repayAsset, onBehalfOf);
            }
        }
    }

    /// @inheritdoc IPoolApeStaking
    function claimApeAndCompound(
        address nftAsset,
        address[] calldata users,
        uint256[][] calldata tokenIds
    ) external nonReentrant {
        require(
            users.length == tokenIds.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        DataTypes.PoolStorage storage ps = poolStorage();
        checkSApeIsNotPaused(ps);

        address xTokenAddress = ps._reserves[nftAsset].xTokenAddress;

        uint256 balanceBefore = APE_COIN.balanceOf(address(this));
        uint256[] memory amounts = new uint256[](tokenIds.length);

        uint256 totalAmount;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256[] calldata userTokenIds = tokenIds[i];
            for (uint256 j = 0; j < userTokenIds.length; j++) {
                address positionOwner = INToken(xTokenAddress).ownerOf(
                    userTokenIds[j]
                );
                require(users[i] == positionOwner, Errors.NOT_THE_OWNER);
            }

            INTokenApeStaking(xTokenAddress).claimApeCoin(
                userTokenIds,
                address(this)
            );

            uint256 balanceAfter = APE_COIN.balanceOf(address(this));
            unchecked {
                amounts[i] = balanceAfter - balanceBefore;
                balanceBefore = balanceAfter;
                totalAmount += amounts[i];
            }
        }

        depositApeAndSupplyCApeForUser(ps, totalAmount, users, amounts);
    }

    struct CompoundPairedApeRewardLocalVar {
        address xTokenAddress;
        IERC721 bakcContract;
        address bakcNToken;
        uint256 balanceBefore;
        uint256 balanceAfter;
        uint256[] amounts;
        address[] transferredTokenOwners;
        uint256 totalAmount;
    }

    /// @inheritdoc IPoolApeStaking
    function claimPairedApeAndCompound(
        address nftAsset,
        address[] calldata users,
        ApeCoinStaking.PairNft[][] calldata _nftPairs
    ) external nonReentrant {
        require(
            users.length == _nftPairs.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        DataTypes.PoolStorage storage ps = poolStorage();

        CompoundPairedApeRewardLocalVar memory localVar;
        localVar.xTokenAddress = ps._reserves[nftAsset].xTokenAddress;
        localVar.bakcContract = INTokenApeStaking(localVar.xTokenAddress)
            .getBAKC();
        localVar.bakcNToken = ps
            ._reserves[address(localVar.bakcContract)]
            .xTokenAddress;
        localVar.balanceBefore = APE_COIN.balanceOf(address(this));
        localVar.amounts = new uint256[](_nftPairs.length);

        for (uint256 i = 0; i < _nftPairs.length; i++) {
            ApeCoinStaking.PairNft[] calldata nftPair = _nftPairs[i];
            localVar.transferredTokenOwners = new address[](nftPair.length);
            for (uint256 j = 0; j < nftPair.length; j++) {
                require(
                    users[i] ==
                        INToken(localVar.xTokenAddress).ownerOf(
                            nftPair[j].mainTokenId
                        ),
                    Errors.NOT_THE_OWNER
                );

                localVar.transferredTokenOwners[
                    j
                ] = validateBAKCOwnerAndTransfer(
                    localVar.bakcContract,
                    nftPair[j].bakcTokenId,
                    localVar.bakcNToken,
                    localVar.xTokenAddress,
                    users[i]
                );
            }

            INTokenApeStaking(localVar.xTokenAddress).claimBAKC(
                nftPair,
                address(this)
            );

            for (uint256 index = 0; index < nftPair.length; index++) {
                localVar.bakcContract.safeTransferFrom(
                    localVar.xTokenAddress,
                    localVar.transferredTokenOwners[index],
                    nftPair[index].bakcTokenId
                );
            }

            localVar.balanceAfter = APE_COIN.balanceOf(address(this));
            localVar.amounts[i] =
                localVar.balanceAfter -
                localVar.balanceBefore;
            localVar.balanceBefore = localVar.balanceAfter;
            localVar.totalAmount += localVar.amounts[i];
        }

        depositApeAndSupplyCApeForUser(
            ps,
            localVar.totalAmount,
            users,
            localVar.amounts
        );
    }

    /// @inheritdoc IPoolApeStaking
    function getApeCompoundFeeRate() external view returns (uint256) {
        DataTypes.PoolStorage storage ps = poolStorage();
        return uint256(ps._apeCompoundFee);
    }

    function depositApeAndSupplyCApeForUser(
        DataTypes.PoolStorage storage ps,
        uint256 totalAmount,
        address[] calldata users,
        uint256[] memory amounts
    ) internal {
        APE_COMPOUND.deposit(address(this), totalAmount);

        uint256 compoundFee = ps._apeCompoundFee;
        uint256 totalFee = totalAmount.percentMul(compoundFee);
        if (totalFee > 0) {
            IERC20(address(APE_COMPOUND)).safeTransfer(msg.sender, totalFee);
        }

        for (uint256 index = 0; index < users.length; index++) {
            if (amounts[index] != 0) {
                supplyCApeForUser(
                    ps,
                    users[index],
                    amounts[index].percentMul(
                        PercentageMath.PERCENTAGE_FACTOR - compoundFee
                    )
                );
            }
        }
    }

    function getUserHf(DataTypes.PoolStorage storage ps, address user)
        internal
        view
        returns (uint256)
    {
        DataTypes.CalculateUserAccountDataParams memory params = DataTypes
            .CalculateUserAccountDataParams({
                userConfig: ps._usersConfig[user],
                reservesCount: ps._reservesCount,
                user: user,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            });

        (, , , , , , , uint256 healthFactor, , ) = GenericLogic
            .calculateUserAccountData(ps._reserves, ps._reservesList, params);
        return healthFactor;
    }

    function checkSApeIsNotPaused(DataTypes.PoolStorage storage ps)
        internal
        view
    {
        DataTypes.ReserveData storage reserve = ps._reserves[
            DataTypes.SApeAddress
        ];

        (bool isActive, , , bool isPaused, ) = reserve.configuration.getFlags();

        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function supplyCApeForUser(
        DataTypes.PoolStorage storage ps,
        address user,
        uint256 amount
    ) internal {
        DataTypes.UserConfigurationMap storage userConfig = ps._usersConfig[
            user
        ];
        SupplyLogic.executeSupply(
            ps._reserves,
            userConfig,
            DataTypes.ExecuteSupplyParams({
                asset: address(APE_COMPOUND),
                amount: amount,
                onBehalfOf: user,
                payer: address(this),
                referralCode: 0
            })
        );
        DataTypes.ReserveData storage assetReserve = ps._reserves[
            address(APE_COMPOUND)
        ];
        bool currentStatus = userConfig.isUsingAsCollateral(assetReserve.id);
        if (!currentStatus) {
            userConfig.setUsingAsCollateral(assetReserve.id, true);
            emit ReserveUsedAsCollateralEnabled(address(APE_COMPOUND), user);
        }
    }

    function validateBAKCOwnerAndTransfer(
        IERC721 bakcContract,
        uint256 tokenId,
        address bakcNToken,
        address apeStakingNToken,
        address userAddress
    ) internal returns (address bakcOwner) {
        bakcOwner = bakcContract.ownerOf(tokenId);
        address nBAKCOwner;
        if (bakcNToken != address(0)) {
            nBAKCOwner = INToken(bakcNToken).ownerOf(tokenId);
        }
        require(
            (userAddress == bakcOwner) || (userAddress == nBAKCOwner),
            Errors.NOT_THE_BAKC_OWNER
        );
        bakcContract.safeTransferFrom(bakcOwner, apeStakingNToken, tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "../dependencies/yoga-labs/ApeCoinStaking.sol";

/**
 * @title IPoolApeStaking
 *
 * @notice Defines the basic interface for an ParaSpace Ape Staking Pool.
 **/
interface IPoolApeStaking {
    struct StakingInfo {
        // Contract address of BAYC/MAYC
        address nftAsset;
        // address of borrowing asset, can be Ape or cApe
        address borrowAsset;
        // Borrow amount of Ape from lending pool
        uint256 borrowAmount;
        // Cash amount of Ape from user wallet
        uint256 cashAmount;
    }

    /**
     * @notice Deposit ape coin to BAYC/MAYC pool or BAKC pool
     * @param stakingInfo Detail info of the staking
     * @param _nfts Array of BAYC/MAYC NFT's with staked amounts
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's with staked amounts
     * @dev Need check User health factor > 1.
     */
    function borrowApeAndStake(
        StakingInfo calldata stakingInfo,
        ApeCoinStaking.SingleNft[] calldata _nfts,
        ApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external;

    /**
     * @notice Withdraw staked ApeCoin from the BAYC/MAYC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nfts Array of BAYC/MAYC NFT's with staked amounts
     * @dev Need check User health factor > 1.
     */
    function withdrawApeCoin(
        address nftAsset,
        ApeCoinStaking.SingleNft[] calldata _nfts
    ) external;

    /**
     * @notice Claim rewards for array of tokenIds from the BAYC/MAYC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     * @dev Need check User health factor > 1.
     */
    function claimApeCoin(address nftAsset, uint256[] calldata _nfts) external;

    /**
     * @notice Withdraw staked ApeCoin from the BAKC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's with staked amounts
     * @dev Need check User health factor > 1.
     */
    function withdrawBAKC(
        address nftAsset,
        ApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs
    ) external;

    /**
     * @notice Claim rewards for array of tokenIds from the BAYC/MAYC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's
     * @dev Need check User health factor > 1.
     */
    function claimBAKC(
        address nftAsset,
        ApeCoinStaking.PairNft[] calldata _nftPairs
    ) external;

    /**
     * @notice Unstake user Ape coin staking position and repay user debt
     * @param nftAsset Contract address of BAYC/MAYC
     * @param tokenId Token id of the ape staking position on
     * @dev Need check User health factor > 1.
     */
    function unstakeApePositionAndRepay(address nftAsset, uint256 tokenId)
        external;

    /**
     * @notice repay asset and supply asset for user
     * @param underlyingAsset Contract address of BAYC/MAYC
     * @param repayAsset Asset address to repay and supply
     * @param onBehalfOf The beneficiary of the repay and supply
     * @dev Convenient callback function for unstakeApePositionAndRepay. Only NToken of BAYC/MAYC can call this.
     */
    function repayAndSupply(
        address underlyingAsset,
        address repayAsset,
        address onBehalfOf,
        uint256 totalAmount
    ) external;

    /**
     * @notice Claim user Ape coin reward and deposit to ape compound to get cApe, then deposit cApe to Lending pool for user
     * @param nftAsset Contract address of BAYC/MAYC
     * @param users array of user address
     * @param tokenIds array of user tokenId array
     */
    function claimApeAndCompound(
        address nftAsset,
        address[] calldata users,
        uint256[][] calldata tokenIds
    ) external;

    /**
     * @notice Claim user BAKC paired Ape coin reward and deposit to ape compound to get cApe, then deposit cApe to Lending pool for user
     * @param nftAsset Contract address of BAYC/MAYC
     * @param users array of user address
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's
     */
    function claimPairedApeAndCompound(
        address nftAsset,
        address[] calldata users,
        ApeCoinStaking.PairNft[][] calldata _nftPairs
    ) external;

    /**
     * @notice get current incentive fee rate for claiming ape position reward to compound
     */
    function getApeCompoundFeeRate() external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializablePToken} from "./IInitializablePToken.sol";
import {IXTokenType} from "./IXTokenType.sol";

/**
 * @title IPToken
 *
 * @notice Defines the basic interface for an PToken.
 **/
interface IPToken is
    IERC20,
    IScaledBalanceToken,
    IInitializablePToken,
    IXTokenType
{
    /**
     * @notice Mints `amount` xTokens to `user`
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted xTokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address caller,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @notice Burns xTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the xTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The next liquidity index of the reserve
     **/
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @notice Mints xTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @notice Transfers xTokens in the event of a borrow being liquidated, in case the liquidators reclaims the xToken
     * @param from The address getting liquidated, current owner of the xTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param amount The amount getting transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount) external;

    /**
     * @notice Handles the underlying received by the xToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be xTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount) external;

    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the address of the underlying asset of this xToken (E.g. WETH for pWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the ParaSpace treasury, receiving the fees on this xToken.
     * @return Address of the ParaSpace treasury
     **/
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Returns the nonce for owner.
     * @param owner The address of the owner
     * @return The nonce of the owner
     **/
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IParaProxy} from "../interfaces/IParaProxy.sol";

/**
 * @title IPoolAddressesProvider
 *
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param implementationParams The old address of the Pool
     * @param _init The new address to call upon upgrade
     * @param _calldata The calldata input for the call
     */
    event PoolUpdated(
        IParaProxy.ProxyImplementation[] indexed implementationParams,
        address _init,
        bytes _calldata
    );

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the WETH is updated.
     * @param oldAddress The old address of the WETH
     * @param newAddress The new address of the WETH
     */
    event WETHUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event ProtocolDataProviderUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationParams The params of the implementation update
     */
    event ParaProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        IParaProxy.ProxyImplementation[] indexed implementationParams
    );

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationParams The params of the implementation update
     */
    event ParaProxyUpdated(
        bytes32 indexed id,
        address indexed proxyAddress,
        IParaProxy.ProxyImplementation[] indexed implementationParams
    );

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @dev Emitted when the marketplace registered is updated
     * @param id The identifier of the marketplace
     * @param marketplace The address of the marketplace contract
     * @param adapter The address of the marketplace adapter contract
     * @param operator The address of the marketplace transfer helper
     * @param paused Is the marketplace adapter paused
     */
    event MarketplaceUpdated(
        bytes32 indexed id,
        address indexed marketplace,
        address indexed adapter,
        address operator,
        bool paused
    );

    /**
     * @notice Returns the id of the ParaSpace market to which this contract points to.
     * @return The market id
     **/
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple ParaSpace markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress)
        external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param implementationParams Contains the implementation addresses and function selectors
     * @param _init The address of the contract or implementation to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     *                  _calldata is executed with delegatecall on _init
     **/
    function updatePoolImpl(
        IParaProxy.ProxyImplementation[] calldata implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     **/
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     **/
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Returns the address of the Wrapped ETH.
     * @return The address of the Wrapped ETH
     */
    function getWETH() external view returns (address);

    /**
     * @notice Returns the info of the marketplace.
     * @return The info of the marketplace
     */
    function getMarketplace(bytes32 id)
        external
        view
        returns (DataTypes.Marketplace memory);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setProtocolDataProvider(address newDataProvider) external;

    /**
     * @notice Updates the address of the WETH.
     * @param newWETH The address of the new WETH
     **/
    function setWETH(address newWETH) external;

    /**
     * @notice Updates the info of the marketplace.
     * @param marketplace The address of the marketplace
     *  @param adapter The contract which handles marketplace logic
     * @param operator The contract which operates users' tokens
     **/
    function setMarketplace(
        bytes32 id,
        address marketplace,
        address adapter,
        address operator,
        bool paused
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "../dependencies/yoga-labs/ApeCoinStaking.sol";
import "./INToken.sol";

interface INTokenApeStaking {
    function getBAKC() external view returns (IERC721);

    function getApeStaking() external view returns (ApeCoinStaking);

    function depositApeCoin(ApeCoinStaking.SingleNft[] calldata _nfts) external;

    function claimApeCoin(uint256[] calldata _nfts, address _recipient)
        external;

    function withdrawApeCoin(
        ApeCoinStaking.SingleNft[] calldata _nfts,
        address _recipient
    ) external;

    function depositBAKC(
        ApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external;

    function claimBAKC(
        ApeCoinStaking.PairNft[] calldata _nftPairs,
        address _recipient
    ) external;

    function withdrawBAKC(
        ApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs,
        address _apeRecipient
    ) external;

    function unstakePositionAndRepay(uint256 tokenId, address unstaker)
        external;

    function getUserApeStakingAmount(address user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "../dependencies/openzeppelin/contracts/IERC20.sol";

interface IAutoCompoundApe is IERC20 {
    /**
     * @dev Emitted during deposit()
     * @param user The address of the user deposit for
     * @param amountDeposited The amount being deposit
     * @param amountShare The share being deposit
     **/
    event Deposit(
        address indexed caller,
        address indexed user,
        uint256 amountDeposited,
        uint256 amountShare
    );

    /**
     * @dev Emitted during withdraw()
     * @param user The address of the user
     * @param amountWithdraw The amount being withdraw
     * @param amountShare The share being withdraw
     **/
    event Redeem(
        address indexed user,
        uint256 amountWithdraw,
        uint256 amountShare
    );

    /**
     * @dev Emitted during rescueERC20()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    event RescueERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice deposit an `amount` of ape into compound pool.
     * @param onBehalf The address of user will receive the pool share
     * @param amount The amount of ape to be deposit
     **/
    function deposit(address onBehalf, uint256 amount) external;

    /**
     * @notice withdraw an `amount` of ape from compound pool.
     * @param amount The amount of ape to be withdraw
     **/
    function withdraw(uint256 amount) external;

    /**
     * @notice collect ape reward in ApeCoinStaking and deposit to earn compound interest.
     **/
    function harvestAndCompound() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IXTokenType
 * @author ParallelFi
 * @notice Defines the basic interface for an IXTokenType.
 **/
enum XTokenType {
    PhantomData, // unused
    NToken,
    NTokenMoonBirds,
    NTokenUniswapV3,
    NTokenBAYC,
    NTokenMAYC,
    PToken,
    DelegationAwarePToken,
    RebasingPToken,
    PTokenAToken,
    PTokenStETH,
    PTokenSApe,
    NTokenBAKC
}

interface IXTokenType {
    /**
     * @notice return token type`of xToken
     **/
    function getXTokenType() external pure returns (XTokenType);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../openzeppelin/contracts/IERC20.sol";
import "../openzeppelin/contracts/SafeERC20.sol";
import "../openzeppelin/contracts/SafeCast.sol";
import "../openzeppelin/contracts/Ownable.sol";
import "../openzeppelin/contracts/ERC721Enumerable.sol";

/**
 * @title ApeCoin Staking Contract
 * @notice Stake ApeCoin across four different pools that release hourly rewards
 * @author HorizenLabs
 */
contract ApeCoinStaking is Ownable {
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice State for ApeCoin, BAYC, MAYC, and Pair Pools
    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    /// @notice Pool rules valid for a given duration of time.
    /// @dev All TimeRange timestamp values must represent whole hours
    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    /// @dev Convenience struct for front-end applications
    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    /// @dev Per address amount and reward tracking
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }
    mapping (address => Position) public addressPosition;

    /// @dev Struct for depositing and withdrawing from the BAYC and MAYC NFT pools
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }
    /// @dev Struct for depositing from the BAKC (Pair) pool
    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    /// @dev Struct for withdrawing from the BAKC (Pair) pool
    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    /// @dev Struct for claiming from an NFT pool
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }
    /// @dev NFT paired status.  Can be used bi-directionally (BAYC/MAYC -> BAKC) or (BAKC -> BAYC/MAYC)
    struct PairingStatus {
        uint248 tokenId;
        bool isPaired;
    }

    // @dev UI focused payload
    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }
    /// @dev Sub struct for DashboardStake
    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }
    /// @dev Placeholder for pair status, used by ApeCoin Pool
    DashboardPair private NULL_PAIR = DashboardPair(0, 0);

    /// @notice Internal ApeCoin amount for distributing staking reward claims
    IERC20 public immutable apeCoin;
    uint256 private constant APE_COIN_PRECISION = 1e18;
    uint256 private constant MIN_DEPOSIT = 1 * APE_COIN_PRECISION;
    uint256 private constant SECONDS_PER_HOUR = 3600;
    uint256 private constant SECONDS_PER_MINUTE = 60;

    uint256 constant APECOIN_POOL_ID = 0;
    uint256 constant BAYC_POOL_ID = 1;
    uint256 constant MAYC_POOL_ID = 2;
    uint256 constant BAKC_POOL_ID = 3;
    Pool[4] public pools;

    /// @dev NFT contract mapping per pool
    mapping(uint256 => ERC721Enumerable) public nftContracts;
    /// @dev poolId => tokenId => nft position
    mapping(uint256 => mapping(uint256 => Position)) public nftPosition;
    /// @dev main type pool ID: 1: BAYC 2: MAYC => main token ID => bakc token ID
    mapping(uint256 => mapping(uint256 => PairingStatus)) public mainToBakc;
    /// @dev bakc Token ID => main type pool ID: 1: BAYC 2: MAYC => main token ID
    mapping(uint256 => mapping(uint256 => PairingStatus)) public bakcToMain;

    /** Custom Events */
    event UpdatePool(
        uint256 indexed poolId,
        uint256 lastRewardedBlock,
        uint256 stakedAmount,
        uint256 accumulatedRewardsPerShare
    );
    event Deposit(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event DepositNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 tokenId
    );
    event DepositPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event WithdrawNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        address recipient,
        uint256 tokenId
    );
    event WithdrawPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );
    event ClaimRewards(
        address indexed user,
        uint256 amount,
        address recipient
    );
    event ClaimRewardsNft(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 tokenId
    );
    event ClaimRewardsPairNft(
        address indexed user,
        uint256 amount,
        uint256 mainTypePoolId,
        uint256 mainTokenId,
        uint256 bakcTokenId
    );

    error DepositMoreThanOneAPE();
    error InvalidPoolId();
    error StartMustBeGreaterThanEnd();
    error StartNotWholeHour();
    error EndNotWholeHour();
    error StartMustEqualLastEnd();
    error CallerNotOwner();
    error MainTokenNotOwnedOrPaired();
    error BAKCNotOwnedOrPaired();
    error BAKCAlreadyPaired();
    error ExceededCapAmount();
    error NotOwnerOfMain();
    error NotOwnerOfBAKC();
    error ProvidedTokensNotPaired();
    error ExceededStakedAmount();
    error NeitherTokenInPairOwnedByCaller();
    error SplitPairCantPartiallyWithdraw();
    error UncommitWrongParameters();

    /**
     * @notice Construct a new ApeCoinStaking instance
     * @param _apeCoinContractAddress The ApeCoin ERC20 contract address
     * @param _baycContractAddress The BAYC NFT contract address
     * @param _maycContractAddress The MAYC NFT contract address
     * @param _bakcContractAddress The BAKC NFT contract address
     */
    constructor(
        address _apeCoinContractAddress,
        address _baycContractAddress,
        address _maycContractAddress,
        address _bakcContractAddress
    ) {
        apeCoin = IERC20(_apeCoinContractAddress);
        nftContracts[BAYC_POOL_ID] = ERC721Enumerable(_baycContractAddress);
        nftContracts[MAYC_POOL_ID] = ERC721Enumerable(_maycContractAddress);
        nftContracts[BAKC_POOL_ID] = ERC721Enumerable(_bakcContractAddress);
    }

    // Deposit/Commit Methods

    /**
     * @notice Deposit ApeCoin to the ApeCoin Pool
     * @param _amount Amount in ApeCoin
     * @param _recipient Address the deposit it stored to
     * @dev ApeCoin deposit must be >= 1 ApeCoin
     */
    function depositApeCoin(uint256 _amount, address _recipient) public {
        if (_amount < MIN_DEPOSIT) revert DepositMoreThanOneAPE();
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[_recipient];
        _deposit(APECOIN_POOL_ID, position, _amount);

        apeCoin.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _amount, _recipient);
    }

    /**
     * @notice Deposit ApeCoin to the ApeCoin Pool
     * @param _amount Amount in ApeCoin
     * @dev Deposit on behalf of msg.sender. ApeCoin deposit must be >= 1 ApeCoin
     */
    function depositSelfApeCoin(uint256 _amount) external {
        depositApeCoin(_amount, msg.sender);
    }

    /**
     * @notice Deposit ApeCoin to the BAYC Pool
     * @param _nfts Array of SingleNft structs
     * @dev Commits 1 or more BAYC NFTs, each with an ApeCoin amount to the BAYC pool.\
     * Each BAYC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the BAYC pool cap amount.
     */
    function depositBAYC(SingleNft[] calldata _nfts) external {
        _depositNft(BAYC_POOL_ID, _nfts);
    }

    /**
     * @notice Deposit ApeCoin to the MAYC Pool
     * @param _nfts Array of SingleNft structs
     * @dev Commits 1 or more MAYC NFTs, each with an ApeCoin amount to the MAYC pool.\
     * Each MAYC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the MAYC pool cap amount.
     */
    function depositMAYC(SingleNft[] calldata _nfts) external {
        _depositNft(MAYC_POOL_ID, _nfts);
    }

    /**
     * @notice Deposit ApeCoin to the Pair Pool, where Pair = (BAYC + BAKC) or (MAYC + BAKC)
     * @param _baycPairs Array of PairNftDepositWithAmount structs
     * @param _maycPairs Array of PairNftDepositWithAmount structs
     * @dev Commits 1 or more Pairs, each with an ApeCoin amount to the Pair pool.\
     * Each BAKC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the Pair pool cap amount.\
     * Example 1: BAYC + BAKC + 1 ApeCoin:  [[0, 0, "1000000000000000000"],[]]\
     * Example 2: MAYC + BAKC + 1 ApeCoin:  [[], [0, 0, "1000000000000000000"]]\
     * Example 3: (BAYC + BAKC + 1 ApeCoin) and (MAYC + BAKC + 1 ApeCoin): [[0, 0, "1000000000000000000"], [0, 1, "1000000000000000000"]]
     */
    function depositBAKC(PairNftDepositWithAmount[] calldata _baycPairs, PairNftDepositWithAmount[] calldata _maycPairs) external {
        updatePool(BAKC_POOL_ID);
        _depositPairNft(BAYC_POOL_ID, _baycPairs);
        _depositPairNft(MAYC_POOL_ID, _maycPairs);
    }

    // Claim Rewards Methods

    /**
     * @notice Claim rewards for msg.sender and send to recipient
     * @param _recipient Address to send claim reward to
     */
    function claimApeCoin(address _recipient) public {
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[msg.sender];
        uint256 rewardsToBeClaimed = _claim(APECOIN_POOL_ID, position, _recipient);

        emit ClaimRewards(msg.sender, rewardsToBeClaimed, _recipient);
    }

    /// @notice Claim and send rewards
    function claimSelfApeCoin() external {
        claimApeCoin(msg.sender);
    }

    /**
     * @notice Claim rewards for array of BAYC NFTs and send to recipient
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimBAYC(uint256[] calldata _nfts, address _recipient) external {
        _claimNft(BAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Claim rewards for array of BAYC NFTs
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     */
    function claimSelfBAYC(uint256[] calldata _nfts) external {
        _claimNft(BAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Claim rewards for array of MAYC NFTs and send to recipient
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimMAYC(uint256[] calldata _nfts, address _recipient) external {
        _claimNft(MAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Claim rewards for array of MAYC NFTs
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     */
    function claimSelfMAYC(uint256[] calldata _nfts) external {
        _claimNft(MAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Claim rewards for array of Paired NFTs and send to recipient
     * @param _baycPairs Array of Paired BAYC NFTs owned and committed by the msg.sender
     * @param _maycPairs Array of Paired MAYC NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs, address _recipient) public {
        updatePool(BAKC_POOL_ID);
        _claimPairNft(BAYC_POOL_ID, _baycPairs, _recipient);
        _claimPairNft(MAYC_POOL_ID, _maycPairs, _recipient);
    }

    /**
     * @notice Claim rewards for array of Paired NFTs
     * @param _baycPairs Array of Paired BAYC NFTs owned and committed by the msg.sender
     * @param _maycPairs Array of Paired MAYC NFTs owned and committed by the msg.sender
     */
    function claimSelfBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs) external {
        claimBAKC(_baycPairs, _maycPairs, msg.sender);
    }

    // Uncommit/Withdraw Methods

    /**
     * @notice Withdraw staked ApeCoin from the ApeCoin pool.  Performs an automatic claim as part of the withdraw process.
     * @param _amount Amount of ApeCoin
     * @param _recipient Address to send withdraw amount and claim to
     */
    function withdrawApeCoin(uint256 _amount, address _recipient) public {
        updatePool(APECOIN_POOL_ID);

        Position storage position = addressPosition[msg.sender];
        if (_amount == position.stakedAmount) {
            uint256 rewardsToBeClaimed = _claim(APECOIN_POOL_ID, position, _recipient);
            emit ClaimRewards(msg.sender, rewardsToBeClaimed, _recipient);
        }
        _withdraw(APECOIN_POOL_ID, position, _amount);

        apeCoin.transfer(_recipient, _amount);

        emit Withdraw(msg.sender, _amount, _recipient);
    }

    /**
     * @notice Withdraw staked ApeCoin from the ApeCoin pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _amount Amount of ApeCoin
     */
    function withdrawSelfApeCoin(uint256 _amount) external {
        withdrawApeCoin(_amount, msg.sender);
    }

    /**
     * @notice Withdraw staked ApeCoin from the BAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of BAYC NFT's with staked amounts
     * @param _recipient Address to send withdraw amount and claim to
     */
    function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external {
        _withdrawNft(BAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Withdraw staked ApeCoin from the BAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of BAYC NFT's with staked amounts
     */
    function withdrawSelfBAYC(SingleNft[] calldata _nfts) external {
        _withdrawNft(BAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Withdraw staked ApeCoin from the MAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of MAYC NFT's with staked amounts
     * @param _recipient Address to send withdraw amount and claim to
     */
    function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external {
        _withdrawNft(MAYC_POOL_ID, _nfts, _recipient);
    }

    /**
     * @notice Withdraw staked ApeCoin from the MAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of MAYC NFT's with staked amounts
     */
    function withdrawSelfMAYC(SingleNft[] calldata _nfts) external {
        _withdrawNft(MAYC_POOL_ID, _nfts, msg.sender);
    }

    /**
     * @notice Withdraw staked ApeCoin from the Pair pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _baycPairs Array of Paired BAYC NFT's with staked amounts and isUncommit boolean
     * @param _maycPairs Array of Paired MAYC NFT's with staked amounts and isUncommit boolean
     * @dev if pairs have split ownership and BAKC is attempting a withdraw, the withdraw must be for the total staked amount
     */
    function withdrawBAKC(PairNftWithdrawWithAmount[] calldata _baycPairs, PairNftWithdrawWithAmount[] calldata _maycPairs) external {
        updatePool(BAKC_POOL_ID);
        _withdrawPairNft(BAYC_POOL_ID, _baycPairs);
        _withdrawPairNft(MAYC_POOL_ID, _maycPairs);
    }

    // Time Range Methods

    /**
     * @notice Add single time range with a given rewards per hour for a given pool
     * @dev In practice one Time Range will represent one quarter (defined by `_startTimestamp`and `_endTimeStamp` as whole hours)
     * where the rewards per hour is constant for a given pool.
     * @param _poolId Available pool values 0-3
     * @param _amount Total amount of ApeCoin to be distributed over the range
     * @param _startTimestamp Whole hour timestamp representation
     * @param _endTimeStamp Whole hour timestamp representation
     * @param _capPerPosition Per position cap amount determined by poolId
     */
    function addTimeRange(
        uint256 _poolId,
        uint256 _amount,
        uint256 _startTimestamp,
        uint256 _endTimeStamp,
        uint256 _capPerPosition) external onlyOwner
    {
        if (_poolId > BAKC_POOL_ID) revert InvalidPoolId();
        if (_startTimestamp >= _endTimeStamp) revert StartMustBeGreaterThanEnd();
        if (getMinute(_startTimestamp) > 0 || getSecond(_startTimestamp) > 0) revert StartNotWholeHour();
        if (getMinute(_endTimeStamp) > 0 || getSecond(_endTimeStamp) > 0) revert EndNotWholeHour();

        Pool storage pool = pools[_poolId];
        uint256 length = pool.timeRanges.length;
        if (length > 0) {
            if (_startTimestamp != pool.timeRanges[length - 1].endTimestampHour) revert StartMustEqualLastEnd();
        }

        uint256 hoursInSeconds = _endTimeStamp - _startTimestamp;
        uint256 rewardsPerHour = _amount * SECONDS_PER_HOUR / hoursInSeconds;

        TimeRange memory next = TimeRange(_startTimestamp.toUint48(), _endTimeStamp.toUint48(),
            rewardsPerHour.toUint96(), _capPerPosition.toUint96());
        pool.timeRanges.push(next);
    }

    /**
     * @notice Removes the last Time Range for a given pool.
     * @param _poolId Available pool values 0-3
     */
    function removeLastTimeRange(uint256 _poolId) external onlyOwner {
        pools[_poolId].timeRanges.pop();
    }

    /**
     * @notice Lookup method for a TimeRange struct
     * @return TimeRange A Pool's timeRanges struct by index.
     * @param _poolId Available pool values 0-3
     * @param _index Target index in a Pool's timeRanges array
     */
    function getTimeRangeBy(uint256 _poolId, uint256 _index) public view returns (TimeRange memory) {
        return pools[_poolId].timeRanges[_index];
    }

    // Pool Methods

    /**
     * @notice Lookup available rewards for a pool over a given time range
     * @return uint256 The amount of ApeCoin rewards to be distributed by pool for a given time range
     * @return uint256 The amount of time ranges
     * @param _poolId Available pool values 0-3
     * @param _from Whole hour timestamp representation
     * @param _to Whole hour timestamp representation
     */
    function rewardsBy(uint256 _poolId, uint256 _from, uint256 _to) public view returns (uint256, uint256) {
        Pool memory pool = pools[_poolId];

        uint256 currentIndex = pool.lastRewardsRangeIndex;
        if(_to < pool.timeRanges[0].startTimestampHour) return (0, currentIndex);

        while(_from > pool.timeRanges[currentIndex].endTimestampHour && _to > pool.timeRanges[currentIndex].endTimestampHour) {
        unchecked {
            ++currentIndex;
        }
        }

        uint256 rewards;
        TimeRange memory current;
        uint256 startTimestampHour;
        uint256 endTimestampHour;
        uint256 length = pool.timeRanges.length;
        for(uint256 i = currentIndex; i < length;) {
            current = pool.timeRanges[i];
            startTimestampHour = _from <= current.startTimestampHour ? current.startTimestampHour : _from;
            endTimestampHour = _to <= current.endTimestampHour ? _to : current.endTimestampHour;

            rewards = rewards + (endTimestampHour - startTimestampHour) * current.rewardsPerHour / SECONDS_PER_HOUR;

            if(_to <= endTimestampHour) {
                return (rewards, i);
            }
        unchecked {
            ++i;
        }
        }

        return (rewards, length - 1);
    }

    /**
     * @notice Updates reward variables `lastRewardedTimestampHour`, `accumulatedRewardsPerShare` and `lastRewardsRangeIndex`
     * for a given pool.
     * @param _poolId Available pool values 0-3
     */
    function updatePool(uint256 _poolId) public {
        Pool storage pool = pools[_poolId];

        if (block.timestamp < pool.timeRanges[0].startTimestampHour) return;
        if (block.timestamp <= pool.lastRewardedTimestampHour + SECONDS_PER_HOUR) return;

        uint48 lastTimestampHour = pool.timeRanges[pool.timeRanges.length-1].endTimestampHour;
        uint48 previousTimestampHour = getPreviousTimestampHour().toUint48();

        if (pool.stakedAmount == 0) {
            pool.lastRewardedTimestampHour = previousTimestampHour > lastTimestampHour ? lastTimestampHour : previousTimestampHour;
            return;
        }

        (uint256 rewards, uint256 index) = rewardsBy(_poolId, pool.lastRewardedTimestampHour, previousTimestampHour);
        if (pool.lastRewardsRangeIndex != index) {
            pool.lastRewardsRangeIndex = index.toUint16();
        }
        pool.accumulatedRewardsPerShare = (pool.accumulatedRewardsPerShare + (rewards * APE_COIN_PRECISION) / pool.stakedAmount).toUint96();
        pool.lastRewardedTimestampHour = previousTimestampHour > lastTimestampHour ? lastTimestampHour : previousTimestampHour;

        emit UpdatePool(_poolId, pool.lastRewardedTimestampHour, pool.stakedAmount, pool.accumulatedRewardsPerShare);
    }

    // Read Methods

    function getCurrentTimeRangeIndex(Pool memory pool) private view returns (uint256) {
        uint256 current = pool.lastRewardsRangeIndex;

        if (block.timestamp < pool.timeRanges[current].startTimestampHour) return current;
        for(current = pool.lastRewardsRangeIndex; current < pool.timeRanges.length; ++current) {
            TimeRange memory currentTimeRange = pool.timeRanges[current];
            if (currentTimeRange.startTimestampHour <= block.timestamp && block.timestamp <= currentTimeRange.endTimestampHour) return current;
        }
        revert("distribution ended");
    }

    /**
     * @notice Fetches a PoolUI struct (poolId, stakedAmount, currentTimeRange) for each reward pool
     * @return PoolUI for ApeCoin.
     * @return PoolUI for BAYC.
     * @return PoolUI for MAYC.
     * @return PoolUI for BAKC.
     */
    function getPoolsUI() public view returns (PoolUI memory, PoolUI memory, PoolUI memory, PoolUI memory) {
        Pool memory apeCoinPool = pools[0];
        Pool memory baycPool = pools[1];
        Pool memory maycPool = pools[2];
        Pool memory bakcPool = pools[3];
        uint256 current = getCurrentTimeRangeIndex(apeCoinPool);
        return (PoolUI(0,apeCoinPool.stakedAmount, apeCoinPool.timeRanges[current]),
        PoolUI(1,baycPool.stakedAmount, baycPool.timeRanges[current]),
        PoolUI(2,maycPool.stakedAmount, maycPool.timeRanges[current]),
        PoolUI(3,bakcPool.stakedAmount, bakcPool.timeRanges[current]));
    }

    /**
     * @notice Fetches an address total staked amount, used by voting contract
     * @return amount uint256 staked amount for all pools.
     * @param _address An Ethereum address
     */
    function stakedTotal(address _address) external view returns (uint256) {
        uint256 total = addressPosition[_address].stakedAmount;

        total += _stakedTotal(BAYC_POOL_ID, _address);
        total += _stakedTotal(MAYC_POOL_ID, _address);
        total += _stakedTotalPair(_address);

        return total;
    }

    function _stakedTotal(uint256 _poolId, address _addr) private view returns (uint256) {
        uint256 total = 0;
        uint256 nftCount = nftContracts[_poolId].balanceOf(_addr);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 tokenId = nftContracts[_poolId].tokenOfOwnerByIndex(_addr, i);
            total += nftPosition[_poolId][tokenId].stakedAmount;
        }

        return total;
    }

    function _stakedTotalPair(address _addr) private view returns (uint256) {
        uint256 total = 0;

        uint256 nftCount = nftContracts[BAYC_POOL_ID].balanceOf(_addr);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 baycTokenId = nftContracts[BAYC_POOL_ID].tokenOfOwnerByIndex(_addr, i);
            if (mainToBakc[BAYC_POOL_ID][baycTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[BAYC_POOL_ID][baycTokenId].tokenId;
                total += nftPosition[BAKC_POOL_ID][bakcTokenId].stakedAmount;
            }
        }

        nftCount = nftContracts[MAYC_POOL_ID].balanceOf(_addr);
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 maycTokenId = nftContracts[MAYC_POOL_ID].tokenOfOwnerByIndex(_addr, i);
            if (mainToBakc[MAYC_POOL_ID][maycTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[MAYC_POOL_ID][maycTokenId].tokenId;
                total += nftPosition[BAKC_POOL_ID][bakcTokenId].stakedAmount;
            }
        }

        return total;
    }

    /**
     * @notice Fetches a DashboardStake = [poolId, tokenId, deposited, unclaimed, rewards24Hrs, paired] \
     * for each pool, for an Ethereum address
     * @return dashboardStakes An array of DashboardStake structs
     * @param _address An Ethereum address
     */
    function getAllStakes(address _address) public view returns (DashboardStake[] memory) {

        DashboardStake memory apeCoinStake = getApeCoinStake(_address);
        DashboardStake[] memory baycStakes = getBaycStakes(_address);
        DashboardStake[] memory maycStakes = getMaycStakes(_address);
        DashboardStake[] memory bakcStakes = getBakcStakes(_address);
        DashboardStake[] memory splitStakes = getSplitStakes(_address);

        uint256 count = (baycStakes.length + maycStakes.length + bakcStakes.length + splitStakes.length + 1);
        DashboardStake[] memory allStakes = new DashboardStake[](count);

        uint256 offset = 0;
        allStakes[offset] = apeCoinStake;
        ++offset;

        for(uint256 i = 0; i < baycStakes.length; ++i) {
            allStakes[offset] = baycStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < maycStakes.length; ++i) {
            allStakes[offset] = maycStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < bakcStakes.length; ++i) {
            allStakes[offset] = bakcStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < splitStakes.length; ++i) {
            allStakes[offset] = splitStakes[i];
            ++offset;
        }

        return allStakes;
    }

    /**
     * @notice Fetches a DashboardStake for the ApeCoin pool
     * @return dashboardStake A dashboardStake struct
     * @param _address An Ethereum address
     */
    function getApeCoinStake(address _address) public view returns (DashboardStake memory) {
        uint256 tokenId = 0;
        uint256 deposited = addressPosition[_address].stakedAmount;
        uint256 unclaimed = deposited > 0 ? this.pendingRewards(0, _address, tokenId) : 0;
        uint256 rewards24Hrs = deposited > 0 ? _estimate24HourRewards(0, _address, 0) : 0;

        return DashboardStake(APECOIN_POOL_ID, tokenId, deposited, unclaimed, rewards24Hrs, NULL_PAIR);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the BAYC pool
     * @return dashboardStakes An array of DashboardStake structs
     */
    function getBaycStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, BAYC_POOL_ID);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the MAYC pool
     * @return dashboardStakes An array of DashboardStake structs
     */
    function getMaycStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, MAYC_POOL_ID);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the BAKC pool
     * @return dashboardStakes An array of DashboardStake structs
     */
    function getBakcStakes(address _address) public view returns (DashboardStake[] memory) {
        return _getStakes(_address, BAKC_POOL_ID);
    }

    /**
     * @notice Fetches an array of DashboardStakes for the Pair Pool when ownership is split \
     * ie (BAYC/MAYC) and BAKC in pair pool have different owners.
     * @return dashboardStakes An array of DashboardStake structs
     * @param _address An Ethereum address
     */
    function getSplitStakes(address _address) public view returns (DashboardStake[] memory) {
        uint256 baycSplits = _getSplitStakeCount(nftContracts[BAYC_POOL_ID].balanceOf(_address), _address, BAYC_POOL_ID);
        uint256 maycSplits = _getSplitStakeCount(nftContracts[MAYC_POOL_ID].balanceOf(_address), _address, MAYC_POOL_ID);
        uint256 totalSplits = baycSplits + maycSplits;

        if(totalSplits == 0) {
            return new DashboardStake[](0);
        }

        DashboardStake[] memory baycSplitStakes = _getSplitStakes(baycSplits, _address, BAYC_POOL_ID);
        DashboardStake[] memory maycSplitStakes = _getSplitStakes(maycSplits, _address, MAYC_POOL_ID);

        DashboardStake[] memory splitStakes = new DashboardStake[](totalSplits);
        uint256 offset = 0;
        for(uint256 i = 0; i < baycSplitStakes.length; ++i) {
            splitStakes[offset] = baycSplitStakes[i];
            ++offset;
        }

        for(uint256 i = 0; i < maycSplitStakes.length; ++i) {
            splitStakes[offset] = maycSplitStakes[i];
            ++offset;
        }

        return splitStakes;
    }

    function _getSplitStakes(uint256 splits, address _address, uint256 _mainPoolId) private view returns (DashboardStake[] memory) {

        DashboardStake[] memory dashboardStakes = new DashboardStake[](splits);
        uint256 counter;

        for(uint256 i = 0; i < nftContracts[_mainPoolId].balanceOf(_address); ++i) {
            uint256 mainTokenId = nftContracts[_mainPoolId].tokenOfOwnerByIndex(_address, i);
            if(mainToBakc[_mainPoolId][mainTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[_mainPoolId][mainTokenId].tokenId;
                address currentOwner = nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId);

                /* Split Pair Check*/
                if (currentOwner != _address) {
                    uint256 deposited = nftPosition[BAKC_POOL_ID][bakcTokenId].stakedAmount;
                    uint256 unclaimed = deposited > 0 ? this.pendingRewards(BAKC_POOL_ID, currentOwner, bakcTokenId) : 0;
                    uint256 rewards24Hrs = deposited > 0 ? _estimate24HourRewards(BAKC_POOL_ID, currentOwner, bakcTokenId): 0;

                    DashboardPair memory pair = NULL_PAIR;
                    if(bakcToMain[bakcTokenId][_mainPoolId].isPaired) {
                        pair = DashboardPair(bakcToMain[bakcTokenId][_mainPoolId].tokenId, _mainPoolId);
                    }

                    DashboardStake memory dashboardStake = DashboardStake(BAKC_POOL_ID, bakcTokenId, deposited, unclaimed, rewards24Hrs, pair);
                    dashboardStakes[counter] = dashboardStake;
                    ++counter;
                }
            }
        }

        return dashboardStakes;
    }

    function _getSplitStakeCount(uint256 nftCount, address _address, uint256 _mainPoolId) private view returns (uint256) {
        uint256 splitCount;
        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 mainTokenId = nftContracts[_mainPoolId].tokenOfOwnerByIndex(_address, i);
            if(mainToBakc[_mainPoolId][mainTokenId].isPaired) {
                uint256 bakcTokenId = mainToBakc[_mainPoolId][mainTokenId].tokenId;
                address currentOwner = nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId);
                if (currentOwner != _address) {
                    ++splitCount;
                }
            }
        }

        return splitCount;
    }

    function _getStakes(address _address, uint256 _poolId) private view returns (DashboardStake[] memory) {
        uint256 nftCount = nftContracts[_poolId].balanceOf(_address);
        DashboardStake[] memory dashboardStakes = nftCount > 0 ? new DashboardStake[](nftCount) : new DashboardStake[](0);

        if(nftCount == 0) {
            return dashboardStakes;
        }

        for(uint256 i = 0; i < nftCount; ++i) {
            uint256 tokenId = nftContracts[_poolId].tokenOfOwnerByIndex(_address, i);
            uint256 deposited = nftPosition[_poolId][tokenId].stakedAmount;
            uint256 unclaimed = deposited > 0 ? this.pendingRewards(_poolId, _address, tokenId) : 0;
            uint256 rewards24Hrs = deposited > 0 ? _estimate24HourRewards(_poolId, _address, tokenId): 0;

            DashboardPair memory pair = NULL_PAIR;
            if(_poolId == BAKC_POOL_ID) {
                if(bakcToMain[tokenId][BAYC_POOL_ID].isPaired) {
                    pair = DashboardPair(bakcToMain[tokenId][BAYC_POOL_ID].tokenId, BAYC_POOL_ID);
                } else if(bakcToMain[tokenId][MAYC_POOL_ID].isPaired) {
                    pair = DashboardPair(bakcToMain[tokenId][MAYC_POOL_ID].tokenId, MAYC_POOL_ID);
                }
            }

            DashboardStake memory dashboardStake = DashboardStake(_poolId, tokenId, deposited, unclaimed, rewards24Hrs, pair);
            dashboardStakes[i] = dashboardStake;
        }

        return dashboardStakes;
    }

    function _estimate24HourRewards(uint256 _poolId, address _address, uint256 _tokenId) private view returns (uint256) {
        Pool memory pool = pools[_poolId];
        Position memory position = _poolId == 0 ? addressPosition[_address]: nftPosition[_poolId][_tokenId];

        TimeRange memory rewards = getTimeRangeBy(_poolId, pool.lastRewardsRangeIndex);
        return (position.stakedAmount * uint256(rewards.rewardsPerHour) * 24) / uint256(pool.stakedAmount);
    }

    /**
     * @notice Fetches the current amount of claimable ApeCoin rewards for a given position from a given pool.
     * @return uint256 value of pending rewards
     * @param _poolId Available pool values 0-3
     * @param _address Address to lookup Position for
     * @param _tokenId An NFT id
     */
    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256) {
        Pool memory pool = pools[_poolId];
        Position memory position = _poolId == 0 ? addressPosition[_address]: nftPosition[_poolId][_tokenId];

        (uint256 rewardsSinceLastCalculated,) = rewardsBy(_poolId, pool.lastRewardedTimestampHour, getPreviousTimestampHour());
        uint256 accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare;

        if (block.timestamp > pool.lastRewardedTimestampHour + SECONDS_PER_HOUR && pool.stakedAmount != 0) {
            accumulatedRewardsPerShare = accumulatedRewardsPerShare + rewardsSinceLastCalculated * APE_COIN_PRECISION / pool.stakedAmount;
        }
        return ((position.stakedAmount * accumulatedRewardsPerShare).toInt256() - position.rewardsDebt).toUint256() / APE_COIN_PRECISION;
    }

    // Convenience methods for timestamp calculation

    /// @notice the minutes (0 to 59) of a timestamp
    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    /// @notice the seconds (0 to 59) of a timestamp
    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    /// @notice the previous whole hour of a timestamp
    function getPreviousTimestampHour() internal view returns (uint256) {
        return block.timestamp - (getMinute(block.timestamp) * 60 + getSecond(block.timestamp));
    }

    // Private Methods - shared logic
    function _deposit(uint256 _poolId, Position storage _position, uint256 _amount) private {
        Pool storage pool = pools[_poolId];

        _position.stakedAmount += _amount;
        pool.stakedAmount += _amount.toUint96();
        _position.rewardsDebt += (_amount * pool.accumulatedRewardsPerShare).toInt256();
    }

    function _depositNft(uint256 _poolId, SingleNft[] calldata _nfts) private {
        updatePool(_poolId);
        uint256 tokenId;
        uint256 amount;
        Position storage position;
        uint256 length = _nfts.length;
        uint256 totalDeposit;
        for(uint256 i; i < length;) {
            tokenId = _nfts[i].tokenId;
            position = nftPosition[_poolId][tokenId];
            if (position.stakedAmount == 0) {
                if (nftContracts[_poolId].ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
            }
            amount = _nfts[i].amount;
            _depositNftGuard(_poolId, position, amount);
            totalDeposit += amount;
            emit DepositNft(msg.sender, _poolId, amount, tokenId);
            unchecked {
                ++i;
            }
        }
        if (totalDeposit > 0) apeCoin.transferFrom(msg.sender, address(this), totalDeposit);
    }

    function _depositPairNft(uint256 mainTypePoolId, PairNftDepositWithAmount[] calldata _nfts) private {
        uint256 length = _nfts.length;
        uint256 totalDeposit;
        PairNftDepositWithAmount memory pair;
        Position storage position;
        for(uint256 i; i < length;) {
            pair = _nfts[i];
            position = nftPosition[BAKC_POOL_ID][pair.bakcTokenId];

            if(position.stakedAmount == 0) {
                if (nftContracts[mainTypePoolId].ownerOf(pair.mainTokenId) != msg.sender
                    || mainToBakc[mainTypePoolId][pair.mainTokenId].isPaired) revert MainTokenNotOwnedOrPaired();
                if (nftContracts[BAKC_POOL_ID].ownerOf(pair.bakcTokenId) != msg.sender
                    || bakcToMain[pair.bakcTokenId][mainTypePoolId].isPaired) revert BAKCNotOwnedOrPaired();

                mainToBakc[mainTypePoolId][pair.mainTokenId] = PairingStatus(pair.bakcTokenId, true);
                bakcToMain[pair.bakcTokenId][mainTypePoolId] = PairingStatus(pair.mainTokenId, true);
            } else if (pair.mainTokenId != bakcToMain[pair.bakcTokenId][mainTypePoolId].tokenId
                || pair.bakcTokenId != mainToBakc[mainTypePoolId][pair.mainTokenId].tokenId)
                revert BAKCAlreadyPaired();

            _depositNftGuard(BAKC_POOL_ID, position, pair.amount);
            totalDeposit += pair.amount;
            emit DepositPairNft(msg.sender, pair.amount, mainTypePoolId, pair.mainTokenId, pair.bakcTokenId);
            unchecked {
                ++i;
            }
        }
        if (totalDeposit > 0) apeCoin.transferFrom(msg.sender, address(this), totalDeposit);
    }

    function _depositNftGuard(uint256 _poolId, Position storage _position, uint256 _amount) private {
        if (_amount < MIN_DEPOSIT) revert DepositMoreThanOneAPE();
        if (_amount + _position.stakedAmount > pools[_poolId].timeRanges[pools[_poolId].lastRewardsRangeIndex].capPerPosition)
            revert ExceededCapAmount();

        _deposit(_poolId, _position, _amount);
    }

    function _claim(uint256 _poolId, Position storage _position, address _recipient) private returns (uint256 rewardsToBeClaimed) {
        Pool storage pool = pools[_poolId];

        int256 accumulatedApeCoins = (_position.stakedAmount * uint256(pool.accumulatedRewardsPerShare)).toInt256();
        rewardsToBeClaimed = (accumulatedApeCoins - _position.rewardsDebt).toUint256() / APE_COIN_PRECISION;

        _position.rewardsDebt = accumulatedApeCoins;

        if (rewardsToBeClaimed != 0) {
            apeCoin.transfer(_recipient, rewardsToBeClaimed);
        }
    }

    function _claimNft(uint256 _poolId, uint256[] calldata _nfts, address _recipient) private {
        updatePool(_poolId);
        uint256 tokenId;
        uint256 rewardsToBeClaimed;
        uint256 length = _nfts.length;
        for(uint256 i; i < length;) {
            tokenId = _nfts[i];
            if (nftContracts[_poolId].ownerOf(tokenId) != msg.sender) revert CallerNotOwner();
            Position storage position = nftPosition[_poolId][tokenId];
            rewardsToBeClaimed = _claim(_poolId, position, _recipient);
            emit ClaimRewardsNft(msg.sender, _poolId, rewardsToBeClaimed, tokenId);
            unchecked {
                ++i;
            }
        }
    }

    function _claimPairNft(uint256 mainTypePoolId, PairNft[] calldata _pairs, address _recipient) private {
        uint256 length = _pairs.length;
        uint256 mainTokenId;
        uint256 bakcTokenId;
        Position storage position;
        PairingStatus storage mainToSecond;
        PairingStatus storage secondToMain;
        for(uint256 i; i < length;) {
            mainTokenId = _pairs[i].mainTokenId;
            if (nftContracts[mainTypePoolId].ownerOf(mainTokenId) != msg.sender) revert NotOwnerOfMain();

            bakcTokenId = _pairs[i].bakcTokenId;
            if (nftContracts[BAKC_POOL_ID].ownerOf(bakcTokenId) != msg.sender) revert NotOwnerOfBAKC();

            mainToSecond = mainToBakc[mainTypePoolId][mainTokenId];
            secondToMain = bakcToMain[bakcTokenId][mainTypePoolId];

            if (mainToSecond.tokenId != bakcTokenId || !mainToSecond.isPaired
            || secondToMain.tokenId != mainTokenId || !secondToMain.isPaired) revert ProvidedTokensNotPaired();

            position = nftPosition[BAKC_POOL_ID][bakcTokenId];
            uint256 rewardsToBeClaimed = _claim(BAKC_POOL_ID, position, _recipient);
            emit ClaimRewardsPairNft(msg.sender, rewardsToBeClaimed, mainTypePoolId, mainTokenId, bakcTokenId);
            unchecked {
                ++i;
            }
        }
    }

    function _withdraw(uint256 _poolId, Position storage _position, uint256 _amount) private {
        if (_amount > _position.stakedAmount) revert ExceededStakedAmount();

        Pool storage pool = pools[_poolId];

        _position.stakedAmount -= _amount;
        pool.stakedAmount -= _amount.toUint96();
        _position.rewardsDebt -= (_amount * pool.accumulatedRewardsPerShare).toInt256();
    }

    function _withdrawNft(uint256 _poolId, SingleNft[] calldata _nfts, address _recipient) private {
        updatePool(_poolId);
        uint256 tokenId;
        uint256 amount;
        uint256 length = _nfts.length;
        uint256 totalWithdraw;
        Position storage position;
        for(uint256 i; i < length;) {
            tokenId = _nfts[i].tokenId;
            if (nftContracts[_poolId].ownerOf(tokenId) != msg.sender) revert CallerNotOwner();

            amount = _nfts[i].amount;
            position = nftPosition[_poolId][tokenId];
            if (amount == position.stakedAmount) {
                uint256 rewardsToBeClaimed = _claim(_poolId, position, _recipient);
                emit ClaimRewardsNft(msg.sender, _poolId, rewardsToBeClaimed, tokenId);
            }
            _withdraw(_poolId, position, amount);
            totalWithdraw += amount;
            emit WithdrawNft(msg.sender, _poolId, amount, _recipient, tokenId);
            unchecked {
                ++i;
            }
        }
        if (totalWithdraw > 0) apeCoin.transfer(_recipient, totalWithdraw);
    }

    function _withdrawPairNft(uint256 mainTypePoolId, PairNftWithdrawWithAmount[] calldata _nfts) private {
        address mainTokenOwner;
        address bakcOwner;
        PairNftWithdrawWithAmount memory pair;
        PairingStatus storage mainToSecond;
        PairingStatus storage secondToMain;
        Position storage position;
        uint256 length = _nfts.length;
        for(uint256 i; i < length;) {
            pair = _nfts[i];
            mainTokenOwner = nftContracts[mainTypePoolId].ownerOf(pair.mainTokenId);
            bakcOwner = nftContracts[BAKC_POOL_ID].ownerOf(pair.bakcTokenId);

            if (mainTokenOwner != msg.sender) {
                if (bakcOwner != msg.sender) revert NeitherTokenInPairOwnedByCaller();
            }

            mainToSecond = mainToBakc[mainTypePoolId][pair.mainTokenId];
            secondToMain = bakcToMain[pair.bakcTokenId][mainTypePoolId];

            if (mainToSecond.tokenId != pair.bakcTokenId || !mainToSecond.isPaired
            || secondToMain.tokenId != pair.mainTokenId || !secondToMain.isPaired) revert ProvidedTokensNotPaired();

            position = nftPosition[BAKC_POOL_ID][pair.bakcTokenId];
            if(!pair.isUncommit) {
                if(pair.amount == position.stakedAmount) revert UncommitWrongParameters();
            }
            if (mainTokenOwner != bakcOwner) {
                if (!pair.isUncommit) revert SplitPairCantPartiallyWithdraw();
            }

            if (pair.isUncommit) {
                uint256 rewardsToBeClaimed = _claim(BAKC_POOL_ID, position, bakcOwner);
                mainToBakc[mainTypePoolId][pair.mainTokenId] = PairingStatus(0, false);
                bakcToMain[pair.bakcTokenId][mainTypePoolId] = PairingStatus(0, false);
                emit ClaimRewardsPairNft(msg.sender, rewardsToBeClaimed, mainTypePoolId, pair.mainTokenId, pair.bakcTokenId);
            }
            uint256 finalAmountToWithdraw = pair.isUncommit ? position.stakedAmount: pair.amount;
            _withdraw(BAKC_POOL_ID, position, finalAmountToWithdraw);
            apeCoin.transfer(mainTokenOwner, finalAmountToWithdraw);
            emit WithdrawPairNft(msg.sender, finalAmountToWithdraw, mainTypePoolId, pair.mainTokenId, pair.bakcTokenId);
            unchecked {
                ++i;
            }
        }
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title PoolStorage
 *
 * @notice Contract used as storage of the Pool contract.
 * @dev It defines the storage layout of the Pool contract.
 */
contract PoolStorage {
    bytes32 constant POOL_STORAGE_POSITION =
        bytes32(uint256(keccak256("paraspace.proxy.pool.storage")) - 1);

    function poolStorage()
        internal
        pure
        returns (DataTypes.PoolStorage storage rgs)
    {
        bytes32 position = POOL_STORAGE_POSITION;
        assembly {
            rgs.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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
abstract contract ParaReentrancyGuard {
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
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    bytes32 constant RG_STORAGE_POSITION =
        bytes32(uint256(keccak256("paraspace.proxy.rg.storage")) - 1);

    struct RGStorage {
        uint256 _status;
    }

    function rgStorage() internal pure returns (RGStorage storage rgs) {
        bytes32 position = RG_STORAGE_POSITION;
        assembly {
            rgs.slot := position
        }
    }

    // constructor() {
    //     _status = _NOT_ENTERED;
    // }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        RGStorage storage rgs = rgStorage();
        // On the first call to nonReentrant, _notEntered will be true
        require(rgs._status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        rgs._status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        rgs._status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title VersionedInitializable
 * , inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract ParaVersionedInitializable {
    bytes32 constant VERSION_STORAGE_POSITION =
        bytes32(uint256(keccak256("paraspace.proxy.version.storage")) - 1);

    struct VersionStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint256 lastInitializedRevision;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool initializing;
    }

    function versionStorage()
        internal
        pure
        returns (VersionStorage storage vs)
    {
        bytes32 position = VERSION_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        VersionStorage storage vs = versionStorage();

        uint256 revision = getRevision();
        require(
            vs.initializing ||
                isConstructor() ||
                revision > vs.lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !vs.initializing;
        if (isTopLevelCall) {
            vs.initializing = true;
            vs.lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            vs.initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     **/
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    // uint256[50] private ______gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title WadRayMath library
 *
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the ParaSpace protocol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
    string public constant CALLER_NOT_BRIDGE = "6"; // 'The caller of the function is not a bridge'
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
    string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
    string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
    string public constant CALLER_NOT_XTOKEN = "11"; // 'The caller of the function is not an PToken or NToken'
    string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
    string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
    string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
    string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
    string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
    string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
    string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
    string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
    string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
    string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
    string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
    string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
    string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
    string public constant STABLE_BORROWING_NOT_ENABLED = "31"; // 'Stable borrowing is not enabled'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "35"; // 'Health factor is lesser than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
    string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "38"; // 'The requested amount is greater than the max loan size in stable rate mode'
    string public constant NO_DEBT_OF_SELECTED_TYPE = "39"; // 'For repayment of a specific type of debt, the user needs to have debt that type'
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
    string public constant NO_OUTSTANDING_STABLE_DEBT = "41"; // 'User does not have outstanding stable rate debt on this reserve'
    string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
    string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
    string public constant COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED = "46"; // 'The collateral chosen cannot be auctioned OR liquidated'
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
    string public constant SAME_BLOCK_BORROW_REPAY = "48"; // 'Borrow and repay in same block is not allowed'
    string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
    string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
    string public constant XTOKEN_SUPPLY_NOT_ZERO = "54"; // 'PToken supply is not zero'
    string public constant STABLE_DEBT_NOT_ZERO = "55"; // 'Stable debt supply is not zero'
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
    string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
    string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
    string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
    string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
    string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
    string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
    string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
    string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
    string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
    string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
    string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
    string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
    string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
    string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
    string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
    string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
    string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
    string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
    string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = "84"; // 'Invalid optimal stable to total debt ratio'
    string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
    string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
    string public constant STABLE_BORROWING_ENABLED = "88"; // 'Stable borrowing is enabled'
    string public constant SILOED_BORROWING_VIOLATION = "89"; // 'User is trying to borrow multiple assets including a siloed one'
    string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
    string public constant NOT_THE_OWNER = "91"; // user is not the owner of a given asset
    string public constant LIQUIDATION_AMOUNT_NOT_ENOUGH = "92";
    string public constant INVALID_ASSET_TYPE = "93"; // invalid asset type for action.
    string public constant INVALID_FLASH_CLAIM_RECEIVER = "94"; // invalid flash claim receiver.
    string public constant ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "95"; // ERC721 Health factor is not below the threshold. Can only liquidate ERC20.
    string public constant UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED = "96"; //underlying asset can not be transferred.
    string public constant TOKEN_TRANSFERRED_CAN_NOT_BE_SELF_ADDRESS = "97"; //token transferred can not be self address.
    string public constant INVALID_AIRDROP_CONTRACT_ADDRESS = "98"; //invalid airdrop contract address.
    string public constant INVALID_AIRDROP_PARAMETERS = "99"; //invalid airdrop parameters.
    string public constant CALL_AIRDROP_METHOD_FAILED = "100"; //call airdrop method failed.
    string public constant SUPPLIER_NOT_NTOKEN = "101"; //supplier is not the NToken contract
    string public constant CALL_MARKETPLACE_FAILED = "102"; //call marketplace failed.
    string public constant INVALID_MARKETPLACE_ID = "103"; //invalid marketplace id.
    string public constant INVALID_MARKETPLACE_ORDER = "104"; //invalid marketplace id.
    string public constant CREDIT_DOES_NOT_MATCH_ORDER = "105"; //credit doesn't match order.
    string public constant PAYNOW_NOT_ENOUGH = "106"; //paynow not enough.
    string public constant INVALID_CREDIT_SIGNATURE = "107"; //invalid credit signature.
    string public constant INVALID_ORDER_TAKER = "108"; //invalid order taker.
    string public constant MARKETPLACE_PAUSED = "109"; //marketplace paused.
    string public constant INVALID_AUCTION_RECOVERY_HEALTH_FACTOR = "110"; //invalid auction recovery health factor.
    string public constant AUCTION_ALREADY_STARTED = "111"; //auction already started.
    string public constant AUCTION_NOT_STARTED = "112"; //auction not started yet.
    string public constant AUCTION_NOT_ENABLED = "113"; //auction not enabled on the reserve.
    string public constant ERC721_HEALTH_FACTOR_NOT_ABOVE_THRESHOLD = "114"; //ERC721 Health factor is not above the threshold.
    string public constant TOKEN_IN_AUCTION = "115"; //tokenId is in auction.
    string public constant AUCTIONED_BALANCE_NOT_ZERO = "116"; //auctioned balance not zero.
    string public constant LIQUIDATOR_CAN_NOT_BE_SELF = "117"; //user can not liquidate himself.
    string public constant INVALID_RECIPIENT = "118"; //invalid recipient specified in order.
    string public constant UNIV3_NOT_ALLOWED = "119"; //flash claim is not allowed for UniswapV3.
    string public constant NTOKEN_BALANCE_EXCEEDED = "120"; //ntoken balance exceed limit.
    string public constant ORACLE_PRICE_NOT_READY = "121"; //oracle price not ready.
    string public constant SET_ORACLE_SOURCE_NOT_ALLOWED = "122"; //source of oracle not allowed to set.
    string public constant INVALID_LIQUIDATION_ASSET = "123"; //invalid liquidation asset.
    string public constant ONLY_UNIV3_ALLOWED = "124"; //only UniswapV3 allowed.
    string public constant GLOBAL_DEBT_IS_ZERO = "125"; //liquidation is not allowed when global debt is zero.
    string public constant ORACLE_PRICE_EXPIRED = "126"; //oracle price expired.
    string public constant APE_STAKING_POSITION_EXISTED = "127"; //ape staking position is existed.
    string public constant SAPE_NOT_ALLOWED = "128"; //operation is not allow for sApe.
    string public constant TOTAL_STAKING_AMOUNT_WRONG = "129"; //cash plus borrow amount not equal to total staking amount.
    string public constant NOT_THE_BAKC_OWNER = "130"; //user is not the bakc owner.
    string public constant CALLER_NOT_EOA = "131"; //The caller of the function is not an EOA account
    string public constant MAKER_SAME_AS_TAKER = "132"; //maker and taker shouldn't be the same address
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {ICollateralizableERC721} from "../../../interfaces/ICollateralizableERC721.sol";
import {IAuctionableERC721} from "../../../interfaces/IAuctionableERC721.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {SignatureChecker} from "../../../dependencies/looksrare/contracts/libraries/SignatureChecker.sol";
import {IPriceOracleSentinel} from "../../../interfaces/IPriceOracleSentinel.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IToken} from "../../../interfaces/IToken.sol";
import {XTokenType, IXTokenType} from "../../../interfaces/IXTokenType.sol";
import {Helpers} from "../helpers/Helpers.sol";
import {INonfungiblePositionManager} from "../../../dependencies/uniswap/INonfungiblePositionManager.sol";
import "../../../interfaces/INTokenApeStaking.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
    // A value of 0.9e4 results in 90%
    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

    // Minimum health factor allowed under any circumstance
    // A value of 0.95e18 results in 0.95
    uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD =
        0.95e18;

    /**
     * @dev Minimum health factor to consider a user position healthy
     * A value of 1e18 results in 1
     */
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    /**
     * @notice Validates a supply action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be supplied
     */
    function validateSupply(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amount,
        DataTypes.AssetType assetType
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);

        IXTokenType xToken = IXTokenType(reserveCache.xTokenAddress);
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            bool isActive,
            bool isFrozen,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(reserveAssetType == assetType, Errors.INVALID_ASSET_TYPE);
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(!isFrozen, Errors.RESERVE_FROZEN);

        uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();

        if (assetType == DataTypes.AssetType.ERC20) {
            require(
                supplyCap == 0 ||
                    (IPToken(reserveCache.xTokenAddress)
                        .scaledTotalSupply()
                        .rayMul(reserveCache.nextLiquidityIndex) + amount) <=
                    supplyCap *
                        (10**reserveCache.reserveConfiguration.getDecimals()),
                Errors.SUPPLY_CAP_EXCEEDED
            );
        } else if (assetType == DataTypes.AssetType.ERC721) {
            require(
                supplyCap == 0 ||
                    (INToken(reserveCache.xTokenAddress).totalSupply() +
                        amount <=
                        supplyCap),
                Errors.SUPPLY_CAP_EXCEEDED
            );
        }
    }

    /**
     * @notice Validates a supply action from NToken contract
     * @param reserveCache The cached data of the reserve
     * @param params The params of the supply
     * @param assetType the type of the asset supplied
     */
    function validateSupplyFromNToken(
        DataTypes.ReserveCache memory reserveCache,
        DataTypes.ExecuteSupplyERC721Params memory params,
        DataTypes.AssetType assetType
    ) internal view {
        require(
            msg.sender == reserveCache.xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );

        uint256 amount = params.tokenData.length;
        validateSupply(reserveCache, amount, assetType);

        for (uint256 index = 0; index < amount; index++) {
            // validate that the owner of the underlying asset is the NToken  contract
            require(
                IERC721(params.asset).ownerOf(
                    params.tokenData[index].tokenId
                ) == reserveCache.xTokenAddress,
                Errors.NOT_THE_OWNER
            );
            // validate that the owner of the ntoken that has the same tokenId is the zero address
            require(
                IERC721(reserveCache.xTokenAddress).ownerOf(
                    params.tokenData[index].tokenId
                ) == address(0x0),
                Errors.NOT_THE_OWNER
            );
        }
    }

    /**
     * @notice Validates a withdraw action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdraw(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amount,
        uint256 userBalance
    ) internal pure {
        require(amount != 0, Errors.INVALID_AMOUNT);

        require(
            amount <= userBalance,
            Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE
        );

        IXTokenType xToken = IXTokenType(reserveCache.xTokenAddress);
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function validateWithdrawERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ReserveCache memory reserveCache,
        address asset,
        uint256[] memory tokenIds
    ) internal view {
        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        INToken nToken = INToken(reserveCache.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            for (uint256 index = 0; index < tokenIds.length; index++) {
                ValidationLogic.validateForUniswapV3(
                    reservesData,
                    asset,
                    tokenIds[index],
                    true,
                    true,
                    false
                );
            }
        }
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 collateralNeededInBaseCurrency;
        uint256 userCollateralInBaseCurrency;
        uint256 userDebtInBaseCurrency;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalSupplyVariableDebt;
        uint256 reserveDecimals;
        uint256 borrowCap;
        uint256 amountInBaseCurrency;
        uint256 assetUnit;
        address siloedBorrowingAddress;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        bool borrowingEnabled;
        bool siloedBorrowingEnabled;
        DataTypes.AssetType assetType;
    }

    /**
     * @notice Validates a borrow action.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional params needed for the validation
     */
    function validateBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.ValidateBorrowParams memory params
    ) internal view {
        require(params.amount != 0, Errors.INVALID_AMOUNT);
        ValidateBorrowLocalVars memory vars;

        (
            vars.isActive,
            vars.isFrozen,
            vars.borrowingEnabled,
            vars.isPaused,
            vars.assetType
        ) = params.reserveCache.reserveConfiguration.getFlags();

        require(
            vars.assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        require(vars.isActive, Errors.RESERVE_INACTIVE);
        require(!vars.isPaused, Errors.RESERVE_PAUSED);
        require(!vars.isFrozen, Errors.RESERVE_FROZEN);
        require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);

        require(
            params.priceOracleSentinel == address(0) ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isBorrowAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        vars.reserveDecimals = params
            .reserveCache
            .reserveConfiguration
            .getDecimals();
        vars.borrowCap = params
            .reserveCache
            .reserveConfiguration
            .getBorrowCap();
        unchecked {
            vars.assetUnit = 10**vars.reserveDecimals;
        }

        if (vars.borrowCap != 0) {
            vars.totalSupplyVariableDebt = params
                .reserveCache
                .currScaledVariableDebt
                .rayMul(params.reserveCache.nextVariableBorrowIndex);

            vars.totalDebt = vars.totalSupplyVariableDebt + params.amount;

            unchecked {
                require(
                    vars.totalDebt <= vars.borrowCap * vars.assetUnit,
                    Errors.BORROW_CAP_EXCEEDED
                );
            }
        }

        (
            vars.userCollateralInBaseCurrency,
            ,
            vars.userDebtInBaseCurrency,
            vars.currentLtv,
            ,
            ,
            ,
            vars.healthFactor,
            ,

        ) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: params.userConfig,
                reservesCount: params.reservesCount,
                user: params.userAddress,
                oracle: params.oracle
            })
        );

        require(
            vars.userCollateralInBaseCurrency != 0,
            Errors.COLLATERAL_BALANCE_IS_ZERO
        );
        require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

        require(
            vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        vars.amountInBaseCurrency =
            IPriceOracleGetter(params.oracle).getAssetPrice(params.asset) *
            params.amount;
        unchecked {
            vars.amountInBaseCurrency /= vars.assetUnit;
        }

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        vars.collateralNeededInBaseCurrency = (vars.userDebtInBaseCurrency +
            vars.amountInBaseCurrency).percentDiv(vars.currentLtv); //LTV is calculated in percentage

        require(
            vars.collateralNeededInBaseCurrency <=
                vars.userCollateralInBaseCurrency,
            Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
        );
    }

    /**
     * @notice Validates a repay action.
     * @param reserveCache The cached data of the reserve
     * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
     * @param onBehalfOf The address of the user msg.sender is repaying for
     * @param variableDebt The borrow balance of the user
     */
    function validateRepay(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amountSent,
        address onBehalfOf,
        uint256 variableDebt
    ) internal view {
        require(amountSent != 0, Errors.INVALID_AMOUNT);
        require(
            amountSent != type(uint256).max || msg.sender == onBehalfOf,
            Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
        );

        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType assetType
        ) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(
            assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );

        uint256 variableDebtPreviousIndex = IScaledBalanceToken(
            reserveCache.variableDebtTokenAddress
        ).getPreviousIndex(onBehalfOf);

        require(
            (variableDebtPreviousIndex < reserveCache.nextVariableBorrowIndex),
            Errors.SAME_BLOCK_BORROW_REPAY
        );

        require((variableDebt != 0), Errors.NO_DEBT_OF_SELECTED_TYPE);
    }

    /**
     * @notice Validates the action of setting an asset as collateral.
     * @param reserveCache The cached data of the reserve
     * @param userBalance The balance of the user
     */
    function validateSetUseERC20AsCollateral(
        DataTypes.ReserveCache memory reserveCache,
        uint256 userBalance
    ) internal pure {
        require(userBalance != 0, Errors.UNDERLYING_BALANCE_ZERO);

        IXTokenType xToken = IXTokenType(reserveCache.xTokenAddress);
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function validateSetUseERC721AsCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ReserveCache memory reserveCache,
        address asset,
        uint256[] calldata tokenIds
    ) internal view {
        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType reserveAssetType
        ) = reserveCache.reserveConfiguration.getFlags();

        require(
            reserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        INToken nToken = INToken(reserveCache.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            for (uint256 index = 0; index < tokenIds.length; index++) {
                ValidationLogic.validateForUniswapV3(
                    reservesData,
                    asset,
                    tokenIds[index],
                    true,
                    true,
                    false
                );
            }
        }
    }

    struct ValidateLiquidateLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool principalReserveActive;
        bool principalReservePaused;
        bool isCollateralEnabled;
        DataTypes.AssetType collateralReserveAssetType;
    }

    struct ValidateAuctionLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool isCollateralEnabled;
        DataTypes.AssetType collateralReserveAssetType;
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateLiquidateERC20(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateLiquidateERC20Params memory params
    ) internal view {
        ValidateLiquidateLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralReserve.configuration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );

        require(
            msg.value == 0 || params.liquidationAsset == params.weth,
            Errors.INVALID_LIQUIDATION_ASSET
        );

        require(
            msg.value == 0 || msg.value >= params.actualLiquidationAmount,
            Errors.LIQUIDATION_AMOUNT_NOT_ENOUGH
        );

        IXTokenType xToken = IXTokenType(
            params.liquidationAssetReserveCache.xTokenAddress
        );
        require(
            xToken.getXTokenType() != XTokenType.PTokenSApe,
            Errors.SAPE_NOT_ALLOWED
        );

        (
            vars.principalReserveActive,
            ,
            ,
            vars.principalReservePaused,

        ) = params.liquidationAssetReserveCache.reserveConfiguration.getFlags();

        require(
            vars.collateralReserveActive && vars.principalReserveActive,
            Errors.RESERVE_INACTIVE
        );
        require(
            !vars.collateralReservePaused && !vars.principalReservePaused,
            Errors.RESERVE_PAUSED
        );

        require(
            params.priceOracleSentinel == address(0) ||
                params.healthFactor <
                MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(
            params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
        );

        vars.isCollateralEnabled =
            collateralReserve.configuration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED
        );
        require(
            params.totalDebt != 0,
            Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
        );
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateLiquidateERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateLiquidateERC721Params memory params
    ) internal view {
        require(
            params.liquidator != params.borrower,
            Errors.LIQUIDATOR_CAN_NOT_BE_SELF
        );

        ValidateLiquidateLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralReserve.configuration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );

        INToken nToken = INToken(collateralReserve.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            ValidationLogic.validateForUniswapV3(
                reservesData,
                params.collateralAsset,
                params.tokenId,
                true,
                true,
                false
            );
        }

        (
            vars.principalReserveActive,
            ,
            ,
            vars.principalReservePaused,

        ) = params.liquidationAssetReserveCache.reserveConfiguration.getFlags();

        require(
            vars.collateralReserveActive && vars.principalReserveActive,
            Errors.RESERVE_INACTIVE
        );
        require(
            !vars.collateralReservePaused && !vars.principalReservePaused,
            Errors.RESERVE_PAUSED
        );

        require(
            params.priceOracleSentinel == address(0) ||
                params.healthFactor <
                MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        if (params.auctionEnabled) {
            require(
                params.healthFactor < params.auctionRecoveryHealthFactor,
                Errors.ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
            require(
                IAuctionableERC721(params.xTokenAddress).isAuctioned(
                    params.tokenId
                ),
                Errors.AUCTION_NOT_STARTED
            );
        } else {
            require(
                params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
                Errors.ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
        }

        require(
            msg.value == 0 || params.liquidationAsset == params.weth,
            Errors.INVALID_LIQUIDATION_ASSET
        );

        require(
            params.maxLiquidationAmount >= params.actualLiquidationAmount &&
                (msg.value == 0 || msg.value >= params.maxLiquidationAmount),
            Errors.LIQUIDATION_AMOUNT_NOT_ENOUGH
        );

        vars.isCollateralEnabled =
            collateralReserve.configuration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id) &&
            ICollateralizableERC721(params.xTokenAddress).isUsedAsCollateral(
                params.tokenId
            );

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED
        );
        require(params.globalDebt != 0, Errors.GLOBAL_DEBT_IS_ZERO);
    }

    /**
     * @notice Validates the health factor of a user.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param user The user to validate health factor of
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHealthFactor(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address user,
        uint256 reservesCount,
        address oracle
    ) internal view returns (uint256, bool) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 healthFactor,
            ,
            bool hasZeroLtvCollateral
        ) = GenericLogic.calculateUserAccountData(
                reservesData,
                reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: userConfig,
                    reservesCount: reservesCount,
                    user: user,
                    oracle: oracle
                })
            );

        require(
            healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        return (healthFactor, hasZeroLtvCollateral);
    }

    function validateStartAuction(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateAuctionParams memory params
    ) internal view {
        ValidateAuctionLocalVars memory vars;

        DataTypes.ReserveConfigurationMap
            memory collateralConfiguration = collateralReserve.configuration;
        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralConfiguration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );

        require(
            IERC721(params.xTokenAddress).ownerOf(params.tokenId) ==
                params.user,
            Errors.NOT_THE_OWNER
        );

        require(vars.collateralReserveActive, Errors.RESERVE_INACTIVE);
        require(!vars.collateralReservePaused, Errors.RESERVE_PAUSED);

        require(
            collateralReserve.auctionStrategyAddress != address(0),
            Errors.AUCTION_NOT_ENABLED
        );
        require(
            !IAuctionableERC721(params.xTokenAddress).isAuctioned(
                params.tokenId
            ),
            Errors.AUCTION_ALREADY_STARTED
        );

        require(
            params.erc721HealthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
        );

        vars.isCollateralEnabled =
            collateralConfiguration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id) &&
            ICollateralizableERC721(params.xTokenAddress).isUsedAsCollateral(
                params.tokenId
            );

        //if collateral isn't enabled as collateral by user, it cannot be auctioned
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_AUCTIONED_OR_LIQUIDATED
        );
    }

    function validateEndAuction(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateAuctionParams memory params
    ) internal view {
        require(tx.origin == msg.sender, Errors.CALLER_NOT_EOA);
        ValidateAuctionLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            vars.collateralReservePaused,
            vars.collateralReserveAssetType
        ) = collateralReserve.configuration.getFlags();

        require(
            vars.collateralReserveAssetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(
            IERC721(params.xTokenAddress).ownerOf(params.tokenId) ==
                params.user,
            Errors.NOT_THE_OWNER
        );
        require(vars.collateralReserveActive, Errors.RESERVE_INACTIVE);
        require(!vars.collateralReservePaused, Errors.RESERVE_PAUSED);
        require(
            IAuctionableERC721(params.xTokenAddress).isAuctioned(
                params.tokenId
            ),
            Errors.AUCTION_NOT_STARTED
        );

        require(
            params.erc721HealthFactor >= params.auctionRecoveryHealthFactor,
            Errors.ERC721_HEALTH_FACTOR_NOT_ABOVE_THRESHOLD
        );
    }

    /**
     * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param asset The asset for which the ltv will be validated
     * @param from The user from which the xTokens are being transferred
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHFAndLtvERC20(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address asset,
        address from,
        uint256 reservesCount,
        address oracle
    ) internal view {
        DataTypes.ReserveData storage reserve = reservesData[asset];

        (, bool hasZeroLtvCollateral) = validateHealthFactor(
            reservesData,
            reservesList,
            userConfig,
            from,
            reservesCount,
            oracle
        );

        require(
            !hasZeroLtvCollateral || reserve.configuration.getLtv() == 0,
            Errors.LTV_VALIDATION_FAILED
        );
    }

    /**
     * @notice Validates the health factor of a user and the ltv of the erc721 asset being withdrawn.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param asset The asset for which the ltv will be validated
     * @param tokenIds The asset tokenIds for which the ltv will be validated
     * @param from The user from which the xTokens are being transferred
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHFAndLtvERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address asset,
        uint256[] memory tokenIds,
        address from,
        uint256 reservesCount,
        address oracle
    ) internal view {
        DataTypes.ReserveData storage reserve = reservesData[asset];

        (, bool hasZeroLtvCollateral) = validateHealthFactor(
            reservesData,
            reservesList,
            userConfig,
            from,
            reservesCount,
            oracle
        );

        if (hasZeroLtvCollateral) {
            INToken nToken = INToken(reserve.xTokenAddress);
            if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
                for (uint256 index = 0; index < tokenIds.length; index++) {
                    (uint256 assetLTV, ) = GenericLogic.getLtvAndLTForUniswapV3(
                        reservesData,
                        asset,
                        tokenIds[index],
                        reserve.configuration.getLtv(),
                        0
                    );
                    require(assetLTV == 0, Errors.LTV_VALIDATION_FAILED);
                }
            } else {
                require(
                    reserve.configuration.getLtv() == 0,
                    Errors.LTV_VALIDATION_FAILED
                );
            }
        }
    }

    /**
     * @notice Validates a transfer action.
     * @param reserve The reserve object
     */
    function validateTransferERC20(DataTypes.ReserveData storage reserve)
        internal
        view
    {
        require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a transfer action.
     * @param reserve The reserve object
     */
    function validateTransferERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ReserveData storage reserve,
        address asset,
        uint256 tokenId
    ) internal view {
        require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
        INToken nToken = INToken(reserve.xTokenAddress);
        if (nToken.getXTokenType() == XTokenType.NTokenUniswapV3) {
            ValidationLogic.validateForUniswapV3(
                reservesData,
                asset,
                tokenId,
                false,
                true,
                false
            );
        }
    }

    /**
     * @notice Validates a drop reserve action.
     * @param reservesList The addresses of all the active reserves
     * @param reserve The reserve object
     * @param asset The address of the reserve's underlying asset
     **/
    function validateDropReserve(
        mapping(uint256 => address) storage reservesList,
        DataTypes.ReserveData storage reserve,
        address asset
    ) internal view {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            reserve.id != 0 || reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        require(
            IToken(reserve.variableDebtTokenAddress).totalSupply() == 0,
            Errors.VARIABLE_DEBT_SUPPLY_NOT_ZERO
        );
        require(
            IToken(reserve.xTokenAddress).totalSupply() == 0,
            Errors.XTOKEN_SUPPLY_NOT_ZERO
        );
    }

    /**
     * @notice Validates a flash claim.
     * @param ps The pool storage
     */
    function validateFlashClaim(
        DataTypes.PoolStorage storage ps,
        address xTokenAddress,
        DataTypes.AssetType assetType,
        uint256[] memory nftTokenIds
    ) internal view {
        require(
            assetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );

        INToken nToken = INToken(xTokenAddress);
        XTokenType tokenType = nToken.getXTokenType();
        require(
            tokenType != XTokenType.NTokenUniswapV3,
            Errors.UNIV3_NOT_ALLOWED
        );

        // need check sApe status when flash claim for bayc or mayc
        if (
            tokenType == XTokenType.NTokenBAYC ||
            tokenType == XTokenType.NTokenMAYC
        ) {
            DataTypes.ReserveData storage sApeReserve = ps._reserves[
                DataTypes.SApeAddress
            ];

            (bool isActive, , , bool isPaused, ) = sApeReserve
                .configuration
                .getFlags();

            require(isActive, Errors.RESERVE_INACTIVE);
            require(!isPaused, Errors.RESERVE_PAUSED);
        }

        // only token owner can do flash claim
        for (uint256 i = 0; i < nftTokenIds.length; i++) {
            require(
                nToken.ownerOf(nftTokenIds[i]) == msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
    }

    /**
     * @notice Validates a flashloan action.
     * @param reserve The state of the reserve
     */
    function validateFlashloanSimple(DataTypes.ReserveData storage reserve)
        internal
        view
    {
        (
            bool isActive,
            ,
            ,
            bool isPaused,
            DataTypes.AssetType assetType
        ) = reserve.configuration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(
            assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
    }

    function validateBuyWithCredit(
        DataTypes.ExecuteMarketplaceParams memory params
    ) internal pure {
        require(!params.marketplace.paused, Errors.MARKETPLACE_PAUSED);
    }

    function validateAcceptBidWithCredit(
        DataTypes.ExecuteMarketplaceParams memory params
    ) internal view {
        require(!params.marketplace.paused, Errors.MARKETPLACE_PAUSED);
        require(
            keccak256(abi.encodePacked(params.orderInfo.id)) ==
                keccak256(abi.encodePacked(params.credit.orderId)),
            Errors.CREDIT_DOES_NOT_MATCH_ORDER
        );
        require(
            verifyCreditSignature(
                params.credit,
                params.orderInfo.maker,
                params.credit.v,
                params.credit.r,
                params.credit.s
            ),
            Errors.INVALID_CREDIT_SIGNATURE
        );
    }

    function verifyCreditSignature(
        DataTypes.Credit memory credit,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        return
            SignatureChecker.verify(
                hashCredit(credit),
                signer,
                v,
                r,
                s,
                getDomainSeparator()
            );
    }

    function hashCredit(DataTypes.Credit memory credit)
        private
        pure
        returns (bytes32)
    {
        bytes32 typeHash = keccak256(
            abi.encodePacked(
                "Credit(address token,uint256 amount,bytes orderId)"
            )
        );

        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodedata
        return
            keccak256(
                abi.encode(
                    typeHash,
                    credit.token,
                    credit.amount,
                    keccak256(abi.encodePacked(credit.orderId))
                )
            );
    }

    function getDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    0x88d989289235fb06c18e3c2f7ea914f41f773e86fb0073d632539f566f4df353, // keccak256("ParaSpace")
                    0x722c0e0c80487266e8c6a45e3a1a803aab23378a9c32e6ebe029d4fad7bfc965, // keccak256(bytes("1.1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    struct ValidateForUniswapV3LocalVars {
        bool token0IsActive;
        bool token0IsFrozen;
        bool token0IsPaused;
        bool token1IsActive;
        bool token1IsFrozen;
        bool token1IsPaused;
    }

    function validateForUniswapV3(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address asset,
        uint256 tokenId,
        bool checkActive,
        bool checkNotPaused,
        bool checkNotFrozen
    ) internal view {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(asset).positions(tokenId);

        ValidateForUniswapV3LocalVars memory vars;
        (
            vars.token0IsActive,
            vars.token0IsFrozen,
            ,
            vars.token0IsPaused,

        ) = reservesData[token0].configuration.getFlags();

        (
            vars.token1IsActive,
            vars.token1IsFrozen,
            ,
            vars.token1IsPaused,

        ) = reservesData[token1].configuration.getFlags();

        if (checkActive) {
            require(
                vars.token0IsActive && vars.token1IsActive,
                Errors.RESERVE_INACTIVE
            );
        }
        if (checkNotPaused) {
            require(
                !vars.token0IsPaused && !vars.token1IsPaused,
                Errors.RESERVE_PAUSED
            );
        }
        if (checkNotFrozen) {
            require(
                !vars.token0IsFrozen && !vars.token1IsFrozen,
                Errors.RESERVE_FROZEN
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveConfiguration} from "./ReserveConfiguration.sol";

/**
 * @title UserConfiguration library
 *
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    uint256 internal constant BORROWING_MASK =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant COLLATERAL_MASK =
        0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

    /**
     * @notice Sets if the user is borrowing the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param borrowing True if the user is borrowing the reserve, false otherwise
     **/
    function setBorrowing(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool borrowing
    ) internal {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            uint256 bit = 1 << (reserveIndex << 1);
            if (borrowing) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
     **/
    function setUsingAsCollateral(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool usingAsCollateral
    ) internal {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            uint256 bit = 1 << ((reserveIndex << 1) + 1);
            if (usingAsCollateral) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Returns if a user has been using the reserve for borrowing or as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
     **/
    function isUsingAsCollateralOrBorrowing(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            return (self.data >> (reserveIndex << 1)) & 3 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve for borrowing
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing, false otherwise
     **/
    function isBorrowing(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            return (self.data >> (reserveIndex << 1)) & 1 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve as collateral, false otherwise
     **/
    function isUsingAsCollateral(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            return (self.data >> ((reserveIndex << 1) + 1)) & 1 != 0;
        }
    }

    /**
     * @notice Checks if a user has been supplying only one reserve as collateral
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     **/
    function isUsingAsCollateralOne(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        uint256 collateralData = self.data & COLLATERAL_MASK;
        return
            collateralData != 0 && (collateralData & (collateralData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been supplying any reserve as collateral
     * @param self The configuration object
     * @return True if the user has been supplying as collateral any reserve, false otherwise
     **/
    function isUsingAsCollateralAny(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data & COLLATERAL_MASK != 0;
    }

    /**
     * @notice Checks if a user has been borrowing only one asset
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     **/
    function isBorrowingOne(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        uint256 borrowingData = self.data & BORROWING_MASK;
        return borrowingData != 0 && (borrowingData & (borrowingData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been borrowing from any reserve
     * @param self The configuration object
     * @return True if the user has been borrowing any reserve, false otherwise
     **/
    function isBorrowingAny(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data & BORROWING_MASK != 0;
    }

    /**
     * @notice Checks if a user has not been using any reserve for borrowing or supply
     * @param self The configuration object
     * @return True if the user has not been borrowing or supplying any reserve, false otherwise
     **/
    function isEmpty(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data == 0;
    }

    /**
     * @notice Returns the siloed borrowing state for the user
     * @param self The configuration object
     * @param reservesData The data of all the reserves
     * @param reservesList The reserve list
     * @return True if the user has borrowed a siloed asset, false otherwise
     * @return The address of the only borrowed asset
     */
    function getSiloedBorrowingState(
        DataTypes.UserConfigurationMap memory self,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList
    ) internal view returns (bool, address) {
        if (isBorrowingOne(self)) {
            uint256 assetId = _getFirstAssetIdByMask(self, BORROWING_MASK);
            address assetAddress = reservesList[assetId];
            if (reservesData[assetAddress].configuration.getSiloedBorrowing()) {
                return (true, assetAddress);
            }
        }

        return (false, address(0));
    }

    /**
     * @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
     * @param self The configuration object
     * @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
     */
    function _getFirstAssetIdByMask(
        DataTypes.UserConfigurationMap memory self,
        uint256 mask
    ) internal pure returns (uint256) {
        unchecked {
            uint256 bitmapData = self.data & mask;
            uint256 firstAssetPosition = bitmapData & ~(bitmapData - 1);
            uint256 id;

            while ((firstAssetPosition >>= 2) != 0) {
                id += 1;
            }
            return id;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721Enumerable} from "../../../dependencies/openzeppelin/contracts/IERC721Enumerable.sol";
import {Math} from "../../../dependencies/openzeppelin/contracts/Math.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {ICollateralizableERC721} from "../../../interfaces/ICollateralizableERC721.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {INonfungiblePositionManager} from "../../../dependencies/uniswap/INonfungiblePositionManager.sol";
import {XTokenType} from "../../../interfaces/IXTokenType.sol";

/**
 * @title GenericLogic library
 *
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    struct CalculateUserAccountDataVars {
        uint256 assetPrice;
        uint256 assetUnit;
        DataTypes.ReserveConfigurationMap reserveConfiguration;
        uint256 userBalanceInBaseCurrency;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 i;
        uint256 healthFactor;
        uint256 erc721HealthFactor;
        uint256 totalERC721CollateralInBaseCurrency;
        uint256 payableDebtByERC20Assets;
        uint256 totalCollateralInBaseCurrency;
        uint256 totalDebtInBaseCurrency;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        uint256 avgERC721LiquidationThreshold;
        address currentReserveAddress;
        bool hasZeroLtvCollateral;
        address xTokenAddress;
        XTokenType xTokenType;
    }

    /**
     * @notice Calculates the user data across the reserves.
     * @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
     * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for the calculation
     * @return The total collateral of the user in the base currency used by the price feed
     * @return The total ERC721 collateral of the user in the base currency used by the price feed
     * @return The total debt of the user in the base currency used by the price feed
     * @return The average ltv of the user
     * @return The average liquidation threshold of the user
     * @return The payable debt by ERC20 assets
     * @return The health factor of the user
     * @return The ERC721 health factor of the user
     * @return True if the ltv is zero, false otherwise
     **/
    function calculateUserAccountData(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.CalculateUserAccountDataParams memory params
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        if (params.userConfig.isEmpty()) {
            return (
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                type(uint256).max,
                type(uint256).max,
                false
            );
        }

        CalculateUserAccountDataVars memory vars;

        while (vars.i < params.reservesCount) {
            if (!params.userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            vars.currentReserveAddress = reservesList[vars.i];

            if (vars.currentReserveAddress == address(0)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            DataTypes.ReserveData storage currentReserve = reservesData[
                vars.currentReserveAddress
            ];

            vars.reserveConfiguration = currentReserve.configuration;

            (
                vars.ltv,
                vars.liquidationThreshold,
                vars.liquidationBonus,
                vars.decimals,

            ) = vars.reserveConfiguration.getParams();

            unchecked {
                vars.assetUnit = 10**vars.decimals;
            }

            vars.xTokenAddress = currentReserve.xTokenAddress;

            if (
                vars.reserveConfiguration.getAssetType() ==
                DataTypes.AssetType.ERC20
            ) {
                vars.assetPrice = _getAssetPrice(
                    params.oracle,
                    vars.currentReserveAddress
                );

                if (
                    (vars.liquidationThreshold != 0) &&
                    params.userConfig.isUsingAsCollateral(vars.i)
                ) {
                    vars.userBalanceInBaseCurrency = _getUserBalanceForERC20(
                        params.user,
                        currentReserve,
                        vars.xTokenAddress,
                        vars.assetUnit,
                        vars.assetPrice
                    );

                    vars.payableDebtByERC20Assets += vars
                        .userBalanceInBaseCurrency
                        .percentDiv(vars.liquidationBonus);

                    vars.liquidationThreshold =
                        vars.userBalanceInBaseCurrency *
                        (vars.liquidationThreshold);
                    vars.avgLtv += vars.userBalanceInBaseCurrency * vars.ltv;

                    vars.totalCollateralInBaseCurrency += vars
                        .userBalanceInBaseCurrency;

                    if (vars.ltv == 0) {
                        vars.hasZeroLtvCollateral = true;
                    }

                    vars.avgLiquidationThreshold += vars.liquidationThreshold;
                }

                if (params.userConfig.isBorrowing(vars.i)) {
                    vars.totalDebtInBaseCurrency += _getUserDebtInBaseCurrency(
                        params.user,
                        currentReserve,
                        vars.assetPrice,
                        vars.assetUnit
                    );
                }
            } else {
                if (
                    (vars.liquidationThreshold != 0) &&
                    params.userConfig.isUsingAsCollateral(vars.i)
                ) {
                    vars.xTokenType = INToken(vars.xTokenAddress)
                        .getXTokenType();
                    if (vars.xTokenType == XTokenType.NTokenUniswapV3) {
                        (
                            vars.userBalanceInBaseCurrency,
                            vars.ltv,
                            vars.liquidationThreshold
                        ) = _getUserBalanceForUniswapV3(
                            reservesData,
                            params,
                            vars
                        );
                    } else {
                        vars
                            .userBalanceInBaseCurrency = _getUserBalanceForERC721(
                            params,
                            vars
                        );

                        vars.liquidationThreshold =
                            vars.userBalanceInBaseCurrency *
                            vars.liquidationThreshold;

                        if (vars.ltv == 0) {
                            vars.hasZeroLtvCollateral = true;
                        }

                        vars.ltv = vars.userBalanceInBaseCurrency * vars.ltv;
                    }

                    vars.avgERC721LiquidationThreshold += vars
                        .liquidationThreshold;
                    vars.totalERC721CollateralInBaseCurrency += vars
                        .userBalanceInBaseCurrency;
                    vars.totalCollateralInBaseCurrency += vars
                        .userBalanceInBaseCurrency;
                    vars.avgLtv += vars.ltv;
                    vars.avgLiquidationThreshold += vars.liquidationThreshold;
                }
            }

            unchecked {
                ++vars.i;
            }
        }

        unchecked {
            vars.avgLtv = vars.totalCollateralInBaseCurrency != 0
                ? vars.avgLtv / vars.totalCollateralInBaseCurrency
                : 0;
            vars.avgLiquidationThreshold = vars.totalCollateralInBaseCurrency !=
                0
                ? vars.avgLiquidationThreshold /
                    vars.totalCollateralInBaseCurrency
                : 0;

            vars.avgERC721LiquidationThreshold = vars
                .totalERC721CollateralInBaseCurrency != 0
                ? vars.avgERC721LiquidationThreshold /
                    vars.totalERC721CollateralInBaseCurrency
                : 0;
        }

        vars.healthFactor = (vars.totalDebtInBaseCurrency == 0)
            ? type(uint256).max
            : (
                vars.totalCollateralInBaseCurrency.percentMul(
                    vars.avgLiquidationThreshold
                )
            ).wadDiv(vars.totalDebtInBaseCurrency);

        vars.erc721HealthFactor = (vars.totalDebtInBaseCurrency == 0 ||
            vars.payableDebtByERC20Assets >= vars.totalDebtInBaseCurrency)
            ? type(uint256).max
            : (
                vars.totalERC721CollateralInBaseCurrency.percentMul(
                    vars.avgERC721LiquidationThreshold
                )
            ).wadDiv(
                    vars.totalDebtInBaseCurrency - vars.payableDebtByERC20Assets
                );

        return (
            vars.totalCollateralInBaseCurrency,
            vars.totalERC721CollateralInBaseCurrency,
            vars.totalDebtInBaseCurrency,
            vars.avgLtv,
            vars.avgLiquidationThreshold,
            vars.avgERC721LiquidationThreshold,
            vars.payableDebtByERC20Assets,
            vars.healthFactor,
            vars.erc721HealthFactor,
            vars.hasZeroLtvCollateral
        );
    }

    /**
     * @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
     * and the average Loan To Value
     * @param totalCollateralInBaseCurrency The total collateral in the base currency used by the price feed
     * @param totalDebtInBaseCurrency The total borrow balance in the base currency used by the price feed
     * @param ltv The average loan to value
     * @return The amount available to borrow in the base currency of the used by the price feed
     **/
    function calculateAvailableBorrows(
        uint256 totalCollateralInBaseCurrency,
        uint256 totalDebtInBaseCurrency,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency
            .percentMul(ltv);

        if (availableBorrowsInBaseCurrency < totalDebtInBaseCurrency) {
            return 0;
        }

        availableBorrowsInBaseCurrency =
            availableBorrowsInBaseCurrency -
            totalDebtInBaseCurrency;
        return availableBorrowsInBaseCurrency;
    }

    /**
     * @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
     * @dev This fetches the `balanceOf` of the stable and variable debt tokens for the user. For gas reasons, the
     * variable debt balance is calculated by fetching `scaledBalancesOf` normalized debt, which is cheaper than
     * fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total debt of the user is being calculated
     * @param assetPrice The price of the asset for which the total debt of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total debt of the user normalized to the base currency
     **/
    function _getUserDebtInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        // fetching variable debt
        uint256 userTotalDebt = IScaledBalanceToken(
            reserve.variableDebtTokenAddress
        ).scaledBalanceOf(user);
        if (userTotalDebt != 0) {
            userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt());
            userTotalDebt = assetPrice * userTotalDebt;

            unchecked {
                return userTotalDebt / assetUnit;
            }
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculates total xToken balance of the user in the based currency used by the price oracle
     * @dev For gas reasons, the xToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
     * is cheaper than fetching `balanceOf`
     * @return totalValue The total xToken balance of the user normalized to the base currency of the price oracle
     **/
    function _getUserBalanceForERC721(
        DataTypes.CalculateUserAccountDataParams memory params,
        CalculateUserAccountDataVars memory vars
    ) private view returns (uint256 totalValue) {
        INToken nToken = INToken(vars.xTokenAddress);
        bool isAtomicPrice = nToken.getAtomicPricingConfig();
        if (isAtomicPrice) {
            uint256 totalBalance = nToken.balanceOf(params.user);

            for (uint256 index = 0; index < totalBalance; index++) {
                uint256 tokenId = nToken.tokenOfOwnerByIndex(
                    params.user,
                    index
                );
                if (
                    ICollateralizableERC721(vars.xTokenAddress)
                        .isUsedAsCollateral(tokenId)
                ) {
                    totalValue += _getTokenPrice(
                        params.oracle,
                        vars.currentReserveAddress,
                        tokenId
                    );
                }
            }
        } else {
            uint256 assetPrice = _getAssetPrice(
                params.oracle,
                vars.currentReserveAddress
            );
            totalValue =
                ICollateralizableERC721(vars.xTokenAddress)
                    .collateralizedBalanceOf(params.user) *
                assetPrice;
        }
    }

    function getLtvAndLTForUniswapV3(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address uniswapV3Manager,
        uint256 tokenId,
        uint256 collectionLTV,
        uint256 collectionLiquidationThreshold
    ) internal view returns (uint256 ltv, uint256 liquidationThreshold) {
        (
            ,
            ,
            address token0,
            address token1,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(uniswapV3Manager).positions(tokenId);

        DataTypes.ReserveConfigurationMap memory token0Configs = reservesData[
            token0
        ].configuration;
        DataTypes.ReserveConfigurationMap memory token1Configs = reservesData[
            token1
        ].configuration;

        (
            uint256 token0Ltv,
            uint256 token0LiquidationThreshold,
            ,
            ,

        ) = token0Configs.getParams();
        (
            uint256 token1Ltv,
            uint256 token1LiquidationThreshold,
            ,
            ,

        ) = token1Configs.getParams();

        ltv = Math.min(Math.min(token0Ltv, token1Ltv), collectionLTV);
        liquidationThreshold = Math.min(
            Math.min(token0LiquidationThreshold, token1LiquidationThreshold),
            collectionLiquidationThreshold
        );
    }

    function _getUserBalanceForUniswapV3(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.CalculateUserAccountDataParams memory params,
        CalculateUserAccountDataVars memory vars
    )
        private
        view
        returns (
            uint256 totalValue,
            uint256 totalLTV,
            uint256 totalLiquidationThreshold
        )
    {
        uint256 totalBalance = INToken(vars.xTokenAddress).balanceOf(
            params.user
        );
        for (uint256 index = 0; index < totalBalance; index++) {
            uint256 tokenId = IERC721Enumerable(vars.xTokenAddress)
                .tokenOfOwnerByIndex(params.user, index);
            if (
                ICollateralizableERC721(vars.xTokenAddress).isUsedAsCollateral(
                    tokenId
                )
            ) {
                uint256 tokenPrice = _getTokenPrice(
                    params.oracle,
                    vars.currentReserveAddress,
                    tokenId
                );
                totalValue += tokenPrice;

                (
                    uint256 tmpLTV,
                    uint256 tmpLiquidationThreshold
                ) = getLtvAndLTForUniswapV3(
                        reservesData,
                        vars.currentReserveAddress,
                        tokenId,
                        vars.ltv,
                        vars.liquidationThreshold
                    );

                if (tmpLTV == 0) {
                    vars.hasZeroLtvCollateral = true;
                }

                totalLTV += tmpLTV * tokenPrice;
                totalLiquidationThreshold +=
                    tmpLiquidationThreshold *
                    tokenPrice;
            }
        }
    }

    /**
     * @notice Calculates total xToken balance of the user in the based currency used by the price oracle
     * @dev For gas reasons, the xToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
     * is cheaper than fetching `balanceOf`
     * @param user The address of the user
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total xToken balance of the user normalized to the base currency of the price oracle
     **/
    function _getUserBalanceForERC20(
        address user,
        DataTypes.ReserveData storage reserve,
        address xTokenAddress,
        uint256 assetUnit,
        uint256 assetPrice
    ) private view returns (uint256) {
        uint256 balance;

        uint256 normalizedIncome = reserve.getNormalizedIncome();
        balance =
            (
                IScaledBalanceToken(xTokenAddress).scaledBalanceOf(user).rayMul(
                    normalizedIncome
                )
            ) *
            assetPrice;

        unchecked {
            return (balance / assetUnit);
        }
    }

    function _getAssetPrice(address oracle, address currentReserveAddress)
        internal
        view
        returns (uint256)
    {
        return IPriceOracleGetter(oracle).getAssetPrice(currentReserveAddress);
    }

    function _getTokenPrice(
        address oracle,
        address currentReserveAddress,
        uint256 tokenId
    ) internal view returns (uint256) {
        return
            IPriceOracleGetter(oracle).getTokenPrice(
                currentReserveAddress,
                tokenId
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    // See `IPool` for descriptions
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @notice Returns the ongoing normalized income for the reserve.
     * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
     * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return The normalized income, expressed in ray
     **/
    function getNormalizedIncome(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (uint256)
    {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.liquidityIndex;
        } else {
            return
                MathUtils
                    .calculateLinearInterest(
                        reserve.currentLiquidityRate,
                        timestamp
                    )
                    .rayMul(reserve.liquidityIndex);
        }
    }

    /**
     * @notice Returns the ongoing normalized variable debt for the reserve.
     * @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
     * @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
     * @param reserve The reserve object
     * @return The normalized variable debt, expressed in ray
     **/
    function getNormalizedDebt(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (uint256)
    {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.variableBorrowIndex;
        } else {
            return
                MathUtils
                    .calculateCompoundedInterest(
                        reserve.currentVariableBorrowRate,
                        timestamp
                    )
                    .rayMul(reserve.variableBorrowIndex);
        }
    }

    /**
     * @notice Updates the liquidity cumulative index and the variable borrow index.
     * @param reserve The reserve object
     * @param reserveCache The caching layer for the reserve data
     **/
    function updateState(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
    ) internal {
        _updateIndexes(reserve, reserveCache);
        _accrueToTreasury(reserve, reserveCache);
    }

    /**
     * @notice Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example
     * to accumulate the flashloan fee to the reserve, and spread it between all the suppliers.
     * @param reserve The reserve object
     * @param totalLiquidity The total liquidity available in the reserve
     * @param amount The amount to accumulate
     * @return The next liquidity index of the reserve
     **/
    function cumulateToLiquidityIndex(
        DataTypes.ReserveData storage reserve,
        uint256 totalLiquidity,
        uint256 amount
    ) internal returns (uint256) {
        //next liquidity index is calculated this way: `((amount / totalLiquidity) + 1) * liquidityIndex`
        //division `amount / totalLiquidity` done in ray for precision
        uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) +
            WadRayMath.RAY).rayMul(reserve.liquidityIndex);
        reserve.liquidityIndex = result.toUint128();
        return result;
    }

    /**
     * @notice Initializes a reserve.
     * @param reserve The reserve object
     * @param xTokenAddress The address of the overlying xtoken contract
     * @param variableDebtTokenAddress The address of the overlying variable debt token contract
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function init(
        DataTypes.ReserveData storage reserve,
        address xTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress,
        address auctionStrategyAddress
    ) internal {
        require(
            reserve.xTokenAddress == address(0),
            Errors.RESERVE_ALREADY_INITIALIZED
        );

        reserve.liquidityIndex = uint128(WadRayMath.RAY);
        reserve.variableBorrowIndex = uint128(WadRayMath.RAY);
        reserve.xTokenAddress = xTokenAddress;
        reserve.variableDebtTokenAddress = variableDebtTokenAddress;
        reserve.interestRateStrategyAddress = interestRateStrategyAddress;
        reserve.auctionStrategyAddress = auctionStrategyAddress;
    }

    struct UpdateInterestRatesLocalVars {
        uint256 nextLiquidityRate;
        uint256 nextVariableRate;
        uint256 totalVariableDebt;
    }

    /**
     * @notice Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate.
     * @param reserve The reserve reserve to be updated
     * @param reserveCache The caching layer for the reserve data
     * @param reserveAddress The address of the reserve to be updated
     * @param liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
     * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
     **/
    function updateInterestRates(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache,
        address reserveAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) internal {
        UpdateInterestRatesLocalVars memory vars;

        vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
            reserveCache.nextVariableBorrowIndex
        );

        (
            vars.nextLiquidityRate,
            vars.nextVariableRate
        ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress)
            .calculateInterestRates(
                DataTypes.CalculateInterestRatesParams({
                    liquidityAdded: liquidityAdded,
                    liquidityTaken: liquidityTaken,
                    totalVariableDebt: vars.totalVariableDebt,
                    reserveFactor: reserveCache.reserveFactor,
                    reserve: reserveAddress,
                    xToken: reserveCache.xTokenAddress
                })
            );

        reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
        reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

        emit ReserveDataUpdated(
            reserveAddress,
            vars.nextLiquidityRate,
            vars.nextVariableRate,
            reserveCache.nextLiquidityIndex,
            reserveCache.nextVariableBorrowIndex
        );
    }

    struct AccrueToTreasuryLocalVars {
        uint256 prevTotalVariableDebt;
        uint256 currTotalVariableDebt;
        uint256 totalDebtAccrued;
        uint256 amountToMint;
    }

    /**
     * @notice Mints part of the repaid interest to the reserve treasury as a function of the reserve factor for the
     * specific asset.
     * @param reserve The reserve to be updated
     * @param reserveCache The caching layer for the reserve data
     **/
    function _accrueToTreasury(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
    ) internal {
        AccrueToTreasuryLocalVars memory vars;

        if (reserveCache.reserveFactor == 0) {
            return;
        }

        //calculate the total variable debt at moment of the last interaction
        vars.prevTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
            reserveCache.currVariableBorrowIndex
        );

        //calculate the new total variable debt after accumulation of the interest on the index
        vars.currTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
            reserveCache.nextVariableBorrowIndex
        );

        //debt accrued is the sum of the current debt minus the sum of the debt at the last update
        vars.totalDebtAccrued =
            vars.currTotalVariableDebt -
            vars.prevTotalVariableDebt;

        vars.amountToMint = vars.totalDebtAccrued.percentMul(
            reserveCache.reserveFactor
        );

        if (vars.amountToMint != 0) {
            reserve.accruedToTreasury += vars
                .amountToMint
                .rayDiv(reserveCache.nextLiquidityIndex)
                .toUint128();
        }
    }

    /**
     * @notice Updates the reserve indexes and the timestamp of the update.
     * @param reserve The reserve reserve to be updated
     * @param reserveCache The cache layer holding the cached protocol data
     **/
    function _updateIndexes(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
    ) internal {
        reserveCache.nextLiquidityIndex = reserveCache.currLiquidityIndex;
        reserveCache.nextVariableBorrowIndex = reserveCache
            .currVariableBorrowIndex;

        //only cumulating if there is any income being produced
        if (reserveCache.currLiquidityRate != 0) {
            uint256 cumulatedLiquidityInterest = MathUtils
                .calculateLinearInterest(
                    reserveCache.currLiquidityRate,
                    reserveCache.reserveLastUpdateTimestamp
                );
            reserveCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                reserveCache.currLiquidityIndex
            );
            reserve.liquidityIndex = reserveCache
                .nextLiquidityIndex
                .toUint128();

            //as the liquidity rate might come only from stable rate loans, we need to ensure
            //that there is actual variable debt before accumulating
            if (reserveCache.currScaledVariableDebt != 0) {
                uint256 cumulatedVariableBorrowInterest = MathUtils
                    .calculateCompoundedInterest(
                        reserveCache.currVariableBorrowRate,
                        reserveCache.reserveLastUpdateTimestamp
                    );
                reserveCache
                    .nextVariableBorrowIndex = cumulatedVariableBorrowInterest
                    .rayMul(reserveCache.currVariableBorrowIndex);
                reserve.variableBorrowIndex = reserveCache
                    .nextVariableBorrowIndex
                    .toUint128();
            }
        }

        //solium-disable-next-line
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
     * @notice Creates a cache object to avoid repeated storage reads and external contract calls when updating state and
     * interest rates.
     * @param reserve The reserve object for which the cache will be filled
     * @return The cache object
     */
    function cache(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (DataTypes.ReserveCache memory)
    {
        DataTypes.ReserveCache memory reserveCache;

        reserveCache.reserveConfiguration = reserve.configuration;
        reserveCache.xTokenAddress = reserve.xTokenAddress;

        (, , , , DataTypes.AssetType reserveAssetType) = reserveCache
            .reserveConfiguration
            .getFlags();

        if (reserveAssetType == DataTypes.AssetType.ERC20) {
            reserveCache.reserveFactor = reserveCache
                .reserveConfiguration
                .getReserveFactor();
            reserveCache.currLiquidityIndex = reserve.liquidityIndex;
            reserveCache.currVariableBorrowIndex = reserve.variableBorrowIndex;
            reserveCache.currLiquidityRate = reserve.currentLiquidityRate;
            reserveCache.currVariableBorrowRate = reserve
                .currentVariableBorrowRate;

            reserveCache.variableDebtTokenAddress = reserve
                .variableDebtTokenAddress;

            reserveCache.reserveLastUpdateTimestamp = reserve
                .lastUpdateTimestamp;

            reserveCache.currScaledVariableDebt = reserveCache
                .nextScaledVariableDebt = IVariableDebtToken(
                reserveCache.variableDebtTokenAddress
            ).scaledTotalSupply();
        }

        return reserveCache;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Helpers} from "../helpers/Helpers.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title BorrowLogic library
 *
 * @notice Implements the base logic for all the actions related to borrowing
 */
library BorrowLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using GPv2SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // See `IPool` for descriptions
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referralCode
    );
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool usePTokens
    );

    /**
     * @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
     * ParaSpace protocol proportionally to their collateralization power.
     * @dev  Emits the `Borrow()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the borrow function
     */
    function executeBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteBorrowParams memory params
    ) public {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateBorrow(
            reservesData,
            reservesList,
            DataTypes.ValidateBorrowParams({
                reserveCache: reserveCache,
                userConfig: userConfig,
                asset: params.asset,
                userAddress: params.onBehalfOf,
                amount: params.amount,
                reservesCount: params.reservesCount,
                oracle: params.oracle,
                priceOracleSentinel: params.priceOracleSentinel
            })
        );

        bool isFirstBorrowing = false;

        (
            isFirstBorrowing,
            reserveCache.nextScaledVariableDebt
        ) = IVariableDebtToken(reserveCache.variableDebtTokenAddress).mint(
            params.user,
            params.onBehalfOf,
            params.amount,
            reserveCache.nextVariableBorrowIndex
        );

        if (isFirstBorrowing) {
            userConfig.setBorrowing(reserve.id, true);
        }

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            0,
            params.releaseUnderlying ? params.amount : 0
        );

        if (params.releaseUnderlying) {
            IPToken(reserveCache.xTokenAddress).transferUnderlyingTo(
                params.user,
                params.amount
            );
        }

        emit Borrow(
            params.asset,
            params.user,
            params.onBehalfOf,
            params.amount,
            reserve.currentVariableBorrowRate,
            params.referralCode
        );
    }

    /**
     * @notice Implements the repay feature. Repaying transfers the underlying back to the xToken and clears the
     * equivalent amount of debt for the user by burning the corresponding debt token.
     * @dev  Emits the `Repay()` event
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the repay function
     * @return The actual amount being repaid
     */
    function executeRepay(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteRepayParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();
        reserve.updateState(reserveCache);

        uint256 variableDebt = Helpers.getUserCurrentDebt(
            params.onBehalfOf,
            reserveCache.variableDebtTokenAddress
        );

        ValidationLogic.validateRepay(
            reserveCache,
            params.amount,
            params.onBehalfOf,
            variableDebt
        );

        uint256 paybackAmount = variableDebt;

        // Allows a user to repay with xTokens without leaving dust from interest.
        if (params.usePTokens && params.amount == type(uint256).max) {
            params.amount = IPToken(reserveCache.xTokenAddress).balanceOf(
                msg.sender
            );
        }

        // if amount user is sending is less than payback amount (debt), update the payback amount to what the user is sending
        if (params.amount < paybackAmount) {
            paybackAmount = params.amount;
        }

        reserveCache.nextScaledVariableDebt = IVariableDebtToken(
            reserveCache.variableDebtTokenAddress
        ).burn(
                params.onBehalfOf,
                paybackAmount,
                reserveCache.nextVariableBorrowIndex
            );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            params.usePTokens ? 0 : paybackAmount,
            0
        );

        if (variableDebt - paybackAmount == 0) {
            userConfig.setBorrowing(reserve.id, false);
        }

        if (params.usePTokens) {
            IPToken(reserveCache.xTokenAddress).burn(
                msg.sender,
                reserveCache.xTokenAddress,
                paybackAmount,
                reserveCache.nextLiquidityIndex
            );
        } else {
            // send paybackAmount from user to reserve
            IERC20(params.asset).safeTransferFrom(
                msg.sender,
                reserveCache.xTokenAddress,
                paybackAmount
            );
            IPToken(reserveCache.xTokenAddress).handleRepayment(
                msg.sender,
                paybackAmount
            );
        }

        emit Repay(
            params.asset,
            params.onBehalfOf,
            msg.sender,
            paybackAmount,
            params.usePTokens
        );

        return paybackAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title PercentageMath library
 *
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256 result)
    {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(
                or(
                    iszero(percentage),
                    iszero(
                        gt(
                            value,
                            div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage)
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            result := div(
                add(mul(value, percentage), HALF_PERCENTAGE_FACTOR),
                PERCENTAGE_FACTOR
            )
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256 result)
    {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(
                iszero(percentage),
                iszero(
                    iszero(
                        gt(
                            value,
                            div(
                                sub(not(0), div(percentage, 2)),
                                PERCENTAGE_FACTOR
                            )
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            result := div(
                add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)),
                percentage
            )
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {INonfungiblePositionManager} from "../../../dependencies/uniswap/INonfungiblePositionManager.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {INTokenApeStaking} from "../../../interfaces/INTokenApeStaking.sol";
import {ICollateralizableERC721} from "../../../interfaces/ICollateralizableERC721.sol";
import {IAuctionableERC721} from "../../../interfaces/IAuctionableERC721.sol";
import {Errors} from "../helpers/Errors.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {XTokenType} from "../../../interfaces/IXTokenType.sol";
import {INTokenUniswapV3} from "../../../interfaces/INTokenUniswapV3.sol";

/**
 * @title SupplyLogic library
 *
 * @notice Implements the base logic for supply/withdraw
 */
library SupplyLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using GPv2SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    // See `IPool` for descriptions
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );
    event SupplyERC721(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        DataTypes.ERC721SupplyParams[] tokenData,
        uint16 indexed referralCode,
        bool fromNToken
    );

    event WithdrawERC721(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256[] tokenIds
    );

    /**
     * @notice Implements the supply feature. Through `supply()`, users supply assets to the ParaSpace protocol.
     * @dev Emits the `Supply()` event.
     * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
     * collateral.
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the supply function
     */
    function executeSupply(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateSupply(
            reserveCache,
            params.amount,
            DataTypes.AssetType.ERC20
        );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            params.amount,
            0
        );

        IERC20(params.asset).safeTransferFrom(
            params.payer,
            reserveCache.xTokenAddress,
            params.amount
        );

        bool isFirstSupply = IPToken(reserveCache.xTokenAddress).mint(
            msg.sender,
            params.onBehalfOf,
            params.amount,
            reserveCache.nextLiquidityIndex
        );

        if (isFirstSupply) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(
                params.asset,
                params.onBehalfOf
            );
        }

        emit Supply(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.amount,
            params.referralCode
        );
    }

    function executeSupplyERC721Base(
        uint16 reserveId,
        address nTokenAddress,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyERC721Params memory params
    ) internal {
        //currently don't need to update state for erc721
        //reserve.updateState(reserveCache);

        (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        ) = INToken(nTokenAddress).mint(params.onBehalfOf, params.tokenData);
        bool isFirstSupplyCollateral = (oldCollateralizedBalance == 0 &&
            newCollateralizedBalance > 0);
        if (isFirstSupplyCollateral) {
            userConfig.setUsingAsCollateral(reserveId, true);
            emit ReserveUsedAsCollateralEnabled(
                params.asset,
                params.onBehalfOf
            );
        }
    }

    /**
     * @notice Implements the supplyERC721 feature.
     * @dev Emits the `SupplyERC721()` event.
     * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
     * collateral.
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the supply function
     */
    function executeSupplyERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyERC721Params memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSupply(
            reserveCache,
            params.tokenData.length,
            DataTypes.AssetType.ERC721
        );

        XTokenType tokenType = INToken(reserveCache.xTokenAddress)
            .getXTokenType();
        if (tokenType == XTokenType.NTokenUniswapV3) {
            for (uint256 index = 0; index < params.tokenData.length; index++) {
                ValidationLogic.validateForUniswapV3(
                    reservesData,
                    params.asset,
                    params.tokenData[index].tokenId,
                    true,
                    true,
                    true
                );
            }
        }
        if (
            tokenType == XTokenType.NTokenBAYC ||
            tokenType == XTokenType.NTokenMAYC
        ) {
            uint16 sApeReserveId = reservesData[DataTypes.SApeAddress].id;
            bool currentStatus = userConfig.isUsingAsCollateral(sApeReserveId);
            if (!currentStatus) {
                userConfig.setUsingAsCollateral(sApeReserveId, true);
                emit ReserveUsedAsCollateralEnabled(
                    DataTypes.SApeAddress,
                    params.onBehalfOf
                );
            }
        }
        for (uint256 index = 0; index < params.tokenData.length; index++) {
            IERC721(params.asset).safeTransferFrom(
                params.payer,
                reserveCache.xTokenAddress,
                params.tokenData[index].tokenId
            );
        }

        executeSupplyERC721Base(
            reserve.id,
            reserveCache.xTokenAddress,
            userConfig,
            params
        );

        emit SupplyERC721(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.tokenData,
            params.referralCode,
            false
        );
    }

    /**
     * @notice Implements the executeSupplyERC721FromNToken feature.
     * @dev Emits the `SupplyERC721()` event with fromNToken as true.
     * @dev same as `executeSupplyERC721` whereas no need to transfer the underlying nft
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the supply function
     */
    function executeSupplyERC721FromNToken(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyERC721Params memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSupplyFromNToken(
            reserveCache,
            params,
            DataTypes.AssetType.ERC721
        );

        executeSupplyERC721Base(
            reserve.id,
            reserveCache.xTokenAddress,
            userConfig,
            params
        );

        emit SupplyERC721(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.tokenData,
            params.referralCode,
            true
        );
    }

    /**
     * @notice Implements the withdraw feature. Through `withdraw()`, users redeem their xTokens for the underlying asset
     * previously supplied in the ParaSpace protocol.
     * @dev Emits the `Withdraw()` event.
     * @dev If the user withdraws everything, `ReserveUsedAsCollateralDisabled()` is emitted.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the withdraw function
     * @return The actual amount withdrawn
     */
    function executeWithdraw(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteWithdrawParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        uint256 userBalance = IPToken(reserveCache.xTokenAddress)
            .scaledBalanceOf(msg.sender)
            .rayMul(reserveCache.nextLiquidityIndex);

        uint256 amountToWithdraw = params.amount;

        if (params.amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        ValidationLogic.validateWithdraw(
            reserveCache,
            amountToWithdraw,
            userBalance
        );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            0,
            amountToWithdraw
        );

        IPToken(reserveCache.xTokenAddress).burn(
            msg.sender,
            params.to,
            amountToWithdraw,
            reserveCache.nextLiquidityIndex
        );

        if (userConfig.isUsingAsCollateral(reserve.id)) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC20(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    msg.sender,
                    params.reservesCount,
                    params.oracle
                );
            }

            if (amountToWithdraw == userBalance) {
                userConfig.setUsingAsCollateral(reserve.id, false);
                emit ReserveUsedAsCollateralDisabled(params.asset, msg.sender);
            }
        }

        emit Withdraw(params.asset, msg.sender, params.to, amountToWithdraw);

        return amountToWithdraw;
    }

    function executeWithdrawERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteWithdrawERC721Params memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        //currently don't need to update state for erc721
        //reserve.updateState(reserveCache);

        ValidationLogic.validateWithdrawERC721(
            reservesData,
            reserveCache,
            params.asset,
            params.tokenIds
        );
        uint256 amountToWithdraw = params.tokenIds.length;

        (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        ) = INToken(reserveCache.xTokenAddress).burn(
                msg.sender,
                params.to,
                params.tokenIds
            );

        bool isWithdrawCollateral = (newCollateralizedBalance <
            oldCollateralizedBalance);
        if (isWithdrawCollateral) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC721(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    params.tokenIds,
                    msg.sender,
                    params.reservesCount,
                    params.oracle
                );
            }

            if (newCollateralizedBalance == 0) {
                userConfig.setUsingAsCollateral(reserve.id, false);
                emit ReserveUsedAsCollateralDisabled(params.asset, msg.sender);
            }
        }

        emit WithdrawERC721(
            params.asset,
            msg.sender,
            params.to,
            params.tokenIds
        );

        return amountToWithdraw;
    }

    function executeDecreaseUniswapV3Liquidity(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteDecreaseUniswapV3LiquidityParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        //currently don't need to update state for erc721
        //reserve.updateState(reserveCache);

        INToken nToken = INToken(reserveCache.xTokenAddress);
        require(
            nToken.getXTokenType() == XTokenType.NTokenUniswapV3,
            Errors.ONLY_UNIV3_ALLOWED
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = params.tokenId;
        ValidationLogic.validateWithdrawERC721(
            reservesData,
            reserveCache,
            params.asset,
            tokenIds
        );

        INTokenUniswapV3(reserveCache.xTokenAddress).decreaseUniswapV3Liquidity(
                params.user,
                params.tokenId,
                params.liquidityDecrease,
                params.amount0Min,
                params.amount1Min,
                params.receiveEthAsWeth
            );

        bool isUsedAsCollateral = ICollateralizableERC721(
            reserveCache.xTokenAddress
        ).isUsedAsCollateral(params.tokenId);
        if (isUsedAsCollateral) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC721(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    tokenIds,
                    params.user,
                    params.reservesCount,
                    params.oracle
                );
            }
        }
    }

    /**
     * @notice Validates a transfer of PTokens. The sender is subjected to health factor validation to avoid
     * collateralization constraints violation.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event for the `to` account, if the asset is being activated as
     * collateral.
     * @dev In case the `from` user transfers everything, `ReserveUsedAsCollateralDisabled()` is emitted for `from`.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the finalizeTransfer function
     */
    function executeFinalizeTransferERC20(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.FinalizeTransferParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        ValidationLogic.validateTransferERC20(reserve);

        uint256 reserveId = reserve.id;

        if (params.from != params.to && params.amount != 0) {
            DataTypes.UserConfigurationMap storage fromConfig = usersConfig[
                params.from
            ];

            if (fromConfig.isUsingAsCollateral(reserveId)) {
                if (fromConfig.isBorrowingAny()) {
                    ValidationLogic.validateHFAndLtvERC20(
                        reservesData,
                        reservesList,
                        usersConfig[params.from],
                        params.asset,
                        params.from,
                        params.reservesCount,
                        params.oracle
                    );
                }

                if (params.balanceFromBefore == params.amount) {
                    fromConfig.setUsingAsCollateral(reserveId, false);
                    emit ReserveUsedAsCollateralDisabled(
                        params.asset,
                        params.from
                    );
                }

                if (params.balanceToBefore == 0) {
                    DataTypes.UserConfigurationMap
                        storage toConfig = usersConfig[params.to];

                    toConfig.setUsingAsCollateral(reserveId, true);
                    emit ReserveUsedAsCollateralEnabled(
                        params.asset,
                        params.to
                    );
                }
            }
        }
    }

    /**
     * @notice Validates a transfer of NTokens. The sender is subjected to health factor validation to avoid
     * collateralization constraints violation.
     * @dev In case the `from` user transfers everything, `ReserveUsedAsCollateralDisabled()` is emitted for `from`.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the finalizeTransfer function
     */
    function executeFinalizeTransferERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.FinalizeTransferERC721Params memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        ValidationLogic.validateTransferERC721(
            reservesData,
            reserve,
            params.asset,
            params.tokenId
        );

        uint256 reserveId = reserve.id;

        if (params.from != params.to) {
            DataTypes.UserConfigurationMap storage fromConfig = usersConfig[
                params.from
            ];

            if (params.usedAsCollateral) {
                if (fromConfig.isBorrowingAny()) {
                    uint256[] memory tokenIds = new uint256[](1);
                    tokenIds[0] = params.tokenId;
                    ValidationLogic.validateHFAndLtvERC721(
                        reservesData,
                        reservesList,
                        usersConfig[params.from],
                        params.asset,
                        tokenIds,
                        params.from,
                        params.reservesCount,
                        params.oracle
                    );
                }

                if (params.balanceFromBefore == 1) {
                    fromConfig.setUsingAsCollateral(reserveId, false);
                    emit ReserveUsedAsCollateralDisabled(
                        params.asset,
                        params.from
                    );
                }
            }
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to activate or deactivate an asset as
     * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
     * checks to ensure collateralization.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
     * @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param useAsCollateral True if the user wants to set the asset as collateral, false otherwise
     * @param reservesCount The number of initialized reserves
     * @param priceOracle The address of the price oracle
     */
    function executeUseERC20AsCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        bool useAsCollateral,
        uint256 reservesCount,
        address priceOracle
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        uint256 userBalance = IERC20(reserveCache.xTokenAddress).balanceOf(
            msg.sender
        );

        ValidationLogic.validateSetUseERC20AsCollateral(
            reserveCache,
            userBalance
        );

        if (useAsCollateral == userConfig.isUsingAsCollateral(reserve.id))
            return;

        if (useAsCollateral) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
        } else {
            userConfig.setUsingAsCollateral(reserve.id, false);
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtvERC20(
                    reservesData,
                    reservesList,
                    userConfig,
                    asset,
                    msg.sender,
                    reservesCount,
                    priceOracle
                );
            }

            emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to activate an asset as
     * collateral at any point in time.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
     * @param reservesData The state of all the reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param tokenIds The ids of the supplied ERC721 token
     * @param sender The address of NFT owner
     */
    function executeCollateralizeERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        uint256[] calldata tokenIds,
        address sender
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSetUseERC721AsCollateral(
            reservesData,
            reserveCache,
            asset,
            tokenIds
        );

        (
            uint256 oldCollateralizedBalance,
            uint256 newCollateralizedBalance
        ) = ICollateralizableERC721(reserveCache.xTokenAddress)
                .batchSetIsUsedAsCollateral(tokenIds, true, sender);

        if (oldCollateralizedBalance == 0 && newCollateralizedBalance != 0) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(asset, sender);
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to deactivate an asset as
     * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
     * checks to ensure collateralization.
     * @dev Emits the `ReserveUsedAsCollateralDisabled()` event if the asset can be deactivated as collateral.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param tokenIds The ids of the supplied ERC721 token
     * @param sender The address of NFT owner
     * @param reservesCount The number of initialized reserves
     * @param priceOracle The address of the price oracle
     */
    function executeUncollateralizeERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        uint256[] calldata tokenIds,
        address sender,
        uint256 reservesCount,
        address priceOracle
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        ValidationLogic.validateSetUseERC721AsCollateral(
            reservesData,
            reserveCache,
            asset,
            tokenIds
        );

        (
            uint256 oldCollateralizedBalance,
            uint256 newCollateralizedBalance
        ) = ICollateralizableERC721(reserveCache.xTokenAddress)
                .batchSetIsUsedAsCollateral(tokenIds, false, sender);

        if (oldCollateralizedBalance == newCollateralizedBalance) {
            return;
        }

        if (newCollateralizedBalance == 0) {
            userConfig.setUsingAsCollateral(reserve.id, false);
            emit ReserveUsedAsCollateralDisabled(asset, sender);
        }
        if (userConfig.isBorrowingAny()) {
            ValidationLogic.validateHFAndLtvERC721(
                reservesData,
                reservesList,
                userConfig,
                asset,
                tokenIds,
                sender,
                reservesCount,
                priceOracle
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
pragma solidity 0.8.10;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;
import {ApeCoinStaking} from "../../../dependencies/yoga-labs/ApeCoinStaking.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../../interfaces/IPool.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {PercentageMath} from "../../libraries/math/PercentageMath.sol";
import "./MintableERC721Logic.sol";
import "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import "../../../interfaces/INToken.sol";

/**
 * @title ApeStakingLogic library
 *
 * @notice Implements the base logic for ApeStaking
 */
library ApeStakingLogic {
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;
    using SafeCast for uint256;

    uint256 constant BAYC_POOL_ID = 1;
    uint256 constant MAYC_POOL_ID = 2;
    uint256 constant BAKC_POOL_ID = 3;

    struct APEStakingParameter {
        uint256 unstakeIncentive;
    }
    event UnstakeApeIncentiveUpdated(uint256 oldValue, uint256 newValue);

    /**
     * @notice withdraw Ape coin staking position from ApeCoinStaking
     * @param _apeCoinStaking ApeCoinStaking contract address
     * @param poolId identify whether BAYC or MAYC paired with BAKC
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's with staked amounts
     * @param _apeRecipient the receiver of ape coin
     */
    function withdrawBAKC(
        ApeCoinStaking _apeCoinStaking,
        uint256 poolId,
        ApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs,
        address _apeRecipient
    ) external {
        ApeCoinStaking.PairNftWithdrawWithAmount[]
            memory _otherPairs = new ApeCoinStaking.PairNftWithdrawWithAmount[](
                0
            );

        uint256 beforeBalance = _apeCoinStaking.apeCoin().balanceOf(
            address(this)
        );
        if (poolId == BAYC_POOL_ID) {
            _apeCoinStaking.withdrawBAKC(_nftPairs, _otherPairs);
        } else {
            _apeCoinStaking.withdrawBAKC(_otherPairs, _nftPairs);
        }
        uint256 afterBalance = _apeCoinStaking.apeCoin().balanceOf(
            address(this)
        );

        _apeCoinStaking.apeCoin().safeTransfer(
            _apeRecipient,
            afterBalance - beforeBalance
        );
    }

    /**
     * @notice undate incentive percentage for unstakePositionAndRepay
     * @param stakingParameter storage for Ape staking
     * @param incentive new incentive percentage
     */
    function executeSetUnstakeApeIncentive(
        APEStakingParameter storage stakingParameter,
        uint256 incentive
    ) external {
        require(
            incentive < PercentageMath.HALF_PERCENTAGE_FACTOR,
            "Value Too High"
        );
        uint256 oldValue = stakingParameter.unstakeIncentive;
        if (oldValue != incentive) {
            stakingParameter.unstakeIncentive = incentive;
            emit UnstakeApeIncentiveUpdated(oldValue, incentive);
        }
    }

    struct UnstakeAndRepayParams {
        IPool POOL;
        ApeCoinStaking _apeCoinStaking;
        address _underlyingAsset;
        uint256 poolId;
        uint256 tokenId;
        address incentiveReceiver;
        address bakcNToken;
    }

    /**
     * @notice Unstake Ape coin staking position and repay user debt
     * @param _owners The state of ownership for nToken
     * @param stakingParameter storage for Ape staking
     * @param params The additional parameters needed to execute this function
     */
    function executeUnstakePositionAndRepay(
        mapping(uint256 => address) storage _owners,
        APEStakingParameter storage stakingParameter,
        UnstakeAndRepayParams memory params
    ) external {
        if (
            IERC721(params._underlyingAsset).ownerOf(params.tokenId) !=
            address(this)
        ) {
            return;
        }
        address positionOwner = _owners[params.tokenId];
        IERC20 _apeCoin = params._apeCoinStaking.apeCoin();
        uint256 balanceBefore = _apeCoin.balanceOf(address(this));

        //1 unstake all position
        {
            //1.1 unstake Main pool position
            (uint256 stakedAmount, ) = params._apeCoinStaking.nftPosition(
                params.poolId,
                params.tokenId
            );
            if (stakedAmount > 0) {
                ApeCoinStaking.SingleNft[]
                    memory nfts = new ApeCoinStaking.SingleNft[](1);
                nfts[0].tokenId = params.tokenId.toUint32();
                nfts[0].amount = stakedAmount.toUint224();
                if (params.poolId == BAYC_POOL_ID) {
                    params._apeCoinStaking.withdrawBAYC(nfts, address(this));
                } else {
                    params._apeCoinStaking.withdrawMAYC(nfts, address(this));
                }
            }
            //1.2 unstake bakc pool position
            (uint256 bakcTokenId, bool isPaired) = params
                ._apeCoinStaking
                .mainToBakc(params.poolId, params.tokenId);
            if (isPaired) {
                (stakedAmount, ) = params._apeCoinStaking.nftPosition(
                    BAKC_POOL_ID,
                    bakcTokenId
                );
                if (stakedAmount > 0) {
                    ApeCoinStaking.PairNftWithdrawWithAmount[]
                        memory _nftPairs = new ApeCoinStaking.PairNftWithdrawWithAmount[](
                            1
                        );
                    _nftPairs[0].mainTokenId = params.tokenId.toUint32();
                    _nftPairs[0].bakcTokenId = bakcTokenId.toUint32();
                    _nftPairs[0].amount = stakedAmount.toUint184();
                    _nftPairs[0].isUncommit = true;
                    ApeCoinStaking.PairNftWithdrawWithAmount[]
                        memory _otherPairs = new ApeCoinStaking.PairNftWithdrawWithAmount[](
                            0
                        );

                    uint256 bakcBeforeBalance = _apeCoin.balanceOf(
                        params.bakcNToken
                    );
                    if (params.poolId == BAYC_POOL_ID) {
                        params._apeCoinStaking.withdrawBAKC(
                            _nftPairs,
                            _otherPairs
                        );
                    } else {
                        params._apeCoinStaking.withdrawBAKC(
                            _otherPairs,
                            _nftPairs
                        );
                    }
                    uint256 bakcAfterBalance = _apeCoin.balanceOf(
                        params.bakcNToken
                    );
                    uint256 balanceDiff = bakcAfterBalance - bakcBeforeBalance;
                    if (balanceDiff > 0) {
                        address bakcOwner = INToken(params.bakcNToken).ownerOf(
                            bakcTokenId
                        );
                        _apeCoin.safeTransferFrom(
                            params.bakcNToken,
                            bakcOwner,
                            balanceDiff
                        );
                    }
                }
            }
        }

        uint256 unstakedAmount = _apeCoin.balanceOf(address(this)) -
            balanceBefore;
        if (unstakedAmount == 0) {
            return;
        }
        //2 send incentive to caller
        if (params.incentiveReceiver != address(0)) {
            uint256 unstakeIncentive = stakingParameter.unstakeIncentive;
            if (unstakeIncentive > 0) {
                uint256 incentiveAmount = unstakedAmount.percentMul(
                    unstakeIncentive
                );
                _apeCoin.safeTransfer(
                    params.incentiveReceiver,
                    incentiveAmount
                );
                unstakedAmount = unstakedAmount - incentiveAmount;
            }
        }

        //3 repay and supply
        params.POOL.repayAndSupply(
            params._underlyingAsset,
            address(_apeCoin),
            positionOwner,
            unstakedAmount
        );
    }

    /**
     * @notice get user total ape staking position
     * @param userState The user state of nToken
     * @param ownedTokens The ownership mapping state of nNtoken
     * @param user User address
     * @param poolId identify whether BAYC pool or MAYC pool
     * @param _apeCoinStaking ApeCoinStaking contract address
     */
    function getUserTotalStakingAmount(
        mapping(address => UserState) storage userState,
        mapping(address => mapping(uint256 => uint256)) storage ownedTokens,
        address _underlyingAsset,
        address user,
        uint256 poolId,
        ApeCoinStaking _apeCoinStaking
    ) external view returns (uint256) {
        uint256 totalBalance = uint256(userState[user].balance);
        uint256 totalAmount;
        for (uint256 index = 0; index < totalBalance; index++) {
            uint256 tokenId = ownedTokens[user][index];
            totalAmount += getTokenIdStakingAmount(
                _underlyingAsset,
                poolId,
                _apeCoinStaking,
                tokenId
            );
        }

        return totalAmount;
    }

    /**
     * @notice get ape staking position for a tokenId
     * @param poolId identify whether BAYC pool or MAYC pool
     * @param _apeCoinStaking ApeCoinStaking contract address
     * @param tokenId specified the tokenId for the position
     */
    function getTokenIdStakingAmount(
        address _underlyingAsset,
        uint256 poolId,
        ApeCoinStaking _apeCoinStaking,
        uint256 tokenId
    ) public view returns (uint256) {
        if (IERC721(_underlyingAsset).ownerOf(tokenId) != address(this)) {
            return 0;
        }
        (uint256 apeStakedAmount, ) = _apeCoinStaking.nftPosition(
            poolId,
            tokenId
        );

        uint256 apeReward = _apeCoinStaking.pendingRewards(
            poolId,
            address(this),
            tokenId
        );

        (uint256 bakcTokenId, bool isPaired) = _apeCoinStaking.mainToBakc(
            poolId,
            tokenId
        );

        if (isPaired) {
            (uint256 bakcStakedAmount, ) = _apeCoinStaking.nftPosition(
                BAKC_POOL_ID,
                bakcTokenId
            );
            apeStakedAmount += bakcStakedAmount;
        }

        return apeStakedAmount + apeReward;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.10;

/**
 * @dev Collection of functions related to the address type
 */
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.10;

import "./IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.10;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.10;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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

pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.10;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IScaledBalanceToken
 *
 * @notice Defines the basic interface for a scaledbalance token.
 **/
interface IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted scaled balance tokens
     * @param value The amount being minted (user entered amount + balance increase from interest)
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param index The next liquidity index of the reserve
     **/
    event Mint(
        address indexed caller,
        address indexed onBehalfOf,
        uint256 value,
        uint256 balanceIncrease,
        uint256 index
    );

    /**
     * @dev Emitted after scaled balance tokens are burned
     * @param from The address from which the scaled tokens will be burned
     * @param target The address that will receive the underlying, if any
     * @param value The amount being burned (user entered amount - balance increase from interest)
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param index The next liquidity index of the reserve
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 balanceIncrease,
        uint256 index
    );

    /**
     * @notice Returns the scaled balance of the user.
     * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
     * at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);

    /**
     * @notice Returns last index interest was accrued to the user's balance
     * @param user The address of the user
     * @return The last index interest was accrued to the user's balance, expressed in ray
     **/
    function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IRewardController} from "./IRewardController.sol";
import {IPool} from "./IPool.sol";

/**
 * @title IInitializablePToken
 *
 * @notice Interface for the initialize function on PToken
 **/
interface IInitializablePToken {
    /**
     * @dev Emitted when an pToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this pToken
     * @param pTokenDecimals The decimals of the underlying
     * @param pTokenName The name of the pToken
     * @param pTokenSymbol The symbol of the pToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 pTokenDecimals,
        string pTokenName,
        string pTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the pToken
     * @param pool The pool contract that is initializing this contract
     * @param treasury The address of the ParaSpace treasury, receiving the fees on this pToken
     * @param underlyingAsset The address of the underlying asset of this pToken (E.g. WETH for pWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param pTokenDecimals The decimals of the pToken, same as the underlying asset's
     * @param pTokenName The name of the pToken
     * @param pTokenSymbol The symbol of the pToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address treasury,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 pTokenDecimals,
        string calldata pTokenName,
        string calldata pTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IRewardController
 *
 * @notice Defines the basic interface for an ParaSpace Incentives Controller.
 **/
interface IRewardController {
    /**
     * @dev Emitted during `handleAction`, `claimRewards` and `claimRewardsOnBehalf`
     * @param user The user that accrued rewards
     * @param amount The amount of accrued rewards
     */
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during `claimRewards` and `claimRewardsOnBehalf`
     * @param user The address that accrued rewards
     * @param to The address that will be receiving the rewards
     * @param claimer The address that performed the claim
     * @param amount The amount of rewards
     */
    event RewardsClaimed(
        address indexed user,
        address indexed to,
        address indexed claimer,
        uint256 amount
    );

    /**
     * @dev Emitted during `setClaimer`
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @notice Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index
     * @return The emission per second
     * @return The last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * LEGACY **************************
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );

    /**
     * @notice Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @notice Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @notice Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        address[] calldata assets,
        uint256[] calldata emissionsPerSecond
    ) external;

    /**
     * @notice Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the pool
     * @param totalSupply The total supply of the asset in the pool
     **/
    function handleAction(
        address asset,
        uint256 totalSupply,
        uint256 userBalance
    ) external;

    /**
     * @notice Returns the total of rewards of a user, already accrued + not yet accrued
     * @param assets The assets to accumulate rewards for
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @notice Claims reward for a user, on the assets of the pool, accumulating the pending rewards
     * @param assets The assets to accumulate rewards for
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Claims reward for a user on its behalf, on the assets of the pool, accumulating the pending rewards.
     * @dev The caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets The assets to accumulate rewards for
     * @param amount The amount of rewards to claim
     * @param user The address to check and claim rewards
     * @param to The address that will be receiving the rewards
     * @return The amount of rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @notice Returns the unclaimed rewards of the user
     * @param user The address of the user
     * @return The unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the user index for a specific asset
     * @param user The address of the user
     * @param asset The asset to incentivize
     * @return The user index for the asset
     */
    function getUserAssetData(address user, address asset)
        external
        view
        returns (uint256);

    /**
     * @notice for backward compatibility with previous implementation of the Incentives controller
     * @return The address of the reward token
     */
    function REWARD_TOKEN() external view returns (address);

    /**
     * @notice for backward compatibility with previous implementation of the Incentives controller
     * @return The precision used in the incentives controller
     */
    function PRECISION() external view returns (uint8);

    /**
     * @dev Gets the distribution end timestamp of the emissions
     */
    function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolCore} from "./IPoolCore.sol";
import {IPoolMarketplace} from "./IPoolMarketplace.sol";
import {IPoolParameters} from "./IPoolParameters.sol";
import {IParaProxyInterfaces} from "./IParaProxyInterfaces.sol";
import "./IPoolApeStaking.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPool is
    IPoolCore,
    IPoolMarketplace,
    IPoolParameters,
    IPoolApeStaking,
    IParaProxyInterfaces
{

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPoolMarketplace {
    event BuyWithCredit(
        bytes32 indexed marketplaceId,
        DataTypes.OrderInfo orderInfo,
        DataTypes.Credit credit
    );

    event AcceptBidWithCredit(
        bytes32 indexed marketplaceId,
        DataTypes.OrderInfo orderInfo,
        DataTypes.Credit credit
    );

    /**
     * @notice Implements the buyWithCredit feature. BuyWithCredit allows users to buy NFT from various NFT marketplaces
     * including OpenSea, LooksRare, X2Y2 etc. Users can use NFT's credit and will need to pay at most (1 - LTV) * $NFT
     * @dev
     * @param marketplaceId The marketplace identifier
     * @param payload The encoded parameters to be passed to marketplace contract (selector eliminated)
     * @param credit The credit that user would like to use for this purchase
     * @param referralCode The referral code used
     */
    function buyWithCredit(
        bytes32 marketplaceId,
        bytes calldata payload,
        DataTypes.Credit calldata credit,
        uint16 referralCode
    ) external payable;

    /**
     * @notice Implements the batchBuyWithCredit feature. BuyWithCredit allows users to buy NFT from various NFT marketplaces
     * including OpenSea, LooksRare, X2Y2 etc. Users can use NFT's credit and will need to pay at most (1 - LTV) * $NFT
     * @dev marketplaceIds[i] should match payload[i] and credits[i]
     * @param marketplaceIds The marketplace identifiers
     * @param payloads The encoded parameters to be passed to marketplace contract (selector eliminated)
     * @param credits The credits that user would like to use for this purchase
     * @param referralCode The referral code used
     */
    function batchBuyWithCredit(
        bytes32[] calldata marketplaceIds,
        bytes[] calldata payloads,
        DataTypes.Credit[] calldata credits,
        uint16 referralCode
    ) external payable;

    /**
     * @notice Implements the acceptBidWithCredit feature. AcceptBidWithCredit allows users to
     * accept a leveraged bid on ParaSpace NFT marketplace. Users can submit leveraged bid and pay
     * at most (1 - LTV) * $NFT
     * @dev The nft receiver just needs to do the downpayment
     * @param marketplaceId The marketplace identifier
     * @param payload The encoded parameters to be passed to marketplace contract (selector eliminated)
     * @param credit The credit that user would like to use for this purchase
     * @param onBehalfOf Address of the user who will sell the NFT
     * @param referralCode The referral code used
     */
    function acceptBidWithCredit(
        bytes32 marketplaceId,
        bytes calldata payload,
        DataTypes.Credit calldata credit,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Implements the batchAcceptBidWithCredit feature. AcceptBidWithCredit allows users to
     * accept a leveraged bid on ParaSpace NFT marketplace. Users can submit leveraged bid and pay
     * at most (1 - LTV) * $NFT
     * @dev The nft receiver just needs to do the downpayment
     * @param marketplaceIds The marketplace identifiers
     * @param payloads The encoded parameters to be passed to marketplace contract (selector eliminated)
     * @param credits The credits that the makers have approved to use for this purchase
     * @param onBehalfOf Address of the user who will sell the NFTs
     * @param referralCode The referral code used
     */
    function batchAcceptBidWithCredit(
        bytes32[] calldata marketplaceIds,
        bytes[] calldata payloads,
        DataTypes.Credit[] calldata credits,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPoolParameters {
    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the value of claim for yield incentive rate update
     **/
    event ClaimApeForYieldIncentiveUpdated(uint256 oldValue, uint256 newValue);

    /**
     * @notice Initializes a reserve, activating it, assigning an xToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param xTokenAddress The address of the xToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function initReserve(
        address asset,
        address xTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress,
        address auctionStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    /**
     * @notice Updates the address of the auction strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param auctionStrategyAddress The address of the auction strategy contract
     **/
    function setReserveAuctionStrategyAddress(
        address asset,
        address auctionStrategyAddress
    ) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external;

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of xTokens
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param assetType The asset type of the token
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amountOrTokenId The amount or id of token to transfer
     */
    function rescueTokens(
        DataTypes.AssetType assetType,
        address token,
        address to,
        uint256 amountOrTokenId
    ) external;

    /**
     * @notice grant token's an unlimited allowance value to the 'to' address
     * @param token The ERC20 token address
     * @param to The address receive the grant
     */
    function unlimitedApproveTo(address token, address to) external;

    /**
     * @notice undate fee percentage for claim ape for compound
     * @param fee new fee percentage
     */
    function setClaimApeForCompoundFee(uint256 fee) external;

    /**
     * @notice Set the auction recovery health factor
     * @param value The new auction health factor
     */
    function setAuctionRecoveryHealthFactor(uint64 value) external;

    /**
     * @notice Set auction validity time, all auctions triggered before the validity time will be considered as invalid
     * @param user The user address
     */
    function setAuctionValidityTime(address user) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 erc721HealthFactor
        );

    /**
     * @notice Returns Ltv and Liquidation Threshold for the asset
     * @param asset The address of the asset
     * @param tokenId The tokenId of the asset
     * @return ltv The loan to value of the asset
     * @return lt The liquidation threshold value of the asset
     **/
    function getAssetLtvAndLT(address asset, uint256 tokenId)
        external
        view
        returns (uint256 ltv, uint256 lt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// interfaces that are compatible with Diamond proxy loupe functions
interface IParaProxyInterfaces {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Implementation {
        address implAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Implementation
    function facets() external view returns (Implementation[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPoolCore {
    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the xTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     **/
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    event SupplyERC721(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        DataTypes.ERC721SupplyParams[] tokenData,
        uint16 indexed referralCode,
        bool fromNToken
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of xTokens
     * @param to The address that will receive the underlying asset
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on withdrawERC721()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of xTokens
     * @param to The address that will receive the underlying asset
     * @param tokenIds The tokenIds to be withdrawn
     **/
    event WithdrawERC721(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256[] tokenIds
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param usePTokens True if the repayment is done using xTokens, `false` if done with underlying asset directly
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool usePTokens
    );
    /**
     * @dev Emitted on setUserUseERC20AsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseERC20AsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param borrower The address of the borrower getting liquidated
     * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidateERC20(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed borrower,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receivePToken
    );

    /**
     * @dev Emitted when a borrower's ERC721 asset is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param borrower The address of the borrower getting liquidated
     * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralTokenId The token id of ERC721 asset received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveNToken True if the liquidators wants to receive the collateral NTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidateERC721(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed borrower,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralTokenId,
        address liquidator,
        bool receiveNToken
    );

    /**
     * @dev Emitted on flashClaim
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash claim
     * @param nftAsset address of the underlying asset of NFT
     * @param tokenId The token id of the asset being flash borrowed
     **/
    event FlashClaim(
        address indexed target,
        address indexed initiator,
        address indexed nftAsset,
        uint256 tokenId
    );

    /**
     * @dev Allows smart contracts to access the tokens within one transaction, as long as the tokens taken is returned.
     *
     * Requirements:
     *  - `nftTokenIds` must exist.
     *
     * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashClaimReceiver interface
     * @param nftAssets addresses of the underlying asset of NFT
     * @param nftTokenIds token ids of the underlying asset
     * @param params Variadic packed params to pass to the receiver as extra information
     */
    function flashClaim(
        address receiverAddress,
        address[] calldata nftAssets,
        uint256[][] calldata nftTokenIds,
        bytes calldata params
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying xTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 pUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supplies multiple `tokenIds` of underlying ERC721 asset into the reserve, receiving in return overlying nTokens.
     * - E.g. User supplies 2 BAYC and gets in return 2 nBAYC
     * @param asset The address of the underlying asset to supply
     * @param tokenData The list of tokenIds and their collateral configs to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supplyERC721(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Same as `supplyERC721` but this can only be called by NToken contract and doesn't require sending the underlying asset.
     * @param asset The address of the underlying asset to supply
     * @param tokenData The list of tokenIds and their collateral configs to be supplied
     * @param onBehalfOf The address that will receive the xTokens
     **/
    function supplyERC721FromNToken(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent xTokens owned
     * E.g. User has 100 pUSDC, calls withdraw() and receives 100 USDC, burning the 100 pUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Withdraws multiple `tokenIds` of underlying ERC721  asset from the reserve, burning the equivalent nTokens owned
     * E.g. User has 2 nBAYC, calls withdraw() and receives 2 BAYC, burning the 2 nBAYC
     * @param asset The address of the underlying asset to withdraw
     * @param tokenIds The underlying tokenIds to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdrawERC721(
        address asset,
        uint256[] calldata tokenIds,
        address to
    ) external returns (uint256);

    /**
     * @notice Decreases liquidity for underlying Uniswap V3 NFT LP and validates
     * that the user respects liquidation checks.
     * @param asset The asset address of uniswapV3
     * @param tokenId The id of the erc721 token
     * @param liquidityDecrease The amount of liquidity to remove of LP
     * @param amount0Min The minimum amount to remove of token0
     * @param amount1Min The minimum amount to remove of token1
     * @param receiveEthAsWeth If convert weth to ETH
     */
    function decreaseUniswapV3Liquidity(
        address asset,
        uint256 tokenId,
        uint128 liquidityDecrease,
        uint256 amount0Min,
        uint256 amount1Min,
        bool receiveEthAsWeth
    ) external;

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve xTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 pUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual xToken dust balance, if the user xToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @return The final amount repaid
     **/
    function repayWithPTokens(address asset, uint256 amount)
        external
        returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseERC20AsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied ERC721 asset with a tokenID as collateral
     * @param asset The address of the underlying asset supplied
     * @param tokenIds the ids of the supplied ERC721 token
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseERC721AsCollateral(
        address asset,
        uint256[] calldata tokenIds,
        bool useAsCollateral
    ) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `liquidationAmount` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidateERC20(
        address collateralAsset,
        address liquidationAsset,
        address user,
        uint256 liquidationAmount,
        bool receivePToken
    ) external payable;

    function liquidateERC721(
        address collateralAsset,
        address user,
        uint256 collateralTokenId,
        uint256 liquidationAmount,
        bool receiveNToken
    ) external payable;

    /**
     * @notice Start the auction on user's specific NFT collateral
     * @param user The address of the user
     * @param collateralAsset The address of the NFT collateral
     * @param collateralTokenId The tokenId of the NFT collateral
     **/
    function startAuction(
        address user,
        address collateralAsset,
        uint256 collateralTokenId
    ) external;

    /**
     * @notice End specific user's auction
     * @param user The address of the user
     * @param collateralAsset The address of the NFT collateral
     * @param collateralTokenId The tokenId of the NFT collateral
     **/
    function endAuction(
        address user,
        address collateralAsset,
        uint256 collateralTokenId
    ) external;

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an PToken transfer
     * @dev Only callable by the overlying xToken of the `asset`
     * @param asset The address of the underlying asset of the xToken
     * @param from The user from which the xTokens are transferred
     * @param to The user receiving the xTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The xToken balance of the `from` user before the transfer
     * @param balanceToBefore The xToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Validates and finalizes an NToken transfer
     * @dev Only callable by the overlying xToken of the `asset`
     * @param asset The address of the underlying asset of the xToken
     * @param tokenId The tokenId of the ERC721 asset
     * @param from The user from which the xTokens are transferred
     * @param to The user receiving the xTokens
     * @param balanceFromBefore The xToken balance of the `from` user before the transfer
     */
    function finalizeTransferERC721(
        address asset,
        uint256 tokenId,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 balanceFromBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the auction related data of specific asset collection and token id.
     * @param ntokenAsset The address of ntoken
     * @param tokenId The token id which is currently auctioned for liquidation
     * @return The auction related data of the corresponding (ntokenAsset, tokenId)
     */
    function getAuctionData(address ntokenAsset, uint256 tokenId)
        external
        view
        returns (DataTypes.AuctionData memory);

    // function getAuctionData(address user, address) external view returns (DataTypes.AuctionData memory);
    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     **/
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Returns the auction recovery health factor
     * @return The auction recovery health factor
     */
    function AUCTION_RECOVERY_HEALTH_FACTOR() external view returns (uint64);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {OfferItem, ConsiderationItem} from "../../../dependencies/seaport/contracts/lib/ConsiderationStructs.sol";

library DataTypes {
    enum AssetType {
        ERC20,
        ERC721
    }

    address public constant SApeAddress = address(0x1);
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //xToken address
        address xTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //address of the auction strategy
        address auctionStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
        // auction validity time for closing invalid auctions in one tx.
        uint256 auctionValidityTime;
    }

    struct ERC721SupplyParams {
        uint256 tokenId;
        bool useAsCollateral;
    }

    struct NTokenData {
        uint256 tokenId;
        bool useAsCollateral;
        bool isAuctioned;
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address xTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
    }

    struct ExecuteLiquidateParams {
        uint256 reservesCount;
        uint256 liquidationAmount;
        uint256 collateralTokenId;
        uint256 auctionRecoveryHealthFactor;
        address weth;
        address collateralAsset;
        address liquidationAsset;
        address borrower;
        address liquidator;
        bool receiveXToken;
        address priceOracle;
        address priceOracleSentinel;
    }

    struct ExecuteAuctionParams {
        uint256 reservesCount;
        uint256 auctionRecoveryHealthFactor;
        uint256 collateralTokenId;
        address collateralAsset;
        address user;
        address priceOracle;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        address payer;
        uint16 referralCode;
    }

    struct ExecuteSupplyERC721Params {
        address asset;
        DataTypes.ERC721SupplyParams[] tokenData;
        address onBehalfOf;
        address payer;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        bool usePTokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct ExecuteWithdrawERC721Params {
        address asset;
        uint256[] tokenIds;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct ExecuteDecreaseUniswapV3LiquidityParams {
        address user;
        address asset;
        uint256 tokenId;
        uint256 reservesCount;
        uint128 liquidityDecrease;
        uint256 amount0Min;
        uint256 amount1Min;
        bool receiveEthAsWeth;
        address oracle;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        bool usedAsCollateral;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeTransferERC721Params {
        address asset;
        address from;
        address to;
        bool usedAsCollateral;
        uint256 tokenId;
        uint256 balanceFromBefore;
        uint256 reservesCount;
        address oracle;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ValidateLiquidateERC20Params {
        ReserveCache liquidationAssetReserveCache;
        address liquidationAsset;
        address weth;
        uint256 totalDebt;
        uint256 healthFactor;
        uint256 liquidationAmount;
        uint256 actualLiquidationAmount;
        address priceOracleSentinel;
    }

    struct ValidateLiquidateERC721Params {
        ReserveCache liquidationAssetReserveCache;
        address liquidationAsset;
        address liquidator;
        address borrower;
        uint256 globalDebt;
        uint256 healthFactor;
        address collateralAsset;
        uint256 tokenId;
        address weth;
        uint256 actualLiquidationAmount;
        uint256 maxLiquidationAmount;
        uint256 auctionRecoveryHealthFactor;
        address priceOracleSentinel;
        address xTokenAddress;
        bool auctionEnabled;
    }

    struct ValidateAuctionParams {
        address user;
        uint256 auctionRecoveryHealthFactor;
        uint256 erc721HealthFactor;
        address collateralAsset;
        uint256 tokenId;
        address xTokenAddress;
    }

    struct CalculateInterestRatesParams {
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalVariableDebt;
        uint256 reserveFactor;
        address reserve;
        address xToken;
    }

    struct InitReserveParams {
        address asset;
        address xTokenAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        address auctionStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }

    struct ExecuteFlashClaimParams {
        address receiverAddress;
        address[] nftAssets;
        uint256[][] nftTokenIds;
        bytes params;
        address oracle;
    }

    struct Credit {
        address token;
        uint256 amount;
        bytes orderId;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ExecuteMarketplaceParams {
        bytes32 marketplaceId;
        bytes payload;
        Credit credit;
        uint256 ethLeft;
        DataTypes.Marketplace marketplace;
        OrderInfo orderInfo;
        address weth;
        uint16 referralCode;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct OrderInfo {
        address maker;
        address taker;
        bytes id;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
    }

    struct Marketplace {
        address marketplace;
        address adapter;
        address operator;
        bool paused;
    }

    struct Auction {
        uint256 startTime;
    }

    struct AuctionData {
        address asset;
        uint256 tokenId;
        uint256 startTime;
        uint256 currentPriceMultiplier;
        uint256 maxPriceMultiplier;
        uint256 minExpPriceMultiplier;
        uint256 minPriceMultiplier;
        uint256 stepLinear;
        uint256 stepExp;
        uint256 tickLength;
    }

    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    struct PoolStorage {
        // Map of reserves and their data (underlyingAssetOfReserve => reserveData)
        mapping(address => ReserveData) _reserves;
        // Map of users address and their configuration data (userAddress => userConfiguration)
        mapping(address => UserConfigurationMap) _usersConfig;
        // List of reserves as a map (reserveId => reserve).
        // It is structured as a mapping for gas savings reasons, using the reserve id as index
        mapping(uint256 => address) _reservesList;
        // Maximum number of active reserves there have been in the protocol. It is the upper bound of the reserves list
        uint16 _reservesCount;
        // Auction recovery health factor
        uint64 _auctionRecoveryHealthFactor;
        // incentive fee for claim ape reward to compound
        uint16 _apeCompoundFee;
    }

    struct ReserveConfigData {
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool isActive;
        bool isFrozen;
        bool isPaused;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/******************************************************************************\
* EIP-2535: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IParaProxy {
    enum ProxyImplementationAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ProxyImplementation {
        address implAddress;
        ProxyImplementationAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _implementationParams Contains the implementation addresses and function selectors
    /// @param _init The address of the contract or implementation to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function updateImplementation(
        ProxyImplementation[] calldata _implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;

    event ImplementationUpdated(
        ProxyImplementation[] _implementationParams,
        address _init,
        bytes _calldata
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    OrderType,
    BasicOrderType,
    ItemType,
    Side
} from "./ConsiderationEnums.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC721Receiver} from "../dependencies/openzeppelin/contracts/IERC721Receiver.sol";
import {IERC721Enumerable} from "../dependencies/openzeppelin/contracts/IERC721Enumerable.sol";
import {IERC1155Receiver} from "../dependencies/openzeppelin/contracts/IERC1155Receiver.sol";

import {IInitializableNToken} from "./IInitializableNToken.sol";
import {IXTokenType} from "./IXTokenType.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title INToken
 * @author ParallelFi
 * @notice Defines the basic interface for an NToken.
 **/
interface INToken is
    IERC721Enumerable,
    IInitializableNToken,
    IERC721Receiver,
    IERC1155Receiver,
    IXTokenType
{
    /**
     * @dev Emitted during rescueERC20()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    event RescueERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during rescueERC721()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     **/
    event RescueERC721(
        address indexed token,
        address indexed to,
        uint256[] ids
    );

    /**
     * @dev Emitted during RescueERC1155()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     * @param amounts The amount of NFTs being rescued for a specific id.
     * @param data The data of the tokens that is being rescued. Usually this is 0.
     **/
    event RescueERC1155(
        address indexed token,
        address indexed to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    /**
     * @dev Emitted during executeAirdrop()
     * @param airdropContract The address of the airdrop contract
     **/
    event ExecuteAirdrop(address indexed airdropContract);

    /**
     * @notice Mints `amount` nTokens to `user`
     * @param onBehalfOf The address of the user that will receive the minted nTokens
     * @param tokenData The list of the tokens getting minted and their collateral configs
     * @return old and new collateralized balance
     */
    function mint(
        address onBehalfOf,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    ) external returns (uint64, uint64);

    /**
     * @notice Burns nTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the nTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param tokenIds The ids of the tokens getting burned
     * @return old and new collateralized balance
     **/
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256[] calldata tokenIds
    ) external returns (uint64, uint64);

    // TODO are we using the Treasury at all? Can we remove?
    // /**
    //  * @notice Mints nTokens to the reserve treasury
    //  * @param tokenId The id of the token getting minted
    //  * @param index The next liquidity index of the reserve
    //  */
    // function mintToTreasury(uint256 tokenId, uint256 index) external;

    /**
     * @notice Transfers nTokens in the event of a borrow being liquidated, in case the liquidators reclaims the nToken
     * @param from The address getting liquidated, current owner of the nTokens
     * @param to The recipient
     * @param tokenId The id of the token getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param tokenId The id of the token getting transferred
     **/
    function transferUnderlyingTo(address user, uint256 tokenId) external;

    /**
     * @notice Handles the underlying received by the nToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC721 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be nTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param tokenId The amount getting repaid
     **/
    function handleRepayment(address user, uint256 tokenId) external;

    /**
     * @notice Returns the address of the underlying asset of this nToken (E.g. WETH for pWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Rescue ERC20 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Rescue ERC721 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     **/
    function rescueERC721(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Rescue ERC1155 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     * @param amounts The amount of NFTs being rescued for a specific id.
     * @param data The data of the tokens that is being rescued. Usually this is 0.
     **/
    function rescueERC1155(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @notice Executes airdrop.
     * @param airdropContract The address of the airdrop contract
     * @param airdropParams Third party airdrop abi data. You need to get this from the third party airdrop.
     **/
    function executeAirdrop(
        address airdropContract,
        bytes calldata airdropParams
    ) external;

    function getAtomicPricingConfig() external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IRewardController} from "./IRewardController.sol";
import {IPool} from "./IPool.sol";

/**
 * @title IInitializablenToken
 *
 * @notice Interface for the initialize function on NToken
 **/
interface IInitializableNToken {
    /**
     * @dev Emitted when an nToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param incentivesController The address of the incentives controller for this nToken
     * @param nTokenName The name of the nToken
     * @param nTokenSymbol The symbol of the nToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        string nTokenName,
        string nTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the nToken
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this nToken (E.g. WETH for pWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param nTokenName The name of the nToken
     * @param nTokenSymbol The symbol of the nToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address underlyingAsset,
        IRewardController incentivesController,
        string calldata nTokenName,
        string calldata nTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.10;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ASSET_TYPE_MASK =                0xFFFFFFFFFFFFFFFFFFFFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    //uint256 internal constant DYNAMIC_CONFIGS_MASK =           0xFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
    /// @dev bit 63 reserved

    uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
    uint256 internal constant ASSET_TYPE_START_BIT_POSITION = 168;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
    uint256 internal constant MAX_ASSET_TYPE = 16;

    uint16 public constant MAX_RESERVES_COUNT = 128;

    /**
     * @notice Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv The new ltv
     **/
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv)
        internal
        pure
    {
        require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @notice Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @notice Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     **/
    function setLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 threshold
    ) internal pure {
        require(
            threshold <= MAX_VALID_LIQUIDATION_THRESHOLD,
            Errors.INVALID_LIQ_THRESHOLD
        );

        self.data =
            (self.data & LIQUIDATION_THRESHOLD_MASK) |
            (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     **/
    function getLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
        return
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
            LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     **/
    function setLiquidationBonus(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 bonus
    ) internal pure {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

        self.data =
            (self.data & LIQUIDATION_BONUS_MASK) |
            (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     **/
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~LIQUIDATION_BONUS_MASK) >>
            LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     **/
    function setDecimals(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 decimals
    ) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        self.data =
            (self.data & DECIMALS_MASK) |
            (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     **/
    function getDecimals(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the asset type of the reserve
     * @param self The reserve configuration
     * @param assetType The asset type
     **/
    function setAssetType(
        DataTypes.ReserveConfigurationMap memory self,
        DataTypes.AssetType assetType
    ) internal pure {
        require(
            uint256(assetType) <= MAX_ASSET_TYPE,
            Errors.INVALID_ASSET_TYPE
        );

        self.data =
            (self.data & ASSET_TYPE_MASK) |
            (uint256(assetType) << ASSET_TYPE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the asset type of the reserve
     * @param self The reserve configuration
     * @return The asset type
     **/
    function getAssetType(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (DataTypes.AssetType)
    {
        return
            DataTypes.AssetType(
                (self.data & ~ASSET_TYPE_MASK) >> ASSET_TYPE_START_BIT_POSITION
            );
    }

    /**
     * @notice Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(
        DataTypes.ReserveConfigurationMap memory self,
        bool active
    ) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getActive(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @notice Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     **/
    function setFrozen(
        DataTypes.ReserveConfigurationMap memory self,
        bool frozen
    ) internal pure {
        self.data =
            (self.data & FROZEN_MASK) |
            (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @notice Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets the paused state of the reserve
     * @param self The reserve configuration
     * @param paused The paused state
     **/
    function setPaused(
        DataTypes.ReserveConfigurationMap memory self,
        bool paused
    ) internal pure {
        self.data =
            (self.data & PAUSED_MASK) |
            (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the paused state of the reserve
     * @param self The reserve configuration
     * @return The paused state
     **/
    function getPaused(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Sets the siloed borrowing flag for the reserve.
     * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
     * @param self The reserve configuration
     * @param siloed True if the asset is siloed
     **/
    function setSiloedBorrowing(
        DataTypes.ReserveConfigurationMap memory self,
        bool siloed
    ) internal pure {
        self.data =
            (self.data & SILOED_BORROWING_MASK) |
            (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
    }

    /**
     * @notice Gets the siloed borrowing flag for the reserve.
     * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
     * @param self The reserve configuration
     * @return The siloed borrowing flag
     **/
    function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~SILOED_BORROWING_MASK) != 0;
    }

    /**
     * @notice Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     **/
    function setBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     **/
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @notice Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     **/
    function setReserveFactor(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 reserveFactor
    ) internal pure {
        require(
            reserveFactor <= MAX_VALID_RESERVE_FACTOR,
            Errors.INVALID_RESERVE_FACTOR
        );

        self.data =
            (self.data & RESERVE_FACTOR_MASK) |
            (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @notice Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     **/
    function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~RESERVE_FACTOR_MASK) >>
            RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @notice Sets the borrow cap of the reserve
     * @param self The reserve configuration
     * @param borrowCap The borrow cap
     **/
    function setBorrowCap(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 borrowCap
    ) internal pure {
        require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

        self.data =
            (self.data & BORROW_CAP_MASK) |
            (borrowCap << BORROW_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrow cap of the reserve
     * @param self The reserve configuration
     * @return The borrow cap
     **/
    function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCap The supply cap
     **/
    function setSupplyCap(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 supplyCap
    ) internal pure {
        require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data =
            (self.data & SUPPLY_CAP_MASK) |
            (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     **/
    function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation protocol fee of the reserve
     * @param self The reserve configuration
     * @param liquidationProtocolFee The liquidation protocol fee
     **/
    function setLiquidationProtocolFee(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 liquidationProtocolFee
    ) internal pure {
        require(
            liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
            Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
        );

        self.data =
            (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
            (liquidationProtocolFee <<
                LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation protocol fee
     * @param self The reserve configuration
     * @return The liquidation protocol fee
     **/
    function getLiquidationProtocolFee(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
        return
            (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >>
            LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flag representing active
     * @return The state flag representing frozen
     * @return The state flag representing borrowing enabled
     * @return The state flag representing paused
     * @return The asset type
     **/
    function getFlags(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool,
            DataTypes.AssetType
        )
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~PAUSED_MASK) != 0,
            DataTypes.AssetType(
                (dataLocal & ~ASSET_TYPE_MASK) >> ASSET_TYPE_START_BIT_POSITION
            )
        );
    }

    /**
     * @notice Gets the configuration parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing ltv
     * @return The state param representing liquidation threshold
     * @return The state param representing liquidation bonus
     * @return The state param representing reserve decimals
     * @return The state param representing reserve factor
     **/
    function getParams(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
                LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >>
                LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~RESERVE_FACTOR_MASK) >>
                RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @notice Gets the caps parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing borrow cap
     * @return The state param representing supply cap.
     **/
    function getCaps(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
            (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";

/**
 * @title IVariableDebtToken
 *
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
    /**
     * @notice Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return True if the previous balance of the user is 0, false otherwise
     * @return The scaled total debt of the reserve
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool, uint256);

    /**
     * @notice Burns user variable debt
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the debt will be burned
     * @param amount The amount getting burned
     * @param index The variable debt index of the reserve
     * @return The scaled total debt of the reserve
     **/
    function burn(
        address from,
        uint256 amount,
        uint256 index
    ) external returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IReserveInterestRateStrategy
 *
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
    /**
     * @notice Returns the base variable borrow rate
     * @return The base variable borrow rate, expressed in ray
     **/
    function getBaseVariableBorrowRate() external view returns (uint256);

    /**
     * @notice Returns the maximum variable borrow rate
     * @return The maximum variable borrow rate, expressed in ray
     **/
    function getMaxVariableBorrowRate() external view returns (uint256);

    /**
     * @notice Calculates the interest rates depending on the reserve's state and configurations
     * @param params The parameters needed to calculate interest rates
     * @return liquidityRate The liquidity rate expressed in rays
     * @return variableBorrowRate The variable borrow rate expressed in rays
     **/
    function calculateInterestRates(
        DataTypes.CalculateInterestRatesParams memory params
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20} from "../../openzeppelin/contracts/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token)
        private
        view
        returns (bool success)
    {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {WadRayMath} from "./WadRayMath.sol";

/**
 * @title MathUtils library
 *
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/
    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 result = rate *
            (block.timestamp - uint256(lastUpdateTimestamp));
        unchecked {
            result = result / SECONDS_PER_YEAR;
        }

        return WadRayMath.RAY + result;
    }

    /**
     * @dev Function to calculate the interest using a compounded interest rate formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     *
     *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     *
     * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
     * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
     * error per different time periods
     *
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate compounded during the timeDelta, in ray
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        //solium-disable-next-line
        uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

        if (exp == 0) {
            return WadRayMath.RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo =
                rate.rayMul(rate) /
                (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
            basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return
            WadRayMath.RAY +
            (rate * exp) /
            SECONDS_PER_YEAR +
            secondTerm +
            thirdTerm;
    }

    /**
     * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
     * @param rate The interest rate (in ray)
     * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
     * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) internal view returns (uint256) {
        return
            calculateCompoundedInterest(
                rate,
                lastUpdateTimestamp,
                block.timestamp
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IRewardController} from "./IRewardController.sol";
import {IPool} from "./IPool.sol";

/**
 * @title IInitializableDebtToken
 *
 * @notice Interface for the initialize function common between debt tokens
 **/
interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param incentivesController The address of the incentives controller for this xToken
     * @param debtTokenDecimals The decimals of the debt token
     * @param debtTokenName The name of the debt token
     * @param debtTokenSymbol The symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the debt token.
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this xToken (E.g. WETH for pWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title ICollateralizableERC721
 * @author Parallel
 * @notice Defines the basic interface for an CollateralizableERC721.
 **/
interface ICollateralizableERC721 {
    /**
     * @dev get the collateralized balance of a specific user
     */
    function collateralizedBalanceOf(address user)
        external
        view
        returns (uint256);

    /**
     * @dev get the the collateral configuration of a specific token
     */
    function isUsedAsCollateral(uint256 tokenId) external view returns (bool);

    /**
     * @dev changes the collateral state/config of a token
     * @return if the state has changed
     */
    function setIsUsedAsCollateral(
        uint256 tokenId,
        bool useAsCollateral,
        address sender
    ) external returns (bool);

    /**
     * @dev the ids of the token want to change the collateral state
     * @return uint256 (user's old collateralized balance), uint256 (user's new collateralized balance)
     */
    function batchSetIsUsedAsCollateral(
        uint256[] calldata tokenIds,
        bool useAsCollateral,
        address sender
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPriceOracleGetter
 *
 * @notice Interface for the ParaSpace price oracle.
 **/
interface IPriceOracleGetter {
    /**
     * @notice Returns the base currency address
     * @dev Address 0x0 is reserved for USD as base currency.
     * @return Returns the base currency address.
     **/
    function BASE_CURRENCY() external view returns (address);

    /**
     * @notice Returns the base currency unit
     * @dev 1 ether for ETH, 1e8 for USD.
     * @return Returns the base currency unit.
     **/
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    /**
     * @notice Returns the asset price in the base currency
     * @param asset The address of the asset
     * @return The price of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @notice Returns the price of a token
     * @param asset the asset address
     * @param tokenId the token id
     * @return The price of the given token
     */
    function getTokenPrice(address asset, uint256 tokenId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IAuctionableERC721
 * @author Parallel
 * @notice Defines the basic interface for an AuctionableERC721.
 **/
interface IAuctionableERC721 {
    /**
     * @dev get the auction configuration of a specific token
     */
    function isAuctioned(uint256 tokenId) external view returns (bool);

    /**
     *
     * @dev start auction
     */
    function startAuction(uint256 tokenId) external;

    /**
     *
     * @dev end auction
     */
    function endAuction(uint256 tokenId) external;

    /**
     *
     * @dev get auction data
     */
    function getAuctionData(uint256 tokenId)
        external
        view
        returns (DataTypes.Auction memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IPriceOracleSentinel
 *
 * @notice Defines the basic interface for the PriceOracleSentinel
 */
interface IPriceOracleSentinel {
    /**
     * @dev Emitted after the sequencer oracle is updated
     * @param newSequencerOracle The new sequencer oracle
     */
    event SequencerOracleUpdated(address newSequencerOracle);

    /**
     * @dev Emitted after the grace period is updated
     * @param newGracePeriod The new grace period value
     */
    event GracePeriodUpdated(uint256 newGracePeriod);

    /**
     * @notice Returns the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns true if the `borrow` operation is allowed.
     * @dev Operation not allowed when PriceOracle is down or grace period not passed.
     * @return True if the `borrow` operation is allowed, false otherwise.
     */
    function isBorrowAllowed() external view returns (bool);

    /**
     * @notice Returns true if the `liquidation` operation is allowed.
     * @dev Operation not allowed when PriceOracle is down or grace period not passed.
     * @return True if the `liquidation` operation is allowed, false otherwise.
     */
    function isLiquidationAllowed() external view returns (bool);

    /**
     * @notice Updates the address of the sequencer oracle
     * @param newSequencerOracle The address of the new Sequencer Oracle to use
     */
    function setSequencerOracle(address newSequencerOracle) external;

    /**
     * @notice Updates the duration of the grace period
     * @param newGracePeriod The value of the new grace period duration
     */
    function setGracePeriod(uint256 newGracePeriod) external;

    /**
     * @notice Returns the SequencerOracle
     * @return The address of the sequencer oracle contract
     */
    function getSequencerOracle() external view returns (address);

    /**
     * @notice Returns the grace period
     * @return The duration of the grace period
     */
    function getGracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IToken {
    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "../openzeppelin/contracts/IERC721Metadata.sol";
import "../openzeppelin/contracts/IERC721Enumerable.sol";

import "./IPoolInitializer.sol";
import "./IERC721Permit.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";
import "./PoolAddress.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title Helpers library
 *
 */
library Helpers {
    /**
     * @notice Fetches the user current stable and variable debt balances
     * @param user The user address
     * @param debtTokenAddress The debt token address
     * @return The variable debt balance
     **/
    function getUserCurrentDebt(address user, address debtTokenAddress)
        internal
        view
        returns (uint256)
    {
        return (IERC20(debtTokenAddress).balanceOf(user));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "../../../openzeppelin/contracts/Address.sol";
import {IERC1271} from "../../../openzeppelin/contracts/IERC1271.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
    /**
     * @notice Recovers the signer of a signature (for EOA)
     * @param hash the hash containing the signed mesage
     * @param v parameter (27 or 28). This prevents maleability since the public key recovery equation has two possible solutions.
     * @param r parameter
     * @param s parameter
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Signature: Invalid s parameter"
        );

        require(v == 27 || v == 28, "Signature: Invalid v parameter");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed mesage
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @param domainSeparator paramer to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
            return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
        } else {
            return recover(digest, v, r, s) == signer;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "../openzeppelin/contracts/IERC721.sol";

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient)
        external
        payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xa598dd2fba360510c5a8f02f44423a4468e902df5857dbce3ca162a43a3a31ff;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface INTokenUniswapV3 {
    /**
     * @notice Decreases liquidity for underlying Uniswap V3 NFT LP and validates
     * that the user respects liquidation checks.
     * @param user The user address decreasing liquidity for
     * @param tokenId The id of the erc721 token
     * @param liquidityDecrease The amount of liquidity to remove of LP
     * @param amount0Min The minimum amount to remove of token0
     * @param amount1Min The minimum amount to remove of token1
     * @param receiveEthAsWeth If convert weth to ETH
     */
    function decreaseUniswapV3Liquidity(
        address user,
        uint256 tokenId,
        uint128 liquidityDecrease,
        uint256 amount0Min,
        uint256 amount1Min,
        bool receiveEthAsWeth
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;
import {ApeCoinStaking} from "../../../dependencies/yoga-labs/ApeCoinStaking.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {SafeERC20} from "../../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../../interfaces/IRewardController.sol";
import "../../libraries/types/DataTypes.sol";
import "../../../interfaces/IPool.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

struct UserState {
    uint64 balance;
    uint64 collateralizedBalance;
    uint128 additionalData;
}

struct MintableERC721Data {
    // Token name
    string name;
    // Token symbol
    string symbol;
    // Mapping from token ID to owner address
    mapping(uint256 => address) owners;
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) ownedTokens;
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) ownedTokensIndex;
    // Array with all token ids, used for enumeration
    uint256[] allTokens;
    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) allTokensIndex;
    // Map of users address and their state data (userAddress => userStateData)
    mapping(address => UserState) userState;
    // Mapping from token ID to approved address
    mapping(uint256 => address) tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) operatorApprovals;
    // Map of allowances (delegator => delegatee => allowanceAmount)
    mapping(address => mapping(address => uint256)) allowances;
    IRewardController rewardController;
    uint64 balanceLimit;
    mapping(uint256 => bool) isUsedAsCollateral;
    mapping(uint256 => DataTypes.Auction) auctions;
}

/**
 * @title MintableERC721 library
 *
 * @notice Implements the base logic for MintableERC721
 */
library MintableERC721Logic {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function executeTransfer(
        MintableERC721Data storage erc721Data,
        IPool POOL,
        bool ATOMIC_PRICING,
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(
            erc721Data.owners[tokenId] == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        require(
            !isAuctioned(erc721Data, POOL, tokenId),
            Errors.TOKEN_IN_AUCTION
        );

        _beforeTokenTransfer(erc721Data, from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(erc721Data, address(0), tokenId);

        uint64 oldSenderBalance = erc721Data.userState[from].balance;
        erc721Data.userState[from].balance = oldSenderBalance - 1;
        uint64 oldRecipientBalance = erc721Data.userState[to].balance;
        uint64 newRecipientBalance = oldRecipientBalance + 1;
        _checkBalanceLimit(erc721Data, ATOMIC_PRICING, newRecipientBalance);
        erc721Data.userState[to].balance = newRecipientBalance;
        erc721Data.owners[tokenId] = to;

        if (from != to && erc721Data.auctions[tokenId].startTime > 0) {
            delete erc721Data.auctions[tokenId];
        }

        IRewardController rewardControllerLocal = erc721Data.rewardController;
        if (address(rewardControllerLocal) != address(0)) {
            uint256 oldTotalSupply = erc721Data.allTokens.length;
            rewardControllerLocal.handleAction(
                from,
                oldTotalSupply,
                oldSenderBalance
            );
            if (from != to) {
                rewardControllerLocal.handleAction(
                    to,
                    oldTotalSupply,
                    oldRecipientBalance
                );
            }
        }

        emit Transfer(from, to, tokenId);
    }

    function executeTransferCollateralizable(
        MintableERC721Data storage erc721Data,
        IPool POOL,
        bool ATOMIC_PRICING,
        address from,
        address to,
        uint256 tokenId
    ) external returns (bool isUsedAsCollateral_) {
        isUsedAsCollateral_ = erc721Data.isUsedAsCollateral[tokenId];

        if (from != to && isUsedAsCollateral_) {
            erc721Data.userState[from].collateralizedBalance -= 1;
            delete erc721Data.isUsedAsCollateral[tokenId];
        }

        executeTransfer(erc721Data, POOL, ATOMIC_PRICING, from, to, tokenId);
    }

    function executeSetIsUsedAsCollateral(
        MintableERC721Data storage erc721Data,
        IPool POOL,
        uint256 tokenId,
        bool useAsCollateral,
        address sender
    ) internal returns (bool) {
        if (erc721Data.isUsedAsCollateral[tokenId] == useAsCollateral)
            return false;

        address owner = erc721Data.owners[tokenId];
        require(owner == sender, "not owner");

        if (!useAsCollateral) {
            require(
                !isAuctioned(erc721Data, POOL, tokenId),
                Errors.TOKEN_IN_AUCTION
            );
        }

        uint64 collateralizedBalance = erc721Data
            .userState[owner]
            .collateralizedBalance;
        erc721Data.isUsedAsCollateral[tokenId] = useAsCollateral;
        collateralizedBalance = useAsCollateral
            ? collateralizedBalance + 1
            : collateralizedBalance - 1;
        erc721Data
            .userState[owner]
            .collateralizedBalance = collateralizedBalance;

        return true;
    }

    function executeMintMultiple(
        MintableERC721Data storage erc721Data,
        bool ATOMIC_PRICING,
        address to,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    )
        external
        returns (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        )
    {
        require(to != address(0), "ERC721: mint to the zero address");
        uint64 oldBalance = erc721Data.userState[to].balance;
        oldCollateralizedBalance = erc721Data
            .userState[to]
            .collateralizedBalance;
        uint256 oldTotalSupply = erc721Data.allTokens.length;
        uint64 collateralizedTokens = 0;

        for (uint256 index = 0; index < tokenData.length; index++) {
            uint256 tokenId = tokenData[index].tokenId;

            require(
                !_exists(erc721Data, tokenId),
                "ERC721: token already minted"
            );

            _addTokenToAllTokensEnumeration(
                erc721Data,
                tokenId,
                oldTotalSupply + index
            );
            _addTokenToOwnerEnumeration(
                erc721Data,
                to,
                tokenId,
                oldBalance + index
            );

            erc721Data.owners[tokenId] = to;

            if (
                tokenData[index].useAsCollateral &&
                !erc721Data.isUsedAsCollateral[tokenId]
            ) {
                erc721Data.isUsedAsCollateral[tokenId] = true;
                collateralizedTokens++;
            }

            emit Transfer(address(0), to, tokenId);
        }

        newCollateralizedBalance =
            oldCollateralizedBalance +
            collateralizedTokens;
        erc721Data
            .userState[to]
            .collateralizedBalance = newCollateralizedBalance;

        uint64 newBalance = oldBalance + uint64(tokenData.length);
        _checkBalanceLimit(erc721Data, ATOMIC_PRICING, newBalance);
        erc721Data.userState[to].balance = newBalance;

        // calculate incentives
        IRewardController rewardControllerLocal = erc721Data.rewardController;
        if (address(rewardControllerLocal) != address(0)) {
            rewardControllerLocal.handleAction(to, oldTotalSupply, oldBalance);
        }

        return (oldCollateralizedBalance, newCollateralizedBalance);
    }

    function executeBurnMultiple(
        MintableERC721Data storage erc721Data,
        IPool POOL,
        address user,
        uint256[] calldata tokenIds
    )
        external
        returns (
            uint64 oldCollateralizedBalance,
            uint64 newCollateralizedBalance
        )
    {
        uint64 burntCollateralizedTokens = 0;
        uint64 balanceToBurn;
        uint256 oldTotalSupply = erc721Data.allTokens.length;
        uint256 oldBalance = erc721Data.userState[user].balance;
        oldCollateralizedBalance = erc721Data
            .userState[user]
            .collateralizedBalance;

        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            address owner = erc721Data.owners[tokenId];
            require(owner == user, "not the owner of Ntoken");
            require(
                !isAuctioned(erc721Data, POOL, tokenId),
                Errors.TOKEN_IN_AUCTION
            );

            _removeTokenFromAllTokensEnumeration(
                erc721Data,
                tokenId,
                oldTotalSupply - index
            );
            _removeTokenFromOwnerEnumeration(
                erc721Data,
                user,
                tokenId,
                oldBalance - index
            );

            // Clear approvals
            _approve(erc721Data, address(0), tokenId);

            balanceToBurn++;
            delete erc721Data.owners[tokenId];

            if (erc721Data.auctions[tokenId].startTime > 0) {
                delete erc721Data.auctions[tokenId];
            }

            if (erc721Data.isUsedAsCollateral[tokenId]) {
                delete erc721Data.isUsedAsCollateral[tokenId];
                burntCollateralizedTokens++;
            }
            emit Transfer(owner, address(0), tokenId);
        }

        erc721Data.userState[user].balance -= balanceToBurn;
        newCollateralizedBalance =
            oldCollateralizedBalance -
            burntCollateralizedTokens;
        erc721Data
            .userState[user]
            .collateralizedBalance = newCollateralizedBalance;

        // calculate incentives
        IRewardController rewardControllerLocal = erc721Data.rewardController;

        if (address(rewardControllerLocal) != address(0)) {
            rewardControllerLocal.handleAction(
                user,
                oldTotalSupply,
                oldBalance
            );
        }

        return (oldCollateralizedBalance, newCollateralizedBalance);
    }

    function executeApprove(
        MintableERC721Data storage erc721Data,
        address to,
        uint256 tokenId
    ) external {
        _approve(erc721Data, to, tokenId);
    }

    function _approve(
        MintableERC721Data storage erc721Data,
        address to,
        uint256 tokenId
    ) private {
        erc721Data.tokenApprovals[tokenId] = to;
        emit Approval(erc721Data.owners[tokenId], to, tokenId);
    }

    function executeApprovalForAll(
        MintableERC721Data storage erc721Data,
        address owner,
        address operator,
        bool approved
    ) external {
        require(owner != operator, "ERC721: approve to caller");
        erc721Data.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function executeStartAuction(
        MintableERC721Data storage erc721Data,
        IPool POOL,
        uint256 tokenId
    ) external {
        require(
            !isAuctioned(erc721Data, POOL, tokenId),
            Errors.AUCTION_ALREADY_STARTED
        );
        require(
            _exists(erc721Data, tokenId),
            "ERC721: startAuction for nonexistent token"
        );
        erc721Data.auctions[tokenId] = DataTypes.Auction({
            startTime: block.timestamp
        });
    }

    function executeEndAuction(
        MintableERC721Data storage erc721Data,
        IPool POOL,
        uint256 tokenId
    ) external {
        require(
            isAuctioned(erc721Data, POOL, tokenId),
            Errors.AUCTION_NOT_STARTED
        );
        require(
            _exists(erc721Data, tokenId),
            "ERC721: endAuction for nonexistent token"
        );
        delete erc721Data.auctions[tokenId];
    }

    function _checkBalanceLimit(
        MintableERC721Data storage erc721Data,
        bool ATOMIC_PRICING,
        uint64 balance
    ) private view {
        if (ATOMIC_PRICING) {
            uint64 balanceLimit = erc721Data.balanceLimit;
            require(
                balanceLimit == 0 || balance <= balanceLimit,
                Errors.NTOKEN_BALANCE_EXCEEDED
            );
        }
    }

    function _exists(MintableERC721Data storage erc721Data, uint256 tokenId)
        private
        view
        returns (bool)
    {
        return erc721Data.owners[tokenId] != address(0);
    }

    function isAuctioned(
        MintableERC721Data storage erc721Data,
        IPool POOL,
        uint256 tokenId
    ) public view returns (bool) {
        return
            erc721Data.auctions[tokenId].startTime >
            POOL
                .getUserConfiguration(erc721Data.owners[tokenId])
                .auctionValidityTime;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        MintableERC721Data storage erc721Data,
        address from,
        address to,
        uint256 tokenId
    ) private {
        if (from == address(0)) {
            uint256 length = erc721Data.allTokens.length;
            _addTokenToAllTokensEnumeration(erc721Data, tokenId, length);
        } else if (from != to) {
            uint256 userBalance = erc721Data.userState[from].balance;
            _removeTokenFromOwnerEnumeration(
                erc721Data,
                from,
                tokenId,
                userBalance
            );
        }
        if (to == address(0)) {
            uint256 length = erc721Data.allTokens.length;
            _removeTokenFromAllTokensEnumeration(erc721Data, tokenId, length);
        } else if (to != from) {
            uint256 length = erc721Data.userState[to].balance;
            _addTokenToOwnerEnumeration(erc721Data, to, tokenId, length);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(
        MintableERC721Data storage erc721Data,
        address to,
        uint256 tokenId,
        uint256 length
    ) private {
        erc721Data.ownedTokens[to][length] = tokenId;
        erc721Data.ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(
        MintableERC721Data storage erc721Data,
        uint256 tokenId,
        uint256 length
    ) private {
        erc721Data.allTokensIndex[tokenId] = length;
        erc721Data.allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        MintableERC721Data storage erc721Data,
        address from,
        uint256 tokenId,
        uint256 userBalance
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = userBalance - 1;
        uint256 tokenIndex = erc721Data.ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = erc721Data.ownedTokens[from][lastTokenIndex];

            erc721Data.ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            erc721Data.ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete erc721Data.ownedTokensIndex[tokenId];
        delete erc721Data.ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(
        MintableERC721Data storage erc721Data,
        uint256 tokenId,
        uint256 length
    ) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = length - 1;
        uint256 tokenIndex = erc721Data.allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = erc721Data.allTokens[lastTokenIndex];

        erc721Data.allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        erc721Data.allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete erc721Data.allTokensIndex[tokenId];
        erc721Data.allTokens.pop();
    }
}