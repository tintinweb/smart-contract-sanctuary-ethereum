// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface OptimisticOracleV2Interface {
    function requestPrice(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        IERC20 currency,
        uint256 reward
    ) external returns (uint256 totalBond);

    function setCustomLiveness(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 customLiveness
    ) external;

    function setBond(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        uint256 bond
    ) external returns (uint256 totalBond);

    function proposePriceFor(
        address proposer,
        address requester,
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 proposedPrice
    ) external returns (uint256 totalBond);

    function setCallbacks(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        bool callbackOnPriceProposed,
        bool callbackOnPriceDisputed,
        bool callbackOnPriceSettled
    ) external;
}

contract Decentralist is Initializable {
    bytes public fixedAncillaryData;
    string public title;
    uint256 public livenessPeriod;
    uint256 public bondAmount;
    uint256 public addReward;
    uint256 public removeReward;
    address[] private listArray;
    mapping(address => bool) public listMapping;

    struct SingleRequest {
        address pendingAddress;
        int256 proposedPrice;
        address proposer;
    }
    mapping(bytes => SingleRequest) private singleRequests;

    struct MultipleRequest {
        uint256 pendingAddressesKey;
        int256 proposedPrice;
        address proposer;
    }
    mapping(bytes => MultipleRequest) private multipleRequests;
    mapping(uint256 => address[]) private pendingAddresses;
    uint256 private pendingAddressesCounter = 1;

    bytes32 public constant priceId = "YES_OR_NO_QUERY";
    OptimisticOracleV2Interface constant oracle =
        OptimisticOracleV2Interface(0xA5B9d8a0B0Fa04Ba71BDD68069661ED5C0848884); //Goerli OOv2
    IERC20 constant WETH = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); //Goerli

    event SinglePriceProposed(address _address, int256 price);
    event SinglePriceSettled(address _address, int256 price);
    event MultiplePriceProposed(uint256 pendingAddressesKey, int256 price);
    event MultiplePriceSettled(uint256 pendingAddressesKey, int256 price);

    function initialize(
        bytes memory _fixedAncillaryData,
        string memory _title,
        uint256 _livenessPeriod,
        uint256 _bondAmount,
        uint256 _addReward,
        uint256 _removeReward
    ) public initializer {
        fixedAncillaryData = _fixedAncillaryData;
        title = _title;
        livenessPeriod = _livenessPeriod;
        bondAmount = _bondAmount;
        addReward = _addReward;
        removeReward = _removeReward;
    }

    function addSingleAddress(address _address) public {
        require(!listMapping[_address], "address is already on list");
        if (bondAmount > 0) {
            bool success = WETH.transferFrom(
                msg.sender,
                address(this),
                bondAmount
            );
            require(success, "transfer of bond amount to List contract failed");
        }
        //prepare price request data
        string memory _addressString = toAsciiString(_address);
        bytes memory ancillaryDataFull = bytes.concat(
            fixedAncillaryData,
            ". Address to Query: 0x",
            abi.encodePacked(_addressString)
        );
        uint256 currentRequestTime = block.timestamp;

        requestPriceFlow(currentRequestTime, ancillaryDataFull);

        //store request info for future reference
        bytes memory requestData = bytes.concat(
            ancillaryDataFull,
            abi.encodePacked(currentRequestTime)
        );
        singleRequests[requestData].pendingAddress = _address;
        singleRequests[requestData].proposedPrice = 1e18;
        singleRequests[requestData].proposer = msg.sender;

        if (bondAmount > 0) {
            bool success = WETH.approve(address(oracle), bondAmount);
            require(
                success,
                "approval of bond amount from List contract to Oracle failed"
            );
        }
        oracle.proposePriceFor(
            msg.sender,
            address(this),
            priceId,
            currentRequestTime,
            ancillaryDataFull,
            1e18
        );

        emit SinglePriceProposed(_address, 1e18);
    }

    function addMutlipleAddresses(address[] calldata _addresses) public {
        for (uint256 i = 0; i <= _addresses.length - 1; i++) {
            require(
                !listMapping[_addresses[i]],
                "at least 1 address is already on list"
            );
        }
        if (bondAmount > 0) {
            bool success = WETH.transferFrom(
                msg.sender,
                address(this),
                bondAmount
            );
            require(success, "transfer of bond amount to List contract failed");
        }
        //prepare price request data
        bytes memory ancillaryDataFull = bytes.concat(
            fixedAncillaryData,
            ". Addresses to query can be found on requester address by calling getPendingAddressesArray with uint argument of ",
            toUtf8BytesUint(pendingAddressesCounter)
        );
        uint256 currentRequestTime = block.timestamp;

        requestPriceFlow(currentRequestTime, ancillaryDataFull);

        //store request info for future reference
        bytes memory requestData = bytes.concat(
            ancillaryDataFull,
            abi.encodePacked(currentRequestTime)
        );
        multipleRequests[requestData]
            .pendingAddressesKey = pendingAddressesCounter;
        multipleRequests[requestData].proposedPrice = 1e18;
        multipleRequests[requestData].proposer = msg.sender;
        pendingAddresses[pendingAddressesCounter] = _addresses;

        if (bondAmount > 0) {
            bool success = WETH.approve(address(oracle), bondAmount);
            require(
                success,
                "approval of bond amount from List contract to Oracle failed"
            );
        }
        oracle.proposePriceFor(
            msg.sender,
            address(this),
            priceId,
            currentRequestTime,
            ancillaryDataFull,
            1e18
        );

        emit MultiplePriceProposed(pendingAddressesCounter, 1e18);
        pendingAddressesCounter++;
    }

    function removeSingleAddress(address _address) public {
        require(listMapping[_address], "address is not on list");
        if (bondAmount > 0) {
            bool success = WETH.transferFrom(
                msg.sender,
                address(this),
                bondAmount
            );
            require(success, "transfer of bond amount to List contract failed");
        }

        //prepare price request data
        string memory _addressString = toAsciiString(_address);
        bytes memory ancillaryDataFull = bytes.concat(
            fixedAncillaryData,
            ". Address to Query: 0x",
            abi.encodePacked(_addressString)
        );
        uint256 currentRequestTime = block.timestamp;

        requestPriceFlow(currentRequestTime, ancillaryDataFull);

        //store request info for future reference
        bytes memory requestData = bytes.concat(
            ancillaryDataFull,
            abi.encodePacked(currentRequestTime)
        );

        singleRequests[requestData].pendingAddress = _address;
        singleRequests[requestData].proposedPrice = 0;
        singleRequests[requestData].proposer = msg.sender;

        if (bondAmount > 0) {
            bool success = WETH.approve(address(oracle), bondAmount);
            require(
                success,
                "approval of bond amount from List contract to Oracle failed"
            );
        }

        //propose price to OO
        oracle.proposePriceFor(
            msg.sender,
            address(this),
            priceId,
            currentRequestTime,
            ancillaryDataFull,
            0
        );

        emit SinglePriceProposed(_address, 0);
    }

    function removeMutlipleAddresses(address[] calldata _addresses) public {
        for (uint256 i = 0; i <= _addresses.length - 1; i++) {
            require(
                listMapping[_addresses[i]],
                "at least 1 address is not on list"
            );
        }
        if (bondAmount > 0) {
            bool success = WETH.transferFrom(
                msg.sender,
                address(this),
                bondAmount
            );
            require(success, "transfer of bond amount to List contract failed");
        }
        //prepare price request data
        bytes memory ancillaryDataFull = bytes.concat(
            fixedAncillaryData,
            ". Addresses to query can be found on requester address by calling getPendingAddressesArray with uint argument of ",
            toUtf8BytesUint(pendingAddressesCounter)
        );
        uint256 currentRequestTime = block.timestamp;

        requestPriceFlow(currentRequestTime, ancillaryDataFull);

        //store request info for future reference
        bytes memory requestData = bytes.concat(
            ancillaryDataFull,
            abi.encodePacked(currentRequestTime)
        );
        multipleRequests[requestData]
            .pendingAddressesKey = pendingAddressesCounter;
        multipleRequests[requestData].proposedPrice = 0;
        multipleRequests[requestData].proposer = msg.sender;
        pendingAddresses[pendingAddressesCounter] = _addresses;

        if (bondAmount > 0) {
            bool success = WETH.approve(address(oracle), bondAmount);
            require(
                success,
                "approval of bond amount from List contract to Oracle failed"
            );
        }
        oracle.proposePriceFor(
            msg.sender,
            address(this),
            priceId,
            currentRequestTime,
            ancillaryDataFull,
            0
        );

        emit MultiplePriceProposed(pendingAddressesCounter, 0);

        pendingAddressesCounter++;
    }

    //externally called settle function will call this when price is settled
    function priceSettled(
        bytes32 identifier,
        uint256 timestamp,
        bytes memory ancillaryData,
        int256 price
    ) external {
        require(
            msg.sender == address(oracle),
            "only oracle can call this function"
        );
        bytes memory requestData = bytes.concat(
            ancillaryData,
            abi.encodePacked(timestamp)
        );

        //handle single requests
        SingleRequest memory request = singleRequests[requestData];

        if (request.pendingAddress != address(0)) {
            //if proposed price was successfully disputed return
            if (request.proposedPrice != price) {
                emit SinglePriceSettled(request.pendingAddress, price);
                return;
            }
            if (price == 0) {
                listMapping[request.pendingAddress] = false;
                removeIndex(getIndex(request.pendingAddress));
                if (removeReward > 0) {
                    WETH.transfer(request.proposer, removeReward);
                }
            } else {
                if (price == 1e18) {
                    listMapping[request.pendingAddress] = true;
                    listArray.push(request.pendingAddress);
                    if (addReward > 0) {
                        WETH.transfer(request.proposer, addReward);
                    }
                }
            }
            emit SinglePriceSettled(request.pendingAddress, price);
            return;
        } else {
            //handle multiple requests
            MultipleRequest memory multipleRequest = multipleRequests[
                requestData
            ];
            if (multipleRequest.pendingAddressesKey != 0) {
                //if proposed price was successfully disputed return
                if (multipleRequest.proposedPrice != price) {
                    emit MultiplePriceSettled(
                        multipleRequest.pendingAddressesKey,
                        price
                    );
                    return;
                }
                if (price == 0) {
                    for (
                        uint256 i = 0;
                        i <=
                        pendingAddresses[multipleRequest.pendingAddressesKey]
                            .length -
                            1;
                        i++
                    ) {
                        address _address = pendingAddresses[
                            multipleRequest.pendingAddressesKey
                        ][i];
                        listMapping[_address] = false;
                        removeIndex(getIndex(_address));
                    }
                    if (removeReward > 0) {
                        WETH.transfer(
                            multipleRequest.proposer,
                            removeReward *
                                pendingAddresses[
                                    multipleRequest.pendingAddressesKey
                                ].length
                        );
                    }
                    emit MultiplePriceSettled(
                        multipleRequest.pendingAddressesKey,
                        0
                    );
                    return;
                }
                if (price == 1e18) {
                    for (
                        uint256 i = 0;
                        i <=
                        pendingAddresses[multipleRequest.pendingAddressesKey]
                            .length -
                            1;
                        i++
                    ) {
                        address _address = pendingAddresses[
                            multipleRequest.pendingAddressesKey
                        ][i];
                        listMapping[_address] = true;
                        listArray.push(_address);
                    }
                    if (addReward > 0) {
                        WETH.transfer(
                            multipleRequest.proposer,
                            addReward *
                                pendingAddresses[
                                    multipleRequest.pendingAddressesKey
                                ].length
                        );
                    }
                    emit MultiplePriceSettled(
                        multipleRequest.pendingAddressesKey,
                        1e18
                    );
                    return;
                }
            }
            emit MultiplePriceSettled(
                multipleRequest.pendingAddressesKey,
                price
            );
            return;
        }
    }

    function getListArray() public view returns (address[] memory) {
        return listArray;
    }

    function getPendingAddressesArray(uint256 pendingAddressesKey)
        public
        view
        returns (address[] memory)
    {
        return pendingAddresses[pendingAddressesKey];
    }

    function getListLength() public view returns (uint256) {
        return listArray.length;
    }

    function getIndex(address _address) internal view returns (uint256 i) {
        for (i = 0; i < listArray.length - 1; i++) {
            if (listArray[i] == _address) {
                return i;
            }
        }
    }

    function removeIndex(uint256 _index) internal {
        for (uint256 i = _index; i < listArray.length - 1; i++) {
            listArray[i] = listArray[i + 1];
        }
        listArray.pop();
    }

    function requestPriceFlow(
        uint256 _currentRequestTime,
        bytes memory _ancillaryDataFull
    ) internal {
        oracle.requestPrice(
            priceId,
            _currentRequestTime,
            _ancillaryDataFull,
            WETH,
            0
        );
        oracle.setCallbacks(
            priceId,
            _currentRequestTime,
            _ancillaryDataFull,
            false,
            false,
            true
        );
        oracle.setCustomLiveness(
            priceId,
            _currentRequestTime,
            _ancillaryDataFull,
            livenessPeriod
        );
        oracle.setBond(
            priceId,
            _currentRequestTime,
            _ancillaryDataFull,
            bondAmount
        );
    }

    //for formatting ancillary data. from: https://stackoverflow.com/a/65707309
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    //for formatting ancillary data. from: https://stackoverflow.com/a/65707309
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    //for formatting ancillary data. from: https://github.com/UMAprotocol/protocol/blob/master/packages/core/contracts/common/implementation/AncillaryData.sol
    function toUtf8BytesUint(uint256 x) internal pure returns (bytes memory) {
        if (x == 0) {
            return "0";
        }
        uint256 j = x;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (x != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(x - (x / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            x /= 10;
        }
        return bstr;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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