/**
 *Submitted for verification at Etherscan.io on 2022-06-19
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
     mapping(address => bool) private admins;
     mapping(address => uint256) private _admin_id;
     address[] private _admins;
 
     address private _owner;
     address private systemAddress = 0x329D526679141ad44E5171a3C975a409865688e6;
     bool private platformStatus;  // platform pause status
     bool private bettingStatus;  // wagering pause status
     bool private marketCreationStatus;  // market creation pause status
     bool private pointEarningStatus;   // validation point earning pause status
 
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
     function isPlatformActive() public view {
         if(platformStatus != true){
             revert("PP");
         }
     }
 
     // check if betting is paused
     function isBettingPaused() public view{
         if(bettingStatus != true){
             revert("PBP");
         }
     }
 
     // check if event/market creation is paused
     function isMarketCreationPaused() public view{
         if(marketCreationStatus != true){
             revert("PMCP");
         }
     }
 
     // check if validation point earning is paused
     function isPointEarningPaused() public view{
         if(pointEarningStatus != true){
             revert("PPEP");
         }
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
         if (poolSize >= 5000000000000000000000) {
             return 10;
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
     
 }