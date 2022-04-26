/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Controller.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Controller.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity 0.8.7;

contract Ownable {
    bytes32 private constant ownerPosition = keccak256("owner.contract:2022");

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner(), "Caller not proxy owner");
        _;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view returns (address _owner) {
        bytes32 position = ownerPosition;
        assembly {
            _owner := sload(position)
        }
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner(), "New owner is the current owner");
        emit OwnershipTransferred(owner(), _newOwner);
        _setOwner(_newOwner);
    }

    function _setOwner(address _newOwner) internal {
        bytes32 position = ownerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
}



/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Controller.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity 0.8.7;

interface IController {
    function ttl() external view returns(uint256);
    function lockTime() external view returns(uint256);
    function minCollateralRatio() external view returns(uint16);
    function maxCollateralRatio() external view returns(uint16);
    function calculationDecimal() external pure returns(uint16);
    function discountRates(address) external view returns(uint16);
    function acceptedCollateral(address) external view returns(bool);
    function mintContract() external view returns(address);
    function lockContract() external view returns(address);
    function router() external view returns(address);
    function oracles(address) external view returns(address);
    function pools(address) external view returns(address);
    function collateralForToken(address) external view returns(address);
}



/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Controller.sol
*/
            
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}




/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Controller.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

////import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        return !AddressUpgradeable.isContract(address(this));
    }
}


/** 
 *  SourceUnit: c:\Users\ADMIN\Desktop\United-WorldEx-Contract\contracts\Controller.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
////import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
////import { IController } from "./interfaces/IController.sol";
////import { Ownable } from "./Ownable.sol";

contract Controller is IController, Ownable, Initializable {
    
    uint16 public override minCollateralRatio;
    uint16 public override maxCollateralRatio;
    uint16 public constant override calculationDecimal = 2;    

    uint256 public override ttl;
    uint256 public override lockTime;

    address public override mintContract;
    address public override lockContract;
    
    address public override router;

    // mapping token address to 
    mapping(address => address) public override oracles;

    // mapping token address to AMM pool address
    mapping(address => address) public override pools;
    
    // mapping listing token to collateral token
    mapping (address => address) public override collateralForToken;

    mapping(address => bool) public override acceptedCollateral;

    mapping(address => address) public tokenOwners;

    mapping(address => uint16) public override discountRates;

    event ListingToken(address indexed tokenAddress, uint256 timestamp);
    event DelistingToken(address indexed tokenAddress, uint256 timestamp);

    constructor() {}

    function initialize(uint16 _minCollateralRatio, uint16 _maxCollateralRatio, uint256 _ttl, address _router) external onlyOwner initializer{
        minCollateralRatio = _minCollateralRatio;
        maxCollateralRatio = _maxCollateralRatio;
        ttl = _ttl;
        router = _router;
    }

    function setMinCollateralRatio(uint16 _minCollateralRatio) external onlyOwner {
        minCollateralRatio = _minCollateralRatio;
    }

    function setMaxCollateralRatio(uint16 _maxCollateralRatio) external onlyOwner {
        maxCollateralRatio = _maxCollateralRatio;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function setTTL(uint256 _ttl) external onlyOwner {
        ttl = _ttl;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
    }

    function setMintContract(address _mintAddress) external onlyOwner {
        mintContract = _mintAddress;
    }

    function setLockContract(address _lockContract) external onlyOwner {
        lockContract = _lockContract;
    }

    function registerIDOToken(
        address tokenAddress,
        address oracleAddress,
        address poolAddress,
        address collateralToken,
        uint16 discountRate
    ) public onlyOwner {
        require(tokenAddress != collateralToken, "Duplicate token addresses");
        require(collateralForToken[tokenAddress] == address(0), "Token is already registered");
        require(acceptedCollateral[collateralToken], "Invalid colateral token");
        collateralForToken[tokenAddress] = collateralToken;
        address token0 = IUniswapV2Pair(poolAddress).token0();
        address token1 = IUniswapV2Pair(poolAddress).token1();
        require(token0 == tokenAddress || token1 == tokenAddress, "Missing token address");
        require(token0 == collateralToken || token1 == collateralToken, "Missing collateral address");
        pools[tokenAddress] = poolAddress;
        oracles[tokenAddress] = oracleAddress;
        tokenOwners[tokenAddress] = msg.sender;
        discountRates[tokenAddress] = discountRate;
        emit ListingToken(tokenAddress, block.timestamp);
    }

    function unregisterToken(address tokenAddress) public onlyOwner {
        require(collateralForToken[tokenAddress] != address(0), "Token have not been registered");
        collateralForToken[tokenAddress] = address(0);
        pools[tokenAddress] = address(0);
        oracles[tokenAddress] = address(0);
        tokenOwners[tokenAddress] = address(0);
        emit DelistingToken(tokenAddress, block.timestamp);
    }

    function updateIDOToken(
        address tokenAddress,
        address oracleAddress,
        address poolAddress,
        address collateralToken
    ) public onlyOwner {
        require(collateralForToken[tokenAddress] != address(0), "Token have not been registered");
        require(acceptedCollateral[collateralToken], "Invalid collateral token");
        pools[tokenAddress] = poolAddress;
        oracles[tokenAddress] = oracleAddress;
    }

    function registerCollateralAsset(address collateralAsset, bool value) public onlyOwner {
        acceptedCollateral[collateralAsset] = value;
    }
}