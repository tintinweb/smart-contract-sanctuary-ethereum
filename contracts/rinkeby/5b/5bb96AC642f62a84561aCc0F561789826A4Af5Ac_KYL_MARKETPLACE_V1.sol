///////////////////////////////////////////////////
// KYL WATCHES LTD // MARKETPLACE CONTRACT V.1.0 //
//////////////////////////////////////////////////////
// author: Valentino Kenpachi // Telegram: @valeken //
//////////////////////////////////////////////////////
// PER // ASPERA // AD // ASTRA //
//////////////////////////////////
// SPDX-License-Identifier: MIT //
//////////////////////////////////
pragma solidity ^0.8.3;
////////////////////////////////////////////////////////////////////////////////////
//###########%%%%%%%%%%%&%%%%#%%%%#%########((((((((((((##%%&&&&&&&&%#%%%%%%%%%%%%//
//###########%%%%%%%%%%%&%&%&&&&%%#%%%%%%%%%%#%###(((////////(#%&&&&%#%%%%%%%%%%%%//
//###########%%%%%%&&&&&&&&%&&&&&&&&&%%%%&&&&&%%%%%&&&%%#((//***/(#%%#%%%%%%%%%%%%//
//###########%%%%&&&&&&&&&&&&&&%&&&&&&&&&&&&%%%&&&&&&&&&&&&&%#(/****/(#%%%%%%%%%%%//
//##########%%&&&&&&%%%&&&&&&&%%&&&&%&&&&%%%%%%&&&&&&&&&&&&&&&%%%(/**,*/#%%%%%%%%%//
//########%%&&&&&&%%%&%,*%%&&&%%&&%&%%&&&%&&&&&&&%%%&&&%&&&&,*&&&&%#(/,,*/(%%%%%%%//
//((((((#%%&&&&&&&&&%%&%*,#&%&&%%&%%%&&%%&&&%%%%%&&&%%&&&&(,(&&&&&&%%%#/*,,/(%%%%%//
//((((#%%&@@&%&&&%%&&&%%&#,*&&&%&%%&&&%&%%%&&%%%%%&&&&&%%,*%%%&%&&&&&%%%(/*,*/#%%%//
//(#%&&&&&&&&&&&%&&%&&%%&*,#&&%%%&&&%%&%%%%&&&&&%&%%&(,(&%&&&&&&%&&&%&%#(*,,*(#%%%//
///(#%%%@&&&&&&%&&&&%&%&%*/%#,*&&&&&&&&%&%%&%%%&&&&&%%,,&&&&*#&%&&&%%&&&%&&#/*,*/#//
//(#&@%#&&&&&&&&%&&&&&/*%&&%%%*,%&&&&&&%&&%&&%%%%%%&(,(&&&&%*#%%&&%&%%&%%&&&#/*,*///
//#&&@#(@&&&&&&&&&&#,#&&&&&%&&%(,/&&&&&%%%&&%&%%&%%*,%&&&%&&*#&&&&&&&&%%%&&&&#/*,,//
//%&@@(/%&&&@&&&%,/%&&%&&%&&&%&&&*,%&&&&&%&&&&&&&#,/&&%%&&&&*#%&%&&&&&%%&&&&%%(**,//
//&@@@((&&&&%%/*%&&&&&%%%&&&&&&&&&#,/&%%&&&&&&&&*,%&%&&&&&&&*#&&&&&&%%&%&&%&&%%(*,//
//&@@@((&%&#,%@&&%%%&&&&&%&&&&%%%&&&*,#&&&&&&&#,(&%&%&&&&%&&*#&&&%%%%&%&&&%&&&&#/*//
//@@@&(/%*(%%%&&&&&&&&%%%&&&&&&%&&&&&(,/&&&&&*,&&&&&&&&&&&&&*#&&&&&&&&&&&%&&&&%%/*//
//@@@@(((,%%%%&&&&&&&&&%&&&&&%%&&&&&&%%*,#&#,/&&&&&&&&&&%%&&*#&&&&&&&&&&%&&&&&&#/*//
//@@&&//%&%*(%%%%&&&&&&&&&&&&%&&&&&&&%&&(,,,%%&&&&&&&&&&&&%&*#&&&%&&%&&&&&&&&&&#/*//
//&@&&(/%&&&&/*%%%%&&&&&&&&&&%%%&&&&&&%&@(,%&%&&&&&&&&&&&%%&*#&&%%&&&&%&&%&&&&%#////
//&@@@((@&%%&&&#,#%%%%&&&&&&%%%&&&&&&&&&&(,#&&&%&&&&&&%%&&%%*#&%%%&&%%&&%%&&%&%((///
//&@@&((&&&%%&%%%%*/%%%%%%&&&&&&&&&&&&&&&(,#%&&&&&&&&&&&&&%%*#&&&%&&&&&%&&&&&%#(////
//&&@@#(&&&&&&&%%%&%(,%%%%%%%%&&&&%%&&%%&(,#%&&&&&&&&&&&&&&&*#&&&&&&&&&%%%&&&%#(((//
//%&@@&#&&&&%%%%%%%%%%%,(%%%%%%%%&&&&&%%&(,#%&&&&&&&&&&@&&&&*#&&&&%%&&%&&%%&%#(((#//
//%&@@&&@&&%%%&&%%%%&&&&%**%%%&&&&&%%%&%%(,#%&&&&&&%&&&&&&&&*(.\.\.*\.*\.*\.(///(#//
//%%%@@@@@&&%&%%&%%%%&&&%%%%%&%&&&&&&&&%&(,%%&&&&%&&&&&&&&%&&%%%%%&&&&&&&&%####%&&//
//%%%%&@@@@&&&&&&&&%%%%%%%&&%%&&%%%&&&&&&(,#&&&%%&&&&&&&&&&&&&&&%&%%%&&&%%####%%&&//
//%%%&&&@@@@@&&&&&&&&&&&&%%%%&%&&%&&&%&&&(,#&&&&&&&&&&&&&&&%%%&&&%&&%%&%%%%%%&&&&&//
//&&&&&&&&@@@@@&&%%&&&&&&&%%&&%%%&&&&&&&&(,#&%&&&&&&&&&%%%%&&&&&&&&%%%%%%%%%%%%%%%//
//&&&&&&&&&&@@@@@@@@&&&&&&&%&&&&&&%%&&&&&&%&&%&&%&&&&&&&&&&&&&&&%%&&&%%%%%%%%%%%%%//
//&&&&&&&&&&&&&@@@@@@@&&&&&&%&&&&&&&&&%%&&%&&%&&&&&&&&&&&&&&&&%%&&&%%%%%%%%%%%%%%%//
//&&&&&&&&&&&&&&&&@@@@@@@@&&%%&&&&&&&&%&&&%%&%&&&&&&&&&&&&&&&&%&&&&%%%&%%%%%%%%%%%//
//&&&&&&&&&&&&&&&&&&&&@@@@@@@@&&&&&%&&%%&&%%&%&&&&&&@@@@@@&&&&%&&&&%%%&%%%%%%%%%%%//
//&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@&&@@&@@&&@@@@@&&&&&&%&&&&%%%&%%%%%%%%%%%//
////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface bal721 { 
    function balanceOf(address account, uint256 id) external view returns (uint256); 
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface bal1155 { 
     function balanceOf(address account, uint256 id) external view returns (uint256); 
     function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface bal20 { 
    function balanceOf(address account) external view returns (uint256); 
    function allowance(address account, address spender) external view returns (uint256);
}

contract KYL_MARKETPLACE_V1 is Context, AccessControl, ReentrancyGuard, Ownable {

    //SYSTEMA VARIABILIUM

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    string public constant name = "KYL WATCHES LTD - ETHEREUM MARKETPLACE v.1.0";
    string public constant symbol = "KYLm";
    bool public salesActive = false;  

    uint public MAX_CU_ITEMS = 10; uint public MAX_AG_ITEMS = 25;
    uint public MAX_AU_ITEMS = 50; uint public MAX_PT_ITEMS = 10000;

    address public zeroAddress = 0x0000000000000000000000000000000000000000;
    IERC1155 public token1155; IERC721 public token721; IERC20 public token20;
    IERC20 public usdt_erc20; IERC20 public usdc_erc20;

    //USDT Tether ERC20 Contract Address
    //mainnet = 0xdAC17F958D2ee523a2206206994597C13D831ec7
    //rinkeby = 0x358082c3c470F7fdDBe35bfB494092d8c34845d1
    address usd_tether = 0x358082c3c470F7fdDBe35bfB494092d8c34845d1;

    //USDC USD Coin ERC20 Contract Address
    //mainnet = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    //rinkeby = 0x70f215dB83e126673085724CdF66658b5070130A
    address usd_coin = 0x70f215dB83e126673085724CdF66658b5070130A;
    
    //KYL PASS CARD ERC1155 - contract address
    //mainnet = 0x771610939656A647F2C46EEBA46791c42b925fdC
    //rinekby = 0x77d7876faf6C5EB7aD1dB4FA5214F2Ad7935A0C2
    address public passAddress = 0x77d7876faf6C5EB7aD1dB4FA5214F2Ad7935A0C2;

    //KYL COIN ERC20 - contract address
    //mainnet = ;
    //rinkeby = 0x2E3e7f5D16030B7E92d7903cc157351111659143;
    address public coinAddress = 0xB550b75d1Dc3A3C0D93B02F0eD80326e78EfABc3;

    //LECTIO FUNCTIONES

    //get total items in db
    function itemsCount() public view returns(uint count) {  return items.length;  }

    //get total items published by a seller
    function userTotalsItems(address _addr) public view returns(uint32 _count) {  
        _count = 0;
        for (uint i = 0; i < items.length; i++) {
            if (items[i].seller == _addr) {
                _count++;
            }
        }
        return _count;
    }

    //get last item published by a seller
    function userLastItem(address _addr) public view returns(uint32 _count) {  
        _count = 0;
        for (uint32 i = 0; i < items.length; i++) {
            if (items[i].seller == _addr) {
                _count = i;
            }
        }
        return _count;
    }

    //get currently active items by a seller
    function userOnlineItems(address _addr) public view returns(uint _count) {  
        _count = 0;
        for (uint32 i = 0; i < items.length; i++) {
            if ((items[i].seller == _addr)&&(items[i].status == 1)) {
                _count++;
            }
        }
        return _count;
    }

    //REX OPTIONES

    //Owner set USDT ERC20 contract
    function setUsdtAddr(IERC20 _caddr) public onlyOwner nonReentrant {    usdt_erc20 = _caddr;    }

    //Owner set USDC ERC20 contract
    function setUsdcAddr(IERC20 _caddr) public onlyOwner nonReentrant {    usdc_erc20 = _caddr;    }

    //Owner set KYL Card Pass contract
    function passContractAddr(address _caddr) public onlyOwner nonReentrant {    passAddress = _caddr;    }

    //Owner set KYL Coin contract
    function coinContractAddr(address _caddr) public onlyOwner nonReentrant {    coinAddress = _caddr;    }

    //Owner set MAX items for Bronze Sellers
    function setMaxBronze(uint _nume) public onlyOwner nonReentrant {    MAX_CU_ITEMS = _nume;    }

    //Owner set MAX items for Silver Sellers
    function setMaxSilver(uint _nume) public onlyOwner nonReentrant {    MAX_AG_ITEMS = _nume;    }

    //Owner set MAX items for Gold Sellers
    function setMaxGold(uint _nume) public onlyOwner nonReentrant {    MAX_AU_ITEMS = _nume;    }

    //Owner set MAX items for Bronze Sellers
    function setMaxPlatinum(uint _nume) public onlyOwner nonReentrant {    MAX_PT_ITEMS = _nume;    }

    //Owner assign MOD_ROLE to user/address
    function addModRole(address _mod) public onlyOwner nonReentrant { _setupRole(MOD_ROLE, _mod);  }

    //Owner remove MOD_ROLE to user/address
    function remModRole(address _mod) public onlyOwner nonReentrant { _revokeRole(MOD_ROLE, _mod);  }

    //Owner withdraw ETH balance if someone mistake and send ETH to contract address
    function withdrETH() public payable onlyOwner {
        bool sent;
        bytes memory response;
        require(address(this).balance > 0, "No Ether to send!");
        (sent, response) = msg.sender.call{value: address(this).balance}("");
	    require(sent, "Failed to send Ether");
    }

    //items db structure
    // status : 1 = published - 2 = pending - 3 = sold //
    // currency : 1 = USDT - 2 = USDC //
    struct Item {
        uint currency;
        uint256 price;
        address seller;
        uint256 status;
        address nftct;
        uint256 nftid;
        uint256 nftype;
        address buyer;
    }

    Item[] public items;

    //reward List array
    mapping(address => uint256) public claimList;  

    //reward Pass Holders
    mapping(address => uint256) public passReward;  

    // 1 KYLcoin -> bronze pass owner reward
    uint256 public REWARD_CU = (1 * 10**18);

    // 2 KYLcoin -> silver pass owner reward
    uint256 public REWARD_AG = (2 * 10**18);

    // 3 KYLcoin -> gold pass owner reward
    uint256 public REWARD_AU = (3 * 10**18);

    // 5 KYLcoin -> platinum pass owner reward
    uint256 public REWARD_PT = (5 * 10**18);

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MOD_ROLE, msg.sender);
        _setupRole(SELLER_ROLE, msg.sender);
    }

    //admin/mods switch marketplace open/close sales
    function switchStatus() public nonReentrant { 
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        salesActive = !salesActive;
    }

    //admin/mods assign SELLER_ROLE to user/address
    function addSellRole(address _mod) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        _setupRole(SELLER_ROLE, _mod);
    }

    //admin/mods remove SELLER_ROLE to user/address
    function remSellRole(address _mod) public nonReentrant { 
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        _revokeRole(SELLER_ROLE, _mod);  delete claimList[_mod];
    }

    //admin/mods check marketplace balance
    //function checkStatus() public nonReentrant returns(string memory _info){
    //    require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
    //    uint _online = 0; uint _pending = 0; uint _sold = 0; uint _closed = 0;
    //    uint256 pending_usdt = 0; uint256 pending_usdc = 0; uint256 pending_eth = 0;
    //    for (uint i = 0; i < items.length; i++) {
    //        if (items[i].status == 1) {
    //            _online++;
    //        }
    //        if (items[i].status == 2) {
    //            _pending++;
    //        }
    //        if (items[i].status == 3) {
    //            _sold++;
    //        }
    //        if (items[i].status == 4) {
    //            _closed++;
    //        }
    //   }
    //   return _count;
    //}

    //admin/mods setup rewards for pass holders
    function setCuReward(uint256 _reward) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        REWARD_CU = _reward;
    }

    function setAgReward(uint256 _reward) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        REWARD_AG = _reward;
    }

    function setAuReward(uint256 _reward) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        REWARD_AU = _reward;
    }

    function setPtReward(uint256 _reward) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        REWARD_PT = _reward;
    }

    //admin/mods transfer tokens from panel
    using SafeERC20 for IERC20;

    function transferErc20(IERC20 token, address recipient, uint256 amount) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        token.safeTransfer(recipient, amount);
    }

    function transferERC721(IERC721 token, address from, address recipient, uint256 tokenId) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        token.safeTransferFrom(from, recipient, tokenId);
    }

    function transferERC1155(IERC1155 token, address from, address recipient, uint256 tokenId) public nonReentrant {
        require(hasRole(MOD_ROLE, msg.sender), "Error: Not Authorized.");
        token.safeTransferFrom(from, recipient, tokenId, 1, "");
    }

    //sellers insert item details
    function itemSell(uint _currency, uint256 _price, address _nftct, uint256 _nftid, uint256 _nftype) public nonReentrant returns(uint32 _itemid){
        //auth control
        require(hasRole(SELLER_ROLE, msg.sender), "Error: Not Authorized.");
        //sales status checking
        require(salesActive, "Currently Marketplace is Closed. Try Later!");



        //read card pass type
        uint passCheck = bal721(passAddress).balanceOf(msg.sender,1);
        if(passCheck == 0) { passCheck = bal721(passAddress).balanceOf(msg.sender,2); }
        if(passCheck == 0) { passCheck = bal721(passAddress).balanceOf(msg.sender,3); }
        if(passCheck == 0) { passCheck = bal721(passAddress).balanceOf(msg.sender,4); }

        //revert if user is not card pass holder
        require(passCheck > 0, "Error: Buy Pass Card to Publish in KYL Marketplace.");

        uint rewardToAdd = 0; uint maxItems = 0; uint currentItems = userOnlineItems(msg.sender);

        //reward based on card pass
        if(passCheck == 1) { rewardToAdd = REWARD_PT; maxItems = MAX_PT_ITEMS; }
        else if(passCheck == 2) { rewardToAdd = REWARD_AU; maxItems = MAX_AU_ITEMS; }
        else if(passCheck == 3) { rewardToAdd = REWARD_AG; maxItems = MAX_AG_ITEMS; }
        else if(passCheck == 4) { rewardToAdd = REWARD_CU; maxItems = MAX_CU_ITEMS; }

        //check user items exceed
        require(currentItems < maxItems, "Error: Items Listed Exceed.");

        //check if marketplace is approved for nft
        if(_nftct != zeroAddress) {

            //check nft contract type (only 721 or 1155)
            require(((_nftype == 721)||(_nftype == 1155)), "Error: Unsupported NFT Contract type");

            if(_nftype == 721) {
                require(bal721(_nftct).isApprovedForAll(msg.sender, address(this)), "ERC721: transfer caller is not owner or approved");
            } else if (_nftype == 1155) {
                require(bal1155(_nftct).isApprovedForAll(msg.sender, address(this)), "ERC1155: transfer caller is not owner or approved");
            }
        }

        //calc reward and add to balance
        uint rewardCoins = (claimList[msg.sender] + rewardToAdd);

        //set new reward amount to seller
        claimList[msg.sender] = rewardCoins;

        //insert item into blockchain database
        items.push(Item(_currency, _price, msg.sender, 1, _nftct, _nftid, _nftype, zeroAddress));

        _itemid = userLastItem(msg.sender); return _itemid;
    }


    function itemBuyUsd(uint _itid, uint256 _coins) public payable nonReentrant {
        uint256 buyer_bal = 0; uint256 buyer_allowance = 0;
        require(items[_itid].status == 1, "This item has been sold or removed.");
        require(items[_itid].price <= _coins, "Trying to send insufficient amount.");

        //retrieve user usdt/usdc balance and check if marketplace is approved.

        if(items[_itid].currency == 1) { 

            buyer_bal = bal20(usd_tether).balanceOf(msg.sender); 
            require(items[_itid].price <= buyer_bal, "Your USDT balance is not enough.");
            buyer_allowance = bal20(usd_tether).allowance(msg.sender,address(this)); 
            require(items[_itid].price <= buyer_allowance, "Error: Approve USDT not sent. First, approve KYL marketplace.");

            usdt_erc20.safeTransferFrom(msg.sender, address(this), buyer_allowance);
            items[_itid].status = 2; items[_itid].buyer = msg.sender;
            
        } else if(items[_itid].currency == 2) { 

            buyer_bal = bal20(usd_coin).balanceOf(msg.sender); 
            require(items[_itid].price <= buyer_bal, "Your USDC balance is not enough.");
            buyer_allowance = bal20(usd_coin).allowance(msg.sender,address(this)); 
            require(items[_itid].price <= buyer_allowance, "Error: Approve USDC not sent. First, approve KYL marketplace.");

            usdc_erc20.safeTransferFrom(msg.sender, address(this), buyer_allowance);
            items[_itid].status = 2; items[_itid].buyer = msg.sender;
        }       
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}