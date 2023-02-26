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

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/converter_contract.sol";
import "./nyx_proposals/NyxProposal.sol";
import "./interfaces/INyxProposalHandler.sol";
import "./interfaces/INyxProposalRegistry.sol";

contract NyxProposalHandler is INyxProposalHandler, Ownable {
    string public constant name = "NyxProposalHandler";

    mapping(address => int8) public approvedCallers;

    // Modifers
    ////////////////////
    modifier onlyApproved
    {
        require(approvedCallers[msg.sender] == 1 || msg.sender == owner(), "not approved");
        _;
    }

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

    // Attributes Getters & Setters
    /////////////////////

    function setProposalRegistry(address addr)
        public
        override
        onlyApproved
    {
        registry = NyxProposalRegistry(addr);
    }

    // function getProposalType(uint256 proposalTypeInt)
    //     public view
    //     withProposalRegistrySetted
    //     returns (NyxProposalRegistry.ProposalType memory)
    // {
    //     return registry.proposalTypeMapping(proposalTypeInt);
    // }

    function isApproved(address addr)
        public view
        returns (bool)
    {
        return approvedCallers[addr] == 1;
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

    function setConverterAddress(address addr)
        public
        override
        onlyApproved
    {
        converterContract = Converter(addr);
    }

    // Proposal Conf Utils
    //////////////////////////////

    function bytesToProposalConf(bytes calldata confBytes)
        public view
        returns (ProposalConf memory)
    {
        bytes[] memory confBytesArray = abi.decode(confBytes, (bytes[]));
        return ProposalConf(
            converterContract.bytesToUint(confBytesArray[0]),
            converterContract.bytesToUint(confBytesArray[1]),
            converterContract.bytesToUint(confBytesArray[2]),
            converterContract.bytesToUint(confBytesArray[3]),
            converterContract.bytesToBool(confBytesArray[4]),
            converterContract.bytesToAddress(confBytesArray[5]),
            converterContract.bytesToAddress(confBytesArray[6]),
            converterContract.bytesToBool(confBytesArray[7])
        );
    }

    function createProposalConf(uint256 proposalId, uint256 proposalTypeInt, address author)
        internal view
        returns (ProposalConf memory)
    {
        ProposalConf memory proposalConf = ProposalConf(proposalId, proposalTypeInt, block.timestamp, block.number, false, author, address(0), false);
        return proposalConf;
    }

    function setProposalConf(uint256 proposalTypeInt, uint256 proposalId, ProposalConf calldata proposalConf)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        Proposal storage proposal = proposalMapping[proposalTypeInt][proposalId];
        proposal.conf = proposalConf;
    }

    // Proposal Creators
    /////////////////////

    function createProposal(uint256 proposalTypeInt, bytes[] calldata params, address author)
        public
        override
        onlyApproved withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (uint256)
    {
        uint256 proposalId = numOfProposals[proposalTypeInt]++;
        NyxProposal proposalInterface = registry.proposalHandlerAddresses(proposalTypeInt);
        bytes memory proposalParams = proposalInterface.createProposal(proposalId, params);
        Proposal memory proposal = Proposal(proposalParams, createProposalConf(proposalId, proposalTypeInt, author));
        proposalMapping[proposalTypeInt].push(proposal);
        return proposalId;
    }

    // Proposal Destructor
    /////////////////////

    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        delete proposalMapping[proposalTypeInt][proposalId];
    }

    // Proposal Getters
    ////////////////////////////

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
    
    function getProposals(uint256 proposalTypeInt)
        public view
        override
        withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (bytes[][] memory)
    {   
        NyxProposal proposalHandler = registry.proposalHandlerAddresses(proposalTypeInt);
        Proposal[] memory proposals = proposalMapping[proposalTypeInt];
        bytes[][] memory proposalBytes = new bytes[][](proposals.length);
        for (uint idx = 0; idx < proposals.length; idx++)
        {
            Proposal memory prop = proposals[idx];
            if (prop.params.length != 0)
            {
                proposalBytes[idx] = proposalHandler.getProposal(prop.params);
            }
            else
            {
                proposalBytes[idx] = new bytes[](0);
            }
        }
        return proposalBytes;
    }

    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId)
        public view
        override
        onlyExistingProposalType(proposalTypeInt)
        returns (ProposalConf memory)
    {   
        ProposalConf memory proposalConf = proposalMapping[proposalTypeInt][proposalId].conf;
        return proposalConf;
    }

    function getProposalConfs(uint256 proposalTypeInt)
        public view
        override
        onlyExistingProposalType(proposalTypeInt)
        returns (ProposalConf[] memory)
    {   
        Proposal[] memory proposals = proposalMapping[proposalTypeInt];
        ProposalConf[] memory proposalsConf = new ProposalConf[](proposals.length);
        for (uint idx = 0; idx < proposals.length; idx++)
        {
            Proposal memory prop = proposals[idx];
            proposalsConf[idx] = prop.conf;
        }
        return proposalsConf;
    }

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
    
    function getProposalReadables(uint256 proposalTypeInt)
        public view
        override
        withProposalRegistrySetted onlyExistingProposalType(proposalTypeInt)
        returns (ProposalReadable[] memory)
    {   
        NyxProposal proposalHandler = registry.proposalHandlerAddresses(proposalTypeInt);
        Proposal[] memory proposals = proposalMapping[proposalTypeInt];
        ProposalReadable[] memory proposalsReadable = new ProposalReadable[](proposals.length);
        for (uint idx = 0; idx < proposals.length; idx++)
        {
            Proposal memory prop = proposals[idx];
            if (prop.params.length != 0)
            {
                proposalsReadable[idx] = ProposalReadable(proposalHandler.getProposal(prop.params), prop.conf);
            }
            else
            {
                proposalsReadable[idx] = ProposalReadable(new bytes[](0), prop.conf);
            }
        }
        return proposalsReadable;
    }
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

