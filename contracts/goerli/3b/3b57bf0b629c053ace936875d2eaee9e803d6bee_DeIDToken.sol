// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./ERC777.sol";
import "./AccessControl.sol";
import "./TokenTimelock.sol";
import "./ReentrancyGuard.sol";

/// @title DeID Token
/// @author Created and IP Owned by KhidrX, LLC. Licensed to DeID technology Group
/// @notice
/// @dev Based on ERC777 standard

abstract contract DeIDOffering is ERC777, AccessControl, ReentrancyGuard {
    bytes32 public constant INVESTORS_ROLE = keccak256("INVESTORS_ROLE");
    bytes32 public constant INCUBATION_ROLE = keccak256("INCUBATION_ROLE");
    bytes32 public constant FOUNDERS_ROLE = keccak256("FOUNDERS_ROLE");
    bytes32 public constant CONTRIBUTORS_ROLE = keccak256("CONTRIBUTORS_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FINANCE_ROLE = keccak256("FINANCE_ROLE");
    bytes32 public constant CUSTOMSALE_ROLE = keccak256("CUSTOMSALE_ROLE");
    address public contractcreator;
    address public investorFundOwner;
    address public founderFundOwner;
    address public contributorFundOwner;
    address public reserveOwner;
    address public incubationFundOwner;
    address public openMarketFundOwner;
    uint256 public remainingTokens = 0;
    mapping(address => uint256) private _balances;

    struct Rates {
        uint256 investorBuy;
        uint256 contributorBuy;
        uint256 icoBuy;
        uint256 customBuy;
        uint256 incubatorbuy;
        uint256 generalBuy;
        uint256 investorSale;
        uint256 contributorSale;
        uint256 icoSale;
        uint256 customSale;
        uint256 incubatorSale;
        uint256 generalSale;
    }
    enum State {
        none,
        pauseBuy,
        pauseSell,
        pauseAll,
        off,
        on
    }
    enum Offer {
        icoStart,
        icoEnd,
        genAvailEnd,
        genAvailStart
    }

    Rates internal rate;
    State internal currentState;
    Offer internal currentOffer;

    event ReceievedETH(uint256 amountETH, address addressSender);

    event InvestorBuy(
        uint256 amountETHSent,
        address walletTokensFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensSent
    );

    event ContributorBuy(
        uint256 amountETHSent,
        address walletTokensFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensSent
    );

    event IcoBuy(
        uint256 amountETHSent,
        address walletTokensFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensSent
    );

    event BuyToken(
        uint256 amountETHSent,
        address walletTokensFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensSent
    );

    event Incubatorbuy(
        uint256 amountETHSent,
        address walletTokensFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensSent
    );

    event GeneralBuy(
        uint256 amountETHSent,
        address walletTokensFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensSent
    );

    event InvestorSale(
        uint256 amountETHSold,
        address walletETHFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensReceieved
    );

    event ContributorSale(
        uint256 amountETHSold,
        address walletETHFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensReceieved
    );

    event IcoSale(
        uint256 amountETHSold,
        address walletETHFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensReceieved
    );

    event SellToken(
        uint256 amountETHSold,
        address walletETHFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensReceieved
    );

    event IncubatorSale(
        uint256 amountETHSold,
        address walletETHFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensReceieved
    );

    event GeneralSale(
        uint256 amountETHSold,
        address walletETHFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensReceieved
    );

    event TokenTimeLocked(
        address walletETHFrom,
        address walletSoldTo,
        address msgSender,
        uint256 contractGUID,
        uint256 amountTokensReceieved,
        uint64 releaseDuration,
        address newTokenContract
    );

    /// @dev standard exchange function along with fallback. Allows any user to exchange tokens direct based on price set
    receive() external payable {
        require(
            msg.sender == contractcreator ||
                currentOffer == Offer.genAvailStart ||
                currentOffer == Offer.icoStart
        );
        require(currentState != State.pauseAll || currentState != State.off);
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        if (msg.sender == contractcreator) {
            emit ReceievedETH(amountWei, msg.sender);
        } else if (currentOffer == Offer.icoStart) {
            require(currentState == State.on);
            require(address(msg.sender) != contractcreator);
            conductPurchase(
                amountWei,
                address(this),
                address(msg.sender),
                rate.icoBuy
            );
        } else if (currentOffer == Offer.genAvailStart) {
            require(currentState == State.on);
            require(address(msg.sender) != contractcreator);
            conductPurchase(
                amountWei,
                address(this),
                address(msg.sender),
                rate.generalBuy
            );
        }
    }

    function setStateNone() public onlyRole(FINANCE_ROLE) {
        currentState = State.none;
    }

    function setStatePauseBuy() public onlyRole(FINANCE_ROLE) {
        currentState = State.pauseBuy;
    }

    function setStatePauseSell() public onlyRole(FINANCE_ROLE) {
        currentState = State.pauseSell;
    }

    function setStatePauseAll() public onlyRole(FINANCE_ROLE) {
        currentState = State.pauseAll;
    }

    function setStateOn() public onlyRole(FINANCE_ROLE) {
        currentState = State.on;
    }

    function startIco() public onlyRole(FINANCE_ROLE) {
        currentOffer = Offer.icoStart;
    }

    function endIco() public onlyRole(FINANCE_ROLE) {
        currentOffer = Offer.icoEnd;
    }

    function startGeneral() public onlyRole(FINANCE_ROLE) {
        currentOffer = Offer.genAvailStart;
    }

    function endGeneral() public onlyRole(FINANCE_ROLE) {
        currentOffer = Offer.genAvailEnd;
    }

    function setInvestorBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.investorBuy = price;
    }

    function setContributorBuyRate(uint256 price)
        public
        onlyRole(FINANCE_ROLE)
    {
        rate.contributorBuy = price;
    }

    function setICOBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.icoBuy = price;
    }

    function setCustomBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.customBuy = price;
    }

    function setInvestorSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.investorSale = price;
    }

    function setContributorSaleRate(uint256 price)
        public
        onlyRole(FINANCE_ROLE)
    {
        rate.contributorSale = price;
    }

    function setICOSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.icoSale = price;
    }

    function setCustomSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.customSale = price;
    }

    function investorPurchase() public payable onlyRole(INVESTORS_ROLE) {
        require(
            currentState != State.pauseAll || currentState != State.pauseBuy
        );
        address investorWallet = msg.sender;
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        conductPurchase(
            amountWei,
            address(investorFundOwner),
            address(investorWallet),
            rate.investorBuy
        );
    }

    function investorSell(address investorWallet, uint256 tokensToSell)
        public
        payable
        onlyRole(INVESTORS_ROLE)
    {
        require(
            tokensToSell > 0,
            "No tokens sent for sale, You need to sell at least 1 token"
        );
        require(
            currentState != State.pauseAll || currentState != State.pauseSell
        );
        conductSale(
            tokensToSell,
            investorWallet,
            investorFundOwner,
            rate.investorSale
        );
    }

    function contributorPurchase(address contributorWallet)
        public
        payable
        onlyRole(CONTRIBUTORS_ROLE)
    {
        require(
            currentState != State.pauseAll || currentState != State.pauseBuy
        );
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        conductPurchase(
            amountWei,
            address(contributorFundOwner),
            address(contributorWallet),
            rate.contributorBuy
        );
    }

    function contributorSell(address contributorWallet, uint256 tokensToSell)
        public
        payable
        onlyRole(CONTRIBUTORS_ROLE)
    {
        require(
            currentState != State.pauseAll || currentState != State.pauseSell
        );
        require(tokensToSell > 0, "No tokens sent for sale");
        conductSale(
            tokensToSell,
            contributorWallet,
            contributorFundOwner,
            rate.contributorSale
        );
    }

    function incubationPurchase(address incubatorWallet)
        public
        payable
        onlyRole(INCUBATION_ROLE)
    {
        require(
            currentState != State.pauseAll || currentState != State.pauseBuy
        );
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        conductPurchase(
            amountWei,
            address(incubationFundOwner),
            incubatorWallet,
            rate.incubatorbuy
        );
    }

    function incubationSell(address incubatorWallet, uint256 tokensToSell)
        public
        payable
        onlyRole(INCUBATION_ROLE)
    {
        require(
            currentState != State.pauseAll || currentState != State.pauseSell
        );
        require(
            tokensToSell > 0,
            "No tokens sent for sale, You need to sell at least 1 token"
        );
        conductSale(
            tokensToSell,
            incubatorWallet,
            incubationFundOwner,
            rate.incubatorSale
        );
    }

    function customPurchase(address walletFrom, address walletTo)
        public
        payable
        onlyRole(CUSTOMSALE_ROLE)
    {
        require(
            currentState != State.pauseAll || currentState != State.pauseBuy
        );
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        conductPurchase(
            amountWei,
            address(walletFrom),
            address(walletTo),
            rate.customBuy
        );
    }

    function customSell(
        address walletFrom,
        address walletTo,
        uint256 tokensToSell
    ) public payable onlyRole(CUSTOMSALE_ROLE) {
        require(
            currentState != State.pauseAll || currentState != State.pauseSell
        );
        require(
            tokensToSell > 0,
            "No tokens sent for sale, You need to sell at least 1 token"
        );
        conductSale(tokensToSell, walletFrom, walletTo, rate.customSale);
    }

    function contractDraw() public payable nonReentrant onlyRole(FINANCE_ROLE) {
        require(currentState != State.pauseAll);
        uint256 amountDraw = balanceOf(address(this));
        payable(msg.sender).transfer(amountDraw);
    }

    function conductPurchase(
        uint256 amountWei,
        address walletFrom,
        address walletTo,
        uint256 ratePurchase
    ) internal nonReentrant {
        uint256 currentTokens = (amountWei / ratePurchase) * (1 ether);
        uint256 currentAtoms = (amountWei % ratePurchase) * (1 ether);
        uint256 tokens = currentTokens + currentAtoms;
        this.operatorSend(walletFrom, walletTo, tokens, "", "");
        payable(walletFrom).transfer(amountWei);
        emit BuyToken(
            amountWei,
            walletFrom,
            walletTo,
            address(msg.sender),
            ratePurchase,
            tokens
        );
    }

    function conductSale(
        uint256 tokensToSell,
        address walletFrom,
        address walletTo,
        uint256 rateSale
    ) internal nonReentrant {
        uint256 totalEth = tokensToSell * rateSale;
        this.operatorSend(walletFrom, walletTo, tokensToSell, "", "");
        payable(walletFrom).transfer(totalEth);
        emit SellToken(
            totalEth,
            walletFrom,
            walletTo,
            address(msg.sender),
            rateSale,
            tokensToSell
        );
    }

    function timeLockContract(
        address tokenOwner,
        uint256 tokens,
        address beneficiary_,
        uint64 releaseDuration,
        uint256 contractGUID
    ) public onlyRole(FINANCE_ROLE) {
        require(
            currentState != State.pauseAll || currentState != State.pauseBuy
        );
        IERC20 thisToken = this;
        uint256 releaseTime_ = releaseDuration;
        TokenTimelock lockedContract = new TokenTimelock(
            thisToken,
            beneficiary_,
            releaseTime_
        );
        this.operatorSend(
            address(tokenOwner),
            address(lockedContract),
            tokens,
            "",
            ""
        );
        emit TokenTimeLocked(
            tokenOwner,
            beneficiary_,
            address(msg.sender),
            contractGUID,
            tokens,
            releaseDuration,
            address(lockedContract)
        );
    }
}

