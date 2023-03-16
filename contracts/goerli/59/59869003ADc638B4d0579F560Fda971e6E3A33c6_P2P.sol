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

interface Token {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

struct Proposal {
    uint256 id;
    address proposer;
    address token1;
    uint256 amount1;
    address token2;
    uint256 amount2;
    bool isClosed;
}

contract P2P {
    // events
    event OpenProposal(
        uint256 id,
        address proposer,
        address _token1,
        uint256 _amount1,
        address _token2,
        uint256 _amount2
    );
    event CloseProposal(address proposer, uint pId);
    event CancelProposal(address proposer, uint pId);

    uint256 id;
    mapping(address => mapping(uint256 => Proposal)) public proposals;
    Proposal[] public proposalsArr;

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
        Proposal memory prp = Proposal(
            id,
            caller,
            _token1,
            _amount1,
            _token2,
            _amount2,
            false
        );
        proposals[caller][id] = prp;

        // Finally push the new proposal
        proposalsArr.push(prp);

        emit OpenProposal(id++, caller, _token1, _amount1, _token2, _amount2);
    }

    // Before calling this function, the caller has to call the
    // approve(spender, amount) on the token2 contract
    // where `spender` should be this contract's address and `amount` should be >= amount2
    function close(address proposer, uint256 pId) external {
        require(proposer != address(0), "proposer is zero");

        // the change will not reflect on the mapping with `memory`
        Proposal storage proposal = proposals[proposer][pId];

        require(
            proposal.proposer != msg.sender,
            "can't close your own proposal"
        );
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

        for (uint256 i = 0; i < proposalsArr.length; i++) {
            if (proposalsArr[i].id == proposal.id) {
                proposalsArr[i].isClosed = true;
                break;
            }
        }

        emit CloseProposal(proposer, pId);
    }

    // This will close a swap proposal of the caller
    // And return the tokens to the caller
    function cancel(uint256 pId) external {
        address caller = msg.sender;

        Proposal storage proposal = proposals[caller][pId];

        proposal.isClosed = true;

        for (uint256 i = 0; i < proposalsArr.length; i++) {
            if (proposalsArr[i].id == proposal.id) {
                proposalsArr[i].isClosed = true;
                break;
            }
        }
        
        // Return the tokens
        IERC20(proposal.token1).transfer(caller, proposal.amount1);

        emit CancelProposal(caller, pId);
    }

    // Will be used to fetch all the proposals
    function getAllProposals() external view returns (Proposal[] memory) {
        return proposalsArr;
    }

    function getTokenDetails(address token)
        external
        view
        returns (string memory name, string memory symbol)
    {
        Token t = Token(token);
        name = t.name();
        symbol = t.symbol();
    }
}
// 0x59869003ADc638B4d0579F560Fda971e6E3A33c6