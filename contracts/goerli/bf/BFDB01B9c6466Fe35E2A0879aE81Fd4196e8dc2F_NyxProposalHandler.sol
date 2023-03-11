// SPDX-License-Identifier: MIT

// @title NyxProposalHandler for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "./interfaces/INyxProposalHandler.sol";

contract NyxProposalHandler is INyxProposalHandler {
    string public constant name = "NyxProposalHandler";

    // Attributes Getters & Setters
    /////////////////////

    /**
    * @notice Set the proposal registry contract, used to map 
    * proposal types to their implementation contract
    */
    function setProposalRegistry(address addr)
        public
        override
        onlyApprovedOrOwner(msg.sender)
    {
        registry = NyxProposalRegistry(addr);
    }

    /**
    * @notice Set the converter address, used to make various cast
    * between types
    */
    function setConverterAddress(address addr)
        public
        override
        onlyApprovedOrOwner(msg.sender)
    {
        converterContract = Converter(addr);
    }

    // Proposal Conf Utils
    //////////////////////////////

    // function bytesToProposalConf(bytes calldata confBytes)
    //     public view
    //     returns (ProposalConf memory)
    // {
    //     bytes[] memory confBytesArray = abi.decode(confBytes, (bytes[]));
    //     return ProposalConf(
    //         converterContract.bytesToUint(confBytesArray[0]),
    //         converterContract.bytesToUint(confBytesArray[1]),
    //         converterContract.bytesToUint(confBytesArray[2]),
    //         converterContract.bytesToUint(confBytesArray[3]),
    //         converterContract.bytesToBool(confBytesArray[4]),
    //         converterContract.bytesToAddress(confBytesArray[5]),
    //         converterContract.bytesToAddress(confBytesArray[6]),
    //         converterContract.bytesToBool(confBytesArray[7])
    //     );
    // }

    /**
    * @notice create the Proposal Configuration object for a
    * given <proposalTypeInt>, <proposalId> and <author>
    */
    function createProposalConf(uint256 proposalTypeInt, uint256 proposalId, address author)
        internal view
        returns (ProposalConf memory)
    {
        ProposalConf memory proposalConf = ProposalConf(proposalId, proposalTypeInt, block.timestamp, block.number, false, author, address(0), false);
        return proposalConf;
    }

    /**
    * @notice store a given <proposalConf> into proposalMapping
    */
    function setProposalConf(ProposalConf calldata proposalConf)
        external
        override
        onlyApprovedOrOwner(msg.sender) onlyExistingProposalType(proposalConf.proposalTypeInt)
    {
        Proposal storage proposal = proposalMapping[proposalConf.proposalTypeInt][proposalConf.id];
        proposal.conf = proposalConf;
    }

    // Proposal Creators
    /////////////////////

    /**
    * @notice create a Proposal object, for a given <proposalTypeInt>, <params> and <author>
    * and store it into proposalMapping
    */
    function createProposal(uint256 proposalTypeInt, bytes[] calldata params, address author)
        public
        override
        onlyApprovedOrOwner(msg.sender) withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (uint256)
    {
        uint256 proposalId = numOfProposals[proposalTypeInt]++;
        NyxProposal proposalInterface = registry.proposalHandlerAddresses(proposalTypeInt);
        bytes memory proposalParams = proposalInterface.createProposal(proposalId, params);
        Proposal memory proposal = Proposal(proposalParams, createProposalConf(proposalTypeInt, proposalId, author));
        // proposalMapping[proposalTypeInt].push(proposal);
        proposalMapping[proposalTypeInt][proposalId] = proposal;

        emit CreatedProposal(author, proposalTypeInt, proposalId);

        return proposalId;
    }

    // Proposal Destructor
    /////////////////////

    /**
    * @notice delete the given <proposalTypeInt>, <proposalId> existing Proposal
    *  object from proposalMapping
    */
    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId)
        public
        override    
        onlyApprovedOrOwner(msg.sender) onlyExistingProposalType(proposalTypeInt)
    {
        delete proposalMapping[proposalTypeInt][proposalId];

        emit DeletedProposal(proposalTypeInt, proposalId);
    }

    // Proposal Getters
    ////////////////////////////

    /**
    * @notice get the Proposal object of given <proposalTypeInt> and <proposalId>
    */
    function getProposal(uint256 proposalTypeInt, uint256 proposalId)
        public view
        override
        withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (bytes[] memory)
    {   
        NyxProposal proposalHandler = registry.proposalHandlerAddresses(proposalTypeInt);
        Proposal memory proposal = proposalMapping[proposalTypeInt][proposalId];

        bytes[] memory proposalBytes;
        if (proposal.params.length != 0)
        {
            proposalBytes = proposalHandler.getProposal(proposal.params);
        }
        else
        {
            proposalBytes = new bytes[](0);
        }
        
        return proposalBytes;
    }
    
    /**
    * @notice get all existing Proposal objects of given <proposalTypeInt>
    */
    function getProposals(uint256 proposalTypeInt)
        public view
        override
        withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (bytes[][] memory)
    {   
        NyxProposal proposalHandler = registry.proposalHandlerAddresses(proposalTypeInt);
        bytes[][] memory proposalBytes = new bytes[][](numOfProposals[proposalTypeInt]);
        for (uint idx = 0; idx < proposalBytes.length;)
        {
            Proposal memory prop = proposalMapping[proposalTypeInt][idx];
            if (prop.params.length != 0)
            {
                proposalBytes[idx] = proposalHandler.getProposal(prop.params);
            }
            else
            {
                proposalBytes[idx] = new bytes[](0);
            }
            unchecked { idx++; }
        }
        return proposalBytes;
    }

    /**
    * @notice get the Proposal Configuration object of given <proposalTypeInt> and <proposalId>
    */
    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId)
        external view
        override
        onlyExistingProposalType(proposalTypeInt)
        returns (ProposalConf memory)
    {   
        ProposalConf memory proposalConf = proposalMapping[proposalTypeInt][proposalId].conf;
        return proposalConf;
    }

    /**
    * @notice get all existing Proposal Configuration objects of given <proposalTypeInt>
    */
    function getProposalConfs(uint256 proposalTypeInt)
        public view
        override
        onlyExistingProposalType(proposalTypeInt)
        returns (ProposalConf[] memory)
    {   
        ProposalConf[] memory proposalsConf = new ProposalConf[](numOfProposals[proposalTypeInt]);
        for (uint idx = 0; idx < proposalsConf.length; idx++)
        {
            Proposal memory prop = proposalMapping[proposalTypeInt][idx];
            proposalsConf[idx] = prop.conf;
        }
        return proposalsConf;
    }

    /**
    * @notice get the Proposal Readable object of given <proposalTypeInt> and <proposalId>
    */
    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId)
        public view
        override
        withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (ProposalReadable memory)
    {   
        NyxProposal proposalHandler = registry.proposalHandlerAddresses(proposalTypeInt);
        Proposal memory proposal = proposalMapping[proposalTypeInt][proposalId];
        
        ProposalReadable memory proposalsReadable;
        if (proposal.params.length != 0)
        {
            proposalsReadable = ProposalReadable(proposalHandler.getProposal(proposal.params), proposal.conf);
        }
        else
        {
            proposalsReadable = ProposalReadable(new bytes[](0), proposal.conf);
        }
        
        return proposalsReadable;
    }
    
    /**
    * @notice get all existing Proposal Readable objects of given <proposalTypeInt>
    */
    function getProposalReadables(uint256 proposalTypeInt)
        public view
        override
        withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (ProposalReadable[] memory)
    {   
        NyxProposal proposalHandler = registry.proposalHandlerAddresses(proposalTypeInt);
        ProposalReadable[] memory proposalsReadable = new ProposalReadable[](numOfProposals[proposalTypeInt]);
        for (uint idx = 0; idx < proposalsReadable.length; )
        {
            Proposal memory prop = proposalMapping[proposalTypeInt][idx];
            if (prop.params.length != 0)
            {
                proposalsReadable[idx] = ProposalReadable(proposalHandler.getProposal(prop.params), prop.conf);
            }
            else
            {
                proposalsReadable[idx] = ProposalReadable(new bytes[](0), prop.conf);
            }
            unchecked { idx++; }
        }
        return proposalsReadable;
    }
}

