/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
}

contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERNIZI is Ownable {
    AggregatorV3Interface internal priceFeed;
    address public enzAddress; // Address of the ENZ token contract
    address public lirAddress; // Address of the LIR token contract
    address private _owner;
    uint256 public MIN_RESERVE_RATIO = 500; 
    uint256 public MAX_RESERVE_RATIO = 1000; 
    uint256 public MINT_ENZ_FEE_PERCENT = 200;
    uint256 public BURN_ENZ_FEE_PERCENT = 200;
    uint256 public MINT_LIR_FEE_PERCENT = 20;
    uint256 public BURN_LIR_FEE_PERCENT = 50;
    uint256 public ENZ_OPER_FEE_PERCENT = 100;
    uint256 public DIVFACTOR = 10000;
    address public reservePool;
    address public treasury;
    uint256 public mintEnzFee;
    uint256 public mintLirFee;
    uint256 public burnEnzFee;
    uint256 public burnLirFee;
    uint256 public opEnzFee;

    /**
        * @dev Emitted when `ENZ` tokens are minted.
    */
    event MINTENZ(address indexed from, uint256  ethAmount, uint256 remainingEthAmount, uint256  enzAmount, uint256 time);

    /**
        * @dev Emitted when `ENZ` tokens are burned
    */
    event BURNENZ(address indexed from, uint256 enzAmount, uint256  ethAmount, uint256 time);

    /**
        * @dev Emitted when `LIR` tokens are minted.
    */
    event MINTLIR(address indexed from, uint256  ethAmount, uint256  lirAmount, uint256 time);

    /**
        * @dev Emitted when `LIR` tokens are burned.
    */
    event BURNLIR(address indexed from, uint256  lirAmount, uint256 ethAmount, uint256 time);

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */

    constructor(address _enzAddress, address _lirAddress, address _reservePool, address _treasury) {
      priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
      enzAddress = _enzAddress;
      lirAddress = _lirAddress;
      reservePool = _reservePool;
      treasury = _treasury;
      _owner = msg.sender;
    }

    /**
        *Returns the latest price of ETH.
    */
    function getLatestPrice() public view returns (int) {
    (uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        return price;
    }

    /**
        *Returns the latest price of ETH.
    */
    function ethPrice() public view returns (uint256) {
        int256 ethLatestPrice = getLatestPrice();
        return uint256(ethLatestPrice);
    }

    /**
        * @dev Mint new ENZ tokens, increasing the total supply and balance of "account"
    */
    function mintENZToken() public payable returns(bool) {
        uint256 enzMinted = msg.value * ethPrice() / 1e18;
        IERC20(enzAddress).mint(msg.sender, enzMinted);
        return true;
    }

    /**
        * @dev calculates ENR token fees for minting
        * @param amount The amount of ETH & token.
        * @return fee percentage for MINT & BURN ENZ.
    */
    function calculateMintENZFee(uint256 amount) public view returns (uint256) {
        return (amount * MINT_ENZ_FEE_PERCENT) / (DIVFACTOR * 10);
    }

    /**
        * @dev calculates ENR token fees burning
        * @param amount The amount of ETH & token.
        * @return fee percentage for MINT & BURN ENZ.
    */
    function calculateBurnENZFee(uint256 amount) public view returns (uint256) {
        return (amount * BURN_ENZ_FEE_PERCENT) / (DIVFACTOR * 10);
    }

    /**
        * @dev calculates ENR token fees for operational
        * @param amount The amount of ETH & token.
        * @return operational fee percentage for MINT & BURN ENZ.
    */
    function calculateoperENZFee(uint256 amount) public view returns (uint256) {
        return (amount * ENZ_OPER_FEE_PERCENT) / (DIVFACTOR * 10);
    }

    /**
        * @dev calculates LIR token fees for minting
        * @param amount The amount of ETH.
        * @return fee percentage for MINT LIR.
    */
    function calculateMintLIRFee(uint256 amount) public view returns (uint256) {
        return (amount * MINT_LIR_FEE_PERCENT) / (DIVFACTOR*10);
    }

    /**
        * @dev calculates LIR token fees
        * @param amount The amount of token.
        * @return fee percentage for BURN LIR.
    */
    function calculateBurnLIRFee(uint256 amount) public view returns (uint256) {
        return (amount * BURN_LIR_FEE_PERCENT) / (DIVFACTOR*10);
    }

    /**
        * @dev findRatio `tokenId` token from `from` to `to`.
        * Retuns calculates the ratio of ethPrice with token supply.
    */
    function findRatio() public view returns (uint256){
        uint256 ethBalance = address(this).balance;
        uint256 tokenSupply = IERC20(enzAddress).totalSupply();
        return ethBalance * ethPrice() * 100 / tokenSupply;
    }

    /**
        * @dev Mint new ENZ tokens, increasing the total supply and balance of "account"
        * Emits a {MINTENZ} event.
    */
    function mintENZ() public payable returns(bool) {
        require(msg.value > 0, "Invalid ETH amount");
        require(findRatio() >= MIN_RESERVE_RATIO, "Minimum reserve ratio not met");
        uint256 enzMinted = msg.value * ethPrice() / 1e18;
        mintEnzFee = calculateMintENZFee(msg.value);
        opEnzFee = calculateoperENZFee(msg.value);
        uint256 totalFee = mintEnzFee + opEnzFee;
        uint256 remainingEthAmount = msg.value - totalFee;
        payable(reservePool).transfer(mintEnzFee);
        payable(treasury).transfer(opEnzFee);
        IERC20(enzAddress).mint(msg.sender, enzMinted);
        emit MINTENZ(msg.sender, msg.value, remainingEthAmount, enzMinted, block.timestamp);
        return true;
    }

    /**
        * @dev Burns ENZ token balance in "account" and decrease totalsupply of token
        * @param amount The amount that will be burnt.
        * Emits a {BURNENZ} event.
    */
    function burnENZ(uint256 amount) public payable returns(bool) {
        require(amount > 0, "Invalid ETH amount");
        uint256 enzBurned = amount * 1e18 / ethPrice();
        burnEnzFee = calculateBurnENZFee(amount);
        opEnzFee = calculateoperENZFee(msg.value);
        payable(reservePool).transfer(burnEnzFee);
        payable(treasury).transfer(opEnzFee);
        IERC20(enzAddress).burn(amount);
        payable(msg.sender).transfer(enzBurned);
        emit BURNENZ(msg.sender, amount, enzBurned, block.timestamp);
        return true;
    }

    /**
        * @dev Mint new LIR tokens, increasing the total supply and balance of "account"
        * Emits a {MINTENZ} event.
    */
    function mintLIR() public payable returns(bool) {
        require(msg.value > 0, "Invalid ETH amount");
        require(findRatio() >= MAX_RESERVE_RATIO, "Maximum reserve ratio not met");
        uint256 lirMinted = msg.value * ethPrice() / 1e18;
        mintLirFee = calculateMintLIRFee(msg.value);
        payable(reservePool).transfer(mintLirFee);
        IERC20(lirAddress).mint(msg.sender, lirMinted);
        emit MINTLIR(msg.sender, msg.value, lirMinted, block.timestamp);
        return true;
    }

    /**
        * @dev Burns LIR token balance in "account" and decrease totalsupply of token
        * @param amount The amount of tokens that will be burnt.
        * Emits a {BURNLIR} event.
    */
    function burnLIR(uint256 amount) public payable returns(bool) {
        require(amount > 0, "Invalid ETH amount");
        uint256 lirBurned = amount * 1e18 / ethPrice();
        burnLirFee = calculateBurnLIRFee(amount);
        payable(reservePool).transfer(burnLirFee);
        IERC20(lirAddress).burn(amount);
        payable(msg.sender).transfer(lirBurned);
        emit BURNLIR(msg.sender, amount, lirBurned, block.timestamp);
        return true;
    }

    /**
        * @dev Change ENZTokenAddress to new address (`newAddress`).
        * Can only be called by the current owner.
    */
    function changeENZAddress( address _newAddress) public onlyOwner returns (bool) {
        enzAddress = _newAddress;
        return true;
    }

    /**
        * @dev Change LIRTokenAddress to new address (`newAddress`).
        * Can only be called by the current owner.
    */
    function changeLIRAddress( address _newAddress) public onlyOwner returns (bool) {
        lirAddress = _newAddress;
        return true;
    }

    /**
        * @dev Change reserveAddress to new address (`newAddress`).
        * Can only be called by the current owner.
    */
    function changeReserveAddress( address _newAddress) public onlyOwner returns (bool) {
        reservePool = _newAddress;
        return true;
    }

    /**
        * @dev Update MinReserveRatio to new Value (`newValue`).
        * Can only be called by the current owner.
    */
    function UpdateMinReserveRatio( uint256 _newValue) public onlyOwner returns (bool) {
        MIN_RESERVE_RATIO = _newValue;
        return true;
    }

    /**
        * @dev Update MaxReserveRatio to new Value (`newValue`).
        * Can only be called by the current owner.
    */
    function UpdateMaxReserveRatio( uint256 _newValue) public onlyOwner returns (bool) {
        MAX_RESERVE_RATIO = _newValue;
        return true;
    }

    /**
        * @dev Update ENZ Mint fees to new Value (`newValue`).
        * Can only be called by the current owner.
    */
    function UpdateMintEnzFeePercent( uint256 _newValue) public onlyOwner returns (bool) {
        MINT_ENZ_FEE_PERCENT = _newValue;
        return true;
    }

    /**
        * @dev Update ENZ Burn fees to new Value (`newValue`).
        * Can only be called by the current owner.
    */
    function UpdateBurnEnzFeePercent( uint256 _newValue) public onlyOwner returns (bool) {
        BURN_ENZ_FEE_PERCENT = _newValue;
        return true;
    }

    /**
        * @dev Update LIR Mint fees to new Value (`newValue`).
        * Can only be called by the current owner.
    */
    function UpdateMintLirFeePercent( uint256 _newValue) public onlyOwner returns (bool) {
        MINT_LIR_FEE_PERCENT = _newValue;
        return true;
    }

    /**
        * @dev Update LIR Burn fees to new Value (`newValue`).
        * Can only be called by the current owner.
    */
    function UpdateBurnLirFeePercent( uint256 _newValue) public onlyOwner returns (bool) {
        BURN_LIR_FEE_PERCENT = _newValue;
        return true;
    }

    /**
        * @dev Update ENZ operational fees to new Value (`newValue`).
        * Can only be called by the current owner.
    */
    function UpdateEnzOperFeePercent( uint256 _newValue) public onlyOwner returns (bool) {
        ENZ_OPER_FEE_PERCENT = _newValue;
        return true;
    }
}