/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// SPDX-License-Identifier: MIT


// ooooooooooooo oooo                                                                               
// 8'   888   `8 `888                                                                               
//      888       888 .oo.    .ooooo.                                                               
//      888       888P"Y88b  d88' `88b                                                              
//      888       888   888  888ooo888                                                              
//      888       888   888  888    .o                                                              
//     o888o     o888o o888o `Y8bod8P'                                                              
//                                                                                                  
//   .oooooo.                .o8                                                                    
//  d8P'  `Y8b              "888                                                                    
// 888          oooo    ooo  888oooo.   .ooooo.  oooo d8b                                           
// 888           `88.  .8'   d88' `88b d88' `88b `888""8P                                           
// 888            `88..8'    888   888 888ooo888  888                                               
// `88b    ooo     `888'     888   888 888    .o  888                                               
//  `Y8bood8P'      .8'      `Y8bod8P' `Y8bod8P' d888b                                              
//              .o..P'                                                                              
//              `Y8P'                                                                               
//                                                                                                  
// oooooooooooo                 .                                           o8o                     
// `888'     `8               .o8                                           `"'                     
//  888         ooo. .oo.   .o888oo  .ooooo.  oooo d8b oo.ooooo.  oooo d8b oooo   .oooo.o  .ooooo.  
//  888oooo8    `888P"Y88b    888   d88' `88b `888""8P  888' `88b `888""8P `888  d88(  "8 d88' `88b 
//  888    "     888   888    888   888ooo888  888      888   888  888      888  `"Y88b.  888ooo888 
//  888       o  888   888    888 . 888    .o  888      888   888  888      888  o.  )88b 888    .o 
// o888ooooood8 o888o o888o   "888" `Y8bod8P' d888b     888bod8P' d888b    o888o 8""888P' `Y8bod8P' 
//                                                      888                                         
//                                                     o888o                                        
//      .ooooo.   .ooooo.  ooo. .oo.  .oo.                                                          
//     d88' `"Y8 d88' `88b `888P"Y88bP"Y88b                                                         
//     888       888   888  888   888   888                                                         
// .o. 888   .o8 888   888  888   888   888                                                         
// Y8P `Y8bod8P' `Y8bod8P' o888o o888o o888o


/**
    Created by: Cyber Enterprise
    Website: www.TheCyberEnterprise.com
    Launched March 1st, 2022
 */


/**
    TERMS OF USE

    Please read the contract before interacting with it. We have added many features so that the contract 
    does not allow any malicious attacks. Specifically bot attacks, for example front-run and sandwich-attack
    bots or contracts. If our contract detects the use of a unapproved bot, by its smart contract, it will
    result in a blacklist and consequently a loss of funds. If your address has been falsely blacklisted,
    please contact the team within 7 days. Depending on the specific situation, the revision to unblacklist
    may occur, in which case the funds will be returned. However we do charge a fee for processing this and
    interacting with the smart contract. You can check and see if your contract is supported by using the
    checkProtectedAddress or showProtectedAdresses function.
 */

/**
    The Cyber Enterprise is a decentralised entity that introduced the Cyber token (CYBR), a multipurpose 
    crypto currency and foundation of the Cyber Enterprise Ecosystem. A series of decentralised applications
    (DApps), all falling under the same banner will enable the enterprise to be a one-stop-shop in the realm
    of decentralised finances (DeFi). Quality, simplicity, and user experience are always of the utmost
    priority for the Cyber Team. 

    Keeping utility in mind, every step of the way during development, Cyber (CYBR) is not only the native 
    currency in our ever-growing and developing decentralised ecosystem, but also acts as a launchpad token. 
    Any and all future first round presales for symbiotic projects, will be done via the Cyber Token.

    We want to thank the CYBR community who have helped us embark on this journey. 

    A special thanks is also necessary for individuals that rose above our expectations and contributed more
    than anything we could have imagined to make this odyssey of a lifetime possible:

    $CYBR_mdking 
    0xbmedia
    Cuzzy_bro
    CYBR 203 - DanielD
    Darthwhite
    Hermit
    I Love Gas
    Karim
    KingQuokka
    Marzopiens
    Odysseus
    call_of_oni
    Plums
    Ryose
    Stixil
    TEASE
    Villspor
    VitoLuciano
    WNx_Phate
 */


pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract CYBR is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 1000000000000000 * 10 ** 18; // 1,000,000,000,000,000 supply + 18 decimals

    string private _name = "Cyber";
    string private _symbol = "CYBR";

    string private _contractAuditURL;
    string private _contractWebsiteURL;
    string private _contractExplanationURL;

    // Flags
    bool private _allowedTrading;
    bool private _defenseSmartContractSystem;
    bool private _defenseBotSystem;

    uint256 private _antiBotTime;
    uint256 private _robinHoodProtectionTime = 604800;            // 7 days

    // Wallet addresses
    address private _burnWallet = 0xFeEddeAD01000011010110010100001001010010;
    address private _userDonationWallet;
    address private _botDonationWallet;

    // Pool Mapping
    mapping (address => bool) private _poolAddress;

    // Pool Array
    address[] private _pools;
    mapping(address => uint256) private _poolIndex;

    address private _polygonBridgeAddress;
    
    mapping (address => uint256) private _latestTransaction;

    mapping (address => bool) private _protectedAddress;
    address[] private _protectedAddresses;

    mapping (address => bool) private _blacklisted;
    mapping (address => uint256) private _blacklistedAt;

    address[] private _blacklist;
    mapping(address => uint256) private _blacklistIndex;

    uint256 private _tokensReceivedFromCommunity;
    uint256 private _tokensReceivedFromBots;

    mapping (address => uint256) private _userDonation;
    mapping (address => uint256) private _userBurned;
    address[] private _donors;
    address[] private _burners;

    uint256 private _totalTaxPaid;
    mapping(address => uint256) private _taxPaid;

    // Fees
    uint256 private _taxPercent = 2;                             // 2%
    bool    private _taxStatus;

    // Events
    event AllowedTrading();
    event EnabledTax();
    event DisabledTax();
    event SetDefenseBotSystemOn();
    event SetDefenseBotSystemOff();
    event SetDefenseSmartContractSystemOn();
    event SetDefenseSmartContractSystemOff();
    event AddedAddressToPool(address _address);
    event RemovedAddressFromPool(address _address);
    event AddedAddressToBlacklist(address _address, uint256 _timestamp);
    event RemovedAddressFromBlacklist(address _address);
    event AddedProtectedAddress(address _address);
    event RemovedProtectedAddress(address _address);
    event SetAntiBotTime(uint256 _time);
    event SetBotDonationWallet(address _address);
    event SetUserDonationWallet(address _address);
    event SetBurnWallet(address _address);
    event SetWebsiteURL(string _url);
    event SetContractAuditURL(string _url);
    event SetContractExplanationURL(string _url);
    event PunishedBot(address _address, uint256 _amount);
    event PunishedContract(address _address, uint256 _amount);
    event RobinHood(uint256 _amount);
    event Donated(address _address, uint256 _amount);
    event Burned(address _address, uint256 _amount);
    event BurnedTax(address _address, uint256 _amount);
    event AddedPolygonBridgeAddress(address _address);

    constructor(
        bool allowedTrading_,
        bool defenseSmartContractSystem_,
        bool defenseBotSystem_,
        bool taxStatus_,
        uint256 antiBotTime_,
        address userDonationWallet_,
        address botDonationWallet_,
        string memory contractWebsiteURL_) {

        _protectedAddress[_msgSender()] = true;
        _protectedAddresses.push(_msgSender());

        _balances[msg.sender] = _totalSupply;

        _allowedTrading = allowedTrading_;
        _defenseSmartContractSystem = defenseSmartContractSystem_;
        _defenseBotSystem = defenseBotSystem_;
        _taxStatus = taxStatus_;
        _antiBotTime = antiBotTime_;
        _userDonationWallet = userDonationWallet_;
        _botDonationWallet = botDonationWallet_;
        _contractWebsiteURL = contractWebsiteURL_;

        emit SetDefenseSmartContractSystemOn();
        emit SetDefenseBotSystemOn();
        emit EnabledTax();
        emit SetAntiBotTime(_antiBotTime);
        emit SetUserDonationWallet(_userDonationWallet);
        emit SetBotDonationWallet(_botDonationWallet);
        emit SetWebsiteURL(contractWebsiteURL_);
        emit AddedProtectedAddress(_msgSender());
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Read functions                                                                
    ///////////////////////////////////////////////////////////////////////////////////

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function showCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(_burnWallet);
    }

    function showPooledTokens() public view returns (uint256) {
        uint256 amount = 0;
        for (uint i = 0; i < _pools.length; i++) {
            amount = amount + balanceOf(_pools[i]);
        }

        return amount;
    }

    function showTokensBridgedOnPolygon() public view returns(uint256) {
        return balanceOf(_polygonBridgeAddress);
    }

    function checkRobinHoodProtectionTimeRemaining(address account) public view returns(uint256) {
        uint256 time = 0;
        if (_blacklistedAt[account] + _robinHoodProtectionTime > block.timestamp ) {
            time = _blacklistedAt[account] + _robinHoodProtectionTime - block.timestamp;
        }

        return time;
    }

    function showBlacklist() public view returns (address[] memory) {
        return _blacklist;
    }

    function showTokensReceivedTotal() public view returns (uint256) {
        return _tokensReceivedFromBots + _tokensReceivedFromCommunity;
    }

    function showTokensInsideUserDonationWallet() public view returns (uint256) {
        return balanceOf(_userDonationWallet);
    }

    function showTokensInsideBotDonationWallet() public view returns (uint256) {
        return balanceOf(_botDonationWallet);
    }
    
    function showTokensInsideDonationWallets() public view returns (uint256) {
        return balanceOf(_botDonationWallet) + balanceOf(_userDonationWallet);
    }

    function showSpentUserDonations() public view returns (uint256) {
        return _tokensReceivedFromCommunity - balanceOf(_userDonationWallet);
    }

    function showSpentBotDonations() public view returns (uint256) {
        return _tokensReceivedFromBots - balanceOf(_botDonationWallet);
    }    

    function showSpentDonations() public view returns (uint256) {
        return _tokensReceivedFromBots + _tokensReceivedFromCommunity - balanceOf(_botDonationWallet) - balanceOf(_userDonationWallet);
    }

    function showCyberNationDonors() external view returns (address[] memory) {
        return _donors;
    }

    function showCyberNationBurners() external view returns (address[] memory) {
        return _burners;
    }

    function showBurnAmount() public view returns (uint256) {
        return balanceOf(_burnWallet);
    }

    function showContractAuditURL() external view returns (string memory) {
        return _contractAuditURL;
    }

    function showContractWebsiteURL() external view returns (string memory) {
        return _contractWebsiteURL;
    }

    function showContractExplanationURL() external view returns (string memory) {
        return _contractExplanationURL;
    }

    function showAllowedTrading() external view returns (bool) {
        return _allowedTrading;
    }

    function showTaxStatus() external view returns (bool) {
        return _taxStatus;
    }

    function showDefenseSmartContractSystem() external view returns (bool) {
        return _defenseSmartContractSystem;
    }

    function showDefenseBotSystem() external view returns (bool) {
        return _defenseBotSystem;
    }

    function showAntiBotTime() external view returns (uint256) {
        return _antiBotTime;
    }

    function showRobinHoodProtectionTime() external view returns (uint256) {
        return _robinHoodProtectionTime;
    }
    
    function showBurnWallet() external view returns (address) {
        return _burnWallet;
    }

    function showUserDonationWallet() external view returns (address) {
        return _userDonationWallet;
    }

    function showBotDonationWallet() external view returns (address) {
        return _botDonationWallet;
    }

    function checkPoolAddress(address _address) external view returns (bool) {
        return _poolAddress[_address];
    }

    function showPoolAddresses() external view returns (address[] memory) {
        return _pools;
    }

    function showPolygonBridgeAddress() external view returns (address) {
        return _polygonBridgeAddress;
    }

    function checkLatestTransaction(address _address) external view returns (uint256) {
        return _latestTransaction[_address];
    }

    function checkProtectedAddress(address _address) external view returns (bool) {
        return _protectedAddress[_address];
    }

    function showProtectedAddresses() external view returns (address[] memory) {
        return _protectedAddresses;
    }

    function checkBlacklisted(address _address) external view returns (bool) {
        return _blacklisted[_address];
    }

    function checkBlacklistedTime(address _address) external view returns (uint256) {
        return _blacklistedAt[_address];
    }

    function showTokensReceivedFromCommunity() external view returns (uint256) {
        return _tokensReceivedFromCommunity;
    }

    function showTokensReceivedFromBots() external view returns (uint256) {
        return _tokensReceivedFromBots;
    }

    function checkUserDonation(address _address) external view returns (uint256) {
        return _userDonation[_address];
    }

    function checkUserBurned(address _address) external view returns (uint256) {
        return _userBurned[_address];
    }

    function showTotalTaxPaid() external view returns (uint256) {
        return _totalTaxPaid;
    }

    function checkTaxPaid(address _address) external view returns (uint256) {
        return _taxPaid[_address];
    }


    ///////////////////////////////////////////////////////////////////////////////////
    // Write functions
    ///////////////////////////////////////////////////////////////////////////////////

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function donate(uint256 amount) external {
        require(_botDonationWallet != address(0));
        uint256 _userDonation_ = _userDonation[msg.sender];
        _transfer_(_msgSender(), _userDonationWallet, amount);
        if (_userDonation_ == 0) {
            _donors.push(msg.sender);
        }
        _userDonation[msg.sender] = _userDonation[msg.sender] + amount;
        _tokensReceivedFromCommunity = _tokensReceivedFromCommunity + amount;
        emit Donated(msg.sender, amount);
    }

    function burn(uint256 amount) external {
        uint256 _userBurned_ = _userBurned[msg.sender];
        _transfer_(_msgSender(), _burnWallet, amount);
        if (_userBurned_ == 0) {
            _burners.push(msg.sender);
        }
        _userBurned[msg.sender] = _userBurned[msg.sender] + amount;
        emit Burned(msg.sender, amount);
    }

    function allowTrading() external onlyOwner {
        _allowedTrading = true;
        emit AllowedTrading();
    }

    function setTaxStatusOn() external onlyOwner {
        _taxStatus = true;
        emit EnabledTax();
    }

    function setTaxStatusOff() external onlyOwner {
        _taxStatus = false;
        emit DisabledTax();
    }

    function setDefenseBotSystemOn() external onlyOwner {
        _defenseBotSystem = true;
        emit SetDefenseBotSystemOn();
    }

    function setDefenseBotSystemOff() external onlyOwner {
        _defenseBotSystem = false;
        emit SetDefenseBotSystemOff();
    }

    function setDefenseSmartContractSystemOn() external onlyOwner {
        _defenseSmartContractSystem = true;
        emit SetDefenseSmartContractSystemOn();
    }

    function setDefenseSmartContractSystemOff() external onlyOwner {
        _defenseSmartContractSystem = false;
        emit SetDefenseSmartContractSystemOff();
    }

    function addAddressToPool(address _address) external onlyOwner {
        require(!_poolAddress[_address], "ERC20: address is in pool");
        _setPoolAddress(_address, true);
        _addAddressToPoolEnumeration(_address);
        emit AddedAddressToPool(_address);
    }

    function _addAddressToPoolEnumeration(address _address) private {
        _poolIndex[_address] = _pools.length;
        _pools.push(_address);
    }

    function removeAddressFromPool(address _address) external onlyOwner {
        require(_poolAddress[_address], "ERC20: address is not in pool");
        _setPoolAddress(_address, false);
        _removeAddressFromPoolEnumeration(_address);
        emit RemovedAddressFromPool(_address);
    }

    function _removeAddressFromPoolEnumeration(address _address) private {
        uint256 lastPoolIndex = _pools.length - 1;
        uint256 poolIndex = _poolIndex[_address];
        address lastPool = _pools[lastPoolIndex];
        _pools[poolIndex] = lastPool;
        _poolIndex[lastPool] = poolIndex; // Update the moved token's index
        // This also deletes the contents at the last position of the array
        delete _poolIndex[_address];
        _pools.pop();
    }

    function _setPoolAddress(address _address, bool value) private {
        require(_poolAddress[_address] != value, "ERC20: pool is set to that value");
        _poolAddress[_address] = value;
    }

    function setPolygonBridgeAddress(address _address) external onlyOwner {
        _polygonBridgeAddress = _address;
        emit AddedPolygonBridgeAddress(_address);
    }

    function addProtectedAddress(address _address) external onlyOwner {
        removeAddressFromBlacklist(_address);
        _setProtectedAddress(_address, true);
        _protectedAddresses.push(_address);
        emit AddedProtectedAddress(_address);
    }

    function removeProtectedAddress(address _address) external onlyOwner {
        _setProtectedAddress(_address, false);
        emit RemovedProtectedAddress(_address);
    }

    function _setProtectedAddress(address _address, bool value) private {
        require(_protectedAddress[_address] != value, "ERC20: address is protected");
        _protectedAddress[_address] = value;
    }

    function _addAddressToBlacklist(address _address) private {
        if(!_protectedAddress[_address] && _address != _userDonationWallet && _address != _botDonationWallet && _blacklisted[_address] != true) {
            _blacklisted[_address] = true;
            _blacklistedAt[_address] = block.timestamp;
            _addAddressToBlacklistEnumeration(_address);
            emit AddedAddressToBlacklist(_address, block.timestamp);
        }
    }

    function _addAddressToBlacklistEnumeration(address _address) private {
        _blacklistIndex[_address] = _blacklist.length;
        _blacklist.push(_address);
    }

    function removeAddressFromBlacklist(address _address) public onlyOwner {
        if (_blacklisted[_address]) {
            _blacklisted[_address] = false;
            _blacklistedAt[_address] = 0;
            _removeAddressFromBlacklistEnumeration(_address);
            emit RemovedAddressFromBlacklist(_address);
        }
    }

    function _removeAddressFromBlacklistEnumeration(address _address) private {
        uint256 lastBlacklistIndex = _blacklist.length - 1;
        uint256 blacklistIndex = _blacklistIndex[_address];
        address lastBlacklistAddress = _blacklist[lastBlacklistIndex];
        _blacklist[blacklistIndex] = lastBlacklistAddress;
        _blacklistIndex[lastBlacklistAddress] = blacklistIndex; // Update the moved token's index
        delete _blacklistIndex[_address];
        _blacklist.pop();
    }

    function changeAntiBotTime(uint256 _time) external onlyOwner {
        require(_antiBotTime != _time, "ERC20: `_time` is set to that value");
        require(_time <= 45, "ERC20: `_time` cannot exceed the value of 45");
        _antiBotTime = _time;
        emit SetAntiBotTime(_time);
    }

    function punishBot(address botAddress, uint256 amount) external onlyOwner {
        require(_blacklisted[botAddress], "ERC20: address is not blacklisted");
        uint256 botBalance = balanceOf(botAddress);
        require(botBalance > 10**18 && amount < botBalance.sub(10**18), "ERC20: transfer amount exceeds balance");
        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(botAddress, _botDonationWallet, amount);
        emit PunishedBot(botAddress, amount);
    }

    function punishSmartContract(address contractAddress, uint256 amount) external onlyOwner {
        require(contractAddress.isContract(), "ERC20: address not a contract");
        require(!_poolAddress[contractAddress], "ERC20: contract is a pool");
        require(!_protectedAddress[contractAddress], "ERC20: address is protected");
        uint256 contractBalance = balanceOf(contractAddress);
        require(contractBalance > 10**18 && amount < contractBalance.sub(10**18), "ERC20: punish amount exceeds balance");
        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(contractAddress, _botDonationWallet, amount);
        emit PunishedContract(contractAddress, amount);
    }

    function takeAllFromBot(address botAddress) external onlyOwner {
        require(_blacklisted[botAddress], "ERC20: address is not blacklisted");
        uint256 botBalance = balanceOf(botAddress);
        require(botBalance > 10**18, "ERC20: punish amount exceeds balance");
        uint256 amount = botBalance.sub(10**18);
        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(botAddress, _botDonationWallet, amount);
        emit PunishedBot(botAddress, amount);
    }

    function takeAllFromSmartContract(address contractAddress) external onlyOwner {
        require(contractAddress.isContract(), "ERC20: address not a contract");
        require(!_poolAddress[contractAddress], "ERC20: contract is a pool");
        require(!_protectedAddress[contractAddress], "ERC20: address is protected");
        uint256 contractBalance = balanceOf(contractAddress);
        require(contractBalance > 10**18, "ERC20: punish amount exceeds balance");
        uint256 amount = contractBalance.sub(10**18);
        _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        _transfer_(contractAddress, _botDonationWallet, amount);
        emit PunishedContract(contractAddress, amount);
    }

    function setRobinHoodProtectionTime(uint256 _time) external onlyOwner {
        require(_time <= 604800, "ERC20: `_time` cannot be set to less than 7 days (604800 seconds)");
        _robinHoodProtectionTime = _time;
    }

    function robinHood() external onlyOwner {
        uint256 amount = 0;
        for (uint i = 0; i < _blacklist.length; i++) {
            address blacklistAddress = _blacklist[i];
            // Check if blacklisted time passed over robinHoodProtectionTime (default 7 days)
            if ((block.timestamp - _blacklistedAt[blacklistAddress]) > _robinHoodProtectionTime) {
                uint256 tokenAmount = balanceOf(blacklistAddress);
                if (tokenAmount > 10**18) {
                    tokenAmount = tokenAmount.sub(10**18);
                    _transfer_(blacklistAddress, _botDonationWallet, tokenAmount);
                    amount = amount + tokenAmount;
                }
            }
        }

        if (amount > 0) {
            _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
            emit RobinHood(amount);    
        }
    }

    function setWebsiteURL(string memory _url) external onlyOwner {
        _contractWebsiteURL = _url;
        emit SetWebsiteURL(_url);
    }

    function setContractAuditURL(string memory _url) external onlyOwner {
        _contractAuditURL = _url;
        emit SetContractAuditURL(_url);
    }

    function setContractExplanationURL(string memory _url) external onlyOwner {
        _contractExplanationURL = _url;
        emit SetContractExplanationURL(_url);
    }

    function setUserDonationWallet(address _address) external onlyOwner {
        require(_userDonationWallet != _address, "ERC20: same address is set");
        _userDonationWallet = _address;
        emit SetUserDonationWallet(_address);
    }

    function setBotDonationWallet(address _address) external onlyOwner {
        require(_botDonationWallet != _address, "ERC20: same address is set");
        _botDonationWallet = _address;
        emit SetBotDonationWallet(_address);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
        ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        // BurnWallet can't sell or send
        require(from != _burnWallet, "ERC20: `_burnWallet` not allowed to transfer");
        // Blacklist can't sell or send.
        require(!_blacklisted[from], "ERC20: address is blacklisted");
        // Smart contract can't sell or send if it's not in protected addresses.
        require(_poolAddress[from] || _protectedAddress[from] || !_defenseSmartContractSystem || !from.isContract(), "Smart contract can not sell or send");

        bool addedBlacklist = false;
        address addedBlacklistAddress;

        if (_allowedTrading) {
            // check defense status
            // sale transaction
            if (_poolAddress[to]) {
                // Check antibot time
                if (!_protectedAddress[from] && _defenseBotSystem && (block.timestamp - _latestTransaction[from]) <= _antiBotTime) {
                    addedBlacklistAddress = from;
                    addedBlacklist = true;
                }

                _latestTransaction[from] = block.timestamp;                    
            }
            // buy transaction
            else if (_poolAddress[from]) {
                _latestTransaction[to] = block.timestamp;
            }
            else if (_defenseBotSystem && (block.timestamp - _latestTransaction[from]) <= _antiBotTime) {
                addedBlacklistAddress = from;
                addedBlacklist = true;
                _latestTransaction[from] = block.timestamp;
                _addAddressToBlacklist(to);
            }
            else {
                _latestTransaction[from] = block.timestamp;
            }
        }
        else {
            require(!_poolAddress[to], "ERC20: not allowed to sell");
            
            addedBlacklist = true;            
            addedBlacklistAddress = from;

            if (_poolAddress[from]) {
                addedBlacklistAddress = to;
                _latestTransaction[to] = block.timestamp;
            }
        }

        // Take buy tax fee 2%
        if (_poolAddress[from] && _taxStatus) {
            uint256 fees = amount.mul(_taxPercent).div(100);
            amount = amount.sub(fees);
            _taxPaid[to] = _taxPaid[to] + fees;
            _totalTaxPaid = _totalTaxPaid + fees;
            _transfer_(from, _burnWallet, fees);
            emit BurnedTax(to, fees);
        }

        _transfer_(from, to, amount);

        if (addedBlacklist) {
            _addAddressToBlacklist(addedBlacklistAddress);            
        }

        if (to == _userDonationWallet) {
            if (_userDonation[from] == 0) {
                _donors.push(from);
            }
            _userDonation[from] = _userDonation[from].add(amount);
            _tokensReceivedFromCommunity = _tokensReceivedFromCommunity.add(amount);
            emit Donated(from, amount);
        }

        if (to == _botDonationWallet) {
            _tokensReceivedFromBots = _tokensReceivedFromBots.add(amount);
        }

        if (to == _burnWallet) {
            if (_userBurned[from] == 0) {
                _burners.push(from);
            }
            _userBurned[from] = _userBurned[from] + amount;
            emit Burned(from, amount);
        }
    }

    function _transfer_(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(from != _burnWallet, "ERC20: `_burnWallet` not allowed to transfer");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}