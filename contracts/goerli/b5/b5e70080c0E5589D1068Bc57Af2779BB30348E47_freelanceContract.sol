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
pragma solidity 0.8.18;

import "./utils/randomNumber.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract freelanceContract is randomNumber, Ownable {
    // State variables

    uint24 public juryLength; // jury length
    // protocol fee
    uint8 public protocolFee; // 5% of the contract price
    uint8 public juryFee; // 5% of the contract price
    address payable protocolAddress; // protocol address

    // admin constructor
    constructor(
        uint8 _protocolFee,
        uint8 _juryFee,
        uint24 _juryLength
    ) {
        protocolFee = _protocolFee;
        juryFee = _juryFee;
        juryLength = _juryLength;
        protocolAddress = payable(msg.sender);
    }

    struct ContractPact {
        address payable client; // client address
        address payable worker; // worker address
        bytes32 hashJob; // title + description of the work - should be a hash
        uint256 deadline; // timestamp
        uint256 createAt; // timestamp
        uint256 price; // price of the work in wei
        uint256 disputeId; // dispute id
        ContractState state; // state of the contract
    }

    struct Dispute {
        uint256 disputeId; // dispute id
        uint256 contractId; // contract id
        uint24 totalVoteCount; // jury vote
        uint24 clientVoteCount; // client vote count private until reveal
        uint24 workerVoteCount; // worker vote count private until reveal
        address disputeInitiator; // dispute initiator
        juryMember[] juryMembers; // jury address => jury hasVoted
        DisputeState state;
    }

    struct juryMember {
        uint24 juryId; // jury id
        bool hasVoted; // jury vote
        address payable juryAddress; // jury address
    }

    // Mappings

    mapping(address => bool) public workers; // mapping of workers - not related to contracts creation - could be used to display workers in the frontend
    mapping(address => bool) public clients; // mapping of clients - not related to contracts creation - could be used to display clients in the frontend
    mapping(uint256 => Dispute) public disputes; // mapping of disputes
    mapping(uint256 => ContractPact) public contracts; // mapping of contracts
    mapping(uint256 => address) public juryPool; // mapping of jury (jury address => jury struct)

    uint256 public contractCounter = 0; // counter of contracts
    uint256 public disputeCounter = 0; // counter of disputes
    uint256 public juryCounter = 0; // counter of jury

    enum ContractState {
        WaitingWorkerSign,
        WorkStarted,
        WaitingClientReview,
        WorkFinishedSuccessufully,
        DisputeOpened,
        WaitingforJuryVote,
        DisputeClosed,
        ClientLostInDispute,
        WorkerLostInDispute,
        CancelByFreelancer,
        CancelByClient,
        Archived
    }
    enum DisputeState {
        WaitingForJurySelection,
        WaitingJuryVote,
        DisputeClosed,
        ClientWon,
        WorkerWon
    }
    // reveal won or lost in dispute after jury vote completed (if jury vote is 50% or more)

    ContractState[] public contractStates; // array of contract states - could be used to display contract states in the frontend
    DisputeState[] public disputeStates; // array of contract states - could be used to display contract states in the frontend

    // Events

    // Event to display contract state change
    event ContractStateChange(
        ContractState previousStatus,
        ContractState newStatus
    );
    event DisputeStateChange(
        DisputeState previousStatus,
        DisputeState newStatus
    );
    // Event to display contract creation by client
    event ContractCreated(
        uint256 contractId,
        address client,
        address worker,
        bytes32 hashJob,
        uint256 createAt,
        uint256 deadline,
        uint256 price,
        ContractState state
    );

    event DisputeCreated(
        uint256 disputeId,
        uint256 contractId,
        address disputeInitiator
    );

    // Event to display contract signing by worker
    event ContractSigned(uint256 contractId, address worker);

    // Event to display work is finish by worker
    event ContractReviewRequested(uint256 contractId, address worker);

    // Event to display work is validated by client
    event ContractIsFinished(uint256 contractId);

    event Voted(uint256 disputeId, address juryAddress);

    // Modifiers

    // Modifier to check if the contract is in the correct state
    modifier inState(uint256 _contractId, ContractState _state) {
        require(
            contracts[_contractId].state == _state,
            "Contract is not in the correct state."
        );
        _;
    }

    // Modifier to check if the dispute is in the correct state
    modifier inStateDispute(uint256 _disputeId, DisputeState _state) {
        require(
            disputes[_disputeId].state == _state,
            "Dispute is not in the correct state."
        );
        _;
    }

    modifier onlyWorker(uint256 _contractId) {
        require(
            contracts[_contractId].worker == msg.sender,
            "Only the worker can call this function."
        );
        _;
    }

    modifier onlyClient(uint256 _contractId) {
        require(
            contracts[_contractId].client == msg.sender,
            "Only the client can call this function."
        );
        _;
    }

    modifier onlyClientOrWorker(uint256 _contractId) {
        require(
            contracts[_contractId].client == msg.sender ||
                contracts[_contractId].worker == msg.sender,
            "Only the client or the worker can call this function."
        );
        _;
    }

    // TODO : add modifier to check only jury of the dispute can call the function
    // if disputes[_disputeId].juryMembers[msg.sender] exists, then onlyJury

    // Functions admin

    function setProtocolFee(uint8 _protocolFee) public onlyOwner {
        protocolFee = _protocolFee;
    }

    function setJuryFee(uint8 _juryFee) public onlyOwner {
        juryFee = _juryFee;
    }

    function setJuryLength(uint8 _juryLength) public onlyOwner {
        juryLength = _juryLength;
    }

    // Function to add a worker to the workers mapping

    function addWorker() external {
        require(msg.sender != address(0), "Invalid address.");
        require(workers[msg.sender] == false, "Worker already exists.");
        workers[msg.sender] = true;
    }

    // Function to add a client to the clients mapping

    function addClient() external {
        require(msg.sender != address(0), "Invalid address.");
        require(clients[msg.sender] == false, "Client already exists.");
        clients[msg.sender] = true;
    }

    // Function to add a jury to the clients mapping

    function addJury() external {
        require(msg.sender != address(0), "Invalid address.");
        require(isJury(msg.sender) == false, "Jury already exists.");
        // add a new jury of juryPool
        juryCounter++;
        juryPool[juryCounter] = msg.sender;
    }

    function isClient() external view returns (bool) {
        if (clients[msg.sender] == true) {
            return true;
        } else {
            return false;
        }
    }

    function isWorker() external view returns (bool) {
        if (workers[msg.sender] == true) {
            return true;
        } else {
            return false;
        }
    }

    function isJury(address _address) public view returns (bool) {
        for (uint256 i = 0; i < juryCounter; i++) {
            if (juryPool[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // Function to create a new contract send by client
    function createContract(
        uint256 _deadline,
        uint256 _today,
        bytes32 _hash
    ) public payable {
        require(
            clients[msg.sender] == true,
            "Only client can create a contract."
        );
        require(msg.value > 0, "The price must be greater than 0.");
        contractCounter++;
        contracts[contractCounter] = ContractPact({
            client: payable(msg.sender),
            worker: payable(address(0)),
            hashJob: _hash,
            createAt: _today,
            deadline: _deadline,
            price: msg.value,
            state: ContractState.WaitingWorkerSign,
            disputeId: 0
        });

        emit ContractCreated(
            contractCounter,
            msg.sender,
            address(0),
            _hash,
            _today,
            _deadline,
            msg.value,
            ContractState.WaitingWorkerSign
        );
    }

    // Function for the client to cancel the contract only if the worker didn't sign the contract

    function cancelContractByClient(uint256 _contractId)
        external
        inState(_contractId, ContractState.WaitingWorkerSign)
        onlyClient(_contractId)
    {
        ContractPact storage thisContract = contracts[_contractId];
        require(
            thisContract.state == ContractState.WaitingWorkerSign,
            "The contract has already been signed."
        );
        thisContract.state = ContractState.CancelByClient;
        emit ContractStateChange(
            ContractState.WaitingWorkerSign,
            ContractState.CancelByClient
        );
    }

    // Function for the worker to cancel the contract

    function cancelContractByWorker(uint256 _contractId)
        external
        inState(_contractId, ContractState.WorkStarted)
        onlyWorker(_contractId)
    {
        ContractPact storage thisContract = contracts[_contractId];
        thisContract.state = ContractState.CancelByFreelancer;
        emit ContractStateChange(
            ContractState.WorkStarted,
            ContractState.CancelByFreelancer
        );
    }

    // Function for the worker to sign the contract
    function signContract(uint256 _contractId)
        external
        inState(_contractId, ContractState.WaitingWorkerSign)
    {
        ContractPact storage thisContract = contracts[_contractId];
        require(
            thisContract.state == ContractState.WaitingWorkerSign,
            "The contract has already been signed."
        );

        thisContract.worker = payable(msg.sender);
        thisContract.state = ContractState.WorkStarted;

        emit ContractSigned(_contractId, msg.sender);
        emit ContractStateChange(
            ContractState.WaitingWorkerSign,
            ContractState.WorkStarted
        );
    }

    // Function to get the contract details

    function getContractDetails(uint256 _contractId)
        external
        view
        returns (
            uint256 contractId,
            address client,
            address worker,
            bytes32 hashJob,
            uint256 deadline,
            uint256 price
        )
    {
        ContractPact storage thisContract = contracts[_contractId];
        contractId = _contractId;
        client = thisContract.client;
        worker = thisContract.worker;
        hashJob = thisContract.hashJob;
        deadline = thisContract.deadline;
        price = thisContract.price;
    }

    // Worker can request client validation

    function requestClientValidation(uint256 _contractId)
        external
        inState(_contractId, ContractState.WorkStarted)
        onlyWorker(_contractId)
    {
        ContractPact storage thisContract = contracts[_contractId];
        thisContract.state = ContractState.WaitingClientReview;
        emit ContractStateChange(
            ContractState.WorkStarted,
            ContractState.WaitingClientReview
        );
    }

    // Function for the client to validate the contract

    function setIsFinishedAndAllowPayment(uint256 _contractId)
        external
        inState(_contractId, ContractState.WaitingClientReview)
        onlyClient(_contractId)
    {
        ContractPact storage thisContract = contracts[_contractId];
        thisContract.state = ContractState.WorkFinishedSuccessufully;
        emit ContractIsFinished(_contractId);
    }

    function openDispute(uint256 _contractId)
        external
        inState(_contractId, ContractState.WorkStarted)
        onlyClientOrWorker(_contractId)
    {
        require(
            juryCounter > juryLength,
            "Not enough jury in juryPool to open a dispute."
        );
        ContractPact storage thisContract = contracts[_contractId];
        thisContract.state = ContractState.DisputeOpened;
        emit ContractStateChange(
            ContractState.WorkStarted,
            ContractState.DisputeOpened
        );

        disputeCounter++;
        Dispute storage thisDispute = disputes[disputeCounter];

        // create an array address(0) of jury member with juryLength
        // initialize the jury members struct array
        // struct juryMember

        // juryMember memory jury;

        // for (uint24 i = 0; i <= juryLength; i++) {
        //     jury = juryMember({
        //         juryId: i,
        //         juryAddress: payable(address(0)),
        //         hasVoted: false
        //     });
        //     thisDispute.juryMembers.push(jury);
        // }

        thisDispute.contractId = _contractId;
        thisDispute.disputeInitiator = msg.sender;
        thisDispute.state = DisputeState.WaitingJuryVote;
        thisContract.disputeId = disputeCounter;

        emit DisputeCreated(disputeCounter, _contractId, msg.sender);
    }

    // only the initiator can launch the jury selection
    // only if not already selected
    function selectJuryMember(uint256 _contractId) external {
        // address[] memory selectedJurors = new address[](juryLength);
        address[3] memory selectedJurors;

        ContractPact storage thisContract = contracts[_contractId];
        Dispute storage _thisDispute = disputes[thisContract.disputeId];

        // select a jury member
        juryMember memory jury;

        address jurySelected = msg.sender;
        for (uint24 i = 0; i < juryLength; i++) {
            uint24 _seed = i;
            // uint256 randomIndex = random(_seed);
            // randomIndex = randomIndex % juryCounter;
            jurySelected = generateRandomJury(_contractId, _seed);
            bool selected = false;
            for (uint24 count = 0; count < selectedJurors.length; count++) {
                if (jurySelected == selectedJurors[i]) {
                    selected = true;
                    break;
                }
                selected = false;
            }
            if (
                _thisDispute.juryMembers.length < juryLength &&
                selected == false
            ) {
                selectedJurors[i] = jurySelected;
                jury = juryMember({
                    juryId: i,
                    juryAddress: payable(jurySelected),
                    hasVoted: false
                });
                _thisDispute.juryMembers.push(jury);
            } else {
                i--;
                continue;
            }
        }
        thisContract.state = ContractState.WaitingforJuryVote;
        emit ContractStateChange(
            ContractState.DisputeOpened,
            ContractState.WaitingforJuryVote
        );
        _thisDispute.state = DisputeState.WaitingJuryVote;
        emit DisputeStateChange(
            DisputeState.WaitingJuryVote,
            DisputeState.WaitingJuryVote
        );
    }

    function generateRandomJury(uint256 _contractId, uint256 _seed)
        internal
        view
        returns (address)
    {
        ContractPact storage thisContract = contracts[_contractId];
        address jurySelected = msg.sender;
        uint256 randomIndex;
        for (uint256 i = 0; i <= 3; i++) {
            uint256 randomSeed = uint256(
                keccak256(
                    abi.encodePacked(
                        jurySelected,
                        block.timestamp,
                        block.number,
                        _seed,
                        i
                    )
                )
            );
            randomIndex = random(randomSeed) % juryCounter;
            jurySelected = juryPool[randomIndex];
            if (
                jurySelected != address(0) &&
                jurySelected != thisContract.client &&
                jurySelected != thisContract.worker
            ) {
                break;
            }
        }
        return jurySelected;
    }

    // Function to get check if jury is in the Dispute

    // function isNotAlreadySelected(
    //     address _jurySelected,
    //     address[3] storage _selectedJurors
    // ) internal pure returns (bool) {
    //     for (uint256 i = 0; i < _selectedJurors.length; i++) {
    //         if (_jurySelected == _selectedJurors[i]) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    function isJuryInDispute(uint256 _disputeId, address _juryAddress)
        external
        view
        returns (bool)
    {
        Dispute storage thisDispute = disputes[_disputeId];
        for (uint256 i = 0; i < thisDispute.juryMembers.length; i++) {
            if (thisDispute.juryMembers[i].juryAddress == _juryAddress) {
                return true;
            }
        }
        return false;
    }

    function getJuryMembers(uint256 _disputeId)
        external
        view
        returns (address[] memory)
    {
        Dispute storage thisDispute = disputes[_disputeId];
        address[] memory juryMembers = new address[](
            thisDispute.juryMembers.length
        );
        for (uint256 i = 0; i < thisDispute.juryMembers.length; i++) {
            juryMembers[i] = thisDispute.juryMembers[i].juryAddress;
        }
        return juryMembers;
    }

    function hasVoted(uint256 _disputeId, address _juryAddress)
        external
        view
        returns (bool)
    {
        Dispute storage thisDispute = disputes[_disputeId];
        bool result = false;
        for (uint256 i = 0; i < thisDispute.juryMembers.length; i++) {
            if (
                thisDispute.juryMembers[i].juryAddress == _juryAddress &&
                thisDispute.juryMembers[i].hasVoted == true
            ) {
                result = true;
            }
        }
        return result;
    }

    // Function for the jury to vote for the dispute between the client and the worker

    function vote(uint256 _disputeId, bool _vote)
        external
        inStateDispute(_disputeId, DisputeState.WaitingJuryVote)
    {
        Dispute storage thisDispute = disputes[_disputeId];
        require(
            thisDispute.state == DisputeState.WaitingJuryVote,
            "The dispute is already closed."
        );

        uint256 _contractId = thisDispute.contractId;
        ContractPact storage thisContract = contracts[_contractId];

        // get the jury member id in the disput
        uint24 juryId = 0;
        uint256 juryMemberLength = thisDispute.juryMembers.length;
        for (uint24 i = 0; i < juryMemberLength; i++) {
            if (thisDispute.juryMembers[i].juryAddress == msg.sender) {
                juryId = i;
            }
        }
        //"The jury member has already voted."
        require(
            thisDispute.juryMembers[juryId].hasVoted == false,
            "The jury member has already voted."
        );

        thisDispute.juryMembers[juryId].hasVoted = true;
        thisDispute.totalVoteCount++;
        if (_vote) {
            thisDispute.clientVoteCount++;
        } else {
            thisDispute.workerVoteCount++;
        }
        emit Voted(_disputeId, msg.sender);

        // // Check if all jury members have voted and return true if they have
        // uint256 voteCount = 0;
        // for (uint256 i = 0; i < juryMemberLength; i++) {
        //     if (thisDispute.juryMembers[i].hasVoted == true) {
        //         voteCount++;
        //     }
        //}

        // replate TotalVoteCount by voteCount due to issue with the jury members
        if (thisDispute.totalVoteCount == juryMemberLength) {
            thisContract.state = ContractState.DisputeClosed;
            emit ContractStateChange(
                ContractState.WaitingforJuryVote,
                ContractState.DisputeClosed
            );
            thisDispute.state = DisputeState.DisputeClosed;
            emit DisputeStateChange(
                DisputeState.WaitingJuryVote,
                DisputeState.DisputeClosed
            );
        }
    }

    // Function to reveal and count the vote of the jury

    function revealState(uint256 _disputeId)
        external
        inStateDispute(_disputeId, DisputeState.DisputeClosed)
    {
        Dispute storage thisDispute = disputes[_disputeId];
        uint256 _contractId = thisDispute.contractId;
        ContractPact storage thisContract = contracts[_contractId];

        if (thisDispute.clientVoteCount > thisDispute.workerVoteCount) {
            thisContract.state = ContractState.WorkerLostInDispute;
            thisDispute.state = DisputeState.ClientWon;
            emit ContractIsFinished(_contractId);
            emit ContractStateChange(
                ContractState.DisputeClosed,
                ContractState.WorkerLostInDispute
            );
            emit DisputeStateChange(
                DisputeState.DisputeClosed,
                DisputeState.ClientWon
            );
        } else {
            thisContract.state = ContractState.ClientLostInDispute;
            thisDispute.state = DisputeState.WorkerWon;
            emit ContractIsFinished(_contractId);
            emit ContractStateChange(
                ContractState.DisputeClosed,
                ContractState.ClientLostInDispute
            );
            emit DisputeStateChange(
                DisputeState.DisputeClosed,
                DisputeState.WorkerWon
            );
        }
    }

    // Function for client or worker to pull payment and split if juryDispute with jury Members and protocol share and the worker if he won the dispute
    //should call payment function with constructor(address[] memory payees, uint256[] memory shares)

    function pullPayment(uint256 _contractId)
        external
        onlyClientOrWorker(_contractId)
    {
        ContractPact storage thisContract = contracts[_contractId];
        // amount in wei
        uint256 amount = thisContract.price;
        uint256 _disputeId = thisContract.disputeId;

        // if there is no dispute
        // if the job have been canceled by the client or freelance
        if (
            thisContract.state == ContractState.CancelByFreelancer ||
            thisContract.state == ContractState.CancelByClient
        ) {
            address payable clientAddress = thisContract.client;
            thisContract.state = ContractState.Archived;
            thisContract.price = 0;
            (bool success, ) = clientAddress.call{value: amount}("");
            require(success, "Transfer failed.");
        }
        // if the job is finished successfully
        else if (
            thisContract.state == ContractState.WorkFinishedSuccessufully
        ) {
            address WinnerAddress = thisContract.worker;
            uint256 WinnerShare = amount * (1 - (protocolFee / 100));
            // protocol address and share
            address[] memory payees = new address[](2);
            payees[0] = WinnerAddress;
            payees[1] = protocolAddress;
            uint256[] memory shares = new uint256[](2);
            shares[0] = WinnerShare;
            shares[1] = amount * (protocolFee / 100);

            // Update state and price
            thisContract.state = ContractState.Archived;
            thisContract.price = 0;
            // create a new payment
            // PaymentSplitter payment = new PaymentSplitter(payees, shares);
            // transfer the amount to the payment contract
            // create a payment
            for (uint256 i = 0; i < payees.length; i++) {
                (bool success, ) = payees[i].call{value: shares[i]}("");
                require(success, "Transfer failed.");
            }
        }
        //if dispute existe and the client or worker lost the dispute
        // As dispute finished split payment between jurors, protocol and who wants
        else if (thisContract.state == ContractState.ClientLostInDispute) {
            Dispute storage thisDispute = disputes[_disputeId];
            uint256 juryMemberLength = thisDispute.juryMembers.length;
            address[] memory payees = new address[](juryMemberLength + 2);
            uint256[] memory shares = new uint256[](juryMemberLength + 2);

            // Update state and price
            thisContract.state = ContractState.Archived;
            thisContract.price = 0;

            // get jury members address and share

            address WinnerAddress = thisContract.worker;
            uint256 JuryShare = ((juryFee / juryMemberLength) * amount) / 100;
            uint256 ProtocolShare = amount * (protocolFee / 100);
            uint256 WinnerShare = amount - JuryShare - ProtocolShare;

            payees[0] = WinnerAddress;
            shares[0] = WinnerShare;
            payees[1] = protocolAddress;
            shares[1] = ProtocolShare;
            for (uint256 i = 0; i < juryMemberLength; i++) {
                payees[i + 2] = thisDispute.juryMembers[i].juryAddress;
                shares[i + 2] = amount * (juryFee / juryMemberLength / 100);
            }
            // create a payment
            for (uint256 i = 0; i < payees.length; i++) {
                (bool success, ) = payees[i].call{value: shares[i]}("");
                require(success, "Transfer failed.");
            }
        } else if (thisContract.state == ContractState.WorkerLostInDispute) {
            // jury members address and share
            Dispute storage thisDispute = disputes[_disputeId];
            uint256 juryMemberLength = thisDispute.juryMembers.length;
            address[] memory payees = new address[](juryMemberLength + 2);
            uint256[] memory shares = new uint256[](juryMemberLength + 2);

            // Update state and price
            thisContract.state = ContractState.Archived;
            thisContract.price = 0;

            // get jury members address and share
            address WinnerAddress = thisContract.client;
            uint256 JuryShare = ((juryFee / juryMemberLength) * amount) / 100;
            uint256 ProtocolShare = amount * (protocolFee / 100);
            uint256 WinnerShare = amount - JuryShare - ProtocolShare;

            payees[0] = WinnerAddress;
            shares[0] = WinnerShare;
            payees[1] = protocolAddress;
            shares[1] = amount * (protocolFee / 100);
            for (uint256 i = 0; i < juryMemberLength; i++) {
                payees[i + 2] = thisDispute.juryMembers[i].juryAddress;
                shares[i + 2] = (amount * (juryFee / juryMemberLength)) / 100;
            }
            // create a payment
            for (uint256 i = 0; i < payees.length; i++) {
                (bool success, ) = payees[i].call{value: shares[i]}("");
                require(success, "Transfer failed.");
            }
        } else {
            revert("No allowed to pull payment");
        }
        // transfer the payment to the contract
        //payment.transfer(amount); // <--- this is the line that fails
        // delete the contract
        // delete contracts[_contractId];

        // emit PaymentReleased(_contractId, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

abstract contract randomNumber {
    // function random() public view returns (uint256) {
    //     return block.prevrandao;
    // }

    function random(uint256 _seed) public view returns (uint256) {
        uint256 result = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, _seed)
            )
        );
        return result;
    }
}