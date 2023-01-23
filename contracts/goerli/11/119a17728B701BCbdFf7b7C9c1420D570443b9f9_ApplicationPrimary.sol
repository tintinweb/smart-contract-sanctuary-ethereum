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
        bytes32  project_name,
        bool project_type,
        uint256 st_range,
        uint256 end_range,
        bytes32 metaURI,
        address sc_address
    );

    event ReturnFund(uint256 projectID, address receiver);

    event BID(
        uint256 projectID,
        address bidder,
        uint256 timestamp,
        address tokenAddress,
        uint256 amount,
        uint8 st_range,
        uint8 end_range
    );

    uint256 public constant PLEDGE_AMOUNT = 1000 * (10**18);
    address public owner;
    address[] tokens;
    address constant LP = 0x15B3477Cf98346f9184320281A8a70ebCA42Deb3;
    address constant CELL = 0xCc1921AbFAFE6809FD1590Bf38e7Dc37E6B83f8b;

    mapping(address => mapping(address => uint)) paidBid;
    mapping(address => bool) paidApplication;
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }



    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Applicants who want to own the slot should apply for the slot auction with pledge.
     */
    function applyTo(
        uint256 auctionID,
        string memory _name,
        bool _typeProject,
        uint256 st_range,
        uint256 end_range,
        string memory _metaURI,
        address token_address
    ) external {
      paidApplication[msg.sender] = true;
        ERC20TokenInterface(CELL).transferFrom(
            msg.sender,
            address(this),
            PLEDGE_AMOUNT
        );


        emit Apply(
            auctionID,
            msg.sender,
            bytes32(bytes(_name)),
            _typeProject,
            st_range,
            end_range,
            bytes32(bytes(_metaURI)),
            token_address
        );
    }

    /**
   * @notice Owner can approve or decline the applications. Approved applications can participate in the auction.
      The pledge will return back to applicant.
   */
    function returnFund(uint256 projectID, address receiver) external onlyOwner {
      require(paidApplication[receiver]);
      paidApplication[receiver]= false;
      ERC20TokenInterface(CELL).transfer(receiver, PLEDGE_AMOUNT);
      emit ReturnFund(projectID, receiver);
    }

    /**
     * @notice Vote funds to the project. if it is a private project, only the manager can vote to it.
     */
     //голосовать только селами или лп селами
    function bid(
        uint256 projectID,
        uint8 st_range,
        uint8 end_range,
        uint256 amount,
        address tokenAddress
    ) external {
        require(
            st_range <= end_range,
            "End time must be bigger than start time"
        );
        require(amount > 0, "You should vote at least more than 0");
        require(
            tokenAddress == CELL || 
            tokenAddress == LP,
            "error token"
        );
//@notice Vote funds to the project. if it is a private project, only the manager can vote to it.
        paidBid[msg.sender][tokenAddress] += amount;
        ERC20TokenInterface bidToken = ERC20TokenInterface(tokenAddress);
        bidToken.transferFrom(
            msg.sender,
            address(this),
            amount * (10 ** bidToken.decimals())
        );
        

        emit BID(
            projectID,
            msg.sender,
            block.timestamp,
            tokenAddress,
            amount,
            st_range,
            end_range
        );
    }

    function claimFundsBid(uint tokenAmount,address tokenAddress) external onlyOwner {
      require(paidBid[msg.sender][tokenAddress] >= tokenAmount);
      paidBid[msg.sender][tokenAddress]-= tokenAmount;
      ERC20TokenInterface(tokenAddress).transfer(msg.sender, tokenAmount * 10**ERC20TokenInterface(tokenAddress).decimals());
    }

    function addToken(address _token) external onlyOwner{
        require(_token != address(0),"Error zero addr");
        tokens.push(_token);
    }

}