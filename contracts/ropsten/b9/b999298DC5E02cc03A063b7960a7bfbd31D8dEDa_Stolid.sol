/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: contracts/1_Storage.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Stolid is Pausable {
    
    constructor() {
        
        chiefJustice = msg.sender;
    }


    function pause() public onlyChiefJustice {
        _pause();
    }

    function unpause() public onlyChiefJustice {
        _unpause();
    }

    

    uint fileId;

    address public chiefJustice;

    uint exhibitId;

    mapping(uint => CaseFile) public allCaseFiles;

    mapping(address => bool) public judges;

    mapping(address => bool) public registrars;

    modifier onlyRegistrars(address _user) {
        bool isRegistrar = registrars[_user];
        require(isRegistrar, "Only Registrars Have Access!");
        _;
    }

    modifier onlyChiefJustice() {
        require(
            msg.sender == chiefJustice,
            "Only The Chief Justice Have Access!"
        );
        _;
    }
    struct CaseFile {
        uint id;
        string caseId;
        string fileHash;
        address judge;
        address clerk;
        bool active;
        string[] caseExhibits;
    }

    event CaseCreated(address indexed creator, string caseId, uint time);
    event CaseEnded(address indexed judge, string caseId, uint time);

    function createCase(
        string memory _caseId,
        string memory _fileHash,
        address _judge,
        address _clerk,
        string[] calldata _exhibits
    ) public whenNotPaused {
        require(
            registrars[msg.sender] || msg.sender == chiefJustice,
            "only Registrars and chief Justices can create files"
        );
        require(bytes(_caseId).length > 0, "invalid case ID");
        require(bytes(_fileHash).length > 0, "invalid FIle");
        require(_judge != address(0), "invalid contract address");
        require(_clerk != address(0), "invalid contract address");
        require(_exhibits.length > 0, " please attach exhibit(s)");

        fileId++;

        allCaseFiles[fileId] = CaseFile(
            fileId,
            _caseId,
            _fileHash,
            _judge,
            _clerk,
            true,
            _exhibits
        );

        emit CaseCreated(msg.sender, _caseId, block.timestamp);
    }

    function addExhibits(string[] calldata _exhibit, uint _id)
        public
        whenNotPaused
    {
        require(
            allCaseFiles[_id].active,
            "you cannot manipulate a closed case"
        );
        require(
            msg.sender == allCaseFiles[_id].judge ||
                msg.sender == allCaseFiles[_id].clerk,
            "only assigned judge or clerk can add exhibits"
        );
        for (uint i = 0; i < _exhibit.length; i++) {
            allCaseFiles[_id].caseExhibits.push(_exhibit[i]);
        }
    }

    function updateCase(uint _id, string memory _filehash)
        public
        whenNotPaused
    {
        require(
            allCaseFiles[_id].active,
            "you cannot manipulate a closed case"
        );
        require(
            msg.sender == allCaseFiles[_id].judge ||
                msg.sender == allCaseFiles[_id].clerk,
            "only assigned judge or clerk can add exhibits"
        );

        allCaseFiles[_id].fileHash = _filehash;
    }

    function reassignCase(
        uint _id,
        address newJudge,
        address newClerk
    ) public whenNotPaused onlyChiefJustice {
        allCaseFiles[_id].judge = newJudge;
        allCaseFiles[_id].clerk = newClerk;
    }

    function endCase(uint _id) public whenNotPaused {
        require(
            allCaseFiles[_id].active,
            "you cannot manipulate a closed case"
        );
        require(
            msg.sender == allCaseFiles[_id].judge,
            "only assigned judge can close case"
        );

        allCaseFiles[_id].active = false;

        emit CaseEnded(msg.sender, allCaseFiles[_id].caseId, block.timestamp);
    }

    function addRegistrar(address newRegistrar)
        public
        whenNotPaused
        onlyChiefJustice
    {
        registrars[newRegistrar] = true;
    }

    function removeRegistrar(address _registrar)
        public
        whenNotPaused
        onlyChiefJustice
    {
        registrars[_registrar] = false;
    }

    /// @notice remove an existing moderator
    function removeChiefJustice(address newChiefJustice)
        public
        whenNotPaused
        onlyChiefJustice
    {
        chiefJustice = newChiefJustice;
    }

    function closedCases() public view returns (CaseFile[] memory) {
        uint currentIndex = 0;

        CaseFile[] memory closed = new CaseFile[](fileId);
        for (uint i = 0; i < fileId; i++) {
            if (allCaseFiles[i + 1].active == false) {
                uint currentId = allCaseFiles[i + 1].id;
                CaseFile storage currentCase = allCaseFiles[currentId];
                closed[currentIndex] = currentCase;
                currentIndex += 1;
            }
        }
        return closed;
    }

    function caseAssignedToJudge() public view returns (CaseFile[] memory) {
        uint currentIndex = 0;
        CaseFile[] memory cases = new CaseFile[](fileId);
        for (uint i = 0; i < fileId; i++) {
            if (allCaseFiles[i + 1].active == true) {
                if (allCaseFiles[i + 1].judge == msg.sender) {
                    uint currentId = allCaseFiles[i + 1].id;
                    CaseFile storage currentCase = allCaseFiles[currentId];
                    cases[currentIndex] = currentCase;
                    currentIndex += 1;
                }
            }
        }
        return cases;
    }

    function caseAssignedToClerk() public view returns (CaseFile[] memory) {
        uint currentIndex = 0;
        CaseFile[] memory cases = new CaseFile[](fileId);
        for (uint i = 0; i < fileId; i++) {
            if (allCaseFiles[i + 1].active == true) {
                if (allCaseFiles[i + 1].clerk == msg.sender) {
                    uint currentId = allCaseFiles[i + 1].id;
                    CaseFile storage currentCase = allCaseFiles[currentId];
                    cases[currentIndex] = currentCase;
                    currentIndex += 1;
                }
            }
        }
        return cases;
    }
}