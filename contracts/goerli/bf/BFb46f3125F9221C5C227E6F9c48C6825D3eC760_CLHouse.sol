// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "Initializable.sol";
import "CLStorage.sol";
import "IUnlock.sol";


/// @title Contract to implement and test the basic fuctions of CLHouses
/// @author Leonardo Urrego
/// @notice This contract for test only the most basic interactions
contract CLHouse is CLStorage, Initializable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Create a new CLH
    /// @dev Some parameters can be ignored depending on the governance model
    /// @param _owner The address of the deployed wallet
    /// @param _houseName Name given by the owner
    /// @param _housePrivate If is set to 1, the CLH is set to private
    /// @param _houseOpen If is set to 1, the CLH is set to Open
    /// @param _govModel keccak256 hash of the governance model, see the __GOV_* constans
    /// @param _govRules Array for goverment rules see `enum gRule`
    /// @param _CLC Array for CL Contracts and others see `enum eCLC`
    /// @param _ManagerWallets Whitelist of address for invitate as managers
    function Init(
        address _owner, 
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        bytes32 _govModel,
        uint256[3] memory _govRules,
        address[6] memory _CLC,
        address[] memory _ManagerWallets
    )
        external
        reinitializer( __UPGRADEABLE_CLH_VERSION__ )
    {
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = _CLC[ uint256( eCLC.CLLConstructorCLH ) ].delegatecall(
            abi.encodeWithSignature(
                "__CLHConstructor(address,string,bool,bool,bytes32,uint256[3],address[6],address[])",
                _owner, 
                _houseName,
                _housePrivate,
                _houseOpen,
                _govModel,
                _govRules,
                _CLC,
                _ManagerWallets
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /// @notice Execute (or reject) a proposal computing the votes and the governance model
    /// @dev Normally is called internally after each vote
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @return status True if the proposal can be execute, false in other cases
    /// @return message result of the transaction
    function ExecProp(
        uint256 _propId
    )
        public
        returns(
            bool status,
            string memory message
        )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature(
                "ExecProp(uint256)",
                _propId
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        return ( true , "Success executed proposal" );
    }

    /// @notice Used to vote a proposal
    /// @dev After vote the proposal automatically try to be executed
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @param _support True for accept, false to reject
    /// @param _justification About your vote
    function VoteProposal(
        uint256 _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        public
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "VoteProposal(uint256,bool,string,bytes)",
                _propId,
                _support,
                _justification,
                _signature
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    /// @notice Generate a new proposal to invite a new user
    /// @dev the execution of this proposal only create an invitation 
    /// @param _walletAddr  Address of the new user
    /// @param _name Can be the nickname or other reference to the User
    /// @param _description A text for the proposal
    /// @param _isManager True if is for a manager
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropInviteUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns( uint256 propId )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropInviteUser(address,string,string,bool,uint256,bytes)",
                _walletAddr,
                _name,
                _description,
                _isManager,
                _delayTime,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a new proposal for remove a user
    /// @dev The user can be a managaer
    /// @param _walletAddr user Address to be removed
    /// @param _description About the proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns( uint256 propId )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropRemoveUser(address,string,uint256,bytes)",
                _walletAddr,
                _description,
                _delayTime,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice generate a new proposal to transfer ETH in weis
    /// @dev When execute this proposal, the transfer is made
    /// @param _to Recipient address
    /// @param _amountOutCLV Amount to transfer (in wei)
    /// @param _description About this proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropTxWei(
        address _to,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropTxWei(address,uint256,string,uint256)",
                _to,
                _amountOutCLV,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice generate a new proposal to transfer ETH in weis
    /// @dev When execute this proposal, the transfer is made
    /// @param _to Recipient address
    /// @param _amountOutCLV Amount to transfer (in wei)
    /// @param _description About this proposal
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropTxERC20(
        address _to,
        uint256 _amountOutCLV,
        address _tokenOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropTxERC20(address,uint256,address,string,uint256)",
                _to,
                _amountOutCLV,
                _tokenOutCLV,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a new proposal for change some governance parameters
    /// @dev When execute this proposal the new values will be set
    /// @param _newApprovPercentage The new percentaje for accept or reject a proposal
    /// @param _description About the new proposal 
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropGovRules(
        uint256 _newApprovPercentage,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 propId )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropGovRules(uint256,string,uint256)",
                _newApprovPercentage,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            propId := mload(ptr)
        }
    }

    /// @notice Generate a proposal from a user that want to join to the CLH
    /// @dev Only avaiable in public CLH
    /// @param _name Nickname or other user identification
    /// @param _description About the request
    /// @param _signerWallet Address of signer to check OffChain signature
    /// @return propId ID of the new proposal, based on `arrProposals`
    function PropRequestToJoin(
        string memory _name,
        string memory _description,
        address _signerWallet,
        bytes memory _signature
    )
        external
        returns( uint256 )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropRequestToJoin(string,string,address,bytes)",
                _name,
                _description,
                _signerWallet,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }

    /// @notice For an user that have an invitation pending
    /// @param _acceptance True for accept the invitation
    function AcceptRejectInvitation(
        bool _acceptance,
        bytes memory _signature
    )
        external
    {
        address CLLUserManagement = CCLFACTORY.CLLUserManagement();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLUserManagement.delegatecall(
            abi.encodeWithSignature( 
                "AcceptRejectInvitation(bool,bytes)",
                _acceptance,
                _signature
            )
        );

        if( !successDGTCLL ) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function PropSwapERC20(
        address _tokenOutCLV,
        address _tokenInCLV,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropSwapERC20(address,address,uint256,string,uint256)",
                _tokenOutCLV,
                _tokenInCLV,
                _amountOutCLV,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }

    function PropSellERC20(
        address _tokenOutCLV,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropSellERC20(address,uint256,string,uint256)",
                _tokenOutCLV,
                _amountOutCLV,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }

    function PropBuyERC20(
        address _tokenInCLV,
        uint256 _amountOutCLV,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns( uint256 )
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "PropBuyERC20(address,uint256,string,uint256)",
                _tokenInCLV,
                _amountOutCLV,
                _description,
                _delayTime
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }


    /// @notice Vote for multiple proposal
    /// @param _propId Array with ID of the proposal to votes
    /// @param _support is the Vote (True or False) for all proposals
    /// @param _justification Description of the vote
    function bulkVote(
        uint256[] memory _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        external
    {
        address CLLGovernance = CCLFACTORY.CLLGovernance();
        /// @custom:oz-upgrades-unsafe-allow delegatecall
        (bool successDGTCLL, ) = CLLGovernance.delegatecall(
            abi.encodeWithSignature( 
                "bulkVote(uint256[],bool,string,bytes)",
                _propId,
                _support,
                _justification,
                _signature
            )
        );

        assembly {
            let ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            if iszero( successDGTCLL ) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }

    /// @notice Length of arrUsers array
    function GetArrUsersLength() external view returns( uint256 ){
        return arrUsers.length;
    }

    /// @notice Length of arrProposals array
    function GetArrProposalsLength() external view returns( uint256 ){
        return arrProposals.length;
    }

    /// @notice The list of all Proposals
    /// @return arrProposals the array with all proposals
    function GetProposalList() external view returns( strProposal[] memory ) {
        return arrProposals;
    }

    /// @notice Get complete array of arrDataPropUser
    /// @return arrDataPropUser the array with all data
    function GetArrDataPropUser() external view returns( strDataUser[] memory ) {
        return arrDataPropUser;
    }

    function GetCLHouseVersion() external view returns ( string memory ) {
        return __CLHOUSE_VERSION__;
    }

    function SetWhitelistCollection( address _whiteListNFT ) external {
        CheckIsManager( msg.sender );
        whiteListNFT = _whiteListNFT;
    }

    function CreateLock(
        uint256 _expirationDuration,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string memory _lockName
    )
        external
        returns (
            address
        )
    {
        CheckIsManager( msg.sender );
        bytes memory params = abi.encodeWithSignature(
            'initialize(address,uint256,address,uint256,uint256,string)',
            msg.sender,
            _expirationDuration,
            address(0),
            _keyPrice,
            _maxNumberOfKeys,
            _lockName
        );

        address aULF = 0x627118a4fB747016911e5cDA82e2E77C531e8206;

        IUnlock iULF = IUnlock( aULF );

        return iULF.createUpgradeableLockAtVersion( params, 11 );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "Address.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLHNFTV2.sol";
import "ICLFactory.sol";
import "CLVault.sol";

/// @title Contract to store data of CLHouse (var stack)
/// @author Leonardo Urrego
/// @notice This contract is part of CLH
abstract contract CLStorage {

	/**
     * ### CLH Public Variables ###
     */

    bool public housePrivate;
    bool public houseOpen;
    bool[30] __gapBool;

    uint256 public numUsers;
    uint256 public numManagers;
    uint256 public govRuleApprovPercentage;
    uint256 public govRuleMaxUsers;
    uint256 public govRuleMaxManagers;
    uint256[27] __gapUint256;

    address public CLHAPI;
    address public CLHSAFE;
    address public whiteListNFT;
    address[29] __gapAddress;

    string public HOUSE_NAME;
    uint256[31] __gapString;

    bytes32 public HOUSE_GOVERNANCE_MODEL;
    bytes32[31] __gapBytes32;

    strUser[] public arrUsers;
    strProposal[] public arrProposals;
    strDataUser[] public arrDataPropUser;
    strDataTxAssets[] public arrDataPropTxAssets;
    strDataGovRules[] public arrDataPropGovRules;
    uint256[27] __gapArrays;

    mapping( address => uint256 ) public mapIdUser;
    mapping( address => uint256 ) public mapInvitationUser; // wallet => propId
    mapping( address => uint256 ) public mapReq2Join; // wallet => propId
    mapping( uint256 => mapping( address => strVote ) ) public mapVotes; // mapVotes[propId][wallet].strVote
    uint256[27] __gapMappings;

    ICLFactory public CCLFACTORY;
    CLVault public vaultCLH;
    CLHNFTV2 public nftAdmin;
    CLHNFTV2 public nftMember;
    CLHNFTV2 public nftInvitation;

    /**
     * ### Contract events ###
     */

    event evtUser( userEvent eventUser, address walletAddr, string name );
    event evtVoted( uint256 propId, bool position, address voter, string justification );
    event evtProposal( proposalEvent eventProposal, uint256 propId, proposalType typeProposal, string description );
    event evtChangeGovRules( uint256 newApprovPercentage );
    event evtTxEth( assetsEvent typeEvent, address walletAddr, uint256 value, uint256 balance );
    event evtTxERC20( address walletAddr, uint256 value, address tokenAdd );
    event evtSwapERC20( address tokenOutCLV, uint256 amountOutCLV, address tokenInCLV, uint256 amountReceived );

    /**
     * ### Function modifiers ###
     */
    
    modifier modIsUser( address _walletAddr ) {
        require( true == arrUsers[ mapIdUser[ _walletAddr ] ].isUser , "User don't exist!!" );
        _;
    }

    modifier modNotUser( address _walletAddr ) {
        require( 0 == mapIdUser[ _walletAddr ] , "User exist!!" );
        _;
    }

    modifier modCheckMaxUsers( ) {
        require( numUsers < govRuleMaxUsers, "No avaliable spots for new users");
        _;
    }

    modifier modCheckMaxManager( bool _isManager ) {
        if( _isManager )
            require( numManagers < govRuleMaxManagers, "No avaliable spots for managers" );
        _;
    }

    modifier modValidApprovPercentage( uint256 _newApprovPercentage ) {
        require(
            _newApprovPercentage >= 0 &&
            _newApprovPercentage <= 100,
            "invalid number for percentage of Approval"
        );
        _;
    }



    function CheckPropExists( uint256 _propId ) internal view {
        require( _propId < arrProposals.length , "Proposal does not exist" );
    }

    function CheckPropNotExecuted( uint256 _propId ) internal view {
        require( false == arrProposals[ _propId ].executed , "Proposal already executed" );
    }

    function CheckPropNotRejected( uint256 _propId ) internal view {
        require( false == arrProposals[ _propId ].rejected , "Proposal was rejected" );
    }

    function CheckDeadline( uint256 _propId ) internal view {
        require( block.timestamp < arrProposals[ _propId ].deadline , "Proposal deadline" );
    }

    function CheckIsManager( address _walletAddr ) internal view {
        require( true == arrUsers[ mapIdUser[ _walletAddr ] ].isManager , "Not manager rights" );
    }

    function CheckNotUser( address _walletAddr ) internal view {
        require( 0 == mapIdUser[ _walletAddr ] , "User exist!!" );
    }

    function CheckNotPendingInvitation( address _walletAddr ) internal view {
        uint256 propId = mapInvitationUser[ _walletAddr ];
        if( propId > 0 && nftInvitation.balanceOf( _walletAddr ) > 0 )
            require( block.timestamp > arrProposals[ propId ].deadline , "User have a pending Invitation" );
    }

    function CheckNotPendingReq2Join( address _walletAddr ) internal view {
        uint256 propId = mapReq2Join[ _walletAddr ];
        if(
            propId > 0 &&
            false == arrProposals[ propId ].executed &&
            false == arrProposals[ propId ].rejected &&
            block.timestamp < arrProposals[ propId ].deadline
        )
            revert( "User have a pending request to Join" );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Initializable.sol";
import "CLTypes.sol";
import "ERC721UL.sol";

contract CLHNFTV2 is ERC721UL, Initializable {
    uint256 public totalSupply;
    address public owner;
    string private tokenURL;

    constructor() {
        _disableInitializers();
    }

    function Init(
        string memory _name,
        string memory _symbol,
        string memory _tokenURL,
        address _owner
    )
        external
        reinitializer( __UPGRADEABLE_NFT_VERSION__ )
    {
        name = _name;
        symbol = _symbol;
        tokenURL = _tokenURL;
        owner = _owner;
    }
    
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        require( msg.sender == owner, "Caller is not the owner");
    }

    function tokenURI(uint256 _id) external view override returns (string memory) {
        return tokenURL;
    }

    function safeMint( address _to ) external {
        _checkOwner();
        _safeMint( _to, ++totalSupply );
    }

    function burn(uint256 _id) external {
        _checkOwner();
        _burn( _id );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) public virtual override {
        revert("Transfer isn't allowed");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes calldata _data
    ) public virtual override {
        revert("Transfer isn't allowed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

error InvalidGovernanceType ( bytes32 ) ;
error DebugDLGTCLL( bool successDLGTCLL , bytes dataDLGTCLL );

/*
 * ### CLH constant Types ###
 */
string constant __CLHOUSE_VERSION__ = "0.1.1";

uint8 constant __UPGRADEABLE_CLH_VERSION__ = 1;
uint8 constant __UPGRADEABLE_CLF_VERSION__ = 1;
uint8 constant __UPGRADEABLE_NFT_VERSION__ = 1;

bytes32 constant __GOV_DICTATORSHIP__ = keccak256("__GOV_DICTATORSHIP__");
bytes32 constant __GOV_COMMITTEE__ = keccak256("__GOV_COMMITTEE__");
bytes32 constant __GOV_SIMPLE_MAJORITY__ = keccak256("__GOV_SIMPLE_MAJORITY__");
bytes32 constant __CONTRACT_NAME_HASH__ = keccak256("CLHouse");
bytes32 constant __CONTRACT_VERSION_HASH__ = keccak256(
    abi.encodePacked( __CLHOUSE_VERSION__ )
);
bytes32 constant __STR_EIP712DOMAIN_HASH__ = keccak256(
    abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    )
);
bytes32 constant __STR_OCINVIT_HASH__ = keccak256(
    abi.encodePacked(
        "strOCInvit(bool acceptance)"
    )
);
bytes32 constant __STR_OCVOTE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCVote(uint256 propId,bool support,string justification)"
    )
);
bytes32 constant __STR_OCBULKVOTE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCBulkVote(uint256[] propIds,bool support,string justification)"
    )
);
bytes32 constant __STR_OCNEWUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewUser(address walletAddr,string name,string description,bool isManager,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCDELUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCDelUser(address walletAddr,string description,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCREQUEST_HASH__ = keccak256(
    abi.encodePacked(
        "strOCRequest(string name,string description)"
    )
);
bytes32 constant __STR_OCNEWCLH_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewCLH(string houseName,bool housePrivate,bool houseOpen,bytes32 govModel,uint256 govRuleMaxUsers,uint256 govRuleMaxManagers,uint256 govRuleApprovPercentage,address whiteListNFT,address whiteListWallets)"
    )
);


/*
 * ### CLH enum Types ###
 */

enum userEvent{
    addUser,
    delUser,
    inviteUser,
    acceptInvitation,
    rejectInvitation,
    requestJoin
}

enum assetsEvent {
    receivedEth,
    transferEth,
    transferERC20,
    swapERC20,
    sellERC20,
    buyERC20
}

enum proposalEvent {
    addProposal,
    execProposal,
    rejectProposal
}

enum proposalType {
    newUser,
    removeUser,
    requestJoin,
    changeGovRules,
    transferEth,
    transferERC20,
    swapERC20,
    sellERC20,
    buyERC20
}

/// @param maxUsers Max of all users (including managers)
/// @param maxManagers Max of managers that CLH can accept (only for COMMITTEE )
/// @param approvPercentage Percentage for approval o reject proposal based on `numManagers`
enum gRule {
    maxUsers,
    maxManagers,
    approvPercentage
}

// / @param CLLUserManagement Address Contract Logic for user management
// / @param CLLGovernance Address Contract Logic for governance
/// @param CLFACTORY Address Proxy Contract for CLF
/// @param CLHAPI Address Contract for API
/// @param CLHSAFE Address Contract Proxy for Gnosis Safe
/// @param CLLConstructorCLH Address Contract with the CLH Constructor logic
enum eCLC {
    CLLConstructorCLH,
    CLFACTORY,
    CLHAPI,
    CLHSAFE,
    whiteListNFT,
    beaconNFT
}


/*
 * ### CLH struct Types ###
 */

struct strUser {
    address walletAddr;
    string name;
    uint256 balance;
    bool isUser;
    bool isManager;
}

struct strProposal {
    address proponent;
    proposalType typeProposal;
    string description;
    uint256 propDataId;
    uint256 numVotes;
    uint256 againstVotes;
    bool executed;
    bool rejected;
    uint256 deadline;
}

struct strVote {
    bool voted;
    bool inSupport;
    string justification;
}

struct strDataUser {
    address walletAddr;
    string name;
    bool isManager;
}

struct strDataTxAssets {
    address to;
    uint256 amountOutCLV;
    address tokenOutCLV;
    address tokenInCLV;
}

struct strDataGovRules {
    uint256 newApprovPercentage;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
// Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,    // _operator
        address,    // _from
        uint256,    // _tokenId
        bytes calldata  // _data
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice Re-implementation of ERC-721 based on Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @author LeoUL (LE0xUL)
abstract contract ERC721UL is ERC721Metadata {
    /**
        EVENTS
    */
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
        METADATA STORAGE/LOGIC
    */
    string public name;

    string public symbol;

    function tokenURI(uint256 _id) external view virtual returns (string memory);

    /**
        ERC721 BALANCE/OWNER STORAGE
    */
    mapping(uint256 => address) internal __ownerOf;

    mapping(address => uint256) internal __balanceOf;

    function ownerOf(uint256 _id) public view virtual returns (address  _owner ) {
        require( ( _owner = __ownerOf[ _id ] ) != address(0), "NOT_MINTED");
    }

    function balanceOf(address  _owner ) public view virtual returns (uint256) {
        require( _owner  != address(0), "ZERO_ADDRESS");

        return __balanceOf[ _owner ];
    }

    /**
        ERC721 APPROVAL STORAGE
    */
    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;


    /**
        ERC721 LOGIC
    */
    function approve( address _spender, uint256 _id ) public virtual {
        address owner = __ownerOf[ _id ];

        require( msg.sender == owner || isApprovedForAll[ owner ][ msg.sender ], "NOT_AUTHORIZED" );

        getApproved[ _id ] = _spender;

        emit Approval( owner, _spender, _id );
    }

    function setApprovalForAll( address operator, bool approved ) public virtual {
        isApprovedForAll[ msg.sender ][ operator ] = approved;

        emit ApprovalForAll( msg.sender, operator, approved );
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == __ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            __balanceOf[from]--;

            __balanceOf[to]++;
        }

        __ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /**
        ERC165 LOGIC
    */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /**
        INTERNAL MINT/BURN LOGIC
    */

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(__ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            __balanceOf[to]++;
        }

        __ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = __ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            __balanceOf[owner]--;
        }

        delete __ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /**
        INTERNAL SAFE MINT LOGIC
    */

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint( to, id );

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLTypes.sol";
import "CLBeacon.sol";
import "ICLHouse.sol";


interface ICLFactory {
    // View fuctions
    function CLHAPI() external view returns( address );
    function CLLConstructorCLH() external view returns( address );
    function CLLUserManagement() external view returns( address );
    function CLLGovernance() external view returns( address );
    function beaconCLH() external view returns( CLBeacon );
    function mapCLH( uint256 ) external view returns( ICLHouse );
    function numCLH() external view returns( uint256 );
    function getCLHImplementation() external view returns (address);

    // Write Functions
    function Init(
        address _CLLUserManagement,
        address _CLLGovernance,
        address _CLLConstructorCLH,
        address _CLHAPI,
        address _beaconCLH,
        address _beaconNFT
    ) external;

    function CreateCLH(
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        bytes32 _govModel,
        uint256[3] memory _govRules,
        address[] memory _ManagerWallets,
        address _gnosisSafe,
        address _whiteListNFT,
        address _signerWallet,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "UpgradeableBeacon.sol";

contract CLBeacon is UpgradeableBeacon {
    constructor(
        address _CLLogicContract
    )
        UpgradeableBeacon(
            _CLLogicContract
        )
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "IBeacon.sol";
import "Ownable.sol";
import "Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLTypes.sol";


interface ICLHouse {

    // View fuctions
    function housePrivate() external view returns( bool );
    function houseOpen() external view returns( bool );
    function HOUSE_NAME() external view returns( string memory );
    function HOUSE_GOVERNANCE_MODEL() external view returns( bytes32 );
    function numUsers() external view returns( uint256 );
    function numManagers() external view returns( uint256 );
    function govRuleApprovPercentage() external view returns( uint256 );
    function govRuleMaxUsers() external view returns( uint256 );
    function govRuleMaxManagers() external view returns( uint256 );
    function arrUsers( uint256 ) external view returns( address , string memory , uint256 , bool , bool );
    function arrProposals( uint256 ) external view returns( address , proposalType , string memory , uint16 , uint8 , uint8 , bool , bool , uint256 );
    function arrDataPropUser( uint256 ) external view returns( address , string memory , bool );
    function arrDataPropTxWei( uint256 ) external view returns( address , uint256 );
    function arrDataPropGovRules( uint256 ) external view returns( uint256 );
    function mapIdUser( address ) external view returns( uint256 );
    function mapInvitationUser( address ) external view returns( uint256 );
    function mapVotes( uint256 ,  address ) external view returns( bool , bool , string memory);
    function GetArrUsersLength() external view returns( uint256 );
    function CLHSAFE() external view returns( address );


    // no-view functions
    function ExecProp(
        uint _propId 
    )
        external 
        returns(
            bool status, 
            string memory message
        );

    function VoteProposal(
        uint _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        external
        returns(
            bool status
        );

    function PropInviteUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function PropRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function PropTxWei(
        address _to,
        uint _value,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns(
            uint propId
        );

    function PropGovRules(
        uint256 _newApprovPercentage,
        string memory _description,
        uint256 _delayTime
    )
        external
        returns(
            uint propId
        );

    function PropRequestToJoin(
        string memory _name,
        string memory _description,
        address _signerWallet,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function AcceptRejectInvitation(
        bool __acceptance,
        bytes memory _signature
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLHouseApi.sol";
import "ISwapRouter.sol";
import "TransferHelper.sol";

/// @title Vault contract for CLH
/// @notice Contract to store the assets and the functions that have any interaction with these
/// @author Leonardo Urrego
contract CLVault {

    /**
     * ### CLV Private Variables ###
     */

    /// @notice Contract of the offcial uniswap router
    ISwapRouter internal constant swapRouterV3 = ISwapRouter( 0xE592427A0AEce92De3Edee1F18E0157C05861564 );

    /// @notice Contract of the ERC20 WETH token
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // rinkeby

    /// @notice CLH that deployed this contract
	ICLHouse ownerCLH;

	/**
     * ### Contract events ###
     */

    /// @notice Event when deposit or transfer ETH
    /// @param typeEvent received/Transfer
    /// @param walletAddr Origin or destination address
    /// @param value amount in wei
    /// @param balance new balance after transacction in wei
    event evtTxEth( assetsEvent typeEvent, address walletAddr, uint256 value, uint256 balance );

    /// @notice Event when transfer any ERC20
    /// @param walletAddr destination address
    /// @param value amount
    /// @param tokenAdd Contract address of the ERC20
    /// @dev The recieve transfer event can't be generated here
    event evtTxERC20( address walletAddr, uint256 value, address tokenAdd );

    /// @notice Event for any swap of ERC20 token
    /// @param tokenOutCLV ERC20 contract token OUT
    /// @param amountOutCLV Amount that OUT from CLVault
    /// @param tokenInCLV ERC20 contract token IN
    /// @param amountReceived Amount that IN from CLVault
    event evtSwapERC20( address tokenOutCLV, uint256 amountOutCLV, address tokenInCLV, uint256 amountReceived );

    modifier modOnlyOwnerCLH( ) {
        require( address( ownerCLH ) == msg.sender , "Not a ownerCLH" );
        _;
    }

    fallback() external payable {
        emit evtTxEth( assetsEvent.receivedEth, msg.sender, msg.value, address(this).balance );
    }

    receive() external payable {
        emit evtTxEth( assetsEvent.receivedEth, msg.sender, msg.value, address(this).balance );
    }


    /// @notice Create the vault and asign the owner house
    /// @param _CLH Address of the vault owner
    constructor( address _CLH ) payable {
        ownerCLH = ICLHouse( _CLH );
    }


    /// @notice Transfer ETH from this vault
    /// @param _walletAddr Address of the receiver
    /// @param _amountOutCLV Amount to transfer from this vault
    function TxWei(
        address _walletAddr,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
    {
        require( address( this ).balance >= _amountOutCLV , "Insufficient funds!!" );
        ( bool success, ) = _walletAddr.call{ value: _amountOutCLV }( "" );
        require( success, "txWei failed" );

        // arrUsers[ mapIdUser[ msg.sender ] ].balance -= msg.value;  // TODO: safeMath?

        emit evtTxEth( assetsEvent.transferEth, _walletAddr, _amountOutCLV, address( this ).balance );
    }


    /// @notice Transfer any ERC20 that this vault has
    /// @param _walletAddr Address of the receiver
    /// @param _amountOutCLV Amount to transfer from this vault
    /// @param _tokenOutCLV Contract Address of the token to transfer
    function TxERC20(
        address _walletAddr,
        uint256 _amountOutCLV,
        address _tokenOutCLV
    )
        modOnlyOwnerCLH()
        external
    {
        IERC20 token = IERC20( _tokenOutCLV );

        require( token.balanceOf( address( this ) ) >= _amountOutCLV , "Insufficient Tokens!!" );
        ( bool success ) = token.transfer({ to: _walletAddr, amount: _amountOutCLV });
        require( success, "TxERC20 failed" );

        emit evtTxERC20( _walletAddr, _amountOutCLV, _tokenOutCLV );
    }


    /// @notice Swap any ERC20 that this vault has using Uniswap
    /// @param _tokenOutCLV Contract Address of the token to swap
    /// @param _tokenInCLV Contract Address of the token to receive
    /// @param _amountOutCLV Amount to swap from this vault
    /// @return amountReceived Token amount "received in the vault"
    function swapERC20(
        address _tokenOutCLV,
        address _tokenInCLV,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
        returns (
            uint256 amountReceived
        )
    {
        require( IERC20( _tokenOutCLV ).balanceOf( address( this ) ) >= _amountOutCLV , "Insufficient Tokens!!" );

        TransferHelper.safeApprove( _tokenOutCLV , address( swapRouterV3 ) , _amountOutCLV );        

        amountReceived = swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: _tokenOutCLV,
                tokenOut: _tokenInCLV,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountOutCLV,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );

        emit evtSwapERC20( _tokenOutCLV, _amountOutCLV, _tokenInCLV, amountReceived );
    }


    /// @notice Buy any ERC20 with Ether using Uniswap
    /// @param _tokenInCLV Contract Address of the token to receive
    /// @param _amountOutCLV Amount in ether out from this vault
    /// @return amountReceived Token amount received in the vault
    /// @dev The Ether is converted to WETH before buy
    function swapEth2Tokens(
        address _tokenInCLV,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
        returns (
            uint256 amountReceived
        )
    {
        require( address( this ).balance >= _amountOutCLV , "Insufficient funds!!"  );

        TransferHelper.safeTransferETH( WETH , _amountOutCLV );

        emit evtTxEth( assetsEvent.transferEth, WETH, _amountOutCLV, address( this ).balance );

        TransferHelper.safeApprove( WETH , address( swapRouterV3 ) , _amountOutCLV );        

        amountReceived = swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: WETH,
                tokenOut: _tokenInCLV,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountOutCLV,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );

        emit evtSwapERC20( address( 0 ), _amountOutCLV, _tokenInCLV, amountReceived );
    }


    /// @notice Sell any ERC20 using Uniswap
    /// @param _tokenOutCLV Contract Address of the token to sell
    /// @param _amountOutCLV Token amount out from this vault
    /// @return amountReceived Ether amount received in the vault
    /// @dev The WETH is converted to Ether at the end
    function swapTokens2Eth(
        address _tokenOutCLV,
        uint256 _amountOutCLV
    )
        modOnlyOwnerCLH()
        external
        returns (
            uint256 amountReceived
        )
    {
        require( IERC20( _tokenOutCLV ).balanceOf( address( this ) ) >= _amountOutCLV , "Insufficient Tokens!!" );

        TransferHelper.safeApprove( _tokenOutCLV , address( swapRouterV3 ) , _amountOutCLV );        

        amountReceived = swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams( {
                tokenIn: _tokenOutCLV,
                tokenOut: WETH,
                fee: 3000,
                recipient: address( this ),
                deadline: block.timestamp,
                amountIn: _amountOutCLV,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            } )
        );

        emit evtSwapERC20( _tokenOutCLV, _amountOutCLV, address( 0 ), amountReceived );

        ( bool result , ) = WETH.call{value: 0}( abi.encodeWithSignature( "withdraw(uint256)" , amountReceived ) );
        require( result , "Withdraw ETH fail" );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ICLHouse.sol";

/// @title Some funtions to interact with a CLHouse
/// @author Leonardo Urrego
/// @notice This contract is only for test 
contract CLHouseApi {

    /// @notice A funtion to verify the signer of a menssage
    /// @param _msghash Hash of the message
    /// @param _signature Signature of the message
    /// @return Signer address of the message
    function SignerOfMsg(
        bytes32  _msghash,
        bytes memory _signature
    )
        public
        pure
        returns( address )
    {
        require( _signature.length == 65, "Bad signature length" );

        bytes32 signR;
        bytes32 signS;
        uint8 signV;

        assembly {
            // first 32 bytes, after the length prefix
            signR := mload( add( _signature, 32 ) )
            // second 32 bytes
            signS := mload( add( _signature, 64 ) )
            // final byte (first byte of the next 32 bytes)
            signV := byte( 0, mload( add( _signature, 96 ) ) )
        }

        return ecrecover( _msghash, signV, signR, signS );
    }

    /// @notice Get the info of an user in one especific CLH
    /// @param _houseAddr Address of the CLH
    /// @param _walletAddr Address of the user
    /// @return name Nickname ot other user identificaction
    /// @return balance How much money have deposited
    /// @return isUser true if is User
    /// @return isManager true if is manager
    function GetUserInfoByAddress(
        address _houseAddr,
        address _walletAddr
    )
        external
        view
        returns(
            string memory name,
            uint balance,
            bool isUser,
            bool isManager
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint256 uid = daoCLH.mapIdUser( _walletAddr );

        require( 0 != uid , "Address not exist!!" );

        strUser memory houseUser;

        (   houseUser.walletAddr,
            houseUser.name,
            houseUser.balance,
            houseUser.isUser,
            houseUser.isManager ) = daoCLH.arrUsers( uid );

        require( true == houseUser.isUser  , "Is not a user" );

        return (
            houseUser.name,
            houseUser.balance,
            houseUser.isUser,
            houseUser.isManager
        );
    }

    /// @notice The list of all users address
    /// @param _houseAddr address of the CLH
    /// @return arrUsers array with list of users
    function GetHouseUserList(
        address _houseAddr
    )
        external
        view
        returns(
            strUser[] memory arrUsers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint256 numUsers = daoCLH.numUsers( );
        uint256 arrUsersLength = daoCLH.GetArrUsersLength();
        strUser[] memory _arrUsers = new strUser[] ( numUsers );

        uint256 index = 0 ;

        for( uint256 uid = 1 ; uid < arrUsersLength ; uid++ ) {
            strUser memory houseUser;

            (   houseUser.walletAddr,
                houseUser.name,
                houseUser.balance,
                houseUser.isUser,
                houseUser.isManager ) = daoCLH.arrUsers( uid );

            if( true == houseUser.isUser ){
                _arrUsers[ index ] = houseUser;
                index++;
            }
        }
        return _arrUsers;
    }

    /// @notice All properties of a House
    /// @param _houseAddr CLH address
    /// @return HOUSE_NAME name of the CLH
    /// @return HOUSE_GOVERNANCE_MODEL Hash of governance model
    /// @return housePrivate True if is private
    /// @return houseOpen True if is Open
    /// @return numUsers Current users of a CLH
    /// @return numManagers Current managers of a CLH
    /// @return govRuleApprovPercentage Percentage for approval o reject proposal based on `numManagers`
    /// @return govRuleMaxUsers Max of all users (including managers)
    /// @return govRuleMaxManagers Max of managers that CLH can accept (only for COMMITTEE )
    function GetHouseProperties(
        address _houseAddr
    )
        external
        view
        returns(
            string memory HOUSE_NAME,
            bytes32 HOUSE_GOVERNANCE_MODEL,
            bool housePrivate,
            bool houseOpen,
            uint256 numUsers,
            uint256 numManagers,
            uint256 govRuleApprovPercentage,
            uint256 govRuleMaxUsers,
            uint256 govRuleMaxManagers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        return(
            daoCLH.HOUSE_NAME(),
            daoCLH.HOUSE_GOVERNANCE_MODEL(),
            daoCLH.housePrivate(),
            daoCLH.houseOpen(),
            daoCLH.numUsers(),
            daoCLH.numManagers(),
            daoCLH.govRuleApprovPercentage(),
            daoCLH.govRuleMaxUsers(),
            daoCLH.govRuleMaxManagers()
        );
    }


    function SignerOCInvit(
        bool _acceptance,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCINVIT_HASH__,
                _acceptance
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCVote(
        uint _propId,
        bool _support,
        string memory _justification,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCVOTE_HASH__,
                _propId,
                _support,
                keccak256( abi.encodePacked( _justification ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCBulkVote(
        uint256[] memory _propIds,
        bool _support,
        string memory _justification,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCBULKVOTE_HASH__,
                keccak256( abi.encodePacked( _propIds ) ),
                _support,
                keccak256( abi.encodePacked( _justification ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCNewUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) ),
                _isManager,
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCDelUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCDELUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _description ) ),
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCRequest(
        string memory _name,
        string memory _description,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCREQUEST_HASH__,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    function SignerOCNewCLH(
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        bytes32 _govModel,
        uint256 _govRuleMaxUsers,
        uint256 _govRuleMaxManagers,
        uint256 _govRuleApprovPercentage,
        address _whiteListNFT,
        address _whiteListWallets,
        address _addrCLF,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _addrCLF
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWCLH_HASH__,
                keccak256( abi.encodePacked( _houseName ) ),
                _housePrivate,
                _houseOpen,
                _govModel,
                _govRuleMaxUsers,
                _govRuleMaxManagers,
                _govRuleApprovPercentage,
                _whiteListNFT,
                _whiteListWallets
                // keccak256( abi.encodePacked( _whiteListWallets ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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
pragma solidity >=0.5.17 <0.9.0;

/**
 * @title The Unlock Interface
 **/

interface IUnlock {
  // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
  function initialize(address _unlockOwner) external;

  /**
   * @dev deploy a ProxyAdmin contract used to upgrade locks
   */
  function initializeProxyAdmin() external;

  /**
   * Retrieve the contract address of the proxy admin that manages the locks
   * @return the address of the ProxyAdmin instance
   */
  function proxyAdminAddress()
    external
    view
    returns (address);

  /**
   * @notice Create lock (legacy)
   * This deploys a lock for a creator. It also keeps track of the deployed lock.
   * @param _expirationDuration the duration of the lock (pass 0 for unlimited duration)
   * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
   * @param _keyPrice the price of each key
   * @param _maxNumberOfKeys the maximum nimbers of keys to be edited
   * @param _lockName the name of the lock
   * param _salt [deprec] -- kept only for backwards copatibility
   * This may be implemented as a sequence ID or with RNG. It's used with `create2`
   * to know the lock's address before the transaction is mined.
   * @dev internally call `createUpgradeableLock`
   */
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName,
    bytes12 // _salt
  ) external returns (address);

  /**
   * @notice Create lock (default)
   * This deploys a lock for a creator. It also keeps track of the deployed lock.
   * @param data bytes containing the call to initialize the lock template
   * @dev this call is passed as encoded function - for instance:
   *  bytes memory data = abi.encodeWithSignature(
   *    'initialize(address,uint256,address,uint256,uint256,string)',
   *    msg.sender,
   *    _expirationDuration,
   *    _tokenAddress,
   *    _keyPrice,
   *    _maxNumberOfKeys,
   *    _lockName
   *  );
   * @return address of the create lock
   */
  function createUpgradeableLock(
    bytes memory data
  ) external returns (address);

  /**
   * Create an upgradeable lock using a specific PublicLock version
   * @param data bytes containing the call to initialize the lock template
   * (refer to createUpgradeableLock for more details)
   * @param _lockVersion the version of the lock to use
   */
  function createUpgradeableLockAtVersion(
    bytes memory data,
    uint16 _lockVersion
  ) external returns (address);

  /**
   * @notice Upgrade a lock to a specific version
   * @dev only available for publicLockVersion > 10 (proxyAdmin /required)
   * @param lockAddress the existing lock address
   * @param version the version number you are targeting
   * Likely implemented with OpenZeppelin TransparentProxy contract
   */
  function upgradeLock(
    address payable lockAddress,
    uint16 version
  ) external returns (address);

  /**
   * This function keeps track of the added GDP, as well as grants of discount tokens
   * to the referrer, if applicable.
   * The number of discount tokens granted is based on the value of the referal,
   * the current growth rate and the lock's discount token distribution rate
   * This function is invoked by a previously deployed lock only.
   */
  function recordKeyPurchase(
    uint _value,
    address _referrer // solhint-disable-line no-unused-vars
  ) external;

  /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function will keep track of consumed discounts by a given user.
   * It will also grant discount tokens to the creator who is granting the discount based on the
   * amount of discount and compensation rate.
   * This function is invoked by a previously deployed lock only.
   */
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens // solhint-disable-line no-unused-vars
  ) external view;

  /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function returns the discount available for a user, when purchasing a
   * a key from a lock.
   * This does not modify the state. It returns both the discount and the number of tokens
   * consumed to grant that discount.
   */
  function computeAvailableDiscountFor(
    address _purchaser, // solhint-disable-line no-unused-vars
    uint _keyPrice // solhint-disable-line no-unused-vars
  ) external pure returns (uint discount, uint tokens);

  // Function to read the globalTokenURI field.
  function globalBaseTokenURI()
    external
    view
    returns (string memory);

  /**
   * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalBaseTokenURI()
    external
    view
    returns (string memory);

  // Function to read the globalTokenSymbol field.
  function globalTokenSymbol()
    external
    view
    returns (string memory);

  // Function to read the chainId field.
  function chainId() external view returns (uint);

  /**
   * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalTokenSymbol()
    external
    view
    returns (string memory);

  /**
   * @notice Allows the owner to update configuration variables
   */
  function configUnlock(
    address _udt,
    address _weth,
    uint _estimatedGasForPurchase,
    string calldata _symbol,
    string calldata _URI,
    uint _chainId
  ) external;

  /**
   * @notice Add a PublicLock template to be used for future calls to `createLock`.
   * @dev This is used to upgrade conytract per version number
   */
  function addLockTemplate(
    address impl,
    uint16 version
  ) external;

  /**
   * Match lock templates addresses with version numbers
   * @param _version the number of the version of the template
   * @return address of the lock templates
   */
  function publicLockImpls(
    uint16 _version
  ) external view returns (address);

  /**
   * Match version numbers with lock templates addresses
   * @param _impl the address of the deployed template contract (PublicLock)
   * @return number of the version corresponding to this address
   */
  function publicLockVersions(
    address _impl
  ) external view returns (uint16);

  /**
   * Retrive the latest existing lock template version
   * @return the version number of the latest template (used to deploy contracts)
   */
  function publicLockLatestVersion()
    external
    view
    returns (uint16);

  /**
   * @notice Upgrade the PublicLock template used for future calls to `createLock`.
   * @dev This will initialize the template and revokeOwnership.
   */
  function setLockTemplate(
    address payable _publicLockAddress
  ) external;

  // Allows the owner to change the value tracking variables as needed.
  function resetTrackedValue(
    uint _grossNetworkProduct,
    uint _totalDiscountGranted
  ) external;

  function grossNetworkProduct()
    external
    view
    returns (uint);

  function totalDiscountGranted()
    external
    view
    returns (uint);

  function locks(
    address
  )
    external
    view
    returns (
      bool deployed,
      uint totalSales,
      uint yieldedDiscountTokens
    );

  // The address of the public lock template, used when `createLock` is called
  function publicLockAddress()
    external
    view
    returns (address);

  // Map token address to exchange contract address if the token is supported
  // Used for GDP calculations
  function uniswapOracles(
    address
  ) external view returns (address);

  // The WETH token address, used for value calculations
  function weth() external view returns (address);

  // The UDT token address, used to mint tokens on referral
  function udt() external view returns (address);

  // The approx amount of gas required to purchase a key
  function estimatedGasForPurchase()
    external
    view
    returns (uint);

  /**
   * Helper to get the network mining basefee as introduced in EIP-1559
   * @dev this helper can be wrapped in try/catch statement to avoid
   * revert in networks where EIP-1559 is not implemented
   */
  function networkBaseFee() external view returns (uint);

  // The version number of the current Unlock implementation on this network
  function unlockVersion() external pure returns (uint16);

  /**
   * @notice allows the owner to set the oracle address to use for value conversions
   * setting the _oracleAddress to address(0) removes support for the token
   * @dev This will also call update to ensure at least one datapoint has been recorded.
   */
  function setOracle(
    address _tokenAddress,
    address _oracleAddress
  ) external;

  // Initialize the Ownable contract, granting contract ownership to the specified sender
  function __initializeOwnable(address sender) external;

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() external view returns (bool);

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external;

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}