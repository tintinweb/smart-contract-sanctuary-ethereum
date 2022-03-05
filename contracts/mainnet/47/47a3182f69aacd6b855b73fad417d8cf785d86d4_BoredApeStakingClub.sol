// SPDX-License-Identifier: MIT

//      |||||\          |||||\               |||||\           |||||\
//      ||||| |         ||||| |              ||||| |          ||||| |
//       \__|||||\  |||||\___\|               \__|||||\   |||||\___\|
//          ||||| | ||||| |                      ||||| |  ||||| |
//           \__|||||\___\|       Y u g a         \__|||||\___\|
//              ||||| |             L a b s          ||||| |
//          |||||\___\|                          |||||\___\|
//          ||||| |                              ||||| |
//           \__|||||||||||\                      \__|||||||||||\
//              ||||||||||| |                        ||||||||||| |
//               \_________\|                         \_________\|

pragma solidity ^0.8.7;

import "ERC721.sol";
import "IERC721Receiver.sol";
import "ERC20.sol";

abstract contract Stakeable is Context {
    address private _staker;
    event StakeTransferred(address indexed previousStaker, address indexed newStaker);
     constructor() {
        _transferStake(_msgSender());
    }
    function staker() internal virtual returns (address) {
        return _staker;
    } 
    modifier onlyStaker() {
        require(staker() == _msgSender(), "Stakeable: caller is not the staker");
        _;
    }
    function transferStake(address newStaker) internal virtual onlyStaker {
        require(newStaker != address(0), "Stakeable: new staker is the zero address");
        _transferStake(newStaker);
    } 
    function _transferStake(address newStaker) internal virtual {
        address oldStaker = _staker;
        _staker = newStaker;
        emit StakeTransferred(oldStaker, newStaker);
    }
}

abstract contract NFTReceiver is IERC721Receiver, Stakeable {
    IERC721 public BAYCAddress;
    IERC721 public MAYCAddress;
    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
        address wallet;
        uint index;
    }
    Stake[] public stakers_enrolled;    
    function addStaker(uint256 _tokenId, uint256 _timestamp, address _wallet) internal virtual {
        uint stakeIndex = stakers_enrolled.length;
        Stake memory new_staker = Stake(_tokenId, _timestamp, _wallet, stakeIndex);
        stakers_enrolled.push(new_staker);
    }
    function array_length() internal virtual returns(uint) {  
        uint numberOfStakers = stakers_enrolled.length;
        return numberOfStakers; 
    } 
    // map staker address to stake details
    mapping(address => Stake) public stakes;
    mapping(uint256 => address) private _owners;
    // map staker to total staking time 
    mapping(address => uint256) public stakingTime; 
    mapping(address => uint256) public claimedTime;     
    mapping(address => uint256) private _balances;
    constructor() {
        BAYCAddress = ERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
        MAYCAddress = ERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
    }
    function stakeApes(uint16[] calldata _tokenIds) public {
        uint length = _tokenIds.length;
        unchecked {
            for (uint i=0; i<length; i++) {
                uint16 _tokenId = _tokenIds[i];
                address tokenOwner = BAYCAddress.ownerOf(_tokenId);
                _owners[_tokenId] = msg.sender;
                addStaker(_tokenId, block.timestamp, tokenOwner);
                BAYCAddress.safeTransferFrom(tokenOwner, staker(), _tokenId);
            }
        }
    } 
    function stakeMutants(uint16[] calldata _tokenIds) public {
        uint length = _tokenIds.length;
        unchecked {
            for (uint i=0; i<length; i++) {
                uint16 _tokenId = _tokenIds[i];
                address tokenOwner = MAYCAddress.ownerOf(_tokenId);
                _owners[_tokenId] = msg.sender;
                addStaker(_tokenId, block.timestamp, tokenOwner);
                MAYCAddress.safeTransferFrom(tokenOwner, staker(), _tokenId);
            }
        }
    } 
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract BoredApeStakingClub is NFTReceiver, IERC20 {
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    constructor() {
        _name = "ApeCoin";
        _symbol = "APE";
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function claimRewards() public {
        _mint(msg.sender, stakingTime[msg.sender]);
        claimedTime[msg.sender] += stakingTime[msg.sender];
        stakingTime[msg.sender] -= stakingTime[msg.sender];
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function _msgSender() internal view virtual override returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual override returns (bytes calldata) {
        return msg.data;
    }
    function unstakeApes(uint16[] calldata _tokenIds) public {
        uint length = _tokenIds.length;
        unchecked {
            for (uint i=0; i<length; i++) {
                uint16 _tokenId = _tokenIds[i];
                uint stakeIndex = stakes[msg.sender].index;
                emit Transfer(address(this), msg.sender, _tokenId);
                stakingTime[msg.sender] += (block.timestamp - stakers_enrolled[stakeIndex].timestamp);
                delete stakes[msg.sender]; 
                delete stakers_enrolled[stakeIndex];
            }
        }  
    }
    function unstakeMutants(uint16[] calldata _tokenIds) public {
        uint length = _tokenIds.length;
        unchecked {
            for (uint i=0; i<length; i++) {
                uint16 _tokenId = _tokenIds[i];
                uint stakeIndex = stakes[msg.sender].index;
                emit Transfer(address(this), msg.sender, _tokenId);
                stakingTime[msg.sender] += (block.timestamp - stakers_enrolled[stakeIndex].timestamp);
                delete stakes[msg.sender]; 
                delete stakers_enrolled[stakeIndex];
            }
        }  
    }
}