/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/* --------- Access Control --------- */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claimable is Ownable {
    bool isclaimable = false;
    
    function startClaim()
        external
        onlyOwner
    {
        isclaimable = true;
    }

    function stopClaim()
        external
        onlyOwner
    {
        isclaimable = false;
    }


    function getClaimStatus()
        external view returns(bool)
    {
        return isclaimable;
    }

    modifier isClaim() {
        require(isclaimable, "Claim is not available now.");
        _;
    }

    function claimToken(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function claimETH(uint256 amount) external onlyOwner {
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}


contract Presale is Claimable {
    event Buy(address to, uint256 amount);
    event Claim(address to, uint256 amount);
    address public tokenAddress;
    uint256 price;
    uint256 public startTime;
    uint256 public totalSaled;

    address aggregatorInterface = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address USDTInterface = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 public baseDecimal = 1000000;

    mapping(address => uint256) public userDeposits;

    constructor(
        address _tokenAddress,
        uint256 _price
    ) {
        tokenAddress = _tokenAddress;
        price = _price;
        startTime = block.timestamp;
        totalSaled = 0;
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 ethPrice, , , ) = Aggregator(aggregatorInterface).latestRoundData();
        ethPrice = (ethPrice * (10 ** 10));
        return uint256(ethPrice);
    }

    function ethBuyHelper(
        uint256 ethAmount
    ) public view returns (uint256 amount) {
        amount = ethAmount * getLatestPrice() * price/(1e6  * 10 **18) ;
    }

    function resetPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    function resetStartTime() public onlyOwner {
        startTime = block.timestamp;
    }

    function buy() public payable {
        uint256 tokenAmount = ethBuyHelper(msg.value);
        userDeposits[_msgSender()] += tokenAmount;
        totalSaled += tokenAmount;
        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit Buy(msg.sender, tokenAmount);
    }

    function claimUserToken() public isClaim {
        require(userDeposits[_msgSender()] >= 0, "Please buy token.");
        IERC20(tokenAddress).transfer(msg.sender, userDeposits[_msgSender()]);
        userDeposits[_msgSender()] = 0;
        emit Claim(msg.sender, userDeposits[_msgSender()]);
    }

    function getClaimAmount(address userAddress) public view returns (uint256 claimAmount) {
        claimAmount = userDeposits[userAddress];
    }

    function usdtBuyHelper(
        uint256 usdPrice
    ) public view returns (uint256 amount) {
        amount = usdPrice * price/baseDecimal ;
    }

    function buyWithUSDT(
        uint256 usdtPrice
    ) external returns (bool) {
        uint256 amount = usdtBuyHelper(usdtPrice);
        totalSaled += amount;
        uint256 ourAllowance = IERC20(USDTInterface).allowance(
            _msgSender(),
            address(this)
        );
        require(usdtPrice <= ourAllowance, "Make sure to add enough allowance");
        userDeposits[_msgSender()] += amount;        
        return true;
    }

    function getPrice() public view returns (uint256 tokenPrice) {
        tokenPrice = price;
    }

    receive() external payable {
        buy();
    }

    fallback() external payable {
        buy();
    }
}