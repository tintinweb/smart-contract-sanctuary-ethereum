//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Events {
    event LogAaveV2Import(
        address indexed user,
        bool convertStable,
        address[] supplyTokens,
        address[] borrowTokens,
        uint[] supplyAmts,
        uint[] stableBorrowAmts,
        uint[] variableBorrowAmts
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Stores } from "../common/stores.sol";
import { AaveLendingPoolProviderInterface, AaveDataProviderInterface } from "./interfaces.sol";

abstract contract Helpers is Stores {
    /**
     * @dev Aave referal code
     */
    uint16 constant internal referalCode = 3228;

    /**
     * @dev Aave Provider
     */
    AaveLendingPoolProviderInterface constant internal aaveProvider = AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    /**
     * @dev Aave Data Provider
     */
    AaveDataProviderInterface constant internal aaveData = AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    function getIsColl(address token, address user) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface AaveInterface {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveDataProviderInterface {
    function getUserReserveData(address _asset, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
    function getReserveConfigurationData(address asset) external view returns (
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );

    function getReserveTokensAddresses(address asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
}

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenInterface {
    function scaledBalanceOf(address _user) external view returns (uint256);
    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);
    function balanceOf(address _user) external view returns(uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function allowance(address, address) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { TokenInterface } from "../common/interfaces.sol";
import { AaveInterface, ATokenInterface } from "./interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract AaveResolver is Helpers, Events {
    function _TransferAtokens(
        uint _length,
        AaveInterface aave,
        ATokenInterface[] memory atokenContracts,
        uint[] memory amts,
        address[] memory tokens,
        address userAccount
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                uint256 _amt = amts[i];
                require(atokenContracts[i].transferFrom(userAccount, address(this), _amt), "allowance?");
                
                if (!getIsColl(tokens[i], address(this))) {
                    aave.setUserUseReserveAsCollateral(tokens[i], true);
                }
            }
        }
    }

    function _borrowOne(AaveInterface aave, address token, uint amt, uint rateMode) private {
        aave.borrow(token, amt, rateMode, referalCode, address(this));
    }

    function _paybackBehalfOne(AaveInterface aave, address token, uint amt, uint rateMode, address user) private {
        aave.repay(token, amt, rateMode, user);
    }

    function _BorrowStable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _borrowOne(aave, tokens[i], amts[i], 1);
            }
        }
    }

    function _BorrowVariable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _borrowOne(aave, tokens[i], amts[i], 2);
            }
        }
    }

    function _PaybackStable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 1, user);
            }
        }
    }

    function _PaybackVariable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 2, user);
            }
        }
    }

    function getBorrowAmount(address _token, address userAccount) 
        internal
        view
        returns
    (
        uint256 stableBorrow,
        uint256 variableBorrow
    ) {
        (
            ,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        ) = aaveData.getReserveTokensAddresses(_token);

        stableBorrow = ATokenInterface(stableDebtTokenAddress).balanceOf(userAccount);
        variableBorrow = ATokenInterface(variableDebtTokenAddress).balanceOf(userAccount);
    }
}

