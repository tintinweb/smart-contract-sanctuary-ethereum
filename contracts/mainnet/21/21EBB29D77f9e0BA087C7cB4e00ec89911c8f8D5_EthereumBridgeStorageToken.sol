/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
// File: contracts/library/BridgeScanRange.sol

pragma solidity ^0.8.7;

struct AbnormalRangeInfo {
    bool startInit;
    bool endInit;
    uint256 startIndex;
    uint256 endIndex;
    bool continuousStart;
    bool continuousEnd;
    bool middle;
}

library BridgeScanRange {
    function getBlockScanRange(
        uint64[] memory r,
        uint64 v1,
        uint64 v2
    ) internal pure returns (uint64[] memory _r) {
        if (r.length == 0) {
            _r = new uint64[](2);
            (, _r) = _insertRange(0, _r, v1, v2);
        } else {
            uint256 total;
            uint64[2][] memory ranges = _extractBlockScanRanges(r);
            bool normality = _determineRangeNormality(ranges, v1, v2);
            if (normality) {
                total = _getNewRangeCount(r.length, ranges, v1, v2);
                if (total > 0) {
                    _r = new uint64[](total);
                    _r = _createNewRanges(ranges, v1, v2, _r);
                }
            } else {
                AbnormalRangeInfo memory info;
                (total, info) = _getAbnormalNewRangeCount(
                    r.length,
                    ranges,
                    v1,
                    v2
                );
                if (total > 0) {
                    _r = new uint64[](total);
                    _r = _createAbnormalNewRanges(ranges, v1, v2, _r, info);
                }
            }

            if (total == 0) {
                _r = new uint64[](r.length);
                _r = r;
            }
        }
    }

    // extract [x1, x2, x3, x4] into [[x1, x2], [x3, x4]]
    function _extractBlockScanRanges(uint64[] memory r)
        private
        pure
        returns (uint64[2][] memory arr)
    {
        uint256 maxRange = r.length / 2;
        arr = new uint64[2][](maxRange);

        uint64 k = 0;
        for (uint64 i = 0; i < maxRange; i++) {
            (bool e1, uint64 v1) = _getElement(i + k, r);
            (bool e2, uint64 v2) = _getElement(i + k + 1, r);

            uint64[2] memory tmp;
            if (e1 && e2) tmp = [v1, v2];
            arr[k] = tmp;
            k++;
        }
    }

    function _getElement(uint64 i, uint64[] memory arr)
        private
        pure
        returns (bool exist, uint64 ele)
    {
        if (exist = (i >= 0 && i < arr.length)) {
            ele = arr[i];
        }
    }

    function _getElement(uint64 i, uint64[2][] memory arr)
        private
        pure
        returns (bool exist, uint64[2] memory ranges)
    {
        if (exist = (i >= 0 && i < arr.length)) {
            ranges = arr[i];
        }
    }

    // determine range overlapping
    function _determineRangeNormality(
        uint64[2][] memory ranges,
        uint64 v1,
        uint64 v2
    ) private pure returns (bool normality) {
        bool ended;
        for (uint64 i = 0; i < ranges.length; i++) {
            (bool e1, uint64[2] memory ele1) = _getElement(i, ranges);
            (bool e2, uint64[2] memory ele2) = _getElement(i + 1, ranges);

            if (e1 && e2)
                (ended, normality) = _checkRangeNormality(
                    i,
                    v1,
                    v2,
                    ele1,
                    ele2
                );
            else if (e1)
                (ended, normality) = _checkRangeNormality(i, v1, v2, ele1);

            if (ended) return normality;
        }
    }

    function _checkRangeNormality(
        uint64 index,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1
    ) private pure returns (bool, bool) {
        if ((index == 0 && v2 <= ele1[0]) || v1 >= ele1[1]) {
            return (true, true);
        }
        return (true, false);
    }

    function _checkRangeNormality(
        uint64 index,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1,
        uint64[2] memory ele2
    ) private pure returns (bool, bool) {
        if ((index == 0 && v2 <= ele1[0]) || (v1 >= ele1[1] && v2 <= ele2[0])) {
            return (true, true);
        }
        return (false, false);
    }

    /** Range Normal */

    // Get total number of elements
    function _getNewRangeCount(
        uint256 curCount,
        uint64[2][] memory ranges,
        uint64 v1,
        uint64 v2
    ) private pure returns (uint256 total) {
        for (uint64 i = 0; i < ranges.length; i++) {
            (bool e1, uint64[2] memory ele1) = _getElement(i, ranges);
            (bool e2, uint64[2] memory ele2) = _getElement(i + 1, ranges);

            if (e1 && e2) total = _calculateRange(curCount, v1, v2, ele1, ele2);
            else if (e1) total = _calculateRange(curCount, v1, v2, ele1);

            if (total > 0) return total;
        }
        return total;
    }

    function _calculateRange(
        uint256 curCount,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1
    ) private pure returns (uint256 total) {
        if (v2 <= ele1[0]) {
            if (_checkEnd(ele1[0], v2)) {
                total = curCount;
            } else {
                total = curCount + 2;
            }
        } else if (v1 >= ele1[1]) {
            if (_checkStart(ele1[1], v1)) {
                total = curCount;
            } else {
                total = curCount + 2;
            }
        }
    }

    function _calculateRange(
        uint256 curCount,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1,
        uint64[2] memory ele2
    ) private pure returns (uint256 total) {
        if (v2 <= ele1[0]) {
            if (_checkEnd(ele1[0], v2)) {
                total = curCount;
            } else {
                total = curCount + 2;
            }
        } else if (v1 >= ele1[1] && v2 <= ele2[0]) {
            if (_checkStart(ele1[1], v1) && _checkEnd(ele2[0], v2)) {
                total = curCount - 2;
            } else if (_checkStart(ele1[1], v1) || _checkEnd(ele2[0], v2)) {
                total = curCount;
            } else {
                total = curCount + 2;
            }
        }
    }

    // Create new blockScanRanges array
    function _createNewRanges(
        uint64[2][] memory ranges,
        uint64 v1,
        uint64 v2,
        uint64[] memory r
    ) private pure returns (uint64[] memory) {
        bool done = false;
        bool skip = false;
        uint256 total = 0;
        for (uint64 i = 0; i < ranges.length; i++) {
            (bool e1, uint64[2] memory ele1) = _getElement(i, ranges);
            (bool e2, uint64[2] memory ele2) = _getElement(i + 1, ranges);

            if (done) {
                if (!skip && e1)
                    (total, r) = _insertRange(total, r, ele1[0], ele1[1]);
                else skip = false;
            } else {
                if (e1 && e2) {
                    (done, total, r) = _insertRange(
                        total,
                        r,
                        v1,
                        v2,
                        ele1,
                        ele2
                    );
                    if (done) skip = true;
                } else if (e1)
                    (done, total, r) = _insertRange(total, r, v1, v2, ele1);
            }
        }
        return r;
    }

    function _insertRange(
        uint256 i,
        uint64[] memory r,
        uint64 v1,
        uint64 v2
    ) private pure returns (uint256, uint64[] memory) {
        r[i] = v1;
        r[i + 1] = v2;
        i += 2;
        return (i, r);
    }

    function _insertRange(
        uint256 i,
        uint64[] memory r,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1
    )
        private
        pure
        returns (
            bool done,
            uint256,
            uint64[] memory
        )
    {
        if (v2 <= ele1[0]) {
            if (_checkEnd(ele1[0], v2)) {
                (i, r) = _insertRange(i, r, v1, ele1[1]);
                done = true;
            } else {
                (i, r) = _insertRange(i, r, v1, v2);
                (i, r) = _insertRange(i, r, ele1[0], ele1[1]);
                done = true;
            }
        } else if (v1 >= ele1[1]) {
            if (_checkStart(ele1[1], v1)) {
                (i, r) = _insertRange(i, r, ele1[0], v2);
                done = true;
            } else {
                (i, r) = _insertRange(i, r, ele1[0], ele1[1]);
                (i, r) = _insertRange(i, r, v1, v2);
                done = true;
            }
        }
        return (done, i, r);
    }

    function _insertRange(
        uint256 i,
        uint64[] memory r,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1,
        uint64[2] memory ele2
    )
        private
        pure
        returns (
            bool done,
            uint256,
            uint64[] memory
        )
    {
        if (v2 <= ele1[0]) {
            if (_checkEnd(ele1[0], v2)) {
                (i, r) = _insertRange(i, r, v1, ele1[1]);
                (i, r) = _insertRange(i, r, ele2[0], ele2[1]);
                done = true;
            } else {
                (i, r) = _insertRange(i, r, v1, v2);
                (i, r) = _insertRange(i, r, ele1[0], ele1[1]);
                (i, r) = _insertRange(i, r, ele2[0], ele2[1]);
                done = true;
            }
        } else if (v1 >= ele1[1] && v2 <= ele2[0]) {
            if (_checkStart(ele1[1], v1) && _checkEnd(ele2[0], v2)) {
                (i, r) = _insertRange(i, r, ele1[0], ele2[1]);
                done = true;
            } else if (_checkStart(ele1[1], v1)) {
                (i, r) = _insertRange(i, r, ele1[0], v2);
                (i, r) = _insertRange(i, r, ele2[0], ele2[1]);
                done = true;
            } else if (_checkEnd(ele2[0], v2)) {
                (i, r) = _insertRange(i, r, ele1[0], ele1[1]);
                (i, r) = _insertRange(i, r, v1, ele2[1]);
                done = true;
            } else {
                (i, r) = _insertRange(i, r, ele1[0], ele1[1]);
                (i, r) = _insertRange(i, r, v1, v2);
                (i, r) = _insertRange(i, r, ele2[0], ele2[1]);
                done = true;
            }
        }

        if (!done) (i, r) = _insertRange(i, r, ele1[0], ele1[1]);

        return (done, i, r);
    }

    /** END Range Normal */

    /** Range Abnormal (overlapping) */
    function _getAbnormalNewRangeCount(
        uint256 curCount,
        uint64[2][] memory ranges,
        uint64 v1,
        uint64 v2
    ) private pure returns (uint256 total, AbnormalRangeInfo memory info) {
        for (uint64 i = 0; i < ranges.length; i++) {
            (bool e1, uint64[2] memory ele1) = _getElement(i, ranges);
            (bool e2, uint64[2] memory ele2) = _getElement(i + 1, ranges);

            if (e1 && e2) {
                if (info.startInit)
                    info = _calculateAbnormalRangeEnd(i, v2, ele1, ele2, info);
                else
                    info = _calculateAbnormalRange(i, v1, v2, ele1, ele2, info);
            } else if (e1) {
                if (info.startInit)
                    info = _calculateAbnormalRange(i, v2, ele1, info);
                else info = _calculateAbnormalRange(i, v1, v2, ele1, info);
            }

            if (info.endInit)
                total = _calculateAbnormalRangeTotal(curCount, info);

            if (total > 0) return (total, info);
        }
    }

    function _calculateAbnormalRange(
        uint256 i,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1,
        AbnormalRangeInfo memory info
    ) private pure returns (AbnormalRangeInfo memory) {
        if (v1 <= ele1[0] && v2 >= ele1[1]) {
            info.startInit = info.endInit = true;
            info.startIndex = info.endIndex = i;
        }
        return info;
    }

    function _calculateAbnormalRange(
        uint256 i,
        uint64 v2,
        uint64[2] memory ele1,
        AbnormalRangeInfo memory info
    ) private pure returns (AbnormalRangeInfo memory) {
        if (v2 >= ele1[1]) {
            info.endInit = true;
            info.endIndex = i;
        }
        return info;
    }

    function _calculateAbnormalRange(
        uint256 i,
        uint64 v1,
        uint64 v2,
        uint64[2] memory ele1,
        uint64[2] memory ele2,
        AbnormalRangeInfo memory info
    ) private pure returns (AbnormalRangeInfo memory) {
        if (v1 <= ele1[0] && v2 >= ele1[1] && v2 <= ele2[0]) {
            info.startInit = info.endInit = true;
            info.startIndex = info.endIndex = i;
            if (_checkEnd(ele2[0], v2)) info.continuousEnd = true;
        } else if (v1 <= ele1[0]) {
            info.startInit = true;
            info.startIndex = i;
        } else if (v1 >= ele1[1] && v1 <= ele2[0]) {
            info.startInit = true;
            info.startIndex = i;
            info.middle = true;
            if (_checkStart(ele1[1], v1)) info.continuousStart = true;
        }
        return info;
    }

    function _calculateAbnormalRangeEnd(
        uint256 i,
        uint64 v2,
        uint64[2] memory ele1,
        uint64[2] memory ele2,
        AbnormalRangeInfo memory info
    ) private pure returns (AbnormalRangeInfo memory) {
        if (v2 >= ele1[1] && v2 <= ele2[0]) {
            info.endInit = true;
            info.endIndex = i;
            if (_checkEnd(ele2[0], v2)) info.continuousEnd = true;
        }
        return info;
    }

    function _calculateAbnormalRangeTotal(
        uint256 curCount,
        AbnormalRangeInfo memory info
    ) private pure returns (uint256 total) {
        if (info.startIndex == info.endIndex) {
            if (info.continuousEnd) total = curCount - 2;
            else total = curCount;
        } else if (info.endIndex > info.startIndex) {
            uint256 diff = info.endIndex - info.startIndex;
            total = curCount - (2 * diff);
            if (
                (info.continuousStart && info.continuousEnd && info.middle) ||
                (info.continuousEnd && !info.middle)
            ) total -= 2;
            else if (
                !info.continuousStart && !info.continuousEnd && info.middle
            ) total += 2;
        }
    }

    function _createAbnormalNewRanges(
        uint64[2][] memory ranges,
        uint64 v1,
        uint64 v2,
        uint64[] memory r,
        AbnormalRangeInfo memory info
    ) private pure returns (uint64[] memory) {
        bool skip = false;
        uint256 total = 0;
        for (uint64 i = 0; i < ranges.length; i++) {
            (, uint64[2] memory ele1) = _getElement(i, ranges);
            (bool e2, uint64[2] memory ele2) = _getElement(i + 1, ranges);

            if (info.startIndex == i) {
                if (info.middle) {
                    if (info.continuousStart) {
                        (total, r) = _insertAbnormalRange(total, r, ele1[0]);
                        skip = true;
                    } else {
                        (total, r) = _insertAbnormalRange(
                            total,
                            r,
                            ele1[0],
                            ele1[1]
                        );
                        (total, r) = _insertAbnormalRange(total, r, v1);
                        skip = true;
                    }
                } else {
                    (total, r) = _insertAbnormalRange(total, r, v1);
                }
            }

            if (info.endIndex == i) {
                if (info.continuousEnd) {
                    (total, r) = _insertAbnormalRange(total, r, ele2[1]);
                    skip = true;
                } else {
                    (total, r) = _insertAbnormalRange(total, r, v2);
                    if (e2) {
                        (total, r) = _insertAbnormalRange(
                            total,
                            r,
                            ele2[0],
                            ele2[1]
                        );
                        skip = true;
                    }
                }
            }

            if (!(i >= info.startIndex && i <= info.endIndex)) {
                if (!skip)
                    (total, r) = _insertAbnormalRange(
                        total,
                        r,
                        ele1[0],
                        ele1[1]
                    );
                else skip = false;
            }
        }
        return r;
    }

    function _insertAbnormalRange(
        uint256 i,
        uint64[] memory r,
        uint64 v
    ) private pure returns (uint256, uint64[] memory) {
        r[i] = v;
        i += 1;
        return (i, r);
    }

    function _insertAbnormalRange(
        uint256 i,
        uint64[] memory r,
        uint64 v1,
        uint64 v2
    ) private pure returns (uint256, uint64[] memory) {
        r[i] = v1;
        r[i + 1] = v2;
        i += 2;
        return (i, r);
    }

    /** END Range Abnormal (overlapping) */

    // Check continuous
    function _checkStart(uint64 ele, uint64 v) private pure returns (bool) {
        return ((uint64(ele + 1) == v) || ele == v);
    }

    function _checkEnd(uint64 ele, uint64 v) private pure returns (bool) {
        return ((uint64(ele - 1) == v) || ele == v);
    }
}

