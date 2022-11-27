/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

    struct Banner {
        uint256 id;
        address owner;
        address subscriber;
        string subscriberImageUrl;
        string companyName;
        string websiteUrl;
        uint256 subscriptionFee;
        uint256 subscriptionPeriod;
        uint256 subscriptionTimestamp;
        address currentBidUserAddress;
        uint256 currentBidValue;
        string currentBidSubscriberImageUrl;
    }

contract Dads {

    //events
    event BannerMinted(uint256 id, address owner, string companyName, string websiteUrl, uint256 subscriptionFee, uint256 subscriptionPeriod);
    event BannerUpdated(uint256 id, uint256 subscriptionFee, uint256 subscriptionPeriod, string subscriberImageUrl);
    event SubscriptionCreated(uint256 bannerId, address subscriber, string subscriberImageUrl, uint256 subscriptionTimestamp);
    event SubscriptionCanceled(uint256 id, uint256 paidSubscriptionFee);
    event BidCreated(uint256 id, address currentBidUserAddress, uint256 currentBidValue, string currentBidSubscriberImageUrl);

    using SafeMath for uint256;

    uint256 public currentId = 0;

    mapping(address => uint256) private owners;
    mapping(address => uint256) private subscriber;
    mapping(uint256 => Banner) public banners;

    address public developmentWalletAddress;

    uint256 public transactionFeePercent = 5;
    //0.002 ETH
    uint256 public mintFee = 2000000000000000;

    constructor(address _developmentWalletAddress) {
        developmentWalletAddress = _developmentWalletAddress;
    }

    function calculateTransactionFee(uint256 amount) private view returns (uint256) {
        return amount.mul(transactionFeePercent).div(10 ** 2);
    }

    function calculateSubscriptionFeeOnCancelation(uint256 amount, uint256 subscriptionTimestamp, uint256 subscriptionPeriod) private view returns (uint256){
        return amount.mul(block.timestamp - subscriptionTimestamp).div(subscriptionPeriod);
    }

    function mintBanner(string calldata companyName, string calldata websiteUrl, uint256 subscriptionFee, uint256 subscriptionPeriod) payable external {
        require(msg.value >= mintFee, "Not enough funds to mint banner.");
        currentId = currentId.add(1);
        uint256 id = currentId;
        payable(developmentWalletAddress).transfer(msg.value);
        //create new banner and id it to banner and owners map
        banners[id] = Banner(id, msg.sender, address(0x0), "", companyName, websiteUrl, subscriptionFee, subscriptionPeriod, block.timestamp,address(0x0),0,"");
        owners[msg.sender] = id;
        //emit event
        emit BannerMinted(id, msg.sender, companyName, websiteUrl, subscriptionFee, subscriptionPeriod);
    }

    function updateSubscriberImageUrl(uint256 id, string calldata subscriberImageUrl) external {
        require(banners[id].subscriber == msg.sender, "You are not subscribed to this banner.");
        //update
        banners[id].subscriberImageUrl = subscriberImageUrl;
        //emit event
        emit BannerUpdated(id, 0, 0, subscriberImageUrl);
    }

    function updateSubscriptionFee(uint256 id, uint256 subscriptionFee) external {
        require(banners[id].owner == msg.sender, "You are not the owner of this banner.");
        //update
        banners[id].subscriptionFee = subscriptionFee;
        //emit event
        emit BannerUpdated(id, subscriptionFee, 0, "");
    }

    function updateSubscriptionPeriod(uint256 id, uint256 subscriptionPeriod) external {
        require(banners[id].owner == msg.sender, "You are not the owner of this banner.");
        //update
        banners[id].subscriptionPeriod = subscriptionPeriod;
        //emit event
        emit BannerUpdated(id, 0, subscriptionPeriod, "");
    }

    function subscribe(uint256 id, string calldata subscriberImageUrl) payable external {
        require(banners[id].id != 0, "Banner with given id does not exists.");
        require(banners[id].subscriber == address(0x0) || block.timestamp - banners[id].subscriptionTimestamp > banners[id].subscriptionPeriod, "Banner with given id is already taken.");
        require(msg.value >= banners[id].subscriptionFee, "Not enough funds to mint banner.");
        //calculate and collect fee
        uint256 fee = calculateTransactionFee(msg.value);
        payable(developmentWalletAddress).transfer(fee);
        //add subscriber to banner
        banners[id].subscriber = msg.sender;
        banners[id].subscriberImageUrl = subscriberImageUrl;
        banners[id].subscriptionTimestamp = block.timestamp;
        //emit event
        emit SubscriptionCreated(id, msg.sender, subscriberImageUrl, block.timestamp);
    }

    function createBid(uint256 id, string calldata currentBidSubscriberImageUrl) payable external {
        require(banners[id].id != 0, "Banner with given id does not exists.");
        require(banners[id].subscriber == address(0x0) || block.timestamp - banners[id].subscriptionTimestamp > banners[id].subscriptionPeriod, "Banner with given id is already taken.");
        require(msg.value >= banners[id].subscriptionFee && msg.value > banners[id].currentBidValue, "Not enough funds to place bid.");
        //return money to previous bidder
        if(banners[id].currentBidValue > 0){
            payable(banners[id].currentBidUserAddress).transfer(banners[id].currentBidValue);
        }
        //add bid to banner
        banners[id].currentBidUserAddress = msg.sender;
        banners[id].currentBidValue = msg.value;
        banners[id].currentBidSubscriberImageUrl = currentBidSubscriberImageUrl;
        //emit event
        emit BidCreated(id, msg.sender, msg.value,currentBidSubscriberImageUrl);
    }

    function acceptBid(uint256 id) external {
        require(banners[id].owner == msg.sender, "You are not the owner of this banner.");
        require(banners[id].subscriber == address(0x0) || block.timestamp - banners[id].subscriptionTimestamp > banners[id].subscriptionPeriod, "Banner with given id is already taken.");
        //calculate and collect fee
        uint256 fee = calculateTransactionFee(banners[id].currentBidValue);
        payable(developmentWalletAddress).transfer(fee);
        //add subscriber to banner
        banners[id].subscriber = banners[id].currentBidUserAddress;
        banners[id].subscriberImageUrl = banners[id].currentBidSubscriberImageUrl;
        banners[id].subscriptionTimestamp = block.timestamp;
        //reset bid value
        banners[id].currentBidUserAddress = address(0x0);
        banners[id].currentBidValue = 0;
        banners[id].currentBidSubscriberImageUrl = "";
        //emit event
        emit SubscriptionCreated(id, msg.sender, banners[id].subscriberImageUrl, block.timestamp);
    }

    function cancelSubscription(uint256 id) external {
        require(banners[id].id != 0, "Banner with given id does not exists.");
        require(banners[id].subscriber == msg.sender, "You are not subscribed to this banner.");
        //calculate fee and send funds to owner and eventualy subscriber if cancelation is happened before subscription expierie
        uint256 subscriptionFeeSpentUntilNow = calculateSubscriptionFeeOnCancelation(banners[id].subscriptionFee, banners[id].subscriptionTimestamp, banners[id].subscriptionPeriod);
        payable(banners[id].owner).transfer(subscriptionFeeSpentUntilNow);
        payable(banners[id].subscriber).transfer(banners[id].subscriptionFee.sub(subscriptionFeeSpentUntilNow));
        //emit event
        emit SubscriptionCanceled(id, subscriptionFeeSpentUntilNow);
        //remove subscriber and subscription timestamp
        banners[id].subscriber = address(0x0);
        banners[id].subscriberImageUrl = "";
        banners[id].subscriptionTimestamp = 0;
    }
}