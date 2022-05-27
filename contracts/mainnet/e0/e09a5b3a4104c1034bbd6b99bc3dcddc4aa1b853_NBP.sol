// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";
import "./ERC721.sol";
import "./DydxFlashloanBase.sol";
import "./IWETHGateway.sol";

contract Constants {
    //bytes32 internal constant _permissionless_  = 'permissionless';
    //uint internal constant MAX_FEE_RATE      = 0.10 ether;   // 10%

    bytes32 internal constant _GemSwap_         = "GemSwap";

    address internal constant _dYdX_SoloMargin_ = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address internal constant _WETH_            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant _BEND_            = 0x0d02755a5700414B26FF040e1dE35D337DF56218;
    address internal constant _bendWETHGateway_ = 0x3B968D2D299B895A5Fcf3BBa7A64ad0F566e6F88;
    address internal constant _bendDebtWETH_    = 0x87ddE3A3f4b629E389ce5894c9A1F34A7eeC5648;
    //address internal constant _bendWETH_        = 0xeD1840223484483C0cb050E6fC344d1eBF0778a9;
    //address internal constant _LendPoolAddressesProvider_ = 0x24451F47CaF13B24f4b5034e1dF6c0E401ec0e46;
    //address internal constant _bendLendPool_    = 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762;
    address internal constant _bendLendPoolLoan_= 0x5f6ac80CdB9E87f3Cfa6a90E5140B9a16A361d5C;
    address internal constant _bendIncentives_  = 0x26FC1f11E612366d3367fc0cbFfF9e819da91C8d;   // BendProtocolIncentivesController

    address internal constant _NPics_           = 0xA2f78200746F73662ea8b5b721fDA86CB0880F15;
    address internal constant _BeaconProxyNBP_  = 0x70643f0DFbA856071D335678dF7ED332FFd6e3be;
    bytes32 internal constant _SHARD_NEO_       = 0;
    bytes32 internal constant _SHARD_NBP_       = bytes32(uint(1));

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
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
    //using SafeERC20 for IERC20;
    using SafeMath for uint;
    //using Strings for uint;
    
    address payable public beacon;
    address public nft;
    uint public tokenId;

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
        assets[0] = _bendDebtWETH_;
        amt = IBendIncentives(_bendIncentives_).claimRewards(assets, uint(-1));
        IERC20(_BEND_).transfer(to, amt);
    }

    function downPayWithETH(TradeDetails[] memory tradeDetails, uint loanAmt) public payable onlyBeacon {
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
        operations[1] = _getCallAction(
            abi.encode(tradeDetails, loanAmt)
        );
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
        (TradeDetails[] memory tradeDetails, uint loanAmt) = abi.decode(data, (TradeDetails[], uint));
        uint balOfLoanedToken = IERC20(_WETH_).balanceOf(address(this));
        WETH9(_WETH_).withdraw(balOfLoanedToken);
        require(address(this).balance >= tradeDetails[0].value, "Insufficient downPay+flashLoan to batchBuyWithETH");

        require(IERC721(nft).ownerOf(tokenId) != address(this), "nbp owned the nft already");
        IGemSwap(NPics(beacon).getConfig(_GemSwap_)).batchBuyWithETH{value: address(this).balance}(tradeDetails);
        require(IERC721(nft).ownerOf(tokenId) == address(this), "nbp not owned the nft yet");

        IERC721(nft).approve(_bendWETHGateway_, tokenId);
        IDebtToken(_bendDebtWETH_).approveDelegation(_bendWETHGateway_, uint(-1));
        IWETHGateway(_bendWETHGateway_).borrowETH(loanAmt, nft, tokenId, address(this), 0);

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
    uint[47] private ______gap;
}

