/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.6.7;

interface ExternallyFundedOSM {
    function updateResult() external;
}

interface OracleRelayer {
    function updateCollateralPrice(bytes32 collateralType) external;
}

interface CoinMedianizer {
    function updateResult(address feeReceiver) external;
}

interface RateSetter {
    function updateRate(address feeReceiver) external;
}

interface CoinJoin {
    function exit(address to, uint256 wad) external;
    function systemCoin() external returns (address);
}

interface SafeEngine {
    function coinBalance(address user) external returns (uint256);
    function approveSAFEModification(address) external;
}

interface Erc20 {
    function balanceOf(address user) external returns (uint256);
    function transfer(address to, uint256 wad) external;
}

contract PingerBundledCall {
    address owner;
    ExternallyFundedOSM public osmEthA;
    OracleRelayer public oracleRelayer;
    CoinMedianizer public coinMedianizer;
    RateSetter public rateSetter;
    CoinJoin public coinJoin;
    bytes32 ETH_A = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    
    constructor(address osmEthA_, address oracleRelayer_, address coinMedianizer_, address rateSetter_, address _owner, address _coinJoin, address _safeEngine) public {
        osmEthA = ExternallyFundedOSM(osmEthA_);
        oracleRelayer = OracleRelayer(oracleRelayer_);
        rateSetter = RateSetter(rateSetter_);
        coinMedianizer = CoinMedianizer(coinMedianizer_);
        owner = _owner;
        coinJoin = CoinJoin(_coinJoin);

        SafeEngine(_safeEngine).approveSAFEModification(_coinJoin);
    }

    function updateOsmAndEthAOracleRelayer() external {
        osmEthA.updateResult();
        oracleRelayer.updateCollateralPrice(ETH_A);
    }

    function updateOsmAndOracleRelayer(address osm, bytes32 collateralType) external {
        ExternallyFundedOSM(osm).updateResult();
        oracleRelayer.updateCollateralPrice(collateralType);
    }

    function updateCoinMedianizerAndRateSetter(address feeReceiver) external {
        coinMedianizer.updateResult(feeReceiver);
        rateSetter.updateRate(feeReceiver);
    }

    function withdrawPayout(address to, uint256 wad) external {
        require(msg.sender == owner, "Not owner");

        coinJoin.exit(address(this), wad);
        Erc20(coinJoin.systemCoin()).transfer(to, wad);
    }


}