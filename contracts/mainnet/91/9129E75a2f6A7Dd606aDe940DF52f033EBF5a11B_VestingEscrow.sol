// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {Auth, Authority} from "@rari-capital/solmate/src/auth/Auth.sol";


interface IVesting {
    function transferLockOwnership(uint256 _lockID, address _newOwner) external;
    function LOCKS(uint _lockID) external view returns (address, uint, uint, uint, uint, uint, address, address);
    function NONCE() external view returns (uint);
}

contract VestingEscrow is Auth {


    uint public purchasePrice = 34.7 ether;
    address public unicryptVesting = address(0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf);
    uint public lockId;
    address public buyer;

    constructor(address buyer_)
    Auth(msg.sender, Authority(address(0))){
        buyer = buyer_;
    }

    function buy() external payable {
        if (buyer != address(0)) {
            require(msg.sender == buyer, "you are not the right purchaser");
        }
        require(msg.value == purchasePrice, "invalid purchase price");
        //no need for owner checks as the following will fail if escrow is not owner
        IVesting(unicryptVesting).transferLockOwnership(lockId, payable(msg.sender));
        owner.call{value:msg.value, gas: gasleft()}("");
    }

    function setPurchasePrice(uint purchasePrice_) requiresAuth external {
        purchasePrice = purchasePrice_;
    }

    function setBuyer(address buyer_) requiresAuth external {
        buyer = buyer_;
    }

    function setLockID(uint newLockID_) requiresAuth external {
        lockId = newLockID_;
    }

    function reclaim() requiresAuth external {
        //no need for owner checks as the following will fail if escrow is not owner
        IVesting(unicryptVesting).transferLockOwnership(lockId, payable(owner));
    }

}