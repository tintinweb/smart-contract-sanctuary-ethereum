// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./OpenZeppelin/ERC20.sol";
import "./OpenZeppelin/Ownable.sol";
import "./Chainlink/AggregatorV3Interface.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/ReentrancyGuard.sol";
import "./AoriSeats.sol";

contract AoriCall is ERC20, ReentrancyGuard {
    address public immutable factory;
    address public oracle; //Must be USD Denominated Chainlink Oracle with 8 decimals
    uint256 public immutable strikeInUSDC;
    uint256 public immutable endingBlock;
    uint256 public immutable duration; //duration in blocks
    IERC20 public immutable UNDERLYING;
    IERC20 public immutable USDC = IERC20(0x0F9A00aA7567b767Cff825D67B7E8dAf649e71AE);
    uint256 public settlementPrice;
    uint256 public immutable feeMultiplier;
    uint256 public immutable decimalDiff;
    bool public hasEnded = false;
    AoriSeats public immutable AORISEATSADD = AoriSeats(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D); //joke test address
    mapping (address => uint256) optionSellers; 


    constructor(
        uint256 _feeMultiplier,
        uint256 _strikeInUSDC,
        uint256 _duration, //in blocks
        IERC20 _UNDERLYING,
        address _oracle,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_, 18) {
        factory = msg.sender;
        feeMultiplier = _feeMultiplier;
        strikeInUSDC = _strikeInUSDC; 
        duration = _duration; //in blocks
        endingBlock = block.number + duration;
        UNDERLYING = _UNDERLYING;
        decimalDiff = (10**UNDERLYING.decimals()) / (10**USDC.decimals()); //The underlying decimals must be greater than or equal to USDC's decimals.
        oracle = _oracle;
    }

    event CallMinted(uint256 optionsMinted, address minter);
    event CallBuyerITMSettled(uint256 optionsRedeemed, address settler);
    event CallSellerITMSettled(uint256 optionsRedeemed, address settler);
    event CallSellerOTMSettled(uint256 optionsRedeemed, address settler);
    event SellerRetrievedFunds(uint256 tokensRetrieved, address seller);

    function setOracle(address newOracle) public returns(address) {
        require(msg.sender == AORISEATSADD.owner());
        oracle = newOracle;
        return oracle;
    }
    /**
        Mints a call option equivalent to the quantity of the underlying asset divided by
        the strike price as quoted in USDC. 
        Note that this does NOT sell the option for you.
        You must list the option in an OptionSwap orderbook to actually be paid for selling this option.
     */
    function mintCall(uint256 quantityOfUNDERLYING, uint256 seatId) public nonReentrant returns (uint256) {
        //confirming the user has enough of the UNDERLYING
        require(UNDERLYING.decimals() == 18 && block.number < endingBlock); //safety check
        require(UNDERLYING.balanceOf(msg.sender) >= quantityOfUNDERLYING);
        require(AORISEATSADD.confirmExists(seatId));

        uint256 mintingFee;
        uint256 refRate;
        uint256 feeToSeat;
        uint256 optionsToMint;
        //Checks seat ownership, and assigns fees and transfers accordingly
        if (msg.sender == AORISEATSADD.ownerOf(seatId)) {
            //If the owner of the seat IS the caller, fees are 0
            mintingFee = 0;
            refRate = 0;
            feeToSeat = 0;
            optionsToMint = (quantityOfUNDERLYING * (10**USDC.decimals())) / strikeInUSDC;
            //transfer the UNDERLYING
            UNDERLYING.transferFrom(msg.sender, address(this), quantityOfUNDERLYING);
            _mint(msg.sender, optionsToMint);
        } else {
            //If the owner of the seat is not the caller, calculate and transfer the fees
            mintingFee = callUNDERLYINGFeeCalculator(quantityOfUNDERLYING, AORISEATSADD.getOptionMintingFee());
            // Calculating the fees out of 100 to go to the seat owner
            refRate = (AORISEATSADD.getSeatScore(seatId) * 5) + 35;
            feeToSeat = (refRate * mintingFee) / 100; 
            optionsToMint = ((quantityOfUNDERLYING - mintingFee) * (10**USDC.decimals())) / strikeInUSDC;

            //transfer the UNDERLYING and route fees
            UNDERLYING.transferFrom(msg.sender, address(this), optionsToMint);
            UNDERLYING.transferFrom(msg.sender, Ownable(factory).owner(), mintingFee - feeToSeat);
            UNDERLYING.transferFrom(msg.sender, AORISEATSADD.ownerOf(seatId), feeToSeat);

            AORISEATSADD.addPoints((feeMultiplier * ((mintingFee - feeToSeat)) / decimalDiff), msg.sender);
            AORISEATSADD.addPoints((feeMultiplier * feeToSeat) / decimalDiff, AORISEATSADD.ownerOf(seatId));

            //mint the user LP tokens
            _mint(msg.sender, optionsToMint);
        }

        //storing this option seller's information for future settlement
        uint256 currentOptionsSold = optionSellers[msg.sender];
        uint256 newOptionsSold = currentOptionsSold + optionsToMint;
        optionSellers[msg.sender] = newOptionsSold;

        emit CallMinted(optionsToMint, msg.sender);

        return (optionsToMint);
    }

    /**
        Sets the settlement price immediately upon the maturation
        of this option. Anyone can set the settlement into motion.
        Note the settlement price is converted to USDC Scale via getPrice();
     */
    function _setSettlementPrice() internal returns (uint256) {
        require(block.number >= endingBlock);
        if(hasEnded == false) {
            settlementPrice = uint256(getPrice());
            hasEnded = true;
        }
        return settlementPrice;
    }

    /**
        Gets the option minting fee from AoriSeats and
        Calculates the minting fee in BPS of the underlying token
     */
    function callUNDERLYINGFeeCalculator(uint256 optionsToSettle, uint256 fee) internal view returns (uint256) {
        require(UNDERLYING.decimals() == 18);
        uint256 txFee = (optionsToSettle * fee) / 10000;
        return txFee;
    }

    /**
        Takes the quantity of options the user wishes to settle then
        calculates the quantity of USDC the user must pay the contract
        Note this calculation only occurs for in the money options.
     */
    function scaleToUSDCAtStrike(uint256 optionsToSettle) internal view returns (uint256) {
        uint256 tokenDecimals = 10**UNDERLYING.decimals();
        uint256 scaledVal = (optionsToSettle * strikeInUSDC) / tokenDecimals; //(1e18 * 1e6) / 1e18
        return scaledVal;
    }

    /**
        In the money settlement procedures for an option purchaser.
        The settlement price must exceed the strike price for this function to be callable
        Then the user must transfer USDC according to the following calculation: (USDC * strikeprice) * optionsToSettle;
        Then the user receives the underlying ERC20 at the strike price.
     */
    function buyerSettlementITM(uint256 optionsToSettle) public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(block.number >= endingBlock && balanceOf[msg.sender] >= optionsToSettle);
        require(settlementPrice > strikeInUSDC  && settlementPrice != 0);
        require(hasEnded == true && optionsToSettle <= totalSupply);
        require(optionsToSettle != 0);
        //Calculating the profit using a ratio of settlement price
        //minus the strikeInUSDC, then dividing by the settlement price.
        //This gives us the total number of underlying tokens to give the settler.
        uint256 profitPerOption = ((settlementPrice - strikeInUSDC) * 10**USDC.decimals()) / settlementPrice; // (1e6 * 1e6) / 1e6
        uint256 UNDERLYINGOwed = (profitPerOption * optionsToSettle) / 10**USDC.decimals(); //1e6 * 1e18 / 1e6 
        
        _burn(msg.sender, optionsToSettle);
        UNDERLYING.transfer(msg.sender, UNDERLYINGOwed); //sending 1e18 scale tokens to user

        emit CallBuyerITMSettled(optionsToSettle, msg.sender);

        return (optionsToSettle);
    }

    /**
        In the money settlement procedures for an option seller.
        The option seller receives USDC equivalent to the strike price * the number of options they sold.
     */
    function sellerSettlementITM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        uint256 optionsToSettle = optionSellers[msg.sender];
        require(block.number >= endingBlock);
        require(optionsToSettle > 0);
        require(settlementPrice > strikeInUSDC && hasEnded == true);

        uint256 UNDERLYINGToReceive = ((strikeInUSDC * 10**USDC.decimals()) / settlementPrice) * optionsToSettle; // (1e6*1e6/1e6) * 1e18
        //store the settlement
        optionSellers[msg.sender] = 0;
    
        //settle
        UNDERLYING.transfer(msg.sender, UNDERLYINGToReceive / 10**USDC.decimals());
        
        emit CallSellerITMSettled(optionsToSettle, msg.sender);

        return optionsToSettle;
    }   

    /**
        Settlement procedures for an option sold that expired out of the money.
        The seller receives all of their underlying assets back while retaining the premium from selling.
     */
    function sellerSettlementOTM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(block.number >= endingBlock);
        require(optionSellers[msg.sender] > 0 && settlementPrice <= strikeInUSDC);
        uint256 optionsSold = optionSellers[msg.sender];

        //store the settlement
        optionSellers[msg.sender] = 0;

        //settle
        UNDERLYING.transfer(msg.sender, optionsSold);

        emit CallSellerOTMSettled(optionsSold, msg.sender);

        return optionsSold;
    }

    /**
     *  VIEW FUNCTIONS
    */

    /** 
        Get the price converted from Chainlink format to USDC
    */
    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(oracle).latestRoundData();
        if(price == 0) {
            return strikeInUSDC;
        }
        else {
            return (uint256(price) / (10**(8 - 10**USDC.decimals()))); 
        }
    }
    /** 
        For frontend ease. If 1 then the option is ITM, if 0 then it is OTM. 
    */
    function getITMorOTM() public view returns (uint256) {
        require(settlementPrice != 0);
        if (settlementPrice > strikeInUSDC) {
            return 1;
        } else {
            return 0;
        }
    }

    function getOptionsSold(address seller_) public view returns (uint256) {
        return optionSellers[seller_];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./OpenZeppelin/ERC20.sol";
import "./OpenZeppelin/Ownable.sol";
import "./Chainlink/AggregatorV3Interface.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/ReentrancyGuard.sol";
import "./AoriSeats.sol";

contract AoriPut is ERC20, ReentrancyGuard {
    address public immutable factory;
    address public oracle; //Must be USD Denominated Chainlink Oracle with 8 decimals
    uint256 public immutable strikeInUSDC; //This is in 1e6 scale
    uint256 public immutable endingBlock;
    uint256 public immutable duration; //duration in blocks
    uint256 public settlementPrice; //price to be set at expiration
    uint256 public immutable feeMultiplier;
    uint256 public immutable decimalDiff;
    bool public hasEnded = false;
    IERC20 public USDC = IERC20(0x0F9A00aA7567b767Cff825D67B7E8dAf649e71AE);
    AoriSeats public immutable AORISEATSADD = AoriSeats(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D); //joke test address

    mapping (address => uint256) optionSellers; 
    

    constructor(
        uint256 _feeMultiplier,
        uint256 _strikeInUSDC,
        uint256 _duration, //in blocks
        address _oracle,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_, 18) {
        feeMultiplier = _feeMultiplier;
        factory = msg.sender;
        strikeInUSDC = _strikeInUSDC; 
        duration = _duration; //in blocks
        endingBlock = block.number + duration;
        oracle = _oracle;
        decimalDiff = (10**18) / (10**USDC.decimals());
    }

    event PutMinted(uint256 optionsMinted, address minter);
    event PutBuyerITMSettled(uint256 optionsRedeemed, address settler);
    event PutSellerITMSettled(uint256 optionsRedeemed, address settler);
    event PutSellerOTMSettled(uint256 optionsRedeemed, address settler);
    event SellerRetrievedFunds(uint256 tokensRetrieved, address seller);

    function setOracle(address newOracle) public returns(address) {
        require(msg.sender == AORISEATSADD.owner());
        oracle = newOracle;
        return oracle;
    }

    /**
        Mints a Put option equivalent to the USDC being deposited divided by the strike price.
        Note that this does NOT sell the option for you.
        You must list the option in an OptionSwap orderbook to actually be paid for selling this option.
     */
    function mintPut(uint256 quantityOfUSDC, uint256 seatId) public nonReentrant returns (uint256) {
        //confirming the user has enough USDC
        require(block.number < endingBlock);
        require(USDC.balanceOf(msg.sender) >= quantityOfUSDC && (AORISEATSADD.confirmExists(seatId)));
        
        uint256 mintingFee;
        uint256 feeToSeat;
        uint256 optionsToMint;
        uint256 optionsToMintScaled;
        if (msg.sender == AORISEATSADD.ownerOf(seatId)) {
            //If the owner of the seat IS the caller, fees are 0
            mintingFee = 0;
            feeToSeat = 0;
            optionsToMint = (quantityOfUSDC * 1e6) / strikeInUSDC;
            optionsToMintScaled = optionsToMint * decimalDiff; //convert the USDC to 1e18 scale to mint LP tokens

            //transfer the USDC
            USDC.transferFrom(msg.sender, address(this), optionsToMint);
            _mint(msg.sender, optionsToMintScaled);
        } else {
            //If the owner of the seat is not the caller, calculate and transfer the fees
            mintingFee = putUSDCFeeCalculator(quantityOfUSDC, AORISEATSADD.getOptionMintingFee());
            uint256 refRate = (AORISEATSADD.getSeatScore(seatId) * 5) + 35;
            // Calculating the fees out of 100 to go to the seat owner
            feeToSeat = (refRate * mintingFee) / 100;     
            optionsToMint = ((quantityOfUSDC - mintingFee) * 10**USDC.decimals()) / strikeInUSDC; //(1e6*1e6) / 1e6
            optionsToMintScaled = optionsToMint * decimalDiff;

            //transfer the USDC and route fees
            USDC.transferFrom(msg.sender, address(this), optionsToMint);
            USDC.transferFrom(msg.sender, Ownable(factory).owner(), mintingFee - feeToSeat);
            USDC.transferFrom(msg.sender, AORISEATSADD.ownerOf(seatId), feeToSeat);
            
            AORISEATSADD.addPoints(feeMultiplier * mintingFee - feeToSeat, msg.sender);
            AORISEATSADD.addPoints(feeMultiplier * feeToSeat, AORISEATSADD.ownerOf(seatId));
            //mint the user LP tokens
            _mint(msg.sender, optionsToMintScaled);
        }

        //storing this option seller's information for future settlement
        uint256 currentOptionsSold = optionSellers[msg.sender];
        uint256 newOptionsSold = currentOptionsSold + optionsToMintScaled;
        optionSellers[msg.sender] = newOptionsSold;

        emit PutMinted(optionsToMintScaled, msg.sender);

        return (optionsToMintScaled);
    }

    /**
        Sets the settlement price immediately upon the maturation
        of this option. Anyone can set the settlement into motion.
        Note the settlement price is converted to USDC Scale via getPrice();
     */
    function _setSettlementPrice() internal returns (uint256) {
        require(block.number >= endingBlock);
        if(hasEnded == false) {
            settlementPrice = uint256(getPrice());
            hasEnded = true;
        }
        return settlementPrice;
    }

    /**
        Essentially a MulDiv functio but for calculating BPS conversions
     */
    function putUSDCFeeCalculator(uint256 quantityOfUSDC, uint256 fee) internal pure returns (uint256) {
        uint256 txFee = (quantityOfUSDC * fee) / 10000;
        return txFee;
    }
     /**
     * IN THE MONEY SETTLEMENT PROCEDURES
     * FOR IN THE MONEY OPTIONS SETTLEMENT
     * 
     */

    //Buyer Settlement ITM
    function buyerSettlementITM(uint256 optionsToSettle) public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(block.number >= endingBlock && balanceOf[msg.sender] >= 0);
        require(strikeInUSDC > settlementPrice && settlementPrice != 0);
        require(hasEnded == true && optionsToSettle <= totalSupply);

        uint256 profitPerOption = strikeInUSDC - settlementPrice;
        //Normalize the optionsToSettle to USDC scale then multiply by profit per option to get USDC Owed to the settler.
        uint256 USDCOwed = ((optionsToSettle / decimalDiff) * profitPerOption) / 10**USDC.decimals(); //((1e18 / 1e12) * 1e6) / 1e6
        //transfers
        _burn(msg.sender, optionsToSettle);
        USDC.transfer(msg.sender, USDCOwed);

        emit PutBuyerITMSettled(optionsToSettle, msg.sender);
        return (optionsToSettle);
    }


    /**
        Settlement procedures for an option sold that expired in of the money.
        The seller receives a portion of their underlying assets back relative to the
        strike price and settlement price. 
     */

    function sellerSettlementITM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        uint256 optionsToSettle = optionSellers[msg.sender];
        require(block.number >= endingBlock);
        require(optionsToSettle >= 0);
        require(strikeInUSDC > settlementPrice && hasEnded == true);

        //Calculating the USDC to receive ()
        uint256 USDCToReceive = ((optionsToSettle * settlementPrice) / decimalDiff) / 10**USDC.decimals(); //((1e18 / 1e12) * 1e6) / 1e6
        //store the settlement
        optionSellers[msg.sender] = 0;
    
        //settle
        USDC.transfer(msg.sender, USDCToReceive);
        
        emit PutSellerITMSettled(optionsToSettle, msg.sender);

        return optionsToSettle;
    }   

    /**
        Settlement procedures for an option sold that expired out of the money.
        The seller receives all of their underlying assets back while retaining the premium from selling.
     */
    function sellerSettlementOTM() public nonReentrant returns (uint256) {
        _setSettlementPrice();
        require(block.number >= endingBlock);
        require(optionSellers[msg.sender] > 0 && settlementPrice >= strikeInUSDC);
        uint256 optionsSold = optionSellers[msg.sender];

        //store the settlement
        optionSellers[msg.sender] = 0;

        //settle
        uint256 USDCOwed = ((optionsSold / decimalDiff) * strikeInUSDC) / 10**USDC.decimals(); //((1e18 / 1e12) * 1e6) / 1e6
        USDC.transfer(msg.sender, USDCOwed);

        emit PutSellerOTMSettled(optionsSold, msg.sender);

        return optionsSold;
    }

    /**
     *  VIEW FUNCTIONS
    */

    /** 
        Get the price of the underlying converted from Chainlink format to USDC.
    */
    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(oracle).latestRoundData();
        if (price == 0) {
            return strikeInUSDC;
        } else {
            return (uint256(price) / (10**(8 - 10**USDC.decimals())));
        }
    }
    /** 
        For frontend ease. If 1 then the option is ITM, if 0 then it is OTM.
    */ 
    function getITMorOTM() public view returns (uint256) {
        require(settlementPrice != 0);
        if (settlementPrice < strikeInUSDC) {
            return 1;
        } else {
            return 0;
        }
    }
    
    function getOptionsSold(address seller_) public view returns (uint256) {
        return optionSellers[seller_];
    }
}

