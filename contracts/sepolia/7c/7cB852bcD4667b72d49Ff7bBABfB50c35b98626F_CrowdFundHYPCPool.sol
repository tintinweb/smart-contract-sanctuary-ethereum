// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICHYPC.sol";
import "../interfaces/IHYPC.sol";
import "../interfaces/IHYPCSwap.sol";

/**
    @title  Crowd Funded HyPC Pool
    @author Barry Rowe, David Liendo
    @notice This contract allows users to pool their HyPC together to swap for a c_HyPC that can be used to back
            a license in the HyperCycle ecosystem. Because of the initial high volume of HyPC required for
            a swap, a pooling contract is useful for users wanting to have HyPC back their license. In this
            case, a license holder creates a proposal in the pool for 1 c_HyPC to back their license. They put up
            some backing HyPC as collateral for this loan, that will be used as interest payments for the users
            that provide HyPC for the proposal.

            As an example, a manager wants to borrow a c_HyPC for 18 months (78 weeks). The manager puts up 
            50,000 HyPC as collateral to act as interest for the user that deposit to this proposal. This means
            that the yearly APR for a depositor to the proposal will be: 50,000/524,288 * (26/39) = 0.063578288
            or roughly 6.35% (26 being the number of 2 week periods in a year, and 39 the number of 2 week
            periods in the proposal's term). The depositors can then claim this interest every period (2 weeks) 
            until the end of the proposal, at which point they can then withdraw and get back their initial 
            deposit. While the proposal is active, the c_HyPC is held by the pool contract itself, though the 
            manager that created the proposal can change the assignement of the swapped for c_HyPC.
*/

