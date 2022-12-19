/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface INFTREWARDS {
    function Deposit(uint256 amount) external returns (bool success);
}

interface IDogeTV {
    function allowtrading() external;
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function approve(address spender, uint256 amount) external returns (bool);
    function approveMax(address spender) external returns (bool);
    function authorize(address adr) external;
    event AutoLiquify(uint256 amountPairToken, uint256 amountToken);
    function changeTvPackagePrice(uint256 _ID, uint256 newPrice)
        external
        returns (bool success);
    function claimtokensback(address tokenAddress) external;
    event OwnershipTransferred(address owner);
    event PackageSubbed(address user, string packName);
    function removePair(address pairToRemove) external;
    function removeTvPackage(uint256 _ID) external returns (bool success);
    function setBlacklistArray(address[] memory walletToBlacklistArray)
        external;
    function setBlacklistedStatus(
        address walletToBlacklist,
        bool isBlacklistedBool
    ) external;
    function setDiscountPackPercentages(
        uint8 percentLowerMul10,
        uint8 percentHigherMul10
    ) external;
    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver
    ) external;
    function setFees(uint8 _liquidityFeeMul10, uint8 _marketingFeeMul10)
        external;
    function setInitialfees(
        uint8 _initialBuyFeePercentMul10,
        uint8 _initialSellFeePercentMul10
    ) external;
    function setIsFeeExempt(address holder, bool exempt) external;
    function setIsTxLimitExempt(address holder, bool exempt) external;
    function setmaxholdpercentage(uint256 percentageMul10) external;
    function setNFTContract(address ctrct) external;
    function setSpecialPackPercentages(
        uint8 percentLowerMul10,
        uint8 percentHigherMul10
    ) external;
    function setSwapBackSettings(bool _enabled, uint256 _amount) external;
    function setSwapThresholdDivisor(uint256 divisor) external;
    function setTxLimit(uint256 amount) external;
    function stopInitialTax() external;
    function subToPackage(uint256 _packageID, uint256 durationVariant)
        external
        returns (bool success);
    event SubWithdrawn(address user);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function transferOwnership(address adr) external;
    function unauthorize(address adr) external;
    function _maxHoldAmount() external view returns (uint256);
    function _maxTxAmount() external view returns (uint256);
    function AllfeeDenominator() external view returns (uint16);
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);
    function autoLiquidityReceiver() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function canTrade() external view returns (bool);
    function decimals() external pure returns (uint8);
    function discountPercentHigh() external view returns (uint8);
    function discountPercentLow() external view returns (uint8);
    function DtvPackages(uint256)
        external
        view
        returns (
            uint256 price,
            uint256 durationDays,
            uint256 packageID,
            string memory name,
            bool isOnlySpecial
        );
    function getCirculatingSupply() external view returns (uint256);
    function getEstimatedTokenForUSDT(uint256 USDTAmount)
        external
        view
        returns (uint256);
    function getOwner() external view returns (address);
    function getSubbedUsersLength()
        external
        view
        returns (uint256 SubbedUsersLength);
    function initialBuyFee() external view returns (uint8);
    function initialSellFee() external view returns (uint8);
    function initialTaxesEnabled() external view returns (bool);
    function isAuthorized(address adr) external view returns (bool);
    function isOwner(address account) external view returns (bool);
    function name() external pure returns (string memory);
    function NftStakingContract() external view returns (address);
    function specialPercentHigh() external view returns (uint8);
    function specialPercentLow() external view returns (uint8);
    function subbedUsers(uint256) external view returns (address);
    function swapEnabled() external view returns (bool);
    function swapThreshold() external view returns (uint256);
    function symbol() external pure returns (string memory);
    function totalFee() external view returns (uint8);
    function totalSupply() external view returns (uint256);

}


