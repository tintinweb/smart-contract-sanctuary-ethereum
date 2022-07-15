// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../chainlink/VRFConsumerBaseUpgradeable.sol";
import "../DataTypes.sol";
import "../interfaces/PriceOracleSpec.sol";

/**
 * @title Minter
 * @notice Allow users to request minting Illuvitars.
 * @dev Users can use ETH or sILV to request minting.
 * @dev Minter uses an chainlink VRF to genrate randomness.
 * @author Dmitry Yakovlevich
 */
contract Minter is VRFConsumerBaseUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint16 private constant MAX_CHANCE = 10000; // 100%
    uint8 private constant TIER_CHANCE_LEN = 4;
    /// @dev expression count - Normal, Expression A, Expression B
    uint8 private constant EXPRESSION_COUNT = 3;
    uint8 private constant STAGE_COUNT = 3;
    /// @dev 0: without accessory
    ///      1: bonded 1 slot
    ///      2: bonded 2 slot
    ///      3: bonded 3 slot
    ///      4: bonded 4 slot
    ///      5: bonded 5 slot
    uint8 private constant PORTRAIT_MASK = 6;

    /// @dev Portrait mint information
    mapping(BoxType => PortraitMintInfo) public portraitMintInfo;
    /// @dev Accessory mint information
    mapping(BoxType => AccessoryMintInfo) public accessoryMintInfo;
    /// @dev expression probability
    uint16[EXPRESSION_COUNT] private expressionProbability;
    /// @dev stage probability
    uint16[STAGE_COUNT] private stageProbability;

    /// @dev Background tier chances
    mapping(uint8 => mapping(BoxType => uint16[4])) public backgroundTierChances;
    /// @dev Background line info per tier
    mapping(uint8 => BackgroundLine[]) public backgroundLines;
    /// @dev Background stages info per (tier, line)
    mapping(uint8 => mapping(BackgroundLine => uint8[])) public backgroundStages;
    /// @dev Background variation count per (tier, line, stage)
    mapping(uint8 => mapping(BackgroundLine => mapping(uint8 => uint8))) public backgroundVariations;
    /// @dev Illuvial count per tier
    uint8[6] private illuvialCounts;

    /// @dev User's mint requests
    mapping(bytes32 => MintRequest) public mintRequests;
    /// @dev User's free mint requests
    mapping(uint256 => MintRequest) public freeRequests;
    /// @dev Free requests count
    uint256 public freeRequestCount;
    /// @dev Portrait sale window
    SaleWindow public portraitSaleWindow;

    /// @dev sILV2 token address
    address public sIlv;
    /// @dev treasury address
    address public treasury;
    /// @dev ILV/ETH Chainlink price feed address
    IlluvitarsPriceOracle public illuvitarsPriceOracle;
    /// @dev chainlink VRF key hash
    bytes32 private vrfKeyHash;
    /// @dev chainlink VRF fee
    uint256 private vrfFee;
    /// @dev Next portrait token id to mint
    uint256 private nextPortraitTokenId;
    /// @dev Next accessory token id to mint
    uint256 private nextAccessoryTokenId;
    uint256 public freePortraitLimitPerTx;
    uint256 public freeAccessoryLimitPerTx;

    /* ======== EVENTS ======== */
    /// @dev Emitted when treasury updated.
    event TreasurySet(address indexed treasury);
    /// @dev Emitted when user request mint.
    event MintRequested(address indexed requester, bytes32 requestId);
    /// @dev Emitted when user request free mint.
    event FreeMintRequested(address indexed requester, uint256 idx);
    /// @dev Emitted when chainlink fulfilled VRF request.
    event RequestFulfilled(bytes32 indexed requestId, uint256 randomNumber);

    /* ======== STRUCT ======== */
    /// @dev Portrait mint params
    struct PortraitMintParams {
        BoxType boxType;
        uint64 amount;
    }

    /// @dev Accessory semi random mint params
    struct AccessorySemiRandomMintParams {
        AccessoryType accessoryType;
        BoxType boxType;
        uint64 amount;
    }

    /// @dev Accessory full random mint params
    struct AccessoryFullRandomMintParams {
        BoxType boxType;
        uint64 amount;
    }

    /// @dev User's mint request data
    struct MintRequest {
        address requester;
        PortraitMintParams[] portraitMintParams;
        uint256 portraitAmount; // total portrait amount
        AccessorySemiRandomMintParams[] accessorySemiRandomMintParams;
        AccessoryFullRandomMintParams[] accessoryFullRandomMintParams;
        uint256 accessoryAmount; // total accessory amount
        uint256 randomNumber; // random number from chainlink
        uint256 portraitStartTokenId; // portrait start token id for this request
        uint256 accessoryStartTokenId; // accessory start token id for this request
    }

    /// @dev Mintable portrait info
    struct PortraitInfo {
        uint256 tokenId;
        BoxType boxType;
        uint8 tier;
        uint8 illuvial;
        uint8 backgroundTier;
        BackgroundLine backgroundLine;
        uint8 backgroundStage;
        uint8 backgroundVariation;
        ExpressionType expression;
        FinishType finish;
    }

    /// @dev Mintable accessory info
    struct AccessoryInfo {
        uint256 tokenId;
        BoxType boxType;
        AccessoryType accessoryType;
        uint8 tier;
        uint8 stage;
    }

    /// @dev Portrait price and tier pick chances for each box type
    struct PortraitMintInfo {
        uint256 price; // price
        uint16[TIER_CHANCE_LEN] tierChances; // tier chances
        uint16 holoProbability; // Holo probability
    }

    /// @dev Accessory semi and random price and tier pick chances for each box type
    struct AccessoryMintInfo {
        uint256 randomPrice; // full random price
        uint256 semiRandomPrice; // semi random price
        uint16[TIER_CHANCE_LEN] tierChances; // tier chances
    }

    /// @dev Sale window
    struct SaleWindow {
        uint64 start;
        uint64 end;
    }

    /**
     * @dev UUPSUpgradeable initializer
     * @param _vrfCoordinator Chainlink VRF Coordinator address
     * @param _linkToken LINK token address
     * @param _vrfKeyhash Chainlink VRF Key Hash
     * @param _vrfFee Chainlink VRF Fee
     * @param _treasury Treasury address
     * @param _sIlv sILV2 token address
     * @param _illuvitarsPriceOracle ILV/ETH Chainlink price feed base illuvitars price oracle
     */
    function initialize(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _vrfKeyhash,
        uint256 _vrfFee,
        address _treasury,
        address _sIlv,
        address _illuvitarsPriceOracle
    ) external initializer {
        require(
            _treasury != address(0) && _illuvitarsPriceOracle != address(0) && _sIlv != address(0),
            "cannot zero address"
        );

        __Ownable_init();
        __VRFConsumerBase_init(_vrfCoordinator, _linkToken);

        vrfKeyHash = _vrfKeyhash;
        vrfFee = _vrfFee;
        sIlv = _sIlv;
        treasury = _treasury;
        illuvitarsPriceOracle = IlluvitarsPriceOracle(_illuvitarsPriceOracle);
        nextPortraitTokenId = 1;
        nextAccessoryTokenId = 1;

        _initializePortraitMintInfo();
        _initializeAccessoryMintInfo();
        _initializeBackgroundGenerationInfo();
    }

    /**
     * @dev Set portrait sale window.
     * @dev only owner can call this function.
     * @param _saleWindow New sale window.
     */
    function setPortraitSaleWindow(SaleWindow calldata _saleWindow) external onlyOwner {
        require(_saleWindow.start < _saleWindow.end, "Invalid sale window");
        portraitSaleWindow = _saleWindow;
    }

    function setFreeMintLimitPerTx(uint256 _freePortraitLimitPerTx, uint256 _freeAccessoryLimitPerTx)
        external
        onlyOwner
    {
        freePortraitLimitPerTx = _freePortraitLimitPerTx;
        freeAccessoryLimitPerTx = _freeAccessoryLimitPerTx;
    }

    /**
     * @dev Set new treasury address.
     * @dev only owner can call this function.
     * @param treasury_ Treasury Address.
     */
    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "Treasury address cannot zero");
        treasury = treasury_;

        emit TreasurySet(treasury_);
    }

    /**
     * @dev Withdraw ether and sILV to treasury address.
     * @dev only owner can call this function.
     */
    function withdraw() external onlyOwner {
        uint256 etherBalance = address(this).balance;
        if (etherBalance != 0) {
            (bool success, ) = treasury.call{ value: etherBalance }("");
            require(success, "Ether withdraw failed");
        }

        uint256 sIlvBalance = IERC20Upgradeable(sIlv).balanceOf(address(this));
        if (sIlvBalance != 0) {
            IERC20Upgradeable(sIlv).safeTransfer(treasury, sIlvBalance);
        }
    }

    /**
     * @notice Mint for random accessory, callback for VRFConsumerBase
     * @dev inaccessible from outside
     * @param requestId requested random accesory Id.
     * @param randomNumber Random Number.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        require(mintRequests[requestId].requester != address(0), "No request exist");
        require(mintRequests[requestId].randomNumber == 0, "Random number already fulfilled");

        mintRequests[requestId].randomNumber = randomNumber;

        emit RequestFulfilled(requestId, randomNumber);
    }

    /**
     * @dev Request minting Portrait and Accesory NFTs.
     * @notice Users pay ETH or sILV to request minting
     * @param portraitMintParams portrait layer mint params.
     * @param accessorySemiRandomMintParams accessory layer semi random mint params.
     * @param accessoryFullRandomMintParams accessory layer full random mint params.
     * @param useSIlv true to use sILV, false to use ETH.
     */
    function paidMint(
        PortraitMintParams[] calldata portraitMintParams,
        AccessorySemiRandomMintParams[] calldata accessorySemiRandomMintParams,
        AccessoryFullRandomMintParams[] calldata accessoryFullRandomMintParams,
        bool useSIlv
    ) public payable {
        uint256 etherPrice;

        bytes32 requestId = requestRandomness(vrfKeyHash, vrfFee);

        MintRequest storage mintRequest = mintRequests[requestId];
        require(mintRequest.requester == address(0), "Already requested");
        mintRequest.requester = msg.sender;

        etherPrice = _storePortraitRequest(mintRequest, portraitMintParams, false);
        etherPrice += _storeAccessoryRequest(
            mintRequest,
            accessorySemiRandomMintParams,
            accessoryFullRandomMintParams,
            false
        );

        unchecked {
            if (useSIlv && etherPrice != 0) {
                IERC20Upgradeable(sIlv).safeTransferFrom(
                    msg.sender,
                    address(this),
                    uint256(illuvitarsPriceOracle.ethToIlv(etherPrice))
                );
                etherPrice = 0;
            } else {
                require(msg.value >= etherPrice, "Not enough ethers sent");
            }
            payable(msg.sender).transfer(msg.value - etherPrice);
        }

        emit MintRequested(msg.sender, requestId);
    }

    function _storePortraitRequest(
        MintRequest storage mintRequest,
        PortraitMintParams[] calldata portraitMintParams,
        bool isFree
    ) internal returns (uint256 etherPrice) {
        uint256 length = portraitMintParams.length;
        if (length > 0) {
            require(
                block.timestamp >= portraitSaleWindow.start && block.timestamp <= portraitSaleWindow.end,
                "Sale not started or ended"
            );
        }

        uint256 portraitAmount;
        for (uint256 i = 0; i < length; i += 1) {
            PortraitMintParams memory param = portraitMintParams[i];
            require(param.amount != 0, "Invalid amount");
            require(isFree == (param.boxType == BoxType.Virtual), "Invalid box type");
            if (!isFree) {
                etherPrice += uint256(param.amount) * portraitMintInfo[param.boxType].price;
            }
            portraitAmount += uint256(param.amount);
            mintRequest.portraitMintParams.push(param);
        }

        require(!isFree || portraitAmount <= freePortraitLimitPerTx, "Exceed limit");

        mintRequest.portraitAmount = portraitAmount;
        mintRequest.portraitStartTokenId = nextPortraitTokenId;
        nextPortraitTokenId += PORTRAIT_MASK * portraitAmount;
    }

    function _storeAccessoryRequest(
        MintRequest storage mintRequest,
        AccessorySemiRandomMintParams[] calldata accessorySemiRandomMintParams,
        AccessoryFullRandomMintParams[] calldata accessoryFullRandomMintParams,
        bool isFree
    ) internal returns (uint256 etherPrice) {
        uint256 length = accessorySemiRandomMintParams.length;

        uint256 accessoryAmount;
        for (uint256 i = 0; i < length; i += 1) {
            AccessorySemiRandomMintParams memory param = accessorySemiRandomMintParams[i];
            require(param.amount != 0, "Invalid amount");
            require(isFree == (param.boxType == BoxType.Virtual), "Invalid box type");
            if (!isFree) {
                etherPrice += uint256(param.amount) * accessoryMintInfo[param.boxType].semiRandomPrice;
            }
            accessoryAmount += uint256(param.amount);
            mintRequest.accessorySemiRandomMintParams.push(param);
        }

        length = accessoryFullRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            AccessoryFullRandomMintParams memory param = accessoryFullRandomMintParams[i];
            require(param.amount != 0, "Invalid amount");
            require(isFree == (param.boxType == BoxType.Virtual), "Invalid box type");
            if (!isFree) {
                etherPrice += uint256(param.amount) * accessoryMintInfo[param.boxType].randomPrice;
            }
            accessoryAmount += uint256(param.amount);
            mintRequest.accessoryFullRandomMintParams.push(param);
        }

        require(!isFree || accessoryAmount <= freeAccessoryLimitPerTx, "Exceed limit");

        mintRequest.accessoryAmount = accessoryAmount;
        mintRequest.accessoryStartTokenId = nextAccessoryTokenId;
        nextAccessoryTokenId += accessoryAmount;
    }

    /**
     * @dev Request minting Portrait and Accesory NFTs.
     * @notice Users pay ETH or sILV to request minting
     * @param portraitMintParams portrait layer mint params.
     * @param accessorySemiRandomMintParams accessory layer semi random mint params.
     * @param accessoryFullRandomMintParams accessory layer full random mint params.
     */
    function freeMint(
        PortraitMintParams[] calldata portraitMintParams,
        AccessorySemiRandomMintParams[] calldata accessorySemiRandomMintParams,
        AccessoryFullRandomMintParams[] calldata accessoryFullRandomMintParams
    ) public {
        MintRequest storage mintRequest = freeRequests[freeRequestCount];
        mintRequest.requester = msg.sender;

        _storePortraitRequest(mintRequest, portraitMintParams, true);
        _storeAccessoryRequest(mintRequest, accessorySemiRandomMintParams, accessoryFullRandomMintParams, true);

        emit FreeMintRequested(msg.sender, freeRequestCount);
        freeRequestCount += 1;

        mintRequest.randomNumber = uint256(keccak256(abi.encode(freeRequestCount, block.timestamp)));
    }

    /**
     * @dev Get paid mintable portrait and accessory infos with chainlink random number
     * @param requestId Request id of mint request.
     * @return requester Requester address
     * @return seed Seed random number from chainlink
     * @return portraits Mintable portrait on-chain metadata
     * @return accessories Mintable accessory on-chain metadata
     */
    function getPaidMintResult(bytes32 requestId)
        external
        view
        returns (
            address requester,
            uint256 seed,
            PortraitInfo[] memory portraits,
            AccessoryInfo[] memory accessories
        )
    {
        require(mintRequests[requestId].randomNumber != 0, "No random number generated");
        MintRequest memory mintRequest = mintRequests[requestId];
        requester = mintRequest.requester;
        seed = mintRequest.randomNumber;

        uint256 rand = seed;
        if (mintRequest.portraitAmount != 0) {
            (portraits, rand) = _getPortraitsInfo(
                rand,
                mintRequest.portraitMintParams,
                mintRequest.portraitAmount,
                mintRequest.portraitStartTokenId
            );
        }

        if (
            mintRequest.accessoryFullRandomMintParams.length > 0 || mintRequest.accessorySemiRandomMintParams.length > 0
        ) {
            accessories = _getAccessoriesInfo(
                rand,
                mintRequest.accessoryFullRandomMintParams,
                mintRequest.accessorySemiRandomMintParams,
                mintRequest.accessoryStartTokenId
            );
        }
    }

    /**
     * @dev Get free mintable portrait and accessory infos with pseudo-random number
     * @param idx Request id of mint request.
     * @return requester Requester address
     * @return seed Seed random number from chainlink
     * @return portraits Mintable portrait on-chain metadata
     * @return accessories Mintable accessory on-chain metadata
     */
    function getFreeMintResult(uint256 idx)
        external
        view
        returns (
            address requester,
            uint256 seed,
            PortraitInfo[] memory portraits,
            AccessoryInfo[] memory accessories
        )
    {
        MintRequest memory mintRequest = freeRequests[idx];
        requester = mintRequest.requester;
        require(requester != address(0), "No request");
        seed = mintRequest.randomNumber;

        uint256 rand = seed;
        if (mintRequest.portraitAmount > 0) {
            (portraits, rand) = _getPortraitsInfo(
                rand,
                mintRequest.portraitMintParams,
                mintRequest.portraitAmount,
                mintRequest.portraitStartTokenId
            );
        }

        if (
            mintRequest.accessoryFullRandomMintParams.length > 0 || mintRequest.accessorySemiRandomMintParams.length > 0
        ) {
            accessories = _getAccessoriesInfo(
                rand,
                mintRequest.accessoryFullRandomMintParams,
                mintRequest.accessorySemiRandomMintParams,
                mintRequest.accessoryStartTokenId
            );
        }
    }

    /**
     * @dev Internal method to get mintable portrait infos
     * @param seed Seed random number to generate portrait infos
     * @param portraitMintParams Users portrait mint params
     * @return portraits Mintable portrait on-chain metadata
     * @return nextRand Last random number to generate accessory metadata
     */
    function _getPortraitsInfo(
        uint256 seed,
        PortraitMintParams[] memory portraitMintParams,
        uint256 portraitAmount,
        uint256 startTokenId
    ) internal view returns (PortraitInfo[] memory portraits, uint256 nextRand) {
        uint256 length = portraitMintParams.length;

        uint256 tokenId = startTokenId;
        nextRand = seed;

        portraits = new PortraitInfo[](portraitAmount);
        uint256 idx;

        for (uint256 i = 0; i < length; i += 1) {
            PortraitMintParams memory mintParam = portraitMintParams[i];
            uint256 amount = mintParam.amount;

            for (uint256 j = 0; j < amount; j += 1) {
                (portraits[idx], nextRand, tokenId) = _getPortraitInfo(nextRand, mintParam, tokenId);
                idx += 1;
            }
        }
    }

    /**
     * @dev Internal method to get portrait info
     * @param rand Random number
     * @param mintParam Portrait mint params
     * @param tokenId token id
     * @return portrait Mintable portrait on-chain metadata
     * @return nextRand Next random number
     * @return nextTokenId Next item token id
     */
    function _getPortraitInfo(
        uint256 rand,
        PortraitMintParams memory mintParam,
        uint256 tokenId
    )
        internal
        view
        returns (
            PortraitInfo memory portrait,
            uint256 nextRand,
            uint256 nextTokenId
        )
    {
        uint256 _rand;

        portrait.tokenId = tokenId;
        portrait.boxType = mintParam.boxType;
        uint8 tier;
        if (mintParam.boxType == BoxType.Virtual) {
            _rand = rand;
        } else {
            uint16 chance;
            (_rand, chance) = _getQuotientAndRemainder16(rand, MAX_CHANCE);
            tier = _getTier(portraitMintInfo[mintParam.boxType].tierChances, chance);
            portrait.tier = tier;
            (_rand, portrait.backgroundTier) = _getBackgroundTier(tier, mintParam.boxType, _rand);
        }

        (_rand, portrait.illuvial) = _getQuotientAndRemainder8(_rand, illuvialCounts[tier]);

        uint8 backgroundIdx;
        (_rand, backgroundIdx) = _getQuotientAndRemainder8(
            _rand,
            uint8(backgroundLines[portrait.backgroundTier].length)
        );
        portrait.backgroundLine = backgroundLines[portrait.backgroundTier][backgroundIdx];

        (_rand, backgroundIdx) = _getQuotientAndRemainder8(
            _rand,
            uint8(backgroundStages[portrait.backgroundTier][portrait.backgroundLine].length)
        );
        portrait.backgroundStage = backgroundStages[portrait.backgroundTier][portrait.backgroundLine][backgroundIdx];

        (_rand, portrait.backgroundVariation) = _getQuotientAndRemainder8(
            _rand,
            backgroundVariations[portrait.backgroundTier][portrait.backgroundLine][portrait.backgroundStage]
        );

        (_rand, portrait.expression) = _getExpression(_rand);
        (, portrait.finish) = _getFinish(_rand, mintParam.boxType);

        nextTokenId = tokenId + PORTRAIT_MASK;
        nextRand = uint256(keccak256(abi.encode(rand, rand)));
    }

    /**
     * @dev Internal method to get semi accessory info
     * @param rand Random number
     * @param mintParam Accessory semi mint params
     * @param tokenId token id
     * @return accessory Mintable accessory on-chain metadata
     * @return nextRand Next random number
     * @return nextTokenId Next item token id
     */
    function _getSemiAcccessoryInfo(
        uint256 rand,
        AccessorySemiRandomMintParams memory mintParam,
        uint256 tokenId
    )
        internal
        view
        returns (
            AccessoryInfo memory accessory,
            uint256 nextRand,
            uint256 nextTokenId
        )
    {
        uint256 _rand;

        accessory.tokenId = tokenId;
        accessory.boxType = mintParam.boxType;
        accessory.accessoryType = mintParam.accessoryType;
        uint8 tier;
        if (mintParam.boxType == BoxType.Virtual) {
            _rand = rand;
        } else {
            uint16 chance;
            (_rand, chance) = _getQuotientAndRemainder16(rand, MAX_CHANCE);
            tier = _getTier(accessoryMintInfo[mintParam.boxType].tierChances, chance);
            accessory.tier = tier;
        }

        (, accessory.stage) = _getAccessoryStage(_rand);

        nextTokenId = tokenId + 1;
        nextRand = uint256(keccak256(abi.encode(rand, rand)));
    }

    /**
     * @dev Internal method to get full accessory info
     * @param rand Random number
     * @param mintParam Accessory full mint params
     * @param tokenId token id
     * @return accessory Mintable accessory on-chain metadata
     * @return nextRand Next random number
     * @return nextTokenId Next item token id
     */
    function _getFullAcccessoryInfo(
        uint256 rand,
        AccessoryFullRandomMintParams memory mintParam,
        uint256 tokenId
    )
        internal
        view
        returns (
            AccessoryInfo memory accessory,
            uint256 nextRand,
            uint256 nextTokenId
        )
    {
        uint256 _rand;

        accessory.tokenId = tokenId;
        accessory.boxType = mintParam.boxType;
        uint8 tier;
        if (mintParam.boxType == BoxType.Virtual) {
            _rand = rand;
        } else {
            uint16 chance;
            (_rand, chance) = _getQuotientAndRemainder16(rand, MAX_CHANCE);
            tier = _getTier(accessoryMintInfo[mintParam.boxType].tierChances, chance);
            accessory.tier = tier;
        }

        accessory.accessoryType = AccessoryType(uint8(_rand % 5));

        (, accessory.stage) = _getAccessoryStage(_rand);

        nextTokenId = tokenId + 1;
        nextRand = uint256(keccak256(abi.encode(rand, rand)));
    }

    /**
     * @dev Internal method to get mintable accessories infos
     * @param seed Seed random number to generate portrait infos
     * @param fullRandomMintParams Users accessory full mint params
     * @param semiRandomMintParams Users accessory semi mint params
     * @return accessories Mintable accessory on-chain metadata
     */
    function _getAccessoriesInfo(
        uint256 seed,
        AccessoryFullRandomMintParams[] memory fullRandomMintParams,
        AccessorySemiRandomMintParams[] memory semiRandomMintParams,
        uint256 startTokenId
    ) internal view returns (AccessoryInfo[] memory accessories) {
        uint256 fullRandomAmount;
        uint256 semiRandomAmount;
        uint256 length = fullRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            fullRandomAmount += fullRandomMintParams[i].amount;
        }

        uint256 tokenId = startTokenId;
        length = semiRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            semiRandomAmount += semiRandomMintParams[i].amount;
        }

        uint256 idx;
        uint256 nextRand = seed;
        accessories = new AccessoryInfo[](semiRandomAmount + fullRandomAmount);

        for (uint256 i = 0; i < length; i += 1) {
            AccessorySemiRandomMintParams memory mintParam = semiRandomMintParams[i];
            uint256 amount = mintParam.amount;
            for (uint256 j = 0; j < amount; j += 1) {
                (accessories[idx], nextRand, tokenId) = _getSemiAcccessoryInfo(nextRand, mintParam, tokenId);
                idx += 1;
            }
        }

        length = fullRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            AccessoryFullRandomMintParams memory mintParam = fullRandomMintParams[i];
            uint256 amount = mintParam.amount;
            for (uint256 j = 0; j < amount; j += 1) {
                (accessories[idx], nextRand, tokenId) = _getFullAcccessoryInfo(nextRand, mintParam, tokenId);
                idx += 1;
            }
        }
    }

    function setPortraitMintInfo(BoxType boxType, PortraitMintInfo memory mintInfo) external onlyOwner {
        require(boxType != BoxType.Virtual, "Cannot set virtual info");
        _validateTierChances(mintInfo.tierChances);

        portraitMintInfo[boxType] = mintInfo;
    }

    function setAccessoryMintInfo(BoxType boxType, AccessoryMintInfo memory mintInfo) external onlyOwner {
        require(boxType != BoxType.Virtual, "Cannot set virtual info");
        _validateTierChances(mintInfo.tierChances);

        accessoryMintInfo[boxType] = mintInfo;
    }

    function _validateTierChances(uint16[TIER_CHANCE_LEN] memory tierChances) internal pure {
        for (uint256 i = 0; i < TIER_CHANCE_LEN - 1; i += 1) {
            require(tierChances[i] <= tierChances[i + 1], "Invalid tier chance");
        }
        require(tierChances[TIER_CHANCE_LEN - 1] <= MAX_CHANCE, "Invalid tier chance");
    }

    /**
     * @dev Initialize portrait mint information
     * @notice Price and tier chances are constant
     */
    function _initializePortraitMintInfo() internal {
        expressionProbability = [5000, 8000, 10000];
        illuvialCounts = [3, 6, 5, 4, 4, 3];
    }

    /**
     * @dev Initialize accessory mint information
     * @notice Price and tier chances are constant
     */
    function _initializeAccessoryMintInfo() internal {
        stageProbability = [4500, 8000, 10000];
    }

    /**
     * @dev Initialize background tier chances
     */
    function _initializeBackgroundGenerationInfo() internal {
        // tier 1
        backgroundTierChances[1][BoxType.Bronze] = [6457, 9201, 9758, 9919];
        backgroundTierChances[1][BoxType.Silver] = [3948, 7443, 9191, 9838];
        backgroundTierChances[1][BoxType.Gold] = [1067, 4800, 7733, 9333];
        backgroundTierChances[1][BoxType.Platinum] = [143, 1000, 2929, 7500];
        backgroundTierChances[1][BoxType.Diamond] = [48, 435, 1525, 3946];

        // tier 2
        backgroundTierChances[2][BoxType.Bronze] = [8700, 9624, 9874, 9956];
        backgroundTierChances[2][BoxType.Silver] = [6912, 8442, 9462, 9887];
        backgroundTierChances[2][BoxType.Gold] = [2775, 5203, 7746, 9307];
        backgroundTierChances[2][BoxType.Platinum] = [385, 962, 2693, 7308];
        backgroundTierChances[2][BoxType.Diamond] = [126, 378, 1324, 3690];

        // tier 3
        backgroundTierChances[3][BoxType.Bronze] = [8636, 9859, 9942, 9978];
        backgroundTierChances[3][BoxType.Silver] = [7248, 9387, 9743, 9941];
        backgroundTierChances[3][BoxType.Gold] = [3512, 7610, 8683, 9561];
        backgroundTierChances[3][BoxType.Platinum] = [750, 2250, 3375, 7375];
        backgroundTierChances[3][BoxType.Diamond] = [253, 928, 1561, 3671];

        // tier 4
        backgroundTierChances[4][BoxType.Bronze] = [8499, 9854, 9976, 9989];
        backgroundTierChances[4][BoxType.Silver] = [7042, 9380, 9899, 9971];
        backgroundTierChances[4][BoxType.Gold] = [3416, 7900, 9466, 9786];
        backgroundTierChances[4][BoxType.Platinum] = [1081, 3513, 5945, 8107];
        backgroundTierChances[4][BoxType.Diamond] = [428, 1711, 3315, 4652];

        // tier 5
        backgroundTierChances[5][BoxType.Bronze] = [8402, 9830, 9975, 9996];
        backgroundTierChances[5][BoxType.Silver] = [6846, 9270, 9876, 9988];
        backgroundTierChances[5][BoxType.Gold] = [3200, 7680, 9440, 9920];
        backgroundTierChances[5][BoxType.Platinum] = [1000, 3400, 6100, 9300];
        backgroundTierChances[5][BoxType.Diamond] = [535, 2246, 4652, 7326];

        // background line, stage, variation info
        backgroundLines[0] = [BackgroundLine.Dots];
        backgroundStages[0][BackgroundLine.Dots] = [1];
        backgroundVariations[0][BackgroundLine.Dots][1] = 10;

        backgroundLines[1] = [BackgroundLine.Flash];
        backgroundStages[1][BackgroundLine.Flash] = [1];
        backgroundVariations[1][BackgroundLine.Flash][1] = 10;

        backgroundLines[2] = [BackgroundLine.Hex, BackgroundLine.Rain];
        backgroundStages[2][BackgroundLine.Hex] = [2];
        backgroundStages[2][BackgroundLine.Rain] = [3];
        backgroundVariations[2][BackgroundLine.Hex][2] = 8;
        backgroundVariations[2][BackgroundLine.Rain][3] = 8;

        backgroundLines[3] = [BackgroundLine.Spotlight, BackgroundLine.Mozart];
        backgroundStages[3][BackgroundLine.Spotlight] = [3];
        backgroundStages[3][BackgroundLine.Mozart] = [2];
        backgroundVariations[3][BackgroundLine.Spotlight][3] = 5;
        backgroundVariations[3][BackgroundLine.Mozart][2] = 8;

        backgroundLines[4] = [BackgroundLine.Affinity, BackgroundLine.Arena];
        backgroundStages[4][BackgroundLine.Affinity] = [1];
        backgroundStages[4][BackgroundLine.Arena] = [1];
        backgroundVariations[4][BackgroundLine.Affinity][1] = 5;
        backgroundVariations[4][BackgroundLine.Arena][1] = 2;

        backgroundLines[5] = [BackgroundLine.Token, BackgroundLine.Encounter];
        backgroundStages[5][BackgroundLine.Token] = [1, 2];
        backgroundStages[5][BackgroundLine.Encounter] = [3];
        backgroundVariations[5][BackgroundLine.Token][1] = 1;
        backgroundVariations[5][BackgroundLine.Token][2] = 1;
        backgroundVariations[5][BackgroundLine.Encounter][3] = 2;
    }

    function _getTier(uint16[TIER_CHANCE_LEN] memory tierChances, uint16 chance) internal pure returns (uint8) {
        for (uint8 k = 0; k < TIER_CHANCE_LEN; k += 1) {
            if (tierChances[k] > chance) {
                return k + 1;
            }
        }
        return TIER_CHANCE_LEN + 1;
    }

    function _getBackgroundTier(
        uint8 tier,
        BoxType boxType,
        uint256 rand
    ) internal view returns (uint256 newRand, uint8 backgroundTier) {
        uint16 chance;
        (newRand, chance) = _getQuotientAndRemainder16(rand, MAX_CHANCE);

        uint16[TIER_CHANCE_LEN] memory chances = backgroundTierChances[tier][boxType];

        for (uint8 k = 0; k < TIER_CHANCE_LEN; k += 1) {
            if (chances[k] > chance) {
                return (newRand, k + 1);
            }
        }
        backgroundTier = TIER_CHANCE_LEN + 1;
    }

    function _getExpression(uint256 rand) internal view returns (uint256 newRand, ExpressionType expression) {
        uint16 value;
        (newRand, value) = _getQuotientAndRemainder16(rand, MAX_CHANCE);

        for (uint8 i = 0; i < EXPRESSION_COUNT; i += 1) {
            if (value < expressionProbability[i]) {
                expression = ExpressionType(i);
                break;
            }
        }
    }

    function _getFinish(uint256 rand, BoxType boxType) internal view returns (uint256 newRand, FinishType finish) {
        uint16 holoProbability = boxType == BoxType.Virtual ? 200 : portraitMintInfo[boxType].holoProbability;
        uint16 value;
        (newRand, value) = _getQuotientAndRemainder16(rand, MAX_CHANCE);

        if (value <= holoProbability) {
            finish = FinishType.Holo;
        } else {
            finish = FinishType.Normal;
        }
    }

    function _getAccessoryStage(uint256 rand) internal view returns (uint256 newRand, uint8 stage) {
        uint16 value;
        (newRand, value) = _getQuotientAndRemainder16(rand, MAX_CHANCE);

        for (uint8 i = 0; i < STAGE_COUNT; i += 1) {
            if (value < stageProbability[i]) {
                stage = i + 1;
                break;
            }
        }
    }

    /// @dev calculate quotient and remainder
    function _getQuotientAndRemainder16(uint256 a, uint16 b) internal pure returns (uint256, uint16) {
        return (a / b, uint16(a % b));
    }

    /// @dev calculate quotient and remainder
    function _getQuotientAndRemainder8(uint256 a, uint8 b) internal pure returns (uint256, uint8) {
        return (a / b, uint8(a % b));
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title VRFConsumerBaseUpgradeable
 * @dev Has same functionality as Chainlink VRFConsumerBase.sol, but used for upgradeable
 */
abstract contract VRFConsumerBaseUpgradeable is Initializable, VRFRequestIDBase {
    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
     * seed field around. We remove the use of it because given that the blockhash
     * enters later, it overrides whatever randomness the used seed provides.
     * Given that it adds no security, and can easily lead to misunderstandings,
     * we have removed it from usage and can now provide a simpler API.
     */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    function __VRFConsumerBase_init(address _vrfCoordinator, address _link) internal initializer {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

enum AccessoryType {
    Skin,
    Body,
    EyeWear,
    HeadWear,
    Props
}

enum BoxType {
    Virtual,
    Bronze,
    Silver,
    Gold,
    Platinum,
    Diamond
}

enum ExpressionType {
    Normal,
    ExpressionA,
    ExpressionB
}

enum FinishType {
    Normal,
    Holo
}

enum BackgroundLine {
    Dots,
    Flash,
    Hex,
    Rain,
    Spotlight,
    Mozart,
    Affinity,
    Arena,
    Token,
    Encounter
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Pair Price Oracle, a.k.a. Pair Oracle
 *
 * @notice Generic interface used to consult on the Uniswap-like token pairs conversion prices;
 *      one pair oracle is used to consult on the exchange rate within a single token pair
 *
 * @notice See also: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/building-an-oracle
 *
 * @author Basil Gorin
 */
interface PairOracle {
    /**
     * @notice Updates the oracle with the price values if required, for example
     *      the cumulative price at the start and end of a period, etc.
     *
     * @dev This function is part of the oracle maintenance flow
     */
    function update() external;

    /**
     * @notice For a pair of tokens A/B (sell/buy), consults on the amount of token B to be
     *      bought if the specified amount of token A to be sold
     *
     * @dev This function is part of the oracle usage flow
     *
     * @param token token A (token to sell) address
     * @param amountIn amount of token A to sell
     * @return amountOut amount of token B to be bought
     */
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

/**
 * @title Price Oracle Registry
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 *
 * @author Basil Gorin
 */
interface PriceOracleRegistry {
    /**
     * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
     *
     * @param tokenA token A (token to sell) address
     * @param tokenB token B (token to buy) address
     * @return pairOracle pair price oracle address for A/B token pair
     */
    function getPriceOracle(address tokenA, address tokenB) external view returns (address pairOracle);
}

/**
 * @title Illuvitars Price Oracle
 *
 * @notice Supports the Illuvitars with the ETH/ILV conversion required,
 *       marker interface is required to support ERC165 lookups
 *
 * @author Basil Gorin
 */
interface IlluvitarsPriceOracle {
    /**
     * @notice Powers the ETH/ILV illuvitar token price conversion, used when
     *      selling the illuvitar for sILV to determine how much sILV to accept
     *      instead of the nominated ETH price
     *
     * @notice Note that sILV price is considered to be equal to ILV price
     *
     * @dev Implementation must guarantee not to return zero, absurdly small
     *      or big values, it must guarantee the price is up to date with some
     *      reasonable update interval threshold
     *
     * @param ethOut amount of ETH sale contract is expecting to get
     * @return ilvIn amount of sILV sale contract should accept instead
     */
    function ethToIlv(uint256 ethOut) external view returns (uint256 ilvIn);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}