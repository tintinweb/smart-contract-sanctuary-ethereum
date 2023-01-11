// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice DIctates how the price of the token is increased post every sale
enum PriceModifier {
    None,
    Fixed,
    Exponential,
    InverseLog
}

struct VariablePriceContract {
    // the price of the token
    uint256 price;
        // how the price is modified
    PriceModifier priceModifier;
    // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
    uint256 priceModifierFactor;
    // max price for the token
    uint256 maxPrice;
}

struct VariablePriceStorage {
    // the price of the token
    VariablePriceContract variablePrices;
}

/// @notice common struct definitions for tokens
interface IVariablePrice {
    /// @notice get the increased price of the token
    function getIncreasedPrice() external view returns (uint256);

    /// @notice get the increased price of the token
    function getTokenPrice() external view returns (VariablePriceContract memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IVariablePrice.sol";

library VariablePriceLib {
    event VariablePriceChanged(
        address eventContract,
        VariablePriceContract price
    );

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.nextblock.bitgem.app.VariablePriceStorage.storage");

    /// @notice get the storage for variable pricing
    /// @return ds the storage
    function variablePriceStorage()
        internal
        pure
        returns (VariablePriceStorage storage ds) {

        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice update the variable price contract
    /// @param self the variable price contract
    function _updatePrice(VariablePriceContract storage self)
        internal
        returns (uint256 _price, uint256 updatedPrice) {

        _price = self.price;
        _increaseClaimPrice(self);
        updatedPrice = self.price;
    }

    /// @notice get the current price of the claim
    /// @return _price the current price of the claim
    function _currentPrice(VariablePriceContract storage self)
        internal
        view
        returns (uint256 _price) {

        _price = self.price;
    }

    function _setPrice(VariablePriceContract storage self, uint256 _price)
        internal
        returns (uint256 _newPrice) {

        self.price = _price;
        _newPrice = self.price;
    }
    
    /// @notice Increases the price of the claim by the price increase rate
    /// @param self The variable price contract
    function _increaseClaimPrice(VariablePriceContract storage self) internal {
        
        // get the current price
        uint256 currentPrice = self.price;
        // get the current modifier
        PriceModifier currentModifier = self.priceModifier;
        // get the current modifier factor
        uint256 currentModifierFactor = self.priceModifierFactor;

        // fixed price - increase by modifier factor
        if (currentModifier == PriceModifier.Fixed) {
            currentPrice = currentPrice + currentModifierFactor;
        }
        // exponential intcrease
        else if (currentModifier == PriceModifier.Exponential) {
            currentPrice =
                currentPrice +
                (currentPrice / currentModifierFactor);
        }
        // inverse log increase
        else if (currentModifier == PriceModifier.InverseLog) {
            currentPrice =
                currentPrice +
                (currentPrice / (currentModifierFactor * currentPrice));
        } else {
            return;
        }
        // set the new price
        self.price = currentPrice;
    }
}