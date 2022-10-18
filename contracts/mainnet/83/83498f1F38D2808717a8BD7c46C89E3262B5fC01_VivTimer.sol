// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "../erc20/Token.sol";
import "../util/SignUtil.sol";
import "../util/SafeMath.sol";

/**
 * A timer contract mainly binds the buyer, agrees on the payment date in advance, and requires the buyer to pay on time. 
 * There is no link of delivery and confirmation of receipt. A deposit (optional) is required. 
 * The deposit is locked before the end of the contract and can be withdrawn by the buyer after the end of the contract.

 * Suitable scenarios such as monthly video membership, rent payment, etc.
 */
contract VivTimer is Token {
    using SafeMath for uint256;

    struct User {
        address payable seller;
        address payable buyer;
        address payable platform;
        address guarantor;
    }

    struct Deposit {
        uint256 deposit;
        uint256 completedDeposit;
        uint256 withdrawedDeposit;
        uint256 historyPenalty;
        uint256 withdrawedPenalty;
    }

    struct Trade {
        address token;
        User user;
        uint256[] values;
        uint256[] times;
        bytes tid;
        bool refund;
        uint256 refundTime;
        Deposit deposit;
        uint256 current;
        uint256 penaltyRate;
        uint256 feeRate;
    }

    mapping(bytes => Trade) _trades;

    bytes[] _tids;

    mapping(bytes => bool) _couponIds;

    uint256 constant _INTERNAL_SECONDS = 86400;

    function getPayAmount(bytes calldata tid) external view returns (uint256 waitPayAmount, uint256 payedAmount) {
        Trade memory trade = _trades[tid];
        if (trade.current == trade.values.length) {
            return (0, 0);
        }
        for (uint256 i = trade.current; i < trade.values.length; i++) {
            waitPayAmount = waitPayAmount.add(trade.values[i]);
        }
        for (uint256 i = 0; i < trade.current; i++) {
            payedAmount = payedAmount.add(trade.values[i]);
        }
    }

    function getDeposit(bytes calldata tid)
        external
        view
        returns (
            uint256 deposit,
            uint256 completedDeposit,
            uint256 withdrawedDeposit,
            uint256 historyPenalty,
            uint256 withdrawedPenalty
        )
    {
        return (
            _trades[tid].deposit.deposit,
            _trades[tid].deposit.completedDeposit,
            _trades[tid].deposit.withdrawedDeposit,
            _trades[tid].deposit.historyPenalty,
            _trades[tid].deposit.withdrawedPenalty
        );
    }

    // function getRefundStatus(bytes calldata tid) external view returns(bool refundStatus) {
    //     Trade memory trade = _trades[tid];
    //     refundStatus = trade.refund;
    // }

    // function getRefundTime(bytes calldata tid) external view returns(uint256 refundTime) {
    //     Trade memory trade = _trades[tid];
    //     refundTime = trade.refundTime;
    // }

    function getCurrent(bytes calldata tid) external view returns (uint256 current) {
        return _trades[tid].current;
    }

    function getWithdrawAmount(bytes calldata tid)
        external
        view
        returns (
            uint256 canWithdraw,
            uint256 withdrawed,
            uint256 totalPenalty
        )
    {
        return _getWithdrawAmount(tid, block.timestamp);
    }

    function _getWithdrawAmount(bytes calldata tid, uint256 currentTime)
        internal
        view
        returns (
            uint256 canWithdraw,
            uint256 withdrawed,
            uint256 totalPenalty
        )
    {
        Trade memory trade = _trades[tid];
        totalPenalty = _getTotalPenalty(trade, currentTime);
        canWithdraw = totalPenalty.sub(trade.deposit.withdrawedPenalty);
        uint256 remainderDeposit = trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(
            trade.deposit.withdrawedDeposit
        );
        if (totalPenalty > remainderDeposit) {
            canWithdraw = remainderDeposit.sub(trade.deposit.withdrawedPenalty);
        }
        withdrawed = trade.deposit.withdrawedPenalty;
    }

    /**
     * purchase
     * note: This function is called by the buyer and completes the purchase
     * @param users users: seller, platform, guarantor, token
     * @param values installment value
     * @param times installment time
     * @param tid trade id
     * @param penaltyRate penalty ratio
     * @param value value
     * @param deposit deposit
     */
    function purchase(
        address[] memory users,
        uint256[] memory values,
        uint256[] memory times,
        bytes calldata tid,
        uint256 penaltyRate,
        uint256 feeRate,
        uint256 value,
        uint256 deposit
    ) external payable {
        _purchase(users, values, times, tid, penaltyRate, feeRate, value, deposit, block.timestamp);
    }

    function _purchase(
        address[] memory users,
        uint256[] memory values,
        uint256[] memory times,
        bytes calldata tid,
        uint256 penaltyRate,
        uint256 feeRate,
        uint256 value,
        uint256 deposit,
        uint256 currentTime
    ) internal {
        require(value > 0, "VIV0001");
        Trade storage trade = _trades[tid];
        if (trade.user.buyer == address(0)) {
            address seller = users[0];
            address platform = users[1];
            address guarantor = users[2];
            address token = users[3];
            require(seller != address(0), "VIV5001");
            require(platform != address(0), "VIV5002");
            require(guarantor != address(0), "VIV5003");
            require(values.length > 0 && times.length > 0, "VIV5409");
            require(values.length == times.length, "VIV5408");

            // first purchage
            trade.token = token;
            trade.user.seller = payable(seller);
            trade.user.buyer = payable(msg.sender);
            trade.user.platform = payable(platform);
            trade.user.guarantor = guarantor;
            trade.values = values;
            trade.times = times;
            trade.tid = tid;
            trade.deposit.deposit = deposit;
            trade.current = 0;
            trade.penaltyRate = penaltyRate;
            trade.feeRate = feeRate;
            _tids.push(tid);
        } else {
            // trade.current == trade.times.length means this transaction has ended
            require(trade.current < trade.times.length, "VIV5505");

            // Calculate whether the user needs to make up the deposit
            uint256 totalPenalty = _getTotalPenalty(trade, currentTime);
            require(deposit >= totalPenalty.sub(trade.deposit.completedDeposit), "VIV5501");
            trade.deposit.historyPenalty = totalPenalty;
            trade.deposit.completedDeposit = trade.deposit.completedDeposit.add(deposit);
        }

        uint256 totalPayment = value.add(deposit);
        _checkTransferIn(trade.token, totalPayment);

        // Determine how much the buyer needs to pay
        // The buyer must pay the debt first
        uint256 needPay = 0;
        uint256 i = trade.current;
        for (; i < trade.times.length; i++) {
            if (trade.times[i] < currentTime) {
                needPay = needPay.add(trade.values[i]);
            } else {
                break;
            }
        }

        // Buyer does not have enough money to pay the debt
        require(value >= needPay, "VIV5502");

        // The payment amount must match the amount to be paid
        if (value > needPay) {
            uint256 over = value.sub(needPay);
            while (i < trade.values.length) {
                over = over.sub(trade.values[i]);
                i++;
                if (over == 0) {
                    break;
                } else if (over < 0) {
                    // The payment amount does not match the amount to be paid
                    revert("VIV5503");
                }
            }
        }

        // Buyer transfer to the contract
        _transferFrom(trade.token, trade.user.buyer, address(this), totalPayment);

        // Pay to the platform
        uint256 fee = value.rate(trade.feeRate);
        if (fee > 0) {
            _transfer(trade.token, trade.user.platform, fee);
        }

        // Pay to the seller
        _transfer(trade.token, trade.user.seller, value.sub(fee));

        // Set the buyer's next payment period
        trade.current = i;
    }

    // /**
    //  * Request a refund
    //  * @param tid trade id
    //  */
    // function refund(bytes calldata tid) external {
    //    Trade storage trade = _trades[tid];
    //    require(trade.user.buyer == msg.sender, "VIV5401");
    //    require(trade.refund == false, "VIV5402");
    //    trade.refund = true;
    //    trade.refundTime = block.timestamp;
    // }

    // /**
    //  * Refused to refund
    //  * @param tid trade id
    //  */
    // function cancelRefund(bytes calldata tid) external {
    //    Trade storage trade = _trades[tid];
    //    require(trade.buyer == msg.sender, "VIV5401");
    //    require(trade.refund == true, "VIV5402");
    //    trade.refund = false;
    // }

    /**
     * Withdraw
     * note: If the buyer, seller, and guarantor sign any two parties, the seller or the buyer can withdraw.
     * @param signedValue1 signed by one of seller, buyer, guarantor
     * @param signedValue2 signed by one of seller, buyer, guarantor
     * @param signedValue3 signed by platform
     * @param value        all amount, include which user can get, platform fee and arbitrate fee
     * @param couponRate   platform service fee rate
     * @param arbitrateFee arbitration service fee
     * @param tid          trade id
     * @param couponId     coupon id
     */
    function withdraw(
        bytes memory signedValue1,
        bytes memory signedValue2,
        bytes memory signedValue3,
        uint256 value,
        uint256 couponRate,
        uint256 arbitrateFee,
        bytes memory tid,
        bytes memory couponId
    ) external {
        _withdraw(
            signedValue1,
            signedValue2,
            signedValue3,
            value,
            couponRate,
            arbitrateFee,
            tid,
            couponId,
            block.timestamp
        );
    }

    function _withdraw(
        bytes memory signedValue1,
        bytes memory signedValue2,
        bytes memory signedValue3,
        uint256 value,
        uint256 couponRate,
        uint256 arbitrateFee,
        bytes memory tid,
        bytes memory couponId,
        uint256 currentTime
    ) internal {
        Trade storage trade = _trades[tid];
        require(trade.user.seller != address(0), "VIV5005");
        require(value > 0, "VIV0001");
        require(trade.user.seller == msg.sender || trade.user.buyer == msg.sender, "VIV5406");
        
        uint256 available = value.sub(arbitrateFee);
        uint256 fee = available.rate(trade.feeRate);
        // Calculate the discounted price when couponRate more than 0
        if (couponRate > 0) {
            // Coupon cannot be reused
            require(!_couponIds[couponId], "VIV0006");
            // Check if platform signed
            bytes32 h = ECDSA.toEthSignedMessageHash(abi.encode(couponRate, couponId, tid));
            require(SignUtil.checkSign(h, signedValue3, trade.user.platform), "VIV0007");
            // Use a coupon
            fee = fee.sub(fee.rate(couponRate));
            _couponIds[couponId] = true;
        }

        bytes32 hashValue = ECDSA.toEthSignedMessageHash(abi.encode(value, arbitrateFee, tid));
        uint256 canWithdraw = 0;
        if (arbitrateFee == 0 && trade.user.seller == msg.sender) { 
            require(
                SignUtil.checkSign(
                    hashValue,
                    signedValue1,
                    signedValue2,
                    trade.user.buyer,
                    trade.user.seller,
                    trade.user.platform
                ),
                "VIV5006"
            );
            // The amount that the seller can withdraw is the number of days from the overdue date to the current day * deposit * daily penalty ratio
            uint256 totalPenalty = _getTotalPenalty(trade, currentTime);
            canWithdraw = totalPenalty.sub(trade.deposit.withdrawedPenalty);
            // If the penalty interest exceeds the deposit, the penalty interest is equal to the deposit
            uint256 remainderDeposit = trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(
                trade.deposit.withdrawedDeposit
            );
            if (totalPenalty > remainderDeposit) {
                canWithdraw = remainderDeposit.sub(trade.deposit.withdrawedPenalty);
            }
            trade.deposit.withdrawedPenalty = trade.deposit.withdrawedPenalty.add(value);
        } else {
            require(
                SignUtil.checkSign(
                    hashValue,
                    signedValue1,
                    signedValue2,
                    trade.user.buyer,
                    trade.user.seller,
                    trade.user.guarantor
                ),
                "VIV5006"
            );
            canWithdraw = trade
                .deposit
                .deposit
                .add(trade.deposit.completedDeposit)
                .sub(trade.deposit.withdrawedDeposit)
                .sub(trade.deposit.withdrawedPenalty);
            trade.deposit.withdrawedDeposit = trade.deposit.withdrawedDeposit.add(value);
        }

        require(value <= canWithdraw, "VIV5405");

        if (arbitrateFee > 0) {
            _transfer(trade.token, trade.user.guarantor, arbitrateFee);
        }
        if (fee > 0) {
            _transfer(trade.token, trade.user.platform, fee);
        }
        _transfer(trade.token, msg.sender, available.sub(fee));

        // If the remaining available deposit is less than or equal to 0, the transaction ends
        if (
            trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(trade.deposit.withdrawedPenalty).sub(
                trade.deposit.withdrawedDeposit
            ) <= 0
        ) {
            trade.current = trade.times.length;
            trade.deposit.historyPenalty = trade.deposit.withdrawedPenalty;
        }
    }

    /**
     * The buyer can refund the remaining deposit at the end of the transaction
     * @param tid trade id
     */
    function refundDeposit(bytes memory tid) external {
        _refundDeposit(tid, block.timestamp);
    }

    function _refundDeposit(bytes memory tid, uint256 currentTime) internal {
        Trade storage trade = _trades[tid];
        require(trade.user.buyer != address(0), "VIV5005");
        require(trade.user.buyer == msg.sender, "VIV0021");
        require(trade.current == trade.times.length, "VIV5507");

        uint256 totalPenalty = _getTotalPenalty(trade, currentTime);
        uint256 canWithdraw = trade.deposit.deposit.add(trade.deposit.completedDeposit).sub(totalPenalty).sub(
            trade.deposit.withdrawedDeposit
        );
        trade.deposit.withdrawedDeposit = trade.deposit.withdrawedDeposit.add(canWithdraw);
        require(canWithdraw > 0, "VIV5506");
        _transfer(trade.token, msg.sender, canWithdraw);
    }

    /**
     * Get total penalty
     */
    function _getTotalPenalty(Trade memory trade, uint256 currentTime) private pure returns (uint256 totalPenalty) {
        totalPenalty = trade.deposit.historyPenalty;
        // If the user's repayment time exceeds the repayment date, the user needs to pay penalty interest
        if (trade.current < trade.times.length && currentTime > trade.times[trade.current]) {
            // 3600
            uint256 overdueDays = currentTime.sub(trade.times[trade.current]).div(_INTERNAL_SECONDS);
            uint256 penaltyAmount = overdueDays.mul(trade.deposit.deposit).rate(trade.penaltyRate);
            totalPenalty = totalPenalty.add(penaltyAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * Used to verify that the signature is correct
 */
library SignUtil {
    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue1 signed by one of user1, user2, user3
     * @param signedValue2 signed by one of user1, user2, user3
     * @param user1 user1
     * @param user2 user2
     * @param user3 user3
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue1,
        bytes memory signedValue2,
        address user1,
        address user2,
        address user3
    ) internal pure returns (bool) {
        // if sign1 equals sign2, return false
        if (_compareBytes(signedValue1, signedValue2)) {
            return false;
        }

        // address must be one of user1, user2, user3
        address address1 = ECDSA.recover(hashValue, signedValue1);
        if (address1 != user1 && address1 != user2 && address1 != user3) {
            return false;
        }
        address address2 = ECDSA.recover(hashValue, signedValue2);
        if (address2 != user1 && address2 != user2 && address2 != user3) {
            return false;
        }
        return true;
    }

    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue1 signed by one of user1, user2
     * @param signedValue2 signed by one of user1, user2
     * @param user1 user1
     * @param user2 user2
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue1,
        bytes memory signedValue2,
        address user1,
        address user2
    ) internal pure returns (bool) {
        // if sign1 equals sign2, return false
        if (_compareBytes(signedValue1, signedValue2)) {
            return false;
        }

        // address must be one of user1, user2
        address address1 = ECDSA.recover(hashValue, signedValue1);
        if (address1 != user1 && address1 != user2) {
            return false;
        }
        address address2 = ECDSA.recover(hashValue, signedValue2);
        if (address2 != user1 && address2 != user2) {
            return false;
        }
        return true;
    }

    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue signed by user
     * @param user User to be verified
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue,
        address user
    ) internal pure returns (bool) {
        address signedAddress = ECDSA.recover(hashValue, signedValue);
        if (signedAddress != user) {
            return false;
        }
        return true;
    }

    /**
     * compare bytes
     * @param a param1
     * @param b param2
     */
    function _compareBytes(bytes memory a, bytes memory b) private pure returns (bool) {
        bytes32 s;
        bytes32 d;
        assembly {
            s := mload(add(a, 32))
            d := mload(add(b, 32))
        }
        return (s == d);
    }
}

// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

/**
 * Standard signed math utilities missing in the Solidity language.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * it means: 100*2‱ = 100*2/10000
     */
    function rate(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, b), 10000);
    }
}

// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * Merge transfer functionality of Ethereum and tokens
 */
contract Token is ReentrancyGuard{

    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * Notify When transfer happened
     * @param sender who sender
     * @param receiver who receiver
     * @param value transfer value
     */
    event Transfer(address indexed sender, address indexed receiver, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * Get balance of this contract
     */
    function _balanceOf(address token) internal view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /**
     * allowance (Used for ERC20)
     * @param owner owner
     * @param spender spender
     */
    function _allowance(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256) {
        if (token != address(0)) {
            return IERC20(token).allowance(owner, spender);
        }
        return 0;
    }

    /**
     * Transfer
     * @param to the destination address
     * @param value value of transaction.
     */
    function _transfer(
        address token,
        address to,
        uint256 value
    ) internal nonReentrant() {
        if (token == address(0)) {
            payable(to).sendValue(value);
            emit Transfer(address(this), to, value);
        } else {
            IERC20(token).safeTransfer(to, value);
        }
    }

    /**
     * Transfer form (Used for ERC20)
     * @param from the source address
     * @param to the destination address
     * @param value value of transaction.
     */
    function _transferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (token != address(0)) {
            IERC20(token).safeTransferFrom(from, to, value);
        }
    }

    /**
     * check transfer in
     * @param value value
     */
    function _checkTransferIn(address token, uint256 value) internal {
        __checkTransferIn(token, msg.sender, value);
    }

    function __checkTransferIn(
        address token,
        address owner,
        uint256 value
    ) internal {
        if (token == address(0)) {
            require(msg.value == value, "VIV0002");
        } else {
            require(IERC20(token).balanceOf(owner) >= value, "VIV0003");
            require(_allowance(token, owner, address(this)) >= value, "VIV0004");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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