// File: contracts/library/BridgeSecurity.sol

pragma solidity ^0.8.7;

library BridgeSecurity {
    function generateSignerMsgHash(uint64 epoch, address[] memory signers)
        internal
        pure
        returns (bytes32 msgHash)
    {
        msgHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                address(0),
                epoch,
                _encodeAddressArr(signers)
            )
        );
    }

    function generatePackMsgHash(
        address thisAddr,
        uint64 epoch,
        uint8 networkId,
        uint64[2] memory blockScanRange,
        uint256[] memory txHashes,
        address[] memory tokens,
        address[] memory recipients,
        uint256[] memory amounts
    ) internal pure returns (bytes32 msgHash) {
        msgHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0),
                thisAddr,
                epoch,
                _encodeFixed2Uint64Arr(blockScanRange),
                networkId,
                _encodeUint256Arr(txHashes),
                _encodeAddressArr(tokens),
                _encodeAddressArr(recipients),
                _encodeUint256Arr(amounts)
            )
        );
    }

    function signersVerification(
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s,
        address[] memory signers,
        mapping(address => bool) storage mapSigners
    ) internal view returns (bool) {
        uint64 totalSigners = 0;
        for (uint64 i = 0; i < signers.length; i++) {
            if (mapSigners[signers[i]]) totalSigners++;
        }
        return (_getVerifiedSigners(msgHash, v, r, s, mapSigners) ==
            (totalSigners / 2) + 1);
    }

    function _getVerifiedSigners(
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s,
        mapping(address => bool) storage mapSigners
    ) private view returns (uint8 verifiedSigners) {
        address lastAddr = address(0);
        verifiedSigners = 0;
        for (uint64 i = 0; i < v.length; i++) {
            address recovered = ecrecover(msgHash, v[i], r[i], s[i]);
            if (recovered > lastAddr && mapSigners[recovered])
                verifiedSigners++;
            lastAddr = recovered;
        }
    }

    function _encodeAddressArr(address[] memory arr)
        private
        pure
        returns (bytes memory data)
    {
        for (uint64 i = 0; i < arr.length; i++) {
            data = abi.encodePacked(data, arr[i]);
        }
    }

    function _encodeUint256Arr(uint256[] memory arr)
        private
        pure
        returns (bytes memory data)
    {
        for (uint64 i = 0; i < arr.length; i++) {
            data = abi.encodePacked(data, arr[i]);
        }
    }

    function _encodeFixed2Uint64Arr(uint64[2] memory arr)
        private
        pure
        returns (bytes memory data)
    {
        for (uint64 i = 0; i < arr.length; i++) {
            data = abi.encodePacked(data, arr[i]);
        }
    }
}

