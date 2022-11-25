// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {  ILido, IWETH9, IERC20 } from "./Interfaces.sol";
import { IUniswapV2Router02 } from "./UniswapInterfaces.sol";
import "./Ownable.sol";


contract LidoStakeAdvance is Ownable {
    // event Received(address, uint);

    // event SwapDone( string data, uint[] finalOutput);

    // event logU( string data, uint val);

    // event logA( string data, address val);

    //For uniswap
    // IUniswapV3Pool pool;
    IWETH9 weth;
    ILido lido;
    IUniswapV2Router02 uniswapRouter;

    // address WETH;
    // address lido;
    // address uniswapRouter;
    //0.5% = 200 (forumula is 100/x%)
    //1% = 100
    

    
    
    // intantiate lending pool addresses provider and get lending pool address
    constructor( ILido _lido,  IWETH9 _weth, IUniswapV2Router02 _uniswapRouter) {
        weth = _weth;
        lido = _lido;
        uniswapRouter = _uniswapRouter;
    }

    
    function SO() public payable  {
        //Send from this contract to Lido Contract
        lido.submit{value: address(this).balance}(address(this));
    }

    function SAS() public payable returns (uint256){
        //Send from this contract to Lido Contract
        SO();
        // the various assets to be flashed
        // the various assets to be flashed
        address[] memory paths = new address[](2);
        paths[0] = address(lido); // stETH
        paths[1] = address(weth); // WETH
        uint256 finalAmt = SUni(IERC20(address(paths[0])).balanceOf(address(this)), paths, address(this));
        return finalAmt;
    }

    function unwrap() public payable  {
        weth.withdraw( IERC20(address(weth)).balanceOf(address(this)));
    }

    function SNS( uint max  ) public payable {
        for(uint i=0; i<max; i++){
            singleSNS();
        }
    }

    function singleSNS() public payable {
        SAS();
        unwrap();
    }


    
    function SUni( uint amount, address[] memory paths, address recipient) public  returns  (uint256 finalAmount){
        require (recipient == address(this) || recipient == owner(),"owner only");
        IERC20 tokenContract = IERC20(address(paths[0]));
        // tokenContract.transferFrom( recipient, address(this), amount);
        tokenContract.approve(address(uniswapRouter),amount);
        uint[] memory output = uniswapRouter.swapExactTokensForTokens(amount,0, paths,recipient, block.timestamp+2);
        finalAmount = output[output.length-1];
        // emit SwapDone("Done", output);
        return finalAmount;
    }
    // function SUniDelegate( uint amount, address[] memory paths) public  {
    //     // require (recipient == address(this) || recipient == owner(),"owner only");
    //     IERC20 tokenContract = IERC20(address(paths[0]));
    //     // tokenContract.transferFrom( recipient, address(this), amount);
    //     tokenContract.approve(address(uniSwapRouter),amount);
    //     if (!address(uniSwapRouter).delegatecall(bytes4(keccak256("swapExactTokensForTokens(uint,uint,address[],address,uint)")),msg.sender)) revert();
    //     // uint[] memory output = uniSwapRouter.swapExactTokensForTokens(amount,0, paths,recipient, block.timestamp+4);
    //     // finalAmount = output[output.length-1];
    //     // emit SwapDone("Done", output);
    //     // return finalAmount;
    // }
    
    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }
    // function() public payable { }

     /*
    * Rugpull all ERC20 tokens from the contract
    */
    function rugPull(address[] calldata addresses) public payable onlyOwner {
        
        // withdraw all ETH
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        if (!success) {
            revert();
        }
        // address(msg.sender).transfer(address(this).balance);
        for (uint8 i = 0; i<addresses.length; i++){
            IERC20(addresses[i]).transfer(owner(), IERC20(addresses[i]).balanceOf(address(this)));
        }
    }
   
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;

interface ILido {
    // User functions

    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256);

}


interface IERC20 {
  

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

  
}

interface IWETH9  {

   
    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;


interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;
pragma abicoder v2;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}