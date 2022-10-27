// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LibGovNFTTierStorage} from "./../../facets/nftTier/LibGovNFTTierStorage.sol";
import {Modifiers} from "./../../shared/libraries/LibAppStorage.sol";
import {LibGovNFTTier} from "./LibGovNFTTier.sol";
import {LibMeta} from "./../../shared/libraries/LibMeta.sol";
import {LibGovTier} from "./../../facets/govTier/LibGovTier.sol";
import "./../../interfaces/IGovTier.sol";

contract GovNFTTierFacet is Modifiers {
    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param _spTierLevel sp tier level struct
    function addSingleSpTierLevel(
        LibGovNFTTierStorage.SingleSPTierData memory _spTierLevel
    ) external onlyEditTierLevelRole(LibMeta.msgSender()) {
        require(_spTierLevel.ltv > 0, "Invalid LTV");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        es.spTierLevels[es.spTierLevelKeys.length + 1] = _spTierLevel;
        es.spTierLevelKeys.push(es.spTierLevelKeys.length + 1);
    }

    /// @dev function to assign tierlevel to the NFT contract only by super admin
    /// @param _nftContract nft token address whose tier is being added
    /// @param _tierLevel NFTTierdata for the nft contract
    function addNftTierLevel(
        address _nftContract,
        LibGovNFTTierStorage.NFTTierData memory _tierLevel
    ) external onlySuperAdmin(LibMeta.msgSender()) {
        require(_tierLevel.nftContract != address(0), "invalid nft address");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();

        require(
            !LibGovNFTTier.isAlreadyNftTier(_nftContract),
            "Already Assigned Nft or Sp Tier"
        );

        if (_tierLevel.isTraditional) {
            require(
                LibGovTier.isAlreadyTierLevel(_tierLevel.traditionalTier),
                "GTL:Traditional Tier Null"
            );
            require(_tierLevel.spTierId == 0, "GTL: Can't set spTierId");
        } else {
            require(
                es.spTierLevels[_tierLevel.spTierId].ltv > 0,
                "GTL: SP Tier Null"
            );
            require(
                _tierLevel.traditionalTier == 0,
                "GTL: Can't set traditionalTier"
            );
        }

        es.nftTierLevels[_nftContract] = _tierLevel;
        es.nftTierLevelsKeys.push(_nftContract);
    }

    /// @dev this method adds the more nft tokens to already existing nft tier
    /// @param _nftContract nft token address
    /// @param _allowedNFTs allowed nfts addresses
    function addNFTTokensinNftTier(
        address _nftContract,
        address[] memory _allowedNFTs
    ) external onlySuperAdmin(LibMeta.msgSender()) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        LibGovNFTTierStorage.NFTTierData storage nftTier = es.nftTierLevels[
            _nftContract
        ];
        uint256 length = _allowedNFTs.length;
        for (uint256 i = 0; i < length; i++) {
            nftTier.allowedNfts.push(_allowedNFTs[i]);
        }
    }

    /// @dev this methods adds the sun token token to the nft tier
    /// @param _nftContract nft contract address
    /// @param _allowedSunTokens adding more allowed sun token addresses
    function addNFTSunTokensinNftTier(
        address _nftContract,
        address[] memory _allowedSunTokens
    ) external onlySuperAdmin(LibMeta.msgSender()) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        LibGovNFTTierStorage.NFTTierData storage nftTier = es.nftTierLevels[
            _nftContract
        ];
        uint256 length = _allowedSunTokens.length;
        for (uint256 i = 0; i < length; i++) {
            nftTier.allowedSuns.push(_allowedSunTokens[i]);
        }
    }

    /// @dev get all the sp nft tier level keys
    /// @return uint256[] returns the tier level keys Example: 0, 1, 2....
    function getSingleSpTierKeys() external view returns (uint256[] memory) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.spTierLevelKeys;
    }

    /// @dev get all gov nft tier level length
    /// @return uint256 returns the length of the gov nft tier levels
    function getNFTTierLength() external view returns (uint256) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.nftTierLevelsKeys.length;
    }

    function getAllNftTierKeys() external view returns (address[] memory) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.nftTierLevelsKeys;
    }

    function getAllSpTierKeys() external view returns (uint256[] memory) {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.spTierLevelKeys;
    }

    /// @dev update single sp tier level
    function updateSingleSpTierLevel(
        uint256 _index,
        uint256 _ltv,
        bool _singleToken,
        bool _multiToken,
        bool _singleNft,
        bool multiNFT
    ) external onlyEditTierLevelRole(LibMeta.msgSender()) {
        require(_ltv > 0, "Invalid LTV");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        require(es.spTierLevels[_index].ltv > 0, "Tier not exist");
        es.spTierLevels[_index].ltv = _ltv;
        es.spTierLevels[_index].singleToken = _singleToken;
        es.spTierLevels[_index].multiToken = _multiToken;
        es.spTierLevels[_index].singleNft = _singleNft;
        es.spTierLevels[_index].multiNFT = multiNFT;
    }

    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param index sp tier level index which is going to be remove
    function removeSingleSpTierLevel(uint256 index)
        external
        onlyEditTierLevelRole(LibMeta.msgSender())
    {
        require(index > 0, "Invalid index");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        require(es.spTierLevels[index].ltv > 0, "Invalid index");
        delete es.spTierLevels[index];
        LibGovNFTTier._removeSingleSpTierLevelKey(
            LibGovNFTTier._getIndexSpTier(index)
        );
    }

    /// @dev add NFT based Traditional or Single Token type tier levels
    /// @param _contract contract address of the nft tier level
    function removeNftTierLevel(address _contract)
        external
        onlyEditTierLevelRole(LibMeta.msgSender())
    {
        require(_contract != address(0), "Invalid address");
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        require(
            es.nftTierLevels[_contract].nftContract != address(0),
            "Invalid index"
        );
        delete es.nftTierLevels[_contract];
        LibGovNFTTier._removeNftTierLevelKey(
            LibGovNFTTier._getIndexNftTier(_contract)
        );
    }

    /// @dev get the user nft tier
    /// @param _wallet address of the borrower
    /// @return nftTierData returns the nft tier data
    function getUserNftTier(address _wallet)
        external
        view
        returns (LibGovNFTTierStorage.NFTTierData memory nftTierData)
    {
        uint256 maxLTVFromNFTTier;
        address maxNFTTierAddress;
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 nftTiersLength = es.nftTierLevelsKeys.length;
        if (nftTiersLength == 0) {
            return es.nftTierLevels[address(0x0)];
        }

        for (uint256 i = 0; i < nftTiersLength; i++) {
            //user owns nft balannce
            uint256 currentLoanToValue;

            if (IERC721(es.nftTierLevelsKeys[i]).balanceOf(_wallet) > 0) {
                if (es.nftTierLevels[es.nftTierLevelsKeys[i]].isTraditional) {
                    currentLoanToValue = IGovTier(address(this))
                        .getSingleTierData(
                            es
                                .nftTierLevels[es.nftTierLevelsKeys[i]]
                                .traditionalTier
                        )
                        .loantoValue;
                } else {
                    currentLoanToValue = es
                        .spTierLevels[
                            es.nftTierLevels[es.nftTierLevelsKeys[i]].spTierId
                        ]
                        .ltv;
                }
                if (currentLoanToValue >= maxLTVFromNFTTier) {
                    maxNFTTierAddress = es.nftTierLevelsKeys[i];
                    maxLTVFromNFTTier = currentLoanToValue;
                }
            } else {
                continue;
            }
        }

        return es.nftTierLevels[maxNFTTierAddress];
    }

    /// @dev returns single sp tier data
    function getSingleSpTier(uint256 _spTierId)
        external
        view
        returns (LibGovNFTTierStorage.SingleSPTierData memory)
    {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.spTierLevels[_spTierId];
    }

    /// @dev returns NFTTierLevel of an NFT contract
    //// @param _nftContract address of the nft contract
    function getNftTierLevel(address _nftContract)
        external
        view
        returns (LibGovNFTTierStorage.NFTTierData memory)
    {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        return es.nftTierLevels[_nftContract];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {LibGovTierStorage} from "./../facets/govTier/LibGovTierStorage.sol";

interface IGovTier {
    function getSingleTierData(bytes32 _tierLevelKey)
        external
        view
        returns (LibGovTierStorage.TierData memory);

    function isAlreadyTierLevel(bytes32 _tierLevel)
        external
        view
        returns (bool);

    function getGovTierLevelKeys() external view returns (bytes32[] memory);

    function getWalletTier(address _userAddress)
        external
        view
        returns (bytes32 _tierLevel);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibGovNFTTierStorage {
    bytes32 constant GOVNFTTIER_STORAGE_POSITION =
        keccak256("diamond.standard.GOVNFTTier.storage");

    struct SingleSPTierData {
        uint256 ltv;
        bool singleToken;
        bool multiToken;
        bool singleNft;
        bool multiNFT;
    }

    struct NFTTierData {
        address nftContract;
        bool isTraditional;
        address spToken; // strategic partner token address - erc20
        bytes32 traditionalTier;
        uint256 spTierId;
        address[] allowedNfts;
        address[] allowedSuns;
    }

    struct GovNFTTierStorage {
        mapping(uint256 => SingleSPTierData) spTierLevels;
        mapping(address => NFTTierData) nftTierLevels;
        address[] nftTierLevelsKeys;
        uint256[] spTierLevelKeys;
    }

    function govNftTierStorage()
        internal
        pure
        returns (GovNFTTierStorage storage es)
    {
        bytes32 position = GOVNFTTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibDiamond} from "./../../shared/libraries/LibDiamond.sol";
import {LibAdminStorage} from "./../../facets/admin/LibAdminStorage.sol";
import {LibLiquidatorStorage} from "./../../facets/liquidator/LibLiquidatorStorage.sol";
import {LibProtocolStorage} from "./../../facets/protocolRegistry/LibProtocolStorage.sol";
import {LibPausable} from "./../../shared/libraries/LibPausable.sol";

struct AppStorage {
    address govToken;
    address govGovToken;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlySuperAdmin(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].superAdmin, "not super admin");
        _;
    }

    /// @dev modifer only admin with edit admin access can call functions
    modifier onlyEditTierLevelRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.approvedAdminRoles[admin].editGovAdmin,
            "not edit tier role"
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        LibLiquidatorStorage.LiquidatorStorage storage es = LibLiquidatorStorage
            .liquidatorStorage();
        require(es.whitelistLiquidators[_admin], "not liquidator");
        _;
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].addToken, "not add token role");
        _;
    }

    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].editToken, "not edit token role");
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].addSp, "not add sp role");
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].editSp, "not edit sp role");
        _;
    }

    modifier whenNotPaused() {
        LibPausable.enforceNotPaused();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibGovNFTTierStorage} from "./../nftTier/LibGovNFTTierStorage.sol";
