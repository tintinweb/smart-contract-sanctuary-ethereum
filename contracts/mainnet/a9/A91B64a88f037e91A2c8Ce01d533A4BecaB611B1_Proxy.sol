// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAlligator} from "./interfaces/IAlligator.sol";
import {IENSReverseRegistrar} from "./interfaces/IENSReverseRegistrar.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract Proxy is IERC1271 {
    address internal immutable alligator;
    address internal immutable governor;

    constructor(address _governor) {
        alligator = msg.sender;
        governor = _governor;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4) {
        return IAlligator(alligator).isValidProxySignature(address(this), hash, signature);
    }

    function setENSReverseRecord(string calldata name) external {
        require(msg.sender == alligator);
        IENSReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148).setName(name);
    }

    fallback() external payable {
        require(msg.sender == alligator);
        address addr = governor;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := call(gas(), addr, callvalue(), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // `receive` is omitted to minimize contract size
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../structs/Rules.sol";

interface IAlligator {
    // =============================================================
    //                             EVENTS
    // =============================================================

    event ProxyDeployed(address indexed owner, address proxy);
    event SubDelegation(address indexed from, address indexed to, Rules rules);
    event SubDelegations(address indexed from, address[] to, Rules[] rules);
    event VoteCast(
        address indexed proxy,
        address indexed voter,
        address[] authority,
        uint256 proposalId,
        uint8 support
    );
    event VotesCast(
        address[] proxies,
        address indexed voter,
        address[][] authorities,
        uint256 proposalId,
        uint8 support
    );
    event Signed(address indexed proxy, address[] authority, bytes32 messageHash);
    event RefundableVote(address indexed voter, uint256 refundAmount, bool refundSent);

    // =============================================================
    //                       WRITE FUNCTIONS
    // =============================================================

    function create(address owner, bool registerEnsName) external returns (address endpoint);

    function registerProxyDeployment(address owner) external;

    function propose(
        address[] calldata authority,
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description
    ) external returns (uint256 proposalId);

    function castVote(address[] calldata authority, uint256 proposalId, uint8 support) external;

    function castVoteWithReason(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castRefundableVotesWithReasonBatched(
        address[][] calldata authorities,
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external;

    function castVoteBySig(
        address[] calldata authority,
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function sign(address[] calldata authority, bytes32 hash) external;

    function subDelegate(address to, Rules calldata rules, bool createProxy) external;

    function subDelegateBatched(address[] calldata targets, Rules[] calldata rules, bool createProxy) external;

    function _togglePause() external;

    // // =============================================================
    // //                         VIEW FUNCTIONS
    // // =============================================================

    function validate(
        address sender,
        address[] memory authority,
        uint256 permissions,
        uint256 proposalId,
        uint256 support
    ) external view;

    function isValidProxySignature(
        address proxy,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4 magicValue);

    function proxyAddress(address owner) external view returns (address endpoint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IENSReverseRegistrar {
    function setName(string memory name) external returns (bytes32 node);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Rules {
    uint8 permissions;
    uint8 maxRedelegations;
    uint32 notValidBefore;
    uint32 notValidAfter;
    uint16 blocksBeforeVoteCloses;
    address customRule;
}