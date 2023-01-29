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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Proposal {
    address token1;
    uint256 amount1;
    address token2;
    uint256 amount2;
    bool isClosed;
}

contract Swap {
    address[] public proposers;
    mapping(address => Proposal[]) public proposals;
    mapping(address => bool) isAdded;

    // Before calling this function, the caller has to call the
    // approve(spender, amount) on the token1 contract
    // where `spender` should be this contract's address and `amount` should be >= amount1
    function open(
        address _token1,
        uint256 _amount1,
        address _token2,
        uint256 _amount2
    ) external {
        // Validating parameters
        require(_token1 != _token2, "both tokens cannot be same");
        require(address(_token1) != address(0), "token is a zero address");
        require(_amount1 > 0 && _amount2 > 0, "amounts cannot be zero");

        address caller = msg.sender;
        // Transfer _amount1 unit of _token1 token from the caller to this contract
        IERC20(_token1).transferFrom(caller, address(this), _amount1);

        // Create a new proposal
        proposals[caller].push(
            Proposal(_token1, _amount1, _token2, _amount2, false)
        );

        // Finally add the caller as a proposer, if he's not already added
        if (!isAdded[caller]) {
            proposers.push(caller);
            isAdded[caller] = true;
        }
    }

    // Before calling this function, the caller has to call the
    // approve(spender, amount) on the token2 contract
    // where `spender` should be this contract's address and `amount` should be >= amount2
    function close(address proposer, uint256 index) external {
        require(proposer != address(0), "proposer is zero");
        require(index < proposals[proposer].length, "invalid index");

        // the change will not reflect on the mapping with `memory`
        Proposal storage proposal = proposals[proposer][index];

        require(!proposal.isClosed, "proposal is closed");

        // Make the transfers
        // Contract -> Closer
        IERC20(proposal.token1).transfer(msg.sender, proposal.amount1);
        // Closer -> proposer
        IERC20(proposal.token2).transferFrom(
            msg.sender,
            proposer,
            proposal.amount2
        );

        // Finally close the proposal
        proposal.isClosed = true;
    }

    // This will close a swap proposal of the caller
    function cancel(uint index) external {
        require(index < proposals[msg.sender].length, "invalid index");

        proposals[msg.sender][index].isClosed = true;
    }

    // Will be used to fetch all the proposals
    function totalProposers() external view returns(uint) {
        return proposers.length;
    }
    function totalProposalsOf(address proposer) external view returns(uint) {
        return proposals[proposer].length;
    }
}