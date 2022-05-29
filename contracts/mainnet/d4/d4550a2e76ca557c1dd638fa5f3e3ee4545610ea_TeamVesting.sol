/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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

contract TeamVesting is ReentrancyGuard {
    IERC20 public token;
    address public teamWallet = 0xBEED5427b0E728AC7EfAaD279c51d511472f9ee2; // team wallet
    uint256 private balance;   
    uint public cooldownTime = 7 days; // cooldown time
    uint public claimReady; //save claim  time
    bool private tokenAvailable = false;
    uint public initialContractBalance = 500000*10**18; 
    constructor() {
         
    }

    modifier onlyOwner() {
        require(msg.sender == teamWallet, 'You must be the owner.');
        _;
    }

    //add the token can only happen once
    function setToken(IERC20 _token) public onlyOwner {
        require(!tokenAvailable, "Token is already inserted.");
        token = _token;
        tokenAvailable = true;
    }

    //% calculator
    function mulScale (uint x, uint y, uint128 scale) internal pure returns (uint) {
        uint a = x / scale;
        uint b = x % scale;
        uint c = y / scale;
        uint d = y % scale;

        return a * c * scale + a * d + b * c + b * d / scale;
    }

    //team claim
    function claimTokens() public onlyOwner nonReentrant {
        require(claimReady <= block.timestamp, "You can't claim now.");
        require(token.balanceOf(address(this)) > 0, "Insufficient Balance.");

        uint _withdrawableBalance = mulScale(initialContractBalance, 1000, 10000); // 1000 basis points = 10%.

        if(token.balanceOf(address(this)) <= _withdrawableBalance) {
            token.transfer(teamWallet, token.balanceOf(address(this)));
        } else {
            claimReady = block.timestamp + cooldownTime;

            token.transfer(teamWallet, _withdrawableBalance); 
        }
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