/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

interface IAaveLendingPool {
    function deposit(address _reserve, uint256 _amount, address _onBehalfOf,uint16 _referralCode) external;
    function withdraw(address _reserve, uint256 _amount, address _onBehalfOf) external;
}

interface ICompoundUsdcPool {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOf(address account) external view returns (uint256);
}

contract BridgeDeFi {
    IERC20 public usdc = IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422);    // Used in Aave
    IERC20 public aUsdc = IERC20(0xe12AFeC5aa12Cf614678f9bFeeB98cA9Bb95b5B0);
    IAaveLendingPool public aaveLendingPool = IAaveLendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    uint256 constant public MAX_INT_NUMBER = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    IERC20 public usdCoin = IERC20(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede); // Used in compound
    ICompoundUsdcPool public compoundPool = ICompoundUsdcPool(0x4a92E71227D294F041BD82dd8f78591B75140d63);

    uint256 constant public AAVE_DEPOSIT_PERCENTAGE = 70;
    uint256 constant public COMPOUND_DEPOSIT_PERCENTAGE = 30;

    address constant public PROTOCOL_ADDRESS = 0xe04cb04127915b2D1E1Fdcb9625F32965bC00c1B;
    uint256 constant public PROTOCOL_PERCENTAGE = 60;
    uint256 constant public USER_PERCENTAGE = 40;

    mapping(address => uint256) public userDepositedUsdc;
    mapping(address => uint256) public userDepositedInAave;
    mapping(address => uint256) public userDepositedInCompound;
    
    constructor() public {
        usdc.approve(address(aaveLendingPool), MAX_INT_NUMBER);
        usdCoin.approve(address(compoundPool), MAX_INT_NUMBER);
    }
    
    function userDepositUsdc(uint256 _amountInUsdc) external {
        userDepositedUsdc[msg.sender] = userDepositedUsdc[msg.sender] + _amountInUsdc;

        require(usdc.transferFrom(msg.sender, address(this), _amountInUsdc), "USDC Transfer failed!");

        aaveLendingPool.deposit(address(usdc), _amountInUsdc, address(this), 0);
    }
    
    function userWithdrawUsdc(uint256 _amountInUsdc) external {
        require(userDepositedUsdc[msg.sender] >= _amountInUsdc, "Cannot withdraw more than deposited!");

        aaveLendingPool.withdraw(address(usdc), _amountInUsdc, address(this));
        
        userDepositedUsdc[msg.sender] = userDepositedUsdc[msg.sender] - _amountInUsdc;
        usdc.transfer(msg.sender, _amountInUsdc);
    }

    function withdrawUsdcPrincipalAndYieldAccrued() external {
        uint256 availableBalance = aUsdc.balanceOf(address(this));
        require(availableBalance >= 0, "Nothing to withdraw!");

        aaveLendingPool.withdraw(address(usdc), availableBalance, address(this));
        
        userDepositedUsdc[msg.sender] = 0;
        usdc.transfer(msg.sender, availableBalance);
    }

    function withdrawUsdcWithYieldAccrued(uint256 _amountInUsdc) external {
        require(userDepositedUsdc[msg.sender] >= _amountInUsdc, "Cannot withdraw more than deposited!");

        uint256 totalBalance = aUsdc.balanceOf(address(this));
        require(totalBalance >= 0, "Nothing to withdraw!");

        uint256 yieldAccrued = totalBalance - _amountInUsdc;
        uint256 userShare = yieldAccrued * USER_PERCENTAGE / 100;

        uint256 protocolShare = yieldAccrued - userShare;

        aaveLendingPool.withdraw(address(usdc), totalBalance, address(this));
        
        userDepositedUsdc[msg.sender] = userDepositedUsdc[msg.sender] - _amountInUsdc;
        usdc.transfer(msg.sender, _amountInUsdc + userShare);
        if (protocolShare > 0) {
            usdc.transfer(PROTOCOL_ADDRESS, protocolShare);
        }
    }

    function depositInPool(uint256 _amountInUsdc) external {
        userDepositedUsdc[msg.sender] = userDepositedUsdc[msg.sender] + _amountInUsdc;

        uint256 aaveDepositAmount = _amountInUsdc * AAVE_DEPOSIT_PERCENTAGE / 100;
        uint256 compoundDepositAmount = _amountInUsdc - aaveDepositAmount;

        userDepositedInAave[msg.sender] = userDepositedInAave[msg.sender] + aaveDepositAmount;
        userDepositedInCompound[msg.sender] = userDepositedInCompound[msg.sender] + compoundDepositAmount;

        require(usdc.transferFrom(msg.sender, address(this), aaveDepositAmount), "AAVE USDC Transfer failed!");

        aaveLendingPool.deposit(address(usdc), aaveDepositAmount, address(this), 0);

        require(usdCoin.transferFrom(msg.sender, address(this), compoundDepositAmount), "Compound USDC Transfer failed!");

        compoundPool.mint(compoundDepositAmount);
    }

    function withdrawFromPool(uint256 _amountInUsdc) external {
        require(userDepositedUsdc[msg.sender] >= _amountInUsdc, "Cannot withdraw more than deposited!");

        uint256 aaveWithdrawAmount = _amountInUsdc * AAVE_DEPOSIT_PERCENTAGE / 100;
        uint256 compoundWithdrawAmount = _amountInUsdc - aaveWithdrawAmount;

        aaveLendingPool.withdraw(address(usdc), aaveWithdrawAmount, address(this));
        compoundPool.redeemUnderlying(compoundWithdrawAmount);
        
        userDepositedUsdc[msg.sender] = userDepositedUsdc[msg.sender] - _amountInUsdc;
        userDepositedInAave[msg.sender] = userDepositedInAave[msg.sender] - aaveWithdrawAmount;
        userDepositedInCompound[msg.sender] = userDepositedInCompound[msg.sender] - compoundWithdrawAmount;
        usdc.transfer(msg.sender, aaveWithdrawAmount);
        usdCoin.transfer(msg.sender, compoundWithdrawAmount);
    }

    function withdrawFromPoolPrincipalAndYieldAccrued() external {
        uint256 availableBalanceInAave = aUsdc.balanceOf(address(this));
        require(availableBalanceInAave >= 0, "Nothing to withdraw!");

        uint256 availableBalanceInCompound = compoundPool.balanceOf(address(this));
        require(availableBalanceInCompound >= 0, "Nothing to withdraw!");

        aaveLendingPool.withdraw(address(usdc), availableBalanceInAave, address(this));
        compoundPool.redeem(availableBalanceInCompound);
    }

    function transferToProtocol() external {
        uint256 availableUsdcBalance = usdc.balanceOf(address(this));
        usdc.transfer(PROTOCOL_ADDRESS, availableUsdcBalance);
        uint256 availableUsdCoinBalance = usdCoin.balanceOf(address(this));
        usdCoin.transfer(PROTOCOL_ADDRESS, availableUsdCoinBalance);
    }
}