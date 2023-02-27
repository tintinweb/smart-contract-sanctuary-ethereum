// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract BSCPaymentSplitter is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Reentrancy Guard
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // Deprecated. It exists only for upgradability.
    mapping(string => address) private symAddrMap;
    // Remaining balance of escrow for each asset
    /// @custom:oz-renamed-from _escrowBalances
    mapping(address => uint256) public escrowBalances;
    // Remaining balance of gas fee that is used to send escrow
    /// @custom:oz-renamed-from _gasFee
    uint256 public gasFee;
    // Remaining balance of pip fee
    /// @custom:oz-renamed-from _pipFees
    mapping(address => uint256) public pipFees;
    // Deprecated. It exists only for upgradability.
    uint256 private _intMax;
    // Deprecated. It exists only for upgradability. 
    address private _owner;
    // Address of Admin #1 to which gasfee will be withdrawn.
    /// @custom:oz-renamed-from _gasFeeAddress
    address public gasFeeAddress;
    // Address of Admin #2 to which pipfee will be withdrawn.
    /// @custom:oz-renamed-from _pipFeeAddress
    address public pipFeeAddress;
    // Deprecated. It exists only for upgradability.
    address private _pipAdminAddress;
    // Key for BNB used in pipFees and escrowBalances
    // @custom:oz-renamed-from wbnb
    address private forBnb;
    // Whitelist for PIP Service. The Token in whitelist is Non Tax Token.
    /// @custom:oz-renamed-from grantee
    mapping(address => bool) public tokenWhitelist;
    // The fee rate about tip amount
    uint256 public pipFeeRatio;
    // The gas fee amount when sender send tip for escrow 
    uint256 public gasFeeAmount;
    // Tokens with decimals other than 18
    mapping(address => uint8) public tokenDecimals;

    event FeeAddressChanged(
        string feeType,
        address indexed prevAddr,
        address indexed newAddr
    );
    event ReceiveAsset(
        string receiveType,
        address indexed toContract,
        address indexed recipient,
        uint256 sendAmount,
        uint256 feeAmount,
        uint256 gasAmount
    );
    event SendAsset(
        string sendType,
        address toContract,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event SendDirect(
        string sendMsg,
        address indexed toContract,
        address indexed from,
        address indexed to,
        uint256 tipAmount,
        uint256 feeAmount
    );
    event PipService(
        address indexed toContract,
        address indexed from,
        address indexed to,
        uint256 amount,
        string payload
    );

    event Transfer(
        string transferType,  // ESCROW, INSTANT
        address indexed sender,
        address indexed receiver,
        address token,
        uint256 amount,
        uint256 serviceFee,
        uint256 escrowGas,
        string payload
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        pipFeeAddress = address(0);
        gasFeeAddress = address(0);
        _status = _NOT_ENTERED;
        _intMax = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        // Unique address used as a key to point to the BNB balance
        forBnb = 0x5ACbf3E2715D95D56d472eBE660106791C8E0C9e;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyAdmin() {
        require(
            msg.sender == owner() 
                || (msg.sender == gasFeeAddress && gasFeeAddress != address(0)) 
                || (msg.sender == pipFeeAddress && pipFeeAddress != address(0)),
             "Only Allowed to Admin"
        );
        _;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReEntrancyGuard : ReEntrant Call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    // Check The Token is Whitelisted token
    // @token : The token address for handling in this contract
    modifier onlyWhitelisted(address token) {
        require(tokenWhitelist[token], "Only Allowed to Token in Whitelist");
        _;
    }

    // Calculate fee amount with entered tipAmount and feeRatio
    // @tipAmount : The tip amount
    // @feeRatio : The fee ratio
    function _calculateFeeAmount(uint256 tipAmount, uint256 feeRatio, uint8 decimals) public pure returns (uint256) {
        require(decimals <= 76, "_calculateFeeAmount(): Decimal can not be bigger than 76");

        uint256 feeAmount = (tipAmount * feeRatio) / (100 - feeRatio);
        if (decimals > 8) {
            uint8 roundDownDecimals = decimals - 8;
            return (feeAmount / 10 ** roundDownDecimals) * (10 ** roundDownDecimals);
        }
        else 
          return feeAmount;
    }

    // Transfer token and assert if the receiver's balance has increased by the amount transfered.
    // @token : The contract address of token to transfer
    // @from : The address of Sender
    // @to : The address of Receiver
    // @amount : The amount of token transfer
    function safeTransferFromAndCheckBalance(address token, address from, address to, uint256 amount) internal {
        IERC20Upgradeable tokenObject = IERC20Upgradeable(token);
        uint256 initialBalance = tokenObject.balanceOf(to);
        tokenObject.safeTransferFrom(from, to, amount);
        uint256 afterBalance = tokenObject.balanceOf(to);
        require(from == to ? (afterBalance - initialBalance == 0) : (afterBalance - initialBalance == amount), "safeTransferFromAndCheckBalance(): transferred amount is incorrect");
    }

    // Replace the address of gasfee
    // @feeAddress: Address of Admin #1 to which gasfee will be withdrawn.
    function setGasFeeAddress(address feeAddress) external onlyAdmin {
        require(feeAddress != gasFeeAddress, "SetGasFeeAddress : The new address is the same as the old one");

        emit FeeAddressChanged("gasFee", gasFeeAddress, feeAddress);
        gasFeeAddress = feeAddress;
    }

    // Return the address of gasfee
    function getGasFeeAddress() external view returns (address) {
        return gasFeeAddress;
    }

    // Replace the address of pipfee
    // @feeAddress: Address of Admin #2 to which pipfee will be withdrawn.
    function setPipFeeAddress(address feeAddress) external onlyAdmin {
        require(feeAddress != pipFeeAddress, "SetPipFeeAddress : The new address is the same as the old one");

        emit FeeAddressChanged("pipFee", pipFeeAddress, feeAddress);
        pipFeeAddress = feeAddress;
    }

    // Return the address of gasfee
    function getPipFeeAddress() external view returns (address) {
        return pipFeeAddress;
    }

    // Replace the value of pip fee ratio
    // @ratio : Ratio of pip fee for tip
    function setPipFeeRatio(uint256 ratio) external onlyAdmin {
        require(ratio > 0, "SetPipFeeRatio : The Ratio Value is only for positive value");
        require(ratio < 100, "SetPipFeeRatio: The Ratio can not be equal to nor bigger than 100");
        require(ratio != pipFeeRatio, "SetPipFeeRatio : The new ratio value is same with old ratio value");
        pipFeeRatio = ratio;
    }

    // Return the value of pip fee ratio
    function getPipFeeRatio() external view returns (uint256) {
        return pipFeeRatio;
    }

    // Replace the amount of gas fee
    // @feeAmount : The amount of gas fee
    function setGasFeeAmount(uint256 feeAmount) external onlyAdmin {
        require(feeAmount > 0, "SetGasFeeAmount : The gas fee amount is only for positive amount");
        require(feeAmount < 100000000000000000000, "SetGasFeeAmount : The gas fee amount cat not be bigger than 100 BNB");
        require(feeAmount != gasFeeAmount, "SetGasFeeAmount : The new gas fee amount is same with old gas fee amount");
        gasFeeAmount = feeAmount;
    }

    // Return the amount of gas fee
    function getGasFeeAmount() external view returns (uint256) {
        return gasFeeAmount;
    }

    // Add the token to whitelist, or Remove from the whitelist
    // @token : The contract address to add/remove for whitelist
    // @value : true - add to whitelist, false - remove from whitelist
    function setTokenWhitelist(address token, bool value) external onlyAdmin {
        require(tokenWhitelist[token] != value, "SetTokenWhitelist : The new value is already same with the old value");
        tokenWhitelist[token] = value;
    }

    // Return whether the token is whitelisted token
    function getTokenWhitelist(address token) external view returns (bool) {
        require(token.isContract(), "GetTokenWhitelist : Address is not Contract Address" );
        return tokenWhitelist[token];
    }

    // Return the balance of gasfee
    function chkGasFee() external view returns (uint256) {
        return gasFee;
    }

    // Return the balance of pipfee of the specified asset
    // @target: The contract address of the asset
    function chkPipFee(address token) external view onlyWhitelisted(token) returns (uint256) {
        return pipFees[token];
    }

    // Return the balance of escrow of the specified asset
    // @target: The contract address of the asset
    function chkEscrowBalance(address token) external view onlyWhitelisted(token) returns (uint256) {
        return escrowBalances[token];
    }

    // Set the decimals of a token
    // @address: The contract address of the asset
    // @decimals: Decimals of a token
    function setTokenDecimals(address token, uint8 decimals) external onlyAdmin {
        tokenDecimals[token] = decimals;
    }

    // Get the decimals of a token
    // @address: The contract address of the asset
    function getTokenDecimals(address token) public view returns (uint8) {
        require(token.isContract(), "_getTokenDecimal(): Token must be a Contract");

        if (tokenDecimals[token] > 0) return tokenDecimals[token];
        else return 18;
    }    

    // Withdraw 'amount' of gasfee to the specified address
    // @to: The address to receive the withdrawn gasfee. it should be Admin
    // @amount: The amount to be withdrawn
    function withdrawGasFee(uint256 amount) external nonReentrant onlyAdmin {
        require(gasFeeAddress != address(0), "Withdraw Gas : Gas Fee Address Cannot be Zero-Address");
        require(amount <= gasFee, "Withdraw Gas: Amount must be less than Gas Balance");
        gasFee -= amount;

        payable(gasFeeAddress).transfer(amount);
        emit SendAsset("wGasFee", forBnb, address(this), gasFeeAddress, amount);
    }

    // Withdraw 'amount' of pipfee to the specified address
    // @symbol: The contract address of the asset to be withdrawn
    // @to: The address to receive the withdrawn pipfee. it should be Admin
    // @amount: The amount to be withdrawn
    function withdrawPipFee(address token, uint256 amount) external nonReentrant onlyAdmin onlyWhitelisted(token) {
        require(pipFeeAddress != address(0), "Withdraw Pip Fee : Pip Fee Address Cannot be Zero-Address");
        require(amount <= pipFees[token], "Withdraw Pip Fee: Required Pip Fee Amount must be less than Pip Fee Balance");

        pipFees[token] -= amount;
        if (token == forBnb) {
            payable(pipFeeAddress).transfer(amount);
        } else {
            IERC20Upgradeable tokenObject = IERC20Upgradeable(token);
            tokenObject.safeTransfer(pipFeeAddress, amount);
        }
        emit SendAsset("wPipFee", token, address(this), pipFeeAddress, amount);
    }

    // Send 'amount' of escrow to the specified address
    // @symbol: The contract address of the asset to be sent
    // @to: The address to receive the withdrawn balance
    // @amount: The amount to be sent
    function sendEscrow(address token, address payable to, uint256 amount) external nonReentrant onlyAdmin onlyWhitelisted(token) {
        require(to != address(0), "Send Escrow : Recipient Address cannot be zero-address");
        require((amount <= escrowBalances[token]) && (amount > 0), "Send Escrow : Required User Balance must be less than User Balance");

        escrowBalances[token] -= amount;
        if (token == forBnb) {
            // withdraw BNB (Native)
            to.transfer(amount);
            emit SendAsset("sEscrowNative", token, address(this), to, amount);
        } else {
            // withdraw Token
            IERC20Upgradeable tokenObject = IERC20Upgradeable(token);
            tokenObject.safeTransfer(to, amount);
            emit SendAsset("sEscrowToken", token, address(this), to, amount);
        }
    }

    // Deposit BNB
    // @isEscrow: If true the deposited balance is owned by the contract.
    //            If false the contract sends the balance to the recipient immediately
    // @recipient: If isEscrow is true, the address to receive the deposited asset
    //             If not, not used
    // @tipAmount: The asset amount to be sent to the receiver
    // @feeAmount: The asset amount to be sent to the service provider(= Admin)
    // @gasAmount: The network fee to be used when sending the escrow to the receiver
    function receiveNative(uint256 isEscrow, address payable recipient, uint256 amount, uint256 serviceFee, uint256 escrowGas) external payable nonReentrant {
        // require(msg.value == tipAmount + feeAmount + gasAmount, "Send Native: Tip, Fee, Gas Summation Not Equal to Sended msg.value");
        // require(recipient != address(0), "Send Native: Recipient Cannot be Zero Address");
        // require(tipAmount > 0, "Send Native: Send Amount Cannot be Negative");
        // require(feeAmount > 0, "Send Native: Fee Amount Cannot be Negative");

        // if (isEscrow == 1) {
        //     // gas > 0
        //     require(gasFeeAmount == gasAmount, "Send Native : Gas Amount is different");

        //     gasFee += gasAmount;
        //     pipFees[forBnb] += feeAmount;
        //     escrowBalances[forBnb] += tipAmount;
        //     emit ReceiveAsset("rEscrowNative", forBnb, recipient, tipAmount, feeAmount, gasAmount);
        // } else {
        //     require(gasAmount == 0, "Send Native: Gas amount should be 0 for non-escrow");

        //     recipient.transfer(tipAmount);
        //     pipFees[forBnb] += feeAmount;
        //     emit SendDirect("sDirectNative", forBnb, msg.sender, recipient, tipAmount, feeAmount);
        // }
        return _transferNative(isEscrow == 1, recipient, amount, serviceFee, escrowGas, "");
    }

    // Deposit token
    // @isEscrow: If true the deposited balance is owned by the contract.
    //            If false the contract sends the balance to the recipient immediately
    // @token: The contract address of the asset
    // @recipient: If isEscrow is true, the address to receive the deposited asset
    //             If not, not used
    // @tipAmount: The asset amount to be sent to the receiver
    // @feeAmount: The asset amount to be sent to the service provider(= Admin)
    // @gasAmount: The network fee to be used when sending the escrow to the receiver.
    function receiveToken(uint256 isEscrow, address token, address recipient, uint256 amount, uint256 serviceFee, uint256 escrowGas) external payable onlyWhitelisted(token) nonReentrant {
        // require(msg.value == gasAmount, "Send Token: Gas Not Equal to msg.value");
        // require(token.isContract(), "Send Token: Address is not Contract Address" );
        // require(recipient != address(0), "Send Token: Recipient Cannot be Zero Address");
        // require(tipAmount > 0, "Send Token: Send Amount Cannot be Negative");
        // require(feeAmount > 0, "Send Token: Fee Amount Cannot be Negative");

        // uint8 decimals = getTokenDecimals(token);

        // if (isEscrow == 1) {
        //     // Escrow
        //     // gas > 0
        //     require(gasFeeAmount == gasAmount, "Send Token : Gas Amount is different");
        //     safeTransferFromAndCheckBalance(token, msg.sender, address(this), tipAmount + feeAmount);
        //     gasFee += gasAmount;
        //     pipFees[token] += feeAmount;
        //     escrowBalances[token] += tipAmount;
        //     emit ReceiveAsset("rEscrowToken", token, recipient, tipAmount, feeAmount, gasAmount);
        // } else {
        //     // Direct
        //     // gas == 0
        //     require(gasAmount == 0, "Send Token: Gas amount should be 0 for non-escrow");
        //     safeTransferFromAndCheckBalance(token, msg.sender, recipient, tipAmount);
        //     safeTransferFromAndCheckBalance(token, msg.sender, address(this), feeAmount);
        //     pipFees[token] += feeAmount;
        //     emit SendDirect("sDirectToken", token, msg.sender, recipient, tipAmount, feeAmount);
        // }
        return _transferToken(isEscrow == 1, recipient, token, amount, serviceFee, escrowGas, "");
    }

    // Send BNB through PIP Service
    // @recipient: The Wallet address to receive funds through transaction execution
    // @amount: The asset amount to be sent to the recipient
    // @payload: The Data transmitted to be used by the server that detects the contract and receives the data, not used in the contract (Exchange rate at the time, remittance history ID, remittance service ID ... )
    function receiveNativeByPipService(address payable recipient, uint256 amount, string memory payload) external payable nonReentrant {
        // require(msg.value == amount, "rNativeByPipService: Amount Not Equal to Sended msg.value");
        // require(recipient != address(0), "rNativeByPipService: Recipient Cannot be Zero Address");
        // require(amount > 0, "rNativeByPipService: Amount Cannot be Negative");
        // recipient.transfer(amount);
        // emit PipService(forBnb, msg.sender, recipient, amount, payload);
        return _transferNative(false, recipient, amount, 0, 0, payload);
    }

    // Send BEP20 Token through PIP Service
    // @token: The contract address of the asset
    // @recipient: The Wallet address to receive funds through transaction execution
    // @amount: The asset amount to be sent to the recipient
    // @payload: The Data transmitted to be used by the server that detects the contract and receives the data, not used in the contract (Exchange rate at the time, remittance history ID, remittance service ID ... )
    function receiveTokenByPipService(address token, address recipient, uint256 amount, string memory payload) external onlyWhitelisted(token) nonReentrant {
        // require(token.isContract(), "rTokenByPipService: Address is not Contract Address");
        // require(recipient != address(0), "rTokenByPipService: Recipient Cannot be Zero Address");
        // require(amount > 0, "rTokenByPipService: Send Amount Cannot be Negative");
        // safeTransferFromAndCheckBalance(token, msg.sender, recipient, amount);
        // emit PipService(token, msg.sender, recipient, amount, payload);
        return _transferToken(false, recipient, token, amount, 0, 0, payload);
    }


    function _transferNative(bool isEscrow, address payable recipient, uint256 amount, uint256 serviceFee, uint256 escrowGas, string memory payload) internal {
        require(recipient != address(0), "_transferNative(): recipient with zero address is not allowed");
        require(amount > 0, "_transferNative(): amount should be greater than 0");
        require(serviceFee >= 0, "_transferNative(): serviceFee should be greater than or equal to 0");
        require(msg.value == amount + serviceFee + escrowGas, "_transferNative(): the sum of amount, serviceFee, and escrowGas is not equal to msg.value");

        if (isEscrow) {
            require(gasFeeAmount == escrowGas, "_transferNative(): escrowGas is not correct");

            gasFee += escrowGas;
            pipFees[forBnb] += serviceFee;
            escrowBalances[forBnb] += amount;

            emit Transfer("ESCROW", msg.sender, recipient, forBnb, amount, serviceFee, escrowGas, payload);
        } else {
            require(escrowGas == 0, "_transferNative(): escrowGas should be 0");

            recipient.transfer(amount);
            pipFees[forBnb] += serviceFee;

            emit Transfer("INSTANT", msg.sender, recipient, forBnb, amount, serviceFee, 0, payload);
        }
    }


    function _transferToken(bool isEscrow, address recipient, address token, uint256 amount, uint256 serviceFee, uint256 escrowGas, string memory payload) internal {
        require(recipient != address(0), "_transferToken(): recipient with zero address is not allowed");
        require(token.isContract(), "_transferToken(): token should be address type");
        require(amount > 0, "_transferToken(): amount should be greater than 0");
        require(serviceFee >= 0, "_transferToken(): serviceFee should be greater than or equal to 0");
        require(msg.value == escrowGas, "_transferToken(): escrowGas is not equal to msg.value");

        if (isEscrow) {
            require(gasFeeAmount == escrowGas, "_transferToken(): escrowGas is not correct");

            safeTransferFromAndCheckBalance(token, msg.sender, address(this), amount + serviceFee);
            gasFee += escrowGas;
            pipFees[token] += serviceFee;
            escrowBalances[token] += amount;

            emit Transfer("ESCROW", msg.sender, recipient, token, amount, serviceFee, escrowGas, payload);
        } else {
            require(escrowGas == 0, "_transferToken(): escrowGas should be 0");

            safeTransferFromAndCheckBalance(token, msg.sender, recipient, amount);
            safeTransferFromAndCheckBalance(token, msg.sender, address(this), serviceFee);
            pipFees[token] += serviceFee;

            emit Transfer("INSTANT", msg.sender, recipient, token, amount, serviceFee, 0, payload);
        }
    }

    // transfer native coin or tokens
    // @isEscrow: It sends to this contract if true.
    //            It sends to the recipient if false.
    // @recipient: If isEscrow is true, the address to receive the deposited asset
    //             If not, not used
    // @token: The address of token contract. It sends native coin if the token is forBnb, if not, it sends a token.
    // @amount: The amount of the asset to be sent to the receiver
    // @serviceFee: The asset amount to be sent to the service provider(= Admin)
    // @escrowGas: The network fee to be used when sending the escrow to the receiver
    // @payload: The payload data that pip service embeds so that pip server can recognize its context
    function transfer(bool isEscrow, address payable recipient, address token, uint256 amount, uint256 serviceFee, uint256 escrowGas, string memory payload) external payable onlyWhitelisted(token) nonReentrant {
        if (token == forBnb) {
          return _transferNative(isEscrow, recipient, amount, serviceFee, escrowGas, payload);
        } else {
          return _transferToken(isEscrow, recipient, token, amount, serviceFee, escrowGas, payload);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}