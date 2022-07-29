/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity ^0.8.14;

// -- interface -- //
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface ILiquidity {
    function borrow(address _token, uint256 _amount, bytes calldata _data) external;
}

// -- library -- //
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract SimpleArbi {
    using SafeMath for uint256;

    struct RepayData {
        address repay_token;
        uint256 repay_amount;
    }


    address owner;
    address liquidityPool = 0x4F868C1aa37fCf307ab38D215382e88FCA6275E2;
    address borrowerProxy = 0x17a4C8F43cB407dD21f9885c5289E66E21bEcD9D;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // constructor
    constructor ()  {
        //address wc =  0xC02aaA39b223FE8D0A0e584F27eAD9083C756Cc2;
        owner = address(tx.origin);
    }
    

    // modifier
    modifier onlyOwner(){
        require(address(msg.sender) == owner, "No authority");
        _;
    }

    // fallback
    receive() external payable {}

    // get
    function getOwner() public view returns(address) {
        return owner;
    }

    function getTokenBalance(address token, address account) public view returns(uint256) {
        return IERC20(token).balanceOf(account);
    }

    // set
    function turnOutETH(uint256 amount) public onlyOwner {
        payable(owner).transfer(amount);
    }

    function turnOutToken(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
    
    function WETHToETH(uint256 amount) public onlyOwner {
        IWETH(WETH).withdraw(amount);
    }

    function ETHtoWETH(uint256 amount) public onlyOwner {
        IWETH(WETH).deposit{value:amount}();
    }

    // flashloan
    function flashLoan(address token, uint256 amount) public onlyOwner {
        RepayData memory _repay_data = RepayData(token, amount);
        ILiquidity(liquidityPool).borrow(token, amount,
            abi.encodeWithSelector(this.receiveLoan.selector, abi.encode(_repay_data)));
    }

    // callback
    function receiveLoan(bytes memory data) public {
        require(msg.sender == borrowerProxy, "Not borrower");
        RepayData memory _repay_data = abi.decode(data, (RepayData));
        IERC20(_repay_data.repay_token).transfer(liquidityPool, _repay_data.repay_amount);
    }
    
}