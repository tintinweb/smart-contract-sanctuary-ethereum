// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IENSTogetherNFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDefaultResolver {
    function name(bytes32 node) external view returns (string memory);
}

interface IReverseRegistrar {
    function node(address addr) external view returns (bytes32);
    function defaultResolver() external view returns (IDefaultResolver);
}

contract ENSTogether is ReentrancyGuard, Ownable {
    IReverseRegistrar ensReverseRegistrar;
    IENSTogetherNFT ensTogetherNFT;

    // address public nftContract;
    uint256 public cost = 0.08 ether;
    uint256 public updateStatusCost = 0.04 ether;
    //it will be longer, 5m is just for testing
    uint256 public timeToRespond = 1 weeks;
    uint256 public proposalsCounter = 0;
    uint256 public registryCounter = 0;

    //Relationship Status
    enum Proposal {
        NOTHING,
        PENDING,
        ACCEPTED,
        DECLINED
    }
    Proposal proposalStatus;
    enum Status {
        NOTHING,
        TOGETHER,
        PAUSED,
        SEPARATED
    }
    Status relationshipStatus;

    struct Union {
        address to;
        uint8 proposalStatus;
        address from;
        uint8 relationshipStatus;
        uint256 proposalNumber;
        uint256 registryNumber;
        uint256 createdAt;
        bool expired;
    }

    mapping(address => Union) public unionWith;

    constructor(address ensReverseRegistrar_) {
        ensReverseRegistrar = IReverseRegistrar(ensReverseRegistrar_);
    }

    //PROPOSAL EVENTS
    event ProposalSubmitted(address indexed to, address indexed from);
    event ProposalResponded(
        address indexed to,
        address indexed from,
        uint256 indexed _status
    );
    event ProposalCancelled(address indexed to, address indexed from);
    //UNION EVENTS
    event GotUnited(
        address indexed from,
        address indexed to,
        uint256 indexed _timestamp,
        uint256 _registrationNumber
    );
    event UnionStatusUpdated(
        address indexed from,
        address indexed to,
        uint256 _status,
        uint256 indexed _timestamp
    );
    //ERRORS
    error SenderPendingProposal();
    error ReceiverPendingProposal();
    //BURNED
    event Burned(uint256 id, bool);

    function propose(address _to) external payable {
        require(msg.value == cost, "Insufficient amount");
        require(_to != msg.sender, "Can't registry with yourself as a partner");
        //revert if msg.sender is already united
        require(
            unionWith[msg.sender].relationshipStatus == uint8(Status.NOTHING) ||
                unionWith[msg.sender].relationshipStatus ==
                uint8(Status.SEPARATED),
            "You are already united"
        );
        //avoid proposals to a person already in a relationship
        require(
            unionWith[_to].relationshipStatus == uint8(Status.NOTHING) ||
                unionWith[_to].expired == true,
            "This address is already in a relationship"
        );
        //Check if both addresses have an ENS name
        string memory ensFrom = lookupENSName(msg.sender);
        string memory ensTo = lookupENSName(_to);
        require(bytes(ensFrom).length > 0, "Sender doesn't have ENS name");
        require(
            bytes(ensTo).length > 0,
            "The address you're proposing to doesnt have ENS name"
        );
        // Revert if sender sent a proposal and its not expired or receiver has a pending not expired proposal
        if (
            unionWith[msg.sender].to != address(0) &&
            block.timestamp < unionWith[msg.sender].createdAt + timeToRespond &&
            unionWith[msg.sender].expired == false
        ) {
            revert SenderPendingProposal();
        } else if (
            unionWith[_to].proposalStatus == uint8(Proposal.PENDING) &&
            block.timestamp < unionWith[_to].createdAt + timeToRespond
        ) {
            revert ReceiverPendingProposal();
        } else {
            Union memory request;
            request.to = _to;
            request.from = msg.sender;
            request.createdAt = block.timestamp;
            request.proposalNumber = proposalsCounter;
            request.proposalStatus = uint8(Proposal.PENDING);
            unionWith[_to] = request;
            unionWith[msg.sender] = request;
            proposalsCounter++;
        }
        emit ProposalSubmitted(_to, msg.sender);
    }

    function lookupENSName(address addr) public view returns (string memory) {
        bytes32 node = ensReverseRegistrar.node(addr);
        return ensReverseRegistrar.defaultResolver().name(node);
    }

    function respondToProposal(
        Proposal response,
        string calldata ens1,
        string calldata ens2
    ) external payable {
        //Response shouldnt be NOTHING or PENDING
        require(
            uint8(response) != uint8(Proposal.NOTHING) &&
            uint8(response) != uint8(Proposal.PENDING),
            "Response not valid"
        );
        //shouldnt be expired
        require(
            block.timestamp < unionWith[msg.sender].createdAt + timeToRespond,
            "Proposal expired"
        );
        //Only the address who was invited to be united should respond to the proposal.
        require(
            unionWith[msg.sender].to == msg.sender,
            "You cant respond your own proposal, that's scary"
        );
        //Proposal status must be "PENDING"
        require(
            unionWith[msg.sender].proposalStatus == uint8(Proposal.PENDING),
            "This proposal has already been responded"
        );
        //Checking the ens names provided against ens registrar
        string memory ensFrom = lookupENSName(unionWith[msg.sender].from);
        string memory ensTo = lookupENSName(unionWith[msg.sender].to);
        require(
            keccak256(abi.encodePacked(ens1)) ==
                keccak256(abi.encodePacked(ensFrom)) ||
                keccak256(abi.encodePacked(ens1)) ==
                keccak256(abi.encodePacked(ensTo)),
            "First ENS name doesn't match with addresses involved"
        );
        require(
            keccak256(abi.encodePacked(ens2)) ==
                keccak256(abi.encodePacked(ensFrom)) ||
                keccak256(abi.encodePacked(ens2)) ==
                keccak256(abi.encodePacked(ensTo)),
            "Second ENS name doesn't match with addresses involved"
        );
        // //instance of the proposal
        Union memory acceptOrDecline = unionWith[msg.sender];
        //get the addresses involved
        address from = acceptOrDecline.from;
        address to = acceptOrDecline.to;
        acceptOrDecline.createdAt = block.timestamp;
        //DECLINE SCENARIO / RESET PROPOSAL
        if (uint8(response) == 3) {
            acceptOrDecline.expired = true;
            acceptOrDecline.proposalStatus = uint8(Proposal.DECLINED);
            unionWith[to] = acceptOrDecline;
            unionWith[from] = acceptOrDecline;
            emit ProposalCancelled(to, from);
            return;
        }
        //ACCEPT SCENARIO AND GET UNITED
        else if (uint8(response) == 2) {
            acceptOrDecline.proposalStatus = uint8(Proposal.ACCEPTED);
            acceptOrDecline.relationshipStatus = uint8(Status.TOGETHER);
            acceptOrDecline.registryNumber = registryCounter;
            unionWith[to] = acceptOrDecline;
            unionWith[from] = acceptOrDecline;
            registryCounter++;
            emit ProposalResponded(to, from, uint8(Proposal.ACCEPTED));
            IENSTogetherNFT(ensTogetherNFT).mint(from, to, ens1, ens2);
            emit GotUnited(from, msg.sender, block.timestamp, acceptOrDecline.registryNumber);
        } else revert("Transaction failed");
    }

    function cancelOrResetProposal() public payable {
        Union memory currentProposal = unionWith[msg.sender];
        address to = currentProposal.to;
        address from = currentProposal.from;
        currentProposal.proposalStatus = uint8(Proposal.DECLINED);
        currentProposal.expired = true;
        unionWith[to] = currentProposal;
        unionWith[from] = currentProposal;
        emit ProposalCancelled(to, from);
    }
    function updateUnion(Status newStatus) external payable {
        require(msg.value >= updateStatusCost, "Insufficient amount");
        //once separated cannot modify status
        require(
            unionWith[msg.sender].relationshipStatus != uint8(Status.SEPARATED),
            "You are separated, make another proposal"
        );
        Union memory unionUpdated = unionWith[msg.sender];
        address from = unionUpdated.from;
        address to = unionUpdated.to;
        unionUpdated.relationshipStatus = uint8(newStatus);
        unionUpdated.createdAt = block.timestamp;
        if (uint8(newStatus) == 3) {
            unionUpdated.proposalStatus = uint8(Proposal.DECLINED);
            unionUpdated.expired = true;
        }
        unionWith[to] = unionUpdated;
        unionWith[from] = unionUpdated;
        emit UnionStatusUpdated(from, to, uint256(newStatus), block.timestamp);
    }

    //Interfacing with ENSTogetherNFT contract
    function getTokenUri(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        string memory uri = IENSTogetherNFT(ensTogetherNFT).tokenURI(_tokenId);
        return uri;
    }

    function getTokenIDS(address _add)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory ids = IENSTogetherNFT(ensTogetherNFT).ownedNFTS(_add);
        return ids;
    }

    function burn(uint256 tokenId) external {
        IENSTogetherNFT(ensTogetherNFT).burn(tokenId, msg.sender);
        emit Burned(tokenId, true);
    }

    //Only owner
    function setNftContractAddress(address ensTogetherNFT_) public onlyOwner {
        ensTogetherNFT = IENSTogetherNFT(ensTogetherNFT_);
    }

    function modifyTimeToRespond(uint256 t) external onlyOwner {
        timeToRespond = t;
    }

    function modifyProposalCost(uint256 amount) external onlyOwner {
        cost = amount;
    }

    function modifyStatusUpdateCost(uint256 amount) external onlyOwner {
        updateStatusCost = amount;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IENSTogetherNFT {
    function mint(
        address from,
        address to,
        string calldata ens1,
        string calldata ens2
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownedNFTS(address _owner) external view returns (uint256[] memory);

    function burn(uint256 tokenId, address _add) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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