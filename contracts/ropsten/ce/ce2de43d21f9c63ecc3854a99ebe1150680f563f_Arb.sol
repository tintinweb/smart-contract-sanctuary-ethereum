/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Arb.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// import "hardhat/console.sol";


interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}

contract Arb is Ownable {

	function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
		IERC20(_tokenIn).approve(router, _amount);
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}

	 function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
		return amountOutMins[path.length -1];
	}
//  #make the same as the trade
	function estimateMultiDexTrade1(address[] memory _routers, address[] memory _tokens, uint256 _amount) external view returns (uint256) {

        uint tradeableAmount = _amount;
        for(uint256 i; i < _routers.length ; i++) {

            address token0 = _tokens[i];
            address token1 = _tokens[i+1];
            address router = _routers[i];

            tradeableAmount = getAmountOutMin(router, token0, token1, tradeableAmount);
        }

		return tradeableAmount;
	}
//to get even cheaper could eitehr send blank array item if router is the same as previous. might use same amound of data-likely
// could add addresses in nexted router array.
 function multiDexTrade2(address[] memory _routers, address[] memory _tokens, uint256 _amount, uint256 _fees) external onlyOwner {
      
    //   address[] routers=_routers;
    //   address[] tokens=_tokens;


      uint tradeableAmount = _amount;
      for(uint256 i; i < _routers.length; i++) {

        address router = _routers[i];
        address token0 = _tokens[i];

        address token1;
        if(i<_routers.length - 1)
        {
          token1 = _tokens[i+1];
        }
        else
        {
          token1 = _tokens[0];
        }

        // uint token1InitialBalance = IERC20(token1).balanceOf(address(this)); //Unless traiding the all tokens need to initial balance. coudl also send this as a variable.

        swap(router, token0, token1, tradeableAmount);

        uint token1Balance = IERC20(token1).balanceOf(address(this));
        tradeableAmount = token1Balance; //- token1InitialBalance;
      }
    require((tradeableAmount-_fees) > _amount, "Trade Reverted, No Profit Made");// by this point gas has already been spent (all?)  best try to recover as much as possible.
    // require((tradeableAmount+_fees)>0, "Trade Reverted, No Profit Made");
  }
  function multiDexTrade3(address[] memory _routers, address[] memory _tokens, uint256 _amount, uint256 _fees) external onlyOwner {
      
    //   address[] routers=_routers;
    //   address[] tokens=_tokens;


      uint tradeableAmount = _amount;
      for(uint256 i; i < _tokens.length; i++) {

        address router = _routers[i];
        address token0 = _tokens[i];

        address token1;
        if(i<_tokens.length - 1)
        {
          token1 = _tokens[i+1];
        }
        else
        {
          token1 = _tokens[0];
        }

        // uint token1InitialBalance = IERC20(token1).balanceOf(address(this)); //Unless traiding the all tokens need to initial balance. coudl also send this as a variable.

        swap(router, token0, token1, tradeableAmount);

        tradeableAmount = IERC20(token1).balanceOf(address(this));
        // tradeableAmount = token1Balance; //- token1InitialBalance;
      }
    // require((tradeableAmount-_fees) > _amount, "Trade Reverted, No Profit Made");// by this point gas has already been spent (all?)  best try to recover as much as possible.
    require(true, "Trade Reverted, No Profit Made");
  }

  function multiDexTrade4(address[] memory _routers, address[] memory _tokens, uint256 _amount, uint256 _fees) external onlyOwner {
      
    //   address[] routers=_routers;
    //   address[] tokens=_tokens;


      uint tradeableAmount = _amount;
      for(uint256 i; i < _tokens.length; i++) {

        address router;


        if(i<_routers.length)
        {
          router = _routers[i];
        }
        else
        {
          router = _routers[0];
        }

        address token0 = _tokens[i];

        address token1;
        if(i<_tokens.length - 1)
        {
          token1 = _tokens[i+1];
        }
        else
        {
          token1 = _tokens[0];
        }

        // uint token1InitialBalance = IERC20(token1).balanceOf(address(this)); //Unless traiding the all tokens need to initial balance. coudl also send this as a variable.

        swap(router, token0, token1, tradeableAmount);

        tradeableAmount = IERC20(token1).balanceOf(address(this));
        // tradeableAmount = token1Balance; //- token1InitialBalance;
      }
    // require((tradeableAmount-_fees) > _amount, "Trade Reverted, No Profit Made");// by this point gas has already been spent (all?)  best try to recover as much as possible.
    require(true, "Trade Reverted, No Profit Made");
  }


  //required?
	function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}
	
	function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

  // is it cheaper to do as much as possible through the router path. prob not?  who knows.  have to assum it takes the cheapers path. it will... Can I just target a token an use path to get the cheaperst path to buty and sell the token for coin.

	function recoverTokens(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

}