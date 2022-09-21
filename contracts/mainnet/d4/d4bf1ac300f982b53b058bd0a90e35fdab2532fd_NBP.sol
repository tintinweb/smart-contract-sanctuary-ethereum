// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";
import "./ERC721.sol";
import "./DydxFlashloanBase.sol";
import "./IWETHGateway.sol";

contract Constants {
    address private  constant _BEND_            = 0x0d02755a5700414B26FF040e1dE35D337DF56218;
    address private  constant _bendWETHGateway_ = 0x3B968D2D299B895A5Fcf3BBa7A64ad0F566e6F88;
    address private  constant _bendDebtWETH_    = 0x87ddE3A3f4b629E389ce5894c9A1F34A7eeC5648;
    //address private  constant _bendWETH_        = 0xeD1840223484483C0cb050E6fC344d1eBF0778a9;
    address private  constant _bendAddrProvider_= 0x24451F47CaF13B24f4b5034e1dF6c0E401ec0e46;   // LendPoolAddressesProvider
    //address private  constant _bendLendPool_    = 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762;
    //address private  constant _bendLendPoolLoan_= 0x5f6ac80CdB9E87f3Cfa6a90E5140B9a16A361d5C;
    //address private  constant _bendIncentives_  = 0x26FC1f11E612366d3367fc0cbFfF9e819da91C8d;   // BendProtocolIncentivesController

    address private  constant _pWING_           = 0xDb0f18081b505A7DE20B18ac41856BCB4Ba86A1a;
    address private  constant _wingWETHGateway_ = 0x5304E9188B6e2C4988f230b3D1C4786d9e05fAdB;
    address private  constant _wingDebtWETH_    = 0xdB3856B8aBbb2A090607e8Da3949aFd5B8bC3273;
    //address private  constant _wingWETH_        = ;
    address private  constant _wingAddrProvider_= 0x8815e486Fb446E954497358582deCd9fb3451Ec6;   // LendPoolAddressesProvider
    //address private  constant _wingLendPool_    = 0xCDeF080e2Fb957f2F5334334fd7b69d069acA136;
    //address private  constant _wingLendPoolLoan_= 0x5A05fC74Db8217f3783B75DEE9932d9a896ECEa4;
    //address private  constant _wingIncentives_  = 0x750B9848b8f4956A41F6822F53aC1f80B4486bDE;   // WingProtocolIncentivesController

    function _bankToken         (uint bank) internal pure returns (address) {  if(bank == 0)  return _BEND_;             else if(bank == 1)  return _pWING_;             else  return address(0);  }
    function _bankWETHGateway   (uint bank) internal pure returns (address) {  if(bank == 0)  return _bendWETHGateway_;  else if(bank == 1)  return _wingWETHGateway_;   else  return address(0);  }
    function _bankDebtWETH      (uint bank) internal pure returns (address) {  if(bank == 0)  return _bendDebtWETH_;     else if(bank == 1)  return _wingDebtWETH_;      else  return address(0);  }
    function _bankAddrProvider  (uint bank) internal pure returns (address) {  if(bank == 0)  return _bendAddrProvider_; else if(bank == 1)  return _wingAddrProvider_;  else  return address(0);  }
    //function _bankLendPool      (uint bank) internal pure returns (address) {  if(bank == 0)  return _bendLendPool_;     else if(bank == 1)  return _wingLendPool_;      else  return address(0);  }
    //function _bankLendPoolLoan  (uint bank) internal pure returns (address) {  if(bank == 0)  return _bendLendPoolLoan_; else if(bank == 1)  return _wingLendPoolLoan_;  else  return address(0);  }
    //function _bankIncentives    (uint bank) internal pure returns (address) {  if(bank == 0)  return _bendIncentives_;   else if(bank == 1)  return _wingIncentives_;    else  return address(0);  }

    address internal constant _dYdX_SoloMargin_ = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address internal constant _WETH_            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant _NPics_           = 0xA2f78200746F73662ea8b5b721fDA86CB0880F15;
    address internal constant _BeaconProxyNBP_  = 0x70643f0DFbA856071D335678dF7ED332FFd6e3be;
    bytes32 internal constant _SHARD_NEO_       = 0;
    bytes32 internal constant _SHARD_NBP_       = bytes32(uint(1));

    bytes32 internal constant _fee_             = "fee";
    bytes32 internal constant _feeTo_           = "feeTo";
    bytes32 internal constant _allowMS_         = "allowMS";

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    function _callRevertMessgae(bytes memory result) internal pure returns(string memory) {
        if (result.length < 68)
            return "";
        assembly {
            result := add(result, 0x04)
        }
        return abi.decode(result, (string));
    }
}

