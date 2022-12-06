// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./ERC777.sol";
import "./AccessControl.sol";
import "./TokenTimelock.sol";
import "./ReentrancyGuard.sol";

/// @title DeID Token
/// @author Created and IP Owned by KhidrX, LLC. Licensed to KUTTA FOUNDATION
/// @notice
/// @dev Based on ERC777 standard

abstract contract KUTTACoinOffering is ERC777, AccessControl, ReentrancyGuard {
    bytes32 public constant INCUBATION_ROLE = keccak256("INCUBATION_ROLE");
    bytes32 public constant FOUNDERS_ROLE = keccak256("FOUNDERS_ROLE");
    bytes32 public constant DONOR_ROLE = keccak256("DONOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FINANCE_ROLE = keccak256("FINANCE_ROLE");
    bytes32 public constant CUSTOMSALE_ROLE = keccak256("CUSTOMSALE_ROLE");
    address public contractcreator;
    address public founderFundOwner;
    address public donationFundOwner;
    address public reserveOwner;
    address public incubationFundOwner;
    address public openMarketFundOwner;
    uint256 public remainingTokens = 0;
    mapping(address => uint256) private _balances;

    struct Rates {
        uint256 donorBuy;
        uint256 icoBuy;
        uint256 customBuy;
        uint256 incubatorbuy;
        uint256 generalBuy;
        uint256 donorSale;
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

    event BuyToken(
        uint256 amountETHSent,
        address walletTokensFrom,
        address walletSoldTo,
        address msgSender,
        uint256 currentRate,
        uint256 amountTokensSent
    );

    event SellToken(
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

    function startIco() public onlyRole(FOUNDERS_ROLE) {
        currentOffer = Offer.icoStart;
    }

    function endIco() public onlyRole(FOUNDERS_ROLE) {
        currentOffer = Offer.icoEnd;
    }

    function startGeneral() public onlyRole(FINANCE_ROLE) {
        currentOffer = Offer.genAvailStart;
    }

    function endGeneral() public onlyRole(FINANCE_ROLE) {
        currentOffer = Offer.genAvailEnd;
    }

    function setDonorBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.donorBuy = price;
    }

    function setICOBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.icoBuy = price;
    }

    function setCustomBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.customBuy = price;
    }

    function setDonorSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.donorSale = price;
    }

    function setICOSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.icoSale = price;
    }

    function setCustomSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.customSale = price;
    }

    function donorPurchase() public payable onlyRole(DONOR_ROLE) {
        require(
            currentState != State.pauseAll || currentState != State.pauseBuy
        );
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        conductPurchase(
            amountWei,
            address(donationFundOwner),
            address(msg.sender),
            rate.donorBuy
        );
    }

    function donorSell(uint256 tokensToSell) public onlyRole(DONOR_ROLE) {
        require(
            tokensToSell > 0,
            "No tokens sent for sale, You need to sell at least 1 token"
        );
        require(
            currentState != State.pauseAll || currentState != State.pauseSell
        );
        conductSale(
            tokensToSell,
            address(msg.sender),
            donationFundOwner,
            rate.donorSale
        );
    }

    function incubationPurchase() public payable onlyRole(INCUBATION_ROLE) {
        require(
            currentState != State.pauseAll || currentState != State.pauseBuy
        );
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        conductPurchase(
            amountWei,
            address(incubationFundOwner),
            address(msg.sender),
            rate.incubatorbuy
        );
    }

    function incubationSell(uint256 tokensToSell)
        public
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
            address(msg.sender),
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
    ) public onlyRole(CUSTOMSALE_ROLE) {
        require(
            currentState != State.pauseAll || currentState != State.pauseSell
        );
        require(
            tokensToSell > 0,
            "No tokens sent for sale, You need to sell at least 1 token"
        );
        conductSale(tokensToSell, walletFrom, walletTo, rate.customSale);
    }

    function contractDraw()
        public
        payable
        nonReentrant
        onlyRole(FOUNDERS_ROLE)
    {
        require(currentState != State.pauseAll);
        uint256 amountDraw = address(this).balance;
        payable(msg.sender).transfer(amountDraw);
    }

    function conductPurchase(
        uint256 amountWei,
        address walletFrom,
        address walletTo,
        uint256 ratePurchase
    ) internal nonReentrant {
        uint256 currentTokens = (amountWei / ratePurchase) * (1 ether);
        uint256 currentHADDIS = (amountWei % ratePurchase) * (1 ether);
        uint256 tokens = currentTokens + currentHADDIS;
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
        uint256 totalETH = (tokensToSell * rateSale) / (1 ether);
        uint256 totalTokens = tokensToSell * 1 ether;
        this.operatorSend(walletFrom, walletTo, totalTokens, "", "");
        emit SellToken(
            totalETH,
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

contract KUTTACoin is KUTTACoinOffering {
    address[] internal operatorList = [address(this), address(msg.sender)];

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address founderFundOwner_,
        address donationFundOwner_,
        address reserveOwner_,
        address incubationFundOwner_
    ) ERC777(name, symbol, operatorList) {
        founderFundOwner = founderFundOwner_;
        donationFundOwner = donationFundOwner_;
        reserveOwner = reserveOwner_;
        incubationFundOwner = incubationFundOwner_;
        initialMint(
            initialSupply,
            founderFundOwner,
            donationFundOwner,
            reserveOwner,
            incubationFundOwner
        );
        contractcreator = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function initialMint(
        uint256 initialSupply,
        address founderFundOwner,
        address donationFundOwner,
        address reserveOwner,
        address incubationFundOwner
    ) internal {
        uint256 founderFundAmount = (initialSupply * 20) / 100;
        uint256 donationFundAmount = (initialSupply * 10) / 100;
        uint256 totalofferingReserveAmount = (initialSupply * 20) / 100;
        uint256 incubationFundAmount = (initialSupply * 10) / 100;
        uint256 openMarketAmount = (initialSupply * 40) / 100;

        _mint(founderFundOwner, founderFundAmount, "", "");
        _mint(donationFundOwner, donationFundAmount, "", "");
        _mint(reserveOwner, totalofferingReserveAmount, "", "");
        _mint(incubationFundOwner, incubationFundAmount, "", "");
        _mint(address(this), openMarketAmount, "", "");
    }
}