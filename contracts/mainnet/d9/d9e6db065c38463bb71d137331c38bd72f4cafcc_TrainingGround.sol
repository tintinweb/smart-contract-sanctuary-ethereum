// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {Portal} from "./Portal.sol";

interface ILegionFighter {
    function isCore(uint256 tokenId) external view returns (bool, uint256);

    function Equipped(uint256 tokenId) external view returns (uint8);
}

contract TrainingGround is Portal {
    bool public trainingActive = false;

    struct Permission {
        uint8 allowLevel;
        uint248 index;
    }

    mapping(address => Permission) allowedCollections; // collection address => Permission struct
    mapping(uint256 => address) allowedCollectionsLookup; // allowedCollections index => collection address (reverse lookup)
    uint256 allowedCollectionsCount = 0;

    struct State {
        uint8 status; // 0 or 1 - Boolean for whether currently training
        uint8 programme; // Programme Id
        uint208 progress; // Progress (104 x 2 bits)
        uint32 startBlock; // Block started training in current programme
    }

    mapping(uint256 => uint32[3]) public durationsByProgramme; // programme id => durations[]
    mapping(uint256 => uint256) public participantsByProgramme; // programme id => count of participants
    uint256 public programmesCount = 0;

    mapping(uint256 => State) stateByMetaToken; // metaToken => State struct

    event NewProgramme(uint8 indexed programme, uint32[3] durations);
    event StartTraining(uint256 indexed metaToken, uint8 indexed programme, uint8 level);
    event Claim(uint256 indexed metaToken, uint8 indexed programme, uint8 level);

    constructor(address jumpPortAddress) Portal(jumpPortAddress) {}

    /* Helper / View functions */

    /**
     * @dev Get a metaToken (a unique id representing a specific tokenId in a specific collection)
     * @param tokenAddress the collection contract address
     * @param tokenId the fighter tokenId
     */
    function getMetaToken(address tokenAddress, uint256 tokenId) public view returns (uint256 metaToken) {
        uint256 tokenAddressIndex = uint256(allowedCollections[tokenAddress].index);
        metaToken = (tokenAddressIndex << 240) | tokenId;
    }

    /**
     * @dev Get the contract address and tokenId of a given metaToken
     * @param metaToken a unique id representing a specific tokenId in a specific collection
     */
    function getTokenDetails(uint256 metaToken) public view returns (address tokenAddress, uint256 tokenId) {
        uint256 tokenAddressIndex = metaToken >> 240;
        tokenAddress = allowedCollectionsLookup[tokenAddressIndex];
        tokenId = metaToken & 0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    /**
     * @dev Check whether a given collection address is allowed into Training Ground
     */
    function isAllowed(address tokenAddress) external view returns (bool allowed) {
        return allowedCollections[tokenAddress].allowLevel > 0;
    }

    /**
     * @dev Check whether a given fighter is currently training (by metaToken)
     */
    function isTraining(uint256 metaToken) public view returns (bool training) {
        return stateByMetaToken[metaToken].status > 0;
    }

    /**
     * @dev Check whether a given fighter is currently training (by contract address and tokenId)
     */
    function isTraining(address tokenAddress, uint256 tokenId) public view returns (bool training) {
        return isTraining(getMetaToken(tokenAddress, tokenId));
    }

    /**
     * @dev Get the full progress (represented by a uint208) of a given fighter (by metaToken)
     */
    function getFullProgress(uint256 metaToken) public view returns (uint208 progress) {
        return stateByMetaToken[metaToken].progress;
    }

    /**
     * @dev Get the full progress (represented by a uint208) of a given fighter (by contract address and tokenId)
     */
    function getFullProgress(address tokenAddress, uint256 tokenId) public view returns (uint208 progress) {
        return getFullProgress(getMetaToken(tokenAddress, tokenId));
    }

    /**
     * @dev Get a count of each level achieved for a given fighter (by metaToken)
     * Returns level counts as named Taunts, Fighting styles and Combos
     */
    function getSkillCounts(uint256 metaToken)
        public
        view
        returns (
            uint256 taunts,
            uint256 styles,
            uint256 combos
        )
    {
        unchecked {
            State storage state = stateByMetaToken[metaToken];

            for (uint8 i = 1; i <= programmesCount; i++) {
                uint256 level = uint8(state.progress >> (208 - (i * 2))) & 3;

                if (level >= 1) {
                    taunts++;
                }
                if (level >= 2) {
                    styles++;
                }
                if (level == 3) {
                    combos++;
                }
            }
        }
    }

    /**
     * @dev Get a count of each level achieved for a given fighter (by contract address and tokenId)
     * Returns level counts as named Taunts, Fighting styles and Combos
     */
    function getSkillCounts(address tokenAddress, uint256 tokenId)
        public
        view
        returns (
            uint256 taunts,
            uint256 styles,
            uint256 combos
        )
    {
        return getSkillCounts(getMetaToken(tokenAddress, tokenId));
    }

    /**
     * @dev Get the status of a fighter during training in their current programme (by metaToken)
     * Returns the current programme id, the block they started and the duration
     */
    function getTrainingStatus(uint256 metaToken)
        public
        view
        returns (
            uint8 programme,
            uint32 startBlock,
            uint32 duration
        )
    {
        require(stateByMetaToken[metaToken].status > 0, "Token is not training");

        State storage state = stateByMetaToken[metaToken];
        programme = state.programme;
        startBlock = state.startBlock;
        duration = uint32(block.number - uint256(state.startBlock));
    }

    /**
     * @dev Get the status of a fighter during training in their current programme (by contract address and tokenId)
     * Returns the current programme id, the block they started and the duration
     */
    function getTrainingStatus(address tokenAddress, uint256 tokenId)
        public
        view
        returns (
            uint8 programme,
            uint32 startBlock,
            uint32 duration
        )
    {
        return getTrainingStatus(getMetaToken(tokenAddress, tokenId));
    }

    /**
     * @dev Get the current level achieved by a fighter in their current programme (by metaToken)
     */
    function getCurrentLevel(uint256 metaToken) public view returns (uint8 level) {
        unchecked {
            (uint8 programme, , uint32 blocksDuration) = getTrainingStatus(metaToken);
            uint32[3] storage durations = durationsByProgramme[programme];

            if (durations[2] <= blocksDuration) {
                return 3;
            } else if (durations[1] <= blocksDuration) {
                return 2;
            } else if (durations[0] <= blocksDuration) {
                return 1;
            } else {
                return 0;
            }
        }
    }

    /**
     * @dev Get the current level achieved by a fighter in their current programme (by contract address and tokenId)
     */
    function getCurrentLevel(address tokenAddress, uint256 tokenId) public view returns (uint8 level) {
        level = getCurrentLevel(getMetaToken(tokenAddress, tokenId));
    }

    /**
     * @dev Get the level claimed by a fighter in a given programme (by metaToken)
     */
    function getClaimedLevel(uint256 metaToken, uint8 programme) public view returns (uint8 level) {
        State storage state = stateByMetaToken[metaToken];
        level = uint8(state.progress >> (208 - (programme * 2))) & 3;
    }

    /**
     * @dev Get the level claimed by a fighter in a given programme (by contract address and tokenId)
     */
    function getClaimedLevel(
        address tokenAddress,
        uint256 tokenId,
        uint8 programme
    ) public view returns (uint8 level) {
        return getClaimedLevel(getMetaToken(tokenAddress, tokenId), programme);
    }

    /* Programme actions */

    /**
     * @dev Internal helper function used for starting a fighter on a new programme
     */
    function _startProgramme(uint256 metaToken, uint8 programme) internal {
        State storage state = stateByMetaToken[metaToken];
        uint8 startLevel = getClaimedLevel(metaToken, programme);

        require(startLevel < 3, "Programme already completed");

        state.programme = programme;

        unchecked {
            state.startBlock = uint32(block.number);

            if (startLevel > 0) {
                uint32[3] storage durations = durationsByProgramme[programme];
                state.startBlock = uint32(block.number) - durations[startLevel - 1];
            }

            participantsByProgramme[programme]++;
        }

        emit StartTraining(metaToken, programme, startLevel);
    }

    /**
     * @dev Join a fighter onto a training programme
     * @param tokenAddress the collection contract address
     * @param tokenId the fighter tokenId
     * @param programme the id of the programme to join
     */
    function joinProgramme(
        address tokenAddress,
        uint256 tokenId,
        uint8 programme
    ) public isActive onlyOperator(tokenAddress, tokenId) tokenAllowed(tokenAddress, tokenId) {
        require(programme > 0 && programme <= programmesCount, "Programme does not exist");

        uint256 metaToken = getMetaToken(tokenAddress, tokenId);
        State storage state = stateByMetaToken[metaToken];

        require(state.status == 0, "Already training");

        _startProgramme(metaToken, programme);
        state.status = 1;

        JumpPort.lockToken(tokenAddress, tokenId);
    }

    /**
     * @dev Switch a fighter onto a different training programme
     * @param tokenAddress the collection contract address
     * @param tokenId the fighter tokenId
     * @param programme the id of the programme to join
     */
    function switchProgramme(
        address tokenAddress,
        uint256 tokenId,
        uint8 programme
    ) public isActive onlyOperator(tokenAddress, tokenId) {
        require(allowedCollections[tokenAddress].allowLevel > 0, "Token not allowed");
        require(programme > 0 && programme <= programmesCount, "Programme does not exist");

        uint256 metaToken = getMetaToken(tokenAddress, tokenId);
        State storage state = stateByMetaToken[metaToken];
        uint8 currentProgramme = state.programme;

        require(state.status == 1, "Token is not training");
        require(currentProgramme != programme, "Token is already in the programme");

        claimLevel(metaToken);

        participantsByProgramme[currentProgramme]--;

        _startProgramme(metaToken, programme);
    }

    /**
     * @dev Remove a fighter from their current programme
     * @param tokenAddress the collection contract address
     * @param tokenId the fighter tokenId
     */
    function leaveCurrentProgramme(address tokenAddress, uint256 tokenId) public onlyOperator(tokenAddress, tokenId) {
        uint256 metaToken = getMetaToken(tokenAddress, tokenId);
        State storage state = stateByMetaToken[metaToken];

        require(state.status == 1, "Token is not training");

        claimLevel(metaToken);

        participantsByProgramme[state.programme]--;

        state.status = 0;
        state.programme = 0;

        JumpPort.unlockToken(tokenAddress, tokenId);
    }

    /**
     * @dev Claim a level achieved for a given fighter in their current programme (by metaToken)
     * This function is public so can be called anytime by anyone if they wish to pay the gas
     */
    function claimLevel(uint256 metaToken) public {
        State storage state = stateByMetaToken[metaToken];
        uint8 currentProgramme = state.programme;

        uint8 claimedLevel = getClaimedLevel(metaToken, currentProgramme);
        uint8 currentLevel = getCurrentLevel(metaToken);

        if (currentLevel > claimedLevel) {
            uint208 mask = uint208(claimedLevel ^ currentLevel) << (208 - currentProgramme * 2);
            state.progress = (state.progress ^ mask);
            emit Claim(metaToken, currentProgramme, currentLevel);
        }
    }

    /**
     * @dev Claim a level achieved for a given fighter in their current programme (by contract address and tokenId)
     * This function is public so can be called anytime by anyone if they wish to pay the gas
     */
    function claimLevel(address tokenAddress, uint256 tokenId) public {
        claimLevel(getMetaToken(tokenAddress, tokenId));
    }

    /* Modifiers */

    /**
     * @dev Prevent execution if training is not currently active
     */
    modifier isActive() {
        require(trainingActive == true, "Training not active");
        _;
    }

    /**
     * @dev Prevent execution if the specified token is not in the JumpPort or msg.sender is not owner or approved
     */
    modifier onlyOperator(address tokenAddress, uint256 tokenId) {
        require(JumpPort.isDeposited(tokenAddress, tokenId) == true, "Token not in JumpPort");
        address tokenOwner = JumpPort.ownerOf(tokenAddress, tokenId);
        require(tokenOwner == msg.sender || JumpPort.getApproved(tokenAddress, tokenId) == msg.sender || JumpPort.isApprovedForAll(tokenOwner, msg.sender) == true, "Not an operator of that token");
        _;
    }

    /**
     * @dev Prevent execution if the Legion like fighter is a core or is not equipped
     */
    modifier tokenAllowed(address tokenAddress, uint256 tokenId) {
        require(allowedCollections[tokenAddress].allowLevel > 0, "Token not allowed");
        ILegionFighter LF = ILegionFighter(tokenAddress);
        (bool core, ) = LF.isCore(tokenId);
        require(core == false, "Not a Legion Fighter");
        require(LF.Equipped(tokenId) > 0, "Fighter not equipped");
        _;
    }

    /* Administration */

    /**
     * @dev Toggle training active state
     * @param active desired state of training active (true/false)
     */
    function setTraining(bool active) external onlyRole(ADMIN_ROLE) {
        trainingActive = active;
    }

    /**
     * @dev Add a new token collection to the allowed list
     * @param tokenAddress the collection contract address
     */
    function addAllowedCollection(address tokenAddress) external onlyRole(ADMIN_ROLE) {
        require(allowedCollections[tokenAddress].index == 0, "Collection permissions already exist");

        allowedCollectionsCount++;
        allowedCollections[tokenAddress] = Permission(1, uint248(allowedCollectionsCount));
        allowedCollectionsLookup[allowedCollectionsCount] = tokenAddress;
    }

    /**
     * @dev Update a token collections permission level
     * @param tokenAddress the collection contract address
     * @param allowLevel an integer (0-255) for allowed permission level. Anything greater than 0 is allowed.
     */
    function updateAllowedCollection(address tokenAddress, uint8 allowLevel) external onlyRole(ADMIN_ROLE) {
        require(allowedCollections[tokenAddress].index > 0, "Collection permissions do not exist");

        allowedCollections[tokenAddress].allowLevel = allowLevel;
    }

    /**
     * @dev Add a new programme with associated level durations
     * @param durations an array of block heights for each level duration
     */
    function addProgramme(uint32[3] calldata durations) public onlyRole(ADMIN_ROLE) {
        require(durations[1] > durations[0] && durations[2] > durations[1], "Durations not in ascending order");
        require(programmesCount < 104, "Max programmes exist");

        programmesCount++;
        durationsByProgramme[programmesCount] = durations;
        emit NewProgramme(uint8(programmesCount), durations);
    }

    /**
     * @dev Add a batch of new programmes with associated level durations
     * @param programmes an array of programme duration arrays (block heights for each level duration)
     */
    function addProgrammes(uint32[3][] calldata programmes) external onlyRole(ADMIN_ROLE) {
        for (uint8 i = 0; i < programmes.length; i++) {
            addProgramme(programmes[i]);
        }
    }

    /**
     * @dev Update an existing programmes level durations
     * @param programme the id of the programme
     * @param durations an array of block heights for each level duration
     */
    function updateProgramme(uint8 programme, uint32[3] calldata durations) external onlyRole(ADMIN_ROLE) {
        require(programme > 0 && programme <= programmesCount, "Programme does not exist");
        require(durations[1] > durations[0] && durations[2] > durations[1], "Durations not in ascending order");

        durationsByProgramme[programme] = durations;
    }

    /**
     * @dev Eject a fighter from their current programme
     * @param tokenAddress the collection contract address
     * @param tokenId the fighter tokenId
     */
    function ejectFighter(address tokenAddress, uint256 tokenId) external onlyRole(ADMIN_ROLE) {
        uint256 metaToken = getMetaToken(tokenAddress, tokenId);
        State storage state = stateByMetaToken[metaToken];

        require(state.status == 1, "Token is not training");

        participantsByProgramme[state.programme]--;

        state.status = 0;
        state.programme = 0;

        JumpPort.unlockToken(tokenAddress, tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {OwnableBase} from "./OwnableBase.sol";

interface IJumpPort {
    function ownerOf(address tokenAddress, uint256 tokenId) external view returns (address owner);

    function isDeposited(address tokenAddress, uint256 tokenId) external view returns (bool);

    function getApproved(address tokenAddress, uint256 tokenId) external view returns (address copilot);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function lockToken(address tokenAddress, uint256 tokenId) external;

    function unlockToken(address tokenAddress, uint256 tokenId) external;

    function unlockAllTokens(bool isOverridden) external;

    function blockExecution(bool isBlocked) external;
}

abstract contract Portal is OwnableBase {
    IJumpPort public JumpPort;
    bytes32 public constant UNLOCK_ROLE = keccak256("UNLOCK_ROLE");

    constructor(address jumpPortAddress) {
        JumpPort = IJumpPort(jumpPortAddress);
    }

    /**
     * @dev Allow current administrators to be able to grant/revoke unlock role to other addresses.
     */
    function setUnlockRole(address account, bool canUnlock) public onlyRole(ADMIN_ROLE) {
        roles[UNLOCK_ROLE][account] = canUnlock;
        emit RoleChange(UNLOCK_ROLE, account, canUnlock, msg.sender);
    }

    /**
     * @dev Mark locks held by this portal as void or not.
     * Allows for portals to have a degree of self-governance; if the administrator(s) of a portal
     * realize something is wrong and wish to allow all tokens locked by that portal as void, they're
     * able to indicate that to the JumpPort, without needing to invlove JumpPort governance.
     */
    function unlockAllTokens(bool isOverridden) public onlyRole(ADMIN_ROLE) {
        JumpPort.unlockAllTokens(isOverridden);
    }

    /**
     * @dev Prevent this Portal from calling `executeAction` on the JumpPort.
     * Intended to be called in the situation of a large failure of an individual Portal's operation,
     * as a way for the Portal itself to indicate it has failed, and arbitrary contract calls should not
     * be allowed to originate from it.
     *
     * This function only allows Portals to enable/disable their own execution right.
     */
    function blockExecution(bool isBlocked) public onlyRole(ADMIN_ROLE) {
        JumpPort.blockExecution(isBlocked);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IDocumentationRepository {
    function doc(address contractAddress)
        external
        view
        returns (
            string memory name,
            string memory description,
            string memory details
        );
}

error MissingRole(bytes32 role, address operator);

abstract contract OwnableBase {
    bytes32 public constant ADMIN_ROLE = 0x00;
    mapping(bytes32 => mapping(address => bool)) internal roles; // role => operator => hasRole
    mapping(bytes32 => uint256) internal validSignatures; // message hash => expiration block height
    IDocumentationRepository public DocumentationRepository;

    event RoleChange(bytes32 indexed role, address indexed account, bool indexed isGranted, address sender);

    constructor() {
        roles[ADMIN_ROLE][msg.sender] = true;
    }

    function doc()
        public
        view
        returns (
            string memory name,
            string memory description,
            string memory details
        )
    {
        return DocumentationRepository.doc(address(this));
    }

    /**
     * @dev See {ERC1271-isValidSignature}.
     */
    function isValidSignature(bytes32 hash, bytes memory) external view returns (bytes4 magicValue) {
        if (validSignatures[hash] >= block.number) {
            return 0x1626ba7e; // bytes4(keccak256("isValidSignature(bytes32,bytes)")
        } else {
            return 0xffffffff;
        }
    }

    /**
     * @dev Inspect whether a specific address has a specific role.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return roles[role][account];
    }

    /* Modifiers */

    modifier onlyRole(bytes32 role) {
        if (roles[role][msg.sender] != true) revert MissingRole(role, msg.sender);
        _;
    }

    /* Administration */

    /**
     * @dev Allow current administrators to be able to grant/revoke admin role to other addresses.
     */
    function setAdmin(address account, bool isAdmin) public onlyRole(ADMIN_ROLE) {
        roles[ADMIN_ROLE][account] = isAdmin;
        emit RoleChange(ADMIN_ROLE, account, isAdmin, msg.sender);
    }

    /**
     * @dev Claim ENS reverse-resolver rights for this contract.
     * https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
     */
    function setReverseResolver(address registrar) public onlyRole(ADMIN_ROLE) {
        IReverseResolver(registrar).claim(msg.sender);
    }

    /**
     * @dev Update address for on-chain documentation lookup.
     */
    function setDocumentationRepository(address documentationAddress) public onlyRole(ADMIN_ROLE) {
        DocumentationRepository = IDocumentationRepository(documentationAddress);
    }

    /**
     * @dev Set a message as valid, to be queried by ERC1271 clients.
     */
    function markMessageSigned(bytes32 hash, uint256 expirationLength) public onlyRole(ADMIN_ROLE) {
        validSignatures[hash] = block.number + expirationLength;
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyRole(ADMIN_ROLE) {
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public virtual onlyRole(ADMIN_ROLE) {
        IERC721(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawEth() public onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
}