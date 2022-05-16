//SPDX-License-Identifier: MIT
import './ReentrancyGuard.sol';
import './ILockedNFT.sol';
import './IGlobalGovernanceSettings.sol';
import './Ownable.sol';
import './IERC20.sol';

pragma solidity ^0.8.0;

contract TradingMarket is Ownable, ReentrancyGuard {
    address public constant eth = address(0);
    bool public emergencyStop = false;

    mapping(address => mapping(bytes => bool)) public userToSignatureToIsInvalid; //disable the sign forever after calling this function
    mapping(address => bool) public userToDisableSignatures; //handle the state of using the signature of the user i.e. if false >> user is enable his/her signature
    mapping(bytes => uint) public usedCountForBuyOrSell;

    IGlobalGovernanceSettings public immutable governanceSettings;
    
    event BuyFNFT(address indexed buyer, address indexed seller, bytes signature, uint amount, uint price, address currency, address indexed fnftContractAddress);
    event SellFNFT(address indexed buyer, address indexed seller, bytes signature, uint amount, uint price, address currency, address indexed fnftContractAddress);

    enum Status {
        forFractionSale,
        inLiveAuction,
        auctionEnd,
        redeemed,
        boughtOut
    }

    constructor(address _governanceSettings) {
        governanceSettings = IGlobalGovernanceSettings(_governanceSettings);
    }
    
    function toggleStopTrading() public onlyOwner {
        emergencyStop = !emergencyStop;
    }
    
    ///@notice enable or disable your all signatures
    function toggleDisableSignatures() public {
        userToDisableSignatures[msg.sender] = !userToDisableSignatures[msg.sender];
    }
    
    ///@notice disable the chosed signature forever
    function invalidateSignature(bytes memory _signature) public {
        userToSignatureToIsInvalid[msg.sender][_signature] = true;
    }
    
    ///@notice buy any FNFT you choosed using other currency (weth, dai, usdc, usdt)
    //amountForSell >> seller wish to sell how much FNFT?
    function buyFNFT(uint _buyAmount, bytes memory _signature, address _seller, uint _amountForSale, uint _price, address _currency, uint _expireTime, address _fnftContractAddress) public nonReentrant {
        require(verify(_signature, _seller, _amountForSale, _price, _currency, 2, _expireTime, _fnftContractAddress) == true, "The signature is invalid");
        require(governanceSettings.currencyToAcceptableForTrading(_currency) == true, "The currency is not accepted now");
        require(userToSignatureToIsInvalid[_seller][_signature] == false, "The signature was invalidated");
        require(block.timestamp < _expireTime, "The order is expired");
        require((usedCountForBuyOrSell[_signature] + _buyAmount) <= _amountForSale);
        require(emergencyStop == false, "Trading is not available now");
        require(userToDisableSignatures[_seller] == false, "User disabled signatures from being used");
        require(ILockedNFT(_fnftContractAddress).checkCurrentStatus() == 0 || ILockedNFT(_fnftContractAddress).checkCurrentStatus() == 1, "The fnft contract is not allow to trade");
        
        require((_price * _buyAmount) >= 1 ether, "price * amount must > 1 ether!");
        uint totalPrice = _price * _buyAmount / 1 ether;
        uint feeForGovernance = governanceSettings.tradingFee() * totalPrice / 10000;
        uint feeForCurator = ILockedNFT(_fnftContractAddress).ownerTradingFee() * totalPrice / 10000;
        
        usedCountForBuyOrSell[_signature] += _buyAmount;
        
        require(IERC20(_currency).transferFrom(msg.sender, ILockedNFT(_fnftContractAddress).curator(), feeForCurator), "You don't have enough balance");
        require(IERC20(_currency).transferFrom(msg.sender, governanceSettings.feeClaimer(), feeForGovernance), "You don't have enough balance");
        require(IERC20(_currency).transferFrom(msg.sender, _seller, totalPrice - feeForGovernance - feeForCurator), "You don't have enough balance");
        require(IERC20(_fnftContractAddress).transferFrom(_seller, msg.sender, _buyAmount), "The seller doesn't have enough FNFT for sale");
        
        emit BuyFNFT(msg.sender, _seller, _signature, _buyAmount, _price, _currency, _fnftContractAddress);
    }
    
    //buyAmount = number of FNFT user want to buy
    //price = price per FNFT
    ///@notice buy any FNFT you choosed using eth
    function buyFNFTWithETH(uint _buyAmount, bytes memory _signature, address _seller, uint _amountForSale, uint _price, uint _expireTime, address _fnftContractAddress) public payable nonReentrant {
        require(verify(_signature, _seller, _amountForSale, _price, eth, 2, _expireTime, _fnftContractAddress) == true, "The signature is invalid");
        require(governanceSettings.currencyToAcceptableForTrading(eth) == true, "The currency is not accepted now");
        require(userToSignatureToIsInvalid[_seller][_signature] == false, "The signature was invalidated");
        require(block.timestamp < _expireTime, "The order is expired");
        require((usedCountForBuyOrSell[_signature] + _buyAmount) <= _amountForSale);
        require(emergencyStop == false, "Trading is not available now");
        require(userToDisableSignatures[_seller] == false, "User disabled signatures from being used");
        require(ILockedNFT(_fnftContractAddress).checkCurrentStatus() == 0 || ILockedNFT(_fnftContractAddress).checkCurrentStatus() == 1, "The fnft contract is not allow to trade");

        require((_price * _buyAmount) > 1 ether, "price * amount must > 1 ether!");
        uint totalPrice = _price * _buyAmount / 1 ether; //total money that user need to pay(unit in ether)
        uint feeForGovernance = governanceSettings.tradingFee() * totalPrice / 10000; // trading fee/10000 => getting percentage
        uint feeForCurator = ILockedNFT(_fnftContractAddress).ownerTradingFee() * totalPrice / 10000;

        usedCountForBuyOrSell[_signature] += _buyAmount; //if amount exceed, the amount for sale is exceed
        
        require(msg.value >= totalPrice, "You didn't send enough money");
        payable(governanceSettings.feeClaimer()).transfer(feeForGovernance); //pay to governance
        payable(ILockedNFT(_fnftContractAddress).curator()).transfer(feeForCurator); //pay fee to curator
        payable(_seller).transfer(totalPrice - feeForGovernance - feeForCurator);
        payable(msg.sender).transfer(msg.value - totalPrice);
        require(IERC20(_fnftContractAddress).transferFrom(_seller, msg.sender, _buyAmount), "The seller doesn't have enough FNFT for sale");
        
        emit BuyFNFT(msg.sender, _seller, _signature, _buyAmount, _price, eth, _fnftContractAddress);
    }
    
    ///@notice the owner of FNFT sell the FNFT to the pointed buyer
    function sellFNFT(uint _sellAmount, bytes memory _signature, address _buyer, uint _amountForPurchase, uint _price, address _currency, uint _expireTime, address _fnftContractAddress) public nonReentrant {
        require(verify(_signature, _buyer, _amountForPurchase, _price, _currency, 1, _expireTime, _fnftContractAddress) == true, "The signature is invalid");
        require((_currency != eth) && (governanceSettings.currencyToAcceptableForTrading(_currency) == true), "The currency is not accepted now");
        require(userToSignatureToIsInvalid[_buyer][_signature] == false, "The signature was invalidated");
        require(block.timestamp < _expireTime, "The order is expired");
        require((usedCountForBuyOrSell[_signature] + _sellAmount) <= _amountForPurchase);
        require(emergencyStop == false, "Trading is not available now");
        require(userToDisableSignatures[_buyer] == false, "User disabled signatures from being used");
        require(ILockedNFT(_fnftContractAddress).checkCurrentStatus() == 0 || ILockedNFT(_fnftContractAddress).checkCurrentStatus() == 1, "The fnft contract is not allow to trade");

        require((_price * _sellAmount) >= 1 ether, "price * amount must > 1 ether!");
        uint totalPrice = _price * _sellAmount / 1 ether;
        uint feeForGovernance = governanceSettings.tradingFee() * totalPrice / 10000;
        uint feeForCurator = ILockedNFT(_fnftContractAddress).ownerTradingFee() * totalPrice / 10000;
        
        usedCountForBuyOrSell[_signature] += _sellAmount;

        require(IERC20(_currency).transferFrom(_buyer, ILockedNFT(_fnftContractAddress).curator(), feeForCurator), "The buyer doesn't have enough balance");
        require(IERC20(_currency).transferFrom(_buyer, governanceSettings.feeClaimer(), feeForGovernance), "The buyer doesn't have enough balance");
        require(IERC20(_currency).transferFrom(_buyer, msg.sender, totalPrice - feeForGovernance - feeForCurator), "The buyer doesn't have enough balance");
        require(IERC20(_fnftContractAddress).transferFrom(msg.sender, _buyer, _sellAmount), "You don't have enough FNFT for sale");
        
        emit SellFNFT(_buyer, msg.sender, _signature, _sellAmount, _price, _currency, _fnftContractAddress);
    }

    function getMessageHash(
        uint _amount,
        uint _price,
        address _currency,
        uint _forBuyOrForSell, // for buy = 1, for sell = 2
        uint _expireTime,
        address _fnftContractAddress
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_amount, _price, _currency, _forBuyOrForSell, _expireTime, _fnftContractAddress));
    }

    function getMessageHashWithETH(
        uint _amount,
        uint _price,
        uint _forBuyOrForSell, // for buy = 1, for sell = 2
        uint _expireTime,
        address _fnftContractAddress
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_amount, _price, eth, _forBuyOrForSell, _expireTime, _fnftContractAddress));
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verify(
        bytes memory signature,
        address _signer,
        uint _amount,
        uint _price,
        address _currency,
        uint _forBuyOrForSell, // for buy = 1, for sell = 2
        uint _expireTime,
        address _fnftContractAddress
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_amount, _price, _currency, _forBuyOrForSell, _expireTime, _fnftContractAddress);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    //find out the signer
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}