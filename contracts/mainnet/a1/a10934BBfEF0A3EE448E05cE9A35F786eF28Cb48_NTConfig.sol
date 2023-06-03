// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

interface ICitizen {
    function getGenderOfTokenId(uint256 citizenId) external view returns (bool);
}

enum NTComponent {
    S1_IDENTITY,
    S1_BOUGHT_IDENTITY,
    S1_VAULT,
    S1_ITEM,
    S1_LAND,
    S1_CITIZEN,
    S2_IDENTITY,
    S2_ITEM,
    S2_LAND,
    S2_CITIZEN,
    CHAMPION_CHIP
}

enum NTSecondaryComponent {
    S1_IDENTITY_RARE_MINT,
    S1_IDENTITY_HAND_MINT,
    S1_CITIZEN_FEMALE,
    S2_CITIZEN_FEMALE
}

enum NTSeason {
    INVALID,
    NO_SEASON,
    SEASON_1,
    SEASON_2
}

struct NTComponents {
    address s1Identity;
    address s1BoughtIdentity;
    address s1Vault;
    address s1Item;
    address s1Land;
    address s1Citizen;
    address s2Identity;
    address s2Item;
    address s2Land;
    address s2Citizen;
    address championChips;
}

struct NTSecondaryComponents {
    address s1IdentityRareMint;
    address s1IdentityHandMint;
    address s1CitizenFemale;
    address s2CitizenFemale;
}

struct FallbackThresholds {
    uint16 s1Identity;
    uint16 s1BoughtIdentity;
    uint16 s1Vault;
    uint16 s1Item;
    uint16 s1Land;
    uint16 s1Citizen;
    uint16 s2Identity;
    uint16 s2Item;
    uint16 s2Land;
    uint16 s2Citizen;
    uint16 championChips;
}

error ComponentNotFound();
error AddressNotConfigured();
error TokenNotFound();

