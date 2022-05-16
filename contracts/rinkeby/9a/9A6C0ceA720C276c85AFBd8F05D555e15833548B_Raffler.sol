// SPDX-License-Identifier: UNLICENSED
/*
   ___  ___ _  _  ___ 
  / _ \| _ \ \| |/ __|
 | (_) |   / .` | (_ |
  \__\_\_|_\_|\_|\___|
                      
*/
/// @title Raffle Contract as PoC for using QRNGs
/// @notice This contract is not secure. Do not use it in production. Refer to
/// the contract for more information.
/// @dev See README.md for more information.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";

contract Raffler is RrpRequesterV0 {
    using Counters for Counters.Counter;
    Counters.Counter private _ids;

    event RaffleCreated(uint256 _raffleId);

    mapping(uint256 => Raffle) public raffles;
    mapping(address => uint256[]) public accountRaffles;

    // To store pending Airnode requests
    mapping(bytes32 => bool) public pendingRequestIds;
    mapping(bytes32 => uint256) private requestIdToRaffleId;

    // These variables can also be declared as `constant`/`immutable`.
    // However, this would mean that they would not be updatable.
    // Since it is impossible to ensure that a particular Airnode will be
    // indefinitely available, you are recommended to always implement a way
    // to update these parameters.
    address public airnodeRrpAddress;
    address public sponsor;
    address public sponsorWallet;
    address public ANUairnodeAddress =
        0x9d3C147cA16DB954873A498e0af5852AB39139f2;
    bytes32 public endpointId =
        0x27cc2713e7f968e4e86ed274a051a5c8aaee9cca66946f23af6f29ecea9704c3;

    struct Raffle {
        uint256 id;
        string title;
        uint256 price;
        uint256 winnerCount;
        address[] winners;
        address[] entries;
        bool open;
        uint256 startTime;
        uint256 endTime;
        uint256 balance;
        address owner;
        bool airnodeSuccess;
    }

    /// @param _airnodeRrpAddress Airnode RRP contract address (https://docs.api3.org/airnode/v0.6/reference/airnode-addresses.html)
    /// @param _sponsorWallet Sponsor Wallet address (https://docs.api3.org/airnode/v0.6/concepts/sponsor.html#derive-a-sponsor-wallet)
    constructor(address _airnodeRrpAddress, address _sponsorWallet)
        RrpRequesterV0(_airnodeRrpAddress)
    {
        airnodeRrpAddress = _airnodeRrpAddress;
        sponsorWallet = _sponsorWallet;
        sponsor = msg.sender;
    }

    /// @notice Create a new raffle
    /// @param _price The price to enter the raffle
    /// @param _winnerCount The number of winners to be selected
    /// @param _title Title of the raffle
    /// @param _startTime Time the raffle starts
    /// @param _endTime Time the raffle ends
    function create(
        uint256 _price,
        uint16 _winnerCount,
        string memory _title,
        uint256 _startTime,
        uint256 _endTime
    ) public {
        require(_winnerCount > 0, "Winner count must be greater than 0");
        _ids.increment();
        Raffle memory raffle = Raffle(
            _ids.current(),
            _title,
            _price,
            _winnerCount,
            new address[](0),
            new address[](0),
            true,
            _startTime,
            _endTime,
            0,
            msg.sender,
            false
        );
        raffles[raffle.id] = raffle;
        accountRaffles[msg.sender].push(raffle.id);
        emit RaffleCreated(raffle.id);
    }

    /// @notice Enter a raffle
    /// @dev To enter more than one entry, send the price * entryCount in
    /// the transaction.
    /// @param _raffleId The raffle id to enter
    /// @param entryCount The number of entries to enter
    function enter(uint256 _raffleId, uint256 entryCount) public payable {
        Raffle storage raffle = raffles[_raffleId];
        require(raffle.open, "Raffle is closed");
        require(entryCount >= 1, "Entry count must be at least 1");
        require(
            block.timestamp >= raffle.startTime &&
                block.timestamp <= raffle.endTime,
            "Raffle is closed"
        );
        require(
            msg.value == raffle.price * entryCount,
            "Entry price does not match"
        );
        raffle.balance += msg.value;
        for (uint256 i = 0; i < entryCount; i++) {
            raffle.entries.push(msg.sender);
        }
    }

    /// @notice Close a raffle
    /// @dev Called by the raffle owner when the raffle is over.
    /// This function will close the raffle to new entries and will
    /// call Airnode for randomness.
    /// @dev send at least .001 ether to fund the sponsor wallet
    /// @param _raffleId The raffle id to close
    function close(uint256 _raffleId) public payable {
        Raffle storage raffle = raffles[_raffleId];
        require(
            msg.sender == raffle.owner,
            "Only raffle owner can pick winners"
        );
        require(raffle.open, "Raffle is closed");

        if (raffle.entries.length == 0) {
            raffle.open = false;
            return;
        }
        require(
            raffle.entries.length >= raffle.winnerCount,
            "Not enough entries"
        );

        // Top up the Sponsor Wallet
        require(
            msg.value >= .001 ether,
            "Please send some funds to the sponsor wallet"
        );
        payable(sponsorWallet).transfer(msg.value);

        bytes32 requestId = airnodeRrp.makeFullRequest(
            ANUairnodeAddress,
            endpointId,
            sponsor,
            sponsorWallet,
            address(this),
            this.pickWinners.selector,
            abi.encode(bytes32("1u"), bytes32("size"), raffle.winnerCount)
        );
        pendingRequestIds[requestId] = true;
        requestIdToRaffleId[requestId] = _raffleId;
        raffle.open = false;
    }

    /// @notice Randomness returned by Airnode is used to choose winners
    /// @dev Only callable by Airnode.
    function pickWinners(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(pendingRequestIds[requestId], "No such request made");
        delete pendingRequestIds[requestId];
        Raffle storage raffle = raffles[requestIdToRaffleId[requestId]];
        require(!raffle.airnodeSuccess, "Winners already picked");

        uint256[] memory randomNumbers = abi.decode(data, (uint256[])); // array of random numbers returned by Airnode
        for (uint256 i = 0; i < randomNumbers.length; i++) {
            uint256 winnerIndex = randomNumbers[i] % raffle.entries.length;
            raffle.winners.push(raffle.entries[winnerIndex]);
            removeAddress(winnerIndex, raffle.entries);
        }
        raffle.airnodeSuccess = true;
        payable(raffle.owner).transfer(raffle.balance);
    }

    /// @notice Get the raffle entries
    /// @param _raffleId The raffle id to get the entries of
    function getEntries(uint256 _raffleId)
        public
        view
        returns (address[] memory)
    {
        return raffles[_raffleId].entries;
    }

    /// @notice Get the raffle winners
    /// @param _raffleId The raffle id to get the winners of
    function getWinners(uint256 _raffleId)
        public
        view
        returns (address[] memory)
    {
        return raffles[_raffleId].winners;
    }

    function isWinner(uint256 _raffleId, address _address)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < raffles[_raffleId].winners.length; i++) {
            if (raffles[_raffleId].winners[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getAccountRaffles(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return accountRaffles[_account];
    }

    function removeAddress(uint256 index, address[] storage array) private {
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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