// SPDX-License-Identifier: MIT

// @title INyxProposalHandler for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "nyx_dao/nyx_proposals/NyxProposal.sol";
import "nyx_dao/NyxProposalRegistry.sol";
import "utils/Converter.sol";
import "nyx_dao/NyxRoleManager.sol";

abstract contract INyxProposalHandler is Ownable, NyxRoleManager
{
    // Enums
    ////////////////////
    // enum ProposalType{Investment, Revenue, Governance, Allocation, Free, WL, Representative, Quorum, SendToken, Mint, Redeem}

    // Structs
    ////////////////////
    struct Proposal
    {
        bytes params;
        ProposalConf conf;
    }

    struct ProposalReadable
    {
        bytes[] params;
        ProposalConf conf;
    }

    struct ProposalConf
    {
        uint256 id;
        uint256 proposalTypeInt;
        uint256 creationTime;
        uint256 creationBlock;
        bool settled;
        address proposer;
        address settledBy;
        bool approved;
    }

    // Attributes
    ////////////////////
    mapping(uint256 => uint256) public numOfProposals;
    // mapping(uint256 => Proposal[]) public proposalMapping;
    mapping(uint256 => mapping(uint256 => Proposal)) public proposalMapping;

    Converter converterContract = Converter(0xB23e433BD8B53Ce077b91A831F80167272337e15);
    NyxProposalRegistry registry;

    // Modifiers
    ////////////////////
    modifier withProposalRegistrySetted()
    {
        require(address(registry) != address(0), "ProposalRegistry have to be setted");
        _;
    }

    modifier onlyExistingProposalType(uint256 proposalTypeInt)
    {
        require(proposalTypeInt > 0, "proposalType id have to be > 0");
        require(proposalTypeInt <= registry.numOfProposalTypes(), "proposalType doesn't exists");
        _;
    }

    // Functions
    ////////////////////
    function setProposalRegistry(address addr) public virtual;
    function setConverterAddress(address addr) external virtual;
    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId) external view virtual returns(ProposalConf memory);
    function setProposalConf(ProposalConf calldata proposalConf) external virtual;
    function createProposal(uint256 proposalTypeInt, bytes[] calldata params, address author) public virtual returns(uint256);
    function getProposal(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (bytes[] memory);
    function getProposals(uint256 proposalTypeInt) public view virtual returns (bytes[][] memory);
    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (ProposalReadable memory);
    function getProposalReadables(uint256 proposalTypeInt) public view virtual returns (ProposalReadable[] memory);
    function getProposalConfs(uint256 proposalTypeInt) external view virtual returns (ProposalConf[] memory);
    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId) public virtual;

    // Events
    ///////////////////
    event CreatedProposal(address indexed proposer, uint256 proposalType, uint256 proposalId);
    event DeletedProposal(uint256 proposalType, uint256 proposalId);
}