contract NTConfig is OwnableUpgradeable {
    bool constant V1 = false;
    bool constant V2 = true;

    address public migrator;
    address public bytesContract;

    FallbackThresholds fallbackThresholds;

    // maps `isV2` => `addresses`
    mapping(bool => NTComponents) _components;

    NTComponents _metadataContracts;
    NTSecondaryComponents _secondaryMetadataContracts;

    function initialize() external initializer {
        __Ownable_init();
    } 

    function findMigrator(
        NTComponent component
    ) external view returns (address) {
        return findComponent(component, true);
    }

    /**
     * @notice Finds the `component` in the version defined by `isV2`.
     *
     * @param component `NTComponent`encoding of the component
     * @param isV2 defines whether V1 or V2 addresses are to be overridden
     */
    function findComponent(
        NTComponent component,
        bool isV2
    ) public view returns (address) {
        NTComponents storage components = _components[isV2];
        if (component == NTComponent.S1_IDENTITY) {
            return components.s1Identity;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            return components.s1BoughtIdentity;
        } else if (component == NTComponent.S1_VAULT) {
            return components.s1Vault;
        } else if (component == NTComponent.S1_ITEM) {
            return components.s1Item;
        } else if (component == NTComponent.S1_LAND) {
            return components.s1Land;
        } else if (component == NTComponent.S1_CITIZEN) {
            return components.s1Citizen;
        } else if (component == NTComponent.S2_IDENTITY) {
            return components.s2Identity;
        } else if (component == NTComponent.S2_ITEM) {
            return components.s2Item;
        } else if (component == NTComponent.S2_LAND) {
            return components.s2Land;
        } else if (component == NTComponent.S2_CITIZEN) {
            return components.s2Citizen;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            return components.championChips;
        }
        revert ComponentNotFound();
    }

    /**
     * @notice Decodes the `components` into a `NTComponents` struct and
     * overrides all the fields relating to the provided version defined by
     * `isV2`.
     *
     * @param components encoded struct of addresses to each NT component
     * @param isV2 defines whether V1 or V2 addresses are to be overridden
     */
    function enlist(bytes calldata components, bool isV2) public onlyOwner {
        NTComponents memory components_ = abi.decode(
            components,
            (NTComponents)
        );
        _components[isV2] = components_;
    }

    /**
     * @notice Sets the provided `component` to `addr`. `isV2` defines
     * which version is being overridden.
     *
     * @param component enum encoding from `NTComponent`
     * @param addr address to `component`
     * @param isV2 defines whether V1 or V2 addresses are to be overridden
     */
    function enlist(
        NTComponent component,
        address addr,
        bool isV2
    ) external onlyOwner {
        NTComponents storage components = _components[isV2];
        if (component == NTComponent.S1_IDENTITY) {
            components.s1Identity = addr;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            components.s1BoughtIdentity = addr;
        } else if (component == NTComponent.S1_VAULT) {
            components.s1Vault = addr;
        } else if (component == NTComponent.S1_ITEM) {
            components.s1Item = addr;
        } else if (component == NTComponent.S1_LAND) {
            components.s1Land = addr;
        } else if (component == NTComponent.S1_CITIZEN) {
            components.s1Citizen = addr;
        } else if (component == NTComponent.S2_IDENTITY) {
            components.s2Identity = addr;
        } else if (component == NTComponent.S2_ITEM) {
            components.s2Item = addr;
        } else if (component == NTComponent.S2_LAND) {
            components.s2Land = addr;
        } else if (component == NTComponent.S2_CITIZEN) {
            components.s2Citizen = addr;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            components.championChips = addr;
        }
    }

    /**
     * @notice Decodes the `metadata` into a `NTComponents` struct
     *
     * @param metadata encoded struct of addresses to each NT metadata contract
     */
    function enlistMetadata(bytes calldata metadata) public onlyOwner {
        NTComponents memory metadataContracts = abi.decode(
            metadata,
            (NTComponents)
        );
        _metadataContracts = metadataContracts;
    }

    function enlistMetadata(
        NTComponent metadata,
        address addr
    ) external onlyOwner {
        if (metadata == NTComponent.S1_IDENTITY) {
            _metadataContracts.s1Identity = addr;
        } else if (metadata == NTComponent.S1_BOUGHT_IDENTITY) {
            _metadataContracts.s1BoughtIdentity = addr;
        } else if (metadata == NTComponent.S1_VAULT) {
            _metadataContracts.s1Vault = addr;
        } else if (metadata == NTComponent.S1_ITEM) {
            _metadataContracts.s1Item = addr;
        } else if (metadata == NTComponent.S1_LAND) {
            _metadataContracts.s1Land = addr;
        } else if (metadata == NTComponent.S1_CITIZEN) {
            _metadataContracts.s1Citizen = addr;
        } else if (metadata == NTComponent.S2_IDENTITY) {
            _metadataContracts.s2Identity = addr;
        } else if (metadata == NTComponent.S2_ITEM) {
            _metadataContracts.s2Item = addr;
        } else if (metadata == NTComponent.S2_LAND) {
            _metadataContracts.s2Land = addr;
        } else if (metadata == NTComponent.S2_CITIZEN) {
            _metadataContracts.s2Citizen = addr;
        } else if (metadata == NTComponent.CHAMPION_CHIP) {
            _metadataContracts.championChips = addr;
        }
    }

    /**
     * @notice Decodes the `metadata` into a `NTSecondaryMetadata` struct
     *
     * @param metadata encoded struct of addresses to each NT secondary metadata contract
     */
    function enlistSecondaryMetadata(bytes calldata metadata) public onlyOwner {
        NTSecondaryComponents memory metadataContracts = abi.decode(
            metadata,
            (NTSecondaryComponents)
        );
        _secondaryMetadataContracts = metadataContracts;
    }

    function enlistSecondaryMetadata(
        NTSecondaryComponent metadata,
        address addr
    ) external onlyOwner {
        if (metadata == NTSecondaryComponent.S1_IDENTITY_RARE_MINT) {
            _secondaryMetadataContracts.s1IdentityRareMint = addr;
        } else if (metadata == NTSecondaryComponent.S1_IDENTITY_HAND_MINT) {
            _secondaryMetadataContracts.s1IdentityHandMint = addr;
        } else if (metadata == NTSecondaryComponent.S1_CITIZEN_FEMALE) {
            _secondaryMetadataContracts.s1CitizenFemale = addr;
        } else if (metadata == NTSecondaryComponent.S2_CITIZEN_FEMALE) {
            _secondaryMetadataContracts.s2CitizenFemale = addr;
        }
    }

    function setBytesContract(address addr) external onlyOwner {
        bytesContract = addr;
    }

    function setFallbackThreshold(
        NTComponent component,
        uint16 threshold
    ) external onlyOwner {
        if (component == NTComponent.S1_IDENTITY) {
            fallbackThresholds.s1Identity = threshold;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            fallbackThresholds.s1BoughtIdentity = threshold;
        } else if (component == NTComponent.S1_VAULT) {
            fallbackThresholds.s1Vault = threshold;
        } else if (component == NTComponent.S1_ITEM) {
            fallbackThresholds.s1Item = threshold;
        } else if (component == NTComponent.S1_LAND) {
            fallbackThresholds.s1Land = threshold;
        } else if (component == NTComponent.S1_CITIZEN) {
            fallbackThresholds.s1Citizen = threshold;
        } else if (component == NTComponent.S2_IDENTITY) {
            fallbackThresholds.s2Identity = threshold;
        } else if (component == NTComponent.S2_ITEM) {
            fallbackThresholds.s2Item = threshold;
        } else if (component == NTComponent.S2_LAND) {
            fallbackThresholds.s2Land = threshold;
        } else if (component == NTComponent.S2_CITIZEN) {
            fallbackThresholds.s2Citizen = threshold;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            fallbackThresholds.championChips = threshold;
        }
    }

    function setMigrator(address addr) external onlyOwner {
        migrator = addr;
    }

    function tokenExists(uint256 tokenId) external view returns (bool) {
        if (msg.sender == _metadataContracts.s1BoughtIdentity) {
            if (tokenId > fallbackThresholds.s1BoughtIdentity) {
                try
                    IERC721(_components[V2].s1Identity).ownerOf(tokenId)
                returns (address) {
                    return true;
                } catch {
                    return false;
                }
            } else if (
                IERC721(_components[V1].s1BoughtIdentity).ownerOf(tokenId) !=
                address(0)
            ) {
                return true;
            }
            return false;
        }
        revert TokenNotFound();
    }

    /**
     * @notice metadata contract will call parent to see who owns the token.
     * Based on metadata contract that's calling we will look at v1 and v2 a specific nft collection
     * if it exists in v2 we return v2 ownerOf else we return v1 ownerOf
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        if (msg.sender == _metadataContracts.s1Identity) {
            return
                IERC721(
                    _components[tokenId > fallbackThresholds.s1Identity]
                        .s1Identity
                ).ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s1Item) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s1Item].s1Item)
                    .ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s1Land) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s1Land].s1Land)
                    .ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s2Identity) {
            return
                IERC721(
                    _components[tokenId > fallbackThresholds.s2Identity]
                        .s2Identity
                ).ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s2Item) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s2Item].s2Item)
                    .ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s2Land) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s2Land].s2Land)
                    .ownerOf(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAbility(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getAbility(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getAbility(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAllocation(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getAllocation(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getApparel(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getApparel(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getApparel(tokenId);
        } else {
            revert AddressNotConfigured();
        }
    }

    function getClass(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getClass(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getClass(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getExpression(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getExpression(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getEyes(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getEyes(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getEyes(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getGender(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getGender(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getHair(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getHair(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getHelm(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getHelm(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getHelm(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getLocation(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Land).getLocation(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Land).getLocation(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getNose(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getNose(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getRace(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getRace(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getRace(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getVehicle(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getVehicle(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getVehicle(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getWeapon(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getWeapon(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAdditionalItem(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_metadataContracts.s1Vault).getAdditionalItem(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAttractiveness(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId))
                    .getAttractiveness(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getAttractiveness(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getCool(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getCool(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getCool(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getIntelligence(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId))
                    .getIntelligence(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getStrength(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getStrength(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getStrength(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getTechSkill(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getTechSkill(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getTechSkill(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getCreditYield(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId))
                    .getCreditYield(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getCredits(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getCredits(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getCreditProportionOfTotalSupply(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_metadataContracts.s1Vault)
                    .getCreditProportionOfTotalSupply(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getCreditMultiplier(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_metadataContracts.s1Vault).getCreditMultiplier(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getIdentityIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s2Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getVaultIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getVaultIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getVaultIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getItemCacheIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s2Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getLandDeedIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s2Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getRewardRateOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getRewardRateOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getRewardRateOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getSpecialMessageOfTokenId(
        uint256 citizenId
    ) external view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            } else {
                return
                    NTConfig(_components[V1].s1Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            } else {
                return
                    NTConfig(_components[V1].s2Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            }
        }
        revert AddressNotConfigured();
    }

    function calculateRewardRate(
        uint256 identityId,
        uint256 vaultId
    ) external returns (uint256) {
        return
            NTConfig(_metadataContracts.s1Citizen).calculateRewardRate(
                identityId,
                vaultId
            );
    }

    function checkSpecialItems(uint256 tokenId) external view returns (string memory) {
        return NTConfig(_components[V1].s1Item).checkSpecialItems(tokenId);
    }

    function generateURI(
        uint256 tokenId
    ) external view returns (string memory) {
        (bool isValid, , ) = _validateCaller(msg.sender);
        require(isValid, "generateURI: not configured address");
        NTConfig tokenContract = NTConfig(
            _selectTokenContract(msg.sender, tokenId)
        );
        return tokenContract.generateURI(tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        (bool isValid, , ) = _validateCaller(msg.sender);
        require(isValid, "tokenURI: not configured address");
        NTConfig tokenContract = NTConfig(
            _selectTokenContract(msg.sender, tokenId)
        );
        if (
            msg.sender == _components[V1].s1Citizen ||
            msg.sender == _components[V2].s1Citizen ||
            msg.sender == _components[V1].s2Citizen ||
            msg.sender == _components[V2].s2Citizen
        ) {
            return tokenContract.generateURI(tokenId);
        }
        return tokenContract.tokenURI(tokenId);
    }

    function _findThreshold(
        NTComponent component
    ) internal view returns (uint256) {
        if (component == NTComponent.S1_IDENTITY) {
            return fallbackThresholds.s1Identity;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            return fallbackThresholds.s1BoughtIdentity;
        } else if (component == NTComponent.S1_VAULT) {
            return fallbackThresholds.s1Vault;
        } else if (component == NTComponent.S1_ITEM) {
            return fallbackThresholds.s1Item;
        } else if (component == NTComponent.S1_LAND) {
            return fallbackThresholds.s1Land;
        } else if (component == NTComponent.S1_CITIZEN) {
            return fallbackThresholds.s1Citizen;
        } else if (component == NTComponent.S2_IDENTITY) {
            return fallbackThresholds.s2Identity;
        } else if (component == NTComponent.S2_ITEM) {
            return fallbackThresholds.s2Item;
        } else if (component == NTComponent.S2_LAND) {
            return fallbackThresholds.s2Land;
        } else if (component == NTComponent.S2_CITIZEN) {
            return fallbackThresholds.s2Citizen;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            return fallbackThresholds.championChips;
        }
        revert ComponentNotFound();
    }

    function _seasonChecker(address addr) internal view returns (NTSeason) {
        if (
            addr == _components[V1].s1Identity ||
            addr == _components[V2].s1Identity ||
            addr == _metadataContracts.s1Identity ||
            addr == _secondaryMetadataContracts.s1IdentityRareMint ||
            addr == _secondaryMetadataContracts.s1IdentityHandMint
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1BoughtIdentity ||
            addr == _components[V2].s1BoughtIdentity ||
            addr == _metadataContracts.s1BoughtIdentity
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Vault ||
            addr == _components[V2].s1Vault ||
            addr == _metadataContracts.s1Vault
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Item ||
            addr == _components[V2].s1Item ||
            addr == _metadataContracts.s1Item
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Land ||
            addr == _components[V2].s1Land ||
            addr == _metadataContracts.s1Land
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Citizen ||
            addr == _components[V2].s1Citizen ||
            addr == _metadataContracts.s1Citizen ||
            addr == _secondaryMetadataContracts.s1CitizenFemale
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s2Identity ||
            addr == _components[V2].s2Identity ||
            addr == _metadataContracts.s2Identity
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].s2Item ||
            addr == _components[V2].s2Item ||
            addr == _metadataContracts.s2Item
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].s2Land ||
            addr == _components[V2].s2Land ||
            addr == _metadataContracts.s2Land
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].s2Citizen ||
            addr == _components[V2].s2Citizen ||
            addr == _metadataContracts.s2Citizen ||
            addr == _secondaryMetadataContracts.s2CitizenFemale
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].championChips ||
            addr == _components[V2].championChips ||
            addr == _metadataContracts.championChips
        ) {
            return NTSeason.NO_SEASON;
        } else {
            return NTSeason.INVALID;
        }
    }

    function _findS1IdentityMetadataContract(
        uint256 tokenId
    ) internal view returns (address) {
        if (tokenId < 2251) {
            return _metadataContracts.s1Identity;
        } else if (tokenId < 2281) {
            return _secondaryMetadataContracts.s1IdentityRareMint;
        } else if (tokenId < 2288) {
            return _secondaryMetadataContracts.s1IdentityHandMint;
        } else {
            return _metadataContracts.s1BoughtIdentity;
        }
    }

    function _validateAddress(
        address addr,
        bool isV2
    ) internal view returns (bool) {
        NTComponents storage components = _components[isV2];
        if (addr == components.s1Identity) {
            return true;
        } else if (addr == components.s1BoughtIdentity) {
            return true;
        } else if (addr == components.s1Vault) {
            return true;
        } else if (addr == components.s1Vault) {
            return true;
        } else if (addr == components.s1Item) {
            return true;
        } else if (addr == components.s1Land) {
            return true;
        } else if (addr == components.s1Citizen) {
            return true;
        } else if (addr == components.s2Identity) {
            return true;
        } else if (addr == components.s2Item) {
            return true;
        } else if (addr == components.s2Land) {
            return true;
        } else if (addr == components.s2Citizen) {
            return true;
        } else if (addr == components.championChips) {
            return true;
        }
        revert ComponentNotFound();
    }

    /**
     * @notice Validates the `caller` address under the assumption
     * of it being from the `V2` set of addresses. If no address is found,
     * it gracefully returns a `false` success-state and all following tuple
     * arguments are invalid.
     *
     * @param caller the address of the caller (usually `msg.sender`)
     */
    function _validateCaller(
        address caller
    ) internal view returns (bool, address, NTComponent) {
        NTComponents storage v1Components = _components[V1];
        NTComponents storage v2Components = _components[V2];
        address fallbackAddr;
        NTComponent callingComponent;

        if (caller == v2Components.s1Identity || caller == v1Components.s1Identity) {
            fallbackAddr = v1Components.s1Identity;
            callingComponent = NTComponent.S1_IDENTITY;
        } else if (caller == v1Components.s1BoughtIdentity) {
            fallbackAddr = v1Components.s1BoughtIdentity;
            callingComponent = NTComponent.S1_BOUGHT_IDENTITY;
        } else if (caller == v2Components.s1Vault || caller == v1Components.s1Vault) {
            fallbackAddr = v1Components.s1Vault;
            callingComponent = NTComponent.S1_VAULT;
        } else if (caller == v2Components.s1Item || caller == v1Components.s1Item) {
            fallbackAddr = v1Components.s1Item;
            callingComponent = NTComponent.S1_ITEM;
        } else if (caller == v2Components.s1Land || caller == v1Components.s1Land) {
            fallbackAddr = v1Components.s1Land;
            callingComponent = NTComponent.S1_LAND;
        } else if (caller == v2Components.s1Citizen || caller == v1Components.s1Citizen) {
            fallbackAddr = v1Components.s1Citizen;
            callingComponent = NTComponent.S1_CITIZEN;
        } else if (caller == v2Components.s2Identity || caller == v1Components.s2Identity) {
            fallbackAddr = v1Components.s2Identity;
            callingComponent = NTComponent.S2_IDENTITY;
        } else if (caller == v2Components.s2Item || caller == v1Components.s2Item) {
            fallbackAddr = v1Components.s2Item;
            callingComponent = NTComponent.S2_ITEM;
        } else if (caller == v2Components.s2Land || caller == v1Components.s2Land) {
            fallbackAddr = v1Components.s2Land;
            callingComponent = NTComponent.S2_LAND;
        } else if (caller == v2Components.s2Citizen || caller == v1Components.s2Citizen) {
            fallbackAddr = v1Components.s2Citizen;
            callingComponent = NTComponent.S2_CITIZEN;
        } else if (caller == v2Components.championChips) {
            fallbackAddr = v1Components.championChips;
            callingComponent = NTComponent.CHAMPION_CHIP;
        } else {
            return (false, fallbackAddr, callingComponent);
        }
        return (true, fallbackAddr, callingComponent);
    }

    function _selectTokenContract(
        address component,
        uint256 tokenId
    ) internal view returns (address) {
        if (component == _components[V2].s1Identity) {
            if (tokenId > fallbackThresholds.s1Identity) {
                return _metadataContracts.s1BoughtIdentity;
            } else {
                //TODO: remove magic numbers probably with some new thresholds mapping
                if (tokenId < 2251) {
                    return _metadataContracts.s1Identity;
                } else if (tokenId < 2281) {
                    return _secondaryMetadataContracts.s1IdentityRareMint;
                } else {
                    return _secondaryMetadataContracts.s1IdentityHandMint;
                }
            }
        } else if (component == _components[V1].s1Identity) {
            return _metadataContracts.s1Identity;
        } else if (component == _components[V1].s1BoughtIdentity) {
            return _metadataContracts.s1BoughtIdentity;
        } else if (
            component == _components[V2].s1Vault ||
            component == _components[V1].s1Vault
        ) {
            return _metadataContracts.s1Vault;
        } else if (
            component == _components[V2].s1Item ||
            component == _components[V1].s1Item
        ) {
            return _metadataContracts.s1Item;
        } else if (
            component == _components[V2].s1Land ||
            component == _components[V1].s1Land
        ) {
            return _metadataContracts.s1Land;
        } else if (
            component == _components[V2].s1Citizen ||
            component == _components[V1].s1Citizen
        ) {
            if (ICitizen(component).getGenderOfTokenId(tokenId)) {
                return _secondaryMetadataContracts.s1CitizenFemale;
            }
            return _metadataContracts.s1Citizen;
        } else if (
            component == _components[V2].s2Identity ||
            component == _components[V1].s2Identity
        ) {
            return _metadataContracts.s2Identity;
        } else if (
            component == _components[V2].s2Item ||
            component == _components[V1].s2Item
        ) {
            return _metadataContracts.s2Item;
        } else if (
            component == _components[V2].s2Land ||
            component == _components[V1].s2Land
        ) {
            return _metadataContracts.s2Land;
        } else if (
            component == _components[V2].s2Citizen ||
            component == _components[V1].s2Citizen
        ) {
            if (ICitizen(component).getGenderOfTokenId(tokenId)) {
                return _secondaryMetadataContracts.s2CitizenFemale;
            }
            return _metadataContracts.s2Citizen;
        } else if (
            component == _components[V2].championChips ||
            component == _components[V1].championChips
        ) {
            return _metadataContracts.championChips;
        }
        revert ComponentNotFound();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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