// SPDX-License-Identifier: MIT


import "./Utility.sol";


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/beeBNB.sol


pragma solidity >=0.4.22 <0.9.0;




/**
@title beeBNB
@author Core Devs Ltd
@notice An Custom smart contract
*/

contract BeeBNB is Ownable{

  using removeElementFromArray for address[];

  address[] clones; //clones list
  address[] pool1; //globalpool leve1 eligible users
  address[] pool2; //globalpool leve2 eligible users
  address[] pool3; //globalpool leve3 eligible users
  uint public globalPoolSize; //global pool
  address payable systemWallet; //system fee wallet
  address payable marketingWallet; //marketing fee pool
  address payable adminWallet; //admin pool
  uint public deploymentTime; //time of deployment


  /**   
  @notice User detail
  */
  struct User{
    uint currentTable; //current table
    uint lastTable; //last joined table
    address referredBy;
    address[]myTable; //users sitting on this users table
    uint referralsInPool;
    bool isRegistered; //is registered
  }

  /**  
  @notice Can bee called to return users profile.
  @custom:function Takes Address /user address as input.
  @custom:example Users(address).
  */
  mapping(address => User) public users;




  /**   
  @notice Table detail.
  */
  struct Table{
    uint fee;
    address[] places;
  }

  
  /**  
  @notice Can be called to return table data.
  @custom:statefunction Takes uint /tableid as input.
  @custom:example Tables(uint).
  */
  mapping(uint => Table) public tables;// Table id: 1,2,3,4,5



  /**
  @param _fee1 Fee for table1.
  @param _fee2 Fee for table2.
  @param _fee3 Fee for table3.
  @param _fee4 Fee for table4.
  @param _fee5 Fee for table5.
  @param _marketingWallet Wallet address for marketting fee
  @param _systemWallet Wallet address for system fee
  */
  constructor(uint _fee1,uint _fee2, uint _fee3, uint _fee4, uint _fee5, address payable _adminWallet, address payable _marketingWallet, address payable _systemWallet){
    tables[1].fee = _fee1;
    tables[2].fee = _fee2;
    tables[3].fee = _fee3;
    tables[4].fee = _fee4;
    tables[5].fee = _fee5;
    deploymentTime = block.timestamp;
    //Setting up Ref commission percetages
    refComissionPercentage[1]=10;
    refComissionPercentage[2]=7;
    refComissionPercentage[3]=3;
    refComissionPercentage[4]=3;
    refComissionPercentage[5]=2;
    globalPoolSize=0;
    marketingWallet= _marketingWallet; 
    systemWallet = _systemWallet;
    adminWallet = _adminWallet;
  }


  /**  
  @notice Can bee called to return referral commision percentage for each level.
  @custom:statefunction Takes uint /level as input.
  @custom:example rRefComissionPercentage(uint).
  */
  mapping(uint => uint) public refComissionPercentage;

  /**   
  @notice Events.
  */

  /**   
  @notice Emitted for incoming transactions.
  @dev Passes wallet address, amount and type: ref/income/pool.
  */
  event In(address wallet,uint amount,string txType);
  /**   
  @notice Emitted for outgoing transactions.
  @dev Passes wallet address, amount amount tableid.
  */
  event Out(address wallet,uint amount,uint tableId);
  /**   
  @notice Emitted on new member registration.
  @dev Passes wallet address of user, referred by.
  */
  event NewMember(address member, address ref);

  /**   
  @notice Emitted when table gets completed.
  @dev Passes wallet address of user.
  */
  event CompleteTable(address member);


  /**  
  @notice Function to read user list on table.
  @param _tableId Table id: 1,2,3,4,5.
  */
  function showPlacesfromTable(uint _tableId) public view returns (address[] memory array) {
    return tables[_tableId].places;
  }

  /**  
  @notice Function to read users virtual table on table/
  @param _user User addres.
  */
  function showUsersTable(address _user) public view returns (address[] memory array) {
    return users[_user].myTable;
  }

  /**  
  @notice Function to read list of clones.
  */
  function showClones() public view returns (address[] memory) {
    return clones;
  }

  /**  
  @notice Function to read wallets in pool.
  @param _poolLevel Pool level: 1,2,3.
  */
  function showPools(uint _poolLevel) public view returns (address[] memory array) {
    if(_poolLevel==1){
      return pool1;
    }else if(_poolLevel==2){
      return pool2;
    } else if(_poolLevel==3){
      return pool3;
    }
  }

  /**  
  @notice Function to read wallets counts in pool.
  @param _poolLevel Pool level: 1,2,3.
  */
  function poolLength(uint _poolLevel) public view returns (uint _poolLength) {
    if(_poolLevel==1){
      return pool1.length;
    }else if(_poolLevel==2){
      return pool2.length;
    } else if(_poolLevel==3){
      return pool3.length;
    }
  }

  /**  
  @notice Function to register the user.
  @param _reference Referral address.
  @custom:events This emits "NewMember" event.
  */
  function register(address _reference) public {
    require(users[msg.sender].isRegistered==false,"You are already a registered user");
    require(_reference!=msg.sender,"You can not refer yourself");
    users[msg.sender].referredBy=_reference;
    users[msg.sender].isRegistered=true;
    users[msg.sender].referralsInPool=0;
    if(_reference!=0x0000000000000000000000000000000000000000){
      users[msg.sender].referredBy=_reference;
      users[_reference].referralsInPool++;
      if(users[_reference].referralsInPool==2){
        pool1.push(_reference);
      }else if(users[_reference].referralsInPool==4){
        pool2.push(_reference);
      } else if(users[_reference].referralsInPool==6){
        pool3.push(_reference);
      }
    }
    emit NewMember(msg.sender, _reference);
  }

  /**  
  @notice Function to register the user.
  @param _user wallet address of user.
  @custom:events This emits "NewMember" event.
  */
  function registerUserAsOwner(address _user) public onlyOwner(){
    require(users[_user].isRegistered==false,"User is already registered");
    address _reference = msg.sender;
    users[_user].referredBy=_reference;
    users[_user].isRegistered=true;
    users[_user].referralsInPool=0;
    if(_reference!=0x0000000000000000000000000000000000000000){
      users[_user].referredBy=_reference;
      users[_reference].referralsInPool++;
      if(users[_reference].referralsInPool==2){
        pool1.push(_reference);
      }else if(users[_reference].referralsInPool==4){
        pool2.push(_reference);
      } else if(users[_reference].referralsInPool==6){
        pool3.push(_reference);
      }
    }
    emit NewMember(_user, _reference);
  }

  /**  
  @notice Function to join in a table.
  @param _tableId Table id:1,2,3,4,5.
  @custom:events This emits "Out" event.
  @custom:events This emits "In"/"CompleteTable" events from relations.
  */
  function joinTable(uint _tableId) public payable{
    require(users[msg.sender].isRegistered==true, "You need to register first.");
    require(msg.value==tables[_tableId].fee,"Wrong amount as value");
    require(_tableId>=1 && _tableId<=5,"Invalid table id");
    require(users[msg.sender].currentTable==0,"You are still active a table");
    if (users[msg.sender].lastTable==4){
      require(_tableId==1 || _tableId==5,"You can not join any table except 1 and 5");
    } else if((_tableId>1 && _tableId <5 && users[msg.sender].lastTable!=5)){
      require((users[msg.sender].lastTable+1==_tableId || users[msg.sender].lastTable-1==_tableId||users[msg.sender].lastTable==_tableId),"You can not access this table");
    }

    uint fee = tables[_tableId].fee;
    Table memory currentTable = tables[_tableId];
    address referredBy = users[msg.sender].referredBy;


    if(currentTable.places.length>0){
      address master = currentTable.places[0];
      if (referredBy!=0x0000000000000000000000000000000000000000 &&
          _tableId == users[referredBy].currentTable) {
      
        manageTable(referredBy, _tableId,fee);
 
      } else {
        manageTable(master, _tableId,fee);
      }
    }else{
      payOwner(fee/100*60);
      tables[_tableId].places.push(msg.sender);
      users[msg.sender].currentTable=_tableId;
    }
    if(_tableId==1 && tables[1].places.length>0){
      useClones();
    }
    managePools(fee);
    payRef(msg.sender,fee);
    emit Out(msg.sender,msg.value,_tableId);

  }

  /**  
  @notice Function to manage pools. Called by joinTable().
  @param _amount Fee amount collected.
  */
  function managePools(uint _amount) internal {
    globalPoolSize+=(_amount/100*5);
    systemWallet.transfer(_amount/100*5);
    marketingWallet.transfer(_amount/100*5);
  }
  

  /**  
  @notice Function to pay referrals in all levels.
  @param _user Users/senders Id.
  @param _fee Table fee.
  @custom:events This emits "In" events with "ref" txType.
  */
  function payRef(address _user,uint _fee)internal {
    
    address payable referredBy = payable (users[_user].referredBy);
    for (uint256 index = 1; index <= 5; index++) {
      uint amount = _fee/100*refComissionPercentage[index];
      if (referredBy!=0x0000000000000000000000000000000000000000) {
        referredBy.transfer(amount);
        emit In(referredBy,amount,"ref");
        referredBy = payable (users[referredBy].referredBy);
      } else {
        payOwner(amount);

      }
    }
  }

    /**  
  @notice Function to pay referrals in all levels.
  @param _user Users/senders Id.
  @param _fee Table fee.
  @custom:events This emits "In" events with "ref" txType.
  */
  function payCloneRef(address _user,uint _fee)internal {
    
    address payable referredBy = payable (_user);
    for (uint256 index = 1; index <= 5; index++) {
      uint amount = _fee/100*refComissionPercentage[index];
      if (referredBy!=0x0000000000000000000000000000000000000000) {
        referredBy.transfer(amount);
        emit In(referredBy,amount,"ref");
        referredBy = payable (users[referredBy].referredBy);
      } else {
        payOwner(amount);

      }
    }
  }

  /**  
  @notice Function for managin table. called by joinTable()
  @param _master Address for main master of tx table
  @param _tableId Table Id
  @param _fee Table fee
  @custom:events This emits "In" events with "income" txType from relations.
  @dev Tis funtion directs and highly depends on manageTablePlaces()
  */
  function manageTable(address _master,uint _tableId,uint _fee) internal {
    _fee = _fee/100*60;
    // if(users[_master].myTable.length==0 && (_tableId==1 || _tableId==2)){
    if(users[_master].myTable.length==0 && (_tableId==1)){ 
      manageTablePlaces(_master, _tableId);
      payOwner(_fee);
    } else if(users[_master].myTable.length==0){
      manageTablePlaces(_master, _tableId);
      createClones(_fee);
    }else{
      manageTablePlaces(_master, _tableId);
      payable (_master).transfer(_fee);
      emit In(_master,_fee,"income");

    }
    
  }  

  /**  
  @notice Function for managin table. Called by manageTable().
  @param _master Address for main master of tx table
  @param _tableId Table Id
  @custom:events tThis emits "In" events with "income" txType.
  */
  function manageTablePlaces(address _master,uint _tableId) internal {
    if(users[_master].myTable.length==3){
      users[_master].currentTable=0;
      users[_master].lastTable=_tableId;
      delete users[_master].myTable;
      tables[_tableId].places.removeElement(_master);
      emit CompleteTable(_master);
    }else {
      users[_master].myTable.push(msg.sender);
    }
    tables[_tableId].places.push(msg.sender);
    users[msg.sender].currentTable=_tableId;

    
  }

  /**  
  @notice Function for creating clones. Called by manageTable().
  @param _amount Aamount allocated to create clones
  @dev This funtion directs to useClones()
  */
  function createClones(uint _amount) internal {
    uint perUnit= tables[1].fee;
    uint numOfClones  = _amount / perUnit;
    uint remainder = _amount - perUnit * numOfClones;
    if(remainder>0){
      payOwner(remainder);
    }
    for (uint256 index = 0; index < numOfClones; index++) {
      clones.push(msg.sender);
    }
    useClones();
    
  }

  /**  
  @notice Function for using clones. Called by joinTable() and createClones().
  @custom:events This emits "In" events with "income"/"ref" txType.
  */
  function useClones() internal {
    if(tables[1].places.length>0){
      uint perUnit= tables[1].fee;
      uint masterFeeAmount = perUnit/100*60;
      while(clones.length>0){
        if(tables[1].places.length==0){
          break;
        }
        uint num= 4-users[tables[1].places[0]].myTable.length;
        if(num<=clones.length){
          address user = tables[1].places[0];
          for (uint256 index = 0; index < num; index++) {
            if(index==3){
              payOwner(masterFeeAmount);
            }else{
              payable (user).transfer(masterFeeAmount);
              emit In(user, masterFeeAmount, "income");
            }
            address ref = clones[0];
            clones.shift();
            managePools(perUnit);
            payCloneRef(ref,perUnit);

          }
          users[user].currentTable=0;
          users[user].lastTable=1;
          delete users[user].myTable;
          tables[1].places.shift();
          
          emit CompleteTable(user);

        }else{
          break;
        }
      }
      }
  }

  /**  
  @notice Function to declare pool reward.
  @dev Can only be called by owner.
  @custom:events This emits "In" events with "income"/"ref" txType.
  */
function declarePoolReward() public payable onlyOwner(){
  if (pool1.length>0) {
    uint pool1Amount = (globalPoolSize/100*20)/pool1.length;
    for (uint256 index = 0; index < pool1.length; index++) {
      payable(pool1[index]).transfer(pool1Amount);
      emit In(pool1[index], pool1Amount, 'pool');
    }
  } else {
    uint pool1Amount = (globalPoolSize/100*20);
    payOwner(pool1Amount);
  }
  if (pool2.length>0) {
    uint pool2Amount = (globalPoolSize/100*30)/pool2.length;
    for (uint256 index = 0; index < pool2.length; index++) {
      payable(pool2[index]).transfer(pool2Amount);
      emit In(pool2[index], pool2Amount, 'pool');
    }
  } else {
    uint pool2Amount = (globalPoolSize/100*30);
    payOwner(pool2Amount);
  }
  if (pool3.length>0) {
    uint pool3Amount = (globalPoolSize/100*50)/pool3.length;
    for (uint256 index = 0; index < pool3.length; index++) {
      payable(pool3[index]).transfer(pool3Amount);
      emit In(pool3[index], pool3Amount, 'pool');

    }
  } else {
    uint pool3Amount = (globalPoolSize/100*50);
    payOwner(pool3Amount);
  }



  globalPoolSize = 0;
  delete pool1;
  delete pool2;
  delete pool3;

}
  /**  
  @notice Function to pay owner wallet.
  @param _fee Aamount to pay.
  */
  function payOwner(uint _fee) internal{
    adminWallet.transfer(_fee);

  }

  /**  
  @notice Function used to withdraw funds from smart contract.
  @dev Can only be called by owner.
  @param _amount Amount to withdraw.
  */
  function withdraw(uint _amount) public onlyOwner(){
    payable(msg.sender).transfer(_amount);
  }

  
  

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library removeElementFromArray {
    function removeElement(address[] storage _array, address _element) public {
        uint index = 0;
        unchecked{
            for (uint256 i; i<_array.length; i++) {
                if (_array[i] == _element) {
                    index = i;
                    break;
                }
            }
            for (uint i = index; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
            }
            _array.pop();
        }
    }
    function removeByIndex(address[] storage _array, uint _index) public{
        for (uint i = _index; i < _array.length - 1; i++) {
          _array[i] = _array[i + 1];
        }
        _array.pop();
    }
    function shift(address[] storage _array) public{
        unchecked {
            for (uint i = 0; i < _array.length - 1; i++) {
            _array[i] = _array[i + 1];
            }
            _array.pop();
        }
        
    }
}