// SPDX-License-Identifier: MIT

// @title NyxRoleManager for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "./interfaces/INyxRoleManager.sol";

contract NyxRoleManager is INyxRoleManager {
    // string public constant name = "NyxRoleManager";

    // Main Functions
    ///////////////////////
    function isApproved(address addr)
        public view
        override
        returns (bool)
    {
        return approvedCallers[addr] == 1;
    }

    function toggleApprovedCaller(address addr)
        external
        override
        onlyOwner
    {
        if (approvedCallers[addr] == 1)
        {
            approvedCallers[addr] = 0;
        }
        else

        {
            approvedCallers[addr] = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

// @title INyxDAO for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "./IConverter.sol";

contract Converter is IConverter {
    function stringToBytes(string memory str)
        public pure
        returns (bytes memory)
    {
        return bytes(str);
    }

    function bytesToString(bytes memory strBytes)
        public pure
        returns (string memory)
    {
        return string(strBytes);
    }

    function stringArrayToBytesArray(string[] memory strArray)
        public pure
        returns (bytes[] memory)
    {
        bytes[] memory bytesArray = new bytes[](strArray.length);
        for (uint256 idx = 0; idx < strArray.length; idx++)
        {
            bytes memory bytesElem = bytes(strArray[idx]);
            bytesArray[idx] = bytesElem;
        }
        return bytesArray;
    }

    function bytesArrayToStringAray(bytes[] memory bytesArray)
        public pure
        returns (string[] memory)
    {
        string[] memory strArray = new string[](bytesArray.length);
        for (uint256 idx = 0; idx < bytesArray.length; idx++)
        {
            string memory strElem = string(bytesArray[idx]);
            strArray[idx] = strElem;
        }
        return strArray;
    }

    function intToBytes(int256 i)
        public pure
        returns (bytes memory)
    {
        return abi.encodePacked(i);
    }

    function bytesToUint(bytes memory iBytes)
        public pure
        returns (uint256)
    {
        uint256 i;
        for (uint idx = 0; idx < iBytes.length; idx++)
        {
            i = i + uint(uint8(iBytes[idx])) * (2**(8 * (iBytes.length - (idx + 1))));
        }
        return i;
    }

    // function addressToBytes(address addr)
    //     public pure
    //     returns (bytes memory)
    // {
    //     return bytes(bytes8(uint64(uint160(addr))));
    // }

    function bytesToAddress(bytes memory addrBytes)
        public pure
        returns (address)
    {
        address addr;
        assembly
        {
            addr := mload(add(addrBytes,20))
        }
        return addr;
    }

    function bytesToBool(bytes memory boolBytes)
        public pure
        returns (bool)
    {
        return abi.decode(boolBytes, (bool));
    }

    function boolToBytes(bool b)
        public pure
        returns (bytes memory)
    {
        return abi.encode(b);
    }
}

// SPDX-License-Identifier: MIT

// @title NyxProposalRegistry for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INyxProposalRegistry.sol";

contract NyxProposalRegistry is INyxProposalRegistry, Ownable {
    string public constant name = "NyxProposalRegistry";

    // Enums
    ////////////////////
    // enum ProposalType{Investment, Revenue, Governance, Allocation, Free, WL, Representative, Quorum, SendToken, Mint, Redeem}

    // Structs
    ////////////////////
    mapping(address => int8) public approvedCallers;

    // Constructor
    ////////////////////
    constructor()
    {
        proposalTypeMapping[0] = ProposalType(0, "None", address(0), address(0));
        proposalHandlerAddresses[0] = NyxProposal(address(0));
        proposalSettlerAddresses[0] = NyxProposalSettler(address(0));
    }

    // Modifers
    ////////////////////
    modifier onlyApproved
    {
        require(approvedCallers[msg.sender] == 1 || msg.sender == owner(), "not approved");
        _;
    }

    modifier onlyExistingProposalType(uint256 proposalTypeInt)
    {
        require(proposalTypeInt > 0, "proposalType id have to be > 0");
        require(proposalTypeInt <= numOfProposalTypes, "proposalType doesn't exists");
        _;
    }

    // Attributes Getters & Setters
    /////////////////////

    function getProposalType(uint256 proposalTypeInt)
        public view
        override
        returns (ProposalType memory)
    {
        return proposalTypeMapping[proposalTypeInt];
    }

    function isApproved(address addr)
        public view
        returns (bool)
    {
        return approvedCallers[addr] == 1;
    }

    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr, address proposalSettlerAddr)
        public
        override
        onlyApproved
    {
        uint256 proposalTypeId = ++numOfProposalTypes;
        proposalTypeMapping[proposalTypeId] = ProposalType(proposalTypeId, proposalTypeName, proposalHandlerAddr, proposalSettlerAddr);
        proposalHandlerAddresses[proposalTypeId] = NyxProposal(proposalHandlerAddr);
        proposalSettlerAddresses[proposalTypeId] = NyxProposalSettler(proposalSettlerAddr);
    }

    function toggleApprovedCaller(address addr)
        external
        onlyOwner
    {
        if (approvedCallers[addr] == 1)
        {
            approvedCallers[addr] = 0;
        }
        else
        
        {
            approvedCallers[addr] = 1;
        }
    }

    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        ProposalType storage proposalType = proposalTypeMapping[proposalTypeInt];
        proposalType.name = newProposalTypeName;
    }

    function setProposalContractAddress(uint256 proposalTypeInt, address addr)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        proposalHandlerAddresses[proposalTypeInt] = NyxProposal(addr);
        proposalTypeMapping[proposalTypeInt].contract_address = addr;
    }

    function setProposalSettlerAddress(uint256 proposalTypeInt, address addr)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        proposalSettlerAddresses[proposalTypeInt] = NyxProposalSettler(addr);
        proposalTypeMapping[proposalTypeInt].settler_address = addr;
    }
}

