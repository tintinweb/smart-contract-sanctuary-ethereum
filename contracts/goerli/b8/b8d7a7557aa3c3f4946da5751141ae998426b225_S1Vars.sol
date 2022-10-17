// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Ownable.sol";


contract S1Vars is Ownable {
    // StrategiesData[0] -> TrueFi USDC
    // StrategiesData[1] -> TrueFi USDT
    // StrategiesData[2] -> mStable USDC
    // StrategiesData[3] -> VesperFinance ETH
    // StrategiesData[4] -> VesperFinance DAI
    StrategiesData[5] strategiesData;
    address public swapRouterAddress;
    address public quoterAddress;
    address public wethAddress;
    address public usdtAddress;
    address public usdcAddress;

    // protocols 
    address public trueFiUSDCAddress;
    address public trueFiUSDTAddress;
    address public trueFiTokenAddress;
    address public stakedTrueFiTokenAddress;
    address public farmTrueFiAddress;
    address public notionalAddress;
    address public mStableA;
    address public mStableVaultA;
    address public mUSDAddress;
    address public imUSDAddress;
    address public mtaTokenAddress;
    address public vPoolETH;
    address public vPoolDAI;
    address public vPoolRewardsETH;
    address public vPoolRewardsDAI;
    address public VSPToken;

    struct DepositCurrency {
        bool exists;
        uint16 fee;
    }

    struct StrategiesData {
        uint256[][] feeRanges;
        mapping(address => DepositCurrency) whitelistedDepositCurrencies;
        bool depositsStopped;
        uint8 uniswapSlippage;
        address feeCollector;
    }

    constructor(
        address _swapRouterAddress,
        address _quoterAddress,
        address _wethAddress,
        address _usdtAddress,
        address _usdcAddress
    ) {
        swapRouterAddress = _swapRouterAddress;
        quoterAddress = _quoterAddress;
        wethAddress = _wethAddress;
        usdtAddress = _usdtAddress;
        usdcAddress = _usdcAddress;
    }

    function setStrategiesData(
        uint8 _structIndex,
        address[] calldata _addresses, 
        uint16[] calldata _fees,
        uint256[] calldata _values,
        uint8[] calldata _percents,
        bool _depositsStopped,
        address _feeCollector
    ) external onlyOwner {
        uint256 addressesLen = _addresses.length;
        require(addressesLen == _fees.length, "ERROR: INVALID_PARAMS");
        require(_values.length == _percents.length, "ERROR: INVALID_LENGTH");

        for (uint8 i = 0; i < addressesLen; i+=1) {
            strategiesData[_structIndex].whitelistedDepositCurrencies[_addresses[i]] = DepositCurrency({
                exists: true,
                fee: _fees[i]
            });
        }

        delete strategiesData[_structIndex].feeRanges;
        for (uint256 i = 0; i < _values.length; i+=1) {
            uint256[] memory arr = new uint256[](2);
            arr[0] = _values[i];
            arr[1] = _percents[i];
            strategiesData[_structIndex].feeRanges.push(arr);
        }

        strategiesData[_structIndex].depositsStopped = _depositsStopped;
        strategiesData[_structIndex].uniswapSlippage = 5; // by default the uniswap slippage will be 5 percents
        strategiesData[_structIndex].feeCollector = _feeCollector;
    }

    function setStrategySlippage(uint8 _structIndex, uint8 _uniswapSlippage) external onlyOwner {
        strategiesData[_structIndex].uniswapSlippage = _uniswapSlippage;
    }

    function setTrueFiAddresses(
        address _trueFiUSDCAddress,
        address _trueFiUSDTAddress,
        address _trueFiTokenAddress,
        address _stakedTrueFiTokenAddress,
        address _farmTrueFiAddress
    ) external onlyOwner {
        trueFiUSDCAddress = _trueFiUSDCAddress;
        trueFiUSDTAddress = _trueFiUSDTAddress;
        trueFiTokenAddress = _trueFiTokenAddress;
        stakedTrueFiTokenAddress = _stakedTrueFiTokenAddress;
        farmTrueFiAddress = _farmTrueFiAddress;
    }

    function setmStableAddresses(
        address _mStableA,
        address _mStableVaultA,
        address _mUSDAddress,
        address _imUSDAddress,
        address _mtaTokenAddress
    ) external onlyOwner {
        mStableA = _mStableA;
        mStableVaultA = _mStableVaultA;
        mUSDAddress = _mUSDAddress;
        imUSDAddress = _imUSDAddress;
        mtaTokenAddress = _mtaTokenAddress;
    }

    function setVesperFinanceAddresses(
        address _vPoolETH,
        address _vPoolDAI,
        address _vPoolRewardsETH,
        address _vPoolRewardsDAI,
        address _VSPToken
    ) external onlyOwner {
        vPoolETH = _vPoolETH;
        vPoolDAI = _vPoolDAI;
        vPoolRewardsETH = _vPoolRewardsETH;
        vPoolRewardsDAI = _vPoolRewardsDAI;
        VSPToken = _VSPToken;
    }

    function getDepositsStopped(uint8 _structIndex) external view returns(bool) {
        return strategiesData[_structIndex].depositsStopped;
    }

    function getUniswapSlippage(uint8 _structIndex) external view returns(uint8) {
        return strategiesData[_structIndex].uniswapSlippage;
    }

    function getFeeCollector(uint8 _structIndex) external view returns(address) {
        return strategiesData[_structIndex].feeCollector;
    }

    function calculateWithdrawFee(uint8 _structIndex, uint256 _amount) external view returns(uint256) {
        uint256 percentage;
        for (uint256 i = 0; i < strategiesData[_structIndex].feeRanges.length; i+=1) {
            if (_amount < strategiesData[_structIndex].feeRanges[i][0]) {
                percentage = strategiesData[_structIndex].feeRanges[i][1];
                break;
            }
        }

        if (percentage == 0) {
            percentage = strategiesData[_structIndex].feeRanges[strategiesData[_structIndex].feeRanges.length - 1][1];
        }
        return percentage;
    }

    function validateWhitelistedDepositCurrencyFee(uint8 _structIndex, address _token) public view returns(bool) {
        return strategiesData[_structIndex].whitelistedDepositCurrencies[_token].exists;
    }

    function getWhitelistedDepositCurrencyFee(uint8 _structIndex, address _token) public view returns(uint16) {
        return strategiesData[_structIndex].whitelistedDepositCurrencies[_token].fee;
    }
}

// MN bby ¯\_(ツ)_/¯