pragma solidity ^0.8.16;

interface IERC20 {
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function approve(address,uint) external;
}

interface IVault {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
    );
}

contract Purchaser {
    
    mapping(address => bool) public whitelist;
    
    uint public startTime;
    uint public runTime;
    uint public lastBuy;

    uint public dailyLimit;
    uint public dailyBuy;
    uint public lifetimeLimit;
    uint public lifetimeBuy;
    uint public minInvPrice;
    uint public bonusBps;

    address public constant gov = 0x926dF14a23BE491164dCF93f4c468A50ef659D5B;
    IVault public constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    bytes32 public constant poolId = bytes32(0x441b8a1980f2f2e43a9397099d15cc2fe6d3625000020000000000000000035f);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant INV = IERC20(0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68);

    modifier onlyGov(){
        require(msg.sender == gov, "ONLY GOV");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "ONLY WHITELIST");
        _;
    }

    function buy(uint amount, uint maxInvPrice) external onlyWhitelist {
        require(startTime != 0 && runTime != 0, "NOT INITIALIZED");
        require(block.timestamp > startTime && block.timestamp < startTime + runTime, "OUT OF BUY PERIOD");
        require(limitAvailable() >= amount, "BUY EXCEED LIMIT");
        if(lastBuy >= lastReset()){
            dailyBuy += amount;
        } else {
            dailyBuy = amount;
        }
        lastBuy = block.timestamp;
        lifetimeBuy += amount;
        USDC.transferFrom(msg.sender, gov, amount);
        
        uint invPrice = getInvPrice();
        require(invPrice >= minInvPrice, "INV PRICE TOO LOW");
        require(invPrice <= maxInvPrice, "INV PRICE TOO HIGH");

        uint invToReceive = amount * 10**18 * 10**12 / invPrice; //Amount is multiplied by 10**30, 10**18 from invPrice precision and 10**12 to account for USDC low decimals
        invToReceive += invToReceive * bonusBps / 10000;

        INV.transfer(msg.sender, invToReceive);
        emit Buy(block.timestamp, amount, invToReceive, msg.sender);
    }

    function getInvPrice() public view returns(uint){
        (,uint256[] memory balances,) = vault.getPoolTokens(poolId);
        return balances[1] * 10**18 / balances[0];
    }

    function lastReset() public view returns(uint){
        return block.timestamp - block.timestamp % 1 days;
    }

    function limitAvailable() public view returns(uint){
        uint dailyLimitAvailable = lastBuy >= lastReset() ? dailyLimit - dailyBuy : dailyLimit;
        uint lifetimeLimitAvailable = lifetimeLimit - lifetimeBuy;
        return dailyLimitAvailable < lifetimeLimitAvailable ? dailyLimitAvailable : lifetimeLimitAvailable;
    }

    /***********************************************************/
    /****************** ADMIN FUNCTIONS ************************/
    /***********************************************************/

    function init(uint _startTime, uint _runTime, uint _dailyLimit, uint _lifetimeLimit, uint _bonusBps, uint _minInvPrice) external onlyGov{
        require(startTime == 0 && runTime == 0, "ALREADY INITIALIZED");
        require(_bonusBps <= 10000);
        startTime = _startTime;
        runTime = _runTime;
        dailyLimit = _dailyLimit;
        lifetimeLimit = _lifetimeLimit;
        bonusBps = _bonusBps;
        minInvPrice = _minInvPrice;
    }

    function toggleWhitelist(address buyer) external onlyGov {
        whitelist[buyer] = !whitelist[buyer];
    }

    function sweep(address token) external onlyGov {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(gov, balance);
    }

    function setMinInvPrice(uint newMinPrice) external onlyGov {
        minInvPrice = newMinPrice;
    }

    function extendBuyPeriod(uint additionalTime) external onlyGov {
        runTime += additionalTime;       
    }

    event Buy(uint timestamp, uint usdcAmount, uint invAmount, address purchaser);
}