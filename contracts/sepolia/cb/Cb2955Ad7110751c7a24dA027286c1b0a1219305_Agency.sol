pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "./AgentNFT.sol";
import "./TransferHelper.sol";

/// @title Referral system contract
/// @notice If a user deposits in DysonPair and has registered in referral system,
/// he will get extra Dyson token as reward.
/// Each user in the referral system is an `Agent`.
/// Referral of a agent is called the `child` of the agent.
contract Agency {
    using TransferHelper for address;

    bytes32 public constant REGISTER_ONCE_TYPEHASH = keccak256("register(address child)"); // onceSig
    bytes32 public constant REGISTER_PARENT_TYPEHASH = keccak256("register(address once,uint deadline,uint price)"); // parentSig
    /// @notice Max number of children, i.e., referrals, per agent
    /// Note that this limit is not forced on root agent
    uint constant MAX_NUM_CHILDREN = 3;
    /// @notice Amount of time a new agent have to wait before he can refer a new user
    uint constant REGISTER_DELAY = 4 hours;
    
    AgentNFT public immutable agentNFT;

    /// @dev For EIP-2612 permit
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @member owner Owner of the agent data
    /// @member gen Agent's generation in the referral system
    /// @member birth Timestamp when the agent registerred in the referral system
    /// @member parentId Id of the agent's parent, i.e., it's referrer
    /// @member childrenId Ids of the agent's children, i.e., referrals

    struct Agent {
        address owner;
        uint gen;
        uint birth;
        uint parentId;
        uint[] childrenId;
    }

    address public owner;
    /// @notice Number of users in the referral system
    uint public totalSupply;

    /// @notice User's id in the referral system
    /// Param is User's address
    mapping(address => uint) public whois;
    /// @notice User's agent
    /// Param is User's id in the referral system
    mapping(uint => Agent) internal agents;
    /// @notice Record if an invite code has been used
    mapping(address => bool) public oneTimeCodes;
    /// @notice Record if a hash has been presigned by an address
    mapping(address => mapping(bytes32 => bool)) public presign;

    event TransferOwnership(address newOwner);
    event Register(uint indexed referrer, uint referee);
    event Sign(address indexed signer, bytes32 digest);

    constructor(address _owner, address root) {
        require(_owner != address(0), "INVALID_OWNER");
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Dyson Agency")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));

        owner = _owner;

        AgentNFT _agentNFT = new AgentNFT(address(this));
        agentNFT = _agentNFT;
        // Initialize root
        uint id = ++totalSupply; // root agent has id 1
        whois[root] = id;
        Agent storage rootAgent = agents[id];
        rootAgent.owner = root;
        rootAgent.birth = block.timestamp;
        rootAgent.parentId = id; // root agent's parent is also root agent itself
        _agentNFT.onMint(root, id);
        emit Register(id, id);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FORBIDDEN");
        _;
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        owner = _owner;

        emit TransferOwnership(_owner);
    }

    /// @notice rescue token stucked in this contract
    /// @param tokenAddress Address of token to be rescued
    /// @param to Address that will receive token
    /// @param amount Amount of token to be rescued
    function rescueERC20(address tokenAddress, address to, uint256 amount) onlyOwner external {
        tokenAddress.safeTransfer(to, amount);
    }

    /// @notice Add new child agent to root agent. This child will have the privilege of being a 1st generation agent.
    /// This function can only be executed by `owner`.
    /// @param newUser User of the new agent
    /// @return id Id of the new agent
    function adminAdd(address newUser) onlyOwner external returns (uint id) {
        require(whois[newUser] == 0, "OCCUPIED");
        id = _newAgent(newUser, 1);
    }

    /// @notice Transfer agent data to another user
    /// Can not transfer to a user who already has an agent.
    /// @param from previous owner of the agent
    /// @param to User who will receive the agent
    /// @param id index of the agent to be transfered
    /// @return True if transfer succeed
    function transfer(address from, address to, uint id) external returns (bool) {
        require(msg.sender == address(agentNFT), "FORBIDDEN");
        require(to != address(0), "TRANSFER_INVALID_ADDRESS");
        require(id != 0, "NOTHING_TO_TRANSFER");
        require(id == whois[from], "FORBIDDEN");
        Agent storage agent = agents[id];
        require(whois[to] == 0, "OCCUPIED");
        agent.owner = to;
        whois[to] = id;
        whois[from] = 0;
        return true;
    }

    /// @dev Create new `Agent` data and update the link between the agent and it's parent agent
    function _newAgent(address _owner, uint parentId) internal returns (uint id) {
        require(_owner != address(0), "NEW_AGENT_INVALID_ADDRESS");
        id = ++totalSupply;
        whois[_owner] = id;
        Agent storage parent = agents[parentId];
        Agent storage child = agents[id];
        parent.childrenId.push(id);
        child.owner = _owner;
        child.gen = parent.gen + 1;
        child.birth = block.timestamp;
        child.parentId = parentId;
        agentNFT.onMint(_owner, id);
        emit Register(parentId, id);
    }

    function _getHashTypedData(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    /// @notice User register in the referral system by providing an one time invite code: `onceSig`
    /// and his referrer's signature: `parentSig`.
    /// User can not register if he already has an agent.
    /// User can not register if the referrer already has maximum number of child agents.
    /// User can not register if the referrer is new and has not passed the register delay
    /// @notice If the referral code is presigned, use parent's address for parentSig
    /// @param parentSig Referrer's signature or referrer's address
    /// @param onceSig Invite code
    /// @param deadline Deadline of the invite code, set by the referrer
    /// @return id Id of the new agent
    function register(bytes memory parentSig, bytes memory onceSig, uint deadline) payable external returns (uint id) {
        require(block.timestamp < deadline, "EXCEED_DEADLINE");
        require(whois[msg.sender] == 0, "ALREADY_REGISTERED");

        bytes32 onceSigDigest = _getHashTypedData(keccak256(abi.encode(
            REGISTER_ONCE_TYPEHASH,
            msg.sender
        )));
        address once = _ecrecover(onceSigDigest, onceSig);
        require(once != address(0), "INVALID_ONCE_SIG");
        require(oneTimeCodes[once] == false, "SIGNATURE_IS_USED");

        bytes32 parentSigDigest = _getHashTypedData(keccak256(abi.encode(
            REGISTER_PARENT_TYPEHASH,
            once,
            deadline,
            msg.value
        )));
        address _parent;
        if(parentSig.length == 65) {
            _parent = _ecrecover(parentSigDigest, parentSig);
        }
        else if(parentSig.length == 20) {
            assembly {
                _parent := mload(add(parentSig, 20))
            }
            require(presign[_parent][parentSigDigest], "INVALID_PARENT_SIG");
        }
        require(_parent != address(0), "INVALID_PARENT_SIG");

        uint parentId = whois[_parent];
        require(parentId != 0, "INVALID_PARENT");
        Agent storage parent = agents[parentId];
        require(parent.childrenId.length < MAX_NUM_CHILDREN, "NO_EMPTY_SLOT");
        require(parent.birth + REGISTER_DELAY <= block.timestamp, "NOT_READY");

        id = _newAgent(msg.sender, parentId);
        oneTimeCodes[once] = true;
        if(msg.value > 0) {
            _parent.safeTransferETH(msg.value);
        }
    }

    /// @dev parent do onchain presign for a referral code
    function sign(bytes32 digest) external {
        presign[msg.sender][digest] = true;
        emit Sign(msg.sender, digest);
    }

    function getHashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _getHashTypedData(structHash);
    }

    /// @notice User's agent data
    /// @param _owner User's address
    /// @return ref Parent agent's owner address
    /// @return gen Generation of user's agent
    function userInfo(address _owner) external view returns (address ref, uint gen) {
        Agent storage agent = agents[whois[_owner]];
        ref = agents[agent.parentId].owner;
        gen = agent.gen;
    }

    /// @notice Get agent data by user's id
    /// @param id Id of the user
    /// @return User's agent data
    function getAgent(uint id) external view returns (address, uint, uint, uint, uint[] memory) {
        Agent storage agent = agents[id];
        return(agent.owner, agent.gen, agent.birth, agent.parentId, agent.childrenId);
    }

    function _ecrecover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }

            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                return address(0);
            } else if (v != 27 && v != 28) {
                return address(0);
            } else {
                return ecrecover(hash, v, r, s);
            }
        } else {
            return address(0);
        }
    }

}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "interfaces/IAgency.sol";

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

