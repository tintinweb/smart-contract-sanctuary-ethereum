/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the decimal points used by the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    
    /**
     * @dev Burns `amount` of token, shringking total supply
     */
    function burn(uint amount) external;

    /**
     * @dev Mints `amount` of token to address `to` increasing total supply
     */
    function mint(address to, uint amount) external;

    //For testing
    function addMinter(address minter_) external;
}

interface IYearnVault is IERC20{
    //Getter functions for public vars
    function token() external view returns (IERC20);
    function depositLimit() external view returns (uint);  // Limit for totalAssets the Vault can hold
    function debtRatio() external view returns (uint);  // Debt ratio for the Vault across all strategies (in BPS, <= 10k)
    function totalDebt() external view returns (uint);  // Amount of tokens that all strategies have borrowed
    function lastReport() external view returns (uint);  // block.timestamp of last report
    function activation() external view returns (uint);  // block.timestamp of contract deployment
    function lockedProfit() external view returns (uint); // how much profit is locked and cant be withdrawn
    function lockedProfitDegradation() external view returns (uint); // rate per block of degradation. DEGRADATION_COEFFICIENT is 100% per block

    //Function interfaces
    function deposit(uint _amount,  address recipient) external returns (uint);
    function withdraw(uint maxShares, address recipient, uint maxLoss) external returns (uint);
    function maxAvailableShares() external returns (uint);
    function pricePerShare() external view returns (uint);
    function totalAssets() external view returns (uint);
}

