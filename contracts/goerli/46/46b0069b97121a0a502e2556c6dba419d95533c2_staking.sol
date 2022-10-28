/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
/*
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
    constructor(address newOwner) {
        _setOwner(newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}


contract staking is Ownable {
    using SafeMath for uint256;

    address public treasury;

    uint256 private divider=10000;

    uint256 public depoiteTax=0;

    uint256 public withdrawTax=0;

    uint256 public rewardPercentage=150;

    bool public hasStart=true;

    uint256 public totalInvestedToken;

    uint256 public totalWithdrawToken;

    IERC20 public token;
    struct depoite{
        uint256 amount;
        uint256 depositeTime;
        uint256 checkPointToken;
    }

    struct user {
        depoite[] deposites;
        uint256 totalRewardWithdrawToken;
        uint256 checkToken;
        uint256 withdrawCheckToken;
    }

    mapping (address=>user) public investor;

	event NewDeposit(address indexed user, uint256 amount);
    event Compund(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardWithdraw(address indexed user,uint256 amount);
    constructor() Ownable(0x2cdA25C0657d7622E6301bd93B7EC870a56fE500){
        treasury=0x2cdA25C0657d7622E6301bd93B7EC870a56fE500;
        token=  IERC20(0xa0F8BFC19E1E9Ed1dC31BfcD5F4832f1c6eC6A17);
    }
    function toggleSale(bool _sale) public  onlyOwner{
        hasStart=_sale;
    }
   
    function setWallet( address _treasury) public  onlyOwner{
        treasury=_treasury;
    }

    function setTax(uint256 _depoiteTax,uint256 _withdrawTax) public  onlyOwner{
        depoiteTax=_depoiteTax;
        withdrawTax=_withdrawTax;
    }

    function setRewardPercentage(uint256 _rewardPercentage) public  onlyOwner{
        rewardPercentage=_rewardPercentage;        
    }

    function invest(uint256 amount) public payable {
        require(hasStart,"Sale is not satrted yet");
        user storage users =investor[msg.sender];
        
        require(amount<=token.allowance(msg.sender, address(this)),"Insufficient Allowence to the contract");
        uint256 tax=amount.mul(depoiteTax).div(divider);
        
        token.transferFrom(msg.sender, treasury, tax);
        token.transferFrom(msg.sender, address(this), amount.sub(tax));
        users.deposites.push(depoite(amount.sub(tax), block.timestamp,block.timestamp));
        totalInvestedToken=totalInvestedToken.add(amount.sub(tax));
        users.checkToken=block.timestamp;
        emit NewDeposit(msg.sender, amount);
    }
    
    function compund() public payable {
        require(hasStart,"Sale is not satrted yet");
        user storage users =investor[msg.sender];
        
            (uint256 amount)=calclulateReward(msg.sender);
           
            require(amount>0,"Compund Amount very low");
            users.deposites.push(depoite(amount, block.timestamp,block.timestamp));
            totalInvestedToken=totalInvestedToken.add(amount);
            emit Compund(msg.sender, amount);
                for(uint256 i=0;i<investor[msg.sender].deposites.length;i++){
                investor[msg.sender].deposites[i].checkPointToken=block.timestamp;
        }
            users.withdrawCheckToken=block.timestamp;
             users.checkToken=block.timestamp;
        
        
    }
   
    function withdrawTokens()public {
        require(hasStart,"Sale is not Started yet");
        uint256 totalDeposite=getUserTotalDepositeToken(msg.sender);
        require(totalDeposite>0,"No Deposite Found");
        require(totalDeposite<=getContractTokenBalacne(),"Not Enough Token for withdrwal from contract please try after some time");
        uint256 tax=totalDeposite.mul(withdrawTax).div(divider);
        token.transfer(treasury, tax);
        token.transfer(msg.sender, totalDeposite.sub(tax));
        investor[msg.sender].checkToken=block.timestamp;
        investor[msg.sender].withdrawCheckToken=block.timestamp;
        
        emit Withdrawn(msg.sender, totalDeposite);
    }
    
    function withdrawRewardToken()public {
        require(hasStart,"Sale is not Started yet");
        (uint256 totalRewards)=calclulateReward(msg.sender);
        require(totalRewards>0,"No Rewards Found");
        require(totalRewards<=getContractTokenBalacne(),"Not Enough Token for withdrwal from contract please try after some time");
        uint256 taxR=totalRewards.mul(withdrawTax).div(divider);
        token.transfer(msg.sender, totalRewards.sub(taxR));

        for(uint256 i=0;i<investor[msg.sender].deposites.length;i++){
            investor[msg.sender].deposites[i].checkPointToken=block.timestamp; 
        }
        investor[msg.sender].totalRewardWithdrawToken+=totalRewards;
        investor[msg.sender].checkToken=block.timestamp;
        totalWithdrawToken+=totalRewards;
        emit RewardWithdraw(msg.sender, totalRewards);
    }
    
    function calclulateReward(address _user) public view returns(uint256){
        uint256 totalRewardToken;
        user storage users=investor[_user];
        for(uint256 i=0;i<users.deposites.length;i++){
            uint256 depositeAmount=users.deposites[i].amount;
            uint256 time = block.timestamp.sub(users.deposites[i].checkPointToken);
            totalRewardToken += depositeAmount.mul(rewardPercentage).div(divider).mul(time).div(1 days);            
        }
        return(totalRewardToken);
    }

    function getUserTotalDepositeToken(address _user) public view returns(uint256 _totalInvestment){
        for(uint256 i=0;i<investor[_user].deposites.length;i++){
             _totalInvestment=_totalInvestment.add(investor[_user].deposites[i].amount);
        }
    }
    
    function getUserTotalRewardWithdrawToken(address _user) public view returns(uint256 _totalWithdraw){
        _totalWithdraw=investor[_user].totalRewardWithdrawToken;
    }
    

    function getContractTokenBalacne() public view returns(uint256 totalToken){
        totalToken=token.balanceOf(address(this));
    }

    function getContractBNBBalacne() public view returns(uint256 totalBNB){
        totalBNB=address(this).balance;
    }
     function withdrawlTokens(uint256 amount) public onlyOwner{
        require(token.balanceOf(address(this))>= amount,"Contract balance is low");
        token.transfer(msg.sender,amount);
    }
    function withdrawlBNB() public payable onlyOwner{
        payable(owner()).transfer(getContractBNBBalacne());
    }
    function getUserDepositeHistoryToken( address _user) public view  returns(uint256[] memory,uint256[] memory){
        uint256[] memory amount = new uint256[](investor[_user].deposites.length);
        uint256[] memory time = new uint256[](investor[_user].deposites.length);
        for(uint256 i=0;i<investor[_user].deposites.length;i++){
                amount[i]=investor[_user].deposites[i].amount;
                time[i]=investor[_user].deposites[i].depositeTime;
        }
        return(amount,time);
    }
    receive() external payable {
      
    }
     
}