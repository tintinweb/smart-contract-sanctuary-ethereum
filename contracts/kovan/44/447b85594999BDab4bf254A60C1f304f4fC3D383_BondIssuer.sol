// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IBondFactory } from "./_interfaces/buttonwood/IBondFactory.sol";
import { IBondController } from "./_interfaces/buttonwood/IBondController.sol";
import { IBondIssuer } from "./_interfaces/IBondIssuer.sol";

/*
 *  @title BondIssuer
 *
 *  @notice A issuer periodically issues bonds based on a predefined a configuration.
 *
 *  @dev Based on the provided frequency issuer instantiates a new bond with the config when poked.
 *
 */
contract BondIssuer is IBondIssuer {
    // @notice Address of the bond factory.
    IBondFactory public immutable bondFactory;

    // @notice Time to elapse since last issue window start, after which a new bond can be issued.
    //         AKA, issue frequency.
    uint256 public immutable minIssueTimeIntervalSec;

    // @notice The issue window begins this many seconds into the minIssueTimeIntervalSec period.
    // @dev For example if minIssueTimeIntervalSec is 604800 (1 week), and issueWindowOffsetSec is 93600
    //      then the issue window opens at Friday 2AM GMT every week.
    uint256 public immutable issueWindowOffsetSec;

    // @notice The maximum maturity duration for the issued bonds.
    // @dev In practice, bonds issued by this issuer won't have a constant duration as
    //      block.timestamp when the issue function is invoked can varie.
    //      Rather these bonds are designed to have a predictable maturity date.
    uint256 public immutable maxMaturityDuration;

    // @notice The underlying rebasing token used to be tranched.
    address public immutable collateralToken;

    // @notice The tranche ratios.
    uint256[] public trancheRatios;

    // @notice A private mapping to keep track of bonds issued by this issuer.
    mapping(IBondController => bool) private _issuedBonds;

    // @notice The address of the most recently issued bond.
    IBondController private _lastBond;

    // @notice The timestamp when the issue window opened during the last issue.
    uint256 public lastIssueWindowTimestamp;

    constructor(
        IBondFactory bondFactory_,
        uint256 minIssueTimeIntervalSec_,
        uint256 issueWindowOffsetSec_,
        uint256 maxMaturityDuration_,
        address collateralToken_,
        uint256[] memory trancheRatios_
    ) {
        bondFactory = bondFactory_;
        minIssueTimeIntervalSec = minIssueTimeIntervalSec_;
        issueWindowOffsetSec = issueWindowOffsetSec_;
        maxMaturityDuration = maxMaturityDuration_;

        collateralToken = collateralToken_;
        trancheRatios = trancheRatios_;

        lastIssueWindowTimestamp = 0;
    }

    /// @inheritdoc IBondIssuer
    function isInstance(IBondController bond) external view override returns (bool) {
        return _issuedBonds[bond];
    }

    /// @inheritdoc IBondIssuer
    function issue() public override {
        if (lastIssueWindowTimestamp + minIssueTimeIntervalSec < block.timestamp) {
            return;
        }

        // Set to the timestamp of the most recent issue window start
        lastIssueWindowTimestamp = block.timestamp - (block.timestamp % minIssueTimeIntervalSec) + issueWindowOffsetSec;

        IBondController bond = IBondController(
            bondFactory.createBond(collateralToken, trancheRatios, lastIssueWindowTimestamp + maxMaturityDuration)
        );

        _issuedBonds[bond] = true;

        _lastBond = bond;

        emit BondIssued(bond);
    }

    /// @inheritdoc IBondIssuer
    // @dev Lazily issues a new bond when the time is right.
    function getLastBond() external override returns (IBondController) {
        issue();
        return _lastBond;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
interface IBondFactory {
    function createBond(
        address _collateralToken,
        uint256[] memory trancheRatios,
        uint256 maturityDate
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { ITranche } from "./ITranche.sol";

interface IBondController {
    function collateralToken() external view returns (address);

    function maturityDate() external view returns (uint256);

    function creationDate() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function feeBps() external view returns (uint256);

    function isMature() external view returns (bool);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    function deposit(uint256 amount) external;

    function redeem(uint256[] memory amounts) external;

    function mature() external;

    function redeemMature(address tranche, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IBondController } from "./buttonwood/IBondController.sol";

interface IBondIssuer {
    /// @notice Event emitted when a new bond is issued by the issuer.
    /// @param bond The newly issued bond.
    event BondIssued(IBondController bond);

    // @notice Issues a new bond if sufficient time has elapsed since the last issue.
    function issue() external;

    // @notice Checks if a given bond has been issued by the issuer.
    // @param Address of the bond to check.
    // @return if the bond has been issued by the issuer.
    function isInstance(IBondController bond) external view returns (bool);

    // @notice Fetches the most recently issued bond.
    // @return Address of the most recent bond.
    function getLastBond() external returns (IBondController);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// solhint-disable-next-line compiler-version
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITranche is IERC20 {
    function bond() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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