import {LibGovTierStorage} from "./../govTier/LibGovTierStorage.sol";

library LibGovNFTTier {

    /// @dev remove single sp tieer level key
    /// @param index already existing tierlevel index

    function _removeSingleSpTierLevelKey(uint256 index) internal {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 length = es.spTierLevelKeys.length;
        if (length != 1) {
            for (uint256 i = index; i < length - 1; i++) {
                es.spTierLevelKeys[i] = es.spTierLevelKeys[i + 1];
            }
        }
        es.spTierLevelKeys.pop();
    }

    function _removeNftTierLevelKey(uint256 index) internal {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 length = es.nftTierLevelsKeys.length;
        for (uint256 i = index; i < length - 1; i++) {
            es.nftTierLevelsKeys[i] = es.nftTierLevelsKeys[i + 1];
        }
        es.nftTierLevelsKeys.pop();
    }

    /// @dev get index of the singleSpTierLevel from the allTierLevel array
    /// @param _tier hash of the tier level

    function _getIndexSpTier(uint256 _tier)
        internal
        view
        returns (uint256 index)
    {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 length = es.spTierLevelKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (es.spTierLevelKeys[i] == _tier) {
                return i;
            }
        }
    }

    /// @dev get index of the nftTierLevel from the allTierLevel array
    /// @param _tier hash of the tier level

    function _getIndexNftTier(address _tier)
        internal
        view
        returns (uint256 index)
    {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();

        uint256 length = es.nftTierLevelsKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (es.nftTierLevelsKeys[i] == _tier) {
                return i;
            }
        }
    }

    function isAlreadyNftTier(address _nftAddress)
        internal
        view
        returns (bool)
    {
        LibGovNFTTierStorage.GovNFTTierStorage storage es = LibGovNFTTierStorage
            .govNftTierStorage();
        uint256 length = es.nftTierLevelsKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.nftTierLevelsKeys[i] == _nftAddress) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibGovTierStorage} from "./../../facets/govTier/LibGovTierStorage.sol";