// File: contracts/BaseToken/interface/ITokenFactory.sol

pragma solidity ^0.8.7;

interface ITokenFactory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event BridgeChanged(address indexed oldBridge, address indexed newBridge);

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    event TokenCreated(
        string name,
        string indexed symbol,
        uint256 amount,
        uint256 cap,
        address indexed token
    );

    event TokenRemoved(address indexed token);

    function owner() external view returns (address);

    function tokens() external view returns (address[] memory);

    function tokenExist(address token) external view returns (bool);

    function bridge() external view returns (address);

    function admin() external view returns (address);

    function setBridge(address bridge) external;

    function setAdmin(address admin) external;

    function createToken(
        string memory name,
        string memory symbol,
        uint256 amount,
        uint256 cap
    ) external returns (address token);

    function removeToken(address token) external;
}

// File: contracts/BaseCrossBridge/interface/ICrossBridgeStorageToken.sol

pragma solidity ^0.8.7;

interface ICrossBridgeStorageToken {
    event TokenConnected(
        address indexed token,
        uint256 amount,
        uint256 percent,
        address indexed crossToken,
        string symbol
    );

    event TokenRequirementChanged(
        uint64 blockIndex,
        address indexed token,
        uint256[2] amount,
        uint256[2] percent
    );

    function owner() external view returns (address);

