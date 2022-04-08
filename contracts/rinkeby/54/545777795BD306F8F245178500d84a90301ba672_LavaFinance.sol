// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20MetadataUpgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IERC721Upgradeable as IERC721} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/Pair.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/GLAVA.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/IFusion.sol";
import "./interfaces/IOracle.sol";


contract LavaFinance is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    event TierUpdated(uint indexed tier, uint indexed cost, uint indexed reward);
    event NodeMinted(address indexed user, uint tier, uint timestamp);
    event MicroNodeUpdated(address indexed user, uint amount);
    event NodeRewardsClaimed(address indexed user, uint amount);
    event NodeRewardsCompounded(address indexed user, uint amount);
    event NodeFusion(address indexed user, uint[] nodeIds, uint newTier);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    struct Tier {
        uint cost;      // 18 decimals
        uint reward;    // 18 decimals
        uint fees;      // 6 decimals. Amount in usdc.e per month
        bool active;
    }

    struct NodeData {
        string name;
        uint tier;
        uint lastClaim;
        uint paymentExpiry;
    }

    mapping(uint => address) private _owners;
    mapping(address => uint) private userNodeAmount;
    mapping(uint => NodeData) public nodeData;
    mapping(address => uint) public lastMicroClaim;
    mapping(address => uint[]) public userNodes;
    mapping(address => mapping(uint => uint)) private userNodesMap; // address maps to (tokenId maps to userNode index)
    mapping(address => uint) public microNodes;
    mapping(uint => mapping(address => uint)) public Ratios;

    address public lpPairAddress;
    uint public lpPairRatio;

    mapping(uint => Tier) public tiers;
    mapping(address => bool) public boosters;

    mapping(address => address) public tokenFeeds;

    IOracle public oracle;
    address public lavaToken;
    address public pLavaToken;
    address public gLavaToken;
    address public usdce;
    IERC721 public bronzeNFT;
    IERC721 public silverNFT;
    IERC721 public goldNFT;

    uint public microReward; // 18 decimals
    uint public nextMinted;

    uint public lpRatio;    // 4 decimals. 1000 = 10% = 0.1
    uint public burnRatio;   // 4 decimals. 1000 = 10% = 0.1
    address public lpWallet;
    address public treasury;

    uint public maxNodeLavaAllowed;
    uint public claimCooldown;

    address public fusionNFT;
    uint public fusionFees; // 6 decimals
    bool public fusionActive;
    uint private constant lavaDecimals = 18;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => bool) public transferWhitelist;


    modifier onlyWhitelisted() {
        require(transferWhitelist[msg.sender], "Not allowed");
        _;
    }

    function initialize(address _oracle, address _lavaToken, address _pLavaToken, address _gLavaToken, address _usdce, address _usdceFeed, address _lpWallet, address _treasury) public initializer {
        require(_oracle != address(0), "ZERO");
        require(_lavaToken != address(0), "ZERO");
        require(_pLavaToken != address(0), "ZERO");
        require(_gLavaToken != address(0), "ZERO");
        require(_usdce != address(0), "ZERO");
        require(_lpWallet != address(0), "ZERO");
        require(_treasury != address(0), "ZERO");
        __Context_init_unchained();
        __Ownable_init_unchained();
        oracle = IOracle(_oracle);
        lavaToken = _lavaToken;
        pLavaToken = _pLavaToken;
        gLavaToken = _gLavaToken;
        usdce = _usdce;
        tokenFeeds[usdce] = _usdceFeed;
        for (uint i = 1; i < 4; i++) {
            Ratios[i][_lavaToken] = 1e4;
            Ratios[i][_pLavaToken] = 1e4;
        }
        lpWallet = _lpWallet;
        treasury = _treasury;
        claimCooldown = 86400;
        maxNodeLavaAllowed = 20_000e18;
    }

    /****************************************|
    |     Mutable Functions                  |
    |_______________________________________*/

    function setTier(uint _tier, uint _cost, uint _reward, uint _fees, bool _active) external onlyOwner {
        require(_cost > 0, "Cost 0");
        require(_tier > 0 && _tier < 10, "Tier must be 1 and 9");
        tiers[_tier] = Tier({
            cost: _cost,
            reward: _reward,
            fees: _fees,
            active: _active
        });
        emit TierUpdated(_tier, _cost, _reward);
    }

    function setTierStatus(uint _tier, bool _active) external onlyOwner {
        tiers[_tier].active = _active;
    }

    function setMicroReward(uint _microReward) external onlyOwner {
        microReward = _microReward;
    }

    function setLPAndBurnRatio(uint _lpRatio, uint _burnRatio) external onlyOwner {
        lpRatio = _lpRatio;
        burnRatio = _burnRatio;
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "ZERO");
        oracle = IOracle(_oracle);
    }

    function setWallets(address _lpWallet, address _treasury) external onlyOwner {
        require(_lpWallet != address(0), "ZERO");
        require(_treasury != address(0), "ZERO");
        lpWallet = _lpWallet;
        treasury = _treasury;
    }

    function setWalletNFTs(address _bronze, address _silver, address _gold) external onlyOwner {
        bronzeNFT = IERC721(_bronze);
        silverNFT = IERC721(_silver);
        goldNFT = IERC721(_gold);
    }

    function setBoosterNFT(address nftAddress, bool status) external onlyOwner {
        require(nftAddress != address(0), "ZERO");
        boosters[nftAddress] = status;
    }

    function setFusionNFT(address _fusionNFT) external onlyOwner {
        fusionNFT = _fusionNFT;
    }

    function addToken(address _token, uint _tier, uint _ratio, address _feed) external onlyOwner {
        Ratios[_tier][_token] = _ratio;
        if (_feed != address(0)) {
            tokenFeeds[_token] = _feed;
        }
    }

    function addTokenMultiple(address _token, uint _ratio, address _feed) external onlyOwner {
        for (uint i = 1; i < 10; i++) {
            if (tiers[i].active) {
                Ratios[i][_token] = _ratio;
            }
        }
        if (_feed != address(0)) {
            tokenFeeds[_token] = _feed;
        }
    }

    // Only LAVA-USDC.e LP token to be set for now.
    function setLPToken(address _pair, uint _ratio) external onlyOwner {
        lpPairAddress = _pair;
        lpPairRatio = _ratio;
    }

    function setMaxLava(uint _maxNodeLavaAllowed) external onlyOwner {
        require(_maxNodeLavaAllowed >= maxNodeLavaAllowed, "Too low");
        maxNodeLavaAllowed = _maxNodeLavaAllowed;
    }

    function setClaimCooldown(uint _claimCooldown) external onlyOwner {
        claimCooldown = _claimCooldown;
    }

    function setFusionParameters(uint _fusionFees, bool _fusionActive) external onlyOwner {
        fusionFees = _fusionFees;
        fusionActive = _fusionActive;
    }

    function setTransferWhitelist(address user, bool status) external onlyOwner {
        require(user != address(0), "Cannot be zero");
        transferWhitelist[user] = status;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function mint(uint tier, address token, uint numNodes, string memory name) external nonReentrant returns (uint cost) {
        uint tokenRatio = Ratios[tier][token];
        require(tokenRatio != 0 || (token == lpPairAddress && lpPairRatio > 0), "Not accepted");
        require(tiers[tier].active, "No such Tier");
        require(numNodes > 0 && numNodes <= 10, "Incorrect no. of nodes");

        updateOracle();

        uint nodePrice = tiers[tier].cost * numNodes;
        if (token == lpPairAddress && lpPairRatio > 0) {
            cost = (oracle.getEquivalentPairAmount(lavaToken, nodePrice) * lpPairRatio) / 1e4;
            require(IERC20(token).transferFrom(msg.sender, lpWallet, cost), "Payment error");
        } else {
            if(token == lavaToken || token == pLavaToken ) {
                cost = (nodePrice * tokenRatio) / 1e4;
                IERC20(token).transferFrom(msg.sender, address(this), cost);
            } else {
                uint tokenPrice = getNodePriceInToken(token, nodePrice);
                cost = (tokenPrice * tokenRatio) / 1e4;
                require(IERC20(token).transferFrom(msg.sender, treasury, cost), "Payment error");
            }
        }

        for(uint i=0; i < numNodes; i++) {
            _mintNode(msg.sender, tier, name);
        }

        if (token == lavaToken || token == pLavaToken) {
            uint lavaAmount = (nodePrice * tokenRatio) / 1e4;
            IERC20Burnable(lavaToken).burn((lavaAmount * burnRatio) / 1e4);
            IERC20(lavaToken).transfer(lpWallet, (lavaAmount * lpRatio) / 1e4);
        }
    }

    function _mintNode(address user, uint tier, string memory name) internal {
        _mintNodeNoGLava(user, tier, name);
        GLAVA(gLavaToken).mint(user, tiers[tier].cost);
    }

    function _mintNodeNoGLava(address user, uint tier, string memory name) internal whenNotPaused {
        require(userNodeAmount[user] + tiers[tier].cost <= maxNodeLavaAllowed, "Limit reached");
        nodeData[nextMinted] = NodeData({
            name: name,
            tier: tier,
            lastClaim: block.timestamp,
            paymentExpiry: block.timestamp + 7 days
        });
        _transferNode(address(0), user, nextMinted);
        nextMinted++;
        emit NodeMinted(user, tier, block.timestamp);
    }

    function addMicroNode(address token, uint amount) external nonReentrant {
        require(token == lavaToken || token == pLavaToken, "Only Lava tokens");
        uint totalMicroAmount = amount + microNodes[msg.sender];
        require(totalMicroAmount >= 10 ** lavaDecimals, "Amount too low");
        (, uint minPrice) = getMinNodePrice();
        require(totalMicroAmount <= minPrice + 1e16, "Amount too high");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _addMicroNodeAmount(msg.sender, amount);
    }

    function _addMicroNodeAmount(address user, uint amount) internal {
        uint currentMicroAmount = microNodes[user];
        uint totalAmount = currentMicroAmount + amount + getMicroReward(user);
        (uint minTier, uint minNodePrice) = getMinNodePrice();
        if (currentMicroAmount > 0 && totalAmount >= minNodePrice) {
            _mintNode(user, minTier, "Lava Node");
            totalAmount -= minNodePrice;
        }
        while (totalAmount >= minNodePrice) {
            (uint maxTier, uint tierCost) = getMaxTierBuyable(totalAmount);
            uint numNodes = totalAmount / tierCost;
            for (uint i=0; i < numNodes; i++) {
                _mintNode(user, maxTier, "Lava Node");
            } 
            totalAmount -= numNodes * tierCost;
        }
        microNodes[user] = totalAmount;
        lastMicroClaim[user] = block.timestamp;
        emit MicroNodeUpdated(user, totalAmount);
    }

    function payMaintenanceFees(uint[] memory tokenIds, uint[] memory numMonths) external nonReentrant returns (uint amount) {
        require(tokenIds.length == numMonths.length, "Unequal length input");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            Tier storage tier = tiers[nodeData[tokenId].tier];
            uint fees = tier.fees;
            require(ownerOf(tokenId) == msg.sender, "User not Owner");
            uint maintenanceAmount = fees * numMonths[i];
            // if (nodeData[tokenId].paymentExpiry < block.timestamp) {
            //     maintenanceAmount += ((block.timestamp - nodeData[tokenId].paymentExpiry) * fees * tier.reward) / (tier.cost * 1 days);
            // }
            amount += maintenanceAmount;
            nodeData[tokenIds[i]].paymentExpiry += numMonths[i] * 30 days;
        }
        require(IERC20(usdce).transferFrom(msg.sender, treasury, amount), "Payment error");
    }

    // compoundPercent is 4 decimals. 1000 = 0.1 = 10%
    function claim(uint[] memory tokenIds, uint compoundPercent, bool claimMicro, address booster) external nonReentrant {
        // force claimMicro to be false, because its added on compounding anyway
        if (compoundPercent > 0) {
            claimMicro = false;
        }
        uint amountToClaim = setClaimAmount(msg.sender, tokenIds, claimMicro, booster);
        require(amountToClaim > 0, "Nothing To Claim");
        if (compoundPercent > 0) {
            uint compoundAmount = amountToClaim * compoundPercent / 1e4;
            amountToClaim -= compoundAmount;
            _addMicroNodeAmount(msg.sender, compoundAmount);
            emit NodeRewardsCompounded(msg.sender, compoundAmount);
        }
        if (amountToClaim > 0) {
            IERC20(lavaToken).transfer(msg.sender, amountToClaim);
            emit NodeRewardsClaimed(msg.sender, amountToClaim);
        }
        updateOracle();
    }

    function setClaimAmount(address user, uint[] memory tokenIds, bool claimMicro, address booster) internal returns (uint amount) {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            (uint tokenAmount, uint claimTimestamp) = getTokenClaim(user, tokenId, true);
            amount += tokenAmount;
            if (claimTimestamp > 0) {
                nodeData[tokenId].lastClaim = claimTimestamp;
            }
        }
        if (claimMicro && microNodes[user] > 0) {
            amount += getMicroReward(user);
            lastMicroClaim[user] = block.timestamp;
        }

        (uint bonus, bool boosterUsed) = getBoosterBonus(user, booster);
        amount = (amount * bonus) / 100;
        if (boosterUsed) {
            IBooster(booster).useBooster(user);
        }
    }

    function fuseNodes(uint[] memory tokenIds, uint newTier, string memory name) external nonReentrant {
        require(fusionActive, "Inactive");
        require(tokenIds.length > 1, "Low nodes");
        if (fusionNFT != address(0)) {
            IFusion(fusionNFT).fuse(msg.sender);
        }
        uint newTierCost = tiers[newTier].cost;
        uint currentNodeCost;
        for (uint i=0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "User Not Owner");
            require(nodeData[tokenId].paymentExpiry > block.timestamp, "Pay Maintenance");
            currentNodeCost += tiers[nodeData[tokenId].tier].cost;
        }
        require(currentNodeCost == newTierCost, "Fusion not possible");
        if (fusionFees > 0) {
            require(IERC20(usdce).transferFrom(msg.sender, address(this), fusionFees), "Pay error");
        }
        for (uint i=0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            _transferNode(msg.sender, address(0), tokenId);
            // delete nodeData[tokenId];
        }
        _mintNodeNoGLava(msg.sender, newTier, name);
        emit NodeFusion(msg.sender, tokenIds, newTier);
    }

    function setNodeName(uint tokenId, string memory name) external {
        require(ownerOf(tokenId) == msg.sender, "User not owner");
        nodeData[tokenId].name = name;
    }

    function updateOracle() internal {
        oracle.update();
    }

    function adminWithdraw(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function adminWithdrawETH(address payable admin) external onlyOwner {
        admin.transfer(address(this).balance);
    }

    /****************************************|
    |     Non Mutable Functions              |
    |_______________________________________*/

    function variableAssetPriceInUSD(address _address) public view returns (uint) {
        AggregatorV3Interface feed = AggregatorV3Interface(tokenFeeds[_address]);
        ( , int price, , , ) = feed.latestRoundData();
        return (uint(price) * (10 ** IERC20(usdce).decimals())) / (10 ** feed.decimals());
    }

    function getNodePriceInToken(address token, uint nodePrice) public view returns (uint) {
        uint nodePriceInUsdce = oracle.consult(usdce, nodePrice);
        if (token == usdce) {
            return nodePriceInUsdce;
        } else {
            uint nodePriceInUSD = (nodePriceInUsdce * variableAssetPriceInUSD(usdce)) / (10 ** IERC20(usdce).decimals());
            uint tokenValueInUSD = variableAssetPriceInUSD(token);
            return (nodePriceInUSD * (10 ** IERC20(token).decimals())) / tokenValueInUSD;
        }
    }

    function getClaimAmount(address user, uint[] memory tokenIds, bool claimMicro, address booster) public view returns (uint amount) {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            (uint tokenAmount, ) = getTokenClaim(user, tokenId, false);
            amount += tokenAmount;
        }
        if (claimMicro && microNodes[user] > 0) {
            amount += getMicroReward(user);
        }

        (uint bonus, ) = getBoosterBonus(user, booster);
        amount = (amount * bonus) / 100;
    }

    function getTokenClaim(address user, uint tokenId, bool useCooldown) public view returns (uint amount, uint claimTimestamp) {
        require(ownerOf(tokenId) == user, "User Not Owner");
        NodeData storage nd = nodeData[tokenId];
        if (!useCooldown || block.timestamp - nd.lastClaim > claimCooldown) {
            claimTimestamp = nd.paymentExpiry < block.timestamp ? nd.paymentExpiry : block.timestamp;
            amount = ((claimTimestamp - nd.lastClaim) * tiers[nd.tier].reward) / 1 days;
        }
    }

    function getMicroReward(address user) public view returns (uint) {
        return (microNodes[user] * (block.timestamp - lastMicroClaim[user]) * microReward) / (10**lavaDecimals * 1 days);
    }

    function getBoosterBonus(address user, address booster) public view returns (uint bonus, bool boosterUsed) {
        uint boosterBonus = 0;
        if (boosters[booster]) {
            boosterBonus = IBooster(booster).getBonus();
        }
        uint nftBonus = 100;
        if (goldNFT.balanceOf(user) > 0) {
            nftBonus = 115;
        } else if (silverNFT.balanceOf(user) > 0) {
            nftBonus = 110;
        } else if (bronzeNFT.balanceOf(user) > 0) {
            nftBonus = 105;
        }

        if (boosterBonus > nftBonus) {
            bonus = boosterBonus;
            boosterUsed = true;
        } else {
            bonus = nftBonus;
        }
    }

    function getMinNodePrice() public view returns (uint tier, uint amount) {
        for (uint i = 1; i < 10; i++) {
            if (tiers[i].active && (amount == 0 || tiers[i].cost < amount)) {
                tier = i;
                amount = tiers[i].cost;
            }
        }
    }

    function getMaxTierBuyable(uint amount) public view returns (uint tier, uint maxAmount) {
        for (uint i = 1; i < 10; i++) {
            if (tiers[i].active && amount >= tiers[i].cost && tiers[i].cost >= maxAmount) {
                tier = i;
                maxAmount = tiers[i].cost;
            }
        }
    }

    function getUserNodes(address user) public view returns (uint[] memory nodeIds) {
        return userNodes[user];
    }


    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferNode(address from, address to, uint tokenId) external onlyWhitelisted {
        require(from != address(0), "Cannot mint");
        require(from == ownerOf(tokenId), "Wrong token Id");
        require(isApprovedForAll(from, msg.sender), "Not Approved");
        _transferNode(from, to, tokenId);
    }

    function _transferNode(address from, address to, uint tokenId) internal {
        uint nodeAmount = tiers[nodeData[tokenId].tier].cost;
        if (from != address(0)) {
            // Remove the node from the `from` address. Need to update userNodes and userNodesMap accordingly
            uint index = userNodesMap[from][tokenId];
            delete userNodesMap[from][tokenId];
            uint finalElementIndex = userNodes[from].length - 1;
            uint tokenIdToShift = userNodes[from][finalElementIndex];
            userNodes[from][index] = tokenIdToShift;
            userNodesMap[from][tokenIdToShift] = index;
            userNodes[from].pop();
            userNodeAmount[from] -= nodeAmount;
        }
        if (to != address(0)) {
            userNodes[to].push(tokenId);
            userNodesMap[to][tokenId] = userNodes[to].length - 1;
            userNodeAmount[to] += nodeAmount;
        }
        _owners[tokenId] = to;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Pair {
    function totalSupply() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GLAVA {
    function mint(address recipient, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBooster {
    function getBonus() external view returns (uint256);

    function useBooster(address user) external;

    function mint(address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFusion {
    function fuse(address user) external;

    function mint(address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function getEquivalentPairAmount(address _token, uint256 _amount) external view returns (uint256 lpAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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