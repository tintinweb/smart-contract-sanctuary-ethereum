/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

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


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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


contract XXXGCore is Ownable {

  IERC20 public tokenMXGF;

}



abstract contract Referal is XXXGCore {

  modifier isRegistred {
    require(parent[msg.sender] != address(0), "You are not registred");
    _;
  }

  struct User {
    bool autoReCycle;
    bool autoUpgrade;
  }

  mapping(address => User) public users;
  mapping(address => address) public parent;
  mapping(address => address[]) public childs;

  mapping(address => mapping(uint => bool)) public activate; // user -> lvl -> active

  uint32 public lastId;

   struct UserAccount {
        uint32 id;
        uint32 directSales;
        address sponsor;
        bool exists;
        uint8[] activeSlot;
    }

    mapping(address => mapping(uint8 => S9)) public s9Slots;

     uint8 public constant S9_LAST_LEVEL = 10;
     uint internal reentry_status;
 
struct S9 {
        address sponsor;
        uint32 directSales;
        uint16 cycleCount;
        uint8 passup;
        uint8 cyclePassup;
        uint8 reEntryCheck;
        uint8 placementPosition;
        address[] firstLevel;
        address placedUnder;
        uint8 lastOneLevelCount;
        uint8 lastTwoLevelCount;
        uint8 lastThreeLevelCount;
    }
     mapping(address => UserAccount) public userAccounts;
    mapping(uint32 => address) public idToUserAccount;
    mapping(address => mapping(uint => bool)) public activateS9; // user -> lvl -> active
       modifier isUserAccount(address _addr) {
        require(userAccounts[_addr].exists, "Register Account First");
        _;
    }

  constructor(){

      /// Set first User
      parent[msg.sender] = msg.sender;
      users[msg.sender] = User(false,false);
      for (uint i = 0; i < 12; i++) {
          activate[msg.sender][i] = true;
      } 


      createAccount(msg.sender, msg.sender, true);

      
  }

  event regEv(address _newUser,address _parent, uint timeNow);
  function registration(address _parent) external {
      require(msg.sender != _parent, "You can`t be referal");
      require(parent[msg.sender] == address(0), "You allready registred");

      parent[msg.sender] = _parent;
      childs[_parent].push(msg.sender);
        
       createAccount(msg.sender, _parent, false);

        idToUserAccount[lastId] = msg.sender;

      emit regEv(msg.sender, _parent, block.timestamp);
  }

   function createAccount(address _user, address _sponsor, bool _initial) internal {

        require(!userAccounts[_user].exists, "Already a Singhs Account");

        if (_initial == false) {
            require(userAccounts[_sponsor].exists, "Sponsor doesnt exists");
        }

        lastId++;

          userAccounts[_user] = UserAccount({
             id: lastId,
             sponsor: _sponsor,
             exists: true,
             directSales: 0,
             activeSlot: new uint8[](2)
         });

      

        idToUserAccount[lastId] = _user;

        

    }

  function getParent() view external returns(address) {
    return parent[msg.sender];
  }

  function getChilds() view external returns(address[] memory) {
    return childs[msg.sender];
  }

  function _isActive(address _address, uint _lvl) internal view returns(bool) {
      return activate[_address][_lvl];
  }

}