    function admin() external view returns (address);

    function bridge() external view returns (address);

    function mapToken(address token) external view returns (bool);

    function mapOcToken(address token) external view returns (address);

    function mapCoToken(address token) external view returns (address);

    function blockScanRange() external view returns (uint64[] memory);

    function crossToken(address token)
        external
        view
        returns (string memory, string memory);

    function tokens(
        ITokenFactory tf,
        uint64 futureBlock,
        uint64 searchBlockIndex
    )
        external
        view
        returns (
            uint8[] memory,
            address[][] memory,
            address[][] memory,
            uint256[][] memory,
            uint256[][] memory,
            uint8[][] memory
        );

    function tokens(
        ITokenFactory tf,
        uint8 id,
        uint64 futureBlock,
        uint64 searchBlockIndex
    )
        external
        view
        returns (
            address[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint8[] memory
        );

    function charges()
        external
        view
        returns (address[] memory tokens, uint256[] memory charges);

    function txHash(uint256 txHash) external view returns (bool);

    function transactionInfo(
        uint64 futureBlock,
        address token,
        uint256 amount
    ) external view returns (uint256 fee, uint256 amountAfterCharge);

    function setCallers(address admin, address bridge) external;

    function resetConnection(address token, address crossToken) external;

    function setConnection(
        address token,
        uint256 amount,
        uint256 percent,
        address crossToken,
        string memory name,
        string memory symbol
    ) external;

    function setInfo(
        address token,
        uint256 amount,
        uint256 percent
    ) external;

    function setAmount(address token, uint256 amount) external;

    function setPercent(address token, uint256 percent) external;

    function setTxHash(uint256 txHash) external;

    function setCollectedCharges(address token, uint256 amount) external;

    function setScanRange(uint64[2] memory scanRange) external;
}

// File: contracts/BaseBridge/interface/IBridge.sol

pragma solidity ^0.8.7;

struct TokenReq {
    bool exist;
    uint256 minAmount;
    uint256 chargePercent;
}

struct CrossTokenInfo {
    string name;
    string symbol;
}

struct NetworkInfo {
    uint8 id;
    string name;
}

struct TokenData {
    address[] tokens;
    address[] crossTokens;
    uint256[] minAmounts;
    uint256[] chargePercents;
    uint8[] tokenTypes;
}

struct TokensInfo {
    uint8[] ids;
    address[][] tokens;
    address[][] crossTokens;
    uint256[][] minAmounts;
    uint256[][] chargePercents;
    uint8[][] tokenTypes;
}

struct TokensChargesInfo {
    uint8[] ids;
    address[][] tokens;
    uint256[][] charges;
}

interface IBridge {
    event TokenConnected(
        address indexed token,
        uint256 amount,
        uint256 percent,
        address indexed crossToken,
        string symbol
    );

