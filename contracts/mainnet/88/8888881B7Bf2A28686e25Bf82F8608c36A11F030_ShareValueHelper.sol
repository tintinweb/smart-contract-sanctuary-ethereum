/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

pragma solidity 0.8.6;

interface IVault {
    function totalSupply() external view returns (uint);
    function lockedProfitDegradation() external view returns (uint);
    function lastReport() external view returns (uint);
    function totalAssets() external view returns (uint);
    function lockedProfit() external view returns (uint);
}

contract ShareValueHelper {

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

    function amountToShares(address vault, uint amount) external view returns (uint) {
        uint totalSupply = IVault(vault).totalSupply();
        if (totalSupply > 0) {
            return amount * totalSupply / calculateFreeFunds(vault);
        }
        return 0;
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