contract NEO is ERC721UpgradeSafe, Constants {      // NFT Everlasting Options
    //using SafeERC20 for IERC20;
    //using SafeMath for uint;
    //using Strings for uint;
    
    address payable public beacon;
    address public nft;

    function __NEO_init(address nft_) external initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        (string memory name, string memory symbol) = spellNameAndSymbol(nft_);
        __ERC721_init_unchained(name, symbol);
        __NEO_init_unchained(nft_);
    }

    function __NEO_init_unchained(address nft_) internal initializer {
        beacon = _msgSender();
        nft = nft_;
    }

    function spellNameAndSymbol(address nft_) public view returns (string memory name, string memory symbol) {
        name = string(abi.encodePacked("NPics.xyz NFT Everlasting Options ", IERC721Metadata(nft_).symbol()));
        symbol = string(abi.encodePacked("neo", IERC721Metadata(nft_).symbol()));
    }

    function setNameAndSymbol(string memory name, string memory symbol) external {
        require(_msgSender() == NPics(beacon).governor() || _msgSender() == __AdminUpgradeabilityProxy__(beacon).__admin__());
        _name = name;
        _symbol = symbol;
    }

    modifier onlyBeacon {
        require(_msgSender() == beacon, 'Only Beacon');
        _;
    }
    
    function transfer_(address sender, address recipient, uint tokenId) external onlyBeacon {
        _transfer(sender, recipient, tokenId);
    }
    
    function mint_(address to, uint tokenId) external onlyBeacon {
        _mint(to, tokenId);
        _setTokenURI(tokenId, IERC721Metadata(nft).tokenURI(tokenId));
    }
    
    function burn_(uint tokenId) external onlyBeacon {
        _burn(tokenId);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint[48] private ______gap;
}

