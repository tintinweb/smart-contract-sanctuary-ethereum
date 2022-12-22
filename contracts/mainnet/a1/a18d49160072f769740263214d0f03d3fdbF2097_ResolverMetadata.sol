// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@1inch/erc20-pods/contracts/interfaces/IERC20Pods.sol";

interface IDelegatedShare is IERC20Pods {
    function addDefaultFarmIfNeeded(address account, address farm) external; // onlyOwner
    function mint(address account, uint256 amount) external; // onlyOwner
    function burn(address account, uint256 amount) external; // onlyOwner
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/erc20-pods/contracts/interfaces/IPod.sol";

interface IDelegationPod is IPod, IERC20 {
    event Delegated(address account, address delegatee);

    function delegated(address delegator) external view returns(address delegatee);
    function delegate(address delegatee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDelegationPod.sol";
import "./IDelegatedShare.sol";

interface ITokenizedDelegationPod is IDelegationPod {
    event RegisterDelegatee(address delegatee);

    function register(string memory name, string memory symbol) external returns(IDelegatedShare shareToken);
    function registration(address account) external returns(IDelegatedShare shareToken);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Pods is IERC20 {
    event PodAdded(address account, address pod);
    event PodRemoved(address account, address pod);

    function hasPod(address account, address pod) external view returns(bool);
    function podsCount(address account) external view returns(uint256);
    function podAt(address account, uint256 index) external view returns(address);
    function pods(address account) external view returns(address[] memory);
    function podBalanceOf(address pod, address account) external view returns(uint256);

    function addPod(address pod) external;
    function removePod(address pod) external;
    function removeAllPods() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPod {
    function updateBalances(address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/delegating/contracts/interfaces/ITokenizedDelegationPod.sol";

contract ResolverMetadata {
    error NotRegisteredDelegatee();

    ITokenizedDelegationPod public immutable delegation;
    mapping (address => string) public getUrl;

    modifier onlyRegistered {
        if (address(delegation.registration(msg.sender)) == address(0)) revert NotRegisteredDelegatee();
        _;
    }

    constructor(ITokenizedDelegationPod delegation_) {
        delegation = delegation_;
    }

    function setResolverUrl(string calldata url) external onlyRegistered {
        getUrl[msg.sender] = url;
    }
}