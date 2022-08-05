pragma solidity 0.8.6;


import "ReentrancyGuard.sol";
import "Shared.sol";
import "IForwarder.sol";


/**
* @notice   This contract serves as both a router for bundling actions
*           to be automated, along with conditions under which those actions
*           should only be executed under, aswell as a vault for storing ETH
*           to pay the execution fees by Autonomy Network as part of
*           Autonomy's Automation Station. Users can deposit and withdraw
*           funds at any time. This system is designed to be extremely modular
*           where users can use an arbitrary number of conditions with an
*           arbitrary number of calls in an arbitrary order.
* @author   @quantafire (James Key)
*/
contract FundsRouter is ReentrancyGuard, Shared {

    event BalanceChanged(address indexed user, uint newBal);


    // ETH balances to pay for execution fees
    mapping(address => uint) public balances;
    // The Autonomy Registry to send the execution fee to
    address payable public immutable registry;
    // The forwarder used by the Registry to guarantee that calls from it
    // have the correct `user` and `feeAmount` arguments
    IForwarder public immutable regUserFeeVeriForwarder;
    // The forwarder used by this FundsRouter contract to guarantee that
    // calls from it have the correct `user` argument, where the recipient
    // of the call(s) know that the `user` argument is correct
    IForwarder public immutable routerUserVeriForwarder;


    struct FcnData {
        address target;
        bytes callData;
        uint ethForCall;
        bool verifyUser;
    }


    constructor(
        address payable registry_,
        IForwarder regUserFeeVeriForwarder_,
        IForwarder routerUserVeriForwarder_
    ) ReentrancyGuard() {
        registry = registry_;
        regUserFeeVeriForwarder = regUserFeeVeriForwarder_;
        routerUserVeriForwarder = routerUserVeriForwarder_;
    }

    /**
    * @notice   Deposit ETH to fund the execution of requests by `spender`.
    * @param spender    The address that should be credited with the funds.
    */
    function depositETH(address spender) external payable {
        uint newBal = balances[spender] + msg.value;
        balances[spender] = newBal;
        emit BalanceChanged(spender, newBal);
    }

    /**
    * @notice   Withdraw ETH from `msg.sender`'s balance to send to `recipient`.
    * @param recipient  The address to receive the ETH.
    * @param amount The amount of ETH to withdraw.
    */
    function withdrawETH(address payable recipient, uint amount) external nonReentrant {
        uint startBal = balances[msg.sender];
        require(startBal >= amount, "FRouter: not enough funds");

        uint newBal = startBal - amount;
        balances[msg.sender] = newBal;
        recipient.transfer(amount);
        emit BalanceChanged(msg.sender, newBal);
    }

    /**
    * @notice   Forward an arbitrary number of calls. These could be to
    *           contracts that just test a condition, such as time or a price,
    *           or to contracts to execute an action and change the state of
    *           that contract, such as rebalancing a portfolio, or simply
    *           sending ETH. This function takes into account any ETH received
    *           during any of the calls and adds it to `user`'s balance, enabling
    *           requests to be made without any deposited funds if the receiving
    *           contract pays some kind of reward for calling it.
    * @param user   The address of the user who made the request.
    * @param feeAmount  The amount that Autonomy charges to cover the gas cost of
    *                   executing the request each time, plus a small, deterministic
    *                   incentive fee to the bot. Assumed to be denominated in ETH.
    * @param fcnData    An array of FcnData structs to be called in series. Each struct
    *                   specifies everything needed to make each call independently:
    *                    - target - the address to be called
    *                    - callData - the calldata that specifies what function in the target
    *                       should be called (if a contract) along with any input parameters.
    *                    - ethForCall - any ETH that should be sent with the call
    *                    - verifyUser - whether or not the 1st argument of `callData` should
    *                       be guaranteed to be `user`. If `true`, then the call is routed
    *                       through `routerUserVeriForwarder` so that `target` knows it can
    *                       trust the 1st input parameter as correct if
    *                       `msg.sender == routerUserVeriForwarder` from `target`'s perspective.
    *                       The user should make sure that that is true when generating `callData`.
    *                       If `verifyUser` is `false`, the call will just be sent directly from this
    *                       `FundsRouter` contract.
    */
    function forwardCalls(
        address user,
        uint feeAmount,
        FcnData[] calldata fcnData
    ) external nonReentrant returns (bool, bytes memory) {
        require(msg.sender == address(regUserFeeVeriForwarder), "FRouter: not userFeeForw");

        uint userBal = balances[user];
        uint routerStartBal = address(this).balance;
        uint ethSent = 0;

        bool success;
        bytes memory returnData;
        // Iterate through conditions and make sure they're all met
        for (uint i; i < fcnData.length; i++) {
            ethSent += fcnData[i].ethForCall;
            if (fcnData[i].verifyUser) {
                // Ensure that the 1st argument in this call is the user
                require(abi.decode(fcnData[i].callData[4:36], (address)) == user, "FRouter: calldata not user");
                (success, returnData) = routerUserVeriForwarder.forward{value: fcnData[i].ethForCall}(fcnData[i].target, fcnData[i].callData);
            } else {
                (success, returnData) = fcnData[i].target.call{value: fcnData[i].ethForCall}(fcnData[i].callData);
            }

            revertFailedCall(success, returnData);
        }

        uint routerEndBal = address(this).balance;
        // Make sure that funds were siphoned out this contract somehow
        require(routerEndBal + ethSent >= routerStartBal, "FRouter: funds missing");
        uint ethReceivedDuringForwards = routerEndBal + ethSent - routerStartBal;

        // Make sure that the user has enough balance
        // Having both these checks is definitely overkill - need to get rid of 1
        require(userBal + ethReceivedDuringForwards >= ethSent + feeAmount, "FRouter: not enough funds - fee");
        require(userBal + ethReceivedDuringForwards - ethSent - feeAmount == userBal + routerEndBal - routerStartBal - feeAmount, "FRouter: something doesnt add up");
        balances[user] = userBal + ethReceivedDuringForwards - ethSent - feeAmount;

        registry.transfer(feeAmount);
    }

    // Receive ETH from called contracts, perhaps if they have a reward for poking them
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity 0.8.6;


/**
* @title    Shared contract
* @notice   Holds constants and modifiers that are used in multiple contracts
* @dev      It would be nice if this could be a library, but modifiers can't be exported :(
* @author   Quantaf1re (James Key)
*/
abstract contract Shared {
    address constant internal _ADDR_0 = address(0);
    uint constant internal _E_18 = 10**18;

    function revertFailedCall(bool success, bytes memory returnData) internal {
        // Need this if statement because if the call succeeds, the tx will revert
        // with an EVM error because it can't decode 0x00. If a tx fails with no error
        // message, maybe that's a problem? But if it failed without a message then it's
        // gonna be hard to know what went wrong regardless
        if (!success) {
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/d57593c148dad16abe675083464787ca10f789ec/contracts/utils/Address.sol#L210
            if (returnData.length > 0) {
                assembly {
                    let returndata_size := mload(returnData)
                    revert(add(32, returnData), returndata_size)
                }
            } else {
                revert("No error message!");
            }
        }
    }

    /// @dev    Checks that a uint isn't nonzero/empty
    modifier nzUint(uint u) {
        require(u != 0, "Shared: uint input is empty");
        _;
    }

    /// @dev    Checks that a uint array isn't nonzero/empty
    modifier nzUintArr(uint[] calldata arr) {
        require(arr.length > 0, "Shared: uint arr input is empty");
        _;
    }
}

pragma solidity 0.8.6;


interface IForwarder {

    function forward(
        address target,
        bytes calldata callData
    ) external payable returns (bool success, bytes memory returnData);

}