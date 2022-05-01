/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/BidInterface.sol


pragma solidity ^0.8.0;

abstract contract BidInterface {
    enum employeePosition {
        MANAGER,
        SENIOR,
        JUNIOR
    }

    enum languageSkill {
        None,
        A1,
        B1,
        C1,
        C2
    }

    struct CommissionCriteriaPoints {
        bool initialized;
        uint256 candidates;
        uint256 credibility;
        uint256 references;
    }

    struct Employee {
        string employeeId;
        employeePosition position;
        languageSkill langSkill;
        uint256 hoursAboveMin;
    }

    uint8 public addedEmployees;
    uint256 public quotation;
    uint256 public maintenanceLength;
    Employee[] public employees;
    address public tenderAddress;
    address public bidderSCAddress;
    CommissionCriteriaPoints public pointsFromCommision;
    uint256 public totalPoints;
    bool public decrypted;

    function lockBid() external virtual;

    function setDecryptedValues(
        uint256 _quotation,
        uint256 _maintenanceLength,
        Employee[] memory _employees
    ) external virtual;

    function setCommisionPoints(
        uint256 _candidates,
        uint256 _credibility,
        uint256 _references
    ) external virtual;

    function setEvalFnPoints(uint256 points) external virtual;
}

// File: contracts/BidderInterface.sol


pragma solidity ^0.8.0;

interface BidderInterface {
    struct BidderResidence {
        string street;
        string city;
        string postalCode;
    }

    function certificate() external returns (bytes32);

    function decrypted() external returns (bool);

    function symmetricKey() external view returns (string memory);

    function setDecryptedValues(
        string memory _bidderName,
        BidderResidence memory _residence,
        string memory _identificator
    ) external;
}

// File: contracts/Tender.sol


pragma solidity ^0.8.0;




//Only for evalFn purposes
struct BestPositionCombination {
    BidInterface.employeePosition position;
    BidInterface.languageSkill languageSkill;
    uint256 hoursAboveMin;
}

struct ScoredBid {
    uint256 score;
    address bidderSCAddress;
    address bidSCAddress;
}

function sortScoredBids(
    ScoredBid[] memory bids,
    uint256 left,
    uint256 right
) pure {
    uint256 i = left;
    uint256 j = right;
    if (i == j) return;
    uint256 pivot = bids[uint256(left + (right - left) / 2)].score;
    while (i <= j) {
        while (bids[uint256(i)].score > pivot) i++;
        while (pivot > bids[uint256(j)].score) j--;
        if (i <= j) {
            (bids[uint256(i)], bids[uint256(j)]) = (
                bids[uint256(j)],
                bids[uint256(i)]
            );
            i++;
            j--;
        }
    }
    if (left < j) sortScoredBids(bids, left, j);
    if (i < right) sortScoredBids(bids, i, right);
}

