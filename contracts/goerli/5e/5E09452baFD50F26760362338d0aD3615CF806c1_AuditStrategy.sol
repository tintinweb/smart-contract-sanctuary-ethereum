/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-08 14:44:30
 * @Description: TSCS 内默认的字幕审核策略, 设计逻辑可参阅论文
 * @Copyright (c) 2022 by LaplaceMan [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IAuditStrategy.sol";

contract AuditStrategy is IAuditStrategy {
    /**
     * @notice 根据观众（审核员）对字幕的评价数据判断字幕是否被采纳, 内部功能
     * @param uploaded 已上传的字幕数目
     * @param support 单个字幕获得的支持数
     * @param against 单个字幕获得的反对（举报）数
     * @param allSupport 相应申请下所有字幕获得支持数的和
     * @return 返回 0 表示字幕状态不变化, 返回 1 表示字幕被采纳（申请被确认）
     */
    function _adopt(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport
    ) internal pure returns (uint8) {
        uint8 flag;
        if (uploaded > 1) {
            if (
                support > 10 && ((support - against) > (allSupport / uploaded))
            ) {
                flag = 1;
            }
        } else {
            // 在测试时将其修改为 1, 默认为 10
            if (
                support > 1 &&
                (((support - against) * 10) / (support + against) >= 6)
            ) {
                flag = 1;
            }
        }
        return flag;
    }

    /**
     * @notice 根据观众（审核员）对字幕的评价数据判断字幕是否被认定为恶意字幕, 内部功能
     * @param support 单个字幕获得的支持数
     * @param against 单个字幕获得的反对（举报）数
     * @return 返回 0 表示字幕状态不变化, 返回 2 表示字幕被认定为恶意字幕
     */
    function _delete(uint256 support, uint256 against)
        internal
        pure
        returns (uint8)
    {
        uint8 flag;
        if (support > 1) {
            if (against >= 10 * support) {
                flag = 2;
            }
        } else {
            if (against >= 2) {
                flag = 2;
            }
        }
        return flag;
    }

    /**
     * @notice 根据观众（审核员）对字幕的评价数据判断字幕状态是否发生变化
     * @param uploaded 相应申请下已经上传的字幕数量
     * @param support 单个字幕获得的支持数
     * @param against 单个字幕获得的反对（举报）数
     * @param allSupport 相应申请下所有字幕获得支持数的和
     * @param uploadTime 字幕上传时间
     * @param lockUpTime TSCS 内设置的锁定期/审核期
     * @return 返回 0 表示状态不变化, 返回 1 表示字幕被采纳（申请被采纳）, 返回 2 表示字幕被认定为恶意字幕
     */
    function auditResult(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view override returns (uint8) {
        uint8 flag1;
        if (block.timestamp >= uploadTime + lockUpTime) {
            flag1 = _adopt(uploaded, support, against, allSupport);
        }
        uint8 flag2 = _delete(support, against);
        if (flag1 != 0) {
            return flag1;
        } else if (flag2 != 0) {
            return flag2;
        } else {
            return 0;
        }
    }
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