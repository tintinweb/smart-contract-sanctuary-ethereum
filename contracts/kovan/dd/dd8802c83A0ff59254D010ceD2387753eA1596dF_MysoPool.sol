import {MysoToken} from "./MysoToken.sol";
import {BMath} from "./libraries/BMath.sol";
import {IMysoPool} from "./interfaces/IMysoPool.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MysoPool is MysoToken, BMath, IMysoPool, Initializable{

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    event swappedCollForBorrCcyAndCall(
        address indexed caller,
        uint256 indexed tokenId,
        uint256 indexed exercisePrice,
        uint256         borrAmount
    );

    event exercisedCall(
        uint256 indexed exerciseAmount,
        uint256 indexed callTokenId,
        uint256         convertedCcyAmount
    );

    event settledCall(
        address indexed caller,
        uint256 indexed referralCode,
        uint256         settledCcyAmount
    );

    event addedLiquidity(
        address indexed caller,
        uint256 indexed lpShares,
        uint256         collCcyAmount,
        uint256         borrCcyAmount
    );

    event removedLiquidity(
        address indexed caller,
        uint256 indexed lpShares,
        uint256         collCcyAmount,
        uint256         borrCcyAmount
    );

    address deployer;
    address public factory;
    address collToken;
    address borrToken;
    uint256 poolExpiry;
    uint256 callOptionTenor;
    uint256 fee;
    uint256 r0;
    uint256 r1;
    address interestRateModelAddress;

    constructor() {
        deployer = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _collToken,
        address _borrToken,
        uint256 _poolExpiry,
        uint256 _callOptionTenor,
        uint256 _fee,
        DataTypes.InterestRateModelConfig calldata interestRateModelConfig) external override initializer {
        //require(factory == address(0), 'MYSOPool: FORBIDDEN'); // checks not called yet
        factory = msg.sender;
        collToken = _collToken;
        borrToken = _borrToken;
        poolExpiry = _poolExpiry;
        callOptionTenor = _callOptionTenor;
        fee = _fee;
        r0 = interestRateModelConfig.r0;
        r1 = interestRateModelConfig.r1;
        interestRateModelAddress = interestRateModelConfig.interestRateModelAddress;
    }

    /**
     * @notice Function to change interest model address
     * @dev caller must be pool admin from factory
     * @param newAddress The new address for interest rate model parameters
     */

    function setIntRateModelAddr(
        address newAddress
        ) external {
            (bool success, bytes memory data) = factory.call(abi.encodeWithSelector(bytes4(keccak256("poolAdmin()"))));
            require(success, "MYSOPool : UNSUCCESSFUL_CALL");
            address possibleAdmin = abi.decode(data, (address));
            require(possibleAdmin == msg.sender, "MYSOPool : INVALID_SENDER");
            interestRateModelAddress = newAddress;
    }

    function swapCollForBorrCcyAndCall(
        uint256 collAmount,
        uint256 minBorrAmount,
        uint256 maxRepayAmount,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256, uint256){
        return (0,0);
    }

    function swapBorrCcyForCall(
        uint256 borrAmount,
        uint256 minCollAmount,
        uint256 maxExercisePrice,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256, uint256){
        return (0,0);
    }

    function exerciseCall(
        uint256 exerciseAmount,
        uint256 callTokenId,
        uint256 referralCode
    ) external returns (uint256){
        return 0;
    }

    function settleUnexercisedCall(uint256 callTokenId, uint256 referralCode)
        external
        returns (uint256){
            return 0;
        }

    function addLiquidity(
        uint256 collTokenAmount,
        uint256 maxBorrTokenAmount,
        uint256 minLpShares,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256){
        return 0;
    }

    function removeLiquidity(
        uint256 lpShares,
        uint256 minCollTokenAmount,
        uint256 minBorrTokenAmount,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256){
        return 0;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {IMysoERC20} from "./interfaces/IMysoERC20.sol";
import {BNum} from "./libraries/BNum.sol";

abstract contract MysoToken is IMysoERC20, BNum {
    string public constant name = 'Myso-LP';
    string public constant symbol = 'MYSO-LP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    constructor() {
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(balanceOf[from] >= value, "MYSOERC20: INSUFFICIENT_BAL");
        balanceOf[from] = bsub(balanceOf[from], value);
        balanceOf[to] = badd(balanceOf[to], value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(msg.sender == from || value <= allowance[from][msg.sender], "MYSOERC20: BAD_CALLER");
        if (msg.sender != from && allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = bsub(allowance[from][msg.sender], value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'MYSOERC20: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'MYSOERC20: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.11;

import "./BNum.sol";

contract BMath is BConst, BNum {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) public pure returns (uint256 spotPrice) {
        uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint256 ratio = bdiv(numer, denom);
        uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
        return (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) public pure returns (uint256 tokenAmountOut) {
        uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint256 adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint256 foo = bpow(y, weightRatio);
        uint256 bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IMysoPool {
    /**
     * @notice Function to initialize a new pool
     * @dev Uses factory design pattern to create clones of base implementation
     * @param collToken The collateral ccy token address
     * @param borrToken The borrow ccy token address
     * @param poolExpiry The pool's expiry
     * @param callOptionTenor The tenor of the options to be minted
     * @param fee The protocol fee
     * @param interestRateModelConfig The interest rate model to be used
     **/
    function initialize(
        address collToken,
        address borrToken,
        uint256 poolExpiry,
        uint256 callOptionTenor,
        uint256 fee,
        DataTypes.InterestRateModelConfig calldata interestRateModelConfig
    ) external;

    /**
     * @notice Function to let borrowers take out zero-liquidation loan
     * @dev Allows users to swap collateral for borrow ccy and calls,
     *   e.g., user pledges 1 ETH and borrows 2000 USDC and ETH call with
     *   strike 2100 USDC
     * @param collAmount The collateral amount the user is willing to pledge
     * @param minBorrAmount The min. amount the user wants to receive for his
     *   pledged collateral (comparable to a limit order); if the AMM can't
     *   provide minBorrAmount the borrow TX shall fail
     * @param maxRepayAmount The max. amount the user is willing to repay to
     *   reclaim his collateral (comparable to a limit order); if the AMM can't
     *   provide for this the borrow TX shall fail
     * @param deadline The max. time the user is willing to wait and let swap
     *   be pending
     * @param referralCode Code used to identify 3rd party integrations and
     *   referrals (for potential future rewards)
     * @return The final borrwed amount and call option token ID
     **/
    function swapCollForBorrCcyAndCall(
        uint256 collAmount,
        uint256 minBorrAmount,
        uint256 maxRepayAmount,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256, uint256);

    /**
     * @notice Function to let users buy call option for borrow ccy
     * @dev Allows users to swap borrow ccy for call option, e.g., user
     * - gives 2000 USDC for ETH call with strike 2100 USDC
     * @param borrAmount The borrow ccy amount the user is willing to give
     * @param minCollAmount The min. collateral amount the user expects to be
     *   reserved to cover his call option (this is equal to the min. number of
     *   call options the user expects to receive at least)
     * @param maxExercisePrice The max. exercise price the user would accept
     *   for his call options (= minCollAmount x strike price per call option)
     * @param deadline The max. time the user is willing to wait and let swap
     *   be pending
     * @param referralCode Code used to register the integrator originating
     *   the operation, for potential rewards.
     * @return The final reserved call amount and call option token ID
     **/
    function swapBorrCcyForCall(
        uint256 borrAmount,
        uint256 minCollAmount,
        uint256 maxExercisePrice,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256, uint256);

    /**
     * @notice Function to let users exercise their call options
     * @dev Allows users to exercise their call options
     * - E.g. User borrows 2000 USDC for 1 ETH
     * @param exerciseAmount The amount of borrow ccy the user wants to
     *   exercise and convert into collateral ccy according to the exercise
     *   price he locked in with his call option
     * @param callTokenId The ERC1155 token id of the call option the user
     *   wants to exercise
     * @param referralCode Code used to register the integrator originating
     *   the operation, for potential rewards.
     * @return The final converted collateral ccy amount
     **/
    function exerciseCall(
        uint256 exerciseAmount,
        uint256 callTokenId,
        uint256 referralCode
    ) external returns (uint256);

    /**
     * @notice Function to let users settle unexercised call options
     * @dev Allows users to settle unexercised call options
     * @param callTokenId The ERC1155 token id of the call option the user
     *   wants to exercise
     * @param referralCode Code used to register the integrator originating
     *   the operation, for potential rewards.
     * @return The final settled collateral ccy amount
     **/
    function settleUnexercisedCall(uint256 callTokenId, uint256 referralCode)
        external
        returns (uint256);

    /**
     * @notice Function to let LPs add liquidity to pool and receive LP shares
     * @dev Allows users to add liquidity to a pool and mint LP shares
     * @param collTokenAmount The amount of collateral ccy the user wants to
     *   add to the pool
     * @param maxBorrTokenAmount The max. amount of borrow ccy the user is
     *   willing to add to pool to maintain constant ratio
     * @param deadline The max. time the user is willing to wait and let Tx be
     *   pending
     * @param minLpShares The min. amount of LP shares the user wants to
     *   receive
     * @param deadline The max. time the user is willing to wait and let Tx
     *   be pending
     * @param referralCode Code used to register the integrator originating
     *   the operation, for potential rewards.
     * @return The final LP shares minted
     **/
    function addLiquidity(
        uint256 collTokenAmount,
        uint256 maxBorrTokenAmount,
        uint256 minLpShares,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256);

    /**
     * @notice Function to let LPs remove liquidity from pool and receive pro
     *   rata share of pool balances
     * @dev Allows users to remove liquidity, receive pro rata share of pool
     *   balances and burn LP shares
     * @param lpShares The amount of LP shares the user wants to redeem
     * @param minCollTokenAmount The min. amount of collateral ccy the user
     *   wants to receive
     * @param minBorrTokenAmount The min. amount of borrow ccy the user
     *   wants to receive
     * @param deadline The max. time the user is willing to wait and let Tx
     *   be pending
     * @param referralCode Code used to register the integrator originating
     *   the operation, for potential rewards.
     * @return The final LP shares minted
     **/
    function removeLiquidity(
        uint256 lpShares,
        uint256 minCollTokenAmount,
        uint256 minBorrTokenAmount,
        uint256 deadline,
        uint256 referralCode
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library DataTypes {
    struct InterestRateModelConfig {
        //R_0 intercept parameter
        uint256 r0;
        //R_1 slope parameter
        uint256 r1;
        //address of interest rate model
        address interestRateModelAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
* @dev this is an ERC20Permit interface with PERMIT_TYPEHASH included as well
**/

interface IMysoERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.11;

import "./BConst.sol";

contract BNum is BConst {
    function btoi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function bfloor(uint256 a) internal pure returns (uint256) {
        return btoi(a) * BONE;
    }

    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint256 whole = bfloor(exp);
        uint256 remain = bsub(exp, whole);

        uint256 wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = bsubSign(base, BONE);
        uint256 term = BONE;
        uint256 sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.11;

contract BConst {
    uint256 public constant BONE = 10**18;

    uint256 public constant MIN_BOUND_TOKENS = 2;
    uint256 public constant MAX_BOUND_TOKENS = 8;

    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    uint256 public constant EXIT_FEE = 0;

    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**12;

    uint256 public constant INIT_POOL_SUPPLY = BONE * 100;

    uint256 public constant MIN_BPOW_BASE = 1 wei;
    uint256 public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant BPOW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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