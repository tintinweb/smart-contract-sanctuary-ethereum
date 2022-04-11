//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract UserModule {
    /**
     * @dev User function to supply.
     * @param token_ address of token.
     * @param amount_ amount to supply.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external returns (uint256 vtokenAmount_) {}

    /**
     * @dev User function to withdraw.
     * @param amount_ amount to withdraw.
     * @param to_ address to send tokens to.
     * @return vtokenAmount_ amount of vTokens burnt from caller
     */
    function withdraw(uint256 amount_, address to_)
        external
        returns (uint256 vtokenAmount_)
    {}

    /**
     * @dev If ratio is below then this function will allow anyone to swap from steth -> weth.
     * @param amt_ amount of stEth to swap for weth.
     */
    function leverage(
        uint amt_
    ) external {}

    /**
     * @dev If ratio is above then this function will allow anyone to payback WETH and withdraw astETH to msg.sender at 1:1 ratio.
     * @param amt_ amount of weth to swap for steth.
     */
    function deleverage(
        uint amt_
    ) external {}

    event supplyLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event withdrawLog(
        uint256 amount_,
        address indexed caller_,
        address indexed to_
    );

    event leverageLog(
        uint amt_
    );

    event deleverageLog(
        uint amt_
    );
}

contract RebalancerModule {
    /**
     * @dev low gas function just to collect profit.
     * @notice Collected the profit & leave it in the DSA itself to optimize further on gas.
     * @param isWeth what token to swap. WETH or stETH.
     * @param withdrawAmt_ need to borrow any weth amount or withdraw steth for swaps from Aave position.
     * @param amt_ amount to swap into base vault token.
     * @param unitAmt_ unit amount for swap.
     * @param oneInchData_ 1inch's data for the swaps.
     */
    function collectProfit(
        bool isWeth, // either weth or steth
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_,
        uint256 oneInchData_
    ) external {}

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_, // 1inch's swap amount
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external {}

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 tokenSupplyAmt_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external {}

    event collectProfitLog(
        bool isWeth,
        uint256 withdrawAmt_,
        uint256 amt_,
        uint256 unitAmt_
    );

    event rebalanceOneLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] vaults_,
        uint256[] amts_,
        uint256 leverageAmt_,
        uint256 swapAmt_,
        uint256 tokenSupplyAmt_,
        uint256 tokenWithdrawAmt_,
        uint256 unitAmt_
    );

    event rebalanceTwoLog(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 saveAmt_,
        uint256 unitAmt_
    );
}

contract AdminModule {

    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
    {}

    /**
     * @dev Update withdrawal fee.
     * @param newWithdrawalFee_ new withdrawal fee.
     */
    function updateWithdrawalFee(uint256 newWithdrawalFee_) external {}

    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external {}

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external {}

    /**
     * @dev function to initialize variables
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address rebalancer_,
        address token_,
        address atoken_,
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 idealExcessAmt_,
        uint16[] memory ratios_,
        uint256 swapFee_,
        uint256 saveSlippage_
    ) external {}

    event updateRebalancerLog(address auth_, bool isAuth_);

    event changeStatusLog(uint256 status_);

    event updateRatiosLog(
        uint16 maxLimit,
        uint16 maxLimitGap,
        uint16 minLimit,
        uint16 minLimitGap,
        uint16 stEthLimit,
        uint128 maxBorrowRate
    );

    event updateWithdrawalFeeLog(
        uint256 oldWithdrawalFee_,
        uint256 newWithdrawalFee_
    );

}

contract ReadModule {

    function isRebalancer(address accountAddr_) public view returns (bool) {}

    /**
     * @dev Base token of the vault
     */
    function token() public view returns (address) {}

    /**
     * @dev Minimum token limit used inside the functions
     */
    function tokenMinLimit() public view returns (uint256) {}

    /**
     * @dev atoken of the base token of the vault
     */
    function atoken() public view returns (address) {}

    /**
     * @dev DSA for this particular vault
     */
    function vaultDsa() public view returns (address) {}

    struct Ratios {
        uint16 maxLimit; // Above this withdrawals are not allowed
        uint16 maxLimitGap;
        uint16 minLimit; // After leverage the ratio should be below minLimit & above minLimitGap
        uint16 minLimitGap;
        uint16 stEthLimit; // if 7500. Meaning stETH collateral covers 75% of the ETH debt. Excess ETH will be covered by token limit.
        // send borrow rate in 4 decimals from UI. In the smart contract it'll convert to 27 decimals which where is 100%
        uint128 maxBorrowRate; // maximum borrow rate above this leveraging should not happen
    }

    /**
     * @dev Ratios to set particular limits on leveraging, saving and risks of the vault.
     */
    function ratios() public view returns (Ratios memory) {}

    /**
     * @dev last stored revenue exchange price
     */
    function lastRevenueExchangePrice() public view returns (uint256) {}

    /**
     * @dev cut to take from the profits
     */
    function revenueFee() public view returns (uint256) {}

    /**
     * @dev base token revenue stored in the vault
     */
    function revenue() public view returns (uint256) {}

    /**
     * @dev ETH revenue stored in the vault
     */
    function revenueEth() public view returns (uint256) {}

    /**
     * @dev Withdrawl Fee of the vault
     */
    function withdrawalFee() public view returns (uint256) {}

    /**
     * @dev extra eth/stETH amount to leave in the vault for easier swaps.
     */
    function idealExcessAmt() public view returns (uint256) {}

    /**
     * @dev Fees of leverage swaps.
     */
    function swapFee() public view returns (uint256) {}
    
    /**
     * @dev Max allowed slippage at the time of saving the vault
     */
    function saveSlippage() public view returns (uint256) {}
}

contract HelperReadFunctions {
    /**
     * @dev Helper function to token balances of everywhere.
     */
    function getVaultBalances()
        public
        view
        returns (
            uint256 tokenCollateralAmt_,
            uint256 stethCollateralAmt_,
            uint256 wethDebtAmt_,
            uint256 tokenVaultBal_,
            uint256 tokenDSABal_,
            uint256 netTokenBal_
        )
    {}

    // returns net eth. net stETH + ETH - net ETH debt.
    function getNewProfits()
        public
        view
        returns (
            uint256 profits_
        )
    {}

    /**
     * @dev Helper function to get current exchange price and new revenue generated.
     */
    function getCurrentExchangePrice()
        public
        view
        returns (uint256 exchangePrice_, uint256 newTokenRevenue_)
    {}
}

contract ERC20Functions {

    function decimals() public view returns (uint8) {}

    function totalSupply() external view returns (uint256) {}

    function balanceOf(address account) external view returns (uint256) {}

    function transfer(address to, uint256 amount) external returns (bool) {}

    function allowance(address owner, address spender) external view returns (uint256) {}

    function approve(address spender, uint256 amount) external returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {}

    function name() external view returns (string memory) {}

    function symbol() external view returns (string memory) {}

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract VaultDummyImplementation is UserModule, RebalancerModule, ReadModule, HelperReadFunctions, ERC20Functions {
    receive() external payable {}
}