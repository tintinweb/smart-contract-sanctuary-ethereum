// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
pragma solidity ^0.8.10;

// import "./MeshPools.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface MeshGateway {
    function depositETH() external payable;

    function depositToken(uint256 amount) external;

    function withdrawETH(uint256 withdrawAmount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address pool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address pool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;

    function withdrawETHWithPermit(
        address pool,
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;
}

contract bWalletImpl is Initializable {
    address public owner;
    uint256 public nonce;
    event Received(address, uint256);
    event Sent(address, uint256);
    event Staked(address, uint256, bytes);
    event Replayed(address, uint256, uint256 fee);
    event FeeIncoming(address, uint256 finalAmt, uint256 fee);
    event StakedMesh(address, uint256 amount, address token, address pool);
    event StakedMeshMatic(address, uint256 amount);
    event StakedAave(address, uint256);
    mapping(address => uint256) public staked;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;
    mapping(address => mapping(address => uint256))
        public userStakedAmountERC20;
    address public bitsManager;
    address public _aEthWETHcontract;
    address public _aaveContract;
    address public iUSDCcontract;
    address public aaveLendingPool;
    address public aEthWETH;
    address public iWMatic;
    address public meshToken;
    address public meshSwapRouter;
    address public WrappedTokenGatewayV3;
    uint256 public bitsValue;
    uint256 public totalFee;
    uint256 public feez;

    IWETHGateway public aaveContract;
    MeshGateway public meshContract;

    IERC20 public aEthWETHcontract;

    mapping(address => uint256) public userStakedAmount;
    mapping(address => uint256) public userStakedAmountMesh;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(bitsManager == msg.sender, "Manager only");
        _;
    }

    // initialize the contract

    function initialize(address _owner) public initializer {
        owner = _owner;
        _aaveContract = 0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
        aaveContract = IWETHGateway(_aaveContract);
        aEthWETHcontract = IERC20(aEthWETH);

        bitsManager = 0x07f899CA879Ba85376D710fE448B88aF53049067;
        _aEthWETHcontract;
        _aaveContract;
        iUSDCcontract;
        aaveLendingPool = 0x7b5C526B7F8dfdff278b4a3e045083FBA4028790;
        aEthWETH = 0x7649e0d153752c556b8b23DB1f1D3d42993E83a5;
        iWMatic = 0xb880e6AdE8709969B9FD2501820e052581aC29Cf;
        meshToken = 0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a;
        meshSwapRouter = 0x10f4A785F458Bc144e3706575924889954946639;
        WrappedTokenGatewayV3 = 0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;

        feez = 85;

        address MESH = 0x6dBADf2a3e53885076f1D30B6198e560830cb4Bb; // token
        address iMESH = 0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a; // pool

        address WMATIC = 0xb880e6AdE8709969B9FD2501820e052581aC29Cf; // token
        address iWMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // pool

        address WETH = 0x865824C7ddF5a7486fe048bbBa2425D9c1F4903D; // token
        address iWETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; // pool

        address WBTC = 0xAf304d0371Ac4CB628aA7e7F0Ae46ddde1ECE1C0; // token
        address iWBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6; // pool

        address USDC = 0x590Cd248e16466F747e74D4cfa6C48f597059704; // token
        address iUSDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // pool

        address DAI = 0xbE068B517e869f59778B3a8303DF2B8c13E05d06; // token
        address iDAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // pool

        address USDT = 0x782D7eC740d997445D62e4463ce64C67c7484497; // token
        address iUSDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // pool

        address oXRP = 0xd84b86F415a251D30e5a42411D0c1149c181fF74; // token
        address ioXRP = 0xCc2a9051E904916047c26C90f41c000D4f273456; // pool

        address oKLAY = 0xB8578ffcECAac5df649bFBe8861Aea8c7803353A; // token
        address ioKLAY = 0x0A02D33031917d836Bd7Af02F9f7F6c74d67805F; // pool

        address oKSP = 0x0426858446eE2A1D9D26C32CD24f4F9C54d174AC; // token
        address ioKSP = 0x3D3B92Fe0B4c26b74F8fF13A32dD764F4DFD8b51; // pool

        address oORC = 0xeEe82264F10BB68E313599b47D6fbF2EAd7fbc4d; // token
        address ioORC = 0x12c9FFE6538f20A982FD4D17912f0ca00fA82D30; // pool

        address oMATIC = 0x29bFE37F639582bDa68567De97d485c7c41E5E34; // token
        address ioMATIC = 0x3f364853F01D32d581fc9734110B21C77AeEA024; // pool

        address MaticX = 0x00C3e7978Ede802d7ce6c6EfFfB4F05A4a806FD3; // token
        address iMaticX = 0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6; // pool

        address oTON = 0xE6c511Ed7549Cc1d6C1b23126D1653588C1C71bA; // token
        address ioTON = 0x4B96dBf8f42C8c296573933a6616dcAfb80Ca461; // pool

        address BUSD = 0x0E60e45b8083Ac694e3A5D863862Be67AbdaEcE7; // token
        address iBUSD = 0x9C9e5fD8bbc25984B178FdCE6117Defa39d2db39; // pool
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stakeETHAave() public payable {
        require(msg.value > 0, "You must send some ETH");
        // approve weth
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        approveWeth(WrappedTokenGatewayV3, maxUint);

        aaveContract.depositETH{value: msg.value}(
            aaveLendingPool,
            address(this),
            0
        );
        values[msg.sender] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit StakedAave(msg.sender, msg.value);
    }

    function stakeMeshswaMatic() public payable {
        require(msg.value > 0, "You must send some ETH");
        // approv wmatic
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        approveWMATIC(iWMatic, maxUint);

        meshContract.depositETH{value: msg.value}();
        values[msg.sender] = msg.value;
        userStakedAmountMesh[msg.sender] += msg.value;
        emit StakedMeshMatic(msg.sender, msg.value);
    }

    function stakeMeshERC20(
        uint256 amount,
        address token,
        address pool
    ) public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        IERC20(token).approve(pool, maxUint);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        userStakedAmountERC20[msg.sender][token] += amount;
        meshContract = MeshGateway(pool);
        meshContract.depositToken(amount);
        emit StakedMesh(msg.sender, amount, token, pool);
    }

    function updateFee(uint256 _feez) public onlyManager {
        feez = _feez;
    }

    function withdrawETHAave() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        aaveContract.withdrawETH(aaveLendingPool, maxUint, address(this));
    }

    function approveWMATIC(address spender, uint256 amount)
        public
        returns (bool)
    {
        aEthWETHcontract.approve(spender, amount);
        return true;
    }

    function approveWeth(address spender, uint256 amount)
        public
        returns (bool)
    {
        aEthWETHcontract.approve(spender, amount);
        return true;
    }

    function withdrawETHMesh() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        meshContract.withdrawETH(maxUint);
    }

    function send(address payable _to, uint256 _amount) external onlyManager {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        nonce += 1;
        emit Sent(_to, _amount);
    }

    function deposit() external payable {
        emit Received(msg.sender, msg.value);
    }

    function transferOwnership(address _newOwner) external onlyManager {
        owner = _newOwner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyManager {
        payable(msg.sender).transfer(address(this).balance);
        nonce += 1;
    }

    // function destroy(address payable recipient) public onlyManager {
    //     selfdestruct(recipient);
    // }

    function Stake(address payable _addr, bytes memory data) public payable {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );
        emit Staked(_addr, msg.value, data);
        require(success, string(returnData));
    }

    function BitsStaking(address payable _addr, bytes memory data)
        external
        payable
    {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );
        calls[_addr] = data;
        values[_addr] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit Staked(_addr, msg.value, data);
        require(success, string(returnData));
    }

    function unStake(address _aave, bytes memory data) external {
        (bool success, bytes memory returnData) = _aave.call(data);
        require(success, string(returnData));
    }

    function approveERC20Mesh(address _token, address pool) public {
        IERC20 token = IERC20(_token);
        token.approve(
            pool,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }

    function approveERC20Aave(address _token) public {
        IERC20 token = IERC20(_token);
        token.approve(
            aaveLendingPool,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }

    function SplitIt() public {
        uint256 _staked = userStakedAmount[msg.sender];
        uint256 feeValue = address(this).balance - _staked;
        uint256 fee = (feeValue * feez) / 100;
        uint256 _amount = feeValue - fee;
        uint256 finalAmount = _amount + _staked;
        userStakedAmount[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: finalAmount}("");
        require(sent, "Failed to send Ether");
        (bool sent2, ) = address(bitsManager).call{value: fee}("");
        require(sent2, "Failed to send Ether");
        emit FeeIncoming(msg.sender, finalAmount, feeValue);
        totalFee += feeValue;
    }

    function SplitItERC20(address _token, uint256 _staked) public {
        IERC20 token = IERC20(_token);
        uint256 feeValue = token.balanceOf(address(this)) - _staked;
        uint256 fee = (feeValue * feez) / 100;
        uint256 _amount = feeValue - fee;
        uint256 finalAmount = _amount + _staked;
        userStakedAmountERC20[msg.sender][_token] = 0;
        token.transfer(msg.sender, finalAmount);
        token.transfer(address(bitsManager), fee);
        emit FeeIncoming(msg.sender, finalAmount, feeValue);
        totalFee += feeValue;
    }

    function updateAave(address _aave) public onlyOwner {
        _aaveContract = _aave;
        aaveContract = IWETHGateway(_aave);
    }

    function updateAaveWETH(address _aaveWETH) public onlyOwner {
        aEthWETH = _aaveWETH;
        aEthWETHcontract = IERC20(aEthWETH);
    }

    function updateManager(address _bitsManager) public onlyOwner {
        bitsManager = _bitsManager;
    }

    function updateAaveLendingPool(address _aaveLendingPool) public onlyOwner {
        aaveLendingPool = _aaveLendingPool;
    }
}