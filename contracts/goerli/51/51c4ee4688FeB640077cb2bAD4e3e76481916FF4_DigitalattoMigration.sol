/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
            // Gas optimization: this is cheaper than requiring "a" not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract DigitalattoMigration{
    using SafeMath for uint256;

    struct UserInfo {
        bool isWL;
        uint256 amount;
        uint256 migrationedAmount;
    }
    
    IBEP20 public OLDTOKEN = IBEP20(0xEc328682a5192c6b8DeC40D13eDDc582DAd128D0);
    IBEP20 public NEWTOKEN = IBEP20(0x0a96EE8b3D59AeA26b4cC31342747e176e711FDd);
    // IBEP20 public OLDTOKEN = IBEP20(0xB469F7cfD0E5921372A7D6310F661D08DEee075C); // Test
    // IBEP20 public NEWTOKEN = IBEP20(0x0023E41964290Dc6B5e49E269fbEb1eC44539865); // Test
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public marketingWallet = 0x4a94ee3A28bc64C6c012E1d53d49dcFcAC80E198;
    address public owner;
    uint256 public swapFee = 0.005 ether; // BNB

    bool public swapEnabled;
    uint256 public limitAmount;
    uint256 public topAmount;
    uint256 public newRatio;
    uint256 public oldRatio;
    uint256 public migrationFee;
    mapping (address => UserInfo) public userinfo;

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor ()  {	
        owner = msg.sender;	
    }

    function migrate(uint256 _amount) external payable {    
        require(swapEnabled, "paused");
        require(_amount < topAmount, "paused");    
        UserInfo storage user = userinfo[msg.sender];
        require(user.migrationedAmount  + _amount <= limitAmount, "paused");
        user.migrationedAmount += _amount;
        require(user.isWL, "not whitelisted");
        require(user.amount >= _amount, "insufficient allowed amount");
        if(swapFee > 0) {
            require(msg.value >= swapFee , "not enough swapFee");
        }
        require(_amount >= topAmount, "exceed the top migration amount");

        user.amount -= _amount;

        if(user.amount == 0) {
            user.isWL = false;
        }
        payable(marketingWallet).transfer(address(this).balance);
        uint256 newtokenAmount = _amount.mul(oldRatio).mul(10 ** NEWTOKEN.decimals()).div(newRatio).div(10 ** OLDTOKEN.decimals());
        require(NEWTOKEN.balanceOf(address(this)) >= newtokenAmount, "insufficient contract balance");
        OLDTOKEN.transferFrom(msg.sender, BURN_ADDRESS, _amount);
        NEWTOKEN.transfer(msg.sender, newtokenAmount);        
    }

    function setWhiteList(address[] memory _accounts, uint256[] memory _amounts, bool _value) public onlyOwner {
      for(uint256 i = 0; i < _accounts.length; i++) {
            UserInfo storage user = userinfo[_accounts[i]];
            user.amount = _amounts[i];
            user.isWL = _value;
        }
    }

    function setSwapFee(uint256 _swapFee) external onlyOwner{
        swapFee = _swapFee;
    }

    function setMigrationFee(uint256 _migrationpFee) external onlyOwner{
        migrationFee = _migrationpFee;
    }

    function setNewRatio(uint256 _ratio) external onlyOwner{
        newRatio = _ratio;
    }

    function setOldRatio(uint256 _ratio) external onlyOwner{
        oldRatio = _ratio;
    }

    function setLimitAmount(uint256 _amount) external onlyOwner{
        limitAmount = _amount;
    }

    function setTopAmount(uint256 _amount) external onlyOwner{
        topAmount = _amount;
    }

    function toggleSwap() external onlyOwner{
        swapEnabled = !swapEnabled;
    }

    function setMarketingWallet(address _account) external onlyOwner{
        require(_account != address(0), "wrong");
        marketingWallet = _account;
    }
    
    function setTokens(address _oldtoken, address _newtoken) external onlyOwner{
        require(_oldtoken != address(0), "wrong");
        require(_newtoken != address(0), "wrong");
        OLDTOKEN = IBEP20(_oldtoken);
        NEWTOKEN = IBEP20(_newtoken);
    }

    function transferOwnerShip(address _owner) external onlyOwner{
        owner = _owner;
    }

    function getTokensBack(address _token, address payable _to) external onlyOwner {
        if(_token == address(0)){
            _to.transfer(address(this).balance);
        } else {
            IBEP20(_token).transfer(_to, IBEP20(_token).balanceOf(address(this)));
        }        
    }
}