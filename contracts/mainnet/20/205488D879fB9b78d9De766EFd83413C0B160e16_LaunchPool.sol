/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract LaunchPool {
    using SafeMath for uint256;
    address payable public owner;
    uint256[] public vestDuration = [0, 30 days, 60 days];
    uint256[] public vestingClaim = [30, 35, 35]; // in percentage
    address wBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    enum Release {
        NOT_SET,
        FAILED,
        RELEASED
    }

    IERC20 public tokenSell;
    uint256 public perTokenBuy;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalTokenSell;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public maxBuy;
    uint256 public minBuy;
    uint256 public alreadyRaised;
    Release public release;
    uint256 public releaseTime;
    IERC20 public activeCurrency;
    bool public isWhitelist;
    bool public isCheckSoftCap = true;
    bool public isVesting = true;

    struct UserInfo {
        uint256 totalToken;
        uint256 totalSpent;
    }

    enum Claims {
        HALF,
        FULL,
        FAILED
    }

    mapping(address => UserInfo) public usersTokenBought; // userAddress => User Info
    mapping(address => bool) public whitelistedAddress;
    mapping(address => mapping(uint256 => bool)) public claimInPeriod; // userAddress => period => true/false

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    modifier withdrawCheck() {
        require(getSoftFilled() == true, "Can't withdraw");
        _;
    }

    event BUY(address Buyer, uint256 amount);
    event CLAIM(address Buyer, Claims claim);
    event RELEASE(Release released);

    constructor(address payable _owner, address _activeCurrency) {
        owner = _owner;
        activeCurrency = IERC20(_activeCurrency);
    }

    // onlyOwner Function
    function setEventPeriod(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(address(tokenSell) != address(0), "Setup raised first");
        require(_startTime != 0, "Cannot set 0 value");
        require(_endTime > _startTime, "End time must be greater");
        startTime = _startTime;
        endTime = _endTime;
    }

    function setRaised(
        address _tokenSale,
        uint256 _perTokenBuy,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _maxBuy,
        uint256 _minBuy,
        bool _isWhitelist,
        bool _isCheckSoftCap,
        bool _isVesting
    ) external onlyOwner {
        // require(startTime == 0, "Raising period already start");
        require(_hardcap > _softcap, "Hardcap must greater than softcap");
        tokenSell = IERC20(_tokenSale);
        uint256 _totalTokenSale = _hardcap.mul(_perTokenBuy);
        uint256 allowance = tokenSell.allowance(msg.sender, address(this));
        uint256 balance = tokenSell.balanceOf(msg.sender);
        //require(balance >= _totalTokenSale, "Not enough tokens");
        require(allowance >= _totalTokenSale, "Check the token allowance");
        perTokenBuy = _perTokenBuy; //4 
        totalTokenSell = _totalTokenSale;
        softCap = _softcap;
        hardCap = _hardcap;
        maxBuy = _maxBuy; // in in active currency
        minBuy = _minBuy; // in in active currency
        isWhitelist = _isWhitelist;
        isVesting = _isVesting; // only set one time
        isCheckSoftCap = _isCheckSoftCap; // only set one time
        //tokenSell.transferFrom(msg.sender, address(this), _perTokenBuy.div(100).mul(75) ); 
    }

    function setMinMaxBuy(uint256 _minBuy, uint _maxBuy) external onlyOwner {
        require(_maxBuy > _minBuy, "max buy less than min buy");
        minBuy = _minBuy;
        maxBuy = _maxBuy;
    }

    function setIsWhitelist(bool _isWhitelist) external onlyOwner {
        require(isWhitelist != _isWhitelist, "cannot assign same value");
        isWhitelist = _isWhitelist;
    }

    function addWhitelised(
        address[] memory whitelistAddresses,
        bool[] memory values
    ) external onlyOwner {
        require(
            whitelistAddresses.length == values.length,
            "provide same length"
        );
        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            whitelistedAddress[whitelistAddresses[i]] = values[i];
        }
    }

    function setVestingPeriodAndClaim(
        uint256[] memory _vests,
        uint256[] memory _claims
    ) external onlyOwner {
        require(_vests.length == _claims.length, "length must be same");
        require(block.timestamp < startTime, "Raising period already started");
        uint total;
        for (uint256 i = 0; i < _claims.length; i++) {
            total += _claims[i];
        }
        require(total == 100, "total claim must be 100");

        for (uint256 i = 0; i < _vests.length; i++) {
            vestDuration[i] = _vests[i].mul(1 days);
            vestingClaim[i] = _claims[i];
        }
    }

    function setRelease(Release _release) external onlyOwner {
        require(startTime != 0, "Raise no start");
        require(release != _release, "Can't setup same release");
        if (isCheckSoftCap) {
            require(getSoftFilled(), "Softcap not fullfiled");
        }
        if (getHardFilled() == false) {
            require(block.timestamp > endTime, "Raising not end");
        }
        release = _release;
        releaseTime = block.timestamp;

        emit RELEASE(_release);
    }

    function withdrawBNB() public onlyOwner withdrawCheck {
        uint256 balance = address(this).balance;
        require(balance > 0, "does not have any balance");
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(msg.sender, _amount);
    }

    // Buy Function
    function getHardFilled() public view returns (bool) {
        return alreadyRaised >= hardCap;
    }

    function getSoftFilled() public view returns (bool) {
        return alreadyRaised >= softCap;
    }

    function getSellTokenAmount(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return _amount * perTokenBuy;
    }

    function buy(uint256 amount) external payable {
        if (isWhitelist) {
            require(whitelistedAddress[msg.sender], "not whitelisted");
        }
        require(block.timestamp != 0, "Raising period not set");
        require(block.timestamp >= startTime, "Raising period not started yet");
        require(block.timestamp < endTime, "Raising period already end");
        require(getHardFilled() == false, "Raise already fullfilled");

        UserInfo memory userInfo = usersTokenBought[msg.sender];

        uint256 tokenSellAmount;

        if (activeCurrency == IERC20(wBNB)) {
            require(msg.value > 0, "Please input value");
            require(
                userInfo.totalSpent.add(msg.value) >= minBuy,
                "Less than min buy"
            );
            require(
                userInfo.totalSpent.add(msg.value) <= maxBuy,
                "More than max buy"
            );
            require(
                msg.value + alreadyRaised <= hardCap,
                "amount buy more than total hardcap"
            );

            tokenSellAmount = getSellTokenAmount(msg.value);
            userInfo.totalToken = userInfo.totalToken.add(tokenSellAmount);
            userInfo.totalSpent = userInfo.totalSpent.add(msg.value);
            usersTokenBought[msg.sender] = userInfo;

            alreadyRaised = alreadyRaised.add(msg.value);
        } else {
            require(amount > 0, "Please input value");
            require(
                userInfo.totalSpent.add(amount) >= minBuy,
                "Less than min buy"
            );
            require(
                userInfo.totalSpent.add(amount) <= maxBuy,
                "More than max buy"
            );
            require(
                amount + alreadyRaised <= hardCap,
                "amount buy more than total hardcap"
            );

            tokenSellAmount = getSellTokenAmount(amount);
            require(
                activeCurrency.balanceOf(msg.sender) >= amount,
                "not enough balance"
            );
            require(
                activeCurrency.allowance(msg.sender, address(this)) >= amount,
                "not enough allowance"
            );

            activeCurrency.transferFrom(msg.sender, address(this), amount);
            userInfo.totalToken = userInfo.totalToken.add(tokenSellAmount);
            userInfo.totalSpent = userInfo.totalSpent.add(amount);
            usersTokenBought[msg.sender] = userInfo;
            alreadyRaised = alreadyRaised.add(amount);
        }

        emit BUY(msg.sender, tokenSellAmount);
    }

    // Claim Function
    function claimFailed() external {
        require(block.timestamp > endTime, "Raising not end");
        if (isCheckSoftCap) {
            require(getSoftFilled() == false, "Soft cap already fullfiled");
        } else {
            require(release == Release.FAILED, "Release not failed");
        }

        uint256 userSpent = usersTokenBought[msg.sender].totalSpent;
        require(userSpent > 0, "Already claimed");

        if (activeCurrency == IERC20(wBNB)) {
            payable(msg.sender).transfer(userSpent);
        } else {
            activeCurrency.transfer(msg.sender, userSpent);
        }

        delete usersTokenBought[msg.sender];
        emit CLAIM(msg.sender, Claims.FAILED);
    }

    modifier checkPeriod(uint256 _claim) {
        require(
            vestDuration[_claim] + releaseTime <= block.timestamp,
            "Claim not avalaible yet"
        );
        _;
    }

    function claimSuccess(uint256 _claim)
        external
        checkPeriod(uint256(_claim))
    {
        require(release == Release.RELEASED, "Not Release Time");
        UserInfo storage userInfo = usersTokenBought[msg.sender];
        require(userInfo.totalToken > 0, "You can't claim any amount");

        uint256 amountClaim;
        Claims claim;

        if (isVesting == false) {
            amountClaim = userInfo.totalToken;
            usersTokenBought[msg.sender] = userInfo;
            tokenSell.transfer(msg.sender, amountClaim);
            claim = Claims.FULL;
        } else {
            require(_claim < vestDuration.length, "more than max claim");
            require(
                claimInPeriod[msg.sender][_claim] == false,
                "already claim"
            );
            amountClaim = userInfo.totalToken.mul(vestingClaim[_claim]).div(
                100
            );
            usersTokenBought[msg.sender] = userInfo;
            tokenSell.transfer(msg.sender, amountClaim);
            claimInPeriod[msg.sender][_claim] = true;
            claim = Claims.HALF;
        }

        emit CLAIM(msg.sender, claim);
    }

    function getRaised()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256[] memory,
            uint256,
            uint256,
            uint256,
            IERC20,
            bool,
            bool,
            bool
        )
    {
        return (
            alreadyRaised,
            startTime,
            endTime,
            softCap,
            hardCap,
            releaseTime,
            vestDuration,
            minBuy,
            maxBuy,
            perTokenBuy,
            activeCurrency,
            isWhitelist,
            isCheckSoftCap,
            isVesting
        );
    }
}