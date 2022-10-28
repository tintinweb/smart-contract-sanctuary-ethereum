// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ReentrancyGuard.sol";

uint128 constant N_COINS = 3; // <- change

interface ERC20 {
    function transfer(address _to, uint256 _amount) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function balanceOf(address _user) external view returns (uint256);
}

interface CurveToken {
    function totalSupply() external view returns (uint256);

    function mint(address _to, uint256 _value) external returns (bool);

    function mint_relative(address _to, uint256 frac)
        external
        returns (uint256);

    function burnFrom(address _to, uint256 _value) external returns (bool);
}

interface Math {
    function geometric_mean(uint256[N_COINS] memory unsorted_x)
        external
        view
        returns (uint256);

    function reduction_coefficient(uint256[N_COINS] memory x, uint256 fee_gamma)
        external
        view
        returns (uint256);

    function newton_D(
        uint256 ANN,
        uint256 gamma,
        uint256[N_COINS] memory x_unsorted
    ) external view returns (uint256);

    function newton_y(
        uint256 ANN,
        uint256 gamma,
        uint256[N_COINS] memory x,
        uint256 D,
        uint256 i
    ) external view returns (uint256);

    function halfpow(uint256 power, uint256 precision)
        external
        view
        returns (uint256);

    function sqrt_int(uint256 x) external view returns (uint256);
}

interface Views {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[N_COINS] memory amounts, bool deposit)
        external
        view
        returns (uint256);
}

interface WETH {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}