contract AaveImportHelpers is AaveResolver {
    struct ImportData {
        address[] _supplyTokens;
        address[] _borrowTokens;
        ATokenInterface[] aTokens;

        uint[] supplyAmts;
        uint[] supplySplitAmts;
        uint[] supplyFinalAmts;

        uint[] variableBorrowAmts;
        uint[] variableBorrowFinalAmts;
        uint[] variableBorrowSplitAmts;
        uint[] variableBorrowAmtsWithFee;
        uint[] variableBorrowFinalAmtsWithFee;
        uint[] variableBorrowSplitAmtsWithFee;

        uint[] totalBorrowAmts;
        uint[] totalBorrowAmtsFinalAmts;
        uint[] totalBorrowAmtsSplitAmts;
        uint[] totalBorrowAmtsWithFee;
        uint[] totalBorrowAmtsFinalAmtsWithFee;
        uint[] totalBorrowAmtsSplitAmtsWithFee;

        uint[] stableBorrowAmts;
        uint[] stableBorrowSplitAmts;
        uint[] stableBorrowFinalAmts;
        uint[] stableBorrowAmtsWithFee;
        uint[] stableBorrowSplitAmtsWithFee;
        uint[] stableBorrowFinalAmtsWithFee;
    }

    struct ImportInputData {
        address[] supplyTokens;
        address[] borrowTokens;
        bool convertStable;
        uint256 times;
        bool isFlash;
        uint[] flashFees;
    }

    function getBorrowAmounts (
        address userAccount,
        AaveInterface aave,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal returns(ImportData memory) {
        if (inputData.borrowTokens.length > 0) {
            data._borrowTokens = new address[](inputData.borrowTokens.length);

            data.variableBorrowAmts = new uint[](inputData.borrowTokens.length);
            data.variableBorrowSplitAmts = new uint256[](inputData.borrowTokens.length);
            data.variableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            data.variableBorrowAmtsWithFee = new uint[](inputData.borrowTokens.length);
            data.variableBorrowFinalAmtsWithFee = new uint256[](inputData.borrowTokens.length);
            data.variableBorrowSplitAmtsWithFee = new uint256[](inputData.borrowTokens.length);
    
            data.stableBorrowAmts = new uint[](inputData.borrowTokens.length);
            data.stableBorrowSplitAmts = new uint256[](inputData.borrowTokens.length);
            data.stableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            data.stableBorrowAmtsWithFee = new uint[](inputData.borrowTokens.length);
            data.stableBorrowSplitAmtsWithFee = new uint256[](inputData.borrowTokens.length);
            data.stableBorrowFinalAmtsWithFee = new uint256[](inputData.borrowTokens.length);

            data.totalBorrowAmts = new uint[](inputData.borrowTokens.length);
            data.totalBorrowAmtsWithFee = new uint[](inputData.borrowTokens.length);
            data.totalBorrowAmtsSplitAmts = new uint256[](inputData.borrowTokens.length);
            data.totalBorrowAmtsFinalAmts = new uint256[](inputData.borrowTokens.length);
            data.totalBorrowAmtsFinalAmtsWithFee = new uint256[](inputData.borrowTokens.length);
            data.totalBorrowAmtsSplitAmtsWithFee = new uint256[](inputData.borrowTokens.length);

            if (inputData.times > 0) {
                for (uint i = 0; i < inputData.borrowTokens.length; i++) {
                    for (uint j = i; j < inputData.borrowTokens.length; j++) {
                        if (j != i) {
                            require(inputData.borrowTokens[i] != inputData.borrowTokens[j], "token-repeated");
                        }
                    }
                }


                for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
                    address _token = inputData.borrowTokens[i] == ethAddr ? wethAddr : inputData.borrowTokens[i];
                    data._borrowTokens[i] = _token;

                    (
                        data.stableBorrowAmts[i],
                        data.variableBorrowAmts[i]
                    ) = getBorrowAmount(_token, userAccount);

                    if (data.variableBorrowAmts[i] != 0) {
                        data.variableBorrowAmtsWithFee[i] = data.variableBorrowAmts[i] + inputData.flashFees[i];
                    } else {
                        data.stableBorrowAmtsWithFee[i] = data.stableBorrowAmts[i] + inputData.flashFees[i];
                    }

                    data.totalBorrowAmts[i] = data.stableBorrowAmts[i] + data.variableBorrowAmts[i];
                    data.totalBorrowAmtsWithFee[i] = data.stableBorrowAmtsWithFee[i] + data.variableBorrowAmtsWithFee[i];

                    if (data.totalBorrowAmts[i] > 0) {
                        uint256 _amt = inputData.times == 1 ? data.totalBorrowAmts[i] : type(uint256).max;
                        TokenInterface(_token).approve(address(aave), _amt);
                    }
                }

                if (inputData.times == 1) {
                    data.variableBorrowFinalAmts = data.variableBorrowAmts;
                    data.stableBorrowFinalAmts = data.stableBorrowAmts;
                    data.totalBorrowAmtsFinalAmts = data.totalBorrowAmts;

                    data.variableBorrowFinalAmtsWithFee = data.variableBorrowAmtsWithFee;
                    data.stableBorrowFinalAmtsWithFee = data.stableBorrowAmtsWithFee;
                    data.totalBorrowAmtsFinalAmtsWithFee = data.totalBorrowAmtsWithFee;
                } else {
                    for (uint i = 0; i < data.totalBorrowAmts.length; i++) {
                        data.variableBorrowSplitAmts[i] = data.variableBorrowAmts[i] / inputData.times;
                        data.variableBorrowFinalAmts[i] = data.variableBorrowAmts[i] - (data.variableBorrowSplitAmts[i] * (inputData.times - 1));
                        data.stableBorrowSplitAmts[i] = data.stableBorrowAmts[i] / inputData.times;
                        data.stableBorrowFinalAmts[i] = data.stableBorrowAmts[i] - (data.stableBorrowSplitAmts[i] * (inputData.times - 1));
                        data.totalBorrowAmtsSplitAmts[i] = data.totalBorrowAmts[i] / inputData.times;
                        data.totalBorrowAmtsFinalAmts[i] = data.totalBorrowAmts[i] - (data.totalBorrowAmtsSplitAmts[i] * (inputData.times - 1));

                        data.variableBorrowSplitAmtsWithFee[i] = data.variableBorrowAmtsWithFee[i] / inputData.times;
                        data.variableBorrowFinalAmtsWithFee[i] = data.variableBorrowAmtsWithFee[i] - (data.variableBorrowSplitAmtsWithFee[i] * (inputData.times - 1));
                        data.stableBorrowSplitAmtsWithFee[i] = data.stableBorrowAmtsWithFee[i] / inputData.times;
                        data.stableBorrowFinalAmtsWithFee[i] = data.stableBorrowAmtsWithFee[i] - (data.stableBorrowSplitAmtsWithFee[i] * (inputData.times - 1));
                        data.totalBorrowAmtsSplitAmtsWithFee[i] = data.totalBorrowAmtsWithFee[i] / inputData.times;
                        data.totalBorrowAmtsFinalAmtsWithFee[i] = data.totalBorrowAmtsWithFee[i] - (data.totalBorrowAmtsSplitAmtsWithFee[i] * (inputData.times - 1));
                    }
                }
            }
        }
        return data;
    }

    function getBorrowFinalAmounts (
        address userAccount,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal view returns(
        uint[] memory variableBorrowFinalAmts,
        uint[] memory variableBorrowFinalAmtsWithFee,
        uint[] memory stableBorrowFinalAmts,
        uint[] memory stableBorrowFinalAmtsWithFee,
        uint[] memory totalBorrowAmtsFinalAmts,
        uint[] memory totalBorrowAmtsFinalAmtsWithFee
    ) {    
        if (inputData.borrowTokens.length > 0) {
            variableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            variableBorrowFinalAmtsWithFee = new uint256[](inputData.borrowTokens.length);
            stableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            stableBorrowFinalAmtsWithFee = new uint256[](inputData.borrowTokens.length);
            totalBorrowAmtsFinalAmts = new uint[](inputData.borrowTokens.length);
            totalBorrowAmtsFinalAmtsWithFee = new uint[](inputData.borrowTokens.length);

            if (inputData.times > 0) {
                for (uint i = 0; i < data._borrowTokens.length; i++) {
                    address _token = data._borrowTokens[i];
                    (
                        stableBorrowFinalAmts[i],
                        variableBorrowFinalAmts[i]
                    ) = getBorrowAmount(_token, userAccount);

                    if (variableBorrowFinalAmts[i] != 0) {
                        variableBorrowFinalAmtsWithFee[i] = variableBorrowFinalAmts[i] + inputData.flashFees[i];
                    } else {
                        stableBorrowFinalAmtsWithFee[i] = stableBorrowFinalAmts[i] + inputData.flashFees[i];
                    }

                    totalBorrowAmtsFinalAmtsWithFee[i] = stableBorrowFinalAmts[i] + variableBorrowFinalAmts[i];
                }
            }
        }
    }

    function getSupplyAmounts (
        address userAccount,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal view returns(ImportData memory) {
        data.supplyAmts = new uint[](inputData.supplyTokens.length);
        data._supplyTokens = new address[](inputData.supplyTokens.length);
        data.aTokens = new ATokenInterface[](inputData.supplyTokens.length);
        data.supplySplitAmts = new uint[](inputData.supplyTokens.length);
        data.supplyFinalAmts = new uint[](inputData.supplyTokens.length);

        for (uint i = 0; i < inputData.supplyTokens.length; i++) {
            for (uint j = i; j < inputData.supplyTokens.length; j++) {
                if (j != i) {
                    require(inputData.supplyTokens[i] != inputData.supplyTokens[j], "token-repeated");
                }
            }
        }

        for (uint i = 0; i < inputData.supplyTokens.length; i++) {
            address _token = inputData.supplyTokens[i] == ethAddr ? wethAddr : inputData.supplyTokens[i];
            (address _aToken, ,) = aaveData.getReserveTokensAddresses(_token);
            data._supplyTokens[i] = _token;
            data.aTokens[i] = ATokenInterface(_aToken);
            data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
        }

        if ((inputData.times == 1 && inputData.isFlash) || inputData.times == 0) {
            data.supplyFinalAmts = data.supplyAmts;
        } else {
            for (uint i = 0; i < data.supplyAmts.length; i++) {
                uint _times = inputData.isFlash ? inputData.times : inputData.times + 1;
                data.supplySplitAmts[i] = data.supplyAmts[i] / _times;
                data.supplyFinalAmts[i] = data.supplyAmts[i] - (data.supplySplitAmts[i] * (_times - 1));
            }
        }

        return data;
    }

    function getSupplyFinalAmounts(
        address userAccount,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal view returns(uint[] memory supplyFinalAmts) {
        supplyFinalAmts = new uint[](inputData.supplyTokens.length);

        for (uint i = 0; i < data.aTokens.length; i++) {
            supplyFinalAmts[i] = data.aTokens[i].balanceOf(userAccount);
        }
    }
}

contract AaveImportResolver is AaveImportHelpers {

    function _importAave(
        address userAccount,
        ImportInputData memory inputData
    ) internal returns (string memory _eventName, bytes memory _eventParam) {
        require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

        ImportData memory data;

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        data = getBorrowAmounts(userAccount, aave, inputData, data);
        data = getSupplyAmounts(userAccount, inputData, data);

        if (!inputData.isFlash && inputData.times > 0) {
            _TransferAtokens(
                inputData.supplyTokens.length,
                aave,
                data.aTokens,
                data.supplySplitAmts,
                data._supplyTokens,
                userAccount
            );
        } else if (inputData.times == 0) {
            _TransferAtokens(
                inputData.supplyTokens.length,
                aave,
                data.aTokens,
                data.supplyFinalAmts,
                data._supplyTokens,
                userAccount
            );
        }

        for (uint i = 0; i < inputData.times; i++) {
            if (i == (inputData.times - 1)) {

                if (!inputData.isFlash && inputData.times == 1) {
                    data.supplyFinalAmts = getSupplyFinalAmounts(userAccount, inputData, data);
                }

                if (inputData.times > 1) {
                    (
                        ,
                        data.variableBorrowFinalAmtsWithFee,
                        ,
                        data.stableBorrowFinalAmtsWithFee,
                        ,
                        data.totalBorrowAmtsFinalAmtsWithFee
                    ) = getBorrowFinalAmounts(userAccount, inputData, data);
                    
                    data.supplyFinalAmts = getSupplyFinalAmounts(userAccount, inputData, data);
                }

                _PaybackStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowFinalAmts, userAccount);
                _PaybackVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowFinalAmts, userAccount);
                _TransferAtokens(inputData.supplyTokens.length, aave, data.aTokens, data.supplyFinalAmts, data._supplyTokens, userAccount);

                if (inputData.convertStable) {
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.totalBorrowAmtsFinalAmtsWithFee);
                } else {
                    _BorrowStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowFinalAmtsWithFee);
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowFinalAmtsWithFee);
                }

            } else {

                _PaybackStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowSplitAmts, userAccount);
                _PaybackVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowSplitAmts, userAccount);
                _TransferAtokens(inputData.supplyTokens.length, aave, data.aTokens, data.supplySplitAmts, data._supplyTokens, userAccount);

                if (inputData.convertStable) {
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.totalBorrowAmtsSplitAmtsWithFee);
                } else {
                    _BorrowStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowSplitAmtsWithFee);
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowSplitAmtsWithFee);
                }

            }
        }

        _eventName = "LogAaveV2Import(address,bool,address[],address[],uint256[],uint256[],uint256[])";
        _eventParam = abi.encode(
            userAccount,
            inputData.convertStable,
            inputData.supplyTokens,
            inputData.borrowTokens,
            data.supplyAmts,
            data.stableBorrowAmts,
            data.variableBorrowAmts
        );
    }

    function importAave(
        address userAccount,
        ImportInputData memory inputData
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        (_eventName, _eventParam) = _importAave(userAccount, inputData);
    }


    function migrateAave(
        ImportInputData memory inputData
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (_eventName, _eventParam) = _importAave(msg.sender, inputData);
    }
}

contract ConnectV2AaveV2Import is AaveImportResolver {

    string public constant name = "AaveV2-Import-v2";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}