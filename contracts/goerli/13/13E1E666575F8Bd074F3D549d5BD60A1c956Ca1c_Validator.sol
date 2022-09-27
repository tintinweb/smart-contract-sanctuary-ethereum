/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|                                                                                                                                                                                                                                           
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 < 0.9.0;
import "../contracts/interfaces/UserInterface.sol";

contract Validator {
    
    address private ctOwner;

    /* @dev Throws if called by any account other than the owner.*/
    modifier onlyOwner() {
        require(msg.sender != ctOwner, "Sender should be Contract Creator");
        _;
    }
    
    /**
     * @dev Struct that implements Validator.
     */
    struct ValidatorEntry{
        string nodeId;
        string nodeUrl;
        bool created;
    }
    
    mapping(string => ValidatorEntry) ve;
    
    uint count = 0;
    
    /**
     * @dev Emits when entry is added in validator.
     */
    event SetNode (string nodeId, string nodeUrl, address indexed _from, uint count);
    event UpdateNode (string nodeId, string nodeUrl);
    
    /**
     * @dev creates node entry
     * @param nodeId - Node Id
     * @param nodeUrl - Node URL
     */
    function setNode(string memory nodeId, string memory nodeUrl) public onlyOwner returns(string memory){
        require(ve[nodeId].created == false, "Node Id already exists");
        require(bytes (nodeId).length > 0, "Node Id Cannot be Blank");
        require(bytes (nodeUrl).length > 0, "Node URL Cannot be blank");
        ve[nodeId].nodeId = nodeId; 
        ve[nodeId].nodeUrl = nodeUrl;
        ve[nodeId].created = true;
        count++;
        emit SetNode (nodeId, nodeUrl, msg.sender, count);
        return nodeId;
    }

    /**
     * @dev Updates node entry
     * @param nodeId - Node Id
     * @param nodeUrl - Node URL
     */
    function updateNode(string memory nodeId, string memory nodeUrl) public onlyOwner {
        require(bytes (nodeId).length > 0, "Node Id Cannot be Blank");
        require(bytes (nodeUrl).length > 0, "Node URL Cannot be blank");
        require(ve[nodeId].created == true, "Node Id does not exist");
        ve[nodeId].nodeUrl = nodeUrl;
        emit UpdateNode(nodeId, nodeUrl);
    }

    /**
     * @dev Validates node 
     * @param nodeId - Node Id
     * @param userAddr - User address
     * @param requestId - Request Id by user
     * @param report - Query result
     */
    function validateNode (string memory nodeId, address userAddr, string memory requestId, string memory report) public onlyOwner{
        require(ve[nodeId].created == true, "INVALID NODE");
        UserInterface ui = UserInterface(userAddr);
        ui.onReceiveApi(requestId, report);
    }
    
    /**
     * @dev Returns node URL from node Id
     * @param nodeId - node id
     */
    function getNode(string memory nodeId) public view returns(string memory id, string memory nodeUrl){
        require(ve[nodeId].created == true, "Node Id does not exist");
        return (nodeId, ve[nodeId].nodeUrl);
    }
    
    /**
     * @dev Returns count of nodes
     */
    function getNodeCount() public view returns(uint){
        return count;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 < 0.9.0;

interface UserInterface {
    function onReceiveApi(string memory requestId, string memory report) external;
}