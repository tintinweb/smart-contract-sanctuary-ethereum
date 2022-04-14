//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequester.sol";

contract Requester is RrpRequester {
    // Hardcoded API_ID. This should be filled out using the constructor,
    // e.g. when customers are deploying their smart contract
    uint256 API_ID = 1;

    /// Check against the whitelisted mapping
    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "msg.sender is not in whitelist.");
        _;
    }
    mapping(address => bool) public whitelisted;
    mapping(bytes32 => bool) public incomingFulfillments;

    // Probably not useful. Leaving here just to match the make-request script.
    mapping(bytes32 => bytes) public fulfilledData;

    // Using bool, to see if this thing even works
//    mapping(bytes32 => bool) public fulfilledData;

    constructor(address airnodeAddress) RrpRequester(airnodeAddress) {}

    // This function will be called by end-users.
    // This will check whether the user has been whitelisted, against an API endpoint.
    //
    // Currently, the callData parameters is unused.
    function makeRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        bytes calldata parameters
    ) external {
        // See https://docs.api3.org/airnode/v0.5/reference/specifications/airnode-abi-specifications.html
        bytes memory standardParameters = abi.encode(
            bytes32("1B"),
            bytes32("payload"), abi.encode(
                bytes32("1uaa"),
                bytes32("API_ID"), API_ID,
                bytes32("endUserAddress"), msg.sender,
                bytes32("requesterAddress"), address(this)
            )
        );

        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointId,
            sponsor,
            sponsorWallet,
            address(this),
            this.fulfill.selector,
            standardParameters
        );
        incomingFulfillments[requestId] = true;
    }

    // Testing the onlyWhitelisted modifier
    function mockMint()
    external
    onlyWhitelisted
    view
    returns (bool)
    {
        return true;
    }

    function mockFulfill(bytes calldata data)
        public
        returns(bool)
    {
        (
        bytes32 header,
        bytes32 paramName1, address endUserAddress,
        bytes32 paramName2, bool isCheckPassed
        ) = abi.decode(data, (bytes32, bytes32, address, bytes32, bool));

        return isCheckPassed;
    }

    // If the end-user address is marked as whitelisted on the server,
    // add said address to the smart contract's whitelisted mapping.
    function fulfill(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
//        fulfilledData[requestId] = data;
        // Using bool, to see if this thing even works
//        bool apiSuccess = abi.decode(data, (bool));
//        fulfilledData[requestId] = apiSuccess;
//
        bytes memory decodedData = abi.decode(data, (bytes));
        // Currently works while commenting out all of the decoding part.
        (
            bytes32 header,
            bytes32 paramName1, address endUserAddress,
            bytes32 paramName2, bool isCheckPassed
        ) = abi.decode(decodedData, (bytes32, bytes32, address, bytes32, bool));

        if (isCheckPassed) {
            whitelisted[endUserAddress] = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IAirnodeRrp.sol";

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequester {
    IAirnodeRrp public immutable airnodeRrp;

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
        airnodeRrp = IAirnodeRrp(_airnodeRrp);
        IAirnodeRrp(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAuthorizationUtils.sol";
import "./ITemplateUtils.sol";
import "./IWithdrawalUtils.sol";

interface IAirnodeRrp is IAuthorizationUtils, ITemplateUtils, IWithdrawalUtils {
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
pragma solidity 0.8.9;

interface IAuthorizationUtils {
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
pragma solidity 0.8.9;

interface ITemplateUtils {
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
pragma solidity 0.8.9;

interface IWithdrawalUtils {
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