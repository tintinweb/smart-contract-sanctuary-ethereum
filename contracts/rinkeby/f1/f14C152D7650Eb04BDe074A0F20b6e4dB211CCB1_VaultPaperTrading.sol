/** 
    Created by Arcadia Finance
    https://www.arcadia.finance

    SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity >=0.4.22 <0.9.0;

import "./Vault.sol";
import {FixedPointMathLib} from "./FixedPointMathLib.sol";

contract VaultPaperTrading is Vault {
    using FixedPointMathLib for uint256;

    address public _tokenShop;
    uint256 rewards;

    constructor() {
        owner = msg.sender;
    }

    event SingleDeposit(
        address indexed vaultAddress,
        address assetAddress,
        uint256 assetId,
        uint256 assetAmount
    );
    event BatchDeposit(
        address indexed vaultAddress,
        address[] assetAddresses,
        uint256[] assetIds,
        uint256[] assetAmounts
    );
    event SingleWithdraw(
        address indexed vaultAddress,
        address assetAddress,
        uint256 assetId,
        uint256 assetAmount
    );
    event BatchWithdraw(
        address indexed vaultAddress,
        address[] assetAddresses,
        uint256[] assetIds,
        uint256[] assetAmounts
    );

    /**
     * @dev Throws if called by any address other than the tokenshop
     *  only added for the paper trading competition
     */
    modifier onlyTokenShop() {
        require(msg.sender == _tokenShop, "Not tokenshop");
        _;
    }

    function initialize(
        address,
        address,
        uint256,
        address,
        address,
        address
    ) external payable override {
        revert("Not Allowed");
    }

    /** 
    @notice Initiates the variables of the vault
    @dev A proxy will be used to interact with the vault logic.
         Therefore everything is initialised through an init function.
         This function will only be called (once) in the same transaction as the proxy vault creation through the factory.
         Costly function (156k gas)
    @param _owner The tx.origin: the sender of the 'createVault' on the factory
    @param registryAddress The 'beacon' contract to which should be looked at for external logic.
    @param numeraire The numeraire of the vault.
    @param stable The contract address of the stablecoin of Arcadia Finance
    @param stakeContract The stake contract in which stablecoin can be staked. 
                         Used when syncing debt: interest in stable is minted to stakecontract.
    @param irmAddress The contract address of the InterestRateModule, which calculates the going interest rate
                      for a credit line, based on the underlying assets.
    @param tokenShop The contract with the mocked token shop, added for the paper trading competition
  */
    function initialize(
        address _owner,
        address registryAddress,
        uint256 numeraire,
        address stable,
        address stakeContract,
        address irmAddress,
        address tokenShop
    ) external payable {
        require(initialized == false);
        _registryAddress = registryAddress;
        owner = _owner;
        debt._collThres = 150;
        debt._liqThres = 110;
        debt._numeraire = uint8(numeraire);
        _stable = stable;
        _stakeContract = stakeContract;
        _irmAddress = irmAddress;
        _tokenShop = tokenShop; //Variable only added for the paper trading competition

        initialized = true;

        //Following logic added only for the paper trading competition
        //All new vaults are initiated with $1.000.000 worth of Numeraire
        uint256 UsdValue = 1000000 * FixedPointMathLib.WAD; //Can be optimised by saving as constant, to lazy now
        _mintNumeraire(UsdValue);
    }

    /** 
    @notice The function used to deposit assets into the proxy vault by the proxy vault owner.
    @dev All arrays should be of same length, each index in each array corresponding
         to the same asset that will get deposited. If multiple asset IDs of the same contract address
         are deposited, the assetAddress must be repeated in assetAddresses.
         The ERC20 get deposited by transferFrom. ERC721 & ERC1155 using safeTransferFrom.
         Can only be called by the proxy vault owner to avoid attacks where malicous actors can deposit 1 wei assets,
         increasing gas costs upon credit issuance and withrawals.
         Example inputs:
            [wETH, DAI, Bayc, Interleave], [0, 0, 15, 2], [10**18, 10**18, 1, 100], [0, 0, 1, 2]
            [Interleave, Interleave, Bayc, Bayc, wETH], [3, 5, 16, 17, 0], [123, 456, 1, 1, 10**18], [2, 2, 1, 1, 0]
    @param assetAddresses The contract addresses of the asset. For each asset to be deposited one address,
                          even if multiple assets of the same contract address are deposited.
    @param assetIds The asset IDs that will be deposited for ERC721 & ERC1155. 
                    When depositing an ERC20, this will be disregarded, HOWEVER a value (eg. 0) must be filled!
    @param assetAmounts The amounts of the assets to be deposited. 
    @param assetTypes The types of the assets to be deposited.
                      0 = ERC20
                      1 = ERC721
                      2 = ERC1155
                      Any other number = failed tx
  */
    function deposit(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        uint256[] calldata assetTypes
    ) external payable override onlyTokenShop {
        uint256 assetAddressesLength = assetAddresses.length;

        require(
            assetAddressesLength == assetIds.length &&
                assetAddressesLength == assetAmounts.length &&
                assetAddressesLength == assetTypes.length,
            "Length mismatch"
        );

        require(
            IRegistry(_registryAddress).batchIsWhiteListed(
                assetAddresses,
                assetIds
            ),
            "Not all assets are whitelisted!"
        );

        for (uint256 i; i < assetAddressesLength; ) {
            if (assetTypes[i] == 0) {
                _depositERC20(msg.sender, assetAddresses[i], assetAmounts[i]);
            } else if (assetTypes[i] == 1) {
                _depositERC721(msg.sender, assetAddresses[i], assetIds[i]);
            } else if (assetTypes[i] == 2) {
                _depositERC1155(
                    msg.sender,
                    assetAddresses[i],
                    assetIds[i],
                    assetAmounts[i]
                );
            } else {
                require(false, "Unknown asset type");
            }
            unchecked {
                ++i;
            }
        }
        emit BatchDeposit(msg.sender, assetAddresses, assetIds, assetAmounts);
    }

    /** 
    @notice The function deposits a single ERC20 into the proxy vault by the proxy vault owner.
    @param assetAddress The contract address of the asset
    @param assetAmount The amount of the asset to be deposited. 
  */
    function depositERC20(address assetAddress, uint256 assetAmount)
        external
        onlyTokenShop
    {
        _depositERC20(msg.sender, assetAddress, assetAmount);
        emit SingleDeposit(msg.sender, assetAddress, 0, assetAmount);
    }

    /** 
    @notice Processes withdrawals of assets by and to the owner of the proxy vault.
    @dev All arrays should be of same length, each index in each array corresponding
         to the same asset that will get withdrawn. If multiple asset IDs of the same contract address
         are to be withdrawn, the assetAddress must be repeated in assetAddresses.
         The ERC20 get withdrawn by transferFrom. ERC721 & ERC1155 using safeTransferFrom.
         Can only be called by the proxy vault owner.
         Will fail if balance on proxy vault is not sufficient for one of the withdrawals.
         Will fail if "the value after withdrawal / open debt (including unrealised debt) > collateral threshold".
         If no debt is taken yet on this proxy vault, users are free to withraw any asset at any time.
         Example inputs:
            [wETH, DAI, Bayc, Interleave], [0, 0, 15, 2], [10**18, 10**18, 1, 100], [0, 0, 1, 2]
            [Interleave, Interleave, Bayc, Bayc, wETH], [3, 5, 16, 17, 0], [123, 456, 1, 1, 10**18], [2, 2, 1, 1, 0]
    @param assetAddresses The contract addresses of the asset. For each asset to be withdrawn one address,
                          even if multiple assets of the same contract address are withdrawn.
    @param assetIds The asset IDs that will be withdrawn for ERC721 & ERC1155. 
                    When withdrawing an ERC20, this will be disregarded, HOWEVER a value (eg. 0) must be filled!
    @param assetAmounts The amounts of the assets to be withdrawn. 
    @param assetTypes The types of the assets to be withdrawn.
                      0 = ERC20
                      1 = ERC721
                      2 = ERC1155
                      Any other number = failed tx
  */
    function withdraw(
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts,
        uint256[] calldata assetTypes
    ) external payable override onlyTokenShop {
        uint256 assetAddressesLength = assetAddresses.length;

        require(
            assetAddressesLength == assetIds.length &&
                assetAddressesLength == assetAmounts.length &&
                assetAddressesLength == assetTypes.length,
            "Length mismatch"
        );

        for (uint256 i; i < assetAddressesLength; ) {
            if (assetTypes[i] == 0) {
                _withdrawERC20(msg.sender, assetAddresses[i], assetAmounts[i]);
            } else if (assetTypes[i] == 1) {
                _withdrawERC721(msg.sender, assetAddresses[i], assetIds[i]);
            } else if (assetTypes[i] == 2) {
                _withdrawERC1155(
                    msg.sender,
                    assetAddresses[i],
                    assetIds[i],
                    assetAmounts[i]
                );
            } else {
                require(false, "Unknown asset type");
            }
            unchecked {
                ++i;
            }
        }
        //No need to check if withdraw would bring collaterisation ratio under treshhold since only tokenShop can withdraw
        emit BatchWithdraw(msg.sender, assetAddresses, assetIds, assetAmounts);
    }

    /** 
    @notice The function withdraws a single ERC20 into the proxy vault by the proxy vault owner.
    @param assetAddress The contract address of the asset
    @param assetAmount The amount of the asset to be deposited. 
  */
    function withdrawERC20(address assetAddress, uint256 assetAmount)
        external
        onlyTokenShop
    {
        _withdrawERC20(msg.sender, assetAddress, assetAmount);
        //No need to check if withdraw would bring collaterisation ratio under treshhold since only tokenShop can withdraw
        emit SingleWithdraw(msg.sender, assetAddress, 0, assetAmount);
    }

    /** 
    @notice Sets the yearly interest rate of the proxy vault, in the form of a 1e18 decimal number.
    @dev First syncs all debt to realise all unrealised debt. Fetches all the asset data and queries the
         Registry to obtain an array of values, split up according to the credit rating of the underlying assets.
  */
    function setYearlyInterestRate() external override {
        require(
            msg.sender == _tokenShop || msg.sender == owner,
            "VPT_SYIR: Not Allowed"
        );
        syncDebt();
        uint256 minCollValue;
        //gas: can't overflow: uint128 * uint16 << uint256
        unchecked {
            minCollValue = (uint256(debt._openDebt) * debt._collThres) / 100;
        }
        (
            address[] memory assetAddresses,
            uint256[] memory assetIds,
            uint256[] memory assetAmounts
        ) = generateAssetData();
        uint256[] memory ValuesPerCreditRating = IRegistry(_registryAddress)
            .getListOfValuesPerCreditRating(
                assetAddresses,
                assetIds,
                assetAmounts,
                debt._numeraire
            );

        _setYearlyInterestRate(ValuesPerCreditRating, minCollValue);
    }

    /** 
    @notice Internal function to take out credit.
    @dev Syncs debt to cement unrealised debt. 
         MinCollValue is calculated without unrealised debt since it is zero.
         Gets the total value of assets per credit rating.
         Calculates and sets the yearly interest rate based on the values per credit rating and the debt to be taken out.
         Mints stablecoin directly in the vault.
  */
    function _takeCredit(
        uint128 amount,
        address[] memory _assetAddresses,
        uint256[] memory _assetIds,
        uint256[] memory _assetAmounts
    ) internal override {
        syncDebt();

        uint256 minCollValue;
        //gas: can't overflow: uint129 * uint16 << uint256
        unchecked {
            minCollValue =
                uint256((uint256(debt._openDebt) + amount) * debt._collThres) /
                100;
        }

        uint256[] memory valuesPerCreditRating = IRegistry(_registryAddress)
            .getListOfValuesPerCreditRating(
                _assetAddresses,
                _assetIds,
                _assetAmounts,
                debt._numeraire
            );
        uint256 vaultValue = sumElementsOfList(valuesPerCreditRating);

        require(
            vaultValue >= minCollValue,
            "Cannot take this amount of extra credit!"
        );

        _setYearlyInterestRate(valuesPerCreditRating, minCollValue);

        //gas: can only overflow when total opendebt is
        //above 340 billion billion *10**18 decimals
        //could go unchecked as well, but might result in opendebt = 0 on overflow
        debt._openDebt += amount;

        //Following logic added only for the paper trading competition: minst stable directly in the vault
        IERC20(_stable).mint(address(this), amount);
        _depositERC20(address(this), _stable, amount);
        emit SingleDeposit(address(this), _stable, 0, amount);
    }

    /** 
    @notice Function used by owner of the proxy vault to repay any open debt.
    @dev Amount of debt to repay in same decimals as the stablecoin decimals.
         Amount given can be greater than open debt. Will only transfer the required
         amount from the user's balance.
    @param amount Amount of debt to repay.
  */
    function repayDebt(uint256 amount) public override onlyOwner {
        syncDebt();

        // if a user wants to pay more than their open debt
        // we should only take the amount that's needed
        // prevents refunds etc
        uint256 openDebt = debt._openDebt;
        uint256 transferAmount = openDebt > amount ? amount : openDebt;

        _withdrawERC20(address(this), _stable, transferAmount);
        emit SingleWithdraw(address(this), _stable, 0, transferAmount);

        IERC20(_stable).burn(transferAmount);

        //gas: transferAmount cannot be larger than debt._openDebt,
        //which is a uint128, thus can't underflow
        assert(openDebt >= transferAmount);
        unchecked {
            debt._openDebt -= uint128(transferAmount);
        }

        // if interest is calculated on a fixed rate, set interest to zero if opendebt is zero
        // todo: can be removed safely?
        if (getOpenDebt() == 0) {
            debt._yearlyInterestRate = 0;
        }
    }

    /** 
    @notice Function to reward the vault with $20000 worth of Numeraire.
    @dev Function can only be called by the factory, when a specific event was triggered to earn the reward.
    @dev Each vault can receive a maximum of 5 rewards (10% of the starting capital).
  */
    function receiveReward() external onlyFactory {
        require(rewards < 5, "VPT_RR: Max rewards received.");
        unchecked {
            ++rewards;
        }

        uint256 UsdValue = 20000 * FixedPointMathLib.WAD; //Can be optimised by saving as constant, too lazy now
        _mintNumeraire(UsdValue);
    }

    function _mintNumeraire(uint256 UsdValue) internal {
        address[] memory addressArr = new address[](1);
        uint256[] memory idArr = new uint256[](1);
        uint256[] memory amountArr = new uint256[](1);

        addressArr[0] = _stable;
        idArr[0] = 0;
        amountArr[0] = FixedPointMathLib.WAD;

        uint256 rateStableToUsd = IRegistry(_registryAddress).getTotalValue(
            addressArr,
            idArr,
            amountArr,
            0
        );
        uint256 stableAmount = FixedPointMathLib.mulDivUp(
            UsdValue,
            FixedPointMathLib.WAD,
            rateStableToUsd
        );
        IERC20(_stable).mint(address(this), stableAmount);
        _depositERC20(address(this), _stable, stableAmount);
        emit SingleDeposit(address(this), _stable, 0, stableAmount);
    }
}