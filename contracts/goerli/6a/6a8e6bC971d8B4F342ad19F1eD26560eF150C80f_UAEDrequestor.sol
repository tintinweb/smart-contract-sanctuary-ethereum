// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IUAED{
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) external;
    function changePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals) external;
    function addAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals) external returns(uint8);
    function toggleCollateralPause(uint8 _assetId) external;
    function changeInterestRate(uint _interestRatePerHour) external ;
    // function changeFee(uint _feePercentage, uint _maxFee) external;
}

contract UAEDrequestor{

    address public owner ;
    address public ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;  
    bool public isUAEDset;
    IUAED public uaed;
    uint public changeCollateralFactorD = 7 days;
    uint public changePriceFeedD = 7 days;
    uint public addAssetAsCollateralD = 7 days;
    uint public changeInterestRateD = 1 days;
    // uint public changeFeeD = 10 days;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"onlyOwner");
        _;
    }
    
    function setUAED(address _uaed) public onlyOwner{
        require(!isUAEDset,"UAED has set");
        uaed = IUAED(_uaed);
        isUAEDset = true;
    }

    //////////////// change financial parameters and manage requests ////////////////////////////
    mapping(bytes32 => uint) public requests ;

    modifier checkRequest(bytes32 _request){
        require(requests[_request] != 0,"unsubmitted request");
        _;
    }

    event requestCanceled(bytes32 request);

    function _submitRequest(bytes32 _request) private {
        require(requests[_request] == 0,"request already submitted");                  // collision resistance
        requests[_request] = block.timestamp;
    }

    function checkRequestTime(bytes32 _request, uint _delayedTime) private view checkRequest(_request) {     
        require(requests[_request] + _delayedTime <= block.timestamp,"wait more");
    }

    function cancelRequest(bytes32 _request) public checkRequest(_request) onlyOwner {     
        delete requests[_request];
        emit requestCanceled(_request);
    }

    //--------1----------
    event requestCollateralFactorChange(uint8 indexed assetId, uint8 newCollateralFactor, uint timeStamp, bytes32 indexed request);
    event collateralFactorChanged(uint8 assetId, uint8 newCollateralFactor, bytes32 indexed request);
    function requestChangeCollateralFactor(uint8 _assetId, uint8 _collateralFactor) public onlyOwner{
        require(_collateralFactor < 100, "invalid collateralFactor");
        require(_assetId != 0 && _assetId != 6, "this asset isn't supported as collateral");
        bytes32 request = keccak256(abi.encodeCall(this.changeCollateralFactor, (_assetId, _collateralFactor, block.timestamp)));
        _submitRequest(request);
        emit requestCollateralFactorChange(_assetId, _collateralFactor, block.timestamp, request);
    }
    function changeCollateralFactor(uint8 _assetId, uint8 _collateralFactor, uint _timeStamp) public onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeCollateralFactor, (_assetId, _collateralFactor, _timeStamp)));
        checkRequestTime(request, changeCollateralFactorD);
        uaed.changeCollateralFactor(_assetId, _collateralFactor);
        emit collateralFactorChanged(_assetId, _collateralFactor, request);
    }

    //--------2----------
    event requestPriceFeedChange(address priceFeed, uint8 indexed assetId, uint8 priceFeedDecimals, uint timeStamp, bytes32 indexed request);
    event priceFeedChanged(address priceFeed, uint8 assetId, uint8 priceFeedDecimals, bytes32 indexed request);
    function requestChangePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals) public onlyOwner{
        require(_priceFeed != ZERO_ADDRESS, "invalid priceFeed address");
        bytes32 request = keccak256(abi.encodeCall(this.changePriceFeed, (_priceFeed, _assetId, _priceFeedDecimals, block.timestamp)));
        _submitRequest(request);
        emit requestPriceFeedChange(_priceFeed, _assetId, _priceFeedDecimals, block.timestamp, request);
    }
    function changePriceFeed(address _priceFeed, uint8 _assetId, uint8 _priceFeedDecimals, uint _timeStamp) public onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changePriceFeed, (_priceFeed, _assetId, _priceFeedDecimals, _timeStamp)));
        checkRequestTime(request, changePriceFeedD);
        uaed.changePriceFeed(_priceFeed, _assetId, _priceFeedDecimals);
        emit priceFeedChanged(_priceFeed, _assetId, _priceFeedDecimals, request);
    }

    //--------3----------
    event requestAssetAddAsCollateral(address indexed tokenAddress, address priceFeed, uint8 collateralFactor, uint timeStamp, bytes32 indexed request);
    event assetAddedAsCollateral(address indexed tokenAddress, address priceFeed,uint8 assetId, uint8 collateralFactor, bytes32 indexed request);
    function requestAddAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals) public onlyOwner {
        require(_tokenAddress != ZERO_ADDRESS && _priceFeed != ZERO_ADDRESS, "invalid address");
        require(_collateralFactor < 100, "invalid collateralFactor");
        bytes32 request = keccak256(abi.encodeCall(this.addAssetAsCollateral, (_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, _priceFeedDecimals, block.timestamp)));
        _submitRequest(request);
        emit requestAssetAddAsCollateral(_tokenAddress, _priceFeed, _collateralFactor, block.timestamp, request);
    }
    function addAssetAsCollateral(address _tokenAddress, address _priceFeed, uint8 _tokenDecimals, uint8 _collateralFactor, uint8 _priceFeedDecimals, uint _timeStamp) public onlyOwner {
        bytes32 request = keccak256(abi.encodeCall(this.addAssetAsCollateral, (_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, _priceFeedDecimals, _timeStamp)));
        checkRequestTime(request, addAssetAsCollateralD);
        uint8 assetN = uaed.addAssetAsCollateral(_tokenAddress, _priceFeed, _tokenDecimals, _collateralFactor, _priceFeedDecimals);

        emit assetAddedAsCollateral(_tokenAddress, _priceFeed, assetN - 1, _collateralFactor, request);
    }

    //-------4-----------
    event collateralPauseToggled(uint8 assetId);
    function toggleCollateralPause(uint8 _assetId) public onlyOwner {
        uaed.toggleCollateralPause(_assetId);
        emit collateralPauseToggled(_assetId);
    }

    // --------5----------
    event requestInterestRateChange(uint interestRate, uint timeStamp, bytes32 indexed request);
    event interestRateChanged(uint interestRate, bytes32 indexed request);
    function requestChangeInterestRate(uint _interestRate) public onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeInterestRate, (_interestRate, block.timestamp)));
        _submitRequest(request);
        emit requestInterestRateChange(_interestRate, block.timestamp, request);
    }

    function changeInterestRate(uint _interestRate, uint _timeStamp) public onlyOwner{
        bytes32 request = keccak256(abi.encodeCall(this.changeInterestRate, (_interestRate, _timeStamp)));
        checkRequestTime(request, changeInterestRateD);
        uaed.changeInterestRate(_interestRate);
        emit interestRateChanged(_interestRate, request);
    }

    //--------6----------
    // event requestFeeChange(uint _feePercentage, uint _maxFee, uint timeStamp, bytes32 indexed request);
    // event feeChanged(uint _feePercentage, uint _maxFee, bytes32 indexed request);
    // function requestChangeFee(uint _feePercentage, uint _maxFee) public onlyOwner{
    //     bytes32 request = keccak256(abi.encodeCall(this.changeFee, (_feePercentage, _maxFee, block.timestamp)));
    //     _submitRequest(request);
    //     emit requestFeeChange(_feePercentage, _maxFee, block.timestamp, request);
    // }

    // function changeFee(uint _feePercentage, uint _maxFee, uint _timeStamp) public onlyOwner{
    //     bytes32 request = keccak256(abi.encodeCall(this.changeFee, (_feePercentage, _maxFee, _timeStamp)));
    //     checkRequestTime(request, 30 days);
    //     uaed.changeFee(_feePercentage, _maxFee);
    //     emit feeChanged(_feePercentage, _maxFee);
    // }
}