/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: none

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface CULTBurn {
    function burn(uint256 amount) external;
}


contract DistributorContract is Context, Ownable {
    using SafeMath for uint256;
 
    address public OppcultureContract = 0x3cdFC8dE85c094cA8d292feE269919E407ecDc1a;
    address public EquityContract = 0x14895D191C8c2BdE4c488BE84fdAe95339eabfa1;

    address[] public equityHolders;

    address payable public OppcultureTreasury;
    address payable public InvestmentTreasury;
    address payable public ScrapTreasury;
    uint256 public OppculturePercent = 60;
    uint256 public InvestmentPercent = 20;
    uint256 public ScrapPercent = 20;
 
    function SetOppcultureContract(address adr) public onlyOwner {
        OppcultureContract = adr;
    }
    function SetEquityContract(address adr) public onlyOwner {
        EquityContract = adr;
    }

    function SetWallets(address payable oppcultureTreasury, address payable investmentTreasury, address payable scrapTreasury) public onlyOwner {
        OppcultureTreasury = oppcultureTreasury;
        InvestmentTreasury = investmentTreasury;
        ScrapTreasury = scrapTreasury;
    }

    function SetDistribution(uint256 oppculturePercent, uint256 investmentPercent, uint256 scrapPercent) public onlyOwner {
        require(oppculturePercent.add(investmentPercent).add(scrapPercent) == 100, "Must be equal to 100%");

        OppculturePercent = oppculturePercent;
        InvestmentPercent = investmentPercent;
        ScrapPercent = scrapPercent;
    }

    function SetEquityHolders(address[] memory adrs) public onlyOwner {
        equityHolders = adrs;
    }

    function withdrawCULT(uint256 percent) public onlyOwner {
        uint256 amount = (IERC20(OppcultureContract).balanceOf(address(this)).mul(percent)).div(100);

        IERC20(OppcultureContract).transfer(OppcultureTreasury, (amount.mul(90)).div(100) );
    }
    function withdrawCULTtoEquityHolders(uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < equityHolders.length; i++) {
            IERC20(OppcultureContract).transfer(equityHolders[i], amount.mul( IERC20(EquityContract).balanceOf(equityHolders[i]) ).div(100 * 10**uint256(18)) );
        }
    }
    
    function burn(uint256 amount) public onlyOwner {
        CULTBurn(OppcultureContract).burn(amount);
    }

    function withdrawETH(uint256 percent) public onlyOwner {
        uint256 amount = address(this).balance.mul(percent).div(100);

        OppcultureTreasury.transfer(amount.mul(OppculturePercent).div(100));
        InvestmentTreasury.transfer(amount.mul(InvestmentPercent).div(100));
        ScrapTreasury.transfer(amount.mul(ScrapPercent).div(100));
    }

    receive() external payable {}
}