// SPDX-License-Identifier: MIT

/*                          
*                                          |`._         |\
*                                           `   `.  .    | `.    |`.
*                                            .    `.|`-. |   `-..'  \           _,.-'
*                                            '      `-. `.           \ /|   _,-'   /
*                                        .--..'        `._`           ` |.-'      /
*                                         \   |                                  /
*                                      ,..'   '                                 /
*                                      `.                                      /
*                                      _`.---                                 /
*                                  _,-'               `.                 ,-  /"-._
*                                ,"                   | `.             ,'|   `    `.           
*                              .'                     |   `.         .'  |    .     `.
*                            ,'                       '   ()`.     ,'()  '    |       `.
*'                          -.                    |`.  `.....-'    -----' _   |         .
*                           / ,   ________..'     '  `-._              _.'/   |         :
*                           ` '-"" _,.--"'         \   | `"+--......-+' //   j `"--.. , '
*                              `.'"    .'           `. |   |     |   / //    .       ` '
*                                `.   /               `'   |    j   /,.'     '
*                                  \ /                  `-.|_   |_.-'       /\
*                                   /                        `""          .'  \
*                                  j                                           .
*                                  |                                 _,        |
*                                  |             ,^._            _.-"          '
*                                  |          _.'    `'""`----`"'   `._       '
*                                  j__     _,'                         `-.'-."`
*                                     ',-.,' 
*                           ++======================================================++
*       `````^`                                                                                                                                        .'```'  
*       ``````^^                                                                                                                                      `````^` 
*       ^````^"^                                                                                                                                      `^^^""' 
*       ^````^"^                                                                                                                                       .''.   
*       ^````^"^                                                                                                                                              
*       ^````^"^                          `````^'                       `````^`      ..'```````````````````````^.  ``````^'                          .``````^`
*       ^````^"^         ..''.            ````^^`                       `````^^    .'`````^^"""""^^^``````````^^.  ``````^`                          ``'''``^^
*       ^`````^^      .'`````^^.          ^```^"`            .          ````^^"   .`````^",`'..     .`````````^^.  ``````^`                          ``'''``^^
*       ^`````^`...'``^^^^^^^"".          ^```^"`        `````^'        ````^^"   `````^,`        '``````''```^".  ``````^`                          ``'''``^^
*       ^`````^""""""""""",,"^.           ^```^"`        `````^`        `````^"  .````^"`       .```````.``'``^".  ``''``^`                         .``'''``^^
*       ^````^""                          ````^"`        ````^^`        `````^"  '````^"'     .```````` ``''``^^.  ``''``^`                         .``'''``^^
*       `````^""                 ......   ````^"`        ````^"`        `````^"  '````^"'    .```````^ '`''''``^.  ``''``^`                 ......  .``'''``^^
*       ``````^^            .''``````^^.  `````^`       .`````^`       .`````^"  '`````^.   '``'''``^' ``''''``^.  ``''``^`            .''```````^  .``'''``^^
*       ``````^`         .'``````````^^.  `````^'      '````````     .'``''``^"  '``''``'..'`''''```^..``''''``^.  ``''``^`         .'```'''''``^^  .``'''``^^
*       ^```````.  ...'``````````````^".  ^``````.''````````````''```````````^"  '````````````````^^^ .```````^".  ^```````......'``````````````^"  .```````^^
*       ^"^^^^^^^^^^^^^^^^^^^^^"""""",,.  "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"",,  ."^^^^^^^^^^^^^"",,' '"^^^^^"",.  ""^^^^^^^^^^^^^^^^^^^^^^^^^"",,  ."^^^^""""
*/
pragma solidity ^0.8.13;



import "./interfaces/IGnosisSafe.sol";
import "./helpers/Enum.sol";
// import "./SignatureVerify.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
interface GnosisSafe {
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
    external
    returns (bool success);
}                                                                                                                                                                                          

