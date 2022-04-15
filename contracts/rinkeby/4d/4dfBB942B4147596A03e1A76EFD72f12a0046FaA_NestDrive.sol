//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @author Team Resilient - Blockgames Internship 22
/// @title A Decentralized file storage Dapp
contract NestDrive is Pausable {
    constructor() {
        moderator[msg.sender] = true;
    }

    using Counters for Counters.Counter;

    /// @notice total number of items ever created
    /// @dev counts the number of items in the state variable `_itemIds`
    Counters.Counter private _itemIds;

    /// @notice total number of items made private
    /// @dev counts the number of items in the state variable `_itemsPrivate`
    Counters.Counter private _itemsPrivate;

    /// @notice stores the list of moderators
    /// @dev mapping outlining addresses of assigned moderators
    mapping(address => bool) public moderator;

    /// @notice stores the list of files
    /// @dev mapping outlining all files created
    mapping(uint => File) public Allfiles;

   

    /// @dev mapping of blacklisted addresses
    mapping(address => bool) public blackListedAddresses;

/// @notice stores the list of blacklisted addresses
address[] public blackList;

/// @dev mapping of blacklisted addresses index
mapping(address=> uint) indexOfblackList;
//
    uint[] public reportedFiles;
    mapping(uint=>uint) indexOfreportedFiles;
    mapping(uint => bool) public reportExist;

 /// @notice emits a notice when a new file is uploaded
    /// @dev emit an event containing all the file details when file is uploaded
    event FileUploaded(
        uint fileId,
        string fileHash,
        string fileSize,
        string fileType,
        string fileName,
        string fileDescription,
        uint uploadTime,
        address uploader,
        bool isPublic
    );

    /// @notice Notification when a moderator is assigned
    /// @dev Emit event when a new moderator is assigned
    event AssignMod(address adder, address newMod);

    /// @notice Notification when a moderator is removed
    /// @dev Emit event when a moderator is removed
    event RemoveMod(address remover, address newMod);

    /// @notice Notification when a address is blacklisted
    /// @dev Emit event when a new address is blacklisted
    event addInBlackList(address addr);


    /// @notice Notification when a blacklisted address is removed
    /// @dev Emit event when a blacklisted address is removed
    event remInBlackList(address addr);

 /// @notice Notification when a file is reported
    /// @dev Emit event when a file  is reported
    event newReport(uint _itemIds);

    /// @notice Notification when a user makes their file private
    /// @dev Emit event when a user makes their file private
    event madePrivate(uint _itemIds);

    /// @notice Notification when a user makes their file public
    /// @dev Emit when a user makes their file public
    event madePublic(uint _itemIds);

    /// @notice Notification when a moderator makes a file private as penalty
    /// @dev Emit event when a moderator makes a file private as penalty
    event madePrivateMod(uint _itemIds);




    /// @dev modifier to ensure only moderators can call selected functions.
    modifier isMod(address _user) {
        bool ismod = moderator[_user];
        require(ismod, "Only Moderators Have Access!");
        _;
    }

  

    /// @dev modifier to check address is not blacklisted
    modifier isNotBlacklisted() {
        require(
            blackListedAddresses[msg.sender] == false,
            "Address is currently Blacklisted.."
        );
        _;
    }

    /// @notice defines the variables of an uploaded file
    struct File {
        uint fileId;
        string fileHash;
        string fileSize;
        string fileType;
        string fileName;
        string fileDescription;
        uint uploadTime;
        address uploader;
        bool isPublic;
    }
   

    /// @notice Function to upload a file
    function uploadFile(
        string memory _fileHash,
        string memory _fileSize,
        string memory _fileType,
        string memory _fileName,
        string memory _fileDescription,
        bool _isPublic
    ) public whenNotPaused isNotBlacklisted {
        /// @dev Make sure the file hash exists
        require(bytes(_fileHash).length > 0);

        /// @dev Make sure file type exists
        require(bytes(_fileType).length > 0);

        /// @dev Make sure file description exists
        require(bytes(_fileDescription).length > 0);

        /// @dev Make sure file fileName exists
        require(bytes(_fileName).length > 0);

        /// @dev Make sure uploader address exists
        require(msg.sender != address(0));
        // Make sure file size is more than 0
        require(bytes(_fileSize).length > 0);

        /// @dev Increment file id
        _itemIds.increment();
        uint currentfileId = _itemIds.current();

        /// @notice Add File to the contract
        Allfiles[currentfileId] = File(
            currentfileId,
            _fileHash,
            _fileSize,
            _fileType,
            _fileName,
            _fileDescription,
            block.timestamp,
            msg.sender,
            _isPublic
        );

        /// @notice Trigger an event when file is uploaded
        emit FileUploaded(
            currentfileId,
            _fileHash,
            _fileSize,
            _fileType,
            _fileName,
            _fileDescription,
            block.timestamp,
            msg.sender,
            _isPublic
        );
    }

    /// @dev Only the uploader can change file visibility
    function makeFilePrivate(uint fileId)
        public
        whenNotPaused
        isNotBlacklisted
    {
        /// @notice ensure that the uploader can change file visibility
        require(
            Allfiles[fileId].uploader == msg.sender,
            "you can only manipulate your own file"
        );

        /// @notice make files private
        Allfiles[fileId].isPublic = false;

        /// @dev increase count of private files
        _itemsPrivate.increment();

        /// @notice emit when a user fmakes their file from private
        emit madePrivate(fileId);
    }



    /// @dev Only the uploader can change file visibility
    function makeReportedPrivate(uint fileId)
        public
        whenNotPaused
        isNotBlacklisted
    {
        /// @notice ensure that the moderator can change file visibility
        require(
             moderator[msg.sender],
            "only admin can call this"
        );

        /// @notice make files private
        Allfiles[fileId].isPublic = false;

        uint index = indexOfreportedFiles[fileId];
         reportedFiles[index] = reportedFiles[reportedFiles.length-1];
        
        reportedFiles.pop();


        /// @dev increase count of private files
        _itemsPrivate.increment();

        /// @notice emit when a moderator makes a file private as penalty
        emit madePrivateMod(fileId);
    }

    /// @dev Only the uploader can change file visibility
    function makeFilePublic(uint fileId) public whenNotPaused isNotBlacklisted {
        /// @notice ensure that the uploader can change file visibility
       
        require(
            Allfiles[fileId].uploader == msg.sender,
            "you can only manipulate your own file"
        );

        /// @notice ensure that the reported files can not be made puvlic after penalty
          require(
            reportExist[fileId] == false,
            "File has been blacklisted for violation, and cannot be made public."
        );

        /// @notice make file public
        Allfiles[fileId].isPublic = true;

        /// @dev Increment public files
        _itemIds.increment();

        /// @notice emit when a user makes their file public
        emit madePublic(fileId);
    }

    /// @notice Function to retrieve all public files
    function fetchPublicFiles()
        public
        view
        whenNotPaused
        isNotBlacklisted
        returns (File[] memory)
    {
        /// @notice total number of items ever created
        uint totalFiles = _itemIds.current();

        uint publicFilesID = _itemIds.current() - _itemsPrivate.current();
        uint currentIndex = 0;

        File[] memory items = new File[](publicFilesID);

        /// @notice Loop through all items ever created
        for (uint i = 0; i < totalFiles; i++) {
            /// @notice Get only public item
            if (Allfiles[i + 1].isPublic == true) {
                uint currentId = Allfiles[i + 1].fileId;
                File storage currentItem = Allfiles[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
    

    /// @dev function to  fetch only files uploaded by the user
    function fetchUserFiles()
        public
        view
        whenNotPaused
        isNotBlacklisted
        returns (File[] memory)
    {
        uint totalFiles = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalFiles; i++) {
            if (Allfiles[i + 1].uploader == msg.sender) {
                itemCount += 1;
            }
        }

        File[] memory items = new File[](itemCount);
        for (uint i = 0; i < totalFiles; i++) {
            if (Allfiles[i + 1].uploader == msg.sender) {
                uint currentId = Allfiles[i + 1].fileId;
                File storage currentItem = Allfiles[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///@dev function to pause the contract
    function pause() public isMod(msg.sender) {
        _pause();
    }

    ///@dev function to unpause the contract
    function unpause() public isMod(msg.sender) {
        _unpause();
    }

    ///@dev function to blacklist an address
    function addToBlackList(address _addr)
        public
        isMod(msg.sender)
        returns (bool)
    {
        blackListedAddresses[_addr] = true;
        blackList.push(_addr);

        /// @notice emit when a address is blacklisted
        emit addInBlackList(_addr);
        return true;
        
    }

    ///@dev function to remove an address from the blacklist
    function removeFromBlackList(address _addr)
        public
        isMod(msg.sender)
        returns (bool)
    {

          uint index = indexOfblackList[_addr];
         blackList[index] = blackList[blackList.length-1];
        
  blackList.pop();
        blackListedAddresses[_addr] = false;

        /// @notice emit when a address is removed from blacklist
        emit remInBlackList(_addr);
        return true;


    }

 /// @dev function to  fetch only all blacklisted addresses

 function blackListArray()
      public  view
        isMod(msg.sender)
        returns (address[] memory)
    {
        
        return blackList;
    }

     ///@dev function to return an array of  reported Files using fileId
    function reportedListArray()
      public  view
        isMod(msg.sender)
        returns (uint[] memory)
    {
        
        return reportedFiles;
    }

    /// @notice add a new moderator
    function assignMod(address _newMod) public whenNotPaused isMod(msg.sender) {
        moderator[_newMod] = true;

        /// @notice Emit event when a new moderator has been added
        emit AssignMod(msg.sender, _newMod);
    }

    /// @notice remove an existing moderator
    function removeMod(address _mod) public whenNotPaused isMod(msg.sender) {
         moderator[_mod] = false;

        /// @notice Emit event when a moderator has been removed
        emit RemoveMod(msg.sender, _mod);
    }

 /// @dev function to  check if a connected user is a moderatore for mod's features visibility
     function checkMod(address _user) public view whenNotPaused returns(bool){
         bool ismod = moderator[_user];
        return ismod;
        
       
    }

 /// @dev function to  report a file a user
    function report(uint fileId) public {
         require(
            reportExist[fileId] == false,
            "File has been reported earlier."
        );
        reportExist[fileId]= true;
    reportedFiles.push(fileId);
    /// @notice emit when a file is reported
        emit newReport(fileId);
  }

        
    

    function clearReportedFiles(uint fileId) public isMod(msg.sender) {
        /// @notice set status of file to private
        Allfiles[fileId].isPublic = false;
        
        /// @dev increase count of private files
        _itemsPrivate.increment();
        ///@dev empty array of reported files
        delete reportedFiles;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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