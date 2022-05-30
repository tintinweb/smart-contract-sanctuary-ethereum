/**
 *Submitted for verification at Etherscan.io on 2022-05-30
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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/BaseToken/interface/ITokenMintable.sol

pragma solidity ^0.8.7;

interface ITokenMintable is IERC20Upgradeable {
    function initialize(
        address factory,
        string memory name,
        string memory symbol,
        uint256 amount,
        uint8 decimal,
        uint256 cap
    ) external;

    function factory() external view returns (address);

    function decimals() external view returns (uint8);

    function cap() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function increaseCap(uint256 cap) external;

    function setupDecimal(uint8 decimal) external;
}

// File: contracts/BaseCrossBridgeV2/interface/ICrossBridgeAdminV2.sol

pragma solidity ^0.8.7;

interface ICrossBridgeAdminV2 {
    function owner() external view returns (address);

    function crossToken(address crossToken)
        external
        view
        returns (string memory, string memory);

    function resetTokenConnection(address token, address crossToken) external;

    function setTokenConnection(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 chargePercent,
        uint256 minCharge,
        uint256 maxCharge,
        address crossToken,
        string memory name,
        string memory symbol
    ) external;

    function setTokenInfo(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 chargePercent,
        uint256 minCharge,
        uint256 maxCharge
    ) external;

    function increaseCap(address token, uint256 cap) external;
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
        uint8 decimal,
        uint256 cap,
        address indexed token
    );

    event TokenRemoved(address indexed token);

    event TokenDecimalChanged(
        address indexed token,
        uint8 oldDecimal,
        uint8 newDecimal
    );

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
        uint8 decimal,
        uint256 cap
    ) external returns (address token);

    function removeToken(address token) external;

    function setTokenDecimal(address token, uint8 decimal) external;
}

// File: contracts/BaseBridgeV2/interface/IBridgeV2.sol

pragma solidity ^0.8.7;

struct TokenReq {
    bool exist;
    uint256 minAmount;
    uint256 maxAmount;
    uint256 chargePercent;
    uint256 minCharge;
    uint256 maxCharge;
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
    uint256[] maxAmounts;
    uint256[] chargePercents;
    uint256[] minCharges;
    uint256[] maxCharges;
    uint8[] tokenTypes;
}

struct TokensInfo {
    uint8[] ids;
    address[][] tokens;
    address[][] crossTokens;
    uint256[][] minAmounts;
    uint256[][] maxAmounts;
    uint256[][] chargePercents;
    uint256[][] minCharges;
    uint256[][] maxCharges;
    uint8[][] tokenTypes;
}

interface IBridgeV2 {
    event TokenConnected(
        address indexed token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 percent,
        uint256 minCharge,
        uint256 maxCharge,
        address indexed crossToken,
        string symbol
    );

    event TokenReqChanged(
        uint64 blockIndex,
        address indexed token,
        uint256[2] minAmount,
        uint256[2] maxAmount,
        uint256[2] percent,
        uint256[2] minCharge,
        uint256[2] maxCharge
    );

    function initialize(
        address factory,
        address admin,
        address tokenFactory,
        address wMech,
        uint8 networkId,
        string memory networkName
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

    function txHash(uint256 txHash) external view returns (bool);

    function setTokenConnection(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 percent,
        uint256 minCharge,
        uint256 maxCharge,
        address crossToken,
        string memory name,
        string memory symbol
    ) external;

    function setTokenInfo(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 percent,
        uint256 minCharge,
        uint256 maxCharge
    ) external;

    function resetTokenConnection(address token, address crossToken) external;

    function processPack(
        uint64[2] memory blockScanRange,
        uint256[] memory txHashes,
        address[] memory tokens,
        address[] memory recipients,
        uint256[] memory amounts
    ) external;

    function setScanRange(uint64[2] memory scanRange) external;
}

// File: contracts/BaseCrossBridgeV2/interface/ICrossBridgeStorageTokenV2.sol

pragma solidity ^0.8.7;

interface ICrossBridgeStorageTokenV2 {
    event TokenConnected(
        address indexed token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 percent,
        uint256 minCharge,
        uint256 maxCharge,
        address indexed crossToken,
        string symbol
    );

    event TokenRequirementChanged(
        uint64 blockIndex,
        address indexed token,
        uint256[2] minAmount,
        uint256[2] maxAmount,
        uint256[2] percent,
        uint256[2] minCharge,
        uint256[2] maxCharge
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
    ) external view returns (TokensInfo memory info);

    function txHash(uint256 txHash) external view returns (bool);

    function setCallers(address admin, address bridge) external;

    function resetTokenConnection(address token, address crossToken) external;

    function setTokenConnection(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 chargePercent,
        uint256 minCharge,
        uint256 maxCharge,
        address crossToken,
        string memory name,
        string memory symbol
    ) external;

    function setTokenInfo(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 chargePercent,
        uint256 minCharge,
        uint256 maxCharge
    ) external;

    function setTxHash(uint256 txHash) external;

    function setScanRange(uint64[2] memory scanRange) external;
}

// File: contracts/library/BridgeUtilsV2.sol

pragma solidity ^0.8.7;

library BridgeUtilsV2 {
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
                _ranges[k] = IBridgeV2(bridges[networks[i]]).blockScanRange();
                k++;
            }
        }
    }

    function getTokenReq(
        uint64 futureBlock,
        address token,
        uint64[] memory futureBlocks,
        mapping(address => mapping(uint64 => TokenReq)) storage tokenReqs
    )
        internal
        view
        returns (
            uint256 minAmount,
            uint256 maxAmount,
            uint256 percent,
            uint256 minCharge,
            uint256 maxCharge
        )
    {
        TokenReq memory _req = getReq(
            futureBlock,
            token,
            futureBlocks,
            tokenReqs
        );
        minAmount = _req.minAmount;
        maxAmount = _req.maxAmount;
        percent = _req.chargePercent;
        minCharge = _req.minCharge;
        maxCharge = _req.maxCharge;
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

// File: contracts/BaseCrossBridgeV2/interface/ICrossBridgeStorageV2.sol

pragma solidity ^0.8.7;

interface ICrossBridgeStorageV2 {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event SignersChanged(
        address[] indexed oldSigners,
        address[] indexed newSigners
    );

    event RelayersChanged(
        address[] indexed oldRelayers,
        address[] indexed newRelayers
    );

    function owner() external view returns (address);

    function admin() external view returns (address);

    function bridge() external view returns (address);

    function network() external view returns (NetworkInfo memory);

    function epoch() external view returns (uint64);

    function signers() external view returns (address[] memory);

    function relayers() external view returns (address[] memory);

    function mapSigner(address signer) external view returns (bool);

    function mapRelayer(address relayer) external view returns (bool);

    function setCallers(address admin, address bridge) external;

    function setEpoch(uint64 epoch) external;

    function setSigners(address[] memory signers_) external;

    function setRelayers(address[] memory relayers_) external;

    function signerVerification(
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external view returns (bool);
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

// File: contracts/BaseCrossBridgeV2/base/CrossBridgeAdminUpgradeableV2.sol

pragma solidity ^0.8.7;

contract CrossBridgeAdminUpgradeableV2 is
    Initializable,
    OwnableUpgradeable,
    ICrossBridgeAdminV2
{
    using BridgeSecurity for *;
    using BridgeUtilsV2 for *;
    using BridgeScanRange for uint64[];

    ITokenFactory private tf;
    ICrossBridgeStorageV2 private bs;
    ICrossBridgeStorageTokenV2 private bts;

    function __CrossBridgeAdmin_init(
        address tokenFactory,
        address bridgeStorage,
        address bridgeTokenStorage
    ) internal initializer {
        __Ownable_init();
        tf = ITokenFactory(tokenFactory);
        bs = ICrossBridgeStorageV2(bridgeStorage);
        bts = ICrossBridgeStorageTokenV2(bridgeTokenStorage);
    }

    function owner()
        public
        view
        override(OwnableUpgradeable, ICrossBridgeAdminV2)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    function crossToken(address crossToken_)
        external
        view
        virtual
        override
        returns (string memory name, string memory symbol)
    {
        return bts.crossToken(crossToken_);
    }

    function resetTokenConnection(address token, address crossToken_)
        external
        virtual
        override
        onlyOwner
    {
        require(token != address(0), "ZA");
        require(crossToken_ != address(0), "ZA");

        bts.resetTokenConnection(token, crossToken_);
    }

    function setTokenConnection(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 chargePercent,
        uint256 minCharge,
        uint256 maxCharge,
        address crossToken_,
        string memory name,
        string memory symbol
    ) external virtual override onlyOwner {
        require(token != address(0), "ZA");
        require(crossToken_ != address(0), "ZA");
        require(bts.mapOcToken(token) == address(0), "TCE");

        bts.setTokenConnection(
            token,
            minAmount,
            maxAmount,
            chargePercent,
            minCharge,
            maxCharge,
            crossToken_,
            name,
            symbol
        );
    }

    function setTokenInfo(
        address token,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 chargePercent,
        uint256 minCharge,
        uint256 maxCharge
    ) external virtual override onlyOwner {
        require(bts.mapToken(token), "TXE");
        bts.setTokenInfo(
            token,
            minAmount,
            maxAmount,
            chargePercent,
            minCharge,
            maxCharge
        );
    }

    function increaseCap(address token, uint256 cap)
        external
        virtual
        override
        onlyOwner
    {
        require(token != address(0), "ZA");
        ITokenMintable(token).increaseCap(cap);
    }
}

// File: contracts/Net-Ethereum/BridgeV2/EthereumBridgeAdminV2.sol

pragma solidity ^0.8.7;

contract EthereumBridgeAdminV2 is CrossBridgeAdminUpgradeableV2 {
    function initialize(
        address tokenFactory,
        address bridgeStorage,
        address bridgeTokenStorage
    ) public initializer {
        __CrossBridgeAdmin_init(
            tokenFactory,
            bridgeStorage,
            bridgeTokenStorage
        );
    }
}