//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {VoteContract, VoteAndImplementContract, VotingStatus} from "../voteContract/VoteContract.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error AlreadyVoted(address voter); // TODO: add more fields
error VotingNotAllowed(uint256 voteIndex, address callingContract);

    

uint256 constant BASISPOINTS = 10_000;

struct Parameters {
    uint256 quorum;
    uint256 threshold;
    uint256 deadline;
    IERC20 token;
}

struct Votes {
    uint256 pro;
    uint256 contra;
    uint256 total;   // = pro + contra + abstain
}


contract ThresholdTokenVoteAndImplement is VoteAndImplementContract {

    mapping(address=>mapping(uint256=>Parameters)) internal parameters;
    mapping(address=>mapping(uint256=>Votes)) internal votes;
    mapping(address=>mapping(uint256=>mapping(address=>bool))) internal alreadyVoted;

    // constructor(bytes8 _categoryId)
    // VoteAndImplementContract(_categoryId){}
    // constructor(bytes8 _categoryId, address _registry)
    // VoteAndImplementContract(_categoryId, _registry){}

    function _start(bytes memory votingParams) 
    internal 
    override(VoteAndImplementContract)
    returns(uint256 voteIndex)
    {
        voteIndex = getCurrentVoteIndex(msg.sender);

        // load parameters into variables
        (uint256 quorum,
         uint256 threshold,
         uint256 duration,
         address tokenAddress) = decodeVotingParams(votingParams);

        // check parameter consistence
        require(threshold > quorum, "inconsistent parameters");

        // assign parameters to storage
        parameters[msg.sender][voteIndex].quorum = quorum;
        parameters[msg.sender][voteIndex].threshold = threshold;
        parameters[msg.sender][voteIndex].deadline = block.timestamp + duration;
        parameters[msg.sender][voteIndex].token = IERC20(tokenAddress);
        
    }

    function vote(uint256 voteIndex, address voter, uint256 option) 
    external
    override(VoteAndImplementContract) 
    permitsVoting(voteIndex)
    doubleVotingGuard(voteIndex, voter)
    returns(uint256)
    {
        
        if (condition(voteIndex)==true){
            updateStatus(voteIndex);
            if (votingStatus[msg.sender][voteIndex]==uint256(uint8(VotingStatus.completed))) {
                _implement(voteIndex);
            }
            return votingStatus[msg.sender][voteIndex];
        }

        uint256 weight = parameters[msg.sender][voteIndex].token.balanceOf(voter);
        votes[msg.sender][voteIndex].total += weight;

        if (option==0) {
            votes[msg.sender][voteIndex].pro += weight;
        }
        if (option==1) {
            votes[msg.sender][voteIndex].contra += weight;
        }

        return votingStatus[msg.sender][voteIndex];
        
    }

    function condition(uint voteIndex) internal view override(VoteAndImplementContract) returns(bool) {
        // check whether deadline is over
        return block.timestamp > parameters[msg.sender][voteIndex].deadline;
    }

    function updateStatus(uint256 voteIndex) internal {
        
        // check Quorum
        uint256 totalVotes = votes[msg.sender][voteIndex].total;
        uint256 currentTokenSupply = parameters[msg.sender][voteIndex].token.totalSupply();
        if (totalVotes < (parameters[msg.sender][voteIndex].quorum * currentTokenSupply) / BASISPOINTS) {
            votingStatus[msg.sender][voteIndex] = uint256(uint8(VotingStatus.failed));
            return;
        } 

        // check Majority
        uint256 majorityThreshold = (parameters[msg.sender][voteIndex].threshold * totalVotes) / BASISPOINTS;
        bool moreProThanContra = votes[msg.sender][voteIndex].pro > votes[msg.sender][voteIndex].contra;
        // for simplicity lets assume that 
        bool completed = moreProThanContra && (votes[msg.sender][voteIndex].pro >= majorityThreshold);
        votingStatus[msg.sender][voteIndex] = completed ? uint256(uint8(VotingStatus.completed)) : uint256(uint8(VotingStatus.failed));

    }

    function statusPermitsVoting(uint256 voteIndex) external view override(VoteAndImplementContract) returns(bool) {
        return _statusPermitsVoting(voteIndex);
    }

    function result(uint256 voteIndex) external view override(VoteAndImplementContract) returns(bytes32 votingResult){
        return bytes32(votes[msg.sender][voteIndex].pro);
    }

    function result(address caller, uint256 voteIndex) external view returns(bytes32 votingResult){
        return bytes32(votes[caller][voteIndex].pro);
    }

    function getTotalVotes(uint256 voteIndex) external view returns (uint256) {
        return votes[msg.sender][voteIndex].total;
    }

    function getVotes(uint256 voteIndex) external view returns (uint256 pro, uint256 contra, uint256 abstain) {
        pro = votes[msg.sender][voteIndex].pro;
        contra = votes[msg.sender][voteIndex].contra;
        abstain = votes[msg.sender][voteIndex].total - (pro + contra);
    }

    function getTotalVotes(address caller, uint256 voteIndex) external view returns (uint256) {
        return votes[caller][voteIndex].total;
    }

    function getVotes(address caller, uint256 voteIndex) external view returns (uint256 pro, uint256 contra, uint256 abstain) {
        pro = votes[caller][voteIndex].pro;
        contra = votes[caller][voteIndex].contra;
        abstain = votes[caller][voteIndex].total - (pro + contra);
    }

    function getStatus(address caller, uint256 voteIndex) external view returns (uint256) {
        return votingStatus[caller][voteIndex];
    }

    function getCallbackResponse(address caller, uint256 voteIndex) external view returns(uint8) {
        return uint8(callback[caller][voteIndex].response);
    }
    

    function encodeVotingParams(
        uint256 quorum,
        uint256 threshold,
        uint256 duration,
        address tokenAddress)
    public
    pure 
    returns(bytes memory)
    {
        return abi.encode(quorum,threshold,duration,tokenAddress);
    }

    function decodeVotingParams(
        bytes memory votingParams) 
    public
    pure
    returns(
        uint256 quorum,
        uint256 thresholdInBasisPoints,
        uint256 duration,
        address tokenAddress)
    {
        (quorum,
         thresholdInBasisPoints,
         duration,
         tokenAddress) = abi.decode(votingParams, (uint256,uint256,uint256,address));
    }

    modifier doubleVotingGuard(uint256 voteIndex, address voter) {
        if (alreadyVoted[msg.sender][voteIndex][voter]){
            revert AlreadyVoted(voter);
        }
        _;
        alreadyVoted[msg.sender][voteIndex][voter] = true;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {REGISTRY} from "../registry/RegistryAddress.sol";
import {IVotingRegistry} from "../registry/IVotingRegistry.sol";
import {IVoteContract, IVoteAndImplementContract, Callback, Response} from "./IVoteContract.sol";


error StatusPermitsVoting(address caller, uint256 voteIndex);
error MayOnlyRegisterOnceByDeployer(address caller, bytes8 categoryId);

abstract contract RegisterVoteContract is IERC165 {

    bytes8[] public categories;
    // at some point stop using the registry argument
    function register(bytes8 categoryId)
    external 
    {
        if (categories.length>0){revert MayOnlyRegisterOnceByDeployer(msg.sender, categoryId);}
        IVotingRegistry(REGISTRY).register(categoryId);
        categories.push(categoryId);
    }

    function _addCategoryToRegistration(bytes8 categoryId)
    internal 
    {
        IVotingRegistry(REGISTRY).addCategoryToRegistration(categoryId);
        categories.push(categoryId);
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(IERC165) returns (bool) {
        return 
            interfaceId == type(IVoteContract).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}


enum VotingStatus {inactive, completed, failed, active}

abstract contract VotingStatusHandling{
    // votingStatus:  0 = inactive, 1 = completed, 2 = failed, 3 = active,
    // we deliberately don't use enums that are fixed, because the end user should choose how many statuses there are.
    mapping(address=>mapping(uint256=>uint256)) internal votingStatus; 

    function _statusPermitsVoting(uint256 voteIndex) internal view returns(bool) {
        return votingStatus[msg.sender][voteIndex] >= 3;
    }

    function getCurrentVotingStatus(uint256 voteIndex) public view returns(uint256) {
        return votingStatus[msg.sender][voteIndex];
    }

    modifier permitsVoting(uint256 voteIndex) {
        if (!_statusPermitsVoting(voteIndex)) {
            revert StatusPermitsVoting(msg.sender, voteIndex);
        }
        _;
    }
}


abstract contract VoteContractPrimitive is IERC165, RegisterVoteContract, VotingStatusHandling, IVoteContract {

    mapping(address=>uint256) internal _registeredVotes;

    // constructor(bytes8 _categoryId, address _registry) { 
    //     // _register(_categoryId,_registry);
    // }

    // VOTING PRIMITIVES

    function _start(bytes memory votingParams) 
    internal
    virtual
    returns(uint256 voteIndex)
    {
        votingParams;  // silence compiler warnings.
        return 0;
    }

    function vote(uint256 voteIndex, address voter, uint256 option) external virtual override(IVoteContract) returns(uint256 status);

    function result(uint256 voteIndex) external view virtual override(IVoteContract) returns(bytes32 votingResult);

    function condition(uint voteIndex) internal view virtual returns(bool);

    function statusPermitsVoting(uint256 voteIndex) external view virtual override(IVoteContract) returns(bool);

    function getCurrentVoteIndex(address caller) public view returns(uint256){
        return _registeredVotes[caller];
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(IERC165, RegisterVoteContract) returns (bool) {
        return 
            super.supportsInterface(interfaceId) ||
            interfaceId == type(VoteContract).interfaceId;
    }

    modifier activateNewVote {
        _registeredVotes[msg.sender] += 1;
        _;
        votingStatus[msg.sender][getCurrentVoteIndex(msg.sender)] = uint256(uint8(VotingStatus.active));
    }
    
}

abstract contract VoteContract is IVoteContract, VoteContractPrimitive {
    
    function start(bytes memory votingParams)
    public
    override(IVoteContract) 
    activateNewVote
    returns(uint256 voteIndex) {
        voteIndex = _start(votingParams);
    }

    function _start(bytes memory votingParams) 
    virtual
    internal
    override(VoteContractPrimitive)
    returns(uint256 voteIndex)
    {
        votingParams;  // silence compiler warnings.
        return 0;
    }

    function vote(uint256 voteIndex, address voter, uint256 option) external virtual override(IVoteContract, VoteContractPrimitive) returns (uint256 status);
    
    function result(uint256 voteIndex) external view virtual override(IVoteContract, VoteContractPrimitive) returns(bytes32 votingResult);

    function condition(uint voteIndex) internal view virtual override(VoteContractPrimitive) returns(bool);

    function statusPermitsVoting(uint256 voteIndex) external view virtual override(IVoteContract, VoteContractPrimitive) returns(bool);

}

abstract contract ImplementCallback {

     function _implement(address _contract, Callback memory callback) 
     internal 
     returns(Response)
     {
        (bool success, ) = _contract.call(
            abi.encodePacked(
                callback.selector,
                callback.arguments));
        return success ? Response.successful : Response.failed; 
    }
}

abstract contract VoteAndImplementContract is IVoteContract, VoteContractPrimitive, ImplementCallback, IVoteAndImplementContract {

    mapping(address=>mapping(uint256=>Callback)) internal callback;

    // constructor(bytes8 _categoryId, address _registry) VoteContract(_categoryId, _registry){}

    function _implement(uint256 voteIndex) 
    internal
    {
        callback[msg.sender][voteIndex].response = _implement(msg.sender, callback[msg.sender][voteIndex]);
    }

    function _start(bytes memory votingParams) 
    virtual
    internal
    override(VoteContractPrimitive)
    returns(uint256 voteIndex)
    {
        votingParams;  // silence compiler warnings.
        return 0;
    }

    function start(bytes memory votingParams)
    public
    override(IVoteContract) 
    activateNewVote
    returns(uint256 voteIndex) {
        voteIndex = _start(votingParams);
    }

    function vote(uint256 voteIndex, address voter, uint256 option) external virtual override(IVoteContract, VoteContractPrimitive) returns (uint256 status);
    
    function result(uint256 voteIndex) external view virtual override(IVoteContract, VoteContractPrimitive) returns(bytes32 votingResult);

    function condition(uint voteIndex) internal view virtual override(VoteContractPrimitive) returns(bool);

    function statusPermitsVoting(uint256 voteIndex) external view virtual override(IVoteContract, VoteContractPrimitive) returns(bool);

    function start(
        bytes memory votingParams,
        bytes4 _callbackSelector,
        bytes memory _callbackArgs)
    external
    override(IVoteAndImplementContract) 
    activateNewVote
    returns(uint256 index) {
        index = _start(votingParams);
        callback[msg.sender][index] = Callback({
            selector: _callbackSelector,
            arguments: _callbackArgs,
            response: Response.none});
    }

    function getCallbackResponse(uint256 voteIndex) external view override(IVoteAndImplementContract) returns(uint8) {
        return uint8(callback[msg.sender][voteIndex].response);
    }

    function getCallbackData(uint256 voteIndex) external view override(IVoteAndImplementContract) returns(bytes4 selector, bytes memory arguments) {
        selector = callback[msg.sender][voteIndex].selector;
        arguments = callback[msg.sender][voteIndex].arguments;
    }


    function supportsInterface(bytes4 interfaceId) public pure virtual override(IERC165, VoteContractPrimitive) returns (bool) {
        return 
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IVoteAndImplementContract).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

address constant REGISTRY = 0x5354453d6FA8a3A285aBe7B7b34dadC70AE1a2Fc;

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IVoteContract} from "../voteContract/IVoteContract.sol";



interface IVotingRegistry {

    function register(bytes8 categoryId) external returns(uint256 registrationIndex);
    function isRegistered(address voteContract) external view returns(bool registrationFlag);

    function addCategoryToRegistration(bytes8 categoryId) external;
    function isRegisteredCategory(bytes8 categoryId) external view returns(bool registrationFlag);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

enum Response {none, successful, failed}

struct Callback {
    bytes4 selector;
    bytes arguments;
    Response response;
}

interface IVoteContract is IERC165{
    function start(bytes memory votingParams) external returns(uint256 voteIndex); 

    function vote(uint256 voteIndex, address voter, uint256 option) external returns(uint256 status);

    /**
     * @notice The result can be the casted version of an address, an integer or a pointer to a mapping that contains the entire result.
     */
    function result(uint256 voteIndex) external view returns(bytes32 votingResult);

    function statusPermitsVoting(uint256 voteIndex) external view returns(bool);
}


interface IVoteAndImplementContract is IVoteContract {
    function start(
        bytes memory votingParams,
        bytes4 _callbackSelector,
        bytes memory _callbackArgs)
    external returns(uint256 index); 

    function getCallbackResponse(uint256 voteIndex) external view returns(uint8);

    function getCallbackData(uint256 voteIndex) external view returns(bytes4 selector, bytes memory arguments);
}