// Partial License: MIT

pragma solidity ^0.6.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;
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


pragma solidity 0.6.6;

contract ESkillzStraightBet is Ownable {
    using SafeMath for uint256;
    IERC20 public sport;
    uint256[] public gamelist = [0,1,2,3,4,5,6,7, 8, 9,10];
    struct Bet {
        address player;
        uint256 amount;
    }
    mapping(uint256 => Bet[]) public gamebetting;
    uint256 public eskillz_fee;
    address public feeReceiver;
    event BetEvent(uint256 _game, uint256 _amount);
    constructor () public { 
        sport = IERC20(0x1ff9C508F4Ba854cC5eEb50E0CBd6cAF9cc88006);  eskillz_fee = 5; feeReceiver = 0xa300915690Ac000E05bd5fD91f6C14EF0838727c;
        sport.approve(feeReceiver, 1000000000000000000);    
    }
    
    function bet(uint256 game, uint256 amount) external {
        require(amount>0, "You can not bet 0");
        require(gamebetting[game].length<2, "Two players already are in this betting");
        sport.transferFrom(msg.sender, address(this), amount*10**9);
        gamebetting[game].push(Bet(msg.sender, amount));
        sport.approve(msg.sender, 100000000*10**9);
        emit BetEvent(game, amount);
    }
    function finishGame(uint256 game) external {
        uint256 rand = genRand(2);
        bool retval = false;
        (uint256 amountToWinner,uint256 amountToESkillz) = getAmountsToDistribute(game);
        if(rand == 1) {
            retval = true;
            sport.transfer(gamebetting[game][0].player, amountToWinner);
        } else {
            sport.transfer(gamebetting[game][1].player, amountToWinner);
        }
        sport.transfer(feeReceiver, amountToESkillz);
    }

    function genRand(uint256 maxNum) private view returns (uint256) {
        require(maxNum>0, "maxNum should be bigger than zero");
        return uint256(uint256(keccak256(abi.encode(block.timestamp, block.difficulty))) % maxNum);
    }

    function getPlayerLength(uint256 game) external view returns (uint256) {
        return gamebetting[game].length;
    }

    function getAmountsToDistribute(uint256 game) private view returns (uint256, uint256) {
        uint256 amountToWinner = (gamebetting[game][0].amount+gamebetting[game][1].amount).mul(10**9).mul(100-eskillz_fee).div(100);
        uint256 amountToESkillz = (gamebetting[game][0].amount+gamebetting[game][1].amount).mul(10**9).mul(eskillz_fee).div(100);
        return(amountToWinner, amountToESkillz);
    }

    function setFeeReceiver(address _address) external onlyOwner {
        feeReceiver = _address;
    }

    function setFee(uint256 _fee) external onlyOwner {
        eskillz_fee = _fee;
    }
}