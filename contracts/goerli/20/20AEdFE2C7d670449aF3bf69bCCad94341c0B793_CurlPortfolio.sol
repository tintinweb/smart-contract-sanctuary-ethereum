//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./CurlToken.sol";
import "./HxToken.sol";

/// @title CURL porfolio
/// @notice CURL uses portfolios instead of pairs to hold liquidity
/// @dev The portfolio pool holds base assets. They are Layer 2 synthetics
contract CurlPortfolio {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// The portfolio amounts. The Layer 2 token contract address is the key
    EnumerableMap.AddressToUintMap private amountPool;

    /// The portfolio weights. The Layer 2 token contract address is the key
    EnumerableMap.AddressToUintMap private weightPool;

    /// The hX token fee. CURL protocol fee for the hX tokens minting
    /// A fraction of 1
    uint256 private immutable tokenFee;

    // Sum of weights
    uint256 private immutable totalWeight;

    // W% min percentage of fee while withdrawing
    // expecting that Wmin come multiplying on hx.decimal().
    // For example, 1% = 0.01% will be 0.01*10^18=1*10^16
    uint256 private immutable minWithdrawPercent;

    // W%_max max percentage of fee while withdrawing
    // expecting that Wmin come multiplying on hx.decimal().
    // For example, 1% = 0.01% will be 0.01*10^18=1*10^16
    uint256 private immutable maxWithdrawPercent;

    /// softening factor for slippage phi
    /// See the `eta` variable in the white paper
    /// A fraction of 1
    uint256 private immutable slippageRatio;

    /// P% is the maximum percentage bonus one can receive
    /// This constant is set by the DAO
    /// A fraction of 1
    uint256 private immutable curlMaxBonus;

    /// Homogenized synthetic token contract
    HxToken private immutable hX;

    /// Project token (an incentive to keep portfolio balanced)
    CurlToken private immutable curl;

    // n is natural number. Used as a degree to obtain restrict parameter
    uint16 private immutable n;

    // k is natural number. Used as a degree to obtain slippage parameter
    uint16 private immutable k;

    struct PowPair {
        uint16 n;
        uint16 k;
    }

    /// @param tokens Layer 2 sinthetic token contract addresses
    /// @param amounts initial amount of x_i tokens
    /// @param weights weights for evere x_i token
    /// @param homogenizedToken Homogenized synthetic token contract
    /// @param curlToken the CURL protocol token
    /// @param tokenFeeHx the fee of the hX token minting (a fraction of 1)
    /// @param slippageAmplifier the slippage coefficient (a fraction of 1)
    /// @param maxBonus the CURL maximum percentage bonus (a fraction of 1)
    /// @param minWithdrawPercentConstant W% min percentage of fee while withdrawing
    /// @param minWithdrawPercentConstant W%_max max percentage of fee while withdrawing
    constructor(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory weights,
        HxToken homogenizedToken,
        CurlToken curlToken,
        uint256 tokenFeeHx,
        uint256 slippageAmplifier,
        uint256 maxBonus,
        uint256 minWithdrawPercentConstant,
        uint256 maxWithdrawPercentConstant,
        PowPair memory powPair
    ) {
        uint256 sumOfWeightMemory = 0;
        for (uint256 index = 0; index < tokens.length; index++) {
            amountPool.set(tokens[index], amounts[index]);
            weightPool.set(tokens[index], weights[index]);
            sumOfWeightMemory = sumOfWeightMemory + weights[index];
        }
        totalWeight = sumOfWeightMemory;

        hX = homogenizedToken;
        curl = curlToken;
        tokenFee = tokenFeeHx;
        slippageRatio = slippageAmplifier;
        curlMaxBonus = maxBonus;
        minWithdrawPercent = minWithdrawPercentConstant;
        maxWithdrawPercent = maxWithdrawPercentConstant;
        k = powPair.k;
        n = powPair.n;
    }

    /// Update weight of the token in the pool
    /// @param token Layer 2 token address
    /// @param value the natural number
    function setWeight(address token, uint256 value) external {
        weightPool.set(token, value);
    }

    /// Liquidity addition
    /// @param token The Layer 2 synthetic token with the Layer 1 underlying
    /// @param token E.g.: madUSDT, cUSDT, multiUSDT, etc.
    /// @param amount The token amount to put in the portfolio
    function deposit(address token, uint256 amount) external {
        require(amountPool.contains(token), "Portfolio has not such a token");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 slippage = getDepositSlippage(token, amount);

        uint256 hXamount = getHxAmountOnDeposit(amount, slippage);
        hX.mint(msg.sender, hXamount);

        uint256 curlAmount = getCurlAmountOnDeposit(hXamount, slippage);
        curl.mintCurl(msg.sender, curlAmount);

        uint256 total = amountPool.get(token) + amount;
        amountPool.set(token, total);
    }

    /// Calculate slippage (Phi) on deposit
    /// @dev See the CURL white paper for more info
    /// @param token The pool item token
    /// @param depositAmount Layer 2 token amount
    /// @return slippage the token amount minting slippage
    function getDepositSlippage(address token, uint256 depositAmount)
        private
        view
        returns (uint256)
    {
        uint256 totalValueLocked = calcTVL();
        uint256 tokenAmount = amountPool.get(token);
        uint256 equilibrium = equilibriumAmountOfTokens(
            token,
            totalValueLocked
        );

        uint256 sum = depositAmount + tokenAmount;
        if (sum < equilibrium) {
            return 0;
        } else {
            uint256 diff = sum - equilibrium;
            uint256 amplifier = calcAmplifier(tokenAmount, equilibrium);

            uint256 powedSlippage = powSlippage(diff, totalValueLocked);
            return (powedSlippage * amplifier) / 10**hX.decimals();
        }
    }

    /// Calculate the amount of $hX a liquidity provider will receive
    /// @dev See the CURL white paper for more info
    /// @param depositAmount Layer 2 token amount
    /// @param slippage the token amount minting slippage
    /// @return hXamount the amount of hX tokens
    function getHxAmountOnDeposit(uint256 depositAmount, uint256 slippage)
        private
        view
        returns (uint256)
    {
        uint256 amount;
        if (slippage > 0) {
            amount =
                (depositAmount * slippage) /
                (slippage + slippage**2 / 10**hX.decimals());
        } else {
            amount = depositAmount;
        }
        return amount - amount / tokenFee;
    }

    /// Calculate the amount of $CURL a liquidity provider will receive
    /// @dev See the CURL white paper for more info
    /// @param hXamount the hX token amount
    /// @param slippage the token amount minting slippage
    /// @return the amount of CURL tokens
    function getCurlAmountOnDeposit(uint256 hXamount, uint256 slippage)
        private
        view
        returns (uint256)
    {
        uint256 amount;
        if (slippage > 0) {
            amount =
                (hXamount * slippage) /
                (slippage + slippage**2 / 10**hX.decimals());
        } else {
            amount = hXamount;
        }
        return amount / curlMaxBonus;
    }

    error TokenNotInAmountPool(address specificToken);
    error InsufficientBalance(uint256 requested, uint256 available);
    error FewTokens(address token, uint256 available);

    /// Liqudity withdrawal
    /// @param token resulting token type e.g.: madUSDT, cUSDT, multiUSDT, etc.
    /// @param hXwithdrawal amount of token for withdrawal
    function withdraw(address token, uint256 hXwithdrawal) external {
        if (!amountPool.contains(token)) {
            revert TokenNotInAmountPool({specificToken: token});
        }
        uint256 availableHx = hX.balanceOf(msg.sender);
        if (availableHx < hXwithdrawal) {
            revert InsufficientBalance({
                requested: hXwithdrawal,
                available: availableHx
            });
        }
        uint256 currentTokenAmount = amountPool.get(token);
        uint256 amountOfRecievedTokens = calcAmountOfTokensForWithdraw(
            token,
            currentTokenAmount,
            hXwithdrawal
        );

        if (amountOfRecievedTokens == 0) {
            revert FewTokens({token: token, available: currentTokenAmount});
        }

        // In V3 version of whitepaper this is not possible
        // if (currentTokenAmount < amountOfRecievedTokens) {
        //     revert InsufficientBalance({
        //         requested: amountOfRecievedTokens,
        //         available: currentTokenAmount
        //     });
        // }

        hX.burn(msg.sender, hXwithdrawal);

        IERC20(token).transfer(msg.sender, amountOfRecievedTokens);

        uint256 newCurrentTokenAmount = currentTokenAmount -
            amountOfRecievedTokens;

        amountPool.set(token, newCurrentTokenAmount);
    }

    // Calculating amount of x_i type of i for hX amount
    /// @param token resulting token type e.g.: madUSDT, cUSDT, multiUSDT, etc.
    /// @param currentTokenAmount current amount of x_i tokens type of i in the pool
    /// @param hXwithdrawal amount of token for withdrawal
    /// @return amount of tokens for withdraw, exponent: 10**hx.decimal()
    function calcAmountOfTokensForWithdraw(
        address token,
        uint256 currentTokenAmount,
        uint256 hXwithdrawal
    ) private view returns (uint256) {
        uint256 withdrawalSlippage = calcWithdrawalSlippage(
            token,
            currentTokenAmount,
            hXwithdrawal
        );

        uint256 equilibriumStarAmount = equilibriumStar(
            hXwithdrawal,
            withdrawalSlippage
        );
        uint256 restrictParameter = calcRestrictParameter(
            equilibriumStarAmount,
            currentTokenAmount
        );
        return
            (restrictParameter * equilibriumStarAmount) / (10**hX.decimals());
    }

    // Calculation phi - slippage. phi must be >= 0.
    /// @param token - current amount of x_i tokens type of i in the pool
    /// @param currentTokenAmount - current amount of x_i tokens type of i in the pool
    /// @param hXwithdrawal - target amount of tokens for equilibrium of the system
    /// @return slippgae withdraw, exponent: 10**hX.decimal()*10**hX.decimal
    function calcWithdrawalSlippage(
        address token,
        uint256 currentTokenAmount,
        uint256 hXwithdrawal
    ) private view returns (uint256) {
        uint256 tvl = calcTVL();
        uint256 equilibriumTokenAmount = equilibriumAmountOfTokens(token, tvl);

        uint256 sum = hXwithdrawal + equilibriumTokenAmount;
        if (sum < currentTokenAmount) {
            return 0;
        } else {
            uint256 diff = sum - currentTokenAmount;
            uint256 amplifier = calcAmplifier(
                currentTokenAmount,
                equilibriumTokenAmount
            );
            uint256 powedSlippage = powSlippage(diff, tvl);
            return (powedSlippage * amplifier) / 10**hX.decimals();
        }
    }

    // exponent: 10**hX.decimal
    // The function raises a fraction first/second to the power of 2*k
    /// @param first - numerator
    /// @param second - denumerator
    /// @return (first/second)^(2*k), exponent: 10**hX.decimal
    function powSlippage(uint256 first, uint256 second)
        private
        view
        returns (uint256)
    {
        uint256 powedSlippage = 10**hX.decimals();

        for (uint256 index = 0; index < 2 * k; index++) {
            uint256 numerator = powedSlippage * first;
            powedSlippage = numerator / second;
        }
        return powedSlippage;
    }

    // Calculation of target token x_i type of i - x^0_i
    /// @param token type of token - i
    /// @return equilibrium amount of tokens type of i, exponent: 10**hX.deciml()
    function equilibriumAmountOfTokens(address token, uint256 tvl)
        private
        view
        returns (uint256)
    {
        uint256 weight = weightPool.get(token);

        return (weight * tvl) / totalWeight;
    }

    // Calculation sum of x_i from i = 1 to i = n OR
    /// @return The sum of tokens locked in the pool (TVL), exponent: 10**hx.decimal()
    function calcTVL() private view returns (uint256) {
        uint256 lengthPool = amountPool.length();
        uint256 tvl = 0;
        for (uint256 index = 0; index < lengthPool; index++) {
            (, uint256 specificToken) = amountPool.at(index);
            tvl += specificToken;
        }
        return tvl;
    }

    // Calculate softening factor (coefficient eta), using eta_0.
    /// @param currentTokenAmount - current amount of x_i tokens type of i in the pool
    /// @param equilibriumTokenAmount - ctarget token x_i type of i - x^0_i
    /// @return softening factor, exponent: 10**hX.decimal*10**hX.decimal
    function calcAmplifier(
        uint256 currentTokenAmount,
        uint256 equilibriumTokenAmount
    ) private view returns (uint256) {
        uint256 module = absDiff(currentTokenAmount, equilibriumTokenAmount);
        if (module == 0) {
            // if difference of currentTokenAmount and equilibriumTokenAmount equals zero, than eta equals 1.
            // but in this method the value returns like multiplying on currentTokenAmount
            return 10**hX.decimals() * slippageRatio;
        }

        uint256 qudraticSum = currentTokenAmount *
            currentTokenAmount +
            module *
            module;
        uint256 preAmplifier = (qudraticSum / currentTokenAmount) * slippageRatio;
        return (preAmplifier * 10**hX.decimals()) / currentTokenAmount;
    }

    // Calculation absolute value for the difference two positive number
    /// @return |first - second|, exponent: dim of input values
    function absDiff(uint256 first, uint256 second)
        private
        pure
        returns (uint256)
    {
        if (first < second) {
            return second - first;
        }
        return first - second;
    }

    // Calculation of approximate amount of requested token x_i type of i - x^0_i with using withdrawalSlippage
    /// @param hXwithdrawal amount of token for withdrawal
    /// @param withdrawalSlippage - slippage multiplyed on currentTokenAmount
    /// @return approximate amount of requested token x_i, exponent: 10**hX.decimal()
    function equilibriumStar(uint256 hXwithdrawal, uint256 withdrawalSlippage)
        private
        view
        returns (uint256)
    {
        uint256 withdrawalFeePercentage = calcWithdrawalFeePercentage(
            withdrawalSlippage
        );
        uint256 numerator = hXwithdrawal *
            (10**hX.decimals() - withdrawalFeePercentage);
        uint256 denominator = (10**hX.decimals() + withdrawalSlippage);
        return numerator / denominator;
    }

    // Calculation Withdrawal Fee frac of percentage. For example, 2% = 0.02 frac
    // removing extra multiplying on 10**hx.decimal()
    /// @param withdrawalSlippage - slappage. Multiplied by currentTokenAmount, multiplyed on currentTokenAmount
    /// @return withdrawal fee percentage, exponent: 10**hx.decimal()
    function calcWithdrawalFeePercentage(uint256 withdrawalSlippage)
        private
        view
        returns (uint256)
    {
        uint256 firstMin = (minWithdrawPercent *
            (10**hX.decimals() + withdrawalSlippage)) / 10**hX.decimals();
        if (firstMin < maxWithdrawPercent) {
            return firstMin;
        }
        return maxWithdrawPercent;
    }

    // Calculate parameter used to restrict users from draining some token from the pool
    /// @param equilibriumStarAmount - approximate amount of requested token x_i type of i - x^0_i with using withdrawalSlippage
    /// @param currentTokenAmount - current amount of x_i tokens type of i in the pool
    /// @return restrict parameter, exponent: 10**hX.decimal()
    function calcRestrictParameter(
        uint256 equilibriumStarAmount,
        uint256 currentTokenAmount
    ) private view returns (uint256) {
        if (equilibriumStarAmount >= currentTokenAmount) {
            return 0;
        }

        uint256 restrinctParameter = 10**hX.decimals();
        for (uint256 index = 0; index < 2 * n; index++) {
            uint256 numerator = restrinctParameter * equilibriumStarAmount;
            restrinctParameter = numerator / currentTokenAmount;
        }
        return 10**hX.decimals() - restrinctParameter;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Project token.
/// @notice Project token CURL is used for the payment for operations that broke balance in the portfolio
/// @dev CURL is an incentive to keep the portfolio balanced.
contract CurlToken is ERC20, Ownable {
    constructor(uint256 initialBalance) ERC20("Curl", "CURL") {
        _mint(msg.sender, initialBalance);
    }

    /// Mint more CURL
    /// @notice the CURL owner could mint more tokens
    /// @dev the owner's balance will be incresed by the specified amount
    /// @param account account to assign the tokens
    /// @param amount tokens to mint
    function mintCurl(address account, uint256 amount) public {
        // onlyOwner TODO
        _mint(account, amount);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Homogenized synthetic token (hX)
/// @notice hX is fungible with any asset comprising the underlying Curl pool
/// @dev hX is minted every time, LP bonds one’s base asset synthetic into a base asset pool.
/// @dev hX is (almost) always 1:1 exchangeable with any of the base asset synthetics
/// @dev hX is pegged to the base assets which it is minted to represent. For the purposes of this paper,
/// @dev we will assume that base assets are synthetics minted from USD stable coins, thus the value of hX should be exactly (or close to) $1
contract HxToken is ERC20, Ownable {
    /// the portfolio contract address
    address private portfolio;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialBalance
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialBalance);
    }

    /// Set up the portfolio for the token
    /// @param portfolioAddress the portfolio contract address
    function setPortfolio(address portfolioAddress) external onlyOwner {
        portfolio = portfolioAddress;
    }

    /// Mint more hX
    /// @notice you could mint more tokens from the CURL portfolio
    /// @dev assign the hX token to the CURL portfolio in advance
    /// @param account account to assign the tokens
    /// @param amount tokens to mint
    function mint(address account, uint256 amount) public {
        require(msg.sender != address(0), "Portfolio is not set");
        require(msg.sender == portfolio, "Invalid portfolio address");

        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(portfolio != address(0), "Portfolio is not set");
        require(msg.sender == portfolio, "Invalid portfolio address");
        require(balanceOf(account) >= amount, "Not enough hX");

        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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