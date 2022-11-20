/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-07 17:56:09
 * @Description: 基于区块链的代币化字幕众包系统
 * @Copyright (c) 2022 by LaplaceMan [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/ISettlementStrategy.sol";
import "./base/StrategyManager.sol";
import "./base/VideoManager.sol";
import "./interfaces/IVT.sol";

contract SubtitleSystem is StrategyManager, VideoManager {
    /**
     * @notice TSCS 内已经发出的申请总数
     */
    uint256 public totalApplyNumber;

    /**
     * @notice 每个申请都有一个相应的 Application 结构记录申请信息
     * @param applicant 发出申请, 需求制作字幕服务的用户
     * @param videoId 申请所属视频的 ID
     * @param strategy 结算策略
     * @param amount 支付金额/比例
     * @param language 申请所需语言的 ID
     * @param subtitles 申请下已上传字幕的 ID 集合
     * @param adopted 最终被采纳字幕的 ID
     * @param deadline 结算策略为 0 时, 超过该期限可提取费用, 其它策略为申请冻结
     */
    struct Application {
        address applicant;
        address platform;
        uint256 videoId;
        string source;
        uint8 strategy;
        uint256 amount;
        uint16 language;
        uint256[] subtitles;
        uint256 adopted;
        uint256 deadline;
    }

    constructor(address owner) {
        _setOwner(owner);
        // 当结算类型为一次性结算时, 默认字幕支持者分成 1/100
        platforms[address(0)].rateAuditorDivide = 655;
        platforms[address(0)].name = "Default";
        platforms[address(0)].symbol = "Default";
        languageTypes.push("Default");
    }

    /**
     * @notice applyId 与 Application 的映射, 从 1 开始（发出申请的顺位）
     */
    mapping(uint256 => Application) public totalApplys;

    event ApplicationSubmit(
        address applicant,
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint16 language,
        uint256 deadline,
        uint256 applyId,
        string src
    );
    event SubtitleCountsUpdate(
        address platform,
        uint256[] subtitleId,
        uint256[] counts
    );

    event ApplicationCancel(uint256 applyId);
    event ApplicationRecover(uint256 applyId, uint256 amount, uint256 deadline);
    event ApplicationUpdate(
        uint256 applyId,
        uint256 newAmount,
        uint256 newDeadline
    );
    event ApplicationReset(uint256 applyId);

    event UserWithdraw(
        address user,
        address platform,
        uint256[] day,
        uint256 all
    );
    event VideoPreExtract(uint256 videoId, uint256 unsettled, uint256 surplus);

    /**
     * @notice 由平台 Platform 注册视频, 此后该视频支持链上结算（意味着更多结算策略的支持）
     * @param id 视频在 Platform 内部的 ID
     * @param symbol 视频的 symbol
     * @param creator 视频创作者区块链地址
     * @return 视频在 TSCS 内的 ID
     */
    function createVideo(
        uint256 id,
        string memory symbol,
        address creator
    ) external returns (uint256) {
        require(platforms[msg.sender].rateCountsToProfit > 0, "ER1");
        uint256 videoId = _createVideo(msg.sender, id, symbol, creator);
        return videoId;
    }

    /**
     * @notice 提交制作字幕的申请
     * @param platform 视频所属平台 Platform 区块链地址
     * @param videoId 视频在 TSCS 内的 ID
     * @param strategy 结算策略 ID
     * @param amount 支付金额/比例
     * @param language 申请所需要语言的 ID
     * @return 在 TSCS 内发出申请的顺位, applyId
     */
    function submitApplication(
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint16 language,
        uint256 deadline,
        string memory source
    ) external returns (uint256) {
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 Zimu 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        require(deadline > block.timestamp, "ER1");
        require(settlementStrategy[strategy].strategy != address(0), "ER6");
        totalApplyNumber++;
        // 当平台地址为 0, 意味着使用默认结算策略
        if (platform == address(0)) {
            require(strategy == 0, "ER7");
            require(bytes(source).length > 0, "ER1-7");
            // 一次性结算策略下, 需要用户提前授权主合约额度且只能使用 Zimu 代币支付
            IZimu(zimuToken).transferFrom(msg.sender, address(this), amount);
        } else {
            // 当结算策略非一次性时, 与视频收益相关, 需要由视频创作者主动提起
            require(videos[videoId].creator == msg.sender, "ER5");
            // 下面是为了防止重复申请制作同一语言的字幕
            for (uint256 i; i < videos[videoId].applys.length; i++) {
                uint256 applyId = videos[videoId].applys[i];
                require(totalApplys[applyId].language != language, "ER0");
            }
            uint256[] memory newApplyArr = _sortStrategyPriority(
                videos[videoId].applys,
                strategy,
                totalApplyNumber
            );
            videos[videoId].applys = newApplyArr;
        }
        if (strategy == 2 || strategy == 0) {
            // 更新未结算稳定币数目
            ISettlementStrategy(settlementStrategy[strategy].strategy)
                .updateDebtOrReward(totalApplyNumber, 0, amount, 0);
        }
        // 上面都是对不同支付策略时申请变化的判断，也可以或者说应该模块化设计
        totalApplys[totalApplyNumber].applicant = msg.sender;
        totalApplys[totalApplyNumber].videoId = videoId;
        totalApplys[totalApplyNumber].strategy = strategy;
        totalApplys[totalApplyNumber].amount = amount;
        totalApplys[totalApplyNumber].language = language;
        totalApplys[totalApplyNumber].deadline = deadline;
        totalApplys[totalApplyNumber].platform = platform;
        totalApplys[totalApplyNumber].source = source;
        // 奖励措施
        IVT(videoToken).mintStableToken(
            0,
            msg.sender,
            users[msg.sender].reputation
        );
        emit ApplicationSubmit(
            msg.sender,
            platform,
            videoId,
            strategy,
            amount,
            language,
            deadline,
            totalApplyNumber,
            source
        );
        return totalApplyNumber;
    }

    /**
     * @notice 每次为视频新添加申请时，根据结算策略优先度更新 applys 数组（主要是方便结算逻辑的执行）
     * @param arr 已有的申请序列
     * @param spot 新申请的策略
     * @param id 新申请的 id
     * @return 从小到大（策略结算优先级）顺序的申请序列
     */
    function _sortStrategyPriority(
        uint256[] memory arr,
        uint256 spot,
        uint256 id
    ) internal view returns (uint256[] memory) {
        uint256[] memory newArr = new uint256[](arr.length + 1);
        if (newArr.length == 1) {
            newArr[0] = id;
            return newArr;
        }
        uint256 flag;
        for (flag = arr.length - 1; flag > 0; flag--) {
            if (spot >= totalApplys[arr[flag]].strategy) {
                break;
            }
        }
        for (uint256 i; i < newArr.length; i++) {
            if (i <= flag) {
                newArr[i] = arr[i];
            } else if (i == flag + 1) {
                newArr[i] = id;
            } else {
                newArr[i] = arr[i - 1];
            }
        }
        return newArr;
    }

    /**
     * @notice 获得特定申请下所有已上传字幕的指纹, 暂定为 Simhash
     * @param applyId 申请在 TSCS 内的顺位 ID
     * @return 该申请下所有已上传字幕的 fingerprint
     */
    function _getHistoryFingerprint(uint256 applyId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory history = new uint256[](
            totalApplys[applyId].subtitles.length
        );
        for (uint256 i = 0; i < totalApplys[applyId].subtitles.length; i++) {
            history[i] = IST(subtitleToken).getSTFingerprint(
                totalApplys[applyId].subtitles[i]
            );
        }
        return history;
    }

    /**
     * @notice 上传制作的字幕
     * @param applyId 字幕所属申请在 TSCS 内的顺位 ID
     * @param cid 字幕存储在 IPFS 获得的 CID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹值, 暂定为 Simhash
     * @return 字幕 ST ID
     */
    function uploadSubtitle(
        uint256 applyId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256) {
        // 无法为已被确认的申请上传字幕, 防止资金和制作力浪费
        require(totalApplys[applyId].adopted == 0, "ER3");
        // 期望截至日期前没有字幕上传则申请被冻结
        if (totalApplys[applyId].subtitles.length == 0) {
            require(block.timestamp <= totalApplys[applyId].deadline, "ER3");
        }
        // 确保字幕的语言与申请所需的语言一致
        require(languageId == totalApplys[applyId].language, "ER9");
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 Zimu 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        uint256[] memory history = _getHistoryFingerprint(applyId);
        // 字幕相似度检测
        if (address(detectionStrategy) != address(0)) {
            require(
                detectionStrategy.beforeDetection(fingerprint, history),
                "ER10"
            );
        }
        // ERC721 Token 生成
        uint256 subtitleId = _createST(
            msg.sender,
            applyId,
            cid,
            languageId,
            fingerprint
        );
        totalApplys[applyId].subtitles.push(subtitleId);
        return subtitleId;
    }

    /**
     * @notice 由平台 Platform 更新其旗下视频中被确认字幕的使用量，目前只对于分成结算有用
     * @param id 相应的申请 ID
     * @param ss 新增使用量
     */
    function updateUsageCounts(uint256[] memory id, uint256[] memory ss)
        external
    {
        require(id.length == ss.length, "ER1");
        for (uint256 i = 0; i < id.length; i++) {
            if (totalApplys[id[i]].adopted > 0) {
                address platform = videos[totalApplys[id[i]].videoId].platform;
                require(msg.sender == platform, "ER5");
                require(
                    totalApplys[id[i]].strategy != 0 &&
                        totalApplys[id[i]].strategy != 2,
                    "ER1"
                );
                ISettlementStrategy(
                    settlementStrategy[totalApplys[id[i]].strategy].strategy
                ).updateDebtOrReward(
                        id[i],
                        ss[i],
                        totalApplys[id[i]].amount,
                        platforms[platform].rateCountsToProfit
                    );
            }
        }
        emit SubtitleCountsUpdate(msg.sender, id, ss);
    }

    /**
     * @notice 获得特定字幕与审核相关的信息
     * @param subtitleId 字幕 ID
     * @return 同一申请下已上传字幕数, 该字幕获得的支持数, 该字幕获得的反对数, 同一申请下已上传字幕获得支持数的和
     */
    function getSubtitleAuditInfo(uint256 subtitleId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 applyId = subtitleNFT[subtitleId].applyId;
        uint256 uploaded = totalApplys[applyId].subtitles.length;
        uint256 allSupport;
        for (uint256 i = 0; i < uploaded; i++) {
            uint256 singleSubtitle = totalApplys[applyId].subtitles[i];
            allSupport += subtitleNFT[singleSubtitle].supporters.length;
        }
        return (
            uploaded,
            subtitleNFT[subtitleId].supporters.length,
            subtitleNFT[subtitleId].dissenter.length,
            allSupport,
            subtitleNFT[subtitleId].stateChangeTime
        );
    }

    /**
     * @notice 批量更新用户信誉度和质押信息, 字幕状态发生变化时被调用
     * @param subtitleId 字幕 ID
     * @param flag 1 表示字幕被采用（奖励）, 2 表示字幕被认定为恶意字幕（惩罚）
     */
    function _updateUsers(uint256 subtitleId, uint8 flag) internal {
        int8 newFlag = 1;
        uint8 multiplier = accessStrategy.multiplier();
        // 2 表示字幕被认定为恶意字幕, 对字幕制作者和支持者进行惩罚, 所以标志位为 负
        if (flag == 2) newFlag = -1;
        // 更新字幕制作者信誉度和 Zimu 质押数信息
        {
            (uint256 reputationSpread, uint256 tokenSpread) = accessStrategy
                .spread(
                    users[IST(subtitleToken).ownerOf(subtitleId)].reputation,
                    flag
                );
            _updateUser(
                IST(subtitleToken).ownerOf(subtitleId),
                int256((reputationSpread * multiplier) / 100) * newFlag,
                int256((tokenSpread * multiplier) / 100) * newFlag
            );
        }
        // 更新审核员信息, 支持者和反对者受到的待遇相反
        for (
            uint256 i = 0;
            i < subtitleNFT[subtitleId].supporters.length;
            i++
        ) {
            (uint256 reputationSpread, uint256 tokenSpread) = accessStrategy
                .spread(
                    users[subtitleNFT[subtitleId].supporters[i]].reputation,
                    flag
                );
            _updateUser(
                subtitleNFT[subtitleId].supporters[i],
                int256(reputationSpread) * newFlag,
                int256(tokenSpread) * newFlag
            );
        }
        for (uint256 i = 0; i < subtitleNFT[subtitleId].dissenter.length; i++) {
            (uint256 reputationSpread, uint256 tokenSpread) = accessStrategy
                .spread(
                    users[subtitleNFT[subtitleId].dissenter[i]].reputation,
                    flag
                );
            _updateUser(
                subtitleNFT[subtitleId].dissenter[i],
                int256(reputationSpread) * newFlag * (-1),
                int256(tokenSpread) * newFlag * (-1)
            );
        }
    }

    /**
     * @notice 评价/审核字幕
     * @param subtitleId 字幕 ST ID
     * @param attitude 态度, 0 表示积极/支持, 1 表示消极/反对
     */
    function evaluateSubtitle(uint256 subtitleId, uint8 attitude) external {
        // 无法为已被确认的申请上传字幕, 防止资金和制作力浪费
        require(
            totalApplys[subtitleNFT[subtitleId].applyId].adopted == 0,
            "ER3"
        );
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 ETH 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        _evaluateST(subtitleId, attitude, msg.sender);
        // 基于字幕审核信息和审核策略判断字幕状态改变
        (
            uint256 uploaded,
            uint256 support,
            uint256 against,
            uint256 allSupport,
            uint256 uploadTime
        ) = getSubtitleAuditInfo(subtitleId);
        uint8 flag = auditStrategy.auditResult(
            uploaded,
            support,
            against,
            allSupport,
            uploadTime,
            lockUpTime
        );
        if (flag != 0 && subtitleNFT[subtitleId].state == 0) {
            // 改变 ST 状态, 以及利益相关者信誉度和质押 Zimu 信息
            _changeST(subtitleId, flag);
            _updateUsers(subtitleId, flag);
            // 字幕被采用, 更新相应申请的状态
            if (flag == 1) {
                totalApplys[subtitleNFT[subtitleId].applyId]
                    .adopted = subtitleId;
            }
        }
    }

    /**
     * @notice 预结算（视频和字幕）收益, 此处仅适用于结算策略为一次性结算（0）的申请
     * @param applyId 申请 ID
     */
    function preExtract0(uint256 applyId) external {
        require(totalApplys[applyId].strategy == 0, "ER6");
        address platform = videos[totalApplys[applyId].videoId].platform;
        ISettlementStrategy(settlementStrategy[0].strategy).settlement(
            applyId,
            platform,
            IST(subtitleToken).ownerOf(totalApplys[applyId].adopted),
            0,
            platforms[platform].rateAuditorDivide,
            subtitleNFT[totalApplys[applyId].adopted].supporters
        );
    }

    /**
     * @notice 预结算时, 遍历用到的结算策略
     * @param videoId 视频在 TSCS 内的 ID
     * @param unsettled 未结算稳定币数
     * @return 本次预结算支付字幕制作费用后剩余的稳定币数目
     */
    function _ergodic(uint256 videoId, uint256 unsettled)
        internal
        returns (uint256)
    {
        // 结算策略 strategy 拥有优先度, 根据id（小的优先级高）划分
        for (uint256 i = 0; i < videos[videoId].applys.length; i++) {
            uint256 applyId = videos[videoId].applys[i];
            if (
                totalApplys[applyId].strategy != 0 &&
                totalApplys[applyId].adopted > 0 &&
                unsettled > 0
            ) {
                address platform = videos[videoId].platform;
                uint256 subtitleGet = ISettlementStrategy(
                    settlementStrategy[totalApplys[applyId].strategy].strategy
                ).settlement(
                        applyId,
                        platform,
                        IST(subtitleToken).ownerOf(
                            totalApplys[applyId].adopted
                        ),
                        unsettled,
                        platforms[platform].rateAuditorDivide,
                        subtitleNFT[totalApplys[applyId].adopted].supporters
                    );
                unsettled -= subtitleGet;
            }
        }
        return unsettled;
    }

    /**
     * @notice 预结算（视频和字幕）收益, 仍需优化, 实现真正的模块化
     * @param videoId 视频在 TSCS 内的 ID
     * @return 本次结算稳定币数目
     */
    function preExtractOther(uint256 videoId) external returns (uint256) {
        require(videos[videoId].unsettled > 0, "ER11");
        // 获得相应的代币计价
        uint256 unsettled = (platforms[videos[videoId].platform]
            .rateCountsToProfit *
            videos[videoId].unsettled *
            (10**6)) / RATE_BASE;
        uint256 surplus = _ergodic(videoId, unsettled);
        // 若支付完字幕制作费用后仍有剩余, 则直接将收益以稳定币的形式发送给视频创作者
        if (surplus > 0) {
            IVT(videoToken).mintStableToken(
                platforms[videos[videoId].platform].platformId,
                videos[videoId].creator,
                surplus
            );
        }

        videos[videoId].unsettled = 0;
        emit VideoPreExtract(videoId, unsettled, surplus);
        return unsettled;
    }

    /**
     * @notice 预结算（字幕制作者）收益, "预" 指的是结算后不会直接得到稳定币, 经过锁定期（审核期）后才能提取
     * @param platform 所属平台 Platform 区块链地址
     * @param to 收益接收方
     * @param amount 新增数目
     */
    function preDivide(
        address platform,
        address to,
        uint256 amount
    ) external auth {
        _preDivide(platform, to, amount);
    }

    /**
     * @notice 为批量用户（字幕支持者）预结算收益, "预" 指的是结算后不会直接得到稳定币, 经过锁定期（审核期）后才能提取
     * @param platform 所属平台 Platform 区块链地址
     * @param to 收益接收方
     * @param amount 新增数目
     */
    function preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) external auth {
        _preDivideBatch(platform, to, amount);
    }

    /**
     * @notice 提取经过锁定期的收益
     * @param platform 要提取的平台 Platform 的区块链地址
     * @param day 要提取 天 的集合
     * @return 本次总共提取的（由相应平台背书的）稳定币数
     */
    function withdraw(address platform, uint256[] memory day)
        external
        returns (uint256)
    {
        uint256 all;
        for (uint256 i = 0; i < day.length; i++) {
            if (
                users[msg.sender].lock[platform][day[i]] > 0 &&
                block.timestamp >= day[i] + lockUpTime
            ) {
                all += users[msg.sender].lock[platform][day[i]];
                users[msg.sender].lock[platform][day[i]] = 0;
            }
        }
        if (all > 0) {
            if (fee > 0) {
                uint256 thisFee = (all * fee) / BASE_FEE_RATE;
                all -= thisFee;
                if (platform != address(0)) {
                    IVT(videoToken).mintStableToken(
                        platforms[platform].platformId,
                        address(this),
                        thisFee
                    );
                }
                _addFee(platforms[platform].platformId, thisFee);
            }
            if (platform != address(0)) {
                IVT(videoToken).mintStableToken(
                    platforms[platform].platformId,
                    msg.sender,
                    all
                );
            } else {
                IZimu(zimuToken).transfer(msg.sender, all);
            }
        }
        emit UserWithdraw(msg.sender, platform, day, all);
        return all;
    }

    /**
     * @notice 取消申请（仅支持一次性结算策略, 其它的自动冻结）
     * @param applyId 申请 ID
     */
    function cancel(uint256 applyId) external {
        require(msg.sender == totalApplys[applyId].applicant, "ER5");
        require(
            totalApplys[applyId].adopted == 0 &&
                totalApplys[applyId].subtitles.length == 0 &&
                totalApplys[applyId].deadline <= block.timestamp,
            "ER1-5"
        );
        require(totalApplys[applyId].strategy == 0, "ER6");
        uint256 platformId = platforms[
            videos[totalApplys[applyId].videoId].platform
        ].platformId;
        IVT(videoToken).mintStableToken(
            platformId,
            msg.sender,
            totalApplys[applyId].amount
        );
        emit ApplicationCancel(applyId);
    }

    /**
     * @notice 恢复申请（一次性结算策略的申请无法恢复, 必须重新发起）
     * @param applyId 申请 ID
     * @param amount 新的支付金额/比例
     * @param deadline 新的截至期限
     */
    function recover(
        uint256 applyId,
        uint256 amount,
        uint256 deadline
    ) external {
        require(msg.sender == totalApplys[applyId].applicant, "ER5");
        require(
            totalApplys[applyId].adopted == 0 &&
                totalApplys[applyId].subtitles.length == 0 &&
                totalApplys[applyId].deadline <= block.timestamp,
            "ER1-5"
        );
        require(totalApplys[applyId].strategy != 0, "ER6");
        require(deadline > block.timestamp, "ER1");
        totalApplys[applyId].deadline = deadline;
        totalApplys[applyId].amount = amount;
        emit ApplicationRecover(applyId, amount, deadline);
    }

    /**
     * @notice 更新（增加）申请中的额度和（延长）到期时间
     * @param applyId 申请顺位 ID
     * @param plusAmount 增加支付额度
     * @param plusTime 延长到期时间
     */
    function updateApplication(
        uint256 applyId,
        uint256 plusAmount,
        uint256 plusTime
    ) public {
        require(msg.sender == totalApplys[applyId].applicant, "ER5");
        require(totalApplys[applyId].adopted == 0, "ER6");
        totalApplys[applyId].amount += plusAmount;
        totalApplys[applyId].deadline += plusTime;
        emit ApplicationUpdate(
            applyId,
            totalApplys[applyId].amount,
            totalApplys[applyId].deadline
        );
    }

    /**
     * @notice 该功能服务于后续的仲裁法庭，取消被确认的恶意字幕，相当于重新发出申请
     * @param applyId 被重置的申请 ID
     */
    function resetApplication(uint256 applyId) public auth {
        delete totalApplys[applyId].adopted;
        totalApplys[applyId].deadline = block.timestamp + 365 days;
        emit ApplicationReset(applyId);
    }
}

