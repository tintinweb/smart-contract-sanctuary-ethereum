// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library GenRanNum {

    function startRandomGen(
        uint256 tokenId,
        address sender,
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.timestamp,
                        numWords,
                        block.difficulty,
                        keyHash,
                        block.basefee,
                        sender,
                        block.gaslimit,
                        tokenId,
                        block.coinbase
                    )
                )
            );
    }

    function startRandomRarity(
        uint256 tokenId,
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        numWords,
                        block.basefee,
                        block.difficulty,
                        keyHash,
                        block.gaslimit,
                        tokenId,
                        block.coinbase
                    )
                )
            );
    }

    function startRandomJob(
        uint256 tokenId,
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.timestamp,
                        numWords,
                        keyHash,
                        block.difficulty,
                        block.basefee,
                        tokenId,
                        block.gaslimit,
                        block.coinbase
                    )
                )
            );
    }

    function startRandomHair(
        uint256 tokenId,
        uint256 numWords
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        numWords,
                        block.basefee,
                        tokenId,
                        block.coinbase,
                        block.timestamp
                    )
                )
            );
    }

    function startRandomExprss(
        uint256 tokenId,
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        numWords,
                        block.basefee,
                        tokenId,
                        block.difficulty,
                        block.chainid,
                        keyHash,
                        blockhash(block.number)
                    )
                )
            );
    }

    function startRandomHaveHelmet(
        uint256 tokenId,
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        blockhash(block.number),
                        numWords,
                        block.basefee,
                        tokenId,
                        block.difficulty,
                        block.chainid,
                        keyHash
                    )
                )
            );
    }

    function startRandomHelmet(
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        numWords,
                        blockhash(block.number),
                        block.basefee,
                        block.difficulty,
                        block.chainid,
                        keyHash
                    )
                )
            );
    }
    
    function startRandomBody(
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.timestamp,
                        numWords,
                        block.basefee,
                        keyHash,
                        block.difficulty,
                        block.chainid
                    )
                )
            );
    }

    function startRandomHand(
        uint256 numWords,
        bytes32 keyHash
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        blockhash(block.number),
                        numWords,
                        block.timestamp,
                        block.basefee,
                        keyHash,
                        block.difficulty,
                        block.chainid
                    )
                )
            );
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Helper/GenRanNum.sol";

interface IVRF2 {
    function getNums() external returns (uint256);
}

interface IRARITIES {
    function getResult(uint32 _number, uint16 keysType)
        external
        view
        returns (uint32);

    function getPoolLength(uint16 poolKey) external view returns (uint256);

    function getPoolResult(uint16 poolKey, uint32 index)
        external
        view
        returns (uint32);
}

