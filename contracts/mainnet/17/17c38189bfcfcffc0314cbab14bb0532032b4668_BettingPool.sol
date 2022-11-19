/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity ^0.8.17;

abstract contract Context{
    function _msgSender() internal view virtual returns (address){
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address){
        return _owner;
    }

    modifier onlyOwner(){
        require(_owner == _msgSender(), "Ownerable: caller is not owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner{
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
	
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	event TransferDetails(address indexed from, address indexed to, uint256 total_Amount, uint256 reflected_amount, uint256 total_TransferAmount, uint256 reflected_TransferAmount);
}

contract BettingPool is Context, Ownable{

    using SafeMath for uint256;

    struct Bet {
        uint256 betAmount;
        uint8 betCountry;
    }

    mapping(address => Bet) public _betInfo;
    mapping(uint8 => uint256) public _poolAmount;

    uint256 private constant MAX = ~uint256(0);

    IERC20 private stadium;

    bool private bettingStart;
    bool private drawMode = false;
    bool private isGameStart = false; 

    uint256 private bettingAmountTotal; 
    uint8 private worldChampion = 0;

    address payable private _deploymentWallet;

    constructor() {
        stadium = IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
        _deploymentWallet = payable(_msgSender());
    }

    function PlaceBet(uint256 amount,uint8 country) external {
        require(amount > 0 && country > 0);
        require(stadium.balanceOf(_msgSender()) >= amount && stadium.allowance(_msgSender(), address(this)) >= amount);
        require(isGameStart);
        if(_betInfo[_msgSender()].betCountry == 0){
        _betInfo[_msgSender()].betAmount = amount;
        _betInfo[_msgSender()].betCountry = country;
        _poolAmount[country] = _poolAmount[country].add(amount);
        }
        else{
            require(_betInfo[_msgSender()].betCountry == country);
            _poolAmount[country] = _poolAmount[country].add(amount);
            _betInfo[_msgSender()].betAmount = _betInfo[_msgSender()].betAmount.add(amount);
        }
        stadium.transferFrom(_msgSender(),address(this), amount);
    }

    function checkContractBalance() public view returns(uint256){
        return stadium.balanceOf(address(this));
    }

    function setGameStart(bool onoff) external {
        require(_msgSender() == _deploymentWallet);
        isGameStart = onoff;
    }

    function setDrawMode(bool onoff) external {
        require(_msgSender() == _deploymentWallet);
        drawMode = onoff;
    }

    function setWorldChampion(uint8 country) external {
        require(_msgSender() == _deploymentWallet);
        require(!isGameStart);
        bettingAmountTotal = stadium.balanceOf(address(this));
        worldChampion = country;
    }
 
    function claim() external {

        require(!isGameStart);
        require(worldChampion>0);

        if(_betInfo[_msgSender()].betCountry == worldChampion){
            uint256 winAmount = bettingAmountTotal.mul(_betInfo[_msgSender()].betAmount).div(_poolAmount[worldChampion]);
            stadium.transfer(_msgSender(), winAmount);
            _betInfo[_msgSender()].betAmount = 0;
            _betInfo[_msgSender()].betCountry = 0;
        }
    }


    function claimEst(uint256 amount, uint8 country) external view returns(uint256){
        if(bettingAmountTotal >0){
            return bettingAmountTotal.mul(amount).div(_poolAmount[country]);
        }
        return bettingAmountTotal.mul(amount).div(_poolAmount[country]);
    }

    function backupClaim() external {
        require(drawMode);
        require(_betInfo[_msgSender()].betAmount > 0);
        stadium.transfer(_msgSender(), _betInfo[_msgSender()].betAmount);
        _betInfo[_msgSender()].betAmount = 0;
        _betInfo[_msgSender()].betCountry = 0;
    }

    function clearStuckBalance(uint256 amountPercentage) external {
        require(_msgSender() == _deploymentWallet);
		uint256 amountToClear = amountPercentage * address(this).balance / 100;
		payable(msg.sender).transfer(amountToClear);
	}

	function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
		if(tokens == 0){
			tokens = IERC20(tokenAddress).balanceOf(address(this));
		}
		return IERC20(tokenAddress).transfer(msg.sender, tokens);
	}

    function managePoolInfo(uint8 country, uint256 poolBalance) external onlyOwner(){
        _poolAmount[country] = poolBalance;
    }

    function manageUserInfo(address user, uint8 country, uint256 betAmount) external onlyOwner(){
        _betInfo[user].betCountry = country;
        _betInfo[user].betAmount = betAmount;

    }

}