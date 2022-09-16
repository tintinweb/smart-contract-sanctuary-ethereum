// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.16;

import 'src/VaultTracker.sol';

import 'src/tokens/ZcToken.sol';

import 'src/interfaces/ICreator.sol';

contract Creator is ICreator {
    /// @dev A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    address public admin;
    address public marketPlace;

    event SetAdmin(address indexed admin);

    constructor() {
        admin = msg.sender;
    }

    /// @notice Allows the owner to create new markets
    /// @param p Protocol associated with the new market
    /// @param u Underlying token associated with the new market
    /// @param m Maturity timestamp of the new market
    /// @param c Compounding Token address associated with the new market
    /// @param sw Address of the deployed swivel contract
    /// @param n Name of the new market zcToken
    /// @param s Symbol of the new market zcToken
    /// @param d Decimals of the new market zcToken
    function create(
        uint8 p,
        address u,
        uint256 m,
        address c,
        address sw,
        string calldata n,
        string calldata s,
        uint8 d
    ) external authorized(marketPlace) returns (address, address) {
        if (marketPlace == address(0)) {
            revert Exception(34, 0, 0, marketPlace, address(0));
        }

        address zct = address(new ZcToken(p, u, m, c, marketPlace, n, s, d));
        address tracker = address(new VaultTracker(p, m, c, sw, marketPlace));

        return (zct, tracker);
    }

    /// @param a Address of a new admin
    function setAdmin(address a) external authorized(admin) returns (bool) {
        admin = a;

        emit SetAdmin(a);

        return true;
    }

    /// @param m Address of the deployed marketPlace contract
    /// @notice We only allow this to be set once
    /// @dev there is no emit here as it's only done once post deploy by the deploying admin
    function setMarketPlace(address m)
        external
        authorized(admin)
        returns (bool)
    {
        if (marketPlace != address(0)) {
            revert Exception(33, 0, 0, marketPlace, address(0));
        }

        marketPlace = m;
        return true;
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.16;

import 'src/lib/Compounding.sol';

import 'src/interfaces/IVaultTracker.sol';

contract VaultTracker is IVaultTracker {
    /// @notice A single custom error capable of indicating a wide range of detected errors by providing
    /// an error code value whose string representation is documented <here>, and any possible other values
    /// that are pertinent to the error.
    error Exception(uint8, uint256, uint256, address, address);

    struct Vault {
        uint256 notional;
        uint256 redeemable;
        uint256 exchangeRate;
        uint256 accrualBlock;
    }

    mapping(address => Vault) public vaults;

    address public immutable cTokenAddr;
    address public immutable marketPlace;
    address public immutable swivel;
    uint256 public immutable maturity;
    uint256 public maturityRate;
    uint8 public immutable protocol;

    /// @param m Maturity timestamp associated with this vault
    /// @param c Compounding Token address associated with this vault
    /// @param s Address of the deployed swivel contract
    /// @param mp Address of the designated admin, which is the Marketplace addess stored by the Creator contract
    constructor(
        uint8 p,
        uint256 m,
        address c,
        address s,
        address mp
    ) {
        protocol = p;
        maturity = m;
        cTokenAddr = c;
        swivel = s;
        marketPlace = mp;

        // instantiate swivel's vault (unblocking transferNotionalFee)
        vaults[s] = Vault({
            notional: 0,
            redeemable: 0,
            exchangeRate: Compounding.exchangeRate(p, c),
            accrualBlock: block.number
        });
    }

    /// @notice Adds notional to a given address
    /// @param o Address that owns a vault
    /// @param a Amount of notional added
    function addNotional(address o, uint256 a)
        external
        authorized(marketPlace)
        returns (bool)
    {
        Vault memory vlt = vaults[o];

        if (vlt.notional > 0) {
            // If marginal interest has not been calculated up to the current block, calculate marginal interest and update exchangeRate + accrualBlock
            if (vlt.accrualBlock != block.number) {
                // note that mRate is is maturityRate if > 0, exchangeRate otherwise
                (uint256 mRate, uint256 xRate) = rates();
                // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
                // otherwise, calculate marginal exchange rate between current and previous exchange rate.
                uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
                uint256 interest = (yield * (vlt.notional + vlt.redeemable)) /
                    1e26;
                // add interest and amount to position, reset cToken exchange rate
                vlt.redeemable = vlt.redeemable + interest;
                // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
                vlt.exchangeRate = mRate < xRate ? mRate : xRate;
                // set vault's accrual block to the current block
                vlt.accrualBlock = block.number;
            }
            vlt.notional = vlt.notional + a;
        } else {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // set notional
            vlt.notional = a;
            // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
            vlt.exchangeRate = mRate < xRate ? mRate : xRate;
            // set vault's accrual block to the current block
            vlt.accrualBlock = block.number;
        }

        vaults[o] = vlt;

        return true;
    }

    /// @notice Removes notional from a given address
    /// @param o Address that owns a vault
    /// @param a Amount of notional to remove
    function removeNotional(address o, uint256 a)
        external
        authorized(marketPlace)
        returns (bool)
    {
        Vault memory vlt = vaults[o];

        if (a > vlt.notional) {
            revert Exception(31, a, vlt.notional, o, address(0));
        }

        if (vlt.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();

            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
            uint256 interest = (yield * (vlt.notional + vlt.redeemable)) / 1e26;
            // remove amount from position, Add interest to position, reset cToken exchange rate
            vlt.redeemable = vlt.redeemable + interest;
            // set vault's exchange rate to the lower of (maturityRate, exchangeRate) if vault has matured, otherwise exchangeRate
            vlt.exchangeRate = maturityRate < xRate ? mRate : xRate;
            // set vault's accrual block to the current block
            vlt.accrualBlock = block.number;
        }
        vlt.notional = vlt.notional - a;

        vaults[o] = vlt;

        return true;
    }

    /// @notice Redeem's interest accrued by a given address
    /// @param o Address that owns a vault
    function redeemInterest(address o)
        external
        authorized(marketPlace)
        returns (uint256)
    {
        Vault memory vlt = vaults[o];

        uint256 redeemable = vlt.redeemable;

        if (vlt.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();

            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / vlt.exchangeRate) - 1e26;
            uint256 interest = (yield * (vlt.notional + vlt.redeemable)) / 1e26;

            vlt.exchangeRate = mRate < xRate ? mRate : xRate;
            vlt.accrualBlock = block.number;
            // adds marginal interest to previously accrued redeemable interest
            redeemable += interest;
        }
        vlt.redeemable = 0;

        vaults[o] = vlt;

        // returns current redeemable if already accrued, redeemable + interest if not
        return redeemable;
    }

    /// @notice Matures the vault
    /// @param c The current cToken exchange rate
    function matureVault(uint256 c)
        external
        authorized(marketPlace)
        returns (bool)
    {
        maturityRate = c;
        return true;
    }

    /// @notice Transfers notional from one address to another
    /// @param f Owner of the amount
    /// @param t Recipient of the amount
    /// @param a Amount to transfer
    function transferNotionalFrom(
        address f,
        address t,
        uint256 a
    ) external authorized(marketPlace) returns (bool) {
        if (f == t) {
            revert Exception(32, 0, 0, f, t);
        }

        Vault memory from = vaults[f];

        if (a > from.notional) {
            revert Exception(31, a, from.notional, f, t);
        }

        if (from.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / from.exchangeRate) - 1e26;
            uint256 interest = (yield * (from.notional + from.redeemable)) /
                1e26;
            // remove amount from position, Add interest to position, reset cToken exchange rate
            from.redeemable = from.redeemable + interest;
            from.exchangeRate = mRate < xRate ? mRate : xRate;
            from.accrualBlock = block.number;
        }
        from.notional = from.notional - a;
        vaults[f] = from;

        Vault memory to = vaults[t];

        // transfer notional to address "t", calculate interest if necessary
        if (to.notional > 0) {
            // if interest hasnt been calculated within the block, calculate it
            if (from.accrualBlock != block.number) {
                // note that mRate is is maturityRate if > 0, exchangeRate otherwise
                (uint256 mRate, uint256 xRate) = rates();
                uint256 yield = ((mRate * 1e26) / to.exchangeRate) - 1e26;
                uint256 interest = (yield * (to.notional + to.redeemable)) /
                    1e26;
                // add interest and amount to position, reset cToken exchange rate
                to.redeemable = to.redeemable + interest;
                to.exchangeRate = mRate < xRate ? mRate : xRate;
                to.accrualBlock = block.number;
            }
            to.notional = to.notional + a;
        } else {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            to.notional = a;
            to.exchangeRate = mRate < xRate ? mRate : xRate;
            to.accrualBlock = block.number;
        }

        vaults[t] = to;

        return true;
    }

    /// @notice Transfers, in notional, a fee payment to the Swivel contract without recalculating marginal interest for the owner
    /// @param f Owner of the amount
    /// @param a Amount to transfer
    function transferNotionalFee(address f, uint256 a)
        external
        authorized(marketPlace)
        returns (bool)
    {
        Vault memory oVault = vaults[f];

        if (a > oVault.notional) {
            revert Exception(31, a, oVault.notional, f, address(0));
        }
        // remove notional from its owner, marginal interest has been calculated already in the tx
        oVault.notional = oVault.notional - a;

        Vault memory sVault = vaults[swivel];

        // check if exchangeRate has been stored already this block. If not, calculate marginal interest + store exchangeRate
        if (sVault.accrualBlock != block.number) {
            // note that mRate is is maturityRate if > 0, exchangeRate otherwise
            (uint256 mRate, uint256 xRate) = rates();
            // if market has matured, calculate marginal interest between the maturity rate and previous position exchange rate
            // otherwise, calculate marginal exchange rate between current and previous exchange rate.
            uint256 yield = ((mRate * 1e26) / sVault.exchangeRate) - 1e26;
            uint256 interest = (yield * (sVault.notional + sVault.redeemable)) /
                1e26;
            // add interest and amount, reset cToken exchange rate
            sVault.redeemable = sVault.redeemable + interest;
            // set to maturityRate only if both > 0 && < exchangeRate
            sVault.exchangeRate = (mRate < xRate) ? mRate : xRate;
            // set current accrual block
            sVault.accrualBlock = block.number;
        }
        // add notional to swivel's vault
        sVault.notional = sVault.notional + a;
        // store the adjusted vaults
        vaults[swivel] = sVault;
        vaults[f] = oVault;
        return true;
    }

    /// @notice Return both the current maturityRate if it's > 0 (or exchangeRate in its place) and the Compounding exchange rate
    /// @dev While it may seem unnecessarily redundant to return the exchangeRate twice, it prevents many kludges that would otherwise be necessary to guard it
    /// @return maturityRate, exchangeRate if maturityRate > 0, exchangeRate, exchangeRate if not.
    function rates() public returns (uint256, uint256) {
        uint256 exchangeRate = Compounding.exchangeRate(protocol, cTokenAddr);
        return ((maturityRate > 0 ? maturityRate : exchangeRate), exchangeRate);
    }

    /// @notice Returns both relevant balances for a given user's vault
    /// @param o Address that owns a vault
    function balancesOf(address o) external view returns (uint256, uint256) {
        Vault memory vault = vaults[o];
        return (vault.notional, vault.redeemable);
    }

    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.16;

import 'src/tokens/ERC20.sol';
import 'src/interfaces/IERC5095.sol';
import 'src/interfaces/IRedeemer.sol';

contract ZcToken is ERC20, IERC5095 {
    /// @dev unix timestamp when the ERC5095 token can be redeemed
    uint256 public immutable override maturity;
    /// @dev address of the ERC20 token that is returned on ERC5095 redemption
    address public immutable override underlying;
    /// @dev uint8 associated with a given protocol in Swivel
    uint8 public immutable protocol;

    /////////////OPTIONAL///////////////// (Allows the calculation and distribution of yield post maturity)
    /// @dev address of a cToken
    address public immutable cToken;
    /// @dev address and interface for an external custody contract (necessary for some project's backwards compatability)
    address public immutable redeemer;

    error Maturity(uint256 timestamp);

    error Approvals(uint256 approved, uint256 amount);

    error Authorized(address owner);

    constructor(
        uint8 _protocol,
        address _underlying,
        uint256 _maturity,
        address _cToken,
        address _redeemer,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        protocol = _protocol;
        underlying = _underlying;
        maturity = _maturity;
        cToken = _cToken;
        redeemer = _redeemer;
    }

    /// @notice Post maturity converts an amount of principal tokens to an amount of underlying that would be returned. Returns 0 pre-maturity.
    /// @param principalAmount The amount of principal tokens to convert
    /// @return The amount of underlying tokens returned by the conversion
    function convertToUnderlying(uint256 principalAmount)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (principalAmount * xRate) / mRate;
    }

    /// @notice Post maturity converts a desired amount of underlying tokens returned to principal tokens needed. Returns 0 pre-maturity.
    /// @param underlyingAmount The amount of underlying tokens to convert
    /// @return The amount of principal tokens returned by the conversion
    function convertToPrincipal(uint256 underlyingAmount)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (underlyingAmount * mRate) / xRate;
    }

    /// @notice Post maturity calculates the amount of principal tokens that `owner` can redeem. Returns 0 pre-maturity.
    /// @param owner The address of the owner for which redemption is calculated
    /// @return The maximum amount of principal tokens that `owner` can redeem.
    function maxRedeem(address owner) external view override returns (uint256) {
        if (block.timestamp < maturity) {
            return 0;
        }
        return balanceOf[owner];
    }

    /// @notice Post maturity simulates the effects of redeemption at the current block. Returns 0 pre-maturity.
    /// @param principalAmount the amount of principal tokens redeemed in the simulation
    /// @return The maximum amount of underlying returned by `principalAmount` of PT redemption
    function previewRedeem(uint256 principalAmount)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (principalAmount * xRate) / mRate;
    }

    /// @notice Post maturity calculates the amount of underlying tokens that `owner` can withdraw. Returns 0 pre-maturity.
    /// @param  owner The address of the owner for which withdrawal is calculated
    /// @return The maximum amount of underlying tokens that `owner` can withdraw.
    function maxWithdraw(address owner)
        external
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (balanceOf[owner] * xRate) / mRate;
    }

    /// @notice Post maturity simulates the effects of withdrawal at the current block. Returns 0 pre-maturity.
    /// @param underlyingAmount the amount of underlying tokens withdrawn in the simulation
    /// @return The amount of principal tokens required for the withdrawal of `underlyingAmount`
    function previewWithdraw(uint256 underlyingAmount)
        public
        view
        override
        returns (uint256)
    {
        if (block.timestamp < maturity) {
            return 0;
        }

        // note that maturity rate (mRate) == exchangeRate (xRate) if the mRate would have been 0 (see VaultTracker.rates)
        (uint256 mRate, uint256 xRate) = IRedeemer(redeemer).rates(
            protocol,
            underlying,
            maturity
        );

        return (underlyingAmount * mRate) / xRate;
    }

    /// @notice At or after maturity, Burns principalAmount from `owner` and sends exactly `underlyingAmount` of underlying tokens to `receiver`.
    /// @param underlyingAmount The amount of underlying tokens withdrawn
    /// @param receiver The receiver of the underlying tokens being withdrawn
    /// @return The amount of principal tokens burnt by the withdrawal
    function withdraw(
        uint256 underlyingAmount,
        address receiver,
        address holder
    ) external override returns (uint256) {
        // If maturity is not yet reached. TODO this is moved from underneath the previewAmount call - should have been here before? Discuss.
        if (block.timestamp < maturity) {
            revert Maturity(maturity);
        }

        // TODO removing both the `this.foo` and `external` bits of this pattern as it's simply an unnecessary misdirection. Discuss.
        uint256 previewAmount = previewWithdraw(underlyingAmount);

        // Transfer logic: If holder is msg.sender, skip approval check
        if (holder == msg.sender) {
            IRedeemer(redeemer).authRedeem(
                protocol,
                underlying,
                maturity,
                msg.sender,
                receiver,
                previewAmount
            );
        } else {
            uint256 allowed = allowance[holder][msg.sender];
            if (allowed < previewAmount) {
                revert Approvals(allowed, previewAmount);
            }
            allowance[holder][msg.sender] =
                allowance[holder][msg.sender] -
                previewAmount;
            IRedeemer(redeemer).authRedeem(
                protocol,
                underlying,
                maturity,
                holder,
                receiver,
                previewAmount
            );
        }

        return previewAmount;
    }

    /// @notice At or after maturity, burns exactly `principalAmount` of Principal Tokens from `owner` and sends underlyingAmount of underlying tokens to `receiver`.
    /// @param principalAmount The amount of principal tokens being redeemed
    /// @param receiver The receiver of the underlying tokens being withdrawn
    /// @return The amount of underlying tokens distributed by the redemption
    function redeem(
        uint256 principalAmount,
        address receiver,
        address holder
    ) external override returns (uint256) {
        // If maturity is not yet reached
        if (block.timestamp < maturity) {
            revert Maturity(maturity);
        }

        // some 5095 tokens may have custody of underlying and can can just burn PTs and transfer underlying out, while others rely on external custody
        if (holder == msg.sender) {
            return
                IRedeemer(redeemer).authRedeem(
                    protocol,
                    underlying,
                    maturity,
                    msg.sender,
                    receiver,
                    principalAmount
                );
        } else {
            uint256 allowed = allowance[holder][msg.sender];

            if (allowed < principalAmount) {
                revert Approvals(allowed, principalAmount);
            }

            allowance[holder][msg.sender] =
                allowance[holder][msg.sender] -
                principalAmount;
            return
                IRedeemer(redeemer).authRedeem(
                    protocol,
                    underlying,
                    maturity,
                    holder,
                    receiver,
                    principalAmount
                );
        }
    }

    /// @param f Address to burn from
    /// @param a Amount to burn
    function burn(address f, uint256 a)
        external
        onlyAdmin(address(redeemer))
        returns (bool)
    {
        _burn(f, a);
        return true;
    }

    /// @param t Address recieving the minted amount
    /// @param a The amount to mint
    function mint(address t, uint256 a)
        external
        onlyAdmin(address(redeemer))
        returns (bool)
    {
        // disallow minting post maturity
        if (block.timestamp > maturity) {
            revert Maturity(maturity);
        }
        _mint(t, a);
        return true;
    }

    modifier onlyAdmin(address a) {
        if (msg.sender != a) {
            revert Authorized(a);
        }
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface ICreator {
    function create(
        uint8,
        address,
        uint256,
        address,
        address,
        string calldata,
        string calldata,
        uint8
    ) external returns (address, address);

    function setAdmin(address) external returns (bool);

    function setMarketPlace(address) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import 'src/Protocols.sol';

import 'src/lib/LibCompound.sol';

import 'src/interfaces/IERC4626.sol';
import 'src/interfaces/ICERC20.sol';
import 'src/interfaces/IAavePool.sol';
import 'src/interfaces/IAaveToken.sol';
import 'src/interfaces/IEulerToken.sol';
import 'src/interfaces/ICompoundToken.sol';
import 'src/interfaces/IYearnVault.sol';

library Compounding {
    /// @param p Protocol Enum value
    /// @param c Compounding token address
    function underlying(uint8 p, address c) internal view returns (address) {
        if (p == uint8(Protocols.Compound) || p == uint8(Protocols.Rari)) {
            return ICompoundToken(c).underlying();
        } else if (p == uint8(Protocols.Yearn)) {
            return IYearnVault(c).token();
        } else if (p == uint8(Protocols.Aave)) {
            return IAaveToken(c).UNDERLYING_ASSET_ADDRESS();
        } else if (p == uint8(Protocols.Euler)) {
            return IEulerToken(c).underlyingAsset();
        } else {
            return IERC4626(c).asset();
        }
    }

    /// @param p Protocol Enum value
    /// @param c Compounding token address
    function exchangeRate(uint8 p, address c) internal returns (uint256) {
        // in contrast to the below, LibCompound provides a lower gas alternative to exchangeRateCurrent()
        if (p == uint8(Protocols.Compound)) {
            return LibCompound.viewExchangeRate(ICERC20(c));
            // with the removal of LibFuse we will direct Rari to the exposed Compound CToken methodology
        } else if (p == uint8(Protocols.Rari)) {
            return ICompoundToken(c).exchangeRateCurrent();
        } else if (p == uint8(Protocols.Yearn)) {
            return IYearnVault(c).pricePerShare();
        } else if (p == uint8(Protocols.Aave)) {
            IAaveToken aToken = IAaveToken(c);
            return
                IAavePool(aToken.POOL()).getReserveNormalizedIncome(
                    aToken.UNDERLYING_ASSET_ADDRESS()
                );
        } else if (p == uint8(Protocols.Euler)) {
            // NOTE: the 1e26 const is a degree of precision to enforce on the return
            return IEulerToken(c).convertBalanceToUnderlying(1e26);
        } else {
            // NOTE: the 1e26 const is a degree of precision to enforce on the return
            return IERC4626(c).convertToAssets(1e26);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IVaultTracker {
    function addNotional(address, uint256) external returns (bool);

    function removeNotional(address, uint256) external returns (bool);

    function redeemInterest(address) external returns (uint256);

    function matureVault(uint256) external returns (bool);

    function transferNotionalFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transferNotionalFee(address, uint256) external returns (bool);

    function rates() external returns (uint256, uint256);

    function balancesOf(address) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub. Natspec adpated from OpenZeppelin.

pragma solidity 0.8.16;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error Invalid(address signer, address owner);

    error Deadline(uint256 deadline, uint256 timestamp);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (deadline < block.timestamp) {
            revert Deadline(deadline, block.timestamp);
        }
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        '\x19\x01',
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner) {
                revert Invalid(msg.sender, owner);
            }

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                    ),
                    keccak256(bytes(name)),
                    keccak256('1'),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IERC5095 {
    event Redeem(address indexed from, address indexed to, uint256 amount);

    function maturity() external view returns (uint256);

    function underlying() external view returns (address);

    function convertToUnderlying(uint256) external view returns (uint256);

    function convertToPrincipal(uint256) external view returns (uint256);

    function maxRedeem(address) external view returns (uint256);

    function previewRedeem(uint256) external view returns (uint256);

    function maxWithdraw(address) external view returns (uint256);

    function previewWithdraw(uint256) external view returns (uint256);

    function withdraw(
        uint256,
        address,
        address
    ) external returns (uint256);

    function redeem(
        uint256,
        address,
        address
    ) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IRedeemer {
    function authRedeem(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (uint256);

    function rates(
        uint8,
        address,
        uint256
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

enum Protocols {
    Erc4626,
    Compound,
    Rari,
    Yearn,
    Aave,
    Euler
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import {FixedPointMathLib} from 'src/lib/FixedPointMathLib.sol';

import 'src/interfaces/ICERC20.sol';

/// @notice Get up to date cToken data without mutating state.
/// @author Transmissions11 (https://github.com/transmissions11/libcompound)
library LibCompound {
    using FixedPointMathLib for uint256;

    function viewUnderlyingBalanceOf(ICERC20 cToken, address user)
        internal
        view
        returns (uint256)
    {
        return cToken.balanceOf(user).mulWadDown(viewExchangeRate(cToken));
    }

    function viewExchangeRate(ICERC20 cToken) internal view returns (uint256) {
        uint256 accrualBlockNumberPrior = cToken.accrualBlockNumber();

        if (accrualBlockNumberPrior == block.number)
            return cToken.exchangeRateStored();

        uint256 totalCash = cToken.underlying().balanceOf(address(cToken));
        uint256 borrowsPrior = cToken.totalBorrows();
        uint256 reservesPrior = cToken.totalReserves();

        uint256 borrowRateMantissa = cToken.interestRateModel().getBorrowRate(
            totalCash,
            borrowsPrior,
            reservesPrior
        );

        require(borrowRateMantissa <= 0.0005e16, 'RATE_TOO_HIGH'); // Same as borrowRateMaxMantissa in CTokenInterfaces.sol

        uint256 interestAccumulated = (borrowRateMantissa *
            (block.number - accrualBlockNumberPrior)).mulWadDown(borrowsPrior);

        uint256 totalReserves = cToken.reserveFactorMantissa().mulWadDown(
            interestAccumulated
        ) + reservesPrior;
        uint256 totalBorrows = interestAccumulated + borrowsPrior;
        uint256 totalSupply = cToken.totalSupply();

        return
            totalSupply == 0
                ? cToken.initialExchangeRateMantissa()
                : (totalCash + totalBorrows - totalReserves).divWadDown(
                    totalSupply
                );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IERC4626 {
    function deposit(uint256, address) external returns (uint256);

    function withdraw(
        uint256,
        address,
        address
    ) external returns (uint256);

    /// @dev Converts the given 'assets' (uint256) to 'shares', returning that amount
    function convertToAssets(uint256) external view returns (uint256);

    /// @dev The address of the underlying asset
    function asset() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function decimals() external returns (uint8);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

interface InterestRateModel {
    function getBorrowRate(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);
}

interface ICERC20 is IERC20 {
    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function underlying() external view returns (IERC20);

    function totalBorrows() external view returns (uint256);

    function totalFuseFees() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function totalReserves() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function totalAdminFees() external view returns (uint256);

    function fuseFeeMantissa() external view returns (uint256);

    function adminFeeMantissa() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function interestRateModel() external view returns (InterestRateModel);

    function initialExchangeRateMantissa() external view returns (uint256);

    function repayBorrowBehalf(address, uint256) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IAavePool {
    /// @dev Returns the normalized income of the reserve given the address of the underlying asset of the reserve
    function getReserveNormalizedIncome(address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IAaveToken {
    // @dev Deployed ddress of the associated Aave Pool
    function POOL() external view returns (address);

    /// @dev The address of the underlying asset
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IEulerToken {
    /// @notice Convert an eToken balance to an underlying amount, taking into account current exchange rate
    function convertBalanceToUnderlying(uint256)
        external
        view
        returns (uint256);

    /// @dev The address of the underlying asset
    function underlyingAsset() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface ICompoundToken {
    function exchangeRateCurrent() external returns (uint256);

    /// @dev The address of the underlying asset
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IYearnVault {
    function pricePerShare() external view returns (uint256);

    /// @dev The address of the underlying asset
    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                              CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error ExpOverflow();

    error Undefined();

    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert ExpOverflow();

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >>
                96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) *
                    3822833074963236453042738258902158003155416615667) >>
                    uint256(195 - k)
            );
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            if (x < 0) revert Undefined();

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r +=
                16597577552685614221487285958193947469193820559219878177908093499208371 *
                k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        if (x < 0) revert Undefined();

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }
}