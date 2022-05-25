/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.13;

interface IDividendDistributor {
    function setRewardToken(address newRewardToken) external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
    function claimDividend(address shareholder) external;
    function getDividendsClaimedOf (address shareholder) external returns (uint256);
    function process(uint256 gas) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DefaultContract {
    function name() public pure returns (uint) {}
    
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _owner;
    DefaultContract dc;

    address public RewardToken;
    address[] RewardTokens;

    struct Token {
        string name;
        address contractAddress;
        bool active;
    }
  
    struct ShareUser {
            uint256 amount;
            uint256 totalExcluded;
            uint256 totalClaimed;
            bool active;
}

    struct Share {
       mapping (address => ShareUser) tokens;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) shares;
    mapping (address => Token) ReflectionsTokens;

    mapping (address => uint256) public totalShares;
    mapping (address => uint256) public totalDividends;
    mapping (address => uint256) public totalClaimed;
    uint256 public dividendsPerShare;
    uint256 private dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod;
    uint256 public minDistribution;

    uint256 currentIndex;
    bool initialized;

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner); _;
    }

    constructor () {
        _token = 0x05645Ef3D246844bE40f55599c1d52e7a97D24cA;
        _owner = (msg.sender);
    }

    receive() external payable { }

    function setRewardToken(address newRewardToken) external override onlyToken {
        bool exists = false;
         for (uint i=0; i < RewardTokens.length; i++) {
            if(RewardTokens[i] == newRewardToken)
            {
                exists = true;
            }
        }
        if(!exists){
            RewardTokens.push(newRewardToken);
        }
        RewardToken = newRewardToken;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function checkTokenUser(address shareHolder) internal  {
        if(!shares[shareHolder].tokens[RewardToken].active){
            shares[shareHolder].tokens[RewardToken].active = true;
        }
        if(shares[shareHolder].tokens[RewardToken].amount <= 0)
        {
            shares[shareHolder].tokens[RewardToken].amount = 0;
        }
        
        if(shares[shareHolder].tokens[RewardToken].totalExcluded <= 0)
        {
            shares[shareHolder].tokens[RewardToken].totalExcluded = 0;
        }
        if(shares[shareHolder].tokens[RewardToken].totalClaimed <= 0)
        {
            shares[shareHolder].tokens[RewardToken].totalClaimed = 0;
        }
    }

    function setShare(address shareHolder, uint256 amount) external override onlyToken {       
        checkTokenUser(shareHolder);
        if(shares[shareHolder].tokens[RewardToken].amount > 0){
            distributeDividend(shareHolder);
        }

        if(amount > 0 && shares[shareHolder].tokens[RewardToken].amount == 0){
            addShareholder(shareHolder);
        }else if(amount == 0 && shares[shareHolder].tokens[RewardToken].amount > 0){
            removeShareholder(shareHolder);
        }

        totalShares[RewardToken] = totalShares[RewardToken].sub(shares[shareHolder].tokens[RewardToken].amount).add(amount);
        shares[shareHolder].tokens[RewardToken].amount = amount;
        shares[shareHolder].tokens[RewardToken].totalExcluded = getCumulativeDividends(shares[shareHolder].tokens[RewardToken].amount);
    }

    function deposit(uint256 amount) external override onlyToken {

        if (amount > 0) {
            totalDividends[RewardToken] = totalDividends[RewardToken].add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares[RewardToken]));
        }
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while(gasUsed < gas && iterations < shareholderCount) {

            if(currentIndex >= shareholderCount){ currentIndex = 0; }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
            && getUnpaidEarningsOfUserAndCurrentToken(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].tokens[RewardToken].amount == 0){ return; }

        uint256 amount = getClaimableDividendOfUserAndCurrentReward(shareholder);
        if(amount > 0){
            totalClaimed[RewardToken] = totalClaimed[RewardToken].add(amount);
            shares[shareholder].tokens[RewardToken].totalClaimed = shares[shareholder].tokens[RewardToken].totalClaimed.add(amount);
            shares[shareholder].tokens[RewardToken].totalExcluded = getCumulativeDividends(shares[shareholder].tokens[RewardToken].amount);
            IERC20(RewardToken).transfer(shareholder, amount);
        }
    }

    function distributeDividendByUserAndToken(address shareholder, address rewardToken) internal {
        if(shares[shareholder].tokens[rewardToken].amount == 0){ return; }

        uint256 amount = getClaimableDividendOfUserAndCurrentReward(shareholder);
        if(amount > 0){
            totalClaimed[rewardToken] = totalClaimed[rewardToken].add(amount);
            shares[shareholder].tokens[rewardToken].totalClaimed = shares[shareholder].tokens[rewardToken].totalClaimed.add(amount);
            shares[shareholder].tokens[rewardToken].totalExcluded = getCumulativeDividends(shares[shareholder].tokens[rewardToken].amount);
            IERC20(rewardToken).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function claimDividendByUserAndToken(address shareholder, address rewardToken) external {
        distributeDividendByUserAndToken(shareholder,rewardToken);
    }

    function getTotalSharesByUserAndToken(address shareholder, address rewardToken) public view returns (uint256) {
        return shares[shareholder].tokens[rewardToken].amount;
    }

    function getTokenTotalSharesByUserAndCurrentReward(address shareholder) public view returns (uint256) {
        return shares[shareholder].tokens[RewardToken].amount;
    }

    function getClaimableDividendOfUserAndCurrentReward(address shareholder) public view returns (uint256) {
        if(shares[shareholder].tokens[RewardToken].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].tokens[RewardToken].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].tokens[RewardToken].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getClaimableDividendOfUserAndToken(address shareholder, address rewardToken) public view returns (uint256) {
        if(shares[shareholder].tokens[rewardToken].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].tokens[rewardToken].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].tokens[rewardToken].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getUnpaidEarningsOfUserAndToken(address shareholder, address rewardToken) public view returns (uint256) {
        if(shares[shareholder].tokens[rewardToken].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].tokens[rewardToken].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].tokens[rewardToken].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getUnpaidEarningsOfUserAndCurrentToken(address shareholder) public view returns (uint256) {
        if(shares[shareholder].tokens[RewardToken].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].tokens[RewardToken].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].tokens[RewardToken].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }


    function getDividendsClaimedOfUserAndCurrentToken(address shareholder, address rewardToken) external view returns (uint256) {
        return shares[shareholder].tokens[rewardToken].totalClaimed;
    }

    function getDividendsClaimedOf(address shareholder) external view returns (uint256) {
        return shares[shareholder].tokens[RewardToken].totalClaimed;
    }

    function getShareHoldersCurrentReflection(address shareHolder) public view returns ( ShareUser memory) {
        return shares[shareHolder].tokens[RewardToken];
    }

    function getRewardTokens() public view returns (address[] memory) {
        return RewardTokens;
    }

    function getTotalDividendsByTokenAddress() public view returns (uint256 ) {
        return totalDividends[RewardToken];
    }

    function getTotalClaimedByTokenAddress() public view returns (uint256 ) {
        return totalClaimed[RewardToken];
    }

    function getTotalSharesByTokenAddress() public view returns (uint256 ) {
        return totalShares[RewardToken];
    }
}