// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "../Interfaces/IETHGobblers.sol";

contract ETHGobblersBulkBurn is Owned {

    address public gobblers;

    constructor(
        address _owner,
        address _gobblers
    ) Owned(_owner) {
        gobblers = _gobblers;
    }

    /// @notice Function to burn multiple gobblers at once.
    /// @param tokenIds The tokenIds of the gobblers to burn.
    function bulkBurn(
        uint[] calldata tokenIds
    ) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            IETHGobblers(gobblers).transferFrom(msg.sender, address(0), tokenIds[i]);
        }
    }

    /// @notice Owner function to update the gobblers address.
    /// @param _gobblers The new gobblers address.
    function updateGobblers(address _gobblers) external onlyOwner {
        gobblers = _gobblers;
    }

}

pragma solidity ^0.8.10;

interface IETHGobblers {
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Bury(uint256 indexed tokenID, address indexed owner);
    event ConfigureTraits(uint256 indexed tokenID, uint256 indexed traitIDs);
    event Feed(uint256 indexed tokenID, uint8 indexed amount, address indexed owner);
    event GobblerGobbled(
        uint256 indexed gobblerGobblerID, uint256 indexed victimID, uint256 indexed newGobblerGobblerID
    );
    event Groom(uint256 indexed tokenID, uint8 indexed amount, address indexed owner);
    event Mitosis(uint256 indexed parentTokenID, uint256 indexed newTokenID, address indexed owner);
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event Sleep(uint256 indexed tokenID, address indexed owner);
    event TraitUnlocked(uint256 indexed parentGobblerID, uint256 indexed newTraitTokenID, address indexed owner);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function ETHGobbled(uint256) external view returns (uint256);
    function actionAlive(uint8 action, uint256 tokenID, uint8 amount, bytes32 messageHash, bytes memory signature)
        external
        payable;
    function approve(address spender, uint256 id) external;
    function balanceOf(address owner) external view returns (uint256);
    function baseURI() external view returns (string memory);
    function bury(uint256 tokenID, bytes32 messageHash, bytes memory signature) external;
    function changeBaseURI(string memory newBaseURI) external;
    function changeFeedPrice(uint256 price) external;
    function changeGobbleGobblerPrice(uint256 price) external;
    function changeGroomPrice(uint256 price) external;
    function changeSigner(address signer) external;
    function changeSleepPrice(uint256 price) external;
    function configureTraits(uint256 tokenID, uint256 traitIDs, bytes32 messageHash, bytes memory signature) external;
    function currentGobblerGobbler() external view returns (uint256);
    function equippedTraits(uint256) external view returns (uint256);
    function feedPrice() external view returns (uint256);
    function flipPaused() external;
    function getApproved(uint256) external view returns (address);
    function getTraitConfiguration(uint256 tokenID)
        external
        view
        returns (
            uint32 wings,
            uint32 sidekick,
            uint32 food,
            uint32 accessory,
            uint32 weather,
            uint32 cushion,
            uint32 inflight,
            uint32 freeSlot
        );
    function gobDrops() external view returns (address);
    function gobbleGobbler(
        uint256 gobblerGobblerTokenID,
        uint256 victimTokenID,
        uint256 newGobblerGobbler,
        bytes32 messageHash,
        bytes memory signature
    ) external payable;
    function gobbleGobblerPrice() external view returns (uint256);
    function groomPrice() external view returns (uint256);
    function hashMessage(address sender, address thisContract, bytes4 functionNameSig, uint256 nonce)
        external
        pure
        returns (bytes32);
    function hashMessageBury(
        address sender,
        address thisContract,
        bytes4 functionNameSig,
        uint256 tokenID,
        uint256 nonce
    ) external pure returns (bytes32);
    function hashMessageConfigureTraits(
        address sender,
        address thisContract,
        bytes4 functionNameSig,
        uint256 traitIDs,
        uint256 nonce
    ) external pure returns (bytes32);
    function hashMessageGobbleGobbler(
        address sender,
        address thisContract,
        bytes4 functionNameSig,
        uint256 newGobblerGobbler,
        uint256 nonce
    ) external pure returns (bytes32);
    function isApprovedForAll(address, address) external view returns (bool);
    function mint(bytes32 messageHash, bytes memory signature) external;
    function mitosis(uint256 tokenID, bytes32 messageHash, bytes memory signature) external;
    function mitosisSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function ownerOf(uint256 id) external view returns (address owner);
    function paused() external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setGobblerGobbler(uint256 tokenID) external;
    function signatureNonce(address) external view returns (uint256);
    function signerAddress() external view returns (address);
    function sleepPrice() external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenID) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 id) external;
    function transferOwnership(address newOwner) external;
    function unlockTrait(uint256 tokenID, bytes32 messageHash, bytes memory signature) external;
    function withdraw() external;
}