// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthorizationUtilsV0.sol";
import "./ITemplateUtilsV0.sol";
import "./IWithdrawalUtilsV0.sol";

interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirnodeRrpV0.sol";

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { DataTypes } from "../../libraries/DataTypes.sol";
import { Events } from "../../libraries/Events.sol";
import { Errors } from "../../libraries/Errors.sol";

import { RrpRequesterV0 } from "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AirnodeLogic
 * @author API3 Latam
 *
 * @notice This is an abstract contract to be inherited by the modules
 * which are going to make use of an Airnode.
 */
abstract contract AirnodeLogic is 
    RrpRequesterV0,
    Ownable
{
    // ========== Storage ==========
    address public airnode;              // The address of the QRNG airnode.
    address internal derivedAddress;     // The derived address to be sponsored.
    address internal sponsorAddress;      // The sponsored wallet address that will pay for fulfillments.
    
    DataTypes.Endpoint[] public endpointsIds; // The storage for endpoints data.
    
    mapping(bytes4 => uint256) public callbackToIndex;      // The mapping of functions to their index in the array.
    mapping(bytes32 => bool) internal incomingFulfillments; // The list of ongoing fulfillments.
    
    // ========== Modifiers ==========
    /**
     * @notice Validates if the given requestId exists.
     * @dev Is up to each requester how to deal with edge cases
     * of missing requests.
     *
     * @param _requestId The requestId being used.
     */
    modifier validRequest (
        bytes32 _requestId
    ) {
        if (incomingFulfillments[_requestId] == false) {
            revert Errors.RequestIdNotKnown();
        }
        _;
    }

    // ========== Constructor ==========
    /**
     * @notice Constructor function for AirnodeLogic contract.
     *
     * @param _airnodeRrp The RRP contract address for the network being deploy. 
     */
    constructor (
        address _airnodeRrp
    ) RrpRequesterV0 (
        _airnodeRrp
    ) {}

    // ========== Core Functions ==========
    /**
     * @notice Boilerplate to implement airnode calls.
     * @dev This function should be overwritten to include further
     * pre or post processing of airnode calls with a hook.
     *
     * @param _functionSelector - The target endpoint to use as callback.
     * @param parameters - The data for the API endpoint.
     */
    function callAirnode (
        bytes4 _functionSelector,
        bytes memory parameters
    ) internal virtual returns (
        bytes32
    ) {}

    // ========== Get/Set Functions ==========
    /** 
     * @notice Sets parameters used in requesting QRNG services.
     * @dev Pending to add access control.
     *
     * @param _airnode - The Airnode address for the QRNG.
     * @param _derivedAddress - The derived address to sponsor.
     * @param _sponsorAddress - The actual sponsorer address.
     */
    function setRequestParameters (
        address _airnode,
        address _derivedAddress,
        address _sponsorAddress
    ) external onlyOwner {
        airnode = _airnode;
        derivedAddress = _derivedAddress;
        sponsorAddress = _sponsorAddress;
        emit Events.SetRequestParameters(
            _airnode,
            _derivedAddress,
            _sponsorAddress
        );
    }

    /**
     * @notice Function to push endpoints to the `endpointsIds` array.
     * @dev Pending adding access control.
     *
     * @param _endpointId - The identifier for the airnode endpoint.
     * @param _endpointFunction - The function selector to point the callback to.
     */
    function addNewEndpoint (
        bytes32 _endpointId,
        string memory _endpointFunction
    ) external onlyOwner {
        bytes4 _endpointSelector =  bytes4(keccak256(bytes(_endpointFunction)));

        DataTypes.Endpoint memory endpointToPush = DataTypes.Endpoint(
            _endpointId,
            _endpointSelector
        );

        endpointsIds.push(endpointToPush);
        callbackToIndex[_endpointSelector] = endpointsIds.length - 1;

        emit Events.SetAirnodeEndpoint(
            endpointsIds.length - 1,
            _endpointId,
            _endpointFunction,
            _endpointSelector
        );
    }

    /**
     * @notice Function to get the fulfillment status from a request.
     *
     * @param _requestId The id of the desired request.
     *
     * @return _notFulfilled Boolean True if is yet to be fulfilled 
     *  or False if does not exists or is already fulfilled.
     */
    function getIncomingFulfillments (
        bytes32 _requestId
    ) external view onlyOwner returns (
        bool _notFulfilled
    ) {
        return incomingFulfillments[_requestId];
    }

    // ========== Utilities Functions ==========
    /**
     */
    function withdraw()
     external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Checks wether and endpoint exists and
     * if it corresponds with the registered index.
     *
     * @param _selector The function selector to look for.
     */
    function _beforeFullfilment (
        bytes4 _selector
    ) internal virtual returns (
        DataTypes.Endpoint memory
    ) {
        uint256 endpointIdIndex = callbackToIndex[_selector];
        
        if (endpointIdIndex == 0 && endpointsIds.length == 0) {
            revert Errors.NoEndpointAdded();
        }

        DataTypes.Endpoint memory _currentEndpoint = endpointsIds[endpointIdIndex];

        // This two validations will be useful when update mechanism is added for endpoints.
        if (_currentEndpoint.endpointId.length == 0) {
            revert Errors.InvalidEndpointId();
        }

        if (_currentEndpoint.functionSelector != _selector) {
            revert Errors.IncorrectCallback();
        }

        return _currentEndpoint;
    }

    /**
     * @notice - Basic hook for airnode callback functions.
     * @dev - You should manually add them to the specific airnode defined callbacks.
     * We suggest further personalization trough overriding it for each specific need.
     *
     * @param _requestId - The id of the request for this fulfillment.
     * @param _airnodeAddress - The address from the airnode of this fulfillment.
     */
    function _afterFulfillment (
        bytes32 _requestId,
        address _airnodeAddress
    ) internal virtual {
        emit Events.SuccessfulRequest(
            _requestId,
            _airnodeAddress
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { AirnodeLogic } from "../../base/AirnodeLogic.sol";
import { IWinnerAirnode } from "../../../interfaces/IWinnerAirnode.sol";
import { DataTypes } from "../../../libraries/DataTypes.sol";
import { Events } from "../../../libraries/Events.sol";
import { Errors } from "../../../libraries/Errors.sol";

/**
 * @title WinnerAirnode
 * @author API3 Latam
 *
 * @notice This is the contract implementation to pick winners for raffles
 * using the QRNG oracle.
 * @dev Pending access control for Raffle Role. To modify `requestToRaffle`.
 */
contract WinnerAirnode is 
    AirnodeLogic,
    IWinnerAirnode
{
    // ========== Storage ==========
    // Raffle airnode metadata for each request.
    mapping(bytes32 => DataTypes.WinnerReponse) internal requestToRaffle;

    // ========== Constructor ==========
    constructor (
        address _airnodeRrpAddress
    ) AirnodeLogic (
        _airnodeRrpAddress
    ) {}

    // ========== Core Functions ==========
    /**
     * @dev See { AirnodeLogic-callAirnode }.
     */
    function callAirnode (
        bytes4 _functionSelector,
        bytes memory _parameters
    ) internal override returns (
        bytes32
    ) {
        DataTypes.Endpoint memory currentEndpoint = _beforeFullfilment(
            _functionSelector
        );

        bytes32 _requestId = airnodeRrp.makeFullRequest(
            airnode,
            currentEndpoint.endpointId,
            sponsorAddress,
            derivedAddress,
            address(this),
            currentEndpoint.functionSelector,
            _parameters
        );

        incomingFulfillments[_requestId] = true;

        return _requestId;
    }

    /**
     * @dev See { IWinnerAirnode-requestWinners }.
     */
    function requestWinners (
        bytes4 callbackSelector,
        uint256 winnerNumbers,
        uint256 participantNumbers
    ) external override returns (
        bytes32
    ) {
        bytes32 requestId;

        if (participantNumbers == 0 || winnerNumbers == 0) revert Errors.InvalidParameter();
        if (winnerNumbers > participantNumbers) revert Errors.InvalidWinnerNumber();

        if (winnerNumbers == 1) {
            requestId = callAirnode(
                callbackSelector,
                ""
            );
        } else {
            requestId = callAirnode(
                callbackSelector,
                abi.encode(bytes32("1u"), bytes32("size"), winnerNumbers)
            );
        }

        requestToRaffle[requestId].totalEntries = participantNumbers;
        requestToRaffle[requestId].totalWinners = winnerNumbers;

        emit Events.NewWinnerRequest(
            requestId,
            airnode
        );

        return requestId;
    }

    /**
     * @dev See { IWinnerAirnode-requestResults }
     */
    function requestResults (
        bytes32 requestId
    ) external override returns (
        DataTypes.WinnerReponse memory
    ) {
        DataTypes.WinnerReponse memory result = requestToRaffle[requestId];

        if (result.isFinished) revert Errors.ResultRetrieved();

        requestToRaffle[requestId].isFinished = true;
        
        return result;
    }

    // ========== Callback Functions ==========
    /**
     * @dev See { IWinnerAirnode-getIndividualWinner }.
     */
    function getIndividualWinner (
        bytes32 requestId,
        bytes calldata data
    ) external virtual override onlyAirnodeRrp validRequest(requestId) {

        uint256 qrngUint256 = abi.decode(data, (uint256));

        DataTypes.WinnerReponse memory raffleData = requestToRaffle[requestId];

        uint256 winnerIndex = qrngUint256 % raffleData.totalEntries;

        requestToRaffle[requestId].winnerIndexes.push(winnerIndex);
        incomingFulfillments[requestId] = false;

        _afterFulfillment(
            requestId,
            airnode
        );
    }

    /**
     * @dev See { IWinnerAirnode-getMultipleWinners }.
     */
    function getMultipleWinners (
        bytes32 requestId,
        bytes calldata data
    ) external virtual override onlyAirnodeRrp validRequest(requestId) {

        DataTypes.WinnerReponse memory raffleData = requestToRaffle[requestId];
        
        uint256[] memory qrngUint256Array = abi.decode(data, (uint256[]));

        for (uint256 i; i < raffleData.totalWinners; i++) {
            requestToRaffle[requestId].winnerIndexes.push(
                qrngUint256Array[i] % raffleData.totalEntries
            );
        }

        incomingFulfillments[requestId] = false;

        _afterFulfillment(
            requestId,
            airnode
        );
    }

    // ========== Get/Set Functions ==========
    /**
     * @dev See { IWinnerAirnode-getRequestToRaffle }.
     */
    function getRequestToRaffle (
        bytes32 requestId
    ) external view override onlyOwner returns (
        DataTypes.WinnerReponse memory _winnerReponse
    ) {
        return requestToRaffle[requestId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title IWinnerAirnode
 * @author API3 Latam
 *
 * @notice This is the interface for the Winner Airnode,
 * which is initialized utilized when closing up a raffle.
 */
interface IWinnerAirnode {
    // ========== Core Functions ==========
    /**
     * @notice - The function to request this airnode implementation call.
     *
     * @param callbackSelector - The target endpoint to use as callback.
     * @param winnerNumbers - The number of winners to return
     * @param participantNumbers - The number of participants from the raffle.
     */
    function requestWinners (
        bytes4 callbackSelector,
        uint256 winnerNumbers,
        uint256 participantNumbers
    ) external returns (
        bytes32
    );

    /**
     * @notice Return the results from a given request.
     *
     * @param requestId The request to get results from.
     */
    function requestResults (
        bytes32 requestId
    ) external returns (
        DataTypes.WinnerReponse memory
    );

    // ========== Callback Functions ==========
    /**
     * @notice - Callback function when requesting one winner only.
     * @dev - We suggest to set this as endpointId index `1`.
     *
     * @param requestId - The id for this request.
     * @param data - The response from the API send by the airnode.
     */
    function getIndividualWinner (
        bytes32 requestId,
        bytes calldata data
    ) external;

    /**
     * @notice - Callback function when requesting multiple winners.
     * @dev - We suggest to set this as endpointId index `2`.
     *
     * @param requestId - The id for this request.
     * @param data - The response from the API send by the airnode. 
     */
    function getMultipleWinners (
        bytes32 requestId,
        bytes calldata data
    ) external;

    // ========== Get/Set Functions ==========
    /**
     * @notice Function to get the output of a raffle request.
     *
     * @param requestId The request ID of the raffle request.
     *
     * @return _winnerReponse The metadata for the request result.
     */
    function getRequestToRaffle (
        bytes32 requestId
    ) external view returns (
        DataTypes.WinnerReponse memory _winnerReponse
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title DataTypes
 * @author API3 Latam
 * 
 * @notice A standard library of data types used across the API3 LATAM
 * Fairness Platform.
 */
library DataTypes {
    
    // ========== Enums ==========
    /**
     * @notice An enum containing the different states a raffle can use.
     *
     * @param Unintialized - A raffle is created but yet to be open.
     * @param Canceled - A raffle that is invalidated.
     * @param Open - A raffle where participants can enter.
     * @param Close - A raffle which cannot recieve more participants.
     * @param Finish - A raffle that has been wrapped up.
     */
    enum RaffleStatus {
        Unintialized,
        Canceled,
        Open,
        Close,
        Finish
    }

    // ========== Structs ==========
    /**
     * @notice An enum containing the 
     */

    /**
     * @notice Structure to efficiently save IPFS hashes.
     * @dev To reconstruct full hash insert `hash_function` and `size` before the
     * the `hash` value. So you have `hash_function` + `size` + `hash`.
     * This gives you a hexadecimal representation of the CIDs. You need to parse
     * it to base58 from hex if you want to use it on a traditional IPFS gateway.
     *
     * @param hash - The hexadecimal representation of the CID payload from the hash.
     * @param hash_function - The hexadecimal representation of multihash identifier.
     * IPFS currently defaults to use `sha2` which equals to `0x12`.
     * @param size - The hexadecimal representation of `hash` bytes size.
     * Expecting value of `32` as default which equals to `0x20`. 
     */
    struct Multihash {
        bytes32 hash;
        uint8 hash_function;
        uint8 size;
    }

    /**
     * @notice Information for Airnode endpoints.
     *
     * @param endpointId - The unique identifier for the endpoint this
     * callbacks points to.
     * @param functionSelector - The function selector for this endpoint
     * callback.
     */
    struct Endpoint {
        bytes32 endpointId;
        bytes4 functionSelector;
    }

    /**
     * @notice Metadata information for WinnerAirnode request flow.
     * @dev This should be consume by used in addition to IndividualRaffle struct
     * to return actual winner addresses.
     *
     * @param totalEntries - The number of participants for this raffle.
     * @param totalWinners - The number of winners finally set for this raffle.
     * @param winnerIndexes - The indexes for the winners from raffle entries.
     * @param isFinished - Indicates wether the result has been retrieved or not.
     */
    struct WinnerReponse {
        uint256 totalEntries;
        uint256 totalWinners;
        uint256[] winnerIndexes;
        bool isFinished;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Errors
 * @author API3 Latam
 * 
 * @notice A standard library of error types used across the API3 LATAM
 * Raffle Platform.
 */
library Errors {

    // ========== Core Errors ==========
    error SameValueProvided ();
    error AlreadyInitialized ();
    error InvalidProxyAddress (
        address _proxy
    );
    error ZeroAddress();
    error WrongInitializationParams (
        string errorMessage
    );
    error InvalidParameter();
    error ParameterNotSet();
    error RaffleNotOpen ();             // Raffle
    error RaffleNotAvailable ();        // Raffle
    error RaffleNotClose ();            // Raffle
    error RaffleAlreadyOpen ();         // Raffle
    error EarlyClosing();               // Raffle

    // ========== Base Errors ==========
    error CallerNotOwner (               // Ownable ERC721
        address caller
    );
    error RequestIdNotKnown ();          // AirnodeLogic
    error NoEndpointAdded ();            // AirnodeLogic
    error InvalidEndpointId ();          // AirnodeLogic
    error IncorrectCallback ();          // AirnodeLogic

    // ========== Airnode Module Errors ==========
    error InvalidWinnerNumber ();        // WinnerAirnode
    error ResultRetrieved ();            // WinnerAirnode

    // ========== Vault Module Errors ==========
    error VaultWithdrawsDisabled ();     // AssetVault
    error VaultWithdrawsEnabled ();      // AssetVault
    error TokenIdOutOfBounds (           // VaultFactory
        uint256 tokenId
    );
    error NoTransferWithdrawEnabled (    // VaultFactory
        uint256 tokenId
    );
    error BatchLengthMismatch();         // VaultDepositRouter

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { DataTypes } from "./DataTypes.sol";

/**
 * @title Events
 * @author API3 Latam
 * 
 * @notice A standard library of Events used across the API3 LATAM
 * Raffle Platform.
 */
library Events {

    // ========== Core Events ==========
    /**
     * @dev Emitted when a Raffle is created.
     * 
     * @param _raffleId - The identifier for this specific raffle.
     */
    event RaffleCreated (
        uint256 indexed _raffleId
    );

    /**
     * @dev Emitted when the winners are set from the QRNG provided data.
     *
     * @param _raffleId - The identifier for this specific raffle.
     * @param raffleWinners - The winner address list for this raffle.
     */
    event WinnerPicked (
        uint256 indexed _raffleId,
        address[] raffleWinners
    );

        // ========== Base Events ==========
    /**
     * @dev Emitted when we set the parameters for the airnode.
     *
     * @param airnodeAddress - The Airnode address being use.
     * @param derivedAddress - The derived address for the airnode-sponsor.
     * @param sponsorAddress - The actual sponsor wallet address.
     */
    event SetRequestParameters (
        address airnodeAddress,
        address derivedAddress,
        address sponsorAddress
    );

    /**
     * @dev Emitted when a new Endpoint is added to an AirnodeLogic instance.
     *
     * @param _index - The current index for the recently added endpoint in the array.
     * @param _newEndpointId - The given endpointId for the addition.
     * @param _newEndpointSelector - The selector for the given endpoint of this addition.
     */
    event SetAirnodeEndpoint (
        uint256 indexed _index,
        bytes32 indexed _newEndpointId,
        string _endpointFunction,
        bytes4 _newEndpointSelector
    );

    // ========== Airnode Module Events ==========
    /**
     * @dev Should be emitted when a request to WinnerAirnode is done.
     *
     * @param requestId - The request id which this event is related to.
     * @param airnodeAddress - The airnode address from which this request was originated.
     */
    event NewWinnerRequest (
        bytes32 indexed requestId,
        address indexed airnodeAddress
    );

    /**
     * @dev Same as `NewRequest` but, emitted at the callback time when
     * a request is successful for flow control.
     *
     * @param requestId - The request id from which this event was emitted.
     * @param airnodeAddress - The airnode address from which this request was originated.
     */
    event SuccessfulRequest (
        bytes32 indexed requestId,
        address indexed airnodeAddress
    );

    // ========== Vault Module Events ==========
    /**
     * @dev Should be emitted when withdrawals are enabled on a vault.
     *
     * @param emitter The address of the vault owner.
     */
    event WithdrawEnabled (
        address emitter
    );
    
    /**
     * @dev Should be emitted when the balance of ERC721s is withdraw
     * from a vault.
     *
     * @param emitter The address of the vault owner.
     * @param recipient The end user to recieve the assets.
     * @param tokenContract The addresses of the assets being transfered.
     * @param tokenId The id of the token being transfered.
     */
    event WithdrawERC721 (
        address indexed emitter,
        address indexed recipient,
        address indexed tokenContract,
        uint256 tokenId
    );

    /**
     * @dev Should be emitted when factory creates a new vault clone.
     *
     * @param vault The address of the new vault.
     * @param to The new owner of the vault.
     */
    event VaultCreated (
        address vault,
        address to
    );
}