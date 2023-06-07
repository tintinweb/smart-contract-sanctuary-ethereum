// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./MulticallUpgradeable.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IPTokenFactory.sol";
import "./interfaces/IPToken.sol";
import "./interfaces/IFundingStrategy.sol";
import "./libraries/TransferHelper.sol";

/**
 * @title Pawnfi's LB Contract
 * @author Pawnfi
 */
contract LB is MulticallUpgradeable, OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // Denominator, used for calculating percentage
    uint256 private constant BASE = 1e18;

    /// @notice WETH address
    address public WETH;

    /// @notice ptoken factory address
    address public ptokenFactory;

    /// @notice Floating percentage for calculating rational price range - to provide liquidity on Uniswap
    uint256 public floatingPercentage;

    /// @notice Strategy address
    address public strategy;

    /**
     * @dev Fundraising status
     */
    enum FundraisingStatus { processing, finished, received, canceled }

    /**
     * @notice Fundraising info
     * @member startTime Start time
     * @member endTime End time
     * @member unlockTime Unlock time
     * @member fee uniswap fee tier
     * @member sqrtPriceX96 Expected square root price when adding liquidity
     * @member tickLower Min price
     * @member tickUpper Max price
     * @member rewardToken Reward token address
     * @member token0 token0 address
     * @member token1 token1 address
     * @member fundraisingStatus Fundraising status
     * @member rewardAmounts Reward token amount when event completes
     * @member targetAmounts Target amount
     * @member amounts Raised amount
     */
    struct FundraisingInfo {
        uint32 startTime;
        uint32 endTime;
        uint32 unlockTime;
        uint24 fee;
        uint160 sqrtPriceX96;
        int24 tickLower;
        int24 tickUpper;
        address rewardToken;
        address token0;
        address token1;
        FundraisingStatus fundraisingStatus;
        mapping(address => uint256) rewardAmounts;
        mapping(address => uint256) targetAmounts;
        mapping(address => uint256) amounts;
    }

    /**
     * @notice User info
     * @member nftIds Comitted nft id list
     * @member depositAmount Comitted asset amount
     * @member withdrawAmount Withdrawalbe asset amount
     */
    struct UserInfo {
        mapping(address => EnumerableSetUpgradeable.UintSet) nftIds;
        mapping(address => uint256) depositAmount;
        mapping(address => uint256) withdrawAmount;
    }

    /// @notice Latest EventID
    uint256 public roundId;

    // Store fundraising info of different Event ID
    mapping(uint256 => FundraisingInfo) private _fundraisingInfoMap;

    // Store user info of different Event ID
    mapping(address => mapping(uint256 => UserInfo)) private _userInfoMap;

    /// @notice Emitted event info when fundraising launches
    event OrganiseEvent(
        uint256 indexed roundId,
        address indexed account,
        address rewardToken,
        address token0,
        address token1,
        uint256 rewardAmount0,
        uint256 rewardAmount1,
        uint256 targetAmount0,
        uint256 targetAmount1,
        uint32 startTime,
        uint32 endTime,
        uint32 unlockTime
    );

    /// @notice Emitted market making info when fundraising launches
    event MarketMakingInfo(uint256 indexed roundId, uint24 fee, uint160 sqrtPriceX96, int24 tickLower, int24 tickUpper);

    /// @notice Emitted when fundraising completes
    event RaisingSuccess(uint256 indexed roundId, uint256 price);

    /// @notice Emitted when cancelling fundraising
    event RaisingCancel(uint256 indexed roundId);

    /// @notice Emitted when committing in NFT
    event RaiseFundsNFT(uint256 indexed roundId, address indexed account, address nft, uint256[] nftIds);

    /// @notice Emitted when participating in fundraising
    event RaiseFunds(uint256 indexed roundId, address indexed account, address token, uint256 totalDepositAmount, uint256 totalAmount);

    /// @notice Emitted when redeeming NFT
    event RedeemNft(uint256 indexed roundId, address indexed account, address nft, uint256[] ids);

    /// @notice Emitted when applying refund - fundraising failed
    event RefundAsset(uint256 indexed roundId, address indexed account, address token0, address token1, uint256 amount0, uint256 amount1);

    /// @notice Emitted when withdrawing - fundraising succeeded
    event WithdrawAsset(
        uint256 indexed roundId,
        address indexed account,
        address token0,
        address token1,
        uint256 liquidityAmount0,
        uint256 liquidityAmount1,
        uint256 swapFee0,
        uint256 swapFee1,
        uint256 bonus0,
        uint256 bonus1,
        uint256 rewardAmount
    );

    /// @notice Emitted when claiming asset
    event Claim(uint256 indexed roundId, address indexed account);
    
    /// @notice Emitted when claiming reward token
    event ClaimRewardToken(uint256 indexed roundId, address indexed account);

    /**
     * @notice Initialize contract parameters - only execute once
     * @param owner_ Owner address
     * @param WETH_ WETH address
     * @param ptokenFactory_ ptkoen factory address
     * @param floatingPercentage_ Floating percentage for calculating rational price range - to provide liquidity on Uniswap
     */
    function initialize(address owner_, address WETH_, address ptokenFactory_, uint256 floatingPercentage_) external initializer {
        _transferOwnership(owner_);

        WETH = WETH_;
        ptokenFactory = ptokenFactory_;
        floatingPercentage = floatingPercentage_;
    }

    /**
     * @notice Set new strategy address - exclusive to owner
     * @param newStrategy New strategy address
     */
    function setStrategy(address newStrategy) external onlyOwner {
        strategy = newStrategy;
    }

    /**
     * @notice Set new floating percentage - exclusive to owner
     * @param newFloatingPercentage New floating percentage
     */
    function setFloatingPercentage(uint256 newFloatingPercentage) external onlyOwner {
        floatingPercentage = newFloatingPercentage;
    }

    struct OrganiseEventParams {
        uint32 startTime;
        uint32 endTime;
        uint32 unlockTime;
        uint24 fee;
        uint160 sqrtPriceX96;
        int24 tickLower;
        int24 tickUpper;
        address rewardToken;
        address token0;
        address token1;
        uint256 rewardAmount0;
        uint256 rewardAmount1;
        uint256 targetAmount0;
        uint256 targetAmount1;
    }

    /**
     * @notice Initiate fundraising - exclusive to owner
     * @param organiseEventParams Fundraising info
     */
    function organiseEvent(OrganiseEventParams memory organiseEventParams) external onlyOwner {
        require(
            organiseEventParams.startTime >= block.timestamp &&
            organiseEventParams.startTime < organiseEventParams.endTime &&
            organiseEventParams.endTime < organiseEventParams.unlockTime,
            "time error"
        );
        require(organiseEventParams.token0 < organiseEventParams.token1, "sort error");
        require(organiseEventParams.token0 != address(0), "token error");

        roundId++;
        FundraisingInfo storage info = _fundraisingInfoMap[roundId];
        info.startTime = organiseEventParams.startTime;
        info.endTime = organiseEventParams.endTime;
        info.unlockTime = organiseEventParams.unlockTime;
        info.fee = organiseEventParams.fee;
        info.sqrtPriceX96 = organiseEventParams.sqrtPriceX96;
        info.tickLower = organiseEventParams.tickLower;
        info.tickUpper = organiseEventParams.tickUpper;
        info.rewardToken = organiseEventParams.rewardToken;
        info.token0 = organiseEventParams.token0;
        info.token1 = organiseEventParams.token1;
        info.rewardAmounts[organiseEventParams.token0] = organiseEventParams.rewardAmount0;
        info.rewardAmounts[organiseEventParams.token1] = organiseEventParams.rewardAmount1;
        info.targetAmounts[organiseEventParams.token0] = organiseEventParams.targetAmount0;
        info.targetAmounts[organiseEventParams.token1] = organiseEventParams.targetAmount1;

        emit OrganiseEvent(
            roundId,
            msg.sender,
            organiseEventParams.rewardToken,
            organiseEventParams.token0,
            organiseEventParams.token1,
            organiseEventParams.rewardAmount0,
            organiseEventParams.rewardAmount1,
            organiseEventParams.targetAmount0,
            organiseEventParams.targetAmount1,
            organiseEventParams.startTime,
            organiseEventParams.endTime,
            organiseEventParams.unlockTime
        );
        emit MarketMakingInfo(roundId, organiseEventParams.fee, organiseEventParams.sqrtPriceX96, organiseEventParams.tickLower, organiseEventParams.tickUpper);
    }

    /**
     * @notice Get fundraising info based on EventID
     * @param rId EventID
     * @return startTime raising start time
     * @return endTime raising end time
     * @return unlockTime token unlock time
     * @return rewardToken reward token
     * @return token0 token0 address
     * @return token1 token1 address
     * @return rewardAmount0 token0 reward amount assigned
     * @return rewardAmount1 token1 reward amount assigned
     * @return targetAmount0 token0 target amount
     * @return targetAmount1 token1 target amount
     * @return amount0 token0 raised amount
     * @return amount1 token1 raised amount
     */
    function getFundraisingInfo(uint256 rId)
        external
        view
        returns (
            uint32 startTime,
            uint32 endTime,
            uint32 unlockTime,
            address rewardToken,
            address token0,
            address token1,
            uint256 rewardAmount0,
            uint256 rewardAmount1,
            uint256 targetAmount0,
            uint256 targetAmount1,
            uint256 amount0,
            uint256 amount1
        )
    {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        
        startTime = raisingInfo.startTime;
        endTime = raisingInfo.endTime;
        unlockTime = raisingInfo.unlockTime;

        rewardToken = raisingInfo.rewardToken;
        (token0, token1, targetAmount0, targetAmount1, amount0, amount1) = getAmountsInfo(rId);
        
        rewardAmount0 = raisingInfo.rewardAmounts[token0];
        rewardAmount1 = raisingInfo.rewardAmounts[token1];
    }

    /**
     * @notice Get raised amount info
     * @param rId EventID
     * @return token0 token0 address
     * @return token1 token1 address
     * @return targetAmount0 token0 target amount
     * @return targetAmount1 token1 target amount
     * @return amount0 token0 raised amount
     * @return amount1 token1 raised amount
     */
    function getAmountsInfo(uint256 rId) public view returns (address token0, address token1, uint256 targetAmount0, uint256 targetAmount1, uint256 amount0, uint256 amount1) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        token0 = raisingInfo.token0;
        token1 = raisingInfo.token1; 
        targetAmount0 = raisingInfo.targetAmounts[token0];
        targetAmount1 = raisingInfo.targetAmounts[token1];
        amount0 = raisingInfo.amounts[token0];
        amount1 = raisingInfo.amounts[token1];
    }

    /**
     * @notice Get market making info based on EventID
     * @param rId EventID
     * @return fee uniswap fee tier
     * @return sqrtPriceX96 Expected square root price
     * @return tickLower Min price
     * @return tickUpper Max price
     * @return token0 token0 address
     * @return token1 token1 address
     */
    function getMarketMakingInfo(uint256 rId) external view returns (uint24 fee, uint160 sqrtPriceX96, int24 tickLower, int24 tickUpper, address token0, address token1) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];

        fee = raisingInfo.fee;
        sqrtPriceX96 = raisingInfo.sqrtPriceX96;
        tickLower = raisingInfo.tickLower;
        tickUpper = raisingInfo.tickUpper;

        token0 = raisingInfo.token0;
        token1 = raisingInfo.token1;
    }

    /**
     * @notice Get fundraising status
     * @param rId EventID
     * @return status Event status
     */
    function getFundraisingStatus(uint256 rId) public view returns (FundraisingStatus status) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        status = raisingInfo.fundraisingStatus;
    }

    /**
     * @notice Get user info
     * @param user User address
     * @param rId EventID
     * @return token0 token0 address
     * @return token1 token1 address
     * @return amount0 Committed token0 amount
     * @return amount1 Committed token1 amount
     * @return withdrawAmount0 Withdrawable token0 amount
     * @return withdrawAmount1 Withdrawable token1 amount
     * @return idsAtToken0 token0 nft array
     * @return idsAtToken1 token1 nft array
     */
    function getUserInfo(address user, uint256 rId)
        public
        view
        returns (
            address token0,
            address token1,
            uint256 amount0,
            uint256 amount1,
            uint256 withdrawAmount0,
            uint256 withdrawAmount1,
            uint256[] memory idsAtToken0,
            uint256[] memory idsAtToken1
        )
    {
        UserInfo storage userInfo = _userInfoMap[user][rId];
        token0 = _fundraisingInfoMap[rId].token0;
        token1 = _fundraisingInfoMap[rId].token1;

        amount0 = userInfo.depositAmount[token0];
        amount1 = userInfo.depositAmount[token1];

        withdrawAmount0 = userInfo.withdrawAmount[token0];
        withdrawAmount1 = userInfo.withdrawAmount[token1];

        EnumerableSetUpgradeable.UintSet storage nftIdsAtToken0 = _userInfoMap[user][rId].nftIds[token0];
        EnumerableSetUpgradeable.UintSet storage nftIdsAtToken1 = _userInfoMap[user][rId].nftIds[token1];
        
        idsAtToken0 = new uint256[](nftIdsAtToken0.length());
        for(uint i = 0; i < nftIdsAtToken0.length(); i++) {
            idsAtToken0[i] = nftIdsAtToken0.at(i);
        }

        idsAtToken1 = new uint256[](nftIdsAtToken1.length());
        for(uint i = 0; i < nftIdsAtToken1.length(); i++) {
            idsAtToken1[i] = nftIdsAtToken1.at(i);
        }
    }

    /**
     * @notice Get the owner address of nft id
     * @param user user address
     * @param nftAddr nft address
     * @param nftId nft id
     * @return address owner address
     */
    function nftOwner(address user, address nftAddr, uint256 nftId) external view returns(address) {
        address token = IPTokenFactory(ptokenFactory).getPiece(nftAddr);
        for(uint i = 1; i <= roundId; i++) {
            EnumerableSetUpgradeable.UintSet storage nftIdsAtToken = _userInfoMap[user][i].nftIds[token];
            for(uint j = 0; j < nftIdsAtToken.length(); j++) {
                if(nftId == nftIdsAtToken.at(j)) {
                    return user;
                }
            }
        }
        
        return address(0);
    }

    /**
     * @notice Validate whether committing is allowed
     * @param rId Event ID
     * @param token Token address
     * @param amount Committed amount
     * @return Difference from target amount
     */
    function _raiseAllowed(uint256 rId, address token, uint256 amount) private view returns (uint256) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        require(block.timestamp >= raisingInfo.startTime && block.timestamp <= raisingInfo.endTime, "out of time frame");
        require(raisingInfo.fundraisingStatus == FundraisingStatus.processing, "fundraising status isn't processing");
        uint256 targetAmount = raisingInfo.targetAmounts[token];
        require(targetAmount > 0, "token error");
        uint256 raisedAmount = raisingInfo.amounts[token];
        uint256 diffAmount = targetAmount - raisedAmount;
        require(diffAmount > 0, "enough amount");
        return MathUpgradeable.min(amount, diffAmount);
    }

    /**
     * @notice Participate in fundraising
     * @param rId EventID
     * @param token token address
     * @param amount Committed amount
     */
    function raiseFundsToken(uint256 rId, address token, uint256 amount) external payable {
        require(amount > 0, "raise funds failed");
        uint256 depositAmount = _raiseAllowed(rId, token, amount);
        if(token == WETH && address(this).balance >= depositAmount) {
            IWETH(token).deposit{value: depositAmount}();
        } else {
            IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), depositAmount);
        }
        _raiseFunds(rId, msg.sender, token, depositAmount);
    }

    /**
     * @notice Raise fund with nft
     * @param rId EventID
     * @param ptoken ptoken address
     * @param ids nft id array
     */
    function raiseFundsNFT(uint256 rId, address ptoken, uint256[] memory ids) external payable {
        address nftAddr = IPTokenFactory(ptokenFactory).getNftAddress(ptoken);
        require(nftAddr != address(0), "nft address not exist");
        uint256 idsLength = ids.length;
        require(idsLength > 0, "length error");

        uint256 pieceCount = IPToken(ptoken).pieceCount();
        uint256 depositAmount = _raiseAllowed(rId, ptoken, pieceCount * idsLength);
        uint256 length = depositAmount / pieceCount;
        length = depositAmount % pieceCount > 0 ? length + 1 : length;
        length = MathUpgradeable.min(idsLength, length);

        uint256[] memory nftIds = new uint256[](length);
        address nftTransferManager = IPTokenFactory(ptokenFactory).nftTransferManager();
        for(uint i = 0; i < length; i++) {
            TransferHelper.transferInNonFungibleToken(nftTransferManager, nftAddr, msg.sender, address(this), ids[i]);
            TransferHelper.approveNonFungibleToken(nftTransferManager, nftAddr, address(this), ptoken, ids[i]);
            
            nftIds[i] = ids[i];
            _userInfoMap[msg.sender][rId].nftIds[ptoken].add(ids[i]);
        }

        uint256 amount = IPToken(ptoken).deposit(nftIds, type(uint256).max);
        _raiseFunds(rId, msg.sender, ptoken, MathUpgradeable.min(amount, depositAmount));
        if(amount > depositAmount) {
            IERC20Upgradeable(ptoken).safeTransfer(msg.sender, amount - depositAmount);
        }
        emit RaiseFundsNFT(rId, msg.sender, nftAddr, nftIds);
    }

    /**
     * @notice Update fundraising info
     * @param rId Event Id
     * @param user User address
     * @param token Token address
     * @param amount Committed amount 
     */
    function _raiseFunds(uint256 rId, address user, address token, uint256 amount) private {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        uint256 totalAmount = raisingInfo.amounts[token] + amount;
        raisingInfo.amounts[token] = totalAmount;

        UserInfo storage userInfo = _userInfoMap[user][rId];
        uint256 userAmount = userInfo.depositAmount[token] + amount;
        userInfo.depositAmount[token] = userAmount;

        emit RaiseFunds(rId, user, token, userAmount, totalAmount);

        _automatedExecuteStrategy(rId);
    }

    /**
     * @notice Manually execute strategy - exclusive to owner 
     * @param rId EventId
     */
    function executeStrategy(uint256 rId) external onlyOwner {
        require(reachTargetAmount(rId), "fundraising fund failed");
        _executeStrategy(rId);
    }

    /**
     * @notice Automatic strategy execution
     * @param rId Event Id
     */
    function _automatedExecuteStrategy(uint256 rId) private {
        if(reachTargetAmount(rId)) {
            FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
            uint256 realTimePrice = IFundingStrategy(strategy).getRealTimePrice(raisingInfo.token0, raisingInfo.token1, raisingInfo.fee, 0);
            uint256 proposedPrice = IFundingStrategy(strategy).getRealTimePrice(raisingInfo.token0, raisingInfo.token1, raisingInfo.fee, raisingInfo.sqrtPriceX96);
            uint256 delta = proposedPrice * floatingPercentage / BASE;
            uint256 proposedPriceMinimum = proposedPrice - delta;
            uint256 proposedPriceMaximum = proposedPrice + delta;
            if(proposedPriceMinimum <= realTimePrice && realTimePrice <= proposedPriceMaximum) {
                _executeStrategy(rId);
            }
        }
    }

    /**
     * @notice Execute strategy
     * @param rId Event Id
     */
    function _executeStrategy(uint256 rId) private {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        require(raisingInfo.fundraisingStatus == FundraisingStatus.processing, "executed strategy");
        raisingInfo.fundraisingStatus = FundraisingStatus.finished;

        _approveMax(raisingInfo.token0, strategy, raisingInfo.amounts[raisingInfo.token0]);
        _approveMax(raisingInfo.token1, strategy, raisingInfo.amounts[raisingInfo.token1]);
        IFundingStrategy(strategy).executeStrategy(rId);

        uint256 lockTime = uint256(raisingInfo.unlockTime) - raisingInfo.endTime;
        raisingInfo.unlockTime = uint32(block.timestamp + lockTime);
        
        emit RaisingSuccess(rId, IFundingStrategy(strategy).getInvestmentPrice(rId));
    }

    /**
     * @notice Get whether event reaches target amount
     * @param rId EventID
     * @return success Target reached or not
     */
    function reachTargetAmount(uint256 rId) public view returns (bool success) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        address[] memory tokens = new address[](2);
        tokens[0] = raisingInfo.token0;
        tokens[1] = raisingInfo.token1;

        success = true;
        for(uint8 i = 0; i < tokens.length; i++) {
            if(raisingInfo.amounts[tokens[i]] < raisingInfo.targetAmounts[tokens[i]]) {
                success = false;
            }
        }
    }

    /**
     * @notice Cancel event - exclusive to owner
     * @param rId EventID
     */
    function setFundingRaisingCancel(uint256 rId) external onlyOwner {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        require(raisingInfo.fundraisingStatus == FundraisingStatus.processing, "fundraising status isn't processing");
        
        raisingInfo.endTime = uint32(block.timestamp);
        raisingInfo.fundraisingStatus = FundraisingStatus.canceled;
        emit RaisingCancel(rId);
    }

    /**
     * @notice Redeem nft
     * @param rId Event ID
     * @param token ptoken address
     * @param ids nft id array
     */
    function _redeemNft(uint256 rId, address token, uint256[] memory ids) private {
        uint256 pieceCount = IPToken(token).pieceCount();
        uint256 amount = pieceCount * ids.length;

        UserInfo storage userInfo = _userInfoMap[msg.sender][rId];
        uint256 withdrawalAmount = userInfo.withdrawAmount[token];
        if(amount > withdrawalAmount) {
            uint256 shortfall = amount - withdrawalAmount;
            IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), shortfall);
            withdrawalAmount += shortfall;
        }
        userInfo.withdrawAmount[token] = withdrawalAmount - amount;

        for(uint i = 0; i < ids.length; i++) {
            require(userInfo.nftIds[token].contains(ids[i]), "id not exist");
            userInfo.nftIds[token].remove(ids[i]);
        }
        IPToken(token).withdraw(ids);
        address nftTransferManager = IPTokenFactory(ptokenFactory).nftTransferManager();
        address nftAddr = IPTokenFactory(ptokenFactory).getNftAddress(token);
        for(uint i = 0; i < ids.length; i++) {
            TransferHelper.transferOutNonFungibleToken(nftTransferManager, nftAddr, address(this), msg.sender, ids[i]);
        }
        emit RedeemNft(rId, msg.sender, nftAddr, ids);
    }

    /**
     * @notice Target not reached - refund
     * @param rId EventID
     */
    function refundAsset(uint256 rId) external {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];

        require(block.timestamp > raisingInfo.endTime, "not ended");

        require(
            raisingInfo.fundraisingStatus == FundraisingStatus.processing || raisingInfo.fundraisingStatus == FundraisingStatus.canceled,
            "fundraising status inconsistent"
        );
        if(raisingInfo.fundraisingStatus != FundraisingStatus.canceled) {
            raisingInfo.fundraisingStatus = FundraisingStatus.canceled;
        }

        UserInfo storage userInfo = _userInfoMap[msg.sender][rId];
        address token0 = raisingInfo.token0;
        address token1 = raisingInfo.token1;
        require(userInfo.depositAmount[token0] > 0 || userInfo.depositAmount[token1] > 0, "no deposit amount");

        uint256 amount0 = userInfo.depositAmount[token0];
        uint256 amount1 = userInfo.depositAmount[token1];
        delete userInfo.depositAmount[token0];
        delete userInfo.depositAmount[token1];
        userInfo.withdrawAmount[token0] = amount0;
        userInfo.withdrawAmount[token1] = amount1;

        emit RefundAsset(rId, msg.sender, token0, token1, amount0, amount1);
    }

    /**
     * @notice Exit strategy
     * @param rId EventId
     */
    function exitStrategy(uint256 rId) external {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        require(block.timestamp > raisingInfo.unlockTime, "time error");
        require(raisingInfo.fundraisingStatus == FundraisingStatus.finished, "fundraising status inconsistent");
        raisingInfo.fundraisingStatus = FundraisingStatus.received;
        IFundingStrategy(strategy).exitedStrategy(rId);
    }

    /**
     * @notice Withdraw asset
     * @param rId EventId
     */
    function withdrawAsset(uint256 rId) external {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        require(block.timestamp > raisingInfo.unlockTime, "time error");
        require(raisingInfo.fundraisingStatus == FundraisingStatus.finished || raisingInfo.fundraisingStatus == FundraisingStatus.received, "fundraising status inconsistent");

        if(raisingInfo.fundraisingStatus == FundraisingStatus.finished) {
            IFundingStrategy(strategy).exitedStrategy(rId);
            raisingInfo.fundraisingStatus = FundraisingStatus.received;
        }

        UserInfo storage userInfo = _userInfoMap[msg.sender][rId];
        require(userInfo.depositAmount[raisingInfo.token0] > 0 || userInfo.depositAmount[raisingInfo.token1] > 0, "no deposit amount");

        (uint256 liquidityAmount0, uint256 liquidityAmount1, uint256 swapFee0, uint256 swapFee1, uint256 bonus0, uint256 bonus1) = getWithdrawAmounts(rId, msg.sender);

        uint256 rewardAmount = getRewardTokenAmount(rId, msg.sender);

        delete userInfo.depositAmount[raisingInfo.token0];
        delete userInfo.depositAmount[raisingInfo.token1];

        uint amount0 = liquidityAmount0 + swapFee0 + bonus0;
        userInfo.withdrawAmount[raisingInfo.token0] = amount0;

        uint amount1 = liquidityAmount1 + swapFee1 + bonus1;
        userInfo.withdrawAmount[raisingInfo.token1] = amount1;

        userInfo.withdrawAmount[raisingInfo.rewardToken] = rewardAmount;
        emit WithdrawAsset(rId, msg.sender, raisingInfo.token0, raisingInfo.token1, liquidityAmount0, liquidityAmount1, swapFee0, swapFee1, bonus0, bonus1, rewardAmount);
    }

    /**
     * @notice Get user's withdrawable amount after unlock
     * @param rId EventID
     * @param user User address
     * @return liquidityAmount0 token0 unlock amount
     * @return liquidityAmount1 token1 unlock amount
     * @return swapFee0 token0 swap fee
     * @return swapFee1 tokne1 swap fee
     * @return bonus0 token0 reward
     * @return bonus1 tokne1 reward
     */
    function getWithdrawAmounts(uint256 rId, address user) public returns (uint256 liquidityAmount0, uint256 liquidityAmount1, uint256 swapFee0, uint256 swapFee1, uint256 bonus0, uint256 bonus1) {
        (liquidityAmount0, liquidityAmount1) = _capitalDistribution(rId, user);
        (swapFee0, swapFee1, bonus0, bonus1) = _feeDistribution(rId, user);
    }

    /**
     * @notice Get added liquidity token share
     * @param rId Event Id
     * @param user User address
     * @return liquidityAmount0 token0 amount
     * @return liquidityAmount1 token1 amount
     */
    function _capitalDistribution(uint256 rId, address user) private returns (uint256 liquidityAmount0, uint256 liquidityAmount1) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        uint256 amount0 = raisingInfo.targetAmounts[raisingInfo.token0];
        uint256 amount1 = raisingInfo.targetAmounts[raisingInfo.token1];

        uint256 depositAmount0 = _userInfoMap[user][rId].depositAmount[raisingInfo.token0];
        uint256 depositAmount1 = _userInfoMap[user][rId].depositAmount[raisingInfo.token1];

        (uint256 returnAmount0, uint256 returnAmount1) = IFundingStrategy(strategy).getAmountsForLiquidity(rId);
        (uint256 capital0, uint256 capital1, , ) = IFundingStrategy(strategy).getLendInfos(rId);

        returnAmount0 = returnAmount0 + capital0;
        returnAmount1 = returnAmount1 + capital1;

        uint256 diffAmount;
        uint256 pct;
        if(returnAmount0 > amount0) {
            diffAmount = returnAmount0 - amount0;
            pct = depositAmount1 * BASE / amount1;
            liquidityAmount0 = depositAmount0 + (pct * diffAmount / BASE);
            liquidityAmount1 = pct * returnAmount1 / BASE;
        } else if(returnAmount1 > amount1) {
            diffAmount = returnAmount1 - amount1;
            pct = depositAmount0 * BASE / amount0;
            liquidityAmount1 = depositAmount1 + (pct * diffAmount / BASE);
            liquidityAmount0 = pct * returnAmount0 / BASE;
        } else {
            liquidityAmount0 = depositAmount0 * returnAmount0 / amount0;
            liquidityAmount1 = depositAmount1 * returnAmount1 / amount1;
        }
    }

    /**
     * @notice Get swap fee and lending revenue after strategy execution
     * @param rId Event Id
     * @param user User address
     * @return swapFee0 token0 swap fee
     * @return swapFee1 token1 swap fee
     * @return bonus0 token0 lending revenue
     * @return bonus1 token1 lending revenue
     */
    function _feeDistribution(uint256 rId, address user) private returns (uint256 swapFee0, uint256 swapFee1, uint256 bonus0, uint256 bonus1) {
        ( , , uint256 tokenBonus0, uint256 tokenBonus1) = IFundingStrategy(strategy).getLendInfos(rId);
        (uint256 token0Fee, uint256 token1Fee) = IFundingStrategy(strategy).getSwapFees(rId);

        uint256 proportion = getInvestmentProportion(rId, user);
        swapFee0 = proportion * token0Fee / BASE;
        swapFee1 = proportion * token1Fee / BASE;
        bonus0 = proportion * tokenBonus0 / BASE;
        bonus1 = proportion * tokenBonus1 / BASE;
    }

    /**
     * @notice Claim committed token
     * @param rId EventID
     */
    function claim(uint256 rId) external {
        // (address token0, address token1, uint256 amount0, uint256 amount1, uint256 withdrawAmount0, uint256 withdrawAmount1, uint256[] idsAtToken0, uint256[] idsAtToken1)
        (address token0, address token1, , , , , uint256[] memory idsAtToken0, uint256[] memory idsAtToken1) = getUserInfo(msg.sender, rId);

        if(idsAtToken0.length > 0) {
            _redeemNft(rId, token0, idsAtToken0);
        }
        if(idsAtToken1.length > 0) {
            _redeemNft(rId, token1, idsAtToken1);
        }

        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;
        _claim(rId, msg.sender, tokens);

        emit Claim(rId, msg.sender);
    }

    /**
     * @notice Claim reward token
     * @param rId EventId
     */
    function claimRewardToken(uint256 rId) external {
        address[] memory tokens = new address[](1);
        tokens[0] = _fundraisingInfoMap[rId].rewardToken;
        _claim(rId, msg.sender, tokens);
        emit ClaimRewardToken(rId, msg.sender);
    }

    function _claim(uint256 rId, address user, address[] memory tokens) private {
        UserInfo storage userInfo = _userInfoMap[user][rId];
        for(uint i = 0; i < tokens.length; i++) {
            uint256 amount = userInfo.withdrawAmount[tokens[i]];
            if(amount > 0) {
                delete userInfo.withdrawAmount[tokens[i]];
                _transferAsset(tokens[i], amount);
            }
        }
    }

    /**
     * @notice Send asset
     * @param token token address
     * @param amount Sent amount
     */
    function _transferAsset(address token, uint256 amount) private {
        if(token == WETH) {
            IWETH(WETH).withdraw(amount);
            refundETH();
        } else {
            IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice Refund ETH
     */
    function refundETH() public payable {
        uint256 bal = address(this).balance;
        if(bal > 0) {
            payable(msg.sender).transfer(bal);
        }
    }

    /**
     * @notice Get user committed proportion
     * @param rId EventID
     * @param user User address
     * @return proportion proportion percentage / BASE
     */
    function getInvestmentProportion(uint256 rId, address user) public view returns (uint256) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];
        if(raisingInfo.fundraisingStatus == FundraisingStatus.finished || raisingInfo.fundraisingStatus == FundraisingStatus.received) {
            uint256 price = IFundingStrategy(strategy).getInvestmentPrice(rId);
        
            // (address token0, address token1, uint256 depositAmount0, uint256 depositAmount1, uint256 withdrawAmount0, uint256 withdrawAmount1, uint256[] idsAtToken0, uint256[] idsAtToken1)
            (address token0, address token1, uint256 depositAmount0, uint256 depositAmount1, , , , ) = getUserInfo(user, rId);

            uint256 amount0 = raisingInfo.targetAmounts[token0];
            uint256 amount1 = raisingInfo.targetAmounts[token1];

            uint256 totalAmount = amount0 * price / BASE + amount1;
            uint256 totalDepositAmount = depositAmount0 * price / BASE + depositAmount1;
            return totalDepositAmount * BASE / totalAmount;
        }
        return 0;
    }

    /**
     * @notice Get reward token amount based on committed tokens
     * @param rId EventID
     * @param user User address
     * @return reward reward token amount
     */
    function getRewardTokenAmount(uint256 rId, address user) public view returns (uint256) {
        FundraisingInfo storage raisingInfo = _fundraisingInfoMap[rId];

        address token0 = raisingInfo.token0;
        address token1 = raisingInfo.token1;

        uint256 depositAmount0 = _userInfoMap[user][rId].depositAmount[token0];
        uint256 depositAmount1 = _userInfoMap[user][rId].depositAmount[token1];

        uint256 targetAmount0 = raisingInfo.targetAmounts[token0];
        uint256 targetAmount1 = raisingInfo.targetAmounts[token1];

        uint256 rewardAmount0 = raisingInfo.rewardAmounts[token0] * depositAmount0 / targetAmount0;
        uint256 rewardAmount1 = raisingInfo.rewardAmounts[token1] * depositAmount1 / targetAmount1;
        return rewardAmount0 + rewardAmount1;
    }

    /**
     * @notice Approve token
     * @param token token address
     * @param spender Approved address
     * @param amount Approved amount
     */
    function _approveMax(address token, address spender, uint256 amount) private {
        uint256 allowance = IERC20Upgradeable(token).allowance(address(this), spender);
        if(allowance < amount) {
            IERC20Upgradeable(token).safeApprove(spender, 0);
            IERC20Upgradeable(token).safeApprove(spender, type(uint256).max);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IFundingStrategy {

    function getInvestmentPrice(uint256 _roundId) external view returns(uint256);

    function getRealTimePrice(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) external view returns(uint256);

    function executeStrategy(uint256 _roundId) external;

    function exitedStrategy(uint256 _roundId) external;

    function getAmountsForLiquidity(uint256 _roundId) external view returns(uint256 amount0, uint256 amount1);

    function getLendInfos(uint256 _roundId) external returns(uint256 capital0, uint256 capital1, uint256 bonus0, uint256 bonus1);

    function getSwapFees(uint256 _roundId) external returns(uint256 token0Fee, uint256 token1Fee);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IPToken {

    function pieceCount() external view returns(uint256);

    function deposit(uint256[] memory nftIds, uint256 blockNumber) external returns(uint256 tokenAmount);

    function withdraw(uint256[] memory nftIds) external returns(uint256 tokenAmount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IPTokenFactory {

    function nftTransferManager() external view returns(address);

    function getNftAddress(address ptokenAddr) external view returns(address);
    function getPiece(address nftAddr) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

interface ITransferManager {
    function getInputData(address nftAddress, address from, address to, uint256 tokenId, bytes32 operateType) external view returns (bytes memory data);
}

library TransferHelper {

    using AddressUpgradeable for address;

    // keccak256("TRANSFER_IN")
    bytes32 private constant TRANSFER_IN = 0xe69a0828d85fdb5875ad77f7b8a0e2275447a64f18daaf58f34b3af9b7b691da;
    // keccak256("TRANSFER_OUT")
    bytes32 private constant TRANSFER_OUT = 0x2b6780fa84213a97faf5c6208861692a9b75df0c4afffad07a2dc98411dfe785;
    // keccak256("APPROVAL")
    bytes32 private constant APPROVAL = 0x2acd155ba8c67e9321668716d05aae1ff9e47e502b6b2f301b6f41e3a57ee2ef;

    /**
     * @notice Transfer in NFT
     * @param transferManager nft transfer manager contract address
     * @param nftAddr nft address
     * @param from Sender address
     * @param to Receiver address
     * @param nftId NFT ID   
     */
    function transferInNonFungibleToken(address transferManager, address nftAddr, address from, address to, uint256 nftId) internal {
        bytes memory data = ITransferManager(transferManager).getInputData(nftAddr, from, to, nftId, TRANSFER_IN);
        nftAddr.functionCall(data);
    }

    /**
     * @notice Transfer in NFT
     * @param transferManager nft transfer manager contract address
     * @param nftAddr nft address
     * @param from Sender address
     * @param to Receiver address
     * @param nftId NFT ID   
     */
    function transferOutNonFungibleToken(address transferManager, address nftAddr, address from, address to, uint256 nftId) internal {
        bytes memory data = ITransferManager(transferManager).getInputData(nftAddr, from, to, nftId, TRANSFER_OUT);
        nftAddr.functionCall(data);
    }

    /**
     * @notice Approve NFT
     * @param transferManager nft transfer manager contract address
     * @param nftAddr nft address
     * @param from Sender address
     * @param to Receiver address
     * @param nftId NFT ID   
     */
    function approveNonFungibleToken(address transferManager, address nftAddr, address from, address to, uint256 nftId) internal {
        bytes memory data = ITransferManager(transferManager).getInputData(nftAddr, from, to, nftId, APPROVAL);
        nftAddr.functionCall(data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external payable virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}