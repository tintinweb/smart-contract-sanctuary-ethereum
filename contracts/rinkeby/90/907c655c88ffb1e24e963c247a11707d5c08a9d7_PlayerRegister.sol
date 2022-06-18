/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity >=0.4.0<=0.6.0;

/**
 * @title playerRegister
 * @notice playerRegister contract is a contract to register player
*/

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PlayerRegister {
    using SafeMath for uint256;

/**
 * @dev owner is a state variable
 */
    address public owner;
  
  /**
   * @dev mapping address as key to struct player with mapping name players
   */
    mapping (address=>player)players;

    bool private registrationsOpen = true;

    address public tokenAddress = 0xd01A476F9eCe92B0a0ED68DA2b1E3084AaBFca1A;

    uint256 public tokenAmount = 1000 * 1e9;
    
    /**
     * @dev assigning the contract deployer as the owner
     */
    constructor() public {
        owner=msg.sender;
    }
    
    /**
     * @dev a modifier onlyOwner is created to limit the access to function register to contract deployer
     */
    modifier onlyOwner {
        require(msg.sender==owner);
        _;
    }
    /**
     * @dev a struct player is defined
     */
    struct player{
        
        address playerId;
        string  name;
        bool isExist;
        
    }

    function setRegistrations(bool _registrationsOpen) public onlyOwner {
        registrationsOpen = _registrationsOpen;
    }


    /**
     * @param playerId is player's ethereum address
     * @param name player's name
     */
    function register(address playerId,string memory name) public {

            /**
             *@dev require statment to block multiple entry
             */
            require(players[playerId].isExist==false, "Player details already registered and cannot be altered");

            require (registrationsOpen == true, "Registrations closed!");

            require (msg.sender == playerId);

            require(IERC20(tokenAddress).balanceOf(msg.sender) >= tokenAmount, "Must have enough balance");

            require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount), "Failed amount transfer.");

            // require(IToken(tokenAddress).balanceOf(msg.sender, tokenAmount);
            
            /**
             * @dev assigning the player details to a key (playerId)
             */
            players[playerId]=player(playerId,name,true);

            // IToken(tokenAddress).transfer(address(this), tokenAmount);
    }
    
    /**
     * @notice function to get the details of a player when playerId is given
     */
            
    function getplayerDetails(address playerId) public view returns (address,string memory){
        
        /**
         * @dev returning playerId,name to corresponding key
         */ 
        return(players[playerId].playerId,players[playerId].name);
    }

    function setTokenAddress(address token) external onlyOwner {
        require(tokenAddress == address(0), "Token address is already set.");
        require(token != address(0), "Token address zero not allowed.");
        
        tokenAddress = token;
    }

    function setTokenAmount(uint256 tokenAmt) external onlyOwner {
        tokenAmount = tokenAmt * 1e9;
    }

}