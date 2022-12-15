// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2022-11-07
 */

/**
 *Submitted for verification at BscScan.com on 2022-02-10
 */

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * To buy AhouZ user must be Whitelisted
 * Add user address and value to Whitelist
 * Remove user address from Whitelist
 * Check if User is Whitelisted
 * Check if User have equal or greater value than Whitelisted
 */

library Whitelist {
    struct List {
        mapping(address => bool) registry;
        mapping(address => uint256) amount;
    }

    function addUserWithValue(
        List storage list,
        address _addr,
        uint256 _value
    ) internal {
        list.registry[_addr] = true;
        list.amount[_addr] = _value;
    }

    function add(List storage list, address _addr) internal {
        list.registry[_addr] = true;
    }

    function remove(List storage list, address _addr) internal {
        list.registry[_addr] = false;
        list.amount[_addr] = 0;
    }

    function check(
        List storage list,
        address _addr
    ) internal view returns (bool) {
        return list.registry[_addr];
    }

    function checkValue(
        List storage list,
        address _addr,
        uint256 _value
    ) internal view returns (bool) {
        /**
         * divided by  10^18 because bnb decimal is 18
         * and conversion to bnb to uint256 is carried out
         */

        return list.amount[_addr] <= _value;
    }
}

contract owned {
    address public owner;

    constructor() {
        owner = 0x19826aFD679a659ef2dA5B26E8998D1675af6a12;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

/**
 * Contract to whitelist User for buying token
 */
contract Whitelisted is owned {
    Whitelist.List private _list;
    uint256 decimals = 100000000000000;
    address public whitelister;

    modifier onlyWhitelisted() {
        require(Whitelist.check(_list, msg.sender) == true);
        _;
    }

    modifier onlyWhitelister() {
        require(msg.sender == whitelister);
        _;
    }

    event AddressAdded(address _addr);
    event AddressRemoved(address _addr);
    event AddressReset(address _addr);

    /**
     * Add User to Whitelist with bnb amount
     * @param _address User Wallet address
     * @param amount The amount of bnb user Whitelisted in wei
     */
    function addWhiteListAddress(
        address _address,
        uint256 amount
    ) public onlyWhitelister {
        require(!isAddressWhiteListed(_address));

        Whitelist.addUserWithValue(_list, _address, amount);

        emit AddressAdded(_address);
    }

    /**
     * Set User's Whitelisted bnb amount to 0 so that
     * during second buy transaction user won't need to
     * validate for Whitelisted amount
     */
    function resetUserWhiteListAmount() internal {
        Whitelist.addUserWithValue(_list, msg.sender, 9999999 ether);
        emit AddressReset(msg.sender);
    }

    /**
     * Disable User from Whitelist so user can't buy token
     * @param _addr User Wallet address
     */
    function disableWhitelistAddress(address _addr) public onlyOwner {
        Whitelist.remove(_list, _addr);
        emit AddressRemoved(_addr);
    }

    /**
     * Check if User is Whitelisted
     * @param _addr User Wallet address
     */
    function isAddressWhiteListed(address _addr) public view returns (bool) {
        return Whitelist.check(_list, _addr);
    }

    /**
     * Check if User has enough bnb amount in Whitelisted to buy token
     * @param _addr User Wallet address
     * @param amount The amount of bnb user inputed
     */
    function isWhiteListedValueValid(
        address _addr,
        uint256 amount
    ) public view returns (bool) {
        return Whitelist.checkValue(_list, _addr, amount);
    }

    /**
     * Check if User is valid to buy token
     * @param _addr User Wallet address
     * @param amount The amount of bnb user inputed
     */
    function isValidUser(
        address _addr,
        uint256 amount
    ) public view returns (bool) {
        return
            isAddressWhiteListed(_addr) &&
            isWhiteListedValueValid(_addr, amount);
    }

    /**
     * returns the total amount of the address hold by the user during white list
     */
    function getUserAmount(address _addr) public view returns (uint256) {
        require(isAddressWhiteListed(_addr));
        return _list.amount[_addr];
    }

    /**
     * change whitelister address
     */
    function transferWhitelister(address newWhitelister) public onlyOwner {
        whitelister = newWhitelister;
    }
}

contract AhouZCrowdsale is Whitelisted {
    using SafeMath for uint256;

    AggregatorV3Interface internal priceFeed;
    address public beneficiary;
    uint256 public SoftCap;
    uint256 public HardCap;
    uint256 public amountRaised;
    uint256[2] public seedSaleDates;
    uint256[2] public privateSale1Dates;
    uint256[2] public privateSale2Dates;
    uint256[2] public publicSaleDates;
    uint256 public fundTransferred;
    uint256 public tokenSold;
    uint256 public tokenSoldWithBonus;
    uint256[4] public price;
    IERC20 public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public crowdsaleClosed = false;
    bool public returnFunds = false;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    // constructor(
    //     address priceFeedAddress,
    //     address beneficiaryAddress,
    //     uint256 softCap,
    //     uint256 hardCap,
    //     uint256[2] memory _seedSaleDates,
    //     uint256[2] memory _privateSale1Dates,
    //     uint256[2] memory _privateSale2Dates,
    //     uint256[2] memory _publicSaleDates,
    //     uint256[4] memory _price,
    //     address tokenRewardAddress
    // )  {
    //     priceFeed = AggregatorV3Interface(
    //         priceFeedAddress
    //     );
    //     beneficiary = beneficiaryAddress;
    //     SoftCap = softCap;
    //     HardCap = hardCap;

    //     seedSaleDates = _seedSaleDates;
    //     privateSale1Dates = _privateSale1Dates;
    //     privateSale2Dates = _privateSale2Dates;
    //     publicSaleDates = _publicSaleDates;

    //     // price should be in 10^18 format.
    //     price = _price;
    //     tokenReward = IERC20(tokenRewardAddress);
    // }

    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        beneficiary = 0x19826aFD679a659ef2dA5B26E8998D1675af6a12;
        SoftCap = 8333 ether;
        HardCap = 25000 ether;
        seedSaleDates = [1666224000, 1671494400];
        privateSale1Dates = [1671494400, 1679270400];
        privateSale2Dates = [1679270400, 1687219200];
        publicSaleDates = [1687219200, 1693267200];
        // price should be in 10^18 format.
        price = [500000000000000, 550000000000000, 600000000000000, 750000000000000];
        tokenReward = IERC20(0x84BCFAD742958fFe118ea9D1C1E1b05D4533C5D9);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    fallback() external payable {
        uint256 bonus = 0;
        uint256 bonusPercent = 0;
        uint256 amount = 0;
        uint256 amountWithBonus = 0;
        uint256 ethamount = msg.value;

        require(!crowdsaleClosed);

        require(isValidUser(msg.sender, ethamount));

        //add bonus for funders
        if (
            block.timestamp >= seedSaleDates[0] &&
            block.timestamp <= seedSaleDates[1]
        ) {
            int priceOfEth = getLatestPrice();
            uint cost = uint256(1 / priceOfEth) * price[0];
            amount = ethamount.div(cost);
            bonusPercent = block.timestamp <=
                ((seedSaleDates[1] - seedSaleDates[0]) / 2 + seedSaleDates[0])
                ? 25
                : 23;
        } else if (
            block.timestamp >= privateSale1Dates[0] &&
            block.timestamp <= privateSale1Dates[1]
        ) {
            int priceOfEth = getLatestPrice();
            uint cost = uint256(1 / priceOfEth) * price[1];
            amount = ethamount.div(cost);
            bonusPercent = block.timestamp <=
                ((privateSale1Dates[1] - privateSale1Dates[0]) /
                    2 +
                    privateSale1Dates[0])
                ? 20
                : 18;
        } else if (
            block.timestamp >= privateSale2Dates[0] &&
            block.timestamp <= privateSale2Dates[1]
        ) {
            int priceOfEth = getLatestPrice();
            uint cost = uint256(1 / priceOfEth) * price[2];
            amount = ethamount.div(cost);
            bonusPercent = block.timestamp <=
                ((privateSale2Dates[1] - privateSale2Dates[0]) /
                    2 +
                    privateSale2Dates[0])
                ? 15
                : 12;
        } else if (
            block.timestamp >= publicSaleDates[0] &&
            block.timestamp <= publicSaleDates[1]
        ) {
            int priceOfEth = getLatestPrice();
            uint cost = uint256(1 / priceOfEth) * price[3];
            amount = ethamount.div(cost);
            bonusPercent = block.timestamp <=
                ((publicSaleDates[1] - publicSaleDates[0]) /
                    2 +
                    publicSaleDates[0])
                ? 10
                : 5;
        }

        bonus = (amount * bonusPercent) / 100;
        amountWithBonus = amount.add(bonus);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(ethamount);
        amountRaised = amountRaised.add(ethamount);

        tokenReward.transfer(msg.sender, amountWithBonus.mul(100000000000000));
        tokenSold = tokenSold.add(amount.mul(100000000000000));
        tokenSoldWithBonus = tokenSoldWithBonus.add(
            amountWithBonus.mul(100000000000000)
        );

        resetUserWhiteListAmount();
        emit FundTransfer(msg.sender, ethamount, true);
    }

    receive() external payable {
        // custom function code
    }

    modifier afterDeadline() {
        if (block.timestamp >= publicSaleDates[1]) _;
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *ends the campaign after deadline
     */

    function endCrowdsale() public afterDeadline onlyOwner {
        crowdsaleClosed = true;
    }

    function EnableReturnFunds() public onlyOwner {
        returnFunds = true;
    }

    function DisableReturnFunds() public onlyOwner {
        returnFunds = false;
    }

    function bonusSent() public view returns (uint256) {
        return tokenSoldWithBonus - tokenSold;
    }

    /**
     * seed sale price
     * private sale 1 price
     * private sale 2 price
     * public sale price
     */
    function ChangeSalePrices(
        uint256 _seed_price,
        uint256 _privatesale1_price,
        uint256 _privatesale2_price,
        uint256 _publicsale_price
    ) public onlyOwner {
        price[0] = _seed_price;
        price[1] = _privatesale1_price;
        price[2] = _privatesale2_price;
        price[3] = _publicsale_price;
    }

    function changeAggregator(address newAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(newAddress);
    }

    function ChangeBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function SeedSaleDates(
        uint256 _seedSaleStartdate,
        uint256 _seedSaleDeadline
    ) public onlyOwner {
        if (_seedSaleStartdate != 0) {
            seedSaleDates[0] = _seedSaleStartdate;
        }
        if (_seedSaleDeadline != 0) {
            seedSaleDates[1] = _seedSaleDeadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale1Dates(
        uint256 _privateSale1Startdate,
        uint256 _privateSale1Deadline
    ) public onlyOwner {
        if (_privateSale1Startdate != 0) {
            privateSale1Dates[0] = _privateSale1Startdate;
        }
        if (_privateSale1Deadline != 0) {
            privateSale1Dates[1] = _privateSale1Deadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale2Dates(
        uint256 _privateSale2Startdate,
        uint256 _privateSale2Deadline
    ) public onlyOwner {
        if (_privateSale2Startdate != 0) {
            privateSale2Dates[0] = _privateSale2Startdate;
        }
        if (_privateSale2Deadline != 0) {
            privateSale2Dates[1] = _privateSale2Deadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    function ChangeMainSaleDates(
        uint256 _mainSaleStartdate,
        uint256 _mainSaleDeadline
    ) public onlyOwner {
        if (_mainSaleStartdate != 0) {
            publicSaleDates[0] = _mainSaleStartdate;
        }
        if (_mainSaleDeadline != 0) {
            publicSaleDates[1] = _mainSaleDeadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    /**
     * Get all the remaining token back from the contract
     */
    function getTokensBack() public onlyOwner {
        require(crowdsaleClosed);

        uint256 remaining = tokenReward.balanceOf(address(this));
        tokenReward.transfer(beneficiary, remaining);
    }

    /**
     * User can get their bnb back if crowdsale didn't meet it's requirement
     */
    function safeWithdrawal() public afterDeadline {
        if (returnFunds) {
            uint256 amount = balanceOf[msg.sender];
            if (amount > 0) {
                if (payable(msg.sender).send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                    balanceOf[msg.sender] = 0;
                    fundTransferred = fundTransferred.add(amount);
                }
            }
        }

        if (returnFunds == false && beneficiary == msg.sender) {
            uint256 ethToSend = amountRaised - fundTransferred;
            if (payable(beneficiary).send(ethToSend)) {
                fundTransferred = fundTransferred.add(ethToSend);
            }
        }
    }
}