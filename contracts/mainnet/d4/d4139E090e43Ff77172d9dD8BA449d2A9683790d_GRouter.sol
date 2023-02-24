// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";
import {FixedPointMathLib} from "FixedPointMathLib.sol";
import {SafeTransferLib} from "SafeTransferLib.sol";
import {IGRouter} from "IGRouter.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";
import {RouterOracle} from "RouterOracle.sol";
import {AllowedPermit} from "AllowedPermit.sol";
import {ERC4626} from "ERC4626.sol";
import {Errors} from "Errors.sol";
import {GVault} from "GVault.sol";
import {GTranche} from "GTranche.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title GRouter
/// @notice Handles deposits and withdrawals from the three supported stablecoins
/// DAI, USDC and USDT into Gro Protocol
/// @dev The legacy deposit and withdrawal flows are for old integrations and
/// should be avoided for new integrations as they are less gas efficient.
contract GRouter is IGRouter {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint8 public constant N_COINS = 3; // number of underlying tokens in curve pool

    GTranche public immutable tranche;
    GVault public immutable vaultToken;
    RouterOracle public immutable routerOracle;
    ICurve3Pool public immutable threePool;
    ERC20 public immutable threeCrv;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogDeposit(
        address indexed sender,
        uint256 tokenAmount,
        uint256 tokenIndex,
        bool tranche,
        uint256 trancheAmount,
        uint256 calcAmount
    );

    event LogLegacyDeposit(
        address indexed sender,
        uint256[N_COINS] tokenAmounts,
        bool tranche,
        uint256 trancheAmount,
        uint256 calcAmount
    );

    event LogWithdrawal(
        address indexed sender,
        uint256 tokenAmount,
        uint256 tokenIndex,
        bool tranche,
        uint256 calcAmount
    );

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR / GETTERS
    //////////////////////////////////////////////////////////////*/

    constructor(
        GTranche _GTranche,
        GVault _vaultToken,
        RouterOracle _routerOracle,
        ICurve3Pool _threePool,
        ERC20 _threeCrv
    ) {
        tranche = _GTranche;
        vaultToken = _vaultToken;
        routerOracle = _routerOracle;
        threePool = _threePool;
        threeCrv = _threeCrv;

        // Approve contracts for max amounts to reduce gas
        threeCrv.approve(address(_vaultToken), type(uint256).max);
        threeCrv.approve(address(_threePool), type(uint256).max);
        ERC20(address(_vaultToken)).safeApprove(
            address(_GTranche),
            type(uint256).max
        );
        // Approve Stables for 3pool
        ERC20(routerOracle.getToken(0)).safeApprove(
            address(_threePool),
            type(uint256).max
        );
        ERC20(routerOracle.getToken(1)).safeApprove(
            address(_threePool),
            type(uint256).max
        );
        ERC20(routerOracle.getToken(2)).safeApprove(
            address(_threePool),
            type(uint256).max
        );

        // Approve GTokens for Tranche
        ERC20(address(tranche.getTrancheToken(false))).safeApprove(
            address(_GTranche),
            type(uint256).max
        );
        ERC20(address(tranche.getTrancheToken(true))).safeApprove(
            address(_GTranche),
            type(uint256).max
        );
    }

    /// @notice Helper Function to get correct input for curve 'add_liquidity' function
    /// @param _amount the amount of stablecoin with the correct decimals
    /// @param _index the index of the stable corresponding to DAI, USDC and USDT respectively
    /// @return array of length three with the corresponding stablecoin amount
    function getAmounts(uint256 _amount, uint256 _index)
        internal
        pure
        returns (uint256[N_COINS] memory)
    {
        if (_index == 0) {
            return [_amount, 0, 0];
        } else if (_index == 1) {
            return [0, _amount, 0];
        } else {
            return [0, 0, _amount];
        }
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/ WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit supported stablecoin into either junior or senior tranches of gro protocol
    /// assumes the user has pre-approved the stablecoin for the GRouter
    /// @param _amount the amount of stablecoin being deposited with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @return amount Returns $ value of tranche tokens minted
    function deposit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        amount = depositIntoTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /// @notice Deposit supported stablecoin into either junior or senior tranches of gro protocol
    /// with the permit pattern so user doesn't need pre-approve the token, this supports USDC only
    /// from our supported stables
    /// @param _amount the amount of stablecoin being deposited with the correct decimals
    /// @param _token_index index of deposit 1 - USDC, USDC SUPPORT ONLY
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @param deadline The time at which this expires (unix time)
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signature
    /// @return amount Returns $ value of tranche tokens minted
    function depositWithPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        ERC20 token = ERC20(routerOracle.getToken(_token_index));
        token.permit(msg.sender, address(this), _amount, deadline, v, r, s);
        amount = depositIntoTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /// @notice Deposit supported stablecoin into either junior or senior tranches of gro protocol
    /// with the permit pattern so user doesn't need pre-approve the token, this supports DAI only
    /// from our supported stables
    /// @param _amount the amount of stablecoin being deposited with the correct decimals
    /// @param _token_index index of deposit 0 - DAI, DAI SUPPORT ONLY
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @param deadline The time at which this expires (unix time)
    /// @param nonce nonce value for permit
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signature
    /// @return amount Returns $ value of tranche tokens minted
    function depositWithAllowedPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        AllowedPermit token = AllowedPermit(
            routerOracle.getToken(_token_index)
        );
        token.permit(msg.sender, address(this), nonce, deadline, true, v, r, s);
        amount = depositIntoTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /// @notice Withdraw stablecoins by burning equivalent amount of tranche tokens
    /// @param _amount the amount of tranche tokens being withdrawn with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tokens expected in return
    /// @return  amount Returns $ value of tranche tokens burned
    function withdraw(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        amount = withdrawFromTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /*//////////////////////////////////////////////////////////////
                    LEGACY DEPOSIT/ WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Legacy deposit for the senior tranche token
    /// @param inAmounts amount of stables being deposited as an array of length 3 with the
    /// following indexes corresponding to the following stables 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _minAmount minimum amount of tranche token received
    /// @param _referral not used in updated protocol just use zero address
    function depositPwrd(
        uint256[N_COINS] memory inAmounts,
        uint256 _minAmount,
        address _referral
    ) external {
        uint256 amount = legacyDepositIntoTrancheForCaller(inAmounts, true);
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }
    }

    /// @notice Legacy deposit for the junior tranche token
    /// @param inAmounts amount of stables being deposited as an array of length 3 with the
    /// following indexes corresponding to the following stables 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _minAmount minimum amount of tranche token received
    /// @param _referral not used in updated protocol just use zero address
    function depositGvt(
        uint256[N_COINS] memory inAmounts,
        uint256 _minAmount,
        address _referral
    ) external {
        uint256 amount = legacyDepositIntoTrancheForCaller(inAmounts, false);
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }
    }

    /// @notice Explain to an end user what this does
    /// @param pwrd false for junior (gvt) and true for senior tranche (pwrd)
    /// @param index index of deposit token you wish to withdraw in 0 - DAI, 1 - USDC, 2 -USDT
    /// @param lpAmount the amount of tranche tokens being withdrawn with the correct decimals
    /// @param _minAmount minimum mount of token received
    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 _minAmount
    ) external {
        if (lpAmount == 0) {
            revert Errors.AmountIsZero();
        }
        uint256 amount = withdrawFromTrancheForCaller(lpAmount, index, pwrd, 0);
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HOOKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Helper Function to deposit users funds into the tranche
    /// @param _amount the amount of tranche tokens being deposited with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 - USDT, 3+ - 3Crv
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @return amount Returns $ value of tranche tokens minted
    function depositIntoTrancheForCaller(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) internal returns (uint256 amount) {
        // pull token from user assume pre-approved
        ERC20(routerOracle.getToken(_token_index)).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        uint256 depositAmount;
        if (_token_index < 3) {
            // swap for 3crv
            threePool.add_liquidity(getAmounts(_amount, _token_index), 0);

            // check 3crv amount received
            depositAmount = threeCrv.balanceOf(address(this));
        } else {
            // depositing 3crv
            depositAmount = _amount;
        }

        // deposit into GVault
        uint256 shareAmount = vaultToken.deposit(depositAmount, address(this));

        // deposit into Tranche
        // index is zero for ETH mainnet as there is just one yield token
        uint256 trancheAmount;
        (trancheAmount, amount) = tranche.deposit(
            shareAmount,
            0,
            _tranche,
            msg.sender
        );
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }

        emit LogDeposit(
            msg.sender,
            _amount,
            _token_index,
            _tranche,
            trancheAmount,
            amount
        );
    }

    /// @notice Helper Function to deposit users funds into the tranche for legacy functions
    /// @param inAmounts amount of stables being deposited as an array of length 3 with the
    /// following indexes corresponding to the following stables 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @return amount Returns $ value of tranche tokens minted
    function legacyDepositIntoTrancheForCaller(
        uint256[N_COINS] memory inAmounts,
        bool _tranche
    ) internal returns (uint256 amount) {
        // swap each stable into 3crv
        for (uint256 index; index < N_COINS; index++) {
            // skip loop if amount zero for index
            if (inAmounts[index] == 0) {
                continue;
            }
            // pull token from user assume pre-approved
            ERC20(routerOracle.getToken(index)).safeTransferFrom(
                msg.sender,
                address(this),
                inAmounts[index]
            );
        }

        // swap for 3crv we do minAmount check in parent function
        threePool.add_liquidity(inAmounts, 0);

        // check 3crv amount received
        uint256 depositAmount = threeCrv.balanceOf(address(this));

        // deposit into GVault
        uint256 shareAmount = vaultToken.deposit(depositAmount, address(this));

        // deposit into Tranche
        // index is zero for ETH mainnet as there is just one yield token
        uint256 trancheAmount;
        (trancheAmount, amount) = tranche.deposit(
            shareAmount,
            0,
            _tranche,
            msg.sender
        );

        emit LogLegacyDeposit(
            msg.sender,
            inAmounts,
            _tranche,
            trancheAmount,
            amount
        );
    }

    /// @notice helper function to withdraw stablecoins by burning equivalent amount of tranche tokens
    /// @param _amount the amount of tranche tokens being withdrawn with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @return amount Returns $ value of tranche tokens burned
    function withdrawFromTrancheForCaller(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) internal returns (uint256 amount) {
        ERC20(address(tranche.getTrancheToken(_tranche))).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        // withdraw from tranche
        // index is zero for ETH mainnet as there is just one yield token
        // returns usd value of withdrawal
        (uint256 vaultTokenBalance, ) = tranche.withdraw(
            _amount,
            0,
            _tranche,
            address(this)
        );

        // withdraw underlying from GVault
        uint256 underlying = vaultToken.redeem(
            vaultTokenBalance,
            address(this),
            address(this)
        );

        ERC20 stableToken = ERC20(routerOracle.getToken(_token_index));
        if (_token_index < 3) {
            // remove liquidity from 3crv to get desired stable from curve
            threePool.remove_liquidity_one_coin(
                underlying,
                int128(uint128(_token_index)), //value should always be 0,1,2
                0
            );

            amount = stableToken.balanceOf(address(this));
        } else {
            amount = underlying;
        }

        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }

        // send stable to user
        stableToken.safeTransfer(msg.sender, amount);

        emit LogWithdrawal(msg.sender, _amount, _token_index, _tranche, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

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
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
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
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus)
        private
        pure
        returns (bool success)
    {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGRouter {
    function deposit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount);

    function depositWithPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    function depositWithAllowedPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount);

    function withdraw(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount);

    function depositPwrd(
        uint256[3] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external;

    function depositGvt(
        uint256[3] memory inAmounts,
        uint256 minAmount,
        address _referral
    ) external;

    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 minAmount
    ) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// Curve 3pool interface
interface ICurve3Pool {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        uint256[3] calldata _deposit_amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {AggregatorV3Interface} from "AggregatorV3Interface.sol";
import {IGRouterOracle} from "IGRouterOracle.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";
import {Errors} from "Errors.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared
contract FixedStablecoins {
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    ICurve3Pool public constant curvePool =
        ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    uint256 constant DAI_DECIMALS = 1_000_000_000_000_000_000;
    uint256 constant USDC_DECIMALS = 1_000_000;
    uint256 constant USDT_DECIMALS = 1_000_000;
    uint256 constant THREE_CRV_DECIMALS = 1_000_000_000_000_000_000;

    constructor() {}

    function getToken(uint256 _index) public pure returns (address) {
        if (_index == 0) {
            return DAI;
        } else if (_index == 1) {
            return USDC;
        } else if (_index == 2) {
            return USDT;
        } else {
            return THREE_CRV;
        }
    }

    function getDecimal(uint256 _index) public pure returns (uint256) {
        if (_index == 0) {
            return DAI_DECIMALS;
        } else if (_index == 1) {
            return USDC_DECIMALS;
        } else if (_index == 2) {
            return USDT_DECIMALS;
        } else {
            return THREE_CRV_DECIMALS;
        }
    }
}

contract RouterOracle is FixedStablecoins, IGRouterOracle {
    uint256 constant CHAINLINK_FACTOR = 1_00_000_000;
    uint256 constant NO_OF_AGGREGATORS = 3;
    uint256 constant STALE_CHECK = 86_400; // 24 Hours

    address public immutable daiUsdFeed;
    address public immutable usdcUsdFeed;
    address public immutable usdtUsdFeed;

    constructor(address[NO_OF_AGGREGATORS] memory aggregators) {
        daiUsdFeed = aggregators[0];
        usdcUsdFeed = aggregators[1];
        usdtUsdFeed = aggregators[2];
    }

    /// @notice Get estimate USD price of a stablecoin amount
    /// @param _amount Token amount
    /// @param _index Index of token
    function stableToUsd(uint256 _amount, uint256 _index)
        external
        view
        override
        returns (uint256, bool)
    {
        if (_index == 3)
            return (
                (curvePool.get_virtual_price() * _amount) / THREE_CRV_DECIMALS,
                true
            );
        (uint256 price, bool isStale) = getPriceFeed(_index);
        return ((_amount * price) / CHAINLINK_FACTOR, isStale);
    }

    /// @notice Get LP token value of input amount of single token
    function usdToStable(uint256 _amount, uint256 _index)
        external
        view
        override
        returns (uint256, bool)
    {
        if (_index == 3)
            return (
                (curvePool.get_virtual_price() * _amount) / THREE_CRV_DECIMALS,
                true
            );
        (uint256 price, bool isStale) = getPriceFeed(_index);
        return ((_amount * CHAINLINK_FACTOR) / price, isStale);
    }

    /// @notice Get price from aggregator
    /// @param _index Stablecoin to get USD price for
    function getPriceFeed(uint256 _index)
        internal
        view
        returns (uint256, bool)
    {
        (, int256 answer, , uint256 updatedAt, ) = AggregatorV3Interface(
            getAggregator(_index)
        ).latestRoundData();
        return (uint256(answer), staleCheck(updatedAt));
    }

    function staleCheck(uint256 _updatedAt) internal view returns (bool) {
        return (block.timestamp - _updatedAt >= STALE_CHECK);
    }

    /// @notice Get USD/Stable coin chainlink feed
    /// @param _index index of feed based of stablecoin index (dai/usdc/usdt)
    function getAggregator(uint256 _index) public view returns (address) {
        if (_index >= NO_OF_AGGREGATORS) revert Errors.IndexTooHigh();
        if (_index == 0) {
            return daiUsdFeed;
        } else if (_index == 1) {
            return usdcUsdFeed;
        } else {
            return usdtUsdFeed;
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

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGRouterOracle {
    function stableToUsd(uint256 _amount, uint256 _index)
        external
        view
        returns (uint256, bool);

    function usdToStable(uint256 _amount, uint256 _index)
        external
        view
        returns (uint256, bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

library Errors {
    // Common
    error AlreadyMigrated(); // 0xca1c3cbc
    error AmountIsZero(); // 0x43ad20fc
    error ChainLinkFeedStale(); //0x3bc80ea6
    error IndexTooHigh(); // 0xfbf22ac0
    error IncorrectSweepToken(); // 0x25371b04
    error LTMinAmountExpected(); //less than 0x3d93e699
    error NotEnoughBalance(); // 0xad3a8b9e
    error ZeroAddress(); //0xd92e233d
    error MinDeposit(); //0x11bcd830

    // GMigration
    error TrancheAlreadySet(); //0xe8ce7222
    error TrancheNotSet(); //0xc7896cf2

    // GTranche
    error UtilisationTooHigh(); // 0x01dbe4de
    error MsgSenderNotTranche(); // 0x7cda3092
    error NoAssets(); // 0x5373815f

    // GVault
    error InsufficientShares(); // 0x39996567
    error InsufficientAssets(); // 0x96d80433
    error IncorrectStrategyAccounting(); //0x7b6d99a5
    error IncorrectVaultOnStrategy(); //0x7408aa63
    error OverDepositLimit(); //0xbf41e3d0
    error StrategyActive(); // 0xebb33d91
    error StrategyNotActive(); // 0xdc974a98
    error StrategyDebtNotZero(); // 0x332c333c
    error StrategyLossTooHigh(); // 0xa9aba8bd
    error VaultDebtRatioTooHigh(); //0xf6f34eca
    error VaultFeeTooHigh(); //0xb6659cb6
    error ZeroAssets(); //0x32d971dc
    error ZeroShares(); //0x9811e0c7

    //Whitelist
    error NotInWhitelist(); // 0x5b0aa2ba
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";

/// @notice Minimal interface for tokens using DAI's non-standard permit interface.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/external/IERC20PermitAllowed.sol)
abstract contract AllowedPermit is ERC20 {
    /// @param holder The address of the token owner.
    /// @param spender The address of the token spender.
    /// @param nonce The owner's nonce, increases at each call to permit.
    /// @param expiry The timestamp at which the permit is no longer valid.
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;
}

// SPDX-License-Identifier: MIT
// Adpated from OZ Draft Implementation

pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";

abstract contract ERC4626 is ERC20 {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view virtual returns (ERC20);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets()
        external
        view
        virtual
        returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver)
        external
        view
        virtual
        returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver)
        external
        virtual
        returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver)
        external
        view
        virtual
        returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver)
        external
        virtual
        returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner)
        external
        view
        virtual
        returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets)
        external
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner)
        external
        view
        virtual
        returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares)
        external
        view
        virtual
        returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual returns (uint256 assets);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";
import {SafeTransferLib} from "SafeTransferLib.sol";
import {Math} from "Math.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {IStrategy} from "IStrategy.sol";
import {ERC4626} from "ERC4626.sol";
import {Constants} from "Constants.sol";
import {Errors} from "Errors.sol";
import {StrategyQueue} from "StrategyQueue.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @notice GVault - Gro protocol stand alone vault for generating yield
/// @title GVault
/// @notice  Gro protocol stand alone vault for generating yield on
/// stablecoins following the EIP-4626 Standard
contract GVault is Constants, ERC4626, StrategyQueue, Ownable, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    // Underlying token
    ERC20 public immutable override asset;
    uint256 public immutable minDeposit;

    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    struct StrategyParams {
        bool active;
        uint256 debtRatio;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
    }

    mapping(address => StrategyParams) public strategies;
    uint256 public vaultAssets;

    // Slow release of profit
    uint256 public lockedProfit;
    uint256 public releaseTime;

    uint256 public vaultDebtRatio;
    uint256 public vaultTotalDebt;
    uint256 public lastReport;

    // Vault fee
    address public feeCollector;
    uint256 public vaultFee;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Strategy events
    event LogStrategyHarvestReport(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 debtAdded,
        uint256 lockedProfit,
        uint256 lockedProfitBeforeLoss
    );

    event LogStrategyTotalChanges(
        address indexed strategy,
        uint256 totalGain,
        uint256 totalLoss,
        uint256 totalDebt
    );

    event LogWithdrawalFromStrategy(
        uint48 strategyId,
        uint256 strategyDebt,
        uint256 totalVaultDebt,
        uint256 lossFromStrategyWithdrawal
    );

    // Vault events
    event LogNewDebtRatio(
        address indexed strategy,
        uint256 debtRatio,
        uint256 vaultDebtRatio
    );

    event LogNewReleaseFactor(uint256 factor);
    event LogNewVaultFee(uint256 vaultFee);
    event LogNewfeeCollector(address feeCollector);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(ERC20 _asset)
        ERC20(
            string(abi.encodePacked("Gro ", _asset.symbol(), " Vault")),
            string(abi.encodePacked("gro", _asset.symbol())),
            _asset.decimals()
        )
    {
        asset = _asset;
        minDeposit = 10**_asset.decimals();
        // 24 hours release window in seconds
        releaseTime = 86400;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get number of strategies in underlying vault
    /// @return number of strategies in the withdrawal queue
    function getNoOfStrategies() external view returns (uint256) {
        return noOfStrategies();
    }

    /// @notice Helper function for strategy to get debt from vault
    function getStrategyDebt() external view returns (uint256) {
        return strategies[msg.sender].totalDebt;
    }

    /// @notice Get total invested in strategy
    /// @param _index index of strategy
    /// @return amount of total debt the strategies have to the GVault
    function getStrategyDebt(uint256 _index)
        external
        view
        returns (uint256 amount)
    {
        return strategies[nodes[_index].strategy].totalDebt;
    }

    /// @notice Helper function for strategy to get harvest data from vault
    function getStrategyData()
        external
        view
        returns (
            bool,
            uint256,
            uint256
        )
    {
        StrategyParams storage stratData = strategies[msg.sender];
        return (stratData.active, stratData.totalDebt, stratData.lastReport);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set contract that will receive vault fees
    /// @param _feeCollector address of feeCollector contract
    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
        emit LogNewfeeCollector(_feeCollector);
    }

    /// @notice Set fee that is reduced from strategy yields when harvests are called
    /// @param _fee new strategy fee
    function setVaultFee(uint256 _fee) external onlyOwner {
        if (_fee >= 3000) revert Errors.VaultFeeTooHigh();
        vaultFee = _fee;
        emit LogNewVaultFee(_fee);
    }

    /// @notice Set how quickly profits are released
    /// @param _time how quickly profits are released in seconds
    function setProfitRelease(uint256 _time) external onlyOwner {
        releaseTime = _time;
        emit LogNewReleaseFactor(_time);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit assets into the GVault
    /// @param _assets user deposit amount
    /// @param _receiver Address receiving the shares
    /// @return shares the number of shares minted during the deposit
    function deposit(uint256 _assets, address _receiver)
        external
        override
        nonReentrant
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        if (_assets < minDeposit) revert Errors.MinDeposit();
        if ((shares = previewDeposit(_assets)) == 0) revert Errors.ZeroShares();

        asset.safeTransferFrom(msg.sender, address(this), _assets);
        vaultAssets += _assets;

        _mint(_receiver, shares);

        emit Deposit(msg.sender, _receiver, _assets, shares);

        return shares;
    }

    /// @notice Request shares to be minted by depositing assets into the GVault
    /// @param _shares Amount of shares to be minted
    /// @param _receiver Address receiving the shares
    /// @return assets the number of asset tokens deposited during the mint of the
    /// vault shares
    function mint(uint256 _shares, address _receiver)
        external
        override
        nonReentrant
        returns (uint256 assets)
    {
        // Check for rounding error in previewMint.
        if ((assets = previewMint(_shares)) < minDeposit)
            revert Errors.MinDeposit();

        asset.safeTransferFrom(msg.sender, address(this), assets);
        vaultAssets += assets;

        _mint(_receiver, _shares);

        emit Deposit(msg.sender, _receiver, assets, _shares);

        return assets;
    }

    /// @notice withdraw assets from the GVault
    /// @param _assets the amount of want token the caller wants to withdraw
    /// @param _receiver address receiving the asset token
    /// @param _owner address that owns the 4626 shares that will be burnt
    /// @param _minAmount minAmount of assets to return
    /// @return shares the number of shares burnt during the withdrawal
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        uint256 _minAmount
    ) external nonReentrant returns (uint256 shares) {
        return _withdraw(_assets, _receiver, _owner, _minAmount);
    }

    /// @notice withdraw assets from the GVault
    /// @param _assets the amount of want token the caller wants to withdraw
    /// @param _receiver address receiving the asset token
    /// @param _owner address that owns the 4626 shares that will be burnt
    /// @return shares the number of shares burnt during the withdrawal
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external override nonReentrant returns (uint256 shares) {
        return _withdraw(_assets, _receiver, _owner, 0);
    }

    /// @notice Internal helper function for withdrawal - called by EIP-4626 standard withdraw function
    ///     or custom withdraw function with minAmount.
    function _withdraw(
        uint256 _assets,
        address _receiver,
        address _owner,
        uint256 _minAmount
    ) internal returns (uint256 shares) {
        if (_assets == 0) revert Errors.ZeroAssets();

        shares = previewWithdraw(_assets);

        if (shares > balanceOf[_owner]) revert Errors.InsufficientShares();

        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_owner][msg.sender] = allowed - shares;
        }

        uint256 vaultBalance;
        (_assets, vaultBalance) = beforeWithdraw(_assets);

        if (_assets < _minAmount) revert Errors.InsufficientAssets();

        _burn(_owner, shares);

        asset.safeTransfer(_receiver, _assets);
        vaultAssets = vaultBalance - _assets;

        emit Withdraw(msg.sender, _receiver, _owner, _assets, shares);

        return shares;
    }

    /// @notice Redeem GVault shares for the equivalent amount of assets
    /// @param _shares the number of vault shares the caller wants to burn
    /// @param _receiver the address that will receive the asset tokens
    /// @param _owner the owner of the shares that will be burnt
    /// @return assets the amount of asset tokens sent to the receiver
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external override nonReentrant returns (uint256 assets) {
        if (_shares == 0) revert Errors.ZeroShares();

        if (_shares > balanceOf[_owner]) revert Errors.InsufficientShares();

        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max)
                allowance[_owner][msg.sender] = allowed - _shares;
        }

        assets = convertToAssets(_shares);
        uint256 vaultBalance;
        (assets, vaultBalance) = beforeWithdraw(assets);

        _burn(_owner, _shares);

        asset.safeTransfer(_receiver, assets);
        vaultAssets = vaultBalance - assets;

        emit Withdraw(msg.sender, _receiver, _owner, assets, _shares);

        return assets;
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice The maximum amount a user can deposit into the vault
    function maxDeposit(address)
        public
        view
        override
        returns (uint256 maxAssets)
    {
        return type(uint256).max - convertToAssets(totalSupply);
    }

    /// @notice Simulate the shares issued for a given deposit
    /// @param _assets number of asset tokens being deposited
    /// @return shares number of shares issued for the number of assets provided
    function previewDeposit(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        return convertToShares(_assets);
    }

    /// @notice maximum number of shares that can be minted
    function maxMint(address) public view override returns (uint256 maxShares) {
        return type(uint256).max - totalSupply;
    }

    /// @notice Simulate the number of assets required to mint a specific number of shares
    /// @param _shares number of shares to mint
    /// @return assets number of assets required to issue the shares inputted
    function previewMint(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            _totalSupply == 0
                ? _shares
                : Math.ceilDiv((_shares * _freeFunds()), _totalSupply);
    }

    /// @notice maximum amount of asset tokens the owner can withdraw
    /// @param _owner address of the owner of the GVault Shares
    /// @return maxAssets maximum amount of asset tokens the owner can withdraw
    function maxWithdraw(address _owner)
        public
        view
        override
        returns (uint256 maxAssets)
    {
        return convertToAssets(balanceOf[_owner]);
    }

    /// @notice return the amount of shares that would be burned for a given number of assets
    /// @param _assets number of assert tokens to withdraw
    /// @return shares burnt during withdrawal
    function previewWithdraw(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        uint256 freeFunds_ = _freeFunds(); // Saves an extra SLOAD if _freeFunds is non-zero.
        return
            freeFunds_ == 0
                ? _assets
                : Math.ceilDiv(_assets * totalSupply, freeFunds_);
    }

    /// @notice maximum number of shares the owner can redeem
    /// @param _owner address for the owner of the GVault shares
    /// @return maxShares number of GVault shares the owner has
    function maxRedeem(address _owner)
        public
        view
        override
        returns (uint256 maxShares)
    {
        return balanceOf[_owner];
    }

    /// @notice Returns the amount of assets that can be redeemed with the shares
    /// @param _shares the number of shares the caller wants to redeem
    /// @return assets the number of asset tokens the caller would receive
    function previewRedeem(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        return convertToAssets(_shares);
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate system total assets including estimated profits
    function totalAssets() external view override returns (uint256) {
        return _estimatedTotalAssets();
    }

    /// @notice Calculate system total assets excluding estimated profits
    function realizedTotalAssets() external view returns (uint256) {
        return _totalAssets();
    }

    /// @notice Value of asset in shares
    /// @param _assets amount of asset to convert to shares
    function convertToShares(uint256 _assets)
        public
        view
        override
        returns (uint256 shares)
    {
        uint256 freeFunds_ = _freeFunds(); // Saves an extra SLOAD if _freeFunds is non-zero.
        return freeFunds_ == 0 ? _assets : (_assets * totalSupply) / freeFunds_;
    }

    /// @notice Value of shares in underlying asset
    /// @param _shares amount of shares to convert to tokens
    function convertToAssets(uint256 _shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            _totalSupply == 0
                ? _shares
                : ((_shares * _freeFunds()) / _totalSupply);
    }

    /// @notice Gives the price for a single Vault share.
    /// @return The value of a single share.
    function getPricePerShare() external view returns (uint256) {
        return convertToAssets(10**decimals);
    }

    /*//////////////////////////////////////////////////////////////
                            STRATEGY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of active strategies in the vaultAdapter
    function noOfStrategies() internal view returns (uint256) {
        return strategyQueue.totalNodes;
    }

    /// @notice Update the debtRatio of a specific strategy
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    function setDebtRatio(address _strategy, uint256 _debtRatio)
        external
        onlyOwner
    {
        if (!strategies[_strategy].active) revert Errors.StrategyNotActive();
        _setDebtRatio(_strategy, _debtRatio);
    }

    /// @notice Add a new strategy to the vault adapter
    /// @param _strategy target strategy to add
    /// @param _debtRatio target debtRatio of strategy
    function addStrategy(address _strategy, uint256 _debtRatio)
        external
        onlyOwner
    {
        if (_strategy == ZERO_ADDRESS) revert Errors.ZeroAddress();
        if (strategies[_strategy].active) revert Errors.StrategyActive();
        if (address(this) != IStrategy(_strategy).vault())
            revert Errors.IncorrectVaultOnStrategy();

        StrategyParams storage newStrat = strategies[_strategy];
        newStrat.active = true;
        _setDebtRatio(_strategy, _debtRatio);
        newStrat.lastReport = block.timestamp;

        _push(_strategy);
    }

    /// @notice remove existing strategy from vault by revoking and removing
    ///     from the withdrawal queue
    /// @param _strategy address of old strategy
    /// @dev Should be called when all the debt has been paid back to the vault
    function removeStrategy(address _strategy) external onlyOwner {
        if (!strategies[_strategy].active) revert Errors.StrategyNotActive();
        _revokeStrategy(_strategy);
        _removeStrategy(_strategy);
    }

    /// @notice remove strategy from the withdrawal queue
    /// @param _strategy address of strategy to remove
    function _removeStrategy(address _strategy) internal {
        if (strategies[_strategy].active) revert Errors.StrategyActive();
        if (strategies[_strategy].totalDebt > 0)
            revert Errors.StrategyDebtNotZero();

        _pop(_strategy);
    }

    /// @notice Remove strategy from vault adapter
    function revokeStrategy() external {
        if (!strategies[msg.sender].active) revert Errors.StrategyNotActive();
        _revokeStrategy(msg.sender);
    }

    /// @notice Move the strategy to a new position
    /// @param _strategy Target strategy to move
    /// @param _pos desired position of strategy
    /// @dev if the _pos value is >= number of strategies in the queue,
    ///      the strategy will be moved to the tail position
    function moveStrategy(address _strategy, uint256 _pos) external onlyOwner {
        uint256 currentPos = getStrategyPositions(_strategy);
        uint256 _strategyId = strategyId[_strategy];
        if (currentPos > _pos)
            move(uint48(_strategyId), uint48(currentPos - _pos), false);
        else move(uint48(_strategyId), uint48(_pos - currentPos), true);
    }

    /// @notice Check how much credits are available for the strategy
    /// @param _strategy Target strategy
    function creditAvailable(address _strategy)
        external
        view
        returns (uint256)
    {
        return _creditAvailable(_strategy);
    }

    /// @notice Same as above but called by the streategy
    function creditAvailable() external view returns (uint256) {
        return _creditAvailable(msg.sender);
    }

    /// @notice Amount of debt the strategy has to pay back to the vault at next harvest
    /// @param _strategy target strategy
    /// @return amount of debt the strategy has to pay back and the current debt ratio of the strategy
    function excessDebt(address _strategy)
        external
        view
        returns (uint256, uint256)
    {
        return _excessDebt(_strategy);
    }

    /// @notice Helper function to get strategy's total debt to the vault
    /// @dev here to simplify strategy's life when trying to get the totalDebt
    function strategyDebt() external view returns (uint256) {
        return strategies[msg.sender].totalDebt;
    }

    /// @notice Report back any gains/losses from a (strategy) harvest, vault adapter
    ///     calls back debt or gives out more credit to the strategy depending on available
    ///     credit and the strategies current position.
    /// @param _gain Strategy gains from latest harvest
    /// @param _loss Strategy losses from latest harvest
    /// @param _debtPayment Amount strategy can pay back to vault
    /// @param _emergency Flag to indicate if the harvest was an emergency harvest
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment,
        bool _emergency
    ) external returns (uint256) {
        StrategyParams storage _strategy = strategies[msg.sender];
        if (!_strategy.active) revert Errors.StrategyNotActive();
        if (asset.balanceOf(msg.sender) < _debtPayment)
            revert Errors.IncorrectStrategyAccounting();

        if (_loss > 0) {
            _reportLoss(msg.sender, _loss);
        }
        if (_gain > 0) {
            _strategy.totalGain += _gain;
            _strategy.totalDebt += _gain;
            vaultTotalDebt += _gain;
        }

        if (_emergency) {
            _revokeStrategy(msg.sender);
        }

        (uint256 debt, ) = _excessDebt(msg.sender);
        uint256 debtPayment = Math.min(_debtPayment, debt);

        if (debtPayment > 0) {
            _strategy.totalDebt = _strategy.totalDebt - debtPayment;
            vaultTotalDebt -= debtPayment;
            debt -= debtPayment;
        }

        uint256 credit = _creditAvailable(msg.sender);

        if (credit > 0) {
            _strategy.totalDebt += credit;
            vaultTotalDebt += credit;
        }

        uint256 totalAvailable = debtPayment;

        if (totalAvailable < credit) {
            asset.safeTransfer(msg.sender, credit - totalAvailable);
            vaultAssets -= credit - totalAvailable;
        } else if (totalAvailable > credit) {
            asset.safeTransferFrom(
                msg.sender,
                address(this),
                totalAvailable - credit
            );
            vaultAssets += totalAvailable - credit;
        }

        // Profit is locked and gradually released per block
        // this computes current locked profit and replace with
        // the sum of the current and the new profit
        uint256 lockedProfitBeforeLoss = _calculateLockedProfit() +
            _calcFees(_gain);
        // Store how much loss remains after locked profit is removed,
        // here only for logging purposes
        if (lockedProfitBeforeLoss > _loss) {
            lockedProfit = lockedProfitBeforeLoss - _loss;
        } else {
            lockedProfit = 0;
        }

        lastReport = block.timestamp;
        _strategy.lastReport = lastReport;

        if (_emergency) {
            _removeStrategy(msg.sender);
        }

        emit LogStrategyHarvestReport(
            msg.sender,
            _gain,
            _loss,
            debtPayment,
            credit,
            lockedProfit,
            lockedProfitBeforeLoss
        );

        emit LogStrategyTotalChanges(
            msg.sender,
            _strategy.totalGain,
            _strategy.totalLoss,
            _strategy.totalDebt
        );

        return credit;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL HOOKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Runs before any withdraw function mainly to ensure vault has enough assets
    /// @param _assets Amount of assets to withdraw
    /// @return Amount of assets withdrawn and amount of assets in vault
    function beforeWithdraw(uint256 _assets)
        internal
        returns (uint256, uint256)
    {
        // If reserves dont cover the withdrawal, start withdrawing from strategies
        ERC20 _token = asset;
        uint256 vaultBalance = vaultAssets;
        if (_assets > vaultBalance) {
            uint48 _strategyId = strategyQueue.head;
            while (true) {
                address _strategy = nodes[_strategyId].strategy;
                // break if we have withdrawn all we need
                if (_assets <= vaultBalance) break;
                uint256 amountNeeded = _assets - vaultBalance;

                StrategyParams storage _strategyData = strategies[_strategy];
                amountNeeded = Math.min(amountNeeded, _strategyData.totalDebt);
                // If nothing is needed or strategy has no assets, continue
                if (amountNeeded > 0) {
                    (uint256 withdrawn, uint256 loss) = IStrategy(_strategy)
                        .withdraw(amountNeeded);

                    // Handle the loss if any
                    if (loss > 0) {
                        _assets = _assets - loss;
                        _reportLoss(_strategy, loss);
                    }
                    // Remove withdrawn amount from strategy and vault debts
                    _strategyData.totalDebt -= withdrawn;
                    vaultTotalDebt -= withdrawn;
                    vaultBalance += withdrawn;
                    emit LogWithdrawalFromStrategy(
                        _strategyId,
                        _strategyData.totalDebt,
                        vaultTotalDebt,
                        loss
                    );
                }
                _strategyId = nodes[_strategyId].next;
                if (_strategyId == 0) break;
            }
            if (_assets > vaultBalance) {
                _assets = vaultBalance;
            }
        }
        return (_assets, vaultBalance);
    }

    /// @notice Calculate how much profit is currently locked
    function _calculateLockedProfit() internal view returns (uint256) {
        uint256 _releaseTime = releaseTime;
        uint256 _timeSinceLastReport = block.timestamp - lastReport;
        if (_releaseTime > _timeSinceLastReport) {
            uint256 _lockedProfit = lockedProfit;
            return
                _lockedProfit -
                ((_lockedProfit * _timeSinceLastReport) / _releaseTime);
        } else {
            return 0;
        }
    }

    /// @notice the number of total assets the GVault has excluding profits
    /// and losses
    function _freeFunds() internal view returns (uint256) {
        return _totalAssets() - _calculateLockedProfit();
    }

    /// @notice Calculate the amount of assets the vault has available for the strategy to pull and invest,
    ///     the available credit is based on the strategies debt ratio and the total available assets
    ///     the vault has
    /// @param _strategy target strategy
    /// @dev called during harvest
    function _creditAvailable(address _strategy)
        internal
        view
        returns (uint256)
    {
        StrategyParams memory _strategyData = strategies[_strategy];
        uint256 vaultTotalAssets = _totalAssets();
        uint256 vaultDebtLimit = (vaultDebtRatio * vaultTotalAssets) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 _vaultTotalDebt = vaultTotalDebt;
        uint256 strategyDebtLimit = (_strategyData.debtRatio *
            vaultTotalAssets) / PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = _strategyData.totalDebt;

        if (
            strategyDebtLimit <= strategyTotalDebt ||
            vaultDebtLimit <= _vaultTotalDebt
        ) {
            return 0;
        }

        uint256 available = strategyDebtLimit - strategyTotalDebt;

        available = Math.min(available, vaultDebtLimit - _vaultTotalDebt);

        return Math.min(available, vaultAssets);
    }

    /// @notice Deal with any loss that a strategy has realized
    /// @param _strategy target strategy
    /// @param _loss amount of loss realized
    function _reportLoss(address _strategy, uint256 _loss) internal {
        StrategyParams storage strategy = strategies[_strategy];
        // Loss can only be up the amount of debt issued to strategy
        if (strategy.totalDebt < _loss) revert Errors.StrategyLossTooHigh();
        // Add loss to strategy and remove loss from strategyDebt
        strategy.totalLoss += _loss;
        strategy.totalDebt -= _loss;
        vaultTotalDebt -= _loss;
    }

    /// @notice Amount by which a strategy exceeds its current debt limit
    /// @param _strategy target strategy
    /// @return amount of debt the strategy has to pay back and the current debt ratio of the strategy
    function _excessDebt(address _strategy)
        internal
        view
        returns (uint256, uint256)
    {
        StrategyParams storage strategy = strategies[_strategy];
        uint256 _debtRatio = strategy.debtRatio;
        uint256 strategyDebtLimit = (_debtRatio * _totalAssets()) /
            PERCENTAGE_DECIMAL_FACTOR;
        uint256 strategyTotalDebt = strategy.totalDebt;

        if (strategyTotalDebt <= strategyDebtLimit) {
            return (0, _debtRatio);
        } else {
            return (strategyTotalDebt - strategyDebtLimit, _debtRatio);
        }
    }

    function _calcFees(uint256 _gain) internal returns (uint256) {
        uint256 fees = (_gain * vaultFee) / PERCENTAGE_DECIMAL_FACTOR;
        if (fees > 0) {
            uint256 shares = convertToShares(fees);
            _mint(feeCollector, shares);
        }
        return _gain - fees;
    }

    /// @notice Update a given strategys debt ratio
    /// @param _strategy target strategy
    /// @param _debtRatio new debt ratio
    /// @dev See setDebtRatio functions
    function _setDebtRatio(address _strategy, uint256 _debtRatio) internal {
        uint256 _vaultDebtRatio = vaultDebtRatio -
            strategies[_strategy].debtRatio +
            _debtRatio;
        if (_vaultDebtRatio > PERCENTAGE_DECIMAL_FACTOR)
            revert Errors.VaultDebtRatioTooHigh();
        strategies[_strategy].debtRatio = _debtRatio;
        vaultDebtRatio = _vaultDebtRatio;
        emit LogNewDebtRatio(_strategy, _debtRatio, _vaultDebtRatio);
    }

    /// @notice Get current estimated amount of assets in strategy
    /// @param _index index of strategy
    function _getStrategyEstimatedTotalAssets(uint256 _index)
        internal
        view
        returns (uint256)
    {
        return IStrategy(nodes[_index].strategy).estimatedTotalAssets();
    }

    /// @notice Remove strategy from vault
    /// @param _strategy address of strategy
    function _revokeStrategy(address _strategy) internal {
        vaultDebtRatio -= strategies[_strategy].debtRatio;
        strategies[_strategy].debtRatio = 0;
        strategies[_strategy].active = false;
    }

    /// @notice Vault adapters total assets including loose assets and debts
    /// @dev note that this does not consider estimated gains/losses from the strategies
    function _totalAssets() private view returns (uint256) {
        return vaultAssets + vaultTotalDebt;
    }

    /// @notice Vault adapters total assets including loose assets and estimated returns
    /// @dev note that this does consider estimated gains/losses from the strategies
    function _estimatedTotalAssets() private view returns (uint256) {
        uint256 total = vaultAssets;
        uint256[MAXIMUM_STRATEGIES] memory _queue = fullWithdrawalQueue();
        for (uint256 i = 0; i < noOfStrategies(); ++i) {
            total += _getStrategyEstimatedTotalAssets(_queue[i]);
        }
        return total;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IStrategy {
    function asset() external view returns (address);

    function vault() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function withdraw(uint256 _amount) external returns (uint256, uint256);

    function canHarvest() external view returns (bool);

    function runHarvest() external;

    function canStopLoss() external view returns (bool);

    function stopLoss() external returns (bool);

    function getMetaPool() external view returns (address);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint8 public constant DEFAULT_DECIMALS = 18; // GToken and Controller use these decimals
    uint256 public constant DEFAULT_DECIMALS_FACTOR =
        uint256(10)**DEFAULT_DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR =
        uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR =
        uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR =
        uint256(10)**CURVE_RATIO_DECIMALS;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title StrategyQueue
/// @notice StrategyQueue - logic for handling ordering of vault strategies
///     ---------    ---------    ---------
///     | Strat |    | Strat |    | Strat |
///     |  ---  |    |  ---  |    |  ---  |
/// 0<--|  prev-|<---|  prev-|<---|  prev-|
///     |  next-|--->|  next-|--->|  next-|-->0
///     ---------    ---------    ---------
///       Head                      Tail
contract StrategyQueue {
    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    // node in queue
    struct Strategy {
        uint48 next;
        uint48 prev;
        address strategy;
    }

    // Information regarding queue
    struct Queue {
        uint48 head;
        uint48 tail;
        uint48 totalNodes;
        uint48 nextAvailableNode;
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAXIMUM_STRATEGIES = 5;
    address internal constant ZERO_ADDRESS = address(0);
    uint48 internal constant EMPTY_NODE = 0;

    mapping(address => uint256) public strategyId;
    mapping(uint256 => Strategy) internal nodes;

    Queue internal strategyQueue;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogStrategyRemoved(address indexed strategy, uint256 indexed id);
    event LogStrategyAdded(
        address indexed strategy,
        uint256 indexed id,
        uint256 pos
    );
    event LogNewQueueLink(uint256 indexed id, uint256 next);
    event LogNewQueueHead(uint256 indexed id);
    event LogNewQueueTail(uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                            ERRORS HANDLING
    //////////////////////////////////////////////////////////////*/

    error NoIdEntry(uint256 id);
    error StrategyNotMoved(uint256 errorNo);
    // 1 - no move specified
    // 2 - strategy cant be moved further up/down the queue
    // 3 - strategy moved to its own position
    error NoStrategyEntry(address strategy);
    error StrategyExists(address strategy);
    error MaxStrategyExceeded();

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get strategy at position i of withdrawal queue
    /// @param i position in withdrawal queue
    /// @return strategy strategy at position i
    function withdrawalQueueAt(uint256 i)
        external
        view
        returns (address strategy)
    {
        if (i == 0 || i == strategyQueue.totalNodes - 1) {
            strategy = i == 0
                ? nodes[strategyQueue.head].strategy
                : nodes[strategyQueue.tail].strategy;
        } else {
            uint256 index = strategyQueue.head;
            for (uint256 j; j <= i; j++) {
                if (j == i) return nodes[index].strategy;
                index = nodes[index].next;
            }
        }
    }

    /// @notice Get the entire withdrawal queue
    /// @return queue list of all strategy ids in order of withdrawal priority
    function fullWithdrawalQueue()
        internal
        view
        returns (uint256[MAXIMUM_STRATEGIES] memory queue)
    {
        uint256 index = strategyQueue.head;
        uint256 _totalNodes = strategyQueue.totalNodes;
        queue[0] = index;
        for (uint256 i = 1; i < _totalNodes; ++i) {
            index = nodes[index].next;
            queue[i] = index;
        }
    }

    /// @notice Get position of strategy in withdrawal queue
    /// @param _strategy address of strategy
    /// @return returns position of strategy in withdrawal queue
    function getStrategyPositions(address _strategy)
        public
        view
        returns (uint256)
    {
        uint48 index = strategyQueue.head;
        uint48 _totalNodes = strategyQueue.totalNodes;
        for (uint48 i = 0; i <= _totalNodes; ++i) {
            if (_strategy == nodes[index].strategy) {
                return i;
            }
            index = nodes[index].next;
        }
        revert NoStrategyEntry(_strategy);
    }

    /*//////////////////////////////////////////////////////////////
                          QUEUE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a strategy to the end of the queue
    /// @param _strategy address of strategy to add
    /// @dev creates a new node which is inserted at the end of the
    ///     strategy queue. the strategy is assigned an id and is
    ///     linked to the previous tail. Note that this ID isnt
    ///        necessarily the same as the position in the withdrawal queue
    function _push(address _strategy) internal returns (uint256) {
        if (strategyId[_strategy] > 0) revert StrategyExists(_strategy);
        uint48 nodeId = _createNode(_strategy);
        return uint256(nodeId);
    }

    /// @notice Remove strategy from queue
    /// @param _strategy strategy to remove
    /// @dev removes a node and links the nodes neighbours
    function _pop(address _strategy) internal {
        uint256 id = strategyId[_strategy];
        if (id == 0) revert NoStrategyEntry(_strategy);
        Strategy storage removeNode = nodes[uint48(id)];
        address strategy = removeNode.strategy;
        if (strategy == ZERO_ADDRESS) revert NoIdEntry(id);
        _link(removeNode.prev, removeNode.next);
        strategyId[_strategy] = 0;
        emit LogStrategyRemoved(strategy, id);
        delete nodes[uint48(id)];
        strategyQueue.totalNodes -= 1;
    }

    /// @notice move a strategy to a new position in the queue
    /// @param _id id of strategy to move
    /// @param _steps number of steps to move the strategy
    /// @param _back move towards tail (true) or head (false)
    /// @dev Moves a strategy a given number of steps. If the number
    ///        of steps exceeds the position of the head/tail, the
    ///        strategy will take the place of the current head/tail
    function move(
        uint48 _id,
        uint48 _steps,
        bool _back
    ) internal {
        Strategy storage oldPos = nodes[_id];
        if (_steps == 0) revert StrategyNotMoved(1);
        if (oldPos.strategy == ZERO_ADDRESS) revert NoIdEntry(_id);
        uint48 _newPos = !_back ? oldPos.prev : oldPos.next;
        if (_newPos == 0) revert StrategyNotMoved(2);

        for (uint256 i = 1; i < _steps; ++i) {
            _newPos = !_back ? nodes[_newPos].prev : nodes[_newPos].next;
            if (_newPos == 0) {
                _newPos = !_back ? strategyQueue.head : strategyQueue.tail;
                break;
            }
        }
        if (_newPos == _id) revert StrategyNotMoved(3);
        Strategy memory newPos = nodes[_newPos];
        _link(oldPos.prev, oldPos.next);
        if (!_back) {
            _link(newPos.prev, _id);
            _link(_id, _newPos);
        } else {
            _link(_id, newPos.next);
            _link(_newPos, _id);
        }
    }

    /// @notice Create a new node to be inserted at the tail of the queue
    /// @param _strategy address of strategy to add
    /// @return id of strategy
    function _createNode(address _strategy) internal returns (uint48) {
        uint48 _totalNodes = strategyQueue.totalNodes;
        if (_totalNodes >= MAXIMUM_STRATEGIES) revert MaxStrategyExceeded();
        strategyQueue.nextAvailableNode += 1;
        strategyQueue.totalNodes = _totalNodes + 1;
        uint48 newId = uint48(strategyQueue.nextAvailableNode);
        strategyId[_strategy] = newId;

        uint48 _tail = strategyQueue.tail;
        Strategy memory node = Strategy(EMPTY_NODE, _tail, _strategy);

        _link(_tail, newId);
        _setTail(newId);
        nodes[newId] = node;

        emit LogStrategyAdded(_strategy, newId, _totalNodes + 1);

        return newId;
    }

    /// @notice Set the head of the queue
    /// @param _id Id of the strategy to set the head to
    function _setHead(uint256 _id) internal {
        strategyQueue.head = uint48(_id);
        emit LogNewQueueHead(_id);
    }

    /// @notice Set the tail of the queue
    /// @param _id Id of the strategy to set the tail to
    function _setTail(uint256 _id) internal {
        strategyQueue.tail = uint48(_id);
        emit LogNewQueueTail(_id);
    }

    /// @notice Link two nodes
    /// @param _prevId id of previous node
    /// @param _nextId id of next node
    function _link(uint48 _prevId, uint48 _nextId) internal {
        if (_prevId == EMPTY_NODE) {
            _setHead(_nextId);
        } else {
            nodes[_prevId].next = _nextId;
        }
        if (_nextId == EMPTY_NODE) {
            _setTail(_prevId);
        } else {
            nodes[_nextId].prev = _prevId;
        }
        emit LogNewQueueLink(_prevId, _nextId);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {Ownable} from "Ownable.sol";
import {IGTranche} from "IGTranche.sol";
import {IOracle} from "IOracle.sol";
import {IPnL} from "IPnL.sol";
import {ERC4626} from "ERC4626.sol";
import {Errors} from "Errors.sol";
import {FixedTokensCurve} from "FixedTokensCurve.sol";
import {GMigration} from "GMigration.sol";
import {IGToken} from "IGToken.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title GTranche
/// @notice GTranche - Lego block for handling tranching
///
///     ###############################################
///     GTranche Specification
///     ###############################################
///
///     The GTranche provides a novel way for insurance to be implemented on the blockchain,
///         allowing for users who seek a safer yield opportunity (senior tranche) to do so by
///         providing part of their deposit as leverage for an insurer (junior tranche). Which
///         is done by distributing parts of the yield generated by underlying tokens based
///         on the demand for insurance (utilisation ratio).
///     This version of the tranche takes advantage of the new tokenized vault standard
///     (https://eips.ethereum.org/EIPS/eip-4626) and acts as a wrapper for 4626 token in
///     order to generate and distribute yield.
///
///     This contract is one part of two required to define a tranche:
///         1) GTranche module - defines a set of tokens, and handles accounting
///             and yield distribution between the Senior and Junior tranche.
///         2) oracle/relation module - defines the relation between the tokens in
///             the tranche
///
///     The following logic is covered in the GTranche contract:
///         - Deposit:
///             - User deposits takes an EIP-4626 token and evaluates it to a common denominator,
///                which indicates the value of their deposit and the number of tranche tokens
///                that get minted
///         - Withdrawal:
///             - User withdrawals takes tranche tokens and evaluates their value to EIP-4626 tokens,
///                which indicates the number of tokens that should be returned to the user
///                on withdrawal
///         - PnL:
///             - User interactions evaluates the latest price per share of the underlying
///                4626 compatible tokens, effectively handling front-running of gains/losses.
///                Its important that the underlying EIP-4626 cannot be price manipulated, as this
///                would break the pnl functionality of this contract.
contract GTranche is IGTranche, FixedTokensCurve, Ownable {
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    // Module defining relations between underlying assets
    IOracle public immutable oracle;
    // Migration contract
    GMigration private immutable gMigration;
    uint256 public constant minDeposit = 1e18;

    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    // SENIOR / JUNIOR Tranche
    uint256 public utilisationThreshold = 10000;
    IPnL public pnl;

    // migration state
    bool public hasMigratedFromOldTranche;
    bool public hasMigrated;
    address newGTranche;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogNewDeposit(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 index,
        bool indexed tranche,
        uint256 calcAmount
    );

    event LogNewWithdrawal(
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint256 index,
        bool indexed tranche,
        uint256 yieldTokenAmounts,
        uint256 calcAmount
    );

    event LogNewUtilisationThreshold(uint256 newThreshold);
    event LogNewPnL(int256 profit, int256 loss);

    event LogMigration(
        uint256 JuniorTrancheBalance,
        uint256 SeniorTrancheBalance,
        uint256[] YieldTokenBalances
    );

    event LogSetNewPnLLogic(address pnl);
    event LogMigrationPrepared(address newGTranche);
    event LogMigrationFinished(address newGTranche);

    constructor(
        address[] memory _yieldTokens,
        address[2] memory _trancheTokens,
        IOracle _oracle,
        GMigration _gMigration
    ) FixedTokensCurve(_yieldTokens, _trancheTokens) {
        oracle = _oracle;
        gMigration = _gMigration;
    }

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the threshold for when utilisation will prohibit deposit
    ///     from the senior tranche, or withdrawals for the junior
    /// @param _newThreshold target utilisation threshold
    function setUtilisationThreshold(uint256 _newThreshold) external onlyOwner {
        utilisationThreshold = _newThreshold;
        emit LogNewUtilisationThreshold(_newThreshold);
    }

    /// @notice Set the pnl logic of the tranche
    /// @param _pnl new pnl logic
    function setPnL(IPnL _pnl) external onlyOwner {
        pnl = _pnl;
        emit LogSetNewPnLLogic(address(_pnl));
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Handles deposit logic for GTranche:
    ///     User deposits underlying yield tokens which values get calculated
    ///     to a common denominator used to price the tranches in. This operation
    ///     relies on the existence of a relation/oracle module that allows this
    ///     contract to establish a relation between the underlying yield tokens.
    ///     Any unearned profit will be realized before the tokens are minted,
    ///     effectively stopping the user from front-running profit.
    /// @param _amount amount of yield token user deposits
    /// @param _index index of yield token deposited
    /// @param _tranche tranche user wishes to go into
    /// @param _recipient recipient of tranche tokens
    /// @return trancheAmount amount of tranche tokens minted
    /// @return calcAmount value of tranche token in common denominator (USD)
    /// @dev this function will revert if a senior tranche deposit makes the utilisation
    ///     exceed the utilisation ratio
    function deposit(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address _recipient
    ) external override returns (uint256 trancheAmount, uint256 calcAmount) {
        ERC4626 token = getYieldToken(_index);
        token.transferFrom(msg.sender, address(this), _amount);

        IGToken trancheToken = getTrancheToken(_tranche);

        uint256 factor;
        uint256 trancheUtilisation;

        // update value of current tranches - this prevents front-running of profits
        (trancheUtilisation, calcAmount, factor) = updateDistribution(
            _amount,
            _index,
            _tranche,
            false
        );

        if (calcAmount < minDeposit) {
            revert("GTranche: deposit amount too low");
        }
        if (_tranche && trancheUtilisation > utilisationThreshold) {
            revert Errors.UtilisationTooHigh();
        }

        tokenBalances[_index] += _amount;
        trancheToken.mint(_recipient, factor, calcAmount);
        emit LogNewDeposit(
            msg.sender,
            _recipient,
            _amount,
            _index,
            _tranche,
            calcAmount
        );
        if (_tranche) trancheAmount = calcAmount;
        else trancheAmount = (calcAmount * factor) / DEFAULT_FACTOR;
    }

    /// @notice Handles withdrawal logic:
    ///     User redeems an amount of tranche token for underlying yield tokens, any loss/profit
    ///     will be realized before the tokens are burned, effectively stopping the user from
    ///     front-running losses or lose out on gains when redeeming
    /// @param _amount amount of tranche tokens to redeem
    /// @param _index index of yield token the user wishes to withdraw
    /// @param _tranche tranche user wishes to redeem
    /// @param _recipient recipient of the yield tokens
    /// @return yieldTokenAmounts amount of underlying tokens withdrawn
    /// @return calcAmount value of tranche token in common denominator (USD)
    /// @dev this function will revert if a senior tranche deposit makes the utilisation
    function withdraw(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address _recipient
    )
        external
        override
        returns (uint256 yieldTokenAmounts, uint256 calcAmount)
    {
        IGToken trancheToken = getTrancheToken(_tranche);

        if (_amount > trancheToken.balanceOf(msg.sender)) {
            revert Errors.NotEnoughBalance();
        }
        ERC4626 token = getYieldToken(_index);

        uint256 factor; // = _calcFactor(_tranche);
        uint256 trancheUtilisation;

        // update value of current tranches - this prevents front-running of losses
        (trancheUtilisation, calcAmount, factor) = updateDistribution(
            _amount,
            _index,
            _tranche,
            true
        );

        if (!_tranche && trancheUtilisation > utilisationThreshold) {
            revert Errors.UtilisationTooHigh();
        }

        yieldTokenAmounts = _calcTokenAmount(_index, calcAmount, false);
        tokenBalances[_index] -= yieldTokenAmounts;

        trancheToken.burn(msg.sender, factor, calcAmount);
        token.transfer(_recipient, yieldTokenAmounts);

        emit LogNewWithdrawal(
            msg.sender,
            _recipient,
            _amount,
            _index,
            _tranche,
            yieldTokenAmounts,
            calcAmount
        );
        return (yieldTokenAmounts, calcAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the current utilisation ratio of the tranche in BP
    function utilisation() external view returns (uint256) {
        (uint256[NO_OF_TRANCHES] memory _totalValue, , ) = pnlDistribution();
        if (_totalValue[1] == 0) return 0;
        return
            _totalValue[0] > 0
                ? (_totalValue[1] * DEFAULT_DECIMALS) / (_totalValue[0])
                : type(uint256).max;
    }

    /// @notice Update the current assets in the Junior/Senior tranche by
    ///     taking the change in value of the underlying yield token into account since
    ///     the previous interaction and distributing these based on the profit
    ///     distribution curve.
    /// @param _amount value of deposit/withdrawal
    /// @param _index index of yield token
    /// @param _tranche senior or junior tranche being deposited/withdrawn
    /// @param _withdraw withdrawal or deposit
    /// @return trancheUtilisation current utilisation of the two tranches (senior / junior)
    /// @return calcAmount value of tranche token in common denominator (USD)
    /// @return factor factor applied to the tranche token
    function updateDistribution(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        bool _withdraw
    )
        internal
        returns (
            uint256 trancheUtilisation,
            uint256 calcAmount,
            uint256 factor
        )
    {
        (
            uint256[NO_OF_TRANCHES] memory _totalValue,
            int256 profit,
            int256 loss
        ) = _pnlDistribution();

        factor = _tranche
            ? _calcFactor(_tranche, _totalValue[1])
            : _calcFactor(_tranche, _totalValue[0]);
        if (_withdraw) {
            calcAmount = _tranche
                ? _amount
                : _calcTrancheValue(_tranche, _amount, factor, _totalValue[0]);
            if (_tranche) _totalValue[1] -= calcAmount;
            else _totalValue[0] -= calcAmount;
        } else {
            calcAmount = _calcTokenValue(_index, _amount, true);
            if (_tranche) _totalValue[1] += calcAmount;
            else _totalValue[0] += calcAmount;
        }
        trancheBalances[SENIOR_TRANCHE_ID] = _totalValue[1];
        trancheBalances[JUNIOR_TRANCHE_ID] = _totalValue[0];

        if (_totalValue[1] == 0) trancheUtilisation = 0;
        else
            trancheUtilisation = _totalValue[0] > 0
                ? (_totalValue[1] * DEFAULT_DECIMALS) / (_totalValue[0])
                : type(uint256).max;
        emit LogNewTrancheBalance(_totalValue, trancheUtilisation);
        emit LogNewPnL(profit, loss);
        return (trancheUtilisation, calcAmount, factor);
    }

    /// @notice View of current asset distribution
    function pnlDistribution()
        public
        view
        returns (
            uint256[NO_OF_TRANCHES] memory newTrancheBalances,
            int256 profit,
            int256 loss
        )
    {
        int256[NO_OF_TRANCHES] memory _trancheBalances;
        int256 totalValue = int256(_calcUnifiedValue());
        _trancheBalances[0] = int256(trancheBalances[JUNIOR_TRANCHE_ID]);
        _trancheBalances[1] = int256(trancheBalances[SENIOR_TRANCHE_ID]);
        int256 lastTotal = _trancheBalances[0] + _trancheBalances[1];
        if (lastTotal > totalValue) {
            unchecked {
                loss = lastTotal - totalValue;
            }
            int256[NO_OF_TRANCHES] memory losses = pnl.distributeLoss(
                loss,
                _trancheBalances
            );
            _trancheBalances[0] -= losses[0];
            _trancheBalances[1] -= losses[1];
        } else {
            unchecked {
                profit = totalValue - lastTotal;
            }
            int256[NO_OF_TRANCHES] memory profits = pnl.distributeProfit(
                profit,
                _trancheBalances
            );
            _trancheBalances[0] += profits[0];
            _trancheBalances[1] += profits[1];
        }
        newTrancheBalances[0] = uint256(_trancheBalances[0]);
        newTrancheBalances[1] = uint256(_trancheBalances[1]);
    }

    /// @notice Calculate the changes in underlying token value and distribute profit
    function _pnlDistribution()
        internal
        returns (
            uint256[NO_OF_TRANCHES] memory newTrancheBalances,
            int256 profit,
            int256 loss
        )
    {
        int256[NO_OF_TRANCHES] memory _trancheBalances;
        int256 totalValue = int256(_calcUnifiedValue());
        _trancheBalances[0] = int256(trancheBalances[JUNIOR_TRANCHE_ID]);
        _trancheBalances[1] = int256(trancheBalances[SENIOR_TRANCHE_ID]);
        int256 lastTotal = _trancheBalances[0] + _trancheBalances[1];
        if (lastTotal > totalValue) {
            unchecked {
                loss = lastTotal - totalValue;
            }
            int256[NO_OF_TRANCHES] memory losses = pnl.distributeAssets(
                true,
                loss,
                _trancheBalances
            );
            _trancheBalances[0] -= losses[0];
            _trancheBalances[1] -= losses[1];
        } else {
            unchecked {
                profit = totalValue - lastTotal;
            }
            int256[NO_OF_TRANCHES] memory profits = pnl.distributeAssets(
                false,
                profit,
                _trancheBalances
            );
            _trancheBalances[0] += profits[0];
            _trancheBalances[1] += profits[1];
        }
        newTrancheBalances[0] = uint256(_trancheBalances[0]);
        newTrancheBalances[1] = uint256(_trancheBalances[1]);
    }

    /*//////////////////////////////////////////////////////////////
                        Price/Value logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of the underlying yield token
    /// @param _index index of yield token
    /// @param _amount amount of yield tokens
    /// @param _deposit is the transaction a deposit or a withdrawal
    function _calcTokenValue(
        uint256 _index,
        uint256 _amount,
        bool _deposit
    ) internal view returns (uint256) {
        return
            oracle.getSinglePrice(
                _index,
                getYieldTokenValue(_index, _amount),
                _deposit
            );
    }

    /// @notice Calculate the number of yield token for the given amount
    /// @param _index index of yield token
    /// @param _amount amount to convert to yield tokens
    /// @param _deposit is the transaction a deposit or a withdrawal
    function _calcTokenAmount(
        uint256 _index,
        uint256 _amount,
        bool _deposit
    ) internal view returns (uint256) {
        return
            getYieldTokenAmount(
                _index,
                oracle.getTokenAmount(_index, _amount, _deposit)
            );
    }

    /// @notice Calculate the value of all underlying yield tokens
    function _calcUnifiedValue() internal view returns (uint256 totalValue) {
        uint256[NO_OF_TOKENS] memory yieldTokenValues = getYieldTokenValues();
        uint256[] memory tokenValues = new uint256[](NO_OF_TOKENS);
        for (uint256 i; i < NO_OF_TOKENS; ++i) {
            tokenValues[i] = yieldTokenValues[i];
        }
        totalValue = oracle.getTotalValue(tokenValues);
    }

    /*//////////////////////////////////////////////////////////////
                        Migration LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Migrates funds from the old gro protocol
    /// @dev Can only be run once and is and intermediary step to move assets
    ///     from gro-protocol to GSquared. This function is ultimately going to
    ///     be removed from newer iterations of this smart contract as it serves
    ///     no purpose for new tranches.
    function migrateFromOldTranche() external onlyOwner {
        if (hasMigratedFromOldTranche) {
            revert Errors.AlreadyMigrated();
        }

        // only one token in the initial version of the GTranche
        uint256 token_index = NO_OF_TOKENS - 1;
        ERC4626 token = getYieldToken(token_index);

        uint256[] memory yieldTokenShares = new uint256[](NO_OF_TOKENS);
        uint256 _shares = token.balanceOf(address(gMigration));
        yieldTokenShares[token_index] = _shares;
        uint256 seniorDollarAmount = gMigration.seniorTrancheDollarAmount();

        // calculate yield token shares for seniorDollarAmount
        uint256 seniorShares = _calcTokenAmount(0, seniorDollarAmount, true);
        // get the amount of shares per tranche
        uint256 juniorShares = _shares - seniorShares;

        // calculate $ value of each tranche
        uint256 juniorValue = _calcTokenValue(0, juniorShares, true);
        uint256 seniorValue = _calcTokenValue(0, seniorShares, true);

        // update tranche $ balances
        trancheBalances[SENIOR_TRANCHE_ID] += seniorValue;
        trancheBalances[JUNIOR_TRANCHE_ID] += juniorValue;

        // update yield token balances
        tokenBalances[0] += _shares;
        hasMigratedFromOldTranche = true;

        token.transferFrom(address(gMigration), address(this), _shares);

        updateDistribution(0, 0, true, false);

        emit LogMigration(juniorValue, seniorValue, yieldTokenShares);
    }

    /// @notice Set the target for the migration
    /// @dev This should be kept behind a timelock as the address could be any EOA
    ///    which could drain funds. This function should ultimately be removed
    /// @param _newGTranche address of new GTranche
    function prepareMigration(address _newGTranche) external onlyOwner {
        newGTranche = _newGTranche;
        emit LogMigrationPrepared(_newGTranche);
    }

    /// @notice Transfer funds and update Tranches values
    /// @dev Updates the state of the tranche post migration.
    ///     This function should ultimately be removed
    function finalizeMigration() external override {
        if (msg.sender != newGTranche) revert Errors.MsgSenderNotTranche();
        if (hasMigrated) {
            revert Errors.AlreadyMigrated();
        }
        ERC4626 token;
        for (uint256 index; index < NO_OF_TOKENS; index++) {
            token = getYieldToken(index);
            token.transfer(msg.sender, token.balanceOf(address(this)));
            tokenBalances[index] = token.balanceOf(address(this));
        }
        updateDistribution(0, 0, true, false);
        emit LogMigrationFinished(msg.sender);
    }

    /// @notice Migrate assets from old GTranche to new GTranche
    /// @dev Assumes same mapping of yield tokens but you can have more at increased indexes
    ///     in the new tranche. This function should be behind a timelock.
    /// @param _oldGTranche address of the old GTranche
    function migrate(address _oldGTranche) external onlyOwner {
        GTranche oldTranche = GTranche(_oldGTranche);
        uint256 oldSeniorTrancheBalance = oldTranche.trancheBalances(true);
        uint256 oldJuniorTrancheBalance = oldTranche.trancheBalances(false);

        trancheBalances[SENIOR_TRANCHE_ID] += oldSeniorTrancheBalance;
        trancheBalances[JUNIOR_TRANCHE_ID] += oldJuniorTrancheBalance;

        uint256[] memory yieldTokenBalances = new uint256[](
            oldTranche.NO_OF_TOKENS()
        );

        oldTranche.finalizeMigration();

        uint256 oldBalance;
        uint256 currentBalance;
        for (uint256 index = 0; index < NO_OF_TOKENS; index++) {
            ERC4626 token = getYieldToken(index);
            oldBalance = tokenBalances[index];
            currentBalance = token.balanceOf(address(this));
            tokenBalances[index] = currentBalance;
            yieldTokenBalances[index] = currentBalance - oldBalance;
        }

        updateDistribution(0, 0, true, false);
        hasMigrated = true;

        emit LogMigration(
            trancheBalances[JUNIOR_TRANCHE_ID],
            trancheBalances[SENIOR_TRANCHE_ID],
            yieldTokenBalances
        );
    }

    /*//////////////////////////////////////////////////////////////
                        Legacy logic (GTokens)
    //////////////////////////////////////////////////////////////*/

    // Current BASE of legacy GVT (Junior tranche token)
    uint256 internal constant JUNIOR_INIT_BASE = 5000000000000000;

    /// @notice This function exists to support the older versions of the GToken
    ///     return value of underlying token based on caller
    function gTokenTotalAssets() external view returns (uint256) {
        (uint256[NO_OF_TRANCHES] memory _totalValue, , ) = pnlDistribution();
        if (msg.sender == JUNIOR_TRANCHE) return _totalValue[0];
        else if (msg.sender == SENIOR_TRANCHE) return _totalValue[1];
        else return _totalValue[0] + _totalValue[1];
    }

    /// @notice calculate the number of tokens for the given amount
    /// @param _tranche junior or senior tranche
    /// @param _amount amount to transform to tranche tokens
    /// @param _factor factor applied to tranche token
    /// @param _total total value in tranche
    function _calcTrancheValue(
        bool _tranche,
        uint256 _amount,
        uint256 _factor,
        uint256 _total
    ) internal view returns (uint256 amount) {
        if (_factor == 0) revert Errors.NoAssets();
        amount = (_amount * DEFAULT_FACTOR) / _factor;
        if (amount > _total) return _total;
        return amount;
    }

    /// @notice calculate the tranches factor
    /// @param _tranche junior or senior tranche
    /// @param _totalAssets total value in tranche
    /// @return factor factor to be applied to tranche
    /// @dev The factor is used to either determine the value of the tranche
    ///     or the number of tokens to be issued for a given amount
    function _calcFactor(bool _tranche, uint256 _totalAssets)
        internal
        view
        returns (uint256 factor)
    {
        IGToken trancheToken = getTrancheToken(_tranche);
        uint256 init_base = _tranche ? DEFAULT_FACTOR : JUNIOR_INIT_BASE;
        uint256 supply = trancheToken.totalSupplyBase();

        if (supply == 0) {
            return init_base;
        }

        if (_totalAssets > 0) {
            return (supply * DEFAULT_FACTOR) / _totalAssets;
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGTranche {
    function deposit(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address recipient
    ) external returns (uint256, uint256);

    function withdraw(
        uint256 _amount,
        uint256 _index,
        bool _tranche,
        address recipient
    ) external returns (uint256, uint256);

    function finalizeMigration() external;

    function utilisationThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IOracle {
    function getSwappingPrice(
        uint256 _i,
        uint256 _j,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getSinglePrice(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getTokenAmount(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view returns (uint256);

    function getTotalValue(uint256[] memory _amount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

/// @title IPnL
/// @notice PnL interface for a dsitribution module with two tranches
interface IPnL {
    function distributeAssets(
        bool _loss,
        int256 _amount,
        int256[2] calldata _trancheBalances
    ) external returns (int256[2] memory amounts);

    function distributeLoss(int256 _amount, int256[2] calldata _trancheBalances)
        external
        view
        returns (int256[2] memory loss);

    function distributeProfit(
        int256 _amount,
        int256[2] calldata _trancheBalances
    ) external view returns (int256[2] memory profit);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {Errors} from "Errors.sol";
import {ERC4626} from "ERC4626.sol";
import {IGToken} from "IGToken.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title FixedTokensCurve
/// @notice Token definition contract
///
///     ###############################################
///     GTranche Tokens specification
///     ###############################################
///
///     This contract allows us to modify the underpinnings of the tranche
///         without having to worry about changing the core logic. The implementation
///         beneath supports 3 underlying EIP-4626 compatible tokens, but this contract
///         can be modified to use any combination.
///     Tranche Tokens:
///         - One Senior and one Junior tranche, this should be left unchanged
///     Yield Tokens
///         - Define one address var. and one decimal var.
///             per asset in the tranche
///         - Modify the getYieldtoken and getYieldtokenDecimal functions
///             to reflect the number of tokens defined above.
///         - updated NO_OF_TOKENS to match above number
///
///     Disclaimer:
///     The tranche has only been tested with EIP-4626 compatible tokens,
///         but should in theory be able to work with any tokens as long as
///         custom logic is supplied in the getYieldTokenValue function.
///         The core logic that defines the relationship between the underlying
///         assets in the tranche is defined outside the scope of this contract
///         (see oracle/relation module). Also note that this contract assumes
///         that the 4626 token has the same decimals as its underlying token,
///         this is not guaranteed by EIP-4626 and would have to be modified in
///         case these to values deviate, but for the purpose of the token this
///         version intends to operate on, this is held true.
contract FixedTokensCurve {
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant DEFAULT_DECIMALS = 10_000;
    uint256 internal constant DEFAULT_FACTOR = 1_000_000_000_000_000_000;

    // Tranches
    uint256 public constant NO_OF_TRANCHES = 2;
    bool internal constant JUNIOR_TRANCHE_ID = false;
    bool internal constant SENIOR_TRANCHE_ID = true;

    // Yield tokens - 1 address + 1 decimal per token
    uint256 public constant NO_OF_TOKENS = 1;

    address internal immutable FIRST_TOKEN;
    uint256 internal immutable FIRST_TOKEN_DECIMALS;

    address internal immutable JUNIOR_TRANCHE;
    address internal immutable SENIOR_TRANCHE;

    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    // Accounting for total amount of yield tokens in the contract
    uint256[NO_OF_TOKENS] public tokenBalances;
    // Accounting for the total "value" (as defined in the oracle/relation module)
    //  of the tranches: True => Senior Tranche, False => Junior Tranche
    mapping(bool => uint256) public trancheBalances;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogNewTrancheBalance(
        uint256[NO_OF_TRANCHES] balances,
        uint256 _utilisation
    );

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory _yieldTokens, address[2] memory _trancheTokens)
    {
        FIRST_TOKEN = _yieldTokens[0];
        FIRST_TOKEN_DECIMALS = 10**ERC4626(_yieldTokens[0]).decimals();
        JUNIOR_TRANCHE = _trancheTokens[0];
        SENIOR_TRANCHE = _trancheTokens[1];
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the underlying yield token by index
    /// @param _index index of desired token
    /// @dev this function needs to be modified if the number of tokens is changed
    /// @return yieldToken tranches underlying yield token at index
    function getYieldToken(uint256 _index)
        public
        view
        returns (ERC4626 yieldToken)
    {
        if (_index >= NO_OF_TOKENS) {
            revert Errors.IndexTooHigh();
        }
        return ERC4626(FIRST_TOKEN);
    }

    /// @notice Get the underlying yield tokens decimals by index
    /// @param _index index of desired token
    /// @dev this function needs to be modified if the number of tokens is changed
    /// @return decimals token decimals
    function getYieldTokenDecimals(uint256 _index)
        public
        view
        returns (uint256 decimals)
    {
        if (_index >= NO_OF_TOKENS) {
            revert Errors.IndexTooHigh();
        }
        return FIRST_TOKEN_DECIMALS;
    }

    /// @notice Get the underlying tranche token by id (bool)
    /// @param _tranche boolean representation of tranche token
    /// @return trancheToken senior or junior tranche
    function getTrancheToken(bool _tranche)
        public
        view
        returns (IGToken trancheToken)
    {
        if (_tranche) return IGToken(SENIOR_TRANCHE);
        return IGToken(JUNIOR_TRANCHE);
    }

    /// @notice Get values of all underlying yield tokens
    /// @dev this function needs to be modified if the number of tokens is changed
    /// @return values Amount of underlying tokens of yield tokens
    function getYieldTokenValues()
        public
        view
        returns (uint256[NO_OF_TOKENS] memory values)
    {
        values[0] = getYieldTokenValue(0, tokenBalances[0]);
    }

    /// @notice Get the amount of yield tokens
    /// @param _index index of desired token
    /// @param _amount amount (common denominator) that we want
    ///     to convert to yield tokens
    /// @return get amount of yield tokens from amount
    /// @dev Note that this contract assumes that the underlying decimals
    ///     of the 4626 token and its yieldtoken is the same, which
    ///     isnt guaranteed by EIP-4626. The _amount variable is denoted in the
    ///     precision of the common denominator (1E18), return value is denoted in
    ///     the yield tokens decimals
    function getYieldTokenAmount(uint256 _index, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return getYieldToken(_index).convertToShares(_amount);
    }

    /// @notice Get the value of a yield token in its underlying token
    /// @param _index index of desired token
    /// @param _amount amount of yield token that we want to convert
    /// @dev Note that this contract assumes that the underlying decimals
    ///     of the 4626 token and its yieldtoken is the same, which
    ///     isnt guaranteed by EIP-4626. The _amount variable is denoted in the
    ///     precision of the yield token, return value is denoted in the precision
    ///     of the common denominator (1E18)
    function getYieldTokenValue(uint256 _index, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return
            (getYieldToken(_index).convertToAssets(_amount) * DEFAULT_FACTOR) /
            getYieldTokenDecimals(_index);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGToken {
    function mint(
        address recipient,
        uint256 factor,
        uint256 amount
    ) external;

    function burn(
        address recipient,
        uint256 factor,
        uint256 amount
    ) external;

    function totalSupplyBase() external view returns (uint256);

    function factor() external view returns (uint256);

    function factor(uint256 amount) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";
import {Ownable} from "Ownable.sol";
import {SafeTransferLib} from "SafeTransferLib.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";
import {Constants} from "Constants.sol";
import {Errors} from "Errors.sol";
import {GTranche} from "GTranche.sol";
import {GVault} from "GVault.sol";
import {SeniorTranche} from "SeniorTranche.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title GMigration
/// @notice Responsible for migrating funds from old gro protocol to the new gro protocol
/// this contract converts stables to 3crv and then deposits into the new GVault which in turn
/// is deposited into the gTranche.
contract GMigration is Ownable, Constants {
    using SafeTransferLib for ERC20;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant THREE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address constant THREE_POOL_TOKEN =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address constant PWRD = 0xF0a93d4994B3d98Fb5e3A2F90dBc2d69073Cb86b;
    GVault immutable gVault;
    bool IsGTrancheSet;
    GTranche public gTranche;
    uint256 public seniorTrancheDollarAmount;

    constructor(GVault _gVault) {
        gVault = _gVault;
    }

    /// @notice Set address of gTranche
    /// @dev Needs to be set after deploying gTranche
    /// @param _gTranche address of gTranche
    function setGTranche(GTranche _gTranche) external onlyOwner {
        if (IsGTrancheSet) {
            revert Errors.TrancheAlreadySet();
        }
        gTranche = _gTranche;
        IsGTrancheSet = true;
    }

    /// @notice Migrates funds from old gro-protocol to new gro-protocol
    /// @dev assumes gMigration has all stables from old gro protocol
    /// @param minAmountThreeCRV minimum amount of 3crv expected from swapping all stables
    function prepareMigration(
        uint256 minAmountThreeCRV,
        uint256 minAmountShares
    ) external onlyOwner {
        if (!IsGTrancheSet) {
            revert Errors.TrancheNotSet();
        }

        // read senior tranche value before migration
        seniorTrancheDollarAmount = SeniorTranche(PWRD).totalAssets();

        uint256 DAI_BALANCE = ERC20(DAI).balanceOf(address(this));
        uint256 USDC_BALANCE = ERC20(USDC).balanceOf(address(this));
        uint256 USDT_BALANCE = ERC20(USDT).balanceOf(address(this));

        // approve three pool
        ERC20(DAI).safeApprove(THREE_POOL, DAI_BALANCE);
        ERC20(USDC).safeApprove(THREE_POOL, USDC_BALANCE);
        ERC20(USDT).safeApprove(THREE_POOL, USDT_BALANCE);

        // swap for 3crv
        ICurve3Pool(THREE_POOL).add_liquidity(
            [DAI_BALANCE, USDC_BALANCE, USDT_BALANCE],
            minAmountThreeCRV
        );

        //check 3crv amount received
        uint256 depositAmount = ERC20(THREE_POOL_TOKEN).balanceOf(
            address(this)
        );

        // approve 3crv for GVault
        ERC20(THREE_POOL_TOKEN).safeApprove(address(gVault), depositAmount);

        // deposit into GVault
        uint256 shareAmount = gVault.deposit(depositAmount, address(this));

        if (shareAmount < minAmountShares) revert Errors.InsufficientShares();
        // approve gVaultTokens for gTranche
        ERC20(address(gVault)).safeApprove(address(gTranche), shareAmount);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "GToken.sol";

/// @notice Rebasing token implementation of the GToken.
///     This contract defines the PWRD Stablecoin (pwrd) - A yield bearing stable coin used in
///     Gro protocol. The Rebasing token does not rebase in discrete events by minting new tokens,
///     but rather relies on the GToken factor to establish the amount of tokens in circulation,
///     in a continuous manner. The token supply is defined as:
///         BASE (10**18) / factor (total supply / total assets)
///     where the total supply is the number of minted tokens, and the total assets
///     is the USD value of the underlying assets used to mint the token.
///     For simplicity the underlying amount of tokens will be referred to as base, while
///     the rebased amount (base/factor) will be referred to as rebase.
contract SeniorTranche is GToken {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event LogTransfer(
        address indexed sender,
        address indexed recipient,
        uint256 indexed amount
    );

    constructor(string memory name, string memory symbol)
        GToken(name, symbol)
    {}

    /// @notice TotalSupply override - the totalsupply of the Rebasing token is
    ///     calculated by dividing the totalSupplyBase (standard ERC20 totalSupply)
    ///     by the factor. This result is the rebased amount
    function totalSupply() public view override returns (uint256) {
        uint256 f = factor();
        return f > 0 ? applyFactor(totalSupplyBase(), f, false) : 0;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 f = factor();
        return f > 0 ? applyFactor(balanceOfBase(account), f, false) : 0;
    }

    /// @notice Transfer override - Overrides the transfer method to transfer
    ///     the correct underlying base amount of tokens, but emit the rebased amount
    /// @param recipient Recipient of transfer
    /// @param amount Base amount to transfer
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 transferAmount = applyFactor(amount, factor(), true);
        super._transfer(msg.sender, recipient, transferAmount, amount);
        emit LogTransfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Price should always be 1E18
    function getPricePerShare() external view override returns (uint256) {
        return BASE;
    }

    function getShareAssets(uint256 shares)
        external
        view
        override
        returns (uint256)
    {
        return shares;
    }

    function getAssets(address account)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf(account);
    }

    /// @notice Mint RebasingGTokens
    /// @param account Target account
    /// @param _factor Factor to use for mint
    /// @param amount Mint amount in USD
    function mint(
        address account,
        uint256 _factor,
        uint256 amount
    ) external override onlyWhitelist {
        require(account != address(0), "mint: 0x");
        require(amount > 0, "Amount is zero.");
        // Apply factor to amount to get rebase amount
        uint256 mintAmount = applyFactor(amount, _factor, true);
        // uint256 mintAmount = amount.mul(_factor).div(BASE);
        _mint(account, mintAmount, amount);
    }

    /// @notice Burn RebasingGTokens
    /// @param account Target account
    /// @param _factor Factor to use for mint
    /// @param amount Burn amount in USD
    function burn(
        address account,
        uint256 _factor,
        uint256 amount
    ) external override onlyWhitelist {
        require(account != address(0), "burn: 0x");
        require(amount > 0, "Amount is zero.");
        // Apply factor to amount to get rebase amount
        uint256 burnAmount = applyFactor(amount, _factor, true);
        // uint256 burnAmount = amount.mul(_factor).div(BASE);
        _burn(account, burnAmount, amount);
    }

    /// @notice Burn all pwrds for account - used by withdraw all methods
    /// @param account Target account
    function burnAll(address account) external override onlyWhitelist {
        require(account != address(0), "burnAll: 0x");
        uint256 burnAmount = balanceOfBase(account);
        uint256 amount = applyFactor(burnAmount, factor(), false);
        // uint256 amount = burnAmount.mul(BASE).div(factor());
        // Apply factor to amount to get rebase amount
        _burn(account, burnAmount, amount);
    }

    /// @notice transferFrom override - Overrides the transferFrom method
    ///     to transfer the correct amount of underlying tokens (Base amount)
    ///     but emit the rebased amount
    /// @param sender Sender of transfer
    /// @param recipient Reciepient of transfer
    /// @param amount Mint amount in USD
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        super._decreaseApproved(sender, msg.sender, amount);
        uint256 transferAmount = applyFactor(amount, factor(), true);
        // amount.mul(factor()).div(BASE)
        super._transfer(sender, recipient, transferAmount, amount);
        return true;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "Context.sol";
import "Address.sol";
import "IERC20.sol";
import "Ownable.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "Constants.sol";
import "Whitelist.sol";
import "IERC20Detailed.sol";

abstract contract GERC20 is Context, IERC20 {
    using Address for address;
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupplyBase() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOfBase(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
        _transfer(sender, recipient, amount, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *      GERC20 addition - transferAmount added to take rebased amount into account
     * This is internal function is equivalent to {transfer}, and can be used to
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
        uint256 transferAmount,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, transferAmount);

        _balances[sender] = _balances[sender].sub(
            transferAmount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(transferAmount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *      GERC20 addition - mintAmount added to take rebased amount into account
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 mintAmount,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, mintAmount);

        _totalSupply = _totalSupply.add(mintAmount);
        _balances[account] = _balances[account].add(mintAmount);
        emit Transfer(address(0), account, amount);
    }

    event LogTestGToken(uint256 _burnAmount, uint256 _balance);

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *      GERC20 addition - burnAmount added to take rebased amount into account
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 burnAmount,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), burnAmount);
        emit LogTestGToken(burnAmount, _balances[account]);

        _balances[account] = _balances[account].sub(
            burnAmount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(burnAmount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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

    function _decreaseApproved(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = _allowances[owner][spender] - (amount);
        emit Approval(owner, spender, _allowances[owner][spender]);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}

interface IController {
    function stablecoins() external view returns (address[3] memory);

    function vaults() external view returns (address[3] memory);

    function underlyingVaults(uint256 i) external view returns (address vault);

    function curveVault() external view returns (address);

    function pnl() external view returns (address);

    function insurance() external view returns (address);

    function lifeGuard() external view returns (address);

    function buoy() external view returns (address);

    function reward() external view returns (address);

    function isValidBigFish(
        bool pwrd,
        bool deposit,
        uint256 amount
    ) external view returns (bool);

    function withdrawHandler() external view returns (address);

    function emergencyHandler() external view returns (address);

    function depositHandler() external view returns (address);

    function totalAssets() external view returns (uint256);

    function gTokenTotalAssets() external view returns (uint256);

    function eoaOnly(address sender) external;

    function getSkimPercent() external view returns (uint256);

    function gToken(bool _pwrd) external view returns (address);

    function emergencyState() external view returns (bool);

    function deadCoin() external view returns (uint256);

    function distributeStrategyGainLoss(uint256 gain, uint256 loss) external;

    function burnGToken(
        bool pwrd,
        bool all,
        address account,
        uint256 amount,
        uint256 bonus
    ) external;

    function mintGToken(
        bool pwrd,
        address account,
        uint256 amount
    ) external;

    function getUserAssets(bool pwrd, address account)
        external
        view
        returns (uint256 deductUsd);

    function referrals(address account) external view returns (address);

    function addReferral(address account, address referral) external;

    function getStrategiesTargetRatio()
        external
        view
        returns (uint256[] memory);

    function withdrawalFee(bool pwrd) external view returns (uint256);

    function validGTokenDecrease(uint256 amount) external view returns (bool);
}

interface IToken {
    function factor() external view returns (uint256);

    function factor(uint256 totalAssets) external view returns (uint256);

    function mint(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burn(
        address account,
        uint256 _factor,
        uint256 amount
    ) external;

    function burnAll(address account) external;

    function totalAssets() external view returns (uint256);

    function getPricePerShare() external view returns (uint256);

    function getShareAssets(uint256 shares) external view returns (uint256);

    function getAssets(address account) external view returns (uint256);
}

/// @notice Base contract for gro protocol tokens - The Gro token specifies some additional functionality
///     shared by both tokens (Rebasing, NonRebasing).
///     - Factor:
///         The GToken factor. The two tokens are associated with a factor that controls their price (NonRebasing),
///         or their amount (Rebasing). The factor is defined by the totalSupply / total assets lock in token.
///     - Base:
///         The base amount of minted tokens, this affects the Rebasing token as the totalSupply is defined by:
///         BASE amount / factor
///     - Total assets:
///         Total assets is the dollarvalue of the underlying assets used to mint Gtokens. The Gtoken
///         depends on an external contract (Controller.sol) to get this value (retrieved from PnL calculations)
abstract contract GToken is GERC20, Constants, Whitelist, IToken {
    uint256 public constant BASE = DEFAULT_DECIMALS_FACTOR;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IController public ctrl;

    constructor(string memory name, string memory symbol)
        GERC20(name, symbol, DEFAULT_DECIMALS)
    {}

    function setController(address controller) external onlyOwner {
        ctrl = IController(controller);
    }

    function factor() public view override returns (uint256) {
        return factor(totalAssets());
    }

    function applyFactor(
        uint256 a,
        uint256 b,
        bool base
    ) internal pure returns (uint256 resultant) {
        uint256 _BASE = BASE;
        uint256 diff;
        if (base) {
            diff = a.mul(b) % _BASE;
            resultant = a.mul(b).div(_BASE);
        } else {
            diff = a.mul(_BASE) % b;
            resultant = a.mul(_BASE).div(b);
        }
        if (diff >= 5E17) {
            resultant = resultant.add(1);
        }
    }

    function factor(uint256 _totalAssets)
        public
        view
        override
        returns (uint256)
    {
        if (totalSupplyBase() == 0) {
            return getInitialBase();
        }

        if (_totalAssets > 0) {
            return totalSupplyBase().mul(BASE).div(_totalAssets);
        }

        // This case is totalSupply > 0 && totalAssets == 0, and only occurs on system loss
        return 0;
    }

    function totalAssets() public view override returns (uint256) {
        return ctrl.gTokenTotalAssets();
    }

    function getInitialBase() internal pure virtual returns (uint256) {
        return BASE;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {Ownable} from "Ownable.sol";
import {Errors} from "Errors.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event LogAddToWhitelist(address indexed user);
    event LogRemoveFromWhitelist(address indexed user);

    modifier onlyWhitelist() {
        if (!whitelist[msg.sender]) {
            revert Errors.NotInWhitelist();
        }
        _;
    }

    function addToWhitelist(address user) external onlyOwner {
        if (user == address(0)) {
            revert Errors.ZeroAddress();
        }
        whitelist[user] = true;
        emit LogAddToWhitelist(user);
    }

    function removeFromWhitelist(address user) external onlyOwner {
        if (user == address(0)) {
            revert Errors.ZeroAddress();
        }
        whitelist[user] = false;
        emit LogRemoveFromWhitelist(user);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IERC20Detailed {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}