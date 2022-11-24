// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
pragma solidity >=0.5.15;

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

import "tinlake-auth/auth.sol";

interface TrancheLike {
    function supplyOrder(address usr, uint256 currencyAmount) external;
    function redeemOrder(address usr, uint256 tokenAmount) external;
    function disburse(address usr)
        external
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        );
    function disburse(address usr, uint256 endEpoch)
        external
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        );
    function currency() external view returns (address);
}

interface RestrictedTokenLike {
    function hasMember(address) external view returns (bool);
}

interface EIP2612PermitLike {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

interface DaiPermitLike {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @notice the operator contract is the entry point for a tranche contract
contract Operator is Auth {
    TrancheLike public tranche;
    RestrictedTokenLike public token;

    // Events
    event SupplyOrder(uint256 indexed amount);
    event RedeemOrder(uint256 indexed amount);
    event Depend(bytes32 indexed contractName, address addr);

    constructor(address tranche_) {
        tranche = TrancheLike(tranche_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice sets the dependency to another contract
    /// @param contractName bytes32 The name of the contract
    /// @param addr address of the contract
    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "tranche") tranche = TrancheLike(addr);
        else if (contractName == "token") token = RestrictedTokenLike(addr);
        else revert();
        emit Depend(contractName, addr);
    }

    /// @notice only investors that are on the memberlist can submit supplyOrders
    /// @param amount in currency token to supply
    function supplyOrder(uint256 amount) public {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        tranche.supplyOrder(msg.sender, amount);
        emit SupplyOrder(amount);
    }

    /// @notice only investors that are on the memberlist can submit redeemOrders
    /// @param amount in token to redeem
    function redeemOrder(uint256 amount) public {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        tranche.redeemOrder(msg.sender, amount);
        emit RedeemOrder(amount);
    }

    /// @notice only investors that are on the memberlist can disburse
    /// @return payoutCurrencyAmount amount of currency tokens which has been paid out
    /// @return payoutTokenAmount amount of token which has been paid out
    /// @return remainingSupplyCurrency amount of currency which has been left in the pool
    /// @return remainingRedeemToken amount of token which has been left in the pool
    function disburse()
        external
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        return tranche.disburse(msg.sender);
    }

    /// @notice only investors that are on the memberlist can disburse
    /// @param endEpoch epoch until which the disburse should be executed
    /// in case a total disburse over all epochs would exceed the gas limit
    /// @return payoutCurrencyAmount amount of currency tokens which has been paid out
    /// @return payoutTokenAmount amount of token which has been paid out
    /// @return remainingSupplyCurrency amount of currency which has been left in the pool
    /// @return remainingRedeemToken amount of token which has been left in the pool
    function disburse(uint256 endEpoch)
        external
        returns (
            uint256 payoutCurrencyAmount,
            uint256 payoutTokenAmount,
            uint256 remainingSupplyCurrency,
            uint256 remainingRedeemToken
        )
    {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        return tranche.disburse(msg.sender, endEpoch);
    }

    /// @notice supply order with dai permit functionality (instead of approval pattern)
    /// @param amount in currency token to supply
    /// @param nonce nonce of the permit
    /// @param expiry expiry of the permit
    /// @param v value of the signature
    /// @param r value of the signature
    /// @param s value of the signature
    function supplyOrderWithDaiPermit(uint256 amount, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
        public
    {
        DaiPermitLike(tranche.currency()).permit(msg.sender, address(tranche), nonce, expiry, true, v, r, s);
        supplyOrder(amount);
    }
    /// @notice supply order with the EIP2612 permit standard
    /// @param amount in currency token to supply
    /// @param deadline deadline of the permit
    /// @param v value of the signature
    /// @param r value of the signature
    /// @param s value of the signature

    function supplyOrderWithPermit(uint256 amount, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        EIP2612PermitLike(tranche.currency()).permit(msg.sender, address(tranche), value, deadline, v, r, s);
        supplyOrder(amount);
    }

    /// @notice redeem order with the EIP2612 permit standard
    /// @param amount in token to supply
    /// @param deadline deadline of the permit
    /// @param v value of the signature
    /// @param r value of the signature
    /// @param s value of the signature
    function redeemOrderWithPermit(uint256 amount, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        EIP2612PermitLike(address(token)).permit(msg.sender, address(tranche), value, deadline, v, r, s);
        redeemOrder(amount);
    }
}