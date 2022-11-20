/**
 * @Author: LaplaceMan [email protected]
 * @Date: 2022-09-08 19:46:31
 * @Description: 字幕上传前基于 Simhash 指纹值检测相似度, 目的是保护字幕版权
 * @Copyright (c) 2022 by LaplaceMan [email protected], All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IDetectionStrategy.sol";

contract DetectionStrategy is IDetectionStrategy {
    /**
     * @notice 汉明距离阈值, 大于该值表示不相似, 反之表示相似度过高
     */
    uint8 public distanceThreshold;
    /**
     * @notice 拥有修改 distanceThreshold 的权限, 一般为 DAO 合约地址
     */
    address public opeator;

    modifier onlyOwner() {
        require(msg.sender == opeator, "ER5");
        _;
    }
    event SystemSetDistanceThreshold(uint8 newDistanceThreshold);
    event SystemChangeOpeator(address newOpeator);

    constructor(address dao, uint8 threshold) {
        opeator = dao;
        distanceThreshold = threshold;
    }

    /**
     * @notice 计算两个 Simhash 的汉明度距离
     * @param a 字幕文本 1
     * @param b 字幕文本 2
     * @return 汉明度距离
     */
    function _hammingDistance(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        // Get A XOR B...
        uint256 c = a ^ b;
        uint256 count = 0;
        while (c != 0) {
            // This works because if a number is power of 2,
            // then it has only one 1 in its binary representation.
            c = c & (c - 1);
            count++;
        }
        return count;
    }

    /**
     * @notice 判断新上传字幕是否与已上传字幕相似度过高（避免抄袭现象）
     * @param origin 新上传字幕文本 Simhash
     * @param history 相应申请下已上传所有字幕的 Simhash
     * @return 返回 false 表示新上传字幕与已上传字幕相似度过高, 禁止上传, 反之可以上传
     */
    function beforeDetection(uint256 origin, uint256[] memory history)
        external
        view
        override
        returns (bool)
    {
        for (uint256 i = 0; i < history.length; i++) {
            uint256 distance = _hammingDistance(origin, history[i]);
            if (distance <= distanceThreshold) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice 服务字幕版本管理, 防止字幕改动过大（潜在的风险是先随便上传一个版本的字幕, 后面再慢慢修改）
     * @param newUpload 新版本字幕的 Simhash
     * @param oldUpload 旧版本字幕的 Simhash
     * @return 返回 true 表示通过检测, 可以上传, 反之禁止上传
     */
    function afterDetection(uint256 newUpload, uint256 oldUpload)
        external
        view
        override
        returns (bool)
    {
        uint256 distance = _hammingDistance(newUpload, oldUpload);
        if (distance <= distanceThreshold) {
            return true;
        }
        return false;
    }

    /**
     * @notice 由操作员修改策略中的阈值参数
     * @param newDistanceThreshold 新的汉明距离阈值
     */
    function setDistanceThreshold(uint8 newDistanceThreshold)
        external
        onlyOwner
    {
        distanceThreshold = newDistanceThreshold;
        emit SystemSetDistanceThreshold(newDistanceThreshold);
    }

    function changeOpeator(address newOpeator) external onlyOwner {
        opeator = newOpeator;
        emit SystemChangeOpeator(newOpeator);
    }
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