contract NBP is DydxFlashloanBase, ICallee, IERC721Receiver, ReentrancyGuardUpgradeSafe, ContextUpgradeSafe, Constants {      // NFT Backed Position
    using SafeMath for uint;
    using Address for address;
    
    address payable public beacon;
    address public nft;
    uint public tokenId;
    uint public bankId;

    function __NBP_init(address nft_, uint tokenId_) external initializer {
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __NBP_init_unchained(nft_, tokenId_);
    }

    function __NBP_init_unchained(address nft_, uint tokenId_) internal initializer {
        beacon = _msgSender();
        nft = nft_;
        tokenId = tokenId_;
    }

    modifier onlyBeacon {
        require(_msgSender() == beacon, 'Only Beacon');
        _;
    }
    
    function withdraw_(address to) external onlyBeacon {
        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
    }

    function claimRewardsTo_(address to) external onlyBeacon returns(uint amt) {
        address[] memory assets = new address[](1);
        assets[0] = _bankDebtWETH(bankId);
        IBendIncentives(ILendPoolAddressesProvider(_bankAddrProvider(bankId)).getIncentivesController()).claimRewards(assets, uint(-1));
        amt = IERC20(_bankToken(bankId)).balanceOf(address(this));
        IERC20(_bankToken(bankId)).transfer(to, amt);
    }

    function downPayWithETH_(address market, bytes calldata data, uint price, uint loanAmt, uint bank) external payable onlyBeacon {
        bankId = bank;
        _flashLoan(abi.encode(msg.sig, market, data, price, loanAmt));
    }

    function acceptOffer_(address market, bytes calldata data, address approveTo) external onlyBeacon {
        _flashLoan(abi.encode(msg.sig, market, data, approveTo));
    }

    function _flashLoan(bytes memory data) internal {
        address _solo = _dYdX_SoloMargin_;
        address _token = _WETH_;
        // Get marketId from token address
        uint marketId = _getMarketIdFromTokenAddress(_solo, _token);

        uint _amount = IERC20(_token).balanceOf(_solo);
        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint repayAmount = _amount.add(2);   //_getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(_solo, repayAmount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(data);
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        ISoloMargin(_solo).operate(accountInfos, operations);

        //emit DownPay(_msgSender(), nft, tokenId, msg.value.sub(address(this).balance), loanAmt);

        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) override external {
        require(_msgSender() == _dYdX_SoloMargin_ && sender == address(this) && account.owner == address(this) && account.number == 1, "callFunction param check fail");
        bytes4 sig = abi.decode(data, (bytes4));
        if(sig == this.downPayWithETH_.selector)
            _downPayWithETH(data);
        else if(sig == this.acceptOffer_.selector)
            _acceptOffer(data);
        else
            revert("callFunction INVALID selector");
    }

    function _downPayWithETH(bytes memory data) internal {
        (, address market, bytes memory data_, uint price, uint loanAmt) = abi.decode(data, (bytes4, address, bytes, uint, uint));
        uint balOfLoanedToken = IERC20(_WETH_).balanceOf(address(this));
        WETH9(_WETH_).withdraw(balOfLoanedToken);
        require(address(this).balance >= price, "Insufficient downPay+flashLoan < price");

        require(IERC721(nft).ownerOf(tokenId) != address(this), "nbp owned the nft already");
        require(market.isContract(), "market.isContract == false");
        (bool success, bytes memory result) = market.call{value: price}(data_);
        require(success, string(abi.encodePacked("call market.buy failure : ", _callRevertMessgae(result))));
        require(IERC721(nft).ownerOf(tokenId) == address(this), "nbp not owned the nft yet");

        IERC721(nft).approve(_bankWETHGateway(bankId), tokenId);
        IDebtToken(_bankDebtWETH(bankId)).approveDelegation(_bankWETHGateway(bankId), uint(-1));
        IWETHGateway(_bankWETHGateway(bankId)).borrowETH(loanAmt, nft, tokenId, address(this), 0);

        require(address(this).balance >= balOfLoanedToken.add(2), "Insufficient balance to repay flashLoan");
        WETH9(_WETH_).deposit{value: balOfLoanedToken.add(2)}();
    }

    function _acceptOffer(bytes memory data) internal {
        (, address market, bytes memory data_, address approveTo) = abi.decode(data, (bytes4, address, bytes, address));
        uint balOfLoanedToken = IERC20(_WETH_).balanceOf(address(this));
        WETH9(_WETH_).withdraw(balOfLoanedToken);

        (, bool repayAll) = IWETHGateway(_bankWETHGateway(bankId)).repayETH{value: balOfLoanedToken}(nft, tokenId, balOfLoanedToken);
        require(repayAll, "Insufficient flashLoan < repayDebt");
        require(IERC721(nft).ownerOf(tokenId) == address(this), "nbp not owned the nft yet");

        IERC721(nft).transferFrom(address(this), beacon, tokenId);
        NPics(beacon).acceptOffer_(nft, tokenId, market, data_, approveTo);
        WETH9(_WETH_).withdraw(IERC20(_WETH_).balanceOf(address(this)));

        require(address(this).balance >= balOfLoanedToken.add(2), "Insufficient balance to repay flashLoan");
        WETH9(_WETH_).deposit{value: balOfLoanedToken.add(2)}();
    }

    function onERC721Received(address operator, address from, uint tokenId_, bytes calldata data) override external returns (bytes4) {
        operator;
        from;
        data;

        if(tokenId_ == tokenId)
            return this.onERC721Received.selector;
        else
            return 0;
    }

    receive () external payable {

    }

    // Reserved storage space to allow for layout changes in the future.
    uint[46] private ______gap;
}

