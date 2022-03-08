//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GravitySCtest {
    uint strategyCount;
    uint tradeAmount;
    bool tradeExecuted;

    enum AssetType { DAI, wETH, LINK }
    enum IntervalFrquency { Daily, Weekly, Monthly, Quaterly, HalfYearly }

    // user address to user Account policy mapping
    mapping (address => Account[]) public accounts;
    // timestamp interval to PurchaseOrder mapping
    mapping (uint => PurchaseOrder[]) public liveStrategies;
    // ERC20 token address mapping
    mapping (string => address) public tokenAddresses;

    constructor() {
        // load asset addresses into tokenAddress mapping
        tokenAddresses['DAI'] = address(0xC4375B7De8af5a38a93548eb8453a498222C4fF2);
        tokenAddresses['WETH'] = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
        tokenAddresses['LINK'] = address(0xa36085F69e2889c224210F603D836748e7dC0088);
    }

    event Deposited(address, uint256);
    event Withdrawn(address, uint256);

    // data structure for each account policy
    struct Account {
        uint             accountId;
        uint             accountStart;
        AssetType        sourceAsset;
        AssetType        targetAsset;
        uint             sourceBalance;
        uint             targetBalance;
        uint             intervalAmount;
        IntervalFrquency strategyFrequency;   // number of interval days, minimum will be 1 day and max yearly;         // timestamp offset
    }

    // purchase order details for a user & account policy at a specific interval
    struct PurchaseOrder {
        address user;
        uint    accountId;
        uint    purchaseAmount;
    }

    // deposit first requires approving an allowance by the msg.sender
    function deposit(string memory _sourceAsset, uint256 _amount) external {
        require(tokenAddresses[_sourceAsset] != address(0x0), "Unsupported asset type");
        address _token = tokenAddresses[_sourceAsset];
        accounts[msg.sender][0].sourceBalance += _amount;
        (bool success) = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Deposit unsuccessful: transferFrom");
        emit Deposited(msg.sender, _amount);
    }

    function withdraw(string memory _sourceAsset, uint256 _amount) external {
        address _token = tokenAddresses[_sourceAsset];
        require(accounts[msg.sender][0].sourceBalance >= _amount);
        accounts[msg.sender][0].sourceBalance -= _amount;
        (bool success) = IERC20(_token).transfer(msg.sender, _amount);
        require(success, "Withdraw unsuccessful");
        emit Withdrawn(msg.sender, _amount);
    }
}