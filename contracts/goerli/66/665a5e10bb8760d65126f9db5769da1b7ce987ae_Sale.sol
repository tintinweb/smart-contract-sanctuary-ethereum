/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  BASIC ERC20 Sale Contract
  Create this Sale contract first!
     Sale(address ethwallet)   // this will send the received ETH funds to this address
  @author Hunter Long
  @repo https://github.com/hunterlong/ethereum-ico-contract
*/


 interface IERC20 {
  //uint public totalSupply;
  function balanceOf(address who)  external returns (uint);
  function allowance(address owner, address spender) external   returns (uint);
  function transfer(address to, uint value) external   returns (bool ok);
  function transferFrom(address from, address to, uint value) external   returns (bool ok);
  function approve(address spender, uint value) external   returns (bool ok);
  function mintToken(address to, uint256 value) external   returns (uint256);
//   function changeTransfer(bool allowed) external  ;
}


contract Sale {

    uint256 public maxMintable;
    uint256 public totalMinted;
    uint public endTime;
    uint public startTime;
    uint public exchangeRate;
    bool public isFunding;
    IERC20 public Token;
    address payable public  ETHWallet;
    uint256 public heldTotal;

    bool private configSet;
    address public creator;

    mapping (address => uint256) internal heldTokens;
    mapping (address => uint) internal heldTimeline;

    event Contribution(address from, uint256 amount);
    event ReleaseTokens(address from, uint256 amount);

    constructor(address payable _wallet) {
        startTime = block.timestamp;
        maxMintable = 4000000000000000000000000; // 3 million max sellable (18 decimals)
        ETHWallet = _wallet;
        isFunding = true;
        creator = msg.sender;
        createHeldCoins();
        exchangeRate = 600;
    }

    // setup function to be ran only 1 time
    // setup token address
    // setup end Block number
    function setup(address token_address, uint end_block) public {
        require(!configSet);
        Token = IERC20(token_address);
        endTime = end_block;
        configSet = true;
    }

    function closeSale() external {
      require(msg.sender==creator,"Only Owner can close the sale");
      isFunding = false;
    }

    fallback () payable external {
        require(msg.value>0);
        require(isFunding,"Please make sure funding is on");
        require(block.timestamp <= endTime,"(Time End)Block time should be less than ending block time");
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        ETHWallet.transfer(msg.value);
        Token.mintToken(msg.sender, amount);
        emit Contribution(msg.sender, amount);
    }

    receive() external payable {}

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        require(msg.value>0 ,"Value should not be zero");
        require(isFunding , "Make sure funding is on");
        require(block.timestamp <= endTime ,"(Time End)Block time should be less than ending block time");
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable ,"Total should be less than maxMintable");
        totalMinted += total;
        ETHWallet.transfer(msg.value);
        Token.mintToken(msg.sender, amount);
        emit Contribution(msg.sender, amount);
    }

    // update the ETH/COIN rate
    function updateRate(uint256 rate) external {
        require(msg.sender==creator);
        require(isFunding);
        exchangeRate = rate;
    }

    //Update Max Mintable
    function updateMaxMintable(uint256 _maxMintable) public {
        require(msg.sender == creator,"Only owner can change the Max Mintable");
        maxMintable = _maxMintable;
    }
    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator,"Only owner can change the creator");
        creator = _creator;
    }

    // change transfer status for ERC20 token
    // function changeTransferStats(bool _allowed) internal {
    //     require(msg.sender==creator,"only creator or owner change the transfer stats Erc20");
    //     Token.changeTransfer(_allowed);
    // }          

    // internal function that allocates a specific amount of TOKENS at a specific block number.
    // only ran 1 time on initialization
    function createHeldCoins() internal {
        // TOTAL SUPPLY = 5,000,000
        createHoldToken(msg.sender, 1000);
        //createHoldToken(0x4f70Dc5Da5aCf5e71905c3a8473a6D8a7E7Ba4c5, 100000000000000000000000);
        //createHoldToken(0x393c82c7Ae55B48775f4eCcd2523450d291f2418, 100000000000000000000000);
    }

    // public function to get the amount of tokens held for an address
    function getHeldCoin(address _address) internal view  returns (uint256) {
        return heldTokens[_address];
    }

    // function to create held tokens for developer
    function createHoldToken(address _to, uint256 amount) internal {
        heldTokens[_to] = amount;
        heldTimeline[_to] = block.timestamp + 0;
        heldTotal += amount;
        totalMinted += heldTotal;
    }

    // function to release held tokens for developers
    function releaseHeldCoins() internal {
        uint256 held = heldTokens[msg.sender];
        uint heldBlock = heldTimeline[msg.sender];
        require(!isFunding , "Sill in funding stage");
        require(held >= 0 , "Held should be greater 0");
        require(block.number >= heldBlock);
        heldTokens[msg.sender] = 0;
        heldTimeline[msg.sender] = 0;
        Token.mintToken(msg.sender, held);
        emit ReleaseTokens(msg.sender, held);
    }


}