contract NPics is Configurable, ReentrancyGuardUpgradeSafe, ContextUpgradeSafe, Constants {
    //using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address;
    using Address for address payable;

    //address public implementation;
    function implementation() public view returns(address) {  return implementations[0];  }
    mapping (bytes32 => address) public implementations;

    mapping (address => address) public neos;     // nft => neo
    address[] public neoA;
    function neoN() external view returns (uint) {  return neoA.length;  }
    
    mapping(address => mapping(uint => address payable)) public nbps;     // nft => tokenId => nbp
    address[] public nbpA;
    function nbpN() external view returns (uint) {  return nbpA.length;  }
    
    function __NPics_init(address governor, address implNEO, address implNBP) public initializer {
        __Governable_init_unchained(governor);
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __NPics_init_unchained(implNEO, implNBP);
    }

    function __NPics_init_unchained(address implNEO, address implNBP) internal initializer {
        config[_fee_]   = 0.02e18;      //2%
        config[_feeTo_] = uint(0xc5dAe1a5fB39C4DC57713Bcb9cF936B99a173a32);
        upgradeImplementationTo(implNEO, implNBP);
    }
    
    function upgradeImplementationTo(address implNEO, address implNBP) public governance {
        implementations[_SHARD_NEO_]    = implNEO;
        implementations[_SHARD_NBP_]    = implNBP;
    }
    
    function createNEO(address nft) public returns (address neo) {
        require(nft.isContract(), 'nft should isContract');
        require(IERC165(nft).supportsInterface(_INTERFACE_ID_ERC721), 'nft should supportsInterface(_INTERFACE_ID_ERC721)');

        require(neos[nft] == address(0), 'the NEO exist already');

        bytes memory bytecode = type(BeaconProxyNEO).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(nft));
        assembly {
            neo := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        NEO(neo).__NEO_init(nft);

        neos[nft] = neo;
        neoA.push(neo);
        emit CreateNEO(_msgSender(), nft, neo, neoA.length);
    }
    event CreateNEO(address indexed creator, address indexed nft, address indexed neo, uint count);

    function createNBP(address nft, uint tokenId) public returns (address payable nbp) {
        require(nft.isContract(), 'nft should isContract');
        require(IERC165(nft).supportsInterface(_INTERFACE_ID_ERC721), 'nft should supportsInterface(_INTERFACE_ID_ERC721)');

        require(nbps[nft][tokenId] == address(0), 'the NBP exist already');

        bytes32 salt = keccak256(abi.encodePacked(nft, tokenId));
        nbp = payable(Clones.cloneDeterministic(_BeaconProxyNBP_, salt));
        NBP(nbp).__NBP_init(nft, tokenId);

        nbps[nft][tokenId] = nbp;
        nbpA.push(nbp);
        emit CreateNBP(_msgSender(), nft, tokenId, nbp, nbpA.length);
    }
    event CreateNBP(address indexed creator, address indexed nft, uint indexed tokenId, address nbp, uint count);

    // calculates the CREATE2 address for a neo without making any external calls
    function neoFor(address nft) public view returns (address neo) {
        neo = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(nft)),
                keccak256(abi.encodePacked(type(BeaconProxyNEO).creationCode))
            ))));
    }

    // return neos if neo exist, or else return neoFor
    function getNeoFor(address nft) public view returns (address neo) {
        neo = neos[nft];
        if(neo == address(0))
            neo = neoFor(nft);
    }
    
    // calculates the CREATE2 address for a nbp without making any external calls
    function nbpFor(address nft, uint tokenId) public view returns (address nbp) {
        bytes32 salt = keccak256(abi.encodePacked(nft, tokenId));
        nbp = Clones.predictDeterministicAddress(_BeaconProxyNBP_, salt);
    }

    // return nbps if nbp exist, or else return nbpFor
    function getNbpFor(address nft, uint tokenId) public view returns (address nbp) {
        nbp = nbps[nft][tokenId];
        if(nbp == address(0))
            nbp = nbpFor(nft, tokenId);
    }
    

    function availableBorrowsInETH(address nft) external view returns(uint) {
        return availableBorrowsInETH(nft, 0);
    }
    function availableBorrowsInETH(address nft, uint bank) public view returns(uint r) {
        (, , r, , , ,) = ILendPool(ILendPoolAddressesProvider(_bankAddrProvider(bank)).getLendPool()).getNftCollateralData(nft, _WETH_);
    }

    function downPayWithETH(address nft, uint tokenId, address market, bytes calldata data, uint price, uint loanAmt) external payable {
        downPayWithETH(nft, tokenId, market, data, price, loanAmt, 0);
    }
    function downPayWithETH(address nft, uint tokenId, address market, bytes calldata data, uint price, uint loanAmt, uint bank) public payable nonReentrant {
        _checkMarketSig(market, data, msg.sig);
        require(loanAmt <= availableBorrowsInETH(nft, bank), "Too much borrowETH");
        uint value = address(this).balance;
        require(value.add(loanAmt) >= price.add(2), "Insufficient down payment");

        address payable nbp = nbps[nft][tokenId];
        if(nbp == address(0))
            nbp = createNBP(nft, tokenId);
        NBP(nbp).downPayWithETH_{value: value}(market, data, price, loanAmt, bank);

        address neo = neos[nft];
        if(neo == address(0))
            neo = createNEO(nft);
        NEO(neo).mint_(_msgSender(), tokenId);

        emit DownPayWithETH(_msgSender(), nft, tokenId, value.sub(address(this).balance), loanAmt);

        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
    }
    event DownPayWithETH(address indexed sender, address indexed nft, uint indexed tokenId, uint value, uint loanAmt);

    function downPayWithWETH(address nft, uint tokenId, address market, bytes calldata data, uint price, uint loanAmt, uint wethAmt) external payable {
        downPayWithWETH(nft, tokenId, market, data, price, loanAmt, wethAmt, 0);
    }
    function downPayWithWETH(address nft, uint tokenId, address market, bytes calldata data, uint price, uint loanAmt, uint wethAmt, uint bank) public payable {
        require(wethAmt >= IERC20(_WETH_).balanceOf(_msgSender()), "Insufficient WETH");
        IERC20(_WETH_).transferFrom(_msgSender(), address(this), wethAmt);
        WETH9(_WETH_).withdraw(wethAmt);
        downPayWithETH(nft, tokenId, market, data, price, loanAmt, bank);
    }

    function getLoanReserveBorrowAmount(address nftAsset, uint nftTokenId) public view returns(address reserveAsset, uint repayDebtAmount) {
        NBP nbp = NBP(nbps[nftAsset][nftTokenId]);
        require(address(nbp) != address(0) && address(nbp).isContract(), "INVALID nbp");
        uint bank = NBP(nbp).bankId();
        address lendPoolLoan = ILendPoolAddressesProvider(_bankAddrProvider(bank)).getLendPoolLoan();
        uint loanId = ILendPoolLoan(lendPoolLoan).getCollateralLoanId(nftAsset, nftTokenId);
        if(loanId == 0)
            return (address(0), 0);
        return ILendPoolLoan(lendPoolLoan).getLoanReserveBorrowAmount(loanId);
    }

    function getDebtWEthOf(address user) external view returns(uint amt) {
        for(uint i=0; i<neoA.length; i++) {
            NEO neo = NEO(neoA[i]);
            address nft = neo.nft();
            for(uint j=0; j<neo.balanceOf(user); j++) {
                (address reserveAsset, uint repayDebtAmount) = getLoanReserveBorrowAmount(nft, neo.tokenOfOwnerByIndex(user, j));
                if(reserveAsset == _WETH_)
                    amt = amt.add(repayDebtAmount);
            }
        }
    }
    
    function repayETH(address nftAsset, uint nftTokenId, uint amount) external payable nonReentrant returns(uint repayAmount, bool repayAll) {
        NBP nbp = NBP(nbps[nftAsset][nftTokenId]);
        require(address(nbp) != address(0) && address(nbp).isContract(), "INVALID nbp");
        if(amount > 0)
            (repayAmount, repayAll) = IWETHGateway(_bankWETHGateway(nbp.bankId())).repayETH{value: msg.value}(nftAsset, nftTokenId, amount);
        if(amount == 0 || repayAll) {
            NEO neo = NEO(neos[nftAsset]);
            require(address(neo) != address(0) && address(neo).isContract(), "INVALID neo");
            address user = neo.ownerOf(nftTokenId);
            uint rwd = nbp.claimRewardsTo_(user);
            emit RewardsClaimed(user, rwd);
            nbp.withdraw_(user);
            neo.burn_(nftTokenId);
        }
        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
        emit RepayETH(_msgSender(), nftAsset, nftTokenId, repayAmount, repayAll);
    }
    event RepayETH(address indexed sender, address indexed nftAsset, uint indexed nftTokenId, uint repayAmount, bool repayAll);

    function batchRepayETH(address[] calldata nftAssets, uint256[] calldata nftTokenIds, uint256[] calldata amounts, uint bank) external payable nonReentrant returns(uint256[] memory repayAmounts, bool[] memory repayAlls) {
        (repayAmounts, repayAlls) = IWETHGateway(_bankWETHGateway(bank)).batchRepayETH{value: msg.value}(nftAssets, nftTokenIds, amounts);
        for(uint i=0; i<repayAmounts.length; i++) {
            if(repayAlls[i]) {
                NEO neo = NEO(neos[nftAssets[i]]);
                require(address(neo) != address(0) && address(neo).isContract(), "INVALID neo");
                address user = neo.ownerOf(nftTokenIds[i]);
                NBP nbp = NBP(nbps[nftAssets[i]][nftTokenIds[i]]);
                uint rwd = nbp.claimRewardsTo_(user);
                emit RewardsClaimed(user, rwd);
                nbp.withdraw_(user);
                neo.burn_(nftTokenIds[i]);
            }
            emit RepayETH(_msgSender(), nftAssets[i], nftTokenIds[i], repayAmounts[i], repayAlls[i]);
        }
        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
    }

    function getRewardsBalance(address user) external view returns(uint amt) {
        return getRewardsBalance(user, 0);
    }
    function getRewardsBalance(address user, uint bank) public view returns(uint amt) {
        address[] memory assets = new address[](1);
        assets[0] = _bankDebtWETH(bank);
        address incentives = ILendPoolAddressesProvider(_bankAddrProvider(bank)).getIncentivesController();
        for(uint i=0; i<neoA.length; i++) {
            NEO neo = NEO(neoA[i]);
            address nft = neo.nft();
            for(uint j=0; j<neo.balanceOf(user); j++) {
                address payable nbp = nbps[nft][neo.tokenOfOwnerByIndex(user, j)];
                if(NBP(nbp).bankId() == bank) {
                    amt = amt.add(IERC20(_bankToken(bank)).balanceOf(nbp));
                    amt = amt.add(IBendIncentives(incentives).getRewardsBalance(assets, nbp));
                }
            }
        }
    }

    function claimRewards() external returns(uint amt) {
        return claimRewards(0);
    }
    function claimRewards(uint bank) public returns(uint amt) {
        address user = _msgSender();
        for(uint i=0; i<neoA.length; i++) {
            NEO neo = NEO(neoA[i]);
            address nft = neo.nft();
            for(uint j=0; j<neo.balanceOf(user); j++) {
                address payable nbp = nbps[nft][neo.tokenOfOwnerByIndex(user, j)];
                if(NBP(nbp).bankId() == bank)
                    amt = amt.add(NBP(nbp).claimRewardsTo_(user));
            }
        }
        emit RewardsClaimed(user, amt);
    }
    event RewardsClaimed(address indexed user, uint amount);

    function acceptOffer(address nft, uint tokenId, address market, bytes calldata data, address approveTo) external nonReentrant {
        _checkMarketSig(market, data, msg.sig);
        address payable sender = _msgSender();
        NEO neo = NEO(neos[nft]);
        require(address(neo) != address(0) && address(neo).isContract(), "INVALID neo");
        require(sender == neo.ownerOf(tokenId), "Not owner");
        neo.burn_(tokenId);

        NBP nbp = NBP(nbps[nft][tokenId]);
        require(address(nbp) != address(0) && address(nbp).isContract(), "INVALID nbp");
        nbp.acceptOffer_(market, data, approveTo);
        uint rwd = nbp.claimRewardsTo_(sender);
        emit RewardsClaimed(sender, rwd);

        emit AcceptOffer(sender, nft, tokenId, address(this).balance);

        if(address(this).balance > 0)
            sender.transfer(address(this).balance);
    }
    event AcceptOffer(address indexed sender, address indexed nft, uint indexed tokenId, uint value);

    function acceptOffer_(address nft, uint tokenId, address market, bytes calldata data, address approveTo) external {
        require(msg.sender == nbps[nft][tokenId], 'Only nbp');
        IERC721(nft).approve(approveTo, tokenId);
        (bool success, bytes memory result) = market.call(data);
        require(success, string(abi.encodePacked("call market.acceptOffer failure : ", _callRevertMessgae(result))));
        if(config[_fee_] > 0 && config[_feeTo_] != 0)
            IERC20(_WETH_).transfer(address(config[_feeTo_]), IERC20(_WETH_).balanceOf(address(this)).mul(config[_fee_]).div(1e18));    
        IERC20(_WETH_).transfer(msg.sender, IERC20(_WETH_).balanceOf(address(this)));
    }

    function _checkMarketSig(address market, bytes calldata data, bytes4 sig) internal view {
        bytes4 sig_ = data[0] | bytes4(data[1]) >> 8 | bytes4(data[2]) >> 16 | bytes4(data[3]) >> 24;
        require(getConfigI(_allowMS_, (uint(market) << 32) ^ uint32(sig_)) & uint32(sig) == uint32(sig), "checkMarketSig failure");
    }

    receive () external payable {
        
    }

    // Reserved storage space to allow for layout changes in the future.
    uint[45] private ______gap;
}

