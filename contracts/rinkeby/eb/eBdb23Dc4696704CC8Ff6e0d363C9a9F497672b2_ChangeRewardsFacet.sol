// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "../libraries/LibDCO2Storage.sol";
import "../libraries/LibOwnership.sol";

contract ChangeRewardsFacet {
    function changeRewardsAddress(address _rewards) public {
        LibOwnership.enforceIsContractOwner();

        LibDCO2Storage.Storage storage ds = LibDCO2Storage.dco2Storage();
        ds.rewards = IRewards(_rewards);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IRewards.sol";

library LibDCO2Storage {
    bytes32 constant STORAGE_POSITION = keccak256("com.decarb.dco2.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    struct Storage {
        bool initialized;
        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;
        // array of DCO2 staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] dco2StakedHistory;
        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;
        IERC20 dco2;
        IRewards rewards;
    }

    function dco2Storage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./LibDiamondStorage.sol";

library LibOwnership {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            .diamondStorage();

        address previousOwner = ds.contractOwner;
        require(
            previousOwner != _newOwner,
            "Previous owner and new owner must be different"
        );

        ds.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamondStorage.diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == LibDiamondStorage.diamondStorage().contractOwner,
            "Must be contract owner"
        );
    }

    modifier onlyOwner() {
        require(
            msg.sender == LibDiamondStorage.diamondStorage().contractOwner,
            "Must be contract owner"
        );
        _;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IRewards {
    function registerUserAction(address user) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

library LibDiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;
        // ERC165
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}