contract RandomWorker is AccessControl {
    using Strings for string;
    using Counters for Counters.Counter;

    Counters.Counter public tokenIdCounter;

    bytes32 private keyHash;
    IVRF2 private vrf;
    IRARITIES private rarities;

    uint32 curCollection = 1;

    enum StartRandom {
        Gen,
        Rarity,
        Job,
        Hair,
        Exprss,
        HaveHelmet,
        Helmet,
        Body,
        Hand
    }

    struct RandomStorage {
        uint256 randomGender;
        uint256 randomRarity;
        uint256 randomJob;
        uint256 randomHair;
        uint256 randomExpress;
        uint256 randomHaveHelmet;
    }

    struct Layer2Storage {
        uint32 finalHelmet;
        uint32 helmetRarity;
        uint32 finalBody;
        uint32 bodyRarity;
        uint32 finalHand;
        uint32 handRarity;
    }

    struct ResultStorage {
        uint32 finalGen;
        uint32 finalRarity;
        uint32 finalJob;
        uint32 finalHair;
        uint32 finalExpress;
        uint32 haveHelmet;
        uint32 finalHelmet;
        uint32 helmetRarity;
        uint32 finalBody;
        uint32 bodyRarity;
        uint32 finalHand;
        uint32 handRarity;
        uint32 finalEyes;
        uint32 finalSkills;
    }

    struct AdjustedMetadata {
        uint32 rarity;
        uint32 bodyRarity;
        uint32 helmetRarity;
        uint32 handRarity;
    }

    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    ////////////////////////////mock\\\\\\\\\\\\\\\\\\\\\\\\\\
    string[5555] public preBuilt;

    constructor(
        bytes32 _keyHash,
        IVRF2 _vrf,
        IRARITIES _rarities
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        keyHash = _keyHash;
        vrf = IVRF2(_vrf);
        rarities = IRARITIES(_rarities);
    }

    function setKeyHash(bytes32 _keyHash) public onlyRole(DEV_ROLE) {
        keyHash = _keyHash;
    }

    function setVRF(IVRF2 _vrf) public onlyRole(DEV_ROLE) {
        vrf = IVRF2(_vrf);
    }

    function setCurrentColl(uint32 _newCollection) public onlyRole(DEV_ROLE) {
        curCollection = _newCollection;
    }

    function genStringToken(uint32 _tokenId)
        internal
        pure
        returns (string memory)
    {
        string memory tokenStr = Strings.toString(_tokenId);

        if (_tokenId < 10) {
            return string(abi.encodePacked("0", tokenStr));
        } else {
            return tokenStr;
        }
    }

    function appendCollect(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function append(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function appendHelmet(
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }

    function getRandomNumber(uint256 tokenId, address _msgSender)
        external
        onlyRole(MINTER_ROLE)
        returns (string memory result)
    {
        result = getResult(tokenId, _msgSender);

        return result;
    }

    function getResult(uint256 tokenId, address _msgSender)
        public
        returns (string memory result)
    {
        uint256 numwords = vrf.getNums();
        uint256 ranNums = GenRanNum.startRandomGen(
            tokenId,
            _msgSender,
            numwords,
            keyHash
        );

        uint256 index = ranNums % preBuilt.length;
        result = preBuilt[index];
        preBuilt[index] = preBuilt[preBuilt.length - 1];

        return result;
    }

    function prebuiltRannum() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 total = tokenIdCounter.current() + 25;
        require(total <= preBuilt.length, "exceed supply");

        for (uint256 i = 0; i < 25 ; i++) {
            (
                ResultStorage memory resultStorage,
                RandomStorage memory randomStorage
            ) = startRandomNumber(i, address(this));

            AdjustedMetadata memory rarityPart = AdjustedMetadata(
                resultStorage.finalRarity,
                resultStorage.bodyRarity,
                resultStorage.helmetRarity,
                resultStorage.handRarity
            );
            rarityPart = adjustMetadata(rarityPart, randomStorage);

            resultStorage.finalRarity = rarityPart.rarity;
            resultStorage.bodyRarity = rarityPart.bodyRarity;
            resultStorage.helmetRarity = rarityPart.helmetRarity;
            resultStorage.handRarity = rarityPart.handRarity;

            string memory result = sortingMetadata(resultStorage);
            preBuilt[i] = result;
            tokenIdCounter.increment();
        }
    }

    function adjustMetadata(
        AdjustedMetadata memory rarityPart,
        RandomStorage memory randomStorage
    ) public view returns (AdjustedMetadata memory newRarityPart) {
        newRarityPart.rarity = checkRarirty(
            rarityPart.rarity,
            randomStorage.randomRarity
        );
        newRarityPart.bodyRarity = checkRarirty(
            rarityPart.bodyRarity,
            randomStorage.randomGender
        );
        newRarityPart.helmetRarity = checkRarirty(
            rarityPart.helmetRarity,
            randomStorage.randomHaveHelmet
        );
        newRarityPart.handRarity = checkRarirty(
            rarityPart.handRarity,
            randomStorage.randomHair
        );
        return newRarityPart;
    }

    function checkRarirty(uint32 rarity, uint256 randomNums)
        internal
        view
        returns (uint32 result)
    {
        if (rarity == 0) {
            result = getPoolResult(982, randomNums);
        } else if (rarity == 1) {
            result = getPoolResult(983, randomNums);
        } else if (rarity == 2) {
            result = getPoolResult(984, randomNums);
        } else if (rarity == 3) {
            result = getPoolResult(985, randomNums);
        } else if (rarity == 4) {
            result = getPoolResult(986, randomNums);
        }
        return result;
    }

    function startRandomNumber(uint256 tokenId, address _msgSender)
        internal
        returns (
            ResultStorage memory resultStorage,
            RandomStorage memory randomStorage
        )
    {
        uint256 requestId = vrf.getNums();
        uint256 regenId;

        randomStorage.randomGender = GenRanNum.startRandomGen(
            tokenId,
            _msgSender,
            requestId,
            keyHash
        );
        randomStorage.randomRarity = GenRanNum.startRandomRarity(
            tokenId,
            requestId,
            keyHash
        );
        randomStorage.randomJob = GenRanNum.startRandomJob(
            tokenId,
            requestId,
            keyHash
        );
        regenId = requestId / 1000; // frontId
        randomStorage.randomHair = GenRanNum.startRandomHair(tokenId, regenId);
        regenId = requestId % 1000; // backId
        randomStorage.randomExpress = GenRanNum.startRandomExprss(
            tokenId,
            regenId,
            keyHash
        );
        regenId = (requestId / 100) % 10; // middleId
        randomStorage.randomHaveHelmet = GenRanNum.startRandomHaveHelmet(
            tokenId,
            regenId,
            keyHash
        );

        resultStorage.finalGen = uint32(randomStorage.randomGender % 2);

        //get rarities result
        resultStorage.finalRarity = uint32(
            (randomStorage.randomRarity % 1000) + 1
        );
        resultStorage.finalRarity = rarities.getResult(
            resultStorage.finalRarity,
            1
        );

        resultStorage.finalJob = uint32(randomStorage.randomJob % 4);
        resultStorage.finalHair = uint32((randomStorage.randomHair % 60) + 1);
        resultStorage.finalExpress = uint32(
            (randomStorage.randomExpress % 15) + 1
        );
        resultStorage.haveHelmet = uint32(randomStorage.randomHaveHelmet % 2);

        //Layer2
        regenId = requestId % 10; //lastId
        Layer2Storage memory layer2 = randomLayer2(
            resultStorage.haveHelmet,
            regenId
        );

        resultStorage.finalHelmet = layer2.finalHelmet;
        resultStorage.helmetRarity = layer2.helmetRarity;
        resultStorage.finalBody = layer2.finalBody;
        resultStorage.bodyRarity = layer2.bodyRarity;
        resultStorage.finalHand = layer2.finalHand;
        resultStorage.handRarity = layer2.handRarity;

        //Eyes
        resultStorage.finalEyes = getRandomEye(
            resultStorage.finalRarity,
            randomStorage.randomRarity
        );

        //Skills
        resultStorage.finalSkills = getRandomSkills(
            resultStorage.finalJob,
            resultStorage.finalRarity,
            randomStorage.randomJob
        );
        return (resultStorage, randomStorage);
    }

    function sortingMetadata(ResultStorage memory resultStorage)
        internal
        view
        returns (string memory result)
    {
        // gender + rarity + class
        result = append(
            genStringToken(resultStorage.finalGen),
            genStringToken(resultStorage.finalRarity),
            genStringToken(resultStorage.finalJob)
        );

        // (3) + hair + express
        result = append(
            result,
            appendCollect(
                genStringToken(curCollection),
                genStringToken(resultStorage.finalHair)
            ),
            appendCollect(
                genStringToken(curCollection),
                genStringToken(resultStorage.finalExpress)
            )
        );

        // (5) + eye + body
        result = append(
            result,
            appendCollect(
                genStringToken(curCollection),
                genStringToken(resultStorage.finalEyes)
            ),
            append(
                genStringToken(curCollection),
                genStringToken(resultStorage.bodyRarity),
                genStringToken(resultStorage.finalBody)
            )
        );

        //(7) + Helmet
        if (resultStorage.haveHelmet == 0) {
            result = appendCollect(
                result,
                appendHelmet(
                    genStringToken(curCollection),
                    genStringToken(resultStorage.haveHelmet),
                    genStringToken(0),
                    genStringToken(0)
                )
            );
        } else if (resultStorage.haveHelmet == 1) {
            result = appendCollect(
                result,
                appendHelmet(
                    genStringToken(curCollection),
                    genStringToken(resultStorage.haveHelmet),
                    genStringToken(resultStorage.helmetRarity),
                    genStringToken(resultStorage.finalHelmet)
                )
            );
        }

        //(8) + Hand
        result = appendCollect(
            result,
            append(
                genStringToken(curCollection),
                genStringToken(resultStorage.handRarity),
                genStringToken(resultStorage.finalHand)
            )
        );

        //(9) + skills
        result = appendCollect(
            result,
            appendCollect(
                genStringToken(curCollection),
                genStringToken(resultStorage.finalSkills)
            )
        );
    }

    function randomLayer2(uint32 finalHaveHelmet, uint256 regenId)
        internal
        view
        returns (Layer2Storage memory layer2Storage)
    {
        if (finalHaveHelmet == 1) {
            (layer2Storage.finalHelmet, layer2Storage.helmetRarity) = getRandom(
                regenId,
                StartRandom.Helmet
            );
        } else if (finalHaveHelmet == 0) {
            layer2Storage.finalHelmet = finalHaveHelmet;
        }

        (layer2Storage.finalBody, layer2Storage.bodyRarity) = getRandom(
            regenId,
            StartRandom.Body
        );

        (layer2Storage.finalHand, layer2Storage.handRarity) = getRandom(
            regenId,
            StartRandom.Hand
        );

        return layer2Storage;
    }

    function getRandom(uint256 lastId, StartRandom _randomType)
        internal
        view
        returns (uint32 finalRandom, uint32 partRarity)
    {
        uint256 random;
        uint256 randommed;

        if (_randomType == StartRandom.Helmet) {
            random = GenRanNum.startRandomHelmet(lastId, keyHash);
            randommed = (random % 1000) + 1;
            //get Helmet result = 11
            partRarity = rarities.getResult(uint32(randommed), 11);

            if (partRarity == 0) {
                finalRandom = uint32((random % 34) + 1);
            } else if (partRarity == 1) {
                finalRandom = uint32((random % 24) + 1);
            }
        } else if (_randomType == StartRandom.Body) {
            random = GenRanNum.startRandomBody(lastId, keyHash);
            randommed = (random % 1000) + 1;
            //get Body result = 10
            partRarity = rarities.getResult(uint32(randommed), 10);

            if (partRarity == 0) {
                finalRandom = uint32((random % 7) + 1);
            } else if (partRarity == 1) {
                finalRandom = uint32((random % 6) + 1);
            }
        } else if (_randomType == StartRandom.Hand) {
            random = GenRanNum.startRandomBody(lastId, keyHash);
            random = GenRanNum.startRandomHand(random, keyHash);
            randommed = (random % 1000) + 1;
            //get Hands result = 7
            partRarity = rarities.getResult(uint32(randommed), 7);

            if (partRarity == 0) {
                finalRandom = uint32((random % 7) + 1);
            } else if (partRarity == 1) {
                finalRandom = uint32((random % 6) + 1);
            }
        }
        return (finalRandom, partRarity);
    }

    function getRandomEye(uint32 rarity, uint256 rarityNums)
        internal
        pure
        returns (uint32 finalRandom)
    {
        if (rarity == 0) {
            finalRandom = uint32((rarityNums % 11) + 1);
        } else if (rarity == 1) {
            finalRandom = uint32((rarityNums % 7) + 1);
        } else if (rarity == 2) {
            finalRandom = uint32((rarityNums % 6) + 1);
        } else if (rarity == 3) {
            finalRandom = uint32((rarityNums % 5) + 1);
        } else if (rarity == 4) {
            finalRandom = uint32((rarityNums % 3) + 1);
        }
        return (finalRandom);
    }

    function getRandomSkills(
        uint32 class,
        uint32 rarity,
        uint256 ranNums
    ) internal view returns (uint32 skillResult) {
        if (class == 0) {
            //Vanguard
            uint16 power = uint16(class) * 10;
            if (rarity == 2) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 3) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 4) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            }
        } else if (class == 1) {
            //Caster
            uint16 power = uint16(class) * 10;
            if (rarity == 2) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 3) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 4) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            }
        } else if (class == 2) {
            //Sniper
            uint16 power = uint16(class) * 10;
            if (rarity == 2) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 3) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 4) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            }
        } else if (class == 3) {
            //Assassin
            uint16 power = uint16(class) * 10;
            if (rarity == 2) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 3) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            } else if (rarity == 4) {
                skillResult = getPoolResult(uint16(power + rarity), ranNums);
            }
        }
        return skillResult;
    }

    function getPoolResult(uint16 poolKeys, uint256 ranNums)
        internal
        view
        returns (uint32 poolResult)
    {
        uint256 length = rarities.getPoolLength(poolKeys);
        uint32 index = uint32((ranNums % length));
        poolResult = rarities.getPoolResult(poolKeys, index);

        return poolResult;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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