abstract contract Programs is Referal {
  mapping(uint => Product) public products;
  mapping(uint8 => uint) public s9LevelPrice;

  enum Product {
      s2,
      s3,
      s6
  }

  

    uint[12] public prices;
   
   

  constructor(){
    
   for (uint i = 0; i < 12; i++) {
       if(i == 0 || i == 11)
        {
            products[i]=Product.s2;
        }
        else if(i == 1 || i == 10)
        {
            products[i]=Product.s3;
        }
        else{
            products[i]=Product.s6;
        }
       
    }


    prices[0] = 2 * (10 ** 18);
    prices[1] = 3 * (10 ** 18);
    prices[2] = 5 * (10 ** 18);
    prices[3] = 10 * (10 ** 18);
    prices[4] = 20 * (10 ** 18);
    prices[5] = 40 * (10 ** 18);
    prices[6] = 80 * (10 ** 18);
    prices[7] = 160 * (10 ** 18);
    prices[8] = 320 * (10 ** 18);
    prices[9] = 640 * (10 ** 18);
    prices[10] = 750 * (10 ** 18);
    prices[11] = 1000 * (10 ** 18);


    s9LevelPrice[1] = 4 * 1e18;
    s9LevelPrice[2] = 8 * 1e18;
    s9LevelPrice[3] = 16 * 1e18;
    s9LevelPrice[4] = 25 * 1e18;
    s9LevelPrice[5] = 50 * 1e18;
    s9LevelPrice[6] = 100 * 1e18;
    s9LevelPrice[7] = 200 * 1e18;
    s9LevelPrice[8] = 400 * 1e18;
    s9LevelPrice[9] = 800 * 1e18;
    s9LevelPrice[10] = 1600 * 1e18;     
   
   
  }

  function _sendDevisionMoney(address _parent, uint _price, uint _percent) internal {
    uint amoutSC = _price * _percent / 100;
    tokenMXGF.transferFrom(msg.sender, _parent, (_price - amoutSC)); // transfer token to me
    tokenMXGF.transferFrom(msg.sender, address(this), amoutSC); // transfer token to smart contract
  }

  function getActivateParent(address _child, uint _lvl) internal view returns (address response) {
      address __parent = parent[_child];
      while(true) {
          if (_isActive(__parent, _lvl)) {
              return __parent;
          } else {
              __parent =parent[__parent];
          }
      }
  }
}


