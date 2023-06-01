/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20Token {
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
    function transfer(address _to, uint256 _amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Deskillz is Ownable {
    address busdAddress;
    uint256 BUSDToLP;
    uint256 public AdminShare;
    constructor(address _busd, uint256 _BUSDToLP) {
        busdAddress = _busd;
        BUSDToLP = _BUSDToLP;
    }
    struct MatchScoreData {
        uint256 winningPrize;
        address player;
        uint256 developerPrize;
        address developer;
        uint256 matchFees;
        uint256 adminShare;
        address[] players;
    }
    using SafeMath for uint256;    mapping(address => uint256) developersBalances;
    mapping(address => uint256) playersBalances;
    
    function depositFunds(uint256 _amount) external payable {
        transferFromERC20(msg.sender, address(this), _amount, busdAddress);
        playersBalances[msg.sender] = _amount;
    }
    function withdrawPlayerFunds(uint256 _amount) external payable {
        uint256 playerBalance = playersBalances[msg.sender];
        require(playerBalance  >= _amount, "Insufficient balance");
        transferERC20(msg.sender, _amount, busdAddress);
        playersBalances[msg.sender] = playerBalance - _amount;
    }
    function withdrawDeveloperFunds(uint256 _amount) external payable {
        uint256 developerBalance = developersBalances[msg.sender];
        require(developerBalance  >= _amount, "Insufficient balance");
        transferERC20(msg.sender, _amount, busdAddress);
        developersBalances[msg.sender] = developerBalance - _amount;
    }
    function loyaltyPointsConversion(uint256 _amount) external {
        uint256 busd = calculateBUSD(_amount);
        uint256 playerBalance = playersBalances[msg.sender] + busd;
        playersBalances[msg.sender] = playerBalance;
    }
    function checkPlayerBalance (address player) view public returns(uint256) {
        return playersBalances[player];
    }
    function checkDeveloperBalance (address developer) view public returns(uint256) {
        return developersBalances[developer];
    }
    function calculatePercentValue(uint256 total, uint256 percent) pure private returns(uint256) {
        uint256 division = total.mul(percent);
        uint256 percentValue = division.div(100);
        return percentValue;
    }
    function updateMatchScores(MatchScoreData memory _matchScoreData) external {
        address[] memory players = _matchScoreData.players;
        for(uint8 i=0; i<players.length; i++) {
            uint256 playerIBalance = playersBalances[players[i]];
            playersBalances[players[i]] = playerIBalance - _matchScoreData.matchFees;
        }
        uint256 playerBalance = playersBalances[_matchScoreData.player];
        playersBalances[_matchScoreData.player] = playerBalance + _matchScoreData.winningPrize;

        uint256 developerBalance = developersBalances[_matchScoreData.developer];
        developersBalances[_matchScoreData.developer] = developerBalance + _matchScoreData.developerPrize;

        AdminShare = AdminShare + _matchScoreData.adminShare;
        // transferERC20(_matchScoreData.player, _matchScoreData.winningPrize, busdAddress);
        // transferERC20(_matchScoreData.developer, _matchScoreData.developerPrize, busdAddress);
    }
    fallback () payable external {}
    receive () payable external {}
    function transferFromERC20(address from, address to, uint256 amount, address tokenAddress) private {
        IERC20Token token = IERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        token.transferFrom(from, to, amount);
    }
    function transferERC20(address to, uint256 amount, address tokenAddress) private {
        IERC20Token token = IERC20Token(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "insufficient balance" );
        token.transfer(to, amount);
    }
    function withdrawBNB() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawBUSD() public onlyOwner {
        IERC20Token busd = IERC20Token(busdAddress);
        uint256 balance = busd.balanceOf(address(this));
        require(balance >= 0, "insufficient balance" );
        busd.transfer(owner(), balance);
    }
    function withdrawAdminShare() public onlyOwner {
        IERC20Token busd = IERC20Token(busdAddress);
        // uint256 balance = busd.balanceOf(address(this));
        // require(balance >= 0, "insufficient balance" );
        busd.transfer(owner(), AdminShare);
    }
    function updateLPToBUSD(uint256 _BUSDToLP) public onlyOwner {
        BUSDToLP = _BUSDToLP;
    }
    function calculateBUSD(uint256 lpValue) view public returns(uint256) {
        return lpValue.div(BUSDToLP);
    }
}