// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./HeraMinter.sol";
import "./interfaces/IHeraERC1155.sol";

struct stake {
    uint256 amount;
    uint256 deadline;
    uint8 apyOption;
}

contract HeraStaking is Ownable, ReentrancyGuard {
    mapping(address => stake) _stakes;
    mapping(address => uint256) _rewards;
    mapping(address => uint256) _lastTime;

    IERC20 public _token;
    uint256 constant _decimal = 18;
    uint256[] _apyOptions = new uint256[](7);
    uint256 _denominator = 100;

    IHeraERC1155 public HercERC1155;

    event Deposit(address indexed account, uint256 amount, uint256 period);
    event Claim(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event ContractCreated(address indexed account);

    constructor(address token_, IHeraERC1155 _HercERC1155) {
        HercERC1155 = _HercERC1155;
        _token = IERC20(token_);
        _apyOptions[0] = 2;
        _apyOptions[1] = 4;
        _apyOptions[2] = 6;
        _apyOptions[3] = 8;
        _apyOptions[4] = 10;
        _apyOptions[5] = 12;
        _apyOptions[6] = 19;
    }

    function stakeOf(address account) external view returns (uint256) {
        return _stakes[account].amount;
    }

    function isStakeholder(address account) external view returns (bool) {
        return _stakes[account].amount > 0;
    }

    function deposit(uint256 amount, uint256 period) external {
        require(_stakes[_msgSender()].amount == 0, "Staking: already staked");

        uint8 option;

        if(amount == 100) {
            option = 1;
        } else if(amount == 1000) {
            option = 2;
        } else if(amount == 10000) {
            option = 3;
        } else if(amount == 100000) {
            option = 4;
        } else if(amount == 1000000) {
            option = 5;
        } else {
            revert("Staking: no option for deposit amount");
        }
        require(_token.transferFrom(_msgSender(), address(this), amount * 10 ** _decimal), "Staking: failed to send HERC tokens");

        bytes memory bytecode = type(HeraMinter).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(option, _msgSender()));
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMinter(addr).initialize(option, _msgSender());

        HercERC1155.whitelistUser(addr);

        emit ContractCreated(addr);


        _stakes[_msgSender()].amount = amount * 10 ** _decimal;

        if(period == 3) {
            _stakes[_msgSender()].apyOption = 0;
        } else if(period == 6) {
            _stakes[_msgSender()].apyOption = 1;
        } else if(period == 9) {
            _stakes[_msgSender()].apyOption = 2;
        } else if(period == 12) {
            _stakes[_msgSender()].apyOption = 3;
        } else if(period == 18) {
            _stakes[_msgSender()].apyOption = 4;
        } else if(period == 24) {
            _stakes[_msgSender()].apyOption = 5;
        } else if(period == 36) {
            _stakes[_msgSender()].apyOption = 6;
        } else {
            revert("Staking: no option for lock time");
        }
        _stakes[_msgSender()].deadline = block.timestamp + period * 30 days;
        _lastTime[_msgSender()] = block.timestamp;

        emit Deposit(_msgSender(), amount * 10 ** _decimal, period * 30 days);
    }

    function claimRewards() external {
        _claimRewards(_msgSender());
    }

    function _claimRewards(address account) internal {
        _updateRewards(account);

        require(_rewards[account] > 0, "Staking: nothing to claim");

        require(_token.transfer(account, _rewards[account]), "Staking: failed to send HERC tokens");
        
        emit Claim(account, _rewards[account]);

        _rewards[account] = 0;
        
    }

    function _updateRewards(address account) internal {
        _rewards[account] += _calculateRewards(account);
        _lastTime[account] = block.timestamp;
    }

    function _calculateRewards(address account) internal view returns (uint256) {
        return _stakes[account].amount * _apyOptions[_stakes[account].apyOption] / _denominator * (block.timestamp - _lastTime[account]) / 360 days ;
    }

    function withdraw() external {
        require(block.timestamp > _stakes[_msgSender()].deadline, "Staking: does not reach lock deadline");

        _updateRewards(_msgSender());
        if(_rewards[_msgSender()] > 0)
            _claimRewards(_msgSender());
        
        require(_token.transfer(_msgSender(), _stakes[_msgSender()].amount), "Staking: failed to send HERC tokens");

        emit Withdraw(_msgSender(), _stakes[_msgSender()].amount);

        _stakes[_msgSender()].amount = 0;
    }

    function getApyOption(uint8 option) external view returns (uint256) {
        return _apyOptions[option];
    }

    function setApyOption(uint8 option, uint256 value) external onlyOwner {
        _apyOptions[option] = value;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    function mint(uint256 tokenId, uint256 count) external;
}

interface IMinter {
    function initialize(uint8 option, address minter) external;

    function mint() external;
}

contract HeraMinter is IMinter {
    IERC1155 _token;
    bool _initialized;
    uint8 _option;
    uint256 _count;
    address _minter;

    constructor() {
        // _token = IERC1155(token_);
        //Set HeraERC1155 contract address
        _token = IERC1155(0xDd8553cF788b4790051Ed09A7529d6b0E7CdE754);
    }

    function initialize(uint8 option, address minter) external override {
        require(!_initialized, "Minter: already initialized");

        if(option == 1) {
            _count = 9;
        } else if(option == 2) {
            _count = 99;
        } else if(option == 3) {
            _count = 499;
        } else if(option == 4) {
            _count = 999;
        } else if(option == 5) {
            _count = 9999;
        } else {
            revert("Minter: no such option");
        }

        _option = option;
        _initialized = true;
        _minter = minter;
    }

    function mint() external override {
        require(msg.sender == _minter, "Minter: caller is not minter");
        require(_count > 0, "Minter: already minted all");
        _token.mint(_option, 1);
        _count--;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IHeraERC1155 {
    function whitelistUser(address _user) external;

    function whitelistUsers(address[] calldata _users) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}