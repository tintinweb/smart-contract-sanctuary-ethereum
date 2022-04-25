// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IStarknetCore} from "./interfaces/IStarknetCore.sol";
import {IUniV3OracleAdapter} from "./interfaces/IUniV3OracleAdapter.sol";

contract Observer {

    IStarknetCore public immutable starknetCore;
    IUniV3OracleAdapter public immutable uniV3OracleAdapter;
    address public immutable oracleAdder;

    uint constant UPDATE_UNI_V3_TWAP_GAS = 400000;
    uint constant PERCENTAGE_FACTOR = 1e4;

    struct UniV3Oracle {
        bool initialized;
        address pool; // uniswap v3 pool address
        address baseCurrency; // base currency. to get eth/usd price, eth is base token
        address quoteCurrency; // quote currency. to get eth/usd price, usd is the quote currency
        uint twap; // price of 1 base currency in quote currency. scaled by 1e18
        uint32 twapPeriod; // number of seconds in the past to start calculating time-weighted average
        uint updateDeviationThreshold; // change in twap value to incentivize update, scaled by PERCENTAGE_FACTOR
        uint updateDurationThreshold; // number of seconds after lastUpdatedAt to incentivize update
        uint lastUpdatedAt; // last block.timestamp when twap was called
        uint incentiveBaseFeeMultiplier; // multiplier of base fee to incentivize calling oracle update
        uint incentiveAvailable; // amount of ETH incentive available for incentivizing oracle updates
        uint starknetAddress; // corresponding Starknet contract address
        uint starknetSelector; // corresponding Starknet contract selector
    }

    mapping(bytes32 => UniV3Oracle) public uniV3Oracles;

    event UniV3OracleAdded(
        bytes32 oracleId,
        address pool,
        address baseCurrency,
        address quoteCurrency,
        uint32 twapPeriod,
        uint updateDeviationThreshold,
        uint updateDurationThreshold,
        uint incentiveBaseFeeMultiplier,
        uint starknetAddress,
        uint starknetSelector
    );
    event IncentiveAdded(
        bytes32 oracleId, 
        uint incentiveAvailable,
        address payer,
        uint incentivePaid
    );
    event TwapUpdated(
        bytes32 oracleId, 
        uint twap,
        uint updatedAt,
        address caller,
        uint incentivePaid
    );

    modifier onlyOracleAdder() {
        require(msg.sender == oracleAdder);
        _;
    }

    modifier onlyInitializedUniV3Oracle(bytes32 oracleId) {
        require(uniV3Oracles[oracleId].initialized == true);
        _;
    }

    constructor(address starknetCoreAddr, address uniV3OracleAdapterAddr) {
        starknetCore = IStarknetCore(starknetCoreAddr);
        uniV3OracleAdapter = IUniV3OracleAdapter(uniV3OracleAdapterAddr);
        oracleAdder = msg.sender;
    }

    function addUniV3Oracle(
        address pool,
        address baseCurrency,
        address quoteCurrency,
        uint32 twapPeriod,
        uint updateDeviationThreshold,
        uint updateDurationThreshold,
        uint incentiveBaseFeeMultiplier,
        uint starknetAddress,
        uint starknetSelector
    ) external payable onlyOracleAdder {
        bytes32 oracleId = keccak256(
            abi.encodePacked(
                pool,
                baseCurrency,
                quoteCurrency,
                twapPeriod,
                updateDeviationThreshold,
                updateDurationThreshold,
                incentiveBaseFeeMultiplier,
                starknetAddress
            )
        );
        uint twap = uniV3OracleAdapter.getTwap(
            pool,
            baseCurrency,
            quoteCurrency,
            twapPeriod,
            true
        );
        uniV3Oracles[oracleId] = UniV3Oracle(
            {
                initialized: true, 
                pool: pool,
                baseCurrency: baseCurrency,
                quoteCurrency: quoteCurrency,
                twap: twap,
                twapPeriod: twapPeriod,
                updateDeviationThreshold: updateDeviationThreshold,
                updateDurationThreshold: updateDurationThreshold,
                lastUpdatedAt: block.timestamp,
                incentiveBaseFeeMultiplier: incentiveBaseFeeMultiplier,
                incentiveAvailable: msg.value,
                starknetAddress: starknetAddress,
                starknetSelector: starknetSelector
            }
        );

        uint[] memory payload = new uint[](2);
        payload[0] = twap;
        payload[1] = block.timestamp;
        starknetCore.sendMessageToL2(starknetAddress, starknetSelector, payload);

        if(msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        }

        emit UniV3OracleAdded(
            oracleId,
            pool,
            baseCurrency,
            quoteCurrency,
            twapPeriod,
            updateDeviationThreshold,
            updateDurationThreshold,
            incentiveBaseFeeMultiplier,
            starknetAddress,
            starknetSelector
        );
        emit IncentiveAdded(
            oracleId, 
            msg.value,
            msg.sender,
            msg.value
        );
        emit TwapUpdated(
            oracleId, 
            twap, 
            block.timestamp, 
            msg.sender, 
            msg.value
        );
    }

    function addUniV3Incentive(bytes32 oracleId) external payable onlyInitializedUniV3Oracle(oracleId) {
        require(msg.value > 0, "requires msg.value > 0");

        uint prevIncentiveAvailable = uniV3Oracles[oracleId].incentiveAvailable;
        uniV3Oracles[oracleId].incentiveAvailable = prevIncentiveAvailable + msg.value;
        payable(msg.sender).transfer(msg.value);

        emit IncentiveAdded(
            oracleId, 
            uniV3Oracles[oracleId].incentiveAvailable,
            msg.sender,
            msg.value
        );
    }

    function updateUniV3Oracle(bytes32 oracleId) external onlyInitializedUniV3Oracle(oracleId) {
        uint prevTwap = uniV3Oracles[oracleId].twap;
        uint prevLastUpdatedAt = uniV3Oracles[oracleId].lastUpdatedAt;

        uint twap = uniV3OracleAdapter.getTwap(
            uniV3Oracles[oracleId].pool,
            uniV3Oracles[oracleId].baseCurrency,
            uniV3Oracles[oracleId].quoteCurrency,
            uniV3Oracles[oracleId].twapPeriod,
            false
        );
        uniV3Oracles[oracleId].twap = twap;
        uniV3Oracles[oracleId].lastUpdatedAt = block.timestamp;

        uint[] memory payload = new uint[](2);
        payload[0] = twap;
        payload[1] = block.timestamp;
        starknetCore.sendMessageToL2(uniV3Oracles[oracleId].starknetAddress, uniV3Oracles[oracleId].starknetSelector, payload);

        uint incentivePaid = 0;
        if(uniV3Oracles[oracleId].incentiveAvailable > 0) {
            if(_checkDeviationThreshold(oracleId, prevTwap, twap) || _checkDurationThreshold(oracleId, prevLastUpdatedAt)) {
                uint incentiveAvailable = uniV3Oracles[oracleId].incentiveAvailable;
                uint amountOwed = (UPDATE_UNI_V3_TWAP_GAS * block.basefee * uniV3Oracles[oracleId].incentiveBaseFeeMultiplier) / PERCENTAGE_FACTOR;
                if(incentiveAvailable >= amountOwed) {
                    payable(msg.sender).transfer(amountOwed);
                    incentivePaid = amountOwed;
                }else{
                    payable(msg.sender).transfer(incentiveAvailable);
                    incentivePaid = incentiveAvailable;
                }
                uniV3Oracles[oracleId].incentiveAvailable = incentiveAvailable - incentivePaid;
            }
        }

        emit TwapUpdated(
            oracleId, 
            twap, 
            block.timestamp, 
            msg.sender, 
            incentivePaid
        );
    }

    function checkThresholds(bytes32 oracleId) public view onlyInitializedUniV3Oracle(oracleId) returns (bool deviationThreshold, bool durationThreshold) {
        uint prevTwap = uniV3Oracles[oracleId].twap;
        uint prevLastUpdatedAt = uniV3Oracles[oracleId].lastUpdatedAt;

        uint twap = uniV3OracleAdapter.getTwap(
            uniV3Oracles[oracleId].pool,
            uniV3Oracles[oracleId].baseCurrency,
            uniV3Oracles[oracleId].quoteCurrency,
            uniV3Oracles[oracleId].twapPeriod,
            false
        );

        deviationThreshold = _checkDeviationThreshold(oracleId, prevTwap, twap);
        durationThreshold = _checkDurationThreshold(oracleId, prevLastUpdatedAt);
    }

    function _checkDeviationThreshold(bytes32 oracleId, uint prevTwap, uint newTwap) internal view returns (bool deviationThreshold) {
        uint twapDeviation;
        if(newTwap >= prevTwap) {
            twapDeviation = ((newTwap - prevTwap) * PERCENTAGE_FACTOR) / prevTwap;
        }else {
            twapDeviation = ((prevTwap - newTwap) * PERCENTAGE_FACTOR) / prevTwap;
        }
        deviationThreshold = (twapDeviation >= uniV3Oracles[oracleId].updateDeviationThreshold);
    }

    function _checkDurationThreshold(bytes32 oracleId, uint prevLastUpdatedAt) internal view returns (bool durationThreshold) {
        uint timeDiff = block.timestamp - prevLastUpdatedAt;
        durationThreshold = (timeDiff >= uniV3Oracles[oracleId].updateDurationThreshold);
    }
}

pragma solidity =0.8.10;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

interface IUniV3OracleAdapter {
    function getTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) external view returns (uint256);
}