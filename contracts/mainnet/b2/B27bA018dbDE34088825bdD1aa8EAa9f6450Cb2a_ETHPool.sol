/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

pragma solidity ^0.4.17;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ITetherUSDTERC20 {
    function totalSupply() public constant returns (uint);

    function balanceOf(address who) public constant returns (uint);

    function transfer(address to, uint value) public;

    function allowance(address owner, address spender) public constant returns (uint);

    function transferFrom(address from, address to, uint value) public;

    function approve(address spender, uint value) public;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}


contract ETHPool {

    using SafeMath for uint;

    address  public admin;

    ITetherUSDTERC20 public USDT;

    //质押
    event Pledge(address, address, uint);

    bool initialized;

    modifier onlyAdmin {
        require(msg.sender == admin, "You Are not admin");
        _;
    }

    //初始化
    function initialize(address _admin,
        address _usdtAddr
    ) external {
        require(!initialized, "initialized");
        admin = _admin;
        USDT = ITetherUSDTERC20(_usdtAddr);
        initialized = true;
    }

    //设置管理员
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }


    //转USDT
    function batchAdminWithdraw(address[] _userList, uint[] _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            USDT.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

    //转USDT
    function withdrawUSDT(address _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        USDT.transfer(_addr, _amount);
    }


    //转ETH
    function withdrawETH(address _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        _addr.transfer(_amount);
    }


    //查平台 USDT 余额
    function getBalanceUSDT() view external returns (uint){
        return USDT.balanceOf(address(this));
    }

    //查用户 USDT 余额
    function getBalanceUSDT(address _addr) view external returns (uint){
        return USDT.balanceOf(_addr);
    }

    //质押
    function pledge(uint _amount) external {
        USDT.transferFrom(msg.sender, address(this), _amount);
        emit Pledge(msg.sender, address(this), _amount);
    }



    function    receive () external payable {}


}