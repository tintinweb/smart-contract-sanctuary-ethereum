/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
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

// IntercessorV1 for a tradable pair like USDC/DAI
contract IntercessorERC20V1 is Ownable, ReentrancyGuard {
    address private _base_token_address;
    address private _term_token_address;
    
    mapping(address => bool) private _allowed_parties;

    // Counterparty cp1 transfers amount_1 of token_1 to cp2;
    // First leg is sent at creation_time and
    // Second leg must be executed before deadline
    struct SltDatum {
        bool exists;
        string trade_id;

        address base_cp;
        uint256 base_amt;
        address base_token;

        address term_cp;
        uint256 term_amt;
        address term_token;
        
        uint256 creation_time;
        uint256 deadline;

        address trigger_address;
        bool settled;
    }

    mapping(string => SltDatum) private _settlements;

    modifier onlyParticipant {
        //require(_allowed_parties[msg.sender], "Participant is not allowed");
        _;
    }

    event ParticipantAddedEvent(address adr);
    event ParticipantRemovedEvent(address adr);
    event TradeEntryCreatedEvent(SltDatum datum);
    event TradeSwapEvent(SltDatum datum);
    
    // constructor(address base_token_address, address term_token_address) {
    //     _base_token_address = base_token_address;
    //     _term_token_address = term_token_address;
    // }

    constructor() {}

    function setBaseToken(address base_token_address) public onlyOwner nonReentrant {
        _base_token_address = base_token_address;
    }

    function setTermToken(address term_token_address) public onlyOwner nonReentrant {
        _term_token_address = term_token_address;
    }

    function add_participant(address participant) public onlyOwner nonReentrant {
        _allowed_parties[participant] = true;
        emit ParticipantAddedEvent(participant);
    }

    function remove_participant(address participant) public onlyOwner nonReentrant {
        _allowed_parties[participant] = false;
    }

    function stl_data(string memory trade_id) public view returns 
        (bool, string memory, address, uint256, address, address, uint256, address, uint256, uint256, address, bool) {
        SltDatum memory datum = _settlements[trade_id];
        return (
            datum.exists, 
            datum.trade_id,
            datum.base_cp,
            datum.base_amt,
            datum.base_token,
            datum.term_cp,
            datum.term_amt,
            datum.term_token,
            datum.creation_time,
            datum.deadline,
            datum.trigger_address,
            datum.settled);
    }

    // todo - eth? https://ethereum.stackexchange.com/questions/56466/wrapping-eth-calling-the-weth-contract
    // https://solidity-by-example.org/payable/
    function trade(
        string memory trade_id, 
        uint256 base_amount, 
        address base_counter_party,
        address base_token_address,
        uint256 term_amount,
        address term_counter_party,
        address term_token_address) public onlyParticipant nonReentrant {
        
        require(msg.sender == base_counter_party || msg.sender == term_counter_party, "Sender and counter parties must match");
        require(_base_token_address == base_token_address, "Base Token Addresses Do Not Match");
        require(_term_token_address == term_token_address, "Term Token Addresses Do Not Match");
        require(base_amount > 0, "Base amount must be > 0");
        require(term_amount > 0, "Term amount must be > 0");

        SltDatum memory sltDatum = _settlements[trade_id];
        
        if (!sltDatum.exists) {
            // console.log("IntercessorV1::trade The first call does not exist - so we simply create the entry");
            uint256 creation_time  = block.timestamp;
            uint256 deadline = creation_time + 1 days; // Move as a property
            sltDatum = SltDatum(
                true, 
                trade_id, 
                base_counter_party, 
                base_amount, 
                base_token_address, 
                term_counter_party, 
                term_amount,
                term_token_address,
                creation_time,
                deadline,
                msg.sender,
                false);
            _settlements[trade_id] = sltDatum;
            emit TradeEntryCreatedEvent(sltDatum);
        } else {
            require(sltDatum.trigger_address != msg.sender, "Wrong sender for the second leg");
            require(sltDatum.settled == false, "Already settled");

            // console.log("IntercessorERC20V1::trade There is an entry.. we need to see if there is a match i.e. all args must match");
            require(sltDatum.base_cp == base_counter_party, "Base Counter Party Mismatch");
            require(sltDatum.base_amt == base_amount, "Base Amount Party Mismatch");
            require(sltDatum.base_token == base_token_address, "Base Token Party Mismatch");

            require(sltDatum.term_cp == term_counter_party, "Term Counter Party Mismatch");
            require(sltDatum.term_amt == term_amount, "Term Amount Party Mismatch");
            require(sltDatum.term_token == term_token_address, "Term Token Party Mismatch");

            uint256 current_time  = block.timestamp;
            require(current_time <= sltDatum.deadline, "Trade Leg Expired");

            // console.log("IntercessorERC20V1::trade All basic checks are good");

            // At this stage - all Trade Data match
            // We will start the checks for the Swaps by starting with Approves, Amount and finally the Swap

            IERC20 base_token = IERC20(base_token_address);
            require(base_token.allowance(base_counter_party, address(this)) >= base_amount, 
                "base_counter_party has not approved enough");
            require(base_token.balanceOf(base_counter_party) >= base_amount, "base_counter_party has inssuficient amount");

            IERC20 term_token = IERC20(term_token_address);
            require(term_token.allowance(term_counter_party, address(this)) >= term_amount, 
                "term_counter_party has not approved enough");
            require(term_token.balanceOf(term_counter_party) >= term_amount, "term_counter_party has insuficient amount");

            // console.log("IntercessorERC20V1::trade Allowances are good");

            // Let's swap
            bool sent = base_token.transferFrom(base_counter_party, term_counter_party, base_amount);
            require(sent, "Issue with sending the base token");

            sent = term_token.transferFrom(term_counter_party, base_counter_party, term_amount);
            require(sent, "Issue with sending the term token");

            sltDatum.settled = true;
            _settlements[trade_id] = sltDatum;
            emit TradeSwapEvent(sltDatum);
        }
    }
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}