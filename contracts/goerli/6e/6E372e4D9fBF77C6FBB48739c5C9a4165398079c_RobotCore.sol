// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RobotMarketPlace.sol";

pragma solidity 0.8.15;

contract RobotCore is Ownable, RobotMarketPlace {

  uint256 public constant CREATION_LIMIT_GEN0 = 10;

  // Counts the number of robots the contract owner has created.
  uint256 public gen0Counter;

  constructor(){
    // We are creating the first robot at index 0  
    _createRobot(0, 0, 0, type(uint).max, address(0));
  }

/*
       we get a 

       Basic binary operation

       >>> '{0:08b}'.format(255 & 1)
       '00000001'
       >>> '{0:08b}'.format(255 & 2)
       '00000010'
       >>> '{0:08b}'.format(255 & 4)
       '00000100'
       >>> '{0:08b}'.format(255 & 8)
       '00001000'
       >>> '{0:08b}'.format(255 & 16)
       '00010000'
       >>> '{0:08b}'.format(255 & 32)
       '00100000'
       >>> '{0:08b}'.format(255 & 64)
       '01000000'
       >>> '{0:08b}'.format(255 & 128)
       '10000000'

       So we use a mask on our random number to check if we will use the firstRobotParentId or the secondRobotParentID

       For example 205 is 11001101 in binary So
       firstRobotParent - firstRobotParent - secondRobotParent - secondRobotParent - firstRobotParent - firstRobotParent - secondRobotParent - firstRobotParent

*/
  function Modifying(uint256 _secondRobotParentId, uint256 _firstRobotParentId) public {
      require(_owns(msg.sender, _secondRobotParentId), "The user doesn't own the token");
      require(_owns(msg.sender, _firstRobotParentId), "The user doesn't own the token");

      require(_firstRobotParentId != _secondRobotParentId, "The robot can't modify himself without scheme of another robot");

      ( uint256 secondRobotParentId,,,,uint256 secondRobotParentGeneration ) = getRobot(_secondRobotParentId);

      ( uint256 firstRobotParentId,,,,uint256 firstRobotParentGeneration ) = getRobot(_firstRobotParentId);

      uint256 newRobotId;
      uint256 [8] memory IdArray;
      uint256 index = 7;
      uint8 random = uint8(block.timestamp % 255);
      uint256 i = 0;
      
      for(i = 1; i <= 128; i=i*2){

          /* We are */
          if(random & i != 0){
              IdArray[index] = uint8(firstRobotParentId % 100);
          } else {
              IdArray[index] = uint8(secondRobotParentId % 100);
          }
          firstRobotParentId /= 100;
          secondRobotParentId /= 100;
        index -= 1;
      }
     
      /* Add a random parameter in a random place */
      uint8 newIdIndex =  random % 7;
      IdArray[newIdIndex] = random % 99;

      /* We reverse the Id in the right order */
      for (i = 0 ; i < 8; i++ ){
        newRobotId += IdArray[i];
        if(i != 7){
            newRobotId *= 100;
        }
      }

      uint256 newRobotGeneration = 0;
      if (secondRobotParentGeneration < firstRobotParentGeneration){
        newRobotGeneration = firstRobotParentGeneration + 1;
        newRobotGeneration /= 2;
      } else if (secondRobotParentGeneration > firstRobotParentGeneration){
        newRobotGeneration = secondRobotParentGeneration + 1;
        newRobotGeneration /= 2;
      } else{
        newRobotGeneration = firstRobotParentGeneration + 1;
      }

      _createRobot(_firstRobotParentId, _secondRobotParentId, newRobotGeneration, newRobotId, msg.sender);
  }


  function createRobotGen0(uint256 _id) public onlyOwner {
    require(gen0Counter < CREATION_LIMIT_GEN0);

    gen0Counter++;

    // Gen0 have no owners they are own by the contract
    uint256 tokenId = _createRobot(0, 0, 0, _id, msg.sender);
    setOffer(0.2 ether, tokenId);
  }

  function getRobot(uint256 _id)
    public
    view
    returns (
    uint256 id,
    uint256 buildTime,
    uint256 firstRobotParentId,
    uint256 secondRobotParentId,
    uint256 generation
  ) {
    Robot storage robot = robots[_id];

    require(robot.buildTime > 0, "the robot doesn't exist");

    buildTime = uint256(robot.buildTime);
    firstRobotParentId = uint256(robot.firstRobotParentId);
    secondRobotParentId = uint256(robot.secondRobotParentId);
    generation = uint256(robot.generation);
    id = robot.id;
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
import "./RobotOwnership.sol";

pragma solidity 0.8.15;

contract RobotMarketPlace is RobotOwnership {

  struct Offer {
    address payable seller;
    uint256 price;
    uint256 tokenId;
  }

  Offer[] offers;

  mapping (uint256 => Offer) tokenIdToOffer;
  mapping (uint256 => uint256) tokenIdToOfferId;


  event MarketTransaction(string TxType, address owner, uint256 tokenId);

  function getOffer(uint256 _tokenId)
      public
      view
      returns
  (
      address payable seller,
      uint256 price,
      uint256 tokenId

  ) {
      Offer storage offer = tokenIdToOffer[_tokenId];
      return (
          offer.seller,
          offer.price,
          offer.tokenId
      );
  }


  function getAllTokenOnSale() public view returns(uint256[] memory listOfToken){
    uint256 totalOffers = offers.length;
    
    if (totalOffers == 0) {
        return new uint256[](0);
    } else {
  
      uint256[] memory resultOfToken = new uint256[](totalOffers);

      uint256 offerId;
  
      for (offerId = 0; offerId < totalOffers; offerId++) {
        if(offers[offerId].price != 0){
          resultOfToken[offerId] = offers[offerId].tokenId;
        }
      }
      return resultOfToken;
    }
  }

  function setOffer(uint256 _price, uint256 _tokenId)
    public
  {
    
    //contract have the ability to transfer robots
    //As the robots will be in the market place we need to be able to transfer them
    //Checking if the user is owning the robot inside the approve function
    
    require(_price > 0.009 ether, "Robot price should be greater than 0.01");
    require(tokenIdToOffer[_tokenId].price == 0, "You can't sell twice the same offers ");

    approve(address(this), _tokenId);

    Offer memory _offer = Offer({
      seller: payable(msg.sender),
      price: _price,
      tokenId: _tokenId
    });

    tokenIdToOffer[_tokenId] = _offer;

    offers.push(_offer);

    uint index = offers.length -1;

    tokenIdToOfferId[_tokenId] = index;

    emit MarketTransaction("Create offer", msg.sender, _tokenId);
  }

  function removeOffer(uint256 _tokenId)
    public
  {
    require(_owns(msg.sender, _tokenId), "The user doesn't own the token");

    Offer memory offer = tokenIdToOffer[_tokenId];

    require(offer.seller == msg.sender, "You should own the robot to be able to remove this offer");

    //delete the offer info 
    delete offers[tokenIdToOfferId[_tokenId]];

    //Remove the offer in the mapping
    delete tokenIdToOffer[_tokenId];


    _deleteApproval(_tokenId);

    emit MarketTransaction("Remove offer", msg.sender, _tokenId);
  }

  function buyRobot(uint256 _tokenId)
    public
    payable
  {
    Offer memory offer = tokenIdToOffer[_tokenId];
    require(msg.value == offer.price, "The price is not correct");

    //delete the offer info
    delete offers[tokenIdToOfferId[_tokenId]];

    //Remove the offer in the mapping
    delete tokenIdToOffer[_tokenId];

    _approve(_tokenId, msg.sender);


    transferFrom(offer.seller, msg.sender, _tokenId);

    offer.seller.transfer(msg.value);
    emit MarketTransaction("Buy", msg.sender, _tokenId);
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
pragma solidity 0.8.15;

import "./RobotFactory.sol";

contract RobotOwnership is RobotFactory{

  string public constant name = "TechnoirClub";
  string public constant symbol = "NOIR";

  event Approval(address owner, address approved, uint256 tokenId);

  
  // I use the modulo of each function to set the interfaceId
  
  bytes4 constant InterfaceSignature_ERC165 =
      bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 constant InterfaceSignature_ERC721 =
      bytes4(keccak256('name()')) ^
      bytes4(keccak256('symbol()')) ^
      bytes4(keccak256('totalSupply()')) ^
      bytes4(keccak256('balanceOf(address)')) ^
      bytes4(keccak256('ownerOf(uint256)')) ^
      bytes4(keccak256('approve(address,uint256)')) ^
      bytes4(keccak256('transfer(address,uint256)')) ^
      bytes4(keccak256('transferFrom(address,address,uint256)')) ^
      bytes4(keccak256('tokensOfOwner(address)')) ^
      bytes4(keccak256('tokenMetadata(uint256,string)'));

  function supportsInterface(bytes4 _interfaceID) external pure returns (bool)
  {
      return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return robotIndexToOwner[_tokenId] == _claimant;
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return robotIndexToApproved[_tokenId] == _claimant;
  }

  function _approve(uint256 _tokenId, address _approved) internal {
      robotIndexToApproved[_tokenId] = _approved;
  }

  function _deleteApproval(uint256 _tokenId) internal {
      require(_owns(msg.sender, _tokenId));
      delete robotIndexToApproved[_tokenId];
  }


  
  // Function required by the erc 721 interface
  

  function totalSupply() public view returns (uint) {
      return robots.length - 1;
  }

  function balanceOf(address _owner) public view returns (uint256 count) {
      return ownershipTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId)
      external
      view
      returns (address owner)
  {
      owner = robotIndexToOwner[_tokenId];

      require(owner != address(0));
  }

  function approve(
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_owns(msg.sender, _tokenId));

      _approve(_tokenId, _to);
      emit Approval(msg.sender, _to, _tokenId);
  }

  function transfer(
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_to != address(0));
      require(_owns(msg.sender, _tokenId));

      _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
  )
      public
  {
      require(_to != address(0));
      require(_approvedFor(msg.sender, _tokenId));
      require(_owns(_from, _tokenId));

      _transfer(_from, _to, _tokenId);
  }

  function tokensOfOwner(address _owner) public view returns(uint256[] memory ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);

    if (tokenCount == 0) {
        return new uint256[](0);
    } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalRobots = totalSupply();
        uint256 resultIndex = 0;

        uint256 robotId;

        for (robotId = 1; robotId <= totalRobots; robotId++) {
            if (robotIndexToOwner[robotId] == _owner) {
                result[resultIndex] = robotId;
                resultIndex++;
            }
        }

        return result;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract RobotFactory {

  
// A new robot is build
  
event Build( address owner, 
             uint256 robotId, 
             uint256 firstRobotParentId,
             uint256 secondRobotParentId, 
             uint256 id);

  
//A robot has been transfer
  
event Transfer( address indexed from, 
                address indexed to, 
                uint256 indexed tokenId);



struct Robot { 
              uint256 id;
              uint64 buildTime;
              uint32 firstRobotParentId;
              uint32 secondRobotParentId;
              uint16 generation;
              }

   Robot[] robots;

  mapping (uint256 => address) public robotIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;

  // Add a list of approved robots, that are allowed to be transfered
  mapping (uint256 => address) public robotIndexToApproved;

  function _createRobot(
              uint256 _firstRobotParentId,
              uint256 _secondRobotParentId,
              uint256 _generation,
              uint256 _id,
              address _owner
    ) 
    internal returns (uint256) 
    {
        Robot memory _robot = Robot({
            id: _id,
            buildTime: uint64(block.timestamp),
            firstRobotParentId: uint32(_firstRobotParentId),
            secondRobotParentId: uint32(_secondRobotParentId),
            generation: uint16(_generation)
        });

        robots.push(_robot);
        uint newRobotId = robots.length - 1;

    // It's probably never going to happen, 4 billion robotss is A LOT, but
    // let's just be 100% sure this never happen.
    require(newRobotId == uint256(uint32(newRobotId)));

    // emit the build event
    emit Build(
        _owner,
        newRobotId,
        uint256(_robot.firstRobotParentId),
        uint256(_robot.secondRobotParentId),
        _robot.id
    );

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newRobotId);
    return newRobotId;
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {

    // Since the number of robots is capped to 2^32 we can't overflow this
    ownershipTokenCount[_to]++;
    // transfer ownership
    robotIndexToOwner[_tokenId] = _to;

    if (_from != address(0)) {
        ownershipTokenCount[_from]--;

        delete robotIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _tokenId);
  }
}