//  https://docs.soliditylang.org/en/v0.6.12/types.html#array-slices
//  https://github.com/ethereum/solidity/issues/9439
//  https://github.com/ethereum/solidity/issues/6012
//  https://twitter.com/nicksdjohnson/status/1484344786878623744
//
//contract TestSig {
//    function getSig(bytes calldata data) public pure returns (bytes4) {
//        require(data.length >=32 && uint224(abi.decode(data, (uint))) == 0, "unlucky data");
//        return abi.decode(data, (bytes4));
//    }
//
//    function getSig1(bytes calldata data) public pure returns (bytes4) {
//        return abi.decode(abi.encodePacked(data[:4], bytes28(0)), (bytes4));
//    }
//
//    function getSig2(bytes calldata data) public pure returns (bytes4) {
//        return bytes4(uint32(abi.decode(abi.encodePacked(bytes28(0), data), (uint))));
//    }
//
//    function getSig3(bytes calldata data) public pure returns (bytes4) {
//        return data[0] | bytes4(data[1]) >> 8 | bytes4(data[2]) >> 16 | bytes4(data[3]) >> 24;
//    }
//
//    function getSig4(bytes memory data) public pure returns (bytes4 sig) {
//        assembly {
//            sig := mload(add(data, 32))
//        }
//    }
//}


