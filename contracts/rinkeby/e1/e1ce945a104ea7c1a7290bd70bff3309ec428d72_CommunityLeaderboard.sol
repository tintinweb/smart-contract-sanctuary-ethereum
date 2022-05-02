/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

//SPDX-License-Identifier: MIT

/// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/lib/BasicMetaTransaction.sol

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BasicMetaTransaction {

    using SafeMath for uint256;

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) nonces;

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(address userAddress, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {

        require(verify(userAddress, nonces[userAddress], getChainID(), functionSignature, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successfull");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function getNonce(address user) public view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function verify(address owner, uint256 nonce, uint256 chainID, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public view returns (bool) {

        bytes32 hash = prefixed(keccak256(abi.encodePacked(nonce, this, chainID, functionSignature)));
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
		return (owner == signer);
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            return msg.sender;
        }
    }
}

// File: contracts/abstractions/Ownable.sol



pragma solidity ^0.8.0;
// ****** Meta-Gas

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
    Remove gsn context import "../GSN/Context.sol"; swapped _msgSender to msgSender for biconomy
    owner is now payable and is not private. - jgonzalez
    changed any owner setting to payable(newowner) casting
    renounceOwnership - removed jgonzalez
 */
abstract contract Ownable is BasicMetaTransaction {
    address payable _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msgSender();
        _owner = payable(msgSender);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msgSender(), "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = payable(newOwner);
    }
}

// File: contracts/CommunityLeaderboard.sol


pragma solidity ^0.8.0;



