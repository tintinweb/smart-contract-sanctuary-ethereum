/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// File: contracts/DarkCoin.sol

// SPDX-License-Identifier: MIT

// Amended by DarkPortalsNFTs

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Dark Coin token contract
//
// creted by @DarkPortalsNFTs_27/5/2022
//
// Deployed to : 0x4b07D86cddE01400Fb302cDc1892a876E5Ba1D61
// Symbol      : DRK
// Name        : Dark Coin
// Total supply: 999999999999999999999999999
// Decimals    : 18
//
// Enjoy.
//
// 
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract SimpleStorage {
  uint storedData;

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }
}




interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;


contract ERC721Holder is IERC721Receiver {
   
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


pragma solidity ^0.8.0;

interface IERC165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;


interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) external view returns (address owner);

  
    function safeTransferFrom(
        address from ,
        address to,
        uint256 tokenId
    ) external;

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function getApproved(uint256 tokenId) external view returns (address operator);

   
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;



abstract contract ERC165 is IERC165 {
   
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

   
    function toString(uint256 value) internal pure returns (string memory) {
       
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

 
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

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

pragma solidity ^0.8.0;


interface IAccessControl {
    
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

   
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    
    function hasRole(bytes32 role, address account) external view returns (bool);

    
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    
    function grantRole(bytes32 role, address account) external;

    
    function revokeRole(bytes32 role, address account) external;

   
    function renounceRole(bytes32 role, address account) external;
}


pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



pragma solidity ^0.8.0;


abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

   
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }


    function _checkRole(bytes32 role, address account) internal view {
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

    
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

   
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

   
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

   
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity ^0.8.0;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}


pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name; 
    string private _symbol;

   
    constructor(string memory name_, string memory symbol_) {
        _name = name_; 
        _symbol = symbol_;
    }

  
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

   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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




pragma solidity ^0.8.2;




contract darkCoin is ERC20, AccessControl, ERC721Holder {
    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public collectionAddress;
    uint256 public numberOfBlocksPerRewardUnit;
    uint256 public coinAmountPerRewardUnit;
    uint256 public welcomeBonusAmount;
    uint256 public amountOfStakers;
    uint256 public tokensStaked;
    uint256 public contractCreationBlock;

    struct StakeInfo {
        uint256 stakedAtBlock;
        uint256 lastHarvestBlock;
        bool currentlyStaked;
    }
    /// owner => tokenId => StakeInfo
    mapping (address => mapping(uint256 => StakeInfo)) public stakeLog;
    /// owner => #NFTsStaked
    mapping (address => uint256) public tokensStakedByUser;
    /// tokenId => true/false (true if welcome bonus has been collected for a specific tokenId)
    mapping (uint256 => bool) public welcomeBonusCollected;
    /// owner => list of all tokenIds that the user has staked
    mapping (address => uint256[]) public stakePortfolioByUser;
    /// tokenId => indexInStakePortfolio
    mapping(uint256 => uint256) public indexOfTokenIdInStakePortfolio;

    event RewardsHarvested (address owner, uint256 amount);
    event NFTStaked (address owner, uint256 tokenId);
    event NFTUnstaked (address owner, uint256 tokenId);

    constructor(address owner, address _collectionAddress) ERC20("Dark Coin", "DRK") AccessControl(){
        _mint(owner, 9999999999999999 * 10 ** 18);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
        _setupRole(CONTRACT_ADMIN_ROLE, owner);
        _setupRole(BURNER_ROLE, owner);
        _setupRole(MINTER_ROLE, owner);
        collectionAddress = _collectionAddress;
        contractCreationBlock = block.number;
        coinAmountPerRewardUnit = 1 * 10 ** 18; // 1 ERC20 coins per rewardUnit, may be changed later on
        numberOfBlocksPerRewardUnit = 20571; // 12 hours per reward unit , may be changed later on
        welcomeBonusAmount = 200 * 10 ** 18; // 200 tokens welcome bonus, only paid once per tokenId
    }

    function stakedNFTSByUser(address owner) external view returns (uint256[] memory){
        return stakePortfolioByUser[owner];
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        super._burn(from, amount);
    }

    function pendingRewards(address owner, uint256 tokenId) public view returns (uint256){
        StakeInfo memory info = stakeLog[owner][tokenId];

        if(info.lastHarvestBlock < contractCreationBlock || info.currentlyStaked == false) {
            return 0;
        }
        uint256 blocksPassedSinceLastHarvest = block.number - info.lastHarvestBlock;
        if (blocksPassedSinceLastHarvest < numberOfBlocksPerRewardUnit * 2) {
            return 0;
        }
        uint256 rewardAmount = blocksPassedSinceLastHarvest / numberOfBlocksPerRewardUnit - 1;
        return rewardAmount * coinAmountPerRewardUnit;

    }

    function stake(uint256 tokenId) public {
        IERC721(collectionAddress).safeTransferFrom(_msgSender(), address(this), tokenId);
        require(IERC721(collectionAddress).ownerOf(tokenId) == address(this),
            "drk: Error while transferring token");
        StakeInfo storage info = stakeLog[_msgSender()][tokenId];
        info.stakedAtBlock = block.number;
        info.lastHarvestBlock = block.number;
        info.currentlyStaked = true;
        if(tokensStakedByUser[_msgSender()] == 0){
            amountOfStakers += 1;
        }
        tokensStakedByUser[_msgSender()] += 1;
        tokensStaked += 1;
        stakePortfolioByUser[_msgSender()].push(tokenId);
        uint256 indexOfNewElement = stakePortfolioByUser[_msgSender()].length - 1;
        indexOfTokenIdInStakePortfolio[tokenId] = indexOfNewElement;
        if(!welcomeBonusCollected[tokenId]) {
            _mint(_msgSender(), welcomeBonusAmount);
            welcomeBonusCollected[tokenId] = true;
        }

        emit NFTStaked(_msgSender(), tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            stake(tokenIds[currentId]);
        }
    }

    function unstakeBatch(uint256[] memory tokenIds) external {
        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            unstake(tokenIds[currentId]);
        }
    }

    function unstake(uint256 tokenId) public {
        if(pendingRewards(_msgSender(), tokenId) > 0){
            harvest(tokenId);
        }
        StakeInfo storage info = stakeLog[_msgSender()][tokenId];
        info.currentlyStaked = true;
        IERC721(collectionAddress).safeTransferFrom(address(this), _msgSender(), tokenId);
        require(IERC721(collectionAddress).ownerOf(tokenId) == _msgSender(),
            "drk: Error while transferring token");
        if(tokensStakedByUser[_msgSender()] == 1){
            amountOfStakers -= 1;
        }
        tokensStakedByUser[_msgSender()] -= 1;
        tokensStaked -= 1;
        stakePortfolioByUser[_msgSender()][indexOfTokenIdInStakePortfolio[tokenId]] = 0;
        emit NFTUnstaked(_msgSender(), tokenId);
    }

    function harvest(uint256 tokenId) public {
        StakeInfo storage info = stakeLog[_msgSender()][tokenId];
        uint256 rewardAmountInERC20Tokens = pendingRewards(_msgSender(), tokenId);
        if(rewardAmountInERC20Tokens > 1) {
            info.lastHarvestBlock = block.number;
            _mint(_msgSender(), rewardAmountInERC20Tokens);
            emit RewardsHarvested(_msgSender(), rewardAmountInERC20Tokens);
        }
    }

    function harvestBatch(address user) external {
        uint256[] memory tokenIds = stakePortfolioByUser[user];

        for(uint currentId = 0; currentId < tokenIds.length; currentId++) {
            if(tokenIds[currentId] == 0) {
                continue;
            }
            harvest(tokenIds[currentId]);
        }
    }

    function setNumberOfBlocksPerRewardUnit(uint256 numberOfBlocks) external onlyRole(CONTRACT_ADMIN_ROLE){
        numberOfBlocksPerRewardUnit = numberOfBlocks; 
    }

    function setCoinAmountPerRewardUnit(uint256 coinAmount) external onlyRole(CONTRACT_ADMIN_ROLE){
        coinAmountPerRewardUnit = coinAmount; 
    }

    function setWelcomeBonusAmount(uint256 coinAmount) external onlyRole(CONTRACT_ADMIN_ROLE){
        welcomeBonusAmount = coinAmount; 
    }

    function setCollectionAddress(address newAddress) external onlyRole(CONTRACT_ADMIN_ROLE){
        require (newAddress != address(0), "DRK");
        collectionAddress = newAddress;
    }
}