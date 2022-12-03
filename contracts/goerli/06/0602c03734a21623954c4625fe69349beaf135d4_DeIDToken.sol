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


abstract contract DeIDOffering is ERC777, AccessControl, ReentrancyGuard  {
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

    struct Rates{ 
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
    
    /// @dev standard exchange function along with fallback. Allows any user to exchange tokens direct based on price set
    receive() external payable nonReentrant {
        require(currentOffer == Offer.icoStart || currentOffer == Offer.genAvailStart || msg.sender == contractcreator);
        require(msg.value > 0, "No ETH Sent");
        uint256 amountWei = msg.value;
        
        if(msg.sender == contractcreator) {   
            }

        if(currentOffer == Offer.icoStart) {
            require(currentState == State.on);
            require(msg.sender != contractcreator);
            transferIcoTokens(amountWei);
            }

        if(currentOffer== Offer.genAvailStart){
            require(currentState == State.on);
            require(msg.sender != contractcreator);
            transferGeneralTokens(amountWei);
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
        rate.investorBuy=price;
    }

    function setContributorBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.contributorBuy=price;
    }

    function setICOBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.icoBuy=price;
    }

    function setCustomBuyRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.customBuy=price;
    }

    function setInvestorSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.investorSale=price;
    }

    function setContributorSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.contributorSale=price;
    }
        
    function setICOSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.icoSale=price;
    }

    function setCustomSaleRate(uint256 price) public onlyRole(FINANCE_ROLE) {
        rate.customSale=price;
    }

    function investorPurchase(address investorWallet) public payable nonReentrant onlyRole(INVESTORS_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseBuy);
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        uint256 currentTokens = (amountWei / rate.investorBuy) * (1 ether);
        uint256 currentAtoms = amountWei -((currentTokens * rate.investorBuy) / (1 ether));
        uint256 tokens= currentTokens+currentAtoms;
      
        if(investorWallet == address(0)) {
            investorWallet=address(msg.sender);
        }

        this.operatorSend(investorFundOwner, address(investorWallet), tokens, "", "");
        payable(investorFundOwner).transfer(amountWei);
    }

    function investorSell(address investorWallet, uint256 tokensToSell) public payable nonReentrant onlyRole(INVESTORS_ROLE) {
        require(tokensToSell > 0, "No tokens sent for sale, You need to sell at least 1 token");
        require(currentState != State.pauseAll || currentState != State.pauseSell);
        uint256 currentWei = (tokensToSell * rate.investorSale) / (1 ether);

        if(investorWallet ==address(0)) {
            investorWallet=address(msg.sender);
        }

        this.operatorSend(investorWallet, investorFundOwner, tokensToSell,"","");
        payable(investorWallet).transfer(currentWei);
    }
    
    function contributorPurchase(address contributorWallet) public payable nonReentrant onlyRole(CONTRIBUTORS_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseBuy);
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        uint256 currentTokens = (amountWei / rate.contributorBuy) * (1 ether);
        uint256 currentAtoms =amountWei -((currentTokens * rate.contributorBuy) / (1 ether));
        uint256 tokens= currentTokens+currentAtoms;
        
        if(contributorWallet ==address(0)) {
            contributorWallet=address(msg.sender);
        }  
        
        this.transferFrom(address(contributorFundOwner),address(contributorWallet),tokens);
        payable(contributorFundOwner).transfer(amountWei);
     }

    function contributorSell(address contributorWallet, uint256 tokensToSell) public payable nonReentrant onlyRole(CONTRIBUTORS_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseSell);
        require(tokensToSell > 0, "No tokens sent for sale");
        uint256 currentWei =  (tokensToSell * rate.contributorSale) / (1 ether);
          
        if(contributorWallet == address(0)) {
            contributorWallet=address(msg.sender);
        }
        
        this.transferFrom(contributorWallet, contributorFundOwner, tokensToSell);
        payable(contributorWallet).transfer(currentWei);
    }
    
    function incubationPurchase(address incubatorWallet) public payable nonReentrant onlyRole(INCUBATION_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseBuy);
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        uint256 currentTokens = (amountWei / rate.incubatorbuy) * (1 ether);
        uint256 currentAtoms = amountWei -((currentTokens * rate.incubatorbuy) / (1 ether));
        uint256 tokens= currentTokens+currentAtoms;
        this.transferFrom(address(incubationFundOwner),address(incubatorWallet),tokens);
        payable(incubationFundOwner).transfer(amountWei);
    }

    function incubationSell(address incubatorWallet, uint256 tokensToSell) public payable nonReentrant onlyRole(INCUBATION_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseSell);
        require(tokensToSell > 0, "No tokens sent for sale, You need to sell at least 1 token");
        uint256 currentWei =  (tokensToSell * rate.incubatorSale) / (1 ether);

        if(incubatorWallet == address(0)) {
            incubatorWallet=address(msg.sender);
        }

        this.transferFrom(incubatorWallet, incubationFundOwner, tokensToSell);
        payable(incubatorWallet).transfer(currentWei);
    }

    function customPurchase(address walletFrom, address walletTo) public payable nonReentrant onlyRole(CUSTOMSALE_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseBuy);
        uint256 amountWei = msg.value;
        require(amountWei > 0, "No ETH Sent");
        uint256 currentTokens = (amountWei / rate.customBuy) * (1 ether);
        uint256 currentAtoms = amountWei -((currentTokens * rate.customBuy) / (1 ether));
        uint256 tokens= currentTokens+currentAtoms;
        this.transferFrom(address(walletFrom),address(walletTo),tokens);
        payable(walletFrom).transfer(amountWei);
    }

    function customSell(address walletFrom, address walletTo, uint256 tokensToSell) public payable onlyRole(CUSTOMSALE_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseSell);
        require(tokensToSell > 0, "No tokens sent for sale, You need to sell at least 1 token");
        uint256 currentWei =  (tokensToSell * rate.customSale) / (1 ether);
        this.transferFrom(walletFrom, walletTo, tokensToSell);
        payable(walletFrom).transfer(currentWei); 
    }

    function contractDraw(uint256 amountDraw, address walletTo) public onlyRole(FINANCE_ROLE) {
        require(currentState != State.pauseAll);
        payable(walletTo).transfer(amountDraw); 
    }

    function transferIcoTokens(uint256 amountWei) internal nonReentrant {
        require(currentState != State.pauseAll);
        uint256 currentTokens = (amountWei / rate.icoBuy) * (1 ether);
        uint256 currentatoms = amountWei -((currentTokens * rate.icoBuy) / (1 ether));
        uint256 tokens= currentTokens+ currentatoms;
        this.transfer(address(msg.sender),tokens);
     }
    
    function transferGeneralTokens(uint256 amountWei) internal nonReentrant {
        require(currentState != State.pauseAll);
        uint256 currentTokens = (amountWei / rate.generalBuy) * (1 ether);
        uint256 currentatoms = amountWei -((currentTokens * rate.generalBuy) / (1 ether));
        uint256 tokens= currentTokens+ currentatoms;
        this.transfer(address(msg.sender),tokens);
     }
 
    function timeLockContract(address tokenOwner, uint256 tokens, address beneficiary_, uint64 releaseDuration) public nonReentrant onlyRole(FINANCE_ROLE) {
        require(currentState != State.pauseAll || currentState != State.pauseBuy);
        IERC20 thisToken = this;
        uint256 releaseTime_ = releaseDuration;
        TokenTimelock lockedContract = new TokenTimelock(thisToken,beneficiary_,releaseTime_);
        this.transferFrom(address(tokenOwner),address(lockedContract),tokens);   
    }
}


contract DeIDToken is DeIDOffering {
        address[] internal operatorList=[address(this),address(msg.sender)];
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address investorFundOwner_,
        address founderFundOwner_,
        address contributorFundOwner_,
        address reserveOwner_,
        address incubationFundOwner_   
      ) 
      ERC777(name, symbol, operatorList) {
        investorFundOwner=investorFundOwner_;
        founderFundOwner= founderFundOwner_;
        contributorFundOwner= contributorFundOwner_;
        reserveOwner= reserveOwner_;
        incubationFundOwner= incubationFundOwner_;
        initialMint( initialSupply, investorFundOwner, founderFundOwner, contributorFundOwner, reserveOwner, incubationFundOwner);
        contractcreator=msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      }
      
    function initialMint (
        uint256 initialSupply,
        address investorFundOwner, 
        address founderFundOwner,
        address contributorFundOwner, 
        address reserveOwner,
        address incubationFundOwner
        ) internal {      

        uint256 investorFundAmount = (initialSupply * 15) / 100 ;
        uint256 founderFundAmount= (initialSupply * 10) / 100;
        uint256 contributorFundAmount = (initialSupply * 10) / 100;
        uint256 totalofferingReserveAmount= (initialSupply * 40) / 100;
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