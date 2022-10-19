// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/INodeStaking.sol";
import "./interfaces/INode.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GetAllData is Ownable {
    INodeStaking private _IRigelStaking;
    INodeStaking private _ISiriusStaking;
    INodeStaking private _IVegaStaking;
    INode private _INode;

    constructor(
        address rigel,
        address sirius,
        address vega,
        address node
    ) {
        _IRigelStaking = INodeStaking(rigel);
        _ISiriusStaking = INodeStaking(sirius);
        _IVegaStaking = INodeStaking(vega);
        _INode = INode(node);
    }

    function getGeneralNodeData()
        external
        view
        returns (
            uint256[4] memory,
            uint16[3] memory,
            uint256[4] memory,
            uint16[3] memory,
            uint256[4] memory,
            uint16[3] memory
        )
    {
        (
            uint256[4] memory rigelFeesAndClaimed,
            uint16[3] memory rigelSettings
        ) = _IRigelStaking.getGeneralNodeData();
        (
            uint256[4] memory siriusFeesAndClaimed,
            uint16[3] memory siriusSettings
        ) = _ISiriusStaking.getGeneralNodeData();
        (
            uint256[4] memory vegaFeesAndClaimed,
            uint16[3] memory vegaSettings
        ) = _IVegaStaking.getGeneralNodeData();
        return (
            rigelFeesAndClaimed,
            rigelSettings,
            siriusFeesAndClaimed,
            siriusSettings,
            vegaFeesAndClaimed,
            vegaSettings
        );
    }

    function getUserData(address userAddress)
        external
        view
        returns (
            uint256,
            uint24[] memory,
            uint256,
            uint24[] memory,
            uint256,
            uint24[] memory
        )
    {
        (uint256 rigelClaimed, uint24[] memory rigelNodes) = _IRigelStaking
            .getUserData(userAddress);
        (uint256 siriusClaimed, uint24[] memory siriusNodes) = _ISiriusStaking
            .getUserData(userAddress);
        (uint256 vegaClaimed, uint24[] memory vegaNodes) = _IVegaStaking
            .getUserData(userAddress);
        return (
            rigelClaimed,
            rigelNodes,
            siriusClaimed,
            siriusNodes,
            vegaClaimed,
            vegaNodes
        );
    }

    function getAllUnclaimedReward(address userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rigel = _IRigelStaking.getAllReward(userAddress);
        uint256 sirius = _ISiriusStaking.getAllReward(userAddress);
        uint256 vega = _IVegaStaking.getAllReward(userAddress);
        return (rigel, sirius, vega);
    }

    function getNodeData(uint256 tokenId)
        external
        view
        returns (
            address,
            uint256[3] memory,
            address,
            uint256[3] memory,
            address,
            uint256[3] memory
        )
    {
        (address rigelOwner, uint256[3] memory rigelTokenData) = _IRigelStaking
            .getNodeData(tokenId);
        (
            address siriusOwner,
            uint256[3] memory siriusTokenData
        ) = _ISiriusStaking.getNodeData(tokenId);
        (address vegaOwner, uint256[3] memory vegaTokenData) = _IVegaStaking
            .getNodeData(tokenId);

        return (
            rigelOwner,
            rigelTokenData,
            siriusOwner,
            siriusTokenData,
            vegaOwner,
            vegaTokenData
        );
    }

    function setNodeAddress(
        address rigel,
        address sirius,
        address vega
    ) external onlyOwner {
        _IRigelStaking = INodeStaking(rigel);
        _ISiriusStaking = INodeStaking(sirius);
        _IVegaStaking = INodeStaking(vega);
    }

    function getGlobalStake()
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        (uint256[] memory rigel, , ) = _INode.getUnclaimedNode(
            address(_IRigelStaking)
        );
        (, uint256[] memory sirius, ) = _INode.getUnclaimedNode(
            address(_ISiriusStaking)
        );
        (, , uint256[] memory vega) = _INode.getUnclaimedNode(
            address(_IVegaStaking)
        );
        return (rigel, sirius, vega);
    }
}

//Global claimed
// getAllReward()

// SPDX-License-Identifier: MIT
interface INodeStaking {
    function getGeneralNodeData()
        external
        view
        returns (uint256[4] memory, uint16[3] memory);

    function getUserData(address userAddress)
        external
        view
        returns (uint256, uint24[] memory);

    function getNodeData(uint256 tokenId)
        external
        view
        returns (address, uint256[3] memory);

    function getReward(uint256 tokenId) external view returns (uint256);

    function getAllReward(address userAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface INode is IERC165Upgradeable {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeMint(
        address to,
        string memory uri,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function getNodeType(uint256 tokenId) external view returns (uint256);

    function getNodeSettingAndPrice()
        external
        view
        returns (uint16[6] memory, uint80[3] memory);

    function getUnclaimedNode(address userAddress)
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory);

    function getNodeSold() external returns (uint256);
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
interface IERC165Upgradeable {
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