// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IInterestManager.sol";
import "../util/Ownable.sol";
import "../compound/ICToken.sol";
import "../compound/IComptroller.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../util/Initializable.sol";

/**
 * @title InterestManagerCompound
 * @author Shmoji
 * 
 * Invests DAI into Compound to generate interest
 * Sits behind an AdminUpgradabilityProxy 
 */
contract InterestManagerCompound is Ownable, Initializable {

    // Dai contract
    IERC20 private _dai;
    // cDai contract
    ICToken private _cDai;
    // COMP contract
    IERC20 private _comp;
    // Address which is allowed to withdraw accrued COMP tokens
    address private _compRecipient;

    /**
     * Initializes the contract with all required values
     *
     * @param owner The owner of the contract
     * @param dai The Dai token address
     * @param cDai The cDai token address
     * @param comp The Comp token address
     * @param compRecipient The address of the recipient of the Comp tokens
     */
    function initialize(address owner, address dai, address cDai, address comp, address compRecipient) external initializer {
        require(dai != address(0) &&
                cDai != address(0) && 
                comp != address(0) &&
                compRecipient != address(0),
                "invalid-params");

        setOwnerInternal(owner); // Checks owner to be non-zero
        _dai = IERC20(dai);
        _cDai = ICToken(cDai);
        _comp = IERC20(comp);
        _compRecipient = compRecipient;
    }

    /**
     * Invests a given amount of Dai into Compound
     * The Dai have to be transfered to this contract before this function is called
     *
     * @param amount The amount of Dai to invest
     *
     * @return The amount of minted cDai
     */
    function invest(uint amount) external onlyOwner returns (uint) {
        uint balanceBefore = _cDai.balanceOf(address(this));
        // DAI balance of this contract must be >= amount passed in
        require(_dai.balanceOf(address(this)) >= amount, "insufficient-dai");

        // Approve and mint both cost money. User pays for these (even though THIS contract is doing the approval)

        // Before supplying an asset (DAI), THIS contract must approve that _cDai contract is allowed to access/transfer amount of DAI: https://docs.openzeppelin.com/contracts/2.x/api/token/erc20#IERC20-approve-address-uint256-
        require(_dai.approve(address(_cDai), amount), "dai-cdai-approve");
        // User shall supply the asset (DAI) to THIS contract and THIS contract will receive the minted cTokens. So, this method subtracts DAI from THIS contract and adds cTokens to THIS contract: https://compound.finance/docs/ctokens#mint
        require(_cDai.mint(amount) == 0, "cdai-mint");

        uint balanceAfter = _cDai.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    /**
     * Redeems a given amount of Dai from Compound and sends it to the recipient
     *
     * @param recipient The recipient of the redeemed Dai
     * @param amount The amount of Dai to redeem
     *
     * @return The amount of burned cDai
     */
    function redeem(address recipient, uint amount) external onlyOwner returns (uint) {
        uint balanceBefore = _cDai.balanceOf(address(this));
        // cTokens are subtracted from IMC and DAI is added back to IMC. Interest can be made to not be included by providing correct amount argument: https://compound.finance/docs/ctokens#redeem-underlying
        require(_cDai.redeemUnderlying(amount) == 0, "redeem");
        uint balanceAfter = _cDai.balanceOf(address(this));
        // Transfer DAI from this contract to the IdeaTokenExchange contract (which then will eventually go to user)
        require(_dai.transfer(recipient, amount), "dai-transfer");
        return balanceBefore - balanceAfter;
    }

    /**
     * Redeems a given amount of cDai from Compound and sends Dai to the recipient
     *
     * @param recipient The recipient of the redeemed Dai
     * @param amount The amount of cDai to redeem
     *
     * @return The amount of redeemed Dai
     */
    function redeemInvestmentToken(address recipient, uint amount) external onlyOwner returns (uint) {
        uint balanceBefore = _dai.balanceOf(address(this));
        require(_cDai.redeem(amount) == 0, "redeem");
        uint redeemed = _dai.balanceOf(address(this)) - balanceBefore;
        require(_dai.transfer(recipient, redeemed), "dai-transfer");
        return redeemed;
    }

    /**
     * Updates accrued interest on the invested Dai
     */
    function accrueInterest() external {
        // Applies accrued interest to total borrows and reserves for our cDai instance here: https://github.com/compound-finance/compound-protocol/blob/3affca87636eecd901eb43f81a4813186393905d/contracts/CToken.sol#L384
        require(_cDai.accrueInterest() == 0, "accrue");
    }

    /**
     * Withdraws the generated Comp tokens to the Comp recipient
     */
    function withdrawComp() external {
        address addr = address(this);
        IComptroller(_cDai.comptroller()).claimComp(addr);
        require(_comp.transfer(_compRecipient, _comp.balanceOf(addr)), "comp-transfer");
    }

    /**
     * Converts an amount of underlying tokens to an amount of investment tokens
     *
     * @param underlyingAmount The amount of underlying tokens
     *
     * @return The amount of investment tokens
     */
    function underlyingToInvestmentToken(uint underlyingAmount) external view returns (uint) {
        return divScalarByExpTruncate(underlyingAmount, _cDai.exchangeRateStored());
    }

    /**
     * Converts an amount of investment tokens to an amount of underlying tokens
     *
     * @param investmentTokenAmount The amount of investment tokens
     *
     * @return The amount of underlying tokens
     */
    function investmentTokenToUnderlying(uint investmentTokenAmount) external view returns (uint) {
        return mulScalarTruncate(investmentTokenAmount, _cDai.exchangeRateStored());
    }

    // ====================================== COMPOUND MATH ======================================
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Exponential.sol
    //
    // Modified to revert instead of returning an error code

    function mulScalarTruncate(uint a, uint scalar) pure internal returns (uint) {
        uint product = mulScalar(a, scalar);
        return truncate(product);
    }

    function mulScalar(uint a, uint scalar) pure internal returns (uint) {
        return a * scalar;
    }

    function divScalarByExpTruncate(uint scalar, uint divisor) pure internal returns (uint) {
        uint fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    function divScalarByExp(uint scalar, uint divisor) pure internal returns (uint) {
        uint numerator = uint(10**18) * scalar;
        return getExp(numerator, divisor);
    }

    function getExp(uint num, uint denom) pure internal returns (uint) {
        uint scaledNumerator = num * (10**18);
        return scaledNumerator / denom;
    }

    function truncate(uint num) pure internal returns (uint) {
        return num / 10**18;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title IInterestManager
 * @author Shmoji
 */
interface IInterestManager {
    function invest(uint amount) external returns (uint);
    function redeem(address recipient, uint amount) external returns (uint);
    function redeemInvestmentToken(address recipient, uint amount) external returns (uint);
    function donateInterest(uint amount) external;
    function redeemDonated(uint amount) external;
    function accrueInterest() external;
    function underlyingToInvestmentToken(uint underlyingAmount) external view returns (uint);
    function investmentTokenToUnderlying(uint investmentTokenAmount) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Ownable
 * @author Shmoji
 *
 * @dev Implements only-owner functionality
 */
contract Ownable {

    address _owner;

    event OwnershipChanged(address oldOwner, address newOwner);

    modifier onlyOwner {
        require(_owner == msg.sender, "only-owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        setOwnerInternal(newOwner);
    }

    function setOwnerInternal(address newOwner) internal {
        require(newOwner != address(0), "zero-addr");

        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipChanged(oldOwner, newOwner);
    }

    function getOwner() external view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ICToken
 * @author Shmoj
 *
 * @dev A simplified interface for Compound's cToken
 */
interface ICToken is IERC20 {
    function exchangeRateStored() external view returns (uint);
    function accrueInterest() external returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function comptroller() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title ICToken
 * @author Shmoji
 *
 * @dev A simplified interface for Compound's Comptroller
 */
interface IComptroller {
    function claimComp(address holder) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
}

// SPDX-License-Identifier: MIT
// https://github.com/OpenZeppelin/openzeppelin-upgrades/blob/master/packages/core/contracts/Initializable.sol

pragma solidity 0.8.4;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "already-initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}