contract DeIDToken is DeIDOffering {
    address[] internal operatorList = [address(this), address(msg.sender)];

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address investorFundOwner_,
        address founderFundOwner_,
        address contributorFundOwner_,
        address reserveOwner_,
        address incubationFundOwner_
    ) ERC777(name, symbol, operatorList) {
        investorFundOwner = investorFundOwner_;
        founderFundOwner = founderFundOwner_;
        contributorFundOwner = contributorFundOwner_;
        reserveOwner = reserveOwner_;
        incubationFundOwner = incubationFundOwner_;
        initialMint(
            initialSupply,
            investorFundOwner,
            founderFundOwner,
            contributorFundOwner,
            reserveOwner,
            incubationFundOwner
        );
        contractcreator = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initialMint(
        uint256 initialSupply,
        address investorFundOwner,
        address founderFundOwner,
        address contributorFundOwner,
        address reserveOwner,
        address incubationFundOwner
    ) internal {
        uint256 investorFundAmount = (initialSupply * 15) / 100;
        uint256 founderFundAmount = (initialSupply * 10) / 100;
        uint256 contributorFundAmount = (initialSupply * 10) / 100;
        uint256 totalofferingReserveAmount = (initialSupply * 40) / 100;
        uint256 incubationFundAmount = (initialSupply * 5) / 100;
        uint256 openMarketAmount = (initialSupply * 20) / 100;

        _mint(investorFundOwner, investorFundAmount, "", "");
        _mint(founderFundOwner, founderFundAmount, "", "");
        _mint(contributorFundOwner, contributorFundAmount, "", "");
        _mint(reserveOwner, totalofferingReserveAmount, "", "");
        _mint(incubationFundOwner, incubationFundAmount, "", "");
        _mint(address(this), openMarketAmount, "", "");
    }
}