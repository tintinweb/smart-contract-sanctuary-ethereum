/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}

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
     * by making the `nonReentrant` function external, and making it call a
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

/**
 * Handle stakes and discount plans logic
 */
contract EVEOTCStakes is Owner, ReentrancyGuard {

    // token to be staked
    IERC20 public asset;

    // contract parameters
    uint16 public interest_rate;    // Interest rate for users who lock funds

    // stakes history
    struct Record {
        uint256 from;
        uint256 amount;
        bool    active;
        uint256 plan;
    }

    // Users locked funds
    mapping(address => Record) public ledger;

    // discount plans
    struct Plan {
        uint256 token_amount; // amount of EVE to apply for this plan
        uint8 smart_discount_seller;    // smart trades percentage discount to apply, from 0, to 100
        uint8 smart_discount_buyer;     // smart trades percentage discount to apply, from 0, to 100
        uint8 option_discount_seller;   // option trades percentage discount to apply, from 0, to 100
        uint8 option_discount_buyer;    // option trades percentage discount to apply, from 0, to 100
        uint256 minimum_time; // minimum staking time, in seconds. Blocks the funds until this time
        uint256 discount_duration; // duration of the discount, in seconds, if the staker get this plan
        bool active; // if the plan is active, new stakings with this plan can be done
    }

    // active discount plans
    Plan[] public plans;

    // timestamp of when a discount expire
    mapping(address => uint256) public expiring_discount;

    event StakeStart(address indexed user, uint256 value);
    event StakeEnd(address indexed user, uint256 value, uint256 interest);

    IERC721[] public nfts;
    uint8 public nft_smart_discount;
    uint8 public nft_option_discount;

    /**
     * @param _erc20 token to be staked
     * @param _owner contract owner
     * @param _rate APY
     */
    constructor(IERC20 _erc20, address _owner, uint16 _rate) Owner(_owner) {
        asset = _erc20;
        interest_rate = _rate;
    }

    /**
     *
     * Add staking / discount plans
     *
     * @param _token_amount; amount of EVE to apply for this plan
     * @param _smart_discount_seller; smart trades percentage discount to apply to the seller, from 0, to 100
     * @param _smart_discount_buyer; smart trades percentage discount to apply to the buyer, from 0, to 100
     * @param _option_discount_seller; option trades percentage discount to apply to the seller, from 0, to 100
     * @param _option_discount_buyer; option trades percentage discount to apply to the seller, from 0, to 100
     * @param _minimum_time; minimum staking time, in seconds. Blocks the funds until this time
     * @param _discount_duration; duration of the discount, in seconds, if the staker get this plan
     *
     */ 
    function addPlan(
        uint256 _token_amount, 
        uint8 _smart_discount_seller, 
        uint8 _smart_discount_buyer, 
        uint8 _option_discount_seller, 
        uint8 _option_discount_buyer, 
        uint256 _minimum_time, 
        uint256 _discount_duration
    ) external isOwner {
        require(_token_amount > 0, "Minimum amount has to be greater than 0");
        require(_smart_discount_seller <= 100, "Discount has to be equal or lower than 100");
        require(_smart_discount_buyer <= 100, "Discount has to be equal or lower than 100");
        require(_option_discount_seller <= 100, "Discount has to be equal or lower than 100");
        require(_option_discount_buyer <= 100, "Discount has to be equal or lower than 100");
        plans.push(Plan(_token_amount, _smart_discount_seller, _smart_discount_buyer, _option_discount_seller, _option_discount_buyer, _minimum_time, _discount_duration, true));
    }

    /**
     *
     * Change Plan Amount
     *
     * @param _i; plan index
     * @param _token_amount; amount of EVE to apply for this plan
     *
     */ 
    function changePlan(uint256 _i, uint256 _token_amount) external isOwner {
        require(_token_amount > 0, "Minimum amount has to be greater than 0");
        plans[_i].token_amount = _token_amount;
    }

    /**
     * Plans are not deleted, they are deactivate to avoid inconsistency in already created stakes 
     */ 
    function deactivatePlan(uint256 _i) external isOwner {
        plans[_i].active = false;
    }

    /**
     * length of plans
     */ 
    function plans_length() external view returns (uint256) {
        return plans.length;
    }

    /**
     * Lock funds based on an existing active plan
     * @param _plan the selected plan index
     */
    function startLock(uint256 _plan) external nonReentrant {

        require(!ledger[msg.sender].active, "The user already has locked funds");
        require(asset.transferFrom(msg.sender, address(this), plans[_plan].token_amount));
        require(plans[_plan].active, "Plan is not active");
        
        ledger[msg.sender] = Record(block.timestamp, plans[_plan].token_amount, true, _plan);
        
        // replace expiring time
        expiring_discount[msg.sender] = block.timestamp + plans[_plan].discount_duration;
        
        emit StakeStart(msg.sender, plans[_plan].token_amount);

    }

    /**
     * Unlock user funds, and pay the interest if any
     */
    function endLock() external nonReentrant {

        require(ledger[msg.sender].active, "No locked funds found");
        
        uint256 _minimum_time = plans[ledger[msg.sender].plan].minimum_time;

        uint256 _record_seconds = block.timestamp - ledger[msg.sender].from;
        require(_record_seconds > _minimum_time, "The funds cannot be unlocked yet");

        uint256 _interest = get_gains(msg.sender);

        // check that the owner have to / can pay interest before trying to pay
        if (_interest > 0) {
            if (asset.allowance(getOwner(), address(this)) >= _interest && asset.balanceOf(getOwner()) >= _interest) {
                require(asset.transferFrom(getOwner(), msg.sender, _interest));
            } else {
                _interest = 0;
            }
        }

        // return funds
        require(asset.transfer(msg.sender, ledger[msg.sender].amount));

        // close the stake
        ledger[msg.sender].amount = 0;
        ledger[msg.sender].active = false;
        
        // throw event
        emit StakeEnd(msg.sender, ledger[msg.sender].amount, _interest);

    }

    /**
     * Returns the smart trades discount based on the staking state and plan selected
     * Also NFT discount is applied (and prioritized) if the user have NFT balance
     * @param user user account to be queried
     */
    function getSmartDiscount(address user) external view returns (uint8 _discount_seller, uint8 _discount_buyer) {
        if (nft_smart_discount > 0) {
            for (uint256 index = 0; index < nfts.length; index++) {
                if (nfts[index].balanceOf(user) > 0) {
                    return (nft_smart_discount, nft_smart_discount);
                }
            }
        } else {
            if (ledger[user].active) {
                if (expiring_discount[user] > block.timestamp) {
                    return (plans[ledger[user].plan].smart_discount_seller, plans[ledger[user].plan].smart_discount_buyer);
                } else {
                    return (0, 0);
                }
            } else {
                return (0, 0);
            }
        }
    }

    /**
     * Returns the option trades discount based on the staking state and plan selected
     * Also NFT discount is applied (and prioritized) if the user have NFT balance
     * @param user user account to be queried
     */
    function getOptionDiscount(address user) external view returns (uint8 _discount_seller, uint8 _discount_buyer) {
        if (nft_option_discount > 0) {
            for (uint256 index = 0; index < nfts.length; index++) {
                if (nfts[index].balanceOf(user) > 0) {
                    return (nft_option_discount, nft_option_discount);
                }
            }
        } else {
            if (ledger[user].active) {
                if (expiring_discount[user] > block.timestamp) {
                    return (plans[ledger[user].plan].option_discount_seller, plans[ledger[user].plan].option_discount_buyer);
                } else {
                    return (0, 0);
                }
            } else {
                return (0, 0);
            }
        }
    }

    /**
     * Set staking parameters
     * @param _asset new erc20 token to stake. This should be used just in test or emergency cases given that the older stakes can be lost. Admin should use this responsibly
     * @param _rate new APY
     */
    function stakingSet(IERC20 _asset, uint16 _rate) external isOwner {
        interest_rate = _rate;
        asset = _asset;
    }
    
    /**
     * calculate interest to the current date time
     * @param _address user address to be queried
     */ 
    function get_gains(address _address) public view returns (uint256) {
        uint256 _record_seconds = block.timestamp - ledger[_address].from;
        uint256 _year_seconds = 365*24*60*60;
        return _record_seconds * ledger[_address].amount * interest_rate / 100 / _year_seconds;
    }

    /**
     * length of nfts
     */ 
    function nfts_length() external view returns (uint256) {
        return nfts.length;
    }

    /**
     * Add NFT contracts if it does not exist
     * @param _nft IERC721 NFT address
     */
    function addNFT(IERC721 _nft) external isOwner {
        // exists?
        for (uint256 index = 0; index < nfts.length; index++) {
            if (nfts[index] == _nft) return;
        }
        // add it if not
        nfts.push(_nft);
    }

    function removeNFT(uint256 _index) external isOwner {
        nfts[_index] = nfts[nfts.length - 1];
        nfts.pop();
    }

    /**
     * Set NFT Discount
     * @param _smart_discount discount percent for smart trades
     * @param _option_discount discount percent for option trades
     */ 
    function setNFTDiscount(uint8 _smart_discount, uint8 _option_discount) external isOwner {
        require(_smart_discount <= 100, "Smart Trades discount cannot be greater than 100");
        require(_option_discount <= 100, "Option Trades discount cannot be greater than 100");
        nft_smart_discount = _smart_discount;
        nft_option_discount = _option_discount;
    }

}