/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// File: contracts/Presale.sol



pragma solidity ^0.8.16;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode
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
    require(newOwner != address(0), "Ownable: new owner is the zero address");
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

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Presale is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) public _contributions;

  IERC20 public _token;
  IERC20 public  _payment_token;
  uint256 private _tokenDecimals;
  uint256 private _weiRaised;
  uint256 public rate;
  uint256 public presaleRate;
  uint256 public hardCap;
  uint256 public softCap;
  uint256 public minPurchase;
  uint256 public maxPurchase;
  uint256 public liquidity;
  uint256 public startTime;
  uint256 public endICO;
  uint256 public availableTokensICO;
  uint256 public liqLock;
  uint256 public refundStartDate;

  bool public selectedFee = false;
  bool public autoListing = false;
  bool public iswhitelist = false;
  bool public refundType = true;

  address payable public _wallet;
  address public router;
  address[] public whitelist;
  mapping (address => bool) public existWhiteList;

//  Site info
  string public logoLink;
  string public webiste;
  string public facebook;
  string public twitter;
  string public github;
  string public telegram;
  string public instagram;
  string public discord;
  string public reddit;
  string public youtube;
  string public description;

  event TokensPurchased(
    address purchaser,
    uint256 value,
    uint256 amount
  );
  event Refund(address recipient, uint256 amount);

  constructor(
    address wallet,
    IERC20 token,
    IERC20 payToken,
    uint256 tokenDecimals,
    bool _selectFee,
    bool _autoListing,
    bool _iswhiteList
  ) {
    require(wallet != address(0), "Pre-Sale: wallet is the zero address");
    require(
      address(token) != address(0),
      "Pre-Sale: token is the zero address"
    );
    _payment_token = payToken;
    _wallet = payable (wallet);
    _token = token;
    _tokenDecimals = 18 - tokenDecimals;
    selectedFee = _selectFee;
    autoListing = _autoListing;
    iswhitelist = _iswhiteList;
  }
  // WhiteList1 for 800 USD
  function addWhiteList(address[] memory _buyers)
    external
    onlyOwner
    returns (bool)
  {
    require(iswhitelist, "you didn't sent whitelist option.");
    for (uint256 i; i < _buyers.length; i++) {
      whitelist.push(_buyers[i]);
      existWhiteList[_buyers[i]] = true;
    }
    return true;
  }
  function removeWhiteList(address[] memory _buyers)
    external
    onlyOwner
    returns (bool)
  {
    require(iswhitelist, "you didn't sent whitelist option.");
    for (uint256 i; i < _buyers.length; i++) {
      for(uint256 j; j< whitelist.length; j ++) {
        if (_buyers[i] == whitelist[j]) {
          delete whitelist[j];
          break ;
        }
      }
      existWhiteList[_buyers[i]] = false;
    }
    return true;
  }

  // site info: [logo url, website url, facebook, twitter, github, telegram, instagram, discord, reddit, youtube, description]
  function setSiteInfo(string[] calldata siteInfo) public onlyOwner {
      logoLink = siteInfo[0];
      webiste = siteInfo[1];
      facebook = siteInfo[2];
      twitter = siteInfo[3];
      github = siteInfo[4];
      telegram = siteInfo[5];
      instagram = siteInfo[6];
      discord = siteInfo[7];
      reddit = siteInfo[8];
      youtube = siteInfo[9];
      description = siteInfo[10];
  }

  //Start Pre-Sale
  // initial info: [startDate, endDate, rate, presalerate, softcap, hardcap, minpurchase, maxpurchase, liquidity, liqlock]
  // site info: [logo url, website url, facebook, twitter, github, telegram, instagram, discord, reddit, youtube, description]
  function startICO(
    uint256[] calldata initialInfo,
    string[] calldata siteInfo,
    bool _refundType,
    address __router
  ) external onlyOwner icoNotActive {
    require(initialInfo[1] > block.timestamp, "duration should be > 0");
    require(initialInfo[2] > 0, "Sale: rate is 0");
    require(initialInfo[3] > 0, "Pre-Sale: rate is 0");
    require(initialInfo[4] < initialInfo[5], "Softcap must be lower than Hardcap");
    require(
      initialInfo[6] < initialInfo[7],
      "minPurchase must be lower than maxPurchase"
    );

    startTime = initialInfo[0];
    endICO = initialInfo[1];
    rate = initialInfo[2];
    presaleRate = initialInfo[3];
    minPurchase = initialInfo[6];
    maxPurchase = initialInfo[7];
    softCap = initialInfo[4];
    hardCap = initialInfo[5];
    liquidity = initialInfo[8];
    liqLock = initialInfo[9];
    refundType = _refundType;
    router = __router;
    require(_token.totalSupply() > getTokenAmount(presaleRate * hardCap), "overflow total supply");
    _token.transfer(address(this), getTokenAmount(presaleRate * hardCap));
    availableTokensICO = _token.balanceOf(address(this));
    
    require(availableTokensICO > 0, "availableTokens must be > 0");
    require(initialInfo[6] > 0, "_minPurchase should > 0");
    _weiRaised = 0;
    setSiteInfo(siteInfo);
  }

  function stopICO() external onlyOwner icoActive {
    endICO = 0;
    _forwardFunds();
  }

  //Pre-Sale
  function buyTokens(uint256 _val)
    public
    payable
    nonReentrant
    icoActive
  {
    require(_val >= 0, "Below minimum allocation");
    require(_val >= minPurchase, "have to send at least: minPurchase");
    require(
      _contributions[msg.sender].add(_val) <= maxPurchase,
      "can't buy more than: maxPurchase"
    );
    require(iswhitelist && existWhiteList[msg.sender], "You are not whitelist");
    require((_weiRaised + _val) <= hardCap, "Hard Cap reached");
    uint256 tokens = getTokenAmount(_val);
    _weiRaised = _weiRaised.add(_val);
    availableTokensICO = availableTokensICO - tokens;
    _contributions[msg.sender] = _contributions[msg.sender].add(_val);
    _payment_token.transferFrom(msg.sender, address(this), _val);
    emit TokensPurchased(_msgSender(), _val, tokens);
  }

  function claimTokens() external icoNotActive {
    require(_contributions[msg.sender] > 0 , "Not enough amount to claim");
    uint256 tokensAmt = getTokenAmount(_contributions[msg.sender]);
    _contributions[msg.sender] = 0;
    _token.transfer(msg.sender, tokensAmt);
  }

  function getTokenAmount(uint256 weiAmount) public view returns (uint256) {
    return weiAmount.mul(presaleRate).div(10**_tokenDecimals);
  }

  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }

  function withdraw() external onlyTokenOwner icoNotActive {
    require(address(this).balance > 0, "Contract has no money");
    _wallet.transfer(address(this).balance);
  }

  function checkContribution(address addr) public view returns (uint256) {
    return _contributions[addr];
  }

  function setRate(uint256 newRate) external onlyTokenOwner icoNotActive {
    rate = newRate;
  }

  function setAvailableTokens(uint256 amount) public onlyTokenOwner icoNotActive {
    availableTokensICO = amount;
  }

  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

  function setWalletReceiver(address payable newWallet) external onlyTokenOwner {
    _wallet = newWallet;
  }

  function setHardCap(uint256 value) external onlyTokenOwner {
    hardCap = value;
  }

  function setSoftCap(uint256 value) external onlyTokenOwner {
    softCap = value;
  }

  function setMaxPurchase(uint256 value) external onlyTokenOwner {
    maxPurchase = value;
  }

  function setMinPurchase(uint256 value) external onlyTokenOwner {
    minPurchase = value;
  }

  function takeTokens(IERC20 tokenAddress) public onlyTokenOwner icoNotActive {
    IERC20 token_ = tokenAddress;
    uint256 tokenAmt = token_.balanceOf(address(this));
    require(tokenAmt > 0, "ERC20 balance is 0");
    token_.transfer(_wallet, tokenAmt);
  }
  function refundMe() public icoNotActive {
    uint256 amount = _contributions[msg.sender];
    if (_payment_token.balanceOf(address(this)) >= amount) {
      _contributions[msg.sender] = 0;
      if (amount > 0) {
        address payable recipient = payable(msg.sender);
        // recipient.transfer(amount);
        _payment_token.transferFrom(address(this), recipient, amount.mul(10).div(9));
        emit Refund(msg.sender, amount);
      }
    }
  }

  function saleLive() public view returns (bool) {
    return endICO > 0 && block.timestamp < endICO && availableTokensICO > 0;
  }

  function forward(address token_, uint256 amount_, address wallet_) public onlyTokenOwner icoNotActive returns (bool) {
      require(token_ != address(0), "Zero address");
      require(amount_ > 0, "Zero amount");
      require(wallet_ != address(0), "Zero address");

      IERC20(token_).transfer(wallet_, amount_);

      return true;
  }

  modifier icoActive() {
    require(
      startTime > 0 && startTime < block.timestamp && endICO > 0 && block.timestamp < endICO && availableTokensICO > 0,
      "ICO must be active"
    );
    _;
  }
  modifier onlyTokenOwner() {
    require(msg.sender == _wallet, "Admin can withdraw only");
    _;
  }
  modifier icoNotActive() {
    require(endICO < block.timestamp, "ICO should not be active");
    _;
  }
}

