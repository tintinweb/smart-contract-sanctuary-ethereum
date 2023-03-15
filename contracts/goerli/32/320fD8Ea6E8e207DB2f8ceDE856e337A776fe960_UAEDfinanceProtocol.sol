// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UAEDfinancePool.sol";
import "./UAEDProtocolRequestor.sol";
import "./UAED.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IFlashLoanReceiver {
    function executeOperation(uint premium, uint8 assetId) external returns (bool);
}

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}


// asset :   [BTC, WBTC, ETH, DAI, USDC, USDT, UAED, BUSD]
// assetId:  [  0,    1,   2,   3,    4,    5,    6,    7]

contract UAEDfinanceProtocol is IERC677Receiver{

    uint public interestRatePerHour;                   // 8 decimals
    uint public flashLoanFee;                          // flashLoanFee amount
    uint _entered;                                     // 0 => not entered  ,  1 => entered
    uint public liquidatorBonusPercentage ;       
    uint public liquidatorMinBounus ;           
    uint public minLoanValue ; 

    bool public isERCflashLoanPaused;
    bool public isETHflashLoanPaused;

    UAEDfinancePool public immutable  uaedFinancePool;
    UAEDProtocolRequestor public immutable protocolRequestor;
    address public owner;
    address public owner2; 

    address[] public tokenAddress;               // collateral contract address
    address[] public priceFeed;
    uint8[] public collateralFactor;             // healthFactor, 2 decimals
    uint8[] public tokenDecimals;
    uint8[] public priceFeedDecimals;

    bytes4 public constant flashLoanSig = bytes4(abi.encodeWithSelector(this.flashLoan.selector));          

    struct Security {
        bool isPledgedBefore;                // resistance against override!
        uint pledgedAmount;                  // amount of asset that user deposited as collateral
        uint UAEDminted;                     // number of UAED minted for user
        uint pledgedTime;                    // time that user deposited collateral and minted UAED
    }

    mapping (uint8 => bool)public isPausedAsCollateral ;
    mapping(address => mapping(uint8 => Security)) public pledgor;                  // pledgor[user][assetId] = Security

    constructor(){
        owner = msg.sender;
        owner2 = msg.sender;
        interestRatePerHour = 913; 
        flashLoanFee = 1e6;
        liquidatorBonusPercentage = 125;       // 4 decimals
        liquidatorMinBounus = 5e7;             // 50 UAED
        minLoanValue = 1e9;                    // 1000 UAED

        protocolRequestor = new UAEDProtocolRequestor();
        uaedFinancePool = new UAEDfinancePool();

        // collateral contract address
        tokenAddress = [
            address(0),                                      // BTC
            0x62f963Faccd33B14C7a37163C881472a8519782C,      // WBTC   Goerli
            address(0),                                      // ETH
            0xb2d0D5b9e00e7b5a8ab1b42DF97fE9cf0FB34def,      // DAI    Goerli
            0xd60f8696d12D3a9eB678BC97dB4216E7e239e4f6,      // USDC   Goerli
            0x8Aa5c8b033938D02Ea993F7794458EAa144a0Eb6,      // USDT   Goerli
            0x71EF885b88772d7eACcB40cF582784Ce30A0F515,      // UAED
            0xE4d81bc98368125CA2fE22527504906a4539ED84       // BUSD   Goerli
        ];

        tokenDecimals = [
            0,  // BTC     (   not used   )
            8,  // WBTC    (decimals => 8 )
            18, // ETH     (decimals => 18)
            18, // DAI     (decimals => 18)
            6,  // USDC    (decimals => 6 )
            6,  // USDT    (decimals => 6 )
            6,  // UAED    (decimals => 6 )
            18  // BUSD    (decimals => 18)
        ];

        // max of collateralFactor is 100, and uint8 supports 2^8=256 so is appropriate
        collateralFactor = [      // 2 decimals
            0,                    // BTC      0
            90,                   // WBTC     1
            90,                   // ETH      2
            95,                   // DAI      3
            95,                   // USDC     4
            95,                   // USDT     5
            0,                    // UAED     6
            95                    // BUSD     7
        ];   

        // collateral priceFeed on Goerli Mainnet
        // address checked in etherscan.io
        priceFeed = [                                   //                                         alternativePriceFeed
            0xA39434A63A52E749F02807ae27335515BA4b07F7, // BTC /USD    (decimals => 8 )  Goerli
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7, // WBTC/BTC    (decimals => 8 )  Goerli    USDC/USD
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e, // ETH /USD    (decimals => 8 )  Goerli
            0x0d79df66BE487753B02D015Fb622DED7f0E9798d, // DAI /USD    (decimals => 8 )  Goerli
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7, // USDC/USD    (decimals => 8 )  Goerli    USDC/USD
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7, // USDT/USD    (decimals => 8 )  Goerli    USDC/USD
            0xc5e58Af02a6E96Dba5d0D0b6cA52A6F2567493b4, // UAED/USD    (decimals => 8 )  
            0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7  // BUSD/USD    (decimals => 8 )  Goerli    USDC/USD
        ];

        priceFeedDecimals = [
            8,                      // BTC /USD
            8,                      // WBTC/BTC
            8,                      // ETH /USD
            8,                      // DAI /USD
            8,                      // USDC/USD
            8,                      // USDT/USD
            8,                      // UAED/USD
            8                       // BUSD/USD            
        ];
    }

    fallback(bytes calldata _data) external payable returns(bytes memory) {
        require(getSelector(_data) == flashLoanSig,"only for flashLoan ETH receive");
    }

    receive() external payable{
        mintByETHcollateral(collateralFactor[2] / 2);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyProtocolRequestor() {
        require(msg.sender == address(protocolRequestor), "onlyProtocolRequestor");
        _;
    }

    modifier notPausedAsCollateral(uint8 _assetId){
        require(!isPausedAsCollateral[_assetId], "pausedAsset");
        _;
    }

    modifier nonReentrant() {
        require(_entered == 0, "ReentrancyGuard");
        _entered = 1;
        _;
        _entered = 0;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function changeOwner2(address _owner2) external onlyOwner {
        owner2 = _owner2;
    }
    
    
    function onTokenTransfer(address _sender, uint _value, bytes calldata _data) public {

        require(msg.sender == tokenAddress[6],"only UAED contract");
        bytes4 funcSig = getSelector(_data);
        // bytes4 funcSig = _data[0] |  bytes4(_data[1]) >> 8 | bytes4(_data[2]) >> 16  | bytes4(_data[3]) >> 24;

        if(funcSig == bytes4(abi.encodeWithSignature("_payDebt(uint8,address)"))){
            // _payDebt(uint8 _assetId, address _msgSender)
            (uint8 _assetId) = abi.decode(_data[4:], (uint8));
            _payDebt(_assetId, _sender);

        }else if(funcSig == bytes4(abi.encodeWithSignature("_liquidate(address,uint8,address)"))){
            // _liquidate(address _user, uint8 _assetId, address _msgSender)
            (address _user, uint8 _assetId) = abi.decode(_data[4:], (address, uint8));
            _liquidate( _user, _assetId, _sender);
        }else{
            revert("wrong selector");
        }
        IERC20(tokenAddress[6]).transfer(_sender, IERC20(tokenAddress[6]).balanceOf(address(this)));
    }

    function getSelector(bytes memory _data) private pure returns(bytes4 sig) {
        assembly {
            sig := mload(add(_data, 32))
        }
    }


    ///////////////////////// change financial parameters and manage requests /////////////////////////////////////
    //--------1---------
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external onlyProtocolRequestor {
        collateralFactor[_assetId] = _collateralFactor;
    }

    //-------2----------
    function changePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals) external onlyProtocolRequestor {
        priceFeed[_assetId] = _priceFeed;
        priceFeedDecimals[_assetId] = _priceFeedDecimals;
    }

    //-------3---------
    function addAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals) external onlyProtocolRequestor returns(uint8 assetN){
        tokenAddress.push(_tokenAddress);
        priceFeed.push(_priceFeed);
        tokenDecimals.push(_tokenDecimals);
        priceFeedDecimals.push(_priceFeedDecimals);
        collateralFactor.push(_collateralFactor);

        assetN = uint8(tokenAddress.length);
        assert(priceFeed.length == assetN && tokenDecimals.length == assetN && priceFeedDecimals.length == assetN && collateralFactor.length == assetN);
    }

    //--------4--------
    function changeInterestRate(uint _interestRate) external onlyProtocolRequestor {
        interestRatePerHour = _interestRate;
    }

    //--------5-------- 
    function changeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus) external onlyProtocolRequestor{
        liquidatorBonusPercentage = _liquidatorBonusPercentage;
        liquidatorMinBounus = _liquidatorMinBounus;
    }    

    //--------6--------
    event collateralPauseToggled(uint8 assetId);
    function toggleCollateralPause(uint8 _assetId) external onlyOwner {
        isPausedAsCollateral[_assetId] = !isPausedAsCollateral[_assetId];
        emit collateralPauseToggled(_assetId);
    }

    //--------7--------
    function changeFlashLoanFee(uint _flashLoanFee) external onlyOwner {
        flashLoanFee = _flashLoanFee;
    }
    
    //-------8---------
    function changeMinLoanValue(uint _minLoanValue) external onlyOwner {
        minLoanValue = _minLoanValue;
    }


    //////////////////////////////////////////// getting assets' price ////////////////////////////////////////////
    function getPriceInUSD(uint8 _assetId) public returns (uint) {
        require(_assetId < priceFeed.length, "incorrect assetId");
        (
            /*uint80 roundID*/,
            int256 _price, 
            /*uint startedAt*/,
            /*uint timestamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(priceFeed[_assetId]).latestRoundData();

        if (_assetId == 1) {
            return uint(_price) * getPriceInUSD(0)/ 1e8; //    WBTC/USD = WBTC/BTC * BTC/USD
        } else {
            return uint(_price);
        }
    } 


    //////////////////////////////////////////// manage pool UAED balance  ////////////////////////////////////////////
    function withdrawUAEDfromPool(uint _amount) public onlyOwner {
        sendAssetFromPool(owner, 6, _amount);
    }


    ///////////////////////////////////////// get collateral and mint UAED //////////////////////////////////////////
    /*
        algorithm to calculate the amount of UAED that should be minted by depositing collaterals
        
        UAED minted :
        assetNumber * assetPrice/USD * USD/AED * userPercentage ;

        equation that sould be true (otherwise user should be liquidated ):
        assetNumber * (assetPrice/USD * USD/AED)' * collateralFactor >= assetNumber * assetPrice/USD * USD/AED * userPercentage
        Notice : in equation above , ' charachter means the price in second state 
    */

    event mintedByCollateral(
        address indexed user,
        uint8 indexed assetId,
        uint collateralAmount,
        uint userCollateralPercentage,
        uint indexed amountMinted,
        uint timeStamp
    );

    function getSecurity(address _user, uint8 _assetId) external view returns (bool isPledgedBefore, uint pledgedAmount, uint mintedUAED, uint pledgedTime){
        Security storage security = pledgor[_user][_assetId];
        
        isPledgedBefore = security.isPledgedBefore;
        pledgedAmount = security.pledgedAmount;
        mintedUAED = security.UAEDminted;
        pledgedTime = security.pledgedTime;
    }

    function mintByETHcollateral(uint8 _percentage) public payable nonReentrant {
        require(msg.value > 0, "worng amount");
        require(_percentage < collateralFactor[2], "wrong percentage");
        require(!pledgor[msg.sender][2].isPledgedBefore, "Repetitious asset");
        
        _sendAssetToPool(2, msg.value);
        
        _mintByCollateral(msg.sender, msg.value, 2, _percentage);
    }

    // user should approve to this contract before executing this function .
    // only for ECRC20 tokens
    // _percentage has 2 decimals
    function mintByCollateral(uint _amount, uint8 _assetId, uint8 _percentage) external {
        require(_amount > 0, "worng amount");
        require(_assetId != 0 && _assetId != 2 && _assetId != 6 && _assetId < tokenAddress.length, "wrong assetId");
        require(_percentage < collateralFactor[_assetId], "wrong percentage");
        require(!pledgor[msg.sender][_assetId].isPledgedBefore, "Repetitious asset");

        _sendAssetToPool(msg.sender, _assetId, _amount);

        _mintByCollateral(msg.sender, _amount, _assetId, _percentage);
    }

    function _mintByCollateral(address _user, uint _amount, uint8 _assetId, uint8 _percentage) private notPausedAsCollateral(_assetId) {
        uint mintAmountNumerator = _amount * getPriceInUSD(_assetId) * _percentage * 10**(tokenDecimals[6] + priceFeedDecimals[6]);    // 6 is UAED assetId
        uint mintAmountDenominator = getPriceInUSD(6) * 10**(tokenDecimals[_assetId] + priceFeedDecimals[_assetId] + 2);               // +2 : _percentage decimals
        uint mintAmount = mintAmountNumerator / mintAmountDenominator;

        require(mintAmount > minLoanValue,"insufficinat amount");

        pledgor[_user][_assetId] = Security({
            isPledgedBefore: true,                  // resistance against override!
            pledgedAmount: _amount,                 // amount of asset that user deposited as collateral
            UAEDminted: mintAmount,                 // number of UAED minted for user
            pledgedTime: block.timestamp            // liquidation price in AED
        });

        sendAssetFromPool(_user,6 , mintAmount);     

        emit mintedByCollateral( _user, _assetId, _amount, _percentage, mintAmount, block.timestamp);
    }


    /////////////////////////// helper functions for liquidation and debt payback ////////////////////////////
    function sendAssetFromPool(address _receiver, uint8 _assetId, uint _amount) private {
        if (_assetId == 2) {
            uaedFinancePool.ETHtransfer(payable(_receiver), _amount);
        } else {
            uaedFinancePool.ERC20transfer(tokenAddress[_assetId], _receiver, _amount);
        }
    }
    
    function _sendAssetToPool(address _from, uint8 _assetId, uint _amount) private {
        IERC20(tokenAddress[_assetId]).transferFrom(_from, address(uaedFinancePool), _amount);
    } 

    function _sendAssetToPool(uint8 _assetId, uint _amount) private {
        if(_assetId == 6){
            IERC20(tokenAddress[6]).transfer(address(uaedFinancePool), _amount);
        }else{
            (bool sent, ) = payable(address(uaedFinancePool)).call{ value: _amount }("");
            require(sent,"send ETH to pool failed");
        }
    } 


    function getDebtState(address _user, uint8 _assetId) public returns (uint, uint, bool){
        Security storage security = pledgor[_user][_assetId];

        require(_assetId < collateralFactor.length && collateralFactor[_assetId] != 0, "wrong assetId");
        require(security.isPledgedBefore, "unpledged user");
        uint mintedAmount = security.UAEDminted;
        uint mintedTime = security.pledgedTime;
        uint securityPledgedAmount = security.pledgedAmount;

        // interest = (block.timestamp - mintedTime)/3600  *  (interestRatePerHour/10**8)   *   mintedAmount
        uint interest = ((block.timestamp - mintedTime) * interestRatePerHour * mintedAmount) / (3600 * 10**8);
        uint debtAmount = interest + mintedAmount;                            // debtAmount in UAED
        
        // I => indexed
        // N => Numerator & D => Denominator
        // values below are in UAED
        uint collateralValueN = securityPledgedAmount * getPriceInUSD(_assetId) * 10**(tokenDecimals[6] + priceFeedDecimals[6]);
        uint collateralValueD = getPriceInUSD(6) * 10**(tokenDecimals[_assetId] + priceFeedDecimals[_assetId]);  
        uint collateralValue = collateralValueN / collateralValueD;                                                     // collateralValue in UAED
        uint IcollateralValue = collateralValue * collateralFactor[_assetId] / 1e2;                                     // 1e2 : collateralFactor decimals

        // debtAmountInAED / collateralValue = debtAmountInCollateral / securityPledgedAmount

        return (debtAmount, collateralValue, debtAmount > IcollateralValue);
    } 


    //////////////////////////////////// liquidate underbalanced user /////////////////////////////////////
    // A borrowing account becomes insolvent when the Borrow Ballance exceeds the amount allowed by the collateral factor.

    event userLiquidated(address indexed user, uint8 indexed assetId, uint debtAmount, uint timeStamp);

    function _liquidate(address _user, uint8 _assetId, address _msgSender) private {
        Security storage security = pledgor[_user][_assetId];

        (uint _debtAmount, uint _collateralValue, bool _isOverCollateralized) = getDebtState(_user, _assetId);  // _collateralValue is in UAED
        require(_isOverCollateralized, "uninsolvent user");

        _sendAssetToPool(6, security.UAEDminted);
        IERC20(tokenAddress[6]).transfer(owner2, _debtAmount - security.UAEDminted);

        uint _pledgedAmount = security.pledgedAmount ;
        delete pledgor[_user][_assetId];

        if(_debtAmount >= _collateralValue){
            sendAssetFromPool(_msgSender, _assetId, _pledgedAmount); 
        }else {
            uint liquidatorBonus;
            // (100 - collateralFactor(_assetId)) * X = 100 * liquidatorBonusPercentage
            uint X = 100 * liquidatorBonusPercentage / (100 - collateralFactor[_assetId]);     // X has 4 decimals

            uint surplusCollateralValue = _collateralValue - _debtAmount;                               // difference of debtAmount and collateralValue
            uint liquidatorLinearBonus =  surplusCollateralValue * X / 1e4; 

            if(surplusCollateralValue < liquidatorMinBounus){
                liquidatorBonus = surplusCollateralValue;
            }else{
                liquidatorBonus = liquidatorLinearBonus < liquidatorMinBounus ? liquidatorMinBounus : liquidatorLinearBonus;
            }

            // (_debtAmount + liquidatorBonus) / _collateralValue = liquidatorPortion / _pledgedAmount
            uint liquidatorPortion = (_debtAmount + liquidatorBonus) * _pledgedAmount / _collateralValue;

            sendAssetFromPool(_msgSender, _assetId, liquidatorPortion);
            if(_pledgedAmount > liquidatorPortion){
                sendAssetFromPool(_user, _assetId, _pledgedAmount - liquidatorPortion);
            }

        }

        emit userLiquidated(_user, _assetId, _debtAmount, block.timestamp);
    }


    ////////////////////////////////////////////// pay debt ///////////////////////////////////////////////
    event debtPaid(address indexed user, uint8 indexed assetId, uint debtAmount, uint timeStamp);

    function _payDebt(uint8 _assetId, address _msgSender) private {
        Security storage security = pledgor[_msgSender][_assetId];
        require(security.isPledgedBefore, "No collateral provided");

        (uint _debtAmount, , ) = getDebtState(_msgSender, _assetId);

        _sendAssetToPool(6, security.UAEDminted);
        IERC20(tokenAddress[6]).transfer(owner2, _debtAmount - security.UAEDminted);

        uint _pledgedAmount = security.pledgedAmount ;
        delete pledgor[_msgSender][_assetId];

        sendAssetFromPool(_msgSender, _assetId, _pledgedAmount);

        emit debtPaid(_msgSender, _assetId, _debtAmount, block.timestamp);
    }


    //////////////////////////////////////////////  flashLoan  ///////////////////////////////////////////////

    function toggleERCflashLoanPause() external onlyOwner{
        isERCflashLoanPaused = !isERCflashLoanPaused;
    }

    function toggleETHflashLoanPause() external onlyOwner{
        isETHflashLoanPaused = !isETHflashLoanPaused;
    }

    function getFlashLoanedETH() external payable{}

    event flashLoanExecuted(address user, uint8 indexed assetId, uint amount);
    function flashLoan(uint8 _assetId, uint _amount) public {
        if(_assetId == 2){     
            require(!isETHflashLoanPaused,"ETHflashLoanPaused");
            _ETHflashLoan(_amount);
        }else{
            require(_assetId != 0 && _assetId < tokenAddress.length, "wrong assetId");
            require(!isERCflashLoanPaused,"ERCflashLoanPaused");
            _ERCflashLoan(_assetId, _amount);
        }

        IERC20(tokenAddress[6]).transferFrom(msg.sender, owner2, flashLoanFee);   
        emit flashLoanExecuted(msg.sender, _assetId, _amount);
    }
    
    function _ETHflashLoan(uint _amount) private nonReentrant {

        sendAssetFromPool(msg.sender, 2, _amount);  
        require(IFlashLoanReceiver(msg.sender).executeOperation(flashLoanFee, 2),"flashLoan failed");   // 2 is ETH assetId
        _sendAssetToPool(2, _amount);

    }

    function _ERCflashLoan(uint8 _assetId, uint _amount) private{

        sendAssetFromPool(msg.sender, _assetId, _amount);  
        require(IFlashLoanReceiver(msg.sender).executeOperation(flashLoanFee, _assetId),"flashLoan failed");
        _sendAssetToPool(msg.sender, _assetId, _amount); 

    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC677Receiver {
   function onTokenTransfer(address _sender, uint256 _value, bytes calldata _data) external;
}

contract ERC677Token is ERC20 {

    address tokenAddress;
    constructor(address _tokenAddress, string memory _name, string memory _symbol) ERC20(_name, _symbol){
        tokenAddress = _tokenAddress;
    }

    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    function transferAndCall(address _to, uint256 _value, bytes calldata _data) public returns (bool success) {
        transfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(address _to, uint256 _value, bytes calldata _data) private {
        IERC677Receiver(_to).onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool _isContract) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        _isContract = length > 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        require(from != tokenAddress && to != tokenAddress);
    }
}

contract UAED is ERC677Token {
    string private constant _name = "FALCOIN";
    string private constant _symbol = "UAED";
    address public owner;

    constructor() ERC677Token(address(this), _name, _symbol) {
        owner = msg.sender;
    }

    event OwnershipTransferred(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
        emit OwnershipTransferred(_owner);
    }

    function mint(address _user, uint _amount) external onlyOwner{
        _mint(_user, _amount);
    }

    function burn(address _user, uint _amount) external onlyOwner{
        require(allowance(_user, address(this)) >= _amount, "insufficiant allowance");
        _burn(_user, _amount);
        _spendAllowance(msg.sender, owner, _amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IUAEDprotocol{
    function owner() external returns(address);
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external;
    function changePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals) external;
    function addAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals) external returns(uint8);
    function changeInterestRate(uint _interestRatePerHour) external ;
    function changeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus) external;

}

contract UAEDProtocolRequestor{

    IUAEDprotocol public immutable uaedProtocol; 
    uint public constant changeCollateralFactorD = 30 days;
    uint public constant changePriceFeedD = 3 hours;
    uint public constant addAssetAsCollateralD = 7 hours;
    uint public constant changeInterestRateD = 30 hours;
    uint public constant changeLiquidationParamsD = 7 hours;
    uint public constant expirationTime = 1 days;

    mapping(bytes32 => uint) public requests ;                               // timestamp of each request

    constructor(){
        uaedProtocol = IUAEDprotocol(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == uaedProtocol.owner(),"onlyOwner");
        _;
    }

    //////////////// change financial parameters and manage requests ////////////////////////////

    function _submitRequest(bytes32 _request) private {
        require(requests[_request] == 0,"request already submitted");                  // collision resistance
        requests[_request] = block.timestamp;
    }

    function _checkRequestTime(bytes32 _request, uint _delayedTime) private view {     
        require(requests[_request] + _delayedTime <= block.timestamp,"wait more");
        require(block.timestamp <= requests[_request] + _delayedTime + expirationTime , "Request has expired");
    }

    event requestCanceled(bytes32 request);
    function cancelRequest(bytes32 _request) external onlyOwner {     
        delete requests[_request];
        emit requestCanceled(_request);
    }

    //--------1----------
    event requestCollateralFactorChange(uint8 indexed assetId, uint8 newCollateralFactor, uint timeStamp, bytes32 indexed request);
    event collateralFactorChanged(uint8 assetId, uint8 newCollateralFactor, bytes32 indexed request);

    function requestChangeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external onlyOwner{
        require(_collateralFactor < 100, "invalid collateralFactor");
        require(_assetId != 0 && _assetId != 6, "this asset isn't supported as collateral");
        bytes32 request = keccak256(abi.encodeCall(this.changeCollateralFactor, (_assetId, _collateralFactor, block.timestamp)));
        _submitRequest(request);
        emit requestCollateralFactorChange(_assetId, _collateralFactor, block.timestamp, request);
    }
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeCollateralFactor, (_assetId, _collateralFactor, _timeStamp)));
        _checkRequestTime(request, changeCollateralFactorD);
        uaedProtocol.changeCollateralFactor(_assetId, _collateralFactor);
        emit collateralFactorChanged(_assetId, _collateralFactor, request);
    }

    //--------2----------
    event requestPriceFeedChange(address priceFeed, uint8 indexed assetId, uint8 priceFeedDecimals, uint timeStamp, bytes32 indexed request);
    event priceFeedChanged(address priceFeed, uint8 assetId, uint8 priceFeedDecimals, bytes32 indexed request);

    function requestChangePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals) external onlyOwner{
        require(_priceFeed != address(0), "invalid priceFeed address");
        bytes32 request = keccak256(abi.encodeCall(this.changePriceFeed, (_priceFeed, _assetId, _priceFeedDecimals, block.timestamp)));
        _submitRequest(request);
        emit requestPriceFeedChange(_priceFeed, _assetId, _priceFeedDecimals, block.timestamp, request);
    }
    function changePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changePriceFeed, (_priceFeed, _assetId, _priceFeedDecimals, _timeStamp)));
        _checkRequestTime(request, changePriceFeedD);
        uaedProtocol.changePriceFeed(_priceFeed, _assetId, _priceFeedDecimals);
        emit priceFeedChanged(_priceFeed, _assetId, _priceFeedDecimals, request);
    }

    //--------3----------
    event requestAssetAddAsCollateral(address indexed tokenAddress, address priceFeed, uint8 collateralFactor, uint timeStamp, bytes32 indexed request);
    event assetAddedAsCollateral(address indexed tokenAddress, address priceFeed,uint8 assetId, uint8 collateralFactor, bytes32 indexed request);

    function requestAddAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals) external onlyOwner {
        require(_tokenAddress != address(0) && _priceFeed != address(0), "invalid address");
        require(_collateralFactor < 100, "invalid collateralFactor");
        bytes32 request = keccak256(abi.encodeCall(this.addAssetAsCollateral, (_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, _priceFeedDecimals, block.timestamp)));
        _submitRequest(request);
        emit requestAssetAddAsCollateral(_tokenAddress, _priceFeed, _collateralFactor, block.timestamp, request);
    }
    function addAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals, uint _timeStamp) external onlyOwner {
        bytes32 request = keccak256(abi.encodeCall(this.addAssetAsCollateral, (_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, _priceFeedDecimals, _timeStamp)));
        _checkRequestTime(request, addAssetAsCollateralD);
        uint8 assetN = uaedProtocol.addAssetAsCollateral(_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, _priceFeedDecimals);

        emit assetAddedAsCollateral(_tokenAddress, _priceFeed, assetN - 1, _collateralFactor, request);
    }

    // --------4----------
    event requestInterestRateChange(uint interestRate, uint timeStamp, bytes32 indexed request);
    event interestRateChanged(uint interestRate, bytes32 indexed request);

    function requestChangeInterestRate(uint _interestRate) external onlyOwner{
        uint y = 365 days + 6 hours;
        uint d = block.timestamp % y ;
        require( d > y - changeInterestRateD && d < y + expirationTime - changeInterestRateD,"incorrect request time");
        bytes32 request = keccak256(abi.encodeCall(this.changeInterestRate, (_interestRate, block.timestamp)));
        _submitRequest(request);
        emit requestInterestRateChange(_interestRate, block.timestamp, request);
    }

    function changeInterestRate(uint _interestRate, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeInterestRate, (_interestRate, _timeStamp)));
        _checkRequestTime(request, changeInterestRateD);
        uaedProtocol.changeInterestRate(_interestRate);
        emit interestRateChanged(_interestRate, request);
    }

    // --------5---------- 
    event requestLiquidationParamsChange(uint indexed liquidatorBonusPercentage, uint liquidatorMinBounus, uint timeStamp, bytes32 indexed request);
    event liquidationParamsChanged(uint liquidatorBonusPercentage, uint liquidatorMinBounus, bytes32 indexed request);

    function requestChangeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeLiquidationParams, (_liquidatorBonusPercentage, _liquidatorMinBounus, block.timestamp)));
        _submitRequest(request);
        emit requestLiquidationParamsChange(_liquidatorBonusPercentage, _liquidatorMinBounus, block.timestamp, request);
    }
    function changeLiquidationParams(uint _liquidatorBonusPercentage, uint _liquidatorMinBounus, uint _timeStamp) external onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeLiquidationParams, (_liquidatorBonusPercentage, _liquidatorMinBounus, _timeStamp)));
        _checkRequestTime(request, changeLiquidationParamsD);
        uaedProtocol.changeLiquidationParams(_liquidatorBonusPercentage, _liquidatorMinBounus);
        emit liquidationParamsChanged(_liquidatorBonusPercentage, _liquidatorMinBounus, request);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract forcePay {
    constructor(address payable _user) payable {
        // EIP-4758: Deactivate SELFDESTRUCT
        selfdestruct(_user);
    }
}

contract UAEDfinancePool{

    address public protocol;
    
    constructor(){
        protocol = msg.sender;
    }

    receive() external payable{
        require(msg.sender == protocol);
    }

    modifier onlyProtocol(){
        require(msg.sender == protocol,"onlyProtocol");
        _;
    }

    function ERC20transfer(address _tokenAddress, address _receiver, uint _amount) public onlyProtocol{
        IERC20(_tokenAddress).transfer(_receiver, _amount);
    }

    function ETHtransfer(address payable _receiver, uint _amount) public onlyProtocol{
        (bool sent, ) = _receiver.call{ value: _amount }("");
        if(!sent){
            new forcePay{value : _amount }(_receiver);
        }
    }
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}