contract CommunityLeaderboard is Ownable {
    using SafeMath for uint256;

    //----------------------------------------------------------------------------------------------------------------------
    //Events: 


    //func - registerProject - added to for subgraph               
    event projectRegistser(
        address indexed _from,
        address indexed _nftContract,
        string _name,
        uint256 projectCount,
        uint256 numberOfLeaderboards
    );

    //func - addOwnerToProject - change
    event projectOwnerAdd(
        uint256 _projectId,
        address indexed _newOwner
    );

    //func - createLeaderboardNftRequired - added to for subgraph     
    event createNftRequiredLeaderboard(
        address indexed _from, 
       string  _leaderboardName,
       uint256  _projectId, 
       uint256  leaderBoardId, 
       uint256 leaderboardCount,
       uint256 epoch, 
       bool nftRequired,
       uint256 _nftsRequired
    );

    //func - createLeaderboardOpen - added to for subgraph                 
    event createOpenLeaderboard(
        address indexed _from,
        string _leaderboardName,
        uint256  _projectId, 
        uint256  leaderBoardId,
        uint256 leaderboardCount, 
        uint256 epoch, 
        bool nftRequired
    );

    //func - archiveAndResetLeaderboard
    event achriveResetLeaderboard(
        uint256  _projectId,
        uint256  _leaderboardId
    );

    //funce - castVote - added to for subgraph 
    event voteCast(
        uint256 _projectId,
        uint256 _leaderboardId,
        address indexed _member, 
        uint256 _nftTokenId,
        uint256 indexed voters,
        uint256 numberOfVotes,
        address indexed _from 
        
    );

    //func - changeVote
    event voteChange(
        uint256 _projectId,
        uint256 _leaderboardId,
        address indexed _member,
        address indexed _newMember
    );

    //----------------------------------------------------------------------------------------------------------------------
    
    struct Project {
        mapping(address => bool) owners; //Owner(s) stored
        mapping(address => uint256) voterToVoteCount; //added
        address nftContract;
        string name;
        uint256 projectId;
        uint256 numberOfLeaderboards;
        address[] ownersArr; //added - owners of project not nft contract! 
    }

    struct MemberRow{
        uint256 numberOfVotes;
        address[] voters; // may have 0x addresses, which indicates a changed/deleted vote
        mapping(address => uint256) addressToIndex;
        // mapping(address => bool) voterToHasVoted;
    }


    struct Leaderboard {
        string name;
        uint256 projectId;
        uint256 leaderBoardId;
        uint256 leaderboardCount; // How many leaderboards have been archived
        uint256 epoch; 
        uint256 blockStart;
        uint256 blockEnd; 
        bool nftRequired;
        uint256 numberOfNftsRequired;
        address[] members; // Addresses that have received votes (used to iterate), make sure to not have duplicates
        address[] voters;
         

        mapping(address => MemberRow) rows;
        mapping(address => bool) voterToHasVoted;     
    }


    //-----------------------------------------------------------------------------------------------------------------------
    //Mappings and storage

    uint256 public projectCount = 0;
    uint256[] public projectIds;
    mapping(uint256 => Project) public projectIdToProject; 
    // mapping(uint256 => Leaderboard[]) public projectIdToLeaderboards;
    mapping(uint256 => mapping(uint256 => Leaderboard)) public projectIdToLeaderboardIdToLeaderboard; //Owner address is pulled 
    mapping(uint256 => mapping(uint256 => Leaderboard[])) public leaderboardArchive;


    mapping(address => uint256[]) public voterVotes;  //added 

    function getLeaderboard(uint256 _projectId, uint256 _leaderboardId) 
        external 
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        ) 

    {
        Leaderboard storage leaderboard = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId];
        return (
            leaderboard.name,
            leaderboard.projectId,
            leaderboard.leaderBoardId,
            leaderboard.leaderboardCount,
            leaderboard.epoch,
            leaderboard.blockStart,
            leaderboard.blockEnd,
            leaderboard.nftRequired,
            leaderboard.numberOfNftsRequired
        );

    }

        function getProjectName(uint256 _projectId) external view returns (string memory) {
        return projectIdToProject[_projectId].name;

    }

    //----------------------------------------------------------------------------------------------------------------------------
    //Getter functions
    

    //added
    function getProjectOwners(uint256 _projectId) external view returns (address[] memory) {
        return projectIdToProject[_projectId].ownersArr;
    }
     function getProjectOwnersLength(uint256 _projectId) external view returns (uint256) {
        return projectIdToProject[_projectId].ownersArr.length;
    }

    //added - voters who have voted in the leaderboard
    function getvoters(uint256 _projectId, uint256 _leaderboardId) external view returns (address[] memory) {
        return projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voters; 
    }

    //number of votes casted from voter
    function getvoterParticipation(uint256 _projectId, address _user) external view returns (uint256) {
        return projectIdToProject[_projectId].voterToVoteCount[_user]; 
    }


    //added - gets every id of a leaderboard a user has voted on | leaderboards voter has voted on
    function getvoterVotes (address _user) external view returns (uint256[] memory) {
        return voterVotes[_user];
    }
    
    
    function getProjectLeaderboardCount(uint256 _projectId) external view returns (uint256) {
        return projectIdToProject[_projectId].numberOfLeaderboards;
    }

    function getLeaderboardName(uint256 _projectId, uint256 _leaderboardId) external view returns (string memory) {
        return projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].name;
    }

    function getLeaderboardMemberLength(uint256 _projectId, uint256 _leaderboardId) external view returns (uint256) {
        return projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].members.length;
    }

    function getLeaderboardMemberAddress(uint256 _projectId, uint256 _leaderboardId, uint256 _memberId) external view returns (address) {
        return projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].members[_memberId];
    }

    function getLeaderboardMemberVoteCount(uint256 _projectId, uint256 _leaderboardId, uint256 _memberId) external view returns (uint256) {
        return projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].rows[projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].members[_memberId]].numberOfVotes;
    }
    
    function registerProject(address _nftContract, string memory _name) public {
        // Verify that the person calling function is owner of NFT contract
        // address nftContractOwner = IERC721(_nftContract).owner(); // REMOVE FOR TESTING
        // require(nftContractOwner == msg.sender, "You do not own this NFT contract."); // REMOVE FOR TESTING

        // Create new project and add it to mapping
        Project storage newProject = projectIdToProject[projectCount];
        newProject.owners[msg.sender] = true;
        newProject.nftContract = _nftContract;
        newProject.name = _name;
        newProject.projectId = projectCount;
        newProject.numberOfLeaderboards = 0;

        projectCount = projectCount.add(1);

        emit projectRegistser(msg.sender, _nftContract, _name, newProject.projectId, newProject.numberOfLeaderboards);
    }

    //call in mappings
    function addOwnerToProject(uint256 _projectId, address _newOwner) public {
        require(projectIdToProject[_projectId].owners[msg.sender] == true, "You are not an owner of this project.");
        projectIdToProject[_projectId].owners[_newOwner] = true;
        projectIdToProject[_projectId].ownersArr.push(_newOwner); //added

        emit projectOwnerAdd(_projectId, _newOwner);
    }

    function createLeaderboardNftRequired(uint256 _projectId, string memory _leaderboardName, uint256 _time, uint256 _nftsRequired) public {
        require(projectIdToProject[_projectId].owners[msg.sender] == true, "You are not an owner of this project.");

        Leaderboard storage newLeaderboard = projectIdToLeaderboardIdToLeaderboard[_projectId][projectIdToProject[_projectId].numberOfLeaderboards];
        newLeaderboard.name = _leaderboardName;
        newLeaderboard.projectId = _projectId;
        newLeaderboard.leaderBoardId = projectIdToProject[_projectId].numberOfLeaderboards;
        newLeaderboard.leaderboardCount = 0;
        newLeaderboard.epoch = _time;  
        newLeaderboard.blockStart = block.number;   
        newLeaderboard.blockEnd = block.number + _time; 
        newLeaderboard.nftRequired = true;
        newLeaderboard.numberOfNftsRequired = _nftsRequired;

        projectIdToProject[_projectId].numberOfLeaderboards = projectIdToProject[_projectId].numberOfLeaderboards.add(1);

        emit createNftRequiredLeaderboard(msg.sender, _leaderboardName, _projectId, newLeaderboard.leaderBoardId, newLeaderboard.leaderboardCount, newLeaderboard.epoch, newLeaderboard.nftRequired, _nftsRequired);
    }

    function createLeaderboardOpen(uint256 _projectId, string memory _leaderboardName, uint256 _time) public {
        require(projectIdToProject[_projectId].owners[msg.sender] == true, "You are not an owner of this project.");

        Leaderboard storage newLeaderboard = projectIdToLeaderboardIdToLeaderboard[_projectId][projectIdToProject[_projectId].numberOfLeaderboards];
        newLeaderboard.name = _leaderboardName;
        newLeaderboard.projectId = _projectId;
        newLeaderboard.leaderBoardId = projectIdToProject[_projectId].numberOfLeaderboards;
        newLeaderboard.leaderboardCount = 0;
        newLeaderboard.epoch = _time;
        newLeaderboard.blockStart = block.number;
        newLeaderboard.blockEnd = block.number + _time;
        newLeaderboard.nftRequired = false;

        projectIdToProject[_projectId].numberOfLeaderboards = projectIdToProject[_projectId].numberOfLeaderboards.add(1);

        emit createOpenLeaderboard(msg.sender, _leaderboardName, _projectId, newLeaderboard.leaderBoardId, newLeaderboard.leaderboardCount, newLeaderboard.epoch, newLeaderboard.nftRequired);
    }

    function archiveAndResetLeaderboard(uint256 _projectId, uint256 _leaderboardId) internal {
        Leaderboard storage leaderboardArchived = leaderboardArchive[_projectId][_leaderboardId][projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].leaderboardCount];
        leaderboardArchived = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId];
        // leaderboardArchive[_projectId][_leaderboardId][projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].leaderboardCount] = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId];

        
        Leaderboard storage leaderboardNew = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId];
        leaderboardNew.leaderboardCount = leaderboardNew.leaderboardCount.add(1);
        leaderboardNew.blockStart = block.number;
        leaderboardNew.blockEnd = block.number + leaderboardNew.epoch;
        delete leaderboardNew.members;
        
        // Need to iterate through both mappings and reset each entry
        address[] memory members = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].members;
        for (uint256 i = 0; i < members.length; i++) {
            delete projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].rows[members[i]];
            // If delete does not properly erase addressToIndex mapping, will need to use loop below, need to test
            /* address[] memory rowVoters = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].rows[members[i]].voters;
            for (uint256 j = 0; j < rowVoters.length; j++) {
                projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].rows[members[i]].addressToIndex[rowVoters[j]] = 0;
            } */
        }
        address[] memory voters = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voters;
        for (uint256 i = 0; i < voters.length; i++) {
            projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voterToHasVoted[voters[i]] = false;
        }

        emit achriveResetLeaderboard(_projectId, _leaderboardId);
    }

    function castVote(uint256 _projectId, uint256 _leaderboardId, address _member, uint256 _nftTokenId) public {
        require(projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].epoch != 0, "This leaderboard does not exist.");

        // address nftOwner = IERC721(projectIdToProject[_projectId].nftContract).ownerOf(_nftTokenId); // REMOVE FOR TESTING
        // require(nftOwner == msg.sender, "You do not own the NFT based on the token ID provided."); // REMOVE FOR TESTING

        if (projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].blockEnd <= block.number) {
            archiveAndResetLeaderboard(_projectId, _leaderboardId);
        }

        require(projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voterToHasVoted[msg.sender] == false, "You have already voted on this leaderboard.");

        projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voterToHasVoted[msg.sender] = true;
        projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voters.push(msg.sender);


        //added - pushes leaderboard id into global mappings
        if(projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voterToHasVoted[msg.sender] == false) {
            voterVotes[msg.sender].push(_leaderboardId);
        }

        //added - Adds 1 to voter participation within a project
        projectIdToProject[_projectId].voterToVoteCount[msg.sender] = projectIdToProject[_projectId].voterToVoteCount[msg.sender].add(1);



        MemberRow storage member = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].rows[_member];
        member.addressToIndex[msg.sender] = member.voters.length; // is there better way than using voters.length?
        member.voters.push(msg.sender);
        member.numberOfVotes = member.numberOfVotes.add(1);

        if (member.numberOfVotes == 0) {
            projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].members.push(_member);
        }

        emit voteCast(_projectId, _leaderboardId, _member, _nftTokenId, member.voters.length, member.numberOfVotes, msg.sender);
    }

    function changeVote(uint256 _projectId, uint256 _leaderboardId, address _member, address _newMember) public {
        require(projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].voterToHasVoted[msg.sender] == true, "You have not voted on this leaderboard.");
        require(_member != _newMember, "Cannot change vote to the same member.");

        MemberRow storage member = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].rows[_member];
        /*
        for (uint256 i = 0; i < member.voters.length; i++) {
            if (member.voters[i] == msg.sender) {
                delete member.voters[i];
                break;
            }
        }
        */
        delete member.voters[member.addressToIndex[msg.sender]];
        delete member.addressToIndex[msg.sender];
        member.numberOfVotes = member.numberOfVotes.sub(1);

        MemberRow storage newMember = projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].rows[_newMember];
        newMember.voters.push(msg.sender);
        newMember.numberOfVotes = member.numberOfVotes.add(1);

        if (newMember.numberOfVotes == 0) {
            projectIdToLeaderboardIdToLeaderboard[_projectId][_leaderboardId].members.push(_newMember);
        }

        emit voteChange(_projectId, _leaderboardId, _member, _newMember);
    }

}