// File: contracts/factories.sol



pragma solidity ^0.8.16;


contract PresaleFactories is Ownable {
    address private adminWallet;
    mapping(address => Presale[]) public presaleforOwner;
    Presale[] public presaleList;
    uint256 private pricePresale = 0.01 ether;
    function setAdminWallet (address _wallet) public onlyOwner {
        adminWallet = _wallet;
    }
    function setPricepresale(uint256 _price) public onlyOwner {
        pricePresale = _price;
    }

    function CreateNewPresale(
        address _token,
        address _payToken,
        uint256 _tokenDecimals,
        bool[] calldata _info1,
        uint256[] calldata initialInfo,
        string[] calldata siteInfo,
        address __router
    ) public payable {
        require(msg.value >= pricePresale, "Amount is not enough");
        require(IERC20(_token).balanceOf(msg.sender) >= initialInfo[4] * initialInfo[3]* _tokenDecimals, "Not enough amount");
        Presale presale = new Presale(
            msg.sender,
            IERC20(_token),
            IERC20(_payToken),
            _tokenDecimals,
            _info1[0],
            _info1[1],
            _info1[3]
        );
        // IERC20(_token).transferFrom(msg.sender, 0xcdd0eB801c70Ff7771D179122B10fb1c247E7D76, initialInfo[4] * initialInfo[3]* 10**_tokenDecimals);
        presale.startICO(initialInfo, siteInfo, _info1[2], __router);
        presaleList.push(presale);
        presaleforOwner[msg.sender].push(presale);
    }

    function getPresaleList() public view returns (Presale[] memory) {
        return presaleList;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Contract has no money");
        payable (adminWallet).transfer(address(this).balance);
    }
}