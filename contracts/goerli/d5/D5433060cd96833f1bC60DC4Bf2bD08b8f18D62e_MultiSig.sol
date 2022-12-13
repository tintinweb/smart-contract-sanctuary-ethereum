/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract MultiSig {
    
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
    
    IERC20  public token;
    
    bool    private initToken;
    address private immutable tokenSetter;
    
    address[] public owners;
    uint256 public threshold;
    
    mapping (address => bool) public isOwner;
    mapping (bytes32 => uint256) public numberOfTransferSignatures;
    mapping (bytes32 => uint256) public numberOfApproveSignatures;
    mapping (bytes32 => uint256) public numberOfAddOwnerSignatures;
    mapping (address => mapping(bytes32 => bool)) public hasSignTransfer;
    mapping (address => mapping(bytes32 => bool)) public hasSignApprove;
    mapping (address => mapping(bytes32 => bool)) public hasSignAddOwner;

    event SignTransfer(address indexed owner, address indexed recipient, uint256 amount);
    event SignApprove(address indexed owner, address indexed spender, uint256 value);
    event SignAddOwner(address indexed owner, address indexed newOwner, uint256 threshold);
    event ThresholdUpdate(uint256 oldThreshol, uint256 newThreshol);
    event AddNewOwner(address indexed newOwner);
    
    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _owners
    ) {

        require(_owners.length >= 2, "MultiSig: at least 2 owners");

        name = _name;
        symbol = _symbol;

        for (uint256 i = 0; i < _owners.length; i++) {
            address newOwner = _owners[i];
            owners.push(newOwner);
            isOwner[newOwner] = true;
        }

        threshold = _owners.length;

        tokenSetter = msg.sender;
    }

    function setToken(
        address _tokenAddress
    ) external {
        require(!initToken, "MultiSig: token has been initialized");
        require(msg.sender == tokenSetter, "MultiSig: not token setter");
        token = IERC20(_tokenAddress);
        initToken = true;
    }


    function addOwner(
        address _newOwner,
        uint256 _threshold
    ) external {
        require(!isOwner[_newOwner], "MultiSig: it's already the owner");
        require(isOwner[msg.sender], "MultiSig: not owner");
        require(_newOwner != address(0), "MultiSig: invalid owner address");
        require(_threshold >=2 && _threshold <= (owners.length + 1), "MultiSig: invalid threshold");
        
        bytes32 key = keccak256(abi.encodePacked(_newOwner, _threshold));
        require(!hasSignAddOwner[msg.sender][key], "MultiSig: you've already signed it");
        
        numberOfAddOwnerSignatures[key]++;
        hasSignAddOwner[msg.sender][key] = true;
        emit SignAddOwner(msg.sender, _newOwner, _threshold);

        if (numberOfAddOwnerSignatures[key] >= threshold) {
            
            owners.push(_newOwner);
            isOwner[_newOwner] = true;
            emit AddNewOwner(_newOwner);
            
            emit ThresholdUpdate(threshold, _threshold);
            threshold = _threshold;
            
            numberOfAddOwnerSignatures[key] = 0;

            for (uint256 i = 0; i < owners.length; i++) {
                hasSignAddOwner[owners[i]][key] = false;
            }
        }
    }

    function totalSupply() external view returns (uint256){
        return token.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint) {
        if (isOwner[_owner]){
            return token.balanceOf(address(this));
        }
        return 0;
    }

    function allowance(address owner, address spender) external view returns (uint256){
        return 0;
    }

    function transfer(address recipient, uint256 amount)  public returns (bool){
        
        require(isOwner[msg.sender], "MultiSig: not owner");
        require(token.balanceOf(address(this)) >= amount, "MultiSig: insufficient balance");

        bytes32 key = keccak256(abi.encodePacked(recipient, amount));
        require(!hasSignTransfer[msg.sender][key], "MultiSig: you've already signed it");
        
        numberOfTransferSignatures[key]++;
        hasSignTransfer[msg.sender][key] = true;

        emit SignTransfer(msg.sender, recipient, amount);

        if (numberOfTransferSignatures[key] >= threshold) {
            token.transfer(recipient, amount);
            numberOfTransferSignatures[key] = 0;

            for (uint256 i = 0; i < owners.length; i++) {
                hasSignTransfer[owners[i]][key] = false;
            }
        }

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool){
        require(isOwner[msg.sender], "MultiSig: not owner");

        bytes32 key = keccak256(abi.encodePacked(spender, value));
        require(!hasSignApprove[msg.sender][key], "MultiSig: you've already signed it");
        
        numberOfApproveSignatures[key]++;
        hasSignApprove[msg.sender][key] = true;

        emit SignApprove(msg.sender, spender, value);

        if (numberOfApproveSignatures[key] >= threshold) {
            token.approve(spender, value);
            numberOfApproveSignatures[key] = 0;

            for (uint256 i = 0; i < owners.length; i++) {
                hasSignApprove[owners[i]][key] = false;
            }
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool){
        return false;
    }

    function getKey(address account, uint256 value) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, value));
    }
}