contract CurveCryptoSwap is ReentrancyGuard {
    uint256 constant PRECISION = 10**18; // The precision to convert to
    uint256 constant A_MULTIPLIER = 10000;

    //These addresses are replaced by the deployer
    address math = 0x0000000000000000000000000000000000000000;
    address public token = 0x0000000000000000000000000000000000000001;
    address views = 0x0000000000000000000000000000000000000002;
    address[N_COINS] public coins = [
        0x0000000000000000000000000000000000000010,
        0x0000000000000000000000000000000000000011,
        0x0000000000000000000000000000000000000012
    ];

    uint256 price_scale_packed; //Internal price scale
    uint256 price_oracle_packed; //Price target given by MA

    uint256 last_prices_packed;
    uint256 public last_prices_timestamp;

    uint256 public initial_A_gamma;
    uint256 public future_A_gamma;
    uint256 public initial_A_gamma_time;
    uint256 public future_A_gamma_time;

    uint256 public allowed_extra_profit; //2 * 10**12 - recommended value
    uint256 public future_allowed_extra_profit;

    uint256 public fee_gamma;
    uint256 public future_fee_gamma;

    uint256 public adjustment_step;
    uint256 public future_adjustment_step;

    uint256 public ma_half_time;
    uint256 public future_ma_half_time;

    uint256 public mid_fee;
    uint256 public out_fee;
    uint256 public admin_fee;
    uint256 public future_mid_fee;
    uint256 public future_out_fee;
    uint256 public future_admin_fee;

    uint256[N_COINS] public balances;
    uint256 public D;

    address public owner;
    address public future_owner;

    uint256 public xcp_profit;
    uint256 public xcp_profit_a;
    uint256 public virtual_price;
    bool not_adjusted;

    bool public is_killed;
    uint256 public kill_deadline;
    uint256 public transfer_ownership_deadline;
    uint256 public admin_actions_deadline;

    address public admin_fee_receiver;

    uint256 constant KILL_DEADLINE_DT = 2 * 30 * 86400;
    uint256 constant ADMIN_ACTIONS_DELAY = 3 * 86400;
    uint256 constant MIN_RAMP_TIME = 86400;

    uint256 constant MAX_ADMIN_FEE = 10 * 10**9;
    uint256 constant MIN_FEE = 5 * 10**5;
    uint256 constant MAX_FEE = 10 * 10**9;
    // uint256 constant MIN_A = (N_COINS**N_COINS * A_MULTIPLIER) / 100;
    uint256 constant MAX_A = 10000 * A_MULTIPLIER * N_COINS**N_COINS; // different
    uint256 constant MAX_A_CHANGE = 10;
    uint256 constant MIN_GAMMA = 10**10;
    uint256 constant MAX_GAMMA = 10**16; // different
    uint256 constant NOISE_FEE = 10**5; //0.1 BPS

    uint256 constant PRICE_SIZE = 256 / (N_COINS - 1);
    uint256 constant PRICE_MASK = 2**PRICE_SIZE - 1;

    /*
     * This must be changed for different N_COINS
     * For example
     * N_COINS = 3 -> 1  (10**18 -> 10**18)
     * N_COINS = 4 -> 10**8  (10**18 -> 10**10)
     * PRICE_PRECISION_MUL: constant(uint256) = 1
     */
    // uint256[N_COINS] public PRECISIONS = [1000000000000, 10000000000, 1];
    uint256[N_COINS] public PRECISIONS = [1, 1, 1];

    uint256 constant INF_COINS = 15;

    event TokenExchange(
        address indexed buyer,
        uint256 sold_id,
        uint256 tokens_sold,
        uint256 bought_id,
        uint256 tokens_bought
    );

    event AddLiquidity(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256 fee,
        uint256 token_supply
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256[N_COINS] token_amounts,
        uint256 token_supply
    );

    event RemoveLiquidityOne(
        address indexed provider,
        uint256 token_amount,
        uint256 coin_index,
        uint256 coin_amount
    );

    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);

    event NewAdmin(address indexed admin);

    event CommitNewParameters(
        uint256 indexed deadline,
        uint256 admin_fee,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 fee_gamma,
        uint256 allowed_extra_profit,
        uint256 adjustment_step,
        uint256 ma_half_time
    );

    event NewParameters(
        uint256 admin_fee,
        uint256 mid_fee,
        uint256 out_fee,
        uint256 fee_gamma,
        uint256 allowed_extra_profit,
        uint256 adjustment_step,
        uint256 ma_half_time
    );

    event RampAgamma(
        uint256 initial_A,
        uint256 future_A,
        uint256 initial_gamma,
        uint256 future_gamma,
        uint256 initial_time,
        uint256 future_time
    );

    event StopRampA(uint256 current_A, uint256 current_gamma, uint256 time);

    event ClaimAdminFee(address indexed admin, uint256 tokens);

    struct ConstructorParams {
        address owner;
        address admin_fee_receiver;
        uint256 _A;
        uint256 _gamma;
        uint256 _mid_fee;
        uint256 _out_fee;
    }

    constructor(
        ConstructorParams memory constructorParams,
        uint256 _allowed_extra_profit,
        uint256 _fee_gamma,
        uint256 _adjustment_step,
        uint256 _admin_fee,
        uint256 _ma_half_time,
        uint256[N_COINS - 1] memory _initial_prices,
        address _math,
        address _token,
        address _views,
        address[N_COINS] memory _coins
    ) {
        owner = constructorParams.owner;

        //Pack A and gamma:
        //shifted A + gamma
        uint256 A_gamma = constructorParams._A << 128;
        A_gamma = A_gamma | constructorParams._gamma;
        initial_A_gamma = A_gamma;
        future_A_gamma = A_gamma;

        mid_fee = constructorParams._mid_fee;
        out_fee = constructorParams._out_fee;
        allowed_extra_profit = _allowed_extra_profit;
        fee_gamma = _fee_gamma;
        adjustment_step = _adjustment_step;
        admin_fee = _admin_fee;

        //Packing prices
        uint256 packed_prices = 0;
        for (uint128 k; k < N_COINS - 1; k++) {
            // packed_prices <<= PRICE_SIZE;
            packed_prices = packed_prices << PRICE_SIZE;
            uint256 p = _initial_prices[N_COINS - 2 - k]; // / PRICE_PRECISION_MUL
            assert(p < PRICE_MASK);
            packed_prices = p | packed_prices;
        }

        price_scale_packed = packed_prices;
        price_oracle_packed = packed_prices;
        last_prices_packed = packed_prices;
        last_prices_timestamp = block.timestamp;
        ma_half_time = _ma_half_time;

        xcp_profit_a = 10**18;

        kill_deadline = block.timestamp + KILL_DEADLINE_DT;

        admin_fee_receiver = constructorParams.admin_fee_receiver;

        coins = _coins;
        math = _math;
        token = _token;
        views = _views;
    }

    // fallback

    function _packed_view(uint256 k, uint256 p)
        internal
        view
        returns (uint256)
    {
        require(k < N_COINS - 1);
        return (p >> (PRICE_SIZE * k)) & PRICE_MASK; // * PRICE_PRECISION_MUL
    }

    function xp() internal view returns (uint256[N_COINS] memory) {
        uint256[N_COINS] memory result = balances;
        uint256 packed_prices = price_scale_packed;

        uint256[N_COINS] memory precisions = PRECISIONS;

        result[0] *= PRECISIONS[0];
        for (uint256 i = 1; i < N_COINS; i++) {
            uint256 p = (packed_prices & PRICE_MASK) * precisions[i]; // * PRICE_PRECISION_MUL
            result[i] = (result[i] * p) / PRECISION;
            packed_prices = packed_prices >> PRICE_SIZE;
        }

        return result;
    }

    function _A_gamma() internal view returns (uint256[2] memory) {
        uint256 t1 = future_A_gamma_time;

        uint256 A_gamma_1 = future_A_gamma;
        uint256 gamma1 = A_gamma_1 & (2**128 - 1);
        uint256 A1 = A_gamma_1 >> 128;

        if (block.timestamp < t1) {
            //handle ramping up and down of A
            uint256 A_gamma_0 = initial_A_gamma;
            uint256 t0 = initial_A_gamma_time;

            //Less readable but more compact way of writing and converting to uint256
            // uint256 gamma0 = A_gamma_0 & 2**128-1;
            // uint256 A0 = A_gamma_0 >> 128;
            // A1 = A0 + (A1 - A0) * (block.timestamp - t0) / (t1 - t0);
            // gamma1 = gamma0 + (gamma1 - gamma0) * (block.timestamp - t0) / (t1 - t0);

            t1 -= t0;
            t0 = block.timestamp - t0;
            uint256 t2 = t1 - t0;

            A1 = ((A_gamma_0 >> 128) * t2 + A1 * t0) / t1;
            gamma1 = ((A_gamma_0 & (2**128 - 1)) * t2 + gamma1 * t0) / t1;
        }

        return [A1, gamma1];
    }

    function A() external view returns (uint256) {
        return _A_gamma()[0];
    }

    function gamma() external view returns (uint256) {
        return _A_gamma()[1];
    }

    function _fee(uint256[N_COINS] memory _xp) internal view returns (uint256) {
        uint256 f = Math(math).reduction_coefficient(_xp, fee_gamma);
        return (mid_fee * f + out_fee * (10**18 - f)) / 10**18;
    }

    function fee() external view returns (uint256) {
        return _fee(xp());
    }

    function fee_calc(uint256[N_COINS] memory _xp)
        external
        view
        returns (uint256)
    {
        return _fee(_xp);
    }

    function get_xcp(uint256 _D) internal view returns (uint256) {
        uint256[N_COINS] memory x;
        x[0] = _D / N_COINS;
        uint256 packed_prices = price_scale_packed;
        //No precisions here because we don't switch to "real" units

        for (uint256 i = 1; i < N_COINS; i++) {
            x[i] = (_D * 10**18) / (N_COINS * (packed_prices & PRICE_MASK)); // ... * PRICE_PRECISION_MUL)
            packed_prices >>= PRICE_SIZE;
        }

        return Math(math).geometric_mean(x);
    }

    function get_virtual_price() external view returns (uint256) {
        return (10**18 * get_xcp(D)) / CurveToken(token).totalSupply();
    }

    function _claim_admin_fees() internal {
        uint256[2] memory A_gamma = _A_gamma();

        uint256 _xcp_profit = xcp_profit;
        uint256 _xcp_profit_a = xcp_profit_a;

        // Gulp here
        for (uint256 i; i < N_COINS; i++) {
            balances[i] = ERC20(coins[i]).balanceOf(address(this));
        }

        uint256 vprice = virtual_price;

        if (_xcp_profit > _xcp_profit_a) {
            uint256 fees = ((_xcp_profit - _xcp_profit_a) * admin_fee) /
                (2 * 10**10);
            if (fees > 0 && admin_fee_receiver != address(0)) {
                address receiver = admin_fee_receiver;
                uint256 frac = (vprice * 10**18) / (vprice - fees) - 10**18;
                uint256 claimed = CurveToken(token).mint_relative(
                    receiver,
                    frac
                );
                _xcp_profit -= fees * 2;
                xcp_profit = _xcp_profit;
                emit ClaimAdminFee(receiver, claimed);
            }
        }

        uint256 total_supply = CurveToken(token).totalSupply();

        //Recalculate D b/c/ we gulped
        D = Math(math).newton_D(A_gamma[0], A_gamma[1], xp());

        virtual_price = (10**18 * get_xcp(D)) / total_supply;

        if (_xcp_profit > _xcp_profit_a) {
            xcp_profit_a = _xcp_profit;
        }
    }

    struct TweakPriceLocalVar {
        uint256[N_COINS - 1] price_oracle;
        uint256[N_COINS - 1] last_prices;
        uint256[N_COINS - 1] price_scale;
        uint256[N_COINS] xp;
        uint256[N_COINS - 1] p_new;
        uint256 packed_prices;
        uint256 _last_prices_timestamp;
        uint256 _ma_half_time;
        uint256 alpha;
        uint256 D_unadjusted;
        uint256[N_COINS] __xp;
        uint256 dx_price;
        uint256 p;
        uint256 total_supply;
        uint256 old_xcp_profit;
        uint256 old_virtual_price;
    }

    function tweak_price(
        uint256[2] memory A_gamma,
        uint256[N_COINS] memory _xp,
        uint256 i,
        uint256 p_i,
        uint256 new_D
    ) internal {
        TweakPriceLocalVar memory localVar;

        //Update MA if needed
        localVar.packed_prices = price_oracle_packed;
        for (uint256 k; k < N_COINS - 1; k++) {
            localVar.price_oracle[k] = localVar.packed_prices & PRICE_MASK; // * PRICE_PRECISION_MUL
            localVar.packed_prices >>= PRICE_SIZE;
        }

        localVar._last_prices_timestamp = last_prices_timestamp;
        localVar.packed_prices = last_prices_packed;
        for (uint256 k; k < N_COINS - 1; k++) {
            localVar.last_prices[k] = localVar.packed_prices & PRICE_MASK; // * PRICE_PRECISION_MUL
            localVar.packed_prices >>= PRICE_SIZE;
        }

        if (localVar._last_prices_timestamp < block.timestamp) {
            //MA update required
            localVar._ma_half_time = ma_half_time;
            localVar.alpha = Math(math).halfpow(
                ((block.timestamp - localVar._last_prices_timestamp) * 10**18) /
                    localVar._ma_half_time,
                10**10
            );
            localVar.packed_prices = 0;
            for (uint256 k; k < N_COINS - 1; k++) {
                localVar.price_oracle[k] =
                    (localVar.last_prices[k] *
                        (10**18 - localVar.alpha) +
                        localVar.price_oracle[k] *
                        localVar.alpha) /
                    10**18;
            }
            for (uint256 k; k < N_COINS - 1; k++) {
                localVar.packed_prices <<= PRICE_SIZE;
                localVar.p = localVar.price_oracle[N_COINS - 2 - k]; // /PRICE_PRECISION_MUL
                assert(localVar.p < PRICE_MASK);
                localVar.packed_prices = localVar.p | localVar.packed_prices;
            }
            price_oracle_packed = localVar.packed_prices;
            last_prices_timestamp = block.timestamp;
        }

        localVar.D_unadjusted = new_D; // Withdrawal methods know new D already
        if (new_D == 0) {
            //We will need this a few times (35k gas)
            localVar.D_unadjusted = Math(math).newton_D(
                A_gamma[0],
                A_gamma[1],
                _xp
            );
        }
        localVar.packed_prices = price_scale_packed;
        for (uint256 k; k < N_COINS - 1; k++) {
            localVar.price_scale[k] = localVar.packed_prices & PRICE_MASK; // * PRICE_PRECISION_MUL
            localVar.packed_prices >>= PRICE_SIZE;
        }

        if (p_i > 0) {
            //Save the last price
            if (i > 0) {
                localVar.last_prices[i - 1] = p_i;
            } else {
                //If 0th price cahnged - change all prices instead
                for (uint256 k; k < N_COINS - 1; k++) {
                    localVar.last_prices[k] =
                        (localVar.last_prices[k] * 10**18) /
                        p_i;
                }
            }
        } else {
            //calculate real prices
            //it would cost 70k gas for a 3-token pool. Sad. How do we do better?
            localVar.__xp = _xp;
            localVar.dx_price = localVar.__xp[0] / 10**6;
            localVar.__xp[0] += localVar.dx_price;
            for (uint256 k; k < N_COINS - 1; k++) {
                localVar.last_prices[k] =
                    (localVar.price_scale[k] * localVar.dx_price) /
                    (_xp[k + 1] -
                        Math(math).newton_y(
                            A_gamma[0],
                            A_gamma[1],
                            localVar.__xp,
                            localVar.D_unadjusted,
                            k + 1
                        ));
            }
        }

        localVar.packed_prices = 0;
        for (uint256 k; k < N_COINS - 1; k++) {
            localVar.packed_prices <<= PRICE_SIZE;
            localVar.p = localVar.last_prices[N_COINS - 2 - k]; // / PRICE_PRECISION_MUL
            assert(localVar.p < PRICE_MASK);
            localVar.packed_prices = localVar.p | localVar.packed_prices;
        }
        last_prices_packed = localVar.packed_prices;

        localVar.total_supply = CurveToken(token).totalSupply();
        localVar.old_xcp_profit = xcp_profit;
        localVar.old_virtual_price = virtual_price;

        //Update profit numbers without price adjustment first
        localVar.xp[0] = localVar.D_unadjusted / N_COINS;
        for (uint256 k; k < N_COINS - 1; k++) {
            localVar.xp[k + 1] =
                (localVar.D_unadjusted * 10**18) /
                (N_COINS * localVar.price_scale[k]);
        }
        uint256 _xcp_profit = 10**18;
        uint256 _virtual_price = 10**18;

        if (localVar.old_virtual_price > 0) {
            uint256 xcp = Math(math).geometric_mean(localVar.xp);
            _virtual_price = (10**18 * xcp) / localVar.total_supply;
            _xcp_profit =
                (localVar.old_xcp_profit * _virtual_price) /
                localVar.old_virtual_price;

            uint256 t = future_A_gamma_time;
            if (_virtual_price < localVar.old_virtual_price && t == 0) {
                revert("Loss");
            }
            if (t == 1) {
                future_A_gamma_time = 0;
            }
        }

        xcp_profit = _xcp_profit;

        bool needs_adjustment = not_adjusted;
        // if not needs_adjustment and (virtual_price-10**18 > (xcp_profit-10**18)/2 + allowed_extra_profit):
        //(re-arrange for gas efficiency)

        if (
            !needs_adjustment &&
            (_virtual_price * 2 - 10**18 >
                xcp_profit + 2 * allowed_extra_profit)
        ) {
            needs_adjustment = true;
            not_adjusted = true;
        }

        if (needs_adjustment) {
            uint256 norm = 0;

            for (uint256 k; k < N_COINS - 1; k++) {
                uint256 ratio = (localVar.price_oracle[k] * 10**18) /
                    localVar.price_scale[k];
                if (ratio > 10**18) {
                    ratio -= 10**18;
                } else {
                    ratio = 10**18 - ratio;
                }
                norm += ratio**2;
            }

            if (norm > adjustment_step**2 && localVar.old_virtual_price > 0) {
                norm = Math(math).sqrt_int(norm / 10**18); //Need to convert to 1e18 units!

                for (uint256 k; k < N_COINS - 1; k++) {
                    localVar.p_new[k] =
                        (localVar.price_scale[k] *
                            (norm - adjustment_step) +
                            adjustment_step *
                            localVar.price_oracle[k]) /
                        norm;
                }

                //Calculate balancees * prices
                localVar.xp = _xp;
                for (uint256 k; k < N_COINS - 1; k++) {
                    localVar.xp[k + 1] =
                        (_xp[k + 1] * localVar.p_new[k]) /
                        localVar.price_scale[k];
                }

                //Calculate "extended constant produce" invariant xCP and virtual price
                uint256 _D = Math(math).newton_D(
                    A_gamma[0],
                    A_gamma[1],
                    localVar.xp
                );
                localVar.xp[0] = _D / N_COINS;
                for (uint256 k; k < N_COINS - 1; k++) {
                    localVar.xp[k + 1] =
                        (_D * 10**18) /
                        (N_COINS * localVar.p_new[k]);
                }
                //We reuse old_virtual_price here but it's not old anymore
                localVar.old_virtual_price =
                    (10**18 * Math(math).geometric_mean(localVar.xp)) /
                    localVar.total_supply;

                //Proceed if we've got enough profit
                //if (old_virtual_price > 10**18) and (2 * (old_virtual_price - 10**18) > xcp_profit - 10**18):
                if (
                    localVar.old_virtual_price > 10**18 &&
                    2 * localVar.old_virtual_price - 10**18 > xcp_profit
                ) {
                    localVar.packed_prices = 0;
                    for (uint256 k; k < N_COINS - 1; k++) {
                        localVar.packed_prices <<= PRICE_SIZE;
                        localVar.p = localVar.p_new[N_COINS - 2 - k]; // / PRICE_PRECISION_MUL
                        require(localVar.p < PRICE_MASK);
                        localVar.packed_prices =
                            localVar.p |
                            localVar.packed_prices;
                    }
                    price_scale_packed = localVar.packed_prices;
                    D = _D;
                    virtual_price = localVar.old_virtual_price;

                    return;
                } else {
                    not_adjusted = false;
                }
            }
        }
        //If we are here, the price_scale adjustment did not happen
        //Still need to update teh profit counter and D
        D = localVar.D_unadjusted;
        virtual_price = _virtual_price;
    }

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable nonReentrant returns (uint256) {
        return exchange(i, j, dx, min_dy, false);
    }

    struct ExchangeLocalVar {
        uint256[2] A_gamma;
        uint256[N_COINS] xp;
        uint256 ix;
        uint256 p;
        uint256 dy;
        address[N_COINS] _coins;
        uint256 y;
        uint256 x0;
        uint256[N_COINS - 1] price_scale;
        uint256 packed_prices;
    }

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) public payable nonReentrant returns (uint256) {
        require(!is_killed, "dev: the pool is killed");
        require(i != j, "dev: coin index out of range");
        require(i < N_COINS, "dev: coin index out of range");
        require(j < N_COINS, "dev: coin index out of range");
        require(dx > 0, "dev: do not exchange 0 coins");

        ExchangeLocalVar memory localVar;

        localVar.A_gamma = _A_gamma();
        localVar.xp = balances;
        localVar.ix = j;

        if (true) {
            //scope to reduce size of memory when makign internal calls later
            localVar._coins = coins;
            if (i == 2 && use_eth) {
                require(msg.value == dx, "dev: incorrect eth amount");
                WETH(coins[2]).deposit{value: msg.value}();
            } else {
                require(msg.value == 0, "dev: nonzero eth amount");
                //assert might be needed for some tokens - removed one to save bytespace
                ERC20(localVar._coins[i]).transferFrom(
                    msg.sender,
                    address(this),
                    dx
                );
            }

            localVar.y = localVar.xp[j];
            localVar.x0 = localVar.xp[i];
            localVar.xp[i] = localVar.x0 + dx;
            balances[i] = localVar.xp[i];

            localVar.packed_prices = price_scale_packed;
            for (uint256 k; k < N_COINS - 1; k++) {
                localVar.price_scale[k] = localVar.packed_prices & PRICE_MASK; // * PRICE_PRECISION_MUL
                localVar.packed_prices >>= PRICE_SIZE;
            }

            uint256[N_COINS] memory precisions = PRECISIONS;
            localVar.xp[0] *= PRECISIONS[0];
            for (uint256 k = 1; k < N_COINS; k++) {
                localVar.xp[k] =
                    (localVar.xp[k] *
                        localVar.price_scale[k - 1] *
                        precisions[k]) /
                    PRECISION;
            }

            uint256 prec_i = precisions[i];

            //In case ramp is happening
            if (true) {
                uint256 t = future_A_gamma_time;
                if (t > 0) {
                    localVar.x0 *= prec_i;
                    if (i > 0) {
                        localVar.x0 =
                            (localVar.x0 * localVar.price_scale[i - 1]) /
                            PRECISION;
                    }
                    uint256 x1 = localVar.xp[i]; //Back up old value in xp
                    localVar.xp[i] = localVar.x0;
                    D = Math(math).newton_D(
                        localVar.A_gamma[0],
                        localVar.A_gamma[1],
                        localVar.xp
                    );
                    localVar.xp[i] = x1; //And restore
                    if (block.timestamp >= t) {
                        future_A_gamma_time = 1;
                    }
                }
            }

            uint256 prec_j = precisions[j];

            localVar.dy =
                localVar.xp[j] -
                Math(math).newton_y(
                    localVar.A_gamma[0],
                    localVar.A_gamma[1],
                    localVar.xp,
                    D,
                    j
                );
            //Not defining new "y" here to have less variables / make subsequent calls cheaper
            localVar.xp[j] -= localVar.dy;
            localVar.dy -= 1;

            if (j > 0) {
                localVar.dy =
                    (localVar.dy * PRECISION) /
                    localVar.price_scale[j - 1];
            }
            localVar.dy /= prec_j;

            localVar.dy -= (_fee(localVar.xp) * localVar.dy) / 10**10;
            require(localVar.dy >= min_dy, "Slippage");
            localVar.y -= localVar.dy;

            balances[j] = localVar.y;
            //assert might be needed for some tokens - removed one to save bytespace
            if (j == 2 && use_eth) {
                WETH(coins[2]).withdraw(localVar.dy);
                (bool sent, ) = msg.sender.call{value: localVar.dy}("");
                require(sent);
            } else {
                ERC20(localVar._coins[j]).transfer(msg.sender, localVar.dy);
            }

            localVar.y *= prec_j;
            if (j > 0) {
                localVar.y =
                    (localVar.y * localVar.price_scale[j - 1]) /
                    PRECISION;
            }
            localVar.xp[j] = localVar.y;

            //Calculate price
            if (dx > 10**5 && localVar.dy > 10**5) {
                uint256 _dx = dx * prec_i;
                uint256 _dy = localVar.dy * prec_j;
                if (i != 0 && j != 0) {
                    localVar.p =
                        (((last_prices_packed >> (PRICE_SIZE * (i - 1))) &
                            PRICE_MASK) * _dx) /
                        _dy; // * PRICE_PRECISION_MUL
                } else if (i == 0) {
                    localVar.p = (_dx * 10**18) / _dy;
                } else {
                    // j == 0;
                    localVar.p = (_dy * 10**18) / _dx;
                    localVar.ix = i;
                }
            }
        }
        tweak_price(localVar.A_gamma, localVar.xp, localVar.ix, localVar.p, 0);

        emit TokenExchange(msg.sender, i, dx, j, localVar.dy);

        return localVar.dy; // return in latest version, but not in version tested
    }

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256) {
        return Views(views).get_dy(i, j, dx);
    }

    function _calc_token_fee(
        uint256[N_COINS] memory amounts,
        uint256[N_COINS] memory _xp
    ) internal view returns (uint256) {
        //fee = sum(amounts)i - avg(amounts)) * fee' / sum(amounts)
        uint256 __fee = (_fee(_xp) * N_COINS) / (4 * (N_COINS - 1));
        uint256 S = 0;
        for (uint256 i; i < amounts.length; i++) {
            S += amounts[i];
        }
        uint256 avg = S / N_COINS;
        uint256 Sdiff = 0;
        for (uint256 i; i < amounts.length; i++) {
            if (amounts[i] > avg) {
                Sdiff += amounts[i] - avg;
            } else {
                Sdiff += avg - amounts[i];
            }
        }
        return (__fee * Sdiff) / S + NOISE_FEE;
    }

    function calc_token_fee(
        uint256[N_COINS] memory amounts,
        uint256[N_COINS] memory _xp
    ) external view returns (uint256) {
        return _calc_token_fee(amounts, _xp);
    }

    struct AddLiquidityLocalVar {
        uint256[2] A_gamma;
        address[N_COINS] _coins;
        uint256[N_COINS] xp;
        uint256[N_COINS] amountsp;
        uint256[N_COINS] xx;
        uint256 d_token;
        uint256 d_token_fee;
        uint256 old_D;
        uint256 ix;
    }

    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external nonReentrant {
        assert(!is_killed);

        AddLiquidityLocalVar memory localVar;

        localVar.A_gamma = _A_gamma();

        localVar._coins = coins;
        localVar.xp = balances;
        localVar.ix = INF_COINS;

        //Scope to avoid having extra variables in memory later
        if (true) {
            uint256[N_COINS] memory xp_old = localVar.xp;

            for (uint256 i; i < N_COINS; i++) {
                uint256 bal = localVar.xp[i] + amounts[i];
                localVar.xp[i] = bal;
                balances[i] = bal;
            }
            localVar.xx = localVar.xp;

            uint256[N_COINS] memory precisions = PRECISIONS;
            uint256 packed_prices = price_scale_packed;
            localVar.xp[0] *= PRECISIONS[0];
            xp_old[0] *= PRECISIONS[0];

            for (uint256 i = 1; i < N_COINS; i++) {
                uint256 _price_scale = (packed_prices & PRICE_MASK) *
                    precisions[i]; // * PRICE_PRECISION_MUL
                localVar.xp[i] = (localVar.xp[i] * _price_scale) / PRECISION;
                xp_old[i] = (xp_old[i] * _price_scale) / PRECISION;
                packed_prices >>= PRICE_SIZE;
            }

            for (uint256 i; i < N_COINS; i++) {
                if (amounts[i] > 0) {
                    //assert might be needed for some tokens - removed one to save bytespace
                    ERC20(localVar._coins[i]).transferFrom(
                        msg.sender,
                        address(this),
                        amounts[i]
                    );
                    localVar.amountsp[i] = localVar.xp[i] - xp_old[i];
                    if (localVar.ix == INF_COINS) {
                        localVar.ix = i;
                    } else {
                        localVar.ix = INF_COINS - 1;
                    }
                }
            }
            require(localVar.ix != INF_COINS, "dev: no coins to add");

            uint256 t = future_A_gamma_time;
            if (t > 0) {
                localVar.old_D = Math(math).newton_D(
                    localVar.A_gamma[0],
                    localVar.A_gamma[1],
                    xp_old
                );
                if (block.timestamp >= t) {
                    future_A_gamma_time = 1;
                }
            } else {
                localVar.old_D = D;
            }
        }

        uint256 _D = Math(math).newton_D(
            localVar.A_gamma[0],
            localVar.A_gamma[1],
            localVar.xp
        );

        uint256 token_supply = CurveToken(token).totalSupply();
        if (localVar.old_D > 0) {
            localVar.d_token =
                (token_supply * _D) /
                localVar.old_D -
                token_supply;
        } else {
            localVar.d_token = get_xcp(_D); //making initial virtual price equal to 1
        }
        require(localVar.d_token > 0, "dev: nothing minted");

        if (localVar.old_D > 0) {
            localVar.d_token_fee =
                (_calc_token_fee(localVar.amountsp, localVar.xp) *
                    localVar.d_token) /
                10**10 +
                1;
            localVar.d_token -= localVar.d_token_fee;
            token_supply += localVar.d_token;
            CurveToken(token).mint(msg.sender, localVar.d_token);

            //Calculate price
            //p_i * (dx_i - dtoken / token_supply * xx_i) = sum{k!=i}(p_k * (dtoken / token_supply * xx_k - dx_k))
            //Only ix is nonzero
            uint256 p;
            if (localVar.d_token > 10**5) {
                if (localVar.ix < N_COINS) {
                    uint256 S = 0;
                    uint256[N_COINS - 1] memory _last_prices;
                    uint256 packed_prices = last_prices_packed;
                    uint256[N_COINS] memory precisions = PRECISIONS;
                    for (uint256 k; k < N_COINS - 1; k++) {
                        _last_prices[k] = packed_prices & PRICE_MASK; // * PRICE_PRECISION_MUL
                        packed_prices >>= PRICE_SIZE;
                    }
                    for (uint256 i; i < N_COINS; i++) {
                        if (i != localVar.ix) {
                            if (i == 0) {
                                S += localVar.xx[0] * PRECISIONS[0];
                            } else {
                                S +=
                                    (localVar.xx[i] *
                                        _last_prices[i - 1] *
                                        precisions[i]) /
                                    PRECISION;
                            }
                        }
                    }
                    S = (S * localVar.d_token) / token_supply;
                    p =
                        (S * PRECISION) /
                        (amounts[localVar.ix] *
                            precisions[localVar.ix] -
                            (localVar.d_token *
                                localVar.xx[localVar.ix] *
                                precisions[localVar.ix]) /
                            token_supply);
                }
            }
            tweak_price(localVar.A_gamma, localVar.xp, localVar.ix, p, _D);
        } else {
            D = _D;
            virtual_price = 10**18;
            xcp_profit = 10**18;
            CurveToken(token).mint(msg.sender, localVar.d_token);
        }

        require(localVar.d_token >= min_mint_amount, "Slippage");

        emit AddLiquidity(
            msg.sender,
            amounts,
            localVar.d_token_fee,
            token_supply
        );
    }

    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] memory min_amounts
    ) external nonReentrant {
        /*
      This withdrawal method is very safe, does no complex math
      */
        address[N_COINS] memory _coins = coins;
        uint256 total_supply = CurveToken(token).totalSupply();
        CurveToken(token).burnFrom(msg.sender, _amount);
        uint256[N_COINS] memory _balances = balances;
        uint256 amount = _amount - 1; //Make rounding errors favoring other LPs a tiny bit

        for (uint256 i; i < N_COINS; i++) {
            uint256 d_balance = (_balances[i] * amount) / total_supply;
            assert(d_balance >= min_amounts[i]);
            balances[i] = _balances[i] - d_balance;
            _balances[i] = d_balance; //now it's the amounts going out
            //assert might be needed for some tokens - removed one to save bytespace
            ERC20(_coins[i]).transfer(msg.sender, d_balance);
        }

        uint256 _D = D;
        D = _D - (_D * amount) / total_supply;
        emit RemoveLiquidity(msg.sender, balances, total_supply - _amount);
    }

    function calc_token_amount(uint256[N_COINS] memory amounts, bool deposit)
        external
        view
        returns (uint256)
    {
        return Views(views).calc_token_amount(amounts, deposit);
    }

    struct CalcWithdrawOneCoin {
        uint256 token_supply;
        uint256[N_COINS] xx;
        uint256[N_COINS] xp;
        uint256 D0;
        uint256 price_scale_i;
        uint256 packed_prices;
        uint256 _p;
        uint256 _D;
        uint256 fee;
        uint256 dD;
        uint256 y;
        uint256 dy;
    }

    function _calc_withdraw_one_coin(
        uint256[2] memory A_gamma,
        uint256 token_amount,
        uint256 i,
        bool update_D,
        bool calc_price
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256[N_COINS] memory
        )
    {
        CalcWithdrawOneCoin memory localVar;

        localVar.token_supply = CurveToken(token).totalSupply();
        require(
            token_amount <= localVar.token_supply,
            "dev: token amount more than supply"
        );
        require(i < N_COINS, "dev: coin out of range");

        localVar.xx = balances;
        localVar.xp = PRECISIONS;

        localVar.price_scale_i = PRECISION * PRECISIONS[0];
        if (true) {
            //To remove packed_prices from memory
            localVar.packed_prices = price_scale_packed;
            localVar.xp[0] *= localVar.xx[0];
            for (uint256 k = 1; k < N_COINS; k++) {
                localVar._p = localVar.packed_prices & PRICE_MASK; // * PRICE_PRECISION_MUL
                if (i == k) {
                    localVar.price_scale_i = localVar._p * localVar.xp[i];
                }
                localVar.xp[k] =
                    (localVar.xp[k] * localVar.xx[k] * localVar._p) /
                    PRECISION;
                localVar.packed_prices >>= PRICE_SIZE;
            }
        }

        if (update_D) {
            localVar.D0 = Math(math).newton_D(
                A_gamma[0],
                A_gamma[1],
                localVar.xp
            );
        } else {
            localVar.D0 = D;
        }

        localVar._D = localVar.D0;

        //charge the fee on D, not on y, e.g. reducint invariant LESS than charging the user
        localVar.fee = _fee(localVar.xp);
        localVar.dD = (token_amount * localVar._D) / localVar.token_supply;
        localVar._D -= (localVar.dD -
            ((localVar.fee * localVar.dD) / (2 * 10**10) + 1));
        localVar.y = Math(math).newton_y(
            A_gamma[0],
            A_gamma[1],
            localVar.xp,
            localVar._D,
            i
        );
        localVar.dy =
            ((localVar.xp[i] - localVar.y) * PRECISION) /
            localVar.price_scale_i;
        localVar.xp[i] = localVar.y;

        //Price calc
        uint256 p = 0;
        if (calc_price && localVar.dy > 10**5 && token_amount > 10**5) {
            //p_i = dD / D0 * sum'(p_k * x_k) / (dy - dD / D0 * y0)
            uint256 S = 0;
            uint256[N_COINS] memory precisions = PRECISIONS;
            uint256[N_COINS - 1] memory _last_prices;
            localVar.packed_prices = last_prices_packed;
            for (uint256 k; k < N_COINS - 1; k++) {
                _last_prices[k] = localVar.packed_prices & PRICE_MASK; // * PRICE_PRECISION_MUL
                localVar.packed_prices >>= PRICE_SIZE;
            }
            for (uint256 k; k < N_COINS; k++) {
                if (k != i) {
                    if (k == 0) {
                        S += localVar.xx[0] * PRECISIONS[0];
                    } else {
                        S +=
                            (localVar.xx[k] *
                                _last_prices[k - 1] *
                                precisions[k]) /
                            PRECISION;
                    }
                }
            }
            S = (S * localVar.dD) / localVar.D0;
            p =
                (S * PRECISION) /
                (localVar.dy *
                    precisions[i] -
                    (localVar.dD * localVar.xx[i] * precisions[i]) /
                    localVar.D0);
        }
        return (localVar.dy, p, localVar._D, localVar.xp);
    }

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
        external
        view
        returns (uint256 output)
    {
        (output, , , ) = _calc_withdraw_one_coin(
            _A_gamma(),
            token_amount,
            i,
            true,
            false
        );
    }

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external nonReentrant {
        require(!is_killed, "dev: the pool is killed");

        uint256[2] memory A_gamma = _A_gamma();

        uint256 dy;
        uint256 _D;
        uint256 p;
        uint256[N_COINS] memory _xp;
        uint256 _future_A_gamma_time = future_A_gamma_time;

        (dy, p, _D, _xp) = _calc_withdraw_one_coin(
            A_gamma,
            token_amount,
            i,
            (_future_A_gamma_time > 0),
            true
        );
        require(dy >= min_amount, "Slippage");

        if (block.timestamp >= _future_A_gamma_time) {
            future_A_gamma_time = 1;
        }

        balances[i] -= dy;
        CurveToken(token).burnFrom(msg.sender, token_amount);
        tweak_price(A_gamma, _xp, i, p, _D);

        address[N_COINS] memory _coins = coins;
        //assert might be needed for osme tokens - removed on to save bytespace
        ERC20(_coins[i]).transfer(msg.sender, dy);

        emit RemoveLiquidityOne(msg.sender, token_amount, i, dy);
    }

    function claim_admin_fees() external nonReentrant {
        _claim_admin_fees();
    }

    //Admin parameters
    function ramp_A_gamma(
        uint256 future_A,
        uint256 future_gamma,
        uint256 future_time
    ) external {
        require(msg.sender == owner, "dev: only owner");
        require(block.timestamp > initial_A_gamma_time + MIN_RAMP_TIME - 1);
        require(
            future_time > block.timestamp + MIN_RAMP_TIME - 1,
            "dev: insufficient time"
        );

        uint256[2] memory A_gamma = _A_gamma();
        uint256 _initial_A_gamma = A_gamma[0] << 128;
        _initial_A_gamma = _initial_A_gamma | A_gamma[1];

        require(future_A > 0);
        require(future_A < MAX_A + 1);
        require(future_gamma > MIN_GAMMA - 1);
        require(future_gamma < MAX_GAMMA + 1);

        uint256 ratio = (10**18 * future_A) / A_gamma[0];
        require(ratio < 10**18 * MAX_A_CHANGE + 1);
        require(ratio > 10**18 / MAX_A_CHANGE - 1);

        ratio = (10**18 * future_gamma) / A_gamma[1];
        require(ratio < 10**18 * MAX_A_CHANGE + 1);
        require(ratio > 10**18 / MAX_A_CHANGE - 1);

        initial_A_gamma = _initial_A_gamma;
        initial_A_gamma_time = block.timestamp;

        future_A_gamma = future_A << 128;
        future_A_gamma = future_A_gamma | future_gamma;
        future_A_gamma_time = future_time;

        emit RampAgamma(
            A_gamma[0],
            future_A,
            A_gamma[1],
            future_gamma,
            block.timestamp,
            future_time
        );
    }

    function stop_ramp_A_gamma() external {
        require(msg.sender == owner, "dev: only owner");

        uint256[2] memory A_gamma = _A_gamma();
        uint256 current_A_gamma = A_gamma[0] << 128;
        current_A_gamma = current_A_gamma | A_gamma[1];
        initial_A_gamma = current_A_gamma;
        future_A_gamma = current_A_gamma;
        initial_A_gamma_time = block.timestamp;
        future_A_gamma_time = block.timestamp;
        // now (block.timestamp < t1) is always False, so we return saved A

        emit StopRampA(A_gamma[0], A_gamma[1], block.timestamp);
    }

    function commit_new_parameters(
        uint256 _new_mid_fee,
        uint256 _new_out_fee,
        uint256 _new_admin_fee,
        uint256 _new_fee_gamma,
        uint256 _new_allowed_extra_profit,
        uint256 _new_adjustment_step,
        uint256 _new_ma_half_time
    ) external {
        require(msg.sender == owner, "dev: only owner");
        require(admin_actions_deadline == 0, "dev: active action");

        uint256 new_mid_fee = _new_mid_fee;
        uint256 new_out_fee = _new_out_fee;
        uint256 new_admin_fee = _new_admin_fee;
        uint256 new_fee_gamma = _new_fee_gamma;
        uint256 new_allowed_extra_profit = _new_allowed_extra_profit;
        uint256 new_adjustment_step = _new_adjustment_step;
        uint256 new_ma_half_time = _new_ma_half_time;

        if (new_out_fee < MAX_FEE + 1) {
            require(new_out_fee > MIN_FEE - 1, "dev: fee is out of range");
        } else {
            new_out_fee = out_fee;
        }
        if (new_mid_fee > MAX_FEE) {
            new_mid_fee = mid_fee;
        }
        require(new_mid_fee <= new_out_fee, "dev: mid_fee is too high");
        if (new_admin_fee > MAX_ADMIN_FEE) {
            new_admin_fee = admin_fee;
        }

        //AMM parameters
        if (new_fee_gamma < 10**18) {
            require(
                new_fee_gamma > 0,
                "dev: fee_gamma out of range [1 .. 10**18]"
            );
        } else {
            new_fee_gamma = fee_gamma;
        }
        if (new_allowed_extra_profit > 10**18) {
            new_allowed_extra_profit = allowed_extra_profit;
        }
        if (new_adjustment_step > 10**18) {
            new_adjustment_step = adjustment_step;
        }

        //MA
        if (new_ma_half_time < 7 * 86400) {
            require(
                new_ma_half_time > 0,
                "dev: MA time should be longer than 1 second"
            );
        } else {
            new_ma_half_time = ma_half_time;
        }

        uint256 _deadline = block.timestamp + ADMIN_ACTIONS_DELAY;
        admin_actions_deadline = _deadline;

        future_admin_fee = new_admin_fee;
        future_mid_fee = new_mid_fee;
        future_out_fee = new_out_fee;
        future_fee_gamma = new_fee_gamma;
        future_allowed_extra_profit = new_allowed_extra_profit;
        future_adjustment_step = new_adjustment_step;
        future_ma_half_time = new_ma_half_time;

        emit CommitNewParameters(
            _deadline,
            new_admin_fee,
            new_mid_fee,
            new_out_fee,
            new_fee_gamma,
            new_allowed_extra_profit,
            new_adjustment_step,
            new_ma_half_time
        );
    }

    function apply_new_parameters() external nonReentrant {
        require(msg.sender == owner, "dev: only owner");
        require(
            block.timestamp >= admin_actions_deadline,
            "dev: insufficient time"
        );
        require(admin_actions_deadline != 0, "dev: no active action");

        admin_actions_deadline = 0;

        if (admin_fee != future_admin_fee) {
            _claim_admin_fees();
            admin_fee = future_admin_fee;
        }

        mid_fee = future_mid_fee;
        out_fee = future_out_fee;
        fee_gamma = future_fee_gamma;
        allowed_extra_profit = future_allowed_extra_profit;
        adjustment_step = future_adjustment_step;
        ma_half_time = future_ma_half_time;

        emit NewParameters(
            admin_fee,
            mid_fee,
            out_fee,
            fee_gamma,
            allowed_extra_profit,
            adjustment_step,
            ma_half_time
        );
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