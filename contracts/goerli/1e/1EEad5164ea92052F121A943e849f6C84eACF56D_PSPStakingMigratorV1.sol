pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./utils/Utils.sol";

interface I_sPSP is IERC20 {
    function leave(uint256 _stakedAmount) external;
    function withdraw(int256 id) external;
    function userVsNextID(address owner) external returns (int256);
}

interface I_stkPSPBpt is IERC20 {
   function redeem(address to, uint256 amount) external;
}

interface I_sePSP is IERC20 {
    function deposit(uint256 amount) external;
}

interface I_sePSP2 is I_sePSP {
    function depositPSPAndEth(uint256 pspAmount, uint256 minBptOut, bytes memory pspPermit) external payable;
    function depositPSPAndWeth(uint256 pspAmount, uint256 wethAmount, uint256 minBptOut, bytes memory pspPermit) external;
}

contract PSPStakingMigratorV1 {
    IERC20 immutable public PSP;
    IERC20 immutable public WETH;

    I_sePSP immutable public sePSP;
    I_sePSP2 immutable public sePSP2;
    
    I_stkPSPBpt immutable public stkPSPBpt;
    IERC20 immutable public BPT;

    I_sPSP[] public SPSPs;

    struct RequestSPSP {
        uint8 index;
        uint256 amount;
        bytes permitData;
    }

    constructor(
        IERC20 _PSP, 
        IERC20 _WETH,
        IERC20 _bpt,
        I_sePSP _sePSP,
        I_sePSP2 _sePSP2,
        I_stkPSPBpt _stkPSPBpt,
        I_sPSP[] memory _SPSPs
    ) {
        PSP = _PSP;
        WETH = _WETH;
        BPT = _bpt;
        
        sePSP = _sePSP;
        sePSP2 = _sePSP2;

        stkPSPBpt = _stkPSPBpt;
        SPSPs = _SPSPs;
    }

    function depositSPSPsForSePSP(RequestSPSP[] calldata reqs) external {
        _unstakeSPSPsAndGetPSP(reqs);

        uint256 pspBalance = PSP.balanceOf(address(this));
        
        PSP.approve(address(this), pspBalance);
        sePSP.deposit(pspBalance);

        // Todo: test invariant sePSP.balanceOf(this) == pspBalance

        sePSP.transfer(msg.sender, pspBalance); // 1:1 between sePSP and PSP
    }

    function depositStkPSPBptForSePSP2(uint256 bptAmount, bytes calldata stkPSPBptPermit) external {
        Utils.permit(stkPSPBpt, stkPSPBptPermit); 

        stkPSPBpt.transferFrom(msg.sender, address(this), bptAmount);
        stkPSPBpt.redeem(msg.sender, bptAmount);
        
        // Todo: test invariant BPT.balanceOf(this) >= bptAmount // warning arbitrary transfer
        
        BPT.approve(address(sePSP2), bptAmount);
        sePSP2.deposit(bptAmount);

        // Todo: test invariant sePSP2.balanceOf(this) == bptAmount

        sePSP2.transfer(msg.sender, bptAmount); // 1:1 between stkPSPBpt, BPT and sePSP2
    }

    // TODO: check reentrancy
    function depositSPSPsAndETHForSePSP2(RequestSPSP[] calldata reqs, uint256 minBptOut) external payable {
        _unstakeSPSPsAndGetPSP(reqs);
        
        uint256 pspAmount = PSP.balanceOf(address(this));
        PSP.approve(address(sePSP2), pspAmount);
        sePSP2.depositPSPAndEth{value: msg.value}(pspAmount, minBptOut, "");
        
        uint256 sePSP2Balance = sePSP2.balanceOf(address(this));

        // Todo: test invariant spsp2_bpt_balance_before - spsp2_bpt_balance_after > 0

        sePSP2.transfer(msg.sender, sePSP2Balance);
    }

    function depositSPSPsAndWETHForSePSP2(RequestSPSP[] calldata reqs, uint256 wethAmount, uint256 minBptOut) external {
        _unstakeSPSPsAndGetPSP(reqs);
        
        uint256 pspAmount = PSP.balanceOf(address(this));
        uint256 wethAmount = WETH.balanceOf(address(this));

        PSP.approve(address(sePSP2), pspAmount);
        WETH.approve(address(sePSP2), wethAmount);
        sePSP2.depositPSPAndWeth(pspAmount, wethAmount, minBptOut, "");

        // Todo: test invariant spsp2_bpt_balance_before - spsp2_bpt_balance_after > 0

        uint256 sePSP2ReceivedAmount = sePSP2.balanceOf(address(this));
        sePSP2.transfer(msg.sender, sePSP2ReceivedAmount);
    }

    function _unstakeSPSPsAndGetPSP(RequestSPSP[] calldata reqs) internal {
        for(uint8 i; i < reqs.length; i++) {
            RequestSPSP memory req = reqs[i];
            I_sPSP sPSP = SPSPs[req.index];

            require(address(sPSP) != address(0), "unknown sPSP address");

            Utils.permit(sPSP, req.permitData);

            sPSP.transferFrom(msg.sender, address(this), req.amount);

            int256 id = sPSP.userVsNextID(address(this));
            sPSP.leave(req.amount);
            sPSP.withdraw(id);
        }
    }
}

pragma solidity 0.8.6;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

library Utils {
    function permit(IERC20 token, bytes memory permit) internal {
         if (permit.length == 32 * 7) {
            (bool success, ) = address(token).call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
       }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
            require(result, "Transfer ETH failed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
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