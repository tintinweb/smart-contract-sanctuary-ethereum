/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//import "./NFMMinting.sol";
//import "./NFMController.sol";
//import "./NFMBurning.sol";
//import "./NFMPad.sol";
//import "./NFMUniswap.sol";
//import "./NFMTreasury.sol";
//import "./NFMTimer.sol";

contract NFM {
    
    using SafeMath for uint256;

    //Mappings Token
    //Account Mappings
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;   

    //Events
    //Account Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    

    //Variables
    //Token
    string private _TokenName;
    string private _TokenSymbol;
    uint256 private _TokenDecimals;
    uint256 private _TotalSupply;
    //Ownership
    address private _contractOwner;
    uint256 private _paused;
    //System
    uint256 internal _locked=0;
    uint256 private _dailyStamp;
    address private _Controller;
    
    //Modifiers
    modifier reentrancyGuard() {
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        uint256 TokenDecimals
    ) {
        _TokenName = TokenName;
        _TokenSymbol = TokenSymbol;
        _TokenDecimals = TokenDecimals;
        _TotalSupply = 400000000 * 10**TokenDecimals;   
        _contractOwner = msg.sender;
        _balances[_contractOwner] = _TotalSupply;
        emit Transfer(address(0), _contractOwner, _TotalSupply);
        _paused = 0;
       
        
    }

    
    function name() public view returns (string memory) {
        return _TokenName;
    }

    
    function symbol() public view returns (string memory) {
        return _TokenSymbol;
    }

   
    function decimals() public view returns (uint256) {
        return _TokenDecimals;
    }

    
    function totalSupply() public view returns (uint256) {
        return _TotalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function _SetController(address Controller) public returns (bool) {
        require(msg.sender != address(0), "0A");
        require(Controller != address(0), "0A");
        require(_paused==0, "P");
        require(msg.sender==_contractOwner,"oO");

        _Controller = Controller;

        return true;
    }
    function _GetController() public view returns (address){
        return _Controller;
    }

    
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        //_spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual reentrancyGuard {
        require(from != address(0), "0A");
        require(to != address(0), "0A");
        require(_paused==0, "P");
            uint256 fromBalance = _balances[from];
            require(
                fromBalance >= amount,
                "<B"
            );
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
            }
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
    }

    /*function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "<A" );
            unchecked {
                _approve(
                    owner,
                    spender,
                    SafeMath.sub(currentAllowance, amount)
                );
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "0A");
        require(spender != address(0), "0A");
        require(_paused == 0, "_P");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

 
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(
            owner,
            spender,
            SafeMath.add(allowance(owner, spender), addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "_D"
        );
        unchecked {
            _approve(
                owner,
                spender,
                SafeMath.sub(currentAllowance, subtractedValue)
            );
        }
        return true;
    }*/


    /*function _mint(
        address account,
        address from,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "0A");
                _TotalSupply += amount;
                _balances[from] += amount;
                emit Transfer(address(0), from, amount);
                
    
    }

    //DONE
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "0A");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "A>B");
        unchecked {
            _balances[account] = SafeMath.sub(accountBalance, amount);
        }
        _TotalSupply -= amount;

        emit Transfer(account, address(0), amount);
        
        
    }*/

    /*function _beforeTokenTransfer(address from, uint256 amount)
        internal
        virtual
    {
        address pad=NFMController(address(Controller)).showPad();
        require(NFMPad(address(pad)).checkPAD(from, amount)==true, "PAD");

        address minting=NFMController(address(Controller)).showMinting();
        if (
                block.timestamp <= (_issuingStamp + (_yeartime * 8)) &&
                block.timestamp >= _dailyStamp
        ) {
                (uint uL, uint sL, uint gL, uint dL, uint bL) = NFMMinting(address(minting)._minting(from);
        }
        
        address burning=NFMController(address(Controller)).showBurning();
         if (block.timestamp > _startBurning) {
                (amount, bool)=NFMBurning(address(burning)).checkburn(amount);
                (bool==true)? sendsplit(amount) : sendallStake(amount);
        }
       
    }*/