contract Tender is Ownable {
    event StateChange(TenderStatusEnum value);

    modifier InBiddingPeriod() {
        if (block.timestamp > endTenderTime) {
            revert("Action cannot be done after bidding period!");
        } else if (block.timestamp < startTenderTime) {
            revert("Action cannot be done before bidding period!");
        }
        _;
    }

    modifier AfterBiddingPeriod() {
        require(
            block.timestamp > endTenderTime,
            "Action can be done only after bidding period!"
        );
        _;
    }

    modifier OnlyInEvalPhase() {
        require(
            status == TenderStatusEnum.EVALUATING,
            "Action available only in evaluating phase!"
        );
        _;
    }

    modifier UsableByPublic() {
        if (owner() != _msgSender()) {
            require(
                status == TenderStatusEnum.CLOSED,
                "Action accessible to public, only when Tender is closed!"
            );
        }
        _;
    }

    event StringFailure(string stringFailure);
    event BytesFailure(bytes bytesFailure);

    enum TenderStatusEnum {
        OPEN,
        CLOSED,
        EVALUATING,
        NOT_STARTED
    }

    struct Bidder {
        bytes32 certificate;
        address bidderContractAddress;
        string symmetricKey;
    }

    struct TenderOrganizationResidence {
        string street;
        string city;
        string postalCode;
    }

    struct TenderOrganization {
        string name;
        TenderOrganizationResidence residence;
        string identificator;
    }

    uint8 internal constant quotationW = 65;
    uint8 internal constant maintenanceW = 12;
    uint8 internal constant managerHAMW = 3; //HAM == HoursAboveMin
    uint8 internal constant seniorHAMW = 3; // senior weight is used 2 times - bid contains 2 senior positions
    uint8 internal constant juniorHAMW = 2;
    uint8 internal constant languageSkillW = 3; //used for every employee individually
    uint32 internal decimalPoints = 10**8; // 10 ^ n - 10 ^ 8 -> 8 decimal points

    TenderStatusEnum public status;

    TenderOrganization public organizator;
    string public tenderName;
    string public tenderId;
    uint256 public endTenderTime;
    uint256 public startTenderTime;
    string public tenderDocumentHash;
    string public publicKey;
    string public privateKey;

    mapping(address => address) public registeredBids; // bidderSC address => bidSC address
    mapping(bytes32 => address) public certifiedBidders; // certificate => bidderSC address
    bytes32[] private certificates;
    ScoredBid[] public orderedBids;

    //done
    constructor(
        string memory _tenderName,
        string memory _tenderId,
        uint256 _startTenderTime,
        uint256 _endTenderTime,
        TenderOrganization memory _organizator,
        string memory _tenderDocumentHash,
        string memory _publicKey
    ) {
        require(
            block.timestamp < _endTenderTime,
            "Closing time of tender must be in the future!"
        );
        status = TenderStatusEnum.NOT_STARTED;
        tenderName = _tenderName;
        tenderId = _tenderId;
        endTenderTime = _endTenderTime;
        startTenderTime = _startTenderTime;
        organizator = _organizator;
        tenderDocumentHash = _tenderDocumentHash;
        publicKey = _publicKey;
    }

    //done
    function addBidder(bytes32 cretificate, address bidderContractAddress)
        public
        onlyOwner
    {
        certificates.push(cretificate);
        certifiedBidders[cretificate] = bidderContractAddress;
    }

    //done
    function getBidders() public view returns (Bidder[] memory) {
        uint256 arrLen = certificates.length;
        Bidder[] memory bidders = new Bidder[](arrLen);
        for (uint256 i = 0; i < arrLen; i++) {
            Bidder memory bidder;
            bidder.certificate = certificates[i];
            bidder.bidderContractAddress = certifiedBidders[certificates[i]];
            bidders[i] = bidder;
        }
        return bidders;
    }

    //done
    function getBids() internal view returns (BidInterface[] memory) {
        Bidder[] memory bidders = getBidders();
        uint256 arrLen = bidders.length;
        BidInterface[] memory bids = new BidInterface[](arrLen);
        for (uint256 i = 0; i < arrLen; i++) {
            address bidAddress = registeredBids[
                bidders[i].bidderContractAddress
            ];
            bids[i] = BidInterface(bidAddress);
        }
        return bids;
    }

    //done
    function addBid(address bidSC) external InBiddingPeriod returns (bool) {
        require(
            status == TenderStatusEnum.OPEN,
            "Adding bids to tender is only available in OPEN phase!"
        );
        BidderInterface bidderSC = BidderInterface(msg.sender);
        try bidderSC.certificate() returns (bytes32 cert) {
            require(
                certifiedBidders[cert] == msg.sender,
                "No certification accordance!"
            );
            registeredBids[msg.sender] = bidSC;
            return true;
        } catch Error(string memory _e) {
            emit StringFailure(_e);
            revert(_e);
        } catch (bytes memory _e) {
            emit BytesFailure(_e);
            revert(
                "Bytes failure when adding bid to tender - event emmited to log!"
            );
        }
    }

    //done
    function openTender() public onlyOwner InBiddingPeriod {
        if (status != TenderStatusEnum.NOT_STARTED) {
            revert("Cannot open tender again!");
        }
        status = TenderStatusEnum.OPEN;
        emit StateChange(TenderStatusEnum.OPEN);
    }

    //done
    function startEvaluationPhase() public onlyOwner AfterBiddingPeriod {
        require(
            status == TenderStatusEnum.OPEN,
            "Evaluation phase proceeds only after bidding (OPEN) phase!"
        );
        status = TenderStatusEnum.EVALUATING;
        emit StateChange(TenderStatusEnum.EVALUATING);
    }

    //done
    function decryptBidderWithBid(
        address bidderSC,
        string memory _bidderName, //Bidder val
        BidderInterface.BidderResidence memory _residence, //Bidder val
        string memory _identificator, //Bidder val
        uint256 _quotation,
        uint256 _maintenanceLength,
        BidInterface.Employee[] memory _employees
    ) external onlyOwner OnlyInEvalPhase {
        address bidSC = registeredBids[bidderSC];
        require(bidSC != address(0), "Invalid bidderSC address!");
        BidderInterface bidder = BidderInterface(bidderSC);
        string memory symmetricKey = bidder.symmetricKey();
        bytes memory emptyStringTest = bytes(symmetricKey);
        require(
            emptyStringTest.length != 0,
            "Symmetric key not revealed for specified bidder!"
        );
        BidInterface bid = BidInterface(bidSC);
        bidder.setDecryptedValues(_bidderName, _residence, _identificator);
        bid.setDecryptedValues(_quotation, _maintenanceLength, _employees);
    }

    //b prefix stands for 'best'
    //done
    function evalBidsWithEvalFn(string memory _privateKey)
        public
        onlyOwner
        OnlyInEvalPhase
    {
        BidInterface[] memory bids = getBids();
        uint256 bidsLen = bids.length;
        uint256 b_quotation = 2**256 - 1;
        uint256 b_maintenanceLength = 0;
        BestPositionCombination memory b_junior = BestPositionCombination(
            BidInterface.employeePosition.JUNIOR,
            BidInterface.languageSkill.A1,
            0
        );
        BestPositionCombination memory b_senior = BestPositionCombination(
            BidInterface.employeePosition.SENIOR,
            BidInterface.languageSkill.A1,
            0
        );
        BestPositionCombination memory b_manager = BestPositionCombination(
            BidInterface.employeePosition.MANAGER,
            BidInterface.languageSkill.A1,
            0
        );
        //Loop to get best of every bid eval criteria or revert action when any of bids have uninitialized comission points
        for (uint256 i = 0; i < bidsLen; i++) {
            BidInterface bid = bids[i];
            bool bidDecrypted = bid.decrypted();
            require(
                bidDecrypted == true,
                "Every bid must be decrypted before evaluation!"
            );
            (bool initialized, , , ) = bid.pointsFromCommision(); //check if comission points for this particular bid was set
            require(
                initialized == true,
                "Every bid must have comission points set before evaluating with Fn"
            );
            b_quotation = bid.quotation() < b_quotation
                ? bid.quotation()
                : b_quotation;
            b_maintenanceLength = bid.maintenanceLength() > b_maintenanceLength
                ? bid.maintenanceLength()
                : b_maintenanceLength;
            uint8 empLen = bid.addedEmployees();
            for (uint256 y = 0; y < empLen; y++) {
                (
                    ,
                    BidInterface.employeePosition position,
                    BidInterface.languageSkill langSkill,
                    uint256 hoursAboveMin
                ) = bid.employees(y);
                BestPositionCombination memory positionRef;
                if (position == BidInterface.employeePosition.JUNIOR) {
                    positionRef = b_junior;
                } else if (position == BidInterface.employeePosition.SENIOR) {
                    positionRef = b_senior;
                } else if (position == BidInterface.employeePosition.MANAGER) {
                    positionRef = b_manager;
                } else {
                    continue;
                }
                positionRef.hoursAboveMin = positionRef.hoursAboveMin >
                    hoursAboveMin
                    ? positionRef.hoursAboveMin
                    : hoursAboveMin;
                positionRef.languageSkill = positionRef.languageSkill >
                    langSkill
                    ? positionRef.languageSkill
                    : langSkill;
            }
        }
        // Set score for every bid
        for (uint256 i = 0; i < bidsLen; i++) {
            uint256 sum = 0;
            BidInterface bid = bids[i];
            sum +=
                quotationW *
                uint256((decimalPoints * b_quotation) / bid.quotation()); // fraction is reversed - lower quotation is better
            sum +=
                maintenanceW *
                uint256(
                    (decimalPoints * bid.maintenanceLength()) /
                        b_maintenanceLength
                );
            uint8 empLen = bid.addedEmployees();
            for (uint8 y = 0; y < empLen; y++) {
                (
                    ,
                    BidInterface.employeePosition position,
                    BidInterface.languageSkill langSkill,
                    uint256 hoursAboveMin
                ) = bid.employees(y);

                BestPositionCombination memory bestPositionRef;
                uint8 wForPositionHAM;
                if (position == BidInterface.employeePosition.JUNIOR) {
                    bestPositionRef = b_junior;
                    wForPositionHAM = juniorHAMW;
                } else if (position == BidInterface.employeePosition.SENIOR) {
                    bestPositionRef = b_senior;
                    wForPositionHAM = seniorHAMW;
                } else if (position == BidInterface.employeePosition.MANAGER) {
                    bestPositionRef = b_manager;
                    wForPositionHAM = managerHAMW;
                } else {
                    continue;
                }
                sum +=
                    wForPositionHAM *
                    uint256(
                        (decimalPoints * hoursAboveMin) /
                            bestPositionRef.hoursAboveMin
                    );
                sum +=
                    languageSkillW *
                    uint256(
                        (decimalPoints * uint8(langSkill)) /
                            uint8(bestPositionRef.languageSkill)
                    );
            }
            bid.setEvalFnPoints(sum);
            orderedBids.push(
                ScoredBid(
                    bid.totalPoints(),
                    bid.bidderSCAddress(),
                    address(bid)
                )
            );
        }
        sortScoredBids(orderedBids, 0, uint256(orderedBids.length - 1));
        closeTender(_privateKey);
    }

    //done
    function setCommisionPointsForBid(
        address bidderSC,
        uint256 _candidates,
        uint256 _credibility,
        uint256 _references
    ) external onlyOwner OnlyInEvalPhase {
        address bidSC = registeredBids[bidderSC];
        require(
            bidSC != address(0),
            "There is not registered Bid for specified bidderSC address!"
        );
        BidderInterface bidder = BidderInterface(bidderSC);
        require(
            bytes(bidder.symmetricKey()).length != 0,
            "Bidder has not revealed his symmetric key!"
        );
        BidInterface(bidSC).setCommisionPoints(
            _candidates,
            _credibility,
            _references
        );
    }

    //done
    function closeTender(string memory _privateKey)
        internal
        onlyOwner
        AfterBiddingPeriod
    {
        require(
            status == TenderStatusEnum.EVALUATING,
            "Tender can be closed only after evaluation phase!"
        );
        BidInterface[] memory bids = getBids();
        if (bids.length > 0) {
            require(orderedBids.length != 0, "Winners list cannot be empty!");
        }
        status = TenderStatusEnum.CLOSED;
        privateKey = _privateKey;
        emit StateChange(TenderStatusEnum.CLOSED);
    }

    //done
    function getWinner()
        public
        view
        AfterBiddingPeriod
        returns (ScoredBid memory winner)
    {
        require(
            status == TenderStatusEnum.CLOSED,
            "Action available only after completion of Tender!"
        );
        if (orderedBids.length > 0) {
            return orderedBids[0];
        }
        return ScoredBid(0, address(0), address(0));
    }

    //done
    function getOrderedBids()
        public
        view
        AfterBiddingPeriod
        returns (ScoredBid[] memory)
    {
        require(
            status == TenderStatusEnum.CLOSED,
            "Action available only after completion of Tender!"
        );
        return orderedBids;
    }
}