/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
// Imports
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// import "./Libraries.sol";

contract FirstPresale is ReentrancyGuard {
    address public owner = 0xBEED5427b0E728AC7EfAaD279c51d511472f9ee2; // owner
    IERC20 public token; //  Token.
    bool private tokenAvailable = false;
    uint public tokensPerETH = 35000; // token per ETH
    uint public ending; // sale end time
    bool public presaleStarted = false; //started or not
    address public deadWallet = 0x000000000000000000000000000000000000dEaD; 
    uint public cooldownTime = 10 days; // time between withdrawals of token
    uint public tokensSold;
    uint256 internal balance;
    uint256 public ContractBalance = 1500000*10**18; 


    mapping(address => bool) public whitelist; // Whitelist for presale.
    mapping(address => uint) public invested; // how much a person invested.
    mapping(address => uint) public investorBalance;//their current balance
    mapping(address => uint) public withdrawableBalance;//how much they can take out of tha platform
    mapping(address => uint) public claimReady;//is it time for that to happen

    constructor() {
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'You must be the owner.');
        _;
    }

    function transferOwnership (address newOwner) public onlyOwner{
        //check if not empty
        if (newOwner != 0x0000000000000000000000000000000000000000){
        owner = newOwner;
        }
    }

   //token insertion can only happen 1 time
    function setToken(IERC20 _token) public onlyOwner {
        require(!tokenAvailable, "Token is already inserted.");
        token = _token;
        tokenAvailable = true;
    }

    function multiAddToWhitelist(address[] memory _investor) public onlyOwner {
        for (uint _i = 0; _i < _investor.length; _i++) {
            require(_investor[_i] != address(0), 'Invalid address.');
            address _investorAddress = _investor[_i];
            whitelist[_investorAddress] = true;
        }
    }

    //add to whitelist
    function addToWhitelist(address _investor) public onlyOwner {
            require(_investor != address(0), 'Invalid address.');
            address _investorAddress = _investor;
            whitelist[_investorAddress] = true;        
    }

    function setPrice(uint _priceTPETH) public onlyOwner {
        require(presaleStarted, "Presale not started.");
        require(block.timestamp <  ending, "Presale finished.");
        tokensPerETH = _priceTPETH;
    }

    function startPsale(uint _presaleTime) public onlyOwner {
        require(tokenAvailable, "Token is not set.");
        require(!presaleStarted, "Presale already started.");
        ending = block.timestamp + _presaleTime;
        presaleStarted = true;
    }

    function invest() public payable nonReentrant {
        require(whitelist[msg.sender], "You must be on the whitelist.");
        require(presaleStarted, "Presale must have started.");
        require(block.timestamp <= ending, "Presale finished.");
        invested[msg.sender] += msg.value; // update investors balance
        require(invested[msg.sender] >= 0.05 ether, "Your investment should be more than 0.05 ETH.");
        require(invested[msg.sender] <= 2.5 ether, "Your investment cannot exceed 2.5 ETH.");

        uint _investorTokens = msg.value * tokensPerETH; // how many tokens they will receive
        investorBalance[msg.sender] += _investorTokens;//do the swap
        withdrawableBalance[msg.sender] += _investorTokens;//update the necesary balances
        tokensSold += _investorTokens;
    }

    //% calculation
    function mulScale (uint x, uint y, uint128 scale) internal pure returns (uint) {
        uint a = x / scale;
        uint b = x % scale;
        uint c = y / scale;
        uint d = y % scale;

        return a * c * scale + a * d + b * c + b * d / scale;
    }
    //investors claim function - they claim tokens at the end of the presale 

    //it means a buyer who buys 1000 tokens can take 100 a week every week for x weeks
    function withdrawTokens() public nonReentrant {
        require(whitelist[msg.sender], "You must be on the whitelist.");
        require(block.timestamp > ending, "Presale must have finished.");
        require(claimReady[msg.sender] <= block.timestamp, "You can't claim now.");
        require(ContractBalance > 0, "Insufficient contract balance.");
        require(investorBalance[msg.sender] > 0, "Insufficient investor balance.");

        uint _withdrawableTokensBalance = mulScale(investorBalance[msg.sender], 1000, 10000); // 1000 basis points = 10%.

        if(withdrawableBalance[msg.sender] <= _withdrawableTokensBalance) {
            token.transfer(msg.sender, withdrawableBalance[msg.sender]);
            investorBalance[msg.sender] = 0;
            withdrawableBalance[msg.sender] = 0;
        } else {
            claimReady[msg.sender] = block.timestamp + cooldownTime; // update next claim time
            withdrawableBalance[msg.sender] -= _withdrawableTokensBalance; // update withdrawable balance
            token.transfer(msg.sender, _withdrawableTokensBalance); // transfer the tokens
        }
    }

    //burn left over tokens
    function burnTokens() public onlyOwner {
        require(block.timestamp > ending, "Presale must have finished.");        
        uint _burnBalance = ContractBalance - tokensSold;
        token.transfer(deadWallet, _burnBalance);
    }
    
    function purgeBadToken(IERC20 badToken, address _dest) public {
        uint256 BadTokenBalance = badToken.balanceOf(address(this));
        badToken.transfer(_dest, BadTokenBalance);
    } 

    function BalanceOut() public onlyOwner {
        uint _Balance = address(this).balance;
        payable (owner).transfer(_Balance);
    }

    receive() external payable{
        balance += msg.value;
    }

    fallback() external payable{
        balance += msg.value;
    }
}

interface IERC20 {
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function onERC20Received(address _operator, address _from, uint256 _value, bytes calldata _data) external returns(bytes4);
}