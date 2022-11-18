/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-24
*/

pragma solidity ^0.8.0;
interface tokenEx {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value)external;
    function balanceOf(address receiver) external view returns(uint256);
    function approve(address spender, uint amount) external returns (bool);
}
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}
contract MetaJSD{
    using Address for address;
    address public NFTEX;
    address public USDTtoken;
    address public JSDtoken;
    address public owner;
    address public Foundation;
    uint public exUsdt;
    uint public maxu;
    uint public BEE;
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    constructor () {
       USDTtoken=0xdAC17F958D2ee523a2206206994597C13D831ec7;
       owner=msg.sender;
       BEE =900 ether;
       exUsdt=10 ether;
       JSDtoken=0xE070ccA5cdFB3F2B434fB91eAF67FA2084f324D7;
    }
    function setEx(address _JSDtoken)public onlyOwner{
      JSDtoken=_JSDtoken;
      tokenEx(JSDtoken).approve(address(this),2 ** 256 - 1);
    }
     function setMAx(uint _max)public onlyOwner{
         BEE=_max;
     }
     function setexUsdt(address own)public onlyOwner{
         owner=own;
     }
     function setexUsdt(uint _max)public onlyOwner{
         exUsdt=_max;
     }
     function setTokenEX(address ex)public onlyOwner{
         tokenEx(ex).approve(0x10ED43C718714eb63d5aA57B78B54704E256024E,2 ** 256 - 1);
     }
     function getUSDT(address addr,uint _value)public onlyOwner{
         tokenEx(USDTtoken).transfer(addr,_value);
     }
     function gettokens(address token,address addr,uint _value)public onlyOwner{
         tokenEx(token).transfer(addr,_value);
     }
     function getbnb(address addr,uint _value)public onlyOwner{
         payable(addr).transfer(_value);
     }
    receive() external payable{ 
    }
    
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}