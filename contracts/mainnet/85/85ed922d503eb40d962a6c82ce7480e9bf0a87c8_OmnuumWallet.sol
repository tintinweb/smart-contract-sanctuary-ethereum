// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/// @title OmnuumWallet Allows multiple owners to agree to withdraw money, add/remove/change owners before execution
/// @notice This contract is not managed by Omnuum admin, but for owners
/// @author Omnuum Dev Team <[email protected]>

import '@openzeppelin/contracts/utils/math/Math.sol';

contract OmnuumWallet {
    /// @notice consensusRatio Ratio of votes to reach consensus as a percentage of total votes
    uint256 public immutable consensusRatio;

    /// @notice Minimum limit of required number of votes for consensus
    uint8 public immutable minLimitForConsensus;

    /// @notice Withdraw = 0
    /// @notice Add = 1
    /// @notice Remove = 2
    /// @notice Change = 3
    /// @notice Cancel = 4
    enum RequestTypes {
        Withdraw,
        Add,
        Remove,
        Change,
        Cancel
    }

    /// @notice F = 0 (F-Level Not owner)
    /// @notice D = 1 (D-Level own 1 vote)
    /// @notice C = 2 (C-Level own 2 votes)
    enum OwnerVotes {
        F,
        D,
        C
    }
    struct OwnerAccount {
        address addr;
        OwnerVotes vote;
    }
    struct Request {
        address requester;
        RequestTypes requestType;
        OwnerAccount currentOwner;
        OwnerAccount newOwner;
        uint256 withdrawalAmount;
        mapping(address => bool) voters;
        uint256 votes;
        bool isExecute;
    }

    /* *****************************************************************************
     *   Storages
     * *****************************************************************************/
    Request[] public requests;
    mapping(OwnerVotes => uint8) public ownerCounter;
    mapping(address => OwnerVotes) public ownerVote;

    /* *****************************************************************************
     *   Constructor
     * - set consensus ratio, minimum votes limit for consensus, and initial accounts
     * *****************************************************************************/
    constructor(
        uint256 _consensusRatio,
        uint8 _minLimitForConsensus,
        OwnerAccount[] memory _initialOwnerAccounts
    ) {
        consensusRatio = _consensusRatio;
        minLimitForConsensus = _minLimitForConsensus;
        for (uint256 i; i < _initialOwnerAccounts.length; i++) {
            OwnerVotes vote = _initialOwnerAccounts[i].vote;
            ownerVote[_initialOwnerAccounts[i].addr] = vote;
            ownerCounter[vote]++;
        }

        _checkMinConsensus();
    }

    /* *****************************************************************************
     *   Events
     * *****************************************************************************/
    event PaymentReceived(address indexed sender, string topic, string description);
    event EtherReceived(address indexed sender);
    event Requested(address indexed owner, uint256 indexed requestId, RequestTypes indexed requestType);
    event Approved(address indexed owner, uint256 indexed requestId, OwnerVotes votes);
    event Revoked(address indexed owner, uint256 indexed requestId, OwnerVotes votes);
    event Canceled(address indexed owner, uint256 indexed requestId);
    event Executed(address indexed owner, uint256 indexed requestId, RequestTypes indexed requestType);

    /* *****************************************************************************
     *   Modifiers
     * *****************************************************************************/
    modifier onlyOwner(address _address) {
        /// @custom:error (004) - Only the owner of the wallet is allowed
        require(isOwner(_address), 'OO4');
        _;
    }

    modifier notOwner(address _address) {
        /// @custom:error (005) - Already the owner of the wallet
        require(!isOwner(_address), 'OO5');
        _;
    }

    modifier isOwnerAccount(OwnerAccount memory _ownerAccount) {
        /// @custom:error (NX2) - Non-existent wallet account
        address _addr = _ownerAccount.addr;
        require(isOwner(_addr) && uint8(ownerVote[_addr]) == uint8(_ownerAccount.vote), 'NX2');
        _;
    }

    modifier onlyRequester(uint256 _reqId) {
        /// @custom:error (OO6) - Only the requester is allowed
        require(requests[_reqId].requester == msg.sender, 'OO6');
        _;
    }

    modifier reachConsensus(uint256 _reqId) {
        /// @custom:error (NE2) - Not reach consensus
        require(requests[_reqId].votes >= requiredVotesForConsensus(), 'NE2');
        _;
    }

    modifier reqExists(uint256 _reqId) {
        /// @custom:error (NX3) - Non-existent owner request
        require(_reqId < requests.length, 'NX3');
        _;
    }

    modifier notExecutedOrCanceled(uint256 _reqId) {
        /// @custom:error (SE1) - Already executed
        require(!requests[_reqId].isExecute, 'SE1');

        /// @custom:error (SE2) - Request canceled
        require(requests[_reqId].requestType != RequestTypes.Cancel, 'SE2');
        _;
    }

    modifier notVoted(address _owner, uint256 _reqId) {
        /// @custom:error (SE3) - Already voted
        require(!isOwnerVoted(_owner, _reqId), 'SE3');
        _;
    }

    modifier voted(address _owner, uint256 _reqId) {
        /// @custom:error (SE4) - Not voted
        require(isOwnerVoted(_owner, _reqId), 'SE4');
        _;
    }

    modifier isValidAddress(address _address) {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_address != address(0), 'AE1');
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }

        /// @notice It's not perfect filtering against CA, but the owners can handle it cautiously.
        /// @custom:error (AE2) - Contract address not acceptable
        require(codeSize == 0, 'AE2');
        _;
    }

    /* *****************************************************************************
     *   Methods - Public, External
     * *****************************************************************************/

    function makePayment(string calldata _topic, string calldata _description) external payable {
        /// @custom:error (NE3) - A zero payment is not acceptable
        require(msg.value > 0, 'NE3');
        emit PaymentReceived(msg.sender, _topic, _description);
    }

    receive() external payable {
        emit EtherReceived(msg.sender);
    }

    /// @notice request
    /// @dev Allows an owner to request for an agenda that wants to proceed
    /// @dev The owner can make multiple requests even if the previous one is unresolved
    /// @dev The requester is automatically voted for the request
    /// @param _requestType Withdraw(0) / Add(1) / Remove(2) / Change(3) / Cancel(4)
    /// @param _currentAccount Tuple[address, OwnerVotes] for current exist owner account (use for Request Type as Remove or Change)
    /// @param _newAccount Tuple[address, OwnerVotes] for new owner account (use for Request Type as Add or Change)
    /// @param _withdrawalAmount Amount of Ether to be withdrawal (use for Request Type as Withdrawal)

    function request(
        RequestTypes _requestType,
        OwnerAccount calldata _currentAccount,
        OwnerAccount calldata _newAccount,
        uint256 _withdrawalAmount
    ) external onlyOwner(msg.sender) {
        address requester = msg.sender;

        Request storage request_ = requests.push();
        request_.requester = requester;
        request_.requestType = _requestType;
        request_.currentOwner = OwnerAccount({ addr: _currentAccount.addr, vote: _currentAccount.vote });
        request_.newOwner = OwnerAccount({ addr: _newAccount.addr, vote: _newAccount.vote });
        request_.withdrawalAmount = _withdrawalAmount;
        request_.voters[requester] = true;
        request_.votes = uint8(ownerVote[requester]);

        emit Requested(msg.sender, requests.length - 1, _requestType);
    }

    /// @notice approve
    /// @dev Allows owners to approve the request
    /// @dev The owner can revoke the approval whenever the request is still in progress (not executed or canceled)
    /// @param _reqId Request id that the owner wants to approve

    function approve(uint256 _reqId)
        external
        onlyOwner(msg.sender)
        reqExists(_reqId)
        notExecutedOrCanceled(_reqId)
        notVoted(msg.sender, _reqId)
    {
        OwnerVotes _vote = ownerVote[msg.sender];
        Request storage request_ = requests[_reqId];
        request_.voters[msg.sender] = true;
        request_.votes += uint8(_vote);

        emit Approved(msg.sender, _reqId, _vote);
    }

    /// @notice revoke
    /// @dev Allow an approver(owner) to revoke the approval
    /// @param _reqId Request id that the owner wants to revoke

    function revoke(uint256 _reqId)
        external
        onlyOwner(msg.sender)
        reqExists(_reqId)
        notExecutedOrCanceled(_reqId)
        voted(msg.sender, _reqId)
    {
        OwnerVotes vote = ownerVote[msg.sender];
        Request storage request_ = requests[_reqId];
        delete request_.voters[msg.sender];
        request_.votes -= uint8(vote);

        emit Revoked(msg.sender, _reqId, vote);
    }

    /// @notice cancel
    /// @dev Allows a requester(owner) to cancel the own request
    /// @dev After proceeding, it cannot revert the cancellation. Be cautious
    /// @param _reqId Request id requested by the requester

    function cancel(uint256 _reqId) external reqExists(_reqId) notExecutedOrCanceled(_reqId) onlyRequester(_reqId) {
        requests[_reqId].requestType = RequestTypes.Cancel;

        emit Canceled(msg.sender, _reqId);
    }

    /// @notice execute
    /// @dev Allow an requester(owner) to execute the request
    /// @dev After proceeding, it cannot revert the execution. Be cautious
    /// @param _reqId Request id that the requester wants to execute

    function execute(uint256 _reqId) external reqExists(_reqId) notExecutedOrCanceled(_reqId) onlyRequester(_reqId) reachConsensus(_reqId) {
        Request storage request_ = requests[_reqId];
        uint8 type_ = uint8(request_.requestType);
        request_.isExecute = true;

        if (type_ == uint8(RequestTypes.Withdraw)) {
            _withdraw(request_.withdrawalAmount, request_.requester);
        } else if (type_ == uint8(RequestTypes.Add)) {
            _addOwner(request_.newOwner);
        } else if (type_ == uint8(RequestTypes.Remove)) {
            _removeOwner(request_.currentOwner);
        } else if (type_ == uint8(RequestTypes.Change)) {
            _changeOwner(request_.currentOwner, request_.newOwner);
        }
        emit Executed(msg.sender, _reqId, request_.requestType);
    }

    /// @notice totalVotes
    /// @dev Allows users to see how many total votes the wallet currently have
    /// @return votes The total number of voting rights the owners have

    function totalVotes() public view returns (uint256 votes) {
        return ownerCounter[OwnerVotes.D] + 2 * ownerCounter[OwnerVotes.C];
    }

    /// @notice isOwner
    /// @dev Allows users to verify registered owners in the wallet
    /// @param _owner Address of the owner that you want to verify
    /// @return isVerified Verification result of whether the owner is correct

    function isOwner(address _owner) public view returns (bool isVerified) {
        return uint8(ownerVote[_owner]) > 0;
    }

    /// @notice isOwnerVoted
    /// @dev Allows users to check which owner voted
    /// @param _owner Address of the owner
    /// @param _reqId Request id that you want to check
    /// @return isVoted Whether the owner voted

    function isOwnerVoted(address _owner, uint256 _reqId) public view returns (bool isVoted) {
        return requests[_reqId].voters[_owner];
    }

    /// @notice requiredVotesForConsensus
    /// @dev Allows users to see how many votes are needed to reach consensus.
    /// @return votesForConsensus The number of votes required to reach a consensus

    function requiredVotesForConsensus() public view returns (uint256 votesForConsensus) {
        return Math.ceilDiv((totalVotes() * consensusRatio), 100);
    }

    /// @notice getRequestIdsByExecution
    /// @dev Allows users to see the array of request ids filtered by execution
    /// @param _isExecuted Whether the request was executed or not
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByExecution(
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if (requests[i].isExecute) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if (!requests[i].isExecute) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getRequestIdsByOwner
    /// @dev Allows users to see the array of request ids filtered by owner address
    /// @param _owner The address of owner
    /// @param _isExecuted If you want to see only for that have not been executed, input this argument into true
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByOwner(
        address _owner,
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if ((requests[i].requester == _owner) && (requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if ((requests[i].requester == _owner) && (!requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getRequestIdsByType
    /// @dev Allows users to see the array of request ids filtered by request type
    /// @param _requestType Withdraw(0) / Add(1) / Remove(2) / Change(3) / Cancel(4)
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByType(
        RequestTypes _requestType,
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if ((requests[i].requestType == _requestType) && (requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if ((requests[i].requestType == _requestType) && (!requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getLastRequestNo
    /// @dev Allows users to get the last request number
    /// @return requestNo The last request number

    function getLastRequestNo() public view returns (uint256 requestNo) {
        return requests.length - 1;
    }

    /* *****************************************************************************
     *   Functions - Internal, Private
     * *****************************************************************************/

    /// @notice _withdraw
    /// @dev Withdraw Ethers from the wallet
    /// @param _value Withdraw amount
    /// @param _to Withdrawal recipient

    function _withdraw(uint256 _value, address _to) private {
        /// @custom:error (NE4) - Insufficient balance
        require(_value <= address(this).balance, 'NE4');
        (bool withdrawn, ) = payable(_to).call{ value: _value }('');

        /// @custom:error (SE5) - Address: unable to send value, recipient may have reverted
        require(withdrawn, 'SE5');
    }

    /// @notice _addOwner
    /// @dev Add a new Owner to the wallet
    /// @param _newAccount New owner account to be added

    function _addOwner(OwnerAccount memory _newAccount) private notOwner(_newAccount.addr) isValidAddress(_newAccount.addr) {
        OwnerVotes vote = _newAccount.vote;
        ownerVote[_newAccount.addr] = vote;
        ownerCounter[vote]++;
    }

    /// @notice _removeOwner
    /// @dev Remove existing owner form the wallet
    /// @param _removalAccount Current owner account to be removed

    function _removeOwner(OwnerAccount memory _removalAccount) private isOwnerAccount(_removalAccount) {
        ownerCounter[_removalAccount.vote]--;
        _checkMinConsensus();
        delete ownerVote[_removalAccount.addr];
    }

    /// @notice _changeOwner
    /// @dev Allows changing the existing owner to the new one. It also includes the functionality to change the existing owner's level
    /// @param _currentAccount Current owner account to be changed
    /// @param _newAccount New owner account to be applied

    function _changeOwner(OwnerAccount memory _currentAccount, OwnerAccount memory _newAccount) private {
        OwnerVotes _currentVote = _currentAccount.vote;
        OwnerVotes _newVote = _newAccount.vote;
        ownerCounter[_currentVote]--;
        ownerCounter[_newVote]++;
        _checkMinConsensus();

        if (_currentAccount.addr != _newAccount.addr) {
            delete ownerVote[_currentAccount.addr];
        }
        ownerVote[_newAccount.addr] = _newVote;
    }

    /// @notice _checkMinConsensus
    /// @dev It is the verification function to prevent a dangerous situation in which the number of votes that an owner has
    /// @dev is equal to or greater than the number of votes required for reaching consensus so that the owner achieves consensus by himself or herself.

    function _checkMinConsensus() private view {
        /// @custom:error (NE5) - Violate min limit for consensus
        require(requiredVotesForConsensus() >= minLimitForConsensus, 'NE5');
    }

    function _compactUintArray(uint256[] memory targetArray, uint256 length) internal pure returns (uint256[] memory array) {
        uint256[] memory compactArray = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            compactArray[i] = targetArray[i];
        }
        return compactArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}