contract TwaliContract is Initializable, ReentrancyGuard {

    string public constant NAME = "Twali Contract Staging";
    string public constant VERSION = "1.0.0";

    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
 
    bytes32 public constant WERK_PAYMENT_TYPEHASH = 0x466dd9307c227be8c058cdb1b6581e98a4465f665734fe183f2a62d4f8f09118;
    // keccak256("Werk(string contract_sowMetaData, uint contract_start_date, uint contract_start_date)");

    bytes32 private DOMAIN_SEPARATOR = keccak256(abi.encode(
        DOMAIN_SEPARATOR_TYPEHASH,
        keccak256(bytes(NAME)),
        keccak256(bytes(VERSION)),
        5,
        address(this)));

    bool private isInitialized;
  

    struct WorkDetails {
        address owner;
        string contract_sowMetaData;
        uint contract_payment_amount;
        // Werk is approved or not approved yet
        bool contract_werkApproved; // unassigned variable has default value of 'false'
        // Werk has been paid out 
        bool contract_werkPaidOut;
        // Werk was refunded 
        bool contract_werkRefunded;
        // contract creation date
        uint contract_created_on;
        // experts start date in contract
        uint contract_start_date;
        // End date for werk completion 
        uint contract_end_date;
        // WerkExpert contractExpert;
    }

    struct WerkExpert {
        // expert address that is completion contract and recieving payment
        address contract_expert;
        // Contract amount to be paid 
        uint256 contract_payoutAmount;
        }

    // WorkDetails public werkdetails;
    WerkExpert public werkexpert;

    GnosisSafeProxyFactory gnosisSafeProxyFactory;

    mapping(address => mapping (uint256 => WorkDetails)) public werkdetails;


    /// @notice This contract has four 'status' stages that transitions through in a full contract cycle.
    /// Draft: Contract is in draft stage awaiting for applications and selection.
    /// Active: Contract is active and funded with pay out amount with a selected Contract Expert to complete werk.
    /// Complete: Contract werk is completed, approved by client, and Expert has recieved payment.
    /// Killed: Contract werk is canceled in draft stage or no longer active and client is refunded.
    enum Status { 
        Draft, Active, Complete, Killed
    }

    /// @dev Status: Contract is set to default status of 'Draft' on contract creation.
    Status private contract_currentStatus;
  
    // Events
    event ReceivedPayout(address, bool, bool);
    event RefundedPayment(address, uint);
    event ContractActivated(address, uint, uint);
    event DepoistedExpertPaynment(address, uint);


    /// @notice Functions cannot be called at the current stage.
    error InvalidCurrentStatus();


    // Note: Contract will escrow payments through Gnosis Safe. Will need to confirm this removal of fallback() & receive() functions.
    /// Execute on a call to contract if no other functions match given function signature.
    // fallback() external payable{}
    // receive() external payable{}


    /// @notice This initializer replaces the constructor to is the base input data for a new contract clone instances .
    /// @dev initialize(): Is also called within the clone contract in TwaliCloneFactory.sol.
    /// @param _adminClient the address of the contract owner who is the acting client.
    /// @param _sowMetaData Scope of work of the contract as a URI string.
    /// @param _contract_create_on is passed in from clone factory as the new contract is created.
    function initialize(
        address _adminClient,
        string memory _sowMetaData,
        uint _contract_payment_amount,
        uint _contract_start_date,
        uint _contract_end_date,
        uint _contract_create_on
    ) public initializer {
        require(!isInitialized, "Contract is already initialized");
        require(werkdetails[_adminClient][0].owner == address(0), "Contract is already initialized");
        werkdetails[_adminClient][0] = WorkDetails(_adminClient, _sowMetaData, _contract_payment_amount, false, false, false, _contract_start_date, _contract_end_date, _contract_create_on);
        isInitialized = true;
        gnosisSafeProxyFactory = GnosisSafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
    }

    /*
    *  Modifiers
    */ 

    /// @notice onlyOwner(): This is added to selected function calls to check and ensure only the 'owner'(client) of the contract is calling the selected function.
    modifier onlyOwner() {
        require(
            msg.sender == werkdetails[msg.sender][0].owner, 
            "Only owner can call this function"
            );
        _;
    }

    // / @notice This checks that the address being used is the expert address that is activated within the contract. If not, will throw an error.
    // / @dev isExpert(): This modifier is added to calls that need to confirm addresses passed into functions it the contract_expert.
    //// / @param _expert is an address passed in to check if it is expert. 
    // modifier isExpert(WerkExpert storage _WerkExpert) {
    //     require(_WerkExpert.contract_expert == WerkDetails.contractExpert, "Not contract expert address");
    //     _;
    // }

    /// @notice This checks that an address being passed into a function is a valid address and not a 0 address.
    /// @dev isValid(): Can be used in any function call that passes in a address that is not the contract owner.
    /// @param _addr: is normal wallet / contract address string.
    modifier isValid(address _addr) {
        require(_addr != address(0), "Not a valid address");
        _;
    }

    /// @notice This is added to function calls to be called at at all life cycle status stages,(e.g., only being able to call functions for 'Active' stage).
    /// @dev isStatus(): This is checking concurrently that a function call is being called at it's appropriate set stage order.
    /// @param _contract_currentStatus is setting the appropriate stage as a base parameter to check to with a function call.
    modifier isStatus(Status _contract_currentStatus) {
        if (contract_currentStatus != _contract_currentStatus)
            revert InvalidCurrentStatus();
        _;
    }

    /// @notice Simple check if werk has been paid out or not.
    // modifier werkNotPaid() {
    //     require(werkdetails.contract_werkPaidOut != true, "Werk already paid out!");
    //     _;
    // }

    /// @notice Simple check if werk has not been previously approved, (e.g., to check during a payout instance).
    // modifier werkNotApproved() {
    //     require(werkdetails.contract_werkApproved != true, "Werk already approved!");
    //     _;
    // }

    /// @notice Simple check that funds in contract has not been refunded.
    // modifier isNotRefunded() {
    //     require(werkdetails.contract_werkRefunded != true, "Refunded already!");
    //     _;
    // }

    /// @notice This is added to a function and once it is completed it will then move the contract to its next stage.
    /// @dev setNextStage(): Use's the function 'nextStage()' to transition to contracts next stage with one increment (+1).
    modifier setNextStage() {
        _;
        nextStage();
    }

    function getChainId() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function getWerkDetails(address _owner, uint256 index) public view returns (WorkDetails memory werkdetail) {
        werkdetail = werkdetails[_owner][index];
        return werkdetail;
    }

    // /// @notice Gets the current status of contract.
    function getCurrentStatus() public view returns (Status) {
        return contract_currentStatus;
    }

     /// @notice Simple call / read function that returns balance of contract.
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


    /// @dev This is the stage transition in the 'setNextStage' modifier.
    function nextStage() internal {
        contract_currentStatus = Status(uint(contract_currentStatus)+1);
    }

    /// @notice This will set a 'draft' contract to 'killed' stage if the contract needs to be closed.
    function killDraftContract() 
        external 
        onlyOwner
        isStatus(Status.Draft)
    {
        contract_currentStatus = Status.Killed;
    }

    // Note: Client ablility to set Expert into contract to be verified (may revert only to allowing the expert to set into contract themselves to conserve on gas fees).
    function addExpertDelegate(address _contract_expert) 
        external 
        onlyOwner
        isStatus(Status.Draft)
        {
        werkexpert.contract_expert = payable(_contract_expert);
    }



    /// @notice This enables the Client to deposit funds to the created contract instance for Expert to be paid (escrow form of contract).
    /// @dev depositExpertPayment(): is passed into / called from the activateContract, so that the client can fund the contract in addition to addding in selected Expert.
    /// @param _amount is the amount saved variable that is stored within the contract.
    function depositExpertPayment(uint _amount) public payable {
        require(_amount == msg.value, "Wrong amount of ETH sent");

        emit DepoistedExpertPaynment(msg.sender, msg.value);
    }

    // Note: Module Function to Gnosis Safe that will authorize to pull funds from safe to refund Client.
    // this can only be called within the 'KillDrafContract' function.
    function transferRefundPayment(GnosisSafe safe, address payable to, uint256 amount) 
    internal
    {   
        // Change the curent Workdetails Index state of contract_payment_amount = 0
        // Change the current Workdetails Index state of workrefunded = true
        require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer to Expert");

        // TODO: Set event emiter 
    }

    // Note: Module function to Gnosis Sage that sends information to be transacted from safe to pay out expert.
    function transferExpertPayment(GnosisSafe safe, address payable to, uint256 amount) external onlyOwner {

        require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer to Expert");
        // TODO: Set event emiter
    }
    
    /// @notice This is a contract activation to intialize Client & Expert Commencing werk.
    /// @dev activateContract(): Add's in selected Expert and activates Contract for Expert to begin completing werk.
    /// @param _contract_expert is the address of who is completing werk and receiving payment for werk completed.
    function activateContract(
        address _contract_expert,
        WorkDetails memory workObj,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS)
        external
        // payable 
        // onlyOwner
        // isValid(_contract_expert)
        isStatus(Status.Draft)
        setNextStage 
    { 
        signatureCheck(workObj, sigV, sigR, sigS);

        werkexpert.contract_expert = payable(_contract_expert); 

        // TODO: SET EVENT EMITER
    }


        function deploySafe(
        address _contract_owner,
        uint256 _saltNonce)
        external
        onlyOwner 
        returns (address) {
        GnosisSafe _safe = GnosisSafe(
            payable(
            gnosisSafeProxyFactory.createProxy(
                0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552,
                abi.encodePacked(_contract_owner, _saltNonce)
                )
            )
        );
    return (address(_safe));
    }

    /// @notice Sets an active contract to 'killed' stage and refunds ETH in contract to the client, who is the set contract 'owner'.
    /// @dev killActiveContract(): 
    function killActiveContract(GnosisSafe safe, address payable to, uint256 amount) 
        external 
        onlyOwner
        // isNotRefunded 
        nonReentrant 
        isStatus(Status.Active) 
    {
        contract_currentStatus = Status.Killed;
        transferRefundPayment(safe, to, amount);
    }


    //  Note: Hash to validate the structured data that is signed is the authorized signing expert
    function hashDetails(WorkDetails memory workObj) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01", // initial 0x19 byte & verison byte (EIP712 structured data -> https://eips.ethereum.org/EIPS/eip-191)
            DOMAIN_SEPARATOR, // validator address
            keccak256(abi.encode(
                WERK_PAYMENT_TYPEHASH,
                keccak256(bytes(workObj.contract_sowMetaData))
            ))
        ));
    }


    // Note: Signature check function that determines if the signer is the authorized expert address
    function signatureCheck(WorkDetails memory _Objmsg, uint8 sigV, bytes32 sigR, bytes32 sigS) internal view returns (bool) {
       address signer = ecrecover(hashDetails(_Objmsg), sigV, sigR, sigS);
       require(signer != address(0), "ECDSA: invalid signature");
       return signer == werkexpert.contract_expert;
    }

    /// @notice This is called when an expert completes werk and client will then approve that werk is completed allowing for expert to be paid.
    /// @dev approveWorkSubmitted(): 
    /// 
    // function approveWorkSubmitted() 
    //     public 
    //     onlyOwner
    //     werkNotApproved
    //     werkNotPaid
    //     isStatus(Status.Active) 
    //     nonReentrant
    //     setNextStage 
    // {
    //     WerkDetails storage werkdetails;
    //     werkdetails.contract_werkApproved = true;
    //     werkdetails.contract_werkPaidOut = true;
    //     emit ReceivedPayout(contract_expert, 
    //                         contract_werkPaidOut, 
    //                         contract_werkApproved);
                            
    //     uint256 balance = address(this).balance;
    //     contract_expert.transfer(balance);
    // }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Enum {
    enum Operation {
        Call,
        DelegarteCall
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../helpers/Enum.sol";
interface IGnosisSafe {
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
    external
    returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./GnosisSafeProxy.sol";
import "./IProxyCreationCallback.sol";

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <[email protected]>
contract GnosisSafeProxyFactory {
    event ProxyCreation(GnosisSafeProxy proxy, address singleton);

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param singleton Address of singleton contract.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address singleton, bytes memory data) public returns (GnosisSafeProxy proxy) {
        proxy = new GnosisSafeProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, singleton);
    }

    /// @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).runtimeCode;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).creationCode;
    }

    /// @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
    ///      This method is only meant as an utility to be called from other methods
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function deployProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) internal returns (GnosisSafeProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(GnosisSafeProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        if (initializer.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, _singleton);
    }

    /// @dev Allows to create new proxy contact, execute a message call to the new proxy and call a specified callback within one transaction
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// @param callback Callback that will be invoced after the new proxy contract has been successfully deployed and initialized.
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (GnosisSafeProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }

    /// @dev Allows to get the address for a new proxy contact created via `createProxyWithNonce`
    ///      This method is only meant for address calculation purpose when you use an initializer that would revert,
    ///      therefore the response is returned with a revert. When calling this method set `from` to the address of the proxy factory.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function calculateCreateProxyWithNonceAddress(
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        revert(string(abi.encodePacked(proxy)));
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IProxy {
    function masterCopy() external view returns (address);
}

/// @title GnosisSafeProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeProxy {
    // singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal singleton;

    /// @dev Constructor function sets address of singleton contract.
    /// @param _singleton Singleton address.
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./GnosisSafeProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(
        GnosisSafeProxy proxy,
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external;
}