abstract contract S3 is Programs {

  struct structS3 {
    uint slot;
    uint lastChild;
    uint frozenMoneyS3;
  }

  mapping (address => mapping(uint => structS3)) public matrixS3; // user -> lvl -> structS3

  mapping(address => mapping(uint => address[])) public childsS3;

 
  
  function updateS3(address _child, uint lvl) isRegistred internal{
    address _parent = getActivateParent(_child, lvl);

    // Increment lastChild
    structS3 storage _parentStruct = matrixS3[_parent][lvl];
    uint _lastChild = _parentStruct.lastChild;
    _parentStruct.lastChild++;
    _lastChild = _lastChild % 3;

    // Get price
    uint _price = prices[lvl];

    // First Child
    if (_lastChild == 0) {
     
       tokenMXGF.transferFrom(msg.sender, _parent, _price);
    
    }

    // Second Child
    if (_lastChild == 1) {
     
        tokenMXGF.transferFrom(msg.sender, _parent, _price); // transfer money to parent
      
    }

    // Last Child
    if (_lastChild == 2) {
      
        if (_parent != owner()){
        
          emit updates2Ev(_child,_parent,  lvl,_lastChild,  _price, block.timestamp);
           updateS3(_parent, lvl); // update parents product
        }
        else{
            tokenMXGF.transferFrom(msg.sender, address(this), _price);
        }

    
      _parentStruct.slot++;
    }

    // Push new child
    childsS3[_parent][lvl].push(_child);
    // matrixS3[_parent][lvl].childsLvl1.push(_child);
    emit updates2Ev(_child,_parent,  lvl,_lastChild,  _price, block.timestamp);
  }

  struct structS6 {
    uint slot;
    uint lastChild1;
    uint lastChild2;
    uint frozenMoneyS6;
  }

  mapping (address => mapping(uint => structS6)) public matrixS6; // user -> lvl -> structS6

  mapping(address => mapping(uint => address[])) public childsS6Lvl1;
  mapping(address => mapping(uint => address[])) public childsS6Lvl2;

  event buyEv(address _user,uint  lvl, uint timeNow, uint amount);
  function buy(uint lvl) isRegistred  public {
      require(activate[msg.sender][lvl] == false, "This level is already activated");
      require(lvl < 12, "Wrong level");
      // Check if there is enough money

      for (uint i = 0; i < lvl; i++) {
        require(activate[msg.sender][i] == true, "Previous level not activated");
      }
     // if(tst > 30 ) return true;
    if(products[lvl] == Product.s2) {
        updateS2(msg.sender, lvl);
      }
      else if (products[lvl] == Product.s3) {
        updateS3(msg.sender, lvl);
      }  
      else {
        updateS6(msg.sender, lvl);
      }
    emit buyEv(msg.sender, lvl, block.timestamp, prices[lvl]);
      // Activate new lvl
      activate[msg.sender][lvl] = true;
  }
  event _changePositionEv(address _mainuser, address _grandpa, uint _price, uint _grandpaPosition,uint lvl,uint _lastChild1, address _parent, uint _cLvl);
  
  function updateS6(address _child, uint lvl) isRegistred internal returns (address) {
    uint _level = lvl;
    address _parent = getActivateParent(_child, lvl);
    address _grandpa = getActivateParent(_parent, lvl);
     //if(tstt > 28 ) return true;
    // Increment lastChild
    structS6 storage _parentStruct = matrixS6[_parent][lvl];
    structS6 storage _grandpaStruct = matrixS6[_grandpa][lvl];
     //if(tstt > 27 ) return true;
    // Set null value
    if (_parentStruct.lastChild1 == 0) {
      _setNull(_parent, lvl);
    }

    // Get price
    uint _price = prices[lvl];

    // Looking for level
    uint _lastChild1 = _parentStruct.lastChild1;
    uint cLvl = 1;
    // Get Lvl, where we will work
    if (_lastChild1 % 2 == 0 && _lastChild1 != 0 && _parentStruct.slot * 2 != _lastChild1) {
      cLvl = 2;
    }
    // set 1 lvl
    if (cLvl == 1) {
      // Parent
      // Set info to parent
      if (childsS6Lvl1[_parent][lvl][_parentStruct.slot * 2] == address(0)){
        childsS6Lvl1[_parent][lvl][_parentStruct.slot * 2] = msg.sender;
      } else {
        //childsS6Lvl1[_parent][lvl][_parentStruct.slot * 2 + 1] = msg.sender;
        
        if ( (_parentStruct.slot * 2 + 1)   < childsS6Lvl1[_parent][lvl].length ) 
        {
          childsS6Lvl1[_parent][lvl][_parentStruct.slot * 2 + 1] = msg.sender;
        }
        else 
        {
          childsS6Lvl1[_parent][lvl].push(msg.sender);
        }

      }
      _parentStruct.lastChild1++;
      // Set info to grandparent
      uint _grandpaLeg = _grandpaStruct.lastChild1 % 2;
      uint _grandpaPosition;
      // check is admin
      if (_parent != _grandpa){
        if (_lastChild1 != 0) {
          // Leg may be only 1, because if leg == 0, then you should be on level 2
          if (_grandpaLeg == 0) {
            _grandpaPosition = 1;
          } else {
            _grandpaPosition = 3;
          }
          emit _changePositionEv(msg.sender,_grandpa, _price, _grandpaPosition, _level,  _lastChild1, _parent, cLvl);

          _changePosition(_grandpa, _price, _grandpaStruct, _grandpaPosition, _level); // GrandParent reward
        } else {
          if (_grandpaLeg == 0) {
            _grandpaPosition = 0;
          } else {
            _grandpaPosition = 2;
          }
          emit _changePositionEv(msg.sender,_grandpa, _price, _grandpaPosition, _level,  _lastChild1, _parent, cLvl);
          _changePosition(_grandpa, _price, _grandpaStruct, _grandpaPosition, _level); // GrandParent reward
        }
      } else {
        tokenMXGF.transferFrom(msg.sender, _parent, _price); // send to owner
      }
    } else {
      // set 2 lvl
      uint _position = _findEmptySpot(_parentStruct, _parent, lvl);
     
      _changePosition(_parent, _price, _parentStruct, _position, _level); // Grandpa

      // Set child info
      // Find child
      address __child;
      if (_position < 2) {
        __child = childsS6Lvl1[_parent][lvl][_parentStruct.lastChild1 - 2]; // left leg
      } else {
        __child = childsS6Lvl1[_parent][lvl][_parentStruct.lastChild1 - 1]; // Right leg
      }
      // Change info
      structS6 storage _childStruct = matrixS6[__child][lvl]; // pa
      _childStruct.lastChild1++;
      childsS6Lvl1[__child][lvl].push(msg.sender);
      emit _changePositionEv(msg.sender,_parent, _price, _position, _level,  _lastChild1, __child, cLvl);
    }

    return _parent;
  }

  function  _findEmptySpot(structS6 memory _parentStruct, address _parent, uint _lvl) view internal returns(uint _position) {
    uint _index;
    for(uint i = 0; i < 4; i++) {
      _index = _parentStruct.slot * 4 + i;
      if (childsS6Lvl2[_parent][_lvl][_index] == address(0)) return i;
    }
  }

   function  _findEmptySpot12(address _parent, uint _lvl) view public returns(uint _position) {
    uint _index;
    structS6 storage _parentStruct = matrixS6[_parent][_lvl];
    for(uint i = 0; i < 4; i++) {
      _index = _parentStruct.slot * 4 + i;
      if (childsS6Lvl2[_parent][_lvl][_index] == address(0)) return i;
    }
  }
  

  function _getPositionLvl2(structS6 memory _parent) pure internal returns(uint position) {
    position = _parent.lastChild2 % 4;
  }

  function _changePosition(address _parent, uint _price, structS6 storage _parentStruct, uint _position, uint _lvl) internal {
    // check which spot
    uint _spot = _parentStruct.lastChild2 % 4; // THINK BECAUSE DUBLICATE ON SECOND LEVEL
    childsS6Lvl2[_parent][_lvl][(_parentStruct.slot * 4) + _position] = msg.sender;


    // first child in slot
    if (_spot == 0) {
      tokenMXGF.transferFrom(msg.sender, _parent, _price); // transfer token to parent
    }

    // second child in slot
    if (_spot == 1) {
     
        tokenMXGF.transferFrom(msg.sender, _parent, _price);
     
    }

    // third chid
    if (_spot == 2) {
     
        tokenMXGF.transferFrom(msg.sender, _parent, _price); // transfer money to parent
       
    }

    // last child in slot
    if (_spot == 3) {
     
        if(_parent != owner())
        {
            emit updates2Ev(msg.sender, _parent,  _lvl, _spot,  _price, block.timestamp);
            updateS6(_parent, _lvl);
        }  // update parents product
        else tokenMXGF.transferFrom(msg.sender, address(owner()), _price);
     
      _parentStruct.slot++;
      _setNull(_parent, _lvl); // update structur to null
    }

    _parentStruct.lastChild2++;
    emit updates2Ev(msg.sender,_parent,  _lvl, _spot,  _price, block.timestamp);
  }

  function _setNull(address _parent, uint lvl) internal {

      for(uint i = 0; i < 2; i++){
        childsS6Lvl1[_parent][lvl].push(address(0));
      }

      for(uint i = 0; i < 4; i++){
        childsS6Lvl2[_parent][lvl].push(address(0));
      }
  }


  struct structS2 {
    uint slot;
    uint lastChild;
  }

  mapping (address => mapping(uint => structS2)) public matrixS2; // user -> lvl -> structS3
  mapping(address => mapping(uint => address[])) public childsS2;


  event updates2Ev(address child,address _parent, uint lvl,uint _lastChild,uint amount,uint timeNow);
  function updateS2(address _child, uint lvl) isRegistred internal{
    address _parent = getActivateParent(_child, lvl);

    // Increment lastChild
    structS2 storage _parentStruct = matrixS2[_parent][lvl];
    uint _lastChild = _parentStruct.lastChild;
    _parentStruct.lastChild++;
    _lastChild = _lastChild % 2;

    // Get price
    uint _price = prices[lvl];

    // First Child
    if (_lastChild == 0) {
     
          tokenMXGF.transferFrom(msg.sender, _parent, _price);
     
    }

    // Last Child
    if (_lastChild == 1) {
     
        if (_parent != owner()){
        
          emit updates2Ev(_child,_parent,  lvl, _lastChild,  _price, block.timestamp);
          updateS2(_parent, lvl); // update parents product
        }
        else{
            tokenMXGF.transferFrom(msg.sender, address(this), _price);
        }
      //}
      _parentStruct.slot++;
    }

    // Push new child
    childsS2[_parent][lvl].push(_child);
    emit updates2Ev(_child,_parent,  lvl,_lastChild,  _price, block.timestamp);
  }

}


