// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVCPool.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IArtNft.sol";
import "../interfaces/IVCMarketplace.sol";
import "../interfaces/IVCMarketManager.sol";

contract VCGovernance {
    error GovNotWhitelistedLab();
    error GovOnlyAdmin();
    error GovInvalidAdmin();
    error GovInvalidQuorumPoll();
    error GovInvalidArtnft();

    event ProtocolSetup(
        address indexed vcPool,
        address indexed vcStarter,
        IERC20 currency,
        address marketManager,
        address artNft1155,
        address artNft721,
        address pocNft
    );

    event GovProjectCreated(address indexed lab, address indexed project, uint256 amountToRaise);
    event GovWhitelistedLab(address indexed lab);
    event GovBlacklistedLab(address indexed lab);
    event GovCurrencyListed(IERC20 indexed currency);
    event GovCurrencyUnlisted(IERC20 indexed currency);
    event GovSetMinCampaignDuration(uint256 minCampaignDuration);
    event GovSetMaxCampaignDuration(uint256 maxCampaignDuration);
    event GovSetMaxCampaignOffset(uint256 maxCampaignOffset);
    event GovSetMinCampaignTarget(uint256 minCampaignTarget);
    event GovSetMaxCampaignTarget(uint256 maxCampaignTarget);
    event GovSetSoftTargetBps(uint256 softTargetBps);
    event GovPoCNftSet(IPoCNft indexed poCNft);

    enum MarketPlace {
        FixedPrice1155,
        FixedPrice721,
        Auction721
    }

    enum ArtNft {
        ERC1155,
        ERC721
    }

    address public admin;
    IERC20 public currency;
    IERC20 public cure;
    IVCPool public pool;
    IVCStarter public starter;
    IVCMarketManager public marketManager;
    IArtNft public artNft1155;
    IArtNft public artNft721;
    IPoCNft public pocNft;

    mapping(address => bool) public isWhitelistedLab;

    constructor(IERC20 _cure, address _admin) {
        _setAdmin(_admin);
        cure = _cure;
    }

    modifier onlyWhitelistedLab(address _lab) {
        if (!isWhitelistedLab[_lab]) {
            revert GovNotWhitelistedLab();
        }
        _;
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) {
            revert GovOnlyAdmin();
        }
    }

    function setupProtocol(
        IERC20 _currency,
        address _vcPool,
        address _vcStarter,
        address _artNft1155,
        address _artNft721,
        address _pocNft,
        address _marketplaceFixedPrice1155,
        address _marketplaceFixedPrice721,
        address _marketplaceAuction721,
        address _marketManager
    ) external {
        _onlyAdmin();

        pool = IVCPool(_vcPool);
        starter = IVCStarter(_vcStarter);
        artNft1155 = IArtNft(_artNft1155);
        artNft721 = IArtNft(_artNft721);
        pocNft = IPoCNft(_pocNft);
        marketManager = IVCMarketManager(_marketManager);

        _setMarketManagerToMarketplace(_marketplaceFixedPrice1155);
        _setMarketManagerToMarketplace(_marketplaceFixedPrice721);
        _setMarketManagerToMarketplace(_marketplaceAuction721);

        _setPoCNft(_pocNft);
        _listCurrency(_currency);
        pool.setStarter(_vcStarter);

        _setMinterRoleArtNft(ArtNft.ERC1155, _marketplaceFixedPrice1155);
        _setMinterRoleArtNft(ArtNft.ERC721, _marketplaceFixedPrice721);
        _setMinterRoleArtNft(ArtNft.ERC721, _marketplaceAuction721);

        emit ProtocolSetup(_vcPool, _vcStarter, _currency, _marketManager, _artNft1155, _artNft721, _pocNft);
    }

    function setAdmin(address _newAdmin) external {
        _onlyAdmin();
        _setAdmin(_newAdmin);
    }

    function _setAdmin(address _newAdmin) private {
        if (_newAdmin == address(0) || _newAdmin == admin) {
            revert GovInvalidAdmin();
        }
        admin = _newAdmin;
    }

    function marketplaceWithdrawTo(
        MarketPlace _marketplace,
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketManager.marketplaceWithdrawTo(uint256(_marketplace), _token, _to, _amount);
    }

    function _setPoCNft(address _pocNft) internal {
        _onlyAdmin();
        pool.setPoCNft(_pocNft);
        starter.setPoCNft(_pocNft);
        marketManager.setPoCNft(_pocNft);
    }

    //////////////////////////////////////////
    // MARKETPLACE SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////////

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external {
        _onlyAdmin();
        marketManager.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external {
        _onlyAdmin();
        marketManager.setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external {
        _onlyAdmin();
        marketManager.setMarketplaceFeeBps(_marketplaceFeeBps);
    }

    /////////////////////////////////////////
    // ART NFT SETUP THROUGH GOVERNANCE    //
    /////////////////////////////////////////

    function setMinterRoleArtNft(ArtNft _artNft, address _minter) external {
        _onlyAdmin();
        _setMinterRoleArtNft(_artNft, _minter);
    }

    function _setMinterRoleArtNft(ArtNft _artNft, address _minter) private {
        if (_artNft == ArtNft.ERC1155) {
            artNft1155.grantMinterRole(_minter);
        } else if (_artNft == ArtNft.ERC721) {
            artNft721.grantMinterRole(_minter);
        } else {
            revert GovInvalidArtnft();
        }
    }

    function setRoyaltyInfoArtNft(address _receiver, uint96 _royaltyFeeBps) external {
        _onlyAdmin();
        artNft1155.setRoyaltyInfo(_receiver, _royaltyFeeBps);
        artNft721.setRoyaltyInfo(_receiver, _royaltyFeeBps);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external {
        _onlyAdmin();
        artNft1155.setMaxRoyalty(_maxRoyaltyBps);
        artNft721.setMaxRoyalty(_maxRoyaltyBps);
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external {
        _onlyAdmin();
        artNft1155.setMaxBatchSize(_maxBatchSize);
        artNft721.setMaxBatchSize(_maxBatchSize);
    }

    //////////////////////////////////////
    // STARTER SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////

    // function createProjectStarter(address _lab, uint256 _amountToRaise) external returns (address projectAddress) {
    //     _onlyAdmin();
    //     projectAddress = starter.createProject(_lab, _amountToRaise);
    //     emit GovProjectCreated(_lab, projectAddress, _amountToRaise);
    // }

    function changeAdminStarter(address starterAdmin) external {
        _onlyAdmin();
        starter.changeAdmin(starterAdmin);
    }

    function whitelistLabStarter(address lab) external {
        _onlyAdmin();
        starter.whitelistLab(lab);
        emit GovWhitelistedLab(lab);
    }

    function blacklistLabStarter(address lab) external {
        _onlyAdmin();
        starter.blacklistLab(lab);
        emit GovBlacklistedLab(lab);
    }

    // function forceNotFundedCampaignsStarter(address project, uint256[] calldata campaignIds) external {
    //     _onlyAdmin();
    //     starter.forceNotFundedCampaigns(project, campaignIds);
    // }

    function setMinCampaignDurationStarter(uint256 minCampaignDuration) external {
        _onlyAdmin();
        starter.setMinCampaignDuration(minCampaignDuration);
        emit GovSetMinCampaignDuration(minCampaignDuration);
    }

    function setMaxCampaignDurationStarter(uint256 maxCampaignDuration) external {
        _onlyAdmin();
        starter.setMaxCampaignDuration(maxCampaignDuration);
        emit GovSetMaxCampaignDuration(maxCampaignDuration);
    }

    function setMaxCampaignOffsetStarter(uint256 maxCampaignOffset) external {
        _onlyAdmin();
        starter.setMaxCampaignOffset(maxCampaignOffset);
        emit GovSetMaxCampaignOffset(maxCampaignOffset);
    }

    function setMinCampaignTargetStarter(uint256 minCampaignTarget) external {
        _onlyAdmin();
        starter.setMinCampaignTarget(minCampaignTarget);
        emit GovSetMinCampaignTarget(minCampaignTarget);
    }

    function setMaxCampaignTargetStarter(uint256 maxCampaignTarget) external {
        _onlyAdmin();
        starter.setMaxCampaignTarget(maxCampaignTarget);
        emit GovSetMaxCampaignTarget(maxCampaignTarget);
    }

    function setSoftTargetBpsStarter(uint256 softTargetBps) external {
        _onlyAdmin();
        starter.setSoftTargetBps(softTargetBps);
        emit GovSetSoftTargetBps(softTargetBps);
    }

    ////////////////
    // GOVERNANCE //
    ////////////////

    function votePower(address _account) external view returns (uint256 userVotePower) {
        uint256 userCureBalance = cure.balanceOf(_account);
        uint256 boost = pocNft.getVotingPowerBoost(_account);

        userVotePower = (userCureBalance * (10000 + boost)) / 10000;
    }

    function listCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _listCurrency(_currency);
        emit GovCurrencyListed(_currency);
    }

    function _listCurrency(IERC20 _currency) private {
        currency = _currency;
        starter.listCurrency(_currency);
        pool.setCurrency(_currency);
        marketManager.setCurrency(_currency);
    }

    function unlistCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _unlistCurrency(_currency);
        emit GovCurrencyUnlisted(_currency);
    }

    function _unlistCurrency(IERC20 _currency) private {
        starter.unlistCurrency(_currency);
    }

    function _setMarketManagerToMarketplace(address _marketPlace) private {
        IVCMarketplace(_marketPlace).setMarketManager(marketManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 _currency) external;

    function setStarter(address _starter) external;

    function supportPoolFromStarter(address _supporter, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Project {
    address _projectAddress;
    address _lab;
}

interface IVCStarter {
    function changeAdmin(address admin) external;

    function whitelistLab(address lab) external;

    function blacklistLab(address lab) external;

    function listCurrency(IERC20 currency) external;

    function unlistCurrency(IERC20 currency) external;

    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    function setMaxCampaignOffset(uint256 maxCampaignOffset) external;

    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    function setSoftTargetBps(uint256 softTargetBps) external;

    function setPoCNft(address _pocNft) external;

    function createProject(address _lab) external returns (address);

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory);

    function fundProjectOnBehalf(
        address _user,
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external;

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IArtNft {
    function exists(uint256 _tokenId) external returns (bool);

    function grantMinterRole(address _address) external;

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external;

    function setMaxBatchSize(uint256 _maxBatchSize) external;

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeBps) external;

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/marketplace/VCMarketplaceBase.sol";

enum ListStatus {
    NOT_LISTED,
    FIXED_PRICE,
    AUCTION
}

interface IVCMarketManager {
    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;

    function setMinterRoles() external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function accrueRoyalty(address _receiver, uint256 _royaltyAmount) external;

    function marketplaceWithdrawTo(
        uint256 _marketplace,
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setListStatusERC721(uint256 _tokenId, bool listed) external;

    function getListStatusERC721(uint256 _tokenId) external view returns (ListStatus);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IArtNft.sol";
import "../interfaces/IVCMarketManager.sol";

interface IVCMarketplace {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;

    function setMarketManager(IVCMarketManager _marketManager) external;
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./FeeBeneficiary.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IArtNft.sol";

abstract contract VCMarketplaceBase is FeeBeneficiary, Pausable {
    error MktCallerNotSeller();
    error MktTokenNotListed();
    error MktInsufficientBalance();
    error MktWithdrawFailed();
    error MktCallerNotManager();
    error MktAccrRoyaltiesFailed();
    error MktSettleFailed();
    error MktPurchaseFailed();
    error MktAlreadyListedOnAuction();
    error MktAlreadyListedOnFixedPrice();

    event PoCNftSet(address indexed oldPoCNft, address indexed newPoCNft);

    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IPoCNft public pocNft;

    /// @notice The Viral(Cure) Art Non-Fungible Token
    IArtNft public artNft;

    /**
     * @dev Sets the whitelisted tokens to be traded at the Marketplace.
     */
    constructor(address _artNft) {
        artNft = IArtNft(_artNft);
    }

    /**
     * @dev Pauses or unpauses the Marketplace
     */
    function pause(bool _paused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) _pause();
        else _unpause();
    }

    // IDEA: we left this function just in case, there is no real use for the moment.
    /**
     * @dev Allows the withdrawal of any `ERC20` token from the Marketplace to
     * any account. Can only be called by the owner.
     *
     * Requirements:
     *
     * - Contract balance has to be equal or greater than _amount
     *
     * @param _token: ERC20 token address to withdraw
     * @param _to: Address that will receive the transfer
     * @param _amount: Amount to withdraw
     */
    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyManager {
        uint256 totalBalance = IERC20(_token).balanceOf(address(this));
        uint256 _balanceWithdrawable = IERC20(_token) == currency
            ? totalBalance - _balanceNoTWithdrawable
            : totalBalance;

        if (_balanceWithdrawable < _amount) {
            revert MktInsufficientBalance();
        }
        if (!IERC20(_token).transfer(_to, _amount)) {
            revert MktWithdrawFailed();
        }
    }

    /**
     * @dev Sets the Proof of Collaboration Non-Fungible Token.
     */
    function setPoCNft(address _pocNft) external onlyManager {
        pocNft = IPoCNft(_pocNft);
        emit PoCNftSet(address(pocNft), _pocNft);
    }

    // this function will be changed -> transferFrom(buyer, project, amount);
    // function _fundProject(uint256 _projectId, uint256 _amount) internal override {
    //     IVCStarter(starter).fundProjectFromMarketplace(_projectId, _amount);
    // }

    /**
     * @dev Computes the royalty amount for the given tokenId and its price.
     *
     * @param _tokenId: Non-fungible token identifier
     * @param _amount: A pertinent amount used to compute the royalty.
     */
    function checkRoyalties(uint256 _tokenId, uint256 _amount)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = IERC2981(address(artNft)).royaltyInfo(_tokenId, _amount);
    }

    function _setFeesAndCheckRoyalty(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) internal {
        uint256 totalFeeBps = _setFees(_tokenId, _poolFeeBps, _projects, _projectFeesBps);
        (, uint256 royaltyBps) = checkRoyalties(_tokenId, FEE_DENOMINATOR); // It should be _feeDenominator() instead of FEE_DENOMINATOR
        if (totalFeeBps + royaltyBps > FEE_DENOMINATOR) {
            //revert MktTotalFeeTooHigh();
            revert MktTotalFeeError();
        }
    }

    function _settle(
        uint256 _tokenId,
        address _seller,
        uint256 _highestBid,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal {
        _transferFee(_tokenId, _seller, _highestBid, _starterFee, _marketFee + _poolFee);
        uint256 amountToSeller = _highestBid - _starterFee - _poolFee;

        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transfer(marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailed();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktSettleFailed();
        }
    }

    function _purchase(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal {
        if (!currency.transferFrom(msg.sender, address(this), _listPrice + _marketFee)) {
            revert MktPurchaseFailed();
        }
        _transferFee(_tokenId, _seller, _listPrice, _starterFee, _marketFee + _poolFee);
        uint256 amountToSeller = _listPrice - _starterFee - _poolFee;

        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transfer(marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailed();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktPurchaseFailed();
        }
    }

    function _checkAddressZero(address _address) internal pure {
        if (_address == address(0)) {
            revert MktTokenNotListed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../utils/FeeManager.sol";
import "../interfaces/IVCMarketManager.sol";
import "../interfaces/IVCStarter.sol";

struct TokenFeesData {
    uint256 poolFeeBps;
    uint256 starterFeeBps;
    address[] projects;
    uint256[] projectFeesBps;
}

error MktFeesDataError();
error MktAddProjectFailed();
error MktRemoveProjectFailed();
error MktTotalFeeError();
// error MktTotalFeeTooLow();
// error MktTotalFeeTooHigh();
error MktVCPoolTransferFailed();
error MktVCStarterTransferFailed();
error MktUnexpectedAddress();
error MktInactiveProject();
error MktInvalidMarketManager();
error MktOnlyMktManagerAllowed();

contract FeeBeneficiary is FeeManager, AccessControl {
    bytes32 public constant STARTER_ROLE = keccak256("STARTER_ROLE");
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");

    /// @notice The Marketplace currency
    IERC20 public currency;
    uint256 internal _balanceNoTWithdrawable;

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The VC Starter contract address
    address public starter;

    /// @notice The Marketplace marketManager
    address public marketManager;

    /// @notice The minimum fee in basis points to distribute amongst VC Pool and VC Starter Projects
    uint256 public minTotalFeeBps;

    /// @notice The VC Marketplace fee in basis points
    uint256 public marketplaceFeeBps;

    /// @notice The maximum amount of projects a token seller can support
    uint96 public maxBeneficiaryProjects;

    event ProjectAdded(address indexed project, uint256 time);
    event ProjectRemoved(address indexed project, uint256 time);
    event CurrencySet(address indexed oldCurrency, address indexed newCurrency);

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(uint256 => mapping(address => TokenFeesData)) _tokenFeesData;

    /**
     * @dev Maps a project id to its beneficiary status.
     */
    //mapping(address => bool) internal _isActiveProject;

    modifier onlyManager() {
        if (msg.sender != marketManager) {
            revert MktOnlyMktManagerAllowed();
        }
        _;
    }

    /**
     * @dev Constructor
     */
    constructor(
        address _pool,
        address _starter,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFeeBps,
        uint96 _maxBeneficiaryProjects
    ) {
        _checkAddress(_pool);
        _checkAddress(_starter);

        _setMinTotalFeeBps(_minTotalFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);

        _grantRole(POOL_ROLE, _pool);
        _grantRole(STARTER_ROLE, _starter);

        pool = _pool;
        starter = _starter;
    }

    function setMarketManager(address _marketManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketManager = _marketManager;
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external onlyManager {
        _setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external onlyManager {
        _setMarketplaceFeeBps(_marketplaceFee);
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public onlyManager {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Removes a project as a beneficiary candidate.
     *
     * @param _project the project address to remove.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    // function removeProject(address _project) public onlyRole(STARTER_ROLE) {
    //     if (!_isActiveProject[_project]) {
    //         revert MktRemoveProjectFailed();
    //     }
    //     _isActiveProject[_project] = false;
    //     emit ProjectRemoved(_project, block.timestamp);
    // }

    /**
     * @dev Adds a project as a beneficiary candidate.
     *
     * @param _project the project address to add.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    // function addProject(address _project) public onlyRole(STARTER_ROLE) {
    //     if (_isActiveProject[_project]) {
    //         revert MktAddProjectFailed();
    //     }
    //     _isActiveProject[_project] = true;
    //     emit ProjectAdded(_project, block.timestamp);
    // }

    /**
     * @dev Returns True if the project is active or False if is not.
     *
     * @param _project the project address.
     */
    // function isActiveProject(address _project) public view returns (bool) {
    //     return _isActiveProject[_project];
    // }

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @param _tokenId: Non-fungible token identifier
     */
    function getFeesData(uint256 _tokenId, address _seller) public view returns (TokenFeesData memory result) {
        return _tokenFeesData[_tokenId][_seller];
    }

    /**
     * @dev Constructs a `TokenFeesData` struct which stores the total fees in
     * bips that will be transferred to both the pool and the starter smart
     * contracts.
     *
     * @param _tokenId NFT token ID
     * @param _projects Array of Project addresses to support
     * @param _projectFeesBps Array of fees to support each project ID
     */
    function _setFees(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) internal returns (uint256) {
        if (_projects.length != _projectFeesBps.length || _projects.length > maxBeneficiaryProjects) {
            revert MktFeesDataError();
        }

        uint256 starterFeeBps;
        for (uint256 i = 0; i < _projectFeesBps.length; i++) {
            // if (!_isActiveProject[_projects[i]]) {
            //     revert MktInactiveProject();
            // }
            starterFeeBps += _projectFeesBps[i];
        }

        uint256 totalFeeBps = _poolFeeBps + starterFeeBps;

        if (totalFeeBps < minTotalFeeBps || totalFeeBps > FEE_DENOMINATOR) {
            //revert MktTotalFeeTooLow();
            revert MktTotalFeeError();
        }

        // if (totalFeeBps > FEE_DENOMINATOR) {
        //     revert MktTotalFeeTooHigh();
        // }

        _tokenFeesData[_tokenId][msg.sender] = TokenFeesData(_poolFeeBps, starterFeeBps, _projects, _projectFeesBps);

        return totalFeeBps;
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart contracts when the token is bought.
     *
     * @param _tokenId Non-fungible token identifier
     * @param _price Token price
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     */
    function _transferFee(
        uint256 _tokenId,
        address _seller,
        uint256 _price,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal {
        if (_starterFee > 0) {
            TokenFeesData storage feesData = _tokenFeesData[_tokenId][_seller];
            _poolFee += _fundProjects(feesData, _price);
        }
        if (_poolFee > 0 && !currency.transfer(pool, _poolFee)) {
            revert MktVCPoolTransferFailed();
        }
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     */
    function _fundProjects(TokenFeesData storage _feesData, uint256 _listPrice) internal returns (uint256 toPool) {

        bool[] memory activeProjects = IVCStarter(starter).areActiveProjects(_feesData.projects);

        for (uint256 i = 0; i < activeProjects.length; i++) {
            uint256 amount = _toFee(_listPrice, _feesData.projectFeesBps[i]);
            if (amount > 0) {
                if (activeProjects[i] == true) {
                    IVCStarter(starter).fundProjectOnBehalf(msg.sender, _feesData.projects[i], currency, amount);
                } else {
                    toPool += amount;
                }
            }
        }
    }

    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddress();
        }
    }

    /**
     * @dev Sets the Marketplace currency.
     */
    function setCurrency(IERC20 _currency) external onlyManager {
        currency = _currency;
        emit CurrencySet(address(currency), address(_currency));
    }

    function _setMinTotalFeeBps(uint256 _minTotalFeeBps) private {
        minTotalFeeBps = _minTotalFeeBps;
    }

    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     */
    function _splitListPrice(TokenFeesData memory _feesData, uint256 _listPrice)
        internal
        pure
        returns (
            uint256 starterFee,
            uint256 poolFee,
            uint256 resultingAmount
        )
    {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FeeManager {
    /// @notice Used to translate from basis points to amounts
    uint96 public constant FEE_DENOMINATOR = 10_000;

    /**
     * @dev Translates a fee in basis points to a fee amount.
     */
    function _toFee(uint256 _amount, uint256 _feeBps) internal pure returns (uint256) {
        return (_amount * _feeBps) / FEE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
                        Strings.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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