    event TokenReqChanged(
        uint64 blockIndex,
        address indexed token,
        uint256[2] amount,
        uint256[2] percent
    );

    function initialize(
        address factory,
        address admin,
        address tokenFactory,
        address wMech,
        uint8 id,
        string memory name
    ) external;

    function factory() external view returns (address);

    function admin() external view returns (address);

    function network() external view returns (uint8, string memory);

    function activeTokenCount() external view returns (uint8);

    function crossToken(address crossToken)
        external
        view
        returns (string memory, string memory);

    function tokens(uint64 futureBlock, uint64 searchBlockIndex)
        external
        view
        returns (TokenData memory data);

    function blockScanRange() external view returns (uint64[] memory);

    function charges()
        external
        view
        returns (address[] memory tokens, uint256[] memory charges);

    function txHash(uint256 txHash_) external view returns (bool);

    function setConnection(
        address token,
        uint256 amount,
        uint256 percent,
        address crossToken,
        string memory name,
        string memory symbol
    ) external;

    function setInfo(
        address token,
        uint256 amount,
        uint256 percent
    ) external;

    function setAmount(address token, uint256 amount) external;

    function setPercent(address token, uint256 percent) external;

    function resetConnection(address token, address crossToken) external;

    function processPack(
        uint64[2] memory blockScanRange,
        uint256[] memory txHashes,
        address[] memory tokens,
        address[] memory recipients,
        uint256[] memory amounts
    ) external;
}

// File: contracts/library/BridgeUtils.sol

pragma solidity ^0.8.7;

library BridgeUtils {
    uint256 internal constant FUTURE_BLOCK_INTERVAL = 100;
    uint256 public constant CHARGE_PERCENTAGE_DIVIDER = 10000;

    function roundFuture(uint256 blockIndex) internal pure returns (uint64) {
        uint256 _futureBlockIndex;
        if (blockIndex <= FUTURE_BLOCK_INTERVAL) {
            _futureBlockIndex = FUTURE_BLOCK_INTERVAL;
        } else {
            _futureBlockIndex =
                FUTURE_BLOCK_INTERVAL *
                ((blockIndex / FUTURE_BLOCK_INTERVAL) + 1);
        }
        return uint64(_futureBlockIndex);
    }

    function getFuture(uint256 blockIndex)
        internal
        pure
        returns (uint64 futureBlockIndex)
    {
        uint256 _futureBlockIndex;
        if (blockIndex <= FUTURE_BLOCK_INTERVAL) {
            _futureBlockIndex = 0;
        } else {
            _futureBlockIndex =
                FUTURE_BLOCK_INTERVAL *
                (blockIndex / FUTURE_BLOCK_INTERVAL);
        }
        return uint64(_futureBlockIndex);
    }

    function getBlockScanRange(
        uint16 count,
        uint8[] memory networks,
        mapping(uint8 => address) storage bridges
    )
        internal
        view
        returns (uint8[] memory _networks, uint64[][] memory _ranges)
    {
        _networks = new uint8[](count);
        _ranges = new uint64[][](count);
        uint64 k = 0;
        for (uint64 i = 0; i < networks.length; i++) {
            if (bridges[networks[i]] != address(0)) {
                _networks[k] = networks[i];
                _ranges[k] = IBridge(bridges[networks[i]]).blockScanRange();
                k++;
            }
        }
    }

    function getCharges(
        uint16 count,
        uint8[] memory networks,
        mapping(uint8 => address) storage bridges
    ) internal view returns (TokensChargesInfo memory info) {
        uint8[] memory _networks = new uint8[](count);
        address[][] memory _tokens = new address[][](count);
        uint256[][] memory _charges = new uint256[][](count);
        uint64 k = 0;
        for (uint64 i = 0; i < networks.length; i++) {
            if (bridges[networks[i]] != address(0)) {
                _networks[k] = networks[i];
                (_tokens[k], _charges[k]) = IBridge(bridges[networks[i]])
                    .charges();
                k++;
            }
        }
        info.ids = _networks;
        info.tokens = _tokens;
        info.charges = _charges;
    }

    function getTokenReq(
        uint64 futureBlock,
        address token,
        uint64[] memory futureBlocks,
        mapping(address => mapping(uint64 => TokenReq)) storage tokenReqs
    ) internal view returns (uint256 amount, uint256 percent) {
        TokenReq memory _req = getReq(
            futureBlock,
            token,
            futureBlocks,
            tokenReqs
        );
        amount = _req.minAmount;
        percent = _req.chargePercent;
    }

    function getCollectedChargesCN(
        ICrossBridgeStorageToken bridgeStorage,
        uint8 networkId
    ) internal view returns (TokensChargesInfo memory info) {
        uint8[] memory _networks = new uint8[](1);
        address[][] memory _tokens = new address[][](1);
        uint256[][] memory _charges = new uint256[][](1);
        _networks[0] = networkId;
        (_tokens[0], _charges[0]) = bridgeStorage.charges();
        info.ids = _networks;
        info.tokens = _tokens;
        info.charges = _charges;
    }

    function getTransactionInfo(
        uint64 futureBlock,
        address token,
        uint256 amount,
        uint64[] memory futureBlocks,
        mapping(address => mapping(uint64 => TokenReq)) storage tokenReqs
    ) internal view returns (uint256 fee, uint256 amountAfterCharge) {
        TokenReq memory _req = getReq(
            futureBlock,
            token,
            futureBlocks,
            tokenReqs
        );
        fee = (amount * _req.chargePercent) / CHARGE_PERCENTAGE_DIVIDER;
        amountAfterCharge = amount - fee;
    }

    function updateMap(
        address[] memory arr,
        bool status,
        mapping(address => bool) storage map
    ) internal {
        for (uint64 i = 0; i < arr.length; i++) {
            map[arr[i]] = status;
        }
    }

    function getReq(
        uint64 blockIndex,
        address token,
        uint64[] memory futureBlocks,
        mapping(address => mapping(uint64 => TokenReq)) storage tokenReqs
    ) internal view returns (TokenReq memory req) {
        req = tokenReqs[token][blockIndex];
        if (!req.exist) {
            for (uint256 i = futureBlocks.length; i > 0; i--) {
                if (futureBlocks[i - 1] <= blockIndex) {
                    req = tokenReqs[token][futureBlocks[i - 1]];
                    if (req.exist) return req;
                }
            }
        }
    }

    function getCountBySearchIndex(
        uint64 searchBlockIndex,
        address[] memory tokens,
        mapping(address => bool) storage mapTokens,
        mapping(address => uint64) storage mapTokenCreatedBlockIndex
    ) internal view returns (uint64 k) {
        for (uint64 i = 0; i < tokens.length; i++) {
            if (
                mapTokens[tokens[i]] &&
                (mapTokenCreatedBlockIndex[tokens[i]] <= searchBlockIndex)
            ) {
                k++;
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts/BaseCrossBridge/base/CrossBridgeStorageTokenUpgradeable.sol

pragma solidity ^0.8.7;

contract CrossBridgeStorageTokenUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ICrossBridgeStorageToken
{
    using BridgeSecurity for *;
    using BridgeUtils for *;
    using BridgeScanRange for uint64[];

    address private _admin;
    address private _bridge;

    NetworkInfo private _network;
    uint8 private _activeTokenCount;
    address[] private _tokens;
    uint64[] private _scanRanges;
    uint64[] private _futureBlocks;
    mapping(address => address) private _mappedOCTokens;
    mapping(address => address) private _mappedCOTokens;
    mapping(address => bool) private _mapTokens;
    mapping(address => uint64) private _mapTokenCreatedBlockIndex;
    mapping(address => CrossTokenInfo) private _crossTokenInfos;
    mapping(address => TokenReq) private _tokenLastestReqs;
    mapping(address => mapping(uint64 => TokenReq)) private _tokenReqs;
    mapping(address => uint256) private _collectedTokenCharges;
    mapping(uint256 => bool) private _txHashes;
    mapping(uint64 => bool) private _mapFutureBlocks;

    function __CrossBridgeTokenStorage_init(
        uint8 networkId,
        string memory networkName
    ) internal initializer {
        __Ownable_init();
        _network.id = networkId;
        _network.name = networkName;
    }

    function owner()
        public
        view
        override(OwnableUpgradeable, ICrossBridgeStorageToken)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function admin() public view virtual override returns (address) {
        return _admin;
    }

    function bridge() public view virtual override returns (address) {
        return _bridge;
    }

    modifier onlyAllowedOwner() {
        require(msg.sender == bridge() || msg.sender == admin());
        _;
    }

    function mapToken(address token)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _mapTokens[token];
    }

    function mapOcToken(address token)
        external
        view
        virtual
        override
        returns (address)
    {
        return _mappedOCTokens[token];
    }

    function mapCoToken(address token)
        external
        view
        virtual
        override
        returns (address)
    {
        return _mappedCOTokens[token];
    }

    function blockScanRange()
        external
        view
        virtual
        override
        returns (uint64[] memory)
    {
        return _scanRanges;
    }

    function crossToken(address token)
        external
        view
        virtual
        override
        returns (string memory name, string memory symbol)
    {
        return (_crossTokenInfos[token].name, _crossTokenInfos[token].symbol);
    }

    function tokens(
        ITokenFactory tf,
        uint64 futureBlock,
        uint64 searchBlockIndex
    )
        external
        view
        virtual
        override
        returns (
            uint8[] memory,
            address[][] memory,
            address[][] memory,
            uint256[][] memory,
            uint256[][] memory,
            uint8[][] memory
        )
    {
        TokenData memory data = _getTokensInfo(
            tf,
            futureBlock,
            searchBlockIndex
        );
        TokensInfo memory info = _packTokensInfo(data);
        return (
            info.ids,
            info.tokens,
            info.crossTokens,
            info.minAmounts,
            info.chargePercents,
            info.tokenTypes
        );
    }

    function tokens(
        ITokenFactory tf,
        uint8 id,
        uint64 futureBlock,
        uint64 searchBlockIndex
    )
        external
        view
        virtual
        override
        returns (
            address[] memory tokens_,
            address[] memory crossTokens,
            uint256[] memory amounts,
            uint256[] memory percents,
            uint8[] memory types
        )
    {
        if (id == _network.id) {
            TokenData memory data = _getTokensInfo(
                tf,
                futureBlock,
                searchBlockIndex
            );
            return (
                data.tokens,
                data.crossTokens,
                data.minAmounts,
                data.chargePercents,
                data.tokenTypes
            );
        }
    }

    function charges()
        external
        view
        virtual
        override
        returns (address[] memory tokens_, uint256[] memory charges_)
    {
        tokens_ = new address[](_activeTokenCount);
        charges_ = new uint256[](_activeTokenCount);
        uint64 k = 0;
        for (uint64 i = 0; i < _tokens.length; i++) {
            if (_mapTokens[_tokens[i]]) {
                tokens_[k] = _tokens[i];
                charges_[k] = _collectedTokenCharges[_tokens[i]];
            }
            k++;
        }
    }

    function txHash(uint256 txHash_)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _txHashes[txHash_];
    }

    function transactionInfo(
        uint64 futureBlock,
        address token,
        uint256 amount
    )
        external
        view
        virtual
        override
        returns (uint256 fee, uint256 amountAfterCharge)
    {
        (fee, amountAfterCharge) = BridgeUtils.getTransactionInfo(
            futureBlock,
            token,
            amount,
            _futureBlocks,
            _tokenReqs
        );
    }

    function setCallers(address admin_, address bridge_)
        external
        virtual
        override
        onlyOwner
    {
        _admin = admin_;
        _bridge = bridge_;
    }

    function resetConnection(address token, address crossToken_)
        external
        virtual
        override
        onlyAllowedOwner
    {
        if (!_mapTokens[token]) {
            _tokens.push(token);
            _mapTokens[token] = true;
        }

        if (_mappedCOTokens[crossToken_] != address(0)) {
            _mapTokens[_mappedCOTokens[crossToken_]] = false;

            TokenReq storage _oriReq = _tokenReqs[_mappedCOTokens[crossToken_]][
                0
            ];

            TokenReq storage _req = _tokenReqs[token][0];
            _req.exist = true;
            _req.minAmount = _oriReq.minAmount;
            _req.chargePercent = _oriReq.chargePercent;

            TokenReq storage _oriLatestReq = _tokenReqs[
                _mappedCOTokens[crossToken_]
            ][0];

            TokenReq storage _latestReq = _tokenLastestReqs[token];
            _latestReq.minAmount = _oriLatestReq.minAmount;
            _latestReq.chargePercent = _oriLatestReq.chargePercent;
        }

        _mappedOCTokens[token] = crossToken_;
        _mappedCOTokens[crossToken_] = token;
    }

    function setConnection(
        address token,
        uint256 minAmount,
        uint256 chargePercent,
        address crossToken_,
        string memory name,
        string memory symbol
    ) external virtual override onlyAllowedOwner {
        require(_mappedOCTokens[token] == address(0), "TCE");
        uint64 futureBlock = block.number.roundFuture();

        _mapTokenCreatedBlockIndex[token] = futureBlock;
        _tokens.push(token);
        _mapTokens[token] = true;
        _mappedOCTokens[token] = crossToken_;
        _mappedCOTokens[crossToken_] = token;
        _activeTokenCount++;

        CrossTokenInfo storage _info = _crossTokenInfos[crossToken_];
        _info.name = name;
        _info.symbol = symbol;

        TokenReq storage _req = _tokenReqs[token][0];
        _req.exist = true;
        _req.minAmount = minAmount;
        _req.chargePercent = chargePercent;

        _futureBlocks.push(0);
        _mapFutureBlocks[0] = true;

        TokenReq storage _latestReq = _tokenLastestReqs[token];
        _latestReq.minAmount = minAmount;
        _latestReq.chargePercent = chargePercent;

        emit TokenConnected(
            token,
            minAmount,
            chargePercent,
            crossToken_,
            symbol
        );
    }

    function setInfo(
        address token,
        uint256 minAmount,
        uint256 chargePercent
    ) external virtual override onlyAllowedOwner {
        uint64 futureBlock = block.number.roundFuture();

        TokenReq storage _latestReq = _tokenLastestReqs[token];
        emit TokenRequirementChanged(
            futureBlock,
            token,
            [_latestReq.minAmount, minAmount],
            [_latestReq.chargePercent, chargePercent]
        );
        _latestReq.minAmount = minAmount;
        _latestReq.chargePercent = chargePercent;

        TokenReq storage _req = _tokenReqs[token][futureBlock];
        _req.exist = true;
        _req.minAmount = minAmount;
        _req.chargePercent = chargePercent;

        if (!_mapFutureBlocks[futureBlock]) {
            _futureBlocks.push(futureBlock);
            _mapFutureBlocks[futureBlock] = true;
        }
    }

    function setAmount(address token, uint256 minAmount)
        external
        virtual
        override
        onlyAllowedOwner
    {
        uint64 futureBlock = block.number.roundFuture();

        TokenReq storage _latestReq = _tokenLastestReqs[token];
        emit TokenRequirementChanged(
            futureBlock,
            token,
            [_latestReq.minAmount, minAmount],
            [uint256(0), uint256(0)]
        );
        _latestReq.minAmount = minAmount;

        TokenReq storage _req = _tokenReqs[token][futureBlock];
        _req.exist = true;
        _req.minAmount = minAmount;
        _req.chargePercent = _latestReq.chargePercent;

        if (!_mapFutureBlocks[futureBlock]) {
            _futureBlocks.push(futureBlock);
            _mapFutureBlocks[futureBlock] = true;
        }
    }

    function setPercent(address token, uint256 chargePercent)
        external
        virtual
        override
        onlyAllowedOwner
    {
        uint64 futureBlock = block.number.roundFuture();

        TokenReq storage _latestReq = _tokenLastestReqs[token];
        emit TokenRequirementChanged(
            futureBlock,
            token,
            [uint256(0), uint256(0)],
            [_latestReq.chargePercent, chargePercent]
        );
        _latestReq.chargePercent = chargePercent;

        TokenReq storage _req = _tokenReqs[token][futureBlock];
        _req.exist = true;
        _req.minAmount = _latestReq.minAmount;
        _req.chargePercent = chargePercent;

        if (!_mapFutureBlocks[futureBlock]) {
            _futureBlocks.push(futureBlock);
            _mapFutureBlocks[futureBlock] = true;
        }
    }

    function setTxHash(uint256 txHash_)
        external
        virtual
        override
        onlyAllowedOwner
    {
        _txHashes[txHash_] = true;
    }

    function setCollectedCharges(address token, uint256 amount)
        external
        virtual
        override
        onlyAllowedOwner
    {
        _collectedTokenCharges[token] += amount;
    }

    function setScanRange(uint64[2] memory scanRange_)
        external
        virtual
        override
        onlyAllowedOwner
    {
        uint64[] memory r = _scanRanges.getBlockScanRange(
            scanRange_[0],
            scanRange_[1]
        );
        delete _scanRanges;
        _scanRanges = r;
    }

    function _getTokensInfo(
        ITokenFactory tf,
        uint64 futureBlock,
        uint64 searchBlockIndex
    ) private view returns (TokenData memory data) {
        uint64 _searchActive = searchBlockIndex.getCountBySearchIndex(
            _tokens,
            _mapTokens,
            _mapTokenCreatedBlockIndex
        );
        data.tokens = new address[](_searchActive);
        data.crossTokens = new address[](_searchActive);
        data.minAmounts = new uint256[](_searchActive);
        data.chargePercents = new uint256[](_searchActive);
        data.tokenTypes = new uint8[](_searchActive);
        uint64 k = 0;
        for (uint64 i = 0; i < _tokens.length; i++) {
            if (
                _mapTokens[_tokens[i]] &&
                (_mapTokenCreatedBlockIndex[_tokens[i]] <= searchBlockIndex)
            ) {
                data.tokens[k] = _tokens[i];
                data.crossTokens[k] = _mappedOCTokens[_tokens[i]];
                (data.minAmounts[k], data.chargePercents[k]) = futureBlock
                    .getTokenReq(_tokens[i], _futureBlocks, _tokenReqs);
                data.tokenTypes[k] = tf.tokenExist(_tokens[i]) ? 0 : 1;
                k++;
            }
        }
    }

    function _packTokensInfo(TokenData memory data)
        private
        view
        returns (TokensInfo memory info)
    {
        info.ids = new uint8[](1);
        info.tokens = new address[][](1);
        info.crossTokens = new address[][](1);
        info.minAmounts = new uint256[][](1);
        info.chargePercents = new uint256[][](1);
        info.tokenTypes = new uint8[][](1);

        info.ids[0] = _network.id;
        info.tokens[0] = data.tokens;
        info.crossTokens[0] = data.crossTokens;
        info.minAmounts[0] = data.minAmounts;
        info.chargePercents[0] = data.chargePercents;
        info.tokenTypes[0] = data.tokenTypes;
    }
}

// File: contracts/Net-Ethereum/Bridge/EthereumBridgeStorageToken.sol

pragma solidity ^0.8.7;

contract EthereumBridgeStorageToken is CrossBridgeStorageTokenUpgradeable {
    function initialize(uint8 networkId, string memory networkName)
        public
        initializer
    {
        __CrossBridgeTokenStorage_init(networkId, networkName);
    }
}