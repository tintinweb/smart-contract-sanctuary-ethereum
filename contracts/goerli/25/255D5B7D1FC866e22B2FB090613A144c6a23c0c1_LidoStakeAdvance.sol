// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.4.24;

import {  ILido,IWETH10, IERC20 } from "./Interfaces.sol";
import { IUniswapV2Router02 } from "./UniswapInterfaces.sol";
import "./Ownable.sol";


contract LidoStakeAdvance is Ownable {
    event Received(address, uint);

    event SwapDone( string data, uint[] finalOutput);

    // event logU( string data, uint val);

    // event logA( string data, address val);

    //For uniswap
    // IUniswapV3Pool pool;
    IWETH10 weth;
    ILido public lido;
    IUniswapV2Router02 public uniSwapRouter;

    address WETH;
    //0.5% = 200 (forumula is 100/x%)
    //1% = 100
    

    
    
    // intantiate lending pool addresses provider and get lending pool address
    constructor( ILido _lido,  address _weth, IUniswapV2Router02 _uniswapRouter) public {
        lido = ILido(_lido);
        WETH = _weth;
        uniSwapRouter = IUniswapV2Router02(_uniswapRouter);
        weth = IWETH10(WETH);
        
    }

    function SNS( ) public payable {
        
        for(uint i=0; i<5; i++){
            //Send from this contract to Lido Contract
            lido.submit.value(msg.value);
            // the various assets to be flashed
            address[] memory paths = new address[](2);
            paths[0] = address(lido); // stETH
            paths[1] = WETH; // WETH

            IERC20 tokenContract = IERC20(address(paths[0]));
            uint256 stEthBalance = tokenContract.balanceOf(address(this));
            uint256 finalAmt = SUni(stEthBalance, paths, address(this));
            weth.withdraw(finalAmt);
        }
        
    }
    function singleSNS( ) public payable {
        //Send from this contract to Lido Contract
        lido.submit.value(msg.value);
        // the various assets to be flashed
        address[] memory paths = new address[](2);
        paths[0] = address(lido); // stETH
        paths[1] = WETH; // WETH

        IERC20 tokenContract = IERC20(address(paths[0]));
        uint256 stEthBalance = tokenContract.balanceOf(address(this));
        uint256 finalAmt = SUni(stEthBalance, paths, address(this));
        weth.withdraw(finalAmt);
    }

    function singleSNSWithDelegate( ) public payable {
        //Send from this contract to Lido Contract
        (bool success) =  address(lido).call.value(msg.value)(bytes4(keccak256("submit(address)")),address(msg.sender));
        if (!success) {
            revert();
        }
        // the various assets to be flashed
        address[] memory paths = new address[](2);
        paths[0] = address(lido); // stETH
        paths[1] = WETH; // WETH

        IERC20 tokenContract = IERC20(address(paths[0]));
        // tokenContract.approve(address(this),1000000000000000000000000);

        uint256 stEthBalance = tokenContract.balanceOf(address(msg.sender));
        // uint256 stEthBalanceContract = tokenContract.balanceOf(address(this));
        SUniDelegate(stEthBalance, paths);

        // weth.withdraw(finalAmt);
        
    }



    function SO( ) public payable  {
        //Send from this contract to Lido Contract
        lido.submit.value(msg.value);
        
    }
    function SAS() public payable returns (uint256){
        //Send from this contract to Lido Contract
        lido.submit.value(msg.value);
        // the various assets to be flashed
        address[] memory paths = new address[](2);
        paths[0] = address(lido); // stETH
        paths[1] = WETH; // WETH

        IERC20 tokenContract = IERC20(address(paths[0]));
        uint256 stEthBalance = tokenContract.balanceOf(address(this));
        return stEthBalance;
    }

    function SUni( uint amount, address[] memory paths, address recipient) public  returns  (uint256 finalAmount){
        require (recipient == address(this) || recipient == owner(),"owner only");
        IERC20 tokenContract = IERC20(address(paths[0]));
        // tokenContract.transferFrom( recipient, address(this), amount);
        tokenContract.approve(address(uniSwapRouter),amount);
        uint[] memory output = uniSwapRouter.swapExactTokensForTokens(amount,0, paths,recipient, block.timestamp+4);
        finalAmount = output[output.length-1];
        emit SwapDone("Done", output);
        return finalAmount;
    }
    function SUniDelegate( uint amount, address[] memory paths) public  {
        // require (recipient == address(this) || recipient == owner(),"owner only");
        IERC20 tokenContract = IERC20(address(paths[0]));
        // tokenContract.transferFrom( recipient, address(this), amount);
        tokenContract.approve(address(uniSwapRouter),amount);
        if (!address(uniSwapRouter).delegatecall(bytes4(keccak256("swapExactTokensForTokens(uint,uint,address[],address,uint)")),msg.sender)) revert();
        // uint[] memory output = uniSwapRouter.swapExactTokensForTokens(amount,0, paths,recipient, block.timestamp+4);
        // finalAmount = output[output.length-1];
        // emit SwapDone("Done", output);
        // return finalAmount;
    }
    
    function receive() external payable {
        emit Received(msg.sender, msg.value);
    }

     /*
    * Rugpull all ERC20 tokens from the contract
    */
    function rugPull(address[] addresses) public payable onlyOwner {
        
        
        // withdraw all ETH
        // msg.sender.call{ value: address(this).balance }("");
        bool success = address(owner()).call.value(msg.value)("");
        require(success, "Transfer failed.");
        // address(msg.sender).value(address(this).balance).call(address(this).balance)("");
        // address(msg.sender).transfer(address(this).balance);
        for (uint8 i = 0; i<addresses.length; i++){
            IERC20(addresses[i]).transfer(owner(), IERC20(addresses[i]).balanceOf(address(this)));
        }
        // withdraw all x ERC20 tokens
        // IERC20(kovanEnj).transfer(msg.sender, IERC20(kovanEnj).balanceOf(address(this)));
        // IERC20(kovanDai).transfer(msg.sender, IERC20(kovanDai).balanceOf(address(this)));
        // IERC20(kovanLINK).transfer(msg.sender, IERC20(kovanLINK).balanceOf(address(this)));
        // IERC20(kovanCOMP).transfer(msg.sender, IERC20(kovanCOMP).balanceOf(address(this)));
        // IERC20(kovanWETH).transfer(msg.sender, IERC20(kovanWETH).balanceOf(address(this)));
        
        // IERC20(kovanKyber).transfer(msg.sender, IERC20(kovanKyber).balanceOf(address(this)));
    }
   
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.24;


interface ILido {
    // User functions

    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256 StETH);

    
}




interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWETH10  {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to,  bytes  data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes  data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), 
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes  data) external returns (bool);
}

pragma solidity ^0.4.24;


interface IUniswapV2Router02 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.4.24;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
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