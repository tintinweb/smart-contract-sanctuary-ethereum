// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15;
/*
   __     ___      _     _
   \ \   / (_)    | |   | | ██╗   ██╗██╗███████╗██╗     ██████╗ ███╗   ███╗ █████╗ ████████╗██╗  ██╗
    \ \_/ / _  ___| | __| | ╚██╗ ██╔╝██║██╔════╝██║     ██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║  ██║
     \   / | |/ _ \ |/ _` |  ╚████╔╝ ██║█████╗  ██║     ██║  ██║██╔████╔██║███████║   ██║   ███████║
      | |  | |  __/ | (_| |   ╚██╔╝  ██║██╔══╝  ██║     ██║  ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
      |_|  |_|\___|_|\__,_|    ██║   ██║███████╗███████╗██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
       yieldprotocol.com       ╚═╝   ╚═╝╚══════╝╚══════╝╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
*/

import {Exp64x64} from "./Exp64x64.sol";
import {Math64x64} from "./Math64x64.sol";
import {CastU256U128} from  "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import {CastU128I128} from  "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";

/// Ethereum smart contract library implementing Yield Math model with yield bearing tokens.
/// @dev see Mikhail Vladimirov (ABDK) explanations of the math: https://hackmd.io/gbnqA3gCTR6z-F0HHTxF-A#Yield-Math
library YieldMath {
    using Math64x64 for int128;
    using Math64x64 for uint128;
    using Math64x64 for int256;
    using Math64x64 for uint256;
    using Exp64x64 for uint128;
    using CastU256U128 for uint256;
    using CastU128I128 for uint128;

    uint128 public constant ONE = 0x10000000000000000; //   In 64.64
    uint256 public constant MAX = type(uint128).max; //     Used for overflow checks

    /* CORE FUNCTIONS
     ******************************************************************************************************************/

    /* ----------------------------------------------------------------------------------------------------------------
                                              ┌───────────────────────────────┐                    .-:::::::::::-.
      ┌──────────────┐                        │                               │                  .:::::::::::::::::.
      │$            $│                       \│                               │/                :  _______  __   __ :
      │ ┌────────────┴─┐                     \│                               │/               :: |       ||  | |  |::
      │ │$            $│                      │    fyTokenOutForSharesIn      │               ::: |    ___||  |_|  |:::
      │$│ ┌────────────┴─┐     ────────▶      │                               │  ────────▶    ::: |   |___ |       |:::
      └─┤ │$            $│                    │                               │               ::: |    ___||_     _|:::
        │$│  `sharesIn`  │                   /│                               │\              ::: |   |      |   |  :::
        └─┤              │                   /│                               │\               :: |___|      |___|  ::
          │$            $│                    │                      \(^o^)/  │                 :       ????        :
          └──────────────┘                    │                     YieldMath │                  `:::::::::::::::::'
                                              └───────────────────────────────┘                    `-:::::::::::-'
    */
    /// Calculates the amount of fyToken a user would get for given amount of shares.
    /// https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param sharesIn shares amount to be traded
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return fyTokenOut the amount of fyToken a user would get for given amount of shares
    function fyTokenOutForSharesIn(
        uint128 sharesReserves, // z
        uint128 fyTokenReserves, // x
        uint128 sharesIn, // x == Δz
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            uint128 a = _computeA(timeTillMaturity, k, g);

            uint256 sum;
            {
                /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                y = fyToken reserves
                z = shares reserves
                x = Δz (sharesIn)

                     y - (                         sum                           )^(   invA   )
                     y - ((    Za         ) + (  Ya  ) - (       Zxa           ) )^(   invA   )
                Δy = y - ( c/μ * (μz)^(1-t) +  y^(1-t) -  c/μ * (μz + μx)^(1-t)  )^(1 / (1 - t))

                */
                uint256 normalizedSharesReserves;
                require(
                    (normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX,
                    "YieldMath: Rate overflow (nsr)"
                );

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(uint128(normalizedSharesReserves).pow(a, ONE))) <= MAX,
                    "YieldMath: Rate overflow (za)"
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // normalizedSharesIn = μ * sharesIn
                uint256 normalizedSharesIn;
                require(
                    (normalizedSharesIn = mu.mulu(sharesIn)) <= MAX,
                    "YieldMath: Rate overflow (nsi)"
                );

                // zx = normalizedSharesReserves + sharesIn * μ
                uint256 zx;
                require((zx = normalizedSharesReserves + normalizedSharesIn) <= MAX, "YieldMath: Too many shares in");

                // zxa = c/μ * zx ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 zxa;
                require(
                    (zxa = c.div(mu).mulu(uint128(zx).pow(a, ONE))) <= MAX,
                    "YieldMath: Rate overflow (zxa)"
                );

                sum = za + ya - zxa;

                require(sum <= (za + ya), "YieldMath: Sum underflow");
            }

            // result = fyTokenReserves - (sum ** (1/a))
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 fyTokenOut;
            require(
                (fyTokenOut = uint256(fyTokenReserves) - sum.u128().pow(ONE, a)) <= MAX,
                "YieldMath: Rounding error"
            );

            require(
                fyTokenOut <= fyTokenReserves,
                "YieldMath: > fyToken reserves"
            );


            return uint128(fyTokenOut);
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
          .-:::::::::::-.                       ┌───────────────────────────────┐
        .:::::::::::::::::.                     │                               │
       :  _______  __   __ :                   \│                               │/              ┌──────────────┐
      :: |       ||  | |  |::                  \│                               │/              │$            $│
     ::: |    ___||  |_|  |:::                  │    sharesOutForFYTokenIn      │               │ ┌────────────┴─┐
     ::: |   |___ |       |:::   ────────▶      │                               │  ────────▶    │ │$            $│
     ::: |    ___||_     _|:::                  │                               │               │$│ ┌────────────┴─┐
     ::: |   |      |   |  :::                 /│                               │\              └─┤ │$            $│
      :: |___|      |___|  ::                  /│                               │\                │$│    SHARES    │
       :     `fyTokenIn`   :                    │                      \(^o^)/  │                 └─┤     ????     │
        `:::::::::::::::::'                     │                     YieldMath │                   │$            $│
          `-:::::::::::-'                       └───────────────────────────────┘                   └──────────────┘
    */
    /// Calculates the amount of shares a user would get for certain amount of fyToken.
    /// @param sharesReserves shares reserves amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param fyTokenIn fyToken amount to be traded
    /// @param timeTillMaturity time till maturity in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64
    /// @param g fee coefficient, multiplied by 2^64
    /// @param c price of shares in terms of Dai, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return amount of Shares a user would get for given amount of fyToken
    function sharesOutForFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenIn,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");
            return
                _sharesOutForFYTokenIn(
                    sharesReserves,
                    fyTokenReserves,
                    fyTokenIn,
                    _computeA(timeTillMaturity, k, g),
                    c,
                    mu
                );
        }
    }

    /// @dev Splitting sharesOutForFYTokenIn in two functions to avoid stack depth limits.
    function _sharesOutForFYTokenIn(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenIn,
        uint128 a,
        int128 c,
        int128 mu
    ) private pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

            y = fyToken reserves
            z = shares reserves
            x = Δy (fyTokenIn)

                 z - (                                rightTerm                                              )
                 z - (invMu) * (      Za              ) + ( Ya   ) - (    Yxa      ) / (c / μ) )^(   invA    )
            Δz = z -   1/μ   * ( ( (c / μ) * (μz)^(1-t) +  y^(1-t) - (y + x)^(1-t) ) / (c / μ) )^(1 / (1 - t))

        */
        unchecked {
            // normalizedSharesReserves = μ * sharesReserves
            uint256 normalizedSharesReserves;
            require(
                (normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX,
                "YieldMath: Rate overflow (nsr)"
            );

            uint128 rightTerm;
            {
                uint256 zaYaYxa;
                {
                    // za = c/μ * (normalizedSharesReserves ** a)
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 za;
                    require(
                        (za = c.div(mu).mulu(uint128(normalizedSharesReserves).pow(a, ONE))) <= MAX,
                        "YieldMath: Rate overflow (za)"
                    );

                    // ya = fyTokenReserves ** a
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 ya = fyTokenReserves.pow(a, ONE);

                    // yxa = (fyTokenReserves + x) ** a   # x is aka Δy
                    // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                    // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                    uint256 yxa = (fyTokenReserves + fyTokenIn).pow(a, ONE);

                    require((zaYaYxa = (za + ya - yxa)) <= MAX, "YieldMath: Rate overflow (yxa)");
                }

                rightTerm = uint128(                         // Cast zaYaYxa/(c/μ).pow(1/a).div(μ) from int128 to uint128 - always positive
                    int128(                                  // Cast zaYaYxa/(c/μ).pow(1/a) from uint128 to int128 - always < zaYaYxa/(c/μ)
                        uint128(                             // Cast zaYaYxa/(c/μ) from int128 to uint128 - always positive
                            zaYaYxa.divu(uint128(c.div(mu))) // Cast c/μ from int128 to uint128 - always positive
                        ).pow(uint128(ONE), a)               // Cast 2^64 from int128 to uint128 - always positive
                    ).div(mu)
                );
            }
            require(rightTerm <= sharesReserves, "YieldMath: Rate underflow");

            return sharesReserves - rightTerm;
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
          .-:::::::::::-.                       ┌───────────────────────────────┐
        .:::::::::::::::::.                     │                               │              ┌──────────────┐
       :  _______  __   __ :                   \│                               │/             │$            $│
      :: |       ||  | |  |::                  \│                               │/             │ ┌────────────┴─┐
     ::: |    ___||  |_|  |:::                  │    fyTokenInForSharesOut      │              │ │$            $│
     ::: |   |___ |       |:::   ────────▶      │                               │  ────────▶   │$│ ┌────────────┴─┐
     ::: |    ___||_     _|:::                  │                               │              └─┤ │$            $│
     ::: |   |      |   |  :::                 /│                               │\               │$│              │
      :: |___|      |___|  ::                  /│                               │\               └─┤  `sharesOut` │
       :        ????       :                    │                      \(^o^)/  │                  │$            $│
        `:::::::::::::::::'                     │                     YieldMath │                  └──────────────┘
          `-:::::::::::-'                       └───────────────────────────────┘
    */
    /// Calculates the amount of fyToken a user could sell for given amount of Shares.
    /// @param sharesReserves shares reserves amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param sharesOut Shares amount to be traded
    /// @param timeTillMaturity time till maturity in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64
    /// @param g fee coefficient, multiplied by 2^64
    /// @param c price of shares in terms of Dai, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return fyTokenIn the amount of fyToken a user could sell for given amount of Shares
    function fyTokenInForSharesOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 sharesOut,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

                y = fyToken reserves
                z = shares reserves
                x = Δz (sharesOut)

                     (                  sum                                )^(   invA    ) - y
                     (    Za          ) + (  Ya  ) - (       Zxa           )^(   invA    ) - y
                Δy = ( c/μ * (μz)^(1-t) +  y^(1-t) - c/μ * (μz - μx)^(1-t) )^(1 / (1 - t)) - y

            */

        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");

            uint128 a = _computeA(timeTillMaturity, k, g);
            uint256 sum;
            {
                // normalizedSharesReserves = μ * sharesReserves
                uint256 normalizedSharesReserves;
                require(
                    (normalizedSharesReserves = mu.mulu(sharesReserves)) <= MAX,
                    "YieldMath: Rate overflow (nsr)"
                );

                // za = c/μ * (normalizedSharesReserves ** a)
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 za;
                require(
                    (za = c.div(mu).mulu(uint128(normalizedSharesReserves).pow(a, ONE))) <= MAX,
                    "YieldMath: Rate overflow (za)"
                );

                // ya = fyTokenReserves ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 ya = fyTokenReserves.pow(a, ONE);

                // normalizedSharesOut = μ * sharesOut
                uint256 normalizedSharesOut;
                require(
                    (normalizedSharesOut = mu.mulu(sharesOut)) <= MAX,
                    "YieldMath: Rate overflow (nso)"
                );

                // zx = normalizedSharesReserves + sharesOut * μ
                require(normalizedSharesReserves >= normalizedSharesOut, "YieldMath: Too many shares in");
                uint256 zx = normalizedSharesReserves - normalizedSharesOut;

                // zxa = c/μ * zx ** a
                // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
                // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
                uint256 zxa = c.div(mu).mulu(uint128(zx).pow(a, ONE));

                // sum = za + ya - zxa
                // z < MAX, y < MAX, a < 1. It can only underflow, not overflow.
                require((sum = za + ya - zxa) <= MAX, "YieldMath: > fyToken reserves");
            }

            // result = fyTokenReserves - (sum ** (1/a))
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 result;
            require(
                (result = uint256(uint128(sum).pow(ONE, a)) - uint256(fyTokenReserves)) <= MAX,
                "YieldMath: Rounding error"
            );

            return uint128(result);
        }
    }

    /* ----------------------------------------------------------------------------------------------------------------
                                              ┌───────────────────────────────┐                    .-:::::::::::-.
      ┌──────────────┐                        │                               │                  .:::::::::::::::::.
      │$            $│                       \│                               │/                :  _______  __   __ :
      │ ┌────────────┴─┐                     \│                               │/               :: |       ||  | |  |::
      │ │$            $│                      │    sharesInForFYTokenOut      │               ::: |    ___||  |_|  |:::
      │$│ ┌────────────┴─┐     ────────▶      │                               │  ────────▶    ::: |   |___ |       |:::
      └─┤ │$            $│                    │                               │               ::: |    ___||_     _|:::
        │$│    SHARES    │                   /│                               │\              ::: |   |      |   |  :::
        └─┤     ????     │                   /│                               │\               :: |___|      |___|  ::
          │$            $│                    │                      \(^o^)/  │                 :   `fyTokenOut`    :
          └──────────────┘                    │                     YieldMath │                  `:::::::::::::::::'
                                              └───────────────────────────────┘                    `-:::::::::::-'
    */
    /// @param sharesReserves yield bearing vault shares reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param fyTokenOut fyToken amount to be traded
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @param g fee coefficient, multiplied by 2^64 -- sb under 1.0 for selling shares to pool
    /// @param c price of shares in terms of their base, multiplied by 2^64
    /// @param mu (μ) Normalization factor -- starts as c at initialization
    /// @return result the amount of shares a user would have to pay for given amount of fyToken
    function sharesInForFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenOut,
        uint128 timeTillMaturity,
        int128 k,
        int128 g,
        int128 c,
        int128 mu
    ) public pure returns (uint128) {
        unchecked {
            require(c > 0 && mu > 0, "YieldMath: c and mu must be positive");
            return
                _sharesInForFYTokenOut(
                    sharesReserves,
                    fyTokenReserves,
                    fyTokenOut,
                    _computeA(timeTillMaturity, k, g),
                    c,
                    mu
                );
        }
    }

    /// @dev Splitting sharesInForFYTokenOut in two functions to avoid stack depth limits
    function _sharesInForFYTokenOut(
        uint128 sharesReserves,
        uint128 fyTokenReserves,
        uint128 fyTokenOut,
        uint128 a,
        int128 c,
        int128 mu
    ) private pure returns (uint128) {
        /* https://docs.google.com/spreadsheets/d/14K_McZhlgSXQfi6nFGwDvDh4BmOu6_Hczi_sFreFfOE/

        y = fyToken reserves
        z = shares reserves
        x = Δy (fyTokenOut)

             1/μ * (                 subtotal                            )^(   invA    ) - z
             1/μ * ((     Za       ) + (  Ya  ) - (    Yxa    )) / (c/μ) )^(   invA    ) - z
        Δz = 1/μ * (( c/μ * μz^(1-t) +  y^(1-t) - (y - x)^(1-t)) / (c/μ) )^(1 / (1 - t)) - z

        */
        unchecked {
            // normalizedSharesReserves = μ * sharesReserves
            require(mu.mulu(sharesReserves) <= MAX, "YieldMath: Rate overflow (nsr)");

            // za = c/μ * (normalizedSharesReserves ** a)
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 za = c.div(mu).mulu(uint128(mu.mulu(sharesReserves)).pow(a, ONE));
            require(za <= MAX, "YieldMath: Rate overflow (za)");

            // ya = fyTokenReserves ** a
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 ya = fyTokenReserves.pow(a, ONE);

            // yxa = (fyTokenReserves - x) ** aß
            // The “pow(x, y, z)” function not only calculates x^(y/z) but also normalizes the result to
            // fit into 64.64 fixed point number, i.e. it actually calculates: x^(y/z) * (2^63)^(1 - y/z)
            uint256 yxa = (fyTokenReserves - fyTokenOut).pow(a, ONE);
            require(fyTokenOut <= fyTokenReserves, "YieldMath: Underflow (yxa)");

            uint256 zaYaYxa;
            require((zaYaYxa = (za + ya - yxa)) <= MAX, "YieldMath: Rate overflow (zyy)");

            int128 subtotal = int128(ONE).div(mu).mul(
                (uint128(zaYaYxa.divu(uint128(c.div(mu)))).pow(uint128(ONE), uint128(a))).i128()
            );

            return uint128(subtotal) - sharesReserves;
        }
    }

    /* UTILITY FUNCTIONS
     ******************************************************************************************************************/

    function _computeA(
        uint128 timeTillMaturity,
        int128 k,
        int128 g
    ) private pure returns (uint128) {
        // t = k * timeTillMaturity
        int128 t = k.mul(timeTillMaturity.fromUInt());
        require(t >= 0, "YieldMath: t must be positive"); // Meaning neither T or k can be negative

        // a = (1 - gt)
        int128 a = int128(ONE).sub(g.mul(t));
        require(a > 0, "YieldMath: Too far from maturity");
        require(a <= int128(ONE), "YieldMath: g must be positive");

        return uint128(a);
    }

    /// Calculate a YieldSpace pool invariant according to the whitepaper
    /// @dev Implemented using base reserves and uint128 to be backwards compatible with yieldspace-v2
    /// @param baseReserves base reserve amount
    /// @param fyTokenReserves fyToken reserves amount
    /// @param totalSupply pool token total amount
    /// @param timeTillMaturity time till maturity in seconds e.g. 90 days in seconds
    /// @param k time till maturity coefficient, multiplied by 2^64.  e.g. 25 years in seconds
    /// @return result the invariant value
    function invariant(uint128 baseReserves, uint128 fyTokenReserves, uint256 totalSupply, uint128 timeTillMaturity, int128 k)
        public pure returns(uint128 result)
    {
        if (totalSupply == 0) return 0;

        unchecked {
            // a = (1 - k * timeTillMaturity)
            int128 a = int128(ONE).sub(k.mul(timeTillMaturity.fromUInt()));
            require (a > 0, "YieldMath: Too far from maturity");

            uint256 sum =
            uint256(baseReserves.pow(uint128 (a), ONE)) +
            uint256(fyTokenReserves.pow(uint128 (a), ONE)) >> 1;
            require(sum < MAX, "YieldMath: Sum overflow");

            // We multiply the dividend by 1e18 to get a fixed point number with 18 decimals
            uint256 result_ = uint256(uint128(sum).pow(ONE, uint128(a))) * 1e18 / totalSupply;
            require (result_ < MAX, "YieldMath: Result overflow");

            result = uint128(result_);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15; /*
   __     ___      _     _
   \ \   / (_)    | |   | | ███████╗██╗  ██╗██████╗  ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
    \ \_/ / _  ___| | __| | ██╔════╝╚██╗██╔╝██╔══██╗██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
     \   / | |/ _ \ |/ _` | █████╗   ╚███╔╝ ██████╔╝███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
      | |  | |  __/ | (_| | ██╔══╝   ██╔██╗ ██╔═══╝ ██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
      |_|  |_|\___|_|\__,_| ███████╗██╔╝ ██╗██║     ╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
                            Gas optimized math library custom-built by ABDK -- Copyright © 2019 */

import "./Math64x64.sol";

library Exp64x64 {
    /// @dev Raise given number x into power specified as a simple fraction y/z and then
    /// multiply the result by the normalization factor 2^(128 /// (1 - y/z)).
    /// Revert if z is zero, or if both x and y are zeros.
    /// @param x number to raise into given power y/z -- integer
    /// @param y numerator of the power to raise x into  -- 64.64
    /// @param z denominator of the power to raise x into  -- 64.64
    /// @return x raised into power y/z and then multiplied by 2^(128 * (1 - y/z)) -- integer
    function pow(
        uint128 x,
        uint128 y,
        uint128 z
    ) internal pure returns (uint128) {
        unchecked {
            require(z != 0);

            if (x == 0) {
                require(y != 0);
                return 0;
            } else {
                uint256 l = (uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - log_2(x)) * y) / z;
                if (l > 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) return 0;
                else return pow_2(uint128(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - l));
            }
        }
    }

    /// @dev Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert
    /// in case x is zero.
    /// @param x number to calculate base 2 logarithm of
    /// @return base 2 logarithm of x, multiplied by 2^121
    function log_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            require(x != 0);

            uint256 b = x;

            uint256 l = 0xFE000000000000000000000000000000;

            if (b < 0x10000000000000000) {
                l -= 0x80000000000000000000000000000000;
                b <<= 64;
            }
            if (b < 0x1000000000000000000000000) {
                l -= 0x40000000000000000000000000000000;
                b <<= 32;
            }
            if (b < 0x10000000000000000000000000000) {
                l -= 0x20000000000000000000000000000000;
                b <<= 16;
            }
            if (b < 0x1000000000000000000000000000000) {
                l -= 0x10000000000000000000000000000000;
                b <<= 8;
            }
            if (b < 0x10000000000000000000000000000000) {
                l -= 0x8000000000000000000000000000000;
                b <<= 4;
            }
            if (b < 0x40000000000000000000000000000000) {
                l -= 0x4000000000000000000000000000000;
                b <<= 2;
            }
            if (b < 0x80000000000000000000000000000000) {
                l -= 0x2000000000000000000000000000000;
                b <<= 1;
            }

            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x8000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x4000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x2000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x1000000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x800000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x400000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x200000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x100000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x80000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x40000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x20000000000000000;
            }
            b = (b * b) >> 127;
            if (b >= 0x100000000000000000000000000000000) {
                b >>= 1;
                l |= 0x10000000000000000;
            } /*
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
      b = b * b >> 127; if(b >= 0x100000000000000000000000000000000) l |= 0x1; */

            return uint128(l);
        }
    }

    /// @dev Calculate 2 raised into given power.
    /// @param x power to raise 2 into, multiplied by 2^121
    /// @return 2 raised into given power
    function pow_2(uint128 x) internal pure returns (uint128) {
        unchecked {
            uint256 r = 0x80000000000000000000000000000000;
            if (x & 0x1000000000000000000000000000000 > 0) r = (r * 0xb504f333f9de6484597d89b3754abe9f) >> 127;
            if (x & 0x800000000000000000000000000000 > 0) r = (r * 0x9837f0518db8a96f46ad23182e42f6f6) >> 127;
            if (x & 0x400000000000000000000000000000 > 0) r = (r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90) >> 127;
            if (x & 0x200000000000000000000000000000 > 0) r = (r * 0x85aac367cc487b14c5c95b8c2154c1b2) >> 127;
            if (x & 0x100000000000000000000000000000 > 0) r = (r * 0x82cd8698ac2ba1d73e2a475b46520bff) >> 127;
            if (x & 0x80000000000000000000000000000 > 0) r = (r * 0x8164d1f3bc0307737be56527bd14def4) >> 127;
            if (x & 0x40000000000000000000000000000 > 0) r = (r * 0x80b1ed4fd999ab6c25335719b6e6fd20) >> 127;
            if (x & 0x20000000000000000000000000000 > 0) r = (r * 0x8058d7d2d5e5f6b094d589f608ee4aa2) >> 127;
            if (x & 0x10000000000000000000000000000 > 0) r = (r * 0x802c6436d0e04f50ff8ce94a6797b3ce) >> 127;
            if (x & 0x8000000000000000000000000000 > 0) r = (r * 0x8016302f174676283690dfe44d11d008) >> 127;
            if (x & 0x4000000000000000000000000000 > 0) r = (r * 0x800b179c82028fd0945e54e2ae18f2f0) >> 127;
            if (x & 0x2000000000000000000000000000 > 0) r = (r * 0x80058baf7fee3b5d1c718b38e549cb93) >> 127;
            if (x & 0x1000000000000000000000000000 > 0) r = (r * 0x8002c5d00fdcfcb6b6566a58c048be1f) >> 127;
            if (x & 0x800000000000000000000000000 > 0) r = (r * 0x800162e61bed4a48e84c2e1a463473d9) >> 127;
            if (x & 0x400000000000000000000000000 > 0) r = (r * 0x8000b17292f702a3aa22beacca949013) >> 127;
            if (x & 0x200000000000000000000000000 > 0) r = (r * 0x800058b92abbae02030c5fa5256f41fe) >> 127;
            if (x & 0x100000000000000000000000000 > 0) r = (r * 0x80002c5c8dade4d71776c0f4dbea67d6) >> 127;
            if (x & 0x80000000000000000000000000 > 0) r = (r * 0x8000162e44eaf636526be456600bdbe4) >> 127;
            if (x & 0x40000000000000000000000000 > 0) r = (r * 0x80000b1721fa7c188307016c1cd4e8b6) >> 127;
            if (x & 0x20000000000000000000000000 > 0) r = (r * 0x8000058b90de7e4cecfc487503488bb1) >> 127;
            if (x & 0x10000000000000000000000000 > 0) r = (r * 0x800002c5c8678f36cbfce50a6de60b14) >> 127;
            if (x & 0x8000000000000000000000000 > 0) r = (r * 0x80000162e431db9f80b2347b5d62e516) >> 127;
            if (x & 0x4000000000000000000000000 > 0) r = (r * 0x800000b1721872d0c7b08cf1e0114152) >> 127;
            if (x & 0x2000000000000000000000000 > 0) r = (r * 0x80000058b90c1aa8a5c3736cb77e8dff) >> 127;
            if (x & 0x1000000000000000000000000 > 0) r = (r * 0x8000002c5c8605a4635f2efc2362d978) >> 127;
            if (x & 0x800000000000000000000000 > 0) r = (r * 0x800000162e4300e635cf4a109e3939bd) >> 127;
            if (x & 0x400000000000000000000000 > 0) r = (r * 0x8000000b17217ff81bef9c551590cf83) >> 127;
            if (x & 0x200000000000000000000000 > 0) r = (r * 0x800000058b90bfdd4e39cd52c0cfa27c) >> 127;
            if (x & 0x100000000000000000000000 > 0) r = (r * 0x80000002c5c85fe6f72d669e0e76e411) >> 127;
            if (x & 0x80000000000000000000000 > 0) r = (r * 0x8000000162e42ff18f9ad35186d0df28) >> 127;
            if (x & 0x40000000000000000000000 > 0) r = (r * 0x80000000b17217f84cce71aa0dcfffe7) >> 127;
            if (x & 0x20000000000000000000000 > 0) r = (r * 0x8000000058b90bfc07a77ad56ed22aaa) >> 127;
            if (x & 0x10000000000000000000000 > 0) r = (r * 0x800000002c5c85fdfc23cdead40da8d6) >> 127;
            if (x & 0x8000000000000000000000 > 0) r = (r * 0x80000000162e42fefc25eb1571853a66) >> 127;
            if (x & 0x4000000000000000000000 > 0) r = (r * 0x800000000b17217f7d97f692baacded5) >> 127;
            if (x & 0x2000000000000000000000 > 0) r = (r * 0x80000000058b90bfbead3b8b5dd254d7) >> 127;
            if (x & 0x1000000000000000000000 > 0) r = (r * 0x8000000002c5c85fdf4eedd62f084e67) >> 127;
            if (x & 0x800000000000000000000 > 0) r = (r * 0x800000000162e42fefa58aef378bf586) >> 127;
            if (x & 0x400000000000000000000 > 0) r = (r * 0x8000000000b17217f7d24a78a3c7ef02) >> 127;
            if (x & 0x200000000000000000000 > 0) r = (r * 0x800000000058b90bfbe9067c93e474a6) >> 127;
            if (x & 0x100000000000000000000 > 0) r = (r * 0x80000000002c5c85fdf47b8e5a72599f) >> 127;
            if (x & 0x80000000000000000000 > 0) r = (r * 0x8000000000162e42fefa3bdb315934a2) >> 127;
            if (x & 0x40000000000000000000 > 0) r = (r * 0x80000000000b17217f7d1d7299b49c46) >> 127;
            if (x & 0x20000000000000000000 > 0) r = (r * 0x8000000000058b90bfbe8e9a8d1c4ea0) >> 127;
            if (x & 0x10000000000000000000 > 0) r = (r * 0x800000000002c5c85fdf4745969ea76f) >> 127;
            if (x & 0x8000000000000000000 > 0) r = (r * 0x80000000000162e42fefa3a0df5373bf) >> 127;
            if (x & 0x4000000000000000000 > 0) r = (r * 0x800000000000b17217f7d1cff4aac1e1) >> 127;
            if (x & 0x2000000000000000000 > 0) r = (r * 0x80000000000058b90bfbe8e7db95a2f1) >> 127;
            if (x & 0x1000000000000000000 > 0) r = (r * 0x8000000000002c5c85fdf473e61ae1f8) >> 127;
            if (x & 0x800000000000000000 > 0) r = (r * 0x800000000000162e42fefa39f121751c) >> 127;
            if (x & 0x400000000000000000 > 0) r = (r * 0x8000000000000b17217f7d1cf815bb96) >> 127;
            if (x & 0x200000000000000000 > 0) r = (r * 0x800000000000058b90bfbe8e7bec1e0d) >> 127;
            if (x & 0x100000000000000000 > 0) r = (r * 0x80000000000002c5c85fdf473dee5f17) >> 127;
            if (x & 0x80000000000000000 > 0) r = (r * 0x8000000000000162e42fefa39ef5438f) >> 127;
            if (x & 0x40000000000000000 > 0) r = (r * 0x80000000000000b17217f7d1cf7a26c8) >> 127;
            if (x & 0x20000000000000000 > 0) r = (r * 0x8000000000000058b90bfbe8e7bcf4a4) >> 127;
            if (x & 0x10000000000000000 > 0) r = (r * 0x800000000000002c5c85fdf473de72a2) >> 127; /*
      if(x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
      if(x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
      if(x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
      if(x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
      if(x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
      if(x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
      if(x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
      if(x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
      if(x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
      if(x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
      if(x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
      if(x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
      if(x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
      if(x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
      if(x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
      if(x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
      if(x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
      if(x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
      if(x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
      if(x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
      if(x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
      if(x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
      if(x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
      if(x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
      if(x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
      if(x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
      if(x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
      if(x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
      if(x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
      if(x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
      if(x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
      if(x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
      if(x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
      if(x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
      if(x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
      if(x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
      if(x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
      if(x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
      if(x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
      if(x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
      if(x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
      if(x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
      if(x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
      if(x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
      if(x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
      if(x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
      if(x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
      if(x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
      if(x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
      if(x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
      if(x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
      if(x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
      if(x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
      if(x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
      if(x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
      if(x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
      if(x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
      if(x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
      if(x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
      if(x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
      if(x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
      if(x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
      if(x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
      if(x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127; */

            r >>= 127 - (x >> 121);

            return uint128(r);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.15; /*
  __     ___      _     _
  \ \   / (_)    | |   | |  ███╗   ███╗ █████╗ ████████╗██╗  ██╗ ██████╗ ██╗  ██╗██╗  ██╗ ██████╗ ██╗  ██╗
   \ \_/ / _  ___| | __| |  ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║██╔════╝ ██║  ██║╚██╗██╔╝██╔════╝ ██║  ██║
    \   / | |/ _ \ |/ _` |  ██╔████╔██║███████║   ██║   ███████║███████╗ ███████║ ╚███╔╝ ███████╗ ███████║
     | |  | |  __/ | (_| |  ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║██╔═══██╗╚════██║ ██╔██╗ ██╔═══██╗╚════██║
     |_|  |_|\___|_|\__,_|  ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║╚██████╔╝     ██║██╔╝ ██╗╚██████╔╝     ██║
       yieldprotocol.com    ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝      ╚═╝╚═╝  ╚═╝ ╚═════╝      ╚═╝
*/

/// Smart contract library of mathematical functions operating with signed
/// 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
/// basically a simple fraction whose numerator is signed 128-bit integer and
/// denominator is 2^64.  As long as denominator is always the same, there is no
/// need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
/// represented by int128 type holding only the numerator.
/// @title  Math64x64.sol
/// @author Mikhail Vladimirov - ABDK Consulting
/// https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol
library Math64x64 {
    /* CONVERTERS
     ******************************************************************************************************************/
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev Convert signed 256-bit integer number into signed 64.64-bit fixed point
    /// number.  Revert on overflow.
    /// @param x signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 64-bit integer number rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64-bit integer number
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /// @dev Convert unsigned 256-bit integer number into signed 64.64-bit fixed point number.  Revert on overflow.
    /// @param x unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /// @dev Convert signed 64.64 fixed point number into unsigned 64-bit integer number rounding down.
    /// Reverts on underflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return unsigned 64-bit integer number
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /// @dev Convert signed 128.128 fixed point number into signed 64.64-bit fixed point number rounding down.
    /// Reverts on overflow.
    /// @param x signed 128.128-bin fixed point number
    /// @return signed 64.64-bit fixed point number
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Convert signed 64.64 fixed point number into signed 128.128 fixed point number.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 128.128 fixed point number
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /* OPERATIONS
     ******************************************************************************************************************/

    /// @dev Calculate x + y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x - y.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x///y rounding down.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
    /// number and y is signed 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y signed 256-bit integer number
    /// @return signed 256-bit integer number
    function muli(int128 x, int256 y) internal pure returns (int256) {
        //NOTE: This reverts if y == type(int128).min
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                        y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(absoluteResult <= 0x8000000000000000000000000000000000000000000000000000000000000000);
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                    return int256(absoluteResult);
                }
            }
        }
    }

    /// @dev Calculate x * y rounding down, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// @param x signed 64.64 fixed point number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 256-bit integer number
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /// @dev Calculate x / y rounding towards zero.  Revert on overflow or when y is zero.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are signed 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x signed 256-bit integer number
    /// @param y signed 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return signed 64.64-bit fixed point number
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /// @dev Calculate -x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /// @dev Calculate |x|.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /// @dev Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
    ///zero.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /// @dev Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
    /// Revert on overflow or in case x * y is negative.
    /// @param x signed 64.64-bit fixed point number
    /// @param y signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
            return int128(sqrtu(uint256(m)));
        }
    }

    /* Mikhail Vladimirov, [Jul 6, 2022 at 12:26:12 PM (Jul 6, 2022 at 12:28:29 PM)]:
        In simple words, when have an n-bits wide number x and raise it to a power α, then the result would be α*n bits wide.  This, if α<1, the result will loose precision, and if α>1, the result could exceed range.

        So, the pow function multiplies the result by 2^(n * (1 - α)).  We have:

        x ∈ [0; 2^n)
        x^α ∈ [0; 2^(α*n))
        x^α * 2^(n * (1 - α)) ∈ [0; 2^(α*n) * 2^(n * (1 - α))) = [0; 2^(α*n + n * (1 - α))) = [0; 2^(n * (α +  (1 - α)))) =  [0; 2^n)

        So the normalization returns the result back into the proper range.

        Now note, that:

        pow (pow (x, α), 1/α) =
        pow (x^α * 2^(n * (1 -α)) , 1/α) =
        (x^α * 2^(n * (1 -α)))^(1/α) * 2^(n * (1 -1/α)) =
        x^(α * (1/α)) * 2^(n * (1 -α) * (1/α)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1)) * 2^(n * (1 -1/α)) =
        x * 2^(n * (1/α -1) + n * (1 -1/α)) =
        x

        So, for formulas that look like:

        (a x^α + b y^α + ...)^(1/α)

        The pow function could be used instead of normal power. */
    /// @dev Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
    /// and y is unsigned 256-bit integer number.  Revert on overflow.
    /// also see:https://hackmd.io/gbnqA3gCTR6z-F0HHTxF-A#33-Normalized-Fractional-Exponentiation
    /// @param x signed 64.64-bit fixed point number
    /// @param y uint256 value
    /// @return signed 64.64-bit fixed point number
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down.  Revert if x < 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /// @dev Calculate binary logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /// @dev Calculate natural logarithm of x.  Revert if x <= 0.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return int128(int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128));
        }
    }

    /// @dev Calculate binary exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x4000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            if (x & 0x2000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            if (x & 0x1000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            if (x & 0x800000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            if (x & 0x400000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            if (x & 0x200000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            if (x & 0x100000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            if (x & 0x80000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            if (x & 0x40000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            if (x & 0x20000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            if (x & 0x10000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            if (x & 0x8000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            if (x & 0x4000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            if (x & 0x2000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            if (x & 0x1000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /// @dev Calculate natural exponent of x.  Revert on overflow.
    /// @param x signed 64.64-bit fixed point number
    /// @return signed 64.64-bit fixed point number
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /// @dev Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
    /// integer numbers.  Revert on overflow or when y is zero.
    /// @param x unsigned 256-bit integer number
    /// @param y unsigned 256-bit integer number
    /// @return unsigned 64.64-bit fixed point number
    function divuu(uint256 x, uint256 y) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
            else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /// @dev Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer number.
    /// @param x unsigned 256-bit integer number
    /// @return unsigned 128-bit integer number
    function sqrtu(uint256 x) internal pure returns (uint128) {
        // ^^ changed visibility from private to internal for testing

        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU256U128 {
    /// @dev Safely cast an uint256 to an uint128
    function u128(uint256 x) internal pure returns (uint128 y) {
        require (x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;


library CastU128I128 {
    /// @dev Safely cast an uint128 to an int128
    function i128(uint128 x) internal pure returns (int128 y) {
        require (x <= uint128(type(int128).max), "Cast overflow");
        y = int128(x);
    }
}