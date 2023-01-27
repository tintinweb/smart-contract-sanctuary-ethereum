/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: node_modules\@openzeppelin\contracts\access\Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\PrivateSale.sol

pragma solidity ^0.6.0;


contract Token {
    function balanceOf(address account) public view returns (uint256) {}
    function transferFrom(address sender, address recipient, uint256 amount) public {}
    function approve(address spender, uint256 amount) public {}
}

contract PaymentContract {
    function balanceOf(address account) public view returns (uint256) {}
    function transferFrom(address sender, address recipient, uint256 amount) public {}
    function approve(address spender, uint256 amount) public {}
}

contract PrivateSale is Ownable{

    event TokensLocked(address indexed investor, uint256 indexed amount);
    event ReceivedPayment(address indexed investor, uint256 indexed amount);
    event PaymentWithdrawal(address indexed adminWallet, uint256 indexed amount);
    event ClaimedTokens(address indexed investor, uint256 indexed tokens);

    uint256 private allocatedLiquidity;
    address payable private adminWallet;
    uint256 private lockInterval;
    Token private token;
    PaymentContract private payment;

    struct packageDetails {
        uint256 lockedTokens;
        uint256 lockTime;
    }

    mapping (address => uint256) private lockedByAddress;

    mapping (uint256 => uint256) private packageAmount;
    mapping (uint256 => uint256) private packageRate;

    mapping (address => uint256) private packagesByAddress;
    mapping (address => mapping(uint256 => packageDetails)) private addressPlanDetails; 


    constructor(address _token, address _payment, address payable _adminWallet) public {
        adminWallet = _adminWallet;
        token = Token(_token);
        payment = PaymentContract(_payment);
        allocatedLiquidity = 0;
        lockInterval = 300;
        
        packageAmount[1] = 500 * (1**6);
        packageAmount[2] = 1000 * (1**6);
        packageAmount[3] = 5000 * (1**6);
        packageAmount[4] = 10000 * (1**6);
        packageAmount[5] = 25000 * (1**6);
        packageAmount[6] = 50000 * (1**6);
        packageAmount[7] = 100000 * (1**6);

        packageRate[1] = 2500 * 1 ether;
        packageRate[2] = 5555 * 1 ether;
        packageRate[3] = 31250 * 1 ether;
        packageRate[4] = 71428 * 1 ether;
        packageRate[5] = 208333 * 1 ether;
        packageRate[6] = 500000 * 1 ether;
        packageRate[7] = 1250000 * 1 ether;
    }

    function addPackage(uint256 packageNumber, uint256 amount, uint256 rate) public onlyOwner{
        packageAmount[packageNumber] = amount;
        packageRate[packageNumber] = rate;
    }

    function getPackageAmount(uint256 packageNumber) public view returns(uint256) {
        return packageAmount[packageNumber];
    }

    function getPackageRate(uint256 packageNumber) public view returns(uint256) {
        return packageRate[packageNumber];
    }

    function setCurrencyAddress(address newCurrency) public onlyOwner {
        token = Token(newCurrency);
    }

    function setPaymentAddress(address newPayment) public onlyOwner {
        payment = PaymentContract(newPayment);
    }

    function getCurrencyContract() public view returns(address) {
        return address(token);
    }

    function getPaymentContract() public view returns(address) {
        return address(payment);
    }


    function getPrivateSaleLiquidity() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getAllocatedLiquidity() public view returns (uint256) {
        return allocatedLiquidity;
    }

    function getPakcagesByUser(address privateInvestor) public view returns(uint256) {
        return packagesByAddress[privateInvestor];
    }

    function getLiquidityByUser(address privateInvestor) public view returns(uint256) {
        return lockedByAddress[privateInvestor];
    }

    function getPlanLiquidityByUser(address privateInvestor, uint256 planNumber) public view returns(uint256) {
        return addressPlanDetails[privateInvestor][planNumber].lockedTokens;
    }

    function getPlanLockTimeByUser(address privateInvestor, uint256 planNumber) public view returns(uint256) {
        return addressPlanDetails[privateInvestor][planNumber].lockTime;
    }

    function setLockInterval(uint256 time) public onlyOwner {
        lockInterval = time;
    }

    function getLockInterval() public view returns(uint256) {
        return lockInterval;
    }


    function purchasePackage(uint256 packageNumber) public {
        require(packageAmount[packageNumber] != 0, "Package not found");
        require(payment.balanceOf(msg.sender) >= packageAmount[packageNumber], "Insufficient Balance");
        payment.transferFrom(msg.sender, address(this), packageAmount[packageNumber]);
        uint256 tokensLocked = packageRate[packageNumber];
        setLockedTokens(msg.sender, tokensLocked);
        
        emit ReceivedPayment(msg.sender, packageAmount[packageNumber]);
        emit TokensLocked(msg.sender, tokensLocked);
    }

    function setLockedTokens(address privateInvestors, uint256 amounts) internal{
            if(packagesByAddress[privateInvestors] > 0){
                require(allocatedLiquidity + amounts <= getPrivateSaleLiquidity(), "PrivateSale: Amount is exceeding from max liquidity");
                
                uint256 existingAmount = lockedByAddress[privateInvestors];
                lockedByAddress[privateInvestors] = existingAmount + amounts;

                packagesByAddress[privateInvestors] = packagesByAddress[privateInvestors] + 1;
                addressPlanDetails[privateInvestors][packagesByAddress[privateInvestors]].lockedTokens = amounts;
                addressPlanDetails[privateInvestors][packagesByAddress[privateInvestors]].lockTime = block.timestamp + lockInterval;
                
                allocatedLiquidity += amounts;    
            }
            else {
                require(allocatedLiquidity + amounts <= getPrivateSaleLiquidity(), "PrivateSale: Amount is exceeding from max liquidity");
                packagesByAddress[privateInvestors] = 1;
                addressPlanDetails[privateInvestors][packagesByAddress[privateInvestors]].lockedTokens = amounts;
                addressPlanDetails[privateInvestors][packagesByAddress[privateInvestors]].lockTime = block.timestamp + lockInterval;
                lockedByAddress[privateInvestors] = amounts;
                allocatedLiquidity += amounts;
            }
    }

    function setLockedTokensAdmin(address[] memory privateInvestors, uint256[] memory amounts) public onlyOwner{
        require(privateInvestors.length == amounts.length, "PrivateSale: invalid arrays length");
        for(uint index=0; index<privateInvestors.length; index++){
            
            if(packagesByAddress[privateInvestors[index]] > 0){
                require(allocatedLiquidity + amounts[index] <= getPrivateSaleLiquidity(), "PrivateSale: Amount is exceeding from max liquidity");
                
                uint256 existingAmount = lockedByAddress[privateInvestors[index]];
                lockedByAddress[privateInvestors[index]] = existingAmount + amounts[index];

                packagesByAddress[privateInvestors[index]] = packagesByAddress[privateInvestors[index]] + 1;
                addressPlanDetails[privateInvestors[index]][packagesByAddress[privateInvestors[index]]].lockedTokens = amounts[index];
                addressPlanDetails[privateInvestors[index]][packagesByAddress[privateInvestors[index]]].lockTime = block.timestamp + lockInterval;
                
                allocatedLiquidity += amounts[index];
                emit TokensLocked(privateInvestors[index], amounts[index]);
            }
            else {
                require(allocatedLiquidity + amounts[index] <= getPrivateSaleLiquidity(), "PrivateSale: Amount is exceeding from max liquidity");
                packagesByAddress[privateInvestors[index]] = 1;
                addressPlanDetails[privateInvestors[index]][packagesByAddress[privateInvestors[index]]].lockedTokens = amounts[index];
                addressPlanDetails[privateInvestors[index]][packagesByAddress[privateInvestors[index]]].lockTime = block.timestamp + lockInterval;
                lockedByAddress[privateInvestors[index]] = amounts[index];
                allocatedLiquidity += amounts[index];
                emit TokensLocked(privateInvestors[index], amounts[index]);
            }

        }
    }

    function claim(uint256 planNumber) public {

        require(lockedByAddress[msg.sender] > 0 , "User does not belong to private investors");
        require(addressPlanDetails[msg.sender][planNumber].lockedTokens > 0 , "Plan already claimed");
        require(addressPlanDetails[msg.sender][planNumber].lockTime < block.timestamp, "Quantity is locked");

        uint256 amount = addressPlanDetails[msg.sender][planNumber].lockedTokens;
        require(getPrivateSaleLiquidity() >= amount, "Insufficient Amount to claim");
        addressPlanDetails[msg.sender][planNumber].lockedTokens = 0;
        addressPlanDetails[msg.sender][planNumber].lockTime = 0;

        lockedByAddress[msg.sender] = lockedByAddress[msg.sender] - amount;
        allocatedLiquidity -= amount;
        token.transferFrom(address(this), msg.sender, amount);

        emit ClaimedTokens(msg.sender, amount);
    }

    function withdrawLiquidity(uint256 amount) public onlyOwner {
        require(getPrivateSaleLiquidity() - allocatedLiquidity >= amount,"Insufficient Amount to withdraw" );
        token.transferFrom(address(this), adminWallet, amount);
    }

    function withdrawPayment(uint256 amount) public onlyOwner {
        require(payment.balanceOf(address(this)) >= amount,"Insufficient Amount to withdraw" );
        payment.transferFrom(address(this), adminWallet, amount);
        emit PaymentWithdrawal(adminWallet, amount);
    }

    function approve() public onlyOwner {
        token.approve(address(this), getPrivateSaleLiquidity());
    }

    function approvePayment() public onlyOwner {
        payment.approve(address(this), payment.balanceOf(address(this)));
    }

    function refund(address user, uint256 planNumber) public onlyOwner {
        require(addressPlanDetails[user][planNumber].lockedTokens > 0, "Plan already claimed");
        uint256 existingAmount = addressPlanDetails[user][planNumber].lockedTokens;
        
        addressPlanDetails[user][planNumber].lockedTokens = 0;
        addressPlanDetails[user][planNumber].lockTime = 0;

        lockedByAddress[user] = lockedByAddress[user] - existingAmount;
        allocatedLiquidity -= existingAmount;
    }
}