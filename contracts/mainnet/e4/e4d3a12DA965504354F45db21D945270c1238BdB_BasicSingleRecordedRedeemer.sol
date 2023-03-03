// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.0;

import {IVoucherToken} from "./interfaces/IVoucherToken.sol";
import {BasicSingleRedeemer} from "./BasicSingleRedeemer.sol";

/**
 * @notice Basic redeemer contract with internal bookkeeping.
 */
contract BasicSingleRecordedRedeemer is BasicSingleRedeemer {
    /**
     * @notice Keeps track of who redeemed which voucher.
     */
    mapping(address => mapping(IVoucherToken => uint256[])) internal
        _redeemedVouchers;

    /**
     * @notice Redeems a voucher and emits an event as proof.
     */
    function redeem(IVoucherToken voucher, uint256 tokenId)
        public
        virtual
        override
    {
        _redeemedVouchers[msg.sender][voucher].push(tokenId);
        super.redeem(voucher, tokenId);
    }

    /**
     * @notice Returns the number of vouchers redeemed by a given address.
     */
    function numVouchersRedeemed(address sender, IVoucherToken voucher)
        public
        view
        returns (uint256)
    {
        return _redeemedVouchers[sender][voucher].length;
    }

    /**
     * @notice Returns the voucher tokenIds redeemed by a given address.
     */
    function redeemedVoucherIds(address sender, IVoucherToken voucher)
        public
        view
        returns (uint256[] memory)
    {
        return _redeemedVouchers[sender][voucher];
    }

    /**
     * @notice  Returns the voucher tokenId redeemed by a given address at a
     * given index.
     */
    function redeemedVoucherIdAt(
        address sender,
        IVoucherToken voucher,
        uint256 idx
    ) public view returns (uint256) {
        return _redeemedVouchers[sender][voucher][idx];
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.0;

import {IVoucherToken} from "./interfaces/IVoucherToken.sol";
import {ISingleRedeemer} from "./interfaces/ISingleRedeemer.sol";

interface BasicSingleRedeemerEvents {
    /**
     * @notice Emitted on redemption.
     */
    event VoucherRedeemed(
        address indexed sender, IVoucherToken indexed voucher, uint256 tokenId
    );
}

/**
 * @notice Basic redeemer contract without any internal bookkeeping.
 */
contract BasicSingleRedeemer is ISingleRedeemer, BasicSingleRedeemerEvents {
    /**
     * @notice Redeems a voucher and emits an event as proof.
     */
    function redeem(IVoucherToken voucher, uint256 tokenId) public virtual {
        emit VoucherRedeemed(msg.sender, voucher, tokenId);
        voucher.redeem(msg.sender, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.0;

import {IVoucherToken} from "./IVoucherToken.sol";

/**
 * @notice Interface for a contract that should allow users to redeem a given
 * voucher token.
 */
interface ISingleRedeemer {
    /**
     * @notice Redeems a given voucher.
     * @dev This MUST inform the voucher contract about the redemption by
     * calling its `redeem` method.
     */
    function redeem(IVoucherToken token, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.0;

/**
 * @notice Interface for a redeemable Voucher token preventing double spending
 * through internal book-keeping (e.g. burning the token, token property, etc.).
 * @dev Voucher tokens are intendent to be redeemed through a redeemer contract.
 */
interface IVoucherToken {
    /**
     * @notice Thrown if the redemption caller is not allowed to spend a given
     * voucher.
     */
    error RedeemerCallerNotAllowedToSpendVoucher(
        address sender, uint256 tokenId
    );

    /**
     * @notice Thrown if a redeemer contract is not allowed to redeem this
     * voucher.
     */
    error RedeemerNotApproved(address);

    /**
     * @notice Interface through which a `IRedeemer` contract informs the
     * voucher about its redemption.
     * @param sender The address that initiate the redemption on the
     * redeemer contract.
     * @param tokenId The voucher token to be redeemed.
     * @dev This function MUST be called by redeemer contracts.
     * @dev MUST revert with `RedeemerNotApproved` if the calling redeemer
     * contract is not approved to spend this voucher.
     * @dev MUST revert with `RedeemerCallerNotAllowedToSpendVoucher` if
     * sender is not allowed to spend tokenId.
     */
    function redeem(address sender, uint256 tokenId) external;
}