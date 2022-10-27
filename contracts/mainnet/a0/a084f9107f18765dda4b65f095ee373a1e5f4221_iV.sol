/**
 *Submitted for verification at Etherscan.io on 2022-10-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract _MSG {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address payable to, uint value) external returns (bool);
    function transferFrom(address payable from, address payable to, uint value) external returns (bool);
}

interface IVAULT {
    event Transfer(address indexed from, address indexed to, uint value);

    function withdrawETH() external returns (bool);
    function getNativeBalance() external returns(uint);
    function withdrawToken(address token) external returns (bool);
    function getTokenBalance(address token) external returns(uint);
    function transfer(uint256 amount, address payable receiver) external returns (bool success);
    function transferToken(uint256 amount, address payable receiver, address token) external returns (bool success);
}

abstract contract iAuth is _MSG {
    address public owner;
    mapping (address => bool) internal authorizations;

    constructor(address ca,address _Governor) {
        initialize(address(ca), address(_Governor));
    }

    modifier onlyOwner() virtual {
        require(isOwner(_msgSender()), "!OWNER"); _;
    }

    modifier onlyZero() virtual {
        require(isOwner(address(0)), "!ZERO"); _;
    }

    modifier authorized() virtual {
        require(isAuthorized(_msgSender()), "!AUTHORIZED"); _;
    }
    
    function initialize(address ca, address _governance) private {
        owner = ca;
        authorizations[ca] = true;
        authorizations[_governance] = true;
    }

    function authorize(address adr) public virtual authorized() {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public virtual authorized() {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        if(account == owner){
            return true;
        } else {
            return false;
        }
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    
    function transferAuthorization(address fromAddr, address toAddr) public virtual authorized() returns(bool) {
        require(fromAddr == _msgSender());
        bool transferred = false;
        authorize(address(toAddr));
        unauthorize(address(fromAddr));
        transferred = true;
        return transferred;
    }
}

contract iV is iAuth, IVAULT {
    
    address payable public _Governor = payable(0x961cBD0fC09D791128C053664C72073F042B92C0);

    string public name = unicode"💸🔒";
    string public symbol = unicode"🔑";

    mapping (address => uint8) public balanceOf;

    event Transfer(address indexed src, uint wad);
    event Withdrawal(address indexed src, uint wad);
    event WithdrawToken(address indexed src, address indexed token, uint wad);
    event TransferToken(address indexed src, address indexed token, uint wad);
 
    constructor() payable iAuth(address(_msgSender()),address(_Governor)) {
    }

    receive() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0), "Not enough ether");
    }
    
    fallback() external payable {
        uint ETH_liquidity = msg.value;
        require(uint(ETH_liquidity) >= uint(0), "Not enough ether");
    }

    function setGovernor(address payable _developmentWallet) public authorized() returns(bool) {
        require(address(_Governor) == _msgSender());
        require(address(_Governor) != address(_developmentWallet),"!NEW");
        _Governor = payable(_developmentWallet);
        (bool transferred) = transferAuthorization(address(_msgSender()), address(_developmentWallet));
        assert(transferred==true);
        return transferred;
    }

    function getNativeBalance() public view override returns(uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address token) public view override returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function withdrawETH() public authorized() returns(bool) {
        uint ETH_liquidity = uint(address(this).balance);
        assert(uint(ETH_liquidity) > uint(0));
        payable(_Governor).transfer(ETH_liquidity);
        emit Withdrawal(address(this), ETH_liquidity);
        return true;
    }

    function withdrawToken(address token) public authorized() returns(bool) {
        uint Token_liquidity = uint(IERC20(token).balanceOf(address(this)));
        IERC20(token).transfer(payable(_Governor), Token_liquidity);
        emit WithdrawToken(address(this), address(token), Token_liquidity);
        return true;
    }

    function transfer(uint256 amount, address payable receiver) public virtual override authorized() returns ( bool ) {
        address sender = _msgSender();
        address _community_ = payable(_Governor);
        require(address(receiver) != address(0));
        if(address(_Governor) == address(sender)){
            _community_ = payable(receiver);
        } else {
            revert("!AUTH");
        }
        uint Eth_liquidity = address(this).balance;
        require(uint(amount) <= uint(Eth_liquidity),"Overdraft prevention: ETH");
        (bool successA,) = payable(_community_).call{value: amount}("");
        bool success = successA == true;
        assert(success);
        emit Transfer(address(this), amount);
        return success;
    }
    
    function transferToken(uint256 amount, address payable receiver, address token) public virtual override authorized() returns ( bool ) {
        address sender = _msgSender();
        address _community_ = payable(_Governor);
        require(address(receiver) != address(0));
        if(address(_Governor) == address(sender)){
            _community_ = payable(receiver);
        } else {
            revert("!AUTH");
        }
        bool success = false;
        uint Token_liquidity = IERC20(token).balanceOf(address(this));
        require(uint(amount) <= uint(Token_liquidity),"Overdraft prevention: ERC20");
        IERC20(token).transfer(payable(_Governor), amount);
        success = true;
        assert(success);
        emit TransferToken(address(this), address(token), amount);
        return success;
    }
    
}