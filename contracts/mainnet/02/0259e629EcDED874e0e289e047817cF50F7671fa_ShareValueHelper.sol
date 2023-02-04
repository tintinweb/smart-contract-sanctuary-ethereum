pragma solidity 0.8.6;

interface IVault {
    function totalSupply() external view returns (uint);
    function lockedProfitDegradation() external view returns (uint);
    function lastReport() external view returns (uint);
    function totalAssets() external view returns (uint);
    function lockedProfit() external view returns (uint);
}

/// @title Share Value Helper
/// @dev This works on all Yearn vaults 0.4.0+
/// @dev Achieves a higher precision conversion than pricePerShare; particularly for tokens with < 18 decimals.
contract ShareValueHelper {

    /// @notice Helper function to convert shares to underlying amount with exact precision
    function sharesToAmount(address vault, uint shares) external view returns (uint) {
        uint totalSupply = IVault(vault).totalSupply();
        if (totalSupply == 0) return shares;

        uint freeFunds = calculateFreeFunds(vault);
        return (
            shares
            * freeFunds
            / totalSupply
        );
    }

    /// @notice Helper function to convert underlying amount to shares with exact precision
    function amountToShares(address vault, uint amount) external view returns (uint) {
        uint totalSupply = IVault(vault).totalSupply();
        if (totalSupply > 0) {
            return amount * totalSupply / calculateFreeFunds(vault);
        }
        return amount;
    }
    
    function calculateFreeFunds(address vault) public view returns (uint) {
        uint totalAssets = IVault(vault).totalAssets();
        uint lockedFundsRatio = (block.timestamp - IVault(vault).lastReport()) * IVault(vault).lockedProfitDegradation();

        if (lockedFundsRatio < 10 ** 18) {
            uint lockedProfit = IVault(vault).lockedProfit();
            lockedProfit -= (
                lockedFundsRatio
                * lockedProfit
                / 10 ** 18
            );
            return totalAssets - lockedProfit;
        }
        else {
            return totalAssets;
        }
    }
}