// SPDX-License-Identifier: UNLICENSED
/**
           :=*#%%@@@@@@@%%#*=-.         
        =#@@#+==--=+*@@@@@@@@@@@#-      
      :@@%-           :*@@@@@@@@@@@-    
      @@%                [email protected]@@@@@@@@@    
     [email protected]@%                  [email protected]@@@@@@%    
      #@@*                   -+##*=     
       *@@@+:                           
        :#@@@%=.                        
          :#@@@@%=.                     
            [email protected]@@@@%+.                  
               =%@@@@@%+:               
                 :#@@@@@@%+.            
                   -%@@@@@@@%=          
            .-+#%@@@@%#@@@@@@@@*:       
         -*%@@@@#=:    .*@@@@@@@@#:     
      [email protected]@@@@%-          .%@@@@@@@@*    
    .#@@@@@@-              [email protected]@@@@@@@%.  
   [email protected]@@@@@%.                [email protected]@@@@@@@@. 
  #@@@@@@@.                  [email protected]@@@@@@@% 
 #@@@@@@@+                    #@@@@@@@@+
[email protected]@@@@@@@.     %        #.    [email protected]@@@@@@@%
#@@@@@@@@      @*-....:[email protected]     %@@@@@@@@
@@@@@@@@%      @@@@@@@@@@.     *@@@@@@@@
@@@@@@@@%      @@%#**##@@.     *@@@@@@@#
%@@@@@@@@      @.       %.     #@@@@@@@-
[email protected]@@@@@@@-     =        -      @@@@@@@* 
 %@@@@@@@%                    [email protected]@@@@@#  
 .%@@@@@@@#                  :@@@@@@=   
  .#@@@@@@@#.               [email protected]@@@@#.    
    -%@@@@@@@+            .*@@@@#:      
      -#@@@@@@@*=:    .:=#@@@%+.        
         -*%@@@@@@@@@@@@@%*=. 
              &@@@@@@@@%
 */
