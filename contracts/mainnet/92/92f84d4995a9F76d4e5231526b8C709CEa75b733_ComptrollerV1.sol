// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; 
import "../interfaces/IGnosisSafe.sol";

interface IWModule{
    function name() external view returns (string memory);
    function _whitelisted() external view returns (address whitelisted);
}

interface IDeFiModule{
    function name() external view returns (string memory);
    function getAccount() external view returns (address);
}

contract ComptrollerV1 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /* ---          --- */

    // UserId tracker
    uint256 public userId;
    // AdvisorId tracker
    uint256 public advisorId;
    // BranchId tracker
    uint256 public branchId;
    // UserId to user data
    mapping(uint256 => UserData) users;
    // AdvisorId to advisor data
    mapping(uint256 => AdvisorData) advisors;
    // BranchId to branch data
    mapping(uint256 => BranchData) branches;
    // Get users id from account address
    mapping(address => uint) accountId;
    // Get users id from primary address
    mapping(address => uint) primaryId;
    // Get advisor id from advisor address
    mapping(address => uint) public advisorToId;
    // Get branch id from branch address
    mapping(address => uint) public branchToId;
    // Keeps track of registered advisors
    mapping(address => bool) public isRegisteredAdvisor;
    // Keeps track of registered branches
    mapping(address => bool) public isBranch;

    // Fees
    uint public MAX_FEE = 5000000; // 5%
    uint public NETWORK_FEE = 100000; // 0.1%

    // Dao Admin
    address public owner;

    // Advisor data struct 
    struct AdvisorData {
        EnumerableSet.UintSet userIds;
        uint256 id;
        uint256 branchId;
        address advisorAddress;
    }

    // Branch data struct 
    struct BranchData {
        EnumerableSet.UintSet advisorIds;
        uint256 id;
        address branchAddress;
    }

    // User data struct 
    struct UserData {
        EnumerableSet.AddressSet accounts;
        mapping(address => uint256) accountAdvisor;
        mapping(address => uint256) accountFee;
        mapping(address => EnumerableSet.AddressSet) accountSubset;
        address primaryAddress;
        address backupAddress;
    }


    /* --- Events --- */

    event RegisterUser(uint256 indexed userId, uint256 advisorId, address[] userAddresses);
    event RegisterAdvisor(uint256 indexed advisorId, address advisorAddress);
    event RegisterBranch(uint256 indexed branchId, address branchAddress);

    /* ---          --- */

    constructor(address daoAdmin) {
        owner = daoAdmin;
    }

    /// @dev Method called to register the User addresses,
    /// and create and assign a new userID.
    /// @param _userAccounts The set of user addresses to register.
    /// @param _primaryAddress The user primary address.
    /// @param _backup Backup address among Safe owners.
    /// @param _advisorId The advisorId of the advisor managing the user's assets.
    function registerUser(
        address[] memory _userAccounts,
        uint[] memory _accountFees,
        address _primaryAddress,
        address _backup,
        uint256 _advisorId
    ) 
        external 
        returns (uint256)
    {
        require(advisors[_advisorId].advisorAddress == msg.sender || msg.sender == owner || isSetup(_userAccounts, msg.sender), "NOAUTH");
        userId++;
        _registerUser(userId,_userAccounts,_accountFees,_primaryAddress,_backup,_advisorId);
        emit RegisterUser(userId,_advisorId,_userAccounts);

        return userId;
    }

    /// @dev Method called by branch (or advisor) to register the Advisor address,
    /// and create and assign a new advisorID.
    /// @param advisorAddress The address of the advisor managing the user's assets.
    function registerAdvisor(
        address advisorAddress,
        uint256 branchId
    ) 
        external 
        returns (uint256)
    {
        require(isBranch[msg.sender] && branches[branchId].branchAddress == msg.sender, "NOAUTH");
        require(!isRegisteredAdvisor[advisorAddress],"DUPL");
        advisorId++;
        AdvisorData storage data = advisors[advisorId];
        data.id = advisorId;
        data.branchId = branchId;
        data.advisorAddress = advisorAddress;
        advisorToId[advisorAddress] = advisorId;
        isRegisteredAdvisor[advisorAddress] = true;
        emit RegisterAdvisor(advisorId, advisorAddress);

        return advisorId;
    }

    /// @dev Method called to register the branch to DAA,
    /// and create and assign a new branchId.
    /// @param branchAddress The address of the advisor managing the user's assets.
    function registerBranch(
        address branchAddress
    )   
        external 
        onlyOwner
        returns (uint256)
    {
        require(!isBranch[msg.sender] , "DUPL");
        branchId++;
        BranchData storage data = branches[branchId];
        data.id = branchId;
        data.branchAddress = branchAddress;
        isBranch[branchAddress] = true;
        branchToId[branchAddress] = branchId;
        emit RegisterBranch(branchId, branchAddress);

        return branchId;
    }

    /// @dev Change the registered address of an advisor.
    /// @param _advisorId The id of the advisor record to modify.
    /// @param advisorAddress The new address to add to the record.
    function changeAdvisorAddress(
        uint _advisorId,
        address advisorAddress
    ) external {
        AdvisorData storage data = advisors[_advisorId];
        require(branches[data.branchId].branchAddress == msg.sender,"NOAUTH");
        advisorToId[data.advisorAddress] = 0;
        isRegisteredAdvisor[data.advisorAddress] = false;
        advisorToId[advisorAddress] = _advisorId;
        isRegisteredAdvisor[advisorAddress] = true;
        data.advisorAddress = advisorAddress;

        emit RegisterAdvisor(_advisorId, advisorAddress);
    }

    /// @dev Change the registered branch for an advisor.
    function changeAdvisorBranch(uint _advisorId) external {
        require(isBranch[msg.sender],"NOTB");
        uint newBranchId = branchToId[msg.sender];
        AdvisorData storage data = advisors[_advisorId];
        data.branchId = newBranchId;
    }

    /// @dev Deregister branch.
    function removeBranch(uint _branchId) external onlyOwner {
        BranchData storage data = branches[_branchId];
        isBranch[data.branchAddress] = false;
        branchToId[data.branchAddress] = 0;
    }

    /// @dev Change the advisor associated with the account.
    /// @param _advisorId The id of the advisor record to modify.
    /// @param userAccount The user account.
    /// @param _fee The fee for the new advisor.
    function changeAccountAdvisor(
        address userAccount,
        uint _advisorId,
        uint _fee
    ) external {
        require(users[accountId[userAccount]].accounts.contains(msg.sender) || isUserBranch(accountId[userAccount], msg.sender), "NOAUTH");
        UserData storage user = users[userId];
        user.accountAdvisor[userAccount] = _advisorId;
        require(_feeCheck(_fee));
        user.accountFee[userAccount] = _fee;
    }

    /// @dev Change the branch address record.
    /// @param _branchId The id of the branch to modify.
    /// @param branchAddress The new address to add to the record.
    function changeBranch(
        uint _branchId,
        address branchAddress
    ) external onlyOwner {
        require(_branchId <= branchId && _branchId != 0, "NREG");
        BranchData storage data = branches[_branchId];
        isBranch[data.branchAddress] = false;
        isBranch[branchAddress] = true;
        data.id = _branchId;
        data.branchAddress = branchAddress;
        
        emit RegisterBranch(branchId, branchAddress);
    }

    /// @dev Change user primary address to new address.
    /// @param _userId The user id to modify.
    /// @param _primaryAddress The new address to set as primary address.
    function changeUserPrimaryAddress(
        uint _userId,
        address _primaryAddress
    ) external {
        require(users[_userId].accounts.contains(msg.sender) || isUserBranch(_userId,_primaryAddress), "NOAUTH");
        UserData storage data = users[_userId];
        address[] memory _userSafes = users[_userId].accounts.values();
        _checkPrimaryAddress(_userSafes,_primaryAddress);
        primaryId[data.primaryAddress] = 0;
        primaryId[_primaryAddress] = _userId;
        data.primaryAddress = _primaryAddress;
    }

    /// @dev Change user primary address to new address.
    /// @param _userId The user id to modify.
    /// @param _backupAddress The new address to set as backup address.
    function changeUserBackupAddress(
        uint _userId,
        address _backupAddress
    ) external {
        require(users[_userId].accounts.contains(msg.sender) || isUserBranch(_userId, msg.sender), "NOAUTH");
        UserData storage data = users[_userId];
        data.backupAddress = _backupAddress;
    }

    /// @dev Add an address to the user set.
    /// @param _userId The user id to modify.
    /// @param accountAddress The address to add to the existing set.
    function addUserAccount(
        uint _userId,
        address accountAddress,
        uint _advisorId,
        uint accountFee
    ) external {
        // PrimaryAddress, MainSafe, any Advisor or user Branch
        UserData storage data = users[_userId];
        require(data.primaryAddress == msg.sender || data.accounts.contains(msg.sender) || isRegisteredAdvisor[msg.sender] || isUserBranch(_userId, msg.sender), "NOAUTH");
        require(!data.accounts.contains(accountAddress), "ADUPL");
        accountId[accountAddress] = _userId;
        data.accounts.add(accountAddress); 
        data.accountAdvisor[accountAddress] = _advisorId;
        advisors[_advisorId].userIds.add(_userId);
        require(_feeCheck(accountFee),"MFEE");
        data.accountFee[accountAddress] = accountFee;
    }

    /// @dev Remove an address from the user set.
    /// @param _userId The user id to modify.
    /// @param toRemove The address to remove from the existing set.
    function removeUserAccount(
        uint _userId,
        address toRemove
    ) external {
        require(users[_userId].primaryAddress == msg.sender || users[_userId].accounts.contains(msg.sender), "NOAUTH");
        UserData storage data = users[_userId];
        uint _advisorId = data.accountAdvisor[toRemove];
        if (!_isMultiAccountAdvisor(_advisorId,_userId)){
            advisors[_advisorId].userIds.remove(_userId);
        }
        accountId[toRemove] = 0;
        data.accounts.remove(toRemove);
        data.accountFee[toRemove] = 0;
    }

    function addSafeToAccount(
        address account,
        address[] memory subSafes
    ) 
        external 
    {
        uint userId = accountId[account];
        require(users[userId].accounts.contains(msg.sender) || isUserBranch(userId, msg.sender), "NOAUTH");
        UserData storage data = users[userId];
        uint len = subSafes.length;
        for(uint i=0; i< len; ++i){
            require(!data.accountSubset[account].contains(subSafes[i]),"SDUPL");
            data.accountSubset[account].add(subSafes[i]);
        }
    }

    function removeSafeFromAccount(
        address account,
        address[] memory subSafes
    ) 
        external 
    {
        uint _userId = accountId[account];
        require(users[_userId].accounts.contains(msg.sender) || isUserBranch(_userId, msg.sender), "NOAUTH");
        UserData storage data = users[_userId];
        uint len = subSafes.length;
        for(uint i=0; i< len; ++i){
            data.accountSubset[account].remove(subSafes[i]);
        }
    }

    /// @dev Allows DAAadmin to change the network fee.
    function changeNetworkFee(uint newFee) external onlyOwner {
        NETWORK_FEE = newFee;
    }

    /// @dev Returns the user Id for a given Safe address
    /// @param _address The address to look up.
    function isUserAccount(address _address) external view returns (bool isUser) {
        if(accountId[_address]>0){
            isUser = true;
        }
    }

    /// @dev Returns the user Id for a given primary address
    /// @param _address The address to look up.
    function isUserPrimaryAddress(address _address) external view returns (bool isUser) {
        if(primaryId[_address]>0){
            isUser = true;
        }
    }

    function getUserIdFromSafeAddress(address _address) external view returns(uint){
        return accountId[_address];
    }

    function getUserIdFromPrimaryAddress(address _address) external view returns(uint){
        return primaryId[_address];
    }

    function getPrimaryAddressFromUserId(uint userId) external view returns (address){
        return users[userId].primaryAddress;
    }

    function getBackupAddressFromUserId(uint userId) external view returns (address){
        return users[userId].backupAddress;
    }

    /// @dev Getter of the advisor registered for given user.
    /// @param _userId The registered id of the user.
    function getUserAdvisors(uint _userId) 
        external
        view
        returns (address[] memory accounts, uint256[] memory advisors)
    {
        UserData storage user = users[_userId];
        accounts = user.accounts.values();
        uint len = accounts.length;
        advisors = new uint[](len);
        for(uint i =0; i< len; ++i){
            advisors[i] = user.accountAdvisor[accounts[i]];
        } 
    }

    /// @dev Getter of the advisor registered for given account.
    /// @param _userId The registered id of the user.
    function getAccountAdvisor(uint _userId, address account) 
        external
        view
        returns (uint256)
    {
        return users[_userId].accountAdvisor[account];
    }

    function getAccountFee(uint _userId, address account)
        external
        view
        returns (uint256)
    {  
        return users[_userId].accountFee[account];
    }

    /// @dev Getter of the registred branch id for a given advisor.
    /// @param _advisorId The registred id of the advisor.
    function getAdvisorBranch(
        uint256 _advisorId
    )
        external
        view
        returns (uint256)
    {
        return advisors[_advisorId].branchId;
    }

    /// @dev Getter of the registred branch address for given id.
    /// @param _branchId The registered branch Id.
    function getBranchAddress(uint _branchId) 
        external
        view
        returns (address)
    {
        return branches[_branchId].branchAddress;
    }

    /// @dev For each user registered with the advisor, it returns an array of all user registered addresses (accounts + subAccounts).
    function getSafesByAdvisor(address advisorAddress) external view returns (address[][] memory safesList) {
        uint advisorId = advisorToId[advisorAddress];
        uint[] memory userIds = advisors[advisorId].userIds.values();
        uint len = userIds.length;
        safesList = new address[][](len);
        for (uint i =0; i< len; i++){
            address[] memory safes = getUserAddressesOfAdvisor(advisorId,userIds[i]);
            safesList[i] = safes;
        }
    }

    /// @dev For each user registered with the advisor, it returns an array of all user registered accounts.
    function getAccountsByAdvisor(address advisorAddress) external view returns (address[][] memory safesList) {
        uint advisorId = advisorToId[advisorAddress];
        uint[] memory userIds = advisors[advisorId].userIds.values();
        uint len = userIds.length;
        safesList = new address[][](len);
        for (uint i =0; i< len; i++){
            address[] memory safes = getUserAccountsOfAdvisor(advisorId,userIds[i]);
            safesList[i] = safes;
        }
    }

    /// @dev Getter of all user's data for UI purposes.
    /// It takes the user Safe address as input, and returns:
    ///     - The addresses of the Safe registered for the given user 
    ///       and their type (i.e. Main Safe or DeFi Safe)
    ///     - The addresses of the Owners of each Safe and
    ///       their role (i.e., primary, backup/guardian, advisor, branch)
	///     - The addresses of the Module enabled on each Safe. 
    ///       If the safe is a Withdraw module, it will also return the withdraw whitelisted address,
    ///       if the module is a DeFi module, it will return the SmartWallet address).
    /// @param userAccount The user Main Safe address.
    function getAllUserData(
        address userAccount
    ) 
        external
        view
        returns(address[] memory safes, string[] memory safeTypes, address[][] memory linkedAddresses, uint[][] memory roles)
    {  
        safes = getUserAddresses(userAccount);
        uint len = safes.length;
        linkedAddresses = new address[][](len*8);
        roles = new uint[][](len*8);
        safeTypes = new string[](len);
        for (uint256 i = 0; i < len; i++){
            if(safes[i] != address(0)){
                (safeTypes[i], linkedAddresses[i], roles[i]) = getSafeRoles(safes[i]);
            }
        }
    }

    /// @dev Getter of all account data for UI purposes.
    /// It takes the user Safe address as input, and returns:
    ///     - The addresses of the Safe registered for the given user 
    ///       and their type (i.e. Main Safe or DeFi Safe)
    ///     - The addresses of the Owners of each Safe and
    ///       their role (i.e., primary, backup/guardian, advisor, branch)
	///     - The addresses of the Module enabled on the Safe. 
    ///       If the safe is a Withdraw module, it will also return the withdraw whitelisted address,
    ///       if the module is a DeFi module, it will return the SmartWallet address).
    /// @param userSafe The user Safe address.
    function getAllAccountData(
        address userSafe
    ) 
        external
        view
        returns(address[] memory safes, string[] memory safeTypes, address[][] memory linkedAddresses, uint[][] memory roles)
    {  
        safes = getAccountAddresses(userSafe);
        uint len = safes.length;
        linkedAddresses = new address[][](len*8);
        roles = new uint[][](len*8);
        safeTypes = new string[](len);
        for (uint256 i = 0; i < len; i++){
            if(safes[i] != address(0)){
                (safeTypes[i], linkedAddresses[i], roles[i]) = getSafeRoles(safes[i]);
            }
        }
    }

    /// @dev Getter of all user's data for UI purposes.
    /// It takes the user primary address as input, and returns:
    ///     - The addresses of the Safe registered for the given user 
    ///       and their type (i.e. Main Safe or DeFi Safe)
    ///     - The addresses of the Owners of each Safe and
    ///       their role (i.e., primary, backup/guardian, advisor, branch)
	///     - The addresses of the Module enabled on each Safe. 
    ///       If the safe is a Withdraw module, it will also return the withdraw whitelisted address,
    ///       if the module is a DeFi module, it will return the SmartWallet address).
    /// @param primaryAddress The user primary address - the wallet connected to the app.
    function getAllUserDataFromPrimary(
        address primaryAddress
    ) 
        external
        view
        returns(address[] memory safes, string[] memory safeTypes, address[][] memory linkedAddresses, uint[][] memory roles)
    {  
        safes = getUserAddressesFromPrimary(primaryAddress);
        uint len = safes.length;
        linkedAddresses = new address[][](len*8);
        roles = new uint[][](len*8);
        safeTypes = new string[](len);
        for (uint256 i = 0; i < len; i++){
            if(safes[i] != address(0)){
                (safeTypes[i], linkedAddresses[i], roles[i]) = getSafeRoles(safes[i]);
            }
        }
    }

    /// @dev Takes a User Id as input and returns all connected Safes.
    function getUserAddresses(uint _userId)
        public
        view
        returns (address[] memory)
    {
        return _getUserAddressesFromId(_userId);
    } 

    /// @dev Returns all User Safes (Accounts + SubAccounts) under a specific advisor.
    function getUserAddressesOfAdvisor(
        uint _advisorId,
        uint _userId
    )
        public
        view
        returns (address[] memory)
    {
      return _getUserAddressesFromIdAdvisorFiltered(_advisorId,_userId);
    } 

    /// @dev Takes a Main Safe address as input and returns all connected Safes.
    function getUserAddresses(address userAccount)
        public
        view
        returns (address[] memory)
    {
        uint userId = accountId[userAccount];
        return _getUserAddressesFromId(userId);
    } 

    /// @dev Takes a primary address as input and returns all connected Safes.
    function getUserAddressesFromPrimary(address userPrimaryAddr)
        public
        view
        returns (address[] memory)
    {
        uint userId = primaryId[userPrimaryAddr];
        return _getUserAddressesFromId(userId);
    }

    /// @dev Takes an account address as input and returns account + all connected Safes .
    function getAccountAddresses(address userAccount)
        public
        view
        returns (address[] memory)
    {
        return _getAccountAddresses(userAccount);
    } 

    /// @dev Getter of all registered accounts for given user.
    /// @param _userId The registered id of the user.
    function getUserAccounts(uint _userId) 
        public 
        view 
        returns (address[] memory)
    {
        return users[_userId].accounts.values();
    }

    /// @dev Getter of all accounts for given user registered with given advisor.
    /// @param _advisorId The registered id of the advisor.
    /// @param _userId The registered id of the user.
    function getUserAccountsOfAdvisor(
        uint _advisorId,
        uint _userId
    ) 
        public 
        view 
        returns (address[] memory)
    {
        address[] memory accounts = users[_userId].accounts.values();
        uint len = accounts.length;
        uint nAdvAccounts = 0;
        for(uint i =0; i < len; ++i){
            if(users[_userId].accountAdvisor[accounts[i]] == _advisorId){
                nAdvAccounts++;
            }
        }
        address[] memory advAccounts = new address[](nAdvAccounts);
        for(uint i =0; i < len; ++i){
            if(users[_userId].accountAdvisor[accounts[i]] == _advisorId){
                advAccounts[i] == accounts[i];
            }
        }
        return advAccounts;
    }

    /// @dev Getter of all registered accounts for given user.
    /// @param userAccount One of the user account addresses.
    function getAllAccountsFromUserAccount(address userAccount) 
        public 
        view 
        returns (address[] memory)
    {
        uint _userId = accountId[userAccount];
        return users[_userId].accounts.values();
    }

    /// @dev Getter of the advisor address registered for given id.
    /// @param _advisorId The registred advisor Id to query.
    function getAdvisorAddress(uint _advisorId) 
        public
        view
        returns (address)
    {
        return advisors[_advisorId].advisorAddress;
    }

    /// @dev Getter of all User Ids registered with an advisor.
    /// @param _advisorId The registred advisor Id to query.
    function getAdvisorUserList(uint _advisorId) 
        public
        view
        returns (uint[] memory)
    {
        return advisors[_advisorId].userIds.values();
    }

    function getAccountSubsafes(address userAccount) 
        public 
        view 
        returns (address[] memory) 
    {
        uint userId = accountId[userAccount];
        return users[userId].accountSubset[userAccount].values();
    }

    /// @dev Takes a Safe address as input and returns known DAA roles.
    /// Primary             role id: 1
    /// Backup              role id: 2
    /// Guardian            role id: 3               
    /// Advisor             role id: 4      
    /// Branch              role id: 5
    /// Withdrawal Module   role id: 6
    /// Withdrawal Address  role id: 7
    /// DeFi Module         role id: 8
    /// DeFi SmartWallet    role id: 9
    function getSafeRoles(address safe) 
        public 
        view 
        returns(string memory safeType, address[] memory linkedAddresses, uint[] memory roles)
    {
        safeType = "MAIN";
        linkedAddresses = new address[](10);
        roles = new uint[](10);
        uint userId = accountId[safe];
        address[] memory _owners = IGnosisSafe(safe).getOwners();
        uint256 len = _owners.length;
        for (uint256 i = 0; i < len; i++) {
            linkedAddresses[i] = _owners[i];
            if (users[userId].primaryAddress==_owners[i]){
                roles[i] = 1;
            } else if (users[userId].backupAddress ==_owners[i]){
                roles[i] = 2;
            } else if (getAdvisorAddress(users[userId].accountAdvisor[safe]) == _owners[i]){
                roles[i] = 4;
            } else if (isBranch[_owners[i]]){
                roles[i] = 5;
            } else {
                roles[i] = 3; // guardian
            }
        }
        address[] memory modules = IGnosisSafe(safe).getModules();
        len = modules.length;
        uint nModules = 0;
        for (uint256 i = 0; i < len; i++) {
            if(isWithdrawModule(modules[i])){
                linkedAddresses[4+nModules] = modules[i]; roles[4+nModules] = 6;
                linkedAddresses[5+nModules] = IWModule(linkedAddresses[4+nModules])._whitelisted();roles[5+nModules] = 7;
                nModules+=2;
            }
            if(isDeFiModule(modules[i])){
                linkedAddresses[4+nModules] = modules[i]; roles[4+nModules] = 8;
                linkedAddresses[5+nModules] = IDeFiModule(linkedAddresses[4+nModules]).getAccount();roles[5+nModules] = 9;
                safeType = "DEFI";
                nModules+=2;
            }
        }
    }

    // can update with new withdraw module version name
    function isWithdrawModule(address toCheck) public view returns (bool isWModule){
        try IWModule(toCheck)._whitelisted() {
            isWModule = true;
        } catch{
            isWModule = false;
        }
    }

    function isDeFiModule(address toCheck) public view returns (bool isDModule){
        try IDeFiModule(toCheck).name(){
            if (keccak256(abi.encode(IDeFiModule(toCheck).name())) == keccak256(abi.encode("DAA DSP Module"))){
                isDModule = true;
            } else {
                isDModule = false;
            }
        } catch {
            isDModule = false;
        }
    }

    function _getUserAddressesFromId(uint userId) 
        internal 
        view 
        returns (address[] memory allAddresses) 
    {
        address[] memory accounts = users[userId].accounts.values();
        uint len = accounts.length;
        address[][] memory _subAccounts = new address[][](len);
        uint n = 0;
        for (uint i=0; i< len; ++i){
            _subAccounts[i] = users[userId].accountSubset[accounts[i]].values();
            n = n + _subAccounts[i].length;
        }
        allAddresses = new address[](len+n);
        for (uint i=0; i< len; ++i){
            allAddresses[i] = accounts[i];
        }
        // unpack subAccounts
        address[] memory subAccounts = new address[](n);
        uint skip = 0;
        for (uint i=0; i< len; ++i){
            if (i>0){ skip = skip + _subAccounts[i-1].length;}
            for(uint j=0; j< _subAccounts[i].length; ++j){
                subAccounts[skip+j] = _subAccounts[i][j];
            }
        }
        uint j = 0;
        for (uint i=len; i< len+n; ++i){
            allAddresses[i] = subAccounts[j];
            j++;
        }
        return allAddresses;
    }

    function _getUserAddressesFromIdAdvisorFiltered(
        uint advisorId,
        uint userId) 
        internal 
        view 
        returns (address[] memory allAddresses) 
    {
        address[] memory accounts = users[userId].accounts.values();
        uint len = accounts.length;
        uint nRm = 0;
        for(uint i =0; i< len; i++){
            if (!(users[userId].accountAdvisor[accounts[i]]==advisorId)){
                accounts[i] = address(0);
                nRm++;
            }
        }
        len = len - nRm;
        address[][] memory _subAccounts = new address[][](len);
        uint n = 0;
        for (uint i=0; i< len; ++i){
            if (accounts[i] != address(0)){
                _subAccounts[i] = users[userId].accountSubset[accounts[i]].values();
                n = n + _subAccounts[i].length;
            }
        }
        allAddresses = new address[](len+n);
        for (uint i=0; i< len; ++i){
            if (accounts[i] != address(0)){
                allAddresses[i] = accounts[i];
            }
        }
        // unpack subAccounts
        address[] memory subAccounts = new address[](n);
        uint skip = 0;
        for (uint i=0; i< len; ++i){
            if (i>0){ skip = skip + _subAccounts[i-1].length;}
            for(uint j=0; j< _subAccounts[i].length; ++j){
                subAccounts[skip+j] = _subAccounts[i][j];
            }
        }
        uint j = 0;
        for (uint i=len; i< len+n; ++i){
            allAddresses[i] = subAccounts[j];
            j++;
        }
        return allAddresses;
    }

    function _getAccountAddresses(address account) 
        internal 
        view 
        returns (address[] memory allAddresses) 
    {
        
        uint userId = accountId[account];
        address[] memory _subAccounts = users[userId].accountSubset[account].values();
        uint n = _subAccounts.length + 1;
        allAddresses = new address[](n);
        allAddresses[0] = account;
        for (uint i=1; i<n; i++){
            allAddresses[i] = _subAccounts[i-1];
        }
        return allAddresses;
    }

    function _registerUser(
        uint _userId,
        address[] memory _userSafes,
        uint[] memory _fees,
        address _primaryAddress,
        address _backup,
        uint256 _advisorId
    ) 
        internal 
    {
        _userInputCheck(_userSafes,_fees,_primaryAddress);
        UserData storage data = users[_userId];
        AdvisorData storage advData = advisors[_advisorId];
        advData.userIds.add(_userId);
        uint len = _userSafes.length;
        for(uint i=0; i < len; i++){
            require(_userSafes[i] != address(0), "AZERO");
            if(data.accounts.add(_userSafes[i])){
                accountId[_userSafes[i]] = _userId;
                data.accountAdvisor[_userSafes[i]] = _advisorId;
                data.accountFee[_userSafes[i]] = _fees[i];
            }
        }
        primaryId[_primaryAddress] = _userId;
        data.primaryAddress = _primaryAddress;
        data.backupAddress = _backup;
    }

    function _isMultiAccountAdvisor(uint _advisorId, uint _userId) internal view returns (bool isMulti){
        address[] memory accounts = users[_userId].accounts.values();
        uint len = accounts.length;
        uint nAccounts = 0;
        for (uint i=0; i< len; i++){
            if(users[userId].accountAdvisor[accounts[i]]== _advisorId){
                nAccounts++;
            }
        }
        if (nAccounts>1){
            isMulti = true;
        }
    }

    function _userInputCheck(
        address[] memory _userSafes,
        uint[] memory _fees,
        address _userAddress
    ) 
        internal returns (bool check)
    {
        require(_userSafes.length==_fees.length, "DLEN");
        uint len = _userSafes.length;
        for (uint256 i = 0; i < len; i++){
            // Primay address is safe owner, and account fee < max fee
            if(IGnosisSafe(_userSafes[i]).isOwner(_userAddress) && _feeCheck(_fees[i])) {
                check = true; 
            }
        }
        require(check,"UIC");
    }

    function _feeCheck(uint fee) internal view returns (bool) {
        return fee < MAX_FEE;
    }

    function _checkPrimaryAddress(
        address[] memory _userSafes,
        address _userAddress
    ) 
        internal returns (bool check)
    {
        uint len = _userSafes.length;
        for (uint256 i = 0; i < len; i++){
            // Primay address is safe owner
            if(IGnosisSafe(_userSafes[i]).isOwner(_userAddress)) {
                check = true; 
            }
        }
        require(check,"PAC");
    } 

    function isSetup(address[] memory safes, address sender) internal view returns (bool) {   
        require(accountId[sender]==0, "NO AUTH");
        uint len = safes.length;
        for (uint i=0; i<len; ++i){
            if (safes[i] == sender) return true;
        }
        return false;
    }

    function isUserBranch(uint _userId, address sender) 
        internal 
        view 
        returns (bool)
    {
        uint branchId = branchToId[sender];
        address[] memory accounts = users[_userId].accounts.values();
        uint len = accounts.length;
        for (uint i = 0; i < len; ++i){
            uint _advisorId = users[_userId].accountAdvisor[accounts[i]];
            if (advisors[_advisorId].branchId == branchId){
                return true;
            }
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NOAUTH"); 
        _;
    }

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "../contracts/utils/Enum.sol";

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
    
    function getOwners() external view returns (address[] memory);

    function isOwner(address owner) external view returns (bool);

    function enableModule(address module) external;

    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable virtual returns (bool success);

    function signedMessages(bytes32) external view returns(uint256);

    function domainSeparator() external view returns (bytes32);

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) external;

    function approveHash(bytes32 hashToApprove) external;

    function getModules() external view returns (address[] memory);

    function changeThreshold(uint256 _threshold) external;
    
}