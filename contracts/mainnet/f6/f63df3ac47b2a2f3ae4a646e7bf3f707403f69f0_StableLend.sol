/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface IERC20 {

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}
interface IRToken{
     function main() external view returns (IMain);
}
interface IMain{
    function basketHandler() external view returns (IBasketHandler);
}
interface ICollateral {
    function strictPrice() external view returns(uint192);
}
interface IBasketHandler {
    function price(bool allowFallback) external view returns (bool isFallback, uint192 p);
}

contract StableLend {

    mapping(address => bool) public whitelistCollateral;
    mapping(uint256 => address) public whitelistCollateralList;
    uint256 public whitelistCollateralCount;

    address public rsvToken;

    address public owner;
    mapping(address => mapping(address => uint256)) public balances;

    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public stakeBalance;

    uint256 public totalStakeSupply; // total supply of stake rsv token

    uint256 public liquidationThreshold; // threshold below which collateral will be liquidated, eg 120 (require atleast 120% collateral)

    constructor(address rsvToken_, uint256 liquidationThreshold_, address[] memory whitelistCollateral_){
        owner = msg.sender;

        rsvToken = rsvToken_;
        liquidationThreshold = liquidationThreshold_;
        totalStakeSupply = 0;
        for(uint i = 0;i < whitelistCollateral_.length;i++){
            addWhitelistCollateral(whitelistCollateral_[i]);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Sender must be owner");
        _;
    }

    function deposit(uint256 amount, address rToken) public {
        require(amount > 0);
        require(whitelistCollateral[rToken],"Invalid Collateral");
        require(IERC20(rToken).transferFrom(msg.sender, address(this), amount), "Transfer Error");

        balances[msg.sender][rToken] += amount;
    }

    function withdraw(uint256 amount, address rToken) public {
        require(amount > 0 && balances[msg.sender][rToken] >= amount , "Invalid amount");
        require(borrowed[msg.sender] < 1e17,"Repay Loan");
        balances[msg.sender][rToken] -= amount;
        IERC20(rToken).transfer(msg.sender, amount);
    }

    function borrow(uint256 amount) public {
        uint256 collateral = calculateCollateral(msg.sender);
        uint256 alreadyBorrowed = borrowed[msg.sender];
        require(amount > 0);
        require(collateral - alreadyBorrowed > amount, "Not enough collateral");
        require(IERC20(rsvToken).balanceOf(address(this)) > amount, "Not enough balance");

        borrowed[msg.sender] += amount;
        IERC20(rsvToken).transfer(msg.sender, amount);
    }

    function repay(uint256 amount) public {

        require(amount > 0 && borrowed[msg.sender] >= amount);
        require(IERC20(rsvToken).transferFrom(msg.sender, address(this), amount), "Transfer Error");

        borrowed[msg.sender] -= amount;
    }

    function liquidate(address borrower) public{
        uint256 collateral = calculateCollateral(borrower);
        uint256 borrow_ = borrowed[borrower];

        if((borrow_ * liquidationThreshold)/100 >= collateral){
            require(IERC20(rsvToken).transferFrom(msg.sender, address(this), borrow_));
            // tranfer collateral
            for(uint256 i = 0; i < whitelistCollateralCount;i++){
                address collateralAddress = whitelistCollateralList[i];
                balances[msg.sender][collateralAddress] += balances[borrower][collateralAddress];
            }
        }
    }

    function stake(uint256 amount) public {
        require(amount > 0);
        uint256 stakeAmount = stakePrice(amount);
        require(IERC20(rsvToken).transferFrom(msg.sender, address(this), amount), "Transfer Error");
        totalStakeSupply += stakeAmount; 
        stakeBalance[msg.sender] += stakeAmount;
    }

    function unstake(uint256 amount) public {
        require(amount > 0 && stakeBalance[msg.sender] >= amount);
        uint256 stakeAmount = stakePrice(amount);
        totalStakeSupply -= stakeAmount;
        stakeBalance[msg.sender] -= stakeAmount;

        require(IERC20(rsvToken).transfer(msg.sender, amount), "Transfer Error");
    }

    function stakePrice(uint256 amount) public view returns(uint256){
        if(totalStakeSupply == 0 || IERC20(rsvToken).balanceOf(address(this)) == 0) return amount;
        return (amount * IERC20(rsvToken).balanceOf(address(this))) / totalStakeSupply;
    }

    function calculateCollateral(address collateralOwner) public view returns(uint256 value) {
        for(uint256 i = 0; i < whitelistCollateralCount;i++){
            (,uint192 price) = IRToken(whitelistCollateralList[i]).main().basketHandler().price(false);
            value += (uint256(price) * balances[collateralOwner][whitelistCollateralList[i]])/1e18;
        }
    }

    function calculateSingleCollateral(address collateralOwner, address collateral) public view returns(uint256 value) {
        (,uint192 price) = IRToken(collateral).main().basketHandler().price(false);
        return (uint256(price) * balances[collateralOwner][collateral])/1e18;
    }

    function addWhitelistCollateral(address collateral) public onlyOwner {
        whitelistCollateral[collateral] = true;
        whitelistCollateralList[whitelistCollateralCount] = collateral;
        whitelistCollateralCount += 1;
    }

    function removeWhitelistCollateral(address collateral) public onlyOwner {
        whitelistCollateral[collateral] = false;
    }

    function changeLiquidationThreshold(uint256 liquidationThreshold_) public onlyOwner {
        liquidationThreshold = liquidationThreshold_;
    }
}