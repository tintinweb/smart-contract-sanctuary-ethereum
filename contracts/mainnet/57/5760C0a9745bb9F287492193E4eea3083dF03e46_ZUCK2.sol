/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// https://twitter.com/Zuck2erc


// https://t.me/Zuck2erc

// https://zuck2.nicepage.io


//   ZZZZZZZZZZZZZZZZZ
//                Z
//              z
//          Z
//       Z
//    Z
//  ZZZZZZZZZZZZZZZZZ







// //Whether you're a meme creator, a crypto investor, or just a meme enthusiast,  is the token for you!

// 4%  will be allocated to a wallet for potential listings on CEX and marketing. 



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZUCK2 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private contractOwner;
    address public cexWallet;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensBurned(address indexed burner, uint256 value);
    event ContractRenounced(address indexed previousOwner);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        address _cexWallet
    ) {
        require(_totalSupply > 0, "Total supply must be greater than zero");
        require(_cexWallet != address(0), "Invalid CEX wallet address");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        cexWallet = _cexWallet;

        uint256 cexWalletShare = (_totalSupply * 4) / 100; 
        uint256 ownerShare = _totalSupply - cexWalletShare;

        balanceOf[msg.sender] = ownerShare;
        balanceOf[cexWallet] = cexWalletShare;

        emit Transfer(address(0), msg.sender, ownerShare);
        emit Transfer(address(0), cexWallet, cexWalletShare);

        contractOwner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid recipient");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid spender");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        require(_to != address(0), "Invalid recipient");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit TokensBurned(msg.sender, _value);
        return true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner");

        emit OwnershipTransferred(contractOwner, _newOwner);
        contractOwner = _newOwner;
    }

    function renounceContractOwnership() public onlyOwner {
        emit ContractRenounced(contractOwner);
        contractOwner = address(0);
    }
}