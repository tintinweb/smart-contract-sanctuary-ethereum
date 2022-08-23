pragma solidity 0.8.6;
// pragma experimental ABIEncoderV2;

import "IJellyAccessControls.sol";

/**
 * @title Standard implementation of ERC1643 Document management
 */
contract JellyDocuments {

    struct Document {
        uint32 docIndex;    // Store the document name indexes
        uint64 lastModified; // Timestamp at which document details was last modified
        string data; // data of the document that exist off-chain
    }

    // mapping to store the documents details in the document
    mapping(address => mapping(string => Document)) internal _documents;
    // mapping to store the document name indexes
    mapping(address => mapping(string => uint32)) internal _docIndexes;
    // Array use to store all the document name present in the contracts
    mapping(address => string[]) _docNames;

    /// @notice Whether contract has been initialised or not.
    bool private initialised;

    /// @notice Address that manages approvals.
    IJellyAccessControls public accessControls;

    /**
     * @dev Init function.
     * @param _accessControls Access controls interface.
     */
    function initJellyDocuments(
        address _accessControls
    ) public 
    {
        require(!initialised, "Already initialised");
        require(_accessControls != address(0), "Access controls not set");
        accessControls = IJellyAccessControls(_accessControls);
        initialised = true;
    }

    // Document Events
    event DocumentRemoved(address indexed _contractAddr, string indexed _name, string _data);
    event DocumentUpdated(address indexed _contractAddr, string indexed _name, string _data);

    /**
     * @notice Admin can set key value pairs for UI.
     * @param _name Document key.
     * @param _data Document value.
     */
    function setDocument(address _contractAddr, string calldata _name, string calldata _data) external {
        require(
            accessControls.hasAdminRole(msg.sender) || msg.sender == _contractAddr,
            "setDocument: Sender must be admin or contract"
        );
        _setDocument(_contractAddr, _name, _data);
    }

    function setDocuments(address _contractAddr, string[] calldata _name, string[] calldata _data) external {
        require(
            accessControls.hasAdminRole(msg.sender) || msg.sender == _contractAddr,
            "setDocument: Sender must be admin or contract"
        );
        uint256 numDocs = _name.length;
        for (uint256 i = 0; i < numDocs; i++) {
            _setDocument(_contractAddr, _name[i], _data[i]);
        }
    }

    function removeDocument(address _contractAddr, string calldata _name) external {
        require(
            accessControls.hasAdminRole(msg.sender) || msg.sender == _contractAddr,
            "setDocument: Sender must be admin"
        );
        _removeDocument(_contractAddr, _name);
    }

    /**
     * @notice Used to attach a new document to the contract, or update the data or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _contractAddr Address of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _data Off-chain data of the document from where it is accessible to investors/advisors to read.
     */
    function _setDocument(address _contractAddr, string calldata _name, string calldata _data) internal {
        require(_isContract(_contractAddr));
        require(bytes(_name).length > 0); // dev: Zero name is not allowed
        require(bytes(_data).length > 0); // dev: Zero data is not allowed
        Document storage document = _documents[_contractAddr][_name];
        string[] storage docNames = _docNames[_contractAddr];
        if (document.lastModified == uint64(0)) {
            docNames.push(_name);
            document.docIndex = uint32(docNames.length);
        }

        document.docIndex = document.docIndex;
        document.lastModified = uint64(block.timestamp);
        document.data = _data;
        emit DocumentUpdated(_contractAddr, _name, _data);
    }


    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _contractAddr Address of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function _removeDocument(address _contractAddr, string calldata _name) internal {
        Document memory document = _documents[_contractAddr][_name];
        string[] storage docNames = _docNames[_contractAddr];
        require(document.lastModified != uint64(0)); // dev: Document should exist
        uint32 index = document.docIndex - 1;
        if (index != docNames.length - 1) {
            docNames[index] = docNames[docNames.length - 1];
            _documents[_contractAddr][docNames[index]].docIndex = index + 1; 
        }
        docNames.pop();
        emit DocumentRemoved(_contractAddr, _name, document.data);
        delete _documents[_contractAddr][_name];
    }

    /**
     * @notice Used to return the details of a document with a known name (`string`).
     * @param _contractAddr Address of the contract.
     * @param _name Name of the document
     * @return string The data associated with the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(address _contractAddr, string calldata _name) external view returns (string memory, uint256) {
        Document memory document = _documents[_contractAddr][_name];
        return (document.data, uint256(document.lastModified));
    }

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @param _contractAddr Address of the contract.
     * @return string List of all documents names present in the contract.
     */
    function getAllDocuments(address _contractAddr) external view returns (string[] memory) {
        return _docNames[_contractAddr];
    }

    /**
     * @notice Used to retrieve the total documents in the smart contract.
     * @param _contractAddr Address of the contract.
     * @return uint256 Count of the document names present in the contract.
     */
    function getDocumentCount(address _contractAddr) external view returns (uint256) {
        return _docNames[_contractAddr].length;
    }

    /**
     * @notice Used to retrieve the document name from index in the smart contract.
     * @return string Name of the document name.
     */
    function getDocumentName(address _contractAddr, uint256 _index) external view returns (string memory) {
        require(_index < _docNames[_contractAddr].length); // dev: Index out of bounds
        return _docNames[_contractAddr][_index];
    }


    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}

pragma solidity 0.8.6;

interface IJellyAccessControls {
    function hasAdminRole(address _address) external  view returns (bool);
    function addAdminRole(address _address) external;
    function removeAdminRole(address _address) external;
    function hasMinterRole(address _address) external  view returns (bool);
    function addMinterRole(address _address) external;
    function removeMinterRole(address _address) external;
    function hasOperatorRole(address _address) external  view returns (bool);
    function addOperatorRole(address _address) external;
    function removeOperatorRole(address _address) external;
    function initAccessControls(address _admin) external ;

}