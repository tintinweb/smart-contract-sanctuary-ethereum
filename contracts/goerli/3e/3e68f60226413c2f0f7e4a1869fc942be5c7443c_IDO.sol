/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract IDO {
    address private creator;
    
    address public riceToken;
    uint256 public startBlock;
    uint256 public exchangeRate = 2;
    uint256 public minAllocation = 1e17;
    uint256 public maxAllocation = 100 * 1e18;  // 18 decimals
    uint256 public maxFundsRaised;
    uint256 public totalRaise;
    uint256 public heldTotal;
    address payable public ETHWallet;
    bool public transferStats = true;
    bool public isFunding = true;
    
    mapping(address => uint256) public heldTokens;
    mapping(address => uint256) public heldTimeline;

    event Contribution(address from, uint256 amount);
    event ReleaseTokens(address from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == creator, "Ownable: caller is not the owner");
        _;
    }

    modifier checkStart(){
        require(block.timestamp >= startBlock, "The project has not yet started");
        _;
    }

    constructor(
        address payable _wallet,
        address _riceToken,
        uint256 _maxFundsRaised,
        uint256 _startBlock
    ) {
        startBlock = _startBlock;   // One block in 3 seconds, 24h hours later ( current block + 28800  )
        maxFundsRaised = _maxFundsRaised;   // 18 decimals
        ETHWallet = _wallet;
        creator = msg.sender;
        riceToken = _riceToken;
    }

    function closeSale() external onlyOwner {
        isFunding = false;
    }

    function setMinAllocation(uint256 _minAllocation) public onlyOwner {
        minAllocation = _minAllocation;
    }

    function setMaxAllocation(uint256 _maxAllocation) public onlyOwner {
        maxAllocation = _maxAllocation;
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable checkStart {
        require(msg.value >= minAllocation && msg.value <= maxAllocation, "The quantity exceeds the limit");
        require(heldTokens[msg.sender] == 0, "Number of times exceeded");
        require(isFunding, "ido is closed");
        require(totalRaise + msg.value <= maxFundsRaised);

        uint256 heldAmount = exchangeRate * msg.value;
        totalRaise += msg.value;
        if (totalRaise == maxFundsRaised){
            isFunding = false;
        }
        ETHWallet.transfer(msg.value);
        createHoldToken(msg.sender, heldAmount);
        emit Contribution(msg.sender, heldAmount);
    }

    // update the ETH/COIN rate
    function updateRate(uint256 rate) external onlyOwner {
        require(isFunding, "ido is closed");
        exchangeRate = rate;
    }

    // change creator address
    function changeCreator(address _creator) external onlyOwner {
        creator = _creator;
    }

    // change transfer status for ERC20 token
    function changeTransferStats(bool _allowed) external onlyOwner {
        transferStats = _allowed;
    }

    // public function to get the amount of tokens held for an address
    function getHeldCoin(address _address) public view returns (uint256) {
        return heldTokens[_address];
    }

    // function to create held tokens for developer
    function createHoldToken(address _to, uint256 amount) internal {
        heldTokens[_to] = amount;
        heldTimeline[_to] = block.number;
        heldTotal += amount;
    }

    // function to release held tokens for developers
    function releaseHeldCoins() external checkStart {
        require(!isFunding, "Haven't reached the claim goal");
        require(heldTokens[msg.sender] >= 0, "Number of holdings is 0");
        require(block.timestamp >= heldTimeline[msg.sender], "Abnormal transaction");
        require(transferStats, "Transaction stopped");
        uint256 held = heldTokens[msg.sender];
        heldTokens[msg.sender] = 0;
        heldTimeline[msg.sender] = 0;
        IERC20(riceToken).transfer(msg.sender, held);
        emit ReleaseTokens(msg.sender, held);
    }
}