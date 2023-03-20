// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWosMarketplace {
    
    function BuyArtifact(
        address contractAddress,
        uint256 aType,
        uint256 amount
    ) external;

    function BuyOilWell(
        uint256 bars,
        uint256 nonce,
        bytes32 intent,
        uint256 timestamp,
        bytes[] memory signatures
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./interfaces/IWosMarketplace.sol";

contract MassiveBuy {
    IWosMarketplace wosMarketplace;

    struct BuyWell {
        uint256 bars;
        bytes32 intent;
        uint256 nonce;
        uint256 timestamp;
        bytes[] signatures;
    }

    constructor(IWosMarketplace _wosMarketplace) {
        wosMarketplace = _wosMarketplace;
    }

    function buy(BuyWell[] memory wells) external {
        for (uint i = 0; i < wells.length; i++) {
            BuyWell memory well = wells[i];
            wosMarketplace.BuyOilWell(
                well.bars,
                well.nonce,
                well.intent,
                well.timestamp,
                well.signatures
            );
        }
    }
}