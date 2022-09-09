//SPDX-License-Identifier: Unlicenççse

pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IBEP20.sol";

// import "hardhat/console.sol";

contract Meeting {
    address owner;
    IERC721  public erc721;
    IBEP20 public vbit;
    // Constructor
    constructor(address _erc721, address _vbit){
    owner =msg.sender;
    erc721 = IERC721(_erc721);
    vbit = IBEP20(_vbit);
    }
    struct MeetingRoom{
        uint256 roomNo;
        uint256 capacity; 
        string baseUrl;
        address owner;
        uint256 price;
        string status; // created, onsell, onrent
    }
    struct Booking{
        uint256 roomNo;
        uint256 capacity; 
        string baseUrl;
        address owner;
        address booker;
        uint256 price;
        string status; // "booked" | "complete" | "cancelled"
        uint256 checkIn;
        uint256 checkOut;
        uint256 totalPayment;
        uint256 noOfBookings;
        uint256 participentFee;
        bool isCertificate;
    }
    struct Participents{
      uint256 noUsers;
      address[] participator;
      mapping(address => bool) participantJoin;
    }
    mapping(uint256 => MeetingRoom) meetingRoom;
    mapping(uint256 => MeetingRoom) sellRooms; 
    mapping(uint256 => Booking) booking;
    mapping(uint256 => Participents) participents;
    mapping(uint256 => bool) public isRoomExist;
    // Events
    event DevelopRoom(uint256 _roomId,uint256 _capacity,string _baseUrl);
    event SellRoom(uint256 roomNo, uint256 roomPrice, address _to, string baseUrl, uint256 capacity,string status);
    event RentRoom(uint256 roomNo, uint256 roomPrice, address _to, string baseUrl, uint256 capacity,string status);
    event BookMeeting(uint256 roomId,uint256 totalPayment, string baseUrl,uint256 capacity, string status,  uint256 checkIn,uint256 checkOut);
    event CancelRentRoom(address sender, uint256 roomId);
    event JoinMeeting(uint256 roomId,address sender, uint256 participantFee, address meetingCreator);
    event CompleteMeeting(uint256 roomId,address sender, bool isCertificate);
    event CancelMeeting(address sender,uint256 participentFee, uint256 participators);

  
    modifier onlyOwer{
        require(msg.sender == owner,"OWNER_ONLY");
        _;
    }
    // Develop Room By Metaverse Owner
  function developRoom(uint256 _roomId, uint256 _capacity,string memory _baseUrl)external onlyOwer{
    require(isRoomExist[_roomId], "ALREADY_EXIST");
    meetingRoom[_roomId].owner = msg.sender;
    meetingRoom[_roomId].capacity = _capacity;
    meetingRoom[_roomId].baseUrl = _baseUrl;
    meetingRoom[_roomId].status = "created";
    erc721.mint(msg.sender, _roomId,_baseUrl,"");
    isRoomExist[_roomId] = true;
    emit DevelopRoom(_roomId,_capacity,_baseUrl);
       
  }

  // Sell Room if ownership exist
  function sellRoom(uint256 _roomId, uint256 _roomPrice) external{
     
    require(isRoomExist[_roomId] &&  keccak256(bytes(meetingRoom[_roomId].status)) == keccak256(bytes("created")) ,"NOT_LISTED");
    require(_roomPrice > 0 , "INVALID_PRICE");
    require(erc721.isApprovedForAll(msg.sender, address(this)) == true,"NOT_APPROVE");
    erc721.transferFrom(msg.sender, address(this), _roomId);
    meetingRoom[_roomId].owner = address(this);
    meetingRoom[_roomId].status = "onsell";
    meetingRoom[_roomId].price = _roomPrice;
    emit SellRoom(_roomId, _roomPrice,address(this), meetingRoom[_roomId].baseUrl, meetingRoom[_roomId].capacity, meetingRoom[_roomId].status);

    } 

  // Add room on Rent if its not on sell and ownership exist
  function rentRoom(uint256 _roomId, uint256 _priceHourly/* , uint256 _rOrderNo */) external{
    require(isRoomExist[_roomId] &&  keccak256(bytes(meetingRoom[_roomId].status)) == keccak256(bytes("created")) ,"NOT_LISTED");
    require(_priceHourly > 0 , "INVALID_PRICE");
    require(erc721.isApprovedForAll(msg.sender, address(this)) == true,"NOT_APPROVE");
    erc721.transferFrom(msg.sender, address(this), _roomId);
    meetingRoom[_roomId].owner = address(this);
    meetingRoom[_roomId].status = "onrent";
    meetingRoom[_roomId].price = _priceHourly;
    emit RentRoom(_roomId, _priceHourly,address(this), meetingRoom[_roomId].baseUrl, meetingRoom[_roomId].capacity, meetingRoom[_roomId].status);
  }

  // Book A room On Hourly Basis
  function bookMeeting(uint256 _roomId, uint256 _checkIn, uint256 _checkOut, uint256 _fee, bool _certified)external{
    require(isRoomExist[_roomId] &&  keccak256(bytes(meetingRoom[_roomId].status)) == keccak256(bytes("onrent")) ,"NOT_LISTED");
    require(_checkIn > block.timestamp && _checkOut> _checkIn,"INVALID_TIME" );
    booking[_roomId].totalPayment = calculateFee(_roomId, _checkIn,_checkOut);
    require(vbit.allowance(msg.sender, address(this)) >= booking[_roomId].totalPayment ,"NOT_ENOUGH_ALLOWANCE");
    require(vbit.balanceOf(msg.sender)> booking[_roomId].totalPayment ,"NOT_ENOUGH_BALANCE");
    booking[_roomId].roomNo = _roomId;
    booking[_roomId].capacity = meetingRoom[_roomId].capacity;
    booking[_roomId].owner = meetingRoom[_roomId].owner;
    booking[_roomId].booker = msg.sender;
    booking[_roomId].price = meetingRoom[_roomId].price;
    booking[_roomId].status = "booked";
    booking[_roomId].checkIn = _checkIn;
    booking[_roomId].checkOut = _checkOut;
    booking[_roomId].noOfBookings +=1;
    booking[_roomId].participentFee = _fee;
    booking[_roomId].isCertificate = _certified;
    vbit.transferFrom(msg.sender, address(this), booking[_roomId].totalPayment);  
    emit BookMeeting(_roomId,booking[_roomId].totalPayment, meetingRoom[_roomId].baseUrl, booking[_roomId].capacity, booking[_roomId].status, _checkIn,_checkOut);

  }
  // cancel From Listed on Rent
  function cancelRentRoom(uint256 _roomId)external{
    require(isRoomExist[_roomId] &&  keccak256(bytes(meetingRoom[_roomId].status)) == keccak256(bytes("onrent")) ,"NOT_LISTED");
    require(meetingRoom[_roomId].owner ==msg.sender,"NOT_OWNER");
    require(booking[_roomId].noOfBookings == 0,"BOOKING_EXIST");
    meetingRoom[_roomId].status = "created";
    erc721.transferFrom( address(this),msg.sender, _roomId);
    emit CancelRentRoom(msg.sender, _roomId);


  }
  // Participant Participate in meeting
  function joinMeeting(uint256 _roomId) external{
   require( keccak256(bytes(booking[_roomId].status)) == keccak256(bytes("onrent")));
   require(participents[_roomId].noUsers < booking[_roomId].capacity ,"No_SPACE" );
   require(participents[_roomId].participantJoin[msg.sender],"ALREADY_JOINED");
   if(booking[_roomId].participentFee > 0){
    require(vbit.allowance(msg.sender, address(this)) >= booking[_roomId].participentFee,"NOT_APPORVED");
    require(vbit.balanceOf(msg.sender) >= booking[_roomId].participentFee,"NOT_ENOUGH_BALANCE");
    vbit.transferFrom(msg.sender, booking[_roomId].booker,booking[_roomId].participentFee);
   }
   else{}
   participents[_roomId].participator.push(msg.sender);
   participents[_roomId].noUsers +=1; 
   participents[_roomId].participantJoin[msg.sender]= true;
   emit JoinMeeting(_roomId,msg.sender,booking[_roomId].participentFee, booking[_roomId].booker );

  }
  // Owner Complete Meeting
  function completeMeeting(uint256 _roomId)external{
    require(msg.sender == booking[_roomId].booker, "NOT_MEETING_OWNER");
    require(keccak256(bytes(booking[_roomId].status)) == keccak256(bytes("booked")),"MEETING_NOT_EXIST");
    booking[_roomId].status = "completed";
    if(booking[_roomId].isCertificate){
      // Mint New NFT as Certificate
    }
    emit CompleteMeeting(_roomId, msg.sender, booking[_roomId].isCertificate);
  }
  // Cancel Meeting By Owner
  function cancelMeeting(uint256 _roomId)external{
       require(msg.sender == booking[_roomId].booker,"NOT_BOOKING_OWNER");
       require( keccak256(bytes(booking[_roomId].status)) == keccak256(bytes("booked")), "MEETING_NOT_EXIST");
       require(booking[_roomId].checkIn <= block.timestamp , "MEETING_STARTED");
       if(booking[_roomId].participentFee > 0){
        for(uint256 i =0 ; i< participents[_roomId].participator.length; i++){
          vbit.transfer(participents[_roomId].participator[i],booking[_roomId].participentFee );
        }
       }else{}
       booking[_roomId].status = "cancelled";
       emit CancelMeeting(msg.sender,booking[_roomId].participentFee, participents[_roomId].participator.length);

  }

  // Change Owner
  function changeOwner(address _newOwner)external {
    require(msg.sender == owner, "NOT_OWNER" );
    require(_newOwner !=address(0), "ZERO_ADDRESS");
    owner = _newOwner;
    
  }
  // Calculate Fee Amount According To Time of Booking
  function calculateFee(uint256 _roomId,uint256 _checkIn, uint256 _checkOut)public view returns(uint256){
    require(_checkOut > _checkIn ,"INVALID_TIME");  
    uint256 total = ((_checkOut- _checkIn)*meetingRoom[_roomId].price)/1 hours;
    // console.log("Total is ", total);
    return total;
  }
}

//SPDX-License-Identifier: Unlicenççse

pragma solidity ^0.8.0;

interface IERC721 {
  function burn(uint256 tokenId) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri,
    string calldata _payload
  ) external;

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  function ownerOf(uint256 _tokenId) external returns (address _owner);

  function getApproved(uint256 _tokenId) external returns (address);

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external;

  function creator(uint256 _id) external returns (address);
}

//SPDX-License-Identifier: Unlicenççse


pragma solidity ^0.8.0;

// BEP20 Hardhat token = 0x5FbDB2315678afecb367f032d93F642f64180aa3
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
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
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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
  event Approval(address indexed owner, address indexed spender, uint256 value);
}