contract NPics is Configurable, ReentrancyGuardUpgradeSafe, ContextUpgradeSafe, Constants {
    //using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address;

    //address public implementation;
    function implementation() public view returns(address) {  return implementations[0];  }
    mapping (bytes32 => address) public implementations;

    mapping (address => address) public neos;     // uft => neo
    address[] public neoA;
    function neoN() external view returns (uint) {  return neoA.length;  }
    
    mapping(address => mapping(uint => address payable)) public nbps;     // uft => tokenId => nbp
    address[] public nbpA;
    function nbpN() external view returns (uint) {  return nbpA.length;  }
    
    function __NPics_init(address governor, address implNEO, address implNBP) public initializer {
        __Governable_init_unchained(governor);
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __NPics_init_unchained(implNEO, implNBP);
    }

    function __NPics_init_unchained(address implNEO, address implNBP) internal initializer {
        upgradeImplementationTo(implNEO, implNBP);
        config[_GemSwap_]               = uint(0x83C8F28c26bF6aaca652Df1DbBE0e1b56F8baBa2);
    }
    
    function upgradeImplementationTo(address implNEO, address implNBP) public governance {
        implementations[_SHARD_NEO_]    = implNEO;
        implementations[_SHARD_NBP_]    = implNBP;
    }
    
    function createNEO(address nft) public returns (address neo) {
        //require(config[_permissionless_] != 0 || _msgSender() == governor);
        //require(nft != address(0), 'ZERO_ADDRESS');
        require(nft.isContract(), 'nft should isContract');
        require(IERC165(nft).supportsInterface(_INTERFACE_ID_ERC721), 'nft should supportsInterface(_INTERFACE_ID_ERC721)');

        require(neos[nft] == address(0), 'the NEO exist already');

        //bytes memory bytecode = type(InitializableBeaconProxy).creationCode;
        bytes memory bytecode = type(BeaconProxyNEO).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(nft));
        assembly {
            neo := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //InitializableBeaconProxy(payable(neo)).__InitializableBeaconProxy_init(address(this), _SHARD_NEO_, abi.encodeWithSignature('__NEO_init(address)', nft));
        NEO(neo).__NEO_init(nft);

        neos[nft] = neo;
        neoA.push(neo);
        emit CreateNEO(_msgSender(), nft, neo, neoA.length);
    }
    event CreateNEO(address indexed creator, address indexed nft, address indexed neo, uint count);

    function createNBP(address nft, uint tokenId) public returns (address payable nbp) {
        //require(config[_permissionless_] != 0 || _msgSender() == governor);
        //require(nft != address(0), 'ZERO_ADDRESS');
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

    function downPayWithETH(address nft, uint tokenId, TradeDetails[] memory tradeDetails, uint loanAmt) public payable nonReentrant {
        require(tradeDetails.length == 1, "tradeDetails.length != 1");
        require(msg.value.add(loanAmt) >= tradeDetails[0].value.add(2), "Insufficient down payment");

        address payable nbp = nbps[nft][tokenId];
        if(nbp == address(0))
            nbp = createNBP(nft, tokenId);
        NBP(nbp).downPayWithETH{value: msg.value}(tradeDetails, loanAmt);

        address neo = neos[nft];
        if(neo == address(0))
            neo = createNEO(nft);
        NEO(neo).mint_(_msgSender(), tokenId);

        emit DownPayWithETH(_msgSender(), nft, tokenId, msg.value.sub(address(this).balance), loanAmt);

        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
    }
    event DownPayWithETH(address indexed sender, address indexed nft, uint indexed tokenId, uint value, uint loanAmt);

    function downPayBatchBuyWithETH(address nft, uint tokenId, bytes memory dataBatchBuyWithETH, uint loanAmt) external payable {
        (bytes4 batchBuyWithETH, TradeDetails[] memory tradeDetails) = abi.decode(dataBatchBuyWithETH, (bytes4, TradeDetails[]));
        require(batchBuyWithETH == IGemSwap.batchBuyWithETH.selector, "not batchBuyWithETH.selector");
        downPayWithETH(nft, tokenId, tradeDetails, loanAmt);
    }

    function getLoanReserveBorrowAmount(address nftAsset, uint nftTokenId) public view returns(address reserveAsset, uint repayDebtAmount) {
        uint loanId = ILendPoolLoan(_bendLendPoolLoan_).getCollateralLoanId(nftAsset, nftTokenId);
        if(loanId == 0)
            return (address(0), 0);
        return ILendPoolLoan(_bendLendPoolLoan_).getLoanReserveBorrowAmount(loanId);
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
        if(amount > 0)
            (repayAmount, repayAll) = IWETHGateway(_bendWETHGateway_).repayETH{value: msg.value}(nftAsset, nftTokenId, amount);
        if(amount == 0 || repayAll) {
            NEO neo = NEO(neos[nftAsset]);
            require(address(neo) != address(0) && address(neo).isContract(), "INVALID neo");
            NBP(nbps[nftAsset][nftTokenId]).withdraw_(neo.ownerOf(nftTokenId));
            neo.burn_(nftTokenId);
        }

        emit RepayETH(_msgSender(), nftAsset, nftTokenId, repayAmount, repayAll);

        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
    }
    event RepayETH(address indexed sender, address indexed nftAsset, uint indexed nftTokenId, uint repayAmount, bool repayAll);

    function batchRepayETH(address[] calldata nftAssets, uint256[] calldata nftTokenIds, uint256[] calldata amounts) external payable nonReentrant returns(uint256[] memory repayAmounts, bool[] memory repayAlls) {
        (repayAmounts, repayAlls) = IWETHGateway(_bendWETHGateway_).batchRepayETH{value: msg.value}(nftAssets, nftTokenIds, amounts);
        for(uint i=0; i<repayAmounts.length; i++) {
            if(repayAlls[i]) {
                NEO neo = NEO(neos[nftAssets[i]]);
                require(address(neo) != address(0) && address(neo).isContract(), "INVALID neo");
                NBP(nbps[nftAssets[i]][nftTokenIds[i]]).withdraw_(neo.ownerOf(nftTokenIds[i]));
                neo.burn_(nftTokenIds[i]);
            }
            emit RepayETH(_msgSender(), nftAssets[i], nftTokenIds[i], repayAmounts[i], repayAlls[i]);
        }
        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
    }

    function getRewardsBalance(address user) external view returns(uint amt) {
        address[] memory assets = new address[](1);
        assets[0] = _bendDebtWETH_;
        for(uint i=0; i<neoA.length; i++) {
            NEO neo = NEO(neoA[i]);
            address nft = neo.nft();
            for(uint j=0; j<neo.balanceOf(user); j++) {
                address nbp = nbps[nft][neo.tokenOfOwnerByIndex(user, j)];
                amt = amt.add(IBendIncentives(_bendIncentives_).getRewardsBalance(assets, nbp));
            }
        }
    }

    function claimRewards() external returns(uint amt) {
        address user = _msgSender();
        for(uint i=0; i<neoA.length; i++) {
            NEO neo = NEO(neoA[i]);
            address nft = neo.nft();
            for(uint j=0; j<neo.balanceOf(user); j++) {
                address payable nbp = nbps[nft][neo.tokenOfOwnerByIndex(user, j)];
                amt = amt.add(NBP(nbp).claimRewardsTo_(user));
            }
        }
        emit RewardsClaimed(user, amt);
    }
    event RewardsClaimed(address indexed user, uint amount);

    receive () external payable {
        
    }

    // Reserved storage space to allow for layout changes in the future.
    uint[45] private ______gap;
}


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

struct TradeDetails {
    uint marketId;
    uint value;
    bytes tradeData;
}

interface IGemSwap {
    function batchBuyWithETH(TradeDetails[] memory tradeDetails) payable external;
}

interface IDebtToken {
    function approveDelegation(address delegatee, uint amount) external;
}

interface ILendPoolLoan {
    function getCollateralLoanId(address nftAsset, uint nftTokenId) external view returns(uint);
    function getLoanReserveBorrowAmount(uint loanId) external view returns(address, uint);
}

interface IBendIncentives {
    function getRewardsBalance(address[] calldata assets, address user) external view returns(uint);
    function claimRewards(address[] calldata assets, uint amount) external returns(uint);
}