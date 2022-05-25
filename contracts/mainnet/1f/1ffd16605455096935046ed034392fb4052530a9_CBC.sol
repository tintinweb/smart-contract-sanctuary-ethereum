// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";
import "./ERC721.sol";
import "./DydxFlashloanBase.sol";
import "./IWETHGateway.sol";

contract Constants {
    //bytes32 internal constant _permissionless_  = 'permissionless';
    //uint256 internal constant MAX_FEE_RATE      = 0.10 ether;   // 10%

    bytes32 internal constant _proxyCDP_        = "proxyCDP";
    bytes32 internal constant _GemSwap_         = "GemSwap";

    address internal constant _dYdX_SoloMargin_ = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    address internal constant _WETH_            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant _BendDAO_WETHGateway_ = 0x3B968D2D299B895A5Fcf3BBa7A64ad0F566e6F88;
    //address internal constant _BendDAO_LendPool_    = 0x70b97A0da65C15dfb0FFA02aEE6FA36e507C2762;
    
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
}

contract CBC is ERC721UpgradeSafe, Constants {      // Callable Bull Contract
    //using SafeERC20 for IERC20;
    //using SafeMath for uint;
    //using Strings for uint;
    
    address payable public beacon;
    address public nft;

    function __CBC_init(address nft_) external initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        (string memory name, string memory symbol) = spellNameAndSymbol(nft_);
        __ERC721_init_unchained(name, symbol);
        __CBC_init_unchained(nft_);
    }

    function __CBC_init_unchained(address nft_) internal initializer {
        beacon = _msgSender();
        nft = nft_;
    }

    function spellNameAndSymbol(address nft_) public view returns (string memory name, string memory symbol) {
        name = string(abi.encodePacked("NPics.xyz Callable Bull Contract ", IERC721Metadata(nft_).symbol()));
        symbol = string(abi.encodePacked("cbc", IERC721Metadata(nft_).symbol()));
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
    
    function transfer_(address sender, address recipient, uint256 tokenId) external onlyBeacon {
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
    uint256[48] private ______gap;
}

contract CDP is DydxFlashloanBase, ICallee, IERC721Receiver, ReentrancyGuardUpgradeSafe, ContextUpgradeSafe, Constants {      // Collateralized Debt Position
    //using SafeERC20 for IERC20;
    using SafeMath for uint;
    //using Strings for uint;
    
    address payable public beacon;
    address public nft;
    uint public tokenId;

    function __CDP_init(address nft_, uint tokenId_) external initializer {
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __CDP_init_unchained(nft_, tokenId_);
    }

    function __CDP_init_unchained(address nft_, uint tokenId_) internal initializer {
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

    function downPayWithETH(TradeDetails[] memory tradeDetails, uint loanAmt) public payable nonReentrant onlyBeacon {
        address _solo = _dYdX_SoloMargin_;
        address _token = _WETH_;
        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

        uint _amount = IERC20(_token).balanceOf(_solo);
        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _amount.add(2);   //_getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(_solo, repayAmount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            // Encode MyCustomData for callFunction
            //abi.encode(MyCustomData({token: _token, repayAmount: repayAmount}))
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
        uint256 balOfLoanedToken = IERC20(_WETH_).balanceOf(address(this));
        WETH9(_WETH_).withdraw(balOfLoanedToken);

        require(IERC721(nft).ownerOf(tokenId) != address(this), "cdp owned the nft already");
        IGemSwap(NPics(beacon).getConfig(_GemSwap_)).batchBuyWithETH{value: address(this).balance}(tradeDetails);
        require(IERC721(nft).ownerOf(tokenId) == address(this), "cdp not owned the nft yet");

        IERC721(nft).approve(_BendDAO_WETHGateway_, tokenId);
        IWETHGateway(_BendDAO_WETHGateway_).borrowETH(loanAmt, nft, tokenId, address(this), 0);

        WETH9(_WETH_).deposit{value: balOfLoanedToken.add(2)}();
    }

    function onERC721Received(address operator, address from, uint256 tokenId_, bytes calldata data) override external returns (bytes4) {
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
    uint256[47] private ______gap;
}

contract NPics is Configurable, ReentrancyGuardUpgradeSafe, ContextUpgradeSafe, Constants {
    //using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address;

    //address public implementation;
    function implementation() public view returns(address) {  return implementations[0];  }
    mapping (bytes32 => address) public implementations;

    mapping (address => address) public cbcs;     // uft => cbc
    address[] public cbcA;
    function cbcN() external view returns (uint) {  return cbcA.length;  }
    
    mapping(address => mapping(uint => address payable)) public cdps;     // uft => tokenId => cdp
    address[] public cdpA;
    function cdpN() external view returns (uint) {  return cdpA.length;  }
    
    function __NPics_init(address governor, address implCBC/*, address mintFeeTo, address swapRouter*/) public initializer {
        __Governable_init_unchained(governor);
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __NPics_init_unchained(implCBC/*, mintFeeTo, swapRouter*/);
    }

    function __NPics_init_unchained(address implCBC/*, address mintFeeTo, address swapRouter*/) public governance {
        implementations[0]  = implCBC;
        config[_proxyCDP_]              = uint(0xc5dAe1a5fB39C4DC57713Bcb9cF936B99a173a32);
        config[_GemSwap_]               = uint(0x83C8F28c26bF6aaca652Df1DbBE0e1b56F8baBa2);
    }
    
    function upgradeImplementationTo(address implCBC) external governance {
        implementations[0] = implCBC;
    }
    
    function createCBC(address nft) public returns (address cbc) {
        //require(config[_permissionless_] != 0 || _msgSender() == governor);
        //require(nft != address(0), 'ZERO_ADDRESS');
        require(nft.isContract(), 'nft should isContract');
        require(IERC165(nft).supportsInterface(_INTERFACE_ID_ERC721), 'nft should supportsInterface(_INTERFACE_ID_ERC721)');

        require(cbcs[nft] == address(0), 'the CBC exist already');

        bytes memory bytecode = type(InitializableBeaconProxy).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(nft));
        assembly {
            cbc := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        InitializableBeaconProxy(payable(cbc)).__InitializableBeaconProxy_init(address(this), 0, abi.encodeWithSignature('__CBC_init(address)', nft));

        cbcs[nft] = cbc;
        cbcA.push(cbc);
        emit CreateCBC(_msgSender(), nft, cbc, cbcA.length);
    }
    event CreateCBC(address indexed creator, address indexed nft, address indexed cbc, uint count);

    function createCDP(address nft, uint tokenId) public returns (address payable cdp) {
        //require(config[_permissionless_] != 0 || _msgSender() == governor);
        //require(nft != address(0), 'ZERO_ADDRESS');
        require(nft.isContract(), 'nft should isContract');
        require(IERC165(nft).supportsInterface(_INTERFACE_ID_ERC721), 'nft should supportsInterface(_INTERFACE_ID_ERC721)');

        require(cdps[nft][tokenId] == address(0), 'the CDP exist already');

        bytes32 salt = keccak256(abi.encodePacked(nft, tokenId));
        cdp = payable(Clones.cloneDeterministic(address(config[_proxyCDP_]), salt));
        CDP(cdp).__CDP_init(nft, tokenId);

        cdps[nft][tokenId] = cdp;
        cdpA.push(cdp);
        emit CreateCDP(_msgSender(), nft, tokenId, cdp, cdpA.length);
    }
    event CreateCDP(address indexed creator, address indexed nft, uint indexed tokenId, address cdp, uint count);

    function downPayWithETH(address nft, uint tokenId, TradeDetails[] memory tradeDetails, uint loanAmt) public payable nonReentrant {
        address payable cdp = cdps[nft][tokenId];
        if(cdp == address(0))
            cdp = createCDP(nft, tokenId);
        CDP(cdp).downPayWithETH{value: msg.value}(tradeDetails, loanAmt);

        address cbc = cbcs[nft];
        if(cbc == address(0))
            cbc = createCBC(nft);
        CBC(cbc).mint_(_msgSender(), tokenId);

        emit DownPay(_msgSender(), nft, tokenId, msg.value.sub(address(this).balance), loanAmt);

        if(address(this).balance > 0)
            _msgSender().transfer(address(this).balance);
    }
    event DownPay(address indexed sender, address indexed nft, uint indexed tokenId, uint value, uint loanAmt);

    receive () external payable {
        
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[45] private ______gap;
}


struct TradeDetails {
    uint256 marketId;
    uint256 value;
    bytes tradeData;
}

interface IGemSwap {
    function batchBuyWithETH(TradeDetails[] memory tradeDetails) payable external;
}

interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}