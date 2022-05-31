/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor(){
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Exchange is Ownable {
    // RUN token
	IERC20 public Rex;
    // THETHER token
	IERC20 public Tether;

	uint public rate = 150000000000000000 wei;

	event BuyToken(address receiver, address token, uint amount, uint rate);

	constructor(address _rex, address _tether) { 
		Rex = IERC20(_rex);
		Tether = IERC20(_tether);
	}

    modifier checkAllowance(uint amount) {
            require(Tether.allowance(msg.sender, address(this)) >= amount, "Error");
            _;
        }


    function setRate(uint _rate) external onlyOwner {
        rate = _rate;
    }

  function _calculateFinalPrice(uint tokensAmount) internal view returns (uint){
    uint eth = 1 ether;
    uint finalPrice;
        if(tokensAmount % rate == 0){
            finalPrice = tokensAmount*eth/rate*eth/eth;
        } else {
            finalPrice = (tokensAmount * eth/ rate *eth) / eth;
        }
        return finalPrice;
    }

	function buyToken(uint amount) external checkAllowance(amount) returns (uint){
        require(amount >= rate, "You cannot purchase less than one rex token");
        require(Tether.balanceOf(msg.sender) >= amount, "There are not enough tokens on your balance to exchange for rex token");
        uint tokensAmount = _calculateFinalPrice(amount); 
		require(Rex.balanceOf(address(this)) >= tokensAmount, "The exchange amount exceeds the balance of the exchange office");

        require(Tether.transferFrom(msg.sender, address(this),  amount), 'transfer tether toke has failed');
        Rex.approve(address(this), tokensAmount);
        Rex.transferFrom(address(this), msg.sender, tokensAmount);
		emit BuyToken(msg.sender, address(Rex), tokensAmount, rate);
        return amount;
	}

    function withdrawRex(address _recipient, uint amount) external onlyOwner {
        require (Tether.balanceOf(address(this)) <= amount);
        Rex.approve(address(this), amount);
        Rex.transferFrom(address(this), _recipient, amount);
    }

    function withdrawTether(address _recipient, uint amount) external onlyOwner {
      require (Tether.balanceOf(address(this)) <= amount);
      Tether.approve(address(this), amount);
      Tether.transferFrom(address(this), _recipient, amount);
    }

    function balances () public view onlyOwner returns(uint, uint){
      return(Rex.balanceOf(address(this)), Tether.balanceOf(address(this)));
    }

    function refundTokens(address _recipient, address _token) external onlyOwner {
      require(_token != address(Rex));
      IERC20 token = IERC20(_token);
      uint256 balance = token.balanceOf(address(this));
      require(balance > 0);
      require(token.transfer(_recipient, balance));
    }

    receive () external payable {
        revert("Exchange: You cannot send ether to the address of this contract!");
    }
}