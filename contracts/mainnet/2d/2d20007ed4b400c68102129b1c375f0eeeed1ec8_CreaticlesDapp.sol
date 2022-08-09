/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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




/** 
 *  SourceUnit: /Users/taosu/Workspace/request-contract/contracts/CreaticlesDapp.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

////import "../../utils/AddressUpgradeable.sol";

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




/** 
 *  SourceUnit: /Users/taosu/Workspace/request-contract/contracts/CreaticlesDapp.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /Users/taosu/Workspace/request-contract/contracts/CreaticlesDapp.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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


/** 
 *  SourceUnit: /Users/taosu/Workspace/request-contract/contracts/CreaticlesDapp.sol
*/

pragma solidity 0.8.9;

// ////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
////import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ////import "hardhat/console.sol";

contract CreaticlesDapp is ContextUpgradeable {
    uint256 public CHOOSING_PERIOD;
    uint256 public TAX;

    struct Request {
        address requester;
        bytes32 detailsHash;
        uint256 value;
        uint128 numberOfWinners;
        uint256 createdAt;
        uint256 expiresAt;
        bool active;
        uint256 numMintPerToken;
    }

    address payable public treasury;
    uint256 public numberOfRequests;
    mapping(uint256 => Request) public requests;
    address public adm;
    address public nftContractAddress;
    bool private initialized;

    //EVENTS
    event RequestCreated(
        uint256 requestId,
        address requester,
        bytes32 detailsHash,
        uint256 value,
        uint128 numberOfWinners,
        uint256 createdAt,
        uint256 expiresAt,
        bool active,
        uint256 numMintPerToken
    );
    event ProposalAccepted(
        address to,
        uint256 requestId,
        uint256[] _proposalId,
        uint256[] _tokenIds,
        string[] _tokenURLs,
        address[] _winners,
        uint256 remainingValue,
        uint256 tokenSupplies
    );
    event FundsReclaimed(uint256 requestId, address requester, uint256 amount);
    event ChoosingPeriodChanged(uint256 period);
    event TaxChanged(uint256 tax);

    mapping(uint256 => address) public request_erc20_addresses;

    //MODIFIERS
    modifier onlyRequester(uint256 _requestId) {
        require(
            requests[_requestId].requester == msg.sender,
            "Sender is not Requester"
        );
        _;
    }
    modifier isCreaticlesNFTContract() {
        require(
            _msgSender() == nftContractAddress,
            "Only Creaticles NFT Contract has permission to call this function"
        );
        _;
    }
    modifier isAdmin() {
        require(
            _msgSender() == adm,
            "This function can only be called by an admin"
        );
        _;
    }

    //INTITIALIZER
    /**
     *
     * @param _choosingPeriod: units DAYS => used to set allowable time period for requester to choose winners
     * @param  _tax =>  (parts per thousand)
     * @param _treasury: DAO's address
     */
    function initialize(
        uint256 _choosingPeriod,
        uint256 _tax,
        address payable _treasury
    ) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        adm = msg.sender;
        CHOOSING_PERIOD = _choosingPeriod * 1 days;
        TAX = _tax;
        treasury = _treasury;
    }

    /**
     * @param nftAddress:
     */
    function setNFTContractAddress(address nftAddress) public isAdmin {
        nftContractAddress = nftAddress;
    }

    //MUTABLE FUNCTIONS
    /**
     * @dev creates a request
     * @param _detailsHash => keccak256 hash of the metadata of the request
     * @param _numberOfWinners => the initially set number of winners. A request cannot take more winners than specified
     * @param _duration => time span of contest in seconds. After this time is up. No more proposals can be taken and the choosing period starts
     * @param _numMintPerToken => number of NFTs per winner . You can choose to mint fewer NFTs when your contest is over but you cannot mint more.
     * @param _paymentERC20Address => ERC20Address of payment
     * @param _paymentValue =>  Value of payment
     */
    function createRequest(
        bytes32 _detailsHash,
        uint16 _numberOfWinners,
        uint32 _duration,
        uint256 _numMintPerToken,
        address _paymentERC20Address,
        uint256 _paymentValue
    ) public payable returns (uint256) {
        require(_numberOfWinners > 0);
        require(_paymentValue > 0);

        uint256 _cval;
        uint256 _value;
        {
            if (_paymentERC20Address == address(0)) {
                // zero address corresponds to ethereum payment, the default
                require(msg.value == _paymentValue);
                _cval = (msg.value * TAX) / 1000; // 2.5% commision
                _value = msg.value - _cval;
                treasury.transfer(_cval);
            } else  {
                // Here we explore additional ERC20 payment options
                IERC20(_paymentERC20Address).transferFrom(
                    msg.sender,
                    address(this),
                    _paymentValue
                );
                _cval = (_paymentValue * TAX) / 1000; // 2.5% commision
                _value = _paymentValue - _cval;
                IERC20(_paymentERC20Address).transfer(treasury, _cval);
            }
            request_erc20_addresses[numberOfRequests] = _paymentERC20Address;

            Request storage _request = requests[numberOfRequests];
            _request.requester = msg.sender;
            _request.detailsHash = _detailsHash;
            _request.value = _value;
            _request.numberOfWinners = _numberOfWinners;
            _request.createdAt = block.timestamp;
            _request.expiresAt = block.timestamp + _duration;
            _request.active = true;
            _request.numMintPerToken = _numMintPerToken;
            numberOfRequests += 1;
        }

        emit RequestCreated(
            numberOfRequests - 1,
            msg.sender,
            _detailsHash,
            _value,
            _numberOfWinners,
            block.timestamp,
            block.timestamp + _duration,
            true,
            _numMintPerToken
        );

        return numberOfRequests - 1;
    }

    /**
     * @dev can only be called by the CreaticlesNFT contract. Used to pay winners after the CreaticlesNFT contract mints the winning NFTs
     * @param _to => the address that should receive the NFTs
     * @param _requestId => the requestId of the respective request
     * @param _proposalId => the list of proposalId
     * @param _tokenIds => the list of tokenIds
     * @param _tokenURLs => the list of tokenURLs
     * @param _winners => list of the addresses of the chosen winners
     * @param _tokenSupplies => supply of the NFTs
     */
    function acceptProposals(
        address _to,
        uint256 _requestId,
        uint256[] memory _proposalId,
        uint256[] memory _tokenIds,
        string[] memory _tokenURLs,
        address[] memory _winners,
        uint256 _tokenSupplies
    ) public isCreaticlesNFTContract {
        Request storage _request = requests[_requestId];
        require(
            _winners.length <= _request.numberOfWinners,
            "Requester cannot claim more winners than intially set"
        );
        uint256 _winnerValue = _request.value / _request.numberOfWinners;
        _request.value -= (_winnerValue * _winners.length);
        _request.active = false;

        address request_erc20_address = request_erc20_addresses[_requestId];

        //loop through winners and send their ETH
        for (uint256 i = 0; i < _winners.length; i++) {
            if (request_erc20_address == address(0)) {
                require(
                    payable(_winners[i]).send(_winnerValue),
                    "Failed to send Ether"
                );
            } else {
                // if we are not sending ether, we send ERC20 token
                IERC20(request_erc20_address).transfer(
                    _winners[i],
                    _winnerValue
                );
            }
        }

        // _request.active = false;
        emit ProposalAccepted(
            _to,
            _requestId,
            _proposalId,
            _tokenIds,
            _tokenURLs,
            _winners,
            _winnerValue,
            _tokenSupplies
        );
    }

    /**
     * @dev allows requester to reclaim their funds if they still have funds and the choosing period is over
     * @param _requestId => the requestId of the respective request
     */
    function reclaimFunds(uint256 _requestId)
        external
        onlyRequester(_requestId)
    {
        Request storage _request = requests[_requestId];
        // require(_msgSender() == _request.requester, "Sender is not Requester");
        require(
            block.timestamp >= _request.expiresAt + CHOOSING_PERIOD ||
                !_request.active,
            "Funds are not available"
        );

        address request_erc20_address = request_erc20_addresses[_requestId];

        if (request_erc20_address == address(0)) {
            payable(msg.sender).transfer(_request.value);
        } else {
            // here we send the ERC20 token back to the requester
            IERC20(request_erc20_address).transfer(msg.sender, _request.value);
        }

        emit FundsReclaimed(_requestId, _request.requester, _request.value);
        _request.value = 0;
    }

    /**
     * @dev set CHOOSING_PERIOD
     * @param _duration => (units of days)
     */
    function setChoosingPeriod(uint256 _duration) public isAdmin {
        CHOOSING_PERIOD = _duration * 1 days;
        emit ChoosingPeriodChanged(CHOOSING_PERIOD);
    }

    /**
     * @dev set TAX
     * @param _tax =>  (parts per thousand)
     */
    function setTax(uint256 _tax) public isAdmin {
        TAX = _tax;
        emit TaxChanged(TAX);
    }

    //VIEW FUNCTIONS
    /**
     * @dev used by CreaticlesNFT contract to determine if the minter is the owner of the specified request
     * @param _addr => the target address
     * @param _requestId => the requestId of the respective request
     */
    function isRequester(address _addr, uint256 _requestId)
        public
        view
        returns (bool)
    {
        Request memory _request = requests[_requestId];
        require(_addr == _request.requester, "Address is not the requester");
        return true;
    }

    /**
     * @dev used by CreaticlesNFT contract to determine if the specified request is not closed
     * @param _requestId => the requestId of the respective request
     */
    function isOpenForChoosing(uint256 _requestId) public view returns (bool) {
        Request memory _request = requests[_requestId];
        require(
            block.timestamp >= ((_request.expiresAt * 1 seconds)),
            "Choosing period has not started"
        );
        require(
            block.timestamp <=
                ((_request.expiresAt * 1 seconds) + CHOOSING_PERIOD),
            "Choosing period is up"
        );
        require(_request.active, "request not active");
        return true;
    }

    /**
     * @dev used to set new admin
     * @param _newAdmin =>
     *
     */
    function setAdmin(address _newAdmin) external isCreaticlesNFTContract {
        adm = _newAdmin;
    }

    /**
     * @dev update TaxRecipient
     * @param _newTtreasury => new DAO's address
     *
     */
    function updateTreasury(address payable _newTtreasury) public isAdmin {
        treasury = _newTtreasury;
    }
}