contract DogeTVSubscriptions is Auth {
    struct DogeTvPackage{
        uint256 price;
        uint256 durationDays;
        uint256 packageID;
        string name;
        bool isOnlySpecial;
    }

    struct SubbedTvPackage{
        uint256 subbedTime;
        uint256 expiration_time;
        uint256 packageID;
        uint256 packageVariant;
        bool wasDiscounted;
        bool isSpecial;
    }

    //Important addresses    
    address public DGTV = 0xFEb6d5238Ed8F1d59DCaB2db381AA948e625966D;//mainnet
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping (address => SubbedTvPackage) public userSubs;
    mapping(uint =>  DogeTvPackage) public DtvPackages;
    address[] public subbedUsers;
    uint public totalSubs;

    INFTREWARDS public NftStakingContract;

    constructor (address tokenOwner) Auth(tokenOwner) {
        owner = tokenOwner;
    }

    // READS
    function getPackageWithId(uint ID) internal view returns (DogeTvPackage memory package){
        return DtvPackages[ID];
    }

    function checkSubs(address user)internal view returns (bool wasdiscounted, bool isSpecial){
        return (userSubs[user].wasDiscounted,userSubs[user].isSpecial );
    }

    function getSubbedUsersLength()external view returns (uint SubbedUsersLength){
        return subbedUsers.length;
    }

    // WRITES

    function addTVPackage( uint256 ppvID, uint256 _USDTPriceNoDecimals, uint256 _durationDays, string calldata packName, bool onlyTopHolders) external authorized {
        DogeTvPackage memory packageToAdd;
        packageToAdd.durationDays = _durationDays;
        packageToAdd.packageID = ppvID;
        packageToAdd.name = packName;
        packageToAdd.price = _USDTPriceNoDecimals * 10 ** 6;
        packageToAdd.isOnlySpecial = onlyTopHolders;
        DtvPackages[ppvID] = packageToAdd;
    }

    function changeTvPackagePrice(uint256 _ID, uint256 newPrice) external authorized returns(bool success){
        DtvPackages[_ID].price = newPrice * 10 ** 6;
        return true;
    }

    function removeTvPackage(uint256 _ID) external authorized returns(bool success){
        delete DtvPackages[_ID];
        return true;
    }

    function subToPackage(uint _packageID, uint durationVariant)external returns(bool success){
        DogeTvPackage memory pack = getPackageWithId(_packageID);
        // get the price in token
        uint256 tokenPrice = IDogeTV(DGTV).getEstimatedTokenForUSDT(pack.price);
        uint256 balance = IDogeTV(DGTV).balanceOf(msg.sender);
        uint256 totalSupply = IDogeTV(DGTV).totalSupply();
        uint8 discountPercentHigh = IDogeTV(DGTV).discountPercentHigh();
        uint8 discountPercentLow = IDogeTV(DGTV).discountPercentLow();
        uint8 specialPercentLow = IDogeTV(DGTV).specialPercentLow();
        
        require(balance >= tokenPrice, "DogeTV, You dont have enough token for this");
        uint divisor = 1;
        bool isfree = false;
        bool isDiscounted = false;
        uint256 percentageHeld = ((balance*10) / totalSupply) * 100;
        if(percentageHeld >= discountPercentLow && percentageHeld <= discountPercentHigh){
            divisor = 2;
            isDiscounted = true;
        }
        if(percentageHeld > specialPercentLow){
            isfree = true;
        }
        if(pack.isOnlySpecial){
            require(isfree, "DogeTV: this package is not available to anyone not holding the requirements");
        }
        tokenPrice = tokenPrice / divisor;
        SubbedTvPackage memory packageSubbed;
        if(!isfree){
            require(!pack.isOnlySpecial, "DTV, only high percentage holders can have this package");
            IDogeTV(DGTV).transferFrom(msg.sender, DEAD, tokenPrice/2);
            IDogeTV(DGTV).transferFrom(msg.sender, address(NftStakingContract), tokenPrice/2);
        }
        
        packageSubbed.packageID =  pack.packageID;
        packageSubbed.wasDiscounted = isDiscounted;
        packageSubbed.isSpecial = isfree;
        packageSubbed.subbedTime = block.timestamp;
        packageSubbed.packageVariant = durationVariant;
        packageSubbed.expiration_time = block.timestamp + pack.durationDays * 86400;
        emit PackageSubbed(msg.sender, pack.name);
        userSubs[msg.sender] = packageSubbed;
        subbedUsers.push(msg.sender);
        return true;
    }

    function setNFTContract(INFTREWARDS ctrct)external authorized{
        NftStakingContract = ctrct;
    }

    event PackageSubbed(address user,string packName);
}