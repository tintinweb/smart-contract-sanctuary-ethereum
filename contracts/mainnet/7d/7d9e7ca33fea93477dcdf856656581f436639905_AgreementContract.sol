/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

// pragma experimental ABIEncoderV2;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**To set up a new project, go to the projects directory that you created in Chapter 1 and make a new project using Cargo, like so:                                        
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }
 
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner,"Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract AgreementContract is Ownable {
    
    using SafeMath for uint256;
    
    AggregatorV3Interface internal priceFeed;
    
    uint256 public milestonefee = 500;               //5%
    uint256 public maxMilestoneFee = 1000;           //10%
    
    // uint256 public escrowAmount;
    uint256 public agrementId = 100;
    uint256 public AdminCommissionFee;
    
    constructor() {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);  // Aggregator: ETH/USD
    }

    function getLatestPrice() public view returns (uint256) {
        (
            , // uint80 roundID
            int price, 
            , // uint startedAt
            , // uint timeStamp
              // uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price / 10**8);
    }

    struct Agreement {
        uint256 id;
        string contractName;
        string details;
        string privacy;
        uint256 start_time;
        uint256 end_time;
        uint256 price;
        string validatersID;
        string employeeID;
        string employerID;
        uint256[] milstones;
        bool approved;
        bool validated;
        bool delivered;
    }

    struct milestone {
        uint256 id;
        string taskName;
        uint256 Mile_Price;
        string Priority;
        uint256 due_Date;
        uint256 submission_time;
        bool delivered;
        bool validated;
        bool Approve;
    }

    struct employer {
        uint256 id;
        string name;
        string email;
        uint256 phoneNo;
        uint256 allocationToken;
    }

    struct employee {
        uint256 id;
        string name;
        string email;
        uint256 phoneNo;
        uint256 allocationToken;
    }

    struct validator {
        uint256 id;
        string name;
        string email;
        uint256 phoneNo;
        uint256 allocationToken;
    }

    enum Role {
        employee,       // company
        employer,       // client
        validator
    }
    mapping(uint256 => mapping(uint256 => uint256))public escrowAmount;

    mapping(uint256 => mapping(uint256 => milestone))public milestoneDetails;
    mapping(uint256 => employer) public employerDetails;
    mapping(uint256 => employee) public employeeDetails;
    mapping(uint256 => validator) public validatorDetails;
    mapping(uint256 => Agreement) public agreementDetails;
    mapping(uint256 => mapping(uint256 => bool)) public fundTransfered;
    mapping(uint256 => bool)public contractCancelled;
    mapping(uint256 => mapping(uint256 => mapping(Role => bool))) public claimed;
    mapping(uint256 => mapping(uint256 => bool)) public scrowAmountDeposited;

    event registration(
        uint256 indexed id,
        string indexed name,
        string email,
        uint256 indexed phoneNo,
        Role role
    );

    event ContractCreation(
        uint256 indexed id,
        string details,
        string employeeId,
        uint256 start_time,
        uint256 end_time,
        uint256 price

    );

    //** this function for Registration of different participants according //
    // ** to have Role like Validators,employee,employer //
    function Registration(
        uint256 id,
        string memory name,
        string memory email,
        uint256 phoneNo,
        Role role
    ) public onlyOwner {
        require(
            employerDetails[id].id != id &&
                employeeDetails[id].id != id &&
                validatorDetails[id].id != id,
            "this id is already exist in participants"
        );
        if (role == Role.employee) {
            employee storage emp = employeeDetails[id];
            emp.id = id;
            emp.name = name;
            emp.email = email;
            emp.phoneNo = phoneNo;
            emit registration(id, name, email, phoneNo, role);
        } else if (role == Role.employer) {
            employer storage emplyr = employerDetails[id];
            emplyr.id = id;
            emplyr.name = name;
            emplyr.email = email;
            emplyr.phoneNo = phoneNo;
            emit registration(id, name, email, phoneNo, role);
        } else if (role == Role.validator) {
            validator storage validtr = validatorDetails[id];
            validtr.id = id;
            validtr.name = name;
            validtr.email = email;
            validtr.phoneNo = phoneNo;
            emit registration(id, name, email, phoneNo, role);
        }
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               

    //** this function is used to create agreement between employeee and employer **//

    function CreateContract(
        Agreement calldata _agrement,
        uint256[] memory Mile_Price,
        string[] memory _taskName,
        string[] memory priority,
        uint256[] memory due_date
        
    ) public{

        uint256 totalMile_Price;
        Agreement storage agreemnt = agreementDetails[agrementId];
        agreemnt.id=agrementId;
        agreemnt.contractName = _agrement.contractName;
        agreemnt.privacy=_agrement.privacy;
        agreemnt.details = _agrement.details;
        agreemnt.employeeID = _agrement.employeeID;
        agreemnt.start_time = _agrement.start_time;
        agreemnt.end_time = _agrement.end_time;
        agreemnt.price = _agrement.price;

        for (uint256 i = 0; i < Mile_Price.length; i++) {
            agreementDetails[agrementId].milstones.push(i);
            milestoneDetails[agrementId][i].id = i;
            milestoneDetails[agrementId][i].Mile_Price = Mile_Price[i];
            milestoneDetails[agrementId][i].taskName = _taskName[i];
            milestoneDetails[agrementId][i].Priority =priority[i];
            milestoneDetails[agrementId][i].due_Date = due_date[i];
            totalMile_Price = totalMile_Price.add(Mile_Price[i]);
        }
        require(
           totalMile_Price <= _agrement.price,
            "milestone price is greater than contract price"
        );
        emit ContractCreation(
            agrementId,
            _agrement.details,           
            _agrement.employeeID,
            _agrement.start_time,
            _agrement.end_time,
            _agrement.price
        );
        agrementId+= 1;   
    }
    function shareOption(uint256 agreementID,string memory _employerID)public{
        Agreement storage agrement = agreementDetails[agreementID];
        agrement.employerID=_employerID;

    }
    function Approve(
        uint256 _agreementID,
        string memory _employerID,
        bool status
    ) public {
        require(keccak256(bytes(agreementDetails[_agreementID].employerID)) == keccak256(bytes(_employerID)), "Only Employer");
        require(agreementDetails[_agreementID].approved != true, "Agreement already approved");
        agreementDetails[_agreementID].approved = status;
    }

    function depositFunds(uint256 _agreementID,uint256 _milesID) public payable {
        require(contractCancelled[_agreementID] != true,"Agreement cancelled");
        require(agreementDetails[_agreementID].approved, "Agreement not approved");
        require( scrowAmountDeposited[_agreementID][_milesID] !=true,"ScrowAmount already deposited");
        require(milestoneDetails[_agreementID][_milesID].Approve != true, "Milestone already delivered");
        require(msg.value == getMilestoneETHAmount(_agreementID,_milesID), "Incorrect amount");
        escrowAmount[_agreementID][_milesID] = escrowAmount[_agreementID][_milesID].add(msg.value);
        scrowAmountDeposited[_agreementID][_milesID]=true;
    }

    function deliverMilestone(
        uint256 _agreementID,
        uint256 _milesID,
        string memory _employeeID,
        uint256 _submissionTime    
    ) public {  
        require(keccak256(bytes(agreementDetails[_agreementID].employeeID)) == keccak256(bytes(_employeeID)), "Only Employee");
        require(contractCancelled[_agreementID] != true, "Agreement cancelled");
        require(milestoneDetails[_agreementID][_milesID].Approve != true, "Milestone already accepted");

        for (uint256 i = 0; i < agreementDetails[_agreementID].milstones.length; i++) {
            if (_milesID == agreementDetails[_agreementID].milstones[i]) {
                milestoneDetails[_agreementID][_milesID].delivered = true;
                milestoneDetails[_agreementID][_milesID].submission_time = _submissionTime;
            }
        }
    }

    function approveMilestone(
        uint256 _agreementID,
        string memory _employerID,
        uint256 _milesID,
        bool status,
        address receiver
    ) public {

        require(keccak256(bytes(agreementDetails[_agreementID].employerID)) == keccak256(bytes(_employerID)), "Only Employer");
        require(contractCancelled[_agreementID] != true, "Agreement cancelled");
        require(milestoneDetails[_agreementID][_milesID].Approve != true, "Milestone already approved");
        require(milestoneDetails[_agreementID][_milesID].delivered == true, "Milestone not delivered");
        require(fundTransfered[_agreementID][_milesID] != true, "Milestone already released");

        for (uint256 i = 0; i < agreementDetails[_agreementID].milstones.length; i++) {
            if (_milesID == agreementDetails[_agreementID].milstones[i]) {
                milestoneDetails[_agreementID][_milesID].Approve = status;
                
                if(status == true) {
                    uint amount = milestoneDetails[_agreementID][i].Mile_Price.mul(1e18).div(getLatestPrice());
                    uint fee = amount.mul(milestonefee).div(10000);
                    payable(owner).transfer(fee);
                    payable(receiver).transfer(amount.sub(fee));
                    AdminCommissionFee = AdminCommissionFee.add(fee);
                    escrowAmount[_agreementID][_milesID] = escrowAmount[_agreementID][_milesID].sub(amount);
                    fundTransfered[_agreementID][_milesID] = true;
                }
            }
        }
    }

    function getMilestoneETHAmount(uint256 agreementID, uint256 _mileID) public view returns(uint256){   
        milestone storage mile = milestoneDetails[agreementID][_mileID];
        uint256 milestonePrice = mile.Mile_Price.mul(1e18).div(getLatestPrice());
        return milestonePrice;
    }


    function convertUSDtoETH(uint256 amount) public view returns(uint256){
        uint256 _amount = amount.mul(1e18).div(getLatestPrice());
        return _amount;
    }

    //Validate-milestone:- Used to validated milestone(with respect to milestone id) by validator(validator id).
    function ValidateMilestone(
        // string memory validaterid,
        uint256 agreementID,
        uint256 milestoneID
    ) public {
        milestone storage mile = milestoneDetails[agreementID][milestoneID];
        require(contractCancelled[agreementID] !=true,"Agreement cancelled");
        require(milestoneDetails[agreementID][milestoneID].delivered == true, "it must be delivered");
        require(milestoneDetails[agreementID][milestoneID].Approve != true,"Milestone already accepted");
        mile.validated = true;

    } 

    // End contract id:-
    // Used to end contract-id with this parameter{time stamp,employer id , contract id].
    function endOfContract(uint256 agreementID,string memory employerId) public {
        Agreement storage agrement = agreementDetails[agreementID];
        require(keccak256(bytes(agrement.employerID)) == keccak256(bytes(employerId)),"Only employer have authority to end the contract");
        agreementDetails[agreementID].delivered = true;
        agreementDetails[agreementID].end_time = block.timestamp;
    }

    function cancelcontract(uint256 agreementID) public onlyOwner {
        contractCancelled[agreementID] = true;
    }

    function raiseDispute(uint256 agreementID, uint256 milesid, Role role) public {
        require(fundTransfered[agreementID][milesid] != true,"Fund already transfered");         
        if (role == Role.employee) {
            require(milestoneDetails[agreementID][milesid].delivered == true, "Milestone is not delivered");
            require(milestoneDetails[agreementID][milesid].Approve != true, "Check your Approval status");
            claimed[agreementID][milesid][role] = true;

        } else if (role == Role.employer) {
            require(milestoneDetails[agreementID][milesid].Approve != true, "Check your Approval status");
            require(escrowAmount[agreementID][milesid] >= milestoneDetails[agreementID][milesid].Mile_Price, "Funds not escrowed");
            claimed[agreementID][milesid][role] = true;

        } else {
            revert("Invalid Role");      
        } 
    }

    function disputeResolve(uint256 agreementID, uint256 milesID,uint256 amount, address receiver) public onlyOwner{
        require(amount<=address(this).balance,"Insufficient amount");
       
        for (uint256 i = 0; i < agreementDetails[agreementID].milstones.length; i++) {
            if (milesID == agreementDetails[agreementID].milstones[i]) {
                uint _amount = amount.mul(1e18).div(getLatestPrice());
                uint fee = _amount.mul(milestonefee).div(10000);
                payable(owner).transfer(fee);
                payable(receiver).transfer(_amount.sub(fee));
                AdminCommissionFee = AdminCommissionFee.add(fee);
                escrowAmount[agreementID][milesID] = escrowAmount[agreementID][milesID].sub(amount);
                fundTransfered[agreementID][milesID] = true;   
            }
        }         
    }

    function setMilestoneFee(uint fee) public onlyOwner {
        require(fee <= maxMilestoneFee,"Fee is greater than Maxmilestone Fee");
        milestonefee=fee;
    }

    function updatePriceFeed(address _priceFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);  // Aggregator: ETH/USD
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);  
    } 
    
                                                            
}