contract BeaconProxyNEO is Proxy, Constants {
    function _implementation() virtual override internal view returns (address) {
        return IBeacon(_NPics_).implementations(_SHARD_NEO_);
  }
}

contract BeaconProxyNBP is Proxy, Constants {
    function _implementation() virtual override internal view returns (address) {
        return IBeacon(_NPics_).implementations(_SHARD_NBP_);
  }
}


interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IDebtToken {
    function approveDelegation(address delegatee, uint amount) external;
}

interface ILendPool {
  function getNftCollateralData(address nftAsset, address reserveAsset) external view returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    );
}

interface ILendPoolLoan {
    function getCollateralLoanId(address nftAsset, uint nftTokenId) external view returns(uint);
    function getLoanReserveBorrowAmount(uint loanId) external view returns(address, uint);
}

interface IBendIncentives {
    function getRewardsBalance(address[] calldata assets, address user) external view returns(uint);
    function claimRewards(address[] calldata assets, uint amount) external returns(uint);
}


/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(address indexed newAddress, bytes encodedCallData);
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy, bytes encodedCallData);
  event BNFTRegistryUpdated(address indexed newAddress);
  event LendPoolLiquidatorUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event BendDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(
    bytes32 id,
    address impl,
    bytes memory encodedCallData
  ) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendPool() external view returns (address);

  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  function getLendPoolConfigurator() external view returns (address);

  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getReserveOracle() external view returns (address);

  function setReserveOracle(address reserveOracle) external;

  function getNFTOracle() external view returns (address);

  function setNFTOracle(address nftOracle) external;

  function getLendPoolLoan() external view returns (address);

  function setLendPoolLoanImpl(address loan, bytes memory encodedCallData) external;

  function getBNFTRegistry() external view returns (address);

  function setBNFTRegistry(address factory) external;

  function getLendPoolLiquidator() external view returns (address);

  function setLendPoolLiquidator(address liquidator) external;

  function getIncentivesController() external view returns (address);

  function setIncentivesController(address controller) external;

  function getUIDataProvider() external view returns (address);

  function setUIDataProvider(address provider) external;

  function getBendDataProvider() external view returns (address);

  function setBendDataProvider(address provider) external;

  function getWalletBalanceProvider() external view returns (address);

  function setWalletBalanceProvider(address provider) external;
}