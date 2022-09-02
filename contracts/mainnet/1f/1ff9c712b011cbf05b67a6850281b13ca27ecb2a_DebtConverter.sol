pragma solidity ^0.8.0;

import { IOracle } from "./interfaces/IOracle.sol";
import { ICToken } from "./interfaces/ICToken.sol";
import { ERC20 } from "./interfaces/ERC20.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IFeed } from "./interfaces/IFeed.sol";

contract DebtConverter is ERC20 {
    //Current amount of DOLA-denominated debt accrued by the DebtConverter contract.
    uint public outstandingDebt;

    //Cumulative amount of DOLA-denominated debt accrued by the DebtConverter contract over its lifetime.
    uint public cumDebt;

    //Cumulative amount of DOLA repaid to the DebtConverter contract over its lifetime.
    uint public cumDolaRepaid;

    //Exchange rate of DOLA IOUs to DOLA scaled by 1e18. Default is 1e18.
    //DOLA IOU amount * exchangeRateMantissa / 1e18 = DOLA amount received on redemption
    //Bad Debt $ amount * 1e18 / exchangeRateMantissa = DOLA IOUs received on conversion
    uint public exchangeRateMantissa = 1e18;

    //The amount that exchangeRateMantissa will increase every second. This is how “interest” is accrued.
    uint public exchangeRateIncreasePerSecond;

    //Timestamp of the last time `accrueInterest()` was called.
    uint public lastAccrueInterestTimestamp;

    //Current repayment epoch
    uint public repaymentEpoch;

    //anToken address => maximum price this contract will pay for 1 underlying of the anToken on a call to `convert()`
    //Make sure to use 18 decimals!
    //0 = no maximum price
    mapping(address => uint256) public maxConvertPrice;

    //user address => epoch => Conversion struct
    mapping(address => ConversionData[]) public conversions;
    
    //epoch => Repayment struct
    mapping(uint => RepaymentData) public repayments;

    //user address => bool. True if DOLA IOU transfers to this address are allowed, false by default.
    mapping(address => bool) public transferWhitelist;

    //Can perform repayments and set interest rates.
    address public owner;

    //Treasury address buying the debt.
    address public treasury;

    //Can set privileged roles and sweep tokens.
    address public governance;

    //Frontier master oracle.
    IOracle public immutable oracle;

    //DOLA contract
    address public constant DOLA = 0x865377367054516e17014CcdED1e7d814EDC9ce4;
    address public constant anEth = 0x697b4acAa24430F254224eB794d2a85ba1Fa1FB8;
    address public constant anYfi = 0xde2af899040536884e062D3a334F2dD36F34b4a4;
    address public constant anBtc = 0x17786f3813E6bA35343211bd8Fe18EC4de14F28b;

    //Errors
    error TransferToAddressNotWhitelisted();
    error OnlyOwner();
    error OnlyGovernance();
    error InsufficientDebtTokens(uint needed, uint actual);
    error InsufficientTreasuryFunds(uint needed, uint actual);
    error InvalidDebtToken();
    error DolaAmountLessThanMinOut(uint minOut, uint amount);
    error InsufficientDebtToBeRepaid(uint repayment, uint debt);
    error ConversionDoesNotExist();
    error ConversionEpochNotEqualToCurrentEpoch(uint conversionEpoch, uint currentEpoch);
    error ThatEpochIsInTheFuture();
    error ConversionHasNotBeenRedeemedBefore();

    //Events
    event NewOwner(address owner);
    event NewTreasury(address treasury);
    event NewGovernance(address governance);
    event NewTransferWhitelistAddress(address whitelistedAddr);
    event NewAnnualExchangeRateIncrease(uint increase);
    event NewMaxConvertPrice(address anToken, uint maxPrice);
    event Repayment(uint dolaAmount, uint epoch);
    event Redemption(address indexed user, uint dolaAmount);
    event Conversion(address indexed user, address indexed anToken, uint epoch, uint dolaAmount, uint underlyingAmount);

    struct RepaymentData {
        uint epoch;
        uint dolaAmount;
        uint pctDolaIOUsRedeemable;
    }

    struct ConversionData {
        uint lastEpochRedeemed;
        uint dolaIOUAmount;
        uint dolaIOUsRedeemed;
    }

    constructor(uint initialIncreasePerYear, address _owner, address _treasury, address _governance, address _oracle) ERC20("DOLA IOU", "DOLAIOU") {
        owner = _owner;
        treasury = _treasury;
        governance = _governance;
        oracle = IOracle(_oracle);
        lastAccrueInterestTimestamp = block.timestamp;
        exchangeRateIncreasePerSecond = initialIncreasePerYear / 365 days;
        emit NewAnnualExchangeRateIncrease(initialIncreasePerYear);
    }

    modifier onlyOwner() {
        if ( msg.sender != owner ) revert OnlyOwner();
        _;
    }

    modifier onlyGovernance() {
        if ( msg.sender != governance ) revert OnlyGovernance();
        _;
    }

    /*
     * @notice function for converting bad debt anTokens to DOLA IOU tokens.
     * @param anToken Address of the bad debt anToken to be converted
     * @param amount Amount of `token` to be converted. 0 = max
     * @param minOut Minimum DOLA amount worth of DOLA IOUs to be received. Will revert if actual amount is lower.
     */
    function convert(address anToken, uint amount, uint minOut) external {
        if (anToken != anYfi && anToken != anBtc && anToken != anEth) revert InvalidDebtToken();
        uint anTokenBal = IERC20(anToken).balanceOf(msg.sender);
        if (amount == 0) amount = anTokenBal;
        if (anTokenBal < amount) revert InsufficientDebtTokens(anTokenBal, amount);

        //Accrue interest so exchange rates are fresh
        accrueInterest();
        
        uint underlyingAmount = ICToken(anToken).balanceOfUnderlying(msg.sender) * amount / ICToken(anToken).balanceOf(msg.sender);
        uint underlyingPrice = oracle.getUnderlyingPrice(anToken);
        
        //Allows operator to set anBtc maxConvertPrice with 18 decimals like other tokens since we normalize it here.
        //This is necessary since underlyingAmount for btc is only 8 decimals, meaning we need 28 decimals in price to offset decimal division we do later
        //`oracle.getUnderlyingPrice()` already returns anBtc price normalized for underlying token decimals, so we use it by itself.
        uint maxConversionPrice = maxConvertPrice[anToken];
        if (anToken == anBtc) {
            maxConversionPrice *= 1e10;
        }
        
        //If underlying is currently worth more than maxConvertPrice[anToken], price becomes maxConvertPrice[anToken]
        if (maxConversionPrice != 0 && underlyingPrice > maxConversionPrice) {
            underlyingPrice = maxConversionPrice;
        }
        uint dolaValueOfDebt = (underlyingPrice * underlyingAmount) / (10 ** 18);
        uint dolaIOUsOwed = convertDolaToDolaIOUs(dolaValueOfDebt);

        if (dolaValueOfDebt < minOut) revert DolaAmountLessThanMinOut(minOut, dolaValueOfDebt);

        outstandingDebt += dolaValueOfDebt;
        cumDebt += dolaValueOfDebt;

        uint epoch = repaymentEpoch;
        ConversionData memory c;
        c.dolaIOUAmount = dolaIOUsOwed;
        c.lastEpochRedeemed = epoch;

        conversions[msg.sender].push(c);

        require(IERC20(anToken).transferFrom(msg.sender, treasury, amount), "failed to transfer anTokens");
        _mint(msg.sender, dolaIOUsOwed);

        emit Conversion(msg.sender, anToken, epoch, dolaValueOfDebt, underlyingAmount);
    }

    /*
     * @notice function for repaying DOLA to this contract. Only callable by owner.
     * @param amount Amount of DOLA to repay & transfer to this contract.
     */
    function repayment(uint amount) external onlyOwner {
        if(amount == 0) return;
        accrueInterest();
        uint _outstandingDebt = outstandingDebt;
        if (amount > _outstandingDebt) revert InsufficientDebtToBeRepaid(amount, _outstandingDebt);
        uint _epoch = repaymentEpoch;

        //Calculate redeemable DOLA ratio for this epoch
        uint pctDolaIOUsRedeemable = amount * 1e18 / _outstandingDebt;

        //Update debt state variables
        outstandingDebt -= amount;
        cumDolaRepaid += amount;

        //Store data from current epoch and update epoch state variables
        repayments[_epoch] = RepaymentData(_epoch, amount, pctDolaIOUsRedeemable);
        repaymentEpoch += 1;
        
        uint senderBalance = IERC20(DOLA).balanceOf(msg.sender);
        if(senderBalance >= amount){
            require(IERC20(DOLA).transferFrom(msg.sender, address(this), amount), "DOLA transfer failed");
        } else {
            revert InsufficientTreasuryFunds(amount, senderBalance);
        }

        emit Repayment(amount, _epoch);
    }

     /*
     * @notice Function for redeeming DOLA IOUs for DOLA. 
     * @param _conversion index of conversion to redeem for
     * @param _epoch repayment epoch to redeem DOLA from
     */
    function redeem(uint _conversion, uint _epoch) internal returns (uint) {
        uint redeemableDolaIOUs = getRedeemableDolaIOUsFor(msg.sender, _conversion, _epoch);
        conversions[msg.sender][_conversion].dolaIOUsRedeemed += redeemableDolaIOUs;
        return redeemableDolaIOUs;
    }

    /*
     * @notice Function wrapper for calling `redeem()`. Will redeem all redeemable epochs for given conversion unless an _endEpoch is provided
     * @param _conversion index of conversion to redeem for
     * @param _endEpoch the last repayment epoch that will be claimed in this call for the given conversion
     */
    function redeemConversion(uint _conversion, uint _endEpoch) public {
        if (_conversion > conversions[msg.sender].length) revert ConversionDoesNotExist();
        accrueInterest();
        ConversionData storage c = conversions[msg.sender][_conversion];
        uint lastEpochRedeemed = c.lastEpochRedeemed;

        uint totalDolaIOUsRedeemable;
        uint totalDolaRedeemable;

        if (_endEpoch > repaymentEpoch) revert ThatEpochIsInTheFuture();

        if (_endEpoch == 0) {
            _endEpoch = repaymentEpoch;
        }

        for (uint i = lastEpochRedeemed; i < _endEpoch;) {
            //Get redeemable DOLA IOUs for this epoch and add to running totals
            uint dolaIOUsRedeemable = redeem(_conversion, i);
            totalDolaIOUsRedeemable += dolaIOUsRedeemable;
            totalDolaRedeemable += convertDolaIOUsToDola(dolaIOUsRedeemable);

            //We keep the loop going
            unchecked { i++; }
        }

        c.lastEpochRedeemed = _endEpoch;

        //After loop breaks: burn DOLA IOUs, transfer DOLA & emit event.
        //This way we don't have to loop these naughty, costly calls
        if (totalDolaIOUsRedeemable > 0) {
            //Handles rounding errors. Will only allow max redemption equal to DOLA balance of this contract
            //User will be able to redeem using this conversion after another repayment to collect their dust
            uint dolaBal = IERC20(DOLA).balanceOf(address(this));
            if (totalDolaRedeemable > dolaBal) {
                //Subtract DOLA difference from dolaRedeemed on this conversion object
                //This way, the user will be able to claim their dust on the next repayment & call to `redeemConversion`
                c.dolaIOUsRedeemed -= convertDolaToDolaIOUs(totalDolaRedeemable - dolaBal);
                totalDolaRedeemable = dolaBal;
                totalDolaIOUsRedeemable = convertDolaToDolaIOUs(totalDolaRedeemable);
            }

            //If user does not have enough DOLA IOUs to fully redeem, will redeem remainder of IOUs
            if (totalDolaIOUsRedeemable > balanceOf(msg.sender)) {
                uint diff = totalDolaIOUsRedeemable - balanceOf(msg.sender);
                c.dolaIOUsRedeemed -= diff;
                totalDolaIOUsRedeemable = balanceOf(msg.sender);
                totalDolaRedeemable = convertDolaIOUsToDola(totalDolaIOUsRedeemable);
            }

            _burn(msg.sender, totalDolaIOUsRedeemable);
            require(IERC20(DOLA).transfer(msg.sender, totalDolaRedeemable), "DOLA transfer failed");
            
            emit Redemption(msg.sender, totalDolaRedeemable);
        }
    }

    /*
     * @notice Redeems all DOLA "dust" leftover from rounding errors.
     * @notice Only redeemable if conversion's lastEpochRedeemed is equal to current repaymentEpoch.
     * Simply call `redeemConversion()` to update your conversions' lastEpochRedeemed
     * @param _conversion index of conversion to redeem dust for
     */
    function redeemConversionDust(uint _conversion) public {
        ConversionData memory c = conversions[msg.sender][_conversion];
        if (c.lastEpochRedeemed != repaymentEpoch) revert ConversionEpochNotEqualToCurrentEpoch(c.lastEpochRedeemed, repaymentEpoch);
        if (c.dolaIOUsRedeemed == 0) revert ConversionHasNotBeenRedeemedBefore();
        accrueInterest();
        uint dolaIOUsLeftToRedeem = c.dolaIOUAmount - c.dolaIOUsRedeemed;
        uint dolaLeftToRedeem = convertDolaIOUsToDola(dolaIOUsLeftToRedeem);
        uint redeemableIOUsPct = dolaIOUsLeftToRedeem * 1e18 / c.dolaIOUsRedeemed;

        //1.2%
        uint dolaBal = IERC20(DOLA).balanceOf(address(this));
        if (redeemableIOUsPct <= .012e18 && dolaLeftToRedeem <= dolaBal) {
            conversions[msg.sender][_conversion].dolaIOUsRedeemed += dolaIOUsLeftToRedeem;

            _burn(msg.sender, dolaIOUsLeftToRedeem);
            require(IERC20(DOLA).transfer(msg.sender, dolaLeftToRedeem), "DOLA transfer failed");
            emit Redemption(msg.sender, dolaLeftToRedeem);
        }
    }

    function redeemAll(uint _conversion) external {
        redeemConversion(_conversion, 0);
        redeemConversionDust(_conversion);
    }

    /*
     * @notice function for accounting interest of DOLA IOU tokens. Called by convert(), repayment(), and redeem().
     * @dev only will apply rate increase once per block.
     */
    function accrueInterest() public {
        if(block.timestamp != lastAccrueInterestTimestamp && exchangeRateIncreasePerSecond > 0) {
            uint rateIncrease = (block.timestamp - lastAccrueInterestTimestamp) * exchangeRateIncreasePerSecond;
            exchangeRateMantissa += rateIncrease;
            uint newDebt = rateIncrease * totalSupply() / 1e18;
            cumDebt += newDebt;
            outstandingDebt  += newDebt;
            lastAccrueInterestTimestamp = block.timestamp;
        }
    }

    /*
     * @notice function for calculating redeemable DOLA IOUs of an account
     * @param _addr Address to view redeemable DOLA IOUs of
     * @param _conversion index of conversion to calculate redeemable DOLA IOUs for
     * @param _epoch repayment epoch to calculate redeemable DOLA IOUs of
     */
    function getRedeemableDolaIOUsFor(address _addr, uint _conversion, uint _epoch) public view returns (uint) {
        ConversionData memory c = conversions[_addr][_conversion];
        uint userRedeemedIOUs = c.dolaIOUsRedeemed;
        uint userConvertedIOUs = c.dolaIOUAmount;
        uint dolaIOUsRemaining = userConvertedIOUs - userRedeemedIOUs;

        uint totalDolaIOUsRedeemable = (repayments[_epoch].pctDolaIOUsRedeemable * userConvertedIOUs / 1e18);

        if (dolaIOUsRemaining >= totalDolaIOUsRedeemable) {
            return totalDolaIOUsRedeemable;
        } else {
            return dolaIOUsRemaining;
        }
    }

    /*
     * @notice function for calculating amount of DOLA equal to a given DOLA IOU amount.
     * @param dolaIOUs DOLA IOU amount to be converted to DOLA
     */
    function convertDolaIOUsToDola(uint dolaIOUs) public view returns (uint) {
        return dolaIOUs * exchangeRateMantissa / 1e18;
    }

    /*
     * @notice function for calculating amount of DOLA IOUs equal to a given DOLA amount.
     * @param dola DOLA amount to be converted to DOLA IOUs
     */
    function convertDolaToDolaIOUs(uint dola) public view returns (uint) {
        return dola * 1e18 / exchangeRateMantissa;
    }

    /*
     * @notice function for calculating amount of DOLA redeemable for an addresses' DOLA IOU balance
     * @param addr Address to return balance of
     */
    function balanceOfDola(address _addr) external view returns (uint) {
        return convertDolaIOUsToDola(balanceOf(_addr));
    }

    // Revert if `to` address is not whitelisted. Transfers between users are not enabled.
    function transfer(address to, uint amount) public override returns (bool) {
        if (!transferWhitelist[to]) revert TransferToAddressNotWhitelisted();

        return super.transfer(to, amount);
    }

    // Revert if `to` address is not whitelisted. Transfers between users are not enabled.
    function transferFrom(address from, address to, uint amount) public override returns (bool) {
        if (!transferWhitelist[to]) revert TransferToAddressNotWhitelisted();

        return super.transferFrom(from, to, amount);
    }

    /*
     * @notice function for transferring `amount` of `token` to the `treasury` address from this contract
     * @param token Address of the token to be transferred out of this contract
     * @param amount Amount of `token` to be transferred out of this contract, 0 = max
     */
    function sweepTokens(address token, uint amount) external onlyGovernance {
        if (amount == 0) { 
            require(IERC20(token).transfer(treasury, IERC20(token).balanceOf(address(this))), "Token transfer failed");
        } else {
            require(IERC20(token).transfer(treasury, amount), "Token transfer failed");
        }
    }

    /*
     * @notice function for setting rate at which `exchangeRateMantissa` increases every year
     * @param increasePerYear The amount `exchangeRateMantissa` will increase every year. 1e18 is the default exchange rate.
     */
    function setExchangeRateIncrease(uint increasePerYear) external onlyGovernance {
        accrueInterest();
        exchangeRateIncreasePerSecond = increasePerYear / 365 days;
        
        emit NewAnnualExchangeRateIncrease(increasePerYear);
    }

    /*
     * @notice function for setting maximum price this contract will pay for 1 underlying of the anToken
     * @param anToken address of the anToken to set maxConvertPrice[anToken]
     * @param maxPrice maximum price this contract will pay for 1 underlying of `anToken`
     */
    function setMaxConvertPrice(address anToken, uint maxPrice) external onlyGovernance {
        maxConvertPrice[anToken] = maxPrice;
        
        emit NewMaxConvertPrice(anToken, maxPrice);
    }

    /*
     * @notice function for setting owner address.
     * @param newOwner Address that will become the new owner of the contract.
     */
    function setOwner(address newOwner) external onlyGovernance {
        owner = newOwner;

        emit NewOwner(newOwner);
    }

    /*
     * @notice function for setting treasury address.
     * @param newTreasury Address that will be set as the new treasury of the contract.
     */
    function setTreasury(address newTreasury) external onlyGovernance {
        treasury = newTreasury;

        emit NewTreasury(newTreasury);
    }

    /*
     * @notice function for setting governance address.
     * @param newGovernance Address that will be set as the new treasury of the contract.
     */
    function setGovernance(address newGovernance) external onlyGovernance {
        governance = newGovernance;

        emit NewGovernance(newGovernance);
    }

    /*
     * @notice function for whitelisting IOU token transfers to certain addresses.
     * @param whitelistedAddress Address to be added to whitelist. IOU tokens will be able to be transferred to this address.
     */
    function whitelistTransferFor(address whitelistedAddress) external onlyGovernance {
        transferWhitelist[whitelistedAddress] = true;

        emit NewTransferWhitelistAddress(whitelistedAddress);
    }
}

pragma solidity ^0.8.0;

struct FeedData {
    address addr;
    uint8 tokenDecimals;
}

interface IOracle {
    function setFeed(
        address cToken_,
        address feed_,
        uint8 tokenDecimals_
    ) external;

    function getUnderlyingPrice(address cToken_)
        external
        view
        returns (uint256);


}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title Compound's CToken Contract
 * @notice Abstract base for CTokens
 * @author Compound
 */
interface ICToken {
    function admin() external view returns (address);
    function adminHasRights() external view returns (bool);
    function fuseAdminHasRights() external view returns (bool);
    function symbol() external view returns (string memory);
    function comptroller() external view returns (address);
    function adminFeeMantissa() external view returns (uint256);
    function fuseFeeMantissa() external view returns (uint256);
    function reserveFactorMantissa() external view returns (uint256);
    function totalReserves() external view returns (uint);
    function totalAdminFees() external view returns (uint);
    function totalFuseFees() external view returns (uint);

    function isCToken() external view returns (bool);
    function isCEther() external view returns (bool);
    function decimals() external view returns (uint8);
    function underlying() external view returns (address);

    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);

    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function mint() external payable;
    function mint(uint amount) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
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

pragma solidity ^0.8.0;

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}