/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-08 15:13:26
 * @Description: 管理 TSCS 所使用的审核策略、访问策略、检测策略和结算策略
 * @Copyright (c) 2022 by LaplaceMan email: [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./SubtitleManager.sol";
import "./PlatformManager.sol";
import "../interfaces/IAccessStrategy.sol";
import "../interfaces/IAuditStrategy.sol";
import "../interfaces/IDetectionStrategy.sol";
import "../interfaces/ISettlementStrategy.sol";

contract StrategyManager is PlatformManager, SubtitleManager {
    /**
     * @notice 审核策略合约, 根据观众（审核员）评价信息判断字幕状态是否产生变化, 即无变化、被采用或被删除
     */
    IAuditStrategy public auditStrategy;
    /**
     * @notice 访问策略合约, 包括两点: 1.根据信誉度判断用户是否有继续使用 TSCS 服务的资格; 2.根据信誉度和奖惩标志位, 判断用户因为奖励或惩罚后信誉度（与质押ETH数）发生的变化
     */
    IAccessStrategy public accessStrategy;

    /**
     * @notice 检测策略合约, 字幕上传时携带了额外的指纹字段, 目前的设想是其为字幕的 Simhash 值, 该策略是根据已上传字幕的指纹信息判断新上传字幕是否抄袭
     */
    IDetectionStrategy public detectionStrategy;
    /**
     * @notice 结算相关时的除数
     */
    uint16 constant RATE_BASE = 65535;
    /**
     * @notice 锁定期（审核期）
     */
    uint256 public lockUpTime;
    /**
     * @notice 记录每个结算策略的信息
     * @param strategy 结算策略合约地址
     * @param notes 结算策略合约注释说明
     */
    struct SettlementStruct {
        address strategy;
        string notes;
    }

    event SystemSetAudit(address newAudit);
    event SystemSetAccess(address newAccess);
    event SystemSetDetection(address newDetection);
    event SystemSetSettlement(uint8 strategyId, address strategy, string notes);

    event SystemSetZimuToken(address token);
    event SystemSetVideoToken(address token);
    event SystemSetSubtitleToken(address token);
    event SystemSetLockUpTime(uint256 time);
    /**
     * @notice 结算策略 ID 与 SettlementStruct 的映射, 在 TSCS 内用 ID 唯一标识结算策略, 从0开始
     */
    mapping(uint8 => SettlementStruct) public settlementStrategy;

    /**
     * @notice 修改当前 TSCS 内的审核策略, 仅能由管理员调用
     * @param newAudit 新的审核策略合约地址
     */
    function setAuditStrategy(IAuditStrategy newAudit) external onlyOwner {
        require(address(newAudit) != address(0), "ER1");
        auditStrategy = newAudit;
        emit SystemSetAudit(address(newAudit));
    }

    /**
     * @notice 修改当前 TSCS 内的访问策略, 仅能由管理员调用
     * @param newAccess 新的访问策略合约地址
     */
    function setAccessStrategy(IAccessStrategy newAccess) external onlyOwner {
        require(address(newAccess) != address(0), "ER1");
        accessStrategy = newAccess;
        emit SystemSetAccess(address(newAccess));
    }

    /**
     * @notice 修改当前 TSCS 内的检测策略, 仅能由管理员调用
     * @param newDetection 新的检测策略合约地址
     */
    function setDetectionStrategy(IDetectionStrategy newDetection)
        external
        onlyOwner
    {
        require(address(newDetection) != address(0), "ER1");
        detectionStrategy = newDetection;
        emit SystemSetDetection(address(newDetection));
    }

    /**
     * @notice 添加或修改结算策略
     * @param strategyId 新的结算合约ID, 无顺位关系
     * @param strategy  新的结算合约地址
     * @param notes 新的结算策略注释说明
     */
    function setSettlementStrategy(
        uint8 strategyId,
        address strategy,
        string memory notes
    ) external onlyOwner {
        require(strategy != address(0), "ER1");
        settlementStrategy[strategyId].strategy = strategy;
        settlementStrategy[strategyId].notes = notes;
        if (settlementStrategy[strategyId].strategy != address(0)) {
            opeators[settlementStrategy[strategyId].strategy] = false;
        }
        opeators[strategy] = true;
        emit SystemSetSettlement(strategyId, strategy, notes);
    }

    /**
     * @notice 设置/修改平台币合约地址
     * @param token 新的 ERC20 TSCS 平台币合约地址
     */
    function setZimuToken(address token) external onlyOwner {
        require(token != address(0), "ER1");
        zimuToken = token;
        emit SystemSetZimuToken(token);
    }

    /**
     * @notice 设置/修改稳定币合约地址
     * @param token 新的 ERC1155 稳定币合约地址
     */
    function setVideoToken(address token) external onlyOwner {
        require(token != address(0), "ER1");
        videoToken = token;
        emit SystemSetVideoToken(token);
    }

    /**
     * @notice 设置/修改字幕代币 NFT 合约地址
     * @param token 新的 ERC1155 稳定币合约地址
     */
    function setSubtitleToken(address token) external onlyOwner {
        require(token != address(0), "ER1");
        subtitleToken = token;
        emit SystemSetSubtitleToken(token);
    }

    /**
     * @notice 设置/修改锁定期（审核期）
     * @param time 新的锁定时间（审核期）
     */
    function setLockUpTime(uint256 time) external onlyOwner {
        require(time > 0, "ER1");
        lockUpTime = time;
        emit SystemSetLockUpTime(time);
    }
    /**
     * @notice 返回指定结算策略的基本信息
     * @param strategyId 策略 ID
     * @return 结算策略合约地址和注释说明
     */
    // function getSettlementStrategyBaseInfo(uint8 strategyId)
    //     external
    //     view
    //     returns (address, string memory)
    // {
    //     return (
    //         settlementStrategy[strategyId].strategy,
    //         settlementStrategy[strategyId].notes
    //     );
    // }
}

/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-05 20:48:49
 * @Description: 由 Platform 管理自己平台内视频的信息
 * @Copyright (c) 2022 by LaplaceMan [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

contract VideoManager {
    /**
     * @notice TSCS 内由 Platform 为视频创作者开启服务的视频总数
     */
    uint256 public totalVideoNumber;

    /**
     * @notice 每个视频都有相应的 Video 结构, 记录其信息, 每个视频有两个 ID, 一个是在 TSCS 内创建时的顺位 ID, 它在 TSCS 内用来唯一标识视频; 另一个是视频在 Platform 中的 ID, 主要与 symbol 结合来区分不同的视频
     */
    mapping(uint256 => Video) public videos;

    /**
     * @notice TSCS 内顺位 ID 和 相应 Platform 内 ID 的映射, Platform 区块链地址 => 视频在 Platform 内的 ID => 视频在 TSCS 内的 ID
     */
    mapping(address => mapping(uint256 => uint256)) idReal2System;

    /**
     * @notice 用于存储视频信息
     * @param platform 视频所属 Platform 地址
     * @param id 视频在 Platform 内的 ID （链下决定）
     * @param symbol 用于标识视频的符号
     * @param creator 视频创作者区块链地址
     * @param totalViewCouts 视频总播放量
     * @param unsettled 未结算的视频总播放量
     * @param applys 已经发出的申请的 ID
     */
    struct Video {
        address platform;
        uint256 id;
        string symbol;
        address creator;
        uint256 totalViewCouts;
        uint256 unsettled;
        uint256[] applys;
    }

    event VideoCreate(
        address platform,
        uint256 realId,
        uint256 id,
        string symbol,
        address creator
    );

    event VideoCountsUpdate(address platform, uint256[] id, uint256[] counts);

    /**
     * @notice 初始化视频结构, 内部功能
     * @param platform 平台Platform地址
     * @param id 视频在 Platform 内的 ID
     * @param symbol 标识视频的符号
     * @param creator 视频创作者地址
     * @return 视频在 TSCS 内的顺位 ID
     */
    function _createVideo(
        address platform,
        uint256 id,
        string memory symbol,
        address creator
    ) internal returns (uint256) {
        totalVideoNumber++;
        require(idReal2System[platform][id] == 0, "ER0");
        videos[totalVideoNumber].platform = platform;
        videos[totalVideoNumber].id = id;
        videos[totalVideoNumber].symbol = symbol;
        videos[totalVideoNumber].creator = creator;
        idReal2System[platform][id] = totalVideoNumber;
        emit VideoCreate(platform, id, totalVideoNumber, symbol, creator);
        return totalVideoNumber;
    }

    /**
     * @notice 更新视频播放量, 此处为新增量, 仅能由视频所属的 Platform 调用
     * @param id 视频在 TSCS 内的 ID
     * @param vs 新增播放量
     */
    function updateViewCounts(uint256[] memory id, uint256[] memory vs)
        external
    {
        assert(id.length == vs.length);
        for (uint256 i = 0; i < id.length; i++) {
            require(msg.sender == videos[id[i]].platform, "ER5");
            videos[id[i]].totalViewCouts += vs[i];
            videos[id[i]].unsettled += vs[i];
        }
        emit VideoCountsUpdate(videos[id[0]].platform, id, vs);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettlementStrategy {
    function settlement(
        uint256 applyId,
        address platform,
        address maker,
        uint256 unsettled,
        uint16 auditorDivide,
        address[] memory supporters
    ) external returns (uint256);

    function updateDebtOrReward(
        uint256 applyId,
        uint256 number,
        uint256 amount,
        uint16 rateCountsToProfit
    ) external;

    function subtitleSystem() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC1155/IERC1155.sol";

interface IVT is IERC1155 {
    function decimals() external view returns (uint8);

    function tokenUri(uint256 tokenId) external view returns (string memory);

    function createPlatformToken(
        string memory symbol,
        address endorser,
        uint256 platformId
    ) external;

    function mintStableToken(
        uint256 platformId,
        address to,
        uint256 amount
    ) external;

    function burnStableToken(
        uint256 platformId,
        address from,
        uint256 amount
    ) external;

    // function divide(
    //     uint256 platformId,
    //     address from,
    //     address to,
    //     uint256 amount
    // ) external;

    function subtitleSystem() external returns (address);
}

/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-06 20:23:26
 * @Description: 字幕代币化和管理, ERC721 标准实现（沿用了 OpenZeppelin 提供的模板）
 * @Copyright (c) 2022 by LaplaceMan email: [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IST.sol";

contract SubtitleManager {
    /**
     * @notice ST 合约地址
     */
    address public subtitleToken;
    /**
     * @notice 每个字幕 ST 在生成时都会初始化相应的 Subtitle 结构
     * @param state 字幕当前状态, 0 为默认状态, 1 为被确认, 2 为被认定为恶意字幕
     * @param stateChangeTime 字幕状态改变时的时间戳, 用于利益相关者稳定币锁定期判断, 在申请未确认前, 指的是字幕上传时间
     * @param supporters 支持该字幕被采纳的观众（审核员）地址集合
     * @param dissenter 举报该字幕为恶意字幕的观众（审核员）地址集合
     */
    struct Subtitle {
        uint256 applyId;
        uint8 state;
        uint256 stateChangeTime;
        address[] supporters;
        address[] dissenter;
    }

    /**
     * @notice 与传统 ERC721 代币相比 每个 ST（Subtitle Token）都有相应的 Subtitle 结构记录字幕的详细信息, 因为观众评价（审核）机制的引入, ST 是动态的 NFT
     */
    mapping(uint256 => Subtitle) public subtitleNFT;

    /**
     * @notice 限制每个用户只能对每个字幕评价一次, 用户区块链地址 => ST ID => 是否评价（true 为已参与评价）
     */
    mapping(address => mapping(uint256 => bool)) evaluated;
    /**
     * @notice 限制每个用户只能给每个申请下已上传字幕中的一个好评, 用户区块链地址 => apply ID => 支持的 ST ID
     */
    mapping(address => mapping(uint256 => uint256)) adopted;

    event SubtilteStateChange(uint256 subtitleId, uint8 state, uint256 applyId);
    event SubitlteGetEvaluation(
        uint256 subtitleId,
        address evaluator,
        uint8 attitude
    );

    /**
     * @notice 创建 ST, 内部功能
     * @param maker 字幕制作者区块链地址
     * @param applyId 字幕所属申请的 ID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹, 此处暂定为 Simhash
     * @return 字幕代币 ST（Subtitle Token） ID
     */
    function _createST(
        address maker,
        uint256 applyId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) internal returns (uint256) {
        uint256 id = IST(subtitleToken).mintST(
            maker,
            applyId,
            cid,
            languageId,
            fingerprint
        );
        subtitleNFT[id].applyId = applyId;
        subtitleNFT[id].stateChangeTime = block.timestamp;
        return id;
    }

    /**
     * @notice 更改字幕状态, 0 为无变化, 1 为被确认, 2 为被删除（即被认定为恶意字幕）, 内部功能
     * @param id ST（Subtitle Token） ID
     * @param state 新状态
     */
    function _changeST(uint256 id, uint8 state) internal {
        subtitleNFT[id].state = state;
        subtitleNFT[id].stateChangeTime = block.timestamp;
        emit SubtilteStateChange(id, state, subtitleNFT[id].applyId);
    }

    /**
     * @notice 评价字幕, 内部功能
     * @param subtitleId ST（Subtitle Token） ID
     * @param attitude 评价态度, 0 为支持（积极的）, 1 为反对（消极的）
     * @param evaluator 评价者（观众、审核员）区块链地址
     */
    function _evaluateST(
        uint256 subtitleId,
        uint8 attitude,
        address evaluator
    ) internal {
        require(subtitleNFT[subtitleId].state == 0, "ER3");
        require(evaluated[evaluator][subtitleId] == false, "ER4");
        if (attitude == 0) {
            require(
                adopted[evaluator][subtitleNFT[subtitleId].applyId] == 0,
                "ER4"
            );
            subtitleNFT[subtitleId].supporters.push(evaluator);
            adopted[evaluator][subtitleNFT[subtitleId].applyId] = subtitleId;
        } else {
            subtitleNFT[subtitleId].dissenter.push(evaluator);
        }
        evaluated[evaluator][subtitleId] = true;
        emit SubitlteGetEvaluation(subtitleId, evaluator, attitude);
    }
}

/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-05 19:48:53
 * @Description: 管理 Platform, 包括添加和修改相关参数
 * @Copyright (c) 2022 by LaplaceMan email: [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../common/utils/Ownable.sol";
import "./VideoManager.sol";
import "./EntityManager.sol";
import "../interfaces/IVT.sol";

contract PlatformManager is Ownable, EntityManager {
    /**
     * @notice 已加入的 Platform 总数
     */
    uint256 public totalPlatforms;
    /**
     * @notice Platform 地址与相应结构体的映射
     */
    mapping(address => Platform) public platforms;
    /**
     * @notice 记录每个 Platform 的基本信息
     * @param name Platform名称
     * @param symbol Platform符号
     * @param rateCountsToProfit 播放量与稳定币汇率, 最大为 65535（/65535）
     * @param rateAuditorDivide 审核员（字幕支持者）分成比例, 最大为 65535（/65535）
     */
    struct Platform {
        string name;
        string symbol;
        uint256 platformId;
        uint16 rateCountsToProfit;
        uint16 rateAuditorDivide;
    }

    event PlatformJoin(
        address platform,
        uint256 id,
        string name,
        string symbol,
        uint16 rate1,
        uint16 rate2
    );

    event PlatformSetRate(address platform, uint16 rate1, uint16 rate2);

    /**
     * @notice 由 TSCS 管理员操作, 添加新 Platform 生态
     * @param platfrom Platform区块链地址,
     * @param name Platform名称
     * @param symbol Platform符号
     * @param rate1 rateCountsToProfit 值必须大于0
     * @param rate2 rateAuditorDivide 值必须大于0
     * @return 平台Platform唯一标识ID（加入顺位）
     */
    function platfromJoin(
        address platfrom,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2
    ) external onlyOwner returns (uint256) {
        require(platforms[platfrom].rateCountsToProfit == 0, "ER0");
        require(rate1 > 0 && rate2 > 0, "ER1");
        totalPlatforms++;
        platforms[platfrom] = (
            Platform({
                name: name,
                symbol: symbol,
                platformId: totalPlatforms,
                rateCountsToProfit: rate1,
                rateAuditorDivide: rate2
            })
        );
        //因为涉及到播放量结算, 所以每个 Platform 拥有相应的稳定币, 并且为其价值背书
        IVT(videoToken).createPlatformToken(symbol, platfrom, totalPlatforms);
        emit PlatformJoin(platfrom, totalPlatforms, name, symbol, rate1, rate2);
        return totalPlatforms;
    }

    /**
     * @notice 修改自己 Platform 内的比率, 请至少保证一个非 0, 避免无效修改
     * @param rate1 rateCountsToProfit
     * @param rate2 rateAuditorDivide
     * @return 平台Platform当前最新比率信息
     */
    function platformRate(uint16 rate1, uint16 rate2)
        external
        returns (uint16, uint16)
    {
        require(rate1 != 0 || rate2 != 0, "ER1");
        require(platforms[msg.sender].rateCountsToProfit != 0, "ER2");
        if (rate1 != 0) {
            platforms[msg.sender].rateCountsToProfit = rate1;
        }
        if (rate2 != 0) {
            platforms[msg.sender].rateAuditorDivide = rate2;
        }
        emit PlatformSetRate(msg.sender, rate1, rate2);
        return (
            platforms[msg.sender].rateCountsToProfit,
            platforms[msg.sender].rateAuditorDivide
        );
    }

    /**
     * @notice 获得 Platform 基本信息
     * @param platform 欲查询的 Platform 区块链地址
     * @return 平台platform的名称、符号、ID、播放量稳定币比率、审核分成比例
     */
    // function getPlatformBaseInfo(address platform)
    //     external
    //     view
    //     returns (
    //         string memory,
    //         string memory,
    //         uint256,
    //         uint16,
    //         uint16
    //     )
    // {
    //     return (
    //         platforms[platform].name,
    //         platforms[platform].symbol,
    //         platforms[platform].platformId,
    //         platforms[platform].rateCountsToProfit,
    //         platforms[platform].rateAuditorDivide
    //     );
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessStrategy {
    function spread(uint256 reputation, uint8 flag)
        external
        view
        returns (uint256, uint256);

    function access(uint256 reputation, int256 deposit)
        external
        view
        returns (bool);

    function baseRatio() external view returns (uint16);

    function depositThreshold() external view returns (uint16);

    function blacklistThreshold() external view returns (uint8);

    function minDeposit() external view returns (uint256);

    function rewardToken() external view returns (uint256);

    function punishmentToken() external view returns (uint256);

    function multiplier() external view returns (uint8);

    function opeator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuditStrategy {
    function auditResult(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDetectionStrategy {
    function beforeDetection(uint256 origin, uint256[] memory history)
        external
        view
        returns (bool);

    function afterDetection(uint256 newUpload, uint256 oldUpload)
        external
        view
        returns (bool);

    function distanceThreshold() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../common/token/ERC721/IERC721.sol";

interface IST is IERC721 {
    function mintST(
        address maker,
        uint256 applyId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256);

    function getSTFingerprint(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/***
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /***
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /***
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /***
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /***
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /***
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /***
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

    /***
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

    /***
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /***
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

    /***
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

    /***
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /***
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/***
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /***
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-07 18:33:27
 * @Description: 管理 TSCS 内代币合约地址、语言和用户信息
 * @Copyright (c) 2022 by LaplaceMan email: [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IZimu.sol";
import "./VaultManager.sol";

contract EntityManager is VaultManager {
    /**
     * @notice TSCS代币 ERC20合约地址
     */
    address public zimuToken;
    /**
     * @notice Platform稳定币 ERC1155合约地址
     */
    address public videoToken;
    /**
     * @notice TSCS 内用户初始化时的信誉度分数, 精度为 1 即 100.0
     */
    uint16 constant baseReputation = 1000;
    /**
     * @notice 语言名称与对应ID（注册顺序）的映射, 从1开始（ISO 3166-1 alpha-2 code）
     */
    mapping(string => uint16) public languages;
    /**
     * @notice 根据语言 ID 获得语言类型
     */
    string[] languageTypes;
    /**
     * @notice 每个区块链地址与 User 结构的映射
     */
    mapping(address => User) users;
    /**
     * @notice 每个用户在TSCS内的行为记录
     * @param reputation 信誉度分数
     * @param deposit 已质押以太数, 为负表示负债
     * @param lock 平台区块链地址 => 天（Unix）=> 锁定稳定币数量，Default 为 0x0
     */
    struct User {
        uint256 reputation;
        int256 deposit;
        mapping(address => mapping(uint256 => uint256)) lock;
    }

    event RegisterLanguage(string language, uint16 id);
    event UserJoin(address user, uint256 reputation, int256 deposit);
    event UserLockRewardUpdate(
        address user,
        address platform,
        uint256 day,
        int256 reward
    );
    event UserInfoUpdate(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    );

    /**
     * @notice 为了节省存储成本, 使用ID（uint16）代替语言文本（string）, 同时任何人可调用, 保证适用性
     * @param language 欲添加语言类型
     * @return 新添加语言的ID
     */
    function registerLanguage(string[] memory language)
        external
        returns (uint16)
    {
        for (uint256 i; i < language.length; i++) {
            languageTypes.push(language[i]);
            require(languages[language[i]] == 0, "ER0");
            languages[language[i]] = uint16(languageTypes.length - 1);
            emit RegisterLanguage(
                language[i],
                uint16(languageTypes.length - 1)
            );
        }
        return uint16(languageTypes.length - 1);
    }

    /**
     * @notice 根据 ID 获得相应语言的文字类型
     * @param languageId 欲查询语言 Id
     * @return 语言类型
     */
    function getLanguageType(uint16 languageId)
        external
        view
        returns (string memory)
    {
        return languageTypes[languageId];
    }

    /**
     * @notice 为用户初始化User结构
     * @param usr 用户区块链地址
     * @param amount 质押代币数
     */
    function _userInitialization(address usr, int256 amount) internal {
        if (users[usr].reputation == 0) {
            users[usr].reputation = baseReputation;
            users[usr].deposit = amount;
            emit UserJoin(usr, users[usr].reputation, users[usr].deposit);
        }
    }

    /**
     * @notice 主动加入TSCS, 并质押一定数目的 Zimu
     * @param usr 用户区块链地址
     */
    function userJoin(address usr, uint256 despoit) external {
        IZimu(zimuToken).transferFrom(msg.sender, address(this), despoit);
        if (users[usr].reputation == 0) {
            _changeDespoit(int256(despoit));
            _userInitialization(usr, int256(despoit));
        } else {
            //当已加入时, 仍可调用此功能增加质押 Zimu 数
            users[usr].deposit += int256(despoit);
            _changeDespoit(int256(despoit));
            emit UserInfoUpdate(
                usr,
                int256(users[usr].reputation),
                users[usr].deposit
            );
        }
    }

    /**
     * @notice 更新用户在平台内的锁定稳定币数量（每个Platform都有属于自己的稳定币, 各自背书）
     * @param platform 平台地址, 地址0指TSCS本身
     * @param day 天 的Unix格式
     * @param amount 有正负（新增或扣除）的稳定币数量（为锁定状态）
     * @param usr 用户区块链地址
     */
    function _updateLockReward(
        address platform,
        uint256 day,
        int256 amount,
        address usr
    ) internal {
        require(users[usr].reputation != 0, "ER0");
        uint256 current = users[usr].lock[platform][day];
        users[usr].lock[platform][day] = uint256(int256(current) + amount);
        emit UserLockRewardUpdate(usr, platform, day, amount);
    }

    /**
     * @notice 更新用户信誉度分数和质押 Zimu 数
     * @param usr 用户区块链地址
     * @param reputationSpread 有正负（增加或扣除）的信誉度分数
     * @param tokenSpread 有正负的（增加或扣除）Zimu 数量
     */
    function _updateUser(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    ) internal {
        users[usr].reputation = uint256(
            int256(users[usr].reputation) + reputationSpread
        );
        if (tokenSpread < 0) {
            //小于0意味着惩罚操作, 扣除质押Zimu数
            users[usr].deposit = users[usr].deposit + tokenSpread;
            _changePenalty(uint256(tokenSpread));
        } else {
            //此处待定, 临时设计为奖励操作时, 给与特定数目的平台币Zimu Token
            IZimu(zimuToken).mintReward(usr, uint256(tokenSpread));
        }
        //用户的最小信誉度为1, 这样是为了便于判断用户是否已加入系统（User结构已经初始化过）
        if (users[usr].reputation == 0) {
            users[usr].reputation = 1;
        }
        emit UserInfoUpdate(usr, reputationSpread, tokenSpread);
    }

    /**
     * @notice 根据区块链时间戳获得 当天 的Unix格式
     * @return 天 Unix格式
     */
    function _day() internal view returns (uint256) {
        return block.timestamp / 86400;
    }

    /**
     * @notice 预结算（分发）稳定币, 因为是先记录, 当达到特定天数后才能正式提取, 所以是 "预"
     * @param platform Platform地址
     * @param to 用户区块链地址
     * @param amount 新增稳定币数量（为锁定状态）
     */
    function _preDivide(
        address platform,
        address to,
        uint256 amount
    ) internal {
        _updateLockReward(platform, _day(), int256(amount), to);
    }

    /**
     * @notice 同_preDivide(), 只不过同时改变多个用户的状态
     */
    function _preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) internal {
        for (uint256 i = 0; i < to.length; i++) {
            _updateLockReward(platform, _day(), int256(amount), to[i]);
        }
    }

    /**
     * @notice 获得特定用户当前信誉度分数和质押 Zimu 数量
     * @param usr 欲查询用户的区块链地址
     * @return 信誉度分数, 质押 Zimu 数
     */
    function getUserBaseInfo(address usr)
        public
        view
        returns (uint256, int256)
    {
        return (users[usr].reputation, users[usr].deposit);
    }

    /**
     * @notice 获取用户在指定平台指定日子锁定的稳定币数量
     * @param usr 欲查询用户的区块链地址
     * @param platform 特定Platform地址
     * @param day 指定天
     * @return 锁定稳定币数量
     */
    function getUserLockReward(
        address usr,
        address platform,
        uint256 day
    ) public view returns (uint256) {
        return users[usr].lock[platform][day];
    }

    /**
     * @notice 提取质押的 Zimu 代币
     * @param amount 欲提取 Zimu 代币数
     * @return 实际提取质押 Zimu 代币数
     */
    function withdrawDeposit(uint256 amount) public returns (uint256) {
        require(users[msg.sender].deposit > 0, "ER1");
        if (amount > uint256(users[msg.sender].deposit)) {
            amount = uint256(users[msg.sender].deposit);
        }
        users[msg.sender].deposit -= int256(amount);
        IZimu(zimuToken).transferFrom(address(this), msg.sender, amount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    mapping(address => bool) opeators;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OpeatorsStateChange(address[] indexed opeators, bool indexed state);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier auth() {
        require(opeators[msg.sender] == true);
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function setOperators(address[] memory operators, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < operators.length; i++) {
            opeators[operators[i]] = state;
        }
        emit OpeatorsStateChange(operators, state);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/***
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /***
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /***
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /***
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /***
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /***
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /***
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /***
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /***
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /***
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /***
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC20/IERC20.sol";

interface IZimu is IERC20 {
    function mintReward(address to, uint256 amount) external;
}

/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-22 12:52:13
 * @Description: 管理 TSCS 内的资产
 * @Copyright (c) 2022 by LaplaceMan [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

contract VaultManager {
    /**
     * @notice 用户加入生态时在 TSCS 内质押的 Zimu 数
     */
    uint256 public Despoit;
    /**
     * @notice TSCS内产生的罚款总数（以Zimu计价）
     */
    uint256 public penalty;

    /**
     * @notice 手续费用比率
     */
    uint256 fee;

    /**
     * @notice 计算费用时的除数
     */
    uint256 constant BASE_FEE_RATE = 10000;

    /**
     * @notice 来自于不同平台的手续费收入
     */
    mapping(uint256 => uint256) feeIncome;

    /**
     * @notice 更改 TSCS 内质押的 Zimu 数量
     * @param amount 变化数量
     */
    function _changeDespoit(int256 amount) internal {
        if (amount != 0) {
            Despoit = uint256(int256(Despoit) + amount);
        }
    }

    /**
     * @notice TSCS 内罚没 Zimu 资产
     * @param amount 新增罚没 Zimu 数量
     */
    function _changePenalty(uint256 amount) internal {
        penalty += amount;
        _changeDespoit(int256(amount) * -1);
    }

    /**
     * @notice 新增手续费，内部功能
     * @param platformId 新增手续费来源平台
     * @param amount 新增手续费数量
     */
    function _addFee(uint256 platformId, uint256 amount) internal {
        feeIncome[platformId] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/***
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /***
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /***
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /***
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /***
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /***
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /***
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /***
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

    /***
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