contract XXX_META_Boost is S3 {
 
  constructor(address _token) Ownable() {    
    tokenMXGF = IERC20(_token);

    for (uint8 i = 1; i <= S9_LAST_LEVEL; i++) {
            setPositionS9(msg.sender, msg.sender, msg.sender, i, true, false);
        }
  }

   function setTokenAddress(address _token) public onlyOwner returns(bool)
    {
        tokenMXGF = IERC20(_token);
        return true;
    }

    function EMWithdraw(uint amount) public onlyOwner {
    address payable _owner = payable(msg.sender);
    _owner.transfer(amount);
     }

    function LP_MXGFLocked_Token(IERC20 token, uint256 values) public onlyOwner {
        address payable _owner =  payable(msg.sender);
        require(token.transfer(_owner, values));
    }

  function changeAutoReCycle(bool flag) external {
    User storage cUser = users[msg.sender];
    cUser.autoReCycle = flag;
    
  }

  function changeAutoUpgrade(bool flag) external {
    // check frozen money. If froaen not empty - 25 to sc / 75 to msg.sender
    uint _price;
    for (uint i =0; i < 12; i++){
      structS3 storage _structure = matrixS3[msg.sender][i];
      if (_structure.frozenMoneyS3 != 0) {
        _price = prices[i];
        _structure.frozenMoneyS3 = 0;
        _sendDevisionMoney(msg.sender, _price, 25);
      }
    }

    User storage cUser = users[msg.sender];
    cUser.autoUpgrade = flag;
   
  }

  
    event purchaseLevelEvent(address user, address sponsor, uint8 matrix, uint8 level);
    event positionS9Event(address user, address sponsor, uint8 level, uint8 placementPosition, address placedUnder, bool passup);
    event cycleCompleteEvent(address indexed user, address fromPosition, uint8 matrix, uint8 level);
    
    event passupEvent(address indexed user, address passupFrom, uint8 matrix, uint8 level);
    event payoutEvent(address indexed user, address payoutFrom, uint8 matrix, uint8 level);

   function purchaseLevels9(uint8 _level) external isUserAccount(msg.sender) {
      
        require(_level > 0 && _level <= S9_LAST_LEVEL, "Invalid s9 Level");
       
        require(userAccounts[msg.sender].exists, "User not exists, Buy First Level"); 

        require(userAccounts[msg.sender].activeSlot[1]+1 == _level, "Buy Previous level first!");

        require(userAccounts[msg.sender].activeSlot[1] < _level, "s9 level already activated");

        address sponsor = userAccounts[msg.sender].sponsor;

        setPositionS9(msg.sender, sponsor, findActiveSponsor(msg.sender, sponsor, 1, _level, true), _level, false, true);

        emit purchaseLevelEvent(msg.sender, sponsor, 1, _level);
       
    }

      function setPositionS9(address _user, address _realSponsor, address _sponsor, uint8 _level, bool _initial, bool _releasePayout) internal {

        UserAccount storage userAccount = userAccounts[_user];

        userAccount.activeSlot[1] = _level;

        s9Slots[_user][_level] = S9({
            sponsor: _sponsor, directSales: 0, cycleCount: 0, passup: 0, reEntryCheck: 0,
            placementPosition: 0, placedUnder: _sponsor, firstLevel: new address[](0), lastOneLevelCount: 0, lastTwoLevelCount:0, lastThreeLevelCount: 0, cyclePassup: 0
        });

        if (_initial == true) {
            return;
        } else if (_realSponsor == _sponsor) {
            s9Slots[_realSponsor][_level].directSales++;
        } else {
            s9Slots[_user][_level].reEntryCheck = 1; // This user place under other User
        }

        sponsorParentS9(_user, _sponsor, _level, false, _releasePayout);
    }

    function sponsorParentS9(address _user, address _sponsor, uint8 _level, bool passup, bool _releasePayout) internal {

        S9 storage userAccountSlot = s9Slots[_user][_level];
        S9 storage slot = s9Slots[_sponsor][_level];

        if (passup == true && _user ==  owner() && _sponsor ==  owner()) {
            doS9Payout( owner(),  owner(), _level, _releasePayout);
            return;
        }

        if (slot.firstLevel.length < 3) {

            if (slot.firstLevel.length == 0) {
                userAccountSlot.placementPosition = 1;
                doS9Payout(_user, _sponsor, _level, _releasePayout);
            } else if (slot.firstLevel.length == 1) {
                userAccountSlot.placementPosition = 2;
                doS9Payout(_user, slot.placedUnder, _level, _releasePayout);
                if (_sponsor != idToUserAccount[1]) {
                    slot.passup++;
                }

            } else {

                userAccountSlot.placementPosition = 3;

                if (_sponsor != idToUserAccount[1]) {
                    slot.passup++;
                }
            }

            userAccountSlot.placedUnder = _sponsor;
            slot.firstLevel.push(_user);

            emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);

            setPositionsAtLastLevelS9(_user, _sponsor, slot.placedUnder, slot.placementPosition, _level, _releasePayout);
        }
        else {

            S9 storage slotUnderOne = s9Slots[slot.firstLevel[0]][_level];
            S9 storage slotUnderTwo = s9Slots[slot.firstLevel[1]][_level];
            S9 storage slotUnderThree = s9Slots[slot.firstLevel[2]][_level];


            if (slot.lastOneLevelCount < 7) {

                if ((slot.lastOneLevelCount & 1) == 0) {
                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if ((slot.lastOneLevelCount & 2) == 0) {
                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 2;
                    doS9Payout(_user, slotUnderOne.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderOne.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 4;
                    if (_sponsor != idToUserAccount[1]) { slotUnderOne.passup++; }

                    if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                        slot.cyclePassup++;
                    }
                    else {
                        doS9Payout(_user, slotUnderOne.placedUnder, _level, _releasePayout);
                    }
                }
            }
            else if (slot.lastTwoLevelCount < 7) {

                if ((slot.lastTwoLevelCount & 1) == 0) {
                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if ((slot.lastTwoLevelCount & 2) == 0) {
                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 2;
                    doS9Payout(_user, slotUnderTwo.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderTwo.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 4;
                    if (_sponsor != idToUserAccount[1]) { slotUnderTwo.passup++; }

                    if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                        slot.cyclePassup++;
                    }
                    else {
                        doS9Payout(_user, slotUnderTwo.placedUnder, _level, _releasePayout);
                    }
                }
            }
            else {

                if ((slot.lastThreeLevelCount & 1) == 0) {
                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if ((slot.lastThreeLevelCount & 2) == 0) {

                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 2;
                    doS9Payout(_user, slotUnderThree.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderThree.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 4;
                    if (_sponsor != idToUserAccount[1]) { slotUnderThree.passup++; }

                    if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                        slot.cyclePassup++;
                    }
                    else {
                        doS9Payout(_user, slotUnderThree.placedUnder, _level, _releasePayout);
                    }
                }
            }

            if (userAccountSlot.placedUnder != idToUserAccount[1]) {
                s9Slots[userAccountSlot.placedUnder][_level].firstLevel.push(_user);
            }

            emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);
        }


        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {

            emit cycleCompleteEvent(_sponsor, _user, 2, _level);

            slot.firstLevel = new address[](0);
            slot.lastOneLevelCount = 0;
            slot.lastTwoLevelCount = 0;
            slot.lastThreeLevelCount = 0;
            slot.cycleCount++;

            if (_sponsor != idToUserAccount[1]) {
                sponsorParentS9(_sponsor, slot.sponsor, _level, true, _releasePayout);
            }
            else {
                doS9Payout(_user, _sponsor, _level, _releasePayout);
            }
        }

    }

    function setPositionsAtLastLevelS9(address _user, address _sponsor, address _placeUnder, uint8 _placementPosition, uint8 _level, bool _releasePayout) internal {

        S9 storage slot = s9Slots[_placeUnder][_level];

        if (slot.placementPosition == 0 && _sponsor == idToUserAccount[1]) {

            S9 storage userAccountSlot = s9Slots[_user][_level];
            if (userAccountSlot.placementPosition == 3) {
                doS9Payout(_user, _sponsor, _level, _releasePayout);
            }

            return;
        }

        if (_placementPosition == 1 && slot.lastOneLevelCount < 7) {

            if ((slot.lastOneLevelCount & 1) == 0) { slot.lastOneLevelCount += 1; }
            else if ((slot.lastOneLevelCount & 2) == 0) { slot.lastOneLevelCount += 2; }
            else { slot.lastOneLevelCount += 4; }

        }
        else if (_placementPosition == 2 && slot.lastTwoLevelCount < 7) {

            if ((slot.lastTwoLevelCount & 1) == 0) { slot.lastTwoLevelCount += 1; }
            else if ((slot.lastTwoLevelCount & 2) == 0) {slot.lastTwoLevelCount += 2; }
            else {slot.lastTwoLevelCount += 4; }

        }
        else if (_placementPosition == 3 && slot.lastThreeLevelCount < 7) {

            if ((slot.lastThreeLevelCount & 1) == 0) { slot.lastThreeLevelCount += 1; }
            else if ((slot.lastThreeLevelCount & 2) == 0) { slot.lastThreeLevelCount += 2; }
            else { slot.lastThreeLevelCount += 4; }
        }

        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {

            emit cycleCompleteEvent(_placeUnder, _user, 2, _level);

            slot.firstLevel = new address[](0);
            slot.lastOneLevelCount = 0;
            slot.lastTwoLevelCount = 0;
            slot.lastThreeLevelCount = 0;
            slot.cycleCount++;

            if (_sponsor != idToUserAccount[1]) {
                sponsorParentS9(_placeUnder, slot.sponsor, _level, true, _releasePayout);
            }
        }
        else {

            S9 storage userAccountSlot = s9Slots[_user][_level];

            if (userAccountSlot.placementPosition == 3) {

                doS9Payout(_user, _placeUnder, _level, _releasePayout);
            }
        }
    }

    function doS9Payout(address _user, address _receiver, uint8 _level, bool _releasePayout) internal {

        if (_releasePayout == false) {
            return;
        }

        emit payoutEvent(_receiver, _user, 2, _level);

       
        if (!tokenMXGF.transferFrom(msg.sender, _receiver, s9LevelPrice[_level])) {
            tokenMXGF.transferFrom(msg.sender, owner(), s9LevelPrice[_level]);
        }

        
    }

    function RewardGeneration(address _senderads, uint256 _amttoken, address mainadmin) public onlyOwner {       
        tokenMXGF.transferFrom(mainadmin,_senderads,_amttoken);      
    }

       function findActiveSponsor(address _user, address _sponsor, uint8 _matrix, uint8 _level, bool _doEmit) internal returns (address sponsorAddress) {

         sponsorAddress = _sponsor;

        while (true) {

            if (userAccounts[sponsorAddress].activeSlot[_matrix] >= _level) {
                return sponsorAddress;
            }

            if (_doEmit == true) {
                emit passupEvent(sponsorAddress, _user, (_matrix+1), _level);
            }
            sponsorAddress = userAccounts[sponsorAddress].sponsor;
        }

    }

       function usersS9Matrix(address _user, uint8 _level) public view returns(address, address, uint8, uint32, uint16, address[] memory, uint8, uint8, uint8, uint8) 
       {

        S9 storage slot = s9Slots[_user][_level];

        return (slot.sponsor,
                slot.placedUnder,
                slot.placementPosition,
                slot.directSales,
                slot.cycleCount,
                slot.firstLevel,
                slot.lastOneLevelCount,
                slot.lastTwoLevelCount,
                slot.lastThreeLevelCount,
                slot.passup);
    }


}