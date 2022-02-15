// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "../interfaces/IAggregator.sol";
import "../interfaces/IVesting.sol";

contract Ico {
    /*====================================== Structs ================================*/
    struct UserInfo {
        uint8 tier;
        uint256 initialUnlockAmounts;
        uint256 afterCliffUnlockAmounts;
        uint256 maxDollarAmount; // toplam alma hakkı
        uint256 availableSpendAmount; // kalan alma hakkı
        uint256 spentDollarAmount;
        uint256 boughtTokenAmount; // vesting contractında _tokensAllotment olarak geçilecek // şimdiye kadar aldığı
        bool isInformationSent;
        Plan userPlan;
    }

    struct Plan {
        //uint256 cliffDays; //0
        uint256 recurrences; // 0 yada 9
        uint256 startTime;
        uint256 vType; // 0 yada 2
        uint256 purchasePrice; //0.06 yada 0.05
    }
    /*====================================== Events ================================*/
    event BuyingPrices(uint256 planOne, uint256 planTwo);
    event VestingContractSet(address vesting);
    event DistributionTimeSet(uint256 distTime);
    event PriceFeedContratsSet(address[] contracts);
    event LimitsOfTiers(uint8[] tiers, uint256[] limits);
    event SetUserTiers(address user, uint8 tier);
    event IcoStarted(bool ico, uint256 time);
    event IcoDisabled(bool ico, uint256 time);
    event SoldWithCoins(
        address user,
        uint256 time,
        uint256 purchasedPrice,
        address paidCoin,
        uint256 coinAmount,
        uint256 coinPrice,
        uint256 soccerQuantity
    );
    event SoldWithCreditCard(
        address user,
        uint256 time,
        uint256 purchasedPrice,
        uint256 usdAmount,
        uint256 soccerQuantity
    );
    event SentUsersToVesting(address user);
    event SentUsersToVestingBatch(address[] user);
    event WithdrawnAmount(address token, uint256 amount);
    /*====================================== State Variables ================================*/
    mapping(uint8 => Plan) private plans;
    mapping(uint8 => uint256) private limits;
    mapping(address => UserInfo) private user;
    mapping(address => address) private priceFeedContracts;




    address public admin;
    bool public enabled;
    uint256 private distTime;
    IVesting public vestingContract;
    /*====================================== Modifiers ================================*/
    modifier isEnabled() {
        require(enabled, "contract is disabled");
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin");
        _;
    }

    /*====================================== Constructor ================================*/
    constructor(
        address[] memory _tokenAddress,
        address[] memory _priceFeedAddress
    ) {
        admin = msg.sender;
        require(
            _tokenAddress.length == _priceFeedAddress.length,
            "missing arguments"
        );
        for (uint8 i = 0; i < _tokenAddress.length; i++) {
            priceFeedContracts[_tokenAddress[i]] = _priceFeedAddress[i];
        }
    }

    /*====================================== Read Functions ================================*/
    function getTier(address _user) public view returns (uint8) {
        return user[_user].tier;
    }

    function getUserInfo(address _user)
        public
        view
        returns (UserInfo memory userinfo)
    {
        return user[_user];
    }

    function tokenBalances(address _tokenAddress)
        public
        view
        returns (uint256 _tokenBalance)
    {
        if (_tokenAddress == address(0)) _tokenBalance = address(this).balance;
        _tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
    }

    // calling price feed from chainlink
    function getPrice(address _priceFeed) external view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        return uint256(priceFeed.latestAnswer());
    }

    /*====================================== User Write Functions ================================*/
    function buyTokens(
        address _paymentToken,
        uint256 _paymentTokenAmount,
        uint256 _purchasePrice
    ) external payable isEnabled {
        require(
            _purchasePrice == plans[0].purchasePrice ||
                _purchasePrice == plans[1].purchasePrice,
            "wrong buying plan"
        );
        require(
            user[msg.sender].userPlan.purchasePrice == 0 ||
                user[msg.sender].userPlan.purchasePrice == _purchasePrice,
            "wrong buying price"
        );
        address _user = msg.sender;
        uint256 time = block.timestamp;
        address _priceFeed = priceFeedContracts[_paymentToken];
        uint256 _paymentTokenPrice = this.getPrice(_priceFeed);
        uint256 soccerQuantity;
        if (msg.value == 0) {
            IERC20 token = IERC20(_paymentToken);
            token.transferFrom(_user, address(this), _paymentTokenAmount);
            uint256 _sentUsdAmount = ((_paymentTokenPrice *
                _paymentTokenAmount) / 10**18);
            require(
                _sentUsdAmount <= user[_user].availableSpendAmount,
                "Insufficient allotment!"
            );
            soccerQuantity = computeAmount(
                _paymentTokenPrice,
                _paymentTokenAmount,
                _purchasePrice
            );

            updateUserInfo(
                _user,
                soccerQuantity,
                _purchasePrice,
                _sentUsdAmount
            );
        } else {
            require(_paymentToken == address(0), "Wrong bnb address");

            uint256 _sentUsdAmount = ((_paymentTokenPrice * msg.value) /
                10**18);
            require(
                _sentUsdAmount <= user[_user].availableSpendAmount,
                "Insufficient allotment!"
            );
            soccerQuantity = computeAmount(
                _paymentTokenPrice,
                (msg.value),
                _purchasePrice
            );
            updateUserInfo(
                _user,
                soccerQuantity,
                _purchasePrice,
                _sentUsdAmount
            );
        }

        emit SoldWithCoins(
            _user,
            time,
            _purchasePrice,
            _paymentToken,
            _paymentTokenAmount,
            _paymentTokenPrice,
            soccerQuantity
        );
    }

    /*====================================== Admin Write Functions ================================*/
    function withdrawFunds(
        address _tokenAddress,
        address payable _to,
        uint256 _amount
    ) external onlyAdmin {
        if (_tokenAddress == address(0)) _to.transfer(_amount);
        else IERC20(_tokenAddress).transferFrom(address(this), _to, _amount);

        emit WithdrawnAmount(_tokenAddress, _amount);
    }

    function buyTokensWithCreditCard(
        uint256 _dollarAmount,
        address _user,
        uint256 _purchasePrice
    ) external onlyAdmin isEnabled {
        require(
            user[_user].userPlan.purchasePrice == 0 ||
                user[_user].userPlan.purchasePrice == _purchasePrice,
            "wrong buying price"
        );
        require(
            _dollarAmount <= user[_user].availableSpendAmount,
            "Insufficient allotment!"
        );

        uint256 time = block.timestamp;
        uint256 _soccerQuantity = (_dollarAmount * 10**18) / _purchasePrice;
        updateUserInfo(_user, _soccerQuantity, _purchasePrice, _dollarAmount);

        emit SoldWithCreditCard(
            _user,
            time,
            _purchasePrice,
            _dollarAmount,
            _soccerQuantity
        );
    }

    function sendUserInfos(address _user) external onlyAdmin {
        require(block.timestamp >= distTime, "Not distribution time");
        require(
            user[_user].isInformationSent == false,
            "This user's infos already sent!"
        );
        vestingContract.addInvestor(
            _user,
            user[_user].userPlan.startTime,
            user[_user].boughtTokenAmount,
            user[_user].initialUnlockAmounts,
            user[_user].userPlan.recurrences,
            user[_user].afterCliffUnlockAmounts,
            0,
            user[_user].userPlan.vType
        );
        user[_user].isInformationSent = true;
        emit SentUsersToVesting(_user);
    }

    function sendUserInfosBatch(address[] calldata _users) external onlyAdmin {
        require(block.timestamp >= distTime, "Not distribution time");

        uint256[] memory _afterCliffUnlockAmounts = new uint256[](
            _users.length
        );
        uint256[] memory _initialUnlockAmounts = new uint256[](_users.length);
        uint256[] memory _tokensAllotments = new uint256[](_users.length);
        uint256[] memory _recurrences = new uint256[](_users.length);
        uint256[] memory _startTimes = new uint256[](_users.length);
        uint256[] memory _cliffDays = new uint256[](_users.length);
        uint256[] memory _vTypes = new uint256[](_users.length);

        for (uint24 i = 0; i < _users.length; i++) {
            require(
                user[_users[i]].isInformationSent == false,
                " Includes a user that already sent!"
            );
            _afterCliffUnlockAmounts[i] = user[_users[i]]
                .afterCliffUnlockAmounts;
            _initialUnlockAmounts[i] = user[_users[i]].initialUnlockAmounts;
            _recurrences[i] = user[_users[i]].userPlan.recurrences;
            _tokensAllotments[i] = user[_users[i]].boughtTokenAmount;
            _startTimes[i] = user[_users[i]].userPlan.startTime;
            _vTypes[i] = user[_users[i]].userPlan.vType;
            _cliffDays[i] = 0;
            user[_users[i]].isInformationSent = true;
        }

        vestingContract.addInvestorBatch(
            _users,
            _startTimes,
            _tokensAllotments,
            _initialUnlockAmounts,
            _recurrences,
            _afterCliffUnlockAmounts,
            _cliffDays,
            _vTypes
        );

        emit SentUsersToVestingBatch(_users);
    }

    function setVesting(address _vesting) public onlyAdmin {
        vestingContract = IVesting(_vesting);
        emit VestingContractSet(address(vestingContract));
    }

    function setDistTime(uint256 _distTime) public onlyAdmin {
        distTime = block.timestamp + _distTime;
        emit DistributionTimeSet(distTime);
    }

    function setTiersPurchaseLimits(
        uint8[] calldata _tiers,
        uint256[] calldata _limits
    ) external onlyAdmin {
        require(_tiers.length == _limits.length, "missing argument");
        for (uint8 i = 0; i < _tiers.length; i++) {
            limits[_tiers[i]] = _limits[i];
        }
        emit LimitsOfTiers(_tiers, _limits);
    }

    function setUserTier(address _user, uint8 _tier) external onlyAdmin {
        user[_user].tier = _tier;
        user[_user].maxDollarAmount = limits[_tier];
        user[_user].availableSpendAmount = limits[_tier];
        user[_user].spentDollarAmount = 0;
        user[_user].isInformationSent = false;
    }

    function setMultiUserTier(address[] memory _users, uint8[] memory _tiers)
        external
        onlyAdmin
    {
        require(_users.length == _tiers.length, "Missing Arguments!");
        for (uint8 i = 0; i < _tiers.length; i++) {
            user[_users[i]].tier = _tiers[i];
            user[_users[i]].maxDollarAmount = limits[_tiers[i]];
            user[_users[i]].availableSpendAmount = limits[_tiers[i]];
            user[_users[i]].spentDollarAmount = 0;
            user[_users[i]].isInformationSent = false;
        }
    }

    /*  Set buying plans prices
        @params: _plan1: 0,6
                 _plan2: 0,5 */
    function setBuyingPlan(Plan[] calldata _plan) external onlyAdmin {
        require(
            _plan[0].recurrences == 0 &&
                _plan[0].vType == 0 &&
                _plan[0].purchasePrice == (6 * 10**6),
            "Wrong params for plan one"
        );
        require(
            _plan[1].recurrences == 9 &&
                _plan[1].vType == 2 &&
                _plan[1].purchasePrice == (5 * 10**6),
            "Wrong params for plan two"
        );

        for (uint8 i = 0; i < _plan.length; i++) plans[i] = _plan[i];
    }

    /* Admin starts the ICO */
    function setEnableIco() external onlyAdmin {
        require(
            vestingContract != IVesting(address(0)) &&
                plans[0].purchasePrice > 0 &&
                distTime > 0,
            "Contract is not ready to start!"
        );
        enabled = true;
    }

    function setDisableIco() external onlyAdmin {
        enabled = false;
    }

    function setPriceFeedContracts(
        address[] calldata _tokenAddress,
        address[] calldata _priceFeedAddress
    ) external onlyAdmin {
        require(
            _tokenAddress.length == _priceFeedAddress.length,
            "missing arguments"
        );
        for (uint8 i = 0; i < _tokenAddress.length; i++) {
            priceFeedContracts[_tokenAddress[i]] = _priceFeedAddress[i];
        }
    }

    /*====================================== Internal Functions ================================*/
    function updateUserInfo(
        address _user,
        uint256 _soccerQuantity,
        uint256 _purchasePrice,
        uint256 _sentUsdAmount
    ) internal {
        require(
            user[_user].availableSpendAmount >= _sentUsdAmount,
            "Exceeds limit"
        );
        user[_user].availableSpendAmount -= _sentUsdAmount;
        user[_user].spentDollarAmount += _sentUsdAmount;
        require(
            user[_user].availableSpendAmount + user[_user].spentDollarAmount ==
                user[_user].maxDollarAmount,
            "Compute Error"
        );
        user[_user].boughtTokenAmount += _soccerQuantity;

        if (_purchasePrice == plans[0].purchasePrice) {
            user[_user].initialUnlockAmounts = user[_user].boughtTokenAmount;
            user[_user].userPlan.purchasePrice = _purchasePrice;
            user[_user].afterCliffUnlockAmounts = 0;
            user[_user].userPlan.recurrences = plans[0].recurrences;
            user[_user].userPlan.vType = 0;
        } else if (_purchasePrice == plans[1].purchasePrice) {
            user[_user].initialUnlockAmounts =
                (user[_user].boughtTokenAmount * 10) /
                100;
            user[_user].userPlan.purchasePrice = _purchasePrice;
            user[_user].afterCliffUnlockAmounts = 0;
            user[_user].userPlan.recurrences = plans[1].recurrences;
            user[_user].userPlan.vType = 2;
        }
    }

    function computeAmount(
        uint256 _paymentTokenprice,
        uint256 _amount,
        uint256 _purchasePrice
    ) internal pure returns (uint256 _quantity) {
        _quantity = ((_amount * _paymentTokenprice) / ((_purchasePrice)));
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface AggregatorV3Interface {
  function latestAnswer() external view returns (int256 answer);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVesting {


function addInvestor(
    address _investor,
    uint256 _startTime,
    uint256 _tokensAllotment,
    uint256 _initialUnlockAmount,
    uint256 _recurrence,
    uint256 _afterCliffUnlockAmount,
    uint256 _cliffDays,
    uint256 _vType
  ) external;

function addInvestorBatch(
    address[] memory _investors, // kullanıcı adreslerimiz
    uint256[] memory _startTimes, // dağıtım başlangıç zamanı
    uint256[] memory _tokensAllotments, // satın aldığı token miktarı
    uint256[] memory _initialUnlockAmounts, //vesting başlamadan ön ödeme 
    uint256[] memory _recurrences, // periyodun tekrar süresi (2 yıl seçti aylık olarak bu durumda 24 olur)
    uint256[] memory _afterCliffUnlockAmounts, //clif bitince verilecek initial token miktarı ---           toplam bakiyeden initialın çıkarılmış hali vesting boyunca dağıtılacak miktar
    uint256[] memory _cliffDays, //initialdan sonra vesting başlayana kadar geçecek bekleme süresi
    uint256[] memory _vTypes // vesting tipi (planA planB)
  ) external;

}