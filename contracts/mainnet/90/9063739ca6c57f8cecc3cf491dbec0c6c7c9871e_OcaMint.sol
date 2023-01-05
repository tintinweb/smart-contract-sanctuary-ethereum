/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

pragma solidity ^0.8.16;

// Developed by Orcania (https://orcania.io/)
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    
}

abstract contract OMS { //Orcania Management Standard
    address private _owner;

    event OwnershipTransfer(address indexed newOwner);

    receive() external payable {}

    constructor() {
        _owner = 0x6cC6F4B63883fa596f074c4a09bE7E35A9C7851B;
    }

    //Modifiers ==========================================================================================================================================
    modifier Owner() {
        require(msg.sender == _owner, "OMS: NOT_OWNER");
        _;  
    }

    //Read functions =====================================================================================================================================
    function owner() public view returns (address) {
        return _owner;
    }
    
    //Write functions ====================================================================================================================================
    function setNewOwner(address user) external Owner {
        _owner = user;
        emit OwnershipTransfer(user);
    }

}

contract OcaMint is OMS {
    IERC20 private immutable OCA = IERC20(0x3f8C3b9F543910F611585E3821B00af0617580A7);
    uint256 private immutable ETHprice = 1300;

    IERC20 private immutable USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 private immutable BUSD = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 private immutable USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint256 private _ethPrice = 84000000000000;
    uint256 private _privateEthPrice = 63000000000000;
    mapping (address => uint256) private _tokenPrice;
    mapping (address => uint256) private _privateTokenPrice;

    mapping(address/*user*/ => uint256 /*amount*/) private _ethPayed; //Amount of ETH this user payed to buy OCA
    mapping(address/*token*/ => mapping(address/*user*/ => uint256/*amount*/)) private _tokenPayed; //Amount of token the user payed to buy OCA
    mapping(address /*user*/ => uint256) private _privateBoughtOCA;
    mapping(address /*user*/ => uint256) private _vestingRoundsClaimed;

    //Dead line of the sale
    //If the project doesn't raise the needed funds by that time, users can revert their sale and get back their funds
    //The sale also ends on this date regardless if needed funds were raised or not
    uint256 private immutable _deadLine = block.timestamp + 10520000 /*4 months*/;
    uint256 private immutable _minimumFundsNeeded = 250000; //Minimum amount of USD needed
    uint256 private immutable _vestingStartTime = block.timestamp + 10520000; //Epoch sec at which vesting starts
    uint256 private immutable _vestingRoundTime =  2630000 /*1 month*/; //Time between vesting rounds 

    bool private _goalReached = false;
    uint256 private _totalOcaReserved; //OCA reserved for private investors

    event BuyOCA(address indexed token, uint256 amountPayed, uint256 ocaAmountBought);
    event PrivateBuyOCA(address indexed token, uint256 amountPayed, uint256 ocaAmountBought);

    constructor() {
        _tokenPrice[address(USDT)] = 10**USDT.decimals() / 10;
        _tokenPrice[address(BUSD)] = 10**BUSD.decimals() / 10;
        _tokenPrice[address(USDC)] = 10**USDC.decimals() / 10;

        _privateTokenPrice[address(USDT)] = 75 * 10**USDT.decimals() / 1000;
        _privateTokenPrice[address(BUSD)] = 75 * 10**BUSD.decimals() / 1000;
        _privateTokenPrice[address(USDC)] = 75 * 10**USDC.decimals() / 1000;
    }

    //Checks if sale is still open & if `amount` of OCA is available to be sold
    modifier isSaleValid(uint256 amount) {
        require(block.timestamp < _deadLine, "SALE_PERIOD_IS_OVER");

        require(OCA.balanceOf(address(this)) - (amount * 10**18) >= _totalOcaReserved, "INSUFFICIENT_OCA REDUCE_AMOUNT_YOU_ARE_TRYING_TO_BUY");

        _;
    }

    //Read functions=========================================================================================================================
    function price() external view returns (uint256) {return _ethPrice;}
    function privatePrice() external view returns(uint256) {return _privateEthPrice;}    
    function tokenPrice(address token) external view returns (uint256) {return _tokenPrice[token];}
    function privateTokenPrice(address token) external view returns(uint256) {return _privateTokenPrice[token];}

    function getEthPayed(address user) external view returns(uint256) {return _ethPayed[user];}
    function getTokenPayed(address token, address user) external view returns(uint256) {return _tokenPayed[token][user];}
    function getPrivateBoughtOCA(address user) external view returns(uint256) {return _privateBoughtOCA[user];}
    function getVestingRoundsClaimed(address user) external view returns(uint256) {return _vestingRoundsClaimed[user];}
     
    function getDeadline() external view returns(uint256) {return _deadLine;}
    function getMinimumFundsNeeded()  external view returns(uint256) {return _minimumFundsNeeded;}
    function getVestingStartTime() external view returns(uint256) {return _vestingStartTime;}
    function goalReached() external view returns(bool) {return _goalReached;}
    function totalOcaBought() external view returns(uint256) {return _totalOcaReserved;}
    //Owner Write Functions========================================================================================================================
    function changeEthPrice(uint256 price, uint256 privatePrice) external Owner {
        _ethPrice = price;    
        _privateEthPrice = privatePrice;
    } 

    function changeTokenPrice(address token, uint256 price, uint256 privatePrice) external Owner {
        _tokenPrice[token] = price;
        _privateTokenPrice[token] = privatePrice;
    }  

    //User write functions=========================================================================================================================
    function buyWithEth(uint256 amount) external payable isSaleValid(amount) {
        require(msg.value == _ethPrice * amount, "WRONG_ETH_VALUE");

        amount *= 10**18;
        OCA.transfer(msg.sender, amount);
        _ethPayed[msg.sender] += msg.value;

        emit BuyOCA(address(0), msg.value, amount);
    }

    function buyWithToken(address token, uint256 amount) external isSaleValid(amount) {
        uint256 price = _tokenPrice[token];
        require(price != 0, "UNSUPPORTED_TOKEN");

        uint256 total = price * amount;
        require(IERC20(token).transferFrom(msg.sender, address(this), total), "FAILED_TO_RECEIVE_PAYMENT");

        amount *= 10**18;
        OCA.transfer(msg.sender, amount);
        _tokenPayed[token][msg.sender] += total;

        emit BuyOCA(token, total, amount);
    }

    function privateBuyWithEth(uint256 amount) external payable isSaleValid(amount) {
        require(msg.value == _privateEthPrice * amount, "WRONG_ETH_VALUE");

        amount *= 10**18;
        _privateBoughtOCA[msg.sender] += amount;
        _ethPayed[msg.sender] += msg.value;

        emit PrivateBuyOCA(address(0), msg.value, amount);
    }

    function privateBuyWithToken(address token, uint256 amount) external isSaleValid(amount) {
        uint256 price = _privateTokenPrice[token];
        require(price != 0, "UNSUPPORTED_TOKEN");

        uint256 total = price * amount;
        require(IERC20(token).transferFrom(msg.sender, address(this), total), "FAILED_TO_PAY");

        amount *= 10**18;
        _privateBoughtOCA[msg.sender] += amount;
        _tokenPayed[token][msg.sender] += total;
        
        emit PrivateBuyOCA(token, total, amount);
    }

    function checkGoal() external {
        uint256 totalValueCollected = 0;

        totalValueCollected += address(this).balance * ETHprice / 10**18; //ETH_USD_valueCollected 

        totalValueCollected += USDT.balanceOf(address(this)) / 10**USDT.decimals(); //USDT_USD_valueCollected
        totalValueCollected += BUSD.balanceOf(address(this)) / 10**BUSD.decimals(); //BUSD_USD_valueCollected
        totalValueCollected += USDC.balanceOf(address(this)) / 10**USDC.decimals(); //USDC_USD_valueCollected

        if(totalValueCollected >= _minimumFundsNeeded) {_goalReached = true;}
        else {revert("GOAL_NOT_REACHED");}

    }
    //Refund Functions==========================================================================================================================
    function revertPurchaseWithEth(address[] calldata users) external {
        require(block.timestamp > _deadLine, "SALE_IS_NOT_OVER_YET");
        require(!_goalReached, "GOAL_REACHED");

        uint256 length = users.length;

        for(uint256 t; t < length; ++t) {
            address user = users[t];
            sendValue(payable(user), _ethPayed[user]);

            _ethPayed[user] = 0;
        }
    }
    
    function revertPurchaseWithToken(address token, address[] calldata users) external {
        require(block.timestamp > _deadLine, "SALE_IS_NOT_OVER_YET");
        require(!_goalReached, "GOAL_REACHED");

        IERC20 Token = IERC20(token);
        uint256 length = users.length;

        for(uint256 t; t < length; ++t) {
            address user = users[t];
            Token.transfer(user, _tokenPayed[token][user]);

            _tokenPayed[token][user] = 0;
        }
    }

    //Withdraw Functions========================================================================================================================

    function withdraw(address payable to, uint256 value) external Owner {
        require(_goalReached, "GOAL_NOT_REACHED");
        sendValue(to, value);  
    }

    function withdrawERC20(address token, address to, uint256 value) external Owner {
        require(_goalReached, "GOAL_NOT_REACHED");
        IERC20(token).transfer(to, value);   
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "UNABLE_TO_SEND_VALUE RECIPIENT_MAY_HAVE_REVERTED");
    }

    //Vesting Functions=========================================================================================================================

    //Claim OCA from vesting
    function claim(address[] calldata users) external {
        require(block.timestamp > _vestingStartTime, "VESTING_HAS_NOT_STARTED_YET");
        require(_goalReached, "GOAL_NOT_REACHED");

        uint256 roundsAvailable = 1; //Once the vesting starts private investors can claim one round

        uint256 timeSinceVestingStarted = block.timestamp - _vestingStartTime; 
        roundsAvailable += (timeSinceVestingStarted / _vestingRoundTime /*1 month in sec*/); //They can claim another round each month
        if(roundsAvailable > 6) {roundsAvailable = 6;}

        uint256 length = users.length;
        for(uint256 t; t < length; ++t) {
            address user = users[t];

            uint256 unclaimedRounds = roundsAvailable - _vestingRoundsClaimed[user];
            if(unclaimedRounds == 0) {continue;}

            uint256 OcaClaimPerRound = _privateBoughtOCA[user] / 6;
            uint256 unclaimedOca = OcaClaimPerRound * unclaimedRounds;

            OCA.transfer(user, unclaimedOca);
            _vestingRoundsClaimed[user] = roundsAvailable;
        }
    }
}