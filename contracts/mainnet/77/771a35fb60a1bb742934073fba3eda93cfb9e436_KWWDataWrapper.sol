/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
// File: contracts/KWWUtils.sol

pragma solidity >=0.7.0 <0.9.0;

library KWWUtils{

  uint constant DAY_IN_SECONDS = 86400;
  uint constant HOUR_IN_SECONDS = 3600;
  uint constant WEEK_IN_SECONDS = DAY_IN_SECONDS * 7;

  function pack(uint32 a, uint32 b) external pure returns(uint64) {
        return (uint64(a) << 32) | uint64(b);
  }

  function unpack(uint64 c) external pure returns(uint32 a, uint32 b) {
        a = uint32(c >> 32);
        b = uint32(c);
  }

  function random(uint256 seed) external view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.difficulty,
        block.timestamp,
        seed
    )));
  }


  function getWeekday(uint256 timestamp) public pure returns (uint8) {
      //https://github.com/pipermerriam/ethereum-datetime
      return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }
}
// File: contracts/IKWWData.sol


pragma solidity ^0.8.4;

interface IKWWData { 
    struct KangarooDetails{
        //Timestamp of the date the kangaroo is born
        uint64 birthTime;
        //Dad token id 
        uint32 dadId;
        //Mom token id
        uint32 momId;
        //Couple token id 
        uint32 coupleId;
        //If the kangaroo is on boat, the boatId will be set here
        uint16 boatId;
        //If the kangaroo moved to another land, the new landId will be set here
	    uint16 landId;
        //The generation of the kangaroo (genesis - gen0) NOT CHANGING
		uint8 gen;
        //Status of the kangaroo in the game
        // 0 - Australian
        // 1 - Sailing
        // 2 - Kangaroo Island
        // 3 - Pregnant
		uint8 status;
        //Type of the kangaroo (Pirate, Native, etc.)
        uint8 bornState;
    }

    struct CoupleDetails{
        //Timestamp when the pregnancy started
        uint64 pregnancyStarted;
        uint8 babiesCounter;
        //false - wild world, true - hospital
        bool paidHospital;
        bool activePregnant;
    }

    function initKangaroo(uint32 tokenId, uint32 dadId, uint32 momId) external;
    function setCouple(uint32 male, uint32 female) external ;
    function kangarooMoveLand(uint32 tokenId, uint16 landId) external ;
    function kangarooTookBoat(uint32 tokenId, uint16 boatId) external ;
    function kangarooReachedIsland(uint32 tokenId) external ;
    function kangarooStartPregnancy(uint32 dadId, uint32 momId, bool hospital) external ;
    function birthKangaroos(uint32 dadId, uint32 momId) external ;
    function updateBirthTime(uint32 tokenId, uint64 _time) external;
    function updateDadId(uint32 tokenId, uint32 dadId) external;
    function updateMomId(uint32 tokenId, uint32 momId) external;
    function updateCoupleId(uint32 tokenId, uint32 coupleId) external;
    function updateBoatId(uint32 tokenId, uint16 boatId) external;
    function updateLandId(uint32 tokenId, uint16 landId) external;
    function updateStatus(uint32 tokenId, uint8 status) external;
    function updateBornState(uint32 tokenId, uint8 bornState) external;
    function updateGen(uint32 tokenId, uint8 gen) external;
    function getKangaroo(uint32 tokenId) external view returns(KangarooDetails memory);
    function getPregnancyPeriod() external view returns(uint8);
    function getBabyPeriod() external view returns(uint8);
    function isCouples(uint32 male, uint32 female) external view returns(bool);
    function getCouple(uint32 tokenId) external view returns(uint32);
    function getKangarooGender(uint32 tokenId) external pure returns(string memory);
    function kangarooIsMale(uint32 tokenId) external pure returns(bool);
    function getKangarooGen(uint32 tokenId) external view returns(uint8);
    function isGen0(uint32 tokenId) external view returns(bool);
    function baseMaxBabiesAllowed(uint32 token) external view returns(uint8);
    function getBabyPeriod(uint32 tokenId) external view returns(uint64) ;
    function getStatus(uint32 tokenId) external view returns(uint8);
    function isBaby(uint32 tokenId) external view returns(bool);
    function getBornState(uint32 tokenId) external view returns(uint8);
    function getNumBabies(uint32 dadId, uint32 momId) external view returns(uint8);
    function pregnancyEndTimestamp(uint64 coupleEncoded) external view returns(uint64);
    function getCoupleEncoded(uint32 male, uint32 female) external pure returns(uint64);
    function setPregnancyPeriod(uint8 _pregnancyPeriod) external;
    function setDaysBabyPeriod(uint8 _daysBabyPeriod) external;
    function setPossibleMintStates(uint8[] calldata _states) external;
    function setKangarooContract(address _addr) external;
    function setGameManager(address _addr) external;
    function transferOwnership(address newOwner) external;
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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

interface IKangarooNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
    function birth(uint32 dadId, uint32 momId, address to, uint8 numBabies) external;
}

