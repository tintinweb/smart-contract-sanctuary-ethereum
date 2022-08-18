// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract P2PExchange is ReentrancyGuard {

    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 depositedTime;
    }

    mapping(address => mapping(address => UserInfo)) public users; // user address => token address => amount
    address public WETH;
    address[] public  tokenList;
    uint256 public fee;
    address owner;

    event Deposit(address indexed _from, address indexed _token, uint256 _amount);
    event Transfer(address indexed _from, address indexed _to, address indexed _token, uint256 _amount);

    event DepositETH(address indexed _from, uint256 _amount);
    event TransferETH(address indexed _from, address indexed _to, uint256 _amount);

    event Cancel(address indexed _token, address indexed _user,uint256 _amount);
    event Revoke(address indexed _token, address indexed _user);
    event CancelETH(address indexed _user,uint256 _amount);
    event RevokeETH(address indexed _user);

    constructor(address _WETH, uint256 _fee) {
        WETH = _WETH;
        fee = _fee;
        owner=msg.sender;
       
    }

   
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }


    //returns owner of the contract
    function getTokenAddress(uint256 _index) public view returns(address) {
        return tokenList[_index];
    }

    //returns owner of the contract
    function getOwner() public view returns(address) {
        return owner;
    }

    //returns balance of token inside the contract
    function getTokenBalance(address _token) public view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    //check whether token exists in polkabridge vault or not
    function existTokenInPool(address _token) public view returns(bool) {
        bool exist = IERC20(_token).balanceOf(address(this)) > 0 ? true : false;
        return exist;
    }

    // transfer token into polkabridge vault
    function depositToken(address _token, uint256 _amount) external {
        require(_token != address(0) && _amount > 0, "invalid token or amount");
        uint256 tokenBalanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint256 tokenBalanceAfter = IERC20(_token).balanceOf(address(this));
        uint256 tokenRealAmount = tokenBalanceAfter - tokenBalanceBefore;
        // UserInfo storage user = users[msg.sender][_token];
        users[msg.sender][_token].amount += tokenRealAmount.mul(100-fee).div(100);
        users[msg.sender][_token].depositedTime = block.timestamp;
        if (!existTokenInPool(_token))
            tokenList.push(_token);

        emit Deposit(msg.sender, _token, tokenRealAmount);
    }

    // transfer coin into polkabridge vault
    function depositETH() external payable {        
        users[msg.sender][WETH].amount += msg.value.mul(100-fee).div(100);
        users[msg.sender][WETH].depositedTime = block.timestamp;

        emit DepositETH(msg.sender, msg.value);
    }

    // transfer token to destination (user)
    function transferToken(address _seller,address _buyer, address _token, uint256 _amount) onlyOwner external nonReentrant {
        require(users[_seller][_token].amount >= _amount && _amount > 0, "Seller have insufficient funds in the pool.");
        uint256 tokenBalanceBefore = IERC20(_token).balanceOf(address(this));
        require(tokenBalanceBefore >= _amount && _amount > 0, "Insufficient funds in the pool.");

        IERC20(_token).transfer(_buyer, _amount);
        uint256 tokenBalanceAfter = IERC20(_token).balanceOf(address(this));
        uint256 tokenRealAmount = tokenBalanceBefore - tokenBalanceAfter;
        users[_seller][_token].amount -= tokenRealAmount;

        emit Transfer(address(this), _buyer, _token, tokenRealAmount);
    }


    // transfer coin to destination (user)
    function transferETH(address _seller,address _buyer,uint256 _amount) external onlyOwner nonReentrant {
        require(users[_seller][WETH].amount >= _amount && _amount > 0, "Seller have insufficient ETH in the pool.");
        users[_seller][WETH].amount -= _amount;
        payable(_buyer).transfer(_amount);        
        emit TransferETH(address(this), _buyer, _amount);
    } 

    // user can get his cancel transaction amount after deposit token, he 'll get 99%
    function cancelOrder(address _token,address _user,uint256 _amount) onlyOwner external nonReentrant {
        require(_token != address(0), "invalid token or amount");
        require(users[_user][_token].amount >= _amount && _amount > 0, "amount exceeds or zero");

        uint256 toTransfer = _amount.mul(100-fee).div(100);
        users[_user][_token].amount -= _amount;
        IERC20(_token).transfer(_user, toTransfer);        

        emit Cancel(_token, _user,_amount);
    }

 // user cancel transaction after deposit coin, he 'll get 99%
    function cancelETHOrder(address _user,uint256 _amount) onlyOwner external nonReentrant {
        require(users[_user][WETH].amount >= _amount && _amount > 0, "eth amount exceeds or zero");
        uint256 toTransfer = _amount.mul(100-fee).div(100);
        users[_user][WETH].amount -= _amount;
        payable(_user).transfer(toTransfer);

        emit CancelETH(_user,_amount);
    }

    // user can withdraw all his funds after deposit token, he 'll get 99%
    function revokeToken(address _token,address _user) onlyOwner external nonReentrant {
        require(_token != address(0), "invalid token or amount");
        uint256 amount = users[_user][_token].amount;
        uint256 toTransfer = amount.mul(100-fee).div(100);
        users[_user][_token].amount -= toTransfer;
        IERC20(_token).transfer(_user, toTransfer);        

        emit Revoke(_token, _user);
    }

    // user cancel transaction after deposit coin, he 'll get 99%
    function revokeETH(address _user) onlyOwner external nonReentrant {
        uint256 amount = users[_user][WETH].amount;
        uint256 toTransfer = amount.mul(100-fee).div(100);
        users[_user][WETH].amount -= toTransfer;
        payable(_user).transfer(toTransfer);

        emit RevokeETH(_user);
    }

   
   

    // given user address and token, return deposit time and deposited amount
    function getUserInfo(address _user, address _token) external view returns (uint256 _depositedTime, uint256 _amount) {
        _depositedTime = users[_user][_token].depositedTime;
        _amount = users[_user][_token].amount;
    }

    function getUserEthInfo(address _user) external view returns (uint256 _depositedTime, uint256 _amount) {
        _depositedTime = users[_user][WETH].depositedTime;
        _amount = users[_user][WETH].amount;
    }

    // return eth balance in reserve
    function getEthInReserve() external view returns ( uint256 _amount) {
        return address(this).balance;
    }

    // withdraw token
    function withdrawToken(address _token) external onlyOwner nonReentrant {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "not enough amount");
        IERC20(_token).transfer(msg.sender, balance);
    }

    // withdraw ETH
    function withdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough amount");
        payable(msg.sender).transfer(balance);
    }

    // withdraw all
    function withdrawAll() external onlyOwner {
        //withdraw all tokens
        for(uint256 i=0; i<tokenList.length; i++)
        {
            uint256 balance = IERC20(tokenList[i]).balanceOf(address(this));
            if(balance > 0)
                IERC20(tokenList[i]).transfer(msg.sender, balance);
        }
        //withdraw ETH
        payable(msg.sender).transfer(address(this).balance);
    }

}