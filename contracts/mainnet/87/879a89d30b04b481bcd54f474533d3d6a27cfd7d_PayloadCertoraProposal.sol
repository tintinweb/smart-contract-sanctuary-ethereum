// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibPropConstants} from "./LibPropConstants.sol";
import {IERC20} from "./IERC20.sol";

interface IControllerAaveEcosystemReserve {
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}

interface ISablier {
    function createStream(
        address recipient, 
        uint256 deposit, 
        address tokenAddress, 
        uint256 startTime, 
        uint256 stopTime
    ) external returns (uint256);

    function withdrawFromStream(uint256 streamId, uint256 amount) external returns (bool);

    function balanceOf(uint256 streamId, address who) external view returns (uint256);

    function nextStreamId() external view returns (uint256);
}

interface ICollector {
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}

interface IPool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}


contract PayloadCertoraProposal {

    // Return the price of AAVE in USDC using the Oracle's decimals, and the decimals used
    function getPriceOfAAVEinUSDC() public view returns (uint256,uint8) {
        AggregatorV3Interface oracle = AggregatorV3Interface(LibPropConstants.AAVE_USD_CHAINLINK_ORACLE);
        (, int256 aavePrice, uint startedAt, , ) = oracle.latestRoundData();
        uint freshTime = 3 /* days */ * 24 /* hours */ * 60 /* minutes */ * 60 /* seconds */; // using "days" leads to "Expected primary expression" error
        require (startedAt > block.timestamp - freshTime, "price is not fresh");
        require (aavePrice > 0, "aave price must be positive");

        uint8 priceDecimals = oracle.decimals();
        return (uint256(aavePrice), priceDecimals);
    }

    // formally verify me please :-)
    function convertUSDCAmountToAAVE(uint256 usdcAmount) public view returns (uint256) {
        uint8 usdcDecimals = IERC20(LibPropConstants.USDC_TOKEN).decimals();
        uint8 aaveDecimals = IERC20(LibPropConstants.AAVE_TOKEN).decimals();

        (uint aavePrice, uint8 priceDecimals) = getPriceOfAAVEinUSDC();
        
        /**
            aave_amount = ((usdcAmount / 10**usdcDecimals) * 10**aaveDecimals )/  (aavePrice / 10**oracleDecimals )
         */
        uint256 aaveAmount = usdcAmount * 10**priceDecimals * 10**aaveDecimals 
                                / (aavePrice * 10**usdcDecimals);
        return aaveAmount;
    }


    // LO: Consider using address(this) instead of SHORT_EXECUTOR - changed
    function execute() external {
        uint256 totalAaveAmount = convertUSDCAmountToAAVE(
                LibPropConstants.AAVE_VEST_USDC_WORTH + LibPropConstants.AAVE_FUND_USDC_WORTH
            );
        uint256 vestAaveAmount = convertUSDCAmountToAAVE(LibPropConstants.AAVE_VEST_USDC_WORTH);
        uint256 fundAaveAmount = convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH);
        require (totalAaveAmount - 1 <= vestAaveAmount + fundAaveAmount && vestAaveAmount + fundAaveAmount <= totalAaveAmount + 1, "not addditive");

        /**
            1. Transfer a total worth of $900,000 in AAVE tokens from the EcosystemReserve to the 
            ShortExecutor using the Ecosystem Reserve Controller contract at 0x1E506cbb6721B83B1549fa1558332381Ffa61A93.
        */
        IControllerAaveEcosystemReserve(LibPropConstants.ECOSYSTEM_RESERVE_CONTROLLER).transfer(
            IERC20(LibPropConstants.AAVE_TOKEN),
            address(this),
            totalAaveAmount
        );

        /**
            2. Approve $700,000 worth of AAVE tokens to Sablier.
         */
        require(IERC20(LibPropConstants.AAVE_TOKEN).allowance(address(this), LibPropConstants.SABLIER) == 0, "Allowance to sablier is not zero");
        IERC20(LibPropConstants.AAVE_TOKEN).approve(LibPropConstants.SABLIER, vestAaveAmount);

        /**
            3. Create a Sablier stream with Certora as the beneficiary, to stream the $700,000 worth of Aave over 6 months.
         */
        uint currentTime = block.timestamp;
        uint sixMonthsDuration = 6 * 30 days;
        uint actualAmount = (vestAaveAmount / sixMonthsDuration) * sixMonthsDuration; // rounding
        //console.logUint(vestAaveAmount-actualAmount); // 15281152
        require(vestAaveAmount - actualAmount < 1e18, "losing more than 1 AAVE due to rounding");
        uint streamIdAaveVest = ISablier(LibPropConstants.SABLIER).createStream(
            LibPropConstants.CERTORA_BENEFICIARY,
            actualAmount,
            LibPropConstants.AAVE_TOKEN,
            currentTime,
            currentTime + sixMonthsDuration
        );
        require (streamIdAaveVest > 0, "invalid stream id");

        /**
            4. Approve $200,000 worth of AAVE to a multisig co-controlled by the Certora team and Aave community members.
         */
        IERC20(LibPropConstants.AAVE_TOKEN).transfer(LibPropConstants.CERTORA_AAVE_MULTISIG, fundAaveAmount);

        /**
            5. Transfer the USDC amount (USDC 1,000,000) from the Aave Collector to the ShortExecutor - 
            uses new controller after proposal 61,
            first transferring aUSDC and then withdrawing it from the pool to the executor.
         */
        uint totalUSDCAmount = LibPropConstants.USDC_VEST;
        ICollector(LibPropConstants.AAVE_COLLECTOR /* new controller after proposal 61*/).transfer(
            IERC20(LibPropConstants.AUSDC_TOKEN),
            address(this),
            totalUSDCAmount
        );

        IPool(LibPropConstants.POOL).withdraw(
            address(LibPropConstants.USDC_TOKEN),
            totalUSDCAmount,
            address(this)
        );

        /**
            6. Approve full USDC amount to Sablier.
         */
        require(IERC20(LibPropConstants.USDC_TOKEN).allowance(address(this), LibPropConstants.SABLIER) == 0, "Allowance to sablier is not zero");
        IERC20(LibPropConstants.USDC_TOKEN).approve(LibPropConstants.SABLIER, totalUSDCAmount);
        
        /**
            7. Create a Sablier stream with Certora as the beneficiary, to stream the USDC amount over 6 months.
         */
        actualAmount = (totalUSDCAmount / sixMonthsDuration) * sixMonthsDuration; // rounding
        //console.logUint(totalUSDCAmount - actualAmount); // 6400000
        require(totalUSDCAmount - actualAmount < 10e6, "losing more than 10 USDC due to rounding");
        uint streamIdUSDCVest = ISablier(LibPropConstants.SABLIER).createStream(
            LibPropConstants.CERTORA_BENEFICIARY, 
            actualAmount,
            LibPropConstants.USDC_TOKEN,
            currentTime, 
            currentTime + sixMonthsDuration
        );
        require (streamIdUSDCVest > 0, "invalid stream id");
    }
}