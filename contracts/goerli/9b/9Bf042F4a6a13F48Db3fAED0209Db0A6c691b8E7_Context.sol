/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-21
*/

// SPDX-License-Identifier: GPL-3.0

/**
 * @Author Vron
 */

 pragma solidity >=0.7.0 <0.9.0;

 contract Context {
     // mapping for username
     mapping(address=>string) private _username;
     mapping(address=>bool) private _username_set;
     mapping(address => bool) private admins;
     mapping(address => uint256) private _admin_id;
     mapping(address=>mapping(uint256=>uint256)) private user_bonus;
     address[] private _admins;
 
     address private _owner;
     address private systemAddress = 0x329D526679141ad44E5171a3C975a409865688e6;  // address should be company address
     address private VCContractAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  // address should be VC contract address
     address private VCAddr;
     bool private platformStatus;  // platform pause status
     bool private bettingStatus;  // wagering pause status
     bool private marketCreationStatus;  // market creation pause status
     bool private pointEarningStatus;   // validation point earning pause status
     bool private eventValidationStatus;
     address private platform_address;
 
     event AddAdmin(address indexed _address, bool decision);
     event RemoveAdmin(address indexed _address, bool decision);
     event TransferOwnerShip(address indexed _oldOwner, address indexed _newOwner);
 
     // calls the _onlyOwner function
     function onlyOwner(address _address) external view{
         _onlyOwner(_address);
     }
 
     // restricts access to only owner
     function _onlyOwner(address _address) internal view {
         if(_address != _owner){
             revert("OOA");
         }
     }
 
     // calls _onlyAdmin function
     function onlyAdmin(address _address) external view{
         _onlyAdmin(_address);
     }
 
     // restricts access to only admins
     function _onlyAdmin(address _address) internal view{
         if(admins[_address] != true){
             revert("OAA");
         }
     }
 
     // check if platform is paused
     function isPlatformActive(address _address) public view {
         if(platformStatus != true && admins[_address] != true){
             revert("PP");
         }
     }
 
     // check if betting is paused
     function isBettingPaused(address _address) public view{
         if(bettingStatus != true && admins[_address] != true){
             revert("PBP");
         }
     }
 
     // check if event/market creation is paused
     function isMarketCreationPaused(address _address) public view{
         if(marketCreationStatus != true && admins[_address] != true){
             revert("PMCP");
         }
     }
 
     // check if validation point earning is paused
     function isPointEarningPaused(address _address) public view{
         if(pointEarningStatus != true && admins[_address] != true){
             revert("PPEP");
         }
     }

    // check if event validation is allowed
    function isEventValidationPaused(address _address) public view {
        if(eventValidationStatus != true && admins[_address] != true){
            revert("EVP");
        }
    }

    //  check if username is set
    function isUsernameSet(address addr) public view {
        if(_username_set[addr] == false){
            revert("UNS");
        }
    }

    // function sets user bonus on an event
    function setUserBonusOnEvent(address user_address, uint256 event_id, uint256 amount) public {
        require(platform_address == msg.sender, "OPCA");
        user_bonus[user_address][event_id] = amount;
    }

    // function gets user bonus on an event
    function getUserBonusOnEvent(address user_address, uint256 event_id) public view returns (uint256){
        return user_bonus[user_address][event_id];
    }

 
     constructor() {
         _owner = msg.sender;
         admins[msg.sender] = true;
         _admins.push(msg.sender);
         platformStatus = true;
         bettingStatus = true;
         marketCreationStatus = true;
         pointEarningStatus = true;
         emit AddAdmin(msg.sender, true);
     }
 
     // function returns contract owner
     function getOwner() public view returns (address) {
         return _owner;
     }
     
     // function transfers ownership
     function transferOwnership(address _newOwner) external {
         _onlyOwner(msg.sender);
         _owner = _newOwner;
         emit TransferOwnerShip(msg.sender, _newOwner);
     }
 
     function addAdmin(address _address) public {
         _addAdmin(_address, true);
     }
 
     // sets an admin
     function _addAdmin(address _address, bool _decision)
         private
         returns (bool)
     {
         _onlyOwner(msg.sender);
         require(_address != _owner, "OAA.");
         require(admins[_address] == false, "UAA");
         admins[_address] = _decision;
         _admins.push(_address);
         _admin_id[_address] = _admins.length - 1;
         emit AddAdmin(_address, _decision);
         return true;
     }
 
     function removeAdmin(address _address) public {
         _removeAdmin(_address, false);
     }
 
     // removes an admin
     function _removeAdmin(address _address, bool _decision)
         private
         returns (bool)
     {
         _onlyOwner(msg.sender);
         require(_address != _owner, "OCBR");
         require(admins[_address] == true, "USAA");
         admins[_address] = _decision;
         _admins[_admin_id[_address]] = _admins[_admins.length - 1];
         _admins.pop();
         emit RemoveAdmin(_address, _decision);
         return true;
     }
     
     /**
      * @dev function returns [true] if user is an admin
      * and returns [false] otherwise
     */
     function isAdmin(address _address) 
     external view returns (bool) {
         if(admins[_address]){
             return true;
         }
         return false;
     }
 
     function _calculateValidatorsNeeded(uint256 poolSize) external pure returns (uint256) {
         return calculateValidatorsNeeded(poolSize);
     }
 
     function calculateValidatorsNeeded(uint256 poolSize) internal pure returns (uint256) {
         // check if validators required exceeds max 50
         if (poolSize >= 9000000000000000000000) {
             return 5;
         }
         return 3;
     }
 
     /**
      * @dev function displays lists of admins
      */
     function adminList() external view returns (address[] memory) {
         return _admins;
     }
 
     /**
     * @dev function changes the system reward where rewards are sent.
     */
     function changeVCContractAddress(address _address) external  {
         _onlyOwner(msg.sender);
         VCContractAddress = _address;
     }
 
     /**
     * @dev function returns the system reward address
     */
     function getVCContractAddress() external view returns (address){
         return VCContractAddress; 
     }

      /**
     * @dev function changes the system reward where rewards are sent.
     */
     function changeSystemRewardAddress(address _address) external  {
         _onlyOwner(msg.sender);
         systemAddress = _address;
     }
 
     /**
     * @dev function returns the system reward address
     */
     function getSystemRewardAddress() external view returns (address){
         return systemAddress; 
     }
 
     /**
      * @dev function is used to pause all major platform activities
      */
     function pausePlatform(bool _status) external {
         _onlyOwner(msg.sender);
         platformStatus = _status;
     }
 
     /**
      * @dev function changes the status of betting on platform
     */
    function changeBettingStatus(bool _status) external {
        _onlyOwner(msg.sender);
        bettingStatus = _status;
    }
 
     // function returns betting status
    function getBettingStatus() external view returns (bool){
        return bettingStatus;
    }
 
     /**
      * @dev function changes the status of market creation on platform
     */
    function changeMarketCreationStatus(bool _status) external {
        _onlyOwner(msg.sender);
        marketCreationStatus = _status;
    }
 
    // function returns market creation status
    function getMarketCreationStatus() external view returns (bool){
         return marketCreationStatus;
    }
 
     /**
      * @dev function changes the status of point earning on platform
     */
    function changePointEarningStatus(bool _status) external {
         _onlyOwner(msg.sender);
         pointEarningStatus = _status;
    }
 
    // functions returns point earning status on platform
    function getPointEarningStatus() external view returns (bool){
         return pointEarningStatus;
    }

    /**
     * @dev function changes event validation status
    */
    function changeEventValidationStatus(bool _status) external {
        _onlyOwner(msg.sender);
        eventValidationStatus = _status;
    }

    function getEventValidationStatus() external view returns (bool){
        return eventValidationStatus;
    }

    /**
     *dev function sets a username for an address
    */
    function setUsername(string memory username) external
    {
        require(_username_set[msg.sender] == false, "US");
        _username[msg.sender] = username;
        _username_set[msg.sender] = true;
    }  

    /**
     *dev function gets the username of an address
    */
    function getUsername(address addr) external view returns (string memory){
        return _username[addr];
    }

    /**
     *@dev function sets the address of the SafuBet betting platform
    */
    function setPlatformAddress(address _address) 
        external 
        returns (bool)
    {
        _onlyOwner(msg.sender);
        platform_address = _address;
        return true;
    }

    // function gets the address of SafuBet betting platform
    function getPlatformAddress() external view returns (address){
        return platform_address;
    }
     
 }