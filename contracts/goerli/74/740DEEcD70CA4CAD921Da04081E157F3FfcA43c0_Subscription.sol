//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface iUSDc {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

interface iDai {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

interface iUSDt {
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address who) external view returns (uint);
}

interface iSuperFluid {
    function createFlow(address token, address sender, address receiver, int96 flowrate, bytes memory userData) external returns (bool);
    function deleteFlow(address token, address sender, address receiver, bytes memory userData) external returns (bool);
    function updateFlow(address token, address sender, address receiver, int96 flowrate, bytes memory userData) external returns (bool);
    function getFlowrate(address token, address sender, address receiver) external view returns(int96); 
}

interface iUSDcx {
    function realtimeBalanceOfNow(address account) external view returns (int256);
    function balanceOf(address account) external view returns (uint);
    function transferFrom(address holder, address recipient, uint256 amount) external;
}

interface iDaix {
    function realtimeBalanceOfNow(address account) external view returns (int256);
    function balanceOf(address account) external view returns (uint);
    function transferFrom(address holder, address recipient, uint256 amount) external;
}

interface iUSDtx {
    function realtimeBalanceOfNow(address account) external view returns (int256);
    function balanceOf(address account) external view returns (uint);
    function transferFrom(address holder, address recipient, uint256 amount) external;
}

