// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILending.sol";
import "../interfaces/IOracle.sol";
import "./AssetPool.sol";
import "./Compounder.sol";
import "./RateProvider.sol";

struct Collateral {
    address asset;
    uint256 amount;
}

struct Loan {
    address asset; // The asset being borrowed
    uint256 debt; // The amount of asset being borred
    uint256 lastUpdated;
}

struct MarketParameters {
    uint256 collateralFactor;
    uint256 B0; // base rate
    uint256 B1;
    uint256 B2;
    uint256 a;
}

contract Lending is ILending, Compounder, RateProvider, Ownable {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IOracle public oracle;

    mapping(address => MarketParameters) public markets;

    mapping(address => Collateral[]) public _collateral;
    mapping(address => Loan[]) public _loans;

    event Borrow(address who, address asset, uint256 amount);
    event SupplyCollateral(address who, address collateral, uint256 amount);
    event WithdrawCollateral(address who, address collateral, uint256 amount);

    constructor(address _oracle, address governance) {
        oracle = IOracle(_oracle);
        transferOwnership(governance);
    }

    /**
     * @dev modifer to accrue interest on all debitor's loans
     * @param debitor the address of the debitor to accrue interest on
     */
    modifier preAccrue(address debitor) {
        this.accrueInterest(debitor);
        _;
    }

    /**
     * @dev Borrow assets for msg.sender
     * @param asset the assetPool to borrow from
     * @param amount the amount of tokens to borrow from assetPool
     */
    function borrow(address asset, uint256 amount)
        external
        override
        preAccrue(msg.sender)
        returns (uint256)
    {
        require(amount > 0, "Lending: amount is zero");

        bool updated = false;
        for (uint i=0; i<_loans[msg.sender].length; i++) {
            Loan storage loan = _loans[msg.sender][i];
            if (loan.asset == asset) {
                loan.debt += amount;
                loan.lastUpdated = block.timestamp;
                updated = true;
            }
        }

        if (!updated) {
            _loans[msg.sender].push(Loan(asset, amount, block.timestamp));
        }

        require(this.factor(msg.sender) < 1e18, "Lending: exceeds maximum borrow amount");

        AssetPool(asset).transferAsset(msg.sender, amount);

        emit Borrow(msg.sender, asset, amount);

        return 1;
    }

    /**
     * @dev Payback loan belonging to msg.sender
     * @param loanAsset the assetPool to payback
     * @param amount the amount of tokens to payback
     */
    function payback(address loanAsset, uint256 amount)
        external
        override
        preAccrue(msg.sender)
        returns (uint256)
    {
        require(amount > 0, "Lending: amount is zero");
        Loan storage loan = _loans[msg.sender][0];
        for (uint i=0; i<_loans[msg.sender].length; i++) {
            if (_loans[msg.sender][i].asset == loanAsset) {
                loan = _loans[msg.sender][i];
            }
        }
        require(loan.asset == loanAsset, "Lending: loan does not exist");
        require(loan.debt >= amount, "Lending: payback too high");


        AssetPool assetPool = AssetPool(loanAsset);
        IERC20(assetPool.underlyingToken()).safeTransferFrom(msg.sender, address(assetPool), amount);
        loan.debt -= amount;
        loan.lastUpdated = block.timestamp;

        return loan.debt;
    }

    /** 
     * @dev Supply collateral for msg.sender
     * @param collateralAsset the assetPool to provide collateral with
     * @param amount the amount of collateral to provide
     */
    function supplyCollateral(
        address collateralAsset,
        uint256 amount
    ) external override preAccrue(msg.sender)  {
        require(amount > 0, "Lending: amount is zero");

        IERC20(collateralAsset).safeTransferFrom(msg.sender, address(this), amount);

        MarketParameters memory market = markets[collateralAsset];
        require(market.collateralFactor > 0, "Lending: cannot supply asset as collateral");

        bool updated = false;
        for (uint i=0; i<_collateral[msg.sender].length; i++) {
            Collateral storage c = _collateral[msg.sender][i];
            if (c.asset == collateralAsset) {
                c.amount += amount;
                updated = true;
            }
        }
        if (!updated) {
            _collateral[msg.sender].push(Collateral(collateralAsset, amount));
        }
        emit SupplyCollateral(msg.sender, collateralAsset, amount);
    }


    /**
     * @param collateralAsset the assetPool to provide collateral with
     * @param amount the amount of collateral to provide
     */
    function withdrawCollateral(
        address collateralAsset,
        uint256 amount
    ) external override preAccrue(msg.sender) {
        require(amount > 0, "Lending: amount is zero");
        for (uint i=0; i<_collateral[msg.sender].length; i++) {
            Collateral storage collateral = _collateral[msg.sender][i];
            if (collateral.asset == collateralAsset) {
                require(collateral.amount >= amount, "Lending: insufficient collateral");
                collateral.amount -= amount;
                require(this.factor(msg.sender) < 1e18, "Lending: loan factor unhealthy");
                IERC20(collateral.asset).transfer(msg.sender, amount);
                if (collateral.amount == 0) {
                    // If amount is now zero, remove from collateral array (set last element to current index)
                    _collateral[msg.sender][i] = _collateral[msg.sender][_collateral[msg.sender].length - 1];
                    _collateral[msg.sender].pop();
                }
                emit WithdrawCollateral(msg.sender, collateralAsset, amount);
                return;
            }
        }
        revert("Lending: insufficient collateral");
    }

    /**
     * @dev liquidate loan for debitor's with unhealthy loan factor
     * @dev anyone can call this method to liquidate unhealthy loans
     * @param loanAsset the assetPool address for the loan being liquidated
     * @param collateralAsset the assetPool address (used as collateral) to be taken
     * @param debitor the address of the debitor being liquidated
     */
    function liquidate(
        address loanAsset,
        address collateralAsset,
        address debitor
    ) external override preAccrue(msg.sender) returns (uint256) {

        uint256 loanFactor = this.factor(debitor);
        require(loanFactor > 1e18, "Lending: debitor loans are healthy");

        // Lowest collateral factor loans should be liquidated first
        // Check if colleral address given has lowest collateral factor
        Collateral storage targetCollateral = _collateral[debitor][0];
        uint256 minCollateralFactor = type(uint256).max;
        for (uint i=0; i<_collateral[debitor].length; i++) {
            MarketParameters memory m = markets[_collateral[debitor][i].asset];
            if (m.collateralFactor < minCollateralFactor) {
                minCollateralFactor = m.collateralFactor;
            }
            if (_collateral[debitor][i].asset == collateralAsset) {
                targetCollateral = _collateral[debitor][i];
            }
        }
        require(targetCollateral.asset == collateralAsset, "Lending: collateral does not exist");
        require(markets[collateralAsset].collateralFactor == minCollateralFactor, "Lending: attempt to liquidate wrong collateral asset");

        Loan storage loan = _loans[debitor][0];
        for (uint i=0; i<_loans[debitor].length; i++) {
            if (_loans[debitor][i].asset == loanAsset) {
                loan = _loans[debitor][i];
            }
        } 
        require(loan.asset == loanAsset, "Lending: loan does not exist");

        AssetPool borrowedAssetPool = AssetPool(loanAsset);
        AssetPool collateralAssetPool = AssetPool(collateralAsset);

        uint256 borrowedPrice = this.getPrice(
            address(AssetPool(loanAsset).underlyingToken())
        );
        uint256 collateralPrice = this.getPrice(
            address(AssetPool(collateralAsset).underlyingToken())
        );

        // Subtract equivalent collateral worth from debitor's collateral
        // NOTE: collateral value may be worth more than debitor has supplied.
        uint256 collateralWorth = (loan.debt * borrowedPrice) / collateralPrice;
        if (collateralWorth > targetCollateral.amount) {
            targetCollateral.amount = 0;
        } else {
            targetCollateral.amount -= collateralWorth;
        }
        loan.debt -= loan.debt;
        
        // Transfer borrowed token debt (underlying) from liquidator to AssetPool
        IERC20(address(borrowedAssetPool.underlyingToken())).safeTransferFrom(msg.sender, address(borrowedAssetPool), loan.debt);

        // Burn borrower's supplied wToken collateral
        collateralAssetPool.burn(address(this), targetCollateral.amount);

        // Send collateral underlying token to liquidator
        collateralAssetPool.transferAsset(msg.sender, targetCollateral.amount);

        return 0;
    }

    /**
     * @dev get health factor for a debitor (useful for liquidators)
     * @param debitor the address of the borrower to check
     * @return if return value > 1e18, then debitor's loans are at risk of liquidation
     */
    function factor(address debitor)
        external
        view
        override
        returns (uint256)
    {

        uint256 debtWorth = 0;
        for (uint256 i = 0; i < _loans[debitor].length; i++) {
            Loan memory loan = _loans[debitor][i];
            uint256 borrowPrice = this.getPrice(
                AssetPool(loan.asset).underlyingToken()
            );
            debtWorth += borrowPrice * this.getUnaccruedDebt(debitor, loan.asset); // TODO optimize
        }

        if (debtWorth == 0) {
            return 0;
        }
        
        uint256 maxCollateralWorth = 0;
        for (uint256 i = 0; i < _collateral[debitor].length; i++) {
            Collateral memory collateral = _collateral[debitor][i];
            MarketParameters memory market = markets[collateral.asset];
            uint256 collateralPrice = this.getPrice(
                AssetPool(collateral.asset).underlyingToken()
            );
            maxCollateralWorth +=
                (collateralPrice *
                    collateral.amount *
                    market.collateralFactor) /
                100;
        }

        return debtWorth*1e18 / maxCollateralWorth;
    }

    /**
     * @dev Set collateral factor for a given collateral asset
     * @param collateral the assetPool address to set factor for
     * @param factorMantissa the factor to set (scaled by 100); to set factor to 80%, send value as 80
     */
    function setCollateralFactor(address collateral, uint256 factorMantissa)
        external
        override
        onlyOwner
    {
        markets[collateral].collateralFactor = factorMantissa;
    }

    /**
     * @dev Set interest parameters for an asset to be used in borrow rate calculation, i.e. bw = β0 + β1U + β2U^a
     * @param collateral the assetPool address to set parameters for
     * @param B0 base interest rate
     * @param B1 secondary interest rate parameter
     * @param B2 tertiary interest rate parameter
     * @param a adjustment parameter
     */
    function setInterest(address collateral, uint256 B0, uint256 B1, uint256 B2, uint256 a) external override onlyOwner {
        markets[collateral].B0 = B0;
        markets[collateral].B1 = B1;
        markets[collateral].B2 = B2;
        markets[collateral].a = a;
    }

    /**
     * @dev Get individual collateral given borrower and collateral address
     */
    function getCollateral(address debitor, address collateralAsset) view external returns (Collateral memory) {
        for (uint i=0; i<_collateral[debitor].length; i++) {
            if (_collateral[debitor][i].asset == collateralAsset) {
                return _collateral[debitor][i];
            }
        }
        return Collateral(collateralAsset, 0);
    }

    /**
     * @dev Get individual loan given borrower and loan asset address
     */
    function getLoan(address debitor, address loanAsset) view external returns (Loan memory) {
        for (uint i=0; i<_loans[debitor].length; i++) {
            if (_loans[debitor][i].asset == loanAsset) {
                return _loans[debitor][i];
            }
        }
        return Loan(loanAsset, 0, 0);
    }
    
    /**
     * @dev Get current token price from oracle
     */
    function getPrice(address token) external view returns (uint256) {
        return oracle.getPrice(token);
    }

    /**
     * @dev Get total unaccrued principal since loan was last updated
     */
    function getUnaccruedDebt(address debitor, address loanAsset) public view returns (uint256) {
        Loan memory loan = this.getLoan(debitor, loanAsset);

        if (loan.debt == 0) {
            return 0;
        }

        uint256 ratePerSecond;
        (,ratePerSecond) = this.getCurrentRate(loanAsset);

        if (ratePerSecond == 0) {
            return loan.debt;
        }

        // Calculate difference in seconds since last update
        uint256 diff = block.timestamp - loan.lastUpdated;

        uint256 newPrincipal = this.compound(loan.debt, ratePerSecond, diff);
        return newPrincipal;
    }

    /**
     * @dev Accrue interest on all loans belonging to a borrower
     */
    function accrueInterest(address debitor) public {
        Loan[] storage loans = _loans[debitor];
        for (uint i=0; i<loans.length; i++) {
            Loan storage loan = loans[i];
            // Calculate current borrow rate using utilization rate and market parameters
            uint256 ratePerSecond;
            (,ratePerSecond) = this.getCurrentRate(loan.asset);
            if (ratePerSecond > 0 && loan.debt > 0) {
                uint256 secondsElapsed = block.timestamp - loan.lastUpdated;
                uint256 newPrincipal = this.compound(loan.debt, ratePerSecond, secondsElapsed);
                uint256 newInterest = newPrincipal - loan.debt;
                AssetPool(loan.asset).accumulateReward(newInterest);
                loan.debt = newPrincipal;
                loan.lastUpdated = block.timestamp;
            }
        }
    }

    /**
     * @dev Get the current interest rate for a specific loan asset
     */
    function getCurrentRate(address loanAsset) public view returns(uint256, uint256) {
            // Calculate current borrow rate using utilization rate and market parameters
            MarketParameters memory market = markets[loanAsset];
            AssetPool borrowedAssetPool = AssetPool(loanAsset);
            uint256 available = borrowedAssetPool.totalSupply();
            // require(available > 0, "Lending: insufficient loan asset available");
            if (available == 0) {
                return (0,0);
            }
            uint256 borrows = available - IERC20(borrowedAssetPool.underlyingToken()).balanceOf(loanAsset);
            uint256 rate = this.getBorrowRate(available, borrows, market.B0, market.B1, market.B2, market.a);
            uint256 ratePerSecond = rate.div(this.secondsPerYear());
            return (rate, ratePerSecond);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ILending {
    // mapping(address => mapping(address => Loan)) public loans;

    // deposit token and mint wTokens
    // function deposit(address pool, uint amount) external returns (uint);

    // burn wTokens
    // function withdraw(address pool, uint amount) external returns (bool);

    // borrow another token
    function borrow(address asset, uint amount) external returns (uint);

    function payback(address debt, uint amount) external returns (uint);

    // supply more collateral
    function supplyCollateral(address collateral, uint256 amount) external;

    // withdraw collateral
    function withdrawCollateral(address collateral, uint256 amount) external;

    // anyone can call this method is loan position is unsafe
    function liquidate(address loanAsset, address collateralAsset, address debitor) external returns (uint);

    // useful methods for liquidators
    // get loan factor
    function factor(address debitor) external view returns (uint);

    // onlyOwner
    function setCollateralFactor(address collateral, uint ratio) external;

    // onlyOwner
    function setInterest(address collateral, uint256 B0, uint256 B1, uint256 B2, uint256 a) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IOracle {
    // Get the price of the currency_id.
    // Returns the price.
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IAssetPool.sol";

contract AssetPool is IAssetPool, ERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint8 private _decimals;

    address public underlyingToken;
    address private _lending;

    uint256 public adjustedTotalReward;
    uint256 public adjustedTotalWithdrawnReward;
    mapping(address => uint256) public adjustedWithdrawnReward;

    event Deposit(address who, uint256 amount);
    event Withdraw(address who, uint256 amount);
    event ClaimReward(address who, uint256 amount);
    event AccumulateReward(uint256 amount);

    constructor(address token, address lending, address governance)
    ERC20(
        string(abi.encodePacked("wharf ", ERC20(token).name())),
        string(abi.encodePacked("w", ERC20(token).symbol()))
    ) {
        underlyingToken = token;
        _decimals = ERC20(token).decimals();
        _lending = lending;
        transferOwnership(governance);
    }

    modifier onlyLending() {
        require(msg.sender == _lending, "AssetPool: caller is not lending");
        _;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function deposit(uint256 amount) external override returns (bool) {
        require(amount > 0, "AssetPool: amount is zero");

        IERC20(underlyingToken).safeTransferFrom(msg.sender, address(this), amount);

        uint256 totalShares = totalSupply();

        _mint(msg.sender, amount);

        if (totalShares != 0) {
            uint256 adjustReward = amount.mul(adjustedTotalReward).div(totalShares, "AssetPool: totalShares cannot be zero");
            adjustedTotalReward += adjustReward;
            adjustedTotalWithdrawnReward += adjustReward;
            adjustedWithdrawnReward[msg.sender] += adjustReward;
        }

        emit Deposit(msg.sender, amount);
        return true;
    }

    function withdraw(uint256 amount) external override returns (bool) {
        require(amount > 0, "AssetPool: amount is zero");
        uint256 reward = availableReward(msg.sender);
        if (reward > 0) {
            // claim reward if any
            _claim(msg.sender, reward);
        }
        uint256 shares = balanceOf(msg.sender);
        _burn(msg.sender, amount);
        IERC20(underlyingToken).safeTransfer(msg.sender, amount);

        uint256 adjustReward = amount.mul(adjustedWithdrawnReward[msg.sender]).div(shares, "AssetPool: shares cannot be zero");
        adjustedTotalReward -= adjustReward;
        adjustedTotalWithdrawnReward -= adjustReward;
        adjustedWithdrawnReward[msg.sender] -= adjustReward;

        emit Withdraw(msg.sender, amount);
        return true;
    }

    function availableReward(address who) public view override returns (uint256) {
        uint256 shares = balanceOf(who);
        if (shares == 0) return 0;
        uint256 totalShares = totalSupply();
        (, uint256 amount) = shares.mul(adjustedTotalReward).div(totalShares, "AssetPool: totalShares cannot be zero").trySub(adjustedWithdrawnReward[who]);
        return amount;
    }

    function claimReward() external override returns (bool) {
        uint256 available = availableReward(msg.sender);
        return _claim(msg.sender, available);
    }

    function _claim(address who, uint256 amount) internal returns (bool) {
        IERC20(underlyingToken).safeTransfer(who, amount);
        adjustedWithdrawnReward[who] += amount;
        adjustedTotalWithdrawnReward += amount;

        emit ClaimReward(who, amount);
        return true;
    }

    // onlyLending
    function transferAsset(address to, uint256 amount) external override onlyLending {
        IERC20(underlyingToken).safeTransfer(to, amount);
    }

    // onlyLending
    function burn(address who, uint256 amount) external override onlyLending {
        _burn(who, amount);
    }
    
    function accumulateReward(uint256 amount) external override onlyLending returns (uint256) {
        uint256 totalShares = totalSupply();
        require(totalShares > 0, "AssetPool: no shares");

        adjustedTotalReward += amount;

        emit AccumulateReward(amount);
        return adjustedTotalReward;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Compounder {
    using SafeMath for uint256;

    /**
     * @dev pure method that calculates new principal after compounding
     * @param p the current principal amount
     * @param r the interest rate, scaled by 1e27
     * @param t the number of periods to compound for
     */
    function compound(
        uint256 p,
        uint256 r, // r scaled by 1e27
        uint256 t
    ) public pure returns (uint256) {
        return p.mul(rpow(r.add(1e27), t, 1e27)).div(1e27);
    }

    /**
     * @dev Exponentiation by squaring with a fractional base
     * @dev https://forum.openzeppelin.com/t/how-to-safely-do-a-power-operation-with-a-factional-base/10840/14
     * @dev https://github.com/makerdao/dss/blob/c8d4c806691dacb903ff281b81f316bea974e4c7/src/pot.sol#L85-L107
     */
    function rpow(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RateProvider {
  using SafeMath for uint256;

  uint256 public secondsPerYear = 31536000;

  /** @dev Calculates borrow rate via bw = β0 + β1U + β2U^a
   * @param available amount of shares available for lending
   * @param borrows amount of shares being lent
   * @param B0 base rate, scaled by 1e27
   * @param B1 secondary rate parameter, scaled by 1e27
   * @param B2 tertiary rate parameter, scaled by 1e27
   * @param a tertiary rate exponent
   * @return the current borrow rate scaled by 1e27
   */
  function getBorrowRate(
    uint256 available,
    uint256 borrows,
    uint256 B0,
    uint256 B1,
    uint256 B2,
    uint256 a
  ) public pure returns (uint256) {
    uint256 rate = B0 +
      B1.mul(borrows).div(available) +
      B2.mul((borrows.mul(1e5)**a).div(available**a)).div(1e5**a);
    return rate;
  }

  function getSupplyRate(
    uint256 available,
    uint256 borrows,
    uint256 B0,
    uint256 B1,
    uint256 B2,
    uint256 a
  ) public pure returns (uint256) {
    uint256 bw = getBorrowRate(available, borrows, B0, B1, B2, a);
    uint256 lw = 90; // proportion reserved for borrowers

    uint256 bf = 0; // borrow rate in foreign money market
    uint256 lf = 10; // proportion supplied to foreign money market

    // uint256 la = 0; // proportion supplied to Acala's Homa Protocol (only DOT)

    uint256 v = 1000; // amount reserved for insurance

    return bw.mul(lw).div(100) + bf * lf - v;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
pragma solidity >=0.8.0;

interface IAssetPool {
    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 amount) external returns (bool);

    function availableReward(address who) external view returns (uint256);
    function claimReward() external returns (bool);

    // onlyGateway
    function transferAsset(address to, uint256 amount) external;

    // onlyGateway
    function burn(address to, uint256 amount) external;

    // onlyGateway
    function accumulateReward(uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}