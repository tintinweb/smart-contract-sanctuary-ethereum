// SPDX-License-Identifier: MIT

import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "AggregatorV3Interface.sol";
import "ReentrancyGuard.sol";

pragma solidity ^0.8.0;

contract TokenFarm is Ownable, ReentrancyGuard {
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;
    address[] public allowedTokens;
    using SafeERC20 for IERC20;
    IERC20 public timeToken;
    uint256 public totalRaised;
    uint256 public goal;
    enum FUND_STATE {
        OPEN,
        REFUND,
        CLOSED
    }
    FUND_STATE public fund_state;

    constructor(address _timeTokenAddress) public {
        timeToken = IERC20(_timeTokenAddress);
        fund_state = FUND_STATE.OPEN;
        goal = 500000000000000000000000;
    }

    function stateOpen() public onlyOwner {
        fund_state = FUND_STATE.OPEN;
    }

    function stateRefund() public onlyOwner {
        fund_state = FUND_STATE.REFUND;
    }

    function stateClosed() public onlyOwner {
        fund_state = FUND_STATE.CLOSED;
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function goalAmount() public onlyOwner returns (uint256) {
        return goal;
    }

    function totalERCRaised() public onlyOwner returns (uint256) {
        return totalRaised;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public nonReentrant {
        require(fund_state == FUND_STATE.OPEN);
        require(_amount > 0, "Amount must be more than zero!");
        require(tokenIsAllowed(_token), "Token is currently not allowed!");
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        require(
            totalRaised + ((_amount * price) / ((10**decimals))) < goal,
            "Too much money"
        );
        uint256 _amount2 = ((_amount * (10**20)) / (10**decimals));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        if (getUserTotalValue(msg.sender) <= 0) {
            stakers.push(msg.sender);
        }
        if (
            address(_token) ==
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
        ) {
            stakingBalance[_token][msg.sender] =
                stakingBalance[_token][msg.sender] +
                _amount2;
            totalRaised = uint256(
                totalRaised + (((_amount2 * price)) / ((10**decimals)))
            );
        }
        if (
            address(_token) ==
            address(0xdAC17F958D2ee523a2206206994597C13D831ec7)
        ) {
            stakingBalance[_token][msg.sender] =
                stakingBalance[_token][msg.sender] +
                _amount2;
            totalRaised = uint256(
                totalRaised + (((_amount2 * price)) / ((10**decimals)))
            );
        }
        if (
            address(_token) ==
            address(0x6B175474E89094C44Da98b954EedeAC495271d0F)
        ) {
            stakingBalance[_token][msg.sender] =
                stakingBalance[_token][msg.sender] +
                _amount;
            totalRaised = uint256(
                totalRaised + (((_amount * price)) / ((10**decimals)))
            );
        }
        if (
            address(_token) ==
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
        ) {
            stakingBalance[_token][msg.sender] =
                stakingBalance[_token][msg.sender] +
                _amount;
            totalRaised = uint256(
                totalRaised + (((_amount * price)) / ((10**decimals)))
            );
        }
    }

    function issueTokens() public onlyOwner nonReentrant {
        require(fund_state == FUND_STATE.OPEN);
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            timeToken.transfer(recipient, userTotalValue);
        }
    }

    function claimRefund(address _token) public nonReentrant {
        require(fund_state == FUND_STATE.REFUND);
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be zero!");
        IERC20(_token).safeTransfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function withdrawToken(address _token, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        IERC20 token = IERC20(_token);
        token.safeTransfer(msg.sender, _amount);
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }
}