contract Subscription {
    using SafeMath for uint256;
    uint256 public numSubscriptionLevels;

    // boolean values
    bool public renewalsEnabled = true;
    bool public paymentRecurring;
    bool public paymentStreaming;
    bool public USDcAccepted;
    bool public DaiAccepted;
    bool public USDtAccepted;

    // name of company. initialised in constructor
    string public subscriptionName;
    address public owner;

    mapping(uint256 => uint96) public subscriptionPrices;
    //mapping(address => bool) public claimedFreeTrial;

    // stablecoin addresses for RECURRING payments. USDc, Dai and USDt
    iUSDc public USDc;
    iDai public Dai;
    iUSDt public USDt;

    // SuperFluid's contract address
    iSuperFluid public superFluid;

    // stablecoins addresses for STREAMING payments. USDc and Dai support only
    iUSDcx public USDcx;
    iDaix public Daix;
    iUSDtx public USDtx;

    // expiryTime -> determines whether user's subscription is still valid
    // subscriptionLevel -> determines the features user can access on FE
    mapping(address => uint256) public expiryTime;
    mapping(address => uint256) public userSubscriptionLevel;

    event renewedRecurring(address _addr, uint256 _expiryTime, uint256 _level);
    event renewedStreaming(address _addr, uint256 _level);
    event cancelledSubscription(address _addr);

    modifier onlyOwner() {
        require(owner == msg.sender, "you are not the owner");
        _;
    }

    constructor(uint96[] memory _price, string memory _name, address _owner, bool _USDc, bool _Dai, bool _USDt, bool _recurring, bool _streaming) {
        for(uint256 i; i < _price.length; i++){
            subscriptionPrices[i] = _price[i] * 1e18; // ether unit conversion for easier use
        }
        numSubscriptionLevels = _price.length;
        subscriptionName = _name;
        owner = _owner;
        USDcAccepted = _USDc;
        DaiAccepted = _Dai;
        USDtAccepted = _USDt;
        paymentRecurring = _recurring;
        paymentStreaming = _streaming;

        // TODO
        // initialising addresses of the stablecoins. All addresses currently are for the goerli testnet. 
        USDc = iUSDc(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        Dai = iDai(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);
        USDt = iUSDt(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844);

        superFluid = iSuperFluid(0xcfA132E353cB4E398080B9700609bb008eceB125);

        USDcx = iUSDcx(0x8aE68021f6170E5a766bE613cEA0d75236ECCa9a);
        Daix = iDaix(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00);
        USDtx = iUSDtx(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00);
    }

    // NEED to call grantPermissions first on FE, for the superfluid contract.
    // there is already an in-built buffer deposit upon creating a stream
    function renewalFlow(address _sender, uint256 _stablesId, uint256 _level, bytes memory _data) public {
        require(renewalsEnabled, "Renewals are currently disabled");
        require(paymentStreaming, "not accepting streaming payemnts");
        require(_stablesId <= 2, "not an accepted stablecoin");
        require(_level < numSubscriptionLevels);

        // uses int96 as a param, as specificed by the superfluid contract
        // rate is in wei per second. 30 days = 86400s * 30 days
        int96 _rate = int96(subscriptionPrices[_level] / (2.592e6));

        // TODO
        if (_stablesId == 0) {
            //usdcx
            require(USDcAccepted, "usdc not accepted");
            superFluid.createFlow(0x8aE68021f6170E5a766bE613cEA0d75236ECCa9a, _sender, address(this), _rate, _data);
        } else if (_stablesId == 1) {
            //daix
            require(DaiAccepted, "dai not accepted");
            superFluid.createFlow(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00, _sender, address(this), _rate, _data);
        } else {
            //usdtx
            require(USDtAccepted, "usdt not accepted");
            superFluid.createFlow(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00, _sender, address(this), _rate, _data);
        }

        userSubscriptionLevel[_sender] = _level;
        emit renewedStreaming(_sender, _level);
    }

    function stopSubscription(address _sender, uint256 _stablesId, bytes memory _data) public {
        require(_sender == msg.sender, "you are not this streams owner!");
        require(_stablesId <= 2, "not an accepted stablecoin");

        // TODO
        if (_stablesId == 0) {
            //usdcx
            superFluid.deleteFlow(0x8aE68021f6170E5a766bE613cEA0d75236ECCa9a, _sender, address(this), _data);
        } else if (_stablesId ==1) {
            //daix
            superFluid.deleteFlow(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00, _sender, address(this), _data);
        } else {
            //usdtx
            superFluid.deleteFlow(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00, _sender, address(this), _data);
        }

        emit cancelledSubscription(_sender);
    }

    // need to approve from FE first. _stablesId refers to which stablecoin is used for payment
    function renewalMonthly(address _addr, uint256 _stablesId, uint256 _level) public {
        require(renewalsEnabled, "Renewals are currently disabled");
        require(paymentRecurring, "not accepting recurring monthly payments");
        require(_stablesId <= 2, "not an accepted stablecoin");
        require(_level < numSubscriptionLevels);
        uint256 _currentexpiryTime = expiryTime[_addr];

        if (_stablesId == 0) {
            //usdc
            require(USDcAccepted, "usdc not accepted");
            require(USDc.balanceOf(msg.sender) >= (subscriptionPrices[_level]/1e12)); //dividing by 1e12 as usdc uses 1e6
            USDc.transferFrom(msg.sender, address(this), (subscriptionPrices[_level]/1e12));
        } else if (_stablesId == 1) {
            //dai
            require(DaiAccepted, "dai not accepted");
            require(Dai.balanceOf(msg.sender) >= subscriptionPrices[_level]);
            Dai.transferFrom(msg.sender, address(this), subscriptionPrices[_level]);
        } else {
            //usdt
            require(USDtAccepted, "usdt not accepted");
            require(USDt.balanceOf(msg.sender) >= subscriptionPrices[_level]);
            USDt.transferFrom(msg.sender, address(this), subscriptionPrices[_level]);
        }

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_addr] = block.timestamp + 30 days;
        } else {
            expiryTime[_addr] += 30 days;
        }

        userSubscriptionLevel[_addr] = _level;
        emit renewedRecurring(_addr, expiryTime[_addr], _level);
    }

    // // for users to claim free trial, but horrible as they can just create new wallets easily.
    // function freeTrial() public {
    //     require(claimedFreeTrial[msg.sender] == false, "You have already claimed your free trial");
    //     expiryTime[msg.sender] = block.timestamp + 30 days;
    //     claimedFreeTrial[msg.sender] = true;
    // }

    // // renewal via eth. may not be ideal due to continuous price fluctuations.
    // // fixed price would work best, else the use of oracles to get eth/usd is required.
    // // since this is payable by eth, no approval is needed.
    // function renewalEth(address _addr, uint256 _level) public payable{
    //     require(paymentRecurring, "not accepting recurring monthly payments");
    //     require(msg.value >= subscriptionPrices[_level], "Incorrect amount of ether sent.");
    //     require(_level < numSubscriptionLevels);
    //     require(renewalsEnabled, "Renewals are currently disabled");

    //     uint256 _currentexpiryTime = expiryTime[_addr];

    //     if (block.timestamp > _currentexpiryTime) {
    //         expiryTime[_addr] = block.timestamp + 30 days;
    //     } else {
    //         expiryTime[_addr] += 30 days;
    //     }

    //     userSubscriptionLevel[_addr] = _level;
    //     emit renewedRecurring(_addr, expiryTime[_addr], _level);
    // }

    // Checks if user is still paying/ paid for subscription. True if expired, false else.
    function userSubscriptionInfo(address _user) public view returns(bool expired, uint256 level) {
        bool expiredRecurring = block.timestamp > expiryTime[_user];
        bool expiredStreamingUSDcx = getUserFlowRateUSDcx(_user) <= 0;
        bool expiredStreamingDaix = getUserFlowRateDaix(_user) <= 0;
        bool expiredStreamingUSDtx = getUserFlowRateUSDtx(_user) <= 0;
        expired = expiredRecurring && expiredStreamingUSDcx && expiredStreamingDaix && expiredStreamingUSDtx;
        level = userSubscriptionLevel[_user];
    }

    //TODO
    function getUserFlowRateUSDcx(address _addr) internal view returns (int256) {
        return superFluid.getFlowrate(0x8aE68021f6170E5a766bE613cEA0d75236ECCa9a, _addr, address(this));
    }

    function getUserFlowRateDaix(address _addr) internal view returns (int256) {
        return superFluid.getFlowrate(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00, _addr, address(this));
    }

    function getUserFlowRateUSDtx(address _addr) internal view returns (int256) {
        return superFluid.getFlowrate(0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00, _addr, address(this));
    }

    //ADMIN FUNCTIONS//

    // main function REQUIRED for SuperFluid FE integration
    function getDetails() public view returns(uint256[] memory) {
        uint256[] memory detailList = new uint256[](7);
        detailList[0] = uint256(USDc.balanceOf(address(this)));
        detailList[1] = uint256(Dai.balanceOf(address(this)));
        detailList[2] = uint256(USDt.balanceOf(address(this)));
        detailList[3] = uint256(USDcx.balanceOf(address(this)));
        detailList[4] = uint256(Daix.balanceOf(address(this)));
        detailList[5] = uint256(USDtx.balanceOf(address(this)));

        //total sum
        detailList[6] = detailList[0]+detailList[1]+detailList[2]+detailList[3]+detailList[4]+detailList[5];
        return detailList;
    }

    function renewalAdmin(address _addr, uint256 _level, uint256 _days) public onlyOwner {
        require(_level < numSubscriptionLevels);
        uint256 _currentexpiryTime = expiryTime[_addr];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_addr] = block.timestamp + _days * 1 days;
        } else {
            expiryTime[_addr] += _days * 1 days;
        }

        userSubscriptionLevel[_addr] = _level;
        emit renewedRecurring(_addr, expiryTime[_addr], _level); 
    }

    function toggleRenewalsActive(bool _state) external onlyOwner {
        renewalsEnabled = _state;
    }

    // to counter inflation
    function updateSubscriptionPrice(uint96[] memory _newPrices) external onlyOwner {
        for(uint256 i; i < _newPrices.length; i++){
            subscriptionPrices[i] = _newPrices[i] * 1e18;
        }
        numSubscriptionLevels = _newPrices.length;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new owner cannot be zero address");
        owner = newOwner;    
    }

    // draining the contract of all cryptos
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = (msg.sender).call{value: balance}("");
        if (USDc.balanceOf(address(this)) > 0) {
            USDc.transferFrom(address(this), msg.sender, USDc.balanceOf(address(this)));
        }
        if (Dai.balanceOf(address(this)) > 0) {
            Dai.transferFrom(address(this), msg.sender, Dai.balanceOf(address(this)));
        }
        if (USDt.balanceOf(address(this)) > 0) {
            USDt.transferFrom(address(this), msg.sender, USDt.balanceOf(address(this)));
        }
        if (USDcx.balanceOf(address(this)) > 0) {
            USDcx.transferFrom(address(this), msg.sender, USDcx.balanceOf(address(this)));
        }
        if (Daix.balanceOf(address(this)) > 0) {
            Daix.transferFrom(address(this), msg.sender, Daix.balanceOf(address(this)));
        }
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}