contract YearnFed{

    IYearnVault public vault;
    IERC20 public underlying;
    address public chair; // Fed Chair
    address public gov;
    uint public supply;
    uint public maxLossBpContraction;
    uint public maxLossBpTakeProfit;

    event Expansion(uint amount);
    event Contraction(uint amount);

    /**
    @param vault_ Address of the yearnV2 vault the Fed will deploy capital to
    @param gov_ Address of governance. This address will receive profits generated, and may perform privilegede actions
    @param maxLossBpContraction_ Maximum allowed loss in vault share value, when contracting supply of underlying.
     Denominated in basis points. 1 = 0.01%
    @param maxLossBpTakeProfit_ Maximum allowed loss in vault share value, when taking profit from the vault.
     Denominated in basis points. 1 = 0.01%
    */
    constructor(IYearnVault vault_, address gov_, uint maxLossBpContraction_, uint maxLossBpTakeProfit_) {
        vault = vault_;
        underlying = IERC20(vault_.token());
        underlying.approve(address(vault), type(uint256).max);
        chair = msg.sender;
        maxLossBpContraction = maxLossBpContraction_;
        maxLossBpTakeProfit = maxLossBpTakeProfit_;
        gov = gov_;
    }

    /**
    @notice Method for gov to change gov address
    */
    function changeGov(address newGov_) public {
        require(msg.sender == gov, "ONLY GOV");
        gov = newGov_;
    }

    /**
    @notice Method for gov to change the chair
    */
    function changeChair(address newChair_) public {
        require(msg.sender == gov, "ONLY GOV");
        chair = newChair_;
    }
    /**
    @notice Method for governance to set max loss in basis points, when withdraing from yearn vault
    @param newMaxLossBpContraction new maximally allowed loss in Bp 1 = 0.01%
    */
    function setMaxLossBpContraction(uint newMaxLossBpContraction) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossBpContraction <= 10000, "MAXLOSS OVER 100%");
        maxLossBpContraction = newMaxLossBpContraction;
    }

    /**
    @notice Method for governance to set max loss in basis points, when taking profit from yearn vault
    @param newMaxLossBpTakeProfit new maximally allowed loss in Bp 1 = 0.01%
    */
    function setMaxLossBpTakeProfit(uint newMaxLossBpTakeProfit) public {
        require(msg.sender == gov, "ONLY GOV");
        require(newMaxLossBpTakeProfit <= 10000, "MAXLOSS OVER 100%");
        maxLossBpTakeProfit = newMaxLossBpTakeProfit;
    }

    /**
    @notice Method for withdrawing any token from the contract to governance. Should only be used in emergencies.
    @param token Address of token contract to withdraw to gov
    @param amount Amount of tokens to withdraw
    */
    function emergencyWithdraw(address token, uint amount) public{
        require(msg.sender == gov, "ONLY GOV");
        require(token != address(vault), "FORBIDDEN TOKEN");
        IERC20(token).transfer(gov, amount);
    }

    /**
    @notice Method for current chair of the Yearn FED to resign
    */
    function resign() public {
        require(msg.sender == chair, "ONLY CHAIR");
        chair = address(0);
    }

    /**
    @notice Deposits amount of underlying tokens into yEarn vault

    @param amount Amount of underlying token to deposit into yEarn vault
    */
    function expansion(uint amount) public {
        require(msg.sender == chair, "ONLY CHAIR");
        //Alternatively set amount to max uint if over deposit limit,
        //as that supplies greatest possible amount into vault
        /*
        if( amount > _maxDeposit()){
            amount = type(uint256).max;
        }
        */
        require(amount <= _maxDeposit(), "AMOUNT TOO BIG"); // can't deploy more than max
        underlying.mint(address(this), amount);
        uint shares = vault.deposit(amount, address(this));
        require(shares > 0);
        supply = supply + amount;
        emit Expansion(amount);
    }

    /**
    @notice Withdraws an amount of underlying token to be burnt, contracting supply
    
    @dev Its recommended to always broadcast withdrawl transactions(contraction & takeProfits)
    through a frontrun protected RPC like Flashbots RPC.
    
    @param amountUnderlying The amount of underlying tokens to withdraw. Note that more tokens may
    be withdrawn than requested, as price is calculated by debts to strategies, but strategies
    may have outperformed price of underlying token.
    If underlyingWithdrawn exceeds supply, the remainder is returned as profits
    */
    function contraction(uint amountUnderlying) public {
        require(msg.sender == chair, "ONLY CHAIR");
        uint underlyingWithdrawn = _withdrawAmountUnderlying(amountUnderlying, maxLossBpContraction);
        _contraction(underlyingWithdrawn);
    }
    /**
    @notice Withdraws every vault share, leaving no dust.
    @dev If the vault shares are worth less than the underlying supplied,
    then it may result in some bad debt being left in the vault.
    This can happen due to transaction fees or slippage incurred by withdrawing from the vault
    */
    function contractAll() public {
        require(msg.sender == chair, "ONLY CHAIR");
        uint underlyingWithdrawn = vault.withdraw(vault.balanceOf(address(this)), address(this), maxLossBpContraction);
        _contraction(underlyingWithdrawn);
    }

    /**
    @notice Burns the amount of underlyingWithdrawn.
    If the amount exceeds supply, the surplus is sent to governance as profit
    @param underlyingWithdrawn Amount of underlying that has successfully been withdrawn
    */
    function _contraction(uint underlyingWithdrawn) internal {
        require(underlyingWithdrawn > 0, "NOTHING WITHDRAWN");
        if(underlyingWithdrawn > supply){
            underlying.burn(supply);
            underlying.transfer(gov, underlyingWithdrawn-supply);
            emit Contraction(supply);
            supply = 0;
        } else {
            underlying.burn(underlyingWithdrawn);
            supply = supply - underlyingWithdrawn;
            emit Contraction(underlyingWithdrawn);
        }   
    }

    /**
    @notice Withdraws the profit generated by yEarn vault

    @dev See dev note on Contraction method
    */
    function takeProfit() public {
        uint expectedBalance = vault.balanceOf(address(this))*vault.pricePerShare()/10**vault.decimals();
        if(expectedBalance > supply){
            uint expectedProfit = expectedBalance - supply;
            if(expectedProfit > 0) {
                uint actualProfit = _withdrawAmountUnderlying(expectedProfit, maxLossBpTakeProfit);
                require(actualProfit > 0, "NO PROFIT");
                underlying.transfer(gov, actualProfit);
            }
        }
    }

    /**
    @notice calculates the amount of shares needed for withdrawing amount of underlying, and withdraws that amount.

    @dev See dev note on Contraction method

    @param amount The amount of underlying tokens to withdraw.
    @param maxLossBp The maximally acceptable loss in basis points. 1 = 0.01%
    */
    function _withdrawAmountUnderlying(uint amount, uint maxLossBp) internal returns (uint){
        uint sharesNeeded = amount*10**vault.decimals()/vault.pricePerShare();
        return vault.withdraw(sharesNeeded, address(this), maxLossBp);
    }

    /**
    @notice calculates the maximum possible deposit for the yearn vault
    */
    function _maxDeposit() view internal returns (uint) {
        if(vault.totalAssets() > vault.depositLimit()){
            return 0;
        }
        return vault.depositLimit() - vault.totalAssets();
    }
}