abstract contract INyxProposalRegistry
{
    struct ProposalType
    {
        uint256 id;
        string name;
        address contract_address;
    }

    uint256 public numOfProposalTypes;
    mapping(uint256 => ProposalType) public proposalTypeMapping;
    mapping(uint256 => NyxProposal) public proposalHandlerAddresses;

    function getProposalType(uint256 proposalTypeint) public view virtual returns(ProposalType memory);
    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr) external virtual;
    function setProposalContractAddress(uint256 proposalTypeInt, address addr) external virtual;
    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName) external virtual;
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

import "../nyx_proposals/NyxProposal.sol";
import "../NyxProposalRegistry.sol";
import "./INyxProposalRegistry.sol";

abstract contract INyxProposalHandler
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

    // uint256 public numOfProposalTypes;
    mapping(uint256 => uint256) public numOfProposals;
    // mapping(uint256 => ProposalType) public proposalTypeMapping;
    // mapping(uint256 => NyxProposal) public proposalHandlerAddresses;
    mapping(uint256 => Proposal[]) public proposalMapping;
    Converter converterContract = Converter(0xB23e433BD8B53Ce077b91A831F80167272337e15);
    NyxProposalRegistry registry;

    function setProposalRegistry(address addr) public virtual;
    // function getProposalType(uint256 proposalTypeint) public view virtual returns(INyxProposalRegistry.ProposalType memory);
    // function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr) external virtual;
    function setConverterAddress(address addr) external virtual;
    // function setProposalContractAddress(uint256 proposalTypeInt, address addr) external virtual;
    // function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName) external virtual;
    function getProposalConf(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns(ProposalConf memory);
    function setProposalConf(uint256 proposalTypeInt, uint256 proposalId, ProposalConf calldata proposalConf) public virtual;
    function createProposal(uint256 proposalTypeInt, bytes[] calldata params, address author) public virtual returns(uint256);
    function getProposal(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (bytes[] memory);
    function getProposals(uint256 proposalTypeInt) public view virtual returns (bytes[][] memory);
    function getProposalReadable(uint256 proposalTypeInt, uint256 proposalId) public view virtual returns (ProposalReadable memory);
    function getProposalReadables(uint256 proposalTypeInt) public view virtual returns (ProposalReadable[] memory);
    function getProposalConfs(uint256 proposalTypeInt) public view virtual returns (ProposalConf[] memory);
    function deleteProposal(uint256 proposalTypeInt, uint256 proposalId) public virtual;
    // function settleProposal(uint256 proposalTypeInt, uint256 proposalId) public virtual;
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
import "../../utils/converter_contract.sol";

abstract contract NyxProposal is Converter {
    // Proposal Creators
    /////////////////////

    function createProposal(uint256 proposalId, bytes[] memory params) external virtual pure returns (bytes memory);
    
    // Proposal Getters
    /////////////////////
    function getProposal(bytes memory proposalBytes) external virtual pure returns (bytes[] memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
import "./nyx_proposals/NyxProposal.sol";
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
        proposalTypeMapping[0] = ProposalType(0, "None", address(0));
        proposalHandlerAddresses[0] = NyxProposal(address(0));
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

    function addProposalType(string calldata proposalTypeName, address proposalHandlerAddr)
        public
        override
        onlyApproved
    {
        uint256 proposalTypeId = ++numOfProposalTypes;
        proposalTypeMapping[proposalTypeId] = ProposalType(proposalTypeId, proposalTypeName, proposalHandlerAddr);
        proposalHandlerAddresses[proposalTypeId] = NyxProposal(proposalHandlerAddr);
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

    function setProposalContractAddress(uint256 proposalTypeInt, address addr)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        proposalHandlerAddresses[proposalTypeInt] = NyxProposal(addr);
        proposalTypeMapping[proposalTypeInt].contract_address = addr;
    }

    function setProposalTypeName(uint256 proposalTypeInt, string calldata newProposalTypeName)
        public
        override
        onlyApproved onlyExistingProposalType(proposalTypeInt)
    {
        ProposalType storage proposalType = proposalTypeMapping[proposalTypeInt];
        proposalType.name = newProposalTypeName;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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