// SPDX-License-Identifier: MIT

// @title NyxProposal for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "utils/Converter.sol";

abstract contract NyxProposal is Converter {
    // Proposal Creators
    /////////////////////

    function createProposal(uint256 proposalId, bytes[] memory params) external virtual pure returns (bytes memory);
    
    // Proposal Getters
    /////////////////////
    function getProposal(bytes memory proposalBytes) external virtual pure returns (bytes[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

// @title IConverter for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity ^0.8.0;

interface IConverter
{
    function stringToBytes(string memory str) external pure returns (bytes memory);
    function bytesToString(bytes memory strBytes) external pure returns (string memory);
    function stringArrayToBytesArray(string[] memory strArray) external pure returns (bytes[] memory);
    function bytesArrayToStringAray(bytes[] memory bytesArray) external pure returns (string[] memory);
    function intToBytes(int256 i) external pure returns (bytes memory);
    function bytesToUint(bytes memory iBytes) external pure returns (uint256);
    function bytesToAddress(bytes memory addrBytes) external pure returns (address);
    function bytesToBool(bytes memory boolBytes) external pure returns (bool);
    function boolToBytes(bool b) external pure returns (bytes memory);
}

// SPDX-License-Identifier: MIT

// @title INyxRoleManager for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract INyxRoleManager is Ownable
{
    // Attributes
    ////////////////////
    mapping(address => int8) public approvedCallers;

    // Modifiers
    ////////////////////
    modifier onlyApprovedOrOwner(address addr)
    {
        require(approvedCallers[addr] == 1 || addr == owner(), "Caller is not approved nor owner");
        _;
    }
    
    modifier onlyApproved(address addr)
    {
        require(approvedCallers[addr] == 1, "Caller is not approved");
        _;
    }

    // Functions
    ////////////////////
    function isApproved(address addr) public view virtual returns (bool);
    function toggleApprovedCaller(address addr) external virtual;
}

// SPDX-License-Identifier: MIT

// @title INyxProposalRegistry for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|                       

pragma solidity >=0.8.0;

import "../nyx_proposals/NyxProposal.sol";
import "../nyx_proposals_settlers/NyxProposalSettler.sol";

abstract contract INyxProposalRegistry
{
    struct ProposalType
    {
        uint256 id;
        string name;
        address contract_address;
        address settler_address;
    }

    uint256 public numOfProposalTypes;
    mapping(uint256 => ProposalType) public proposalTypeMapping;
    mapping(uint256 => NyxProposal) public proposalHandlerAddresses;
    mapping(uint256 => NyxProposalSettler) public proposalSettlerAddresses;

    function getProposalType(uint256 proposalTypeint) public view virtual returns(ProposalType memory);
    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr, address proposalSettlerAddr) external virtual;
    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName) external virtual;
    function setProposalContractAddress(uint256 proposalTypeInt, address addr) external virtual;
    function setProposalSettlerAddress(uint256 proposalTypeInt, address addr) external virtual;
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

// SPDX-License-Identifier: MIT

// @title NyxProposal for Nyx DAO
// @author TheV

//  ________       ___    ___ ___    ___      ________  ________  ________     
// |\   ___  \    |\  \  /  /|\  \  /  /|    |\   ___ \|\   __  \|\   __  \    
// \ \  \\ \  \   \ \  \/  / | \  \/  / /    \ \  \_|\ \ \  \|\  \ \  \|\  \   
//  \ \  \\ \  \   \ \    / / \ \    / /      \ \  \ \\ \ \   __  \ \  \\\  \  
//   \ \  \\ \  \   \/  /  /   /     \/        \ \  \_\\ \ \  \ \  \ \  \\\  \ 
//    \ \__\\ \__\__/  / /    /  /\   \         \ \_______\ \__\ \__\ \_______\
//     \|__| \|__|\___/ /    /__/ /\ __\         \|_______|\|__|\|__|\|_______|
//               \|___|/     |__|/ \|__|       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "utils/Converter.sol";
import "nyx_dao/nyx_proposals/NyxProposal.sol";
// import "../interfaces/INyxDao.sol";

abstract contract NyxProposalSettler is Ownable, Converter {
    // INyxDAO dao;
    // NyxNFT nft;

    // modifier withDAOSetted()
    // {
    //     require(address(dao) != address(0), "you have to set dao contract first");
    //     _;
    // }

    // modifier withNFTSetted()
    // {
    //     require(address(nft) != address(0), "you have to set dao contract first");
    //     _;
    // }

    // modifier withApprovedByNFT(address addr)
    // {
    //     require(nft.approved(addr), "you have to set dao contract first");
    //     _;
    // }

    function settleProposal(bytes[] calldata params) public virtual returns(bool);
}