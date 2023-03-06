// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ERC20TokenInterface {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address owner) external returns (uint256);

    function decimals() external returns (uint256);
}

/**
 * @title AuctionApplication
 * @dev This is a primary contract for cellchain slot candle auction. 
        Participants deploy their own participant contract through this contract.
        This starts and finishes auction, and selects the winner participant and mint slot NFT for it.
 */
contract ApplicationPrimary {
    
    event Apply(
        uint256 auctionID,
        address indexed participant,
        string  project_name,
        bool project_type,
        string metaURI,
        uint slotRental,
        address sc_address,
        uint amountTokenProject
    );

    event ReturnFund(uint256 projectID, address receiver);

    event BID(
        uint256 projectID,
        address bidder,
        uint256 timestamp,
        uint256 timeTokenUnlock,
        address tokenAddress,
        uint256 amount
    );

    struct Project{
        uint256 auctionID;
        address participant;
        string  project_name;
        bool project_type;
        string metaURI;
        uint256 slotRental;
        address projectToken;
        uint256 amountTokenProject;
    }


    uint256 public constant PLEDGE_AMOUNT = 1000 * (10**18);
    uint projectID;
    address public owner;
    address admin;
    address constant LP = 0x15B3477Cf98346f9184320281A8a70ebCA42Deb3;
    address constant CELL = 0xCc1921AbFAFE6809FD1590Bf38e7Dc37E6B83f8b;

    mapping(uint => Project) public projectApply;

    
    mapping(address => mapping(address => uint)) ownerProject;
    mapping(address => mapping(address => uint)) paidBid;
    mapping(address => bool) paidApplication;


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManagment() {
        require(
            msg.sender == owner ||
            msg.sender == admin,
            "You are not in management"

            );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"You are not in owner");
        _;
    }

    Project project;

    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin;
    }

    /**
     * @notice Applicants who want to own the slot should apply for the slot auction with pledge.
     */
    function applyTo(
        uint256 auctionID,
        string memory _projectName,
        /// тут должен быть период на который он хочет получить слот
        uint8 _countSlotRental,
        bool _typeProject,// если проект не краудлаун тогда за него голосавать может только владелец проекта
        string memory _metaURI,
        address tokenAddressProject,
        uint amountTokenProject
    ) external {
        require(
            _countSlotRental % 3 == 0 && _countSlotRental <= 24,
            "Slot rental minimal 3 months"
        );

        project = Project(
            auctionID,
            msg.sender,
            _projectName,
            _typeProject,
            _metaURI,
            _countSlotRental,
            tokenAddressProject,
            amountTokenProject
            );

        projectApply[projectID] = project;

        projectID ++;
        paidApplication[msg.sender] = true;
      
        ERC20TokenInterface(CELL).transferFrom( //После того как его добавили средства должны вернуться
            msg.sender,
            address(this),
            PLEDGE_AMOUNT
        );

        if (tokenAddressProject != address(0)) {

            ERC20TokenInterface(tokenAddressProject).transferFrom(
                msg.sender,
                address(this),
                amountTokenProject
            );
            ownerProject[msg.sender][tokenAddressProject] += amountTokenProject;
        }
        
        emit Apply(
            auctionID,
            msg.sender,
            _projectName,
            _typeProject,
            _metaURI,
            _countSlotRental,
            tokenAddressProject,
            amountTokenProject
        );
    }

    /**
   * @notice Owner can approve or decline the applications. Approved applications can participate in the auction.
      The pledge will return back to applicant.
   */
    function returnFund(
        uint256 _projectID,
        address receiver,
        address _tokenProject
        )external onlyManagment {

        require(
            paidApplication[receiver],
            "Receiver not paid"
            );

        paidApplication[receiver]= false;
        ERC20TokenInterface(CELL).transfer(receiver, PLEDGE_AMOUNT);

        if(_tokenProject != address(0)){
            uint balanceToken = projectApply[_projectID].amountTokenProject;
            
            ERC20TokenInterface(_tokenProject).transfer(
                receiver, 
                balanceToken
                );
        }
        delete projectApply[_projectID];
        emit ReturnFund(_projectID, receiver);
    }

    /**
     * @notice Vote funds to the project. if it is a private project, only the manager can vote to it.
     */
     //голосовать только селами или лп селами
    function bid(
        uint256 _projectID,
        uint256 amount,
        uint8 countMonths,
        address tokenAddress
    ) external {
        
        require(amount > 0, "You should vote at least more than 0");
        require(
            tokenAddress == CELL || tokenAddress == LP,
            "error token"
        );
//@notice Vote funds to the project. if it is a private project, only the manager can vote to it.

        bool typeProject = projectApply[_projectID].project_type;

        if (typeProject){
            require(
                msg.sender == projectApply[_projectID].participant,
                "if it is a private project, only the manager"
                );
        }

        paidBid[msg.sender][tokenAddress] += amount;
        ERC20TokenInterface bidToken = ERC20TokenInterface(tokenAddress);
        
        bidToken.transferFrom(
            msg.sender,
            address(this),
            amount 
        );

        uint timeUnlock = time(block.timestamp,countMonths);
        
        emit BID(
            _projectID,
            msg.sender,
            block.timestamp,
            timeUnlock,
            tokenAddress,
            amount
        );
    }

    function claimFundsBid(
        uint tokenAmount,
        address tokenAddress
        ) external onlyManagment  {

        require(
            paidBid[msg.sender][tokenAddress] >= tokenAmount,
            "Paid bid < tokenAmount"
            );

        paidBid[msg.sender][tokenAddress]-= tokenAmount;

        ERC20TokenInterface(tokenAddress).transfer(
            msg.sender, 
            tokenAmount
            );
    }



    function time(uint _time,uint countMonths) internal pure returns (uint){
        require(
            countMonths % 3 == 0 && countMonths <= 24,
            "Number of months must be a multiple of 3"
            );
        return _time + (4 weeks * countMonths);
    }


    function setAdmin(address _newAdmin) external onlyOwner{
        admin = _newAdmin;
    }

}