import {LibAppStorage, AppStorage} from "./../../shared/libraries/LibAppStorage.sol";

library LibGovTier {
    event TierLevelAdded(
        bytes32 _newTierLevel,
        LibGovTierStorage.TierData _tierData
    );
    event TierLevelUpdated(
        bytes32 _updatetierLevel,
        LibGovTierStorage.TierData _tierData
    );
    event TierLevelRemoved(bytes32 _removedtierLevel);
    event AddedWalletTier(address _userAddress, bytes32 _tierLevel);
    event UpdatedWalletTier(address _wallet, bytes32 _tierLevel);

    /// @dev update already created tier level
    /// @param _updatedTierLevelKey key value type of the already created Tier Level in bytes
    /// @param _newTierData access variables for updating the Tier Level

    function _updateTierLevel(
        bytes32 _updatedTierLevelKey,
        LibGovTierStorage.TierData memory _newTierData
    ) internal {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        //update Tier Level to the updatedTier
        uint256 currentIndex = _getIndex(_updatedTierLevelKey);
        uint256 lowerLimit = 0;
        uint256 upperLimit = _newTierData.govHoldings + 10;
        if (currentIndex > 0) {
            lowerLimit = es
                .tierLevels[es.allTierLevelKeys[currentIndex - 1]]
                .govHoldings;
        }
        if (currentIndex < es.allTierLevelKeys.length - 1)
            upperLimit = es
                .tierLevels[es.allTierLevelKeys[currentIndex + 1]]
                .govHoldings;

        require(
            _newTierData.govHoldings < upperLimit &&
                _newTierData.govHoldings > lowerLimit,
            "GTL: Holdings Range Error"
        );

        es.tierLevels[_updatedTierLevelKey] = _newTierData;
        emit TierLevelUpdated(_updatedTierLevelKey, _newTierData);
    }

    /// @dev remove tier level
    /// @param index already existing tierlevel index

    function _removeTierLevelKey(uint256 index) internal {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        if (es.allTierLevelKeys.length != 1) {
            for (uint256 i = index; i < es.allTierLevelKeys.length - 1; i++) {
                es.allTierLevelKeys[i] = es.allTierLevelKeys[i + 1];
            }
        }
        es.allTierLevelKeys.pop();
    }

    /// @dev internal function for the save tier level, which will update and add tier level in the same tx

    function _saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        LibGovTierStorage.TierData[] memory _newTierData
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        for (uint256 i = 0; i < _tierLevelKeys.length; i++) {
            address govToken = s.govToken;

            require(
                _newTierData[i].govHoldings < IERC20(govToken).totalSupply(),
                "GTL: set govHolding error"
            );
            if (!LibGovTier.isAlreadyTierLevel(_tierLevelKeys[i])) {
                LibGovTier._addTierLevel(_tierLevelKeys[i], _newTierData[i]);
            } else if (LibGovTier.isAlreadyTierLevel(_tierLevelKeys[i])) {
                LibGovTier._updateTierLevel(_tierLevelKeys[i], _newTierData[i]);
            }
        }
    }

    /// @dev get index of the tierLevel from the allTierLevel array
    /// @param _tierLevel hash of the tier level

    function _getIndex(bytes32 _tierLevel)
        internal
        view
        returns (uint256 index)
    {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        uint256 length = es.allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.allTierLevelKeys[i] == _tierLevel) {
                return i;
            }
        }
    }

    /// @dev makes _new a pendsing adnmin for approval to be given by all current admins
    /// @param _newTierLevel value type of the New Tier Level in bytes
    /// @param _tierData access variables for _newadmin

    function _addTierLevel(
        bytes32 _newTierLevel,
        LibGovTierStorage.TierData memory _tierData
    ) internal {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        //new Tier is added to the mapping tierLevels
        es.tierLevels[_newTierLevel] = _tierData;

        //new Tier Key for mapping tierLevel
        es.allTierLevelKeys.push(_newTierLevel);
        emit TierLevelAdded(_newTierLevel, _tierData);
    }

    /// @dev Checks if a given _newTierLevel is already added by the admin.
    /// @param _tierLevel value of the new tier

    function isAlreadyTierLevel(bytes32 _tierLevel)
        internal
        view
        returns (bool)
    {
        LibGovTierStorage.GovTierStorage storage es = LibGovTierStorage
            .govTierStorage();
        uint256 length = es.allTierLevelKeys.length;
        for (uint256 i = 0; i < length; i++) {
            if (es.allTierLevelKeys[i] == _tierLevel) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
pragma solidity ^0.8.10;

library LibGovTierStorage {
    bytes32 constant GOVTIER_STORAGE_POSITION =
        keccak256("diamond.standard.GOVTIER.storage");

    struct TierData {
        uint256 govHoldings; // Gov  Holdings to check if it lies in that tier
        uint8 loantoValue; // LTV percentage of the Gov Holdings
        bool govIntel; //checks that if tier level have following access
        bool singleToken;
        bool multiToken;
        bool singleNFT;
        bool multiNFT;
        bool reverseLoan;
    }

    struct GovTierStorage {
        mapping(bytes32 => TierData) tierLevels; //data of the each tier level
        mapping(address => bytes32) tierLevelbyAddress;
        bytes32[] allTierLevelKeys; //list of all added tier levels. Stores the key for mapping => tierLevels
        address[] allTierLevelbyAddress;
        address addressProvider;
        bool isInitializedGovtier;
    }

    function govTierStorage()
        internal
        pure
        returns (GovTierStorage storage es)
    {
        bytes32 position = GOVTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferredDiamond(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferredDiamond(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            LibMeta.msgSender() == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibAdminStorage {
    bytes32 constant ADMINREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.ADMINREGISTRY.storage");

    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    struct AdminStorage {
        mapping(address => AdminAccess) approvedAdminRoles; // approve admin roles for each address
        mapping(uint8 => mapping(address => AdminAccess)) pendingAdminRoles; // mapping of admin role keys to admin addresses to admin access roles
        mapping(uint8 => mapping(address => address[])) areByAdmins; // list of admins approved by other admins, for the specific key
        //admin role keys
        uint8 PENDING_ADD_ADMIN_KEY;
        uint8 PENDING_EDIT_ADMIN_KEY;
        uint8 PENDING_REMOVE_ADMIN_KEY;
        uint8[] PENDING_KEYS; // ADD: 0, EDIT: 1, REMOVE: 2
        address[] allApprovedAdmins; //list of all approved admin addresses
        address[][] pendingAdminKeys; //list of pending addresses for each key
        address superAdmin;
    }

    function adminRegistryStorage()
        internal
        pure
        returns (AdminStorage storage es)
    {
        bytes32 position = ADMINREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibProtocolStorage {
    bytes32 constant PROTOCOLREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.PROTOCOLREGISTRY.storage");

    enum TokenType {
        ISDEX,
        ISELITE,
        ISVIP
    }

    // Token Market Data
    struct Market {
        address dexRouter;
        address gToken;
        bool isMint;
        TokenType tokenType;
        bool isTokenEnabledAsCollateral;
    }

    struct ProtocolStorage {
        uint256 govPlatformFee;
        uint256 govAutosellFee;
        uint256 govThresholdFee;
        mapping(address => address[]) approvedSps; // tokenAddress => spWalletAddress
        mapping(address => Market) approvedTokens; // tokenContractAddress => Market struct
        mapping(address => bool) approveStable; // stable coin address enable or disable in protocol registry
        address[] allApprovedSps; // array of all approved SP Wallet Addresses
        address[] allapprovedTokenContracts; // array of all Approved ERC20 Token Contracts
    }

    function protocolRegistryStorage()
        internal
        pure
        returns (ProtocolStorage storage es)
    {
        bytes32 position = PROTOCOLREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibLiquidatorStorage {
    bytes32 constant LIQUIDATOR_STORAGE =
        keccak256("diamond.standard.LIQUIDATOR.storage");
    struct LiquidatorStorage {
        mapping(address => bool) whitelistLiquidators; // list of already approved liquidators.
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
        address[] whitelistedLiquidators; // list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
        address aggregator1Inch;
        bool isInitializedLiquidator;
    }

    function liquidatorStorage()
        internal
        pure
        returns (LiquidatorStorage storage ls)
    {
        bytes32 position = LIQUIDATOR_STORAGE;
        assembly {
            ls.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibMeta} from "./../../shared/libraries/LibMeta.sol";

/**
 * @dev Library version of the OpenZeppelin Pausable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
 */
library LibPausable {
    struct Storage {
        bool paused;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("diamond.standard.Pausable.storage");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Reverts when paused.
     */
    function enforceNotPaused() internal view {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Reverts when not paused.
     */
    function enforcePaused() internal view {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view returns (bool) {
        return _storage().paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal {
        _storage().paused = true;
        emit Paused(LibMeta.msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal {
        _storage().paused = false;
        emit Unpaused(LibMeta.msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
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