// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
// import './interfaces/ISwapRouter.sol';
import './Math.sol';

interface ERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function mint(address to, uint256 value) external;

    function burn(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract LendingPool is Ownable, Math {
    using SafeMath for uint256;

    mapping(address => uint256) public totalLendings;
    mapping(address => uint256) public reserve;
    mapping(address => uint256) public totalDebt;
    mapping(address => uint256) public totalVariableDebt;
    mapping(address => uint256) public totalStableDebt;
    mapping(address => uint256) public lendingPoolTokenList;
    mapping(address => uint256) public lendersList;
    mapping(address => uint256) public borrowwerList;
    uint256 public lendingId = 0;
    uint256 public borrowerId = 0;
    uint256 public borrowPercentage;
    uint256 public loan;

    //===========================================================================
    struct lendingMember {
        address lenderAddress; // address of the user that lended
        string token; //eth,Matic ,bnb
        uint256 SuppliedAmount; //1
        uint256 startDay; // time when he lended
        uint256 endDay; // when lending period ends
        bool isRedeem; // if true is means he has something in pool if false it means he/she redeem
        address pledgeToken;
        uint256 pledgeTokenAmount;
        uint256 _days;
        uint256 lockId;
    }

    struct Token {
        string symbol;
        address tokenAddress; // address of the user that lended
        uint256 unitPriceInUSD;
    }
uint256[] liquidatedBorrowIds;
    // mapping(address => mapping(string => lendingMember)) public mapLenderInfo;
    mapping(uint256 => lendingMember) public mapLenderInfo; // lending id goes to struct
    mapping(address => mapping(string => uint256[])) public lenderIds;
    mapping(address => mapping(string => uint256)) public lenderShares;
    //===========================================================================
    struct borrowMember {
        address borrowerAddress;
        string loanToken;
        uint256 loanAmount;
        address collateralTokenAddress;
        string collateralToken;
        uint256 collateralAmount;
        uint256 borrowDay;
        uint256 endDay;
        uint256 borrowRate;
        bool isStableBorrow;
        bool hasRepaid;
        uint256 lendingId;
    }
    mapping(uint256 => borrowMember) public mapBorrowerInfo;
    mapping(address => mapping(string => uint256[])) public borrowerIds;
    mapping(address => mapping(string => uint256)) public borrowerShares;

    struct IntrestRateModal {
        uint256 OPTIMAL_UTILIZATION_RATE;
        uint256 StableRateSlope1;
        uint256 StableRateSlope2;
        uint256 VariableRateSlope1;
        uint256 VariableRateSlope2;
        uint256 BaseRate;
    }

    struct Aggregators {
        address aggregator;
        address tokenAddress;
        uint256 decimal;
    }

    address private lendingOwner;

    constructor() {
        lendingOwner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return lendingOwner;
    }

    function getBalance() public view returns (uint256) {
        return lendingOwner.balance;
    }

    function lend(
        Token memory lendingToken,
        Token memory pedgeToken,
        uint256 _amount,
        uint256 _days
    ) public payable {
        require(msg.value <= 0, 'Can not send 0 amount');
        uint256 fftToMint = lendingToken.unitPriceInUSD.mul(_amount).div(pedgeToken.unitPriceInUSD);
        lendingId += 1;
        lenderIds[msg.sender][lendingToken.symbol].push(lendingId);
        lenderShares[msg.sender][lendingToken.symbol] += _amount;
        totalLendings[lendingToken.tokenAddress] += _amount;
        mapLenderInfo[lendingId].lenderAddress = msg.sender;
        mapLenderInfo[lendingId].token = lendingToken.symbol;
        mapLenderInfo[lendingId].SuppliedAmount = _amount;
        mapLenderInfo[lendingId].startDay = block.timestamp;
        mapLenderInfo[lendingId].endDay = block.timestamp + _days * 1 days;
        mapLenderInfo[lendingId].isRedeem = false;
        mapLenderInfo[lendingId]._days = _days;
        mapLenderInfo[lendingId].pledgeToken = pedgeToken.tokenAddress;
        mapLenderInfo[lendingId].pledgeTokenAmount = fftToMint;
        ERC20(lendingToken.tokenAddress).transferFrom(msg.sender, address(this), _amount);
        ERC20(pedgeToken.tokenAddress).mint(msg.sender, fftToMint);
    }

    function getLenderId(string memory _tokenSymbol) public view returns (uint256[] memory) {
        return lenderIds[msg.sender][_tokenSymbol];
    }

    function getLenderAsset(uint256 _id) public view returns (lendingMember memory) {
        return mapLenderInfo[_id];
    }

    function getLenderShare(string memory _tokenSymbol) public view returns (uint256) {
        return lenderShares[msg.sender][_tokenSymbol];
    }

    function redeem(
        string memory _tokenSymbol,
        uint256 _amount,
        address _token,
        uint256 _lendeingId,
        IntrestRateModal memory IRS
    ) external payable {
        require(block.timestamp >= mapLenderInfo[_lendeingId].endDay, 'Can not redeem before end day');
        require(keccak256(abi.encodePacked(mapLenderInfo[_lendeingId].token)) == keccak256(abi.encodePacked(_tokenSymbol)), 'Use correct token');
        mapLenderInfo[_lendeingId].isRedeem = true;
        lenderShares[msg.sender][_tokenSymbol] -= _amount;
        totalLendings[_token] -= _amount;
        uint256 profit = getLendingProfitAmount(_amount, _token, IRS);
        reserve[_token] -= profit;
        uint256 fftAmount = mapLenderInfo[_lendeingId].pledgeTokenAmount;
        ERC20(_token).transfer(msg.sender, _amount.add(profit));
        ERC20(mapLenderInfo[_lendeingId].pledgeToken).burn(msg.sender, fftAmount);
    }

    function borrow(
        Token memory loanToken,
        Token memory collateralToken,
        uint256 _loanAmount,
        uint256 _collateralAmount,
        uint256 _stableBorrowRate,
        bool _isStableBorrow
    ) external payable {
        borrowerId += 1;
        borrowerIds[msg.sender][loanToken.symbol].push(lendingId);
        if (reserve[loanToken.tokenAddress] >= 0) {} else {
            reserve[loanToken.tokenAddress] = 0;
        }
        totalDebt[loanToken.tokenAddress] += _loanAmount;
        if (_isStableBorrow) {
            totalStableDebt[loanToken.tokenAddress] += _loanAmount;
        } else {
            totalVariableDebt[loanToken.tokenAddress] += _loanAmount;
        }
        mapBorrowerInfo[borrowerId].isStableBorrow = _isStableBorrow;
        mapBorrowerInfo[borrowerId].borrowerAddress = msg.sender;
        mapBorrowerInfo[borrowerId].loanToken = loanToken.symbol;
        mapBorrowerInfo[borrowerId].borrowRate = _stableBorrowRate;
        mapBorrowerInfo[borrowerId].collateralToken = collateralToken.symbol;
        mapBorrowerInfo[borrowerId].collateralTokenAddress = collateralToken.tokenAddress;
        mapBorrowerInfo[borrowerId].loanAmount = _loanAmount;
        mapBorrowerInfo[borrowerId].collateralAmount += _collateralAmount;
        mapBorrowerInfo[borrowerId].borrowDay = block.timestamp;
        mapBorrowerInfo[borrowerId].hasRepaid = false;
        borrowerShares[msg.sender][loanToken.symbol] += _loanAmount;
        ERC20(collateralToken.tokenAddress).transferFrom(msg.sender, address(this), _collateralAmount);
        ERC20(loanToken.tokenAddress).transfer(msg.sender, _loanAmount);
        lendingId += 1;
        lenderIds[address(this)][collateralToken.symbol].push(lendingId);
        lenderShares[address(this)][collateralToken.symbol] += _collateralAmount;
        totalLendings[collateralToken.tokenAddress] += _collateralAmount;
        mapLenderInfo[lendingId].lenderAddress = address(this);
        mapLenderInfo[lendingId].token = collateralToken.symbol;
        mapLenderInfo[lendingId].SuppliedAmount = _collateralAmount;
        mapLenderInfo[lendingId].isRedeem = false;
        mapBorrowerInfo[borrowerId].lendingId = lendingId;
    }

    function repay(
        string memory _loanTokenSymbol,
        address _loanToken,
        address _collateral,
        uint256 _borrowerId,
        IntrestRateModal memory IRS
    ) external payable {
        require(mapBorrowerInfo[_borrowerId].borrowerAddress == msg.sender, 'Wrong owner');
        mapBorrowerInfo[_borrowerId].hasRepaid = true;
        uint256 repayCollateralAmount = mapBorrowerInfo[_borrowerId].collateralAmount;
        if (mapBorrowerInfo[_borrowerId].isStableBorrow) {
            IRS.BaseRate = mapBorrowerInfo[_borrowerId].borrowRate;
        }
        (uint256 fee, uint256 paid) = calculateBorrowFee(
            IRS,
            mapBorrowerInfo[_borrowerId].loanAmount,
            _loanToken,
            mapBorrowerInfo[_borrowerId].isStableBorrow
        );
        borrowerShares[msg.sender][_loanTokenSymbol] -= mapBorrowerInfo[_borrowerId].loanAmount;
        reserve[_loanToken] += fee;
        uint256 profit = getLendingProfitAmount(repayCollateralAmount, mapBorrowerInfo[_borrowerId].collateralTokenAddress, IRS);
        reserve[mapBorrowerInfo[_borrowerId].collateralTokenAddress] -= profit;
        mapLenderInfo[mapBorrowerInfo[_borrowerId].lendingId].isRedeem = false;

        ERC20(_collateral).transfer(msg.sender, (repayCollateralAmount + profit));
        ERC20(_loanToken).transferFrom(msg.sender, address(this), paid);
    }

    function getBorrowerId(string memory _collateralTokenSymbol) public view returns (uint256[] memory) {
        return borrowerIds[msg.sender][_collateralTokenSymbol];
    }

    function getBorrowerDetails(uint256 _id) public view returns (borrowMember memory) {
        return mapBorrowerInfo[_id];
    }

    function getBorrowerShare(string memory _collateralTokenSymbol) public view returns (uint256) {
        return borrowerShares[msg.sender][_collateralTokenSymbol];
    }

    function getColateralAmount(
        address loanTokenAggregator,
        address collateralTokenAggregator,
        uint256 loanAmount
    ) public view returns (uint256) {
        // 1dai=1usd
        AggregatorV3Interface CollateralPrice = AggregatorV3Interface(collateralTokenAggregator);
        (, int256 price, , , ) = CollateralPrice.latestRoundData();

        AggregatorV3Interface LoanPrice = AggregatorV3Interface(loanTokenAggregator);
        (, int256 loanPrice, , , ) = LoanPrice.latestRoundData();

        uint256 loanPriceInUSD = loanAmount.mul(uint256(loanPrice));
        uint256 collateralAmountInUSD = loanPriceInUSD.mul(100 * 10**18).div(borrowPercentage);
        uint256 collateralAmount = uint256(collateralAmountInUSD).div(uint256(price));
        return collateralAmount;
    }

    function getAggregatorPrice(address _tokenAddress) public view returns (uint256) {
        AggregatorV3Interface LoanPrice = AggregatorV3Interface(_tokenAddress);
        (
            ,
            /*uint80 roundID*/
            int256 loanPrice, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = LoanPrice.latestRoundData();

        return uint256(loanPrice);
    }

    function calculateBorrowFee(
        IntrestRateModal memory irs,
        uint256 _amount,
        address token,
        bool isStableBorrow
    ) public view returns (uint256, uint256) {
        uint256 uRatio = _utilizationRatio(token);
        uint256 fee;
        if (isStableBorrow) {
            fee = mulExp(_amount, irs.BaseRate);
        } else {
            (, uint256 currentVariableBorrowRate) = getCurrentStableAndVariableBorrowRate(uRatio, irs);
            fee = mulExp(_amount, currentVariableBorrowRate);
        }

        uint256 paid = _amount.add(fee);
        return (fee, paid);
    }

    function _utilizationRatio(address token) public view returns (uint256) {
        return getExp(totalDebt[token], totalLendings[token]);
    }

    function getCurrentStableAndVariableBorrowRate(uint256 utilizationRate, IntrestRateModal memory irs) public pure returns (uint256, uint256) {
        if (utilizationRate >= irs.OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio = utilizationRate.sub(irs.OPTIMAL_UTILIZATION_RATE);
            uint256 unit1 = 1 * 10**18;
            uint256 currentStableBorrowRate = irs.BaseRate.add(irs.StableRateSlope1).add(
                (excessUtilizationRateRatio.mul(1 * 10**18).div(unit1.sub(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.StableRateSlope2).div(1 * 10**18))
            );
            uint256 currentVariableBorrowRate = irs.BaseRate.add(irs.VariableRateSlope1).add(
                (excessUtilizationRateRatio.mul(1 * 10**18).div(unit1.sub(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.VariableRateSlope2).div(1 * 10**18))
            );
            return (currentStableBorrowRate, currentVariableBorrowRate);
        } else {
            uint256 currentStableBorrowRate = irs.BaseRate.add(
                ((utilizationRate.mul(1 * 10**18).div(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.StableRateSlope1)).div(1 * 10**18)
            );
            uint256 currentVariableBorrowRate = irs.BaseRate.add(
                ((utilizationRate.mul(1 * 10**18).div(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.VariableRateSlope1)).div(1 * 10**18)
            );
            return (currentStableBorrowRate, currentVariableBorrowRate);
        }
    }

    function getOverallBorrowRate(
        address token,
        uint256 currentVariableBorrowRate,
        uint256 currentAverageStableBorrowRate
    ) public view returns (uint256) {
        uint256 _totalDebt = totalStableDebt[token].add(totalVariableDebt[token]);
        if (_totalDebt == 0) return 0;
        uint256 weightedVariableRate = totalVariableDebt[token].mul(currentVariableBorrowRate).div(1 * 10**18);
        uint256 weightedStableRate = totalStableDebt[token].mul(currentAverageStableBorrowRate).div(1 * 10**18);
        uint256 overallBorrowRate = (weightedVariableRate.add(weightedStableRate).mul(1 * 10**18)).div(_totalDebt);
        return overallBorrowRate;
    }

    function lendingProfiteRate(
        address token,
        uint256 uRatio,
        IntrestRateModal memory IRS
    ) public view returns (uint256) {
        (uint256 currentStableBorrowRate, uint256 currentVariableBorrowRate) = getCurrentStableAndVariableBorrowRate(uRatio, IRS);
        uint256 bRate = getOverallBorrowRate(token, currentStableBorrowRate, currentVariableBorrowRate);
        return mulExp(uRatio, bRate);
    }

    function calculateCurrentLendingProfitRate(address token, IntrestRateModal memory IRS) public view returns (uint256) {
        uint256 uRatio = _utilizationRatio(token);
        uint256 bRate = lendingProfiteRate(token, uRatio, IRS);
        return mulExp(uRatio, bRate);
    }

    function getLendingProfitAmount(
        uint256 _amount,
        address token,
        IntrestRateModal memory IRS
    ) internal view returns (uint256) {
        uint256 lendingProfitRate = calculateCurrentLendingProfitRate(token, IRS);
        uint256 profit = mulExp(_amount, lendingProfitRate);
        return (profit);
    }

    function getChartData(
        address tokenAddress,
        IntrestRateModal memory IRS,
        uint256 liquidationThreshhold
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256 end = liquidationThreshhold;
        uint256[] memory arr = new uint256[](end);
        uint256[] memory borrowArray = new uint256[](end);
        uint256[] memory supplyArry = new uint256[](end);
        for (uint256 index = 0; index < arr.length; index++) {
            arr[index] = index;
            uint256 uratio = (index.mul(1 * 10**18) / 100);
            uint256 supplyRate = lendingProfiteRate(tokenAddress, uratio, IRS);
            (uint256 currentStableBorrowRate, uint256 currentVariableBorrowRate) = getCurrentStableAndVariableBorrowRate(uratio, IRS);
            uint256 borrowRate = getOverallBorrowRate(tokenAddress, currentStableBorrowRate, currentVariableBorrowRate);
            supplyArry[index] = supplyRate;
            borrowArray[index] = borrowRate;
        }
        return (supplyArry, borrowArray);
    }

    function getTokenMarketDetails(address token)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (totalLendings[token], reserve[token], totalDebt[token], totalVariableDebt[token], totalStableDebt[token]);
    }

    function getCurrentLiquidity(Aggregators[] memory tokens)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalLiquidityUSDS = 0;
        uint256 totalDebtUSDS = 0;
        uint256 totalStableBorrowUSDS = 0;
        uint256 totalVariableBorrowUSDS = 0;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 usdInUnits = getAggregatorPrice(tokens[index].aggregator);
            address tokenaddress = tokens[index].tokenAddress;
            uint256 usds = usdInUnits;
            totalLiquidityUSDS += usds.mul(totalLendings[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
            totalDebtUSDS += usds.mul(totalDebt[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
            totalStableBorrowUSDS += usds.mul(totalStableDebt[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
            totalVariableBorrowUSDS += usds.mul(totalVariableDebt[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
        }
        return (totalLiquidityUSDS, totalDebtUSDS, totalStableBorrowUSDS, totalVariableBorrowUSDS);
    }

    function liquidate(
        uint256 _borrowerId,
        address borrowerAddress,
        string memory loanToken
    ) external returns (bool) {
        require(mapBorrowerInfo[_borrowerId].hasRepaid == false && mapBorrowerInfo[_borrowerId].hasRepaid == false, 'Already repaid pr liquidate');
        mapBorrowerInfo[_borrowerId].hasRepaid = true;
        liquidatedBorrowIds.push(_borrowerId);
        borrowerShares[borrowerAddress][loanToken] -= mapBorrowerInfo[_borrowerId].loanAmount;
        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Math {
    using SafeMath for uint256;

    uint256 private constant EXP_SCALE = 1e18;
    uint256 private constant HALF_EXP_SCALE = EXP_SCALE / 2;

    function getExp(uint256 num, uint256 denom) internal pure returns (uint256) {
        (bool successMul, uint256 scaledNumber) = num.tryMul(EXP_SCALE);
        if (!successMul) return 0;
        (bool successDiv, uint256 rational) = scaledNumber.tryDiv(denom);
        if (!successDiv) return 0;
        return rational;
    }

    function mulExp(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool successMul, uint256 doubleScaledProduct) = a.tryMul(b);
        if (!successMul) return 0;
        (
            bool successAdd,
            uint256 doubleScaledProductWithHalfScale
        ) = HALF_EXP_SCALE.tryAdd(doubleScaledProduct);
        if (!successAdd) return 0;
        (bool successDiv, uint256 product) = doubleScaledProductWithHalfScale
            .tryDiv(EXP_SCALE);
        assert(successDiv == true);
        return product;
    }

    function percentage(uint256 _num, uint256 _percentage) internal pure returns (uint256) {
        uint256 rational = getExp(_num, 5);
        return mulExp(rational, _percentage);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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