pragma solidity 0.8.13;

import "./OpenZeppelin/ERC721Enumerable.sol";
import "./OpenZeppelin/IERC20.sol";
import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/ReentrancyGuardUpgradeable.sol";
import "./CallFactory.sol";
import "./PutFactory.sol";
import "./OrderbookFactory.sol";

/**
    Storage for all Seat NFT management and fee checking
 */
contract AoriSeats is ERC721Enumerable, Ownable, ReentrancyGuard {

     uint256 maxSeats;
     uint256 public currentSeatId;
     uint256 mintFee;
     bool public saleIsActive = false;
     uint256 public maxSeatScore;
     uint256 public feeMultiplier;
     CallFactory public CALLFACTORY;
     PutFactory public PUTFACTORY;
     address public minter;
     OrderbookFactory public ORDERBOOKFACTORY;
     mapping(uint256 => uint256) seatScore;
     mapping(address => uint256) pointsTotal;
     mapping(uint256 => uint256) totalVolumeBySeat;

     constructor(
         string memory name_,
         string memory symbol_,
         uint256 maxSeats_, //default 3318
         uint256 mintFee_,
         uint256 maxSeatScore_,
         uint256 feeMultiplier_
     ) ERC721(name_, symbol_) {
         maxSeats = maxSeats_;
         mintFee = mintFee_;
         maxSeatScore = maxSeatScore_;
         feeMultiplier = feeMultiplier_;
     }

    event FeeSetForSeat (uint256 seatId, address SeatOwner);
    event MaxSeatChange (uint256 NewMaxSeats);
    event MinFeeChange (uint256 NewMinFee);

    /** 
    Admin control functions
    */


    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function setCallFactory(CallFactory newCALLFACTORY) public onlyOwner returns (CallFactory) {
        CALLFACTORY = newCALLFACTORY;
        return CALLFACTORY;
    }

    function setPutFactory(PutFactory newPUTFACTORY) public onlyOwner returns (PutFactory) {
        PUTFACTORY = newPUTFACTORY;
        return PUTFACTORY;
    }
    
    function setOrderbookFactory(OrderbookFactory newORDERBOOKFACTORY) public onlyOwner returns (OrderbookFactory) {
        ORDERBOOKFACTORY = newORDERBOOKFACTORY;
        return ORDERBOOKFACTORY;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function mintSeat() external returns (uint256) {
        require(msg.sender == minter);
        if (currentSeatId % 10 == 0) {
            _mint(owner(), currentSeatId++);
        }
        _mint(minter, currentSeatId++);
        return currentSeatId;
    }
    /** 
        Combines two seats and adds their scores together
        Enabling the user to retain a higher portion of the fees collected from their seat
    */
    function combineSeats(uint256 seatIdOne, uint256 seatIdTwo) public returns(uint256) {
        require(msg.sender == ownerOf(seatIdOne) && msg.sender == ownerOf(seatIdTwo));
        uint256 newSeatScore = seatScore[seatIdOne] + seatScore[seatIdTwo];
        require(newSeatScore <= maxSeatScore);
        _burn(seatIdOne);
        _burn(seatIdTwo);
        uint256 newSeatId = currentSeatId++;
        _safeMint(msg.sender, newSeatId);
        seatScore[newSeatId] = newSeatScore;
        return seatScore[newSeatId];
    }

    /**
        Mints the user a series of one score seats
     */
    function separateSeats(uint256 seatId) public {
        require(msg.sender == ownerOf(seatId));
        uint256 currentSeatScore = seatScore[seatId];
        seatScore[seatId] = 1; //Reset the original seat
        _burn(seatId); //Burn the original seat
        //Mint the new seats
        for(uint i = 0; i < currentSeatScore; i++) {
            uint mintIndex = currentSeatId++;
            _safeMint(msg.sender, mintIndex);
            seatScore[mintIndex] = 1;
        }
    }

    /** 
        Score = Liquidity mining rewards claimable by the userAdd.
        Note once claimed, the user's claimable rewards are reset to 0
        But their pointsTotal remains.
        Must be called by the Call or Put contract itself.
    */
    function addPoints(uint256 pointsToAdd, address userAdd) public nonReentrant {
        //confirms via Orderbook contract that the msg.sender is a call or put market created by the OPTIONTROLLER
        require(CALLFACTORY.checkIsListed(msg.sender) || PUTFACTORY.checkIsListed(msg.sender)); 
        uint256 currentPoints = pointsTotal[userAdd];

        pointsTotal[userAdd] = currentPoints + pointsToAdd;
    }
    /** 
        Score = Liquidity mining rewards claimable by the userAdd.
        Note once claimed, the user's claimable rewards are reset to 0
        But their pointsTotal remains.
        Must be called by the bid/ask itself.
    */
    function addTakerPoints(uint256 pointsToAdd, address userAdd, address Orderbook_) public nonReentrant {
        //confirms that the msg.sender is an bid/ask originating from the OPTIONTROLLER
        require(ORDERBOOKFACTORY.checkIsOrder(Orderbook_, msg.sender)); 
        uint256 currentPoints = pointsTotal[userAdd];

        pointsTotal[userAdd] = currentPoints + pointsToAdd;
    }

    /** 
        Volume = total notional trading volume through the seat
        For data tracking purposes.
    */
    function addTakerVolume(uint256 volumeToAdd, uint256 seatId, address Orderbook_) public nonReentrant {
        //confirms via Orderbook contract that the msg.sender is a call or put market created by the OPTIONTROLLER
        require(ORDERBOOKFACTORY.checkIsOrder(Orderbook_, msg.sender));
        
        uint256 currentVolume = totalVolumeBySeat[seatId];
        totalVolumeBySeat[seatId] = currentVolume + volumeToAdd;
    }


    /**
        Change the total number of seats
     */
    function setMaxSeats(uint256 newMaxSeats) public onlyOwner returns (uint256) {
        maxSeats = newMaxSeats;
        emit MaxSeatChange(newMaxSeats);
        return maxSeats;
    }
     /**
        Change the number of points for taking bids/asks and minting options
     */
    function setFeeMultiplier(uint256 newFeeMultiplier) public onlyOwner returns (uint256) {
        feeMultiplier = newFeeMultiplier;
        return feeMultiplier;
    }

    /**
        Change the maximum number of seats that can be combined
        Currently if this number exceeds 12 the Orderbook will break
     */
    function setMaxSeatScore(uint256 newMaxScore) public onlyOwner returns(uint256) {
        require(newMaxScore > maxSeatScore);
        maxSeatScore = newMaxScore;
        return maxSeatScore;
    }
    /** 
        Change the minimum mintingfee
    */
    function setMinFee(uint256 newMintFee) public onlyOwner returns (uint256) {
        mintFee = newMintFee;
        emit MinFeeChange(newMintFee);
        return mintFee;
    }

    /**
    VIEW FUNCTIONS
     */
    function getOptionMintingFee() public view returns (uint256) {
        return mintFee;
    }

    function confirmExists(uint256 seatId) public view returns (bool) {
        return _exists(seatId);
    }

    function getPoints(address user) public view returns (uint256) {
        return pointsTotal[user];
    }

    function getSeatScore(uint256 seatId) public view returns (uint256) {
        return seatScore[seatId];
    }
    
    function getFeeMultiplier() public view returns (uint256) {
        return feeMultiplier;
    }

    function getSeatVolume(uint256 seatId) public view returns (uint256) {
        return totalVolumeBySeat[seatId];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./OpenZeppelin/IERC20.sol";
import "./AoriSeats.sol";
import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/ReentrancyGuard.sol";
import "./Chainlink/AggregatorV3Interface.sol";

contract Ask is ReentrancyGuard {
    address public immutable factory;
    address public immutable maker;
    uint256 public immutable USDCPerOPTION;
    uint256 public immutable OPTIONSize;
    uint256 public immutable fee; // in bps, default is 30 bps
    uint256 public immutable feeMultiplier;
    uint256 public immutable duration;
    uint256 public endingBlock;
    AoriSeats public immutable AORISEATSADD = AoriSeats(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    bool public hasEnded = false;
    bool public hasBeenFunded = false;
    IERC20 public OPTION;
    IERC20 public USDC; 
    uint256 public OPTIONDecimals = OPTION.decimals();
    uint256 public USDCDecimals = USDC.decimals();
    uint256 public decimalDiff = (10**OPTIONDecimals) / (10**USDCDecimals);

    event OfferFunded(address maker, uint256 OPTIONSize, uint256 duration);
    event Filled(address buyer, uint256 OPTIONAmount, uint256 AmountFilled, bool hasEnded);
    event OfferCanceled(address maker, uint256 OPTIONAmount);

    constructor(
        IERC20 _OPTION,
        IERC20 _USDC, 
        address _maker,
        uint256 _USDCPerOPTION,
        uint256 _fee,
        uint256 _feeMultiplier,
        uint256 _duration, //in blocks
        uint256 _OPTIONSize
    ) {
        factory = msg.sender;
        OPTION = _OPTION;
        USDC = _USDC;
        maker = _maker;
        USDCPerOPTION = _USDCPerOPTION;
        fee = _fee;
        feeMultiplier = _feeMultiplier;
        duration = _duration;
        OPTIONSize = _OPTIONSize;
    }
    

    
    // release trapped funds
    function withdrawTokens(address token) public {
        require(msg.sender == Ownable(factory).owner());
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(Ownable(factory).owner()).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            safeTransfer(token, Ownable(factory).owner(), balance);
        }
    }

    /**
        Fund the Ask with Aori option ERC20's
     */
    function fundContract() public nonReentrant {
        require(msg.sender == factory);
        require(OPTION.balanceOf(msg.sender) >= OPTIONSize);
        OPTION.transferFrom(msg.sender, address(this), OPTIONSize);
        hasBeenFunded = true;
        //officially begin the countdown
        endingBlock = block.number + duration;
        emit OfferFunded(maker, OPTIONSize, duration);
    }
    /**
        Partial or complete fill of the offer, with the requirement of trading through a seat
        regardless of whether the seat is owned or not.
        In the case of not owning the seat, a fee is charged in USDC.
     */
    function fill(uint256 amountOfUSDC, uint256 seatId) public nonReentrant {
        require(isFunded(), "no option balance");
        require(msg.sender != maker);
        require(!hasEnded, "offer has been previously been cancelled");
        require(block.number <= endingBlock, "This offer has expired");

        uint256 USDCAfterFee;
        uint256 OPTIONToReceive;

        if(msg.sender == AORISEATSADD.ownerOf(seatId)) {
            //Seat holders receive 0 fees for trading
            USDCAfterFee = amountOfUSDC;
            OPTIONToReceive = mulDiv(USDCAfterFee, 10**OPTIONDecimals, USDCPerOPTION); //1eY = (1eX * 1eY) / 1eX
            //transfers To the msg.sender
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            //transfer to the Msg.sender
            OPTION.transfer(msg.sender, OPTIONToReceive);
        } else {
            //What the user will receive out of 100 percent in referral fees with a floor of 40
            uint256 refRate = (AORISEATSADD.getSeatScore(seatId) * 5) + 35; 
            //This means for Aori seat governance they should not allow more than 12 seats to be combined at once
            uint256 seatScoreFeeInBPS = mulDiv(fee, refRate, 100);
            //calculating the fee breakdown 
            uint256 seatTxFee = mulDiv(amountOfUSDC, seatScoreFeeInBPS, 10000);
            uint256 ownerTxFee = mulDiv(amountOfUSDC, fee - seatScoreFeeInBPS, 10000);
            //Calcualting the base tokens to transfer after fees
            USDCAfterFee = (amountOfUSDC - (ownerTxFee + seatTxFee));
            //And the amount of the quote currency the msg.sender will receive
            OPTIONToReceive = mulDiv(USDCAfterFee, 10**OPTIONDecimals, USDCPerOPTION); //(1e6 * 1e18) / 1e6 = 1e18
            //Transfers from the msg.sender
            USDC.transferFrom(msg.sender, Ownable(factory).owner(), ownerTxFee);
            USDC.transferFrom(msg.sender, AORISEATSADD.ownerOf(seatId), seatTxFee);
            USDC.transferFrom(msg.sender, maker, USDCAfterFee);
            //Transfers to the msg.sender
            OPTION.transfer(msg.sender, OPTIONToReceive);
            //Tracking the liquidity mining rewards
            AORISEATSADD.addTakerPoints(feeMultiplier * (ownerTxFee / decimalDiff), msg.sender, factory);
            AORISEATSADD.addTakerPoints(feeMultiplier * (seatTxFee / decimalDiff), AORISEATSADD.ownerOf(seatId), factory);
            //Tracking the volume in the NFT
            AORISEATSADD.addTakerVolume(amountOfUSDC, seatId, factory);
        }
        if(OPTION.balanceOf(address(this)) == 0) {
            hasEnded = true;
        }
        emit Filled(msg.sender, USDCAfterFee, amountOfUSDC, hasEnded);
    }
    /**
        Cancel this order and refund all remaining tokens
    */
    function cancel() public nonReentrant {
        require(isFunded(), "no OPTION balance");
        require(msg.sender == maker);
        uint256 balance = OPTION.balanceOf(address(this));
        
        OPTION.transfer(msg.sender, balance);
        hasEnded = true;
        emit OfferCanceled(maker, balance);
    }
    
    //Check if the contract is funded still.
    function isFunded() public view returns (bool) {
        if (OPTION.balanceOf(address(this)) > 0) {
            return true;
        } else {
            return false;
        }
    }
    //View function to see if this offer still holds one USDC
    function isFundedOverOne() public view returns (bool) {
        if (OPTION.balanceOf(address(this)) > (10 ** OPTION.decimals())) {
            return true;
        } else {
            return false;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: failed");
    }


    /**
        Additional view functions 
    */
    function getCurrentBalance() public view returns (uint256) {
        if (OPTION.balanceOf(address(this)) >= 1) {
            return OPTION.balanceOf(address(this));
        } else {
            return 0;
        }
    }
    function getAmountFilled() public view returns (uint256) {
        if(hasBeenFunded == true) {
            return (OPTIONSize - getCurrentBalance());
        } else {
            return 0;
        }
    }
    function getOPTIONSize() public view returns (uint256) {
        return OPTIONSize;
    }
    function getDuration() public view returns (uint256) {
        return duration;
    }
    function getEndingBlock() public view returns (uint256) {
        return endingBlock;
    }
    function getUSDCPerQuote() public view returns (uint256) {
        return USDCPerOPTION;
    }
    function getMaker() public view returns (address) {
        return maker;
    }
    function getOPTION() public view returns (IERC20) {
        return OPTION;
    }
    function getUSDC() public view returns (IERC20) {
        return USDC;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./OpenZeppelin/IERC20.sol";
import "./AoriSeats.sol";
import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/ReentrancyGuard.sol";
import "./Chainlink/AggregatorV3Interface.sol";

contract Bid is ReentrancyGuard {
    address public immutable factory;
    address public immutable maker;
    uint256 public immutable OPTIONPerUSDC;
    uint256 public immutable USDCSize;
    uint256 public immutable fee; // in bps, default is 30 bps
    uint256 public immutable feeMultiplier;
    uint256 public immutable duration;
    uint256 public endingBlock;
    AoriSeats public immutable AORISEATSADD = AoriSeats(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    bool public hasEnded = false;
    bool public hasBeenFunded = false;
    IERC20 public USDC;
    IERC20 public OPTION;
    uint256 public USDCDecimals = USDC.decimals();
    uint256 public OPTIONDecimals = OPTION.decimals();
    uint256 public decimalDiff = (10**OPTIONDecimals) / (10**USDCDecimals);

    event OfferFunded(address maker, uint256 USDCSize, uint256 duration);
    event Filled(address buyer, uint256 USDCAmount, uint256 AmountFilled, bool hasEnded);
    event OfferCanceled(address maker, uint256 USDCAmount);

    constructor(
        IERC20 _USDC,
        IERC20 _OPTION, 
        address _maker,
        uint256 _OPTIONPerUSDC,
        uint256 _fee,
        uint256 _feeMultiplier,
        uint256 _duration, //in blocks
        uint256 _USDCSize
    ) {
        factory = msg.sender;
        USDC = _USDC;
        OPTION = _OPTION;
        maker = _maker;
        OPTIONPerUSDC = _OPTIONPerUSDC;
        fee = _fee;
        feeMultiplier = _feeMultiplier;
        duration = _duration;
        USDCSize = _USDCSize;
    }
    

    
    // release trapped funds
    function withdrawTokens(address token) public {
        require(msg.sender == Ownable(factory).owner());
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(Ownable(factory).owner()).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            safeTransfer(token, Ownable(factory).owner(), balance);
        }
    }
    
    /**
        Fund the Ask with Aori option ERC20's
     */
    function fundContract() public nonReentrant {
        require(msg.sender == factory);
        require(USDC.balanceOf(msg.sender) >= USDCSize);
        USDC.transferFrom(msg.sender, address(this), USDCSize);
        //officially begin the countdown
        endingBlock = block.number + duration;
        emit OfferFunded(maker, USDCSize, duration);
    }
    /**
        Partial or complete fill of the offer, with the requirement of trading through a seat
        regardless of whether the seat is owned or not.
        In the case of not owning the seat, a fee is charged in USDC.
    */
    function fill(uint256 amountOfOPTION, uint256 seatId) public nonReentrant {
        require(isFunded(), "no option balance");
        require(msg.sender != maker);
        require(!hasEnded, "offer has been previously been cancelled");
        require(block.number <= endingBlock, "This offer has expired");

        uint256 OPTIONAfterFee;
        uint256 USDCToReceive;

        if(msg.sender == AORISEATSADD.ownerOf(seatId)) {
            //Seat holders receive 0 fees for trading
            OPTIONAfterFee = amountOfOPTION;
            USDCToReceive = mulDiv(OPTIONAfterFee, 10**USDCDecimals, OPTIONPerUSDC); //1eY = (1eX * 1eY) / 1eX
            //Transfers
            OPTION.transferFrom(msg.sender, maker, OPTIONAfterFee);
            USDC.transfer(msg.sender, USDCToReceive);
        } else {
            //No taker fees are paid in option tokens, but rather USDC.
            OPTIONAfterFee = amountOfOPTION;
            //And the amount of the quote currency the msg.sender will receive
            USDCToReceive = mulDiv(OPTIONAfterFee, 10**USDCDecimals, OPTIONPerUSDC); //1eY = (1eX * 1eY) / 1eX

            //What the user will receive out of 100 percent in referral fees with a floor of 40
            uint256 refRate = (AORISEATSADD.getSeatScore(seatId) * 5) + 35; 
            //This means for Aori seat governance they should not allow more than 12 seats to be combined at once
            uint256 seatScoreFeeInBPS = mulDiv(fee, refRate, 100);
            uint256 seatTxFee = mulDiv(USDCToReceive, seatScoreFeeInBPS, 10000);
            uint256 ownerTxFee = mulDiv(USDCToReceive, fee - seatScoreFeeInBPS, 10000); 
            //Transfers from the msg.sender
            OPTION.transferFrom(msg.sender, maker, OPTIONAfterFee);

            //Fee transfers are all in USDC, so for Bids they're routed here
            //These are to the Factory, the Aori seatholder, then the buyer respectively.
            USDC.transfer(Ownable(factory).owner(), ownerTxFee);
            USDC.transfer(AORISEATSADD.ownerOf(seatId), seatTxFee);
            USDC.transfer(msg.sender, USDCToReceive);
            //Tracking the liquidity mining rewards
            AORISEATSADD.addTakerPoints(feeMultiplier * (ownerTxFee / decimalDiff), maker, factory);
            AORISEATSADD.addTakerPoints(feeMultiplier * (seatTxFee / decimalDiff), AORISEATSADD.ownerOf(seatId), factory);
            //Tracking the volume in the NFT
            AORISEATSADD.addTakerVolume(USDCToReceive + ownerTxFee + seatTxFee, seatId, factory);
        }
        if(USDC.balanceOf(address(this)) == 0) {
            hasEnded = true;
        }
        emit Filled(msg.sender, OPTIONAfterFee, amountOfOPTION, hasEnded);
    }

    /**
        Cancel this order and refund all remaining tokens
    */
    function cancel() public nonReentrant {
        require(isFunded(), "no USDC balance");
        require(msg.sender == maker);
        uint256 balance = USDC.balanceOf(address(this));
        
        USDC.transfer(msg.sender, balance);
        hasEnded = true;
        emit OfferCanceled(maker, balance);
    }

    //Check if the contract is funded still.
    function isFunded() public view returns (bool) {
        if (USDC.balanceOf(address(this)) > 0) {
            return true;
        } else {
            return false;
        }
    }
    //View function to see if this offer still holds one USDC
    function isFundedOverOne() public view returns (bool) {
        if (USDC.balanceOf(address(this)) > (10 ** USDC.decimals())) {
            return true;
        } else {
            return false;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransfer: failed");
    }

    /**
        Additional view functions 
    */
    function getCurrentBalance() public view returns (uint256) {
        if (USDC.balanceOf(address(this)) >= 1) {
            return USDC.balanceOf(address(this));
        } else {
            return 0;
        }
    }
    function getAmountFilled() public view returns (uint256) {
        if(hasBeenFunded == true) {
            return (USDCSize - getCurrentBalance());
        } else {
            return 0;
        }
    }
    function getUSDCSize() public view returns (uint256) {
        return USDCSize;
    }
    function getDuration() public view returns (uint256) {
        return duration;
    }
    function getEndingBlock() public view returns (uint256) {
        return endingBlock;
    }
    function getOPTIONPerQuote() public view returns (uint256) {
        return OPTIONPerUSDC;
    }
    function getMaker() public view returns (address) {
        return maker;
    }
    function getUSDC() public view returns (IERC20) {
        return USDC;
    }
    function getOPTION() public view returns (IERC20) {
        return OPTION;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./OpenZeppelin/Ownable.sol";
import "./AoriSeats.sol";
import "./AoriCall.sol";
import "./OpenZeppelin/IERC20.sol";

contract CallFactory is Ownable {

    mapping(address => bool) isListed;
    address[] callMarkets;
    address public keeper;
    uint256 public fee;
    AoriSeats public immutable AORISEATSADD = AoriSeats(0x61c2A549DE258F875Ae9E995FEBF96C9f6806731);

    event AoriCallCreated(
            address AoriCallAdd,
            uint256 strike, 
            uint256 duration, 
            IERC20 underlying, 
            address oracle, 
            string name, 
            string symbol
        );

    /**
        Set the keeper of the Optiontroller.
        The keeper controls and deploys all new markets and orderbooks.
    */
    function setKeeper(address newKeeper) public onlyOwner returns(address) {
        keeper = newKeeper;
        return newKeeper;
    }
    /**
        Deploys a new call option token at a designated strike and maturation block.
        Additionally deploys an orderbook to pair with the new ERC20 option token.
    */
    function createCallMarket(
            uint256 strikeInUSDC, 
            uint256 duration, 
            IERC20 UNDERLYING, 
            address oracle, 
            string memory name_, 
            string memory symbol_
            ) public returns (AoriCall) {

        require(msg.sender == keeper);

        AoriCall callMarket = new AoriCall(AORISEATSADD.getFeeMultiplier(), strikeInUSDC, duration, UNDERLYING, oracle, name_, symbol_);
        
        isListed[address(callMarket)] = true;
        callMarkets.push(address(callMarket));

        emit AoriCallCreated(address(callMarket), strikeInUSDC, duration, UNDERLYING, oracle, name_, symbol_);
        return (callMarket);
    }

    //Checks if an individual Call/Put is listed
    function checkIsListed(address market) public view returns(bool) {
        return isListed[market];
    }
}

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "../OpenZeppelin/IERC20.sol"; 
import "../Ask.sol";
import "../Bid.sol"; 
import "../AoriCall.sol";
import "../AoriPut.sol";
import "../Orderbook.sol"; 
import "../OpenZeppelin/Ownable.sol";

contract AoriLens {
    //Get specific information about a certain ask
    function getAskInfo(Ask ask)
        public
        view
        returns (
            IERC20 OPTION,
            uint256 USDCPerOption,
            uint256 endingBlock,
            uint256 balance
        )
    {
        return (ask.getOPTION(), ask.USDCPerOPTION(), ask.endingBlock(), ask.getCurrentBalance());
    }
    //Get specific information about a certain ask
    function getBidInfo(Bid bid)
        public
        view
        returns (
            IERC20 USDC,
            uint256 OPTIONPerUSDC,
            uint256 endingBlock,
            uint256 balance
        )
    {
        return (bid.getUSDC(), bid.OPTIONPerUSDC(), bid.endingBlock(), bid.getCurrentBalance());
    }

    //Get all active asks of an orderbook
    function getActiveAsks(Orderbook factory) public view returns (Ask[] memory) {
        return factory.getActiveAsks();
    }
    //Get all active bids of an orderbook
    function getActiveBids(Orderbook factory) public view returns (Bid[] memory) {
        return factory.getActiveBids();
    }
    function getActiveAsksAboveOne(Orderbook factory) public view returns (Ask[] memory) {
        Ask[] memory allAsks = factory.getActiveAsks();
        Ask[] memory activeAsks = new Ask[](allAsks.length);
        uint256 count;
        for (uint256 i; i < allAsks.length; i++) {
            Ask ask = Ask(allAsks[i]);
            if (ask.isFundedOverOne() && !ask.hasEnded()) {
                activeAsks[count++] = ask;
            }
        }

        return activeAsks;
    }

    function getActiveBidsAboveOne(Orderbook factory) public view returns (Bid[] memory) {
        Bid[] memory bids = factory.getActiveBids();
        Bid[] memory activeBids = new Bid[](bids.length);
        uint256 count;
        for (uint256 i; i < bids.length; i++) {
            Bid bid = Bid(bids[i]);
            if (bid.isFundedOverOne() && !bid.hasEnded()) {
                activeBids[count++] = bid;
            }
        }

        return activeBids;
    }

    function getActiveAsksByOwner(Orderbook factory) public view returns (Ask[] memory, Ask[] memory) {
        Ask[] memory allAsks = factory.getActiveAsks();
        Ask[] memory myAsks = new Ask[](allAsks.length);
        Ask[] memory otherAsks = new Ask[](allAsks.length);

        uint256 myAsksCount;
        uint256 otherAsksCount;
        for (uint256 i; i < allAsks.length; i++) {
            Ask ask = Ask(allAsks[i]);
            if (ask.isFunded() && !ask.hasEnded()) {
                if (ask.maker() == msg.sender) {
                    myAsks[myAsksCount++] = allAsks[i];
                } else {
                    otherAsks[otherAsksCount++] = allAsks[i];
                }
            }
        }

        return (myAsks, otherAsks);
    }

    function getActiveBidsByOwner(Orderbook factory) public view returns (Bid[] memory, Bid[] memory) {
        Bid[] memory allBids = factory.getActiveBids();
        Bid[] memory myBids = new Bid[](allBids.length);
        Bid[] memory otherBids = new Bid[](allBids.length);

        uint256 myBidsCount;
        uint256 otherBidsCount;
        for (uint256 i; i < allBids.length; i++) {
            Bid bid = Bid(allBids[i]);
            if (bid.isFunded() && !bid.hasEnded()) {
                if (bid.maker() == msg.sender) {
                    myBids[myBidsCount++] = allBids[i];
                } else {
                    otherBids[otherBidsCount++] = allBids[i];
                }
            }
        }

        return (myBids, otherBids);
    }

    function getActiveLongCalls(AoriCall call, address buyer) public view returns (uint256) {
        return call.balanceOf(buyer);
    }
    
    function getActiveLongPuts(AoriPut put, address buyer) public view returns (uint256) {
        return put.balanceOf(buyer);
    }

    function getActiveShortCalls(AoriCall call, address seller) public view returns (uint256) {
        return call.getOptionsSold(seller);
    }
    
    function getActiveShortPuts(AoriCall put, address seller) public view returns (uint256) {
        return put.getOptionsSold(seller);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    //Base URI
    string private _baseURI;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }


    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }


    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

                // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

    function decimals() external view returns (uint8);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./Math.sol";
import "./SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./OpenZeppelin/Ownable.sol";
import "./AoriSeats.sol";
import "./Bid.sol";
import "./Ask.sol";

contract Orderbook is Ownable {
    address public OPTIONTROLLER;
    AoriSeats public AORISEATSADD = AoriSeats(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

    IERC20 public immutable OPTION;
    IERC20 public immutable USDC = IERC20(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
    uint256 public immutable fee_; // 30 default
    Ask[] public asks;
    Bid[] public bids;
    mapping(address => bool) isAsk;
    mapping(address => bool) isBid;

    constructor(
        uint256 _fee,
        IERC20 _OPTION
    ) {
        OPTIONTROLLER = msg.sender;
        OPTION = _OPTION;
        fee_ = _fee;
    }

    event AskCreated(address ask, uint256 , uint256 duration, uint256 OPTIONSize);
    event BidCreated(address bid, uint256 , uint256 duration, uint256 _USDCSize);

    /**
        Deploys an Ask.sol with the following parameters.    
     */
    function createAsk(uint256 _USDCPerOPTION, uint256 _duration, uint256 _OPTIONSize) public returns (Ask) {
        Ask ask = new Ask(OPTION, USDC, msg.sender, _USDCPerOPTION, fee_, AORISEATSADD.getFeeMultiplier() , _duration, _OPTIONSize);
        ask.fundContract(); //Funds the limit order
        asks.push(ask);
        isAsk[address(ask)] = true;
        emit AskCreated(address(ask), _USDCPerOPTION, _duration, _OPTIONSize);
        return ask;
    }
    /**
        Deploys an Bid.sol with the following parameters.    
     */
    function createBid(uint256 _OPTIONPerUSDC, uint256 _duration, uint256 _USDCSize) public returns (Bid) {
        Bid bid = new Bid(USDC, OPTION, msg.sender, _OPTIONPerUSDC, fee_, AORISEATSADD.getFeeMultiplier() , _duration, _USDCSize);
        bid.fundContract(); //Funds the limit order
        bids.push(bid);
        isBid[address(bid)] = true;
        emit BidCreated(address(bid), _OPTIONPerUSDC, _duration, _USDCSize);
        return bid;
    }

    /**
        Accessory view functions to get data about active bids and asks of this orderbook
     */

    function getActiveAsks() public view returns (Ask[] memory) {
        Ask[] memory activeAsks = new Ask[](asks.length);
        uint256 count;
        for (uint256 i; i < asks.length; i++) {
            Ask ask = Ask(asks[i]);
            if (ask.isFunded() && !ask.hasEnded()) {
                activeAsks[count++] = ask;
            }
        }

        return activeAsks;
    }
    
    function getActiveBids() public view returns (Bid[] memory) {
        Bid[] memory activeBids = new Bid[](bids.length);
        uint256 count;
        for (uint256 i; i < bids.length; i++) {
            Bid bid = Bid(bids[i]);
            if (bid.isFunded() && !bid.hasEnded()) {
                activeBids[count++] = bid;
            }
        }

        return activeBids;
    }

    function getIsAsk(address ask) public view returns (bool) {
        return isAsk[ask];
    }
    
    function getIsBid(address bid) public view returns (bool) {
        return isBid[bid];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./OpenZeppelin/Ownable.sol";
import "./OpenZeppelin/IERC20.sol";
import "./Orderbook.sol";

contract OrderbookFactory is Ownable {

    mapping(address => bool) isListedOrderbook;
    address[] orderbookAdds;
    address public keeper;
    uint256 public fee;

    event AoriCallOrderbookCreated(
        address AoriCallMarketAdd,
        uint256 fee,
        IERC20 underlyingAsset
    );
 
    event AoriPutOrderbookCreated(
        address AoriPutMarketAdd,
        uint256 fee
    );

    /**
        Set the keeper of the Optiontroller.
        The keeper controls and deploys all new markets and orderbooks.
    */
    function setKeeper(address newKeeper) public onlyOwner returns(address) {
        keeper = newKeeper;
        return newKeeper;
    }
    /**
        Sets the trading fee for the protocol.
     */
    function setTradingFee(uint256 newFee) public onlyOwner returns(uint256) {
        fee = newFee;
        return fee;
    }
    /**
        Deploys a new call option token at a designated strike and maturation block.
        Additionally deploys an orderbook to pair with the new ERC20 option token.
    */
    function createOrderbook(
            IERC20 OPTION_
            ) public returns (Orderbook) {

        require(msg.sender == keeper);

        Orderbook orderbook =  new Orderbook(fee, OPTION_); 
        
        isListedOrderbook[address(orderbook)] = true;
        orderbookAdds.push(address(orderbook));

        emit AoriCallOrderbookCreated(address(orderbook), fee, OPTION_);
        return (orderbook);
    }

    //Checks if an individual Orderbook is listed
    function checkIsListedOrderbook(address Orderbook_) public view returns(bool) {
        return isListedOrderbook[Orderbook_];
    }
    //Confirms for points that the Orderbook is a listed orderbook, THEN that the order is a listed order.
    function checkIsOrder(address Orderbook_, address order_) public view returns(bool) {
        require(checkIsListedOrderbook(Orderbook_), "Orderbook is not listed"); 
        require(Orderbook(Orderbook_).getIsBid(order_) == true || Orderbook(Orderbook_).getIsAsk(order_) == true, "Is not a confirmed order");

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./OpenZeppelin/Ownable.sol";
import "./AoriSeats.sol";
import "./AoriPut.sol";
import "./OpenZeppelin/IERC20.sol";

contract PutFactory is Ownable {

    mapping(address => bool) isListed;
    address[] putMarkets;
    address public keeper;
    uint256 public fee;
    AoriSeats public AORISEATSADD = AoriSeats(0x61c2A549DE258F875Ae9E995FEBF96C9f6806731);

    event AoriPutCreated(
            IERC20 AoriPutAdd,
            uint256 strike, 
            uint256 duration, 
            address oracle, 
            string name, 
            string symbol
        );

    /**
        Set the keeper of the Optiontroller.
        The keeper controls and deploys all new markets and orderbooks.
    */
    function setKeeper(address newKeeper) public onlyOwner returns(address) {
        keeper = newKeeper;
        return newKeeper;
    }

    /**
        Deploys a new put option token at a designated strike and maturation block.
        Additionally deploys an orderbook to pair with the new ERC20 option token.
    */
    function createPutMarket(
            uint256 strikeInUSDC, 
            uint256 duration, 
            address oracle, 
            string memory name_, 
            string memory symbol_
            ) public returns (AoriPut) {

        require(msg.sender == keeper);

        AoriPut putMarket = new AoriPut(AORISEATSADD.getFeeMultiplier(), strikeInUSDC, duration, oracle, name_, symbol_);

        isListed[address(putMarket)] = true;
        putMarkets.push(address(putMarket));

        emit AoriPutCreated(IERC20(address(putMarket)), strikeInUSDC, duration, oracle, name_, symbol_);
        return (putMarket);
    }

    //Checks if an individual Call/Put is listed
    function checkIsListed(address market) public view returns(bool) {
        return isListed[market];
    }
}