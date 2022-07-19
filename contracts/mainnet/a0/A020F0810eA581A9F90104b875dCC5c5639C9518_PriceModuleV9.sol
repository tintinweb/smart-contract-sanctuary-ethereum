// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./ChainlinkService.sol";
import "../interfaces/IPriceModule.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/curve/IAddressProvider.sol";
import "../interfaces/curve/IRegistry.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/yieldster/IYieldsterVault.sol";
import "../interfaces/compound/IUniswapAnchoredView.sol";
import "../interfaces/aave/Iatoken.sol";
import "../interfaces/convex/IConvex.sol";

contract PriceModuleV9 is ChainlinkService, Initializable {
    using SafeMath for uint256;

    address public priceModuleManager; // Address of the Price Module Manager
    address public curveAddressProvider; // Address of the Curve Address provider contract.
    address public uniswapAnchoredView; // Address of the Uniswap Anchored view. Used by Compound.

    struct Token {
        address feedAddress;
        uint256 tokenType;
        bool created;
    }

    mapping(address => Token) tokens; // Mapping from address to Token Information
    mapping(address => address) wrappedToUnderlying; // Mapping from wrapped token to underlying

    address public apContract;

    /// @dev Function to initialize priceModuleManager and curveAddressProvider.
    function initialize() public {
        priceModuleManager = msg.sender;
        curveAddressProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;
        uniswapAnchoredView = 0x65c816077C29b557BEE980ae3cC2dCE80204A0C5;
    }

    /// @dev Function to change the address of UniswapAnchoredView Address provider contract.
    /// @param _uniswapAnchoredView Address of new UniswapAnchoredView provider contract.
    function changeUniswapAnchoredView(address _uniswapAnchoredView) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        uniswapAnchoredView = _uniswapAnchoredView;
    }

    /// @dev Function to change the address of Curve Address provider contract.
    /// @param _crvAddressProvider Address of new Curve Address provider contract.
    function changeCurveAddressProvider(address _crvAddressProvider) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        curveAddressProvider = _crvAddressProvider;
    }

    /// @dev Function to set new Price Module Manager.
    /// @param _manager Address of new Manager.
    function setManager(address _manager) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        priceModuleManager = _manager;
    }

    /// @dev Function to add a token to Price Module.
    /// @param _tokenAddress Address of the token.
    /// @param _feedAddress Chainlink feed address of the token if it has a Chainlink price feed.
    /// @param _tokenType Type of token.
    function addToken(
        address _tokenAddress,
        address _feedAddress,
        uint256 _tokenType
    ) external {
        require(
            msg.sender == priceModuleManager || msg.sender == apContract,
            "Not Authorized"
        );
        Token memory newToken = Token({
            feedAddress: _feedAddress,
            tokenType: _tokenType,
            created: true
        });
        tokens[_tokenAddress] = newToken;
    }

    /// @dev Function to add tokens to Price Module in batch.
    /// @param _tokenAddress Address List of the tokens.
    /// @param _feedAddress Chainlink feed address list of the tokens if it has a Chainlink price feed.
    /// @param _tokenType Type of token list.
    function addTokenInBatches(
        address[] memory _tokenAddress,
        address[] memory _feedAddress,
        uint256[] memory _tokenType
    ) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            Token memory newToken = Token({
                feedAddress: address(_feedAddress[i]),
                tokenType: _tokenType[i],
                created: true
            });
            tokens[address(_tokenAddress[i])] = newToken;
        }
    }

    /// @dev Function to retrieve price of a token from Chainlink price feed.
    /// @param _feedAddress Chainlink feed address the tokens.
    function getPriceFromChainlink(address _feedAddress)
        internal
        view
        returns (uint256)
    {
        (int256 price, , uint8 decimals) = getLatestPrice(_feedAddress);
        if (decimals < 18) {
            return (uint256(price)).mul(10**uint256(18 - decimals));
        } else if (decimals > 18) {
            return (uint256(price)).div(uint256(decimals - 18));
        } else {
            return uint256(price);
        }
    }

    /// @dev Function to get price of a token.
    ///     Token Types
    ///     1 = Token with a Chainlink price feed.
    ///     2 = USD based Curve Liquidity Pool token.
    ///     3 = Yearn Vault Token.
    ///     4 = Yieldster Strategy Token.
    ///     5 = Yieldster Vault Token.
    ///     6 = Ether based Curve Liquidity Pool Token.
    ///     7 = Euro based Curve Liquidity Pool Token.
    ///     8 = BTC based Curve Liquidity Pool Token.
    ///     9 = Compound based Token.
    ///     12 = curve lp Token.

    /// @param _tokenAddress Address of the token..

    function getUSDPrice(address _tokenAddress) public view returns (uint256) {
        require(tokens[_tokenAddress].created, "Token not present");

        if (tokens[_tokenAddress].tokenType == 1) {
            return getPriceFromChainlink(tokens[_tokenAddress].feedAddress);
        } else if (tokens[_tokenAddress].tokenType == 2) {
            return
                IRegistry(IAddressProvider(curveAddressProvider).get_registry())
                    .get_virtual_price_from_lp_token(_tokenAddress);
        } else if (tokens[_tokenAddress].tokenType == 3) {
            address token = IVault(_tokenAddress).token();
            uint256 decimals = IVault(_tokenAddress).decimals();
            uint256 tokenPrice = getUSDPrice(token);
            uint256 price = (
                tokenPrice.mul(IVault(_tokenAddress).pricePerShare())
            ).div(1e18);

            if (decimals < 18) {
                return (uint256(price)).mul(10**uint256(18 - decimals));
            } else if (decimals > 18) {
                return (uint256(price)).div(uint256(decimals - 18));
            } else {
                return uint256(price);
            }
        } else if (tokens[_tokenAddress].tokenType == 5) {
            return IYieldsterVault(_tokenAddress).tokenValueInUSD();
        } else if (tokens[_tokenAddress].tokenType == 6) {
            uint256 priceInEther = getPriceFromChainlink(
                tokens[_tokenAddress].feedAddress
            );
            uint256 etherToUSD = getUSDPrice(
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            );
            return (priceInEther.mul(etherToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 7) {
            uint256 lpPriceEuro = IRegistry(
                IAddressProvider(curveAddressProvider).get_registry()
            ).get_virtual_price_from_lp_token(_tokenAddress);
            uint256 euroToUSD = getUSDPrice(
                address(0xb49f677943BC038e9857d61E7d053CaA2C1734C1) // Address representing Euro.
            );
            return (lpPriceEuro.mul(euroToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 8) {
            uint256 lpPriceBTC = IRegistry(
                IAddressProvider(curveAddressProvider).get_registry()
            ).get_virtual_price_from_lp_token(_tokenAddress);
            uint256 btcToUSD = getUSDPrice(
                address(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c) // Address representing BTC.
            );
            return (lpPriceBTC.mul(btcToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 9) {
            return
                IUniswapAnchoredView(uniswapAnchoredView).getUnderlyingPrice(
                    _tokenAddress
                ); // Address of cToken (compound )
        } else if (tokens[_tokenAddress].tokenType == 10) {
            address underlyingAsset = Iatoken(_tokenAddress)
                .UNDERLYING_ASSET_ADDRESS();
            return getUSDPrice(underlyingAsset);
            // Address of aToken (aave)
        } else if (tokens[_tokenAddress].tokenType == 11) {
            address underlyingAsset = wrappedToUnderlying[_tokenAddress];
            return getUSDPrice(underlyingAsset); // Address of generalized underlying token. Eg, Convex
        } else if (tokens[_tokenAddress].tokenType == 12) {
            return
                IConvex(tokens[_tokenAddress].feedAddress).get_virtual_price(); // get USD Price from pool contract
        } else if (tokens[_tokenAddress].tokenType == 13) {
            uint256 priceInEther = IConvex(tokens[_tokenAddress].feedAddress)
                .get_virtual_price();
            uint256 etherToUSD = getUSDPrice(
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            );
            return (priceInEther.mul(etherToUSD)).div(1e18);
        } else if (tokens[_tokenAddress].tokenType == 14) {
            //similar to type 8
            uint256 lpPriceBTC = IConvex(tokens[_tokenAddress].feedAddress)
                .get_virtual_price();
            uint256 btcToUSD = getUSDPrice(
                address(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c) // Address representing BTC.
            );
            return (lpPriceBTC.mul(btcToUSD)).div(1e18);
        } else revert("Token not present");
    }

    /// @dev Function to add wrapped token to Price Module
    /// @param _wrappedToken Address of wrapped token
    /// @param _underlying Address of underlying token
    function addWrappedToken(address _wrappedToken, address _underlying)
        external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        wrappedToUnderlying[_wrappedToken] = _underlying;
    }

    /// @dev Function to add wrapped token to Price Module in batches
    /// @param _wrappedTokens Address of wrapped tokens
    /// @param _underlyings Address of underlying tokens

    function addWrappedTokenInBatches(
        address[] memory _wrappedTokens,
        address[] memory _underlyings
    ) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        for (uint256 i = 0; i < _wrappedTokens.length; i++) {
            wrappedToUnderlying[address(_wrappedTokens[i])] = address(
                _underlyings[i]
            );
        }
    }

    function changeAPContract(address _apContract) external {
        require(msg.sender == priceModuleManager, "Not Authorized");
        apContract = _apContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

contract ChainlinkService {  
  
    function getLatestPrice(address feedAddress) 
        public 
        view 
        returns (int, uint, uint8) 
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        ( ,int price, ,uint timeStamp, ) = priceFeed.latestRoundData();
        uint8 decimal = priceFeed.decimals();
        return (price, timeStamp, decimal);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IYieldsterVault {
    function tokenValueInUSD() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRegistry {
    function get_virtual_price_from_lp_token(address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAddressProvider {
    function get_registry() external view returns (address);
    function get_address(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IConvex {
    function get_virtual_price()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IUniswapAnchoredView {
    function getUnderlyingPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface Iatoken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPriceModule {
    function getUSDPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

pragma solidity >=0.5.0;

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