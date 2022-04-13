// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Inspired by Solmate: https://github.com/Rari-Capital/solmate
/// Developed originally by 0xBasset
/// Upgraded by <redacted>
/// Additions by Tsuki Labs: https://tsukiyomigroup.com/ :)

contract Oil {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    address public impl_;
    address public ruler;
    address public treasury;
    address public uniPair;
    address public weth;

    uint256 public totalSupply;
    uint256 public startingTime;
    uint256 public baseTax;
    uint256 public minSwap;

    bool public paused;
    bool public swapping;

    ERC721Like public habibi;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    mapping(uint256 => uint256) public claims;

    mapping(address => Staker) internal stakers;

    uint256 public sellFee;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    uint256 public doubleBaseTimestamp;

    struct Habibi {
        uint256 stakedTimestamp;
        uint256 tokenId;
    }

    struct Staker {
        Habibi[] habibiz;
        uint256 lastClaim;
    }

    struct Rescueable {
        address revoker;
        bool adminAllowedAsRevoker;
    }

    mapping(address => Rescueable) private rescueable;

    address public sushiswapPair;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Router02 public sushiswapV2Router;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public blockList;

    struct RoyalStaker {
        Royal[] royals;
    }

    struct Royal {
        uint256 stakedTimestamp;
        uint256 tokenId;
    }

    ERC721Like public royals;

    uint256[] public frozenHabibiz;

    mapping(uint256 => address) public claimedRoyals;
    mapping(address => RoyalStaker) internal royalStakers;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return "OIL";
    }

    function symbol() external pure returns (string memory) {
        return "OIL";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function initialize(address habibi_, address treasury_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");
        ruler = msg.sender;
        treasury = treasury_;
        habibi = ERC721Like(habibi_);
        sellFee = 15000;
        _status = _NOT_ENTERED;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        require(!blockList[msg.sender], "Address Blocked");
        _transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external whenNotPaused returns (bool) {
        require(!blockList[msg.sender], "Address Blocked");
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        _transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              STAKING
    //////////////////////////////////////////////////////////////*/

    function _tokensOfStaker(address staker_, bool royals_) internal view returns (uint256[] memory) {
        uint256 i;
        if (royals_) {
            uint256[] memory tokenIds = new uint256[](royalStakers[staker_].royals.length);
            for (i = 0; i < royalStakers[staker_].royals.length; i++) {
                tokenIds[i] = royalStakers[staker_].royals[i].tokenId;
            }
            return tokenIds;
        } else {
            uint256[] memory tokenIds = new uint256[](stakers[staker_].habibiz.length);
            for (i = 0; i < stakers[staker_].habibiz.length; i++) {
                tokenIds[i] = stakers[staker_].habibiz[i].tokenId;
            }
            return tokenIds;
        }
    }

    function habibizOfStaker(address staker_) public view returns (uint256[] memory) {
        return _tokensOfStaker(staker_, false);
    }

    function royalsOfStaker(address staker_) public view returns (uint256[] memory) {
        return _tokensOfStaker(staker_, true);
    }

    function allStakedOfStaker(address staker_) public view returns (uint256[] memory, uint256[] memory) {
        return (habibizOfStaker(staker_), royalsOfStaker(staker_));
    }

    function stake(uint256[] memory habibiz_, uint256[] memory royals_) public whenNotPaused {
        uint256 i;
        for (i = 0; i < habibiz_.length; i++) {
            require(habibi.ownerOf(habibiz_[i]) == msg.sender, "At least one Habibi is not owned by you.");
            habibi.transferFrom(msg.sender, address(this), habibiz_[i]);
            stakers[msg.sender].habibiz.push(Habibi(block.timestamp, habibiz_[i]));
        }

        for (i = 0; i < royals_.length; i++) {
            require(royals.ownerOf(royals_[i]) == msg.sender, "At least one Royals is not owned by you.");
            royals.transferFrom(msg.sender, address(this), royals_[i]);
            royalStakers[msg.sender].royals.push(Royal(block.timestamp, royals_[i]));
        }
    }

    function stakeAll() external whenNotPaused {
        uint256[] memory habibizTokenIds = habibi.walletOfOwner(msg.sender);
        uint256[] memory royalsTokenIds = royals.tokensOfOwner(msg.sender);
        stake(habibizTokenIds, royalsTokenIds);
    }

    function isOwnedByStaker(
        address staker_,
        uint256 tokenId_,
        bool isRoyal_
    ) public view returns (bool) {
        uint256[] memory tokenIds;
        if (isRoyal_) {
            tokenIds = royalsOfStaker(staker_);
        } else {
            tokenIds = habibizOfStaker(staker_);
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId_) {
                return true;
            }
        }
        return false;
    }

    function _unstake(bool habibiz_, bool royals_) internal {
        /*
        address staker_,
        uint256 tokenId_,
        uint256 stakedTimestamp_,
        bool isRoyal_
        */
        uint256 i;
        uint256 oil;
        if (habibiz_) {
            uint256[] memory tokenIds = new uint256[](stakers[msg.sender].habibiz.length);
            for (i = 0; i < tokenIds.length; i++) {
                Habibi memory _habibi = stakers[msg.sender].habibiz[i];
                habibi.transferFrom(address(this), msg.sender, _habibi.tokenId);
                tokenIds[i] = _habibi.tokenId;
                oil += _calculateOil(msg.sender, _habibi.tokenId, _habibi.stakedTimestamp, false);
            }
            _removeHabibizFromStaker(msg.sender, tokenIds);
        }

        if (royals_) {
            uint256[] memory tokenIds = new uint256[](royalStakers[msg.sender].royals.length);
            for (i = 0; i < tokenIds.length; i++) {
                Royal memory _royal = royalStakers[msg.sender].royals[i];
                royals.transferFrom(address(this), msg.sender, _royal.tokenId);
                tokenIds[i] = _royal.tokenId;
                oil += _calculateOil(msg.sender, _royal.tokenId, _royal.stakedTimestamp, true);
            }
            _removeRoyalsFromStaker(msg.sender, tokenIds);
        }
        if (oil > 0) _claimAmount(msg.sender, oil);
    }

    function _unstakeByIds(uint256[] memory habibizIds_, uint256[] memory royalsIds_) internal {
        uint256 i;
        uint256 oil = calculateOilRewards(msg.sender);
        if (habibizIds_.length > 0) {
            uint256[] memory tokenIds = new uint256[](habibizIds_.length);
            for (i = 0; i < habibizIds_.length; i++) {
                require(isOwnedByStaker(msg.sender, habibizIds_[i], false), "Habibi not owned by sender");
                habibi.transferFrom(address(this), msg.sender, habibizIds_[i]);
                tokenIds[i] = habibizIds_[i];
            }
            _removeHabibizFromStaker(msg.sender, tokenIds);
        }
        if (royalsIds_.length > 0) {
            uint256[] memory tokenIds = new uint256[](royalsIds_.length);
            for (i = 0; i < tokenIds.length; i++) {
                require(isOwnedByStaker(msg.sender, royalsIds_[i], true), "Habibi not owned by sender");
                royals.transferFrom(address(this), msg.sender, royalsIds_[i]);
                tokenIds[i] = royalsIds_[i];
            }
            _removeRoyalsFromStaker(msg.sender, tokenIds);
        }
        if (oil > 0) _claimAmount(msg.sender, oil);
    }

    function unstakeAllHabibiz() external whenNotPaused {
        require(stakers[msg.sender].habibiz.length > 0, "No Habibiz staked");
        _unstake(true, false);
    }

    function unstakeAllRoyals() external whenNotPaused {
        require(royalStakers[msg.sender].royals.length > 0, "No Royals staked");
        _unstake(false, true);
    }

    function unstakeAll() external whenNotPaused {
        require(
            stakers[msg.sender].habibiz.length > 0 || royalStakers[msg.sender].royals.length > 0,
            "No Habibiz or Royals staked"
        );
        _unstake(true, true);
    }

    function unstakeHabibizByIds(uint256[] calldata tokenIds_) external whenNotPaused {
        _unstakeByIds(tokenIds_, new uint256[](0));
    }

    function unstakeRoyalsByIds(uint256[] calldata tokenIds_) external whenNotPaused {
        _unstakeByIds(new uint256[](0), tokenIds_);
    }

    function _removeRoyalsFromStaker(address staker_, uint256[] memory tokenIds_) internal {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            for (uint256 j = 0; j < royalStakers[staker_].royals.length; j++) {
                if (tokenIds_[i] == royalStakers[staker_].royals[j].tokenId) {
                    royalStakers[staker_].royals[j] = royalStakers[staker_].royals[
                        royalStakers[staker_].royals.length - 1
                    ];
                    royalStakers[staker_].royals.pop();
                }
            }
        }
    }

    function _removeHabibizFromStaker(address staker_, uint256[] memory tokenIds_) internal {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            for (uint256 j = 0; j < stakers[staker_].habibiz.length; j++) {
                if (tokenIds_[i] == stakers[staker_].habibiz[j].tokenId) {
                    stakers[staker_].habibiz[j] = stakers[staker_].habibiz[stakers[staker_].habibiz.length - 1];
                    stakers[staker_].habibiz.pop();
                }
            }
        }
    }

    function approveRescue(
        address revoker_,
        bool confirm_,
        bool rescueableByAdmin_
    ) external {
        require(confirm_, "Did not confirm");
        require(revoker_ != address(0), "Revoker cannot be null address");
        rescueable[msg.sender] = Rescueable(revoker_, rescueableByAdmin_);
    }

    function revokeRescue(address rescueable_, bool confirm_) external {
        if (msg.sender == ruler) {
            require(rescueable[rescueable_].adminAllowedAsRevoker, "Admin is not allowed to revoke");
        } else {
            require(rescueable[rescueable_].revoker == msg.sender, "Sender is not revoker");
        }
        require(confirm_, "Did not confirm");

        delete rescueable[rescueable_];
    }

    /*////////////////////////////////////////////////////////////
                        Sacrifice for Royals
    ////////////////////////////////////////////////////////////*/

    function freeze(
        address staker_,
        uint256[] calldata habibizIds_,
        uint256 royalId_
    ) external returns (bool) {
        require(msg.sender == address(royals), "You do not have permission to call this function");
        require(
            royals.ownerOf(royalId_) == address(this) && claimedRoyals[royalId_] == address(0),
            "Invalid or claimed token id"
        );
        uint256[] memory habibiz = habibizOfStaker(staker_);

        uint256 count = 0;
        for (uint256 i = 0; i < habibizIds_.length; i++) {
            for (uint256 j = 0; j < habibiz.length; j++) {
                if (habibizIds_[i] == habibiz[j]) {
                    count++;
                    frozenHabibiz.push(habibizIds_[i]);
                    break;
                }
            }
        }
        require(habibizIds_.length == count, "Missing staked Habibiz");
        _claim(staker_);
        _removeHabibizFromStaker(staker_, habibizIds_);
        claimedRoyals[royalId_] = staker_;
        royalStakers[staker_].royals.push(Royal(block.timestamp, royalId_));
        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              CLAIMING
    //////////////////////////////////////////////////////////////*/

    function claim() public whenNotPaused {
        require(!blockList[msg.sender], "Address Blocked");
        _claim(msg.sender);
    }

    function _claim(address to_) internal {
        uint256 oil = calculateOilRewards(to_);
        if (oil > 0) {
            _claimAmount(to_, oil);
        }
    }

    function _claimAmount(address to_, uint256 amount_) internal {
        stakers[to_].lastClaim = block.timestamp;
        _mint(to_, amount_);
    }

    /*///////////////////////////////////////////////////////////////
                            OIL REWARDS
    //////////////////////////////////////////////////////////////*/

    function calculateOilRewards(address staker_) public view returns (uint256 oilAmount) {
        uint256 balanceBonus = holderBonusPercentage(staker_);
        uint256 habibizAmount = stakers[staker_].habibiz.length;
        uint256 royalsAmount = royalStakers[staker_].royals.length;
        uint256 totalStaked = habibizAmount + royalsAmount;
        uint256 royalsBase = getRoyalsBase(staker_);
        uint256 lastClaimTimestamp = stakers[staker_].lastClaim;
        bool isAnimated;
        for (uint256 i = 0; i < totalStaked; i++) {
            uint256 tokenId;
            bool isRoyal;
            uint256 stakedTimestamp;
            if (i < habibizAmount) {
                tokenId = stakers[staker_].habibiz[i].tokenId;
                stakedTimestamp = stakers[staker_].habibiz[i].stakedTimestamp;
                isAnimated = _isAnimated(tokenId);
            } else {
                tokenId = royalStakers[staker_].royals[i - habibizAmount].tokenId;
                stakedTimestamp = royalStakers[staker_].royals[i - habibizAmount].stakedTimestamp;
                isRoyal = true;
            }
            oilAmount += calculateOilOfToken(
                isAnimated,
                lastClaimTimestamp,
                stakedTimestamp,
                balanceBonus,
                isRoyal,
                royalsBase
            );
        }
    }

    function _calculateTimes(uint256 stakedTimestamp_, uint256 lastClaimedTimestamp_)
        internal
        view
        returns (uint256, uint256)
    {
        if (lastClaimedTimestamp_ < stakedTimestamp_) {
            lastClaimedTimestamp_ = stakedTimestamp_;
        }
        return (block.timestamp - stakedTimestamp_, block.timestamp - lastClaimedTimestamp_);
    }

    function _calculateOil(
        address staker_,
        uint256 tokenId_,
        uint256 stakedTimestamp_,
        bool isRoyal_
    ) internal view returns (uint256) {
        uint256 balanceBonus = holderBonusPercentage(staker_);
        uint256 lastClaimTimestamp = stakers[staker_].lastClaim;
        if (isRoyal_) {
            return calculateOilOfToken(false, lastClaimTimestamp, stakedTimestamp_, balanceBonus, true, 0);
        }
        return
            calculateOilOfToken(
                _isAnimated(tokenId_),
                lastClaimTimestamp,
                stakedTimestamp_,
                balanceBonus,
                false,
                getRoyalsBase(staker_)
            );
    }

    function calculateOilOfToken(
        bool isAnimated_,
        uint256 lastClaimedTimestamp_,
        uint256 stakedTimestamp_,
        uint256 balanceBonus_,
        bool isRoyal_,
        uint256 royalsBase
    ) internal view returns (uint256 oil) {
        uint256 bonusPercentage;
        uint256 baseOilMultiplier = 1;

        (uint256 stakedTime, uint256 unclaimedTime) = _calculateTimes(stakedTimestamp_, lastClaimedTimestamp_);

        if (stakedTime >= 15 days || stakedTimestamp_ <= doubleBaseTimestamp) {
            baseOilMultiplier = 2;
        }

        if (stakedTime >= 90 days) {
            bonusPercentage = 100;
        } else {
            for (uint256 i = 2; i < 4; i++) {
                uint256 timeRequirement = 15 days * i;
                if (timeRequirement > 0 && timeRequirement <= stakedTime) {
                    bonusPercentage = bonusPercentage + 15;
                } else {
                    break;
                }
            }
        }

        if (isRoyal_) {
            oil = (unclaimedTime * royalsBase * 1 ether) / 1 days;
        } else if (isAnimated_) {
            oil = (unclaimedTime * 2500 ether * baseOilMultiplier) / 1 days;
        } else {
            bonusPercentage = bonusPercentage + balanceBonus_;
            oil = (unclaimedTime * 500 ether * baseOilMultiplier) / 1 days;
        }
        oil += ((oil * bonusPercentage) / 100);
    }

    function getRoyalsBase(address staker_) public view returns (uint256 base) {
        if (royalStakers[staker_].royals.length == 1) {
            base = 12000;
        } else if (royalStakers[staker_].royals.length == 2) {
            base = 13500;
        } else if (royalStakers[staker_].royals.length >= 3) {
            base = 15000;
        } else {
            base = 0;
        }
        return base;
    }

    function staker(address staker_) public view returns (Staker memory, RoyalStaker memory) {
        return (stakers[staker_], royalStakers[staker_]);
    }

    /*///////////////////////////////////////////////////////////////
                            OIL PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external onlyMinter {
        _mint(to, value);
    }

    function burn(address from, uint256 value) external onlyMinter {
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setDoubleBaseTimestamp(uint256 doubleBaseTimestamp_) external onlyRuler {
        doubleBaseTimestamp = doubleBaseTimestamp_;
    }

    function setMinter(address minter_, bool canMint_) external onlyRuler {
        isMinter[minter_] = canMint_;
    }

    function setRuler(address ruler_) external onlyRuler {
        ruler = ruler_;
    }

    function setPaused(bool paused_) external onlyRuler {
        paused = paused_;
    }

    function setHabibiAddress(address habibiAddress_) external onlyRuler {
        habibi = ERC721Like(habibiAddress_);
    }

    function setRoyalsAddress(address royalsAddress_) external onlyRuler {
        royals = ERC721Like(royalsAddress_);
    }

    function setSellFee(uint256 fee_) external onlyRuler {
        sellFee = fee_;
    }

    function setUniswapV2Router(address router_) external onlyRuler {
        uniswapV2Router = IUniswapV2Router02(router_);
    }

    function setSushiswapV2Router(address router_) external onlyRuler {
        sushiswapV2Router = IUniswapV2Router02(router_);
    }

    function setV2Routers(address uniswapRouter_, address sushiswapRouter_) external onlyRuler {
        uniswapV2Router = IUniswapV2Router02(uniswapRouter_);
        sushiswapV2Router = IUniswapV2Router02(sushiswapRouter_);
    }

    function setUniPair(address uniPair_) external onlyRuler {
        uniPair = uniPair_;
    }

    function setSushiswapPair(address sushiswapPair_) external onlyRuler {
        sushiswapPair = sushiswapPair_;
    }

    function setPairs(address uniPair_, address sushiswapPair_) external onlyRuler {
        uniPair = uniPair_;
        sushiswapPair = sushiswapPair_;
    }

    function excludeFromFees(address[] calldata addresses_, bool[] calldata excluded_) external onlyRuler {
        for (uint256 i = 0; i < addresses_.length; i++) {
            excludedFromFees[addresses_[i]] = excluded_[i];
        }
    }

    function blockOrUnblockAddresses(address[] calldata addresses_, bool[] calldata blocked_) external onlyRuler {
        for (uint256 i = 0; i < addresses_.length; i++) {
            blockList[addresses_[i]] = blocked_[i];
        }
    }

    /// emergency
    function rescue(
        address staker_,
        address to_,
        uint256[] calldata habibiIds_,
        uint256[] calldata royalIds_
    ) external onlyRuler {
        require(rescueable[staker_].revoker != address(0), "User has not opted-in for rescue");
        if (habibiIds_.length > 0) {
            for (uint256 i = 0; i < habibiIds_.length; i++) {
                require(isOwnedByStaker(staker_, habibiIds_[i], false), "Habibi TokenID not found");
                stakers[to_].habibiz.push(Habibi(block.timestamp, habibiIds_[i]));
            }
            _removeHabibizFromStaker(staker_, habibiIds_);
        }

        if (royalIds_.length > 0) {
            for (uint256 i = 0; i < royalIds_.length; i++) {
                require(isOwnedByStaker(staker_, royalIds_[i], true), "Royal TokenID not found");
                royalStakers[to_].royals.push(Royal(block.timestamp, royalIds_[i]));
            }
            _removeRoyalsFromStaker(staker_, royalIds_);
        }
    }

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _getRouterFromPair(address pairAddress_) internal view returns (IUniswapV2Router02) {
        return pairAddress_ == address(uniPair) ? uniswapV2Router : sushiswapV2Router;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(balanceOf[from] >= value, "ERC20: transfer amount exceeds balance");
        uint256 tax;

        bool shouldTax = ((to == uniPair && balanceOf[to] != 0) || (to == sushiswapPair && balanceOf[to] != 0)) &&
            !swapping;
        if (shouldTax && !excludedFromFees[from]) {
            tax = (value * sellFee) / 100_000;
            if (tax > 0) {
                balanceOf[address(this)] += tax;
                swapTokensForEth(to, tax, treasury);
            }
        }
        uint256 taxedAmount = value - tax;
        balanceOf[from] -= value;
        balanceOf[to] += taxedAmount;
        emit Transfer(from, to, taxedAmount);
    }

    function swapTokensForEth(
        address pairAddress_,
        uint256 amountIn_,
        address to_
    ) private lockTheSwap {
        IUniswapV2Router02 router = _getRouterFromPair(pairAddress_);
        IERC20(address(this)).approve(address(router), amountIn_);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH(); // or router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn_, 1, path, to_, block.timestamp);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }

    function holderBonusPercentage(address staker_) public view returns (uint256) {
        uint256 balance = stakers[staker_].habibiz.length + royalStakers[staker_].royals.length * 8;

        if (balance < 5) return 0;
        if (balance < 10) return 15;
        if (balance < 20) return 25;
        return 35;
    }

    function _isAnimated(uint256 id_) internal pure returns (bool animated) {
        return
            id_ == 40 ||
            id_ == 108 ||
            id_ == 169 ||
            id_ == 191 ||
            id_ == 246 ||
            id_ == 257 ||
            id_ == 319 ||
            id_ == 386 ||
            id_ == 496 ||
            id_ == 562 ||
            id_ == 637 ||
            id_ == 692 ||
            id_ == 832 ||
            id_ == 942 ||
            id_ == 943 ||
            id_ == 957 ||
            id_ == 1100 ||
            id_ == 1108 ||
            id_ == 1169 ||
            id_ == 1178 ||
            id_ == 1627 ||
            id_ == 1706 ||
            id_ == 1843 ||
            id_ == 1884 ||
            id_ == 2137 ||
            id_ == 2158 ||
            id_ == 2165 ||
            id_ == 2214 ||
            id_ == 2232 ||
            id_ == 2238 ||
            id_ == 2508 ||
            id_ == 2629 ||
            id_ == 2863 ||
            id_ == 3055 ||
            id_ == 3073 ||
            id_ == 3280 ||
            id_ == 3297 ||
            id_ == 3322 ||
            id_ == 3327 ||
            id_ == 3361 ||
            id_ == 3411 ||
            id_ == 3605 ||
            id_ == 3639 ||
            id_ == 3774 ||
            id_ == 4250 ||
            id_ == 4267 ||
            id_ == 4302 ||
            id_ == 4362 ||
            id_ == 4382 ||
            id_ == 4397 ||
            id_ == 4675 ||
            id_ == 4707 ||
            id_ == 4863;
    }

    /*///////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyMinter() {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT OR BURN");
        _;
    }

    modifier onlyRuler() {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

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

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC721Like.onERC721Received.selector;
    }
}

interface ERC721Like {
    function balanceOf(address holder_) external view returns (uint256);

    function ownerOf(uint256 id_) external view returns (address);

    function walletOfOwner(address _owner) external view returns (uint256[] calldata);

    function tokensOfOwner(address owner) external view returns (uint256[] memory);

    function isApprovedForAll(address operator_, address address_) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface UniPairLike {
    function token0() external returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}