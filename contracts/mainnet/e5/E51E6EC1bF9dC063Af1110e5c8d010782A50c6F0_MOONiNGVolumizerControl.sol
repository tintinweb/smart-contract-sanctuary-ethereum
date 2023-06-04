/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

interface AIVolumizer {
    function tokenVolumeTransaction(address _contract) external;
    function tokenManualVolumeTransaction(address _contract, uint256 maxAmount, uint256 volumePercentage) external;
    function setTokenMaxVolumeAmount(address _contract, uint256 maxAmount) external;
    function setTokenMaxVolumePercent(address _contract, uint256 volumePercentage, uint256 denominator) external;
    function viewDevAboveBalance(address _developer) external view returns (bool);
    function viewInvalidRequest(address _contract) external view returns (bool);
    function onboardTokenClient(address _contract, address _developer, uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 denominator) external;
    function rescueHubERC20(address token, address receiver, uint256 amount) external;
    function viewProjectTokenParameters(address _contract) external view returns (uint256, uint256, uint256);
    function veiwVolumeStats(address _contract) external view returns (uint256 totalPurchased, 
        uint256 totalETH, uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime);
    function viewLastVolumeBlock(address _contract) external view returns (uint256);
    function viewTotalTokenPurchased(address _contract) external view returns (uint256);
    function viewTotalETHPurchased(address _contract) external view returns (uint256);
    function viewLastETHPurchased(address _contract) external view returns (uint256);
    function viewLastTokensPurchased(address _contract) external view returns (uint256);
    function viewTotalTokenVolume(address _contract) external view returns (uint256);
    function viewLastTokenVolume(address _contract) external view returns (uint256);
    function viewLastVolumeTimestamp(address _contract) external view returns (uint256);
    function viewNumberTokenVolumeTxs(address _contract) external view returns (uint256);
    function viewNumberETHVolumeTxs(address _contract) external view returns (uint256);
}

