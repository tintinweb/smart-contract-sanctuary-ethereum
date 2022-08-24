/*
Shenron The Eternal Dragon was first created by a God, emerging as a small dragon from the Dragon Jewel.
Said to reside within the fiery centre of the earth; when all seven dragon balls are gathered, Shenron can be summoned.
As the sky turns pitch black, mighty Shenron will grant a single wish of immense power to those who called him. 
Afterwards the dragon balls are scattered to the corners of the earth and heroes must once again work together to collect them all. 

Shenron encourages community members to unite and create DragonWallz, these are walls of seven consecutive buys, this summons 
the might of The Eternal Dragon Shenron, anyone that dares to sell will be subjected to the wrath of Shenron and taxed 25% upon selling.

The contract will take this extra BNB and distribute it to those heroes who first helped summon Shenron with the DragonWall.

Shenron uses his power to grant the wishes of believers by driving the charts to higher 
heights every day, encouraging the community to come together and create DragonWallz.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ShenronDividendTracker.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./BuyWallMapping.sol";
import "./Counters.sol";

contract Shenron is ERC20, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private constant _name = "Shenron";
    string private constant _symbol = "SHENRON";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e12 * 10**18;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bool private tradingOpen = false;
    bool public dragonWallActive = false;
    bool private dragonWallEnabled = false;
    uint256 private launchBlock = 0;
    uint256 private sniperProtectBlock = 12;
    address private uniswapV2Pair;

    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) private isBot;
    mapping(address => bool) private canClaimUnclaimed;
    mapping(address => bool) public isExcludeFromMaxWalletAmount;

    uint256 public maxWalletAmount;

    uint256 private sniperTax = 60;
    uint256 private baseBuyTax = 2;
    uint256 private baseSellTax = 2;
    uint256 private buyRewards = 3;
    uint256 private sellRewards = 3;
    uint256 private dragonWallJeetTax;

    uint256 private autoLP = 25;
    uint256 private devFee = 30;
    uint256 private teamFee = 30;
    uint256 private buybackFee = 15;

    uint256 private minContractTokensToSwap = 2e9 * 10**_decimals;
    uint256 public minBuyWallIncludeAmount = 100000000 * 10**_decimals;
    uint256 public minBuyWallActivationCount = 7;

    BuyWallMapping public buyWallMap;

    address private devWalletAddress;
    address private teamWalletAddress;
    address private buyBackWalletAddress;

    ShenronDividendTracker public dividendTracker;
    ShenronDividendTracker private dragonWallDivTracker;

    uint256 public pendingTokensForReward;

    uint256 private pendingEthReward;

    uint256 public totalETHRewardsPaidOut;

    struct dragonWallWins {
        address divTrackerWin;
        uint256 timestamp;
    }

    Counters.Counter private dragonWallParticipationHistoryIds;

    mapping(uint256 => dragonWallWins) private dragonWallWinsMap;
    mapping(address => uint256[]) private dragonWallWinIds;

    event BuyFees(address from, address to, uint256 amountTokens);
    event SellFees(address from, address to, uint256 amountTokens);
    event AddLiquidity(uint256 amountTokens, uint256 amountEth);
    event SwapTokensForEth(uint256 sentTokens, uint256 receivedEth);
    event SwapEthForTokens(uint256 sentEth, uint256 receivedTokens);
    event DistributeFees(uint256 devEth, uint256 remarketingEth, uint256 rebuybackFees);

    event SendBuyWallDividends(uint256 amount);

    event DividendClaimed(uint256 ethAmount, address account);

    constructor(
        address _devWalletAddress,
        address _teamWalletAddress,
        address _buyBackWalletAddress
    ) ERC20(_name, _symbol) {
        devWalletAddress = _devWalletAddress;
        teamWalletAddress = _teamWalletAddress;
        buyBackWalletAddress = _buyBackWalletAddress;

        maxWalletAmount = (_tTotal * 1) / 10000; // 0.01% maxWalletAmount (initial limit)

        buyWallMap = new BuyWallMapping();

        dividendTracker = new ShenronDividendTracker();
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));

        isExcludeFromFee[owner()] = true;
        isExcludeFromFee[address(this)] = true;
        isExcludeFromFee[devWalletAddress] = true;
        isExcludeFromFee[teamWalletAddress] = true;
        isExcludeFromFee[buyBackWalletAddress] = true;
        isExcludeFromMaxWalletAmount[owner()] = true;
        isExcludeFromMaxWalletAmount[address(this)] = true;
        isExcludeFromMaxWalletAmount[address(uniswapV2Router)] = true;
        isExcludeFromMaxWalletAmount[devWalletAddress] = true;
        isExcludeFromMaxWalletAmount[teamWalletAddress] = true;
        isExcludeFromMaxWalletAmount[buyBackWalletAddress] = true;
        canClaimUnclaimed[owner()] = true;
        canClaimUnclaimed[address(this)] = true;

        _mint(owner(), _tTotal);

    }

    /**
     * @dev Function to recover any ETH sent to Contract by Mistake.
    */
    function withdrawStuckETH(bool pendingETH) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        bool success;
        (success, ) = address(msg.sender).call{ value: address(this).balance.sub(pendingEthReward) }(
            ""
        );

        if(pendingETH) {
            require(pendingEthReward > 0, "NER");

            bool pendingETHsuccess;
            (pendingETHsuccess, ) = address(msg.sender).call{ value: pendingEthReward }(
                ""
            );

            if (pendingETHsuccess) {
                pendingEthReward = pendingEthReward.sub(pendingEthReward);
            }
        }
    }

    /**
     * @dev Function to recover any ERC20 Tokens sent to Contract by Mistake.
    */
    function recoverAccidentalERC20(address _tokenAddr, address _to) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 _amount = IERC20(_tokenAddr).balanceOf(address(this));
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function setSniperProtect() external onlyOwner {
        require(!tradingOpen, "TOP1");
        uint256 _launchTime;
        
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isExcludeFromMaxWalletAmount[address(uniswapV2Pair)] = true;

        automatedMarketMakerPairs[uniswapV2Pair] = true;
        dividendTracker.excludeFromDividends(uniswapV2Pair);

        addLiquidity(balanceOf(address(this)), address(this).balance);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        tradingOpen = true;
        _launchTime = block.timestamp;
        launchBlock = block.number;
    }

    function manualSwap() external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 totalTokens = balanceOf(address(this)).sub(
            pendingTokensForReward
        );

        swapTokensForEth(totalTokens);
    }

    function manualSend() external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 totalEth = address(this).balance.sub(pendingEthReward);

        uint256 devFeesToSend = totalEth.mul(devFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 teamFeesToSend = totalEth.mul(teamFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 buybackFeesToSend = totalEth.mul(buybackFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 remainingEthForFees = totalEth.sub(devFeesToSend).sub(
            teamFeesToSend).sub(buybackFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, teamFeesToSend, buybackFeesToSend);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(!isBot[_from] && !isBot[_to]);

        uint256 transferAmount = _amount;
        if (
            tradingOpen &&
            (automatedMarketMakerPairs[_from] ||
                automatedMarketMakerPairs[_to]) &&
            !isExcludeFromFee[_from] &&
            !isExcludeFromFee[_to]
        ) {
            
            transferAmount = takeFees(_from, _to, _amount);
        }

        if (!automatedMarketMakerPairs[_to] && !isExcludeFromMaxWalletAmount[_to]) {
            require(balanceOf(_to) + transferAmount <= maxWalletAmount,
                "WBL"
            );
        }

        super._transfer(_from, _to, transferAmount);

    }

    function claimUnclaimed(address dragonWallDivAddress, address payable _unclaimedAccount, address payable _account) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        dragonWallDivTracker = ShenronDividendTracker(payable(dragonWallDivAddress));
        
        uint256 withdrawableAmount = dragonWallDivTracker.withdrawableDividendOf(_unclaimedAccount);
        require(withdrawableAmount > 0,
            "NWD"
        );

        uint256 ethAmount;

        ethAmount = dragonWallDivTracker.processAccount(_unclaimedAccount, _account);

        if (ethAmount > 0) {
            dragonWallDivTracker.setBalance(_unclaimedAccount, 0);

            emit DividendClaimed(ethAmount, _unclaimedAccount);
        }
    }

    function claim(address dragonWallDivAddress) external {
        _claim(dragonWallDivAddress, payable(msg.sender));
    }

    function _claim(address dragonWallDivAddress, address payable _account) private {
        dragonWallDivTracker = ShenronDividendTracker(payable(dragonWallDivAddress));

        uint256 withdrawableAmount = dragonWallDivTracker.withdrawableDividendOf(
            _account
        );
        require(
            withdrawableAmount > 0,
            "NWD"
        );
        uint256 ethAmount;

        ethAmount = dragonWallDivTracker.processAccount(_account, _account);

        if (ethAmount > 0) {
            dragonWallDivTracker.setBalance(_account, 0);

            emit DividendClaimed(ethAmount, _account);
        }
    }

    function checkdragonWallWinnings(address dragonWallDivAddress, address _account) public view returns (uint256) {
        return ShenronDividendTracker(payable(dragonWallDivAddress)).withdrawableDividendOf(_account);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "AMMS"
        );
        automatedMarketMakerPairs[_pair] = _value;
    }

    function setExcludeFromFee(address _address, bool _isExludeFromFee)
        external onlyOwner {
        isExcludeFromFee[_address] = _isExludeFromFee;
    }

    function setExcludeFromMaxWalletAmount(address _address, bool _isExludeFromMaxWalletAmount)
        external onlyOwner {
        isExcludeFromMaxWalletAmount[_address] = _isExludeFromMaxWalletAmount;
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= (totalSupply() * 1 / 1000)/1e18, "MWLP");
        maxWalletAmount = newMaxWallet * (10**_decimals);
    }

    function isIncludeIndragonWall(address _address) public view returns (bool) {
        return buyWallMap.isPartOfdragonWall(_address);
    }

    function setTaxes(
        uint256 _baseBuyTax,
        uint256 _buyRewards,
        uint256 _baseSellTax,
        uint256 _sellRewards,
        uint256 _autoLP,
        uint256 _devFee,
        uint256 _teamFee,
        uint256 _buybackFee
    ) external onlyOwner {
        require(_baseBuyTax <= 10 && _baseSellTax <= 10);

        baseBuyTax = _baseBuyTax;
        buyRewards = _buyRewards;
        baseSellTax = _baseSellTax;
        sellRewards = _sellRewards;
        autoLP = _autoLP;
        devFee = _devFee;
        teamFee = _teamFee;
        buybackFee =_buybackFee;
    }

    function setMinParams(uint256 _numTokenContractTokensToSwap, uint256 _minBuyWallActivationCount, uint256 _minBuyWallIncludeAmount) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        minContractTokensToSwap = _numTokenContractTokensToSwap * 10 ** _decimals;
        minBuyWallActivationCount = _minBuyWallActivationCount;
        minBuyWallIncludeAmount = _minBuyWallIncludeAmount * 10 ** _decimals;
    }

    function setBots(address[] calldata _bots) public onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            if (
                _bots[i] != uniswapV2Pair &&
                _bots[i] != address(uniswapV2Router)
            ) {
                isBot[_bots[i]] = true;
            }
        }
    }

    function setWalletAddress(address _devWalletAddress, address _teamWalletAddress, address _buyBackWalletAddress) external onlyOwner {
        devWalletAddress = _devWalletAddress;
        teamWalletAddress = _teamWalletAddress;
        buyBackWalletAddress = _buyBackWalletAddress;
    }

    function takeFees(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fees;
        uint256 remainingAmount;
        require(
            automatedMarketMakerPairs[_from] || automatedMarketMakerPairs[_to],
            "NMM"
        );

        if (automatedMarketMakerPairs[_from]) {
            uint256 totalBuyTax;
             if (block.number <= launchBlock + sniperProtectBlock) {
                totalBuyTax = sniperTax;
            } else {
                totalBuyTax = baseBuyTax.add(buyRewards);
            }

            fees = _amount.mul(totalBuyTax).div(100);

            uint256 rewardTokens = _amount.mul(buyRewards).div(100);

            pendingTokensForReward = pendingTokensForReward.add(rewardTokens);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);
            
            if (_amount >= minBuyWallIncludeAmount) {

                if(dragonWallEnabled) {

                    if(!dragonWallActive) {
                        dragonWallJeetTax = 0;
                    }

                    if (!buyWallMap.isPartOfdragonWall(_to)) {
                    
                        buyWallMap.includeTodragonWallMap(_to);

                        if (!dividendTracker.isBrokeOutOfdragonWall(_to)) {
                            addHolderTodragonWallWinHistory(_to, address(dividendTracker));
                        }

                    }

                    dividendTracker.includeFromDividends(_to, balanceOf(_to).add(remainingAmount));
                        
                    dividendTracker._brokeOutOfdragonWall(_to, false);
                }
            }

            if (buyWallMap.getNumberOfdragonWallHolders() >= minBuyWallActivationCount) {
                dragonWallActive = true;

                dragonWallJeetTax = 25;
            }

            emit BuyFees(_from, address(this), fees);
        } else {
            uint256 totalSellTax;
            if (block.number <= launchBlock + sniperProtectBlock) {
                totalSellTax = sniperTax;
            } else {

                totalSellTax = baseSellTax.add(sellRewards).add(dragonWallJeetTax);

                if(totalSellTax > 21) {
                    totalSellTax = 21;
                }
            }

            fees = _amount.mul(totalSellTax).div(100);
            if(dragonWallJeetTax > 0) {
                uint256 jeetExtraTax = dragonWallJeetTax.div(4);

                uint256 rewardTokens = _amount.mul(sellRewards.add(jeetExtraTax)).div(100);

                pendingTokensForReward = pendingTokensForReward.add(rewardTokens);
            } else {

                uint256 rewardTokens = _amount.mul(sellRewards).div(100);

                pendingTokensForReward = pendingTokensForReward.add(rewardTokens);
            }

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);

            buyWallMap.excludeTodragonWallMap(_from);

            dividendTracker.setBalance(payable(_from), 0);

            dividendTracker._brokeOutOfdragonWall(_from, true);

            uint256 tokensToSwap = balanceOf(address(this)).sub(
                pendingTokensForReward);

            if (tokensToSwap > minContractTokensToSwap && !dragonWallActive) {
                distributeTokensEth(tokensToSwap);
            }

            if (dragonWallActive) {
                swapAndSendBuyWallDividends(pendingTokensForReward);
            }

            emit SellFees(_from, address(this), fees);
        }

        return remainingAmount;
    }

    function enddragonWall() private {
        dragonWallActive = false;

        delete buyWallMap;

        buyWallMap = new BuyWallMapping();

        dividendTracker = new ShenronDividendTracker();
    }

    function addHolderTodragonWallWinHistory(address _account, address _dragonWallDivAddress) private {
        dragonWallParticipationHistoryIds.increment();
        uint256 hId = dragonWallParticipationHistoryIds.current();
        dragonWallWinsMap[hId].divTrackerWin = _dragonWallDivAddress;
        dragonWallWinsMap[hId].timestamp = block.timestamp;

        dragonWallWinIds[_account].push(hId);
    }

    function distributeTokensEth(uint256 _tokenAmount) private {
        uint256 tokensForLiquidity = _tokenAmount.mul(autoLP).div(100);

        uint256 halfLiquidity = tokensForLiquidity.div(2);
        uint256 tokensForSwap = _tokenAmount.sub(halfLiquidity);

        uint256 totalEth = swapTokensForEth(tokensForSwap);

        uint256 ethForAddLP = totalEth.mul(autoLP).div(100);
        uint256 devFeesToSend = totalEth.mul(devFee).div(100);
        uint256 teamFeesToSend = totalEth.mul(teamFee).div(100);
        uint256 buybackFeesToSend = totalEth.mul(buybackFee).div(100);
        uint256 remainingEthForFees = totalEth
            .sub(ethForAddLP)
            .sub(devFeesToSend)
            .sub(teamFeesToSend)
            .sub(buybackFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, teamFeesToSend, buybackFeesToSend);

        if (halfLiquidity > 0 && ethForAddLP > 0) {
            addLiquidity(halfLiquidity, ethForAddLP);
        }
    }

    function sendEthToWallets(uint256 _devFees, uint256 _teamFees, uint256 _buybackFees) private {
        if (_devFees > 0) {
            payable(devWalletAddress).transfer(_devFees);
        }
        if (_teamFees > 0) {
            payable(teamWalletAddress).transfer(_teamFees);
        }
        if (_buybackFees > 0) {
            payable(buyBackWalletAddress).transfer(_buybackFees);
        }
        emit DistributeFees(_devFees, _teamFees, _buybackFees);
    }

    function swapTokensForEth(uint256 _tokenAmount) private returns (uint256) {
        uint256 initialEthBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedEth = address(this).balance.sub(initialEthBalance);

        emit SwapTokensForEth(_tokenAmount, receivedEth);
        return receivedEth;
    }

    function swapEthForTokens(uint256 _ethAmount, address _to) private returns (uint256) {
        uint256 initialTokenBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, _to, block.timestamp);

        uint256 receivedTokens = balanceOf(address(this)).sub(
            initialTokenBalance
        );

        emit SwapEthForTokens(_ethAmount, receivedTokens);
        return receivedTokens;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit AddLiquidity(_tokenAmount, _ethAmount);
    }

    function swapAndSendBuyWallDividends(uint256 _tokenAmount) private {
        addHolderTodragonWallWinHistory(address(this), address(dividendTracker));

        uint256 pendingRewardsEth = swapTokensForEth(_tokenAmount);

        pendingTokensForReward = pendingTokensForReward.sub(_tokenAmount);

        (bool success, ) = address(dividendTracker).call{value: pendingRewardsEth}(
            ""
        );

        if (success) {
            emit SendBuyWallDividends(pendingRewardsEth);

            dividendTracker.distributeDividends();

            dividendTracker.setdragonWallEnded();

            enddragonWall();
        } else {
            pendingEthReward = pendingEthReward.add(pendingRewardsEth);

            enddragonWall();
        }

        totalETHRewardsPaidOut = totalETHRewardsPaidOut.add(pendingRewardsEth);

    }

    function startdragonWall(bool state) external onlyOwner {
        dragonWallEnabled = state;
    }

    function availableContractTokenBalance() external view returns (uint256) {
        return balanceOf(address(this)).sub(pendingTokensForReward);
    }

    function getBuyTax() public view returns (uint256) {
        return baseBuyTax.add(buyRewards);
    }

    function getSellTax() public view returns (uint256) {
        return baseSellTax.add(sellRewards).add(dragonWallJeetTax);
    }

    function getNumberOfBuyWallHolders() external view returns (uint256) {
        return buyWallMap.getNumberOfdragonWallHolders();
    }

     function getWinningHistory(
        address _account,
        uint256 _limit,
        uint256 _pageNumber
    ) external view returns (dragonWallWins[] memory) {
        require(_limit > 0 && _pageNumber > 0, "IA");
        uint256 dragonWallWinCount = dragonWallWinIds[_account].length;
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < dragonWallWinCount, "OOR");
        uint256 limit = _limit;
        if (end > dragonWallWinCount) {
            end = dragonWallWinCount;
            limit = dragonWallWinCount % _limit;
        }

        dragonWallWins[] memory mydragonWallWins = new dragonWallWins[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = start; i < end; i++) {
            uint256 hId = dragonWallWinIds[_account][i];
            mydragonWallWins[currentIndex] = dragonWallWinsMap[hId];
            currentIndex += 1;
        }
        return mydragonWallWins;
    }

    function getWinningHistoryCount(address _account) external view returns (uint256) {
        return dragonWallWinIds[_account].length;
    }

    receive() external payable {}
}