/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

contract IDOSale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public _contributions;

    IERC20 public _token;
    uint256 private _tokenDecimals;
    address payable public _wallet;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public hardCap;
    uint256 public maxPurchase;
    uint256 public availableTokensIDO;
    bool public startRefund = false;
    uint256 public refundStartDate;

    event TokensPurchased(
        address purchaser,
        address beneficiary,
        uint256 value,
        uint256 amount
    );
    event Refund(address recipient, uint256 amount);

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token,
        uint256 tokenDecimals
    ) {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(
            address(token) != address(0),
            "Pre-Sale: token is the zero address"
        );

        _rate = rate;
        _wallet = wallet;
        _token = token;
        _tokenDecimals = 18 - tokenDecimals;
    }

    // constructor() {
    //     _rate = 100;
    //     _wallet = payable(0xfD2Bd27E15F05A97865441AcfefDcA2842D3192C);
    //     _token = IERC20(0x04Fd3610ff1Bbd900f807F6ebe954738417C32E6);
    //     _tokenDecimals = 18;
    // }

    receive() external payable {
        if (endDate > 0 && block.timestamp < endDate) {
            buyTokens(_msgSender());
        } else {
            endDate = 0;
            revert("Pre-Sale is closed");
        }
    }

    //Start Pre-Sale
    function startIDO(
        uint256 start,
        uint256 end,
        uint256 _maxPurchase,
        uint256 _hardCap
    ) external onlyOwner idoNotActive {
        startRefund = false;
        refundStartDate = 0;
        availableTokensIDO = _token.balanceOf(address(this));
        require(start > block.timestamp, "start date should be > current time");
        require(end > startDate, "duration should be > 0");
        require(availableTokensIDO > 0, "availableTokens must be > 0");
        require(_maxPurchase > 0, "_maxPurchase should be > 0");
        require(_hardCap > 0, "_hardCap should be > 0");
        startDate = start;
        endDate = end;
        maxPurchase = _maxPurchase * 10**18;
        hardCap = _hardCap * 10**18;
        _weiRaised = 0;
    }

    function stopIDO() external onlyOwner idoActive {
        endDate = 0;
        refundStartDate = block.timestamp;
    }

    //Pre-Sale
    function buyTokens(address beneficiary)
        public
        payable
        nonReentrant
        idoActive
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensIDO = availableTokensIDO - tokens;
        _contributions[beneficiary] = _contributions[beneficiary].add(
            weiAmount
        );
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        require(
            beneficiary != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(
            _contributions[beneficiary].add(weiAmount) <= maxPurchase,
            "can't buy more than: maxPurchase"
        );
        require((_weiRaised + weiAmount) <= hardCap, "Hard Cap reached");
        this;
    }

    function claimTokens() external idoNotActive {
        require(startRefund == false);
        uint256 tokensAmt = _getTokenAmount(_contributions[msg.sender]);
        _contributions[msg.sender] = 0;
        _token.transfer(msg.sender, tokensAmt);
    }

    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        return weiAmount.mul(_rate).div(10**_tokenDecimals);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    function withdraw() external onlyOwner idoNotActive {
        require(
            startRefund == false || (refundStartDate + 3 days) < block.timestamp
        );
        require(address(this).balance > 0, "Contract has no money");
        _wallet.transfer(address(this).balance);
    }

    function checkContribution(address addr) public view returns (uint256) {
        return _contributions[addr];
    }

    function setRate(uint256 newRate) external onlyOwner idoNotActive {
        _rate = newRate;
    }

    function setAvailableTokens(uint256 amount) public onlyOwner idoNotActive {
        availableTokensIDO = amount;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function setWalletReceiver(address payable newWallet) external onlyOwner {
        _wallet = newWallet;
    }

    function setHardCap(uint256 value) external onlyOwner {
        hardCap = value;
    }

    function setMaxPurchase(uint256 value) external onlyOwner {
        maxPurchase = value;
    }

    function takeTokens(IERC20 tokenAddress) public onlyOwner idoNotActive {
        IERC20 tokenERC = tokenAddress;
        uint256 tokenAmt = tokenERC.balanceOf(address(this));
        require(tokenAmt > 0, "ERC-20 balance is 0");
        tokenERC.transfer(_wallet, tokenAmt);
    }

    function refundMe() public idoNotActive {
        require(startRefund == true, "no refund available");
        uint256 amount = _contributions[msg.sender];
        if (address(this).balance >= amount) {
            _contributions[msg.sender] = 0;
            if (amount > 0) {
                address payable recipient = payable(msg.sender);
                recipient.transfer(amount);
                emit Refund(msg.sender, amount);
            }
        }
    }

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    modifier idoActive() {
        require(
            startDate > 0 &&
                startDate < block.timestamp &&
                endDate > startDate &&
                endDate > 0 &&
                block.timestamp < endDate &&
                availableTokensIDO > 0,
            "IDO must be active"
        );
        _;
    }

    modifier idoNotActive() {
        require(endDate < block.timestamp, "IDO should not be active");
        _;
    }
}