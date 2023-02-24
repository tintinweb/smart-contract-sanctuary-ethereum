// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IProposal.sol";
import "./interfaces/IGovernance.sol";

//created by EOA s
contract Proposal is IProposal, Ownable, ERC165 {
    // if name is empty then proposal is invalid
    //solhint-disable-next-line
    string public override NAME = "Example Proposal for Proposal";
    string public constant override ABSTRACTION =
        "Example abstraction for Proposal";
    string public constant override IPFS = "ipfs:";

    IGovernance public immutable override governanceContract;

    constructor(address governanceContractAddress) {
        governanceContract = IGovernance(governanceContractAddress);
    }

    // what happens if someone tricks us and make mint proposal as majority
    // not as absolute majority
    // do we need a Suspend Proposal
    function proposalType() external pure override returns (ProposalType) {
        return ProposalType.REQUIRES_ABSOLUTE_MAJORITY;
    }

    //only created for test purposes its not needed
    function setName(string memory _name) external onlyOwner {
        NAME = _name;
    }

    /*
        typeOfVar == 0 => type = bytes
        typeOfVar == 1 => type = uint256
        typeOfVar == 2 => type = int256
        typeOfVar == 3 => type = address
        typeOfVar == 4 => type = bool
        typeOfVar == 5 => type = string
     */
    function execute() external override {
        ProposalMethods[] memory methods = new ProposalMethods[](3);

        methods[0] = ProposalMethods({
            method: abi.encodeWithSignature(
                "setVar(string,bytes)",
                "minDurationUntilVoting",
                abi.encode(0)
            ),
            callee: address(governanceContract)
        });

        methods[1] = ProposalMethods({
            method: abi.encodeWithSignature(
                "setVar(string,bytes)",
                "minDurationWhileVoting",
                abi.encode(10 minutes)
            ),
            callee: address(governanceContract)
        });

        methods[2] = ProposalMethods({
            method: abi.encodeWithSignature(
                "setVar(string,bytes)",
                "minDurationUntilRunProposal",
                abi.encode(0)
            ),
            callee: address(governanceContract)
        });

        governanceContract.runProposal(methods);
    }

    //solhint-disable-next-line
    function revertExecution() external pure override {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IProposal).interfaceId ||
            super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IGovernance.sol";

pragma solidity ^0.8.7;

interface IProposal is IERC165 {
    function NAME() external view returns (string memory);

    function ABSTRACTION() external view returns (string memory);

    function IPFS() external view returns (string memory);

    function governanceContract() external view returns (IGovernance);

    function execute() external;

    function revertExecution() external;

    function proposalType() external view returns (ProposalType);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
enum ProposalType {
    REQUIRES_MAJORITY,
    REQUIRES_ABSOLUTE_MAJORITY,
    CHANGE_AUTHORIZER
}
struct ProposalMethods {
    bytes method;
    address callee;
}

interface IGovernance {
    struct ConsortiumData {
        string consortiumName;
        uint256 lastProposalCreatedAt;
    }

    function addVar(
        uint8,
        string memory,
        bytes memory
    ) external;

    function setVar(string calldata, bytes calldata) external;

    function getVar(string memory) external view returns (bytes memory);

    function getVarUnsigned(string memory) external view returns (uint256);

    function getTypeOfVar(string calldata) external view returns (bytes1);

    function isIProposalImplementer(address) external view returns (bool);

    function createProposal(
        address,
        uint256,
        uint256,
        uint256
    ) external;

    function voteProposal(
        address,
        uint256,
        uint256
    ) external;

    function registerConsortium(string memory) external;

    function consortiumNames(address) external view returns (string memory);

    function addressOfConsortium(string memory) external view returns (address);

    function isNameUnique(string memory) external view returns (bool);

    function suspendConsortium(address) external;

    function reinstateConsortium(address) external;

    function suspendProposal(address proposal) external;

    function reinstateProposal(address proposal) external;

    function getConsortiumData(address)
        external
        view
        returns (string memory, uint256);

    function mint(address consortium, uint256 amount) external;

    function runProposal(ProposalMethods[] memory methods) external;

    function revertProposal(ProposalMethods[] memory methods) external;

    function emergencySuspend(
        address suspendedProposal,
        uint256 durationUntilVoting,
        uint256 durationWhileVoting,
        uint256 durationUntilRunProposal,
        bytes memory parameters,
        bool isConsortium
    ) external returns (address);

    function suspended(address) external view returns (bool);

    function emergencyReinstate(address, bool) external;
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