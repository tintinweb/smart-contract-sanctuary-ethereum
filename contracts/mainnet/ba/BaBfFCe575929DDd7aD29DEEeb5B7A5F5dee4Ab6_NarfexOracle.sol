//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PancakeLibrary.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}

/// @title Oracle contract for Narfex Fiats and storage of commissions
/// @author Danil Sakhinov
/// @notice Fiat prices are regularly sent by the owner from the backend service
/// @notice Added bulk data acquisition functions
contract NarfexOracle is Ownable {
    using Address for address;

    struct Token {
        bool isFiat;
        bool isCustomCommission; // Use default commission on false
        bool isCustomReward; // Use defalt referral percent on false
        uint price; // USD price only for fiats
        uint reward; // Referral percent only for fiats
        int commission; // Commission percent with. Can be lower than zero
        uint transferFee; // Token transfer fee with 1000 decimals precision (20 for NRFX is 2%)
    }

    /// Calculated Token data
    struct TokenData {
        bool isFiat;
        int commission;
        uint price;
        uint reward;
        uint transferFee;
    }

    address[] public fiats; // List of tracked fiat stablecoins
    address[] public coins; // List of crypto tokens with different commission
    mapping (address => Token) public tokens;

    int defaultFiatCommission = 0; // Use as a commission if isCustomCommission = false for fiats
    int defaultCryptoCommission = 0; // Use as a commission if isCustomCommission = false for coins
    uint defaultReward = 0; // Use as a default referral percent if isCustomReward = false

    address public updater; // Updater account. Has rights for update prices
    address public USDT; // Tether address in current network

    event SetUpdater(address updaterAddress);

    /// @notice only factory owner and router have full access
    modifier canUpdate {
        require(_msgSender() == owner() || _msgSender() == updater, "You have no access");
        _;
    }

    constructor(address _USDT) {
        USDT = _USDT;
    }

    // Returns ratio
    function getPairRatio(address _token0, address _token1) internal view returns (uint) {
        IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(_token0, _token1));
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        return pair.token0() == _token0
            ? PancakeLibrary.getAmountOut(10**IERC20(_token0).decimals(), reserve0, reserve1)
            : PancakeLibrary.getAmountOut(10**IERC20(_token1).decimals(), reserve1, reserve0);
    }

    // Returns token USD price
    function getDEXPrice(address _address) internal view returns (uint) {
        return _address == USDT
            ? 10**IERC20(USDT).decimals()
            : getPairRatio(_address, USDT);
    }

    /// @notice Returns token USD price for fiats and coins both
    /// @param _address Token address
    /// @return USD price
    function getPrice(address _address) public view returns (uint) {
        Token storage token = tokens[_address];
        return token.isFiat
            ? token.price
            : getDEXPrice(_address);
    }

    /// @notice Returns token USD price for many tokens
    /// @param _tokens Tokens addresses
    /// @return USD prices array with 18 digits of precision
    function getPrices(address[] calldata _tokens) public view returns (uint[] memory) {
        uint length = _tokens.length;
        uint[] memory response = new uint[](length);
        for (uint i = 0; i < length; i++) {
            response[i] = getPrice(_tokens[i]);
        }
        return response;
    }

    /// @notice Returns address balances for many tokens
    /// @param _address Wallet address
    /// @param _tokens Tokens addresses
    /// @return Balances
    function getBalances(address _address, address[] calldata _tokens) public view returns (uint[] memory) {
        uint length = _tokens.length;
        uint[] memory response = new uint[](length);
        for (uint i = 0; i < length; i++) {
            response[i] = IERC20(_tokens[i]).balanceOf(_address);
        }
        return response;
    }

    /// @notice Returns true if given token is Narfex Fiat
    /// @param _address Token address
    /// @return Token.isFiat value
    function getIsFiat(address _address) public view returns (bool) {
        return tokens[_address].isFiat;
    }

    /// @notice Returns token commission
    /// @param _address Token address
    /// @return Commission - multiplier with 1000 digits of precision
    function getCommission(address _address) public view returns (int) {
        Token storage token = tokens[_address];
        if (token.isCustomCommission) {
            return token.commission;
        } else {
            return token.isFiat
                ? defaultFiatCommission
                : defaultCryptoCommission;
        }
    }

    /// @notice Returns token transfer fee
    /// @param _address Token address
    /// @return Fee with 1000 digits of precision
    function getTokenTransferFee(address _address) public view returns (uint) {
        return tokens[_address].transferFee;
    }

    /// @notice Returns fiat commission
    /// @param _address Token address
    /// @return Commission - multiplier with 1000 digits of precision
    function getReferralPercent(address _address) public view returns (uint) {
        Token storage token = tokens[_address];
        if (token.isFiat) {
            return token.isCustomReward
                ? token.reward
                : defaultReward;
        } else {
            return 0;
        }
    }

    /// @notice Returns array of Narfex Fiats addresses
    /// @return Array of fiats addresses
    function getFiats() public view returns (address[] memory) {
        return fiats;
    }

    /// @notice Returns array of Coins addresses with different commissions
    /// @return Array of coins addresses
    function getCoins() public view returns (address[] memory) {
        return coins;
    }

    /// @notice Returns array of all known tokens to manage commissions
    /// @return Array of tokens addresses
    function getAllTokens() public view returns (address[] memory) {
        uint fiatsLength = fiats.length;
        uint coinsLength = coins.length;
        address[] memory responseTokens = new address[](fiatsLength + coinsLength);
        for (uint i = 0; i < fiatsLength; i++) {
            responseTokens[i] = fiats[i];
        }
        for (uint i = 0; i < coinsLength; i++) {
            responseTokens[fiatsLength + i] = coins[i];
        }
        return responseTokens;
    }

    /// @notice Returns all commissions and rewards data
    /// @return Default fiat commission
    /// @return Default coin commission
    /// @return Default referral reward percent
    /// @return Array of Token structs
    function getSettings() public view returns (
        int,
        int,
        uint,
        Token[] memory
        ) {
        address[] memory allTokens = getAllTokens();
        uint length = allTokens.length;
        Token[] memory responseTokens = new Token[](length);
        for (uint i; i < length; i++) {
            responseTokens[i] = tokens[allTokens[i]];
        }

        return (
            defaultFiatCommission,
            defaultCryptoCommission,
            defaultReward,
            responseTokens
        );
    }

    /// @notice Returns calculated Token data
    /// @param _address Token address
    /// @param _skipCoinPrice Allow to skip external calls for non-fiats
    /// @return tokenData Struct
    function getTokenData(address _address, bool _skipCoinPrice)
        public view returns (TokenData memory tokenData)
    {
        tokenData.isFiat = getIsFiat(_address);
        tokenData.commission = getCommission(_address);
        tokenData.price = !tokenData.isFiat && _skipCoinPrice
            ? 0
            : getPrice(_address);
        tokenData.reward = getReferralPercent(_address);
        tokenData.transferFee = getTokenTransferFee(_address);
    }

    /// @notice Returns calculates Token data for many tokens
    /// @param _tokens Array of addresses
    /// @param _skipCoinPrice Allow to skip external calls for non-fiats
    /// @return Array of TokenData structs
    function getTokensData(address[] calldata _tokens, bool _skipCoinPrice)
        public view returns (TokenData[] memory)
    {
        TokenData[] memory response = new TokenData[](_tokens.length);
        for (uint i; i < _tokens.length; i++) {
            response[i] = getTokenData(_tokens[i], _skipCoinPrice);
        }
        return response;
    }

    /// @notice Set updater account address
    /// @param _updaterAddress Account address
    function setUpdater(address _updaterAddress) public onlyOwner {
        updater = _updaterAddress;
        emit SetUpdater(_updaterAddress);
    }

    /// @notice Update single fiat price
    /// @param _address Token address
    /// @param _price Fiat price - unsigned number with 18 digits of precision
    /// @dev Only owner can manage prices
    function updatePrice(address _address, uint _price) public canUpdate {
        Token storage token = tokens[_address];
        if (token.price != _price) {
            token.price = _price;
        }
        if (!token.isFiat) {
            token.isFiat = true;
            fiats.push(_address);
        }
    }

    /// @notice Update many fiats prices
    /// @param _fiats Array of tokens addresses
    /// @param _prices Fiats prices array - unsigned numbers with 18 digits of precision
    /// @dev Only owner can manage prices
    function updatePrices(address[] calldata _fiats, uint[] calldata _prices) public canUpdate {
        require (_fiats.length == _prices.length, "Data lengths do not match");
        for (uint i = 0; i < _fiats.length; i++) {
            updatePrice(_fiats[i], _prices[i]);
        }
    }

    /// @notice Remove the fiat mark from the token
    /// @param _address Token address
    /// @dev Only owner can use it
    /// @dev Necessary for rare cases, if for some reason the token got into the fiats list
    function removeTokenFromFiats(address _address) public onlyOwner {
        Token storage token = tokens[_address];
        require (token.isFiat, "Token is not fiat");
        token.isFiat = false;
        for (uint i = 0; i < fiats.length; i++) {
            if (_address == fiats[i]) {
                delete fiats[i];
                break;
            }
        }
    }

    /// @notice Remove the token from the coins list
    /// @param _address Token address
    /// @dev Only owner can use it
    function removeTokenFromCoins(address _address) public onlyOwner {
        for (uint i = 0; i < coins.length; i++) {
            if (_address == coins[i]) {
                delete coins[i];
                break;
            }
        }
    }

    /// @notice Set transfer fee percent for token
    /// @param _address Token address
    /// @param _fee Fee percent with 1000 decimals precision (20 = 2%)
    function setTokenTransferFee(address _address, uint _fee) public onlyOwner {
        Token storage token = tokens[_address];
        token.transferFee = _fee;
    }

    /// @notice Update default commissions and reward values
    /// @param _fiatCommission Default fiat commission
    /// @param _cryptoCommission Default coin commission
    /// @param _reward Default referral reward percent
    /// @dev Only owner can use it
    function updateDefaultSettings(
        int _fiatCommission,
        int _cryptoCommission,
        uint _reward
        ) public onlyOwner {
        defaultFiatCommission = _fiatCommission;
        defaultCryptoCommission = _cryptoCommission;
        defaultReward = _reward;
    }

    /// @notice Update tokens commissions
    /// @param tokensToCustom Array of tokens addresses which should stop using the default value
    /// @param tokensToDefault Array of tokens addresses which should start using the default value
    /// @param tokensChanged Array of tokens addresses that will receive changes
    /// @param newValues An array of commissions corresponding to an array of tokens
    /// @dev Only owner can use it
    function updateCommissions(
        address[] calldata tokensToCustom,
        address[] calldata tokensToDefault,
        address[] calldata tokensChanged,
        int[] calldata newValues
        ) public onlyOwner {
            require (tokensChanged.length == newValues.length, "Changed tokens length do not match values length");
            for (uint i = 0; i < tokensToCustom.length; i++) {
                Token storage token = tokens[tokensToCustom[i]];
                token.isCustomCommission = true;
                if (!token.isFiat) {
                    coins.push(tokensToCustom[i]);
                }
            }
            for (uint i = 0; i < tokensToDefault.length; i++) {
                Token storage token = tokens[tokensToCustom[i]];
                token.isCustomCommission = false;
                if (!token.isFiat) {
                    removeTokenFromCoins(tokensToDefault[i]);
                }
            }
            for (uint i = 0; i < tokensChanged.length; i++) {
                tokens[tokensToCustom[i]].commission = newValues[i];
            }
        }

    /// @notice Update default values and tokens commissions by one request
    /// @param _defaultFiatCommission Default fiat commission
    /// @param _defaultCryptoCommission Default coin commission
    /// @param _defaultReward Default referral reward percent
    /// @param tokensToCustom Array of tokens addresses which should stop using the default value
    /// @param tokensToDefault Array of tokens addresses which should start using the default value
    /// @param tokensChanged Array of tokens addresses that will receive changes
    /// @param newValues An array of commissions corresponding to an array of tokens
    /// @dev Only owner can use it
    function updateAllCommissions(
        int _defaultFiatCommission,
        int _defaultCryptoCommission,
        uint _defaultReward,
        address[] calldata tokensToCustom,
        address[] calldata tokensToDefault,
        address[] calldata tokensChanged,
        int[] calldata newValues
    ) public onlyOwner {
        updateCommissions(tokensToCustom, tokensToDefault, tokensChanged, newValues);
        updateDefaultSettings(_defaultFiatCommission, _defaultCryptoCommission, _defaultReward);
    }

    /// @notice Update referral rewards percents for many fiats
    /// @param tokensToCustom Array of tokens addresses which should stop using the default value
    /// @param tokensToDefault Array of tokens addresses which should start using the default value
    /// @param tokensChanged Array of tokens addresses that will receive changes
    /// @param newValues An array of percents corresponding to an array of tokens
    /// @dev Only owner can use it
    function updateReferralPercents(
        address[] calldata tokensToCustom,
        address[] calldata tokensToDefault,
        address[] calldata tokensChanged,
        uint[] calldata newValues
        ) public onlyOwner {
            require (tokensChanged.length == newValues.length, "Changed tokens length do not match values length");
            for (uint i = 0; i < tokensToCustom.length; i++) {
                tokens[tokensToCustom[i]].isCustomReward = true;
            }
            for (uint i = 0; i < tokensToDefault.length; i++) {
                tokens[tokensToCustom[i]].isCustomReward = false;
            }
            for (uint i = 0; i < tokensChanged.length; i++) {
                tokens[tokensToCustom[i]].reward = newValues[i];
            }
        }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPancakePair {
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

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

library PancakeLibrary {

    /// @notice Returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA First token address
    /// @param tokenB Second token address
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    /// @notice Calculates address for a pair without making any external calls
    /// @param tokenA First token address
    /// @param tokenB Second token address
    function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        /// ETH data
        bytes memory factory = hex'5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
        bytes memory initCodeHash = hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f';
        if (block.chainid == 56) { /// BSC
            factory = hex'cA143Ce32Fe78f1f7019d7d551a6402fC5350c73';
            initCodeHash = hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5';
        }
        if (block.chainid == 97) { /// BSC testnet
            factory = hex'b7926c0430afb07aa7defde6da862ae0bde767bc';
            initCodeHash = hex'ecba335299a6693cb2ebc4782e74669b84290b6378ea3a3873c7231a8d7d1074';
        }
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                initCodeHash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal view returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint pancakeCommission = 9970; /// ETH commission
        if (block.chainid == 56) {
            pancakeCommission = 9975; /// BSC commission
        }
        if (block.chainid == 97) {
            pancakeCommission = 9980; /// BSC testnet commission
        }
        uint amountInWithFee = amountIn * pancakeCommission;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal view returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint pancakeCommission = 9970; /// ETH commission
        if (block.chainid == 56) {
            pancakeCommission = 9975; /// BSC commission
        }
        if (block.chainid == 97) {
            pancakeCommission = 9980; /// BSC testnet commission
        }
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * pancakeCommission;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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