// File: contracts/KWWData.sol


pragma solidity ^0.8.4;






contract KWWDataWrapper is Ownable { 
    mapping(uint64 => IKWWData.CoupleDetails) public couplesData;

    address gameManager;
    IKangarooNFT kangarooContract;
    IKWWData dataContract;

    uint8 defaultBabyStatus = 0;
    uint8 maxBabiesGen0 = 2;
    uint8 maxBabiesOtherGens = 1;

    /*
       EXECUTABLE FUNCTIONS
    */

    function initKangaroo(uint32 tokenId, uint32 dadId, uint32 momId) public onlyKangarooContract{
        dataContract.initKangaroo(tokenId, dadId, momId);
        updateStatus(tokenId, defaultBabyStatus);
    }

    function setCouple(uint32 male, uint32 female) public onlyGameManager {
        dataContract.setCouple(male, female);
    }

    //Bonus Step - Kangaroo moved from one area to another
    function kangarooMoveLand(uint32 tokenId, uint16 landId) public onlyGameManager {
        dataContract.kangarooMoveLand(tokenId, landId);
    }

    //Step 1 - Kangaroo took boat to kangaroo island
    function kangarooTookBoat(uint32 tokenId, uint16 boatId) public onlyGameManager {
        dataContract.kangarooTookBoat(tokenId, boatId);
    }

    //Step 2 - kangaroo reached the kangaroo island, leaving the boat
    function kangarooReachedIsland(uint32 tokenId) public onlyGameManager {
        dataContract.kangarooReachedIsland(tokenId);
    }

    //step 3 - kangaroo start the pregnancy process
    function kangarooStartPregnancy(uint32 dadId, uint32 momId, bool hospital) public onlyGameManager {
      require(kangarooIsMale(dadId) && !kangarooIsMale(momId), "Genders not match");

      uint64 coupleEncoded = getCoupleEncoded(dadId, momId);
      uint8 baseMaxBabies = baseMaxBabiesAllowed(dadId);
      require(couplesData[coupleEncoded].babiesCounter < baseMaxBabies, "Max babies already born");
      updateStatus(dadId, 3);
      updateStatus(momId, 3);

      couplesData[coupleEncoded].pregnancyStarted = uint64(block.timestamp);
      couplesData[coupleEncoded].paidHospital = hospital;
      couplesData[coupleEncoded].activePregnant = true;
    }

    //Step 4a - birth the babies
    function birthKangaroos(uint32 dadId, uint32 momId, address ownerAddress) public onlyGameManager {
      require(couplesData[getCoupleEncoded(dadId, momId)].activePregnant == true, "Pregnancy not active");
      require(pregnancyEndTimestamp(getCoupleEncoded(dadId, momId)) <= block.timestamp, "Mom still in pregnancy period");

      uint8 numBabies = getNumBabies(dadId, momId);
      kangarooContract.birth(dadId, momId, ownerAddress, numBabies);

      updateStatus(dadId, 2);
      updateStatus(momId, 2);

      updateCouplesDataAfterBirth(dadId, momId, numBabies);
    }

    //Step 4b - Pregnancy done - Reset details and update the born babies counter
    function updateCouplesDataAfterBirth(uint32 dadId, uint32 momId, uint8 numBabies) public onlyGameManager {
       uint64 coupleEncoded = getCoupleEncoded(dadId, momId);

      couplesData[coupleEncoded].pregnancyStarted = 0;
      couplesData[coupleEncoded].babiesCounter += numBabies;
      couplesData[coupleEncoded].paidHospital = false;
      couplesData[coupleEncoded].activePregnant = false;
    }

    //Step 5 - Get Back to Australian
    function getBackAustralian(uint32 dadId, uint32 momId, uint16 boatId) public onlyGameManager{
        updateStatus(dadId, 1);
        updateStatus(momId, 1);
        updateBoatId(dadId, boatId);
        updateBoatId(momId, boatId);
    }

    //Step 5 - Get Back to Australian
    function kangaroosArrivedContinent(uint32 dadId, uint32 momId) public onlyGameManager{
        updateStatus(dadId, 0);
        updateStatus(momId, 0);
        updateBoatId(dadId, 0);
        updateBoatId(momId, 0);
    }
    
    function updateBirthTime(uint32 tokenId, uint64 _time) public onlyGameManager{
        dataContract.updateBirthTime(tokenId, _time);
    }
    
    function updateDadId(uint32 tokenId, uint32 dadId) public onlyGameManager{
        dataContract.updateDadId(tokenId, dadId);
    }
    
    function updateMomId(uint32 tokenId, uint32 momId) public onlyGameManager{
        dataContract.updateMomId(tokenId, momId);
    }

    function updateCoupleId(uint32 tokenId, uint32 coupleId) public onlyGameManager{
        dataContract.updateCoupleId(tokenId, coupleId);
    }

    function updateBoatId(uint32 tokenId, uint16 boatId) public onlyGameManager{
        dataContract.updateBoatId(tokenId, boatId);
    }
    function updateLandId(uint32 tokenId, uint16 landId) public onlyGameManager{
        dataContract.updateLandId(tokenId, landId);
    }

    function updateStatus(uint32 tokenId, uint8 status) public{
        require(msg.sender == owner() || msg.sender == gameManager || msg.sender == address(kangarooContract), "caller don't have permissions");
        dataContract.updateStatus(tokenId, status);
    }

    function updateBornState(uint32 tokenId, uint8 bornState) public onlyGameManager{
        dataContract.updateBornState(tokenId, bornState);
    }

    function updateGen(uint32 tokenId, uint8 gen) public onlyGameManager{
        dataContract.updateGen(tokenId, gen);
    }

    function updateCouple(uint32 male, uint32 female, uint64 pregnancyStartTime, uint8 babiesCounter, bool paidHospital, bool activePregnant) public onlyGameManager{
        uint64 coupleEncoded = getCoupleEncoded(male, female);

        couplesData[coupleEncoded].pregnancyStarted = pregnancyStartTime;
        couplesData[coupleEncoded].babiesCounter = babiesCounter;
        couplesData[coupleEncoded].paidHospital = paidHospital;
        couplesData[coupleEncoded].activePregnant = activePregnant;
    }

    function updatePregnancyStartTime(uint32 male, uint32 female, uint64 pregnancyStartTime) public onlyGameManager {
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        couplesData[coupleEncoded].pregnancyStarted = pregnancyStartTime;
    }

    function updateBabiesCounter(uint32 male, uint32 female, uint8 babiesCounter) public onlyGameManager {
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        couplesData[coupleEncoded].babiesCounter = babiesCounter;
    }

    function updatePaidHospital(uint32 male, uint32 female, bool paidHospital) public onlyGameManager {
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        couplesData[coupleEncoded].paidHospital = paidHospital;
    }

    function updateActivePregnant(uint32 male, uint32 female, bool activePregnant) public onlyGameManager {
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        couplesData[coupleEncoded].activePregnant = activePregnant;
    }

    /*
       GETTERS
    */

    function ownerOf(uint256 tokenId) public view returns (address owner){
        return kangarooContract.ownerOf(tokenId);
    }

    function totalSupply() public view returns (uint256){
        return kangarooContract.totalSupply();
    }


    function getKangaroo(uint32 tokenId) public view returns(IKWWData.KangarooDetails memory){
        return dataContract.getKangaroo(tokenId);
    }

    function getCouplesData(uint32 male, uint32 female) public view returns(IKWWData.CoupleDetails memory){
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        return couplesData[coupleEncoded];
    }

    function getPregnancyStartTime(uint32 male, uint32 female) public view returns(uint64){
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        return couplesData[coupleEncoded].pregnancyStarted;
    }

    function getBabiesCounter(uint32 male, uint32 female) public view returns(uint8){
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        return couplesData[coupleEncoded].babiesCounter;
    }

    function getPaidHospital(uint32 male, uint32 female) public view returns(bool){
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        return couplesData[coupleEncoded].paidHospital;
    }

    function getActivePregnant(uint32 male, uint32 female) public view returns(bool){
        uint64 coupleEncoded = getCoupleEncoded(male, female);
        return couplesData[coupleEncoded].activePregnant;
    }

    function getPregnancyPeriod() public view returns(uint8){
        return dataContract.getPregnancyPeriod();
    }
    function getBabyPeriod() public view returns(uint8){
        return dataContract.getBabyPeriod();
    }

    function isCouples(uint32 male, uint32 female) public view returns(bool){
      return dataContract.isCouples(male, female);
    }

    function getCouple(uint32 tokenId) public view returns(uint32){
      return dataContract.getCouple(tokenId);
    }

    function getKangarooGender(uint32 tokenId) public pure returns(string memory){
      return kangarooIsMale(tokenId) ? "Male" : "Female";
    }

    function kangarooIsMale(uint32 tokenId) public pure returns(bool){
      return tokenId % 2 == 0;
    }

    function getKangarooGen(uint32 tokenId) public view returns(uint8){
        return dataContract.getKangarooGen(tokenId);
    }

    function isGen0(uint32 tokenId) public view returns(bool){
        return dataContract.isGen0(tokenId);
    }

    function baseMaxBabiesAllowed(uint32 token) public view returns(uint8){
      return isGen0(token) ? maxBabiesGen0 : maxBabiesOtherGens;
    }

    function doneMaxBabies(uint32 male, uint32 female) public view returns(bool){
        return baseMaxBabiesAllowed(male) == getBabiesCounter(male, female);
    }

    function getBabyPeriod(uint32 tokenId) public view returns(uint64) {
        return dataContract.getBabyPeriod(tokenId);
    }

    function getStatus(uint32 tokenId) public view returns(uint8){
        return dataContract.getStatus(tokenId);
    }

    function isBaby(uint32 tokenId) public view returns(bool){
        return dataContract.isBaby(tokenId);
    }

    function getBornState(uint32 tokenId) public view returns(uint8){
        return dataContract.getBornState(tokenId);
    }

    function getNumBabies(uint32 dadId, uint32 momId) public view returns(uint8){
      uint64 coupleEncoded = getCoupleEncoded(dadId, momId);
      uint8 baseMaxBabies = baseMaxBabiesAllowed(dadId);
      require(couplesData[coupleEncoded].babiesCounter < baseMaxBabies, "Max babies already born");

      uint8 babiesAmount = 0;
      if(couplesData[coupleEncoded].paidHospital == true){
        babiesAmount = baseMaxBabies;
      }
      else{
        uint256 rand = KWWUtils.random(random()) % 10000;
        if(isGen0(dadId)){
          //Base Max 2 Babies
          // 0-3500 -> 1 Baby (35%)
          // 3501-6000 -> 2 Babies (25%)
          // 6001-10000 -> 0 Babies (40%)
          babiesAmount =  rand > 6000 ? 0 : (rand <= 3500 ? 1 : 2);
        }
        else{
          //Base Max 1 Baby
          // 0-6500 -> 0 Babies (65%)
          // 6500-10000 -> 1 Baby (35%)
          babiesAmount =  rand > 6500 ? 0 : 1;
        }
      }

      uint8 maxBabiesLeft = baseMaxBabies - couplesData[coupleEncoded].babiesCounter;

      return maxBabiesLeft < babiesAmount ? maxBabiesLeft : babiesAmount;
    }

    function random() internal view returns(uint256){
      return KWWUtils.random(kangarooContract.totalSupply());
    }

    function pregnancyEndTimestamp(uint64 coupleEncoded) public view returns(uint64){
      require(couplesData[coupleEncoded].activePregnant == true, "Pregnancy is not active");
      return couplesData[coupleEncoded].pregnancyStarted + (getPregnancyPeriod() * 1 days);
    }

    function getCoupleEncoded(uint32 male, uint32 female) public pure returns(uint64){
      return KWWUtils.pack(male, female);
    }

    /*
        MODIFIERS
    */
    modifier onlyGameManager() {
        require(gameManager != address(0), "Game manager not exists");
        require(msg.sender == owner() || msg.sender == gameManager, "caller is not the game manager");
        _;
    }

    modifier onlyKangarooContract() {
        require(address(kangarooContract) != address(0), "kangaroo contract not exists");
        require(msg.sender == owner() || msg.sender == address(kangarooContract), "caller is not the Kangaroo contract");
        _;
    }  

    /*
        ONLY OWNER
    */

    function setPregnancyPeriod(uint8 _pregnancyPeriod) public onlyOwner{
        dataContract.setPregnancyPeriod(_pregnancyPeriod);
    }

    function setDaysBabyPeriod(uint8 _daysBabyPeriod) public onlyOwner{
        dataContract.setDaysBabyPeriod(_daysBabyPeriod);
    }

    function setPossibleMintStates(uint8[] calldata _states) public onlyOwner{
        dataContract.setPossibleMintStates(_states);
    }

    function setKangarooContract(address _addr) public onlyOwner{
      kangarooContract = IKangarooNFT(_addr);
    }

    function setGameManager(address _addr) public onlyOwner{
      gameManager = _addr;
    }

    function setDataContract(address _addr) public onlyOwner{
      dataContract = IKWWData(_addr);
    }

    function setDataOwner(address _addr) public onlyOwner{
        dataContract.transferOwnership(_addr);
    }

    function setDefaultBabyStatus(uint8 status) public onlyOwner{
        defaultBabyStatus = status;
    }

    function setMaxBabies(uint8 gen0, uint8 otherGen) public onlyOwner{
        maxBabiesGen0 = gen0;
        maxBabiesOtherGens = otherGen;
    }
}