contract MOONiNGVolumizerControl is Auth {
    using SafeMath for uint256;
    AIVolumizer volumizer;
    
    bool public manualVolumeAllowed = false;
    bool allowedToFund = true;
    bool tokenVolume = true;
    
    address tokenContract;
    address devAddress;
    uint256 public amountTokensFunded;
    mapping(address => bool) public isDevAllowed;
    
    uint256 public volumePercentage = 100;
    uint256 private denominator = 100;
    uint256 public maxAmount = 100000000000000 * (10 ** 18);
    uint256 public decimals = 18;
    uint256 public totalSupply = 100000000000000 * (10 ** 18);

    event eSetTokenContractDetails(address indexed token, uint256 indexed decimals, uint256 indexed timestamp);
    event eSetVolumeParameters(uint256 indexed volumepercentage, uint256 indexed maxamount, uint256 indexed timestamp);
    event eUpgradeVolumizerContract(address indexed user, address indexed volumizer, uint256 indexed timestamp);
    event eSetIsDevAllowed(address indexed user, bool indexed enable, uint256 indexed timestamp);
    event eSetParameters(bool indexed volumeallowed, bool indexed tokenvolume, uint256 indexed timestamp);
    event eSetTokenAnitMEV(bool indexed blockdelay, uint256 numberofblocks, bool indexed seconddelay, uint256 numberofseconds, uint256 indexed timestamp);
    event eRescueVolumizerTokensPercent(address indexed user, uint256 indexed percent, uint256 amount, uint256 userbalance, uint256 volumizerbalance, uint256 indexed timestamp);
    event eRescueVolumizerTokensAmount(address indexed user, uint256 indexed amount, uint256 userbalance, uint256 volumizerbalance, uint256 indexed timestamp);
    event eUserFundVolumizerContract(address indexed user, uint256 indexed amount, uint256 userbalance, uint256 volumizerbalance, uint256 indexed timestamp);
    event ePerformVolumizer(address indexed user, bool indexed tokenvolume, uint256 indexed timestamp);
    event eVolumeTokenTransaction(address indexed tokencontract, uint256 indexed lastTokensPurchased, uint256 lastETHPurchased, uint256 lastTokenVolume, uint256 volumebalance, uint256 indexed timestamp);
    event eVolumeETHTransaction(address indexed tokencontract, uint256 indexed lastTokensPurchased, uint256 lastETHPurchased, uint256 lastTokenVolume, uint256 volumebalance, uint256 indexed timestamp);

    receive() external payable {}
    constructor() Auth(msg.sender) {
        volumizer = AIVolumizer(0xE818B4aFf32625ca4620623Ac4AEccf7CBccc260);
        tokenContract = address(0x31dB94ca4FDf231772254e8072AAb20e4071970a);
        authorize(msg.sender); 
        authorize(address(this));
    }

    function viewParameterSettings() external view returns (bool volumeallowed, bool allowedtofund, bool _tokenVolume) {
        return(manualVolumeAllowed, allowedToFund, tokenVolume);
    }

    function setTokenContractDetails(address _token, uint256 _totalSupply, uint256 _decimals, address developer) external authorized {
        tokenContract = _token; decimals = _decimals; totalSupply = _totalSupply.mul(10 ** decimals); devAddress = developer;
        emit eSetTokenContractDetails(_token, _decimals, block.timestamp);
    }

    function onboardTokenClient(address _token, address developer, uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _totalSupply, uint256 _decimals) external authorized {
        volumePercentage = _volumePercentage; maxAmount = totalSupply.mul(_maxVolumeAmount).div(uint256(10000));
        require(_volumePercentage <= uint256(100), "Value Must Be Less Than or Equal to Denominator");
        tokenContract = _token; decimals = _decimals; totalSupply = _totalSupply.mul(10 ** decimals); devAddress = developer;
        volumizer.onboardTokenClient(_token, developer, maxAmount, volumePercentage, uint256(100));
    }

    function SetVolumeParameters(uint256 _volumePercentage, uint256 _maxAmount) external {
        require(isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        volumePercentage = _volumePercentage; maxAmount = totalSupply.mul(_maxAmount).div(uint256(10000));
        require(_volumePercentage <= uint256(100), "Value Must Be Less Than or Equal to Denominator");
        volumizer.setTokenMaxVolumeAmount(address(tokenContract), maxAmount);
        volumizer.setTokenMaxVolumePercent(address(tokenContract), _volumePercentage, uint256(100));
        emit eSetVolumeParameters(_volumePercentage, _maxAmount, block.timestamp);
    }

    function upgradeVolumizerContract(address volumizerCA) external authorized {
        volumizer = AIVolumizer(volumizerCA);
        emit eUpgradeVolumizerContract(msg.sender, volumizerCA, block.timestamp);
    }

    function setIsDevAllowed(address _address, bool enable) external authorized {
        isDevAllowed[_address] = enable;
        emit eSetIsDevAllowed(_address, enable, block.timestamp);
    }

    function setIsAllowedToFund(bool enable) external authorized {
        allowedToFund = enable;
    }

    function setParameters(bool _manualVolumeAllowed, bool _tokenVolume) external authorized {
        manualVolumeAllowed = _manualVolumeAllowed; tokenVolume = _tokenVolume;
        emit eSetParameters(_manualVolumeAllowed, _tokenVolume, block.timestamp);
    }

    function RescueVolumizerTokensPercent(uint256 percent) external {
        require(isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        uint256 amount = IERC20(tokenContract).balanceOf(address(volumizer)).mul(percent).div(denominator);
        volumizer.rescueHubERC20(tokenContract, msg.sender, amount);
        uint256 newVBalance = IERC20(tokenContract).balanceOf(address(volumizer));
        uint256 newUBalance = IERC20(tokenContract).balanceOf(address(msg.sender));
        emit eRescueVolumizerTokensPercent(msg.sender, percent, amount, newUBalance, newVBalance, block.timestamp);
    }

    function RescueVolumizerTokens(uint256 amount) external {
        require(isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        uint256 tokenAmount = amount.mul(10 ** decimals);
        volumizer.rescueHubERC20(tokenContract, msg.sender, tokenAmount);
        uint256 newVBalance = IERC20(tokenContract).balanceOf(address(volumizer));
        uint256 newUBalance = IERC20(tokenContract).balanceOf(address(msg.sender));
        emit eRescueVolumizerTokensAmount(msg.sender, amount, newUBalance, newVBalance, block.timestamp);
    }

    function UserFundVolumizerContract(uint256 amount) external {
        require(allowedToFund || isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        uint256 amountTokens = amount.mul(10 ** decimals); 
        IERC20(tokenContract).transferFrom(msg.sender, address(volumizer), amountTokens);
        amountTokensFunded = amountTokensFunded.add(amountTokens);
        uint256 newVBalance = IERC20(tokenContract).balanceOf(address(volumizer));
        uint256 newUBalance = IERC20(tokenContract).balanceOf(address(msg.sender));
        emit eUserFundVolumizerContract(msg.sender, amount, newUBalance, newVBalance, block.timestamp);
    }

    function PerformVolumizer() external {
        require(manualVolumeAllowed || isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        require(tokenVolume, "Volumizer is disabled");
        volumeTokenTransaction();
        emit ePerformVolumizer(msg.sender, tokenVolume, block.timestamp);
    }

    function ManualVolumizer(uint256 _maxAmount, uint256 _volumePercentage) external {
        require(isAuthorized(msg.sender) || isDevAllowed[msg.sender], "Volumizer Dictates Function");
        uint256 newAmount = totalSupply.mul(_maxAmount).div(uint256(10000));
        volumizer.tokenManualVolumeTransaction(address(tokenContract), newAmount, _volumePercentage);
    }

    function volumeTokenTransaction() internal {
        volumizer.tokenVolumeTransaction(tokenContract);
        uint256 newVBalance = IERC20(tokenContract).balanceOf(address(volumizer));
        emit eVolumeTokenTransaction(tokenContract, viewLastTokensPurchased(), viewLastETHPurchased(), viewLastTokenVolume(), newVBalance, block.timestamp);
    }

    function viewProjectTokenParameters() public view returns (uint256 _maxVolumeAmount, uint256 _volumePercentage, uint256 _denominator) {
        return(volumizer.viewProjectTokenParameters(tokenContract));
    }

    function viewDevAboveBalance() external view returns (bool) {
        return(volumizer.viewDevAboveBalance(devAddress));
    }
    
    function viewInvalidRequest() external view returns (bool) {
        return(volumizer.viewInvalidRequest(tokenContract));
    }

    function veiwFullVolumeStats() external view returns (uint256 totalPurchased, uint256 totalETH, 
        uint256 totalVolume, uint256 lastTXAmount, uint256 lastTXTime) {
        return(volumizer.viewTotalTokenPurchased(tokenContract), volumizer.viewTotalETHPurchased(tokenContract), 
            volumizer.viewTotalTokenVolume(tokenContract), volumizer.viewLastTokenVolume(tokenContract), 
                volumizer.viewLastVolumeTimestamp(tokenContract));
    }
    
    function viewTotalTokenPurchased() public view returns (uint256) {
        return(volumizer.viewTotalTokenPurchased(tokenContract));
    }

    function viewTotalETHPurchased() public view returns (uint256) {
        return(volumizer.viewTotalETHPurchased(tokenContract));
    }

    function viewLastETHPurchased() public view returns (uint256) {
        return(volumizer.viewLastETHPurchased(tokenContract));
    }

    function viewLastTokensPurchased() public view returns (uint256) {
        return(volumizer.viewLastTokensPurchased(tokenContract));
    }

    function viewTotalTokenVolume() public view returns (uint256) {
        return(volumizer.viewTotalTokenVolume(tokenContract));
    }
    
    function viewLastTokenVolume() public view returns (uint256) {
        return(volumizer.viewLastTokenVolume(tokenContract));
    }

    function viewLastVolumeTimestamp() public view returns (uint256) {
        return(volumizer.viewLastVolumeTimestamp(tokenContract));
    }

    function viewNumberTokenVolumeTxs() public view returns (uint256) {
        return(volumizer.viewNumberTokenVolumeTxs(tokenContract));
    }

    function viewTokenBalanceVolumizer() public view returns (uint256) {
        return(IERC20(tokenContract).balanceOf(address(volumizer)));
    }

    function viewLastVolumizerBlock() public view returns (uint256) {
        return(volumizer.viewLastVolumeBlock(tokenContract));
    }
}