/**
* @title ERC721 token receiver interface
* @dev Interface for any contract that wants to support safeTransfers
* from ERC721 asset contracts.
*/
interface IERC721Receiver {
    function onERC721Received(address, address, uint, bytes calldata) external returns (bytes4);
}

contract AgentNFT {
    IAgency public immutable agency;

    /// @dev ERC165 interface ID of ERC165
    bytes4 private constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    /// @dev ERC165 interface ID of ERC721
    bytes4 private constant ERC721_INTERFACE_ID = 0x80ac58cd;
    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 private constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @dev Get the approved address for a single NFT.
    mapping(uint => address) public getApproved;
    /// @dev Checks if an address is an approved operator. 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /**
    * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    */
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    /**
    * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    */
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    /**
    * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(address _agency) {
        agency = IAgency(_agency);
    }

    /**
    * @dev Interface identification is specified in ERC-165.
    * @param interfaceID Id of the interface
    */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return (interfaceID == ERC165_INTERFACE_ID ||
                interfaceID == ERC721_INTERFACE_ID ||
                interfaceID == ERC721_METADATA_INTERFACE_ID);
    }

    function name() external pure returns (string memory) {
        return "Dyson Agent";
    }

    function symbol() external pure returns (string memory) {
        return "DAG";
    }

    function tokenURI(uint tokenId) external view returns (string memory) {
        (address owner, uint tier, uint birth, uint parent,) = agency.getAgent(tokenId);
        require(owner != address(0), "TOKEN_NOT_EXIST");
        return _tokenURI(tokenId, parent, tier, birth);
    }

    function _tokenURI(uint tokenId, uint parent, uint tier, uint birth) internal pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output = string(abi.encodePacked(output, "token ", _toString(tokenId), '</text><text x="10" y="40" class="base">'));
        output = string(abi.encodePacked(output, "referer ", _toString(parent), '</text><text x="10" y="60" class="base">'));
        output = string(abi.encodePacked(output, "agent_tier ", _toString(tier), '</text><text x="10" y="80" class="base">'));
        output = string(abi.encodePacked(output, "time_of_creation ", _toString(birth), '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Agent #', _toString(tokenId), '", "description": "Dyson Finance Agent NFT", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function totalSupply() external view returns (uint) {
        return agency.totalSupply();
    }

    function balanceOf(address owner) external view returns (uint balance) {
        return agency.whois(owner) == 0 ? 0 : 1;
    }

    function ownerOf(uint tokenId) public view returns (address owner) {
        (owner,,,,) = agency.getAgent(tokenId);
    }

    function onMint(address user, uint tokenId) external {
        require(msg.sender == address(agency), "FORBIDDEN");
        emit Transfer(address(0), user, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external {
        safeTransferFrom(from, to, tokenId, '');
    }

    function approve(address to, uint tokenId) external {
        address owner = ownerOf(tokenId);
        // Throws if `tokenId` is not a valid NFT
        require(owner != address(0), "TOKEN_NOT_EXIST");
        // Check requirements
        require(owner == msg.sender || isApprovedForAll[owner][msg.sender], "FORBIDDEN");
        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "SELF_APPROVAL");
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _transferFrom(
        address from,
        address to,
        uint tokenId,
        address sender
    ) internal {
        require(from == sender || isApprovedForAll[from][sender] || getApproved[tokenId] == sender, "FORBIDDEN");

        getApproved[tokenId] = address(0);

        require(agency.transfer(from, to, tokenId), "FORBIDDEN");

        emit Transfer(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external {
        _transferFrom(from, to, tokenId, msg.sender);
    }

    function _isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) public {
        _transferFrom(from, to, tokenId, msg.sender);

        if (_isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "Transfer Failed");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IAgency {
    function whois(address agent) external view returns (uint);
    function userInfo(address agent) external view returns (address ref, uint gen);
    function transfer(address from, address to, uint id) external returns (bool);
    function totalSupply() external view returns (uint);
    function getAgent(uint id) external view returns (address, uint, uint, uint, uint[] memory);
    function adminAdd(address newUser) external returns (uint id);
}