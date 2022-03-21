/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IWETHGateway {
  function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;
  function withdrawETH(address lendingPool, uint256 amount, address onBehalfOf) external;
  function repayETH(address lendingPool, uint256 amount, uint256 rateMode, address onBehalfOf) external payable;
  function borrowETH(address lendingPool, uint256 amount, uint256 interesRateMode, uint16 referralCode) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TimeLock {

    IWETHGateway internal immutable IAAVE;
    IERC20 internal immutable aWETH;
    address internal lendingPool;

    uint256 public immutable lockDuration;
    mapping (address => uint256) private _timesOfDeposit;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _shares;
    uint256 public numberOfUsers;

    /**
     * IMPORTANT: 
     * Two decimal precision is being used, which means 1% is represented as 100.
     * During each calculation with this precision there will be an error of
     * about 1 USD at the current ETH price because of the integer division in solidity.
     * It also means that by default 100% of shares will be 10000 shares at the begining.
     * I have used small precision because it is easier to spot errors during the tests.
     * In production it would be better to use highest precision possible.
     */
    uint256 private constant FIFTY_PERCENT = 5000; // 50% in two decimals precision // 5000 equals to 50.00% 
    uint256 private constant ONE_HUNDRED_PERCENT = 10000; // 100% in two decimals precision // 10000 equals to 100.00% 
    uint256 private _totalShares;

    constructor (uint256 timePeriodInSeconds) {
        IAAVE = IWETHGateway(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70);
        aWETH = IERC20(address(0x0087b1f4cf9bd63f7bbd3ee1ad04e8f52540349347));
        lendingPool = address(0x00e0fba4fc209b4948668006b2be61711b7f465bae);
        lockDuration = timePeriodInSeconds;
    }

    // #### Event definitions

    /**
     * @dev Emitted when ETH is wrapped, deposited into Lending Pool and aWETH is received.
     */
    event Deposit(uint256 amountDeposited);

    /**
     * @dev Emitted when aWETH is returned to Lending Pool and ETH is sent to user.
     */
    event Withdraw(uint256 amountWithdrawn);

    /**
     * @dev Returns the number of shares the given amount would produce.
     *
     * Note that if there are no deposits (no users), the first depositor will own 100% od shares.
     */
    function _estimateNumberOfShares(uint256 amount) internal view returns (uint256 newShares) {
        if (numberOfUsers == 0) {
            return ONE_HUNDRED_PERCENT;
        }
        uint256 newSharesPercent = ONE_HUNDRED_PERCENT * amount / aWETH.balanceOf(address(this)); // amount/balance = x/ONE_HUNDRED_PERCENT => x = ONE_HUNDRED_PERCENT * amount / balance 
        newShares = _totalShares * newSharesPercent / ONE_HUNDRED_PERCENT; // newSharesPercent/ONE_HUNDRED_PERCENT = x/_totalShares => x = _totalShares * newSharesPercent/ONE_HUNDRED_PERCENT
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `amount` cannot be the zero.
     * - `amount` has to match the ETH sent in transaction.
     * - the caller must have a balance of at least `amount`.
     *
     * Emits a {Deposit} event.
     */
    function deposit(uint256 amount) external payable {
        require(amount > 0, "Sent amount is zero.");
        require(msg.value == amount, "Sent amount does not match the declared amount.");
        uint256 newShares = _estimateNumberOfShares(amount);
        if (_balances[msg.sender] == 0) {
            numberOfUsers++;
        } 
        _shares[msg.sender] += newShares;
        _totalShares += newShares;
        _timesOfDeposit[msg.sender] = block.timestamp;
        _balances[msg.sender] += amount;
        _deposit(amount);
        emit Deposit(amount);
    }

    /**
     * @dev Returns the user balance with interest included.
     *
     * Note that there are no time related checks because the purpose is to estimate the total balance.
     * of a specific user and not how much that user can withdraw.
     */
    function _estimateUserBalance(address userAddress) internal view returns (uint256 estimatedUserBalance) {
        if (numberOfUsers == 1) {
            return aWETH.balanceOf(address(this));
        }
        uint256 userSharesPercent = ONE_HUNDRED_PERCENT * _shares[userAddress] / _totalShares; // x/ONE_HUNDRED_PERCENT = us/ts => x = ONE_HUNDRED_PERCENT * us/ts
        return aWETH.balanceOf(address(this)) * userSharesPercent / ONE_HUNDRED_PERCENT; // w/total = usp/ONE_HUNDRED_PERCENT => w = total * usp/ONE_HUNDRED_PERCENT
    }

    /**
     * @dev Returns the estimation of funds available for a withdrawal to given user. 
     *
     * Note that there will be penalties for premature withdrawal attempt. Potential penalties are included in the estimation.
     */
    function _estimateWithdrawalAmount(address userAddress) internal view returns (uint256 estimatedWithdrawalAmount) {
        if (numberOfUsers == 1) {
            return aWETH.balanceOf(address(this));
        }
        uint256 percentToWithdraw = ONE_HUNDRED_PERCENT; 
        uint256 timePassed = block.timestamp - _timesOfDeposit[userAddress];
        if (timePassed <  lockDuration) {
            uint percentOfTimePassed = ONE_HUNDRED_PERCENT * timePassed / lockDuration; // FORMULA: timePassed / lockDuration = percentOfTimePassed / ONE_HUNDRED_PERCENT => percentOfTimePassed =  ONE_HUNDRED_PERCENT * timePassed / lockDuration
            percentToWithdraw = FIFTY_PERCENT + percentOfTimePassed / 2; // guaranteed 50% of withfrawal + percentOfTimePassed scaled from 0 - 100% to 0 - 50% to match the weight 
        }
        uint256 userSharesPercent = ONE_HUNDRED_PERCENT * _shares[userAddress] / _totalShares; // x/ONE_HUNDRED_PERCENT = us/ts => x = ONE_HUNDRED_PERCENT * us/ts
        // percentToWithdraw / ONE_HUNDRED_PERCENT  = x / userSharesPercent => x = userSharesPercent * percentToWithdraw / ONE_HUNDRED_PERCENT 
        uint256 finalPercent = userSharesPercent * percentToWithdraw / ONE_HUNDRED_PERCENT; // w/total = usp/ONE_HUNDRED_PERCENT => w = total * usp/ONE_HUNDRED_PERCENT
        return aWETH.balanceOf(address(this)) * finalPercent / ONE_HUNDRED_PERCENT;
    }

    /**
     * @dev See {_estimateWithdrawalAmount}.
     *
     * Note that this is the external interface for _estimateWithdrawalAmount function.
     */
    function estimateWithdrawalAmount() external view returns (uint256 estimatedWithdrawalAmount) {
        return _estimateWithdrawalAmount(msg.sender);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Transfers all funds to a user, including the intitial balance and potential inerest and penalties. 
     *
     * User balance is reset to zero, number of shares owned by user is reset to zero, total number
     * of shares in contract is decreased by the number of user shares used for a withdrawal. The time of
     * deposit for a user is reset to zero. Number of users is decreased by one.
     *
     * Requirements:
     *
     * - the caller must have some balance.
     *
     * Emits a {Withdraw} event.
     */
    function withdrawAll() external {
        require(_balances[msg.sender] != 0, "User has no deposit."); 
        uint256 amountToWithdraw = _estimateWithdrawalAmount(msg.sender);
        _balances[msg.sender] = 0;
        numberOfUsers--;
        _shares[msg.sender] = 0;
        _totalShares -= _estimateNumberOfShares(amountToWithdraw);
        _timesOfDeposit[msg.sender] = 0;
        _withdraw(msg.sender, amountToWithdraw);
        emit Withdraw(amountToWithdraw);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Transfers entire interest earned to a user. User deposit stays intact, the time of deposit is reset.
     *
     * The number of shares user owns are decreased by the amount of shares used to withdraw the interest. 
     * Total number of shares in contract is decreased by the number of user shares used for a withdrawal
     * Requirements:
     *
     * - the caller must have some balance.
     * - the caller must have some interest earned.
     *
     * Emits a {Withdraw} event.
     */
    function withdrawInterest() external {
        require(_balances[msg.sender] != 0, "User has no deposit."); 
        require(_balances[msg.sender] < _estimateUserBalance(msg.sender), "User has no interest."); 
        uint256 userInterest = _estimateUserBalance(msg.sender) - _balances[msg.sender];
        _shares[msg.sender] = _estimateNumberOfShares(_balances[msg.sender]);
        _totalShares -= _estimateNumberOfShares(userInterest);
        _timesOfDeposit[msg.sender] = block.timestamp;
        _withdraw(msg.sender, userInterest);
        emit Withdraw(userInterest);
    }

    /**
     * @dev See {IWETHGateway-withdrawETH}.
     *
     * Note that this is the internal interface for IWETHGateway-withdrawETH function.
     */
    function _withdraw(address userAddress, uint amount) internal {
        IAAVE.withdrawETH(lendingPool, amount, userAddress);
    }

    /**
     *@dev See {IWETHGateway-depositETH}.
     *
     * Note that this is the internal interface for IWETHGateway-depositETH function.
     */
    function _deposit(uint256 amount) internal {
        IAAVE.depositETH{value:amount}(lendingPool, address(this), 0);
    }
}