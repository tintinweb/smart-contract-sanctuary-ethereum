// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Owned} from 'solmate/auth/Owned.sol';

interface IFeeCalculator {
	function calculateFee(uint256 amount) external view returns (uint256);
}

contract FeeCalculator is Owned, IFeeCalculator {
	uint256 public constant FEE_PRECISION = 1e18;
	uint256 public fee;

	constructor() Owned(msg.sender) {}

	function calculateFee(uint256 amount) external view returns (uint256) {
		return amount * fee / FEE_PRECISION;
	}

	function setFee(uint256 fee_) external onlyOwner {
		fee = fee_;
	}
}