// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC223 standard token as defined in the EIP.
 */

abstract contract IERC223 {
    
    function name()        public view virtual returns (string memory);
    function symbol()      public view virtual returns (string memory);
    function standard()    public view virtual returns (string memory);
    function decimals()    public view virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);
    
    /**
     * @dev Returns the balance of the `who` address.
     */
    function balanceOf(address who) public virtual view returns (uint);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address
     * and returns `true` on success.
     */
    function transfer(address to, uint value) public virtual returns (bool success);
        
    /**
     * @dev Transfers `value` tokens from `msg.sender` to `to` address with `data` parameter
     * and returns `true` on success.
     */
    function transfer(address to, uint value, bytes calldata data) public virtual returns (bool success);
     
     /**
     * @dev Event that is fired on successful transfer.
     */
    event Transfer(address indexed from, address indexed to, uint value);
    
     /**
     * @dev Additional event that is fired on successful transfer and logs transfer metadata,
     *      this event is implemented to keep Transfer event compatible with ERC20.
     */
    event TransferData(bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC223.sol";

contract TokenVesting {
    uint256 constant public INVESTORS_AMOUNT = 120000000 * 10**18; // 120 million tokens for investors
    uint256 constant public ADVISORS_AMOUNT = 16000000 * 10**18; // 16 million tokens for advisors
    uint256 constant public DEVELOPERS_AMOUNT = 24000000 * 10**18; // 24 million tokens for developers

    address public founderWallet;
    address public advisorAddress;
    address public investorAddress;
    address public teamAddress;
    address public tokenAddress;
    uint256 public vestingStartTime;
    uint256 public investorsReleased;
    uint256 public advisorsReleased;
    uint256 public developersReleased;

    constructor(uint256 _vestingStartTime, address _founderWallet, address _advisorAddress,address _investorAddress, address _teamAddress, address _tokenAddress) {
        require(_vestingStartTime >= block.timestamp, "Vesting start time must be in the future");
        require(_founderWallet != address(0), "Founder wallet cannot be zero address");
        require(_advisorAddress != address(0), "Advisor address cannot be zero address");
        require(_investorAddress != address(0), "Advisor address cannot be zero address");
        require(_teamAddress != address(0), "Team address cannot be zero address");
        require(_tokenAddress != address(0), "Token address cannot be zero address");

        vestingStartTime = _vestingStartTime;
        founderWallet = _founderWallet;
        advisorAddress = _advisorAddress;
        investorAddress = investorAddress;
        teamAddress = _teamAddress;
        tokenAddress = _tokenAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == founderWallet || msg.sender == advisorAddress || msg.sender == teamAddress || msg.sender == investorAddress, "Only the contract creator can call this function");
        _;
    }

    function getInvestorsWithdrawAmount() public view returns (uint256) {
        uint256 timeElapsed = (block.timestamp - vestingStartTime) / (10 minutes);
        uint256 vestingDuration = INVESTORS_AMOUNT ;
        uint256 vestedAmount = timeElapsed * vestingDuration;
        return vestedAmount - investorsReleased;
    }

    function getAdvisorsWithdrawAmount() public view returns (uint256) {
        uint256 timeElapsed = (block.timestamp - vestingStartTime) / (10 minutes);
        uint256 vestingDuration = ADVISORS_AMOUNT ;
        uint256 vestedAmount = timeElapsed * vestingDuration;
        return vestedAmount - advisorsReleased;
    }

    function getDevelopersWithdrawAmount() public view returns (uint256) {
        uint256 timeElapsed = (block.timestamp - vestingStartTime) / (10 minutes);
        uint256 vestingDuration = DEVELOPERS_AMOUNT ;
        uint256 vestedAmount = timeElapsed * vestingDuration;
        return vestedAmount - developersReleased;
    }

    function withdrawInvestorsTokens() public onlyOwner {
        uint256 amount = getInvestorsWithdrawAmount();
        require(amount > 0, "No tokens available for withdrawal");
        investorsReleased += amount;
        IERC223(tokenAddress).transfer(investorAddress, amount);
    }

    function withdrawAdvisorsTokens() public onlyOwner {
        uint256 amount = getAdvisorsWithdrawAmount();
        require(amount > 0, "No tokens available for withdrawal");
        advisorsReleased += amount;
        IERC223(tokenAddress).transfer(advisorAddress, amount);
    }

    function withdrawDevelopersTokens() public onlyOwner {
        uint256 amount = getDevelopersWithdrawAmount();
        require(amount > 0, "No tokens available for withdrawal");
        developersReleased = developersReleased + amount;
        IERC223(tokenAddress).transfer(teamAddress, amount);
    }
}