contract CrowdFundHYPCPool is ERC721Holder, Ownable, ReentrancyGuard {
    using SafeERC20 for IHYPC;

    struct ContractProposal {
        address owner;
        uint256 term;
        uint256 interestRateAPR;
        uint256 deadline;
        string assignmentString;
        uint256 startTime;
        uint256 depositedAmount;
        uint256 backingFunds;
        uint256 status;
        uint256 tokenId;
    }

    struct UserDeposit {
        uint256 amount;
        uint256 proposalIndex;
        uint256 interestTime;
    }

    ContractProposal[] public proposals;
    mapping(address => UserDeposit[]) public userDeposits;

    /// @notice The HyPC ERC20 contract
    IHYPC public immutable HYPCToken;

    /// @notice The c_HyPC ERC721 contract
    ICHYPC public immutable HYPCNFT;

    /// @notice The HyPC/c_HyPC swapping contract
    IHYPCSwap public immutable SwapContract;

    //Timing is done PER WEEK, with the assumption that 1 year = 52 weeks
    uint256 private constant _2_WEEKS = 60 * 60 * 24 * 14;
    uint256 private constant _1_MONTH = 60 * 60 * 24 * 7 * 4; //4 weeks
    uint256 private constant _18_MONTHS = 60 * 60 * 24 * 7 * 78; //78 weeks
    uint256 private constant _24_MONTHS = 60 * 60 * 24 * 7 * 104; //104 weeks
    uint256 private constant _36_MONTHS = 60 * 60 * 24 * 7 * 156; //156 weeks

    uint256 private constant PENDING = 0;
    uint256 private constant STARTED = 1;
    uint256 private constant CANCELLED = 2;
    uint256 private constant COMPLETED = 3;

    uint256 private constant SIX_DECIMALS = 10**6;
    uint256 private constant PERIODS_PER_YEAR = 26;

    /// @notice The amount of HyPC needed to swap for each proposal. 
    uint256 public constant REQUESTED_AMOUNT = (2**19)*SIX_DECIMALS;

    /** 
        @notice The pool fee set by the pool owner for each created proposal. This is given in HyPC with
                6 decimals.
    */
    uint256 public poolFee = 0;

    //Events
    /// @dev   The event for when a manager creates a proposal.
    /// @param proposalIndex: the proposal that was created
    /// @param owner: the proposal creator's address
    /// @param assignmentString: the assignment to give to the c_HyPC token when the proposal is filled
    /// @param deadline: the deadline in blocktime seconds for this proposal to be filled.
    event ProposalCreated(
        uint256 indexed proposalIndex,
        address indexed owner,
        string assignmentString,
        uint256 deadline
    );

    /// @dev   The event for when a proposal is canceled by its creator
    /// @param proposalIndex: the proposal that was canceled
    /// @param owner: The creator's address
    event ProposalCanceled(uint256 indexed proposalIndex, address indexed owner);

    /// @dev   The event for whena proposal is finished by its creator
    /// @param proposalIndex: the proposal that was finished
    /// @param owner: the creator of the proposal
    event ProposalFinished(uint256 indexed proposalIndex, address indexed owner);

    /// @dev   The event for when a user submits a deposit towards a proposal
    /// @param proposalIndex: the proposal this deposit was made towards
    /// @param user: the user address that submitted this deposit
    /// @param amount: the amount of HyPC the user deposited to this proposal.
    event DepositCreated(
        uint256 indexed proposalIndex,
        address indexed user,
        uint256 amount
    );

    /// @dev   The event for when a user withdraws a previously created deposit
    /// @param depositIndex: the user's deposit index that was withdrawn
    /// @param user: the user's address
    /// @param amount: the amount of HyPC that was withdrawn.
    event WithdrawDeposit(
        uint256 indexed depositIndex,
        address indexed user,
        uint256 amount
    );

    /// @dev   The event for when a user updates their deposit and gets interest.
    /// @param depositIndex: the deposit index for this user
    /// @param user: the address of the user
    /// @param interestChange: the amount of HyPC interest given to this user for this update.
    event UpdateDeposit(
        uint256 indexed depositIndex,
        address indexed user,
        uint256 interestChange
    );

    /// @dev   The event for when a user transfers their deposit to another user.
    /// @param depositIndex: the deposit index for this user
    /// @param user: the address of the user
    /// @param to: the address that this deposit was sent to
    /// @param amount: the amount of HyPC in this deposit.
    event TransferDeposit(
        uint256 indexed depositIndex,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /// @dev   The event for when a manager changes the assigned string of a proposal.
    /// @param proposalIndex: Index of the changed proposal.
    /// @param owner: the address of the proposal's owner.
    /// @param assignment: string that the proposal's assignment was changed to
    /// @param assignmentRef: String reference to the value of assignment 
    event AssignmentChanged(
        uint256 indexed proposalIndex,
        address indexed owner,
        string indexed assignment,
        string assignmentRef
    );

    //Modifiers
    /// @dev   Checks that this proposal index has been created.
    /// @param proposalIndex: the proposal index to check
    /// @param proposalsArray: the array that stores proposals.
    modifier validIndex(uint256 proposalIndex, ContractProposal[] storage proposalsArray) {
        require(proposalIndex < proposalsArray.length, "Invalid index.");
        _;
    }

    /// @dev   Checks that the transaction sender is the proposal owner
    /// @param proposalIndex: the proposal index to check ownership of.
    modifier proposalOwner(uint256 proposalIndex) {
        require(
            msg.sender == proposals[proposalIndex].owner,
            "Must be owner of proposal."
        );
        _;
    }

    /// @dev   Checks that the transaction sender's deposit index is valid.
    /// @param depositIndex: the sender's index to check.
    modifier validDeposit(uint256 depositIndex) {
        require(
            depositIndex < userDeposits[msg.sender].length,
            "Invalid deposit."
        );
        _;
    }

    /**
        @dev   The constructor takes in the HyPC token, c_HyPC token, and Swap contract addresses to populate
               the contract interfaces.
        @param hypcTokenAddress: the address for the HyPC token contract.
        @param hypcNFTAddress: the address for the CHyPC token contract.
        @param swapContractAddress: the address of the Swap contract.
    */
    constructor(
        address hypcTokenAddress,
        address hypcNFTAddress,
        address swapContractAddress
    ) {
        require(hypcTokenAddress != address(0), "Invalid Token.");
        require(hypcNFTAddress != address(0), "Invalid NFT.");
        require(swapContractAddress != address(0), "Invalid swap contract.");

        HYPCToken = IHYPC(hypcTokenAddress);
        HYPCNFT = ICHYPC(hypcNFTAddress);
        SwapContract = IHYPCSwap(swapContractAddress);
    }

    /// @notice Allows the owner of the pool to set the fee on proposal creation.
    /// @param  fee: the fee in HyPC to charge the proposal creator on creation.
    function setPoolFee(uint256 fee) external onlyOwner {
        poolFee = fee;
    }

    /**
        @notice Allows someone to create a proposal to have HyPC pooled together to swap for a c_HyPC token and
                have that token be given a speified assignment string. The creator specifies the term length
                for this proposal and supplies an amount of HyPC to act as interest for the depositors of the
                proposal.
        @param  termNum: either 0, 1, or 2, corresponding to 18 months, 24 months or 36 months respectively.
        @param  backingFunds: the amount of HyPC that the creator puts up to create the proposal, which acts
                as the interest to give to the depositors during the course of the proposal's term.
        @param  assignmentString: the string to be assigned to the c_HyPC swapped for when this proposal is
                filled and started.
        @param  deadline: the block timestamp that this proposal must be filled by in order to be started.
        @param  specifiedFee: The fee that the creator expects to pay.
        @dev    The specifiedFee parameter is used to prevent a pool owner from front-running a transaction
                to increase the poolFee after a creator has submitted a transaction.
        @dev    The interest rate calculation for the variable interestRateAPR is described in the contract's
                comment section. The only difference here is that there is an extra term in the numerator of
                SIX_DECIMALS since we can't have floating point numbers by default in solidity.
    */
    function createProposal(
        uint256 termNum,
        uint256 backingFunds,
        string memory assignmentString,
        uint256 deadline,
        uint256 specifiedFee
    ) external nonReentrant {
        require(
            termNum < 3,
            "termNum must be 0, 1, or 2 (18 months, 24 months, or 36 months)."
        );
        require(deadline > block.timestamp, "deadline must be in the future.");
        require(backingFunds > 0, "backingFunds must be positive.");
        require(
            bytes(assignmentString).length > 0,
            "assignmentString must be non-empty."
        );
        require(specifiedFee == poolFee, "Pool fee doesn't match.");

        uint256 termLength;
        if (termNum == 0) {
            termLength = _18_MONTHS;
        } else if (termNum == 1) {
            termLength = _24_MONTHS;
        } else {
            termLength = _36_MONTHS;
        }

        uint256 requiredFunds = 524288*SIX_DECIMALS;
        uint256 periods = termLength / _2_WEEKS;

        uint256 interestRateAPR = (backingFunds * PERIODS_PER_YEAR*SIX_DECIMALS) /
            (requiredFunds * periods);

        proposals.push(
            ContractProposal({
                owner: msg.sender,
                term: termLength,
                interestRateAPR: interestRateAPR,
                deadline: deadline,
                backingFunds: backingFunds,
                tokenId: 0,
                assignmentString: assignmentString,
                startTime: 0,
                status: PENDING,
                depositedAmount: 0
            })
        );

        HYPCToken.safeTransferFrom(msg.sender, address(this), backingFunds);
        HYPCToken.safeTransferFrom(msg.sender, owner(), poolFee);
        emit ProposalCreated(
            proposals.length,
            msg.sender,
            assignmentString,
            deadline
        );
    }

    /**
        @notice Lets a user creates a deposit for a pending proposal and submit the specified amount of 
                HyPC to back it.

        @param  proposalIndex: the proposal index that the user wants to back.
        @param  amount: the amount of HyPC the user wishes to deposit towards this proposal.
    */  
    function createDeposit(
        uint256 proposalIndex,
        uint256 amount
    ) external nonReentrant validIndex(proposalIndex, proposals) {
        ContractProposal storage proposalData = proposals[proposalIndex];
        require(proposalData.status == PENDING, "Proposal not open.");
        require(
            block.timestamp < proposalData.deadline,
            "Proposal has expired."
        );
        require(amount > 0, "HYPC amount must be positive.");
        require(proposalData.depositedAmount + amount <= REQUESTED_AMOUNT,
                "Total HyPC deposit must not exceed the requested amount.");
 
        //Register deposit into proposal's array
        proposalData.depositedAmount += amount;

        //Register user's deposit
        userDeposits[msg.sender].push(
            UserDeposit({
                proposalIndex: proposalIndex,
                amount: amount,
                interestTime: 0
            })
        );
        HYPCToken.safeTransferFrom(msg.sender, address(this), amount);
        emit DepositCreated(proposalIndex, msg.sender, amount); 
    }

    /**
        @notice Lets a user that owns a deposit for a proposal to transfer the ownership of that
                deposit to another user. This is useful for liqudity since deposit can be tied up for
                fairly long periods of time.
        @param  depositIndex: the index of this users deposits array that they wish to transfer.
        @param  to: the address of the user to send this deposit to
        @dev    Deposit objects are deleted from the deposits array after being transfered. The deposit is 
                deleted and the last entry of the array is copied to that index so the array can be decreased
                in length, so we can avoid iterating through the array.
    */
    function transferDeposit(uint256 depositIndex, address to) external validDeposit(depositIndex) {
        require(to != msg.sender, "Can not transfer deposit to yourself.");

        //Copy deposit to the new address
        userDeposits[to].push(userDeposits[msg.sender][depositIndex]);
        uint256 amount = userDeposits[msg.sender][depositIndex].amount;

        //Delete this user deposit now.
        //If the deposit is not the last one, then swap it with the last one.         
        if (
            userDeposits[msg.sender].length > 1 &&
            depositIndex < userDeposits[msg.sender].length - 1
        ) {
            delete userDeposits[msg.sender][depositIndex];
            userDeposits[msg.sender][depositIndex] = userDeposits[msg.sender][
                userDeposits[msg.sender].length - 1
            ];
        }
        userDeposits[msg.sender].pop();
        emit TransferDeposit(depositIndex, msg.sender, to, amount);
    }

    /**
        @notice Marks a proposal as started after it has received enough HyPC. At this point the proposal swaps
                the HyPC for c_HyPC and sets the timestamp for the length of the term and interest payment
                periods.
        @param  proposalIndex: the proposal to start.
    */
    function startProposal(
        uint256 proposalIndex
    ) external nonReentrant validIndex(proposalIndex, proposals) {
        ContractProposal storage proposalData = proposals[proposalIndex];
        require(proposalData.status == PENDING, "Proposal not open.");
        require(
            block.timestamp < proposalData.deadline,
            "Proposal has expired."
        );
        require(proposalData.depositedAmount == REQUESTED_AMOUNT,
                "Proposal's requested HyPC must be filled in order to be started.");
 
        //Start the proposal now:
        proposalData.status = STARTED;
        proposalData.startTime = block.timestamp;
        uint256 tokenId = SwapContract.nfts(0);
        proposalData.tokenId = tokenId;

        //Swap for CHYPC
        //approve first...
        HYPCToken.safeApprove(address(SwapContract), 524288*SIX_DECIMALS);
        SwapContract.swap();
        //Assign CHYPC
        HYPCNFT.assign(tokenId, proposalData.assignmentString);
    }

    /**
        @notice If a proposal hasn't been started yet, then the creator can cancel it and get back their
                backing HyPC. Users who have deposited can then withdraw their deposits with the withdrawDeposit
                function given below.
        @param  proposalIndex: the proposal index to be cancel.
    */
    function cancelProposal(
        uint256 proposalIndex
    )
        external
        nonReentrant
        validIndex(proposalIndex, proposals)
        proposalOwner(proposalIndex)
    {
        require(
            proposals[proposalIndex].status == PENDING,
            "Proposal must be pending."
        );
        uint256 amount = proposals[proposalIndex].backingFunds;
        proposals[proposalIndex].backingFunds = 0;
        proposals[proposalIndex].status = CANCELLED;
        HYPCToken.safeTransfer(msg.sender, amount);

        emit ProposalCanceled(proposalIndex, msg.sender);
    }

    /**
        @notice Allows a user to withdraw their deposit from a proposal if that proposal has been canceled,
                passed its deadline, has not been started yet, or has come to term. For the case of a proposal
                that has come to term, then the user has to update their deposit to claim any remaining 
                interest first.
        @param  depositIndex: the index of this user's deposits array that they wish to withdraw.
    */
    function withdrawDeposit(uint256 depositIndex) external validDeposit(depositIndex) {
        uint256 proposalIndex = userDeposits[msg.sender][depositIndex]
            .proposalIndex;
        ContractProposal storage proposalData = proposals[proposalIndex];
        uint256 status = proposalData.status;

        require(
            status == PENDING || status == CANCELLED || status == COMPLETED,
            "Proposal must be pending, cancelled, or completed."
        );

        if (status == COMPLETED) {
            require(
                userDeposits[msg.sender][depositIndex].interestTime ==
                    proposalData.startTime + proposalData.term,
                "Deposit must be updated before it is withdrawn."
            );
        }

        proposalData.depositedAmount -= userDeposits[msg.sender][depositIndex]
            .amount;
        uint256 amount = userDeposits[msg.sender][depositIndex].amount;

        //Delete this user deposit now.
        //If the deposit is not the last one, then swap it with the last one. 
        if (
            userDeposits[msg.sender].length > 1 &&
            depositIndex < userDeposits[msg.sender].length - 1
        ) {
            delete userDeposits[msg.sender][depositIndex];
            userDeposits[msg.sender][depositIndex] = userDeposits[msg.sender][
                userDeposits[msg.sender].length - 1
            ];
        }
        userDeposits[msg.sender].pop();

        HYPCToken.safeTransfer(msg.sender, amount);

        emit WithdrawDeposit(depositIndex, msg.sender, amount);
    }

    /**
        @notice Updates a user's deposit and sends them the acculumated interest from the amount of two week
                periods that have passed.
        @param  depositIndex: the index of this user's deposits array that they wish to update.
        @dev    The interestChange variable takes the user's deposit amount and mutliplies it by the 
                proposal's calculated interestRateAPR to get the the yearly interest for this deposit with
                6 extra decimal places. It divides this by the number of periods in a year to get the interest
                from one two-week period, and multiplies it by the number of two week periods that have passed
                since this function was called to account for periods that were previously skipped. Finally,
                it divides the result by SIX_DECIMALS to remove the extra decimal places.
    */
    function updateDeposit(uint256 depositIndex) external nonReentrant validDeposit(depositIndex) {
        //get some interest from this deposit
        UserDeposit storage deposit = userDeposits[msg.sender][depositIndex];
        ContractProposal storage proposalData = proposals[
            deposit.proposalIndex
        ];

        require(
            proposalData.status == STARTED || proposalData.status == COMPLETED,
            "Proposal not started or compeleted."
        );

        if (deposit.interestTime == 0) {
            deposit.interestTime = proposalData.startTime;
        }

        uint256 endTime = block.timestamp;
        if (endTime > proposalData.startTime + proposalData.term) {
            endTime = proposalData.startTime + proposalData.term;
        }

        uint256 periods = (endTime - deposit.interestTime) / _2_WEEKS;
        require(
            periods > 0,
            "Not enough time has passed since last interest period."
        );

        uint256 interestChange = (deposit.amount * periods *
            proposalData.interestRateAPR) / (PERIODS_PER_YEAR * SIX_DECIMALS);

        //send this interestChange to the user and update both the backing funds and the interest time;
        deposit.interestTime += periods * _2_WEEKS;
 
        proposalData.backingFunds -= interestChange;
        HYPCToken.safeTransfer(msg.sender, interestChange);
        emit UpdateDeposit(depositIndex, msg.sender, interestChange);
    }

    /**
        @notice This completes proposal after it has come to term, unassigns the c_HyPC and redeems it for
                HyPC, so it can be given back to the depositors.
        @param  proposalIndex: the proposal's index to complete.
    */
    function completeProposal(uint256 proposalIndex) 
        external 
        nonReentrant
        validIndex(proposalIndex, proposals) {
        ContractProposal storage proposalData = proposals[proposalIndex];
        require(proposalData.status == STARTED, "Proposal must be in started state.");
 
        uint256 endTime = block.timestamp;
        require (block.timestamp >= proposalData.startTime + proposalData.term,
            "Proposal must have reached the end of its term." );

        proposalData.status = COMPLETED;
        //unassign tokend and redeem it.
        HYPCNFT.assign(proposalData.tokenId, "");
        HYPCNFT.approve(address(SwapContract), proposalData.tokenId);
        SwapContract.redeem(proposalData.tokenId);
    }

    /**
        @notice This allows the creator of a completed proposal to claim any left over backingFunds interest
                after all users have withdrawn their deposits from this proposal.
        @param  proposalIndex: the proposal's index to be finished.
    */
    function finishProposal(
        uint256 proposalIndex
    )
        external 
        nonReentrant
        validIndex(proposalIndex, proposals)
        proposalOwner(proposalIndex)
    {
        require(
            proposals[proposalIndex].status == COMPLETED,
            "Proposal must be completed."
        );
        require(
            proposals[proposalIndex].depositedAmount == 0,
            "All users must be withdrawn from proposal."
        );
        require(
            proposals[proposalIndex].backingFunds > 0,
            "Some backing funds must be left over."
        );
        uint256 amountToSend = proposals[proposalIndex].backingFunds;
        proposals[proposalIndex].backingFunds = 0;

        HYPCToken.safeTransfer(
            msg.sender,
            amountToSend
        );

        emit ProposalFinished(proposalIndex, msg.sender);
    }
 
    /**
        @notice This allows a proposal creator to change the assignment of a c_HyPC token that was swapped for
                in a fulfilled proposal.
        @param  proposalIndex: the proposal's index to have its c_HyPC assignment changed.
    */
    function changeAssignment(uint256 proposalIndex, string memory assignmentString) external validIndex(proposalIndex, proposals) proposalOwner(proposalIndex) {
        require(proposals[proposalIndex].status == STARTED, "Proposal must be in started state.");
        uint256 tokenId = proposals[proposalIndex].tokenId;
        HYPCNFT.assign(tokenId, assignmentString);

        emit AssignmentChanged(proposalIndex, msg.sender, assignmentString, assignmentString);
    }

    //Getters
    /// @notice Returns a user's deposits
    /// @param  user: the user's address.
    /// @return The UserDeposits array for this user
    function getUserDeposits(address user) external view returns(UserDeposit[] memory) {
        return userDeposits[user];
    }

    /// @notice Returns a specific deposit for a user
    /// @param user: the user's address
    /// @param depositIndex: the user's deposit index to be returned.
    /// @return The UserDeposit object at the index for this user
    function getDeposit(address user, uint256 depositIndex) external view returns(UserDeposit memory) {
        return userDeposits[user][depositIndex];
    }

    /// @notice Returns the length of a user's deposits array
    /// @param  user: the user's address
    /// @return The length of the user deposits array.
    function getDepositsLength(address user) external view returns(uint256) {
        return userDeposits[user].length;
    }

    /// @notice Returns the proposal object at the given index.
    /// @param  proposalIndex: the proposal's index to be returned
    /// @return The ContractProposal object for the given index.
    function getProposal(uint256 proposalIndex) external view returns(ContractProposal memory) {
        return proposals[proposalIndex];
    }
    
    /// @notice Returns the total number of proposals submitted to the contract so far.
    /// @return The length of the contract proposals array.
    function getProposalsLength() external view returns(uint256) {
        return proposals.length;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice Interface for the CHYPC.sol contract.
interface ICHYPC is IERC721 {
    /**
     * Accesses the assignment function of c_HyPC so the swap can remove 
     * the assignment data when a token is redeemed or swapped.
     */
    /// @notice Assigns a string to the given c_HyPC token.
    function assign(
        uint256 tokenId,
        string memory data
    ) external;

    /// @notice Returns the assigned string for this token.
    function getAssignment(
        uint256 tokenId
    ) external view  returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Interface for the HyperCycleToken.sol contract.
interface IHYPC is IERC20 {
    /*
     * Accesses the ERC20 functions of the HYPC contract. The burn function
     * is also exposed for future contracts.
    */
    /// @notice Burns an amount of the HyPC ERC20.
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface for the HYPCSwap.sol contract.
interface IHYPCSwap {
    /**
     * Accesses the addNFT function so that the CHYPC contract can
     * add the newly created NFT into this contract.
     */

    /// @notice Returns the nfts array inside the swap contract.
    function nfts(uint256 tokenId) external returns (uint256);

    /// @notice Adds a c_HyPC token to the swap contract from the c_HyPC contract.
    function addNFT(
        uint256 tokenId
    ) external;

    /// @notice Redeems a c_HyPC token for its amount of backing HyPC.
    function redeem(uint256 tokenId) external;

    /// @notice Swaps 524288 HyPC for 1 c_HyPC.
    function swap() external;
}