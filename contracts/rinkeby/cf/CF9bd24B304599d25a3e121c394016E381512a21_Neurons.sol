// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Neurons/Package.sol";

interface ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

/**
 * @title Neurons
 */
contract Neurons is NRN {
    receive() external payable {}
    fallback() external payable {}

    mapping(uint256 => uint256) private _timestamp;
    mapping(uint256 => uint256) private _stakingTime;
    mapping(uint256 => uint256) private _reward;

    address private _burner;

    bool private _pause;
    bool private _locked;

    ERC721 contractAddress;

    modifier gate() {
        require(_locked == false, "NRN: reentrancy denied");
        _locked = true;
        _;
        _locked = false;
    }

    constructor(ERC721 _address, address _accountBurner) NRN("Neurons", "NRN") {
        _transferOwnership(msg.sender);
        _mint(msg.sender, 1000000 * 10 ** decimals());
        contractAddress = _address;
        _burner = _accountBurner;
        _locked == false;
        _pause = false;
    }

    function unpause() public ownership {
        _pause = false;
    }

    function pause() public ownership {
        _pause = true;
    }

    function paused() public view returns (bool) {
        return _pause;
    }

    function setContractAddress(ERC721 _address) public ownership {
        contractAddress = _address;
    }

    function setBurnerAddress(address _address) public ownership {
        _burner = _address;
    }

    function claim(uint256 _tokenId, uint256 _stakingDays) public gate {
        require(_pause == false, "NRN: staking is paused");
        require(_stakingDays <= 60, "NRN: cannot stake more than 60 days");
        require(_stakingDays != 0, "NRN: cannot stake for 0 days");
        require((_timestamp[_tokenId] + _stakingTime[_tokenId]) <= block.timestamp, "NRN: staking period not complete");
        require(msg.sender == contractAddress.ownerOf(_tokenId));

        uint256 _staked = _stakingDays * 86400;
        _mint(msg.sender, _reward[_tokenId] * 10 ** decimals());

        _timestamp[_tokenId] = block.timestamp;
        _stakingTime[_tokenId] = _staked;
        _reward[_tokenId] = _stakingDays;
    }

    function burn(address _from, uint256 _nrn) public {
        require(msg.sender == _burner, "NRN: unauthorized burn");
        _burn(_from, _nrn * 10 ** decimals());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC/20/ERC20.sol";
import "../ERC/173/ERC173.sol";

/**
 * @dev Implementation of ERC20
 */
contract NRN is ERC20, ERC173 {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address private _ownership;

    function transferOwnership(address _newOwner) public override ownership {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = _ownership;
        _ownership = _newOwner;
    
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    modifier ownership() {
        require(owner() == msg.sender, "ERC173: caller is not the owner");
        _;
    }

    function owner() public view override returns (address) {
        return _ownership;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(balanceOf(msg.sender) >= _value, "ERC20: value exceeds balance");

        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(balanceOf(_from) >= _value, "ERC20: value exceeds balance");

        if (msg.sender != _from) {
            require(balanceOf(_from) >= allowance(_from, msg.sender), "ERC20: allowance exceeds balance");

            _allowances[_from][msg.sender] -= _value;
        }

        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        require(_spender != address(0), "ERC20: cannot approve the zero address");
        require(_spender != msg.sender, "ERC20: cannot approve the owner");

        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {

        return _allowances[_owner][_spender];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "ERC20: transfer to the zero address");

        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function _mint(address _to, uint256 _value) internal {
        require(_to != address(0), "ERC20: cannot mint to the zero address");

        _totalSupply += _value;
        _balances[_to] += _value;

        emit Transfer(address(0), _to, _value);
    }

    function _burn(address _from, uint256 _value) internal {
        require(_from != address(0), "ERC20: burn cannot be from zero address");

        _balances[_from] -= _value;
        _totalSupply -= _value;

        emit Transfer(_from, address(0), _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 Interface
 *
 * @dev Interface of the ERC20 standard
 */
interface ERC20 {
    /**
     * @dev ERC20 standard events
     */

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @dev ERC20 standard functions
     */

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC173 Interface
 *
 * @dev Interface of the ERC173 standard according to the EIP
 */
interface ERC173 {
    /**
     * @dev ERC173 standard events
     */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev ERC173 standard functions
     */

    function owner() view external returns (address);

    function transferOwnership(address _newOwner) external;
}