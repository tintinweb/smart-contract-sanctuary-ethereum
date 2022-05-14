/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Ducia_v1.sol

contract Ducia_v1 is Ownable {
    mapping(address => uint256) public reputation;
    mapping(address => uint256) public reputation_retrievable;

    mapping(string => mapping(address => bool)) public votes;
    mapping(string => mapping(address => bool)) public has_voted;

    mapping(string => user_and_vote[]) public reference_reports;

    mapping(string => uint256) public yes_reference_reports;

    mapping(string => bool) public content_exists;

    mapping(string => validation_tracker) public vote_tracker;

    string[] public content;

    uint256 public num_reference_reports;

    struct user_and_vote {
        address user;
        bool vote;
    }

    struct validation_tracker {
        uint256 number_votes;
        uint256 yes_votes;
        uint256 no_votes;
    }

    IERC20 public reptoken;
    IERC20 public posttoken;

    constructor(address reptoken_address, address posttoken_address) {
        reptoken = IERC20(reptoken_address);
        posttoken = IERC20(posttoken_address);
        num_reference_reports = 3;
    }

    function give_post_tokens(address _user, uint256 _amount) public {
        posttoken.transferFrom(msg.sender, _user, _amount);
    }

    function get_rep_tokens(address _user) public {
        require(
            reputation_retrievable[_user] > 0,
            "No Rep Tokens to be retrieved!"
        );
        uint256 amount = reputation_retrievable[_user];
        reputation_retrievable[_user] = 0;
        reptoken.transferFrom(msg.sender, _user, amount);
    }

    function get_user_rep_tokens(address _user) public view returns (uint256) {
        return reptoken.balanceOf(_user);
    }

    function get_user_post_tokens(address _user) public view returns (uint256) {
        return posttoken.balanceOf(_user);
    }

    function get_current_voting_stats(string memory _content_id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 number_votes = vote_tracker[_content_id].number_votes;
        uint256 yes_votes = vote_tracker[_content_id].yes_votes;
        uint256 no_votes = vote_tracker[_content_id].no_votes;
        return (number_votes, yes_votes, no_votes);
    }

    function get_user_reputation(address _user) public view returns (uint256) {
        return reputation[_user];
    }

    function get_number_reference_reports() public view returns (uint256) {
        return num_reference_reports;
    }

    function vote(string memory _content_id, bool _vote) public {
        require(
            has_voted[_content_id][msg.sender] == false,
            "User has already Voted"
        );
        has_voted[_content_id][msg.sender] = true;
        votes[_content_id][msg.sender] = _vote;
        validation_tracker memory current_validation_tracker = vote_tracker[
            _content_id
        ];
        current_validation_tracker.number_votes += 1;
        if (_vote == true) {
            current_validation_tracker.yes_votes += 1;
        } else {
            current_validation_tracker.no_votes += 1;
        }
        vote_tracker[_content_id] = current_validation_tracker;

        user_and_vote[] storage user_and_vote_array = reference_reports[
            _content_id
        ];

        if (user_and_vote_array.length == num_reference_reports) {
            address user_to_be_rewarded = user_and_vote_array[0].user;
            if (user_and_vote_array[0].vote == true && _vote == false) {
                yes_reference_reports[_content_id]--;
            } else if (user_and_vote_array[0].vote != _vote) {
                yes_reference_reports[_content_id]++;
            }

            for (uint256 i = 0; i < user_and_vote_array.length - 1; i++) {
                user_and_vote_array[i] = user_and_vote_array[i + 1];
            }
            uint256 reward = calculate_reward(
                yes_reference_reports[_content_id],
                _vote,
                current_validation_tracker
            );
            assign_reward(reward, user_to_be_rewarded);
            user_and_vote_array[user_and_vote_array.length - 1] = user_and_vote(
                msg.sender,
                _vote
            );
        } else {
            if (_vote == true) {
                yes_reference_reports[_content_id]++;
            }
            user_and_vote_array.push(user_and_vote(msg.sender, _vote));
        }
    }

    function assign_reward(uint256 _amount, address _user) internal {
        reputation[_user] += _amount;
        reputation_retrievable[_user] += _amount;
    }

    function calculate_reward(
        uint256 _yes_reports,
        bool _vote,
        validation_tracker memory _current_validation_tracker
    ) internal view returns (uint256) {
        uint256 _yes_votes = _current_validation_tracker.yes_votes + 1;
        uint256 _no_votes = _current_validation_tracker.no_votes + 1;
        if (_vote == false) {
            uint256 amount = (10**18 *
                _yes_votes *
                (num_reference_reports - _yes_reports)) /
                (num_reference_reports * (_yes_votes + _no_votes));
            return amount;
        } else {
            uint256 amount = (10**18 * _no_votes * _yes_reports) /
                (num_reference_reports * (_yes_votes + _no_votes));
            return amount;
        }
    }

    function check_content_exists(string memory _content_id)
        public
        view
        returns (bool)
    {
        return content_exists[_content_id];
    }

    function submit_content(string memory _content_id) public {
        require(
            posttoken.balanceOf(msg.sender) >= 10**18,
            "Not enough Ducia Post Tokens!"
        );
        posttoken.transferFrom(msg.sender, address(this), 10**18);
        require(
            content_exists[_content_id] == false,
            "Same content has already been submitted!"
        );
        content_exists[_content_id] = true;
        content.push(_content_id);
    }

    function get_content() public view returns (string[] memory) {
        return content;
    }
}